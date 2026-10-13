local addon = {}
for _, file in ipairs({"SealLogic", "Diagnostics", "Appearance", "NativePrototype", "NativeDisplay"}) do
    assert(loadfile("PallySealCooldowns/" .. file .. ".lua"))("PallySealCooldowns", addon)
end
local combat, failGroup = false, false
local configurations, groups, slots, messages = 0, {}, {}, {}
InCombatLockdown = function() return combat end
CustomAuraContainerAuraProcessingPolicy = {None = 0}
AuraContainerSortMethod = {Default = 0}
AuraContainerSortDirection = {Normal = 0}
Enum = {LuaCurveType = {Step = 0}, DurationTextBindingProperty = {RemainingDuration = 0}}
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
        if key == "CreateTexture" or key == "CreateFontString" or key == "CreateAnimationGroup"
            or key == "CreateAnimation" then return function() return Widget(key) end end
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
        if key == "SetDurationText" then return function(self, text, options) self.textOptions = options end end
        if key == "SetDurationBar" then return function(self, bar) self.boundBar = bar end end
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
failGroup = true
assert(addon.CreateNativeDisplay(root, db, Message) == nil)
assert(messages[#messages]:find("using estimated tracker", 1, true))
io.write("Native display integration tests passed.\n")
