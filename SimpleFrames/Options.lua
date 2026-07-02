local _, SF = ...

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local PANEL_WIDTH = 520
local PANEL_HEIGHT = 620

function SF:CreateOptions()
  if self.optionsFrame then
    return
  end

  self.optionControls = {}
  self.optionPanels = {}
  self.optionTabs = {}

  local frame = CreateFrame("Frame", "SimpleFramesOptions", UIParent, BACKDROP_TEMPLATE)
  frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  self:ApplyBackdrop(frame, 0.035, 0.038, 0.045, 0.98, 0.18, 0.20, 0.24, 1)
  self:RestoreFramePosition(frame, self.db.optionsPosition, self.defaults.optionsPosition)
  frame:Hide()
  self.optionsFrame = frame

  frame:SetScript("OnDragStart", function(f)
    f:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    SF:SaveFramePosition(f, SF.db.optionsPosition)
  end)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
  title:SetText("SimpleFrames")
  title:SetTextColor(0.88, 0.92, 0.96, 1)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

  local tabs = {
    { key = "general", label = "General" },
    { key = "layout", label = "Layout" },
    { key = "text", label = "Text" },
    { key = "auras", label = "Auras" },
    { key = "blizzard", label = "Blizzard UI" },
    { key = "preview", label = "Preview" },
  }

  local lastTab
  for i = 1, #tabs do
    local tab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    tab:SetSize(i == 5 and 88 or 72, 22)
    if lastTab then
      tab:SetPoint("LEFT", lastTab, "RIGHT", 4, 0)
    else
      tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -46)
    end
    tab:SetText(tabs[i].label)
    tab.key = tabs[i].key
    tab:SetScript("OnClick", function(button)
      SF:ShowOptionsTab(button.key)
    end)
    self.optionTabs[tabs[i].key] = tab
    lastTab = tab

    local panel = CreateFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -82)
    panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    panel:Hide()
    self.optionPanels[tabs[i].key] = panel
  end

  self:BuildGeneralOptions(self.optionPanels.general)
  self:BuildLayoutOptions(self.optionPanels.layout)
  self:BuildTextOptions(self.optionPanels.text)
  self:BuildAuraOptions(self.optionPanels.auras)
  self:BuildBlizzardOptions(self.optionPanels.blizzard)
  self:BuildPreviewOptions(self.optionPanels.preview)

  self:ShowOptionsTab("general")
end

function SF:TrackOptionControl(control)
  self.optionControls[#self.optionControls + 1] = control
end

function SF:ShowOptionsTab(key)
  if not self.optionPanels then
    return
  end

  for tabKey, panel in pairs(self.optionPanels) do
    if tabKey == key then
      panel:Show()
      if self.optionTabs[tabKey] then
        self.optionTabs[tabKey]:Disable()
      end
    else
      panel:Hide()
      if self.optionTabs[tabKey] then
        self.optionTabs[tabKey]:Enable()
      end
    end
  end
  self.activeOptionsTab = key
  self:RefreshOptions()
end

function SF:ToggleOptions()
  self:CreateOptions()
  if self.optionsFrame:IsShown() then
    self.optionsFrame:Hide()
  else
    self.optionsFrame:Show()
    self:RefreshOptions()
  end
end

function SF:RefreshOptions()
  if not self.optionControls then
    return
  end

  for i = 1, #self.optionControls do
    local control = self.optionControls[i]
    if control.Refresh then
      control:Refresh()
    end
  end
end

function SF:CreateSectionTitle(parent, text, x, y)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  title:SetText(text)
  title:SetTextColor(0.82, 0.88, 0.94, 1)
  return title
end

function SF:CreateCheck(parent, label, x, y, getter, setter, protectedChange)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  check:SetSize(24, 24)

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", check, "RIGHT", 2, 0)
  text:SetText(label)
  check.label = text

  check:SetScript("OnClick", function(button)
    setter(button:GetChecked() and true or false)
    SF:OnOptionChanged(protectedChange)
  end)

  function check:Refresh()
    self:SetChecked(getter() and true or false)
  end

  self:TrackOptionControl(check)
  return check
end

function SF:CreateCommandButton(parent, label, x, y, width, onClick, enabledGetter)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  button:SetSize(width or 120, 24)
  button:SetText(label)
  button:SetScript("OnClick", onClick)

  if enabledGetter then
    function button:Refresh()
      if enabledGetter() then
        self:Enable()
      else
        self:Disable()
      end
    end
    self:TrackOptionControl(button)
  end

  return button
end

function SF:CreateEditBox(parent, label, x, y, width, getter, setter)
  self.editBoxCount = (self.editBoxCount or 0) + 1
  local name = "SimpleFramesEditBox" .. self.editBoxCount

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local editBox = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
  editBox:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 5, -6)
  editBox:SetSize(width or 160, 24)
  editBox:SetAutoFocus(false)
  editBox:SetMaxLetters(32)
  if editBox.SetTextInsets then
    editBox:SetTextInsets(4, 4, 0, 0)
  end

  editBox:SetScript("OnTextChanged", function(box)
    if box.refreshing then
      return
    end
    setter(box:GetText() or "")
  end)

  editBox:SetScript("OnEnterPressed", function(box)
    setter(box:GetText() or "")
    box:ClearFocus()
  end)

  editBox:SetScript("OnEscapePressed", function(box)
    box.refreshing = true
    box:SetText(getter() or "")
    box.refreshing = false
    box:ClearFocus()
  end)

  function editBox:Refresh()
    if self:HasFocus() then
      return
    end

    local value = getter() or ""
    if self:GetText() ~= value then
      self.refreshing = true
      self:SetText(value)
      self.refreshing = false
    end
  end

  self:TrackOptionControl(editBox)
  return editBox
