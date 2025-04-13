-- LogTimelineCore.lua

-- Tables to store icons
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
TimelineFrame:SetHitRectInsets(-20, -20, -20, -20) -- Expand clickable area
TimelineFrame:Show()
BuffLine:Show()
print("[LogTimeline] BuffLine created with alpha=" .. BuffLine:GetAlpha())

-- Make the timeline movable when unlocked
TimelineFrame:SetMovable(true)
TimelineFrame:EnableMouse(false)
TimelineFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.locked then
        print("[LogTimeline] Starting to move timeline")
        self:StartMoving()
    end
end)
TimelineFrame:SetScript("OnMouseUp", function(self)
    if not self.locked then
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        LogTimelineDB = LogTimelineDB or {}
        LogTimelineDB.point = point
        LogTimelineDB.relativePoint = relativePoint
        LogTimelineDB.xOfs = xOfs
        LogTimelineDB.yOfs = yOfs
        print("[LogTimeline] Timeline moved to: point=" .. (point or "none") .. ", x=" .. (xOfs or 0) .. ", y=" .. (yOfs or 0))
    end
end)

-- SetTimelineLock
function SetTimelineLock(state)
    if not TimelineFrame then
        print("[LogTimeline] TimelineFrame not ready in SetTimelineLock")
        return
    end
    TimelineFrame.locked = state
    TimelineFrame:EnableMouse(not state)
    print("[LogTimeline] Timeline is now " .. (state and "locked" or "unlocked") .. ", mouse enabled: " .. (TimelineFrame:IsMouseEnabled() and "yes" or "no"))
    if LockButton then
        LockButton:SetText(state and "Unlock" or "Lock and Close")
    end
end

-- UpdateTimelineSize
function UpdateTimelineSize()
    LogTimelineDB = LogTimelineDB or {}
    local totalDistance = LogTimelineDB.totalDistance or 500
    local lineThickness = LogTimelineDB.lineThickness or 4
    if not TimelineFrame or not BuffLine then
        print("[LogTimeline] TimelineFrame or BuffLine not ready in UpdateTimelineSize")
        return
    end
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
    local width, height = TimelineFrame:GetSize()
    local texWidth, texHeight = BuffLine:GetSize()
    local point, relativeTo, relativePoint, xOfs, yOfs = TimelineFrame:GetPoint()
    print("[LogTimeline] Set timeline size: width=" .. totalDistance .. ", height=" .. lineThickness)
    print("[LogTimeline] Actual timeline size: width=" .. width .. ", height=" .. height)
    print("[LogTimeline] BuffLine texture size: width=" .. (texWidth or 0) .. ", height=" .. (texHeight or 0))
    print("[LogTimeline] BuffLine visible: " .. (BuffLine:IsVisible() and "yes" or "no"))
    print("[LogTimeline] Timeline position: point=" .. (point or "none") .. ", x=" .. (xOfs or 0) .. ", y=" .. (yOfs or 0))
end

-- Function to update stack text font size
local function UpdateStackTextFontSize()
    local fontSize = (LogTimelineDB and LogTimelineDB.stackFontSize) or STACK_FONT_SIZE or 10
    for _, iconData in pairs(buffIcons) do
        if iconData.stackText then
            iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.stackText then
            iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.stackText then
            iconData.stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        end
    end
end

-- Function to create icon frames
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

-- Function to create cooldown icon frames with selective glow
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
    if spellInfo then
        iconData.icon:SetTexture(spellInfo.iconID)
    end
    
    return iconData
end

