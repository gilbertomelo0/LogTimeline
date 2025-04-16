-- LogTimelineCore.lua

local buffIcons = {}
local cooldownIcons = {}
local debuffIcons = {}
local activeBuffs = {}
local phaseTimer = 0
local overlapGroups = {}

TimelineFrame = CreateFrame("Frame", "LogTimelineTimeline", UIParent)
TimelineFrame.locked = true
BuffLine = TimelineFrame:CreateTexture(nil, "BACKGROUND")
BuffLine:SetColorTexture(1, 1, 1, 1)
BuffLine:SetAllPoints(TimelineFrame)
TimelineFrame:SetSize(LogTimelineDB and LogTimelineDB.totalDistance or 500, LogTimelineDB and LogTimelineDB.lineThickness or 4)
TimelineFrame:SetHitRectInsets(-20, -20, -20, -20)
TimelineFrame:Show()
BuffLine:Show()

TimelineFrame:SetMovable(true)
TimelineFrame:EnableMouse(false)
TimelineFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.locked then
        print("[LogTimeline] Moving timeline")
        self:StartMoving()
    end
end)
TimelineFrame:SetScript("OnMouseUp", function(self)
    if not self.locked then
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        LogTimelineDB = LogTimelineDB or {}
        LogTimelineDB.point = point
        LogTimelineDB.relativePoint = relativePoint
        LogTimelineDB.xOfs = xOfs
        LogTimelineDB.yOfs = yOfs
        print("[LogTimeline] Timeline moved to: point=" .. (point or "none"))
    end
end)

function SetTimelineLock(state)
    if not TimelineFrame then print("[LogTimeline] TimelineFrame not ready") return end
    TimelineFrame.locked = state
    TimelineFrame:EnableMouse(not state)
    print("[LogTimeline] Timeline " .. (state and "locked" or "unlocked"))
    if LockButton then LockButton:SetText(state and "Unlock" or "Lock and Close") end
end

function UpdateTimelineSize()
    LogTimelineDB = LogTimelineDB or {}
    local totalDistance = LogTimelineDB.totalDistance or 500
    local lineThickness = LogTimelineDB.lineThickness or 4
    if not TimelineFrame or not BuffLine then print("[LogTimeline] TimelineFrame/BuffLine not ready") return end
    TimelineFrame:Show()
    TimelineFrame:SetScale(1)
    TimelineFrame:SetClampedToScreen(false)
    BuffLine:SetColorTexture(1, 1, 1, 1)
    BuffLine:SetAlpha(1)
    BuffLine:ClearAllPoints()
    BuffLine:SetAllPoints(TimelineFrame)
    BuffLine:SetDrawLayer("BACKGROUND", 0)
    BuffLine:Show()
    TimelineFrame:SetSize(totalDistance, lineThickness)
end

local function UpdateStackTextFontSize()
    local fontSize = (LogTimelineDB and LogTimelineDB.stackFontSize) or STACK_FONT_SIZE or 10
    for _, iconData in pairs(buffIcons) do
        if iconData.stackText then iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE") end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.stackText then iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE") end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.stackText then iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE") end
    end
end

local function CreateBuffIcon(buffName)
    local iconFrame = CreateFrame("Frame", "LogTimelineIcon_"..buffName, UIParent)
    iconFrame:SetSize(32, 32)
    iconFrame:SetPoint("CENTER", TimelineFrame, "CENTER", (LogTimelineDB and LogTimelineDB.totalDistance or 500)/2, 0)
    iconFrame:Hide()
    iconFrame:SetAlpha(1)
    
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    
    local stackText = iconFrame:CreateFontString(nil, "OVERLAY")
    stackText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    stackText:SetTextColor(1, 1, 1, 1)
    local fontSize = (LogTimelineDB and LogTimelineDB.stackFontSize) or STACK_FONT_SIZE or 10
    stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    stackText:SetDrawLayer("OVERLAY", 1)
    
    return {
        frame = iconFrame,
        icon = iconTexture,
        stackText = stackText,
        remainingTime = 0,
        expirationTime = 0,
        name = buffName,
        xPos = 0,
        groupIndex = 0,
        phaseOffset = 0,
        isActive = false,
        isCooldown = false,
        isDebuff = false
    }
end

