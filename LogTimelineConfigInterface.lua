-- LogTimelineConfigInterface.lua
-- Manages the configuration UI for LogTimeline, including main settings and Learning Mode for spell tracking.

-- Create main configuration frame
ConfigFrame = CreateFrame("Frame", "LogTimelineConfigFrame", UIParent, "BasicFrameTemplateWithInset")
ConfigFrame:SetSize(300, 200)
ConfigFrame:SetPoint("CENTER")
ConfigFrame:Hide()
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing)
ConfigFrame:SetScript("OnShow", function() SetTimelineLock(false) end)
ConfigFrame:SetScript("OnHide", function() SetTimelineLock(true) LearningModeConfigFrame:Hide() end)

-- Set up config frame title
ConfigFrame.Title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ConfigFrame.Title:SetPoint("TOP", ConfigFrame, "TOP", 0, -5)
ConfigFrame.Title:SetText("LogTimeline Settings")

-- Create lock/unlock button
LockButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LockButton:SetSize(100, 25)
LockButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -30)
LockButton:SetText("Lock and Close")
LockButton:SetScript("OnClick", function()
    if TimelineFrame then
        local newState = not TimelineFrame.locked
        SetTimelineLock(newState)
        if newState then ConfigFrame:Hide() else end
    else
        print("[LogTimeline] TimelineFrame not ready")
    end
end)
LockButton:SetScript("OnShow", function()
    LockButton:SetText(TimelineFrame and TimelineFrame.locked and "Unlock" or "Lock and Close")
end)

-- Create button to open Learning Mode
LearningModeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LearningModeButton:SetSize(100, 25)
LearningModeButton:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -10, -30)
LearningModeButton:SetText("Learning Mode")
LearningModeButton:SetScript("OnClick", function() LearningModeConfigFrame:Show() end)

-- Create Learning Mode configuration frame
LearningModeConfigFrame = CreateFrame("Frame", "LearningModeConfigFrame", UIParent, "BasicFrameTemplateWithInset")
LearningModeConfigFrame:SetSize(350, 500) -- Increased height for more spells
LearningModeConfigFrame:SetPoint("CENTER")
LearningModeConfigFrame:Hide()
LearningModeConfigFrame:SetMovable(true)
LearningModeConfigFrame:EnableMouse(true)
LearningModeConfigFrame:RegisterForDrag("LeftButton")
LearningModeConfigFrame:SetScript("OnDragStart", LearningModeConfigFrame.StartMoving)
LearningModeConfigFrame:SetScript("OnDragStop", LearningModeConfigFrame.StopMovingOrSizing)

-- Set up Learning Mode title
LearningModeConfigFrame.Title = LearningModeConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LearningModeConfigFrame.Title:SetPoint("TOP", LearningModeConfigFrame, "TOP", 0, -5)
LearningModeConfigFrame.Title:SetText("Learning Mode Configuration")

-- Set up scroll frame for spell list
local ScrollFrame = CreateFrame("ScrollFrame", "LearningModeScrollFrame", LearningModeConfigFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOPLEFT", 10, -30)
ScrollFrame:SetPoint("BOTTOMRIGHT", LearningModeConfigFrame, "BOTTOMRIGHT", -30, 10)

local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetSize(310, 200)
ScrollFrame:SetScrollChild(ScrollChild)

-- Tables for spell tracking
local detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}} -- Spells detected via events
local spellRows = {} -- UI rows for spell list

