local _, SF = ...

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local PANEL_WIDTH = 520
local PANEL_HEIGHT = 620
local TAB_HEIGHT = 24
local SPELL_SUGGESTION_ROWS = 7
local SPELL_SUGGESTION_ROW_HEIGHT = 20
local LOGO_TEXTURE = "Interface\\AddOns\\SimpleFrames\\Logo.tga"

local function getFrameXOffsetMax()
  local width = SF.db and SF.db.layout and tonumber(SF.db.layout.width) or 0
  return math.max(0, width)
end

local function buildSpellList()
  local spells = {}
  local seen = {}

  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemInfo or not GetSpellBookItemName then
    return spells
  end

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
        local name, subName = GetSpellBookItemName(slot, bookType)
        if name and name ~= "" then
          local display = name
          if subName and subName ~= "" then
            display = name .. "(" .. subName .. ")"
          end

          if not seen[display] then
            seen[display] = true
            spells[#spells + 1] = display
          end
        end
      end
    end
  end

  table.sort(spells)
  return spells
end

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
  frame:SetScript("OnHide", function()
    SF:HideSpellSuggestions()
  end)

  local headerBg = frame:CreateTexture(nil, "BACKGROUND")
  headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  headerBg:SetHeight(76)
  self:SetTextureColor(headerBg, 0.055, 0.062, 0.074, 0.98)
  frame.headerBg = headerBg

  local contentBg = frame:CreateTexture(nil, "BACKGROUND")
  contentBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -84)
  contentBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
  self:SetTextureColor(contentBg, 0.020, 0.023, 0.029, 0.48)
  frame.contentBg = contentBg

  local divider = frame:CreateTexture(nil, "BORDER")
  divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -78)
  divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -78)
  divider:SetHeight(1)
  self:SetTextureColor(divider, 0.22, 0.26, 0.32, 0.90)
  frame.divider = divider

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
  title:SetText("SimpleFrames")
  title:SetTextColor(0.88, 0.92, 0.96, 1)

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("LEFT", title, "RIGHT", 10, 0)
  subtitle:SetText("Party and raid frames")
  subtitle:SetTextColor(0.58, 0.66, 0.76, 1)
  frame.subtitle = subtitle

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

  local tabs = {
    { key = "general", label = "General", width = 62 },
    { key = "layout", label = "Layout", width = 58 },
    { key = "text", label = "Text", width = 50 },
    { key = "auras", label = "Auras", width = 58 },
    { key = "spells", label = "Spells", width = 62 },
    { key = "blizzard", label = "Blizzard UI", width = 84 },
    { key = "preview", label = "Preview", width = 64 },
  }

  local lastTab
  for i = 1, #tabs do
    local tab = CreateFrame("Button", nil, frame)
    tab:SetSize(tabs[i].width or 72, TAB_HEIGHT)
    if lastTab then
      tab:SetPoint("LEFT", lastTab, "RIGHT", 4, 0)
    else
      tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -48)
    end

    local tabBg = tab:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints(tab)
    tab.bg = tabBg

    local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tabText:SetText(tabs[i].label)
    tab.text = tabText

    local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(tab)
    self:SetTextureColor(highlight, 1, 1, 1, 0.07)
    tab:SetHighlightTexture(highlight)

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
  self:BuildSpellOptions(self.optionPanels.spells)
  self:BuildBlizzardOptions(self.optionPanels.blizzard)
  self:BuildPreviewOptions(self.optionPanels.preview)

  self:ShowOptionsTab("general")
end

