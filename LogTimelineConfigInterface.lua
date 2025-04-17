-- LogTimelineConfigInterface.lua
-- Manages the configuration UI for LogTimeline, including main settings and Learning Mode for spell tracking.

-- Create main configuration frame
ConfigFrame = CreateFrame("Frame", "LogTimelineConfigFrame", UIParent, "BasicFrameTemplateWithInset")
ConfigFrame:SetSize(300, 250) -- Increased height for new controls
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
LearningModeConfigFrame:SetSize(700, 500) -- Doubled width for two columns
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

-- Set up header for Buffs/Debuffs column
LearningModeConfigFrame.BuffDebuffHeader = LearningModeConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LearningModeConfigFrame.BuffDebuffHeader:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOPLEFT", 20, -30)
LearningModeConfigFrame.BuffDebuffHeader:SetText("Buffs/Debuffs")

-- Set up header for Cooldowns column
LearningModeConfigFrame.CooldownHeader = LearningModeConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LearningModeConfigFrame.CooldownHeader:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOP", 20, -30)
LearningModeConfigFrame.CooldownHeader:SetText("Cooldowns")

-- Set up scroll frame for Buffs/Debuffs list (left column)
local BuffDebuffScrollFrame = CreateFrame("ScrollFrame", "LearningModeBuffDebuffScrollFrame", LearningModeConfigFrame, "UIPanelScrollFrameTemplate")
BuffDebuffScrollFrame:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOPLEFT", 10, -50)
BuffDebuffScrollFrame:SetPoint("BOTTOMRIGHT", LearningModeConfigFrame, "BOTTOM", -20, 10)

local BuffDebuffScrollChild = CreateFrame("Frame", nil, BuffDebuffScrollFrame)
BuffDebuffScrollChild:SetSize(310, 200)
BuffDebuffScrollFrame:SetScrollChild(BuffDebuffScrollChild)

-- Set up scroll frame for Cooldowns list (right column)
local CooldownScrollFrame = CreateFrame("ScrollFrame", "LearningModeCooldownScrollFrame", LearningModeConfigFrame, "UIPanelScrollFrameTemplate")
CooldownScrollFrame:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOP", 10, -50)
CooldownScrollFrame:SetPoint("BOTTOMRIGHT", LearningModeConfigFrame, "BOTTOMRIGHT", -30, 10)

local CooldownScrollChild = CreateFrame("Frame", nil, CooldownScrollFrame)
CooldownScrollChild:SetSize(310, 200)
CooldownScrollFrame:SetScrollChild(CooldownScrollChild)

-- Tables for spell tracking
local detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}} -- Spells detected via events
local buffDebuffRows = {} -- UI rows for buffs/debuffs list
local cooldownRows = {} -- UI rows for cooldowns list

