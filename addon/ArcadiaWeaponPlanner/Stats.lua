-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
-- Wiki base ranges for unchanged attributes; current weapon payloads for
-- modern haste/final-damage IDs. Factor applies before the native tooltip.
AWP.Stats={};AWP.StatGroups={'common','attack','weapon','speed','defense','utility'}
local function add(id,max,group,family)
 AWP.Stats[#AWP.Stats+1]={id=id,max=max,group=group,family=family or id}
end
add(764,2,'common');add(730,10,'common');add(762,4.8,'common','final');add(761,4.8,'common','final')
add(134,4.8,'common','attack');add(171,4.8,'common','attack');add(44,4,'common');add(283,7.2,'common')
add(25,1540,'attack','flatdamage');add(191,1600,'attack','flatdamage');add(181,16,'attack')
add(7,3200,'attack');for id=161,165 do add(id,6,'attack','percentattribute') end
add(166,4.8,'attack','percentattribute');add(197,8,'attack','accuracy');add(199,8,'attack','accuracy')
for id=184,189 do add(id,4.8,'attack','element') end;add(240,4.8,'attack','element')
-- Percentage elemental magic power: native Inclusion IDs and wiki base range.
for id=45,50 do add(id,4.8,'elemental','element') end
add(37,7.2,'weapon');for _,id in ipairs({52,53,54,55,56,58,59,61,62,63,65,66,67,263,269,277}) do add(id,3.2,'weapon','weapondamage') end
add(205,4,'weapon');add(282,7.2,'weapon')
for _,id in ipairs({244,248,251,252,254,255,256,264}) do add(id,7.2,'weapon') end
for _,id in ipairs({23,51,68,69,70,71,74,75,76,77,78,79,80,81,82,83,265,279}) do add(id,-4,'speed','speed') end
add(13,10000,'defense','flatdefense');add(14,10000,'defense','flatdefense');add(135,6,'defense','defense');add(170,6,'defense','defense')
add(167,4,'defense');add(168,10,'defense');add(17,2000,'defense');add(196,2000,'defense');add(198,3.2,'defense');add(200,3.2,'defense')
add(142,-4.8,'defense','absorption');add(143,-4.8,'defense','absorption');add(207,-4.8,'defense');add(209,-8,'defense');add(276,-8,'defense');add(172,2.4,'defense')
for _,id in ipairs({139,140,141,214,215,216}) do add(id,12,'utility') end
for _,id in ipairs({260,261,262}) do add(id,30,'utility','resource') end
add(33,8,'utility');add(703,40,'utility');add(169,12,'utility');add(24,3.2,'utility')
add(210,10,'utility');add(211,20,'utility');add(230,80,'utility');add(144,4.8,'utility');add(149,6,'utility');add(150,1000,'utility');add(151,12,'utility');add(175,32,'utility')
function AWP.Stat(id) for _,s in ipairs(AWP.Stats) do if s.id==id then return s end end end
function AWP.MaxRoll(id,weapon)
 local s=AWP.Stat(id)
 return s and s.max*(weapon and weapon.factor or 1) or 0
end
function AWP.PenaltyRoll(id)
 local s=AWP.Stat(id);return id==0 and 0 or (s and s.max<0 and .1 or -.1)
end
