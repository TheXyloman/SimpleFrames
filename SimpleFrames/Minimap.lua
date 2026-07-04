local _, SF = ...

local MINIMAP_RADIUS = 80
local MINIMAP_ICON_TEXTURE = "Interface\\AddOns\\SimpleFrames\\Icon.tga"

function SF:CreateMinimapButton()
  if self.minimapButton or not Minimap then
    return
  end

  local button = CreateFrame("Button", "SimpleFramesMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  self.minimapButton = button

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetPoint("CENTER", button, "CENTER", 0, 0)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  button.background = background

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetTexture(MINIMAP_ICON_TEXTURE)
  button.icon = icon

  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  button.overlay = overlay

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "LeftButton" then
      SF:ToggleOptions()
    elseif mouseButton == "RightButton" then
      SF:SetPreviewMode("off")
    end
  end)

  button:SetScript("OnDragStart", function()
    button:SetScript("OnUpdate", function()
      SF:UpdateMinimapButtonFromCursor()
    end)
  end)

  button:SetScript("OnDragStop", function()
    button:SetScript("OnUpdate", nil)
  end)

  button:SetScript("OnMouseUp", function()
    button:SetScript("OnUpdate", nil)
  end)

  button:SetScript("OnEnter", function()
    if not GameTooltip then
      return
    end
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("SimpleFrames", 0.55, 0.74, 1)
    GameTooltip:AddLine("Left click: options", 1, 1, 1)
    GameTooltip:AddLine("Right click: stop preview", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag to move", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)

  self:RefreshMinimapButton()
end

function SF:UpdateMinimapButtonPosition()
  local button = self.minimapButton
  if not button or not self.db or not self.db.minimap then
    return
  end

  local angle = math.rad(self.db.minimap.angle or 225)
  local x = math.cos(angle) * MINIMAP_RADIUS
  local y = math.sin(angle) * MINIMAP_RADIUS

  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function SF:UpdateMinimapButtonFromCursor()
  if not self.minimapButton or not Minimap or not self.db or not self.db.minimap then
    return
  end

  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  if not mx or not my or not px or not py or not scale or scale == 0 then
    return
  end

  px = px / scale
  py = py / scale

  self.db.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
  self:UpdateMinimapButtonPosition()
end

function SF:RefreshMinimapButton()
  if not self.minimapButton then
    return
  end

  self:UpdateMinimapButtonPosition()

  if self.db and self.db.minimap and self.db.minimap.show then
    self.minimapButton:Show()
  else
    self.minimapButton:Hide()
  end
end
