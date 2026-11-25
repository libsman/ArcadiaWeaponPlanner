-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
local P=AWP
function P.RegisterSettings()
 if type(AWP_Settings)~='table' then AWP_Settings={} end
 if type(AWP_Settings.personalEffectiveness)~='boolean' then AWP_Settings.personalEffectiveness=true end
 SaveVariables('AWP_Settings')
end
local function clean(s)return (tostring(s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''))end
function P.EffectivenessNumber(s)
 local n=tonumber((clean(s):gsub(',','.')):match('([%d%.]+)%s*%%'))
 if n and n>0 and n<100000 then return n/100 end
end
local function personal(frame)
 local label=clean(TEXT('SYS_TOTAL_DAEEFFECTIVENESS'))
 for i=1,100 do
  local left=_G[frame:GetName()..'TextLeft'..i]
  local right=_G[frame:GetName()..'TextRight'..i]
  if left and left:IsVisible() and clean(left:GetText())==label and right then
   return P.EffectivenessNumber(right:GetText()),right
  end
 end
end
function P.WithoutPersonalEffectiveness(c,factor)
 local result=P.CopyConfig(c)
 for i=1,4 do
  -- Effectiveness itself is not amplified by personal effectiveness.
  if result.ids[i]~=730 then result.values[i]=result.values[i]/factor end
 end
 return result
end
function P.PreviewTooltip(frame,c,extras,link)
 link=link or P.ConfigLink(c,extras)
 if not link then return false end
 frame:SetItemDB(c.item);frame:SetHyperLink(link)
 if not AWP_Settings or AWP_Settings.personalEffectiveness~=false then return true end
 local factor=personal(frame)
 if not factor then frame:Hide();return false end
 local neutral=P.ConfigLink(P.WithoutPersonalEffectiveness(c,factor),extras)
 if not neutral then frame:Hide();return false end
 frame:SetItemDB(c.item);frame:SetHyperLink(neutral)
 local _,value=personal(frame)
 if value then value:SetText('100.00%') end
 return true
end
function P.EffectivenessField()
 AWPEffectivenessLabel:SetText(P.Label('includePersonalEffectiveness'))
 AWPEffectiveness:SetChecked(not AWP_Settings or AWP_Settings.personalEffectiveness~=false)
 AWPEffectiveness:ClearAllAnchors()
 local comparing=AWPComparison and AWPComparison:IsVisible()
 AWPEffectiveness:SetAnchor('TOPLEFT','TOPLEFT','AWPWindow',comparing and 27 or 650,comparing and 37 or 43)
end
function P.SetEffectiveness(include)
 if not AWP_Settings then P.RegisterSettings() end
 AWP_Settings.personalEffectiveness=include==true
 P.EffectivenessField()
 if AWPComparison:IsVisible() then P.Compare() else P.Render() end
end
function P.ToggleEffectiveness()
 P.SetEffectiveness(AWP_Settings and AWP_Settings.personalEffectiveness==false)
end
function P.RefreshPending(elapsed)
 if not P.refreshPending then return end
 P.refreshElapsed=(P.refreshElapsed or 0)+(elapsed or 0)
 if P.refreshElapsed<.2 then return end
 P.refreshPending=false;P.refreshElapsed=0
 if AWPComparison:IsVisible() then P.Compare() else P.Render() end
end
