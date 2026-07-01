local _, SF = ...

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local HEADER_HEIGHT = 14
local HANDLE_HEIGHT = 18
local MOVE_HANDLE_SIZE = 12

local function startAnchorMove(frame)
  if SF.db.locked or (InCombatLockdown and InCombatLockdown()) then
    return
  end
  frame:GetParent():StartMoving()
end

local function stopAnchorMove(frame)
  local parent = frame:GetParent()
  parent:StopMovingOrSizing()
  SF:SaveFramePosition(parent, SF.db.framePosition)
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

  self.buttons = {}
  self.unitToButton = {}
  for i = 1, 40 do
    self.buttons[i] = self:CreateUnitButton(i)
  end

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

function SF:CreateUnitButton(index)
  local button = CreateFrame("Button", "SimpleFramesUnitButton" .. index, self.content, "SecureUnitButtonTemplate")
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("type1", nil)
  button:SetAttribute("type2", nil)
  button:SetAttribute("type3", "target")
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
  button.nameText:SetFont(fontPath, nameFontSize, "OUTLINE")
  button.healthText:SetFont(fontPath, healthFontSize, "OUTLINE")
  button.powerText:SetFont(fontPath, powerFontSize, "OUTLINE")
  button.stunText:SetFont(fontPath, math.max(14, nameFontSize + 6), "OUTLINE")
  button.silenceText:SetFont(fontPath, math.max(9, nameFontSize - 1), "OUTLINE")
  button.raidIcon:SetSize(raidIconSize, raidIconSize)

  button.nameText:ClearAllPoints()
  if text.namePosition == "center" then
    button.nameText:SetPoint("CENTER", button.health, "CENTER", text.nameOffsetX or 0, text.nameOffsetY or 0)
    button.nameText:SetWidth(math.max(60, width - 78))
    button.nameText:SetJustifyH("CENTER")
  else
    button.nameText:SetPoint("LEFT", button.health, "LEFT", 8 + (text.nameOffsetX or 0), text.nameOffsetY or 0)
    button.nameText:SetPoint("RIGHT", button.healthText, "LEFT", -5, 0)
    button.nameText:SetJustifyH("LEFT")
  end

  button.healthText:ClearAllPoints()
  button.healthText:SetPoint("RIGHT", button.health, "RIGHT", -5 + (text.healthOffsetX or 0), text.healthOffsetY or 0)

  button.powerText:ClearAllPoints()
  button.powerText:SetPoint("RIGHT", button.power, "RIGHT", -5 + (text.powerOffsetX or 0), text.powerOffsetY or 0)
  self:PositionRaidIcon(button)

  for i = 1, 4 do
    local buff = button.buffIcons[i]
    buff:ClearAllPoints()
    buff:SetPoint("TOPRIGHT", button, "TOPRIGHT", -((i - 1) * 14) - 20 + (auras.buffOffsetX or 0), -2 + (auras.buffOffsetY or 0))

    local debuff = button.debuffIcons[i]
    debuff:ClearAllPoints()
    debuff:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 6 + ((i - 1) * 14) + (auras.debuffOffsetX or 0), 2 + (auras.debuffOffsetY or 0))
  end
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
end

function SF:EnsurePreviewData()
  if self.previewData then
    return
  end

  self.previewData = {}
  local debuffs = { nil, "Magic", nil, "Poison", nil, "Curse", nil, "Disease" }
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
        local name, subgroup, classFile
        if GetRaidRosterInfo then
          local rosterName, _, rosterSubgroup, _, _, rosterClassFile = GetRaidRosterInfo(i)
          name = rosterName
          subgroup = rosterSubgroup
          classFile = rosterClassFile
        end
        if not name then
          name = UnitName(unit)
        end
        if not classFile then
          local _, detected = UnitClass(unit)
          classFile = detected
        end
        roster[#roster + 1] = {
          unit = unit,
          name = name,
          classFile = classFile,
          subgroup = subgroup or math.floor((i - 1) / 5) + 1,
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
  end
end

function SF:LayoutRoster(roster, isRaid)
  local db = self.db.layout
  local width = db.width
  local height = db.height
  local spacing = db.spacing
  local unitGrowth = db.unitGrowth
  local groupColumns = self:Clamp(db.groupColumns, 1, 8)
  local showHeaders = isRaid and db.showRaidHeaders
  local handleHeight = self:UpdateHandleVisibility()

  self.content:ClearAllPoints()
  self.content:SetPoint("TOPLEFT", self.anchor, "TOPLEFT", 0, -handleHeight)

  for i = 1, 8 do
    self.headers[i]:Hide()
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
    if entry.isPlayer then
      table.insert(groups[subgroup], 1, i)
    else
      groups[subgroup][#groups[subgroup] + 1] = i
    end
  end

  local maxMembers = 5
  local groupWidth
  local groupHeight

  if unitGrowth == "RIGHT" then
    groupWidth = (width * maxMembers) + (spacing * (maxMembers - 1))
    groupHeight = height + (showHeaders and (HEADER_HEIGHT + spacing) or 0)
  else
    groupWidth = width
    groupHeight = (height * maxMembers) + (spacing * (maxMembers - 1)) + (showHeaders and (HEADER_HEIGHT + spacing) or 0)
  end

  local visibleGroups = 0
  local totalWidth = 0
  local totalHeight = 0

  for subgroup = 1, 8 do
    local members = groups[subgroup]
    if #members > 0 then
      visibleGroups = visibleGroups + 1
      local gridCol = (visibleGroups - 1) % groupColumns
      local gridRow = math.floor((visibleGroups - 1) / groupColumns)
      local groupX = gridCol * (groupWidth + spacing * 2)
      local groupY = -gridRow * (groupHeight + spacing * 2)
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

      totalWidth = math.max(totalWidth, groupX + groupWidth)
      totalHeight = math.max(totalHeight, math.abs(groupY) + groupHeight)
    end
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
  self:SetRaidIcon(button.raidIcon, nil)
  self:PositionRaidIcon(button)
  self:UpdateAuraIndicators(button, nil, nil)
end

function SF:UpdateButtonDemo(button, entry)
  button.nameText:SetText(entry.name or "")

  local r, g, b = self:GetClassColorByFile(entry.classFile)
  self:SetTextureColor(button.classStrip, r, g, b, 1)
  button.nameText:SetTextColor(r, g, b, 1)

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
  classFile = classFile or entry.classFile

  button.nameText:SetText(name)
  local r, g, b = self:GetClassColor(unit, classFile)
  self:SetTextureColor(button.classStrip, r, g, b, 1)
  button.nameText:SetTextColor(r, g, b, 1)

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
end

function SF:UpdateUnit(unit)
  if not unit or self.db.preview.mode ~= "off" then
    return
  end

  local button = self.unitToButton and self.unitToButton[unit]
  if button then
    self:UpdateButtonUnit(button, unit)
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

function SF:ApplyPendingProtected()
  if self.pendingProtected then
    self:RefreshRoster()
  end
  if self.pendingBlizzard then
    self:ApplyBlizzardFrames()
  end
end
