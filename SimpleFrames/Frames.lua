local _, SF = ...

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local HEADER_HEIGHT = 14
local HANDLE_HEIGHT = 18
local MOVE_HANDLE_SIZE = 12
local AURA_ICON_MIN_SIZE = 8
local AURA_ICON_MAX_SIZE = 28
local AURA_ICON_GAP = 2
local ROLE_ICON_SIZE = 14
local ROLE_ICON_GAP = 4
local ROLE_HEADER_HEIGHT = 12
local ROLE_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"

local ROLE_LAYOUT_ORDER = { "TANK", "DAMAGER", "HEALER", "NONE" }
local ROLE_LABELS = {
  TANK = "Tank",
  DAMAGER = "DPS",
  HEALER = "Healer",
  NONE = "Other",
}
local ROLE_COLORS = {
  TANK = { r = 0.45, g = 0.72, b = 1.00 },
  DAMAGER = { r = 1.00, g = 0.74, b = 0.32 },
  HEALER = { r = 0.36, g = 1.00, b = 0.52 },
  NONE = { r = 0.58, g = 0.62, b = 0.68 },
}
local ROLE_TEX_COORDS = {
  TANK = { 0.00, 0.25, 0.00, 0.25 },
  HEALER = { 0.25, 0.50, 0.00, 0.25 },
  DAMAGER = { 0.50, 0.75, 0.00, 0.25 },
}

local function trimText(text)
  text = tostring(text or "")
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

local function isCombatLocked()
  return InCombatLockdown and InCombatLockdown()
end

local function startTrackedMove(frame)
  local parent = frame and frame:GetParent()
  if not parent or not SF.db or SF.db.locked or isCombatLocked() then
    return
  end

  parent.simpleFramesMoving = true
  parent.simpleFramesMoveStopPending = nil
  parent:StartMoving()
end

local function finishTrackedMove(parent, position)
  if not parent or not parent.simpleFramesMoving then
    return
  end

  if isCombatLocked() then
    parent.simpleFramesMoveStopPending = true
    SF.pendingMovementStop = true
    return
  end

  parent.simpleFramesMoving = nil
  parent.simpleFramesMoveStopPending = nil
  parent:StopMovingOrSizing()
  SF:SaveFramePosition(parent, position)
end

local function startAnchorMove(frame)
  startTrackedMove(frame)
end

local function stopAnchorMove(frame)
  finishTrackedMove(frame and frame:GetParent(), SF.db.framePosition)
end

local function startPriorityMove(frame)
  startTrackedMove(frame)
end

local function stopPriorityMove(frame)
  SF:EnsurePriorityConfig()
  finishTrackedMove(frame and frame:GetParent(), SF.db.priority.framePosition)
end

local function startPetMove(frame)
  startTrackedMove(frame)
end

local function stopPetMove(frame)
  SF:EnsurePetConfig()
  finishTrackedMove(frame and frame:GetParent(), SF.db.pets.framePosition)
end

function SF:CreateFrames()
  if self.anchor then
    return
  end

  local anchor = CreateFrame("Frame", "SimpleFramesAnchor", UIParent, BACKDROP_TEMPLATE)
  anchor:SetClampedToScreen(true)
  anchor:SetMovable(true)
  anchor:SetSize(200, 120)
  self:ApplyBackdrop(anchor, 0.03, 0.035, 0.04, 0, 0.20, 0.22, 0.25, 0)
  self:RestoreFramePosition(anchor, self.db.framePosition, self.defaults.framePosition)
  self.anchor = anchor

  local handle = CreateFrame("Frame", nil, anchor)
  handle:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
  handle:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
  handle:SetHeight(HANDLE_HEIGHT)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", startAnchorMove)
  handle:SetScript("OnDragStop", stopAnchorMove)
  anchor.handle = handle

  local handleBg = handle:CreateTexture(nil, "BACKGROUND")
  handleBg:SetAllPoints(handle)
  self:SetTextureColor(handleBg, 0.08, 0.09, 0.10, 0.90)

  local handleText = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  handleText:SetPoint("LEFT", handle, "LEFT", 6, 0)
  handleText:SetText("SimpleFrames")
  handleText:SetTextColor(0.85, 0.90, 0.95, 1)
  handle.text = handleText

  local moveHandle = CreateFrame("Frame", nil, anchor)
  moveHandle:SetSize(MOVE_HANDLE_SIZE, MOVE_HANDLE_SIZE)
  moveHandle:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  moveHandle:EnableMouse(true)
  moveHandle:RegisterForDrag("LeftButton")
  moveHandle:SetScript("OnDragStart", startAnchorMove)
  moveHandle:SetScript("OnDragStop", stopAnchorMove)
  moveHandle:Hide()
  anchor.moveHandle = moveHandle

  local moveHandleBg = moveHandle:CreateTexture(nil, "BACKGROUND")
  moveHandleBg:SetAllPoints(moveHandle)
  self:SetTextureColor(moveHandleBg, 0.08, 0.09, 0.10, 0.90)
  moveHandle.bg = moveHandleBg

  local moveHandleBorder = self:CreateBorder(moveHandle, "OVERLAY")
  self:SetLinesColor(moveHandleBorder, 0.55, 0.62, 0.70, 0.95)
  self:SetLinesShown(moveHandleBorder, true)
  moveHandle.border = moveHandleBorder

  local content = CreateFrame("Frame", nil, anchor)
  content:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -HANDLE_HEIGHT)
  content:SetSize(200, 100)
  anchor.content = content
  self.content = content

  self.headers = {}
  for i = 1, 8 do
    self.headers[i] = self:CreateGroupHeader(i)
  end

  self.roleHeaders = {}
  for subgroup = 1, 8 do
    self.roleHeaders[subgroup] = {}
    for i = 1, #ROLE_LAYOUT_ORDER do
      local role = ROLE_LAYOUT_ORDER[i]
      self.roleHeaders[subgroup][role] = self:CreateRoleHeader(role)
    end
  end

  self.buttons = {}
  self.unitToButton = {}
  for i = 1, 40 do
    self.buttons[i] = self:CreateUnitButton(i)
  end

  self:CreatePriorityFrame()
  self:CreatePetFrame()

  self:ApplyLockState()
end

function SF:CreateGroupHeader(index)
  local header = CreateFrame("Frame", nil, self.content)
  header:SetSize(self.db.layout.width, HEADER_HEIGHT)
  header:Hide()

  local bg = header:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(header)
  self:SetTextureColor(bg, 0.08, 0.09, 0.10, 0.85)
  header.bg = bg

  local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", header, "LEFT", 4, 0)
  text:SetText("G" .. index)
  text:SetTextColor(0.78, 0.82, 0.88, 1)
  header.text = text

  return header
end

function SF:CreateRoleHeader(role)
  local header = CreateFrame("Frame", nil, self.content)
  header:SetSize(self.db.layout.width, ROLE_HEADER_HEIGHT)
  header:Hide()
  header.role = role

  local bg = header:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(header)
  header.bg = bg

  local icon = header:CreateTexture(nil, "ARTWORK")
  icon:SetSize(10, 10)
  icon:SetPoint("LEFT", header, "LEFT", 4, 0)
  header.icon = icon

  local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", header, "LEFT", role == "NONE" and 4 or 18, 0)
  text:SetText(ROLE_LABELS[role] or role)
  header.text = text

  self:ApplyRoleHeaderStyle(header, role)
  return header
end

function SF:CreateAuraIcon(parent)
  local iconFrame = CreateFrame("Frame", nil, parent)
  iconFrame:SetSize(12, 12)
  iconFrame:Hide()

  local icon = iconFrame:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(iconFrame)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  iconFrame.icon = icon

  local shade = iconFrame:CreateTexture(nil, "OVERLAY")
  shade:SetAllPoints(iconFrame)
  self:SetTextureColor(shade, 0, 0, 0, 0.22)
  iconFrame.shade = shade

  local count = iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  count:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
  count:SetText("")
  iconFrame.count = count

  return iconFrame
end

