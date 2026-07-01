local ADDON_NAME, SF = ...

function SF:InitDatabase()
  if type(SimpleFramesDB) ~= "table" then
    SimpleFramesDB = {}
  end
  self.db = self:CopyDefaults(self.defaults, SimpleFramesDB)
  SimpleFramesDB = self.db
end

function SF:ResetDatabase()
  SimpleFramesDB = self:CopyDefaults(self.defaults, {})
  self.db = SimpleFramesDB

  if self.anchor then
    self:RestoreFramePosition(self.anchor, self.db.framePosition, self.defaults.framePosition)
  end
  if self.optionsFrame then
    self:RestoreFramePosition(self.optionsFrame, self.db.optionsPosition, self.defaults.optionsPosition)
  end

  self:ApplyLockState()
  self:RefreshMinimapButton()
  self:ApplyBlizzardFrames()
  self:SetPreviewMode("off")
  self:RequestProtectedRefresh()
  self:RefreshOptions()
end

function SF:RegisterRuntimeEvents()
  local frame = self.eventFrame
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("GROUP_ROSTER_UPDATE")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:RegisterEvent("UNIT_HEALTH")
  frame:RegisterEvent("UNIT_MAXHEALTH")
  frame:RegisterEvent("UNIT_POWER_UPDATE")
  frame:RegisterEvent("UNIT_MAXPOWER")
  frame:RegisterEvent("UNIT_DISPLAYPOWER")
  frame:RegisterEvent("UNIT_AURA")
  frame:RegisterEvent("UNIT_NAME_UPDATE")
  frame:RegisterEvent("UNIT_CONNECTION")
  frame:RegisterEvent("RAID_TARGET_UPDATE")
  pcall(function()
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
  end)
end

function SF:OnAddonLoaded()
  self:InitDatabase()
  self:CreateFrames()
  self:CreateOptions()
  self:CreateMinimapButton()
  self:RegisterRuntimeEvents()
  self:RegisterSlashCommands()
  self:RefreshRoster()
  self:ApplyBlizzardFrames()

  if self.db.preview.mode ~= "off" and self.db.preview.animate then
    self:StartPreviewTicker()
  end
end

function SF:RegisterSlashCommands()
  local function isSlashUsed(command)
    command = string.lower(command)
    for listName in pairs(SlashCmdList) do
      local index = 1
      while true do
        local slash = _G["SLASH_" .. listName .. index]
        if not slash then
          break
        end
        if string.lower(slash) == command then
          return true
        end
        index = index + 1
      end
    end
    return false
  end

  SLASH_SIMPLEFRAMES1 = "/simpleframes"
  SLASH_SIMPLEFRAMES2 = "/simpleframe"
  SLASH_SIMPLEFRAMES3 = "/sframes"
  SLASH_SIMPLEFRAMES4 = "/sfr"
  if not isSlashUsed("/sf") then
    SLASH_SIMPLEFRAMES5 = "/sf"
  end

  SlashCmdList.SIMPLEFRAMES = function(message)
    SF:HandleSlash(message)
  end
end

function SF:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff8fbdf7SimpleFrames|r: " .. tostring(message))
end

function SF:HandleSlash(message)
  message = string.lower(message or "")
  message = string.gsub(message, "^%s+", "")
  message = string.gsub(message, "%s+$", "")

  if message == "" or message == "options" or message == "config" then
    self:ToggleOptions()
    return
  end

  if message == "lock" then
    self.db.locked = true
    self:ApplyLockState()
    self:Print("frames locked")
    self:RefreshOptions()
    return
  end

  if message == "unlock" then
    self.db.locked = false
    self:ApplyLockState()
    self:Print("frames unlocked")
    self:RefreshOptions()
    return
  end

  if message == "test party" or message == "preview party" then
    self:SetPreviewMode("party")
    self:Print("party preview enabled")
    return
  end

  if message == "test raid" or message == "preview raid" then
    self:SetPreviewMode("raid")
    self:Print("raid preview enabled")
    return
  end

  if message == "test off" or message == "preview off" then
    self:SetPreviewMode("off")
    self:Print("preview disabled")
    return
  end

  if message == "reset" then
    self:ResetDatabase()
    self:Print("settings reset")
    return
  end

  if message == "hideblizzard" then
    self.db.hideBlizzard = true
    self:ApplyBlizzardFrames()
    self:RefreshOptions()
    self:Print("Blizzard party and raid frames hidden")
    return
  end

  if message == "showblizzard" then
    self.db.hideBlizzard = false
    self:ApplyBlizzardFrames()
    self:RefreshOptions()
    self:Print("Blizzard party and raid frames restored")
    return
  end

  self:Print("/sfr, /sfr lock, /sfr unlock, /sfr test party, /sfr test raid, /sfr test off, /sfr reset")
end

function SF:OnRosterEvent()
  self:RequestProtectedRefresh()
  self:ApplyBlizzardFrames()
end

function SF:OnUnitEvent(unit)
  if unit then
    self:UpdateUnit(unit)
  else
    self:RefreshAllUnitData()
  end
end

function SF:OnEvent(event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    self:RequestProtectedRefresh()
    self:ApplyBlizzardFrames()
    return
  end

  if event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then
    self:OnRosterEvent()
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    self:ApplyPendingProtected()
    return
  end

  if event == "RAID_TARGET_UPDATE" then
    self:RefreshAllUnitData()
    return
  end

  if event == "UNIT_HEALTH"
    or event == "UNIT_MAXHEALTH"
    or event == "UNIT_POWER_UPDATE"
    or event == "UNIT_MAXPOWER"
    or event == "UNIT_DISPLAYPOWER"
    or event == "UNIT_AURA"
    or event == "UNIT_NAME_UPDATE"
    or event == "UNIT_CONNECTION" then
    self:OnUnitEvent(...)
  end
end

local eventFrame = CreateFrame("Frame", "SimpleFramesEventFrame")
SF.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName == ADDON_NAME then
      eventFrame:UnregisterEvent("ADDON_LOADED")
      SF:OnAddonLoaded()
    end
  else
    SF:OnEvent(event, ...)
  end
end)