end

function SF:CreateSlider(parent, label, x, y, minValue, maxValue, step, getter, setter, protectedChange)
  self.sliderCount = (self.sliderCount or 0) + 1
  local name = "SimpleFramesSlider" .. self.sliderCount
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  slider:SetWidth(180)
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step or 1)
  if slider.SetObeyStepOnDrag then
    slider:SetObeyStepOnDrag(true)
  end

  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetPoint("LEFT", slider, "LEFT", 0, 0)
  track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
  track:SetHeight(4)
  SF:SetTextureColor(track, 0.30, 0.32, 0.36, 0.85)
  slider.track = track

  local fill = slider:CreateTexture(nil, "BORDER")
  fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
  fill:SetHeight(4)
  SF:SetTextureColor(fill, 0.65, 0.76, 0.95, 0.95)
  slider.fill = fill

  local function updateFill(s, value)
    local range = maxValue - minValue
    local ratio = range > 0 and ((value - minValue) / range) or 0
    if ratio < 0 then
      ratio = 0
    elseif ratio > 1 then
      ratio = 1
    end
    s.fill:SetWidth(math.max(1, 180 * ratio))
  end

  local labelText = _G[name .. "Text"]
  local low = _G[name .. "Low"]
  local high = _G[name .. "High"]
  if low then
    low:SetText(tostring(minValue))
  end
  if high then
    high:SetText(tostring(maxValue))
  end

  slider:SetScript("OnValueChanged", function(s, value)
    if s.refreshing then
      return
    end
    local rounded = SF:RoundToStep(value, step or 1)
    setter(rounded)
    if labelText then
      labelText:SetText(label .. ": " .. rounded)
    end
    updateFill(s, rounded)
    SF:OnOptionChanged(protectedChange)
  end)

  function slider:Refresh()
    local value = getter()
    self.refreshing = true
    self:SetValue(value)
    self.refreshing = false
    if labelText then
      labelText:SetText(label .. ": " .. value)
    end
    updateFill(self, value)
  end

  self:TrackOptionControl(slider)
  return slider
end

