-- Run from the repository root with Lua 5.1: lua tests/run.lua
-- Widgets accept opaque secret values; all Lua inspection/arithmetic throws.
local count = 0
local function check(value, message)
  assert(value, message or "check failed")
  count = count + 1
end
local function equal(actual, expected, message)
  check(actual == expected, message or (tostring(actual) .. " ~= " .. tostring(expected)))
end
local combat = false
local secretValues = setmetatable({}, { __mode = "k" })
local function forbidden() error("attempt to inspect a secret value") end
local secretMeta = { __add=forbidden, __sub=forbidden, __div=forbidden, __mul=forbidden,
  __lt=forbidden, __le=forbidden, __concat=forbidden, __tostring=forbidden, __unm=forbidden }
local function secret()
  local v = setmetatable({}, secretMeta)
  secretValues[v] = true
  return v
end
function issecretvalue(v) return type(v) == "table" and secretValues[v] == true end
function InCombatLockdown() return combat end
function GetBuildInfo() return "1.60.1", "70532", "test fixture", 16001 end
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) messages[#messages+1] = text end }
SlashCmdList = {}
Enum = { SpellBookSpellBank = {Player=0}, SpellBookItemType = {Spell=1, Flyout=2, FutureSpell=3}, LuaCurveType={Step=1} }
local methods = {}
local function widget(name, parent, template)
  local w = setmetatable({ name=name, parent=parent, template=template, attributes={}, scripts={}, shown=true, width=160, height=38, points={}, level=1 }, {__index=methods})
  if template == "SecureActionButtonTemplate" then
    w.protected = true
    local p=parent
    while p do p.protected=true; p=p.parent end
  end
  return w
end
local function guard(w) assert(not (combat and w.protected), "protected frame mutation in combat") end
function CreateFrame(kind,name,parent,template)
  local w=widget(name,parent,template)
  if name then _G[name]=w end
  return w
end
function methods:SetAttribute(k,v) guard(self); self.attributes[k]=v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:SetParent(p) guard(self); self.parent=p end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:HookScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:CreateTexture(name) return widget(name,self) end
function methods:CreateFontString(name) return widget(name,self) end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text or "" end
function methods:SetFormattedText(fmt, ...) self.format=fmt; self.formatArgs={...}; self.text=nil end
function methods:Show() guard(self); self.shown=true end
function methods:Hide() guard(self); self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:SetSize(w,h) guard(self); self.width=w; self.height=h end
function methods:SetWidth(w) guard(self); self.width=w end
function methods:SetHeight(h) guard(self); self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetStringWidth() if issecretvalue(self.text) then return secret() end return #(self.text or "")*5 end
function methods:SetPoint(...) guard(self); self.points={...} end
function methods:ClearAllPoints() guard(self); self.points={} end
function methods:GetPoint() return "CENTER",UIParent,"CENTER",0,0 end
function methods:SetValue(v) self.value=v end
function methods:GetValue() return self.value or 1 end
function methods:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function methods:GetMinMaxValues() return self.minimum or 0,self.maximum or 100 end
function methods:GetFrameLevel() return self.level end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetTexture(v) self.texture=v end
function methods:SetAtlas(v) self.atlas=v end
function methods:GetFont() return "font",12,"" end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 100,100 end
function methods:HasFocus() return false end
function methods:GetChecked() return self.checked end
function methods:SetChecked(v) self.checked=v end
function methods:GetThumbTexture() return self.thumb end
function methods:SetThumbTexture(v) self.thumb=widget(nil,self) end
function methods:SetNormalTexture(v) self.normal=widget(nil,self) end
function methods:GetNormalTexture() return self.normal end
function methods:SetHighlightTexture(v) self.highlight=widget(nil,self) end
function methods:GetHighlightTexture() return self.highlight end
for _, name in ipairs({"SetAllPoints","SetVertexColor","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetStatusBarColor","SetStatusBarTexture","SetBlendMode","SetTexCoord","SetDrawLayer","SetTextColor","SetFont","SetJustifyH","SetJustifyV","SetWordWrap","SetFrameStrata","SetClampedToScreen","SetMovable","RegisterForDrag","RegisterForClicks","SetToplevel","SetAutoFocus","SetMaxLetters","SetNumeric","SetMultiLine","SetTextInsets","SetFontObject","SetOrientation","SetValueStep","SetObeyStepOnDrag","SetEnabled","Enable","Disable","ClearFocus","HighlightText","SetFocus","SetHitRectInsets","SetPushedTexture","SetDisabledTexture","SetButtonState","LockHighlight","UnlockHighlight"}) do
  methods[name]=function() end
end
function methods:EnableMouse() guard(self) end
function methods:StartMoving() guard(self) end
function methods:StopMovingOrSizing() guard(self) end
UIParent=widget("UIParent")
Minimap=widget("Minimap",UIParent)
UISpecialFrames={}
BackdropTemplateMixin={}
GameFontHighlightSmall=widget("GameFontHighlightSmall")
NORMAL_FONT_COLOR={r=1,g=1,b=1}
function GetCursorPosition() return 0,0 end
function IsShiftKeyDown() return true end
function GetMinimapShape() return "ROUND" end
function GetMicroIconForRole(role) return "roleicon-tiny-"..string.lower(role) end
C_Texture={GetAtlasInfo=function() return {} end}
local units={ player={name="Tester",guid="player-guid",class="PRIEST"}, party1={name="Friend",guid="friend-guid",class="MAGE"} }
function UnitExists(u) return units[u] ~= nil end
function UnitName(u) return units[u] and units[u].name end
function UnitGUID(u) return units[u] and units[u].guid end
function UnitClass(u) return "class", units[u] and units[u].class end
function UnitIsUnit(a,b) return a==b end
function UnitIsConnected(u) return units[u].connected ~= false end
function UnitIsDeadOrGhost(u) return units[u].dead == true end
function UnitGroupRolesAssigned() return "NONE" end
function GetPartyAssignment() return false end
function IsInRaid() return false end
local partySize=1
function IsInGroup() return partySize>0 end
function GetNumSubgroupMembers() return partySize end
function GetNumGroupMembers() return partySize+1 end
local health, maxHealth, power, maxPower=73,100,40,100
function UnitHealth() return health end
function UnitHealthMax() return maxHealth end
function UnitPower() return power end
function UnitPowerMax() return maxPower end
function UnitPowerType() return 0,"MANA" end
local raidIcon
function GetRaidTargetIndex() return raidIcon end
local curveMethods={}
function curveMethods:SetType(t) self.kind=t end
function curveMethods:AddPoint(x,y) self[#self+1]={x,y} end
function curveMethods:Evaluate(x)
  if issecretvalue(x) then return secret() end
  local last=self[1]
  for i=2,#self do
    local p=self[i]
    if x<p[1] then
      if self.kind == Enum.LuaCurveType.Step then return last[2] end
      return last[2]+(p[2]-last[2])*(x-last[1])/(p[1]-last[1])
    end
    last=p
  end
  return last[2]
end
C_CurveUtil={CreateCurve=function() return setmetatable({}, {__index=curveMethods}) end}
function UnitHealthPercent(u,predicted,curve)
  local ratio=issecretvalue(health) and secret() or health/math.max(1,maxHealth)
  return curve and curve:Evaluate(ratio) or ratio
end
function UnitPowerPercent(u,t,unmodified,curve)
  local ratio=issecretvalue(power) and secret() or power/math.max(1,maxPower)
  return curve and curve:Evaluate(ratio) or ratio
end
local spellItems={
 {spellID=2050,actionID=2050,name="Heal",subName="Rank 1",itemType=1},
 {spellID=2052,actionID=2052,name="Heal",subName="Rank 2",itemType=1},
 {spellID=2006,actionID=2006,name="Resurrection",subName="Rank 1",itemType=1},
 {spellID=999,name="Passive",itemType=1,isPassive=true},
 {spellID=1000,name="Unlearned",itemType=3},
 {spellID=1001,name="Offspec",itemType=1,isOffSpec=true},
}
C_SpellBook={GetNumSpellBookSkillLines=function() return 1 end,
 GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=#spellItems} end,
 GetSpellBookItemInfo=function(slot,bank) equal(bank,0);return spellItems[slot] end}
C_Spell={GetSpellInfo=function(id) return {name=id==2006 and "Resurrection" or "unknown"} end}
C_Macro={RunMacroText=function() error("must run only through client secure execution") end}
C_ClickBindings={ExecuteBinding=function() error("must not invoke global click bindings") end}
local auraData={HELPFUL={},HARMFUL={}}
local stackText="2"
C_UnitAuras={GetAuraDataByIndex=function(u,i,filter) return auraData[filter][i] end,
 GetAuraApplicationDisplayCount=function(u,id,min) equal(min,2);return stackText end}
local SF={}
for line in io.lines("SimpleFrames/SimpleFrames.toc") do
  if line:match("%.lua$") then assert(loadfile("SimpleFrames/"..line))("SimpleFrames",SF) end
end
SF:OnAddonLoaded()
check(SF.anchor and SF.optionsFrame and SF.petAnchor and SF.priorityAnchor, "full UI initializes")
equal(SF.buttons[1].template,"SecureActionButtonTemplate")
equal(SF.buttons[1]:GetAttribute("useOnKeyDown"),false)
equal(SF.buttons[1]:GetAttribute("shift-type3"),"")
equal(SF:ResolveKnownSpell(" Heal ").id,2052)
equal(SF:ResolveKnownSpell("Heal(Rank 1)").id,2050)
equal(SF:ResolveKnownSpell("2050").id,2050)
equal(SF:ResolveKnownSpell("Passive"),nil)
equal(SF:ResolveKnownSpell("Unlearned"),nil)
equal(#SF:GetSpellSuggestionList(),3)
SF:SetClickCastBinding("L","Heal(Rank 1)")
local button=SF.buttons[1]
check(button:GetAttribute("macrotext1"):find("Heal%(Rank 1%)") ~= nil)
check(button:GetAttribute("macrotext1"):find("help,dead%] Resurrection") ~= nil)
SF:SetClickCastBinding("SL","")
equal(button:GetAttribute("shift-type1"),"", "blank modifier cannot inherit left click")
SF:SetClickCastBinding("R","Not learned; /run bad()")
equal(button:GetAttribute("type2"),"")
equal(SF:GetClickCastBinding("R"),"Not learned; /run bad()")
check(SF:GetBindingStatus():find("R",1,true)~=nil)
SF:SetClickCastBinding("R","")
local originalMacro=C_Macro
C_Macro=nil
SF:ApplyAllClickCastBindings()
equal(button:GetAttribute("spell1"),2050)
C_Macro=originalMacro
SF:ApplyAllClickCastBindings()
-- All four text modes must accept opaque secrets without a Lua operation.
health,maxHealth,power,maxPower=secret(),secret(),secret(),secret()
units.player.name=secret()
raidIcon=secret()
for _,mode in ipairs({"raw","percent","both","off"}) do
 SF.db.text.health=mode; SF.db.text.power=mode
 SF:UpdateButtonUnit(button,"player")
 check(issecretvalue(button.health.value))
 check(issecretvalue(button.power.value))
 if mode=="off" then equal(button.healthText.text,"") else check(button.healthText.format~=nil) end
end
check(issecretvalue(button.lowHealth.alpha))
health,maxHealth,power,maxPower=15,100,0,0
units.player.name="Tester";raidIcon=nil
SF:UpdateButtonUnit(button,"player")
equal(button.lowHealth.alpha,1)
health=16
SF:UpdateButtonUnit(button,"player")
equal(button.lowHealth.alpha,0)
units.player.dead=true
SF:UpdateButtonUnit(button,"player")
equal(button.healthText.text,"DEAD")
check(not button.lowHealth.shown)
units.player.dead=false
-- Restricted aura IDs/names/stack counts stay display-only.
stackText=secret()
auraData.HELPFUL={{icon=secret(),auraInstanceID=secret(),applications=secret(),name=secret(),spellId=secret(),dispelName=secret()}}
auraData.HARMFUL={{icon=100,auraInstanceID=7,name="Bash",spellId=5211,dispelName="Magic"}}
SF.db.auras.mode="both"
SF:UpdateAuraIndicators(button,"player")
check(button.buffIcons[1].shown)
check(issecretvalue(button.buffIcons[1].count.text))
check(button.stunText.shown)
check(button.debuffBorder[1].shown)
auraData={HELPFUL={},HARMFUL={}}
SF:UpdateAuraIndicators(button,"player")
check(not button.buffIcons[1].shown and not button.debuffIcons[1].shown)
check(not button.stunText.shown and not button.debuffBorder[1].shown)
-- Profiles are deep copies and do not delete unrecognized binding text.
SF.db.clickCast.bindings.R="Future ability"
SF:SaveProfile("Port test")
SF.db.layout.width=222
SF:LoadProfile("Port test")
equal(SF.db.layout.width,160)
equal(SF.db.clickCast.bindings.R,"Future ability")
local originalDB=SF.db
SF.profileDB.profiles["Port test"].layout.width=190
combat=true
SF:LoadProfile("Port test")
check(SF.db==originalDB)
check(SF.pendingDatabase~=nil)
SF:SetPreviewMode("raid")
equal(SF.db.preview.mode,"off")
SF.db.locked=true; SF:ApplyLockState()
SF:RestoreFramePosition(SF.anchor,{x=33,y=44})
SF:OnOptionChanged(false)
SF:ApplyDatabaseState()
SF:ApplyPendingProtected() -- must not drain during combat
check(SF.pendingDatabase~=nil)
-- Roster event while locked must repaint actual occupant, including priority.
combat=false
SF:TogglePriorityForButton(SF.buttons[2])
combat=true
units.party1.name="Replacement";units.party1.guid="replacement-guid";units.party1.class="WARRIOR"
SF:OnRosterEvent()
equal(SF.buttons[2].nameText.text,"Replacement")
equal(SF.priorityButtons[1].nameText.text,"Replacement (changed)")
SF:SetClickCastBinding("SL","Heal")
check(SF.pendingClickCast)
spellItems[2].subName="Rank 3"
SF:OnEvent("SPELLS_CHANGED")
equal(SF:ResolveKnownSpell("Heal(Rank 3)").id,2052)
combat=false
SF:OnEvent("PLAYER_REGEN_ENABLED")
equal(SF.db.layout.width,190)
equal(SF.db.preview.mode,"raid")
check(not SF.pendingDatabase and not SF.pendingProtected and not SF.pendingClickCast)
equal(#SF.roster,40)
SF:SetPreviewMode("off")
equal(SF.buttons[1]:GetAttribute("unit"),"player")
-- Reset preserves the active configuration until the combat boundary.
combat=true
originalDB=SF.db
SF:ResetDatabase()
check(SF.db==originalDB)
combat=false
SF:ApplyPendingProtected()
equal(SF.db.layout.width,160)
-- Late Blizzard frames are hidden, then restored without spurious unit watches.
PartyFrame=widget("PartyFrame",UIParent)
local watches=0
function RegisterUnitWatch() watches=watches+1 end
function UnitWatchRegistered() return false end
SF.eventFrame.scripts.OnEvent(SF.eventFrame,"ADDON_LOADED","Blizzard_PartyFrame")
check(PartyFrame.parent==SF.hiddenParent)
PartyFrame:Hide() -- Blizzard updates visibility while its parent is hidden.
SF.db.hideBlizzard=false;SF:ApplyBlizzardFrames()
check(PartyFrame.parent==UIParent)
check(not PartyFrame:IsShown(),"restoration must preserve current Blizzard visibility")
equal(watches,0)
local before=#messages
SF:HandleSlash("diagnose")
check(#messages>before)
for i=before+1,#messages do check(not messages[i]:find("Tester",1,true),"diagnostics must exclude identity") end

-- Default aura bounds must sit below the health text, above the power bar.
SF:ApplyButtonStyle(SF.buttons[1])
local styled=SF.buttons[1]
local textBottom=styled.health.height/2+styled.healthText.points[5]-SF.db.text.healthFontSize/2
local buffTop=styled.buffIcons[1].points[5]+styled.buffIcons[1].height
local debuffTop=styled.debuffIcons[1].points[5]+styled.debuffIcons[1].height
check(textBottom>buffTop and textBottom>debuffTop,"default auras must not overlap health text")
check(styled.buffIcons[1].points[2]==styled.health and styled.debuffIcons[1].points[2]==styled.health)
-- A real 40-member roster, including role grouping and unit assignments.
local oldRaid,oldCount=IsInRaid,GetNumGroupMembers
IsInRaid=function() return true end
GetNumGroupMembers=function() return 40 end
GetRaidRosterInfo=function(i) return "Raider"..i,0,math.floor((i-1)/5)+1,60,"Priest","PRIEST",nil,true,false,nil,false,i%5==0 and "HEALER" or "DAMAGER" end
for i=1,40 do units["raid"..i]={name="Raider"..i,guid="raid-guid-"..i,class="PRIEST"} end
SF:RefreshRoster()
equal(#SF.roster,40)
check(SF.buttons[5].roleIcon.shown, "raid roster roles must survive live-data refresh")
equal(SF:GetUnitRole("raid5"),"HEALER")
for i=1,40 do equal(SF.buttons[i]:GetAttribute("unit"),"raid"..i);equal(SF.buttons[i].nameText.text,"Raider"..i) end
IsInRaid,GetNumGroupMembers=oldRaid,oldCount
SF:RefreshRoster()
-- Cache refresh discovers learned spells and localized resurrection names.
spellItems[#spellItems+1]={spellID=3000,actionID=3000,name="New heal",subName="",itemType=1}
SF:OnEvent("SPELLS_CHANGED")
equal(SF:ResolveKnownSpell("New heal").id,3000)
spellItems[3].name="Auferstehung"
C_Spell.GetSpellInfo=function(id) return {name=id==2006 and "Auferstehung" or "unknown"} end
SF:InvalidateSpellCache()
equal(SF:GetPlayerResurrectionSpell(),"Auferstehung")
-- Pet unit replacement must never keep the old owner's class/name.
units.pet={name="Pet",guid="pet-guid",class="WARRIOR"}
SF:RefreshPetFrame()
equal(SF.petButtons[1].nameText.text,"Pet")
combat=true
units.pet.name="New pet";units.pet.guid="new-pet-guid"
SF:OnEvent("UNIT_PET","player")
equal(SF.petButtons[1].nameText.text,"New pet")
units.pet=nil
SF:OnEvent("UNIT_PET","player")
equal(SF.petButtons[1].nameText.text,"")
combat=false
SF:ApplyPendingProtected()
check(not SF.petAnchor.shown)
-- Every options tab can refresh and display the unresolved binding notice.
SF:SetClickCastBinding("R","Future ability")
for key in pairs(SF.optionPanels) do SF:ShowOptionsTab(key);equal(SF.activeOptionsTab,key) end
local foundWarning=false
for _,control in ipairs(SF.optionControls) do
 if control.text and type(control.text)=="string" and control.text:find("Unresolved bindings",1,true) then foundWarning=true end
end
check(foundWarning,"binding status must be refreshed using the options control interface")
-- A profile/reset selected after a queued preview wins over that preview.
combat=true
SF:SetPreviewMode("raid")
SF:ResetDatabase()
equal(SF.pendingPreviewMode,nil)
combat=false
SF:ApplyPendingProtected()
equal(SF.db.preview.mode,"off")
-- Initialization itself is deferred on a reload in combat.
local fresh={}
for line in io.lines("SimpleFrames/SimpleFrames.toc") do
 if line:match("%.lua$") then assert(loadfile("SimpleFrames/"..line))("SimpleFrames",fresh) end
end
combat=true
fresh:OnAddonLoaded()
check(fresh.pendingInitialize and not fresh.anchor)
combat=false
fresh:OnEvent("PLAYER_REGEN_ENABLED")
check(fresh.anchor and not fresh.pendingInitialize)
print("PASS: "..count.." assertions (Lua ".._VERSION..")")