-- Updates the spell lists in Learning Mode, showing checked spells at top, then unchecked
local function UpdateSpellList()
    local buffDebuffYOffset = -10
    local cooldownYOffset = -10
    local rowHeight = 25
    
    -- Initialize saved variables if needed
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
    
    -- Clear existing rows
    for _, row in ipairs(buffDebuffRows) do
        row:Hide()
        row.checkBox:SetScript("OnClick", nil)
    end
    for _, row in ipairs(cooldownRows) do
        row:Hide()
        row.checkBox:SetScript("OnClick", nil)
        if row.glow then row.glow:Hide() end
    end
    wipe(buffDebuffRows)
    wipe(cooldownRows)
    
    -- Split into checked and unchecked spells for Buffs/Debuffs
    local checkedBuffDebuffs = {}
    local uncheckedBuffDebuffs = {}
    
    -- Split into checked and unchecked spells for Cooldowns
    local checkedCooldowns = {}
    local uncheckedCooldowns = {}
    
    -- Add tracked (checked) spells for Buffs/Debuffs
    for spellName, info in pairs(LogTimelineDB.trackedSpells.buffs) do
        table.insert(checkedBuffDebuffs, {name = spellName, type = "Buff", spellID = info.spellID})
    end
    for spellName, info in pairs(LogTimelineDB.trackedSpells.debuffs) do
        table.insert(checkedBuffDebuffs, {name = spellName, type = "Debuff", spellID = info.spellID})
    end
    
    -- Add tracked (checked) spells for Cooldowns
    for spellName, info in pairs(LogTimelineDB.trackedSpells.cooldowns) do
        table.insert(checkedCooldowns, {name = spellName, type = "Cooldown", spellID = info.spellID})
    end
    
    -- Add detected (unchecked) spells for Buffs/Debuffs, skipping those already tracked
    for spellName, info in pairs(detectedSpells.buffs) do
        if not LogTimelineDB.trackedSpells.buffs[spellName] then
            table.insert(uncheckedBuffDebuffs, {name = spellName, type = "Buff", spellID = info.spellID})
        end
    end
    for spellName, info in pairs(detectedSpells.debuffs) do
        if not LogTimelineDB.trackedSpells.debuffs[spellName] then
            table.insert(uncheckedBuffDebuffs, {name = spellName, type = "Debuff", spellID = info.spellID})
        end
    end
    
    -- Add detected (unchecked) spells for Cooldowns, skipping those already tracked
    for spellName, info in pairs(detectedSpells.cooldowns) do
        if not LogTimelineDB.trackedSpells.cooldowns[spellName] then
            table.insert(uncheckedCooldowns, {name = spellName, type = "Cooldown", spellID = info.spellID})
        end
    end
    
    -- Sort each group alphabetically
    table.sort(checkedBuffDebuffs, function(a, b) return a.name < b.name end)
    table.sort(uncheckedBuffDebuffs, function(a, b) return a.name < b.name end)
    table.sort(checkedCooldowns, function(a, b) return a.name < b.name end)
    table.sort(uncheckedCooldowns, function(a, b) return a.name < b.name end)
    
    -- Combine lists: checked first, then unchecked for Buffs/Debuffs
    local allBuffDebuffs = {}
    for _, spell in ipairs(checkedBuffDebuffs) do
        table.insert(allBuffDebuffs, spell)
    end
    for _, spell in ipairs(uncheckedBuffDebuffs) do
        table.insert(allBuffDebuffs, spell)
    end
    
    -- Combine lists: checked first, then unchecked for Cooldowns
    local allCooldowns = {}
    for _, spell in ipairs(checkedCooldowns) do
        table.insert(allCooldowns, spell)
    end
    for _, spell in ipairs(uncheckedCooldowns) do
        table.insert(allCooldowns, spell)
    end
    
    -- Create UI rows for Buffs/Debuffs
    for i, spell in ipairs(allBuffDebuffs) do
        local row = CreateFrame("Frame", nil, BuffDebuffScrollChild)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", BuffDebuffScrollChild, "TOPLEFT", 0, buffDebuffYOffset)
        
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
        text:SetText(spell.name .. " - " .. spell.type)
        
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
        elseif spell.type == "Debuff" and LogTimelineDB.trackedSpells.debuffs[spell.name] then
            isTracked = true
        end
        checkBox:SetChecked(isTracked)
        
        row.checkBox = checkBox
        row:Show()
        table.insert(buffDebuffRows, row)
        
        buffDebuffYOffset = buffDebuffYOffset - rowHeight
    end
    
    -- Create UI rows for Cooldowns
    for i, spell in ipairs(allCooldowns) do
        local row = CreateFrame("Frame", nil, CooldownScrollChild)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", CooldownScrollChild, "TOPLEFT", 0, cooldownYOffset)
        
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
        
        -- Add glow for cooldowns
        local glow = row:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        glow:SetPoint("CENTER", icon, "CENTER")
        glow:SetSize(30, 30) -- Slightly larger than icon
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(1, 0.8, 0, 0.8) -- Yellow glow
        row.glow = glow
        
        -- Create spell name text, offset to right of icon
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        text:SetText(spell.name .. " - " .. spell.type)
        
        -- Create checkbox for tracking
        local checkBox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkBox:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        checkBox:SetSize(20, 20)
        checkBox:SetScript("OnClick", function(self)
            LogTimelineDB = LogTimelineDB or {}
            LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
            
            local isChecked = self:GetChecked()
            
            -- Update tracked spells based on checkbox state
            if spell.type == "Cooldown" then
                if isChecked then
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = {spellID = spell.spellID, shouldGlow = true}
                else
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = nil
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
        if spell.type == "Cooldown" and LogTimelineDB.trackedSpells.cooldowns[spell.name] then
            isTracked = true
        end
        checkBox:SetChecked(isTracked)
        
        row.checkBox = checkBox
        row:Show()
        table.insert(cooldownRows, row)
        
        cooldownYOffset = cooldownYOffset - rowHeight
    end
    
    BuffDebuffScrollChild:SetHeight(math.abs(buffDebuffYOffset))
    CooldownScrollChild:SetHeight(math.abs(cooldownYOffset))
end

-- Queue for delayed cooldown checks
local pendingCooldownChecks = {}

-- Check cooldown after a delay to ensure accurate data
local function CheckCooldownDelayed(spellID, spellName)
    local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
    local duration = spellCooldownInfo and spellCooldownInfo.duration or 0
    if duration == 0 then
        -- Check charges for spells like Angelic Feather
        local chargesInfo = C_Spell.GetSpellCharges(spellID)
        if chargesInfo then
            duration = chargesInfo.cooldownDuration or 0
        end
    end
    --print("[LogTimeline Debug] Delayed check: " .. spellName .. " (ID: " .. spellID .. ", cooldown: " .. duration .. "s)")
    if duration > 0 then
        detectedSpells.cooldowns[spellName] = detectedSpells.cooldowns[spellName] or {spellID = spellID}
        UpdateSpellList()
    end
end

-- Process pending cooldown checks
local function ProcessPendingCooldowns()
    for spellID, spellName in pairs(pendingCooldownChecks) do
        CheckCooldownDelayed(spellID, spellName)
        pendingCooldownChecks[spellID] = nil
    end
end

-- Handle Learning Mode visibility and event registration
LearningModeConfigFrame:SetScript("OnShow", function()
    detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}}
    
    -- Scan spellbook for spells with cooldowns
    for _, spellBook in pairs({Enum.SpellBookSpellBank.Player, Enum.SpellBookSpellBank.Pet}) do
        local i = 1
        while true do
            local spellInfo = C_SpellBook.GetSpellBookItemInfo(i, spellBook)
            if not spellInfo then break end
            if spellInfo.actionType == "spell" and not spellInfo.isPassive then
                local spellID = spellInfo.spellID
                local spellName = C_Spell.GetSpellInfo(spellID).name
                local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
                local duration = spellCooldownInfo and spellCooldownInfo.duration or 0
                if duration == 0 then
                    local chargesInfo = C_Spell.GetSpellCharges(spellID)
                    if chargesInfo then
                        duration = chargesInfo.cooldownDuration or 0
                    end
                end
                if spellName and duration > 0 then
                    detectedSpells.cooldowns[spellName] = detectedSpells.cooldowns[spellName] or {spellID = spellID}
                end
            end
            i = i + 1
        end
    end
    
    -- Scan action bars for additional spells (e.g., racials)
    for slot = 1, 120 do
        local actionType, spellID = GetActionInfo(slot)
        if actionType == "spell" and spellID then
            local spellName = C_Spell.GetSpellInfo(spellID).name
            local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
            local duration = spellCooldownInfo and spellCooldownInfo.duration or 0
            if duration == 0 then
                local chargesInfo = C_Spell.GetSpellCharges(spellID)
                if chargesInfo then
                    duration = chargesInfo.cooldownDuration or 0
                end
            end
            if spellName and duration > 0 then
                detectedSpells.cooldowns[spellName] = detectedSpells.cooldowns[spellName] or {spellID = spellID}
            end
        end
    end
    
    -- Debug: Print detected cooldowns
    --print("[LogTimeline Debug] Cooldowns detected:")
    for spellName, info in pairs(detectedSpells.cooldowns) do
        --print(" - " .. spellName .. " (ID: " .. info.spellID .. ")")
    end
    
    UpdateSpellList()
    LearningModeConfigFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:RegisterEvent("UNIT_AURA")
    LearningModeConfigFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    -- Start a frame to process delayed cooldown checks
    local delayFrame = CreateFrame("Frame")
    delayFrame:SetScript("OnUpdate", function(self, elapsed)
        ProcessPendingCooldowns()
    end)