function SF:CreateUnitButton(index, parent, namePrefix)
  local button = CreateFrame("Button", (namePrefix or "SimpleFramesUnitButton") .. index, parent or self.content, "SecureUnitButtonTemplate")
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("type1", nil)
  button:SetAttribute("type2", nil)
  button:SetAttribute("type3", "target")
  self:ClearClickCastAttributes(button)
  button:SetAttribute("unit", nil)
  button:SetSize(self.db.layout.width, self.db.layout.height)
  button:Hide()
  button.index = index

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  self:SetTextureColor(bg, 0.025, 0.028, 0.032, 0.98)
  button.bg = bg

  local health = CreateFrame("StatusBar", nil, button)
  health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  health:SetMinMaxValues(0, 1)
  health:SetValue(1)
  button.health = health

  local healthBg = health:CreateTexture(nil, "BACKGROUND")
  healthBg:SetAllPoints(health)
  self:SetTextureColor(healthBg, 0.06, 0.065, 0.075, 1)
  button.healthBg = healthBg

  local power = CreateFrame("StatusBar", nil, button)
  power:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  power:SetMinMaxValues(0, 1)
  power:SetValue(1)
  button.power = power

  local powerBg = power:CreateTexture(nil, "BACKGROUND")
  powerBg:SetAllPoints(power)
  self:SetTextureColor(powerBg, 0.03, 0.035, 0.045, 1)
  button.powerBg = powerBg

  local overlay = CreateFrame("Frame", nil, button)
  overlay:SetAllPoints(button)
  overlay:SetFrameLevel(button:GetFrameLevel() + 10)
  button.overlay = overlay

  local classStrip = overlay:CreateTexture(nil, "ARTWORK")
  classStrip:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  classStrip:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
  classStrip:SetWidth(4)
  self:SetTextureColor(classStrip, 0.55, 0.58, 0.62, 1)
  button.classStrip = classStrip

  local roleIcon = overlay:CreateTexture(nil, "OVERLAY")
  roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
  roleIcon:Hide()
  button.roleIcon = roleIcon

  local lowHealth = overlay:CreateTexture(nil, "OVERLAY")
  lowHealth:SetAllPoints(button)
  lowHealth:SetBlendMode("ADD")
  self:SetTextureColor(lowHealth, 1, 0.05, 0.04, 0.28)
  lowHealth:Hide()
  button.lowHealth = lowHealth

  local name = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  name:SetPoint("LEFT", button, "LEFT", 8, 4)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  name:SetTextColor(1, 1, 1, 1)
  button.nameText = name

  local healthText = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  healthText:SetPoint("RIGHT", button, "RIGHT", -5, 4)
  healthText:SetJustifyH("RIGHT")
  healthText:SetTextColor(0.94, 0.96, 0.98, 1)
  button.healthText = healthText

  local powerText = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  powerText:SetPoint("RIGHT", button, "RIGHT", -5, -12)
  powerText:SetJustifyH("RIGHT")
  powerText:SetTextColor(0.88, 0.90, 0.94, 1)
  button.powerText = powerText

  local raidIcon = overlay:CreateTexture(nil, "OVERLAY")
  raidIcon:SetSize(self.db.layout.raidIconSize or 14, self.db.layout.raidIconSize or 14)
  raidIcon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -3, -2)
  raidIcon:Hide()
  button.raidIcon = raidIcon

  button.buffIcons = {}
  button.debuffIcons = {}
  for i = 1, 4 do
    button.buffIcons[i] = self:CreateAuraIcon(overlay)
    button.debuffIcons[i] = self:CreateAuraIcon(overlay)
  end

  button.debuffBorder = self:CreateBorder(overlay, "OVERLAY")
  button.ccBorder = self:CreateBorder(overlay, "OVERLAY")

  local stunText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  stunText:SetPoint("CENTER", button, "CENTER", 0, 0)
  stunText:SetText("X")
  stunText:SetTextColor(0.70, 0.72, 0.75, 0.95)
  stunText:Hide()
  button.stunText = stunText

  local silenceText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  silenceText:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6, 1)
  silenceText:SetText("S")
  silenceText:SetTextColor(0.30, 0.70, 1.00, 1)
  silenceText:Hide()
  button.silenceText = silenceText

  button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local highlight = button:GetHighlightTexture()
  if highlight then
    highlight:SetVertexColor(1, 1, 1, 0.08)
  end

  self:ApplyButtonStyle(button)
  self:AttachPriorityToggleHooks(button)
  return button
end

function SF:ApplyButtonStyle(button)
  local db = self.db.layout
  local text = self.db.text
  local auras = self.db.auras
  local width = db.width
  local height = db.height
  local configuredPowerHeight = db.showPower and (db.powerHeight or 0) or 0
  local maxPowerHeight = math.max(0, height - 12)
  local powerHeight = configuredPowerHeight > 0 and math.min(math.max(10, configuredPowerHeight), maxPowerHeight) or 0
  local healthHeight = height - powerHeight

  if healthHeight < 12 then
    healthHeight = 12
  end

  button:SetSize(width, height)
  if button.overlay then
    button.overlay:SetFrameLevel(button:GetFrameLevel() + 10)
  end

  button.health:ClearAllPoints()
  button.health:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  button.health:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
  button.health:SetHeight(healthHeight)

  button.power:ClearAllPoints()
  button.power:SetPoint("TOPLEFT", button.health, "BOTTOMLEFT", 0, 0)
  button.power:SetPoint("TOPRIGHT", button.health, "BOTTOMRIGHT", 0, 0)
  button.power:SetHeight(powerHeight)

  if powerHeight > 0 then
    button.power:Show()
    button.powerText:Show()
  else
    button.power:Hide()
    button.powerText:Hide()
  end

  local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
  local nameFontSize = self:Clamp(text.nameFontSize, 6, 24)
  local healthFontSize = math.min(self:Clamp(text.healthFontSize, 6, 24), math.max(7, healthHeight - 4))
  local powerFontSize = math.min(self:Clamp(text.powerFontSize, 6, 24), math.max(6, powerHeight - 1))
  local raidIconSize = self:Clamp(db.raidIconSize, 8, 24)
  local buffSize = self:Clamp(auras.buffSize, AURA_ICON_MIN_SIZE, AURA_ICON_MAX_SIZE)
  local debuffSize = self:Clamp(auras.debuffSize, AURA_ICON_MIN_SIZE, AURA_ICON_MAX_SIZE)
  local maxOffsetX = math.max(0, tonumber(width) or 0)
  local nameOffsetX = self:Clamp(text.nameOffsetX, 0, maxOffsetX)
  local healthOffsetX = self:Clamp(text.healthOffsetX, 0, maxOffsetX)
  local powerOffsetX = self:Clamp(text.powerOffsetX, 0, maxOffsetX)
  local buffOffsetX = self:Clamp(auras.buffOffsetX, 0, maxOffsetX)
  local debuffOffsetX = self:Clamp(auras.debuffOffsetX, 0, maxOffsetX)
  button.nameText:SetFont(fontPath, nameFontSize, "OUTLINE")
  button.healthText:SetFont(fontPath, healthFontSize, "OUTLINE")
  button.powerText:SetFont(fontPath, powerFontSize, "OUTLINE")
  button.stunText:SetFont(fontPath, math.max(14, nameFontSize + 6), "OUTLINE")
  button.silenceText:SetFont(fontPath, math.max(9, nameFontSize - 1), "OUTLINE")
  button.raidIcon:SetSize(raidIconSize, raidIconSize)

  button.nameText:ClearAllPoints()
  if text.namePosition == "center" then
    button.nameText:SetPoint("CENTER", button.health, "CENTER", nameOffsetX, text.nameOffsetY or 0)
    button.nameText:SetWidth(math.max(60, width - 78))
    button.nameText:SetJustifyH("CENTER")
  else
    button.nameText:SetPoint("LEFT", button.health, "LEFT", 8 + nameOffsetX, text.nameOffsetY or 0)
    button.nameText:SetPoint("RIGHT", button.healthText, "LEFT", -5, 0)
    button.nameText:SetJustifyH("LEFT")
  end

  button.healthText:ClearAllPoints()
  button.healthText:SetPoint("RIGHT", button.health, "RIGHT", -5 + healthOffsetX, text.healthOffsetY or 0)

  button.powerText:ClearAllPoints()
  button.powerText:SetPoint("RIGHT", button.power, "RIGHT", -5 + powerOffsetX, text.powerOffsetY or 0)
  self:PositionRoleIcon(button)
  self:PositionRaidIcon(button)

  for i = 1, 4 do
    local buff = button.buffIcons[i]
    buff:SetSize(buffSize, buffSize)
    buff:ClearAllPoints()
    buff:SetPoint("TOPRIGHT", button, "TOPRIGHT", -((i - 1) * (buffSize + AURA_ICON_GAP)) - 20 + buffOffsetX, -2 + (auras.buffOffsetY or 0))

    local debuff = button.debuffIcons[i]
    debuff:SetSize(debuffSize, debuffSize)
    debuff:ClearAllPoints()
    debuff:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6 + ((i - 1) * (debuffSize + AURA_ICON_GAP)) + debuffOffsetX, 2 + (auras.debuffOffsetY or 0))
  end
