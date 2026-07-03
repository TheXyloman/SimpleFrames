local ADDON_NAME, SF = ...

local function trimText(text)
  text = tostring(text or "")
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

function SF:InitDatabase()
  if type(SimpleFramesDB) ~= "table" then
    SimpleFramesDB = {}
  end
  self.db = self:CopyDefaults(self.defaults, SimpleFramesDB)
  SimpleFramesDB = self.db

  self:EnsureProfileDatabase()
end

function SF:EnsureProfileDatabase()
  if type(SimpleFramesProfilesDB) ~= "table" then
    SimpleFramesProfilesDB = {}
  end
  if type(SimpleFramesProfilesDB.profiles) ~= "table" then
    SimpleFramesProfilesDB.profiles = {}
  end
  self.profileDB = SimpleFramesProfilesDB
end

function SF:GetDefaultProfileName()
  local playerName = UnitName and UnitName("player")
  if playerName and playerName ~= "" then
    return playerName
  end
  return "Default"
end

function SF:NormalizeProfileName(name)
  name = trimText(name)
  if name == "" then
    return nil
  end
  if string.len(name) > 32 then
    name = string.sub(name, 1, 32)
  end
  return name
end

function SF:GetProfileNameInput()
  self.profileNameInputText = self:NormalizeProfileName(self.profileNameInputText) or self:GetDefaultProfileName()
  return self.profileNameInputText
end

function SF:SetProfileNameInput(name)
  self.profileNameInputText = trimText(name)
end