end)

LearningModeConfigFrame:SetScript("OnHide", function()
    LearningModeConfigFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:UnregisterEvent("UNIT_AURA")
    LearningModeConfigFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
end)

-- Handle spell detection events
LearningModeConfigFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
        if sourceGUID == UnitGUID("player") then
            if subEvent == "SPELL_CAST_SUCCESS" then
                -- Queue cooldown check for the next frame
                if spellName and spellID then
                    pendingCooldownChecks[spellID] = spellName
                end
            elseif subEvent == "SPELL_AURA_APPLIED" then
                -- Queue cooldown check for aura-applying spells
                if spellName and spellID then
                    pendingCooldownChecks[spellID] = spellName
                end
                -- Detect buffs and debuffs
                if destGUID == UnitGUID("player") then
                    detectedSpells.buffs[spellName] = detectedSpells.buffs[spellName] or {spellID = spellID}
                    UpdateSpellList()
                elseif destGUID == UnitGUID("target") then
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

-- Create slider for timeline max duration
MaxDurationSlider = CreateFrame("Slider", "LogTimelineMaxDurationSlider", ConfigFrame, "OptionsSliderTemplate")
MaxDurationSlider:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -170)
MaxDurationSlider:SetWidth(260)
MaxDurationSlider:SetMinMaxValues(10, 300)
MaxDurationSlider:SetValueStep(1)
MaxDurationSlider.Text:SetText("Max Timeline Duration (sec)")
MaxDurationSlider.Low:SetText("10")
MaxDurationSlider.High:SetText("300")
MaxDurationSlider:SetScript("OnValueChanged", function(self, value)
    local roundedValue = math.floor(value + 0.5)
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.timelineMaxDuration = roundedValue
    self:SetValue(roundedValue)
    self.Value:SetText(roundedValue)
    if UpdateIconPositions then UpdateIconPositions() end
end)
MaxDurationSlider.Value = MaxDurationSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
MaxDurationSlider.Value:SetPoint("BOTTOM", MaxDurationSlider, "BOTTOM", 0, -5)