end

function SF:NormalizeRole(role)
  if not role then
    return nil
  end

  role = string.upper(tostring(role))
  if role == "TANK" or role == "MAINTANK" then
    return "TANK"
  end
  if role == "DAMAGER" or role == "DPS" then
    return "DAMAGER"
  end
  if role == "HEALER" then
    return "HEALER"
  end
  return nil
end

function SF:GetUnitRole(unit, rosterRole)
  local role = self:NormalizeRole(rosterRole)
  if role then
    return role
  end

  if UnitGroupRolesAssigned and unit then
    role = self:NormalizeRole(UnitGroupRolesAssigned(unit))
    if role then
      return role
    end
  end

  if GetPartyAssignment and unit and GetPartyAssignment("MAINTANK", unit) then
    return "TANK"
  end

  return nil
end

function SF:SetRoleIconTexture(texture, role)
  if not texture then
    return false
  end

  role = self:NormalizeRole(role)
  local coords = role and ROLE_TEX_COORDS[role]
  if not coords then
    texture:Hide()
    return false
  end

  texture:SetTexture(ROLE_TEXTURE)
  texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  texture:Show()
  return true
end

function SF:PositionRoleIcon(button)
  if not button or not button.roleIcon then
    return
  end

  button.roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
  button.roleIcon:ClearAllPoints()
  button.roleIcon:SetPoint("RIGHT", button, "LEFT", -ROLE_ICON_GAP, 0)
end

function SF:UpdateRoleIcon(button, role)
  if not button or not button.roleIcon then
    return
  end

  if button.isPetButton or button.isPriorityButton then
    button.roleIcon:Hide()
    return
  end

  self:PositionRoleIcon(button)
  self:SetRoleIconTexture(button.roleIcon, role)
end

function SF:ApplyRoleHeaderStyle(header, role)
  if not header then
    return
  end

  role = self:NormalizeRole(role) or "NONE"
  local color = ROLE_COLORS[role] or ROLE_COLORS.NONE
  if header.bg then
    self:SetTextureColor(header.bg, color.r * 0.16, color.g * 0.16, color.b * 0.16, 0.88)
  end
  if header.text then
    header.text:SetText(ROLE_LABELS[role] or role)
    header.text:SetTextColor(color.r, color.g, color.b, 1)
  end
  self:SetRoleIconTexture(header.icon, role)
end

function SF:PositionRaidIcon(button)
  if not button or not button.raidIcon or not button.nameText then
    return
  end

  local icon = button.raidIcon
  icon:ClearAllPoints()

  local nameWidth = button.nameText:GetStringWidth() or 0
  local maxNameWidth = button.nameText:GetWidth() or 0
  if maxNameWidth > 0 and nameWidth > maxNameWidth then
    nameWidth = maxNameWidth
  end

  if self.db.text.namePosition == "center" then
    icon:SetPoint("LEFT", button.nameText, "CENTER", (nameWidth / 2) + 3, 0)
  else
    icon:SetPoint("LEFT", button.nameText, "LEFT", nameWidth + 3, 0)
  end
end

function SF:ShouldShowHandle()
  if not self.anchor or self.db.locked then
    return false
  end
  if self.db.preview.mode ~= "off" then
    return false
  end
  if self.roster and #self.roster > 1 then
    return false
  end
  return true
end

function SF:UpdateHandleVisibility()
  if not self.anchor or not self.anchor.handle then
    return 0
  end

  if self:ShouldShowHandle() then
    self.anchor.handle:Show()
    self.anchor.handle:EnableMouse(true)
    if self.anchor.moveHandle then
      self.anchor.moveHandle:Hide()
      self.anchor.moveHandle:EnableMouse(false)
    end
    return HANDLE_HEIGHT
  end

  self.anchor.handle:Hide()
  self.anchor.handle:EnableMouse(false)
  if self.anchor.moveHandle then
    if not self.db.locked then
      self.anchor.moveHandle:Show()
      self.anchor.moveHandle:EnableMouse(true)
    else
      self.anchor.moveHandle:Hide()
      self.anchor.moveHandle:EnableMouse(false)
    end
  end
  return 0
end

function SF:ApplyLockState()
  if not self.anchor then
    return
  end

  self:UpdateHandleVisibility()
  self:UpdateAnchorVisibility()

  if self.priorityAnchor and self.priorityAnchor.handle then
    self.priorityAnchor.handle:EnableMouse(not self.db.locked)
  end
  if self.petAnchor and self.petAnchor.handle then
    self.petAnchor.handle:EnableMouse(not self.db.locked)
  end
end

