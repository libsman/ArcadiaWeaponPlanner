-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
local P=AWP
local function L(k)return P.Label(k)end
local function name(c)return TEXT('Sys'..c.item..'_name')end
function P.ImportLink(link)
 local c=P.DecodeItem(link)
 if not c then AWPStatus:SetText(L('importFailed'));return false end
 P.baseline=P.CopyConfig(c);P.ApplyConfig(c)
 P.selected.name=P.selected.name or name(c)
 AWPFavoriteName:SetText(P.selected.name);P.Selection();P.Fields();P.Render();P.Rows()
 AWPImportHint:SetText(L('importedHint'));return true
end
function P.InstallImportHook()
 if P.importHookInstalled or type(ChatEdit_AddItemLink)~='function' then return end
 local original=ChatEdit_AddItemLink
 ChatEdit_AddItemLink=function(link,...)
  -- An active chat/link destination retains normal Shift-click behaviour.
  if IsShiftKeyDown() and AWPWindow and AWPWindow:IsVisible() and not AWPComparison:IsVisible() and not ITEMLINK_EDITBOX
   and not (AAC_AuctionFrame and AAC_AuctionFrame:IsVisible())
   and not (AuctionHubFrame and AuctionHubFrame:IsVisible())
   and not (ChatFrameEditBox and ChatFrameEditBox:IsVisible()) then
   if P.ImportLink(link) then return true end
  end
  return original(link,...)
 end
 P.importHookInstalled=true
end
local function tooltip(frame,c,link,x)
 if not P.PreviewTooltip(frame,c,P.comparisonExtras,link) then return false end;frame:SetScale(1)
 local scale=math.min(1,470/frame:GetHeight(),508/frame:GetWidth())
 frame:SetScale(scale);frame:ClearAllAnchors()
 frame:SetAnchor('TOPLEFT','TOPLEFT',AWPComparison:GetName(),x/scale,72/scale);frame:Show();return true
end
function P.Compare()
 if not P.baseline or not P.selected then return end
 local a=P.baseline;local b=P.CurrentConfig()
 local compatible=P.Item(a.item).kind==P.Item(b.item).kind
 local extras=compatible and a.extras or {}
 local leftLink,rightLink=P.ConfigLink(a,extras),P.ConfigLink(b,extras)
 if not leftLink or not rightLink then
  P.CloseComparison();AWPStatus:SetText(L('importFailed'));return false
 end
 AWPEditor:Hide();AWPComparison:Show();if P.EffectivenessField then P.EffectivenessField() end
 AWPCompareBack:SetText(L('back'));AWPCompareLeftTitle:SetText(L('imported')..': '..name(a))
 AWPCompareRightTitle:SetText(L('comparison')..': '..(AWPFavoriteName:GetText() or name(b)))
 AWPCompareNote:SetText(compatible and '' or L('differentTypes'))
 P.comparisonExtras=extras
 if not tooltip(AWPCompareLeft,a,leftLink,22) or not tooltip(AWPCompareRight,b,rightLink,565) then P.CloseComparison();AWPStatus:SetText(L('effectivenessUnavailable')) end
 P.comparisonExtras=nil
end
function P.CloseComparison()
 AWPComparison:Hide();AWPEditor:Show();if P.EffectivenessField then P.EffectivenessField() end;P.Render()
end
