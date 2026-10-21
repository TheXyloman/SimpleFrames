local _, SF = ...

-- All inspection of client values goes through this boundary. Secret values may
-- be passed to supported widgets, but never compared, formatted in Lua or keyed.
function SF:IsSecret(value)
  return issecretvalue and issecretvalue(value) or false
end

function SF:Readable(value)
  if not self:IsSecret(value) then
    return value
  end
end

function SF:IsCombatLocked()
  return InCombatLockdown and InCombatLockdown() or false
end

function SF:InitializeClient()
  local version, build, _, interface = GetBuildInfo()
  self.client = { version = version, build = build, interface = interface }
  if C_CurveUtil and C_CurveUtil.CreateCurve then
    self.percentCurve = C_CurveUtil.CreateCurve()
    self.percentCurve:AddPoint(0, 0)
    self.percentCurve:AddPoint(1, 100)
  end
end

function SF:Diagnose()
  local version, build, _, interface = GetBuildInfo()
  self:Print("version " .. self.version .. "; client " .. version .. "." .. build .. "; interface " .. interface)
  local checks = {
    { "secret values", issecretvalue },
    { "auras", C_UnitAuras and C_UnitAuras.GetAuraDataByIndex },
    { "aura stack display", C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount },
    { "spellbook", C_SpellBook and C_SpellBook.GetSpellBookItemInfo },
    { "health percentage", UnitHealthPercent },
    { "power percentage", UnitPowerPercent },
    { "curves", C_CurveUtil and C_CurveUtil.CreateCurve },
    { "secure macro API", C_Macro and C_Macro.RunMacroText },
  }
  for _, check in ipairs(checks) do
    self:Print(check[1] .. ": " .. (check[2] and "available" or "unavailable"))
  end
  self:Print("Combat-restricted aura classification is omitted; roster/layout edits wait until combat ends.")
  self:Print("API availability does not certify in-game behavior. See README testing checklist.")
end

function SF:SetVitalDisplay(bar, text, unit, kind, mode)
  local current, maximum, percent
  if kind == "health" then
    current, maximum = UnitHealth(unit), UnitHealthMax(unit)
    if UnitHealthPercent and self.percentCurve then
      percent = UnitHealthPercent(unit, true, self.percentCurve)
    end
  else
    current, maximum = UnitPower(unit), UnitPowerMax(unit)
    if UnitPowerPercent and self.percentCurve then
      percent = UnitPowerPercent(unit, nil, false, self.percentCurve)
    end
  end
  -- Only public values may be checked/clamped. Widgets accept secret numbers.
  if not self:IsSecret(current) then current = math.max(0, current or 0) end
  if not self:IsSecret(maximum) then maximum = math.max(1, maximum or 1) end
  bar:SetMinMaxValues(0, maximum)
  bar:SetValue(current)
  local hasPercent = self:IsSecret(percent) or percent ~= nil
  if not hasPercent and not self:IsSecret(current) and not self:IsSecret(maximum) then
    percent = current / maximum * 100
    hasPercent = true
  end
  if mode == "off" then
    text:SetText("")
  elseif mode == "raw" or not hasPercent then
    text:SetFormattedText("%.0f", current)
  elseif mode == "both" then
    text:SetFormattedText("%.0f %.0f%%", current, percent)
  else
    text:SetFormattedText("%.0f%%", percent)
  end
end

function SF:UpdateLowHealth(texture, unit, connected, dead)
  texture:Hide()
  texture:SetAlpha(1)
  -- Unknown connection/death state must not produce a misleading alert.
  if connected ~= true or dead ~= false then return end
  local threshold = self:Clamp(self.db.auras.lowHealthThreshold or 15, 0, 100)
  if UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve then
    if not self.lowHealthCurve or self.lowHealthCurveThreshold ~= threshold then
      local curve = C_CurveUtil.CreateCurve()
      curve:SetType(Enum.LuaCurveType.Step)
      curve:AddPoint(0, 1)
      curve:AddPoint(threshold / 100 + 0.000001, 0)
      curve:AddPoint(1, 0)
      self.lowHealthCurve, self.lowHealthCurveThreshold = curve, threshold
    end
    texture:SetAlpha(UnitHealthPercent(unit, true, self.lowHealthCurve))
    texture:Show()
  else
    local health, maximum = self:Readable(UnitHealth(unit)), self:Readable(UnitHealthMax(unit))
    if health and maximum and maximum > 0 and health / maximum * 100 <= threshold then texture:Show() end
  end
end

function SF:InvalidateSpellCache()
  self.knownSpells = nil
  self.spellSuggestionList = nil
  self.resurrectionSpellChecked = nil
  self.resurrectionSpellName = nil
end

local function normalize(text)
  text = tostring(text or "")
  return string.lower((text:gsub("^%s+", ""):gsub("%s+$", "")))