function SF:EnsurePreviewData()
  if self.previewData then
    return
  end

  self.previewData = {}
  local debuffs = { nil, "Magic", nil, "Poison", nil, "Curse", nil, "Disease" }
  local rolePattern = { "TANK", "DAMAGER", "DAMAGER", "DAMAGER", "HEALER" }
  for i = 1, 40 do
    local classFile = self.classOrder[((i - 1) % #self.classOrder) + 1]
    local name = "Demo" .. string.format("%02d", i)
    if i == 1 then
      name = UnitName and UnitName("player") or "You"
      classFile = UnitClass and select(2, UnitClass("player")) or classFile
    end
    local maxHealth = 8200 + (i * 170)
    local healthPercent = 0.28 + ((i % 11) * 0.06)
    if i == 3 or i == 17 then
      healthPercent = 0.10
    end
    if healthPercent > 1 then
      healthPercent = 1
    end

    self.previewData[i] = {
      isDemo = true,
      name = name,
      classFile = classFile,
      subgroup = math.floor((i - 1) / 5) + 1,
      maxHealth = maxHealth,
      health = math.floor(maxHealth * healthPercent),
      maxPower = 3600 + (i * 60),
      power = 1800 + (i * 35),
      connected = i ~= 29,
      dead = i == 34,
      debuffType = debuffs[((i - 1) % #debuffs) + 1],
      role = rolePattern[((i - 1) % #rolePattern) + 1],
      stunned = i == 9 or i == 22,
      silenced = i == 12 or i == 31,
      raidIcon = (i == 2 or i == 18) and 8 or (i == 7 and 4 or nil),
    }
  end
end

function SF:TickPreview()
  if not self.previewData then
    return
  end

  for i = 1, #self.previewData do
    local entry = self.previewData[i]
    if entry.connected and not entry.dead then
      local delta = math.random(-420, 420)
      entry.health = entry.health + delta
      if entry.health < 1 then
        entry.health = 1
      elseif entry.health > entry.maxHealth then
        entry.health = entry.maxHealth
      end

      local powerDelta = math.random(-180, 180)
      entry.power = entry.power + powerDelta
      if entry.power < 0 then
        entry.power = 0
      elseif entry.power > entry.maxPower then
        entry.power = entry.maxPower
      end
    end
  end

  self:RefreshAllUnitData()
end

function SF:StartPreviewTicker()
  if self.previewTicker then
    return
  end

  local ticker = CreateFrame("Frame", nil, UIParent)
  local elapsed = 0
  ticker:SetScript("OnUpdate", function(_, delta)
    if not SF.db or not SF.db.preview or SF.db.preview.mode == "off" or not SF.db.preview.animate then
      return
    end
    elapsed = elapsed + delta
    if elapsed < 0.35 then
      return
    end
    elapsed = 0
    SF:TickPreview()
  end)
  self.previewTicker = ticker
end

function SF:StopPreviewTicker()
  if not self.previewTicker then
    return
  end

  self.previewTicker:SetScript("OnUpdate", nil)
  self.previewTicker:Hide()
  self.previewTicker = nil
end

function SF:SetPreviewMode(mode)
  mode = mode or "off"
  if mode ~= "party" and mode ~= "raid" then
    mode = "off"
  end

  self.db.preview.mode = mode
  if mode == "off" then
    self:StopPreviewTicker()
  else
    self:EnsurePreviewData()
    if self.db.preview.animate then
      self:StartPreviewTicker()
    end
  end

  self:RequestProtectedRefresh()
  self:RefreshOptions()
end

function SF:BuildPreviewRoster()
  self:EnsurePreviewData()

  local roster = {}
  local mode = self.db.preview.mode
  local total = mode == "raid" and 40 or 5
  for i = 1, total do
    local entry = self.previewData[i]
    roster[#roster + 1] = entry
  end

  return roster, mode == "raid"
end

function SF:BuildRealRoster()
  local roster = {}

  if self:IsInRaidGroup() then
    local count = self:GetRaidSize()
    for i = 1, count do
      local unit = "raid" .. i
      if UnitExists(unit) then
        local name, subgroup, classFile, role
        if GetRaidRosterInfo then
          local rosterName, _, rosterSubgroup, _, _, rosterClassFile, _, _, _, rosterRole, _, combatRole = GetRaidRosterInfo(i)
          name = rosterName
          subgroup = rosterSubgroup
          classFile = rosterClassFile
          role = self:GetUnitRole(unit, combatRole)
          if not role then
            role = self:GetUnitRole(unit, rosterRole)
          end
        end
        if not name then
          name = UnitName(unit)
        end
        if not classFile then
          local _, detected = UnitClass(unit)
          classFile = detected
        end
        if not role then
          role = self:GetUnitRole(unit)
        end
        roster[#roster + 1] = {
          unit = unit,
          name = name,
          classFile = classFile,
          subgroup = subgroup or math.floor((i - 1) / 5) + 1,
          role = role,
          raidIndex = i,
          isPlayer = UnitIsUnit and UnitIsUnit(unit, "player"),
        }
      end
    end
    return roster, true
  end

  if self:IsInAnyGroup() then
    roster[#roster + 1] = {
      unit = "player",
      name = UnitName("player"),
      classFile = select(2, UnitClass("player")),
      subgroup = 1,
      role = self:GetUnitRole("player"),
      isPlayer = true,
    }

    local count = self:GetPartySize()
    for i = 1, count do
      local unit = "party" .. i
      if UnitExists(unit) then
        roster[#roster + 1] = {
          unit = unit,
          name = UnitName(unit),
          classFile = select(2, UnitClass(unit)),
          subgroup = 1,
          role = self:GetUnitRole(unit),
          isPlayer = false,
        }
      end
    end
  else
    roster[#roster + 1] = {
      unit = "player",
      name = UnitName("player"),
      classFile = select(2, UnitClass("player")),
      subgroup = 1,
      role = self:GetUnitRole("player"),
      isPlayer = true,
    }
  end

  return roster, false
end

function SF:BuildRoster()
  if self.db.preview.mode ~= "off" then
    return self:BuildPreviewRoster()
  end
  return self:BuildRealRoster()
end

function SF:EnsurePriorityConfig()
  if type(self.db.priority) ~= "table" then
    self.db.priority = {}
  end
  self:CopyDefaults(self.defaults.priority, self.db.priority)

  if type(self.db.priority.list) ~= "table" then
    self.db.priority.list = {}
  end
  if type(self.db.priority.order) ~= "table" then
    self.db.priority.order = {}
  end

  return self.db.priority
end

function SF:EnsurePetConfig()
  if type(self.db.pets) ~= "table" then
    self.db.pets = {}
  end
  self:CopyDefaults(self.defaults.pets, self.db.pets)
  return self.db.pets
end

function SF:IsPriorityGuid(guid)
  if not guid then
    return false
  end

  local priority = self:EnsurePriorityConfig()
  return priority.list and priority.list[guid] ~= nil
end

function SF:RemovePriorityGuidFromOrder(guid)
  local priority = self:EnsurePriorityConfig()
  local order = priority.order
  for i = #order, 1, -1 do
    if order[i] == guid then
      table.remove(order, i)
    end
  end
end

function SF:TogglePriorityByGuid(guid, info)
  if not guid then
    return false
  end

  if InCombatLockdown and InCombatLockdown() then
    self:Print("cannot change prio targets while in combat")
    return false
  end

  local priority = self:EnsurePriorityConfig()
  local list = priority.list
  local order = priority.order
  local added

  if list[guid] then
    list[guid] = nil
    self:RemovePriorityGuidFromOrder(guid)
    added = false
  else
    list[guid] = info or { name = guid }
    order[#order + 1] = guid
    added = true
  end

  self:RefreshPriorityFrame()
  self:RefreshAllUnitData()
  return true, added
end

function SF:ClearPriorityTargets()
  if InCombatLockdown and InCombatLockdown() then
    self:Print("cannot clear prio targets while in combat")
    return false
  end

  local priority = self:EnsurePriorityConfig()
  self:WipeTable(priority.list)
  self:WipeTable(priority.order)
  self:RefreshPriorityFrame()
  self:RefreshAllUnitData()
  self:Print("prio targets cleared")
  return true
end

function SF:TogglePriorityForButton(button)
  if not button or button.isPetButton or not button.unit or (button.entry and button.entry.isDemo) then
    return false
  end

  local unit = button.unit
  if not UnitExists(unit) then
    return false
  end

  local guid = UnitGUID(unit)
  if not guid then
    return false
  end

  local name = UnitName(unit) or (button.entry and button.entry.name) or unit
  local _, classFile = UnitClass(unit)
  classFile = classFile or (button.entry and button.entry.classFile)

  local ok, added = self:TogglePriorityByGuid(guid, {
    name = name,
    classFile = classFile,
  })

  if ok then
    self:Print((added and "added prio target: " or "removed prio target: ") .. name)
  end

  return ok
end

function SF:AttachPriorityToggleHooks(button)
  if not button or button.priorityToggleHooked then
    return
  end

  button.priorityToggleHooked = true
  button:HookScript("PreClick", function(clicked, mouseButton)
    if mouseButton ~= "MiddleButton" or not IsShiftKeyDown or not IsShiftKeyDown() then
      return
    end

    if not SF:TogglePriorityForButton(clicked) then
      return
    end

    if InCombatLockdown and InCombatLockdown() then
      return
    end

    clicked.suppressMiddleClickRestore = true
    clicked:SetAttribute("type3", "none")
    clicked:SetAttribute("spell3", nil)
    clicked:SetAttribute("macrotext3", nil)
    clicked:SetAttribute("shift-type3", "none")
    clicked:SetAttribute("shift-spell3", nil)
    clicked:SetAttribute("shift-macrotext3", nil)
  end)

  button:HookScript("PostClick", function(clicked, mouseButton)
    if mouseButton ~= "MiddleButton" or not clicked.suppressMiddleClickRestore then
      return
    end

    clicked.suppressMiddleClickRestore = nil
    if InCombatLockdown and InCombatLockdown() then
      return
    end

    if clicked.entry and not clicked.entry.isDemo and clicked.unit then
      clicked:SetAttribute("type3", "target")
    else
      clicked:SetAttribute("type3", nil)
    end
    clicked:SetAttribute("shift-type3", nil)
    clicked:SetAttribute("spell3", nil)
    clicked:SetAttribute("macrotext3", nil)
    clicked:SetAttribute("shift-spell3", nil)
    clicked:SetAttribute("shift-macrotext3", nil)
  end)
end

function SF:CreatePetFrame()
  if self.petAnchor then
    return
  end

  local pets = self:EnsurePetConfig()
  local anchor = CreateFrame("Frame", "SimpleFramesPetAnchor", UIParent, BACKDROP_TEMPLATE)
  anchor:SetClampedToScreen(true)
  anchor:SetMovable(true)
  anchor:SetSize(180, HANDLE_HEIGHT + 38)
  self:ApplyBackdrop(anchor, 0.035, 0.038, 0.045, 0.96, 0.12, 0.30, 0.18, 1)
  self:RestoreFramePosition(anchor, pets.framePosition, self.defaults.pets.framePosition)
  anchor:Hide()
  self.petAnchor = anchor

  local handle = CreateFrame("Frame", nil, anchor)
  handle:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
  handle:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
  handle:SetHeight(HANDLE_HEIGHT)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", startPetMove)
  handle:SetScript("OnDragStop", stopPetMove)
  anchor.handle = handle

  local handleBg = handle:CreateTexture(nil, "BACKGROUND")
  handleBg:SetAllPoints(handle)
  self:SetTextureColor(handleBg, 0.04, 0.14, 0.08, 0.94)

  local handleText = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  handleText:SetPoint("LEFT", handle, "LEFT", 6, 0)
  handleText:SetText("Pets")
  handleText:SetTextColor(0.55, 1.00, 0.68, 1)
  handle.text = handleText

  local content = CreateFrame("Frame", nil, anchor)
  content:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -HANDLE_HEIGHT)
  content:SetSize(160, 38)
  anchor.content = content
  self.petContent = content

  self.petButtons = {}
  self.petUnitToButton = {}
  for i = 1, 40 do
    local button = self:CreateUnitButton(i, content, "SimpleFramesPetButton")
    button.isPetButton = true
    button:SetAttribute("type3", nil)
    button:SetAttribute("unit", nil)
    button:Hide()
    self.petButtons[i] = button
  end
end

function SF:ApplyPetLayout(visibleCount)
  if not self.petAnchor or not self.petButtons then
    return
  end

  local pets = self:EnsurePetConfig()
  local db = self.db.layout
  local width = db.width
  local height = db.height
  local spacing = pets.spacing or db.spacing or 4
  local columns = self:Clamp(pets.columns or 1, 1, 8)

  if visibleCount < columns then
    columns = math.max(1, visibleCount)
  end

  self.petContent:ClearAllPoints()
  self.petContent:SetPoint("TOPLEFT", self.petAnchor, "TOPLEFT", 0, -HANDLE_HEIGHT)

  for i = 1, 40 do
    local button = self.petButtons[i]
    self:ApplyButtonStyle(button)
    button:ClearAllPoints()

    local index = i - 1
    local col = index % columns
    local row = math.floor(index / columns)
    button:SetPoint("TOPLEFT", self.petContent, "TOPLEFT", col * (width + spacing), -(row * (height + spacing)))
  end

  local rows = math.max(1, math.ceil(visibleCount / columns))
  local totalWidth = (columns * width) + ((columns - 1) * spacing)
  local totalHeight = (rows * height) + ((rows - 1) * spacing)
  self.petContent:SetSize(totalWidth, totalHeight)
  self.petAnchor:SetSize(totalWidth, totalHeight + HANDLE_HEIGHT)
end

function SF:AddPetRosterEntry(roster, seen, unit, ownerUnit, ownerName, ownerClassFile)
  if not unit or not UnitExists(unit) then
    return
  end

  local guid = UnitGUID(unit) or unit
  if seen[guid] then
    return
  end
  seen[guid] = true

  local name = UnitName(unit)
  if not name or name == "" or name == UNKNOWNOBJECT then
    name = ownerName and ownerName ~= "" and (ownerName .. "'s pet") or unit
  end

  roster[#roster + 1] = {
    unit = unit,
    name = name,
    classFile = ownerClassFile,
    ownerUnit = ownerUnit,
    ownerName = ownerName,
    isPet = true,
  }
end

function SF:BuildPetRoster()
  local roster = {}
  if self.db.preview.mode ~= "off" or not self:IsInAnyGroup() then
    return roster
  end

  local seen = {}
  local playerName
  local playerClass
  if UnitName then
    playerName = UnitName("player")
  end
  if UnitClass then
    local _, detectedClass = UnitClass("player")
    playerClass = detectedClass
  end
  self:AddPetRosterEntry(roster, seen, "pet", "player", playerName, playerClass)

  if self:IsInRaidGroup() then
    local count = self:GetRaidSize()
    for i = 1, count do
      local ownerUnit = "raid" .. i
      local unit = "raidpet" .. i
      local ownerName = UnitName and UnitName(ownerUnit)
      local _, ownerClass = UnitClass(ownerUnit)
      self:AddPetRosterEntry(roster, seen, unit, ownerUnit, ownerName, ownerClass)
    end
  else
    local count = self:GetPartySize()
    for i = 1, count do
      local ownerUnit = "party" .. i
      local unit = "partypet" .. i
      local ownerName = UnitName and UnitName(ownerUnit)
      local _, ownerClass = UnitClass(ownerUnit)
      self:AddPetRosterEntry(roster, seen, unit, ownerUnit, ownerName, ownerClass)
    end
  end

  return roster
end

function SF:RefreshPetFrame()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingPets = true
    return
  end

  self.pendingPets = false
  local pets = self:EnsurePetConfig()
  if not self.petAnchor then
    self:CreatePetFrame()
  end

  self.petUnitToButton = self.petUnitToButton or {}
  self:WipeTable(self.petUnitToButton)

  if not pets.enabled or not pets.showFrame or self.db.preview.mode ~= "off" then
    self.petAnchor:Hide()
    return
  end

  local roster = self:BuildPetRoster()
  local shown = 0

  for i = 1, #roster do
    if shown >= 40 then
      break
    end

    local entry = roster[i]
    if entry.unit and UnitExists(entry.unit) then
      shown = shown + 1
      local button = self.petButtons[shown]
      if not button then
        break
      end

      button.entry = entry
      button.unit = entry.unit
      button:SetAttribute("type3", "target")
      button:SetAttribute("unit", entry.unit)
      self:ApplyClickCastToButton(button)
      self.petUnitToButton[entry.unit] = button
      self:UpdateButtonUnit(button, entry.unit)
      button:Show()
    end
  end

  for i = shown + 1, 40 do
    local button = self.petButtons[i]
    if button then
      button.entry = nil
      button.unit = nil
      button:SetAttribute("type3", nil)
      button:SetAttribute("unit", nil)
      self:ApplyClickCastToButton(button)
      button:Hide()
    end
  end

  if shown == 0 then
    self.petAnchor:Hide()
    return
  end

  self:ApplyPetLayout(shown)
  self.petAnchor:Show()
end

function SF:RequestPetFrameRefresh()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingPets = true
    return
  end
  self:RefreshPetFrame()
end

function SF:CreatePriorityFrame()
  if self.priorityAnchor then
    return
  end

  local priority = self:EnsurePriorityConfig()
  local anchor = CreateFrame("Frame", "SimpleFramesPriorityAnchor", UIParent, BACKDROP_TEMPLATE)
  anchor:SetClampedToScreen(true)
  anchor:SetMovable(true)
  anchor:SetSize(180, HANDLE_HEIGHT + 38)
  self:ApplyBackdrop(anchor, 0.035, 0.038, 0.045, 0.96, 0.38, 0.32, 0.12, 1)
  self:RestoreFramePosition(anchor, priority.framePosition, self.defaults.priority.framePosition)
  anchor:Hide()
  self.priorityAnchor = anchor

  local handle = CreateFrame("Frame", nil, anchor)
  handle:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
  handle:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", 0, 0)
  handle:SetHeight(HANDLE_HEIGHT)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", startPriorityMove)
  handle:SetScript("OnDragStop", stopPriorityMove)
  anchor.handle = handle

  local handleBg = handle:CreateTexture(nil, "BACKGROUND")
  handleBg:SetAllPoints(handle)
  self:SetTextureColor(handleBg, 0.15, 0.12, 0.04, 0.94)

  local handleText = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  handleText:SetPoint("LEFT", handle, "LEFT", 6, 0)
  handleText:SetText("Prio targets")
  handleText:SetTextColor(1.00, 0.86, 0.32, 1)
  handle.text = handleText

  local content = CreateFrame("Frame", nil, anchor)
  content:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -HANDLE_HEIGHT)
  content:SetSize(160, 38)
  anchor.content = content
  self.priorityContent = content

  self.priorityButtons = {}
  self.priorityUnitToButton = {}
  for i = 1, 40 do
    local button = self:CreateUnitButton(i, content, "SimpleFramesPriorityButton")
    button.isPriorityButton = true
    button:SetAttribute("type3", nil)
    button:SetAttribute("unit", nil)
    button:Hide()
    self.priorityButtons[i] = button
  end
end

function SF:ApplyPriorityLayout(visibleCount)
  if not self.priorityAnchor or not self.priorityButtons then
    return
  end

  local priority = self:EnsurePriorityConfig()
  local db = self.db.layout
  local width = db.width
  local height = db.height
  local spacing = priority.spacing or db.spacing or 4
  local columns = self:Clamp(priority.columns or 1, 1, 8)

  if visibleCount < columns then
    columns = math.max(1, visibleCount)
  end

  self.priorityContent:ClearAllPoints()
  self.priorityContent:SetPoint("TOPLEFT", self.priorityAnchor, "TOPLEFT", 0, -HANDLE_HEIGHT)

  for i = 1, 40 do
    local button = self.priorityButtons[i]
    self:ApplyButtonStyle(button)
    button:ClearAllPoints()

    local index = i - 1
    local col = index % columns
    local row = math.floor(index / columns)
    button:SetPoint("TOPLEFT", self.priorityContent, "TOPLEFT", col * (width + spacing), -(row * (height + spacing)))
  end

  local rows = math.max(1, math.ceil(visibleCount / columns))
  local totalWidth = (columns * width) + ((columns - 1) * spacing)
  local totalHeight = (rows * height) + ((rows - 1) * spacing)
  self.priorityContent:SetSize(totalWidth, totalHeight)
  self.priorityAnchor:SetSize(math.max(totalWidth, 160), totalHeight + HANDLE_HEIGHT)
end

function SF:BuildPriorityUnitMap()
  self.priorityGuidToUnit = self.priorityGuidToUnit or {}
  self:WipeTable(self.priorityGuidToUnit)

  if not self.unitToButton then
    return self.priorityGuidToUnit
  end

  for unit in pairs(self.unitToButton) do
    if unit and UnitExists(unit) then
      local guid = UnitGUID(unit)
      if guid then
        self.priorityGuidToUnit[guid] = unit
      end
    end
  end

  return self.priorityGuidToUnit
end

function SF:RefreshPriorityFrame()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingPriority = true
    return
  end

  self.pendingPriority = false
  local priority = self:EnsurePriorityConfig()
  if not self.priorityAnchor then
    self:CreatePriorityFrame()
  end

  self.priorityUnitToButton = self.priorityUnitToButton or {}
  self:WipeTable(self.priorityUnitToButton)

  if not priority.enabled or not priority.showFrame or self.db.preview.mode ~= "off" then
    self.priorityAnchor:Hide()
    return
  end

  local guidToUnit = self:BuildPriorityUnitMap()
  local shown = 0

  for i = 1, #priority.order do
    local guid = priority.order[i]
    local info = priority.list[guid]
    local unit = guidToUnit[guid]
    if info and unit and UnitExists(unit) then
      shown = shown + 1
      local button = self.priorityButtons[shown]
      if not button then
        break
      end

      button.entry = {
        unit = unit,
        name = info.name,
        classFile = info.classFile,
        isPriority = true,
      }
      button.unit = unit
      button:SetAttribute("type3", "target")
      button:SetAttribute("unit", unit)
      self:ApplyClickCastToButton(button)
      self.priorityUnitToButton[unit] = button
      self:UpdateButtonUnit(button, unit)
      button:Show()
    end
  end

  for i = shown + 1, 40 do
    local button = self.priorityButtons[i]
    if button then
      button.entry = nil
      button.unit = nil
      button:SetAttribute("type3", nil)
      button:SetAttribute("unit", nil)
      self:ApplyClickCastToButton(button)
      button:Hide()
    end
  end

  if shown == 0 then
    self.priorityAnchor:Hide()
    return
  end

  self:ApplyPriorityLayout(shown)
  self.priorityAnchor:Show()
end

function SF:EnsureClickCastConfig()
  if type(self.db.clickCast) ~= "table" then
    self.db.clickCast = {}
  end
  self:CopyDefaults(self.defaults.clickCast, self.db.clickCast)

  if type(self.db.clickCast.bindings) ~= "table" then
    self.db.clickCast.bindings = {}
  end
  self:CopyDefaults(self.defaults.clickCast.bindings, self.db.clickCast.bindings)

  return self.db.clickCast
end

function SF:GetClickCastBinding(key)
  key = string.upper(trimText(key))
  local spec = self.clickCastBindingAttributes and self.clickCastBindingAttributes[key]
  if not spec then
    return ""
  end

  local clickCast = self:EnsureClickCastConfig()
  return clickCast.bindings[key] or ""
end

function SF:SetClickCastBinding(key, spell)
  key = string.upper(trimText(key))
  if not self.clickCastBindingAttributes or not self.clickCastBindingAttributes[key] then
    return false
  end

  local clickCast = self:EnsureClickCastConfig()
  clickCast.bindings[key] = trimText(spell)
  self:RequestClickCastRefresh()
  return true
end

function SF:ClearClickCastAttribute(button, key)
  local spec = self.clickCastBindingAttributes and self.clickCastBindingAttributes[key]
  if not button or not spec then
    return
  end

  local prefix = spec.prefix or ""
  local suffix = tostring(spec.button)
  button:SetAttribute(prefix .. "type" .. suffix, nil)
  button:SetAttribute(prefix .. "spell" .. suffix, nil)
  button:SetAttribute(prefix .. "macrotext" .. suffix, nil)
end

function SF:ClearClickCastAttributes(button)
  if not self.clickCastBindingOrder then
    return
  end

  for i = 1, #self.clickCastBindingOrder do
    self:ClearClickCastAttribute(button, self.clickCastBindingOrder[i])
  end
end

function SF:ClearResurrectionSpellCache()
  self.resurrectionSpellChecked = nil
  self.resurrectionSpellName = nil
end

function SF:PlayerKnowsSpellName(spellName)
  spellName = trimText(spellName)
  if spellName == "" then
    return false
  end

  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemInfo or not GetSpellBookItemName then
    return false
  end

  local query = string.lower(spellName)
  local bookType = BOOKTYPE_SPELL or "spell"
  local numTabs = GetNumSpellTabs() or 0
  for tab = 1, numTabs do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    offset = offset or 0
    numSpells = numSpells or 0

    for i = 1, numSpells do
      local slot = offset + i
      local spellType = GetSpellBookItemInfo(slot, bookType)
      if spellType == "SPELL" then
        local name = GetSpellBookItemName(slot, bookType)
        if name and string.lower(name) == query then
          return true
        end
      end
    end
  end

  return false
end

function SF:GetPlayerResurrectionSpell()
  if self.resurrectionSpellChecked then
    return self.resurrectionSpellName
  end

  self.resurrectionSpellChecked = true

  local candidates = {}
  local seen = {}
  local function addCandidate(spellName)
    spellName = trimText(spellName)
    if spellName ~= "" and not seen[spellName] then
      seen[spellName] = true
      candidates[#candidates + 1] = spellName
    end
  end

  local classFile
  if UnitClass then
    local _, detectedClass = UnitClass("player")
    classFile = detectedClass
  end
  local classSpells = classFile and self.resurrectionSpells and self.resurrectionSpells[classFile]
  if classSpells then
    for i = 1, #classSpells do
      addCandidate(classSpells[i])
    end
  end

  if self.resurrectionSpells then
    for _, spellList in pairs(self.resurrectionSpells) do
      for i = 1, #spellList do
        addCandidate(spellList[i])
      end
    end
  end

  for i = 1, #candidates do
    if self:PlayerKnowsSpellName(candidates[i]) then
      self.resurrectionSpellName = candidates[i]
      return self.resurrectionSpellName
    end
  end

  return nil
end

function SF:BuildClickCastMacro(button, spell, resurrectionSpell)
  local unit = button and button.unit or "mouseover"
  spell = trimText(spell)
  resurrectionSpell = trimText(resurrectionSpell)

  local macro = "/cast [@" .. unit .. ",help,dead] " .. resurrectionSpell
  if spell ~= "" then
    macro = macro .. "; [@" .. unit .. ",help,nodead] " .. spell
  end
  return macro
end

function SF:SetClickCastAttribute(button, key, spell)
  local spec = self.clickCastBindingAttributes and self.clickCastBindingAttributes[key]
  if not button or not spec then
    return
  end

  spell = trimText(spell)
  local resurrectionSpell = not button.isPetButton and self:GetPlayerResurrectionSpell()
  if spell == "" and not (resurrectionSpell and key == "L") then
    self:ClearClickCastAttribute(button, key)
    return
  end

  local prefix = spec.prefix or ""
  local suffix = tostring(spec.button)

  if resurrectionSpell then
    button:SetAttribute(prefix .. "type" .. suffix, "macro")
    button:SetAttribute(prefix .. "spell" .. suffix, nil)
    button:SetAttribute(prefix .. "macrotext" .. suffix, self:BuildClickCastMacro(button, spell, resurrectionSpell))
  else
    button:SetAttribute(prefix .. "type" .. suffix, "spell")
    button:SetAttribute(prefix .. "spell" .. suffix, spell)
    button:SetAttribute(prefix .. "macrotext" .. suffix, nil)
  end
end

function SF:ApplyClickCastToButton(button)
  if not button then
    return
  end

  local clickCast = self:EnsureClickCastConfig()
  local binds = clickCast.bindings or {}
  local canCast = clickCast.enabled
    and button.entry
    and not button.entry.isDemo
    and button.unit
    and button.unit ~= ""

  for i = 1, #self.clickCastBindingOrder do
    local key = self.clickCastBindingOrder[i]
    if canCast then
      self:SetClickCastAttribute(button, key, binds[key])
    else
      self:ClearClickCastAttribute(button, key)
    end
  end
end

function SF:ApplyAllClickCastBindings()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingClickCast = true
    return
  end

  self.pendingClickCast = false

  if not self.buttons then
    return
  end

  for i = 1, 40 do
    self:ApplyClickCastToButton(self.buttons[i])
  end

  if self.priorityButtons then
    for i = 1, 40 do
      self:ApplyClickCastToButton(self.priorityButtons[i])
    end
  end

  if self.petButtons then
    for i = 1, 40 do
      self:ApplyClickCastToButton(self.petButtons[i])
    end
  end
end

function SF:RequestClickCastRefresh()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingClickCast = true
    return
  end
  self:ApplyAllClickCastBindings()
end

function SF:RequestProtectedRefresh()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingProtected = true
    return
  end
  self:RefreshRoster()
end

function SF:RefreshRoster()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingProtected = true
    return
  end

  self.pendingProtected = false

  local roster, isRaid = self:BuildRoster()
  self.roster = roster
  self.isRaidRoster = isRaid
  self:ApplyRosterToButtons(roster)
  self:LayoutRoster(roster, isRaid)
  self:RefreshPriorityFrame()
  self:RefreshPetFrame()
  self:RefreshAllUnitData()
  self:UpdateAnchorVisibility()
end

function SF:ApplyRosterToButtons(roster)
  self:WipeTable(self.unitToButton)

  for i = 1, 40 do
    local button = self.buttons[i]
    local entry = roster[i]
    button.entry = entry
    button.unit = entry and entry.unit or nil

    if entry then
      if entry.isDemo then
        button:SetAttribute("type3", nil)
        button:SetAttribute("unit", "player")
      else
        button:SetAttribute("type3", "target")
        button:SetAttribute("unit", entry.unit)
        self.unitToButton[entry.unit] = button
      end
    else
      button:SetAttribute("type3", nil)
      button:SetAttribute("unit", nil)
      button:Hide()
    end

    self:ApplyClickCastToButton(button)
  end
end

function SF:LayoutRoster(roster, isRaid)
  local db = self.db.layout
  local width = db.width
  local height = db.height
  local spacing = db.spacing or 0
  local unitGrowth = db.unitGrowth
  local groupColumns = self:Clamp(db.groupColumns, 1, 8)
  local showHeaders = isRaid and db.showRaidHeaders
  local handleHeight = self:UpdateHandleVisibility()

  self.content:ClearAllPoints()
  self.content:SetPoint("TOPLEFT", self.anchor, "TOPLEFT", 0, -handleHeight)

  for i = 1, 8 do
    self.headers[i]:Hide()
  end

  if self.roleHeaders then
    for subgroup = 1, 8 do
      for i = 1, #ROLE_LAYOUT_ORDER do
        local role = ROLE_LAYOUT_ORDER[i]
        local header = self.roleHeaders[subgroup] and self.roleHeaders[subgroup][role]
        if header then
          header:Hide()
        end
      end
    end
  end

  for i = 1, 40 do
    self:ApplyButtonStyle(self.buttons[i])
  end

  local groups = {}
  for i = 1, 8 do
    groups[i] = {}
  end

  for i = 1, #roster do
    local entry = roster[i]
    local subgroup = entry.subgroup or 1
    if subgroup < 1 then
      subgroup = 1
    elseif subgroup > 8 then
      subgroup = 8
    end
    if entry.isPlayer and not isRaid then
      table.insert(groups[subgroup], 1, i)
    else
      groups[subgroup][#groups[subgroup] + 1] = i
    end
  end

  local maxMembers = 5
  local groupWidth
  local baseGroupHeight

  if unitGrowth == "RIGHT" then
    groupWidth = (width * maxMembers) + (spacing * (maxMembers - 1))
    baseGroupHeight = height + (showHeaders and (HEADER_HEIGHT + spacing) or 0)
  else
    groupWidth = width
    baseGroupHeight = (height * maxMembers) + (spacing * (maxMembers - 1)) + (showHeaders and (HEADER_HEIGHT + spacing) or 0)
  end

  local function getMembersSpan(memberCount)
    if memberCount < 1 then
      return 0
    end
    if unitGrowth == "RIGHT" then
      return height
    end
    return (memberCount * height) + ((memberCount - 1) * spacing)
  end

  local function buildRoleSections(members)
    if not isRaid then
      return nil
    end

    local buckets = {}
    for i = 1, #ROLE_LAYOUT_ORDER do
      buckets[ROLE_LAYOUT_ORDER[i]] = {}
    end

    local hasAssignedRole = false
    for i = 1, #members do
      local rosterIndex = members[i]
      local entry = roster[rosterIndex]
      local role = entry and self:NormalizeRole(entry.role)
      if role then
        hasAssignedRole = true
      else
        role = "NONE"
      end
      buckets[role][#buckets[role] + 1] = rosterIndex
    end

    if not hasAssignedRole then
      return nil
    end

    local sections = {}
    for i = 1, #ROLE_LAYOUT_ORDER do
      local role = ROLE_LAYOUT_ORDER[i]
      local roleMembers = buckets[role]
      if roleMembers and #roleMembers > 0 then
        sections[#sections + 1] = {
          role = role,
          members = roleMembers,
        }
      end
    end
    return sections
  end

  local function getSectionsHeight(sections)
    local sectionHeight = 0
    for i = 1, #sections do
      if i > 1 then
        sectionHeight = sectionHeight + spacing
      end
      sectionHeight = sectionHeight + ROLE_HEADER_HEIGHT + spacing + getMembersSpan(#sections[i].members)
    end
    return sectionHeight
  end

  local layouts = {}
  local rowHeights = {}
  local visibleGroups = 0

  for subgroup = 1, 8 do
    local members = groups[subgroup]
    if #members > 0 then
      visibleGroups = visibleGroups + 1
      local gridRow = math.floor((visibleGroups - 1) / groupColumns)
      local sections = buildRoleSections(members)
      local layoutHeight = baseGroupHeight
      if sections then
        layoutHeight = (showHeaders and (HEADER_HEIGHT + spacing) or 0) + getSectionsHeight(sections)
      end

      layouts[#layouts + 1] = {
        subgroup = subgroup,
        members = members,
        sections = sections,
        gridCol = (visibleGroups - 1) % groupColumns,
        gridRow = gridRow,
        height = layoutHeight,
      }
      rowHeights[gridRow] = math.max(rowHeights[gridRow] or 0, layoutHeight)
    end
  end

  local rowOffsets = {}
  local runningY = 0
  local rowCount = math.max(1, math.ceil(#layouts / groupColumns))
  for row = 0, rowCount - 1 do
    rowOffsets[row] = -runningY
    runningY = runningY + (rowHeights[row] or 0)
    if row < rowCount - 1 then
      runningY = runningY + spacing * 2
    end
  end

  local totalWidth = 0
  local totalHeight = 0

  for layoutIndex = 1, #layouts do
    local layout = layouts[layoutIndex]
    local subgroup = layout.subgroup
    local members = layout.members
    local groupX = layout.gridCol * (groupWidth + spacing * 2)
    local groupY = rowOffsets[layout.gridRow] or 0
    local startY = groupY

    if showHeaders then
      local header = self.headers[subgroup]
      header:SetWidth(groupWidth)
      header:ClearAllPoints()
      header:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX, groupY)
      header.text:SetText("G" .. subgroup)
      header:Show()
      startY = groupY - HEADER_HEIGHT - spacing
    end

    if layout.sections then
      local sectionY = startY
      for sectionIndex = 1, #layout.sections do
        local section = layout.sections[sectionIndex]
        if sectionIndex > 1 then
          sectionY = sectionY - spacing
        end

        local roleHeader = self.roleHeaders
          and self.roleHeaders[subgroup]
          and self.roleHeaders[subgroup][section.role]
        if roleHeader then
          roleHeader:SetWidth(groupWidth)
          roleHeader:ClearAllPoints()
          roleHeader:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX, sectionY)
          self:ApplyRoleHeaderStyle(roleHeader, section.role)
          roleHeader:Show()
        end

        sectionY = sectionY - ROLE_HEADER_HEIGHT - spacing
        for memberIndex = 1, #section.members do
          local button = self.buttons[section.members[memberIndex]]
          button:ClearAllPoints()
          if unitGrowth == "RIGHT" then
            button:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX + ((memberIndex - 1) * (width + spacing)), sectionY)
          else
            button:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX, sectionY - ((memberIndex - 1) * (height + spacing)))
          end
          button:Show()
        end
        sectionY = sectionY - getMembersSpan(#section.members)
      end
    else
      for memberIndex = 1, #members do
        local button = self.buttons[members[memberIndex]]
        button:ClearAllPoints()
        if unitGrowth == "RIGHT" then
          button:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX + ((memberIndex - 1) * (width + spacing)), startY)
        else
          button:SetPoint("TOPLEFT", self.content, "TOPLEFT", groupX, startY - ((memberIndex - 1) * (height + spacing)))
        end
        button:Show()
      end
    end

    totalWidth = math.max(totalWidth, groupX + groupWidth)
    totalHeight = math.max(totalHeight, math.abs(groupY) + layout.height)
  end

  if #roster == 0 then
    totalWidth = width
    totalHeight = height
  end

  self.content:SetSize(totalWidth, totalHeight)
  self.anchor:SetSize(math.max(totalWidth, 160), totalHeight + handleHeight)
end

function SF:ClearButton(button)
  button.nameText:SetText("")
  button.healthText:SetText("")
  button.powerText:SetText("")
  button.health:SetMinMaxValues(0, 1)
  button.health:SetValue(0)
  button.power:SetMinMaxValues(0, 1)
  button.power:SetValue(0)
  button.health:SetStatusBarColor(0.10, 0.11, 0.12, 1)
  button.power:SetStatusBarColor(0.06, 0.07, 0.08, 1)
  self:SetTextureColor(button.classStrip, 0.22, 0.23, 0.25, 1)
  button.lowHealth:Hide()
  self:UpdateRoleIcon(button, nil)
  self:SetRaidIcon(button.raidIcon, nil)
  self:PositionRaidIcon(button)
  self:UpdateAuraIndicators(button, nil, nil)
end

function SF:UpdateButtonDemo(button, entry)
  button.nameText:SetText(entry.name or "")

  local r, g, b = self:GetClassColorByFile(entry.classFile)
  self:SetTextureColor(button.classStrip, r, g, b, 1)
  button.nameText:SetTextColor(r, g, b, 1)
  self:UpdateRoleIcon(button, entry.role)

  local maxHealth = entry.maxHealth or 1
  local health = entry.health or 0
  button.health:SetMinMaxValues(0, maxHealth)
  button.health:SetValue(health)

  if entry.connected == false then
    button.health:SetStatusBarColor(0.25, 0.26, 0.28, 1)
    button.healthText:SetText("OFF")
  elseif entry.dead then
    button.health:SetStatusBarColor(0.38, 0.04, 0.04, 1)
    button.healthText:SetText("DEAD")
  else
    button.health:SetStatusBarColor(r * 0.72, g * 0.72, b * 0.72, 1)
    local healthMode = self.db.text.health == "off" and "both" or self.db.text.health
    button.healthText:SetText(self:FormatValue(health, maxHealth, healthMode))
  end

  local maxPower = entry.maxPower or 1
  local power = entry.power or 0
  button.power:SetMinMaxValues(0, maxPower)
  button.power:SetValue(power)
  button.power:SetStatusBarColor(0.20, 0.45, 0.95, 1)
  local powerMode = self.db.text.power == "off" and "both" or self.db.text.power
  button.powerText:SetText(self:FormatValue(power, maxPower, powerMode))

  local pct = maxHealth > 0 and (health / maxHealth) * 100 or 0
  if entry.connected ~= false and not entry.dead and pct <= (self.db.auras.lowHealthThreshold or 15) then
    button.lowHealth:Show()
  else
    button.lowHealth:Hide()
  end

  if self.db.layout.showRaidIcons then
    self:SetRaidIcon(button.raidIcon, entry.raidIcon)
  else
    self:SetRaidIcon(button.raidIcon, nil)
  end
  self:PositionRaidIcon(button)

  self:UpdateAuraIndicators(button, nil, entry)
end

function SF:UpdateButtonUnit(button, unit)
  if not unit or not UnitExists(unit) then
    self:ClearButton(button)
    return
  end

  local entry = button.entry or {}
  local name = UnitName(unit) or entry.name or unit
  local _, classFile = UnitClass(unit)
  classFile = entry.isPet and entry.classFile or classFile or entry.classFile

  button.nameText:SetText(name)
  local r, g, b
  if entry.isPet and classFile then
    r, g, b = self:GetClassColorByFile(classFile)
  else
    r, g, b = self:GetClassColor(unit, classFile)
  end
  self:SetTextureColor(button.classStrip, r, g, b, 1)
  button.nameText:SetTextColor(r, g, b, 1)
  local role = nil
  if not button.isPetButton and not button.isPriorityButton then
    role = self:GetUnitRole(unit, entry.role)
    entry.role = role
  end
  self:UpdateRoleIcon(button, role)

  local maxHealth = UnitHealthMax(unit) or 1
  local health = UnitHealth(unit) or 0
  if maxHealth < 1 then
    maxHealth = 1
  end
  if health < 0 then
    health = 0
  end

  button.health:SetMinMaxValues(0, maxHealth)
  button.health:SetValue(health)

  local connected = UnitIsConnected(unit)
  local dead = UnitIsDeadOrGhost(unit)

  if connected == false then
    button.health:SetStatusBarColor(0.25, 0.26, 0.28, 1)
    button.healthText:SetText("OFF")
  elseif dead then
    button.health:SetStatusBarColor(0.38, 0.04, 0.04, 1)
    button.healthText:SetText("DEAD")
  else
    button.health:SetStatusBarColor(r * 0.72, g * 0.72, b * 0.72, 1)
    button.healthText:SetText(self:FormatValue(health, maxHealth, self.db.text.health))
  end

  local maxPower = UnitPowerMax(unit) or 1
  local power = UnitPower(unit) or 0
  if maxPower < 1 then
    maxPower = 1
  end
  button.power:SetMinMaxValues(0, maxPower)
  button.power:SetValue(power)

  local pr, pg, pb = self:GetPowerColor(unit)
  button.power:SetStatusBarColor(pr, pg, pb, 1)
  button.powerText:SetText(self:FormatValue(power, maxPower, self.db.text.power))

  local pct = (health / maxHealth) * 100
  if connected ~= false and not dead and pct <= (self.db.auras.lowHealthThreshold or 15) then
    button.lowHealth:Show()
  else
    button.lowHealth:Hide()
  end

  if self.db.layout.showRaidIcons then
    self:SetRaidIcon(button.raidIcon, GetRaidTargetIndex and GetRaidTargetIndex(unit))
  else
    self:SetRaidIcon(button.raidIcon, nil)
  end
  self:PositionRaidIcon(button)

  self:UpdateAuraIndicators(button, unit, entry)
end

function SF:RefreshAllUnitData()
  if not self.buttons then
    return
  end

  for i = 1, 40 do
    local button = self.buttons[i]
    if button:IsShown() and button.entry then
      if button.entry.isDemo then
        self:UpdateButtonDemo(button, button.entry)
      else
        self:UpdateButtonUnit(button, button.unit)
      end
    end
  end

  if self.priorityButtons then
    for i = 1, 40 do
      local button = self.priorityButtons[i]
      if button:IsShown() and button.entry and button.unit then
        self:UpdateButtonUnit(button, button.unit)
      end
    end
  end

  if self.petButtons then
    for i = 1, 40 do
      local button = self.petButtons[i]
      if button:IsShown() and button.entry and button.unit then
        self:UpdateButtonUnit(button, button.unit)
      end
    end
  end
end

function SF:UpdateUnit(unit)
  if not unit or self.db.preview.mode ~= "off" then
    return
  end

  local button = self.unitToButton and self.unitToButton[unit]
  if button then
    self:UpdateButtonUnit(button, unit)
  end

  local priorityButton = self.priorityUnitToButton and self.priorityUnitToButton[unit]
  if priorityButton then
    self:UpdateButtonUnit(priorityButton, unit)
  end

  local petButton = self.petUnitToButton and self.petUnitToButton[unit]
  if petButton then
    self:UpdateButtonUnit(petButton, unit)
  end
end

function SF:UpdateAnchorVisibility()
  if not self.anchor then
    return
  end

  local hasRoster = self.roster and #self.roster > 0
  local shouldShow = self.db.enabled and (hasRoster or not self.db.locked or self.db.preview.mode ~= "off")
  if shouldShow then
    self.anchor:Show()
  else
    self.anchor:Hide()
  end
end

function SF:ApplyPendingMovementStops()
  if not self.pendingMovementStop or isCombatLocked() then
    return
  end

  if self.anchor and self.anchor.simpleFramesMoveStopPending then
    finishTrackedMove(self.anchor, self.db.framePosition)
  end

  if self.priorityAnchor and self.priorityAnchor.simpleFramesMoveStopPending then
    self:EnsurePriorityConfig()
    finishTrackedMove(self.priorityAnchor, self.db.priority.framePosition)
  end

  if self.petAnchor and self.petAnchor.simpleFramesMoveStopPending then
    self:EnsurePetConfig()
    finishTrackedMove(self.petAnchor, self.db.pets.framePosition)
  end

  self.pendingMovementStop = nil
end

function SF:ApplyPendingProtected()
  self:ApplyPendingMovementStops()
  if self.pendingProtected then
    self:RefreshRoster()
  end
  if self.pendingClickCast then
    self:ApplyAllClickCastBindings()
  end
  if self.pendingPriority then
    self:RefreshPriorityFrame()
  end
  if self.pendingPets then
    self:RefreshPetFrame()
  end
  if self.pendingBlizzard then
    self:ApplyBlizzardFrames()
  end
end