-- Initialize all icons
local function InitializeIcons()
    buffIcons = {}
    cooldownIcons = {}
    debuffIcons = {}
    
    -- Initialize default tracking tables
    local trackedBuffs = {}
    local trackedCooldowns = {}
    local trackedDebuffs = {}
    
    -- Merge defaults with saved variables
    LogTimelineDB = LogTimelineDB or {}
    LogTimelineDB.trackedSpells = LogTimelineDB.trackedSpells or {buffs = {}, cooldowns = {}, debuffs = {}}
    
    for _, buffName in ipairs(BUFFS_TO_TRACK) do
        trackedBuffs[buffName] = true
    end
    for _, cooldownInfo in ipairs(COOLDOWNS_TO_TRACK) do
        trackedCooldowns[cooldownInfo.spellName] = {spellID = cooldownInfo.spellID, shouldGlow = cooldownInfo.shouldGlow}
    end
    for _, debuffName in ipairs(DEBUFFS_TO_TRACK) do
        trackedDebuffs[debuffName] = true
    end
    
    -- Add saved tracked spells
    for buffName, _ in pairs(LogTimelineDB.trackedSpells.buffs) do
        trackedBuffs[buffName] = true
    end
    for spellName, info in pairs(LogTimelineDB.trackedSpells.cooldowns) do
        trackedCooldowns[spellName] = {spellID = info.spellID, shouldGlow = info.shouldGlow}
    end
    for debuffName, _ in pairs(LogTimelineDB.trackedSpells.debuffs) do
        trackedDebuffs[debuffName] = true
    end
    
    -- Create icons
    for buffName, _ in pairs(trackedBuffs) do
        buffIcons[buffName] = CreateBuffIcon(buffName)
    end
    for spellName, info in pairs(trackedCooldowns) do
        cooldownIcons[spellName] = CreateCooldownIcon(info.spellID, spellName, info.shouldGlow)
    end
    for debuffName, _ in pairs(trackedDebuffs) do
        debuffIcons[debuffName] = CreateBuffIcon(debuffName)
        debuffIcons[debuffName].isDebuff = true
    end
end

-- Function to check for buffs
local function CheckBuff()
    local currentTime = GetTime()
    local foundBuffs = {}
    
    for _, iconData in pairs(buffIcons) do
        iconData.isActive = false
    end
    
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if aura and buffIcons[aura.name] then
            local iconData = buffIcons[aura.name]
            iconData.icon:SetTexture(aura.icon)
            
            if aura.expirationTime then
                iconData.expirationTime = aura.expirationTime
                iconData.remainingTime = aura.expirationTime - currentTime
            else
                iconData.expirationTime = 0
                iconData.remainingTime = 0
            end
            
            if aura.applications and aura.applications > 1 then
                iconData.stackText:SetText(aura.applications)
            else
                iconData.stackText:SetText("")
            end
            
            iconData.isActive = true
            iconData.frame:Show()
            iconData.groupIndex = 0
            foundBuffs[aura.name] = true
        end
    end
    
    for buffName, iconData in pairs(buffIcons) do
        if not foundBuffs[buffName] then
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
end

-- Function to check for cooldowns
local function CheckCooldowns()
    local currentTime = GetTime()
    
    for _, iconData in pairs(cooldownIcons) do
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

-- Function to check target debuffs
local function CheckDebuff()
    local currentTime = GetTime()
    local foundDebuffs = {}
    
    for _, iconData in pairs(debuffIcons) do
        iconData.isActive = false
    end
    
    if UnitExists("target") then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("target", i, "HARMFUL")
            if aura and debuffIcons[aura.name] then
                local iconData = debuffIcons[aura.name]
                iconData.icon:SetTexture(aura.icon)
                
                if aura.expirationTime then
                    iconData.expirationTime = aura.expirationTime
                    iconData.remainingTime = aura.expirationTime - currentTime
                else
                    iconData.expirationTime = 0
                    iconData.remainingTime = 0
                end
                
                if aura.applications and aura.applications > 1 then
                    iconData.stackText:SetText(aura.applications)
                else
                    iconData.stackText:SetText("")
                end
                
                iconData.isActive = true
                iconData.frame:Show()
                iconData.groupIndex = 0
                foundDebuffs[aura.name] = true
            end
        end
    end
    
    for debuffName, iconData in pairs(debuffIcons) do
        if not foundDebuffs[debuffName] then
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
end

-- LoadPositionAndSize
local function LoadPositionAndSize()
    LogTimelineDB = LogTimelineDB or {}
    if LogTimelineDB.point then
        TimelineFrame:ClearAllPoints()
        TimelineFrame:SetPoint(
            LogTimelineDB.point,
            UIParent,
            LogTimelineDB.relativePoint,
            LogTimelineDB.xOfs,
            LogTimelineDB.yOfs
        )
    else
        TimelineFrame:SetPoint("CENTER", UIParent, "CENTER", -100, 0)
    end
    print("[LogTimeline] Loading position and size")
    UpdateTimelineSize()
    UpdateStackTextFontSize()
end

