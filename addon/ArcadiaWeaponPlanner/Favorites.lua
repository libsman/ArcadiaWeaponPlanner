-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
local P=AWP
local function copy(a)local b={};for i=1,4 do b[i]=a[i] end;return b end
local function deep(a)if type(a)~='table' then return a end;local b={};for k,v in pairs(a) do b[k]=deep(v) end;return b end
local function finite(n,lo,hi)return type(n)=='number' and n==n and n>=lo and n<=hi end
function P.Item(id)for _,w in ipairs(P.Weapons) do if w.id==id then return w end end end
local function integer(n,lo,hi)return finite(n,lo,hi) and n==math.floor(n) end
local function extrasValid(e)
 if e==nil then return true end
 if type(e)~='table' then return false end
 if e.freeSlots~=nil and not integer(e.freeSlots,0,7) then return false end
 if e.maxDura~=nil and not integer(e.maxDura,1,255) then return false end
 for key,count in pairs({stats=6,runes=4}) do
  local a=e[key]
  if a~=nil then
   if type(a)~='table' then return false end
   for k,v in pairs(a) do
    if not integer(k,1,count) or not integer(v,0,4294967295) then return false end
    if key=='stats' and v~=0 and not integer(v,458753,524287) then return false end
   end
  end
 end
 return true
end
local function valid(f)
 if type(f)~='table' or not finite(f.id,1,2147483647) or type(f.name)~='string' or f.name=='' or not P.Item(f.item) then return false end
 if not integer(f.plus,0,30) or not integer(f.tier,1,20) or type(f.ids)~='table' or type(f.values)~='table' or not extrasValid(f.extras) then return false end
 for i=1,4 do
  if not finite(f.ids[i],0,65535) or f.ids[i]~=math.floor(f.ids[i]) or not finite(f.values[i],-100000,100000) then return false end
 end
 return true
end
local function store()
 if type(AWP_Favorites)~='table' then AWP_Favorites={} end
 if type(AWP_Favorites.entries)~='table' then AWP_Favorites.entries={} end
 AWP_Favorites.version=1
 return AWP_Favorites
end
local function append(entries,f)
 local highest=0;for k in pairs(entries) do if type(k)=='number' and k>highest then highest=k end end
 entries[highest+1]=f
end
function P.RegisterFavorites()
 store()
 if SaveVariables then SaveVariables('AWP_Favorites') end
end
function P.Favorites()
 local list={}
 for _,f in pairs(store().entries) do if valid(f) then list[#list+1]=f end end
 table.sort(list,function(a,b)if a.name==b.name then return a.id<b.id end;return a.name<b.name end)
 return list
end
function P.SaveFavorite(name)
 if type(name)~='string' or not P.selected then return end
 name=name:gsub('|',''):gsub('^%s+',''):gsub('%s+$','')
 if name=='' then return end
 local s=store();local key,index;local highest=0
 for k,f in pairs(s.entries) do
  if type(f)=='table' and finite(f.id,1,2147483646) then
   highest=math.max(highest,f.id)
   if f.name==name then key=f.id;index=k end
  end
 end
 key=key or highest+1
 local f={id=key,name=name,item=P.selected.id,plus=P.plus,tier=P.tier,ids=copy(P.ids),values=copy(P.values),extras=deep(P.extras)}
 if not valid(f) then return end
 if index then s.entries[index]=f else append(s.entries,f) end
 P.favoriteID=key;P.RegisterFavorites();return key
end
function P.LoadFavorite(id)
 for _,f in ipairs(P.Favorites()) do if f.id==id then
  P.selected=P.Item(f.item);P.plus=f.plus;P.tier=f.tier;P.ids=copy(f.ids);P.values=copy(f.values);P.extras=deep(f.extras);P.favoriteID=id
  return true
 end end
 return false
end
function P.DeleteFavorite(id)
 for key,f in pairs(store().entries) do if valid(f) and f.id==id then
  P.deletedFavorite=f;store().entries[key]=nil
  if P.favoriteID==id then P.favoriteID=nil end
  P.RegisterFavorites();return true
 end end
 return false
end
function P.UndoFavoriteDelete()
 local f=P.deletedFavorite;if not f then return false end
 local names={};for _,other in ipairs(P.Favorites()) do names[other.name]=true end
 local original=f.name;local suffix=2
 while names[f.name] do f.name=original..' ('..suffix..')';suffix=suffix+1 end
 -- A new save after deletion must not reuse the restored entry's identity.
 for _,other in ipairs(P.Favorites()) do if other.id==f.id then
  local highest=f.id;for _,x in ipairs(P.Favorites()) do highest=math.max(highest,x.id) end
  f.id=highest+1;break
 end end
 append(store().entries,f);P.deletedFavorite=nil;P.RegisterFavorites();return true
end
