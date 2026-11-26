"""Upload the verified GitHub release asset, never a locally rebuilt substitute."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.request
import uuid
import zipfile


def metadata(release, addon):
    tag = release.get('tag_name', '')
    if release.get('draft') or not re.fullmatch(r'v\d+\.\d+\.\d+(?:-[a-z0-9.]+)?', tag):
        raise ValueError('Expected a published versioned release')
    return dict(changelog=release.get('body') or tag, changelogType='markdown',
                displayName=addon + ' ' + tag[1:],
                gameVersionNames=['11.0.0.0000'],
                releaseType='beta' if release.get('prerelease') else 'release',
                isMarkedForManualRelease=False)


def gh(*args):
    return subprocess.check_output(['gh', *args], text=True)


def verify(archive, source, addon):
    expected = {addon + '/' + f.relative_to(source).as_posix(): f for f in source.rglob('*') if f.is_file()}
    with zipfile.ZipFile(archive) as z:
        if len(z.namelist()) != len(expected) or set(z.namelist()) != set(expected):
            raise ValueError('Release ZIP file list differs from tagged addon source')
        for name, path in expected.items():
            if z.read(name).replace(b'\r\n', b'\n') != path.read_bytes().replace(b'\r\n', b'\n'):
                raise ValueError('Release ZIP differs from tagged source: ' + name)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--tag', required=True)
    p.add_argument('--addon', required=True)
    p.add_argument('--project', required=True, type=int)
    p.add_argument('--dry-run', action='store_true')
    a = p.parse_args()
    repo = os.environ['GITHUB_REPOSITORY']
    release = json.loads(gh('api', f'repos/{repo}/releases/tags/{a.tag}'))
    meta = metadata(release, a.addon)
    receipt_name = 'curseforge-upload.json'
    if any(x['name'] == receipt_name for x in release['assets']):
        print('CurseForge upload already recorded; skipping.')
        return
    name = f'{a.addon}-{a.tag[1:]}.zip'
    if sum(x['name'] == name for x in release['assets']) != 1:
        raise ValueError('Release must contain exactly one named addon ZIP: ' + name)
    out = Path('cf-upload'); out.mkdir(exist_ok=True)
    gh('release', 'download', a.tag, '--repo', repo, '--pattern', name, '--dir', str(out), '--clobber')
    archive = out/name
    verify(archive, Path('release-source/addon')/a.addon, a.addon)
    print('Verified release ZIP and metadata:', name, meta['releaseType'])
    if a.dry_run:
        print('Dry run: no CurseForge request sent.')
        return
    token = os.environ.get('CURSEFORGE_API_TOKEN', '')
    if not token:
        raise ValueError('Set repository secret CURSEFORGE_API_TOKEN first')
    boundary = uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n'.encode()
            + json.dumps(meta).encode() +
            f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\nContent-Type: application/zip\r\n\r\n'.encode()
            + archive.read_bytes() + f'\r\n--{boundary}--\r\n'.encode())
    req = urllib.request.Request(f'https://chronicles-of-arcadia.curseforge.com/api/projects/{a.project}/upload-file', data=body,
        headers={'X-Api-Token':token, 'Content-Type':'multipart/form-data; boundary='+boundary}, method='POST')
    # Do not retry a POST: a timeout may occur after the upload was accepted.
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            result = json.load(response)
        if not isinstance(result.get('id'), int):
            raise ValueError('Missing uploaded file ID')
    except Exception:
        raise RuntimeError('Upload not confirmed. Inspect CurseForge files before rerunning; do not blindly retry.') from None
    receipt = out/receipt_name
    receipt.write_text(json.dumps({'project':a.project,'file':result['id'],'tag':a.tag}, indent=2), encoding='utf8')
    print('CurseForge accepted file ID:', result['id'])
    gh('release', 'upload', a.tag, str(receipt), '--repo', repo)

if __name__ == '__main__':
    main()
