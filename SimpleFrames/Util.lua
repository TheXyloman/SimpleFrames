local _, SF = ...

local function copyDefaults(src, dst)
  if type(src) ~= "table" then
    return dst
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for key, value in pairs(src) do
    if type(value) == "table" then
      dst[key] = copyDefaults(value, dst[key])
    elseif dst[key] == nil then
      dst[key] = value
    end
  end

  return dst
end

local function deepCopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, child in pairs(value) do
    copy[deepCopy(key)] = deepCopy(child)
  end
  return copy
end

function SF:CopyDefaults(src, dst)
  return copyDefaults(src, dst)
end

function SF:DeepCopy(value)
  return deepCopy(value)
end

function SF:Clamp(value, minValue, maxValue)
  value = tonumber(value) or minValue
  if value < minValue then
    return minValue
  end
  if value > maxValue then
    return maxValue
  end
  return value
end

function SF:Round(value)
  value = tonumber(value) or 0
  return math.floor(value + 0.5)
end

function SF:RoundToStep(value, step)
  step = step or 1
  return self:Round((tonumber(value) or 0) / step) * step
end

function SF:SetTextureColor(texture, r, g, b, a)
  if not texture then
    return
  end
  texture:SetTexture("Interface\\Buttons\\WHITE8X8")
  texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
end

function SF:ApplyBackdrop(frame, r, g, b, a, br, bg, bb, ba)
  if not frame or not frame.SetBackdrop then
    return
  end

  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  frame:SetBackdropColor(r or 0.04, g or 0.04, b or 0.045, a or 0.95)
  frame:SetBackdropBorderColor(br or 0.18, bg or 0.18, bb or 0.20, ba or 1)
end

function SF:SaveFramePosition(frame, target)
  if not frame or not target then
    return
  end

  local point, _, relativePoint, x, y = frame:GetPoint(1)
  target.point = point or "CENTER"
  target.relativePoint = relativePoint or target.point
  target.x = self:Round(x or 0)
  target.y = self:Round(y or 0)
end

function SF:RestoreFramePosition(frame, saved, fallback)
  if not frame then
    return
  end

  saved = saved or fallback or {}
  frame:ClearAllPoints()
  frame:SetPoint(
    saved.point or "CENTER",
    UIParent,
    saved.relativePoint or saved.point or "CENTER",
    saved.x or 0,
    saved.y or 0
  )
end

function SF:GetClassColorByFile(classFile)
  if not classFile then
    return 0.55, 0.58, 0.62
  end

  local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
  local color = colors and colors[classFile]
  if color then
    return color.r or 1, color.g or 1, color.b or 1
  end

  return 0.55, 0.58, 0.62
end

function SF:GetClassColor(unit, classFile)
  if unit and UnitExists(unit) then
    local _, detected = UnitClass(unit)
    classFile = detected or classFile
  end
  return self:GetClassColorByFile(classFile)
end

function SF:GetPowerColor(unit)
  local powerType, powerToken
  if unit and UnitExists(unit) then
    powerType, powerToken = UnitPowerType(unit)
  end

  local color
  if PowerBarColor and powerToken and PowerBarColor[powerToken] then
    color = PowerBarColor[powerToken]
  elseif PowerBarColor and powerType and PowerBarColor[powerType] then
    color = PowerBarColor[powerType]
  elseif self.powerColors and powerToken and self.powerColors[powerToken] then
    color = self.powerColors[powerToken]
  else
    color = self.powerColors.MANA
  end

  return color.r or 0.2, color.g or 0.45, color.b or 0.95
end

function SF:FormatNumber(value)
  value = self:Round(value or 0)
  return tostring(value)
end

function SF:FormatValue(current, maximum, mode)
  current = current or 0
  maximum = maximum or 0
  mode = mode or "percent"

  if mode == "off" then
    return ""
  end

  if maximum < 1 then
    maximum = 1
  end

  local percent = self:Round((current / maximum) * 100)

  if mode == "raw" then
    return self:FormatNumber(current)
  end

  if mode == "both" then
    return self:FormatNumber(current) .. " " .. percent .. "%"
  end

  return percent .. "%"
end

function SF:IsInRaidGroup()
  if IsInRaid then
    return IsInRaid()
  end
  if GetNumRaidMembers then
    return (GetNumRaidMembers() or 0) > 0
  end
  return false
end

function SF:IsInAnyGroup()
  if IsInGroup then
    return IsInGroup()
  end
  if GetNumSubgroupMembers then
    return (GetNumSubgroupMembers() or 0) > 0
  end
  if GetNumPartyMembers then
    return (GetNumPartyMembers() or 0) > 0
  end
  return false
end

function SF:GetRaidSize()
  if GetNumGroupMembers then
    return GetNumGroupMembers() or 0
  end
  if GetNumRaidMembers then
    return GetNumRaidMembers() or 0
  end
  return 0
end

function SF:GetPartySize()
  if GetNumSubgroupMembers then
    return GetNumSubgroupMembers() or 0
  end
  if GetNumPartyMembers then
    return GetNumPartyMembers() or 0
  end
  return 0
end

function SF:WipeTable(tbl)
  if not tbl then
    return
  end
  for key in pairs(tbl) do
    tbl[key] = nil
  end
end

function SF:SetLinesColor(lines, r, g, b, a)
  if not lines then
    return
  end
  for i = 1, #lines do
    self:SetTextureColor(lines[i], r, g, b, a)
  end
end

function SF:SetLinesShown(lines, shown)
  if not lines then
    return
  end
  for i = 1, #lines do
    if shown then
      lines[i]:Show()
    else
      lines[i]:Hide()
    end
  end
end

function SF:CreateBorder(parent, layer)
  local lines = {}
  local thickness = 2

  local top = parent:CreateTexture(nil, layer or "OVERLAY")
  top:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  top:SetHeight(thickness)
  lines[1] = top

  local bottom = parent:CreateTexture(nil, layer or "OVERLAY")
  bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  bottom:SetHeight(thickness)
  lines[2] = bottom

  local left = parent:CreateTexture(nil, layer or "OVERLAY")
  left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
  left:SetWidth(thickness)
  lines[3] = left

  local right = parent:CreateTexture(nil, layer or "OVERLAY")
  right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  right:SetWidth(thickness)
  lines[4] = right

  self:SetLinesColor(lines, 1, 1, 1, 1)
  self:SetLinesShown(lines, false)
  return lines
end

function SF:SetRaidIcon(texture, index)
  if not texture then
    return
  end

  if not index or index < 1 then
    texture:Hide()
    return
  end

  texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  if SetRaidTargetIconTexture then
    SetRaidTargetIconTexture(texture, index)
  else
    local left = ((index - 1) % 4) * 0.25
    local right = left + 0.25
    local top = math.floor((index - 1) / 4) * 0.25
    local bottom = top + 0.25
    texture:SetTexCoord(left, right, top, bottom)
  end
  texture:Show()
end