-- Updates the spell list in Learning Mode, showing checked spells at top, then unchecked
local function UpdateSpellList()
    local yOffset = -10
    local rowHeight = 25
    
    -- Initialize saved variables if needed
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
    
    -- Clear existing rows
    for _, row in ipairs(spellRows) do
        row:Hide()
        row.checkBox:SetScript("OnClick", nil)
    end
    wipe(spellRows)
    
    -- Split into checked and unchecked spells
    local checkedSpells = {}
    local uncheckedSpells = {}
    
    -- Add tracked (checked) spells
    for spellName, info in pairs(LogTimelineDB.trackedSpells.buffs) do
        table.insert(checkedSpells, {name = spellName, type = "Buff", spellID = info.spellID})
    end
    for spellName, info in pairs(LogTimelineDB.trackedSpells.cooldowns) do
        table.insert(checkedSpells, {name = spellName, type = "Cooldown", spellID = info.spellID})
    end
    for spellName, info in pairs(LogTimelineDB.trackedSpells.debuffs) do
        table.insert(checkedSpells, {name = spellName, type = "Debuff", spellID = info.spellID})
    end
    
    -- Add detected (unchecked) spells, skipping those already tracked
    for spellName, info in pairs(detectedSpells.buffs) do
        if not LogTimelineDB.trackedSpells.buffs[spellName] then
            table.insert(uncheckedSpells, {name = spellName, type = "Buff", spellID = info.spellID})
        end
    end
    for spellName, info in pairs(detectedSpells.cooldowns) do
        if not LogTimelineDB.trackedSpells.cooldowns[spellName] then
            table.insert(uncheckedSpells, {name = spellName, type = "Cooldown", spellID = info.spellID})
        end
    end
    for spellName, info in pairs(detectedSpells.debuffs) do
        if not LogTimelineDB.trackedSpells.debuffs[spellName] then
            table.insert(uncheckedSpells, {name = spellName, type = "Debuff", spellID = info.spellID})
        end
    end
    
    -- Sort each group alphabetically
    table.sort(checkedSpells, function(a, b) return a.name < b.name end)
    table.sort(uncheckedSpells, function(a, b) return a.name < b.name end)
    
    -- Combine lists: checked first, then unchecked
    local allSpells = {}
    for _, spell in ipairs(checkedSpells) do
        table.insert(allSpells, spell)
    end
    for _, spell in ipairs(uncheckedSpells) do
        table.insert(allSpells, spell)
    end
    
    -- Create UI rows for each spell
    for i, spell in ipairs(allSpells) do
        local row = CreateFrame("Frame", nil, ScrollChild)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 0, yOffset)
        
        -- Create spell icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        local spellInfo = C_Spell.GetSpellInfo(spell.spellID)
        if spellInfo and spellInfo.iconID then
            icon:SetTexture(spellInfo.iconID)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        -- Create spell name text, offset to right of icon
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        text:SetText(spell.name .. " (" .. spell.type .. ")")
        
        -- Create checkbox for tracking
        local checkBox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkBox:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        checkBox:SetSize(20, 20)
        checkBox:SetScript("OnClick", function(self)
            LogTimelineDB = LogTimelineDB or {}
            LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
            
            local isChecked = self:GetChecked()
            
            -- Update tracked spells based on checkbox state
            if spell.type == "Buff" then
                if isChecked then
                    LogTimelineDB.trackedSpells.buffs[spell.name] = {spellID = spell.spellID}
                else
                    LogTimelineDB.trackedSpells.buffs[spell.name] = nil
                end
            elseif spell.type == "Cooldown" then
                if isChecked then
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = {spellID = spell.spellID, shouldGlow = false}
                else
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = nil
                end
            elseif spell.type == "Debuff" then
                if isChecked then
                    LogTimelineDB.trackedSpells.debuffs[spell.name] = {spellID = spell.spellID}
                else
                    LogTimelineDB.trackedSpells.debuffs[spell.name] = nil
                end
            end
            
            -- Update timeline and spell list
            InitializeIcons()
            CheckBuff()
            CheckDebuff()
            CheckCooldowns()
            UpdateIconPositions()
            UpdateSpellList() -- Refresh list to reflect checkbox change
        end)
        
        -- Set checkbox state based on tracking
        local isTracked = false
        if spell.type == "Buff" and LogTimelineDB.trackedSpells.buffs[spell.name] then
            isTracked = true
        elseif spell.type == "Cooldown" and LogTimelineDB.trackedSpells.cooldowns[spell.name] then
            isTracked = true
        elseif spell.type == "Debuff" and LogTimelineDB.trackedSpells.debuffs[spell.name] then
            isTracked = true
        end
        checkBox:SetChecked(isTracked)
        
        row.checkBox = checkBox
        row:Show()
        table.insert(spellRows, row)
        
        yOffset = yOffset - rowHeight
    end
    
    ScrollChild:SetHeight(math.abs(yOffset))
end

-- Handle Learning Mode visibility and event registration
LearningModeConfigFrame:SetScript("OnShow", function()
    detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}}
    UpdateSpellList()
    LearningModeConfigFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:RegisterEvent("UNIT_AURA")
    LearningModeConfigFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
end)

