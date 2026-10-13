local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Diagnostics.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/NativePrototype.lua"))("PallySealCooldowns", addon)
local combat, failCreate = false, false
local creations, enableCalls = 0, 0
local panel, container, slot, binding
CustomAuraContainerAuraProcessingPolicy = {None = 0}
AuraContainerSortMethod = {Default = 0}
AuraContainerSortDirection = {Normal = 0}
InCombatLockdown = function() return combat end
UIParent = {}
C_UnitAuras = setmetatable({}, {__index = function()
    error("Native prototype must not query restricted aura state")
end})

local function Widget()
    return setmetatable({}, {__index = function(_, key)
        if key == "GetFrameLevel" then return function() return 1 end end
        if key == "IsShown" or key == "GetWidth" or key == "GetText" then
            return function() error("Do not observe native aura visibility or geometry") end
        end
        if key == "CreateTexture" or key == "CreateFontString" then return Widget end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        return function() end
    end})
end

CreateFrame = function(kind, name)
    creations = creations + 1
    if kind == "AuraContainer" then
        if failCreate then error("Native template unavailable") end
        container = Widget()
        container.SetEnabled = function(self, value)
            assert(not combat, "Do not configure the container in combat")
            enableCalls = enableCalls + 1
            self.enabled = value
        end
        container.SetUnit = function(self, unit) self.unit = unit end
        container.AddAuraSlot = function(_, key, filter, options)
            assert(key == "Seal" and filter == "HELPFUL")
            slot = options
            binding = Widget()
            binding.SetIcon = function(self, texture) self.iconBinding = texture end
            binding.SetDurationCooldown = function(self, cooldown) self.cooldownBinding = cooldown end
            binding.SetDurationText = function(self, text) self.textBinding = text end
            binding.SetSpellName = function(self, text) self.nameBinding = text end
            options.initializeFrame(binding)
        end
        return container
    end
    local widget = Widget()
    if name == "PallySealCooldownsNativePrototype" then panel = widget end
    return widget
end
local messages = {}
local function Message(value) messages[#messages + 1] = value end
local db = {x = 0, y = -160, scale = 1}
combat = true
addon.NativePrototypeCommand("on", db, Message)
assert(creations == 0, "Combat guard must precede all frame creation")
combat = false
addon.NativePrototypeCommand("on", db, Message)
assert(container.enabled and panel.shown and container.unit == "player")
assert(slot.candidateFilters.includeSpellIDs[20375] and slot.candidateFilters.includeSpellIDs[20305],
    "Native filter includes Command and low-level Crusader ranks")
assert(not slot.candidateFilters.includeSpellIDs[20424], "Damage effects are not buff candidates")
assert(binding.iconBinding and binding.cooldownBinding and binding.textBinding and binding.nameBinding,
    "All aura display elements must bind to Blizzard's native button")
local built = creations
addon.NativePrototypeCommand("on", db, Message)
assert(creations == built, "Re-enabling reuses the native display")
local calls = enableCalls
combat = true
addon.NativePrototypeCommand("off", db, Message)
assert(enableCalls == calls and container.enabled, "Combat configuration is rejected")
combat = false
addon.NativePrototypeCommand("off", db, Message)
assert(not container.enabled and not panel.shown)
addon.NativePrototypeCommand("invalid", db, Message)
assert(creations == built)

-- Initialization errors must hide partial UI, preserve the main tracker, and
-- avoid retrying every update or creating an unbounded number of frames.
assert(loadfile("PallySealCooldowns/NativePrototype.lua"))("PallySealCooldowns", addon)
failCreate = true
addon.NativePrototypeCommand("on", db, Message)
assert(not panel.shown and messages[#messages]:find("unavailable", 1, true))
built = creations
addon.NativePrototypeCommand("on", db, Message)
assert(creations == built, "Failed initialization remains disabled until reload")
io.write("Native prototype tests passed.\n")
