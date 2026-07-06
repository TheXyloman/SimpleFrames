local ADDON_NAME, SF = ...

SF.name = ADDON_NAME
SF.version = "0.1.3"

SF.defaults = {
  profileVersion = 1,
  locked = false,
  enabled = true,
  hideBlizzard = true,
  framePosition = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = -220,
    y = 0,
  },
  optionsPosition = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
  },
  layout = {
    width = 160,
    height = 38,
    powerHeight = 10,
    spacing = 4,
    groupColumns = 5,
    unitGrowth = "DOWN",
    showRaidHeaders = true,
    showPower = true,
    showRaidIcons = true,
    raidIconSize = 14,
  },
  text = {
    health = "both",
    power = "both",
    namePosition = "left",
    nameFontSize = 11,
    healthFontSize = 10,
    powerFontSize = 8,
    nameOffsetX = 0,
    nameOffsetY = 0,
    healthOffsetX = 0,
    healthOffsetY = 0,
    powerOffsetX = 0,
    powerOffsetY = 0,
  },
  auras = {
    mode = "both",
    maxBuffs = 2,
    maxDebuffs = 3,
    lowHealthThreshold = 15,
    showCrowdControl = true,
    buffSize = 12,
    debuffSize = 12,
    buffOffsetX = 0,
    buffOffsetY = 0,
    debuffOffsetX = 0,
    debuffOffsetY = 0,
  },
  preview = {
    mode = "off",
    animate = true,
  },
  clickCast = {
    enabled = true,
    bindings = {
      L = "",
      R = "",
      SL = "",
      SR = "",
      AL = "",
      AR = "",
    },
  },
  priority = {
    enabled = true,
    showFrame = true,
    framePosition = {
      point = "CENTER",
      relativePoint = "CENTER",
      x = 240,
      y = -160,
    },
    columns = 1,
    spacing = 4,
    list = {},
    order = {},
  },
  pets = {
    enabled = true,
    showFrame = true,
    framePosition = {
      point = "CENTER",
      relativePoint = "CENTER",
      x = 240,
      y = 40,
    },
    columns = 1,
    spacing = 4,
  },
  minimap = {
    show = true,
    angle = 225,
  },
}

SF.clickCastBindingOrder = {
  "L",
  "R",
  "SL",
  "SR",
  "AL",
  "AR",
}

SF.clickCastBindingLabels = {
  L = "Left Click",
  R = "Right Click",
  SL = "Shift + Left",
  SR = "Shift + Right",
  AL = "Alt + Left",
  AR = "Alt + Right",
}

SF.clickCastBindingAttributes = {
  L = { button = 1, prefix = "" },
  R = { button = 2, prefix = "" },
  SL = { button = 1, prefix = "shift-" },
  SR = { button = 2, prefix = "shift-" },
  AL = { button = 1, prefix = "alt-" },
  AR = { button = 2, prefix = "alt-" },
}

SF.resurrectionSpells = {
  PRIEST = { "Resurrection" },
  PALADIN = { "Redemption" },
  SHAMAN = { "Ancestral Spirit" },
  DRUID = { "Revive", "Rebirth" },
}

SF.classOrder = {
  "WARRIOR",
  "PALADIN",
  "HUNTER",
  "ROGUE",
  "PRIEST",
  "SHAMAN",
  "MAGE",
  "WARLOCK",
  "DRUID",
}

SF.powerColors = {
  MANA = { r = 0.20, g = 0.45, b = 0.95 },
  RAGE = { r = 0.85, g = 0.16, b = 0.12 },
  FOCUS = { r = 0.95, g = 0.55, b = 0.10 },
  ENERGY = { r = 0.95, g = 0.80, b = 0.20 },
  HAPPINESS = { r = 0.00, g = 1.00, b = 1.00 },
  RUNES = { r = 0.55, g = 0.57, b = 0.61 },
  RUNIC_POWER = { r = 0.00, g = 0.82, b = 1.00 },
}

SF.debuffColors = {
  Magic = { r = 0.62, g = 0.34, b = 1.00, a = 0.95 },
  Curse = { r = 0.86, g = 0.26, b = 0.92, a = 0.95 },
  Poison = { r = 0.20, g = 0.95, b = 0.32, a = 0.95 },
  Disease = { r = 0.95, g = 0.72, b = 0.18, a = 0.95 },
  none = { r = 0.90, g = 0.20, b = 0.20, a = 0.80 },
}