function SF:TrackOptionControl(control)
  self.optionControls[#self.optionControls + 1] = control
end

function SF:StyleOptionTab(tab, selected)
  if not tab then
    return
  end

  if selected then
    self:SetTextureColor(tab.bg, 0.16, 0.20, 0.27, 0.96)
    tab.text:SetTextColor(0.94, 0.97, 1.00, 1)
  else
    self:SetTextureColor(tab.bg, 0.060, 0.070, 0.086, 0.78)
    tab.text:SetTextColor(0.66, 0.74, 0.84, 1)
  end
end

function SF:ShowOptionsTab(key)
  if not self.optionPanels then
    return
  end

  if self.HideSpellSuggestions then
    self:HideSpellSuggestions()
  end

  for tabKey, panel in pairs(self.optionPanels) do
    if tabKey == key then
      panel:Show()
    else
      panel:Hide()
    end
    self:StyleOptionTab(self.optionTabs[tabKey], tabKey == key)
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

  local line = parent:CreateTexture(nil, "BACKGROUND")
  line:SetPoint("LEFT", title, "RIGHT", 8, -1)
  line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
  line:SetHeight(1)
  self:SetTextureColor(line, 0.18, 0.22, 0.28, 0.75)

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

function SF:CreateEditBox(parent, label, x, y, width, getter, setter, maxLetters, callbacks)
  self.editBoxCount = (self.editBoxCount or 0) + 1
  local name = "SimpleFramesEditBox" .. self.editBoxCount

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetText(label)

  local editBox = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
  editBox:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 5, -6)
  editBox:SetSize(width or 160, 24)
  editBox:SetAutoFocus(false)
  editBox:SetMaxLetters(maxLetters or 32)
  if editBox.SetTextInsets then
    editBox:SetTextInsets(4, 4, 0, 0)
  end

  editBox:SetScript("OnTextChanged", function(box)
    if box.refreshing then
      return
    end
    setter(box:GetText() or "")
    if callbacks and callbacks.onTextChanged then
      callbacks.onTextChanged(box)
    end
  end)

  editBox:SetScript("OnEnterPressed", function(box)
    if callbacks and callbacks.onEnterPressed and callbacks.onEnterPressed(box) then
      return
    end
    setter(box:GetText() or "")
    box:ClearFocus()
  end)

  editBox:SetScript("OnEscapePressed", function(box)
    if callbacks and callbacks.onEscapePressed then
      callbacks.onEscapePressed(box)
    end
    box.refreshing = true
    box:SetText(getter() or "")
    box.refreshing = false
    box:ClearFocus()
  end)

  if callbacks and callbacks.onFocusGained then
    editBox:SetScript("OnEditFocusGained", function(box)
      callbacks.onFocusGained(box)
    end)
  end

  if callbacks and callbacks.onFocusLost then
    editBox:SetScript("OnEditFocusLost", function(box)
      callbacks.onFocusLost(box)
    end)
  end

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

function SF:GetSpellSuggestionList(refresh)
  if refresh or not self.spellSuggestionList then
    self.spellSuggestionList = buildSpellList()
  end
  return self.spellSuggestionList
end

function SF:EnsureSpellSuggestionFrame()
  if self.spellSuggestionFrame then
    return self.spellSuggestionFrame
  end

  local frame = CreateFrame("Frame", "SimpleFramesSpellSuggestions", UIParent, BACKDROP_TEMPLATE)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  if frame.SetToplevel then
    frame:SetToplevel(true)
  end
  frame:EnableMouse(true)
  self:ApplyBackdrop(frame, 0.025, 0.028, 0.034, 0.98, 0.32, 0.38, 0.46, 1)
  frame:Hide()

  frame.rows = {}
  for i = 1, SPELL_SUGGESTION_ROWS do
    local row = CreateFrame("Button", nil, frame)
    row:SetHeight(SPELL_SUGGESTION_ROW_HEIGHT)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4 - ((i - 1) * SPELL_SUGGESTION_ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4 - ((i - 1) * SPELL_SUGGESTION_ROW_HEIGHT))

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", row, "LEFT", 4, 0)
    text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetText("")
    row.text = text

    row:SetScript("OnClick", function(button)
      local spell = button.spellText
      if spell and frame.onPick then
        frame.onPick(spell)
      end
      SF:HideSpellSuggestions()
    end)

    frame.rows[i] = row
  end

  self.spellSuggestionFrame = frame
  return frame
end