function SF:CreateDropdown(parent, label, x, y, width, values, getter, setter, protectedChange)
  if not UIDropDownMenu_CreateInfo or not UIDropDownMenu_Initialize or not UIDropDownMenu_AddButton or not UIDropDownMenu_SetText or not UIDropDownMenu_SetWidth then
    return self:CreateCycle(parent, label, x, y, width, values, getter, setter, protectedChange)
  end

  self.dropdownCount = (self.dropdownCount or 0) + 1
  local name = "SimpleFramesDropdown" .. self.dropdownCount

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -16, -2)
  dropdown.values = values

  local function findText(value)
    for i = 1, #values do
      if values[i].value == value then
        return values[i].text
      end
    end
    return values[1] and values[1].text or ""
  end

  UIDropDownMenu_SetWidth(dropdown, width or 130)
  UIDropDownMenu_Initialize(dropdown, function(_, level)
    local selected = getter()
    for i = 1, #values do
      local info = UIDropDownMenu_CreateInfo()
      info.text = values[i].text
      info.value = values[i].value
      info.checked = values[i].value == selected
      info.func = function(item)
        setter(item.value)
        UIDropDownMenu_SetText(dropdown, findText(item.value))
        SF:OnOptionChanged(protectedChange)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  function dropdown:Refresh()
    UIDropDownMenu_SetText(self, findText(getter()))
  end

  self:TrackOptionControl(dropdown)
  return dropdown
end

function SF:CreateDynamicDropdown(parent, label, x, y, width, getValues, getter, setter)
  if not UIDropDownMenu_CreateInfo or not UIDropDownMenu_Initialize or not UIDropDownMenu_AddButton or not UIDropDownMenu_SetText or not UIDropDownMenu_SetWidth then
    return self:CreateDynamicCycle(parent, label, x, y, width, getValues, getter, setter)
  end

  self.dropdownCount = (self.dropdownCount or 0) + 1
  local name = "SimpleFramesDropdown" .. self.dropdownCount

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -16, -2)

  local function findText(value)
    local values = getValues()
    for i = 1, #values do
      if values[i].value == value then
        return values[i].text
      end
    end
    return "No saved profiles"
  end

  UIDropDownMenu_SetWidth(dropdown, width or 150)
  UIDropDownMenu_Initialize(dropdown, function(_, level)
    local values = getValues()
    if #values == 0 then
      local info = UIDropDownMenu_CreateInfo()
      info.text = "No saved profiles"
      info.disabled = true
      UIDropDownMenu_AddButton(info, level)
      return
    end

    local selected = getter()
    for i = 1, #values do
      local info = UIDropDownMenu_CreateInfo()
      info.text = values[i].text
      info.value = values[i].value
      info.checked = values[i].value == selected
      info.func = function(item)
        setter(item.value)
        UIDropDownMenu_SetText(dropdown, findText(item.value))
        SF:RefreshOptions()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  function dropdown:Refresh()
    UIDropDownMenu_SetText(self, findText(getter()))
  end

  self:TrackOptionControl(dropdown)
  return dropdown
end

function SF:CreateDynamicCycle(parent, label, x, y, width, getValues, getter, setter)
  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
  button:SetSize(width or 150, 24)

  local function findIndex(values, value)
    for i = 1, #values do
      if values[i].value == value then
        return i
      end
    end
    return 0
  end

  button:SetScript("OnClick", function()
    local values = getValues()
    if #values == 0 then
      return
    end

    local index = findIndex(values, getter()) + 1
    if index > #values then
      index = 1
    end
    setter(values[index].value)
    SF:RefreshOptions()
  end)

  function button:Refresh()
    local values = getValues()
    if #values == 0 then
      self:SetText("No saved profiles")
      self:Disable()
      return
    end

    self:Enable()
    local selected = getter()
    local index = findIndex(values, selected)
    if index == 0 then
      index = 1
    end
    self:SetText(values[index].text)
  end

  self:TrackOptionControl(button)
  return button
end

function SF:CreateCycle(parent, label, x, y, width, values, getter, setter, protectedChange)
  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -4)
  button:SetSize(width or 130, 24)
  button.values = values

  local function findIndex(value)
    for i = 1, #values do
      if values[i].value == value then
        return i
      end
    end
    return 1
  end

  button:SetScript("OnClick", function(b)
    local index = findIndex(getter()) + 1
    if index > #values then
      index = 1
    end
    setter(values[index].value)
    SF:OnOptionChanged(protectedChange)
  end)

  function button:Refresh()
    local index = findIndex(getter())
    self:SetText(values[index].text)
  end

  self:TrackOptionControl(button)
  return button
end

function SF:OnOptionChanged(protectedChange)
  self:RefreshOptions()
  if protectedChange then
    self:RequestProtectedRefresh()
  else
    self:RefreshAllUnitData()
    self:UpdateAnchorVisibility()
  end
end

