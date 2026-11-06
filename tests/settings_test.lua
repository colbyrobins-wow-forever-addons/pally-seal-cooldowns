local widgets = {}
local function Widget(kind, parent)
    local widget = {kind = kind, scripts = {}, parent = parent, shown = true}
    setmetatable(widget, {__index = function(_, name)
        if name == "SetScript" or name == "HookScript" then
            return function(self, event, handler) self.scripts[event] = handler end
        elseif name == "SetSize" then
            return function(self, width, height) self.width, self.height = width, height end
        elseif name == "GetWidth" then
            return function(self) return rawget(self, "width") end
        elseif name == "SetPoint" then
            return function(self, ...) self.point = {...} end
        elseif name == "SetScrollChild" then
            return function(self, child) self.child = child end
        elseif name == "SetChecked" or name == "SetText" then
            return function(self, value) self.value = value end
        elseif name == "GetChecked" or name == "GetText" then
            return function(self) return self.value end
        elseif name == "SetValue" then
            return function(self, value)
                self.value = value
                self.scripts.OnValueChanged(self, value)
            end
        elseif name == "Show" or name == "Hide" or name == "SetShown" then
            return function(self, value)
                if name == "SetShown" then self.shown = value and true or false
                else self.shown = name == "Show" end
            end
        elseif name == "SetEnabled" then
            return function(self, value) self.enabled = value end
        elseif name == "SetParent" then
            return function(self, value) self.parent = value end
        elseif name == "GetParent" then
            return function(self) return rawget(self, "parent") end
        elseif name == "CreateTexture" or name == "CreateFontString" then
            return function(self) return Widget("Region", self) end
        end
        return function() end
    end})
    widgets[#widgets + 1] = widget
    return widget
end
CreateFrame = function(kind, _, parent) return Widget(kind, parent) end
UIParent = Widget("Root")
UISpecialFrames = {}
local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Appearance.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
local db = {locked = true, sound = true, counterMode = "always", threshold = 5, scale = 1}
db.barWidth, db.showSealName, db.showStatusText = 188, true, true
db.soundChoice, db.soundChannel = "raid", "Master"
addon.NormalizeAppearance(db)
SOUNDKIT = {RAID_WARNING = 1, TELL_MESSAGE = 2, IG_MAINMENU_OPTION = 3}
local playedKit, playedChannel
PlaySound = function(kit, channel) playedKit, playedChannel = kit, channel end
local applied = 0
local panel = addon.CreateSettings(db, function() applied = applied + 1 end)
panel:Synchronize()
assert(applied == 0, "Opening settings must not change stored values")
local pages = panel.pages

-- Controls are found by visible label so layout order can change freely.
local function Label(widget)
    if widget.kind == "Button" then return widget.value end
    for _, region in ipairs(widgets) do
        if region.kind == "Region" and region.parent == widget and type(region.value) == "string" then
            return region.value
        end
    end
end
local function Find(kind, prefix)
    for _, widget in ipairs(widgets) do
        local label = widget.kind == kind and not rawget(widget, "key") and Label(widget)
        if type(label) == "string" and label:sub(1, #prefix) == prefix then return widget end
    end
    error("Missing " .. kind .. ": " .. prefix)
end
local function PageOf(widget)
    while widget and not rawget(widget, "content") do widget = widget.parent end
    return widget and widget.key
end
local function Click(check, value)
    check.value = value
    check.scripts.OnClick(check)
end

-- Four pages: General is the category itself; the others become sub-pages.
local expectedPages = {{"general", "General"}, {"alerts", "Alerts & sounds"},
    {"appearance", "Appearance"}, {"presets", "Presets"}}
assert(#pages == #expectedPages, "Settings must provide four pages")
for index, expected in ipairs(expectedPages) do
    assert(pages[index].key == expected[1] and pages[index].name == expected[2])
    assert(pages[expected[1]] == pages[index], "Pages are reachable by key")
end
local placement = {
    {"CheckButton", "Lock tracker position", "general"},
    {"CheckButton", "Show countdown only when refresh is due", "general"},
    {"CheckButton", "Small icon with horizontal timer bar", "general"},
    {"CheckButton", "Hide outside combat", "general"},
    {"CheckButton", "Show seal name", "general"},
    {"CheckButton", "Show status text", "general"},
    {"Slider", "Refresh warning: ", "general"},
    {"Slider", "Display size: ", "general"},
    {"Slider", "Bar width (bar style): ", "general"},
    {"Button", "Reset position and size", "general"},
    {"CheckButton", "Play refresh warning sound", "alerts"},
    {"CheckButton", "Refresh sound only in combat", "alerts"},
    {"Button", "Refresh sound: ", "alerts"},
    {"Button", "Audio channel: ", "alerts"},
    {"Button", "Test refresh sound", "alerts"},
    {"CheckButton", "Play missing-seal sound", "alerts"},
    {"CheckButton", "Missing sound only in combat", "alerts"},
    {"Button", "Missing sound: ", "alerts"},
    {"Button", "Test missing sound", "alerts"},
    {"Button", "Font: ", "appearance"},
    {"Button", "Outline: ", "appearance"},
    {"CheckButton", "Text shadow", "appearance"},
    {"Slider", "Countdown font size: ", "appearance"},
    {"Slider", "Seal name font size: ", "appearance"},
    {"Button", "Border: ", "appearance"},
    {"Button", "Border color: ", "appearance"},
    {"Slider", "Custom border thickness: ", "appearance"},
    {"Button", "Bar texture: ", "appearance"},
    {"CheckButton", "Bar counts down", "appearance"},
}
for _, choice in ipairs(addon.PresetChoices) do
    placement[#placement + 1] = {"Button", choice.label, "presets"}
end
for _, entry in ipairs(placement) do
    assert(PageOf(Find(entry[1], entry[2])) == entry[3], entry[2] .. " belongs on " .. entry[3])
end
local counts = {}
for _, widget in ipairs(widgets) do
    counts[widget.kind] = (counts[widget.kind] or 0) + 1
    assert(widget.kind ~= "EditBox", "Custom seal input must be removed")
end
assert(counts.CheckButton == 12 and counts.Slider == 6, "No controls are lost in the split")
assert(counts.ScrollFrame == 4, "Each page scrolls independently")

-- General page.
local lock = Find("CheckButton", "Lock tracker position")
assert(lock.value == true)
Click(lock, false)
assert(db.locked == false)
local counter = Find("CheckButton", "Show countdown only when refresh is due")
assert(counter.value == false)
Click(counter, true)
assert(db.counterMode == "refresh")
local barStyle = Find("CheckButton", "Small icon with horizontal timer bar")
Click(barStyle, true)
assert(db.displayStyle == "bar", "Bar style must apply immediately")
panel:Synchronize()
assert(barStyle.value == true, "Bar preference must be restored in the window")
Click(barStyle, false)
assert(db.displayStyle == "icon", "Unchecking bar style must restore icon layout")
local hide = Find("CheckButton", "Hide outside combat")
Click(hide, true)
assert(db.hideOutOfCombat == true)
panel:Synchronize()
assert(hide.value == true, "Combat visibility preference must be restored")
Click(hide, false)
assert(db.hideOutOfCombat == false)
Find("Slider", "Refresh warning: "):SetValue(8)
Find("Slider", "Display size: "):SetValue(1.25)
assert(db.threshold == 8 and db.scale == 1.25)
Click(Find("CheckButton", "Show seal name"), false)
Click(Find("CheckButton", "Show status text"), false)
assert(db.showSealName == false and db.showStatusText == false)
Find("Slider", "Bar width (bar style): "):SetValue(250)
assert(db.barWidth == 250)

-- Alerts & sounds page.
local soundButton = Find("Button", "Refresh sound: ")
local channelButton = Find("Button", "Audio channel: ")
local refreshPreview = Find("Button", "Test refresh sound")
local missingButton = Find("Button", "Missing sound: ")
local missingPreview = Find("Button", "Test missing sound")
soundButton.scripts.OnClick()
channelButton.scripts.OnClick()
assert(db.soundChoice == "whisper" and db.soundChannel == "SFX")
refreshPreview.scripts.OnClick()
assert(playedKit == 2 and playedChannel == "SFX", "Preview must use selected sound and channel")
db.sound = false
refreshPreview.scripts.OnClick()
assert(playedKit == 2, "Explicit preview works when automatic sounds are disabled")
Find("Button", "Reset position and size").scripts.OnClick()
assert(db.x == 0 and db.y == -160 and db.scale == 1)
assert(Find("Slider", "Display size: ").value == 1, "Reset refreshes the general page")
db.missingSoundChoice = "raid"
panel:Synchronize()
missingButton.scripts.OnClick()
assert(db.missingSoundChoice == "whisper" and db.soundChoice == "whisper")
db.soundChoice = "click"
missingPreview.scripts.OnClick()
assert(playedKit == 2, "Missing preview uses its independent choice")
for label, key in pairs({["Refresh sound only in combat"] = "refreshCombatOnly",
    ["Play missing-seal sound"] = "missingSound", ["Missing sound only in combat"] = "missingCombatOnly"}) do
    Click(Find("CheckButton", label), true)
    assert(db[key] == true)
end

-- Appearance page.
local countdown = Find("CheckButton", "Bar counts down")
assert(countdown.value == false, "Bar fills up unless countdown is chosen")
Click(countdown, true)
assert(db.barCountdown == true, "Bar countdown choice must save")
panel:Synchronize()
assert(countdown.value == true, "Bar countdown choice must be restored in the window")
local filePlayed
PlaySoundFile = function(path, channel)
    filePlayed = path
    assert(channel == "SFX")
    return true
end
db.soundChoice = "chime"
addon.PlayWarning(db)
assert(filePlayed:find("RefreshChime.wav", 1, true), "Chime uses bundled audio")
PlaySoundFile = function() return false end
addon.PlayWarning(db)
assert(playedKit == 1, "Unavailable chime falls back to raid warning")
-- Explicit previews bypass automatic enable/combat filters on every channel.
db.sound, db.missingSound = false, false
db.refreshCombatOnly, db.missingCombatOnly = true, true
db.soundChoice, db.missingSoundChoice = "chime", "whisper"
for _, channel in ipairs({"Master", "SFX", "Dialog"}) do
    db.soundChannel = channel
    local fileCalls, kitCalls = 0, 0
    PlaySoundFile = function(path, actualChannel)
        fileCalls = fileCalls + 1
        assert(path == "Interface\\AddOns\\PallySealCooldowns\\Sounds\\RefreshChime.wav")
        assert(actualChannel == channel)
        return true
    end
    PlaySound = function(kit, actualChannel)
        kitCalls = kitCalls + 1
        assert(kit == SOUNDKIT.TELL_MESSAGE and actualChannel == channel)
    end
    refreshPreview.scripts.OnClick()
    missingPreview.scripts.OnClick()
    assert(fileCalls == 1 and kitCalls == 1,
        "Each preview plays only its selected sound on the shared channel")
    -- Both failed playback and a missing playback API must fall back exactly once.
    for _, available in ipairs({true, false}) do
        PlaySoundFile = available and function() return false end or nil
        PlaySound = function(kit, actualChannel)
            kitCalls = kitCalls + 1
            assert(kit == SOUNDKIT.RAID_WARNING and actualChannel == channel)
        end
        local previousCalls = kitCalls
        refreshPreview.scripts.OnClick()
        assert(kitCalls == previousCalls + 1, "Chime fallback plays exactly once")
    end
end
local fontButton = Find("Button", "Font: ")
fontButton.scripts.OnClick()
assert(db.font == "arial", "Font choice applies immediately")
fontButton.scripts.OnClick(nil, "RightButton")
assert(db.font == "default", "Right click cycles backward")
Find("Slider", "Countdown font size: "):SetValue(22)
Find("Slider", "Seal name font size: "):SetValue(14)
assert(db.timerSize == 22 and db.nameSize == 14)
Click(Find("CheckButton", "Text shadow"), false)
assert(not db.fontShadow)
for _, widget in ipairs(widgets) do
    if widget.kind == "Region" and type(widget.value) == "string"
        and widget.value:find("Installed SharedMedia", 1, true) then
        assert(widget.parent == pages.appearance.content, "Appearance help must scroll with controls")
    end
end

-- Presets page.
local function Preset(label) Find("Button", label).scripts.OnClick() end
Preset("Minimal")
assert(db.border == "solid" and db.borderSize == 1, "Minimal preset applies")
Preset("High Contrast")
assert(db.outline == "THICKOUTLINE" and db.borderSize == 3)
Preset("Classic Gold")
assert(db.border == "tooltip" and db.borderColor == "gold")
Preset("Paladin Pink")
assert(db.font == "arial" and db.borderColor == "pink")
assert(Find("Button", "Border color: ").value:find("Paladin pink", 1, true),
    "Presets refresh appearance controls on the other page")
Preset("Clean Text")
assert(db.border == "none" and db.timerSize == 16)
Preset("Default")
assert(db.font == "default" and db.timerSize == 0 and db.border == "default")
assert(db.threshold == 8 and db.counterMode == "refresh", "Presets preserve gameplay settings")

-- Standalone window hosts every page behind tabs.
local tabs = {}
for _, widget in ipairs(widgets) do
    if widget.kind == "Button" and rawget(widget, "key") then tabs[#tabs + 1] = widget end
end
assert(#tabs == 4 and panel.hosted, "Standalone window shows page tabs")
for index, page in ipairs(pages) do
    assert(page.parent == panel and tabs[index].key == page.key and tabs[index].value == page.name)
    assert(page.shown == (index == 1), "Standalone window opens on General")
end
assert(tabs[1].enabled == false and tabs[2].enabled == true)
tabs[3].scripts.OnClick()
for index, page in ipairs(pages) do
    assert(page.shown == (index == 3), "Tabs show only the selected page")
end
assert(tabs[3].enabled == false and tabs[1].enabled == true)
local before = applied
pages.appearance.scripts.OnShow(pages.appearance)
assert(applied == before + 1, "Showing a sub-page refreshes it and applies live settings")

local registrations, opened, registeredPanel = 0, nil, nil
local subcategories = {}
local combat = true
local rootCategory = {GetID = function() return 123 end}
InCombatLockdown = function() return combat end
Settings = {
    RegisterCanvasLayoutCategory = function(value, name)
        assert(name == "Pally Seal Cooldowns")
        registeredPanel = value
        return rootCategory
    end,
    RegisterCanvasLayoutSubcategory = function(parent, frame, name)
        assert(parent == rootCategory, "Sub-pages nest under the addon category")
        subcategories[#subcategories + 1] = {frame = frame, name = name}
        return {}
    end,
    RegisterAddOnCategory = function() registrations = registrations + 1 end,
    OpenToCategory = function(id) opened = id end,
}
local function apply() applied = applied + 1 end
addon.RegisterSettings(db, apply)
assert(registrations == 0, "Registration waits until combat ends")
combat = false
addon.RegisterSettings(db, apply)
addon.RegisterSettings(db, apply)
assert(registrations == 1 and registeredPanel.embedded, "Register one native AddOns category")
assert(#subcategories == 3, "Register three native sub-pages")
local nativePages = registeredPanel.pages
for index, sub in ipairs(subcategories) do
    assert(sub.frame == nativePages[index + 1] and sub.name == nativePages[index + 1].name)
    assert(sub.frame.shown == false, "Native sub-pages stay hidden until selected")
end
assert(not registeredPanel.hosted and nativePages[1].shown, "Category page shows General only")
for _, widget in ipairs(widgets) do
    if widget.kind == "Button" and rawget(widget, "key") and widget.parent == registeredPanel then
        assert(widget.shown == false, "Tabs are hidden when sub-pages are native")
    end
end
addon.OpenSettings(db, apply)
assert(opened == 123, "Slash/minimap route to the native category ID")

-- A settings API without sub-categories keeps the tabs inside the one page.
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
Settings.RegisterCanvasLayoutSubcategory = nil
addon.RegisterSettings(db, apply)
assert(registeredPanel.embedded and registeredPanel.hosted, "Tabs remain without sub-categories")

-- Older clients nest the sub-pages through the legacy category API.
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
Settings = nil
local legacy = {}
InterfaceOptions_AddCategory = function(value) legacy[#legacy + 1] = value end
InterfaceOptionsFrame_OpenToCategory = function(value) opened = value end
addon.RegisterSettings(db, apply)
addon.OpenSettings(db, apply)
local legacyPanel = legacy[1]
assert(#legacy == 4 and legacyPanel.embedded and opened == legacyPanel)
for index = 2, 4 do
    assert(legacy[index] == legacyPanel.pages[index] and legacy[index].parent == legacyPanel.name,
        "Legacy sub-pages name the addon category as parent")
end
assert(not legacyPanel.hosted)

-- Without either API, provide a standalone view and later reuse it for registration.
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
InterfaceOptions_AddCategory, InterfaceOptionsFrame_OpenToCategory = nil, nil
before = #widgets
addon.OpenSettings(db, apply)
local standalone = widgets[before + 1]
assert(standalone and not standalone.embedded and standalone.hosted)
legacy = {}
InterfaceOptions_AddCategory = function(value) legacy[#legacy + 1] = value end
addon.RegisterSettings(db, apply)
assert(legacy[1] == standalone and standalone.embedded, "Late registration reuses the existing view")
assert(#legacy == 4 and not standalone.hosted and pages ~= standalone.pages)
for index = 2, 4 do
    assert(standalone.pages[index].shown == false, "Late registration hides hosted sub-pages")
end
io.write("Settings interaction tests passed.\n")