end

function SF:GetKnownSpells()
  if self.knownSpells then return self.knownSpells end
  local spells, seen = {}, {}
  local api = C_SpellBook
  if not api or not api.GetNumSpellBookSkillLines or not api.GetSpellBookSkillLineInfo
    or not api.GetSpellBookItemInfo or not Enum or not Enum.SpellBookSpellBank then return spells end
  local bank = Enum.SpellBookSpellBank.Player
  local function add(id, name, rank, baseID)
    if id and (not name or name == "") and C_Spell and C_Spell.RequestLoadSpellData then
      C_Spell.RequestLoadSpellData(id)
    end
    if not id or seen[id] or not name or name == "" then return end
    seen[id] = true
    spells[#spells + 1] = {
      id = id, baseID = baseID or id, name = name, rank = rank or "",
      display = rank and rank ~= "" and (name .. "(" .. rank .. ")") or name,
    }
  end
  for line = 1, api.GetNumSpellBookSkillLines() do
    local info = api.GetSpellBookSkillLineInfo(line)
    if info and not info.offSpecID then
      for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
        local item = api.GetSpellBookItemInfo(slot, bank)
        if item and not item.isPassive and not item.isOffSpec then
          if item.itemType == Enum.SpellBookItemType.Spell then
            add(item.spellID or item.actionID, item.name, item.subName, item.actionID)
          elseif item.itemType == Enum.SpellBookItemType.Flyout and GetFlyoutInfo and GetFlyoutSlotInfo then
            local _, _, count, known = GetFlyoutInfo(item.actionID)
            if known then
              for index = 1, count do
                local id, overrideID, isKnown, name = GetFlyoutSlotInfo(item.actionID, index)
                if isKnown then add(overrideID or id, name, nil, id) end
              end
            end
          end
        end
      end
    end
  end
  self.knownSpells = spells
  return spells
end

function SF:ResolveKnownSpell(query)
  local key = normalize(query)
  if key == "" then return nil end
  local spells = self:GetKnownSpells()
  -- Explicit ranks/IDs are exact. An unranked name resolves to the last learned
  -- rank in spellbook order; rank-qualified bindings remain untouched in storage.
  local match
  for _, spell in ipairs(spells) do
    if key == tostring(spell.id) or (spell.rank ~= "" and key == normalize(spell.display)) then return spell end
    if key == normalize(spell.name) then match = spell end
  end
  return match
end

function SF:GetSpellSuggestionList(refresh)
  if refresh then self:InvalidateSpellCache() end
  if not self.spellSuggestionList then
    local list, seen = {}, {}
    for _, spell in ipairs(self:GetKnownSpells()) do
      if not seen[spell.display] then
        seen[spell.display] = true
        list[#list + 1] = spell.display
      end
    end
    table.sort(list)
    self.spellSuggestionList = list
  end
  return self.spellSuggestionList
end

function SF:GetPlayerResurrectionSpell()
  if self.resurrectionSpellChecked then return self.resurrectionSpellName end
  self.resurrectionSpellChecked = true
  local _, class = UnitClass("player")
  local ids = self.resurrectionSpellIDs[self:Readable(class)] or {}
  for _, id in ipairs(ids) do
    local spellInfo = C_Spell and C_Spell.GetSpellInfo(id)
    local known = spellInfo and self:ResolveKnownSpell(spellInfo.name)
    if known then
      self.resurrectionSpellName = known.name
      return known.name
    end
  end
end

function SF:ReadAura(unit, index, filter)
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
  local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
  if self:IsSecret(aura) or not aura then return nil end
  local countText
  if C_UnitAuras.GetAuraApplicationDisplayCount and
    (self:IsSecret(aura.auraInstanceID) or aura.auraInstanceID) then
    countText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, aura.auraInstanceID, 2)
  else
    local count = self:Readable(aura.applications)
    countText = count and count > 1 and tostring(count) or ""
  end
  return {
    name = self:Readable(aura.name), icon = aura.icon, countText = countText,
    spellId = self:Readable(aura.spellId), debuffType = self:Readable(aura.dispelName),
    restrictedDispel = self:IsSecret(aura.dispelName),
  }
end

function SF:GetBindingStatus()
  local missing = {}
  for _, key in ipairs(self.clickCastBindingOrder) do
    local text = self:GetClickCastBinding(key)
    if text ~= "" and not self:ResolveKnownSpell(text) then missing[#missing + 1] = key end
  end
  if #missing > 0 then return "Unresolved bindings (kept, inactive): " .. table.concat(missing, ", ") end
  if not (C_Macro and C_Macro.RunMacroText) then return "Automatic resurrection unavailable: secure macro API missing." end
  return "Bindings apply to SimpleFrames only; changes wait until combat ends."
end