function SF:HideSpellSuggestions()
  local frame = self.spellSuggestionFrame
  if not frame then
    return
  end

  frame:Hide()
  frame.owner = nil
  frame.onPick = nil
  frame.firstSpell = nil
end

function SF:HideSpellSuggestionsSoon(owner)
  if not C_Timer or not C_Timer.After then
    self:HideSpellSuggestions()
    return
  end

  C_Timer.After(0.12, function()
    local frame = SF.spellSuggestionFrame
    if not frame or not frame:IsShown() or frame.owner ~= owner then
      return
    end
    if owner and owner.HasFocus and owner:HasFocus() then
      return
    end
    if frame.IsMouseOver and frame:IsMouseOver() then
      return
    end
    SF:HideSpellSuggestions()
  end)
end

function SF:ShowSpellSuggestions(owner, text, onPick)
  if not owner or not owner.HasFocus or not owner:HasFocus() then
    self:HideSpellSuggestions()
    return
  end

  local query = tostring(text or "")
  query = string.gsub(query, "^%s+", "")
  query = string.gsub(query, "%s+$", "")
  if query == "" then
    self:HideSpellSuggestions()
    return
  end

  local lowerQuery = string.lower(query)
  local spells = self:GetSpellSuggestionList()
  local matches = {}
  for i = 1, #spells do
    local spell = spells[i]
    local lowerSpell = string.lower(spell)
    if string.sub(lowerSpell, 1, string.len(lowerQuery)) == lowerQuery then
      matches[#matches + 1] = spell
      if #matches >= SPELL_SUGGESTION_ROWS then
        break
      end
    end
  end

  if #matches < SPELL_SUGGESTION_ROWS then
    for i = 1, #spells do
      local spell = spells[i]
      local lowerSpell = string.lower(spell)
      if string.sub(lowerSpell, 1, string.len(lowerQuery)) ~= lowerQuery
        and string.find(lowerSpell, lowerQuery, 1, true) then
        matches[#matches + 1] = spell
        if #matches >= SPELL_SUGGESTION_ROWS then
          break
        end
      end
    end
  end

  if #matches == 0 then
    self:HideSpellSuggestions()
    return
  end

  local frame = self:EnsureSpellSuggestionFrame()
  frame.owner = owner
  frame.onPick = onPick
  frame.firstSpell = matches[1]
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -4)
  frame:SetSize(math.max(owner:GetWidth() or 180, 180), (#matches * SPELL_SUGGESTION_ROW_HEIGHT) + 8)
  if self.optionsFrame then
    frame:SetFrameLevel((self.optionsFrame:GetFrameLevel() or 0) + 50)
  end

  for i = 1, SPELL_SUGGESTION_ROWS do
    local row = frame.rows[i]
    local spell = matches[i]
    if spell then
      row.spellText = spell
      row.text:SetText(spell)
      row:Show()
    else
      row.spellText = nil
      row.text:SetText("")
      row:Hide()
    end
  end

  frame:Show()
end

function SF:AcceptFirstSpellSuggestion(owner)
  local frame = self.spellSuggestionFrame
  if frame and frame:IsShown() and frame.owner == owner and frame.firstSpell and frame.onPick then
    frame.onPick(frame.firstSpell)
    self:HideSpellSuggestions()
    return true
  end
  return false
end

function SF:CreateSlider(parent, label, x, y, minValue, maxValue, step, getter, setter, protectedChange)
  self.sliderCount = (self.sliderCount or 0) + 1
  local name = "SimpleFramesSlider" .. self.sliderCount
  step = step or 1

  local function resolveBound(value, fallback)
    if type(value) == "function" then
      value = value()
    end
    return tonumber(value) or fallback or 0
  end

  local function getBounds()
    local min = resolveBound(minValue, 0)
    local max = resolveBound(maxValue, min)
    if max < min then
      max = min
    end
    return min, max
  end

  local initialMin, initialMax = getBounds()
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  slider:SetWidth(180)
  slider:SetMinMaxValues(initialMin, initialMax)
  slider:SetValueStep(step)
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
    local min, max = getBounds()
    local range = max - min
    local ratio = range > 0 and ((value - min) / range) or 0
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

  local function updateBounds(s)
    local min, max = getBounds()
    s:SetMinMaxValues(min, max)
    if low then
      low:SetText(tostring(min))
    end
    if high then
      high:SetText(tostring(max))
    end
    return min, max
  end

  updateBounds(slider)

  slider:SetScript("OnValueChanged", function(s, value)
    if s.refreshing then
      return
    end
    local min, max = getBounds()
    local rounded = SF:Clamp(SF:RoundToStep(value, step), min, max)
    if rounded ~= value then
      s.refreshing = true
      s:SetValue(rounded)
      s.refreshing = false
    end
    setter(rounded)
    if labelText then
      labelText:SetText(label .. ": " .. rounded)
    end
    updateFill(s, rounded)
    SF:OnOptionChanged(protectedChange)
  end)

  function slider:Refresh()
    self.refreshing = true
    local min, max = updateBounds(self)
    local value = SF:Clamp(SF:RoundToStep(getter(), step), min, max)
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

  local logo = panel:CreateTexture(nil, "ARTWORK")
  logo:SetPoint("TOP", panel, "TOP", 0, -430)
  logo:SetSize(78, 78)
  logo:SetTexture(LOGO_TEXTURE)
  panel.logo = logo

  local link = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  link:SetPoint("TOP", logo, "BOTTOM", 0, -6)
  link:SetText("|cff8fbdf7TheXyloman/SimpleFrames|r - github.com/TheXyloman/SimpleFrames")
  link:SetTextColor(0.72, 0.82, 0.96, 1)
  panel.logoLink = link
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

  self:CreateSlider(panel, "Name X", 0, -342, 0, getFrameXOffsetMax, 1,
    function() return SF.db.text.nameOffsetX end,
    function(value) SF.db.text.nameOffsetX = SF:Clamp(value, 0, getFrameXOffsetMax()) end,
    true
  )

  self:CreateSlider(panel, "Name Y", 250, -342, -20, 20, 1,
    function() return SF.db.text.nameOffsetY end,
    function(value) SF.db.text.nameOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Health X", 0, -402, 0, getFrameXOffsetMax, 1,
    function() return SF.db.text.healthOffsetX end,
    function(value) SF.db.text.healthOffsetX = SF:Clamp(value, 0, getFrameXOffsetMax()) end,
    true
  )

  self:CreateSlider(panel, "Health Y", 250, -402, -20, 20, 1,
    function() return SF.db.text.healthOffsetY end,
    function(value) SF.db.text.healthOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Mana X", 0, -462, 0, getFrameXOffsetMax, 1,
    function() return SF.db.text.powerOffsetX end,
    function(value) SF.db.text.powerOffsetX = SF:Clamp(value, 0, getFrameXOffsetMax()) end,
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

  self:CreateSlider(panel, "Buff size", 0, -170, 8, 28, 1,
    function() return SF.db.auras.buffSize end,
    function(value) SF.db.auras.buffSize = value end,
    true
  )

  self:CreateSlider(panel, "Debuff size", 250, -170, 8, 28, 1,
    function() return SF.db.auras.debuffSize end,
    function(value) SF.db.auras.debuffSize = value end,
    true
  )

  self:CreateCheck(panel, "Show stun and silence indicators", 0, -232,
    function() return SF.db.auras.showCrowdControl end,
    function(value) SF.db.auras.showCrowdControl = value end,
    false
  )

  self:CreateSectionTitle(panel, "Icon positions", 0, -284)

  self:CreateSlider(panel, "Buff X", 0, -316, 0, getFrameXOffsetMax, 1,
    function() return SF.db.auras.buffOffsetX end,
    function(value) SF.db.auras.buffOffsetX = SF:Clamp(value, 0, getFrameXOffsetMax()) end,
    true
  )

  self:CreateSlider(panel, "Buff Y", 250, -316, -20, 20, 1,
    function() return SF.db.auras.buffOffsetY end,
    function(value) SF.db.auras.buffOffsetY = value end,
    true
  )

  self:CreateSlider(panel, "Debuff X", 0, -376, 0, getFrameXOffsetMax, 1,
    function() return SF.db.auras.debuffOffsetX end,
    function(value) SF.db.auras.debuffOffsetX = SF:Clamp(value, 0, getFrameXOffsetMax()) end,
    true
  )

  self:CreateSlider(panel, "Debuff Y", 250, -376, -20, 20, 1,
    function() return SF.db.auras.debuffOffsetY end,
    function(value) SF.db.auras.debuffOffsetY = value end,
    true
  )
end

function SF:BuildSpellOptions(panel)
  self:CreateSectionTitle(panel, "Spells", 0, 0)

  self:CreateCheck(panel, "Enable click-casting", 0, -28,
    function() return SF:EnsureClickCastConfig().enabled end,
    function(value)
      SF:EnsureClickCastConfig().enabled = value
      SF:RequestClickCastRefresh()
    end,
    false
  )

  local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  desc:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -66)
  desc:SetWidth(458)
  desc:SetJustifyH("LEFT")
  desc:SetText("Type exact spell names or pick from spellbook matches as you type. Blank left and right clicks do nothing; middle click still targets real units.")

  local rows = {
    { key = "L", x = 0, y = -120 },
    { key = "R", x = 240, y = -120 },
    { key = "SL", x = 0, y = -190 },
    { key = "SR", x = 240, y = -190 },
    { key = "AL", x = 0, y = -260 },
    { key = "AR", x = 240, y = -260 },
  }

  for i = 1, #rows do
    local row = rows[i]
    local key = row.key
    self:CreateEditBox(panel, self.clickCastBindingLabels[key] or key, row.x, row.y, 180,
      function() return SF:GetClickCastBinding(key) end,
      function(value) SF:SetClickCastBinding(key, value) end,
      64,
      {
        onTextChanged = function(box)
          SF:ShowSpellSuggestions(box, box:GetText(), function(spell)
            SF:SetClickCastBinding(key, spell)
            box.refreshing = true
            box:SetText(spell)
            box.refreshing = false
            box:ClearFocus()
          end)
        end,
        onFocusGained = function(box)
          SF:GetSpellSuggestionList(true)
          SF:ShowSpellSuggestions(box, box:GetText(), function(spell)
            SF:SetClickCastBinding(key, spell)
            box.refreshing = true
            box:SetText(spell)
            box.refreshing = false
            box:ClearFocus()
          end)
        end,
        onFocusLost = function(box)
          SF:HideSpellSuggestionsSoon(box)
        end,
        onEnterPressed = function(box)
          return SF:AcceptFirstSpellSuggestion(box)
        end,
        onEscapePressed = function()
          SF:HideSpellSuggestions()
        end,
      }
    )
  end

  local slash = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  slash:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -342)
  slash:SetWidth(458)
  slash:SetJustifyH("LEFT")
  slash:SetText("Slash command: /sfr bind L|R|SL|SR|AL|AR <spell name>")

  self:CreateSectionTitle(panel, "Prio Targets", 0, -392)

  self:CreateCheck(panel, "Enable prio targets frame", 0, -420,
    function() return SF:EnsurePriorityConfig().enabled end,
    function(value)
      SF:EnsurePriorityConfig().enabled = value
      SF:RefreshPriorityFrame()
    end,
    false
  )

  self:CreateCommandButton(panel, "Clear prio targets", 250, -420, 140, function()
    SF:ClearPriorityTargets()
  end)

  local prioHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  prioHelp:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -464)
  prioHelp:SetWidth(458)
  prioHelp:SetJustifyH("LEFT")
  prioHelp:SetText("Shift + Middle Click a real unit frame to add or remove that unit from the separate Prio targets frame.")
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
