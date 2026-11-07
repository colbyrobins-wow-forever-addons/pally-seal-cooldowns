local addon = {}
for _, file in ipairs({"SealLogic", "Diagnostics", "Appearance", "CooldownManager", "NativePrototype", "NativeDisplay"}) do
    assert(loadfile("PallySealCooldowns/" .. file .. ".lua"))("PallySealCooldowns", addon)
end
local combat, failGroup = false, false
local configurations, groups, slots, messages = 0, {}, {}, {}
InCombatLockdown = function() return combat end
CustomAuraContainerAuraProcessingPolicy = {None = 0}
AuraContainerSortMethod = {Default = 0}
AuraContainerSortDirection = {Normal = 0}
Enum = {LuaCurveType = {Step = 0}, DurationTextBindingProperty = {RemainingDuration = 0},
    StatusBarTimerDirection = {ElapsedTime = 0, RemainingTime = 1},
    NumericRuleFormatRounding = {Up = 2}}
local rejectFormatter = false
local formatter = {SetBreakpoints = function(self, rules) self.rules = rules end}
C_StringUtil = {CreateNumericRuleFormatter = function() return formatter end}
CreateColor = function(...) return {...} end
C_UnitAuras = setmetatable({}, {__index = function() error("No aura state queries allowed") end})
local function Widget(kind)
    return setmetatable({kind = kind}, {__index = function(_, key)
        if key == "GetFont" then return function() return "default.ttf", 12, "" end end
        if key == "SetFont" then return function() return true end end
        if key == "GetFrameLevel" then return function() return 1 end end
        if key == "GetWidth" or key == "GetHeight" or key == "GetSize"
            or key == "GetEffectiveScale" or key == "GetText" or key == "IsShown" then
            return function() error("No native state/geometry inspection allowed") end
        end
        if key == "SetBackdrop" or key == "SetBackdropBorderColor" then
            return function() error("Backdrop arithmetic cannot consume secret native geometry") end
        end
        if key == "AddMaskTexture" then return function(self) self.masks = (rawget(self, "masks") or 0) + 1 end end
        if key == "RemoveMaskTexture" then return function(self) self.masks = rawget(self, "masks") - 1 end end
        if key == "CreateTexture" or key == "CreateFontString" or key == "CreateMaskTexture" or key == "CreateAnimationGroup"
            or key == "CreateAnimation" then return function() return Widget(key) end end
        if key == "SetText" then return function(self, text) self.text = text end end
        if key == "SetTexture" then return function(self, texture) self.texture = texture end end
        if key == "SetTextColor" then return function(self, ...) self.color = {...} end end
        if key == "AddPoint" then return function(self, ...)
            self.points = rawget(self, "points") or {}
            self.points[#self.points + 1] = {...}
        end end
        if key == "SetAlpha" then return function(self, alpha) self.alpha = alpha end end
        if key == "SetSize" then return function(self, w, h) self.width, self.height = w, h end end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        if key == "SetShown" then return function(self, shown) self.shown = shown end end
        if key == "SetEnabled" then return function(self, enabled)
            assert(not combat)
            configurations = configurations + 1
            self.enabled = enabled
        end end
        if key == "SetPoint" then return function(self, ...) self.point = {...} end end
        if key == "SetClipsChildren" then return function(self, value) self.clips = value end end
        if key == "SetDurationText" then return function(self, text, options)
            if rejectFormatter and options and options.textFormatter then error("formatter rejected") end
            self.textOptions = options
        end end
        if key == "SetDurationBar" then return function(self, bar, options)
            self.boundBar, self.barOptions = bar, options
        end end
        if key == "AddAuraSlot" then return function(_, name, filter, options)
            assert(filter == "HELPFUL" and options.candidateFilters.includeSpellIDs[20375])
            local button = Widget("NativeButton")
            slots[name] = button
            options.initializeFrame(button)
        end end
        if key == "AddAuraGroup" then return function(_, name, filter, options)
            if failGroup then error("Native presence unavailable") end
            assert(filter == "HELPFUL" and options.maxFrameCount == 1)
            groups[name] = options
            options.initializeFrame(Widget("NativeGroupButton"))
        end end
        if key == "SetAuraGroupLayout" then return function(_, name, layout) groups[name].layout = layout end end
        if key == "Play" then return function(self) self.plays = (rawget(self, "plays") or 0) + 1 end end
        return function() end
    end})
end
C_CurveUtil = {CreateColorCurve = function() return Widget("Curve") end}
CreateFrame = function(kind, _, _, template)
    assert(template ~= "BackdropTemplate", "Native descendants must not install backdrop size callbacks")
    return Widget(kind)
end
C_Texture = {GetAtlasInfo = function() return {} end}
local root = Widget("Root")
local db = {displayStyle = "icon", barWidth = 188, counterMode = "refresh", threshold = 5,
    showSealName = true, showStatusText = true}
addon.NormalizeAppearance(db)
local function Message(text) messages[#messages + 1] = text end
local display = addon.CreateNativeDisplay(root, db, Message)
assert(display and #messages == 0, messages[1])
assert(display.clip.clips and display.container.enabled and display.presence.enabled)
assert(display.clip.point[2] == root, "Missing clip must use fixed root geometry")
assert(slots.Seal.boundBar and slots.Seal.textOptions.textColor)
-- The countdown shows bare numbers: no unit suffix such as "12s".
assert(slots.Seal.textOptions.textFormatter == formatter, "Countdown binds the plain-number formatter")
local rules = formatter.rules
assert(rules[1].threshold == 0 and rules[1].format == "%d" and rules[1].rounding == 2)
assert(rules[2].threshold == 60 and rules[2].format == "%d:%02d")
for _, rule in ipairs(rules) do
    assert(not rule.format:find("s", 1, true), "No seconds unit in any countdown format")
end
assert(slots.Warning.textOptions.textFormatter == nil, "REFRESH SEAL text keeps its literal format")
rejectFormatter = true
assert(display:Apply(db))
assert(slots.Seal.textOptions and slots.Seal.textOptions.textFormatter == nil
    and slots.Seal.textOptions.textColor, "A rejected formatter falls back to the native default")
rejectFormatter = false
assert(display:Apply(db) and slots.Seal.textOptions.textFormatter == formatter)
assert(slots.Seal.barOptions.direction == nil, "Native bar keeps its default fill unless countdown is chosen")
db.barCountdown = true
assert(display:Apply(db))
assert(slots.Seal.barOptions.direction == Enum.StatusBarTimerDirection.RemainingTime,
    "Countdown option binds the native bar to remaining time")
db.barCountdown = false
assert(display:Apply(db) and slots.Seal.barOptions.direction == nil)
assert(slots.Warning.textOptions.textFormat.formatString == "REFRESH SEAL")
local iconWidth = groups.Presence.layout.elementWidth
display:UpdateCombat(true)
display:UpdateCombat(true)
assert(display.pulse.plays == 1, "Polling must not restart native missing animations")
display:UpdateCombat(false)
db.displayStyle, db.barWidth = "bar", 250
assert(display:Apply(db))
assert(display.present.frame.width == 282 and display.missing.frame.width == 282)
assert(groups.Presence.layout.elementWidth > iconWidth, "Missing gate follows the chosen layout width")
local before = configurations
combat = true
db.displayStyle = "icon"
assert(not display:Apply(db) and configurations == before, "Native styling defers in combat")
combat = false
assert(display:Apply(db) and display.present.frame.width == 56)
-- Reproduce the reported gold-preset failure on reconfiguration after binding.
db.border, db.borderSize, db.borderColor = "tooltip", 12, "gold"
assert(display:Apply(db), "Gold border must not invoke BackdropTemplate or read secret geometry")
assert(display.present.edges[1].width == 12)
db.displayStyle = "bar"
assert(display:Apply(db), "Gold border must also work on the bar layout")
db.border = "none"
assert(display:Apply(db) and not display.present.edges[1].shown)
db.border = "solid"
assert(display:Apply(db) and display.present.edges[1].shown)
-- Essential-matching style: padding-free frame at the matched size, masked icon.
db.border, db.scale = "default", 1
db.displayStyle, db.cdmIconSize = "essential", 40
assert(display:Apply(db))
assert(display.present.frame.width == 40 and display.present.icon.width == 40)
assert(display.missing.frame.width == 40 and display.present.bar.width == 40)
assert(groups.Presence.layout.elementHeight == 40, "Missing gate follows the matched size")
assert(display.present.icon.masks == 1 and display.missing.icon.masks == 1)
assert(display:Apply(db) and display.present.icon.masks == 1, "Re-applying does not stack masks")
db.cdmIconSize = 0
assert(display:Apply(db) and display.present.frame.width == 50, "Auto size defaults to Blizzard's 50 px")
db.displayStyle = "bar"
assert(display:Apply(db) and display.present.icon.masks == 0, "Bar style is unaffected by the matched style")
db.displayStyle = "icon"
assert(display:Apply(db) and display.present.frame.width == 56 and display.present.icon.width == 52)
-- The thin icon-layout bar can be hidden; the bar layout always shows its bar.
assert(display.present.bar.alpha == 1, "Icon bar shows by default")
db.showIconBar = false
assert(display:Apply(db) and display.present.bar.alpha == 0 and display.missing.bar.alpha == 0)
assert(slots.Seal.boundBar == display.present.bar, "Hidden bar stays bound to the native timer")
db.displayStyle = "bar"
assert(display:Apply(db) and display.present.bar.alpha == 1, "Bar layout ignores the icon-bar option")
db.displayStyle, db.showIconBar = "icon", true
assert(display:Apply(db) and display.present.bar.alpha == 1)
-- Missing-seal options: alert parts, hiding, text, symbol, icon, and color.
assert(display.missing.frame.alpha == 1, "Missing display shows by default")
display:UpdateCombat(true)
assert(display.glow.shown and display.pulse.plays and display.bounce.plays)
local pulses, bounces = display.pulse.plays, display.bounce.plays
display:UpdateCombat(false)
db.missingAlert = "glow"
assert(display:Apply(db))
display:UpdateCombat(true)
assert(display.pulse.plays == pulses + 1 and display.bounce.plays == bounces, "Glow only skips bounce")
display:UpdateCombat(false)
db.missingAlert = "bounce"
assert(display:Apply(db))
display:UpdateCombat(true)
assert(display.pulse.plays == pulses + 1 and display.bounce.plays == bounces + 1, "Bounce only skips glow")
assert(display.glow.shown == false)
display:UpdateCombat(false)
db.missingAlert = "none"
assert(display:Apply(db))
display:UpdateCombat(true)
assert(display.pulse.plays == pulses + 1 and display.bounce.plays == bounces + 1, "None plays nothing")
display:UpdateCombat(false)
db.missingAlert = "both"
db.hideWhenMissing = true
assert(display:Apply(db) and display.missing.frame.alpha == 0, "Hide when missing clears the missing clip")
assert(rawget(display.present.frame, "alpha") == nil, "Active seal display is unaffected")
db.hideWhenMissing = false
assert(display:Apply(db) and display.missing.frame.alpha == 1)
db.showMissingText = false
assert(display:Apply(db))
assert(display.missing.name.shown == false and display.missing.status.shown == false)
assert(display.present.name.shown == true, "Active seal name keeps its own toggle")
db.showMissingText = true
db.missingSymbol, db.missingIcon, db.warningColor = "none", "wisdom", "yellow"
assert(display:Apply(db))
assert(display.missing.timer.text == "" and display.missing.icon.texture:find("RighteousnessAura", 1, true))
assert(display.missing.timer.color[2] == 0.9, "Missing symbol uses the warning color")
assert(slots.Seal.textOptions.textColor.curve.points[1][2][2] == 0.9,
    "Countdown warning uses the warning color")
db.missingSymbol, db.missingIcon, db.warningColor = "bang", "might", "red"
assert(display:Apply(db) and display.missing.timer.text == "!")
failGroup = true
assert(addon.CreateNativeDisplay(root, db, Message) == nil)
assert(messages[#messages]:find("using estimated tracker", 1, true))
io.write("Native display integration tests passed.\n")
