-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
AWP = AWP or {}
AWP.version = '1.0.0'
function AWP.Number(text, default, lo, hi)
 local n=tonumber(text)
 if not n or n~=n then return default end
 return math.max(lo,math.min(hi,math.floor(n)))
end
local function little(n, bytes)
 local out={}
 for i=1,bytes do out[i]=string.format('%02x',n%256); n=math.floor(n/256) end
 return table.concat(out)
end
function AWP.FloatHex(n)
 if n==0 then return '00000000' end
 assert(type(n)=='number' and n==n and math.abs(n)<1e30,'invalid value')
 local sign=n<0 and 2147483648 or 0
 if math.abs(n)<2^-126 then return little(sign+math.floor(math.abs(n)/2^-149+0.5),4) end
 local fraction,exponent=math.frexp(math.abs(n))
 local mantissa=math.floor((fraction*2-1)*8388608+0.5)
 if mantissa==8388608 then mantissa=0;exponent=exponent+1 end
 return little(sign+(exponent+126)*8388608+mantissa,4)
end
function AWP.Payload(ids,values)
 local a,b={},{}
 for i=1,4 do a[i]=little(ids[i] or 0,2);b[i]=AWP.FloatHex(values[i] or 0) end
 return table.concat(a)..table.concat(b).."00"
end
function AWP.WithPayload(link,payload)
 if type(link)~='string' or type(payload)~='string' or #payload~=50 or payload:find('[^%x]') then return nil end
 local header=link:match('|Hitem:([^|]+)|h')
 if not header then return nil end
 local fields={};for v in header:gmatch('%S+') do fields[#fields+1]=v end
 if #fields~=14 then return nil end
 fields[14]=payload
 return (link:gsub('|Hitem:[^|]+|h',function() return '|Hitem:'..table.concat(fields,' ')..'|h' end,1))
end

-- Lua 5.1 string.lower is byte-based; cover the cased client alphabets.
local upper='ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞŸĀĂĄĆĈĊČĎĐĒĔĖĘĚĜĞĠĢĤĦĨĪĬĮİĴĶĹĻĽŁŃŅŇŊŌŎŐŒŔŖŘŚŜŞŠŢŤŦŨŪŬŮŰŲŴŶŹŻŽẞАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ'
local lower='àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿāăąćĉċčďđēĕėęěĝğġģĥħĩīĭįiĵķĺļľłńņňŋōŏőœŕŗřśŝşšţťŧũūŭůűųŵŷźżžßабвгдеёжзийклмнопрстуфхцчшщъыьэюя'
local chars='[%z\1-\127\194-\244][\128-\191]*'
local folded,letters={},{}
for c in lower:gmatch(chars) do letters[#letters+1]=c end
local index=0;for c in upper:gmatch(chars) do index=index+1;folded[c]=letters[index] end
function AWP.SearchText(s)
 return (tostring(s or ''):gsub(chars,function(c)return folded[c] or (#c==1 and string.lower(c) or c) end):gsub('^%s+',''):gsub('%s+$',''))
end
function AWP.Matches(w,query,kind,quality)
 query=AWP.SearchText(query)
 return (not kind or kind==0 or w.kind==kind) and (not quality or quality==0 or w.quality==quality)
  and (query=='' or tostring(w.id)==query or string.find(AWP.SearchText(w.name),query,1,true)~=nil)
end
