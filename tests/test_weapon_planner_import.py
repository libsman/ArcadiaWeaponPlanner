import unittest,struct
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon'/'ArcadiaWeaponPlanner'
class ImportTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  for name in ['Core.lua','Stats.lua','Catalog.lua','Favorites.lua','Import.lua','Categories.lua']:
   self.lua.execute((ROOT/name).read_bytes())
  self.p=self.lua.globals().AWP
 def link(self,field='f0941564',payload=None):
  payload=payload or self.p.Payload(self.lua.table_from([764,730,762,197]),self.lua.table_from([2,10,4.8,-.15]))
  return '|Hitem:1279fa 1 '+field+' 10002 0 0 a b 0 0 3a980 5fb2 1279fa '+payload+'|h|cffffd700[Hammer +20]|r|h'
 def test_exact_import(self):
  c=self.p.DecodeItem(self.link())
  self.assertEqual(c.item,1210874);self.assertEqual(c.plus,20);self.assertEqual(c.tier,17)
  self.assertEqual(c.ids[1],764);self.assertAlmostEqual(c['values'][3],4.8,places=5)
  self.assertEqual(c.extras.stats[1],0x70002);self.assertEqual(c.extras.stats[2],0x70001)
  self.assertEqual(c.extras.runes[1],10);self.assertEqual(c.extras.freeSlots,4)
 def test_roundtrip_float_including_negative(self):
  for v in [0,-.1,1.35,2.7,1540,1e-40]:
   raw=struct.pack('<f',v).hex();self.assertEqual(self.p.ReadFloat(raw),struct.unpack('<f',bytes.fromhex(raw))[0])
  self.assertIsNone(self.p.ReadFloat('0000807f'))
 def test_malformed_import(self):
  for link in ['',self.link().replace('1279fa','abcdef'),self.link(payload='a'*49),self.link(payload='0'*16+'0000807f'+'0'*26)]:
   result=self.p.DecodeItem(link);self.assertIsNone(result[0] if isinstance(result,tuple) else result)
 def test_oversized_hex_fields_are_rejected(self):
  self.assertIsNone(self.p.DecodeItem(self.link().replace(' a b ', ' '+('f'*300)+' b ')))
 def test_unknown_stat_preserved(self):
  payload=self.p.Payload(self.lua.table_from([999,730,762,0]),self.lua.table_from([3,10,4.8,0]))
  c=self.p.DecodeItem(self.link(payload=payload));self.assertEqual(c.ids[1],999)
 def test_real_grade_six_dagger(self):
  link='|Hitem:127803 2002 140a67 0 0 0 81315 812b8 81269 8128a 26d83 20a3 127803 fc02da02fa0237000000e03f00000c416666864048e132c000|h|cffffd700[Die Düsternis +20]|r|h'
  c=self.p.DecodeItem(link)
  self.assertEqual(c.tier,6);self.assertEqual(c.plus,20);self.assertEqual(c.ids[4],55)
  self.assertEqual(c.extras.runes[1],0x81315)
 def test_snapshot_independent(self):
  c=self.p.DecodeItem(self.link());d=self.p.CopyConfig(c);d['values'][1]=99;d.extras.runes[1]=99
  self.assertEqual(c['values'][1],2);self.assertEqual(c.extras.runes[1],10)
 def test_generate_uses_shared_extras_and_actual_payload(self):
  self.lua.execute("GenerateGearHyperlink=function(...) calls={...};return '|Hitem:1279fa 1 141564 0 0 0 0 0 0 0 3a980 0 1279fa '..string.rep('0',50)..'|h[x]|h' end")
  c=self.p.DecodeItem(self.link());self.p.ConfigLink(c,c.extras)
  args=self.lua.globals().calls
  self.assertEqual(args[5],21);self.assertEqual(args[6],20);self.assertEqual(args[7],0x70002);self.assertEqual(args[13],10);self.assertGreater(args[17],12000)
 def test_category_order_and_shortcuts(self):
  self.assertEqual(list(self.p.StatGroups.values()),['common','attribute','attack','damage','speed','elemental','survival','utility','exploration','progression','others','effectiveness'])
  common=list(self.p.GroupIDs('common').values());self.assertNotIn(44,common)
  for id,group in [(764,'speed'),(730,'effectiveness'),(762,'damage'),(134,'attack'),(283,'attack')]:
   self.assertIn(id,common);self.assertIn(id,list(self.p.GroupIDs(group).values()))
  allids=set()
  for group in self.p.StatGroups.values():allids.update(self.p.GroupIDs(group).values())
  for s in self.p.Stats.values():self.assertIn(s.id,allids)
 def test_saved_import_extras_survive_favorite(self):
  c=self.p.DecodeItem(self.link());self.p.ApplyConfig(c);key=self.p.SaveFavorite('Imported')
  self.assertIsNotNone(key);self.p.extras.runes[1]=88;self.p.LoadFavorite(key)
  self.assertEqual(self.p.extras.runes[1],10)
if __name__=='__main__':unittest.main()