function SF:SetProfileStatus(message)
  self.profileStatusMessage = message or ""
  if self.profileStatusText then
    self.profileStatusText:SetText(self.profileStatusMessage)
  end
end

function SF:BuildGeneralOptions(panel)
  self:CreateSectionTitle(panel, "General", 0, 0)

  self:CreateCheck(panel, "Lock frames", 0, -28,
    function() return SF.db.locked end,
    function(value) SF.db.locked = value; SF:ApplyLockState() end,
    false
  )

  self:CreateCheck(panel, "Show minimap button", 220, -28,
    function() return SF.db.minimap.show end,
    function(value) SF.db.minimap.show = value; SF:RefreshMinimapButton() end,
    false
  )

  self:CreateCommandButton(panel, "Unlock", 0, -70, 90, function()
    SF.db.locked = false
    SF:ApplyLockState()
    SF:RefreshOptions()
  end)

  self:CreateCommandButton(panel, "Lock", 98, -70, 90, function()
    SF.db.locked = true
    SF:ApplyLockState()
    SF:RefreshOptions()
  end)

  self:CreateCommandButton(panel, "Reset frame", 196, -70, 120, function()
    SF.db.framePosition = SF:CopyDefaults(SF.defaults.framePosition, {})
    SF:RestoreFramePosition(SF.anchor, SF.db.framePosition, SF.defaults.framePosition)
  end)

  self:CreateCommandButton(panel, "Reset options", 324, -70, 120, function()
    SF.db.optionsPosition = SF:CopyDefaults(SF.defaults.optionsPosition, {})
    SF:RestoreFramePosition(SF.optionsFrame, SF.db.optionsPosition, SF.defaults.optionsPosition)
  end)

  self:CreateSectionTitle(panel, "Preview", 0, -122)

  self:CreateCommandButton(panel, "Party test", 0, -152, 110, function()
    SF:SetPreviewMode("party")
  end)

  self:CreateCommandButton(panel, "Raid test", 122, -152, 110, function()
    SF:SetPreviewMode("raid")
  end)

  self:CreateCommandButton(panel, "Turn off", 244, -152, 110, function()
    SF:SetPreviewMode("off")
  end)

  self:CreateCommandButton(panel, "Reset all", 0, -204, 120, function()
    SF:ResetDatabase()
  end)

  self:CreateSectionTitle(panel, "Profiles", 0, -254)

  self:CreateEditBox(panel, "Profile name", 0, -284, 180,
    function() return SF:GetProfileNameInput() end,
    function(value) SF:SetProfileNameInput(value) end
  )

  self:CreateDynamicDropdown(panel, "Saved profile", 230, -284, 170,
    function() return SF:BuildProfileDropdownValues() end,
    function() return SF:GetSelectedProfileName() end,
    function(value) SF:SetSelectedProfileName(value) end
  )

  self:CreateCommandButton(panel, "Save", 0, -352, 88, function()
    SF:SaveProfile(SF:GetProfileNameInput())
  end)

  self:CreateCommandButton(panel, "Load", 98, -352, 88, function()
    SF:LoadProfile(SF:GetSelectedProfileName())
  end, function()
    return SF:GetSelectedProfileName() ~= nil
  end)

  self:CreateCommandButton(panel, "Delete", 196, -352, 88, function()
    SF:DeleteProfile(SF:GetSelectedProfileName())
  end, function()
    return SF:GetSelectedProfileName() ~= nil
  end)

  self.profileStatusText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.profileStatusText:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -392)
  self.profileStatusText:SetWidth(440)
  self.profileStatusText:SetJustifyH("LEFT")
  self.profileStatusText:SetTextColor(0.72, 0.82, 0.96, 1)
  self.profileStatusText:SetText(self.profileStatusMessage or "")
end