function SF:GetProfileNames()
  self:EnsureProfileDatabase()

  local names = {}
  for name, profile in pairs(self.profileDB.profiles) do
    if type(name) == "string" and type(profile) == "table" then
      names[#names + 1] = name
    end
  end

  table.sort(names, function(a, b)
    return string.lower(a) < string.lower(b)
  end)
  return names
end

function SF:GetSelectedProfileName()
  self:EnsureProfileDatabase()
  if self.selectedProfileName and self.profileDB.profiles[self.selectedProfileName] then
    return self.selectedProfileName
  end

  local names = self:GetProfileNames()
  self.selectedProfileName = names[1]
  return self.selectedProfileName
end

function SF:SetSelectedProfileName(name)
  self:EnsureProfileDatabase()
  if name and self.profileDB.profiles[name] then
    self.selectedProfileName = name
    self.profileNameInputText = name
  end
end

function SF:BuildProfileDropdownValues()
  local names = self:GetProfileNames()
  local values = {}
  for i = 1, #names do
    values[i] = {
      value = names[i],
      text = names[i],
    }
  end
  return values
end

function SF:CaptureProfile()
  local profile = self:DeepCopy(self.db or {})
  profile = self:CopyDefaults(self.defaults, profile)

  if profile.preview then
    profile.preview.mode = "off"
  end

  return profile
end

function SF:CreateDatabaseFromProfile(profile)
  return self:CopyDefaults(self.defaults, self:DeepCopy(profile or {}))
end

function SF:ApplyDatabaseState()
  if self.anchor then
    self:RestoreFramePosition(self.anchor, self.db.framePosition, self.defaults.framePosition)
  end
  if self.optionsFrame then
    self:RestoreFramePosition(self.optionsFrame, self.db.optionsPosition, self.defaults.optionsPosition)
  end
  if self.priorityAnchor then
    self:EnsurePriorityConfig()
    self:RestoreFramePosition(self.priorityAnchor, self.db.priority.framePosition, self.defaults.priority.framePosition)
  end

  self:ApplyLockState()
  self:RefreshMinimapButton()
  self:ApplyBlizzardFrames()

  if self.db.preview and self.db.preview.mode ~= "off" and self.db.preview.animate then
    self:EnsurePreviewData()
    self:StartPreviewTicker()
  else
    self:StopPreviewTicker()
  end

  self:RequestProtectedRefresh()
  self:RefreshOptions()
end

function SF:SaveProfile(name)
  self:EnsureProfileDatabase()

  name = self:NormalizeProfileName(name) or self:GetProfileNameInput()
  if not name then
    self:Print("enter a profile name")
    if self.SetProfileStatus then
      self:SetProfileStatus("Enter a profile name.")
    end
    return false
  end

  self.profileDB.profiles[name] = self:CaptureProfile()
  self.selectedProfileName = name
  self.profileNameInputText = name

  self:Print("profile saved: " .. name)
  if self.SetProfileStatus then
    self:SetProfileStatus("Saved profile: " .. name)
  end
  self:RefreshOptions()
  return true
end

function SF:LoadProfile(name)
  self:EnsureProfileDatabase()

  name = self:NormalizeProfileName(name) or self:GetSelectedProfileName()
  local profile = name and self.profileDB.profiles[name]
  if not profile then
    self:Print("profile not found")
    if self.SetProfileStatus then
      self:SetProfileStatus("Choose a saved profile first.")
    end
    return false
  end

  SimpleFramesDB = self:CreateDatabaseFromProfile(profile)
  self.db = SimpleFramesDB
  self.selectedProfileName = name
  self.profileNameInputText = name

  self:ApplyDatabaseState()
  self:Print("profile loaded: " .. name)
  if self.SetProfileStatus then
    self:SetProfileStatus("Loaded profile: " .. name)
  end
  return true
end

function SF:DeleteProfile(name)
  self:EnsureProfileDatabase()

  name = self:NormalizeProfileName(name) or self:GetSelectedProfileName()
  if not name or not self.profileDB.profiles[name] then
    self:Print("profile not found")
    if self.SetProfileStatus then
      self:SetProfileStatus("Choose a saved profile first.")
    end
    return false
  end

  self.profileDB.profiles[name] = nil
  if self.selectedProfileName == name then
    self.selectedProfileName = nil
  end

  self:Print("profile deleted: " .. name)
  if self.SetProfileStatus then
    self:SetProfileStatus("Deleted profile: " .. name)
  end
  self:RefreshOptions()
  return true
end

function SF:ListProfiles()
  local names = self:GetProfileNames()
  if #names == 0 then
    self:Print("no saved profiles")
    return
  end
  self:Print("profiles: " .. table.concat(names, ", "))
end

function SF:ResetDatabase()
  SimpleFramesDB = self:CopyDefaults(self.defaults, {})
  self.db = SimpleFramesDB
  self:ApplyDatabaseState()
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

function SF:HandleProfileSlash(command, rest)
  rest = trimText(rest)

  local action, name = string.match(rest, "^(%S+)%s*(.-)$")
  action = string.lower(action or "")
  name = trimText(name)

  if command == "profiles" or action == "" or action == "list" then
    self:ListProfiles()
    return
  end

  if action == "save" then
    self:SaveProfile(name)
    return
  end

  if action == "load" then
    if name == "" then
      self:Print("use /sfr profile load <name>")
      return
    end
    self:LoadProfile(name)
    return
  end

  if action == "delete" or action == "remove" then
    if name == "" then
      self:Print("use /sfr profile delete <name>")
      return
    end
    self:DeleteProfile(name)
    return
  end

  self:Print("/sfr profile save <name>, /sfr profile load <name>, /sfr profile delete <name>, /sfr profiles")
end

function SF:HandleBindSlash(rest)
  rest = trimText(rest)
  local key, spell = string.match(rest, "^(%S+)%s*(.-)$")
  key = string.upper(trimText(key))
  spell = trimText(spell)

  if not self.clickCastBindingAttributes or not self.clickCastBindingAttributes[key] then
    self:Print("use /sfr bind L|R|SL|SR|AL|AR <spell name or blank>")
    return
  end

  self:SetClickCastBinding(key, spell)
  self:RefreshOptions()
  self:Print(("bound %s to: %s"):format(key, spell ~= "" and spell or "(cleared)"))
end

function SF:HandlePrioritySlash(rest)
  rest = trimText(rest)
  local action = string.lower(rest)

  if action == "clear" or action == "reset" then
    self:ClearPriorityTargets()
    return
  end

  if action == "show" then
    self:EnsurePriorityConfig().enabled = true
    self:RefreshPriorityFrame()
    self:RefreshOptions()
    self:Print("prio targets enabled")
    return
  end

  if action == "hide" then
    self:EnsurePriorityConfig().enabled = false
    self:RefreshPriorityFrame()
    self:RefreshOptions()
    self:Print("prio targets disabled")
    return
  end

  self:Print("/sfr prio clear, /sfr prio show, /sfr prio hide")
end

function SF:HandleSlash(message)
  local rawMessage = trimText(message)
  message = string.lower(rawMessage)

  if message == "" or message == "options" or message == "config" then
    self:ToggleOptions()
    return
  end

  local first, rest = string.match(rawMessage, "^(%S+)%s*(.-)$")
  first = string.lower(first or "")
  if first == "profile" or first == "profiles" then
    self:HandleProfileSlash(first, rest)
    return
  end

  if first == "bind" then
    self:HandleBindSlash(rest)
    return
  end

  if first == "prio" or first == "priority" then
    self:HandlePrioritySlash(rest)
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

  self:Print("/sfr, /sfr lock, /sfr unlock, /sfr bind L|R|SL|SR|AL|AR <spell>, /sfr prio clear, /sfr test party, /sfr test raid, /sfr test off, /sfr reset, /sfr profiles")
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
