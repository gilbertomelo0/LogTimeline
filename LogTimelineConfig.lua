-- LogTimelineConfig.lua

-- Timeline Settings
UPDATE_INTERVAL = 0.01
OVERLAP_DISTANCE = 15
PHASE_SPEED = 2.5
MAX_ALPHA = 1.0
MIN_ALPHA = 0.0
TIMELINE_MAX_DURATION = 45

-- Logarithmic Scale Settings
LOGARITHMIC_SCALE = true
LOG_BASE = 20
MIN_VISIBLE_TIME = 0.1

-- Buffs to track on player
BUFFS_TO_TRACK = {
    "Renew",
    "Power Word: Shield", 
    "Prayer of Mending",
    "Atonement",
    -- Monk Buffs
    "Storm, Earth, and Fire",
    "Dance of Chi-Ji",
    "Heart of the Jade Serpent",
    "Beneficial Vibrations"
}

-- Cooldowns to track (spellID, spellName, shouldGlow)
COOLDOWNS_TO_TRACK = {
    -- Major Cooldowns
    { spellID = 123904, spellName = "Invoke Xuen, the White Tiger", shouldGlow = true },
    { spellID = 137639, spellName = "Storm, Earth, and Fire", shouldGlow = true },
    { spellID = 322109, spellName = "Touch of Death", shouldGlow = true },
    { spellID = 391400, spellName = "Conduit of the Celestials", shouldGlow = true },
    -- Rotation Abilities
    { spellID = 113656, spellName = "Fists of Fury", shouldGlow = false },
    { spellID = 107428, spellName = "Rising Sun Kick", shouldGlow = false },
    { spellID = 392983, spellName = "Strike of the Windlord", shouldGlow = false },
    { spellID = 152175, spellName = "Whirling Dragon Punch", shouldGlow = false }
}

-- Debuffs to track on target
DEBUFFS_TO_TRACK = {
    --Priest
    "Shadow Word: Pain",
    "Vampiric Touch",
    "Devouring Plague",
    --Monk
    "Gale Force"
}