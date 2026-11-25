-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
local P=AWP
function P.ReadFloat(hex)
 if type(hex)~='string' or #hex~=8 or hex:find('[^%x]') then return end
 local n=0;for i=1,4 do n=n+tonumber(hex:sub(i*2-1,i*2),16)*256^(i-1) end
 local sign=n>=2147483648 and -1 or 1
 local exponent=math.floor(n/8388608)%256;local fraction=n%8388608
 if exponent==255 then return end
 if exponent==0 then return sign*fraction*2^-149 end
 return sign*(1+fraction/8388608)*2^(exponent-127)
end
function P.CopyConfig(c)
 if type(c)~='table' then return c end
 local copy={};for k,v in pairs(c) do copy[k]=P.CopyConfig(v) end;return copy
end
function P.DecodeItem(link)
 if type(link)~='string' then return end
 local body=link:match('|Hitem:([^|]+)|h');if not body then return end
 local f={};for word in body:gmatch('%S+') do f[#f+1]=word end
 if #f~=14 then return end
 for i=1,14 do if f[i]:find('[^%x]') or (i<14 and #f[i]>8) then return end end
 local id=tonumber(f[1],16);if not P.Item(id) then return end
 if #f[3]>8 or #f[14]~=50 then return end
 local packed=tonumber(f[3],16)
 local plus=math.floor(packed/65536)%32;local tier=math.floor(packed/256)%32-4
 if plus>30 or tier<1 or tier>20 then return end
 local c={item=id,plus=plus,tier=tier,ids={},values={},source=link,extras={stats={},runes={},freeSlots=math.floor(packed/2097152)%8,maxDura=packed%256}}
 if c.extras.maxDura==0 then c.extras.maxDura=100 end
 local payload=f[14]
 for i=1,4 do
  local offset=(i-1)*4
  c.ids[i]=tonumber(payload:sub(offset+3,offset+4)..payload:sub(offset+1,offset+2),16)
  c.values[i]=P.ReadFloat(payload:sub(17+(i-1)*8,24+(i-1)*8))
  if not c.values[i] or math.abs(c.values[i])>100000 then return end
 end
 for i=1,3 do
  local pair=tonumber(f[i+3],16);if pair>4294967295 then return end
  local low=pair%65536;local high=math.floor(pair/65536)
  c.extras.stats[i*2-1]=low==0 and 0 or low+458752
  c.extras.stats[i*2]=high==0 and 0 or high+458752
 end
 for i=1,4 do c.extras.runes[i]=tonumber(f[i+6],16) end
 return c
end
function P.CurrentConfig()
 if not P.selected then return end
 return P.CopyConfig({item=P.selected.id,plus=P.plus,tier=P.tier,ids=P.ids,values=P.values,extras=P.extras})
end
function P.ApplyConfig(c)
 local w=c and P.Item(c.item);if not w then return false end
 local copy=P.CopyConfig(c)
 P.selected=w;P.plus=copy.plus;P.tier=copy.tier;P.ids=copy.ids;P.values=copy.values;P.extras=copy.extras;P.favoriteID=nil
 return true
end
function P.ConfigLink(c,extras)
 if not c then return end
 local e=extras or {};local s=e.stats or {};local r=e.runes or {}
 local link=GenerateGearHyperlink(c.item,1,e.freeSlots or 0,e.maxDura or 100,c.tier+4,c.plus,
  s[1] or 0,s[2] or 0,s[3] or 0,s[4] or 0,s[5] or 0,s[6] or 0,
  r[1] or 0,r[2] or 0,r[3] or 0,r[4] or 0,240000,c.item)
 return P.WithPayload(link,P.Payload(c.ids,c.values))
end