local function CreateCooldownIcon(spellID, spellName, shouldGlow)
    local iconData = CreateBuffIcon(spellName)
    iconData.isCooldown = true
    iconData.spellID = spellID
    iconData.shouldGlow = shouldGlow
    
    iconData.cooldownFrame = CreateFrame("Frame", "LogTimelineCooldown_"..spellName, iconData.frame)
    iconData.cooldownFrame:SetAllPoints(iconData.frame)
    
    if shouldGlow then
        iconData.glow = iconData.frame:CreateTexture(nil, "OVERLAY")
        iconData.glow:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        iconData.glow:SetPoint("CENTER", iconData.frame, "CENTER")
        iconData.glow:SetSize(48, 48)
        iconData.glow:SetBlendMode("ADD")
        iconData.glow:SetVertexColor(1, 0.8, 0, 0.8)
        iconData.glow:SetDrawLayer("OVERLAY", 2)
        iconData.glow:Hide()
    end
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then iconData.icon:SetTexture(spellInfo.iconID) end
    
    return iconData
end

function InitializeIcons()
    -- Hide and clear all existing icons
    for _, iconData in pairs(buffIcons) do
        iconData.frame:Hide()
        iconData.isActive = false
    end
    for _, iconData in pairs(cooldownIcons) do
        iconData.frame:Hide()
        iconData.isActive = false
        if iconData.glow then iconData.glow:Hide() end
    end
    for _, iconData in pairs(debuffIcons) do
        iconData.frame:Hide()
        iconData.isActive = false
    end
    
    -- Reset icon tables
    buffIcons = {}
    cooldownIcons = {}
    debuffIcons = {}
    
    -- Initialize saved variables if needed
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
    
    -- Create icons only for tracked spells from SavedVariables
    for buffName, info in pairs(LogTimelineDB.trackedSpells.buffs) do
        buffIcons[buffName] = CreateBuffIcon(buffName)
    end
    for spellName, info in pairs(LogTimelineDB.trackedSpells.cooldowns) do
        cooldownIcons[spellName] = CreateCooldownIcon(info.spellID, spellName, info.shouldGlow == nil and true or info.shouldGlow)
    end
    for debuffName, info in pairs(LogTimelineDB.trackedSpells.debuffs) do
        debuffIcons[debuffName] = CreateBuffIcon(debuffName)
        debuffIcons[debuffName].isDebuff = true
    end
    
    print("[LogTimeline] Initialized " .. table.getn(buffIcons) .. " buffs, " .. table.getn(cooldownIcons) .. " cooldowns, " .. table.getn(debuffIcons) .. " debuffs")
end

local function CalculatePosition(timeLeft, maxDuration)
    local totalDistance = LogTimelineDB and LogTimelineDB.totalDistance or 500
    if not LOGARITHMIC_SCALE then
        return (totalDistance/2) - (totalDistance * (1 - (timeLeft / maxDuration)))
    else
        if timeLeft <= MIN_VISIBLE_TIME then return (totalDistance/2) - totalDistance end
        local normalizedTime = (timeLeft - MIN_VISIBLE_TIME) / (maxDuration - MIN_VISIBLE_TIME)
        local logValue = math.log(1 + (LOG_BASE - 1) * normalizedTime) / math.log(LOG_BASE)
        return (totalDistance/2) - (totalDistance * (1 - logValue))
    end
end

function CheckBuff()
    local currentTime = GetTime()
    local foundBuffs = {}
    for _, iconData in pairs(buffIcons) do iconData.isActive = false end
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if aura and buffIcons[aura.name] and LogTimelineDB.trackedSpells.buffs[aura.name] then
            local iconData = buffIcons[aura.name]
            iconData.icon:SetTexture(aura.icon)
            iconData.expirationTime = aura.expirationTime or 0
            iconData.remainingTime = aura.expirationTime and (aura.expirationTime - currentTime) or 0
            iconData.stackText:SetText(aura.applications and aura.applications > 1 and aura.applications or "")
            iconData.isActive = true
            iconData.frame:Show()
            iconData.groupIndex = 0
            foundBuffs[aura.name] = true
        end
    end
    for buffName, iconData in pairs(buffIcons) do
        if not foundBuffs[buffName] or not LogTimelineDB.trackedSpells.buffs[buffName] then
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
end

