import unittest, struct
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/"addon"/"ArcadiaWeaponPlanner"
class PlannerTests(unittest.TestCase):
 def test_embedded_tooltips_have_explicit_native_size(self):
  import xml.etree.ElementTree as ET
  root=ET.parse(ROOT/'UI.xml').getroot()
  tips=root.findall('.//{*}GameTooltip')
  self.assertEqual(len(tips),3)
  for tip in tips:
   dim=tip.find('./{*}Size/{*}AbsDimension')
   self.assertIsNotNone(dim,tip.attrib['name']+' inherits parent dimensions on movement')
   self.assertGreater(float(dim.attrib['x']),0)
   self.assertGreater(float(dim.attrib['y']),0)
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  self.lua.execute((ROOT/"Core.lua").read_bytes())
  self.p=self.lua.globals().AWP
 def test_weapon_roll_factors(self):
  self.lua.execute((ROOT/'Stats.lua').read_bytes())
  self.assertEqual(self.p.MaxRoll(730,self.lua.table_from({'factor':1})),10)
  self.assertEqual(self.p.MaxRoll(730,self.lua.table_from({'factor':1.5})),15)
  self.assertEqual(self.p.MaxRoll(730,self.lua.table_from({'factor':.875})),8.75)
  self.assertEqual(self.p.MaxRoll(764,self.lua.table_from({'factor':1})),2)
  self.assertAlmostEqual(self.p.MaxRoll(762,self.lua.table_from({'factor':1.5})),7.2)
 def test_combined_filters(self):
  w=self.lua.table_from({'id':1210893,'kind':22,'quality':9,'name':'Hieb der Leere'})
  self.assertTrue(self.p.Matches(w,'leere',22,9))
  self.assertFalse(self.p.Matches(w,'leere',22,7))
  self.assertFalse(self.p.Matches(w,'leere',2,9))
 def test_localized_search_ignores_case_and_surrounding_spaces(self):
  for name,query in [('Die Düsternis','  DÜSTERNIS  '),('Épée','ÉPÉE'),('Меч','МЕЧ')]:
   w=self.lua.table_from({'id':1210371,'name':name})
   self.assertTrue(self.p.Matches(w,query,0,0),(name,query))
 def test_worldboss_catalog(self):
  self.lua.execute((ROOT/'Catalog.lua').read_bytes())
  records={int(w.id):w for _,w in self.p.Weapons.items()}
  for id in [1210371,1220155,1220156]:self.assertAlmostEqual(records[id].factor,.875)
 def test_instruments_use_135_percent_maxima(self):
  self.lua.execute((ROOT/'Stats.lua').read_bytes())
  self.lua.execute((ROOT/'Catalog.lua').read_bytes())
  instruments=[w for _,w in self.p.Weapons.items() if w.kind==21]
  self.assertEqual(len(instruments),12)
  for w in instruments:
   self.assertAlmostEqual(self.p.MaxRoll(730,w),13.5)
   self.assertAlmostEqual(self.p.MaxRoll(764,w),2.7)
   self.assertAlmostEqual(self.p.MaxRoll(762,w),6.48)
 def test_float(self):
  for n in [0,3,15,7.2,-.1,1540,0.875]:
   self.assertEqual(self.p.FloatHex(n),struct.pack('<f',n).hex())
 def test_payload(self):
  self.assertEqual(self.p.Payload(self.lua.table_from([764,730,762,197]),self.lua.table_from([3,15,7.2,-.1])), 'fc02da02fa02c50000004040000070416666e640cdccccbd00')
 def test_link_preserves(self):
  link='|Hitem:127a0d 1 f0141564 0 0 0 0 0 0 0 3a980 5fb2 127a0d '+('0'*50)+'|h|cffffd700[Name +20]|r|h'
  result=self.p.WithPayload(link,'a'*50)
  self.assertEqual(result,link.replace('0'*50,'a'*50))
 def test_invalid_link(self):
  self.assertIsNone(self.p.WithPayload('bad','a'*50))
 def test_number_clamp(self):
  self.assertEqual(self.p.Number('invalid',17,1,30),17)
  self.assertEqual(self.p.Number('999',17,1,30),30)
  self.assertEqual(self.p.Number('-4',17,1,30),1)
 def test_editing_tier_updates_values(self):
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  self.lua.execute("GetLanguage=function()return 'DE' end; SlashCmdList={}")
  self.lua.execute((ROOT/'UI.lua').read_bytes())
  self.lua.execute("AWPPlus={GetText=function()return '20' end};AWPTier={GetText=function()return '18' end};for i=1,4 do _G['AWPValue'..i]={GetText=function()return '7,2' end} end;AWP.Render=function() rendered=true end;AWP.Changed()")
  self.assertEqual(self.p.tier,18)
  self.assertEqual(self.p['values'][1],7.2)
  self.assertTrue(self.lua.globals().rendered)
 def test_only_confirmed_category_conflicts_block(self):
  self.lua.execute((ROOT/'Stats.lua').read_bytes())
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  self.lua.execute("GetLanguage=function()return 'DE' end;SlashCmdList={}")
  self.lua.execute((ROOT/'UI.lua').read_bytes())
  self.lua.execute("AWP.ids={134,730,23,197}")
  self.assertFalse(self.p.Allowed(171,3))
  self.assertFalse(self.p.Allowed(730,3))
  self.assertTrue(self.p.Allowed(23,3))
  self.lua.execute("AWP.ids={23,730,762,197}")
  self.assertTrue(self.p.Allowed(75,3))
 def test_plus_edit_does_not_round_unedited_corruption(self):
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  self.lua.execute("GetLanguage=function()return 'DE' end;SlashCmdList={}")
  self.lua.execute((ROOT/'UI.lua').read_bytes())
  self.lua.execute("AWP.values={1.23456789123,15,7.2,-.1};AWPPlus={GetText=function()return '21' end};AWPTier={GetText=function()return '17' end};for i=1,4 do _G['AWPValue'..i]={GetText=function()return '1.23457' end} end;AWP.Render=function()end;AWP.Changed(AWPPlus)")
  self.assertEqual(self.p.plus,21)
  self.assertEqual(self.p['values'][1],1.23456789123)
 def test_maximum_keeps_selected_attributes(self):
  self.lua.execute((ROOT/'Stats.lua').read_bytes())
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  self.lua.execute("GetLanguage=function()return 'DE' end;SlashCmdList={}")
  self.lua.execute((ROOT/'UI.lua').read_bytes())
  self.lua.execute("AWP.selected={factor=.875};AWP.ids={134,730,764,197};AWP.Fields=function()end;AWP.Render=function()end;AWP.Maximum()")
  self.assertEqual(self.p.ids[1],134)
  self.assertAlmostEqual(self.p['values'][1],4.2)
  self.assertAlmostEqual(self.p['values'][2],8.75)
  self.assertEqual(self.p['values'][4],-.1)
 def test_all_locales_have_same_keys(self):
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  locales=self.lua.globals().AWPLocales
  expected=set(locales.EN.keys())
  self.assertEqual(len(list(locales.keys())),11)
  for lang,loc in locales.items():self.assertEqual(set(loc.keys()),expected,lang)
 def test_corruption_change_invalidates_native_tooltip_cache(self):
  self.lua.execute((ROOT/'Import.lua').read_bytes())
  self.lua.execute((ROOT/'Effectiveness.lua').read_bytes())
  for f in sorted((ROOT/'Locales').glob('*.lua')):self.lua.execute(f.read_bytes())
  self.lua.execute("GetLanguage=function()return 'DE' end;SlashCmdList={}")
  self.lua.execute((ROOT/'UI.lua').read_bytes())
  self.lua.execute('''
   AWP.selected={id=1220156};AWP.Allowed=function()return true end
   GenerateGearHyperlink=function()return '|Hitem:1 1 1 0 0 0 0 0 0 0 1 1 1 '..string.rep('0',50)..'|h[x]|h' end
   AWPStatus={SetText=function()end};AWPWindow={GetName=function()return 'AWPWindow' end}
   local noop=function()end
   AWPTooltip={Hide=noop,Show=noop,SetScale=noop,ClearAllAnchors=noop,SetAnchor=noop,
    GetHeight=function()return 100 end,GetWidth=function()return 100 end,
    SetItemDB=function(self,id)self.cached=nil end,
    SetHyperLink=function(self,link)if not self.cached then self.cached=link end end}
   AWP.Render();AWP.ids[3]=134;AWP.Render()
  ''')
  self.assertEqual(self.lua.globals().AWPTooltip.cached,self.p.link)
 def test_catalog_unique(self):
  self.lua.execute((ROOT/'Catalog.lua').read_bytes())
  ids=[w.id for _,w in self.p.Weapons.items()]
  self.assertEqual(len(ids),78)
  self.assertEqual(len(set(ids)),78)
  self.assertIn(1210893,ids)
 def test_distribution_compiles_as_bytes(self):
  compile=self.lua.eval('function(s) local f,e=loadstring(s);return f~=nil,e end')
  for f in ROOT.rglob('*.lua'):
   ok,error=compile(f.read_bytes());self.assertTrue(ok,(f,error))
 def test_no_inventory_mutations(self):
  text=''.join(f.read_text(encoding='utf8') for f in ROOT.rglob('*.lua'))
  for forbidden in ['SwapMainhand(', 'UseItemByName(', 'PickupBagItem(', 'EquipItem(', 'PerformSaveVariables(', 'CastSpellByName(']:
   self.assertNotIn(forbidden,text)
if __name__=='__main__':unittest.main()