-- Initialize icons after PLAYER_LOGIN
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        print("[LogTimeline] Loaded for The War Within")
        print("[LogTimeline] Current scale: "..(LOGARITHMIC_SCALE and "Logarithmic (base "..LOG_BASE..")" or "Linear"))
        InitializeIcons()
        LoadPositionAndSize()
        CheckBuff()
        CheckCooldowns()
        CheckDebuff()
        if ConfigFrame and ConfigFrame:IsShown() then
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            WidthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            LengthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            if LockButton then
                LockButton:SetText(TimelineFrame.locked and "Unlock" or "Lock and Close")
            end
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            CheckBuff()
        elseif unit == "target" then
            CheckDebuff()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        CheckCooldowns()
    elseif event == "PLAYER_TARGET_CHANGED" then
        CheckDebuff()
    end
end)


-- Function to calculate position based on time remaining
local function CalculatePosition(timeLeft, maxDuration)
    local totalDistance = LogTimelineDB and LogTimelineDB.totalDistance or 500
    if not LOGARITHMIC_SCALE then
        return (totalDistance/2) - (totalDistance * (1 - (timeLeft / maxDuration)))
    else
        if timeLeft <= MIN_VISIBLE_TIME then
            return (totalDistance/2) - totalDistance
        end
        
        local normalizedTime = (timeLeft - MIN_VISIBLE_TIME) / (maxDuration - MIN_VISIBLE_TIME)
        local logValue = math.log(1 + (LOG_BASE - 1) * normalizedTime) / math.log(LOG_BASE)
        return (totalDistance/2) - (totalDistance * (1 - logValue))
    end
end



-- Function to create icon frames
local function CreateBuffIcon(buffName)
    local iconFrame = CreateFrame("Frame", "LogTimelineIcon_"..buffName, UIParent)
    iconFrame:SetSize(32, 32)
    iconFrame:SetPoint("CENTER", TimelineFrame, "CENTER", (LogTimelineDB and LogTimelineDB.totalDistance or 500)/2, 0)
    iconFrame:Hide()
    iconFrame:SetAlpha(1)
    
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    
    local stackText = iconFrame:CreateFontString(nil, "OVERLAY")
    stackText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0) -- Centered
    stackText:SetTextColor(1, 1, 1, 1)
    -- Set font immediately to avoid "Font not set" error
    local fontSize = LogTimelineDB and LogTimelineDB.stackFontSize or 10 -- Default font size
    stackText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    
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

-- Function to create cooldown icon frames with selective glow
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
        iconData.glow:Hide()
    end
    
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        iconData.icon:SetTexture(spellInfo.iconID)
    end
    
    return iconData
end

-- Initialize all icons
for _, buffName in ipairs(BUFFS_TO_TRACK) do
    buffIcons[buffName] = CreateBuffIcon(buffName)
end

for _, cooldownInfo in ipairs(COOLDOWNS_TO_TRACK) do
    cooldownIcons[cooldownInfo.spellName] = CreateCooldownIcon(
        cooldownInfo.spellID, 
        cooldownInfo.spellName, 
        cooldownInfo.shouldGlow
    )
end

for _, debuffName in ipairs(DEBUFFS_TO_TRACK) do
    debuffIcons[debuffName] = CreateBuffIcon(debuffName)
    debuffIcons[debuffName].isDebuff = true
end


-- Make the timeline movable when unlocked
TimelineFrame:SetMovable(true)
TimelineFrame:EnableMouse(false)
TimelineFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.locked then
        print("[LogTimeline] Starting to move timeline")
        self:StartMoving()
    end
end)
TimelineFrame:SetScript("OnMouseUp", function(self)
    if not self.locked then
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        LogTimelineDB = LogTimelineDB or {}
        LogTimelineDB.point = point
        LogTimelineDB.relativePoint = relativePoint
        LogTimelineDB.xOfs = xOfs
        LogTimelineDB.yOfs = yOfs
        print("[LogTimeline] Timeline moved to: point=" .. (point or "none") .. ", x=" .. (xOfs or 0) .. ", y=" .. (yOfs or 0))
    end
end)