function SF:BuildLayoutOptions(panel)
  self:CreateSectionTitle(panel, "Layout", 0, 0)

  self:CreateSlider(panel, "Width", 0, -34, 90, 280, 1,
    function() return SF.db.layout.width end,
    function(value) SF.db.layout.width = value end,
    true
  )

  self:CreateSlider(panel, "Height", 250, -34, 24, 86, 1,
    function() return SF.db.layout.height end,
    function(value) SF.db.layout.height = value end,
    true
  )

  self:CreateSlider(panel, "Mana height", 0, -94, 0, 18, 1,
    function() return SF.db.layout.powerHeight end,
    function(value) SF.db.layout.powerHeight = value end,
    true
  )

  self:CreateSlider(panel, "Spacing", 250, -94, 0, 14, 1,
    function() return SF.db.layout.spacing end,
    function(value) SF.db.layout.spacing = value end,
    true
  )

  self:CreateSlider(panel, "Group columns", 250, -154, 1, 8, 1,
    function() return SF.db.layout.groupColumns end,
    function(value) SF.db.layout.groupColumns = value end,
    true
  )

  self:CreateCycle(panel, "Member direction", 0, -220, 130, {
    { value = "DOWN", text = "Vertical" },
    { value = "RIGHT", text = "Horizontal" },
  },
    function() return SF.db.layout.unitGrowth end,
    function(value) SF.db.layout.unitGrowth = value end,
    true
  )

  self:CreateCheck(panel, "Show mana/power bar", 250, -218,
    function() return SF.db.layout.showPower end,
    function(value) SF.db.layout.showPower = value end,
    true
  )

  self:CreateCheck(panel, "Show raid group headers", 250, -250,
    function() return SF.db.layout.showRaidHeaders end,
    function(value) SF.db.layout.showRaidHeaders = value end,
    true
  )
end

function SF:BuildTextOptions(panel)
  self:CreateSectionTitle(panel, "Text", 0, 0)

  local formats = {
    { value = "percent", text = "Percent" },
    { value = "raw", text = "Raw" },
    { value = "both", text = "Raw + percent" },
    { value = "off", text = "Off" },
  }

  self:CreateDropdown(panel, "Health text", 0, -34, 150, formats,
    function() return SF.db.text.health end,
    function(value) SF.db.text.health = value end,
    false
  )

  self:CreateDropdown(panel, "Mana text", 220, -34, 150, formats,
    function() return SF.db.text.power end,
    function(value) SF.db.text.power = value end,
    false
  )

  self:CreateDropdown(panel, "Name position", 0, -100, 150, {
    { value = "left", text = "Upper left" },
    { value = "center", text = "Center" },
  },
    function() return SF.db.text.namePosition end,
    function(value) SF.db.text.namePosition = value end,
    true
  )

  self:CreateCheck(panel, "Show raid target icons", 220, -100,
    function() return SF.db.layout.showRaidIcons end,
    function(value) SF.db.layout.showRaidIcons = value end,
    false
  )

  self:CreateSlider(panel, "Raid icon size", 250, -132, 8, 24, 1,
    function() return SF.db.layout.raidIconSize end,
    function(value) SF.db.layout.raidIconSize = value end,
    true
  )

  self:CreateSectionTitle(panel, "Font sizes", 0, -158)

  self:CreateSlider(panel, "Name", 0, -190, 6, 24, 1,
    function() return SF.db.text.nameFontSize end,
    function(value) SF.db.text.nameFontSize = value end,
    true
  )

  self:CreateSlider(panel, "Health", 250, -190, 6, 24, 1,
    function() return SF.db.text.healthFontSize end,
    function(value) SF.db.text.healthFontSize = value end,
    true
  )

  self:CreateSlider(panel, "Mana", 0, -250, 6, 24, 1,
    function() return SF.db.text.powerFontSize end,
    function(value) SF.db.text.powerFontSize = value end,
    true
  )

  self:CreateSectionTitle(panel, "Positions", 0, -310)

  self:CreateSlider(panel, "Name X", 0, -342, -40, 40, 1,
    function() return SF.db.text.nameOffsetX end,
    function(value) SF.db.text.nameOffsetX = value end,
    true
  )

  self:CreateSlider(panel, "Name Y", 250, -342, -20, 20, 1,
    function() return SF.db.text.nameOffsetY end,
    function(value) SF.db.text.nameOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Health X", 0, -402, -40, 40, 1,
    function() return SF.db.text.healthOffsetX end,
    function(value) SF.db.text.healthOffsetX = value end,
    true
  )

  self:CreateSlider(panel, "Health Y", 250, -402, -20, 20, 1,
    function() return SF.db.text.healthOffsetY end,
    function(value) SF.db.text.healthOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Mana X", 0, -462, -40, 40, 1,
    function() return SF.db.text.powerOffsetX end,
    function(value) SF.db.text.powerOffsetX = value end,
    true
  )

  self:CreateSlider(panel, "Mana Y", 250, -462, -20, 20, 1,
    function() return SF.db.text.powerOffsetY end,
    function(value) SF.db.text.powerOffsetY = value end,
    true
  )
