import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('cf_upload', Path(__file__).resolve().parents[1] / 'tools/curseforge_upload.py')
cf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cf)

class UploadTests(unittest.TestCase):
    def test_stable_metadata(self):
        m = cf.metadata({'tag_name':'v1.2.3','body':'Notes','draft':False,'prerelease':False}, 'Addon')
        self.assertEqual(m['releaseType'], 'release')
        self.assertEqual(m['gameVersionNames'], ['11.0.0.0000'])
        self.assertEqual(m['changelog'], 'Notes')
    def test_beta(self):
        self.assertEqual(cf.metadata({'tag_name':'v1.2.3-beta.1','prerelease':True},'Addon')['releaseType'], 'beta')
    def test_draft_rejected(self):
        with self.assertRaises(ValueError): cf.metadata({'tag_name':'v1.2.3','draft':True},'Addon')
    def test_unsafe_tag_rejected(self):
        with self.assertRaises(ValueError): cf.metadata({'tag_name':'../oops'},'Addon')

    def test_package_verification(self):
        import tempfile, zipfile
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); source=root/'source'; source.mkdir()
            (source/'Core.lua').write_bytes(b'hello\r\n')
            archive=root/'addon.zip'
            with zipfile.ZipFile(archive,'w') as z: z.writestr('Addon/Core.lua',b'hello\n')
            cf.verify(archive,source,'Addon')
            with zipfile.ZipFile(archive,'w') as z: z.writestr('Addon/Core.lua',b'changed')
            with self.assertRaises(ValueError): cf.verify(archive,source,'Addon')
            with zipfile.ZipFile(archive,'w') as z:
                z.writestr('Addon/Core.lua',b'hello\n'); z.writestr('private.txt',b'no')
            with self.assertRaises(ValueError): cf.verify(archive,source,'Addon')
