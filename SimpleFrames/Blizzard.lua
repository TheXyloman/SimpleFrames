local _, SF = ...

function SF:CreateHiddenParent()
  if self.hiddenParent then
    return
  end

  self.hiddenParent = CreateFrame("Frame", "SimpleFramesHiddenParent", UIParent)
  self.hiddenParent:Hide()
  self.hiddenFrames = {}
end

function SF:GetBlizzardFrameTargets()
  local frames = {}
  local count = 0

  local function add(frame)
    if frame and frame.GetName then
      count = count + 1
      frames[count] = frame
    end
  end

  add(_G.PartyFrame)

  for i = 1, 4 do
    add(_G["PartyMemberFrame" .. i])
  end

  add(_G.CompactPartyFrame)
  add(_G.CompactRaidFrameManager)
  add(_G.CompactRaidFrameContainer)

  return frames
end

function SF:HideBlizzardFrame(frame)
  if not frame or not frame.GetName then
    return
  end

  self:CreateHiddenParent()

  local name = frame:GetName()
  if not name or self.hiddenFrames[name] then
    return
  end

  self.hiddenFrames[name] = {
    parent = frame:GetParent() or UIParent,
    shown = frame:IsShown() and true or false,
  }
  frame:SetParent(self.hiddenParent)
  frame:Hide()
end

function SF:RestoreBlizzardFrame(frame)
  if not frame or not frame.GetName or not self.hiddenFrames then
    return
  end

  local name = frame:GetName()
  local original = name and self.hiddenFrames[name]
  if not original then
    return
  end

  frame:SetParent(original.parent or UIParent)
  self.hiddenFrames[name] = nil

  if RegisterUnitWatch then
    pcall(RegisterUnitWatch, frame)
  end

  if original.shown then
    frame:Show()
  else
    frame:Hide()
  end
end

function SF:ApplyBlizzardFrames()
  if InCombatLockdown and InCombatLockdown() then
    self.pendingBlizzard = true
    return
  end

  self.pendingBlizzard = false
  local targets = self:GetBlizzardFrameTargets()

  if self.db and self.db.hideBlizzard then
    for i = 1, #targets do
      self:HideBlizzardFrame(targets[i])
    end
  else
    for i = 1, #targets do
      self:RestoreBlizzardFrame(targets[i])
    end
  end
end

function SF:RestoreAllBlizzardFrames()
  if not self.hiddenFrames then
    return
  end

  local targets = self:GetBlizzardFrameTargets()
  for i = 1, #targets do
    self:RestoreBlizzardFrame(targets[i])
  end
end
