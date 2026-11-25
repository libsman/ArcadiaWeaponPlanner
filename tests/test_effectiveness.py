import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon'/'ArcadiaWeaponPlanner'
class EffectivenessTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  for f in ['Core.lua','Import.lua','Effectiveness.lua']:
   self.lua.execute((ROOT/f).read_bytes())
 def test_default_and_persistence(self):
  self.lua.execute('SaveVariables=function()end; AWP.RegisterSettings()')
  self.assertTrue(self.lua.globals().AWP_Settings.personalEffectiveness)
  self.lua.execute('AWP_Settings.personalEffectiveness=false; AWP.RegisterSettings()')
  self.assertFalse(self.lua.globals().AWP_Settings.personalEffectiveness)
 def test_compensation_keeps_config_and_effectiveness_roll(self):
  self.lua.execute('c={ids={764,730,762,197},values={3,15,7.2,-.1}}; result=AWP.WithoutPersonalEffectiveness(c,1.378)')
  g=self.lua.globals()
  self.assertAlmostEqual(g.result['values'][1],3/1.378)
  self.assertEqual(g.result['values'][2],15)
  self.assertAlmostEqual(g.result['values'][3],7.2/1.378)
  self.assertAlmostEqual(g.result['values'][4],-.1/1.378)
  self.assertEqual(g.c['values'][1],3)
 def test_localized_percent(self):
  p=self.lua.globals().AWP
  self.assertAlmostEqual(p.EffectivenessNumber('|cff00ff00137.80%|r'),1.378)
  self.assertAlmostEqual(p.EffectivenessNumber('137,80 %'),1.378)
  self.assertIsNone(p.EffectivenessNumber('unknown'))
  self.assertIsNone(p.EffectivenessNumber('0%'))
 def test_native_render_compensates_only_preview_and_marks_neutral(self):
  self.lua.execute('''
   TEXT=function()return 'Absolute effectiveness' end
   left={IsVisible=function()return true end,GetText=function()return 'Absolute effectiveness' end}
   right={text='137.80%',GetText=function(s)return s.text end,SetText=function(s,v)s.text=v end}
   TestTextLeft1=left;TestTextRight1=right
   calls={};AWP.ConfigLink=function(c,e)calls[#calls+1]=c;return 'link' end
   tip={GetName=function()return 'Test' end,SetItemDB=function()end,SetHyperLink=function()right.text='137.80%' end,Hide=function()hidden=true end}
   c={item=1,ids={764,730,762,197},values={3,15,7.2,-.1}}
   AWP_Settings={personalEffectiveness=false}
   result=AWP.PreviewTooltip(tip,c,{})
  ''')
  g=self.lua.globals()
  self.assertTrue(g.result)
  self.assertEqual(g.right.text,'100.00%')
  self.assertAlmostEqual(g.calls[2]['values'][1],3/1.378)
  self.assertEqual(g.c['values'][1],3)
  self.lua.execute("TestTextLeft1=nil;hidden=false;result=AWP.PreviewTooltip(tip,c,{})")
  self.assertFalse(g.result)
  self.assertTrue(g.hidden)
