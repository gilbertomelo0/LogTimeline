-- LogTimelineConfigInterface.lua

ConfigFrame = CreateFrame("Frame", "LogTimelineConfigFrame", UIParent, "BasicFrameTemplateWithInset")
ConfigFrame:SetSize(300, 200)
ConfigFrame:SetPoint("CENTER")
ConfigFrame:Hide()
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing)
ConfigFrame:SetScript("OnShow", function() SetTimelineLock(false) print("[LogTimeline] ConfigFrame shown") end)
ConfigFrame:SetScript("OnHide", function() SetTimelineLock(true) LearningModeConfigFrame:Hide() print("[LogTimeline] ConfigFrame hidden") end)

ConfigFrame.Title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ConfigFrame.Title:SetPoint("TOP", ConfigFrame, "TOP", 0, -5)
ConfigFrame.Title:SetText("LogTimeline Settings")
print("[LogTimeline] ConfigFrame Title created")

LockButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LockButton:SetSize(100, 25)
LockButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -30)
LockButton:SetText("Lock and Close")
LockButton:SetScript("OnClick", function()
    if TimelineFrame then
        local newState = not TimelineFrame.locked
        SetTimelineLock(newState)
        if newState then ConfigFrame:Hide() print("[LogTimeline] Timeline locked") else print("[LogTimeline] Timeline unlocked") end
    else
        print("[LogTimeline] TimelineFrame not ready")
    end
end)
LockButton:SetScript("OnShow", function()
    LockButton:SetText(TimelineFrame and TimelineFrame.locked and "Unlock" or "Lock and Close")
end)

LearningModeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LearningModeButton:SetSize(100, 25)
LearningModeButton:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -10, -30)
LearningModeButton:SetText("Learning Mode")
LearningModeButton:SetScript("OnClick", function() LearningModeConfigFrame:Show() end)

LearningModeConfigFrame = CreateFrame("Frame", "LearningModeConfigFrame", UIParent, "BasicFrameTemplateWithInset")
LearningModeConfigFrame:SetSize(350, 250)
LearningModeConfigFrame:SetPoint("CENTER")
LearningModeConfigFrame:Hide()
LearningModeConfigFrame:SetMovable(true)
LearningModeConfigFrame:EnableMouse(true)
LearningModeConfigFrame:RegisterForDrag("LeftButton")
LearningModeConfigFrame:SetScript("OnDragStart", LearningModeConfigFrame.StartMoving)
LearningModeConfigFrame:SetScript("OnDragStop", LearningModeConfigFrame.StopMovingOrSizing)

LearningModeConfigFrame.Title = LearningModeConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LearningModeConfigFrame.Title:SetPoint("TOP", LearningModeConfigFrame, "TOP", 0, -5)
LearningModeConfigFrame.Title:SetText("Learning Mode Configuration")
print("[LogTimeline] LearningModeConfigFrame Title created")

local ScrollFrame = CreateFrame("ScrollFrame", "LearningModeScrollFrame", LearningModeConfigFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", LearningModeConfigFrame, "TOPLEFT", 10, -30)
ScrollFrame:SetPoint("BOTTOMRIGHT", LearningModeConfigFrame, "BOTTOMRIGHT", -30, 10)

local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetSize(310, 200)
ScrollFrame:SetScrollChild(ScrollChild)

local detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}}
local spellRows = {}

