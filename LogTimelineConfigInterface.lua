-- LogTimelineConfigInterface.lua

-- Create the interface frame
ConfigFrame = CreateFrame("Frame", "LogTimelineConfigFrame", UIParent, "BasicFrameTemplateWithInset")
ConfigFrame:SetSize(300, 200)
ConfigFrame:SetPoint("CENTER")
ConfigFrame:Hide()
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing)
ConfigFrame:SetScript("OnShow", function()
    SetTimelineLock(false)
end)
ConfigFrame:SetScript("OnHide", function()
    SetTimelineLock(true)
    LearningModeConfigFrame:Hide()
end)

-- Title
ConfigFrame.Title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ConfigFrame.Title:SetPoint("TOP", ConfigFrame, "TOP", 0, -5)
ConfigFrame.Title:SetText("LogTimeline Settings")

-- Lock and Close Button
LockButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LockButton:SetSize(100, 25)
LockButton:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -30)
LockButton:SetText("Lock and Close")

LockButton:SetScript("OnClick", function()
    if TimelineFrame then
        local newState = not TimelineFrame.locked
        SetTimelineLock(newState)
        if newState then
            ConfigFrame:Hide()
            LockButton:SetText("Unlock")
            print("[LogTimeline] Timeline locked")
        else
            LockButton:SetText("Lock and Close")
            print("[LogTimeline] Timeline unlocked")
        end
    else
        print("[LogTimeline] TimelineFrame not ready")
    end
end)


LockButton:SetScript("OnShow", function()
    if TimelineFrame then
        LockButton:SetText(TimelineFrame.locked and "Unlock" or "Lock and Close")
    else
        LockButton:SetText("Lock and Close")
    end
end)

-- Learning Mode Button
LearningModeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelButtonTemplate")
LearningModeButton:SetSize(100, 25)
LearningModeButton:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -10, -30)
LearningModeButton:SetText("Learning Mode")

LearningModeButton:SetScript("OnClick", function()
    LearningModeConfigFrame:Show()
end)

-- Learning Mode Config Frame
LearningModeConfigFrame = CreateFrame("Frame", "LearningModeConfigFrame", UIParent, "BasicFrameTemplateWithInset")
LearningModeConfigFrame:SetSize(300, 200)
LearningModeConfigFrame:SetPoint("CENTER")
LearningModeConfigFrame:Hide()
LearningModeConfigFrame:SetMovable(true)
LearningModeConfigFrame:EnableMouse(true)
LearningModeConfigFrame:RegisterForDrag("LeftButton")
LearningModeConfigFrame:SetScript("OnDragStart", LearningModeConfigFrame.StartMoving)
LearningModeConfigFrame:SetScript("OnDragStop", LearningModeConfigFrame.StopMovingOrSizing)
LearningModeConfigFrame:SetScript("OnShow", function()

end)

-- Learning Mode Config FrameTitle
LearningModeConfigFrame.Title = LearningModeConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LearningModeConfigFrame.Title:SetPoint("TOP", LearningModeConfigFrame, "TOP", 0, -5)
LearningModeConfigFrame.Title:SetText("Learning Mode Configuration")

-- Width Slider
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
    if UpdateTimelineSize then
        UpdateTimelineSize()
        print("[LogTimeline] Line thickness set to " .. roundedValue)
    else
        print("[LogTimeline] Line thickness queued to " .. roundedValue)
    end
end)
WidthSlider.Value = WidthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
WidthSlider.Value:SetPoint("BOTTOM", WidthSlider, "BOTTOM", 0, -5)

-- Length Slider
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
    if UpdateTimelineSize then
        UpdateTimelineSize()
        print("[LogTimeline] Line length set to " .. roundedValue)
    else
        print("[LogTimeline] Line length queued to " .. roundedValue)
    end
end)
LengthSlider.Value = LengthSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LengthSlider.Value:SetPoint("BOTTOM", LengthSlider, "BOTTOM", 0, -5)

-- Initialize sliders and handle pending lock state on PLAYER_LOGIN
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Initialize sliders
        LogTimelineDB = LogTimelineDB or {}
        WidthSlider:SetValue(LogTimelineDB.lineThickness or 4)
        WidthSlider.Value:SetText(LogTimelineDB.lineThickness or 4)
        LengthSlider:SetValue(LogTimelineDB.totalDistance or 500)
        LengthSlider.Value:SetText(LogTimelineDB.totalDistance or 500)
        if UpdateTimelineSize then
            UpdateTimelineSize()
        end
        -- Handle pending lock state
        if pendingLockState ~= nil and TimelineFrame and SetTimelineLock then
            SetTimelineLock(pendingLockState)
            LockButton:SetText(pendingLockState and "Unlock" or "Lock and Close")
            print("[LogTimeline] Applied pending lock state: " .. (pendingLockState and "locked" or "unlocked"))
            pendingLockState = nil
        end
    end
end)