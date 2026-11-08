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
        elseif name == "SetupMenu" then
            return function(self, generator) self.generator = generator end
        elseif name == "SetDefaultText" then
            return function(self, text) self.defaultText = text end
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
assert(loadfile("PallySealCooldowns/CooldownManager.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
local db = {locked = true, sound = true, counterMode = "always", threshold = 5, scale = 1}
db.barWidth, db.showSealName, db.showStatusText = 188, true, true
db.soundChoice, db.soundChannel = "raid", "Master"
addon.NormalizeAppearance(db)
addon.NormalizeCooldownManager(db)
addon.NormalizeDisplayOptions(db)
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

-- Five pages: General is the category itself; the others become sub-pages.
local expectedPages = {{"general", "General"}, {"layout", "Layout"}, {"alerts", "Alerts"},
    {"appearance", "Appearance"}, {"presets", "Presets"}}
assert(#pages == #expectedPages, "Settings must provide five pages")
for index, expected in ipairs(expectedPages) do
    assert(pages[index].key == expected[1] and pages[index].name == expected[2])
    assert(pages[expected[1]] == pages[index], "Pages are reachable by key")
end
local placement = {
    {"CheckButton", "Lock tracker position", "general"},
    {"CheckButton", "Show countdown only when refresh is due", "general"},
    {"CheckButton", "Hide outside combat", "general"},
    {"CheckButton", "Show seal name", "general"},
    {"CheckButton", "Show status text", "general"},
    {"Slider", "Refresh warning: ", "general"},
    {"Slider", "Display size: ", "general"},
    {"Button", "Reset position and size", "general"},
    {"Button", "Layout: ", "layout"},
    {"CheckButton", "Show duration bar under icon", "layout"},
    {"Slider", "Essential icon size: ", "layout"},
    {"Slider", "Bar width: ", "layout"},
    {"Button", "Bar texture: ", "layout"},
    {"CheckButton", "Bar counts down", "layout"},
    {"Button", "Snap position: ", "layout"},
    {"Slider", "Gap from bar: ", "layout"},
    {"Button", "Combat alert: ", "alerts"},
    {"CheckButton", "Hide tracker when no seal is active", "alerts"},
    {"CheckButton", "Show missing-seal text", "alerts"},
    {"Button", "Missing symbol: ", "alerts"},
    {"Button", "Placeholder icon: ", "alerts"},
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
    {"Button", "Warning color: ", "appearance"},
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
assert(counts.CheckButton == 14 and counts.Slider == 8, "No controls are lost in the split")
assert(counts.ScrollFrame == 5, "Each page scrolls independently")

-- General page.
local lock = Find("CheckButton", "Lock tracker position")
assert(lock.value == true)
Click(lock, false)
assert(db.locked == false)
local counter = Find("CheckButton", "Show countdown only when refresh is due")
assert(counter.value == false)
Click(counter, true)
assert(db.counterMode == "refresh")
-- Layout page: one selector chooses among the three layouts.
db.displayStyle = "icon"
panel:Synchronize()
local layout = Find("Button", "Layout: ")
assert(layout.value == "Layout: Large icon  >")
local applies = applied
layout.scripts.OnClick(layout, "LeftButton")
assert(db.displayStyle == "bar" and applied == applies + 1, "Layout applies immediately")
assert(layout.value == "Layout: Small icon with timer bar  >")
layout.scripts.OnClick(layout, "LeftButton")
assert(db.displayStyle == "essential")
layout.scripts.OnClick(layout, "LeftButton")
assert(db.displayStyle == "swing" and layout.value == "Layout: Swing timer bar  >")
layout.scripts.OnClick(layout, "LeftButton")
assert(db.displayStyle == "icon", "Layouts cycle back to the large icon")
layout.scripts.OnClick(layout, "RightButton")
assert(db.displayStyle == "swing", "Right-click cycles layouts backward")
db.displayStyle = "icon"
panel:Synchronize()
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
Find("Slider", "Bar width: "):SetValue(250)
assert(db.barWidth == 250)
-- Icon-layout duration bar toggle.
db.showIconBar = true
panel:Synchronize()
local iconBar = Find("CheckButton", "Show duration bar under icon")
assert(iconBar.value == true)
Click(iconBar, false)
assert(db.showIconBar == false)
Click(iconBar, true)
assert(db.showIconBar == true)
-- Essential Cooldowns icon placement: it always snaps, so there is no
-- on/off setting; position and gap apply live.
assert(db.snapToCDM == nil and db.snapSide == "right")
assert(db.cdmIconSize == 0 and db.snapGap == 2)
local beforeSnap = applied
local side = Find("Button", "Snap position: ")
assert(side.value == "Snap position: Right of bar  >")
side.scripts.OnClick(side, "LeftButton")
assert(db.snapSide == "left" and applied == beforeSnap + 1)
side.scripts.OnClick(side, "RightButton")
side.scripts.OnClick(side, "RightButton")
assert(db.snapSide == "bottom", "Right-click cycles snap sides backward")
local size = Find("Slider", "Essential icon size: ")
size:SetValue(40)
assert(db.cdmIconSize == 40)
size:SetValue(10)
assert(db.cdmIconSize == 0, "Sizes below 16 return to following Blizzard")
Find("Slider", "Gap from bar: "):SetValue(6)
assert(db.snapGap == 6)
panel:Synchronize()
assert(side.value == "Snap position: Below bar  >", "Snap preferences restore in the window")
db.snapSide, db.snapGap = "right", 2
panel:Synchronize()

-- Alerts page: missing-seal behavior.
assert(db.missingAlert == "both" and db.hideWhenMissing == false and db.showMissingText == true)
local alert = Find("Button", "Combat alert: ")
assert(alert.value == "Combat alert: Glow and bounce  >")
for _, expected in ipairs({"glow", "bounce", "none", "both"}) do
    alert.scripts.OnClick(alert, "LeftButton")
    assert(db.missingAlert == expected, "Combat alert cycles to " .. expected)
end
local hideMissing = Find("CheckButton", "Hide tracker when no seal is active")
Click(hideMissing, true)
assert(db.hideWhenMissing == true)
Click(hideMissing, false)
local missingText = Find("CheckButton", "Show missing-seal text")
assert(missingText.value == true)
Click(missingText, false)
assert(db.showMissingText == false and db.showSealName == false,
    "Missing text toggle is separate from the seal-name toggle")
Click(missingText, true)
local symbol = Find("Button", "Missing symbol: ")
symbol.scripts.OnClick(symbol, "LeftButton")
assert(db.missingSymbol == "none" and symbol.value == "Missing symbol: None  >")
symbol.scripts.OnClick(symbol, "LeftButton")
assert(db.missingSymbol == "bang")
local placeholder = Find("Button", "Placeholder icon: ")
placeholder.scripts.OnClick(placeholder, "LeftButton")
assert(db.missingIcon == "righteousness")
placeholder.scripts.OnClick(placeholder, "RightButton")
assert(db.missingIcon == "might" and placeholder.value == "Placeholder icon: Default  >")
local warningColor = Find("Button", "Warning color: ")
warningColor.scripts.OnClick(warningColor, "LeftButton")
assert(db.warningColor == "orange")
warningColor.scripts.OnClick(warningColor, "RightButton")
assert(db.warningColor == "red")

-- Alerts page: sounds.
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
-- The combat-only option cannot apply to the native display's missing sound.
assert(Find("CheckButton", "Missing sound only in combat").shown ~= false,
    "Estimated tracker keeps the missing sound combat-only option")
addon.NativeDisplayActive = true
panel:Synchronize()
assert(Find("CheckButton", "Missing sound only in combat").shown == false,
    "Native display hides the missing sound combat-only option")
assert(Find("CheckButton", "Refresh sound only in combat").shown ~= false,
    "Refresh sound keeps its combat-only option")
addon.NativeDisplayActive = nil
panel:Synchronize()

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
-- Every bundled sound ships with the addon, and keys and labels are unique.
local seenKeys, seenLabels, bundled = {}, {}, 0
for _, choice in ipairs(addon.SoundChoices) do
    assert(not seenKeys[choice.key] and not seenLabels[choice.label], "Duplicate sound " .. choice.key)
    seenKeys[choice.key], seenLabels[choice.label] = true, true
    assert((choice.file ~= nil) ~= (choice.kit ~= nil), "Sound uses exactly one source: " .. choice.key)
    if choice.file then
        local prefix = "Interface\\AddOns\\PallySealCooldowns\\"
        assert(choice.file:sub(1, #prefix) == prefix, "Bundled sound path points at this addon")
        local handle = io.open("PallySealCooldowns/" .. choice.file:sub(#prefix + 1):gsub("\\", "/"), "rb")
        assert(handle and handle:read(4) == "RIFF", "Bundled sound file exists: " .. choice.file)
        handle:close()
        bundled = bundled + 1
    end
end
assert(bundled == 12, "Gentle chime, ten generated sounds, and cat meow are bundled")
-- Added built-in sounds: bundled cat meow and extra game sounds.
PlaySoundFile = function(path, channel)
    filePlayed = path
    return true
end
db.soundChannel = "Master"
db.soundChoice = "meow"
addon.PlayWarning(db)
assert(filePlayed == "Interface\\AddOns\\PallySealCooldowns\\Sounds\\CatMeow.wav", "Cat meow uses bundled audio")
SOUNDKIT.READY_CHECK, SOUNDKIT.ALARM_CLOCK_WARNING_3 = 8, 9
PlaySound = function(kit) playedKit = kit end
for choice, kit in pairs({readycheck = 8, alarm = 9}) do
    db.soundChoice = choice
    addon.PlayWarning(db)
    assert(playedKit == kit, "Game sound choice plays its sound kit")
end
-- A sound the client cannot play falls back to that alert's own default.
SOUNDKIT.ALARM_CLOCK_WARNING_3 = nil
db.soundChoice, db.missingSoundChoice, playedKit, filePlayed = "alarm", "alarm", nil, nil
addon.PlayWarning(db)
assert(filePlayed:find("RefreshChime.wav", 1, true) and playedKit == nil,
    "Missing refresh sound kit falls back to the gentle chime")
filePlayed = nil
addon.PlayWarning(db, "missing")
assert(playedKit == SOUNDKIT.RAID_WARNING and filePlayed == nil,
    "Missing missing-seal sound kit falls back to raid warning")
-- SharedMedia sounds follow the built-ins, skip "None", and play by path.
LibStub = function(name, silent)
    assert(name == "LibSharedMedia-3.0" and silent)
    return {
        List = function(_, kind) return kind == "sound" and {"None", "Kitty"} or {} end,
        Fetch = function(_, kind, key, noDefault)
            assert(kind == "sound" and noDefault)
            return key == "Kitty" and "Interface\\AddOns\\Pack\\kitty.ogg" or nil
        end,
    }
end
local options = addon.SoundOptions()
assert(#options == #addon.SoundChoices + 1 and options[#options].key == "media:Kitty",
    "Installed SharedMedia sounds are listed after built-ins without None")
assert(not addon.IsValidSoundChoice("media:None") and addon.IsValidSoundChoice("media:Kitty"),
    "SharedMedia's silent None sound is never a valid alert choice")
db.soundChoice = options[#options - 1].key
panel:Synchronize()
playedKit, filePlayed = nil, nil
soundButton.scripts.OnClick()
assert(db.soundChoice == "media:Kitty", "Refresh selector cycles into SharedMedia sounds")
assert(playedKit == nil and filePlayed == nil, "Cycling buttons never play a preview")
missingButton.scripts.OnClick(nil, "RightButton")
assert(playedKit == nil and filePlayed == nil, "Cycling the missing sound never plays a preview")
assert(soundButton.value == "Refresh sound: Kitty  >")
addon.PlayWarning(db)
assert(filePlayed == "Interface\\AddOns\\Pack\\kitty.ogg", "SharedMedia sound plays its fetched file")
db.missingSoundChoice = "media:Kitty"
filePlayed = nil
missingPreview.scripts.OnClick()
assert(filePlayed == "Interface\\AddOns\\Pack\\kitty.ogg", "Missing alert can use SharedMedia sounds")
db.soundChoice, playedKit, filePlayed = "media:Removed", nil, nil
panel:Synchronize()
assert(soundButton.value == "Refresh sound: Removed (unavailable)")
addon.PlayWarning(db)
assert(filePlayed:find("RefreshChime.wav", 1, true) and playedKit == nil,
    "Removed SharedMedia refresh sound falls back to the gentle chime, not raid warning")
db.missingSoundChoice, filePlayed = "media:Removed", nil
addon.PlayWarning(db, "missing")
assert(filePlayed == nil and playedKit == SOUNDKIT.RAID_WARNING,
    "Removed SharedMedia missing-seal sound falls back to raid warning")
LibStub = nil
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

-- Only settings that apply to the chosen layout are shown, without gaps.
local function Shown(kind, label) return Find(kind, label).shown end
local function Choose(style)
    db.displayStyle = style
    panel:Synchronize()
end
local layoutHeading
for _, widget in ipairs(widgets) do
    if widget.kind == "Region" and widget.parent == pages.layout.content
        and type(widget.value) == "string" and widget.value:find(" options$") then layoutHeading = widget end
end
db.showIconBar, db.border = true, "solid"
Choose("icon")
assert(layoutHeading.value == "Large icon options")
assert(Shown("CheckButton", "Show duration bar under icon") and not Shown("Slider", "Essential icon size: "))
assert(not Shown("Slider", "Bar width: ") and Shown("Button", "Bar texture: "),
    "Icon layouts keep texture options for their thin bar")
assert(Shown("CheckButton", "Show seal name") and Shown("Button", "Placeholder icon: "))
assert(Shown("Button", "Border color: ") and Shown("Slider", "Custom border thickness: "))
Click(Find("CheckButton", "Show duration bar under icon"), false)
assert(not Shown("Button", "Bar texture: ") and not Shown("CheckButton", "Bar counts down"),
    "Hiding the icon bar hides its options immediately")
Click(Find("CheckButton", "Show duration bar under icon"), true)
Choose("essential")
assert(layoutHeading.value == "Essential Cooldowns icon options" and Shown("Slider", "Essential icon size: "))
assert(Shown("Button", "Snap position: ") and Shown("Slider", "Gap from bar: "),
    "Snap placement belongs to the Essential Cooldowns icon")
Choose("bar")
assert(Shown("Slider", "Bar width: ") and not Shown("CheckButton", "Show duration bar under icon"))
assert(Shown("Slider", "Bar width: ") and Find("Slider", "Bar width: ").point[3] == -158,
    "Bar width moves up into the space of the hidden icon options")
Choose("swing")
assert(layoutHeading.value == "Swing timer bar options")
assert(Shown("Slider", "Bar width: ") and Shown("Button", "Bar texture: ") and Shown("CheckButton", "Bar counts down"))
assert(not Shown("CheckButton", "Show seal name"), "Seal Timer label replaces the seal name")
assert(not Shown("Button", "Placeholder icon: ") and Shown("Button", "Missing symbol: "))
assert(not Shown("Button", "Border color: ") and not Shown("Slider", "Custom border thickness: "))
assert(Shown("Button", "Border: ") and Shown("Button", "Warning color: "))
assert(Find("Slider", "Label font size: "), "The name size slider names the swing label")
assert(Find("Button", "Warning color: ").point[3] == -403 + 100,
    "Warning color closes the gap left by both border options")
assert(not Shown("Button", "Classic Gold") and not Shown("Button", "Paladin Pink"))
assert(not Shown("Button", "Snap position: ") and not Shown("Slider", "Gap from bar: "),
    "Snapping is not offered for the swing bar")
assert(Shown("Button", "Minimal") and Shown("Button", "Clean Text"))
Choose("icon")
db.border = "none"
panel:Synchronize()
assert(not Shown("Button", "Border color: ") and not Shown("Slider", "Custom border thickness: "))
db.border = "default"
panel:Synchronize()
assert(Shown("Button", "Border color: ") and not Shown("Slider", "Custom border thickness: "),
    "The default border has a color but no thickness")
assert(Shown("CheckButton", "Show seal name") and Shown("Button", "Classic Gold"))
assert(not Shown("Button", "Snap position: ") and not Shown("Slider", "Gap from bar: "),
    "Only the Essential Cooldowns icon snaps")

-- Standalone window hosts every page behind tabs.
local tabs = {}
for _, widget in ipairs(widgets) do
    if widget.kind == "Button" and rawget(widget, "key") then tabs[#tabs + 1] = widget end
end
assert(#tabs == 5 and panel.hosted, "Standalone window shows page tabs")
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
assert(#subcategories == 4, "Register four native sub-pages")
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
assert(#legacy == 5 and legacyPanel.embedded and opened == legacyPanel)
for index = 2, 5 do
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
assert(#legacy == 5 and not standalone.hosted and pages ~= standalone.pages)
for index = 2, 5 do
    assert(standalone.pages[index].shown == false, "Late registration hides hosted sub-pages")
end
-- Native dropdowns replace click-cycling where the client has the template.
assert(not panel.usesDropdowns, "Clients without the dropdown template keep cycling buttons")
DoesTemplateExist = function(name) return name == "WowStyle1DropdownTemplate" end
local ddb = {locked = true, sound = true, counterMode = "always", threshold = 5, scale = 1}
ddb.barWidth, ddb.showSealName, ddb.showStatusText = 188, true, true
ddb.soundChoice, ddb.missingSoundChoice, ddb.soundChannel = "raid", "raid", "Master"
addon.NormalizeAppearance(ddb)
addon.NormalizeCooldownManager(ddb)
addon.NormalizeDisplayOptions(ddb)
local ddApplied = 0
local ddPanel = addon.CreateSettings(ddb, function() ddApplied = ddApplied + 1 end)
assert(ddPanel.usesDropdowns)
ddPanel:Synchronize()
assert(ddApplied == 0, "Refreshing dropdowns must not change stored values")
local function Menu(dropdown)
    local radios, scroll = {}, nil
    local root = {
        SetScrollMode = function(_, height) scroll = height end,
        CreateRadio = function(_, text, isSelected, choose, value)
            radios[#radios + 1] = {text = text, isSelected = isSelected, choose = choose, value = value}
        end,
    }
    dropdown.generator(dropdown, root)
    return radios, scroll
end
local function Selected(radios)
    for _, radio in ipairs(radios) do
        if radio.isSelected() then return radio end
    end
end
local function Choose(dropdown, value)
    for _, radio in ipairs(Menu(dropdown)) do
        if radio.value == value then return radio.choose() end
    end
    error("Missing choice " .. value)
end
for _, label in ipairs({"Layout: ", "Bar texture: ", "Snap position: ", "Refresh sound: ",
    "Audio channel: ", "Combat alert: ", "Missing symbol: ", "Placeholder icon: ", "Missing sound: ",
    "Font: ", "Outline: ", "Border: ", "Border color: ", "Warning color: "}) do
    local dropdown = Find("DropdownButton", label)
    assert(#Menu(dropdown) > 1 and Selected(Menu(dropdown)), "Dropdown lists choices and marks the saved one")
end
local soundDrop = Find("DropdownButton", "Refresh sound: ")
local soundRadios, scroll = Menu(soundDrop)
assert(scroll and #soundRadios == #addon.SoundChoices, "Sound list scrolls when long")
assert(Selected(soundRadios).value == "raid")
local played = {}
PlaySoundFile = function(path) played[#played + 1] = path return true end
PlaySound = function(kit) played[#played + 1] = kit end
Choose(soundDrop, "meow")
assert(ddb.soundChoice == "meow" and ddApplied == 1)
assert(#played == 1 and played[1]:find("CatMeow.wav", 1, true), "Choosing a refresh sound previews it")
assert(Selected(Menu(soundDrop)).value == "meow")
Choose(Find("DropdownButton", "Missing sound: "), "chime")
assert(ddb.missingSoundChoice == "chime" and ddb.soundChoice == "meow")
assert(#played == 2 and played[2]:find("RefreshChime.wav", 1, true), "Choosing a missing sound previews it")
Choose(Find("DropdownButton", "Font: "), "arial")
assert(ddb.font == "arial" and #played == 2, "Non-sound choices apply silently")
ddb.soundChoice = "media:Removed"
ddPanel:Synchronize()
assert(soundDrop.defaultText == "Removed (unavailable)" and not Selected(Menu(soundDrop)),
    "Unavailable saved media is named, not silently replaced")
assert(ddb.soundChoice == "media:Removed")
for _, widget in ipairs(widgets) do
    if widget.kind == "Region" and type(widget.value) == "string" and widget.value:find("^Changes apply live")
        and widget.parent == ddPanel.pages.appearance.content then
        assert(not widget.value:find("Left/right", 1, true), "Dropdown help does not mention cycling")
    end
end
DoesTemplateExist = nil
io.write("Settings interaction tests passed.\n")