function CheckCooldowns()
    local currentTime = GetTime()
    for _, iconData in pairs(cooldownIcons) do
        if not LogTimelineDB.trackedSpells.cooldowns[iconData.name] then
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            local spellCooldownInfo = C_Spell.GetSpellCooldown(iconData.spellID)
            if spellCooldownInfo then
                local start, duration, isEnabled = spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled
                if isEnabled and duration and duration > 1.5 then
                    local remaining = (start + duration) - currentTime
                    if remaining > 0 then
                        if not iconData.isActive or remaining > iconData.remainingTime then
                            iconData.expirationTime = currentTime + remaining
                        end
                        iconData.remainingTime = remaining
                        iconData.isActive = true
                        iconData.frame:Show()
                    else
                        iconData.isActive = false
                        iconData.frame:Hide()
                        iconData.xPos = 0
                        iconData.groupIndex = 0
                    end
                else
                    iconData.isActive = false
                    iconData.frame:Hide()
                    iconData.xPos = 0
                    iconData.groupIndex = 0
                end
            else
                iconData.isActive = false
                iconData.frame:Hide()
                iconData.xPos = 0
                iconData.groupIndex = 0
            end
        end
    end
end

function CheckDebuff()
    local currentTime = GetTime()
    local foundDebuffs = {}
    for _, iconData in pairs(debuffIcons) do iconData.isActive = false end
    if UnitExists("target") then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")
            if aura and debuffIcons[aura.name] and LogTimelineDB.trackedSpells.debuffs[aura.name] then
                local iconData = debuffIcons[aura.name]
                iconData.icon:SetTexture(aura.icon)
                iconData.expirationTime = aura.expirationTime or 0
                iconData.remainingTime = aura.expirationTime and (aura.expirationTime - currentTime) or 0
                iconData.stackText:SetText(aura.applications and aura.applications > 1 and aura.applications or "")
                iconData.isActive = true
                iconData.frame:Show()
                iconData.groupIndex = 0
                foundDebuffs[aura.name] = true
            end
        end
    end
    for debuffName, iconData in pairs(debuffIcons) do
        if not foundDebuffs[debuffName] or not LogTimelineDB.trackedSpells.debuffs[debuffName] then
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
end

local function LoadPositionAndSize()
    LogTimelineDB = LogTimelineDB or {}
    if LogTimelineDB.point then
        TimelineFrame:ClearAllPoints()
        TimelineFrame:SetPoint(LogTimelineDB.point, UIParent, LogTimelineDB.relativePoint, LogTimelineDB.xOfs, LogTimelineDB.yOfs)
    else
        TimelineFrame:SetPoint("CENTER", UIParent, "CENTER", -100, 0)
    end
    UpdateTimelineSize()
    UpdateStackTextFontSize()
end

