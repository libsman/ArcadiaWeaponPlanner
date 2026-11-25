"""Build a clean installable addon ZIP. No local settings or game files included."""
from pathlib import Path
import re, zipfile, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
addon=root/'addon'/'ArcadiaWeaponPlanner'
version=re.search(r"AWP.version = '([^']+)'",(addon/'Core.lua').read_text(encoding='utf8')).group(1)
ET.parse(addon/'UI.xml')
files=sorted(p for p in addon.rglob('*') if p.is_file())
allowed={'.lua','.xml','.toc','.md'}
for p in files:
    assert p.suffix in allowed or p.name=='LICENSE', p
    assert not any(x in p.name.lower() for x in ('probe','qa_','.bak')), p
out=root/'dist';out.mkdir(exist_ok=True)
archive=out/f'ArcadiaWeaponPlanner-{version}.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,'ArcadiaWeaponPlanner/'+p.relative_to(addon).as_posix())
print(archive)
