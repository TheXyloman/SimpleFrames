local _, SF = ...

SF.stunSpellIds = {
  [408] = true,
  [853] = true,
  [1833] = true,
  [5211] = true,
  [5588] = true,
  [5589] = true,
  [6798] = true,
  [7922] = true,
  [8983] = true,
  [9005] = true,
  [10308] = true,
  [12355] = true,
  [15269] = true,
  [20253] = true,
  [20549] = true,
  [20614] = true,
  [20615] = true,
  [22570] = true,
  [25273] = true,
  [25274] = true,
  [27006] = true,
  [30283] = true,
  [30413] = true,
  [30414] = true,
}

SF.silenceSpellIds = {
  [1330] = true,
  [15487] = true,
  [18425] = true,
  [18469] = true,
  [18498] = true,
  [24259] = true,
  [25046] = true,
  [28730] = true,
  [30849] = true,
  [34490] = true,
}

SF.stunNames = {
  ["Bash"] = true,
  ["Blackout"] = true,
  ["Charge Stun"] = true,
  ["Cheap Shot"] = true,
  ["Concussion Blow"] = true,
  ["Hammer of Justice"] = true,
  ["Impact"] = true,
  ["Intercept Stun"] = true,
  ["Kidney Shot"] = true,
  ["Maim"] = true,
  ["Pounce"] = true,
  ["Shadowfury"] = true,
  ["War Stomp"] = true,
}

SF.silenceNames = {
  ["Arcane Torrent"] = true,
  ["Counterspell - Silenced"] = true,
  ["Garrote - Silence"] = true,
  ["Improved Kick"] = true,
  ["Improved Shield Bash"] = true,
  ["Silence"] = true,
  ["Silencing Shot"] = true,
  ["Spell Lock"] = true,
}

local debuffPriority = {
  Magic = 4,
  Curse = 3,
  Poison = 2,
  Disease = 1,
}

function SF:ShouldShowBuffs()
  local mode = self.db and self.db.auras and self.db.auras.mode or "both"
  return mode == "both" or mode == "buffs"
end

function SF:ShouldShowDebuffs()
  local mode = self.db and self.db.auras and self.db.auras.mode or "both"
  return mode == "both" or mode == "debuffs"
end

local function readAura(unit, index, filter)
  if not UnitAura then
    return nil
  end
  return UnitAura(unit, index, filter)
end

function SF:ScanUnitAuras(unit)
  local result = {
    buffs = {},
    debuffs = {},
    debuffType = nil,
    stunned = false,
    silenced = false,
  }

  if not unit or not UnitExists(unit) then
    return result
  end

  local showBuffs = self:ShouldShowBuffs()
  local showDebuffs = self:ShouldShowDebuffs()
  local maxBuffs = self.db.auras.maxBuffs or 0
  local maxDebuffs = self.db.auras.maxDebuffs or 0

  if showBuffs and maxBuffs > 0 then
    local count = 0
    for i = 1, 40 do
      local name, icon, stacks, dispelType, duration, expirationTime, source, _, _, spellId = readAura(unit, i, "HELPFUL")
      if not name then
        break
      end
      count = count + 1
      result.buffs[count] = {
        name = name,
        icon = icon,
        count = stacks,
        duration = duration,
        expirationTime = expirationTime,
        source = source,
        spellId = spellId,
        debuffType = dispelType,
      }
      if count >= maxBuffs then
        break
      end
    end
  end

  if showDebuffs or (self.db.auras and self.db.auras.showCrowdControl) then
    local count = 0
    local selectedPriority = 0
    for i = 1, 40 do
      local name, icon, stacks, dispelType, duration, expirationTime, source, _, _, spellId = readAura(unit, i, "HARMFUL")
      if not name then
        break
      end

      if showDebuffs and count < maxDebuffs then
        count = count + 1
        result.debuffs[count] = {
          name = name,
          icon = icon,
          count = stacks,
          duration = duration,
          expirationTime = expirationTime,
          source = source,
          spellId = spellId,
          debuffType = dispelType,
        }
      end

      if dispelType then
        local priority = debuffPriority[dispelType] or 0
        if priority > selectedPriority then
          selectedPriority = priority
          result.debuffType = dispelType
        end
      elseif not result.debuffType then
        result.debuffType = "none"
      end

      if self.db.auras and self.db.auras.showCrowdControl then
        if (spellId and self.stunSpellIds[spellId]) or (name and self.stunNames[name]) then
          result.stunned = true
        end
        if (spellId and self.silenceSpellIds[spellId]) or (name and self.silenceNames[name]) then
          result.silenced = true
        end
      end
    end
  end

  return result
end

function SF:GetDemoAuras(entry)
  local result = {
    buffs = {},
    debuffs = {},
    debuffType = entry and entry.debuffType or nil,
    stunned = entry and entry.stunned or false,
    silenced = entry and entry.silenced or false,
  }

  if not entry then
    return result
  end

  if self:ShouldShowBuffs() then
    local maxBuffs = self.db.auras.maxBuffs or 0
    for i = 1, maxBuffs do
      result.buffs[i] = {
        name = "Demo Buff",
        icon = i == 1 and "Interface\\Icons\\Spell_Holy_Renew" or "Interface\\Icons\\Spell_Nature_Regeneration",
        count = i == 1 and 1 or 0,
      }
    end
  end

  if self:ShouldShowDebuffs() and entry.debuffType then
    local maxDebuffs = self.db.auras.maxDebuffs or 0
    for i = 1, maxDebuffs do
      result.debuffs[i] = {
        name = entry.debuffType,
        icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion",
        count = 0,
        debuffType = entry.debuffType,
      }
    end
  end

  return result
end

function SF:UpdateAuraIcon(iconFrame, aura)
  if not iconFrame then
    return
  end

  if not aura or not aura.icon then
    iconFrame:Hide()
    return
  end

  iconFrame.icon:SetTexture(aura.icon)
  if aura.count and aura.count > 1 then
    iconFrame.count:SetText(aura.count)
  else
    iconFrame.count:SetText("")
  end
  iconFrame:Show()
end

function SF:UpdateAuraIndicators(button, unit, entry)
  if not button then
    return
  end

  local auras
  if entry and entry.isDemo then
    auras = self:GetDemoAuras(entry)
  else
    auras = self:ScanUnitAuras(unit)
  end

  for i = 1, #button.buffIcons do
    self:UpdateAuraIcon(button.buffIcons[i], auras.buffs[i])
  end

  for i = 1, #button.debuffIcons do
    self:UpdateAuraIcon(button.debuffIcons[i], auras.debuffs[i])
  end

  if auras.debuffType and self:ShouldShowDebuffs() then
    local color = self.debuffColors[auras.debuffType] or self.debuffColors.none
    self:SetLinesColor(button.debuffBorder, color.r, color.g, color.b, color.a)
    self:SetLinesShown(button.debuffBorder, true)
  else
    self:SetLinesShown(button.debuffBorder, false)
  end

  if self.db.auras.showCrowdControl and auras.stunned then
    button.stunText:Show()
    self:SetLinesColor(button.ccBorder, 0.55, 0.57, 0.60, 0.95)
    self:SetLinesShown(button.ccBorder, true)
  else
    button.stunText:Hide()
    self:SetLinesShown(button.ccBorder, false)
  end

  if self.db.auras.showCrowdControl and auras.silenced then
    button.silenceText:Show()
  else
    button.silenceText:Hide()
  end
end