local function UpdateOverlapGroups()
    overlapGroups = {}
    for _, iconData in pairs(buffIcons) do iconData.groupIndex = 0 end
    for _, iconData in pairs(cooldownIcons) do iconData.groupIndex = 0 end
    for _, iconData in pairs(debuffIcons) do iconData.groupIndex = 0 end
    
    activeBuffs = {}
    for _, iconData in pairs(buffIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then table.insert(activeBuffs, iconData) end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then table.insert(activeBuffs, iconData) end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then table.insert(activeBuffs, iconData) end
    end
    
    for _, buff in ipairs(activeBuffs) do
        if buff.groupIndex == 0 then
            local newGroup = {buff}
            buff.groupIndex = #overlapGroups + 1
            for _, otherBuff in ipairs(activeBuffs) do
                if otherBuff ~= buff and otherBuff.groupIndex == 0 then
                    local distance = math.abs(buff.xPos - otherBuff.xPos)
                    if distance < OVERLAP_DISTANCE then
                        table.insert(newGroup, otherBuff)
                        otherBuff.groupIndex = buff.groupIndex
                    end
                end
            end
            if #newGroup > 1 then
                table.insert(overlapGroups, newGroup)
                for i, iconData in ipairs(newGroup) do iconData.phaseOffset = (i-1) * (2 * math.pi / #newGroup) end
            else
                buff.groupIndex = 0
            end
        end
    end
end

local function UpdateAlphaPhasing()
    local maxDuration = LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45
    local hideLongDurations = LogTimelineDB and LogTimelineDB.hideLongDurations or false
    
    for _, iconData in pairs(buffIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 or not LogTimelineDB.trackedSpells.buffs[iconData.name] or (hideLongDurations and iconData.remainingTime > maxDuration) then
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            iconData.frame:SetAlpha(MAX_ALPHA)
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 or not LogTimelineDB.trackedSpells.cooldowns[iconData.name] or (hideLongDurations and iconData.remainingTime > maxDuration) then
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            iconData.frame:SetAlpha(MAX_ALPHA)
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 or not LogTimelineDB.trackedSpells.debuffs[iconData.name] or (hideLongDurations and iconData.remainingTime > maxDuration) then
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            iconData.frame:SetAlpha(MAX_ALPHA)
        end
    end
    
    for _, group in ipairs(overlapGroups) do
        local phasePosition = (phaseTimer * PHASE_SPEED) % (2 * math.pi)
        local leadingIndex = 1
        local maxAlpha = 0
        for i, iconData in ipairs(group) do
            local phase = (phasePosition - iconData.phaseOffset) % (2 * math.pi)
            local alpha = phase < math.pi/2 and 1 or phase < math.pi and 1 - (phase - math.pi/2) / (math.pi/2) or phase < 3*math.pi/2 and 0 or (phase - 3*math.pi/2) / (math.pi/2)
            local finalAlpha = MIN_ALPHA + (MAX_ALPHA - MIN_ALPHA) * alpha
            iconData.frame:SetAlpha(finalAlpha)
            if alpha > maxAlpha then maxAlpha = alpha leadingIndex = i end
        end
        for i, iconData in ipairs(group) do
            iconData.stackText:SetAlpha(i == leadingIndex and 1 or 0)
            iconData.stackText:Show()
        end
    end
end

function UpdateIconPositions()
    local currentTime = GetTime()
    local maxDuration = LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45
    local hideLongDurations = LogTimelineDB and LogTimelineDB.hideLongDurations or false
    
    for _, iconData in pairs(buffIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime and LogTimelineDB.trackedSpells.buffs[iconData.name] then
            iconData.remainingTime = iconData.expirationTime - currentTime
            if hideLongDurations and iconData.remainingTime > maxDuration then
                iconData.frame:Hide()
                iconData.xPos = 0
                iconData.groupIndex = 0
            else
                local timeLeft = math.min(iconData.remainingTime, maxDuration)
                iconData.xPos = CalculatePosition(timeLeft, maxDuration)
                iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
                iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10)
                iconData.frame:Show()
                if iconData.stackText then iconData.stackText:SetDrawLayer("OVERLAY", 1) end
            end
        else
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime and LogTimelineDB.trackedSpells.cooldowns[iconData.name] then
            iconData.remainingTime = iconData.expirationTime - currentTime
            if hideLongDurations and iconData.remainingTime > maxDuration then
                iconData.frame:Hide()
                iconData.xPos = 0
                iconData.groupIndex = 0
                if iconData.glow then iconData.glow:Hide() end
            else
                local timeLeft = math.min(iconData.remainingTime, maxDuration)
                iconData.xPos = CalculatePosition(timeLeft, maxDuration)
                iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
                iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10)
                iconData.frame:Show()
                if iconData.stackText then iconData.stackText:SetDrawLayer("OVERLAY", 1) end
                if iconData.glow and iconData.shouldGlow then
                    iconData.glow:SetDrawLayer("OVERLAY", 2)
                    iconData.glow:Show()
                end
            end
        else
            iconData.isActive = false
            iconData.frame:Hide()
            if iconData.glow then iconData.glow:Hide() end
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime and LogTimelineDB.trackedSpells.debuffs[iconData.name] then
            iconData.remainingTime = iconData.expirationTime - currentTime
            if hideLongDurations and iconData.remainingTime > maxDuration then
                iconData.frame:Hide()
                iconData.xPos = 0
                iconData.groupIndex = 0
            else
                local timeLeft = math.min(iconData.remainingTime, maxDuration)
                iconData.xPos = CalculatePosition(timeLeft, maxDuration)
                iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
                iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10)
                iconData.frame:Show()
                if iconData.stackText then iconData.stackText:SetDrawLayer("OVERLAY", 1) end
            end
        else
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
    UpdateOverlapGroups()
    UpdateAlphaPhasing()
    phaseTimer = phaseTimer + UPDATE_INTERVAL
end

SLASH_LOGTIMELINE1 = "/logt"
SlashCmdList["LOGTIMELINE"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command = args[1] or ""
    if command == "lock" then
        SetTimelineLock(true)
        if ConfigFrame:IsShown() then LockButton:SetText("Unlock") end
    elseif command == "unlock" then
        SetTimelineLock(false)
        if ConfigFrame:IsShown() then LockButton:SetText("Lock and Close") end
    elseif command == "debuglayer" then
        for _, iconData in pairs(buffIcons) do
            if iconData.isActive then print("[LogTimeline] Buff icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel()) end
        end
        for _, iconData in pairs(cooldownIcons) do
            if iconData.isActive then print("[LogTimeline] Cooldown icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel()) end
        end
        for _, iconData in pairs(debuffIcons) do
            if iconData.isActive then print("[LogTimeline] Debuff icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel()) end
        end
    elseif command == "linear" then
        LOGARITHMIC_SCALE = false
    elseif command == "log" then
        LOGARITHMIC_SCALE = true
    elseif command == "base" and args[2] then
        local newBase = tonumber(args[2])
        if newBase and newBase > 1 then LOG_BASE = newBase print("[LogTimeline] Log base: "..LOG_BASE) end
    elseif command == "min" and args[2] then
        local newMin = tonumber(args[2])
        if newMin and newMin >= 0 then MIN_VISIBLE_TIME = newMin print("[LogTimeline] Min time: "..MIN_VISIBLE_TIME) end
    elseif command == "fontsize" and args[2] then
        local newSize = tonumber(args[2])
        if newSize and newSize >= 6 and newSize <= 30 then
            LogTimelineDB = LogTimelineDB or {}
            LogTimelineDB.stackFontSize = newSize
            UpdateStackTextFontSize()
        end
    elseif command == "reset" then
        TimelineFrame:ClearAllPoints()
        TimelineFrame:SetPoint("CENTER", UIParent, "CENTER", -100, 0)
        LogTimelineDB = nil
        LoadPositionAndSize()
        if ConfigFrame:IsShown() then
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            MaxDurationSlider:SetValue(LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45)
            HideLongDurationsCheck:SetChecked(LogTimelineDB and LogTimelineDB.hideLongDurations or false)
        end
        print("[LogTimeline] Reset")
    elseif command == "config" then
        if ConfigFrame:IsShown() then ConfigFrame:Hide() else
            ConfigFrame:Show()
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            MaxDurationSlider:SetValue(LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45)
            HideLongDurationsCheck:SetChecked(LogTimelineDB and LogTimelineDB.hideLongDurations or false)
        end
    else
        print("[LogTimeline] Commands: lock, unlock, debuglayer, linear, log, base [number], min [seconds], fontsize [6-30], reset, config")
    end
end

local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        print("[LogTimeline] Loaded")
        LogTimelineDB = LogTimelineDB or {}
        LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
        LogTimelineDB.timelineMaxDuration = LogTimelineDB.timelineMaxDuration or 45
        LogTimelineDB.hideLongDurations = LogTimelineDB.hideLongDurations or false
        LoadPositionAndSize()
        InitializeIcons()
        CheckBuff()
        CheckCooldowns()
        CheckDebuff()
        if ConfigFrame and ConfigFrame:IsShown() then
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            WidthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            LengthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            MaxDurationSlider:SetValue(LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45)
            MaxDurationSlider.Value:SetText(LogTimelineDB and LogTimelineDB.timelineMaxDuration or 45)
            HideLongDurationsCheck:SetChecked(LogTimelineDB and LogTimelineDB.hideLongDurations or false)
            if LockButton then LockButton:SetText(TimelineFrame.locked and "Unlock" or "Lock and Close") end
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then CheckBuff() elseif unit == "target" then CheckDebuff() end
    elseif event == "SPELL_UPDATE_COOLDOWN" then CheckCooldowns()
    elseif event == "PLAYER_TARGET_CHANGED" then CheckDebuff()
    end
end)

local updateTimer = 0
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= UPDATE_INTERVAL then
        UpdateIconPositions()
        updateTimer = 0
    end
end)