LearningModeConfigFrame:SetScript("OnHide", function()
    LearningModeConfigFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:UnregisterEvent("UNIT_AURA")
    LearningModeConfigFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
end)

-- Handle spell detection events
LearningModeConfigFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
        local playerGUID = UnitGUID("player")
        if sourceGUID == playerGUID then
            if subEvent == "SPELL_CAST_SUCCESS" then
                local spellInfo = C_Spell.GetSpellCooldown(spellID)
                if spellInfo and spellInfo.duration and spellInfo.duration > 1.5 then
                    detectedSpells.cooldowns[spellName] = detectedSpells.cooldowns[spellName] or {spellID = spellID}
                    UpdateSpellList()
                end
            elseif subEvent == "SPELL_AURA_APPLIED" then
                if destGUID == playerGUID then
                    detectedSpells.buffs[spellName] = detectedSpells.buffs[spellName] or {spellID = spellID}
                    UpdateSpellList()
                elseif UnitGUID("target") == destGUID then
                    detectedSpells.debuffs[spellName] = detectedSpells.debuffs[spellName] or {spellID = spellID}
                    UpdateSpellList()
                end
            end
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                if aura and aura.sourceUnit == "player" then
                    detectedSpells.buffs[aura.name] = detectedSpells.buffs[aura.name] or {spellID = aura.spellId}
                end
            end
            UpdateSpellList()
        elseif unit == "target" then
            if UnitExists("target") then
                for i = 1, 40 do
                    local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")
                    if aura and aura.sourceUnit == "player" then
                        detectedSpells.debuffs[aura.name] = detectedSpells.debuffs[aura.name] or {spellID = aura.spellId}
                    end
                end
                UpdateSpellList()
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        detectedSpells.debuffs = {}
        if UnitExists("target") then
            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")
                if aura and aura.sourceUnit == "player" then
                    detectedSpells.debuffs[aura.name] = detectedSpells.debuffs[aura.name] or {spellID = aura.spellId}
                end
            end
        end
        UpdateSpellList()
    end
end)

-- Create slider for timeline thickness
WidthSlider = CreateFrame("Slider", "LogTimelineWidthSlider", ConfigFrame, "OptionsSliderTemplate")
WidthSlider:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -70)
WidthSlider:SetWidth(260)
WidthSlider:SetMinMaxValues(1, 100)
WidthSlider:SetValueStep(1)
WidthSlider.Text:SetText("Line Thickness")
WidthSlider.Low:SetText("1")
WidthSlider.High:SetText("100")
WidthSlider:SetScript("OnValueChanged", function(self, value)
    local roundedValue = math.floor(value + 0.5)
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.lineThickness = roundedValue
    self:SetValue(roundedValue)
    self.Value:SetText(roundedValue)
    if UpdateTimelineSize then UpdateTimelineSize() end
end)
WidthSlider.Value = WidthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
WidthSlider.Value:SetPoint("BOTTOM", WidthSlider, "BOTTOM", 0, -5)

-- Create slider for timeline length
LengthSlider = CreateFrame("Slider", "LogTimelineLengthSlider", ConfigFrame, "OptionsSliderTemplate")
LengthSlider:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -120)
LengthSlider:SetWidth(260)
LengthSlider:SetMinMaxValues(100, 1000)
LengthSlider:SetValueStep(10)
LengthSlider.Text:SetText("Line Length")
LengthSlider.Low:SetText("100")
LengthSlider.High:SetText("1000")
LengthSlider:SetScript("OnValueChanged", function(self, value)
    local roundedValue = math.floor(value + 0.5)
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.totalDistance = roundedValue
    self:SetValue(roundedValue)
    self.Value:SetText(roundedValue)
    if UpdateTimelineSize then UpdateTimelineSize() end
end)
LengthSlider.Value = LengthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LengthSlider.Value:SetPoint("BOTTOM", LengthSlider, "BOTTOM", 0, -5)

-- Initialize sliders on login
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        LogTimelineDB = LogTimelineDB or {}
        WidthSlider:SetValue(LogTimelineDB.lineThickness or 4)
        WidthSlider.Value:SetText(LogTimelineDB.lineThickness or 4)
        LengthSlider:SetValue(LogTimelineDB.totalDistance or 500)
        LengthSlider.Value:SetText(LogTimelineDB.totalDistance or 500)
        if UpdateTimelineSize then UpdateTimelineSize() end
        InitializeIcons()
    end
end)