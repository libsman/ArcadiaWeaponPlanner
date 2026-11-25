-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2026 Blackkid
local P=AWP
local lang=string.upper(tostring(GetLanguage and GetLanguage() or 'EN'))
lang=({ENEU='EN',ENUS='EN',ZH='CN',ZH_TW='TW',JA='JP',KO='KR'})[lang] or lang
P.L=AWPLocales[lang] or AWPLocales.EN
P.offset=0;P.kind=0;P.quality=0;P.mode='catalog';P.ids={764,730,762,197};P.values={3,15,7.2,-.1};P.plus=20;P.tier=17;P.editing=false
local function label(k)return P.L[k] or AWPLocales.EN[k] or k end
P.Label=label
function P.StatName(id) if id==0 then return label('none') end return (TEXT('SYS_WEAREQTYPE_'..id):gsub('^%% *','')) end
function P.KindName(id)
 if id==0 then return label('all') end
 if id==101 then return TEXT('SYS_ARMORTYPE_06') end
 if id==102 then return TEXT('SYS_ARMORTYPE_05') end
 return TEXT(string.format('SYS_WEAPON_TYPE%02d',id))
end
function P.Search()
 if not AWPWindow or not AWPWindow:IsVisible() then return end
 local q=P.SearchText(AWPSearch:GetText());P.matches={};P.offset=0
 for _,w in ipairs(P.Weapons) do
  w.name=w.name or TEXT('Sys'..w.id..'_name')
  if P.mode=='catalog' and P.Matches(w,q,P.kind,P.quality) then P.matches[#P.matches+1]={weapon=w,name=w.name} end
 end
 if P.mode=='favorites' then for _,f in ipairs(P.Favorites()) do
  local w=P.Item(f.item)
  if q=='' or string.find(P.SearchText(f.name..' '..w.name),q,1,true) or tostring(w.id)==q then P.matches[#P.matches+1]={weapon=w,favorite=f,name=f.name} end
 end end
 table.sort(P.matches,function(a,b)return a.name<b.name end);P.Rows()
end
function P.Rows()
 local count=#(P.matches or {});P.offset=math.max(0,math.min(P.offset,math.max(0,count-12)))
 for i=1,12 do
  local b=_G['AWPRow'..i];local entry=P.matches[P.offset+i];b.entry=entry
  if entry then
   local w=entry.weapon
   local t=_G[b:GetName()..'Text'];t:SetText(entry.name);t:SetColor(GetItemQualityColor(w.quality))
   local image=GetObjectInfo(w.id,'imageid');local texture=image and GetObjectInfo(image,'actfield')
   _G[b:GetName()..'Icon']:SetTexture(texture or 'Interface/Icons/INV_Misc_QuestionMark')
   local selected=entry.favorite and P.favoriteID==entry.favorite.id or (not entry.favorite and P.selected and P.selected.id==w.id)
   if selected then b:LockHighlight() else b:UnlockHighlight() end
   b:Show()
  else b:Hide() end
 end
 AWPCount:SetText(count==0 and label(P.mode=='favorites' and 'emptyFavorites' or 'empty') or (count..' '..label(P.mode=='favorites' and 'favorites' or 'results')..' | '..(P.offset+1)..'-'..math.min(count,P.offset+12)))
 AWPPrevious:SetEnable(P.offset>0);AWPNext:SetEnable(P.offset+12<count)
end
function P.Scroll(delta)P.offset=P.offset-delta*3;P.Rows()end
function P.Page(delta)P.offset=P.offset+delta*12;P.Rows()end
function P.Select(w)
 P.selected=w;P.favoriteID=nil;P.extras=nil;AWPFavoriteName:SetText(w.name);P.Selection();P.Maximum();P.Rows()
end
function P.Selection()
 if not P.selected then return end
 AWPSelection:SetText(P.selected.name);AWPSelection:SetColor(GetItemQualityColor(P.selected.quality))
 AWPDelete:SetEnable(P.favoriteID~=nil);AWPUndo:SetEnable(P.deletedFavorite~=nil)
 if AWPCompareButton then AWPCompareButton:SetEnable(P.baseline~=nil) end
end
function P.SelectEntry(entry)
 if not entry then return end
 if entry.favorite then
  if P.LoadFavorite(entry.favorite.id) then AWPFavoriteName:SetText(entry.favorite.name);P.Selection();P.Fields();P.Render();P.Rows() end
 else P.Select(entry.weapon) end
end
function P.Mode(mode)
 P.mode=mode;P.kind=0;P.quality=0;AWPSearch:SetText('');P.FilterFields();P.Search()
 if mode=='favorites' then
  AWPType:Hide();AWPRarity:Hide();AWPTypeLabel:Hide();AWPRarityLabel:Hide();AWPFavoriteHint:Show()
 else AWPType:Show();AWPRarity:Show();AWPTypeLabel:Show();AWPRarityLabel:Show();AWPFavoriteHint:Hide() end
 if mode=='catalog' then AWPCatalogTab:LockHighlight();AWPFavoritesTab:UnlockHighlight() else AWPFavoritesTab:LockHighlight();AWPCatalogTab:UnlockHighlight() end
end
function P.SaveCurrent()
 if P.SaveFavorite(AWPFavoriteName:GetText()) then P.Selection();P.Search();AWPStatus:SetText(label('saved')) else AWPStatus:SetText(label('enterName')) end
end
function P.DeleteCurrent()
 if P.DeleteFavorite(P.favoriteID) then P.Selection();P.Search();AWPStatus:SetText(label('removed')) end
end
function P.UndoCurrent()
 if P.UndoFavoriteDelete() then P.Selection();P.Search();AWPStatus:SetText(label('restored')) end
end
function P.Allowed(id,slot)
 if id==0 then return true end
 local s=P.Stat(id)
 for i=1,4 do if i~=slot then
  local other=P.Stat(P.ids[i]);if P.ids[i]==id or (s and other and s.family=='attack' and other.family=='attack') then return false end
 end end
 return true
end
function P.Menu(slot)
 local level=UIDROPDOWNMENU_MENU_LEVEL or 1
 if level==1 then
  UIDropDownMenu_AddButton({text=label('none'),func=function()P.Choose(slot,0)end},level)
  for _,group in ipairs(P.StatGroups) do UIDropDownMenu_AddButton({text=label(group),value=group,hasArrow=true,notCheckable=true},level) end
 else
  for _,id in ipairs(P.GroupIDs(UIDROPDOWNMENU_MENU_VALUE)) do
   local id=id
   UIDropDownMenu_AddButton({text=P.StatName(id),checked=P.ids[slot]==id,disabled=not P.Allowed(id,slot),func=function()P.Choose(slot,id)end},level)
  end
 end
end
function P.Choose(slot,id)
 if not P.Allowed(id,slot) then return end
 P.ids[slot]=id;P.values[slot]=slot==4 and P.PenaltyRoll(id) or P.MaxRoll(id,P.selected)
 P.Fields();P.Render()
end
function P.FilterMenu(which)
 local choices=which=='kind' and {0,1,2,3,4,5,6,7,8,9,10,11,12,13,21,22,101,102} or {0,3,7,9}
 for _,id in ipairs(choices) do
  local value=id;local name=which=='kind' and P.KindName(id) or label(({[0]='all',[3]='purple',[7]='red',[9]='gold'})[id])
  local info={text=name,checked=P[which]==id,func=function()P[which]=value;P.FilterFields();P.Search()end}
  if which=='quality' and id~=0 then info.textR,info.textG,info.textB=GetItemQualityColor(id) end
  UIDropDownMenu_AddButton(info)
 end
end
function P.FilterFields()
 UIDropDownMenu_SetText(AWPType,P.KindName(P.kind));UIDropDownMenu_SetText(AWPRarity,label(({[0]='all',[3]='purple',[7]='red',[9]='gold'})[P.quality]))
end
function P.Reset()P.kind=0;P.quality=0;AWPSearch:SetText('');P.FilterFields();P.Search()end
function P.Fields()
 P.filling=true
 for i=1,4 do
  UIDropDownMenu_SetText(_G['AWPStat'..i],P.StatName(P.ids[i]));_G['AWPValue'..i]:SetText(string.format('%.9g',P.values[i]))
  if P.editing then _G['AWPValue'..i]:Show() else _G['AWPValue'..i]:Hide() end
 end
 if P.editing then AWPBaseLabel:Show() else AWPBaseLabel:Hide() end
 AWPPlus:SetText(tostring(P.plus));AWPTier:SetText(tostring(P.tier));AWPEdit:SetText(label(P.editing and 'done' or 'edit'));P.filling=false
end
function P.Edit()P.editing=not P.editing;P.Fields()end
function P.Changed(field)
 if P.filling then return end
 if not field or field==AWPPlus then P.plus=P.Number(AWPPlus:GetText(),P.plus,0,30) end
 if not field or field==AWPTier then P.tier=P.Number(AWPTier:GetText(),P.tier,1,20) end
 for i=1,4 do if not field or field==_G['AWPValue'..i] then
  local v=tonumber(((_G['AWPValue'..i]:GetText() or ''):gsub(',','.')));if v and v==v and math.abs(v)<=100000 then P.values[i]=v end
 end end
 P.Render()
end
function P.Maximum()
 for i=1,4 do if P.ids[i]==0 or P.Stat(P.ids[i]) then P.values[i]=i==4 and P.PenaltyRoll(P.ids[i]) or P.MaxRoll(P.ids[i],P.selected) end end
 P.Fields();P.Render()
end
function P.Render()
 if not P.selected then return end
 for i=1,4 do if not P.Allowed(P.ids[i],i) then AWPStatus:SetText(label('duplicate'));AWPTooltip:Hide();return end end
 local w=P.selected
 local link=P.ConfigLink(P.CurrentConfig(),P.extras)
 if not link then AWPStatus:SetText(label('empty'));AWPTooltip:Hide();return end
 -- Native hyperlink reuse can retain old corruption when only field14 changes.
 -- Reset the preview source before parsing the new payload (verified in client).
 P.link=link;AWPTooltip:SetItemDB(w.id);AWPTooltip:SetHyperLink(link);AWPTooltip:SetScale(1)
 local scale=math.min(1,525/AWPTooltip:GetHeight(),425/AWPTooltip:GetWidth());AWPTooltip:SetScale(scale)
 AWPTooltip:ClearAllAnchors();AWPTooltip:SetAnchor('TOPLEFT','TOPLEFT',AWPWindow:GetName(),650/scale,48/scale);AWPTooltip:Show();AWPStatus:SetText('')
end
function P.Show()if AWPWindow:IsVisible() then AWPWindow:Hide() else AWPWindow:Show() end end
function P.OnShow()
 if AWPComparison then AWPComparison:Hide() end
 if AWPEditor then AWPEditor:Show() end
 if P.InstallImportHook then P.InstallImportHook() end
 AWPWindow:SetFrameStrata('HIGH');AWPTooltip:SetFrameStrata('HIGH')
 AWPTitle:SetText('Arcadia Weapon Planner by Blackkid - '..P.version)
 for _,pair in ipairs({{'AWPSearchLabel','search'},{'AWPTypeLabel','type'},{'AWPRarityLabel','rarity'},{'AWPPlusLabel','plus'},{'AWPTierLabel','tier'},{'AWPStatsLabel','stats'},{'AWPNegative','negative'},{'AWPBaseLabel','base'},{'AWPFavoriteLabel','favoriteName'},{'AWPFavoriteHint','favoriteHint'},{'AWPCatalogTab','catalog'},{'AWPFavoritesTab','favorites'},{'AWPSave','save'},{'AWPDelete','delete'},{'AWPUndo','undo'}}) do _G[pair[1]]:SetText(label(pair[2])) end
 AWPMax:SetText(label('max'));AWPReset:SetText(label('reset'));AWPPrevious:SetText('<');AWPNext:SetText('>')
 AWPImportHint:SetText(label(P.baseline and 'importedHint' or 'importHint'));AWPCompareButton:SetText(label('compare'))
 P.Mode(P.mode);P.Fields()
 if not P.selected then for _,w in ipairs(P.Weapons) do if w.id==1210893 then P.Select(w);break end end else P.Selection();P.Render() end
end
SLASH_ARCADIAWEAPONPLANNER1='/awp';SlashCmdList['ARCADIAWEAPONPLANNER']=P.Show
