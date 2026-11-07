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

addon.SettingsPages = {
    {key = "general", label = "General", height = 360},
    {key = "layout", label = "Layout", height = 580},
    {key = "alerts", label = "Alerts", height = 640},
    {key = "appearance", label = "Appearance", height = 520},
    {key = "presets", label = "Presets", height = 140},
}

function addon.CreateSettings(db, apply)
    local panelName = "PallySealCooldownsSettings"
    local panel = CreateFrame("Frame", panelName, UIParent, "BackdropTemplate")
    panel.name = "Pally Seal Cooldowns"
    panel:SetSize(440, 640)
    panel:SetPoint("CENTER")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        if not self.embedded then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText(panel.name)
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

    local syncing = false
    local controls = {}
    local pages, tabs, selected = {}, {}, "general"
    panel.pages = pages
    for index, info in ipairs(addon.SettingsPages) do
        -- General is the category's own page; the rest become sub-pages.
        local page = CreateFrame("Frame", nil, index == 1 and panel or UIParent)
        page.key, page.name = info.key, info.label
        local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        heading:SetPoint("TOPLEFT", 20, -20)
        heading:SetText(info.label)
        local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -50)
        scroll:SetPoint("BOTTOMRIGHT", -32, 16)
        page.content = CreateFrame("Frame", nil, scroll)
        page.content:SetSize(380, info.height)
        scroll:SetScrollChild(page.content)
        page.OnRefresh = function() panel:Synchronize() end
        page.refresh = page.OnRefresh
        if index > 1 then
            page:SetScript("OnShow", function(self)
                local parent = self:GetParent()
                if parent and parent ~= panel then self:SetFrameStrata(parent:GetFrameStrata()) end
                panel:Synchronize()
                apply()
            end)
            page:Hide()
        end
        pages[index], pages[info.key] = page, page
    end

    local function SelectPage(key)
        selected = key
        for _, page in ipairs(pages) do page:SetShown(page.key == key) end
        for _, tab in ipairs(tabs) do tab:SetEnabled(tab.key ~= key) end
    end
    for index, page in ipairs(pages) do
        local tab = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tab.key = page.key
        tab:SetSize(80, 22)
        tab:SetPoint("TOPLEFT", 14 + (index - 1) * 82, -46)
        tab:SetText(page.name)
        tab:SetScript("OnClick", function() SelectPage(page.key) end)
        tabs[index] = tab
    end
    -- Hosted pages switch with tabs inside this frame (standalone window, or a
    -- client without sub-categories); otherwise each page is its own category.
    function panel:SetHostedPages(hosted)
        self.hosted = hosted
        title:SetShown(hosted)
        for _, tab in ipairs(tabs) do tab:SetShown(hosted) end
        for index, page in ipairs(pages) do
            if hosted or index == 1 then
                page:SetParent(self)
                page:ClearAllPoints()
                page:SetPoint("TOPLEFT", 0, hosted and -70 or 0)
                page:SetPoint("BOTTOMRIGHT")
            end
        end
        if hosted then
            SelectPage(selected)
        else
            for index, page in ipairs(pages) do page:SetShown(index == 1) end
        end
    end

    local section
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
            if key == "cdmIconSize" and rounded > 0 and rounded < 16 then rounded = 0 end
            text:SetText(label .. string.format(format, rounded))
            if syncing then return end
            db[key] = rounded
            addon.NormalizeAppearance(db)
            addon.NormalizeCooldownManager(db)
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

    local function ActionButton(label, y, width, onClick)
        local button = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        button:SetSize(width, 26)
        button:SetPoint("TOPLEFT", 26, y)
        button:SetText(label)
        button:SetScript("OnClick", onClick)
        return button
    end

    local function Hint(y, text)
        local hint = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 26, y)
        hint:SetWidth(330)
        hint:SetJustifyH("LEFT")
        hint:SetText(text)
    end

    local function Heading(y, text)
        local heading = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        heading:SetPoint("TOPLEFT", 22, y)
        heading:SetText(text)
    end

    section = pages.general.content
    Checkbox("Lock tracker position", -10, "locked", true, false)
    Checkbox("Show countdown only when refresh is due", -45, "counterMode", "refresh", "always")
    Checkbox("Hide outside combat", -80, "hideOutOfCombat", true, false)
    Checkbox("Show seal name", -115, "showSealName", true, false)
    Checkbox("Show status text", -150, "showStatusText", true, false)
    Slider("Refresh warning: ", -220, "threshold", 1, 30, 1, "%d seconds")
    Slider("Display size: ", -275, "scale", 0.5, 2, 0.05, "%.2fx")
    ActionButton("Reset position and size", -310, 170, function()
        db.x, db.y, db.scale = 0, -160, 1
        apply()
        panel:Synchronize()
    end)

    -- Each layout's own options sit under a heading naming that layout.
    section = pages.layout.content
    Selector("Layout: ", -10, "displayStyle", addon.LayoutChoices)
    Hint(-45, "Large icon: 52 px icon with a thin bar beneath.\n"
        .. "Small icon with timer bar: 30 px icon and a long bar.\n"
        .. "Essential Cooldowns icon: matches Blizzard's bar icons.")
    Heading(-100, "Large icon and Essential Cooldowns icon")
    Checkbox("Show duration bar under icon", -118, "showIconBar", true, false)
    Slider("Essential icon size: ", -180, "cdmIconSize", 0, 80, 1, "%d px (0 follows Blizzard)")
    Heading(-215, "Small icon with timer bar")
    Slider("Bar width: ", -255, "barWidth", 120, 360, 1, "%d px")
    Selector("Bar texture: ", -290, "statusbar", function() return addon.MediaChoices("statusbar") end)
    Checkbox("Bar counts down (starts full, drains right to left)", -322, "barCountdown", true, false)
    Heading(-365, "Snap to Blizzard's Essential Cooldowns bar (any layout)")
    Checkbox("Snap to Essential Cooldowns bar", -383, "snapToCDM", true, false)
    Selector("Snap position: ", -423, "snapSide", addon.SnapSides)
    Slider("Gap from bar: ", -478, "snapGap", 0, 20, 1, "%d px")
    Hint(-505, "While snapped, the tracker follows the bar when it moves in\n"
        .. "Edit Mode and cannot be dragged. If the bar is unavailable,\n"
        .. "the saved position is used. Bar countdown and texture also\n"
        .. "apply to the thin bar under the large icon.")

    section = pages.alerts.content
    Heading(-10, "Refresh warning")
    Checkbox("Play refresh warning sound", -28, "sound", true, false)
    Checkbox("Refresh sound only in combat", -63, "refreshCombatOnly", true, false)
    Selector("Refresh sound: ", -103, "soundChoice", addon.SoundChoices)
    local channels = {}
    for _, channel in ipairs(addon.SoundChannels) do
        channels[#channels + 1] = {key = channel, label = channel}
    end
    Selector("Audio channel: ", -138, "soundChannel", channels)
    ActionButton("Test refresh sound", -173, 170, function() addon.PlayWarning(db) end)
    Heading(-218, "When no seal is active")
    Selector("Combat alert: ", -238, "missingAlert", addon.MissingAlertChoices)
    Checkbox("Hide tracker when no seal is active", -270, "hideWhenMissing", true, false)
    Checkbox("Show missing-seal text", -305, "showMissingText", true, false)
    Selector("Missing symbol: ", -343, "missingSymbol", addon.MissingSymbols)
    Selector("Placeholder icon: ", -378, "missingIcon", addon.MissingIcons)
    Checkbox("Play missing-seal sound", -410, "missingSound", true, false)
    Checkbox("Missing sound only in combat", -445, "missingCombatOnly", true, false)
    Selector("Missing sound: ", -485, "missingSoundChoice", addon.SoundChoices)
    ActionButton("Test missing sound", -520, 170, function() addon.PlayWarning(db, "missing") end)
    Hint(-560, "Both alerts share the audio channel.\nTests play even when alerts are off or combat-only.\n"
        .. "Missing-seal text also follows Show seal name and\nShow status text on the General page.")

    section = pages.appearance.content
    Hint(-10, "Changes apply live. Left/right-click choices to cycle.\nFont size 0 uses the layout default.")
    Selector("Font: ", -48, "font", function() return addon.MediaChoices("font") end)
    Selector("Outline: ", -83, "outline", addon.OutlineChoices)
    Checkbox("Text shadow", -113, "fontShadow", true, false)
    Slider("Countdown font size: ", -178, "timerSize", 0, 40, 1, "%d px")
    Slider("Seal name font size: ", -233, "nameSize", 0, 24, 1, "%d px")
    Selector("Border: ", -268, "border", function() return addon.MediaChoices("border") end)
    Selector("Border color: ", -303, "borderColor", addon.BorderColors)
    Slider("Custom border thickness: ", -368, "borderSize", 1, 16, 1, "%d px")
    Selector("Warning color: ", -403, "warningColor", addon.WarningColors)
    Hint(-440, "Installed SharedMedia choices appear automatically.\nMissing media uses the default appearance.\n"
        .. "Warning color marks a due refresh and a missing seal.\nBar options are on the Layout page.")

    section = pages.presets.content
    Hint(-10, "Presets replace only appearance settings.\nTiming, sounds, position, and visibility are kept.")
    for index, choice in ipairs(addon.PresetChoices) do
        local preset = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        preset:SetSize(106, 26)
        local column = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        preset:SetPoint("TOPLEFT", 26 + column * 112, -50 - row * 34)
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
    panel:SetHostedPages(true)
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
    local pages = settingsPanel.pages
    if modern then
        category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
        Settings.RegisterAddOnCategory(category)
        local nested = type(Settings.RegisterCanvasLayoutSubcategory) == "function"
        if nested then
            for index = 2, #pages do
                Settings.RegisterCanvasLayoutSubcategory(category, pages[index], pages[index].name)
            end
        end
        settingsPanel:SetHostedPages(not nested)
    else
        InterfaceOptions_AddCategory(settingsPanel)
        for index = 2, #pages do
            pages[index].parent = settingsPanel.name
            InterfaceOptions_AddCategory(pages[index])
        end
        settingsPanel:SetHostedPages(false)
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
