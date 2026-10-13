local widgets = {}
local function Widget(kind, parent)
    local widget = {kind = kind, scripts = {}, parent = parent}
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
local checks, sliders, buttons = {}, {}, {}
for _, widget in ipairs(widgets) do
    if widget.kind == "CheckButton" then checks[#checks + 1] = widget end
    if widget.kind == "Slider" then sliders[#sliders + 1] = widget end
    if widget.kind == "Button" then buttons[#buttons + 1] = widget end
    assert(widget.kind ~= "EditBox", "Custom seal input must be removed")
end
assert(checks[1].value == true and checks[3].value == false)
checks[1].value = false
checks[1].scripts.OnClick(checks[1])
assert(db.locked == false)
checks[3].value = true
checks[3].scripts.OnClick(checks[3])
assert(db.counterMode == "refresh")
checks[4].value = true
checks[4].scripts.OnClick(checks[4])
assert(db.displayStyle == "bar", "Bar style must apply immediately")
panel:Synchronize()
assert(checks[4].value == true, "Bar preference must be restored in the window")
checks[4].value = false
checks[4].scripts.OnClick(checks[4])
assert(db.displayStyle == "icon", "Unchecking bar style must restore icon layout")
checks[5].value = true
checks[5].scripts.OnClick(checks[5])
assert(db.hideOutOfCombat == true)
panel:Synchronize()
assert(checks[5].value == true, "Combat visibility preference must be restored")
checks[5].value = false
checks[5].scripts.OnClick(checks[5])
assert(db.hideOutOfCombat == false)
sliders[1]:SetValue(8)
sliders[2]:SetValue(1.25)
assert(db.threshold == 8 and db.scale == 1.25)
checks[6].value = false
checks[6].scripts.OnClick(checks[6])
checks[7].value = false
checks[7].scripts.OnClick(checks[7])
assert(db.showSealName == false and db.showStatusText == false)
sliders[3]:SetValue(250)
assert(db.barWidth == 250)
buttons[2].scripts.OnClick()
buttons[3].scripts.OnClick()
assert(db.soundChoice == "whisper" and db.soundChannel == "SFX")
buttons[4].scripts.OnClick()
assert(playedKit == 2 and playedChannel == "SFX", "Preview must use selected sound and channel")
db.sound = false
buttons[4].scripts.OnClick()
assert(playedKit == 2, "Explicit preview works when automatic sounds are disabled")
buttons[5].scripts.OnClick()
assert(db.x == 0 and db.y == -160 and db.scale == 1)
assert(#buttons == 18 and #checks == 11 and #sliders == 6,
    "General and appearance controls must exist together in one panel")
db.missingSoundChoice = "raid"
panel:Synchronize()
buttons[6].scripts.OnClick()
assert(db.missingSoundChoice == "whisper" and db.soundChoice == "whisper")
db.soundChoice = "click"
buttons[7].scripts.OnClick()
assert(playedKit == 2, "Missing preview uses its independent choice")
for index, key in ipairs({"refreshCombatOnly", "missingSound", "missingCombatOnly"}) do
    checks[index + 7].value = true
    checks[index + 7].scripts.OnClick(checks[index + 7])
    assert(db[key] == true)
end
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
    buttons[4].scripts.OnClick()
    buttons[7].scripts.OnClick()
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
        buttons[4].scripts.OnClick()
        assert(kitCalls == previousCalls + 1, "Chime fallback plays exactly once")
    end
end
local appearanceButtons = {buttons[1], buttons[8], buttons[9], buttons[10], buttons[11],
    buttons[12], buttons[13], buttons[14], buttons[15], buttons[16], buttons[17], buttons[18]}
local appearanceSliders = {sliders[4], sliders[5], sliders[6]}
local appearanceChecks = {checks[11]}
appearanceButtons[2].scripts.OnClick()
assert(db.font == "arial", "Font choice applies immediately")
appearanceButtons[2].scripts.OnClick(nil, "RightButton")
assert(db.font == "default", "Right click cycles backward")
appearanceSliders[1]:SetValue(22)
appearanceSliders[2]:SetValue(14)
assert(db.timerSize == 22 and db.nameSize == 14)
appearanceChecks[1].value = false
appearanceChecks[1].scripts.OnClick(appearanceChecks[1])
assert(not db.fontShadow)
appearanceButtons[8].scripts.OnClick()
assert(db.border == "solid" and db.borderSize == 1, "Minimal preset applies")
appearanceButtons[9].scripts.OnClick()
assert(db.outline == "THICKOUTLINE" and db.borderSize == 3)
appearanceButtons[10].scripts.OnClick()
assert(db.border == "tooltip" and db.borderColor == "gold")
appearanceButtons[11].scripts.OnClick()
assert(db.font == "arial" and db.borderColor == "pink")
appearanceButtons[12].scripts.OnClick()
assert(db.border == "none" and db.timerSize == 16)
appearanceButtons[7].scripts.OnClick()
assert(db.font == "default" and db.timerSize == 0 and db.border == "default")
assert(db.threshold == 8 and db.counterMode == "refresh", "Presets preserve gameplay settings")
local scroll
for _, widget in ipairs(widgets) do
    if widget.kind == "ScrollFrame" then scroll = widget end
end
assert(scroll and scroll.child, "One scrollable view must contain both sections")
scroll.width = 760
scroll.scripts.OnSizeChanged()
assert(scroll.child.height == 810, "Wide settings use two columns")
scroll.width = 580
scroll.scripts.OnSizeChanged()
assert(scroll.child.height == 1440, "Narrow settings stack sections for scrolling")
for _, widget in ipairs(widgets) do
    if widget.kind == "Region" and type(widget.value) == "string"
        and widget.value:find("Installed SharedMedia", 1, true) then
        assert(widget.parent.parent == scroll.child, "Appearance help must scroll with controls")
    end
end

local registrations, opened, registeredPanel = 0, nil, nil
local combat = true
InCombatLockdown = function() return combat end
Settings = {
    RegisterCanvasLayoutCategory = function(value, name)
        assert(name == "Pally Seal Cooldowns")
        registeredPanel = value
        return {GetID = function() return 123 end}
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
addon.OpenSettings(db, apply)
assert(opened == 123, "Slash/minimap route to the native category ID")

-- Older clients use the same unified panel through the legacy category API.
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
Settings = nil
local legacyPanel
InterfaceOptions_AddCategory = function(value) legacyPanel = value end
InterfaceOptionsFrame_OpenToCategory = function(value) opened = value end
addon.RegisterSettings(db, apply)
addon.OpenSettings(db, apply)
assert(legacyPanel and legacyPanel.embedded and opened == legacyPanel)

-- Without either API, provide a standalone view and later reuse it for registration.
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
InterfaceOptions_AddCategory, InterfaceOptionsFrame_OpenToCategory = nil, nil
local before = #widgets
addon.OpenSettings(db, apply)
local standalone = widgets[before + 1]
assert(standalone and not standalone.embedded)
InterfaceOptions_AddCategory = function(value) legacyPanel = value end
addon.RegisterSettings(db, apply)
assert(legacyPanel == standalone and standalone.embedded, "Late registration reuses the existing view")
io.write("Settings interaction tests passed.\n")