end

function SF:BuildAuraOptions(panel)
  self:CreateSectionTitle(panel, "Auras", 0, 0)

  self:CreateDropdown(panel, "Aura mode", 0, -34, 150, {
    { value = "both", text = "Buffs + debuffs" },
    { value = "debuffs", text = "Debuffs only" },
    { value = "buffs", text = "Buffs only" },
    { value = "off", text = "Off" },
  },
    function() return SF.db.auras.mode end,
    function(value) SF.db.auras.mode = value end,
    false
  )

  self:CreateSlider(panel, "Buff icons", 220, -34, 0, 4, 1,
    function() return SF.db.auras.maxBuffs end,
    function(value) SF.db.auras.maxBuffs = value end,
    false
  )

  self:CreateSlider(panel, "Debuff icons", 0, -104, 0, 4, 1,
    function() return SF.db.auras.maxDebuffs end,
    function(value) SF.db.auras.maxDebuffs = value end,
    false
  )

  self:CreateSlider(panel, "Low health", 220, -104, 5, 40, 1,
    function() return SF.db.auras.lowHealthThreshold end,
    function(value) SF.db.auras.lowHealthThreshold = value end,
    false
  )

  self:CreateCheck(panel, "Show stun and silence indicators", 0, -170,
    function() return SF.db.auras.showCrowdControl end,
    function(value) SF.db.auras.showCrowdControl = value end,
    false
  )

  self:CreateSectionTitle(panel, "Icon positions", 0, -222)

  self:CreateSlider(panel, "Buff X", 0, -254, -40, 40, 1,
    function() return SF.db.auras.buffOffsetX end,
    function(value) SF.db.auras.buffOffsetX = value end,
    true
  )

  self:CreateSlider(panel, "Buff Y", 250, -254, -20, 20, 1,
    function() return SF.db.auras.buffOffsetY end,
    function(value) SF.db.auras.buffOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Debuff X", 0, -314, -40, 40, 1,
    function() return SF.db.auras.debuffOffsetX end,
    function(value) SF.db.auras.debuffOffsetX = value end,
    true
  )

  self:CreateSlider(panel, "Debuff Y", 250, -314, -20, 20, 1,
    function() return SF.db.auras.debuffOffsetY end,
    function(value) SF.db.auras.debuffOffsetY = value end,
    true
  )
end

function SF:BuildBlizzardOptions(panel)
  self:CreateSectionTitle(panel, "Blizzard UI", 0, 0)

  self:CreateCheck(panel, "Hide Blizzard party and raid frames", 0, -34,
    function() return SF.db.hideBlizzard end,
    function(value) SF.db.hideBlizzard = value; SF:ApplyBlizzardFrames() end,
    false
  )

  self:CreateCommandButton(panel, "Apply now", 0, -78, 120, function()
    SF:ApplyBlizzardFrames()
  end)

  self:CreateCommandButton(panel, "Restore now", 132, -78, 120, function()
    SF.db.hideBlizzard = false
    SF:ApplyBlizzardFrames()
    SF:RefreshOptions()
  end)
end

function SF:BuildPreviewOptions(panel)
  self:CreateSectionTitle(panel, "Preview", 0, 0)

  self:CreateCommandButton(panel, "Party test", 0, -34, 110, function()
    SF:SetPreviewMode("party")
  end)

  self:CreateCommandButton(panel, "Raid test", 122, -34, 110, function()
    SF:SetPreviewMode("raid")
  end)

  self:CreateCommandButton(panel, "Turn off", 244, -34, 110, function()
    SF:SetPreviewMode("off")
  end)

  self:CreateCheck(panel, "Animate preview", 0, -78,
    function() return SF.db.preview.animate end,
    function(value)
      SF.db.preview.animate = value
      if value and SF.db.preview.mode ~= "off" then
        SF:StartPreviewTicker()
      elseif not value then
        SF:StopPreviewTicker()
      end
    end,
    false
  )
end
