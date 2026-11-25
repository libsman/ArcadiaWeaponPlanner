import unittest
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]/'addon'/'ArcadiaWeaponPlanner'

class FavoritesTests(unittest.TestCase):
 def setUp(self):
  self.lua=LuaRuntime(unpack_returned_tuples=True)
  for name in ['Core.lua','Stats.lua','Catalog.lua','Favorites.lua']:self.lua.execute((ROOT/name).read_bytes())
  self.lua.execute("SaveVariables=function(name) registered=name end;AWP.RegisterFavorites();AWP.selected=AWP.Weapons[1];AWP.plus=19;AWP.tier=16;AWP.ids={764,730,762,197};AWP.values={1.25,9,4.2,-.3}")
  self.p=self.lua.globals().AWP
 def test_snapshot_independent_and_load_exact(self):
  key=self.p.SaveFavorite(' Burst ')
  self.lua.execute('AWP.values[1]=99;AWP.ids[1]=134;AWP.plus=1')
  f=self.p.Favorites()[1]
  self.assertEqual(f.name,'Burst');self.assertEqual(f['values'][1],1.25)
  self.assertTrue(self.p.LoadFavorite(key))
  self.assertEqual(self.p.plus,19);self.assertEqual(self.p.ids[1],764);self.assertEqual(self.p['values'][4],-.3)
  self.lua.execute('AWP.values[1]=5')
  self.assertEqual(self.p.Favorites()[1]['values'][1],1.25)
 def test_named_variants_and_update(self):
  a=self.p.SaveFavorite('Burst');b=self.p.SaveFavorite('Sustain')
  self.assertNotEqual(a,b)
  self.lua.execute('AWP.plus=18')
  self.assertEqual(self.p.SaveFavorite('Burst'),a)
  self.assertEqual(len(self.p.Favorites()),2)
  self.p.LoadFavorite(a);self.assertEqual(self.p.plus,18)
 def test_delete_and_undo(self):
  a=self.p.SaveFavorite('A');b=self.p.SaveFavorite('B')
  self.assertTrue(self.p.DeleteFavorite(a));self.assertEqual(len(self.p.Favorites()),1)
  self.assertTrue(self.p.UndoFavoriteDelete());self.assertEqual(len(self.p.Favorites()),2)
  self.assertFalse(self.p.UndoFavoriteDelete());self.assertTrue(self.p.LoadFavorite(b))
 def test_invalid_records_do_not_break_valid_favorites(self):
  a=self.p.SaveFavorite('Good')
  self.lua.execute("table.insert(AWP_Favorites.entries,false);table.insert(AWP_Favorites.entries,{id=999,name='bad',item=1});table.insert(AWP_Favorites.entries,{id=998,name={},item=1210893})")
  self.assertEqual(len(self.p.Favorites()),1);self.assertTrue(self.p.LoadFavorite(a))
 def test_corrupt_optional_extras_are_not_loaded(self):
  key=self.p.SaveFavorite('Good')
  for invalid in ["false", "{runes='bad'}", "{runes={-1}}", "{stats={1/0}}", "{stats={4294967295}}", "{stats={123}}", "{freeSlots=100}", "{maxDura=0}"]:
   self.lua.execute('AWP_Favorites.entries[1].extras='+invalid)
   self.assertFalse(self.p.LoadFavorite(key),invalid)
  self.lua.execute('AWP_Favorites.entries[1].extras={runes={123},stats={0,458754},freeSlots=2,maxDura=120}')
  self.assertTrue(self.p.LoadFavorite(key))
 def test_saved_data_survives_module_reload(self):
  a=self.p.SaveFavorite('Persistent')
  self.lua.execute((ROOT/'Favorites.lua').read_bytes());self.p.RegisterFavorites()
  self.assertEqual(self.lua.globals().registered,'AWP_Favorites')
  self.assertTrue(self.p.LoadFavorite(a));self.assertEqual(self.p.tier,16)
 def test_undo_does_not_create_ambiguous_names(self):
  a=self.p.SaveFavorite('Burst');self.p.DeleteFavorite(a)
  self.lua.execute('AWP.plus=10');self.p.SaveFavorite('Burst');self.p.UndoFavoriteDelete()
  names=[f.name for _,f in self.p.Favorites().items()]
  self.assertEqual(len(set(names)),2)
 def test_reject_invalid_live_config(self):
  self.lua.execute('AWP.values[1]=0/0')
  self.assertIsNone(self.p.SaveFavorite('Bad'))
  self.assertEqual(len(self.p.Favorites()),0)

if __name__=='__main__':unittest.main()
