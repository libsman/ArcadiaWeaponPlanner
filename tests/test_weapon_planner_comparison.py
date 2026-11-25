import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon'/'ArcadiaWeaponPlanner'
class ComparisonTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  for file in ['Core.lua','Stats.lua','Catalog.lua','Favorites.lua','Import.lua','Effectiveness.lua']:
   self.lua.execute((ROOT/file).read_bytes())
  self.lua.execute('''
   function frame()return {visible=true,Hide=function(s)s.visible=false end,Show=function(s)s.visible=true end,IsVisible=function(s)return s.visible end,SetText=function(s,t)s.text=t end,GetText=function(s)return s.text end,SetItemDB=function(s,id)s.item=id end,SetHyperLink=function(s,l)s.link=l end,SetScale=function()end,ClearAllAnchors=function()end,SetAnchor=function()end,GetHeight=function()return 400 end,GetWidth=function()return 400 end} end
   AWPEffectivenessLabel=frame();AWPEffectiveness=frame();AWPEffectiveness.SetChecked=function(s,v)s.checked=v end;AWPWindow=frame();AWPEditor=frame();AWPComparison=frame();AWPComparison:Hide();AWPComparison.GetName=function()return 'AWPComparison' end
   AWPCompareLeft=frame();AWPCompareRight=frame();AWPCompareLeftTitle=frame();AWPCompareRightTitle=frame();AWPCompareBack=frame();AWPCompareNote=frame();AWPFavoriteName=frame();AWPFavoriteName:SetText('Favorite')
   AWPStatus=frame();AWPImportHint=frame();AWP.Label=function(k)return k end;TEXT=function(k)return k end
   AWP.Render=function()rendered=true end;AWP.Selection=function()end;AWP.Fields=function()end;AWP.Rows=function()end
   shift=true;IsShiftKeyDown=function()return shift end
   ChatEdit_AddItemLink=function(l)fallback=l;return 'fallback' end
  ''')
  self.lua.execute((ROOT/'Comparison.lua').read_bytes())
  self.p=self.lua.globals().AWP
 def test_hook_preserves_other_destinations(self):
  self.lua.execute("AWP.ImportLink=function(l)imported=l;return true end;AWP.InstallImportHook()")
  self.assertTrue(self.lua.globals().ChatEdit_AddItemLink('item'))
  for blocker in ["shift=false","ITEMLINK_EDITBOX={}","ChatFrameEditBox=frame()","AAC_AuctionFrame=frame()","AuctionHubFrame=frame()","AWPComparison:Show()","AWPWindow:Hide()"]:
   self.lua.execute("shift=true;ITEMLINK_EDITBOX=nil;ChatFrameEditBox=nil;AAC_AuctionFrame=nil;AuctionHubFrame=nil;AWPComparison:Hide();AWPWindow:Show();imported=nil;fallback=nil;"+blocker)
   self.assertEqual(self.lua.globals().ChatEdit_AddItemLink('next'),'fallback')
   self.assertIsNone(self.lua.globals().imported)
 def test_failed_import_does_not_replace_baseline(self):
  self.lua.execute('AWP.baseline={item=1210893}')
  self.assertFalse(self.p.ImportLink('not-an-item'))
  self.assertEqual(self.p.baseline.item,1210893)
 def test_comparison_hides_editor_and_normalizes_extras(self):
  self.lua.execute('''
   AWP.baseline={item=1210893,plus=20,tier=17,ids={764,730,762,197},values={3,15,7.2,-.1},extras={runes={123}}}
   AWP.ApplyConfig(AWP.baseline);AWP.values[1]=2
   seen={};AWP.ConfigLink=function(c,e)seen[#seen+1]={item=c.item,extras=e};return 'link' end
   AWP.Compare()
  ''')
  g=self.lua.globals()
  self.assertFalse(g.AWPEditor.visible);self.assertTrue(g.AWPComparison.visible)
  self.assertEqual(g.seen[1].extras.runes[1],123);self.assertEqual(g.seen[2].extras.runes[1],123)
  self.assertEqual(self.p.baseline['values'][1],3)
  self.p.CloseComparison();self.assertTrue(g.AWPEditor.visible);self.assertFalse(g.AWPComparison.visible);self.assertTrue(g.rendered)
  self.lua.execute('AWP.selected=AWP.Item(1210371);seen={};AWP.Compare()')
  self.assertIsNone(g.seen[1].extras.runes);self.assertIsNone(g.seen[2].extras.runes)
 def test_failed_comparison_never_keeps_previous_tooltip(self):
  self.lua.execute('''
   AWP.baseline={item=1210893,plus=20,tier=17,ids={764,730,762,197},values={3,15,7.2,-.1}}
   AWP.ApplyConfig(AWP.baseline);AWP.ConfigLink=function()return 'previous' end;AWP.Compare()
   local calls=0;AWP.ConfigLink=function()calls=calls+1;if calls==1 then return 'new' end end
   AWP.Compare()
  ''')
  g=self.lua.globals()
  self.assertFalse(g.AWPComparison.visible)
  self.assertTrue(g.AWPEditor.visible)
  self.assertEqual(g.AWPStatus.text,'importFailed')
if __name__=='__main__':unittest.main()