-- Slash command handler
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
        print("[LogTimeline] Timeline frame level: " .. TimelineFrame:GetFrameLevel())
        print("[LogTimeline] BuffLine draw layer: " .. BuffLine:GetDrawLayer())
        for _, iconData in pairs(buffIcons) do
            if iconData.isActive then
                print("[LogTimeline] Buff icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel())
            end
        end
        for _, iconData in pairs(cooldownIcons) do
            if iconData.isActive then
                print("[LogTimeline] Cooldown icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel())
            end
        end
        for _, iconData in pairs(debuffIcons) do
            if iconData.isActive then
                print("[LogTimeline] Debuff icon " .. iconData.name .. " frame level: " .. iconData.frame:GetFrameLevel())
            end
        end    
    elseif command == "linear" then
        LOGARITHMIC_SCALE = false
        print("[LogTimeline] Using linear timeline scale")
    elseif command == "log" then
        LOGARITHMIC_SCALE = true
        print("[LogTimeline] Using logarithmic timeline scale")
    elseif command == "base" and args[2] then
        local newBase = tonumber(args[2])
        if newBase and newBase > 1 then
            LOG_BASE = newBase
            print("[LogTimeline] Logarithm base set to "..LOG_BASE)
        else
            print("[LogTimeline] Invalid base value. Must be a number > 1")
        end
    elseif command == "min" and args[2] then
        local newMin = tonumber(args[2])
        if newMin and newMin >= 0 then
            MIN_VISIBLE_TIME = newMin
            print("[LogTimeline] Minimum visible time set to "..MIN_VISIBLE_TIME.." seconds")
        else
            print("[LogTimeline] Invalid minimum time. Must be a number >= 0")
        end
    elseif command == "fontsize" and args[2] then
        local newSize = tonumber(args[2])
        if newSize and newSize >= 6 and newSize <= 30 then
            LogTimelineDB = LogTimelineDB or {}
            LogTimelineDB.stackFontSize = newSize
            UpdateStackTextFontSize()
            print("[LogTimeline] Stack text font size set to "..newSize)
        else
            print("[LogTimeline] Invalid font size. Must be a number between 6 and 30")
        end
    elseif command == "reset" then
        TimelineFrame:ClearAllPoints()
        TimelineFrame:SetPoint("CENTER", UIParent, "CENTER", -100, 0)
        LogTimelineDB = nil
        LoadPositionAndSize() -- Reset sliders and font size to default
        if ConfigFrame:IsShown() then
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
        end
        print("[LogTimeline] Timeline position, size, and font size reset to default")
    elseif command == "config" then
        if ConfigFrame:IsShown() then
            ConfigFrame:Hide()
        else
            ConfigFrame:Show()
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
        end
    else
        print("[LogTimeline] Commands:")
        print("/logt lock - Lock the timeline position")
        print("/logt unlock - Unlock the timeline position")
        print("/logt linear - Use linear timeline scale")
        print("/logt log - Use logarithmic timeline scale")
        print("/logt base [number] - Set logarithm base (default 20, higher = steeper)")
        print("/logt min [seconds] - Set minimum visible time (default 0.1)")
        print("/logt fontsize [number] - Set stack text font size (6-30, default "..STACK_FONT_SIZE..")")
        print("/logt reset - Reset timeline position, size, and font size to default")
        print("/logt config - Show/hide configuration panel")
    end
end

-- Function to identify overlapping buff groups
local function UpdateOverlapGroups()
    overlapGroups = {}
    for _, iconData in pairs(buffIcons) do
        iconData.groupIndex = 0
    end
    for _, iconData in pairs(cooldownIcons) do
        iconData.groupIndex = 0
    end
    for _, iconData in pairs(debuffIcons) do
        iconData.groupIndex = 0
    end
    
    activeBuffs = {}
    for _, iconData in pairs(buffIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then
            table.insert(activeBuffs, iconData)
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then
            table.insert(activeBuffs, iconData)
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.isActive and iconData.remainingTime > 0 then
            table.insert(activeBuffs, iconData)
        end
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
                for i, iconData in ipairs(newGroup) do
                    iconData.phaseOffset = (i-1) * (2 * math.pi / #newGroup)
                end
            else
                buff.groupIndex = 0
            end
        end
    end
end

-- Function to update alpha values for overlapping buffs
local function UpdateAlphaPhasing()
    for _, iconData in pairs(buffIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 then
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            iconData.frame:SetAlpha(MAX_ALPHA)
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 then
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        else
            iconData.frame:SetAlpha(MAX_ALPHA)
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if not iconData.isActive or iconData.remainingTime <= 0 then
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
            local alpha = 0
            
            if phase < math.pi/2 then
                alpha = 1
            elseif phase < math.pi then
                alpha = 1 - (phase - math.pi/2) / (math.pi/2)
            elseif phase < 3*math.pi/2 then
                alpha = 0
            else
                alpha = (phase - 3*math.pi/2) / (math.pi/2)
            end
            
            local finalAlpha = MIN_ALPHA + (MAX_ALPHA - MIN_ALPHA) * alpha
            iconData.frame:SetAlpha(finalAlpha)
            
            if alpha > maxAlpha then
                maxAlpha = alpha
                leadingIndex = i
            end
        end
        
        for i, iconData in ipairs(group) do
            if i == leadingIndex then
                iconData.stackText:SetAlpha(1)
            else
                iconData.stackText:SetAlpha(0)
            end
            iconData.stackText:Show() -- Ensure text is visible when active
        end
    end
end

-- UpdateIconPositions (ensure icons are in front)
local function UpdateIconPositions()
    local currentTime = GetTime()
    for _, iconData in pairs(buffIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime then
            iconData.remainingTime = iconData.expirationTime - currentTime
            local timeLeft = math.min(iconData.remainingTime, TIMELINE_MAX_DURATION)
            iconData.xPos = CalculatePosition(timeLeft, TIMELINE_MAX_DURATION)
            iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
            iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10) -- Higher level
            iconData.frame:Show()
            if iconData.stackText then
                iconData.stackText:SetDrawLayer("OVERLAY", 1)
            end
        else
            iconData.isActive = false
            iconData.frame:Hide()
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
    for _, iconData in pairs(cooldownIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime then
            iconData.remainingTime = iconData.expirationTime - currentTime
            local timeLeft = math.min(iconData.remainingTime, TIMELINE_MAX_DURATION)
            iconData.xPos = CalculatePosition(timeLeft, TIMELINE_MAX_DURATION)
            iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
            iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10)
            iconData.frame:Show()
            if iconData.stackText then
                iconData.stackText:SetDrawLayer("OVERLAY", 1)
            end
            if iconData.glow and iconData.shouldGlow then
                iconData.glow:SetDrawLayer("OVERLAY", 2)
                iconData.glow:Show()
            end
        else
            iconData.isActive = false
            iconData.frame:Hide()
            if iconData.glow then
                iconData.glow:Hide()
            end
            iconData.xPos = 0
            iconData.groupIndex = 0
        end
    end
    for _, iconData in pairs(debuffIcons) do
        if iconData.isActive and iconData.expirationTime > currentTime then
            iconData.remainingTime = iconData.expirationTime - currentTime
            local timeLeft = math.min(iconData.remainingTime, TIMELINE_MAX_DURATION)
            iconData.xPos = CalculatePosition(timeLeft, TIMELINE_MAX_DURATION)
            iconData.frame:SetPoint("CENTER", TimelineFrame, "CENTER", iconData.xPos, 0)
            iconData.frame:SetFrameLevel(TimelineFrame:GetFrameLevel() + 10)
            iconData.frame:Show()
            if iconData.stackText then
                iconData.stackText:SetDrawLayer("OVERLAY", 1)
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



-- Event handling
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" then
        print("[LogTimeline] Loaded for The War Within")
        print("[LogTimeline] Current scale: "..(LOGARITHMIC_SCALE and "Logarithmic (base "..LOG_BASE..")" or "Linear"))
        for _, iconData in pairs(buffIcons) do
            iconData.frame:Hide()
            iconData.isActive = false
        end
        for _, iconData in pairs(cooldownIcons) do
            iconData.frame:Hide()
            iconData.isActive = false
        end
        for _, iconData in pairs(debuffIcons) do
            iconData.frame:Hide()
            iconData.isActive = false
        end
        LoadPositionAndSize()
        CheckBuff()
        CheckCooldowns()
        CheckDebuff()
        -- Sync config frame if open
        if ConfigFrame and ConfigFrame:IsShown() then
            WidthSlider:SetValue(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            WidthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.lineThickness or 4)
            LengthSlider:SetValue(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            LengthSlider.Value:SetText(LogTimelineDB and LogTimelineDB.totalDistance or 500)
            if LockButton then
                LockButton:SetText(TimelineFrame.locked and "Unlock" or "Lock and Close")
            end
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            CheckBuff()
        elseif unit == "target" then
            CheckDebuff()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        CheckCooldowns()
    elseif event == "PLAYER_TARGET_CHANGED" then
        CheckDebuff()
    end
end)

-- Update position periodically
local updateTimer = 0
EventFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= UPDATE_INTERVAL then
        UpdateIconPositions()
        updateTimer = 0
    end
end)