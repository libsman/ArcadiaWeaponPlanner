-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
-- Native Inclusion menu, read in client on 2026-11-25.
-- Common is a shortcut list; every entry also belongs to its normal category.
local P=AWP
P.StatGroups={'common','attribute','attack','damage','speed','elemental','survival','utility','exploration','progression','others','effectiveness'}
local groups={
 common={764,730,762,761,134,171,283},
 attribute={7,161,162,163,164,165,166,167,168,260,261,262},
 attack={134,171,197,199,181,283,732},
 damage={18,19,20,21,25,173,762,191,763,192,761,37,52,53,54,55,56,58,59,61,62,63,65,66,67,277,263,269,205,282,244,248,251,252,254,255,256,264,726,727,208},
 speed={23,51,68,69,70,71,74,75,76,77,78,79,80,81,82,83,279,265,728,733,764},
 elemental={44,45,46,47,48,49,50,240,184,185,186,187,188,189},
 survival={13,135,14,170,17,22,142,143,196,200,207,198,209,276,227,182,183,172},
 utility={139,140,141,33,214,215,216},
 exploration={703,169,24},progression={210,211,230},others={144,149,150,151,175},effectiveness={730}
}
function P.GroupIDs(group)
 local out={};for _,id in ipairs(groups[group] or {}) do if P.Stat(id) then out[#out+1]=id end end
 return out
end