local function UpdateSpellList()
    local yOffset = -10
    local rowHeight = 25
    
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
    print("[LogTimeline] UpdateSpellList: trackedSpells initialized")
    
    for _, row in ipairs(spellRows) do
        row:Hide()
        row.checkBox:SetScript("OnClick", nil)
    end
    wipe(spellRows)
    
    local allSpells = {}
    for spellName, info in pairs(detectedSpells.buffs) do
        table.insert(allSpells, {name = spellName, type = "Buff", spellID = info.spellID})
    end
    for spellName, info in pairs(detectedSpells.cooldowns) do
        table.insert(allSpells, {name = spellName, type = "Cooldown", spellID = info.spellID})
    end
    for spellName, info in pairs(detectedSpells.debuffs) do
        table.insert(allSpells, {name = spellName, type = "Debuff", spellID = info.spellID})
    end
    
    table.sort(allSpells, function(a, b) return a.name < b.name end)
    
    for i, spell in ipairs(allSpells) do
        local row = CreateFrame("Frame", nil, ScrollChild)
        row:SetSize(300, rowHeight)
        row:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", 0, yOffset)
        
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", row, "LEFT", 5, 0)
        text:SetText(spell.name .. " (" .. spell.type .. ")")
        print("[LogTimeline] Created FontString for spell: " .. spell.name)
        
        local checkBox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        checkBox:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        checkBox:SetSize(20, 20)
        checkBox:SetScript("OnClick", function(self)
            LogTimelineDB = LogTimelineDB or {}
            LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
            print("[LogTimeline] Checkbox OnClick: trackedSpells initialized")
            
            local isChecked = self:GetChecked()
            
            if spell.type == "Buff" then
                if isChecked then
                    LogTimelineDB.trackedSpells.buffs[spell.name] = {spellID = spell.spellID}
                    print("[LogTimeline] Tracking buff: " .. spell.name)
                else
                    LogTimelineDB.trackedSpells.buffs[spell.name] = nil
                    print("[LogTimeline] Stopped tracking buff: " .. spell.name)
                end
            elseif spell.type == "Cooldown" then
                if isChecked then
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = {spellID = spell.spellID, shouldGlow = false}
                    print("[LogTimeline] Tracking cooldown: " .. spell.name)
                else
                    LogTimelineDB.trackedSpells.cooldowns[spell.name] = nil
                    print("[LogTimeline] Stopped tracking cooldown: " .. spell.name)
                end
            elseif spell.type == "Debuff" then
                if isChecked then
                    LogTimelineDB.trackedSpells.debuffs[spell.name] = {spellID = spell.spellID}
                    print("[LogTimeline] Tracking debuff: " .. spell.name)
                else
                    LogTimelineDB.trackedSpells.debuffs[spell.name] = nil
                    print("[LogTimeline] Stopped tracking debuff: " .. spell.name)
                end
            end
            
            InitializeIcons()
            CheckBuff()
            CheckDebuff()
            CheckCooldowns()
            UpdateIconPositions()
            
            print("[LogTimeline] Tracked spells after update:")
            for k, _ in pairs(LogTimelineDB.trackedSpells.buffs) do print("  Buff: " .. k) end
            for k, _ in pairs(LogTimelineDB.trackedSpells.debuffs) do print("  Debuff: " .. k) end
            for k, _ in pairs(LogTimelineDB.trackedSpells.cooldowns) do print("  Cooldown: " .. k) end
        end)
        
        local isTracked = false
        if spell.type == "Buff" and LogTimelineDB.trackedSpells.buffs[spell.name] then
            isTracked = true
        elseif spell.type == "Cooldown" and LogTimelineDB.trackedSpells.cooldowns[spell.name] then
            isTracked = true
        elseif spell.type == "Debuff" and LogTimelineDB.trackedSpells.debuffs[spell.name] then
            isTracked = true
        end
        checkBox:SetChecked(isTracked)
        print("[LogTimeline] Checkbox for " .. spell.name .. " set to " .. (isTracked and "checked" or "unchecked"))
        
        row.checkBox = checkBox
        row:Show()
        table.insert(spellRows, row)
        
        yOffset = yOffset - rowHeight
    end
    
    ScrollChild:SetHeight(math.abs(yOffset))
end

LearningModeConfigFrame:SetScript("OnShow", function()
    detectedSpells = {buffs = {}, cooldowns = {}, debuffs = {}}
    UpdateSpellList()
    LearningModeConfigFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:RegisterEvent("UNIT_AURA")
    LearningModeConfigFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    print("[LogTimeline] Learning mode activated")
end)

LearningModeConfigFrame:SetScript("OnHide", function()
    LearningModeConfigFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    LearningModeConfigFrame:UnregisterEvent("UNIT_AURA")
    LearningModeConfigFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    print("[LogTimeline] Learning mode deactivated")
end)

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
    if UpdateTimelineSize then UpdateTimelineSize() print("[LogTimeline] Line thickness set to " .. roundedValue) end
end)
WidthSlider.Value = WidthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
WidthSlider.Value:SetPoint("BOTTOM", WidthSlider, "BOTTOM", 0, -5)
print("[LogTimeline] WidthSlider Value created")

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
    if UpdateTimelineSize then UpdateTimelineSize() print("[LogTimeline] Line length set to " .. roundedValue) end
end)
LengthSlider.Value = LengthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LengthSlider.Value:SetPoint("BOTTOM", LengthSlider, "BOTTOM", 0, -5)
print("[LogTimeline] LengthSlider Value created")

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
        print("[LogTimeline] Sliders initialized")
        InitializeIcons() -- Ensure icons are initialized after sliders
    end
end)

print("[LogTimeline] LogTimelineConfigInterface.lua loaded")