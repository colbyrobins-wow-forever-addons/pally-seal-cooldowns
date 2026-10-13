local _, addon = ...

addon.SoundChoices = {
    {key = "raid", label = "Raid warning", kit = "RAID_WARNING"},
    {key = "whisper", label = "Whisper", kit = "TELL_MESSAGE"},
    {key = "click", label = "Soft UI click", kit = "IG_MAINMENU_OPTION"},
}
table.insert(addon.SoundChoices, {key = "chime", label = "Gentle chime",
    file = "Interface\\AddOns\\PallySealCooldowns\\Sounds\\RefreshChime.wav"})
addon.SoundChannels = {"Master", "SFX", "Dialog"}

function addon.PlayWarning(db, alert)
    local selected = alert == "missing" and db.missingSoundChoice or db.soundChoice
    local kit = SOUNDKIT.RAID_WARNING
    for _, choice in ipairs(addon.SoundChoices) do
        if choice.key == selected then
            if choice.file then
                if PlaySoundFile and PlaySoundFile(choice.file, db.soundChannel) then return end
            else
                kit = SOUNDKIT[choice.kit] or kit
            end
        end
    end
    PlaySound(kit, db.soundChannel)
end

function addon.CreateSettings(db, apply)
    local panelName = "PallySealCooldownsSettings"
    local panel = CreateFrame("Frame", panelName, UIParent, "BackdropTemplate")
    panel.name = "Pally Seal Cooldowns"
    panel:SetSize(800, 700)
    panel:SetPoint("CENTER")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not self.embedded then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 20, -20)
    heading:SetText(panel.name)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() panel:Hide() end)
    function panel:SetEmbedded(embedded)
        self.embedded = embedded
        self:SetMovable(not embedded)
        self:SetFrameStrata(embedded and "MEDIUM" or "DIALOG")
        close:SetShown(not embedded)
        self:SetBackdrop(not embedded and {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
        } or nil)
        if not embedded then self:SetBackdropColor(0.08, 0.08, 0.12, 0.98) end
    end
    panel:SetEmbedded(false)
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -55)
    scroll:SetPoint("BOTTOMRIGHT", -32, 16)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(740, 810)
    scroll:SetScrollChild(content)
    local general = CreateFrame("Frame", nil, content)
    local appearance = CreateFrame("Frame", nil, content)
    general:SetSize(370, 810)
    appearance:SetSize(370, 810)
    local function Layout()
        local width = scroll:GetWidth()
        if not width or width <= 0 then width = 740 end
        local columns = width >= 740 and 2 or 1
        content:SetSize(math.max(370, width), columns == 2 and 810 or 1440)
        general:ClearAllPoints()
        general:SetPoint("TOPLEFT", 0, 0)
        appearance:ClearAllPoints()
        appearance:SetPoint("TOPLEFT", columns == 2 and 370 or 0, columns == 2 and 0 or -810)
    end
    scroll:HookScript("OnSizeChanged", Layout)
    local function SectionHeading(parent, text)
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("TOPLEFT", 26, -12)
        label:SetText(text)
    end
    SectionHeading(general, "General & alerts")
    SectionHeading(appearance, "Appearance & presets")
    local syncing = false
    local controls = {}
    local section = general

    local function Checkbox(label, y, key, checkedValue, uncheckedValue)
        local button = CreateFrame("CheckButton", nil, section, "UICheckButtonTemplate")
        button:SetPoint("TOPLEFT", 18, y)
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", button, "RIGHT", 3, 0)
        text:SetText(label)
        button:SetScript("OnClick", function(self)
            db[key] = self:GetChecked() and checkedValue or uncheckedValue
            apply()
        end)
        controls[#controls + 1] = function() button:SetChecked(db[key] == checkedValue) end
    end

    local function Slider(label, y, key, minimum, maximum, step, format)
        local slider = CreateFrame("Slider", nil, section)
        slider:SetPoint("TOPLEFT", 26, y)
        slider:SetSize(330, 16)
        slider:SetOrientation("HORIZONTAL")
        slider:SetMinMaxValues(minimum, maximum)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints()
        track:SetColorTexture(0.2, 0.2, 0.25, 1)
        local text = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 6)
        slider:SetScript("OnValueChanged", function(_, value)
            local rounded = math.floor(value / step + 0.5) * step
            if (key == "timerSize" or key == "nameSize")
                and rounded > 0 and rounded < 8 then rounded = 0 end
            text:SetText(label .. string.format(format, rounded))
            if syncing then return end
            db[key] = rounded
            addon.NormalizeAppearance(db)
            apply()
        end)
        controls[#controls + 1] = function() slider:SetValue(db[key]) end
    end

    local function Selector(label, y, key, source)
        local button = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", 26, y)
        button:SetSize(330, 26)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local function Choices()
            return type(source) == "function" and source() or source
        end
        local function Update()
            local choices = Choices()
            button:SetText(label .. tostring(db[key]):gsub("^media:", "") .. " (unavailable)")
            for _, choice in ipairs(choices) do
                if choice.key == db[key] then button:SetText(label .. choice.label .. "  >") end
            end
        end
        button:SetScript("OnClick", function(_, mouseButton)
            local choices = Choices()
            local selected = 0
            for index, choice in ipairs(choices) do
                if choice.key == db[key] then
                    selected = index
                    break
                end
            end
            local direction = mouseButton == "RightButton" and -1 or 1
            db[key] = choices[(selected - 1 + direction) % #choices + 1].key
            Update()
            apply()
        end)
        controls[#controls + 1] = Update
    end
    Checkbox("Lock tracker position", -55, "locked", true, false)
    Checkbox("Play refresh warning sound", -90, "sound", true, false)
    Checkbox("Show countdown only when refresh is due", -125, "counterMode", "refresh", "always")
    Checkbox("Small icon with horizontal timer bar", -160, "displayStyle", "bar", "icon")
    Checkbox("Hide outside combat", -195, "hideOutOfCombat", true, false)
    Checkbox("Show seal name", -230, "showSealName", true, false)
    Checkbox("Show status text", -265, "showStatusText", true, false)
    Slider("Refresh warning: ", -335, "threshold", 1, 30, 1, "%d seconds")
    Slider("Display size: ", -390, "scale", 0.5, 2, 0.05, "%.2fx")
    Slider("Bar width (bar style): ", -445, "barWidth", 120, 360, 1, "%d px")
    Selector("Refresh sound: ", -480, "soundChoice", addon.SoundChoices)
    local channels = {}
    for _, channel in ipairs(addon.SoundChannels) do
        channels[#channels + 1] = {key = channel, label = channel}
    end
    Selector("Audio channel: ", -515, "soundChannel", channels)
    local preview = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    preview:SetSize(170, 26)
    preview:SetPoint("TOPLEFT", 26, -550)
    preview:SetText("Test refresh sound")
    preview:SetScript("OnClick", function() addon.PlayWarning(db) end)
    local reset = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    reset:SetSize(170, 26)
    reset:SetPoint("TOPLEFT", 24, -590)
    reset:SetText("Reset position and size")
    reset:SetScript("OnClick", function()
        db.x, db.y, db.scale = 0, -160, 1
        apply()
        panel:Synchronize()
    end)

    Checkbox("Refresh sound only in combat", -630, "refreshCombatOnly", true, false)
    Checkbox("Play missing-seal sound", -665, "missingSound", true, false)
    Checkbox("Missing sound only in combat", -700, "missingCombatOnly", true, false)
    Selector("Missing sound: ", -740, "missingSoundChoice", addon.SoundChoices)
    local missingPreview = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    missingPreview:SetSize(170, 26)
    missingPreview:SetPoint("TOPLEFT", 26, -775)
    missingPreview:SetText("Test missing sound")
    missingPreview:SetScript("OnClick", function() addon.PlayWarning(db, "missing") end)

    section = appearance
    local hint = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 26, -52)
    hint:SetWidth(330)
    hint:SetText("Changes apply live. Left/right-click choices to cycle.\nFont size 0 uses the layout default.")
    Selector("Font: ", -90, "font", function() return addon.MediaChoices("font") end)
    Selector("Outline: ", -125, "outline", addon.OutlineChoices)
    Checkbox("Text shadow", -155, "fontShadow", true, false)
    Slider("Countdown font size: ", -220, "timerSize", 0, 40, 1, "%d px")
    Slider("Seal name font size: ", -275, "nameSize", 0, 24, 1, "%d px")
    Selector("Border: ", -310, "border", function() return addon.MediaChoices("border") end)
    Selector("Border color: ", -345, "borderColor", addon.BorderColors)
    Slider("Custom border thickness: ", -410, "borderSize", 1, 16, 1, "%d px")
    Selector("Bar texture: ", -445, "statusbar", function() return addon.MediaChoices("statusbar") end)
    local mediaHint = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mediaHint:SetPoint("TOPLEFT", 26, -484)
    mediaHint:SetWidth(330)
    mediaHint:SetText("Installed SharedMedia choices appear automatically.\nMissing media uses the default appearance.\nWarning colors still indicate when a seal is due.")
    for index, choice in ipairs(addon.PresetChoices) do
        local preset = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        preset:SetSize(106, 26)
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        preset:SetPoint("TOPLEFT", 26 + column * 112, -550 - row * 34)
        preset:SetText(choice.label)
        preset:SetScript("OnClick", function()
            addon.ApplyPreset(db, choice.key)
            apply()
            panel:Synchronize()
        end)
    end
    function panel:Synchronize()
        syncing = true
        for _, update in ipairs(controls) do update() end
        syncing = false
        Layout()
    end
    panel.OnRefresh = function() panel:Synchronize() end
    panel.refresh = panel.OnRefresh
    panel:SetScript("OnShow", function(self)
        if self.embedded then
            self:SetFrameStrata(self:GetParent():GetFrameStrata())
        end
        self:Synchronize()
        apply()
    end)
    panel:Hide()
    return panel
end

local settingsPanel, category, registered

function addon.RegisterSettings(db, apply)
    if registered or (InCombatLockdown and InCombatLockdown()) then return end
    local modern = Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function"
    if not modern and type(InterfaceOptions_AddCategory) ~= "function" then return end
    if not settingsPanel then settingsPanel = addon.CreateSettings(db, apply) end
    settingsPanel:SetEmbedded(true)
    settingsPanel:ClearAllPoints()
    if modern then
        category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(settingsPanel)
    end
    registered = true
end

function addon.OpenSettings(db, apply)
    if InCombatLockdown and InCombatLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("Pally Seals: Open settings after combat ends.")
        return
    end
    addon.RegisterSettings(db, apply)
    if category and Settings and type(Settings.OpenToCategory) == "function" then
        Settings.OpenToCategory(category:GetID())
    elseif registered and type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(settingsPanel)
    elseif not registered then
        if not settingsPanel then
            settingsPanel = addon.CreateSettings(db, apply)
            table.insert(UISpecialFrames, "PallySealCooldownsSettings")
        end
        settingsPanel:Show()
        settingsPanel:Synchronize()
    end
end