-- Create checkbox for hiding icons beyond max duration
HideLongDurationsCheck = CreateFrame("CheckButton", "LogTimelineHideLongDurationsCheck", ConfigFrame, "InterfaceOptionsCheckButtonTemplate")
HideLongDurationsCheck:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -210)
HideLongDurationsCheck.Text = HideLongDurationsCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HideLongDurationsCheck.Text:SetPoint("LEFT", HideLongDurationsCheck, "RIGHT", 5, 0)
HideLongDurationsCheck.Text:SetText("Hide Icons Beyond Max Duration")
HideLongDurationsCheck:SetScript("OnClick", function(self)
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.hideLongDurations = self:GetChecked()
    if UpdateIconPositions then UpdateIconPositions() end
end)

-- Initialize sliders and checkbox on login
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        LogTimelineDB = LogTimelineDB or {}
        WidthSlider:SetValue(LogTimelineDB.lineThickness or 4)
        WidthSlider.Value:SetText(LogTimelineDB.lineThickness or 4)
        LengthSlider:SetValue(LogTimelineDB.totalDistance or 500)
        LengthSlider.Value:SetText(LogTimelineDB.totalDistance or 500)
        MaxDurationSlider:SetValue(LogTimelineDB.timelineMaxDuration or 45)
        MaxDurationSlider.Value:SetText(LogTimelineDB.timelineMaxDuration or 45)
        HideLongDurationsCheck:SetChecked(LogTimelineDB.hideLongDurations or false)
        if UpdateTimelineSize then UpdateTimelineSize() end
        InitializeIcons()
    end
end)