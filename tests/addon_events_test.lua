local scripts, queries, blocked = {}, 0, false
local trackerFrame
local animationPlays, animationStops = 0, 0
local now, cooldownStart, cooldownDuration = 100, nil, nil
local counterText, trackerShown, cooldownShown, barValue
local widget = {}
setmetatable(widget, {__index = function(_, name)
    if name == "CreateAnimationGroup" or name == "CreateAnimation"
        or name == "GetStatusBarTexture" then
        return function() return widget end
    end
    if name == "SetCooldown" then
        return function(_, start, duration) cooldownStart, cooldownDuration = start, duration end
    end
    if name == "SetValue" then
        return function(_, value) barValue = value end
    end
    if name == "Play" then
        return function() animationPlays = animationPlays + 1 end
    end
    if name == "Stop" then
        return function() animationStops = animationStops + 1 end
    end
    if name == "SetScript" then
        return function(_, event, handler) scripts[event] = handler end
    end
    if name == "CreateFontString" then
        return function(_, _, _, font)
            if font == "GameFontHighlightHugeOutline" then
                return setmetatable({SetText = function(_, text) counterText = text end},
                    {__index = widget})
            end
            return widget
        end
    end
    if name == "CreateTexture" then
        return function() return widget end
    end
    return function() end
end})
CreateFrame = function(kind, name)
    if kind == "Cooldown" then
        return setmetatable({Show = function() cooldownShown = true end,
            Hide = function() cooldownShown = false end}, {__index = widget})
    end
    if name == "PallySealCooldownsFrame" then
        trackerFrame = setmetatable({Show = function() trackerShown = true end,
            Hide = function() trackerShown = false end,
            ClearAllPoints = function(self) self.point = nil end,
            SetPoint = function(self, ...) self.point = {...} end,
            EnableMouse = function(self, enabled) self.mouse = enabled end,
            StartMoving = function(self) self.moving = true end}, {__index = widget})
        return trackerFrame
    end
    return widget
end
UIParent = widget
DEFAULT_CHAT_FRAME = widget
SlashCmdList = {}
UISpecialFrames = {}
wipe = function(values) for key in pairs(values) do values[key] = nil end end
UnitClass = function() return "Paladin", "PALADIN" end
UnitAffectingCombat = function() return false end
GetTime = function() return now end
C_Spell = {GetSpellName = function(id) return "Seal " .. id end}
C_UnitAuras = {GetAuraDataBySpellName = function()
    queries = queries + 1
    if blocked then error("Auras cannot be accessed when secret while tainted") end
    return nil
end}
local earlySounds = 0
SOUNDKIT = {RAID_WARNING = 1}
PlaySound = function() earlySounds = earlySounds + 1 end
local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Diagnostics.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/NativePrototype.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Appearance.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/CooldownManager.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Minimap.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Settings.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/NativeDisplay.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/PallySealCooldowns.lua"))("PallySealCooldowns", addon)
scripts.OnEvent(widget, "ADDON_LOADED", "PallySealCooldowns")
assert(queries > 0)
assert(PallySealCooldownsDB.soundChoice == "chime")
assert(earlySounds == 0, "Default missing alert is combat-only")
assert(animationPlays == 0, "No missing-seal animation outside combat")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(animationPlays == 2, "Missing seal in combat starts glow and bounce")
local previous = queries
for index = 1, 150 do scripts.OnUpdate(widget, 0.1) end
assert(queries > previous, "Live aura data must be polled in combat")
assert(animationPlays == 2, "Frame updates must not restart animations")
assert(earlySounds == 1, "Missing alert plays once on combat entry")
blocked = true
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(queries > previous, "Combat aura events must attempt reconciliation")
local stopsAfterRestriction = animationStops
PallySealCooldownsDB.sound = false
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "target", "cast", 20154)
assert(animationStops == stopsAfterRestriction, "Other player casts must not change the alert")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 999)
assert(animationStops == stopsAfterRestriction, "Unrelated spells must not change the alert")
-- Exact reported regression: cast while combat aura reads remain blocked.
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 20154)
assert(animationStops == 2, "Seal cast must stop glow and bounce immediately")
assert(cooldownStart == 100 and cooldownDuration == 30)
SlashCmdList.PALLYSEALCOOLDOWNS("style bar")
assert(PallySealCooldownsDB.displayStyle == "bar")
assert(counterText == "30", "Changing layout must preserve the running timer")
SlashCmdList.PALLYSEALCOOLDOWNS("style invalid")
assert(PallySealCooldownsDB.displayStyle == "bar")
SlashCmdList.PALLYSEALCOOLDOWNS("style icon")
assert(PallySealCooldownsDB.displayStyle == "icon")
assert(counterText == "30", "Default mode shows the full countdown")
SlashCmdList.PALLYSEALCOOLDOWNS("counter refresh")
assert(counterText == "", "Refresh mode hides the early countdown immediately")
now = 125
scripts.OnUpdate(widget, 0.1)
assert(counterText == "5.0", "Countdown appears exactly at the warning threshold")
assert(math.abs(barValue - 25 / 30) < 1e-9, "Estimated bar fills up by default")
PallySealCooldownsDB.barCountdown = true
scripts.OnUpdate(widget, 0.1)
assert(math.abs(barValue - 5 / 30) < 1e-9, "Countdown option drains the estimated bar")
PallySealCooldownsDB.barCountdown = false
SlashCmdList.PALLYSEALCOOLDOWNS("warn 3")
scripts.OnUpdate(widget, 0.1)
assert(counterText == "", "Counter follows a changed warning threshold")
SlashCmdList.PALLYSEALCOOLDOWNS("counter always")
assert(counterText == "5.0", "Always mode restores countdown immediately")
SlashCmdList.PALLYSEALCOOLDOWNS("counter invalid")
assert(PallySealCooldownsDB.counterMode == "always", "Invalid mode preserves setting")
SlashCmdList.PALLYSEALCOOLDOWNS("counter refresh")
now = 100
scripts.OnEvent(widget, "UNIT_AURA", "player")
scripts.OnUpdate(widget, 0.1)
assert(counterText == "", "Restricted aura events preserve the combat cast timer")
assert(animationPlays == 2)
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "sound-test", 20154)
now = 127
local soundCount, warningKit, warningChannel = 0, nil, nil
SOUNDKIT = {RAID_WARNING = 1, TELL_MESSAGE = 2}
PlaySound = function(kit, channel)
    soundCount = soundCount + 1
    warningKit, warningChannel = kit, channel
end
PallySealCooldownsDB.sound = true
PallySealCooldownsDB.soundChoice, PallySealCooldownsDB.soundChannel = "whisper", "SFX"
scripts.OnUpdate(widget, 0.1)
scripts.OnUpdate(widget, 0.1)
assert(soundCount == 1 and warningKit == 2 and warningChannel == "SFX",
    "Automatic warning must play selected sound once per expiration")
PallySealCooldownsDB.sound = false
now = 131
scripts.OnUpdate(widget, 0.1)
assert(counterText == "?", "Expired restricted estimates must not claim a confirmed missing seal")
assert(soundCount == 1, "Expired restricted estimates must not play missing-seal audio")
now = 132
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast2", 20375)
assert(counterText == "", "Switching seals must start a fresh timer")
assert(cooldownStart == 132 and cooldownDuration == 30)
now = 140
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast3", 20375)
assert(cooldownStart == 140, "Recasting must restart the timer")
blocked = false
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    queries = queries + 1
    if name == "Seal 20375" then
        return {icon = 123, duration = 45, expirationTime = 177}
    end
end
now = 141
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(cooldownStart == 132 and cooldownDuration == 45, "Combat exit reconciles actual aura")
assert(PallySealCooldownsDB.sealDurations["Seal 20375"] == 45)
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
now = 150
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast4", 20375)
assert(cooldownStart == 150 and cooldownDuration == 45, "Cast timer uses learned duration")
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
now = 151
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
local stopsBeforeExit = animationStops
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(animationStops == stopsBeforeExit + 2, "Combat exit stops missing-seal animation")
blocked = true
C_UnitAuras.GetAuraDataBySpellName = function() error("restricted") end
scripts.OnEvent(widget, "UNIT_AURA", "player")
scripts.OnUpdate(widget, 0.1)
-- Hidden trackers must still respond to combat events and settings changes.
PallySealCooldownsDB.hideOutOfCombat = true
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(trackerShown == false, "Combat-only tracker must hide outside combat")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(trackerShown == true, "Hidden tracker must appear on combat entry")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(trackerShown == false)
addon.CreateSettings = function(_, apply)
    PallySealCooldownsDB.hideOutOfCombat = false
    apply()
    return {Show = function() end, Synchronize = function() end}
end
SlashCmdList.PALLYSEALCOOLDOWNS("")
assert(trackerShown == true, "Disabling combat-only visibility must show immediately")
-- Readable combat changes must replace estimates without waiting for combat exit.
SlashCmdList.PALLYSEALCOOLDOWNS("counter always")
now = 200
local liveAura = {icon = 123, duration = 45, expirationTime = 245, auraInstanceID = 42}
local liveName = "Seal 20375"
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    queries = queries + 1
    if name == liveName then return liveAura end
end
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(counterText == "45" and cooldownShown)
liveAura.expirationTime = 220
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(counterText == "20", "Combat duration changes reconcile immediately")
liveName = "Seal 20154"
liveAura = {icon = 124, duration = 30, expirationTime = 230, auraInstanceID = 43}
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {42}})
assert(counterText == "30", "Replacement wins over the old aura removal")
liveAura = nil
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(counterText == "30" and cooldownShown,
    "Empty combat lookup preserves the known seal as an estimate")
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {43}})
assert(counterText == "!" and not cooldownShown, "Cancellation clears timer and swipe in combat")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "delayed", 20154)
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(counterText == "30", "Empty snapshot immediately after cast must allow API catch-up")
now = 200.6
scripts.OnUpdate(widget, 0.5)
assert(counterText ~= "!" and cooldownShown,
    "Empty combat polling must preserve casts beyond the grace period")
liveAura = {icon = 124, duration = 30, expirationTime = 230, auraInstanceID = 44}
scripts.OnEvent(widget, "UNIT_AURA", "player")
C_UnitAuras.GetAuraDataBySpellName = function() error("restricted") end
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {99}})
assert(counterText == "30", "Unrelated removal preserves restricted estimate")
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {44}})
assert(counterText == "?" and not cooldownShown,
    "Confirmed removal invalidates old timer even when replacement queries are restricted")
-- Sound latches survive restricted reads, reset on recovery, and respect combat options.
local db = PallySealCooldownsDB
db.missingSound, db.missingCombatOnly = true, true
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
local before = soundCount
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnUpdate(widget, 0.5)
assert(soundCount == before + 1, "Combat entry missing alert plays once")
C_UnitAuras.GetAuraDataBySpellName = function() error("restricted") end
scripts.OnEvent(widget, "UNIT_AURA", "player")
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(soundCount == before + 1, "Restricted reads do not rearm missing warning")
local aura = {icon = 123, duration = 30, expirationTime = now + 30, auraInstanceID = 45}
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    if name == "Seal 20154" then return aura end
end
scripts.OnEvent(widget, "UNIT_AURA", "player")
aura = nil
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {45}})
assert(soundCount == before + 2, "Recovery rearms missing warning")
db.missingSound = false
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(soundCount == before + 2, "Missing sound toggle suppresses alerts")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
db.missingSound, db.missingCombatOnly = true, false
scripts.OnUpdate(widget, 0.5)
assert(soundCount == before + 3, "Missing sound can be enabled outside combat")
db.sound, db.refreshCombatOnly = true, true
aura = {icon = 123, duration = 30, expirationTime = now + 2}
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(soundCount == before + 3, "Refresh sound is suppressed outside combat")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnUpdate(widget, 0.1)
assert(soundCount == before + 4, "Suppressed refresh plays once on combat entry")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
db.refreshCombatOnly = false
aura.expirationTime = now + 1
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(soundCount == before + 5, "Refresh can sound outside combat")
now = now + 2
scripts.OnUpdate(widget, 0.1)
assert(soundCount == before + 6, "Confirmed expiration triggers missing sound")

-- Visibility must not change independently configured audio behavior.
db.hideOutOfCombat = true
aura = {icon = 123, duration = 30, expirationTime = now + 2}
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(not trackerShown and soundCount == before + 7,
    "Hidden tracker still plays an enabled out-of-combat refresh warning")
aura = nil
scripts.OnEvent(widget, "UNIT_AURA", "player")
scripts.OnUpdate(widget, 0.5)
assert(not trackerShown and soundCount == before + 8,
    "Hidden tracker plays missing warning once")
db.refreshCombatOnly, db.missingCombatOnly = true, true
aura = {icon = 123, duration = 30, expirationTime = now + 1}
scripts.OnEvent(widget, "UNIT_AURA", "player")
aura = nil
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(soundCount == before + 8, "Hidden tracker respects both combat-only options")

-- Unknown status must remain silent even with no previous missing-sound latch.
C_UnitAuras.GetAuraDataBySpellName = function() error("restricted") end
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnUpdate(widget, 0.5)
assert(soundCount == before + 8, "Restricted combat entry must not play missing audio")
local secret = {}
issecretvalue = function(value) return value == secret end
C_UnitAuras.GetAuraDataBySpellName = function() return secret end
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(soundCount == before + 8, "Secret aura results must not play missing audio")
issecretvalue = nil

-- Reload the addon chunk to exercise initialization against persisted preferences.
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
local function ReloadWithSettings(saved)
    PallySealCooldownsDB = saved
    assert(loadfile("PallySealCooldowns/PallySealCooldowns.lua"))("PallySealCooldowns", addon)
    scripts.OnEvent(widget, "ADDON_LOADED", "PallySealCooldowns")
    return PallySealCooldownsDB
end
for _, choice in ipairs({"raid", "whisper", "click", "chime"}) do
    local saved = ReloadWithSettings({sound = false, soundChoice = choice, soundChannel = "Dialog"})
    assert(not saved.sound and not saved.missingSound,
        "Previously disabled sounds must keep both alerts disabled")
    assert(saved.soundChoice == choice and saved.soundChannel == "Dialog",
        "Existing refresh choice and channel survive initialization")
    assert(saved.missingSoundChoice == "raid" and saved.refreshCombatOnly and saved.missingCombatOnly)
end
for _, enabled in ipairs({false, true}) do
    local saved = {
        sound = enabled, missingSound = not enabled,
        soundChoice = "whisper", missingSoundChoice = "click", soundChannel = "SFX",
        refreshCombatOnly = enabled, missingCombatOnly = not enabled,
    }
    for reload = 1, 2 do
        saved = ReloadWithSettings(saved)
        assert(saved.sound == enabled and saved.missingSound == not enabled)
        assert(saved.refreshCombatOnly == enabled and saved.missingCombatOnly == not enabled)
        assert(saved.soundChoice == "whisper" and saved.missingSoundChoice == "click"
            and saved.soundChannel == "SFX", "Independent sound preferences survive reloads")
    end
end
local repaired = ReloadWithSettings({soundChoice = "invalid", missingSoundChoice = "invalid",
    soundChannel = "invalid"})
assert(repaired.soundChoice == "chime" and repaired.missingSoundChoice == "raid"
    and repaired.soundChannel == "Master", "Invalid audio choices use supported defaults")

-- Snapping anchors to Blizzard's Essential bar, blocks dragging, and falls
-- back to the saved position with a single warning once the world is up.
local chat = {}
DEFAULT_CHAT_FRAME = {AddMessage = function(_, text) chat[#chat + 1] = text end}
EssentialCooldownViewer = nil
local iconBarDB = ReloadWithSettings({})
assert(iconBarDB.showIconBar == true, "Icon bar defaults to shown")
assert(ReloadWithSettings({showIconBar = false}).showIconBar == false, "Hidden icon bar persists")
local snapDB = ReloadWithSettings({snapToCDM = true, snapSide = "top", snapGap = 4,
    locked = false, x = 10, y = 20})
assert(trackerFrame.point[1] == "CENTER" and trackerFrame.point[4] == 10,
    "Bar not loaded yet keeps the saved position")
assert(#chat == 0, "No warning before the world has loaded")
scripts.OnEvent(widget, "PLAYER_ENTERING_WORLD")
scripts.OnEvent(widget, "PLAYER_ENTERING_WORLD")
assert(#chat == 1 and chat[1]:find("not found", 1, true), "Fallback warns once")
local essential = {}
EssentialCooldownViewer = essential
scripts.OnEvent(widget, "ADDON_LOADED", "Blizzard_CooldownViewer")
assert(trackerFrame.point[1] == "BOTTOM" and trackerFrame.point[2] == essential
    and trackerFrame.point[3] == "TOP" and trackerFrame.point[5] == 4,
    "Blizzard's bar loading late still snaps the tracker")
assert(trackerFrame.mouse == false, "Snapped tracker ignores the mouse")
trackerFrame.moving = false
scripts.OnDragStart(trackerFrame)
assert(not trackerFrame.moving, "Snapped tracker cannot be dragged")
snapDB.snapToCDM = false
scripts.OnEvent(widget, "EDIT_MODE_LAYOUTS_UPDATED")
assert(trackerFrame.point[1] == "CENTER" and trackerFrame.mouse == true,
    "Turning snapping off restores the free, draggable position")
scripts.OnDragStart(trackerFrame)
assert(trackerFrame.moving)
EssentialCooldownViewer = nil
DEFAULT_CHAT_FRAME = widget

-- Missing-seal options on the estimated (non-native) display.
local missingDB = ReloadWithSettings({missingSymbol = "none", missingAlert = "glow"})
scripts.OnUpdate(widget, 0.1)
assert(counterText == "", "Missing symbol None removes the exclamation mark")
local playsBefore = animationPlays
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(animationPlays == playsBefore + 1, "Glow only starts one animation")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
missingDB.missingAlert = "none"
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
assert(animationPlays == playsBefore + 1, "Combat alert None starts no animation")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
missingDB.hideWhenMissing = true
scripts.OnUpdate(widget, 0.1)
assert(trackerShown == false, "Hide when missing hides the tracker without a seal")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "hide-missing", 20154)
assert(trackerShown == true, "Casting a seal shows the hidden tracker")
missingDB.hideWhenMissing = false
missingDB.missingSymbol, missingDB.missingAlert = "bang", "both"
ReloadWithSettings(missingDB)

GetBuildInfo = function() return "test-client", "12345", "date", 16001 end
SlashCmdList.PALLYSEALCOOLDOWNS("debug on")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
local log = PallySealCooldownsDB.debugLog
assert(table.concat(log, "\n"):find("combat enter", 1, true))
assert(table.concat(log, "\n"):find("=empty", 1, true))
local count = #log
for index = 1, 100 do scripts.OnUpdate(widget, 0.5) end
assert(#log == count, "Stable polling does not flood the diagnostic buffer")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "debug-cast", 20154)
assert(table.concat(log, "\n"):find("recognized=true", 1, true))
SlashCmdList.PALLYSEALCOOLDOWNS("debug off")

-- Captured Forever regression: a successful cast is invisible throughout
-- combat, then returns with the same expiration immediately on combat exit.
SlashCmdList.PALLYSEALCOOLDOWNS("counter always")
now = 133199.8
local restored = {icon = 123, duration = 30, expirationTime = 133229.8, auraInstanceID = 99}
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "regression", 20375)
now = 133200.9
local soundsBefore = soundCount
scripts.OnUpdate(widget, 0.5)
assert(counterText ~= "!" and counterText ~= "?" and cooldownShown,
    "Captured combat lookup must keep the cast countdown")
assert(soundCount == soundsBefore, "Empty lookup must not play a false missing alert")
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    if name == "Seal 20375" then return restored end
end
now = 133201.5
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(cooldownStart == 133199.8 and cooldownDuration == 30,
    "Combat exit reconciles the captured expiration")
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
scripts.OnEvent(widget, "UNIT_AURA", "player")
assert(counterText ~= "!" and cooldownShown, "Combat entry retains a precombat seal")
now = 133230
scripts.OnUpdate(widget, 0.5)
scripts.OnUpdate(widget, 0.5)
assert(counterText == "?" and not cooldownShown,
    "Expired combat estimate stays unavailable instead of falsely missing")
assert(soundCount == soundsBefore, "Unknown expiration must not play missing audio")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "switch", 20154)
now = 133231
scripts.OnUpdate(widget, 0.5)
assert(counterText ~= "!" and cooldownShown, "Switching seals survives empty combat queries")
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(counterText == "!" and not cooldownShown,
    "Readable empty lookup outside combat clears the estimate")
io.write("Addon event regression tests passed.\n")
-- Delta additions attach an instance ID to an invisible combat cast, allowing
-- cancellation/dispel removal events to clear it without a name lookup.
now = 300
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "delta-cast", 20154)
local hiddenTiming = {}
issecretvalue = function(value) return value == hiddenTiming end
scripts.OnEvent(widget, "UNIT_AURA", "player", {addedAuras = {
    {name = "Seal 20154", auraInstanceID = 200, duration = hiddenTiming, expirationTime = hiddenTiming},
}})
now = 301
scripts.OnUpdate(widget, 0.5)
assert(counterText ~= "!" and cooldownShown, "Addition retains the cast estimate with hidden timing")
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {999}})
assert(counterText ~= "!", "Unrelated delta removals do not clear the seal")
local beforeRemoval = soundCount
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {200}})
scripts.OnUpdate(widget, 0.5)
assert(counterText == "!" and not cooldownShown and soundCount == beforeRemoval + 1,
    "Matched delta removal clears timer and warns once despite empty combat lookups")
issecretvalue = nil

-- Combat-log confirmation also handles a cast with no known instance ID.
local destination, removedName, subevent = "player-guid", "Seal 20154", "SPELL_AURA_REMOVED"
UnitGUID = function() return "player-guid" end
CombatLogGetCurrentEventInfo = function()
    return now, subevent, false, "source-guid", "unused", 0, 0,
        destination, "unused", 0, 0, 20154, removedName, 2, "BUFF"
end
ReloadWithSettings({sound = false, missingSound = true})
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "log-cast", 20154)
destination = "other-guid"
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
assert(counterText ~= "!", "Other characters' removals are ignored")
destination, removedName = "player-guid", "Other buff"
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
assert(counterText ~= "!", "Other buffs are ignored")
removedName, subevent = "Seal 20154", "SPELL_AURA_APPLIED"
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
assert(counterText ~= "!", "Application must not be treated as removal")
subevent = "SPELL_AURA_REMOVED"
beforeRemoval = soundCount
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
assert(counterText == "!" and not cooldownShown and soundCount == beforeRemoval + 1,
    "Confirmed combat-log removal clears a cast-only estimate and warns once")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "restricted-log", 20154)
CombatLogGetCurrentEventInfo = function() error("restricted") end
scripts.OnEvent(widget, "COMBAT_LOG_EVENT_UNFILTERED")
assert(counterText ~= "!", "Unavailable combat log must not claim removal")
local originalSpellName = C_Spell.GetSpellName
C_Spell.GetSpellName = function(id)
    if id == 20424 then return "Seal 20154" end
    return originalSpellName(id)
end
local startBefore = cooldownStart
now = now + 1
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "damage-effect", 20424)
assert(cooldownStart == startBefore, "Command damage effect must not restart a buff timer")
local spellProbeCalls = 0
C_Spell.GetSpellName = function(id)
    if id == 20305 then return "Seal 21082" end
    return originalSpellName(id)
end
C_UnitAuras.GetPlayerAuraBySpellID = function(id)
    if id == 20305 then spellProbeCalls = spellProbeCalls + 1 end
end
SlashCmdList.PALLYSEALCOOLDOWNS("debug on")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "rank-probe", 20305)
scripts.OnUpdate(widget, 0.5)
assert(spellProbeCalls > 0, "Compatibility probes include the exact seal rank cast")
assert(counterText ~= "!", "Empty probe results do not clear the combat estimate")
-- Native presentation must not be overwritten by legacy polling/cast timers.
local appliedNative, combatUpdates = 0, 0
addon.CreateNativeDisplay = function()
    return {
        Apply = function() appliedNative = appliedNative + 1 end,
        UpdateCombat = function() combatUpdates = combatUpdates + 1 end,
    }
end
ReloadWithSettings({sound = false, missingSound = false})
local legacyText = counterText
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "native-cast", 20154)
scripts.OnUpdate(widget, 0.5)
assert(counterText == legacyText and not cooldownShown,
    "Legacy timer renders must stay hidden once native display owns the tracker")
assert(combatUpdates > 0)
local lockdown = true
InCombatLockdown = function() return lockdown end
SlashCmdList.PALLYSEALCOOLDOWNS("style bar")
assert(appliedNative == 0, "Native layout changes are deferred during lockdown")
lockdown = false
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
assert(appliedNative > 0, "Pending native layout applies after combat")

-- Native refresh audio must survive the same empty/restricted combat lookups
-- as the cast timer. Reproduce repeated fights with Crusader and Righteousness.
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
local nativeDB = ReloadWithSettings({sound = true, missingSound = false})
local nativeSounds = soundCount
for fight = 1, 14 do
    now = 1000 + fight * 40
    scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
    local spell = fight % 2 == 0 and 21082 or 20154
    scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "native-refresh", spell)
    now = now + 24
    scripts.OnUpdate(widget, 0.5)
    assert(soundCount == nativeSounds + fight - 1, "No warning before threshold")
    now = now + 1
    scripts.OnUpdate(widget, 0.5)
    scripts.OnUpdate(widget, 0.5)
    assert(soundCount == nativeSounds + fight, "Each combat cast warns once at threshold")
    now = now + 6
    scripts.OnUpdate(widget, 0.5)
    assert(soundCount == nativeSounds + fight, "Expired estimate adds no warning")
    scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
end

nativeSounds = soundCount
now = 2000
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "first", 20154)
now = 2020
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "switch", 21082)
now = 2025
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds, "Switching seals cancels the old warning deadline")
nativeDB.sound = false
now = 2045
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds, "Disabled refresh sound stays silent")
nativeDB.sound = true
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 1, "New seal warns at its own deadline")

-- Readable removal cancels a pending native reminder.
now = 2100
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "removed", 20154)
scripts.OnEvent(widget, "UNIT_AURA", "player", {addedAuras = {
    {name = "Seal 20154", duration = 30, expirationTime = 2130, auraInstanceID = 301},
}})
scripts.OnEvent(widget, "UNIT_AURA", "player", {removedAuraInstanceIDs = {301}})
now = 2125
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 1, "Confirmed removal cancels native refresh audio")

-- Hidden timing without a known cast must remain silent. A successful cast
-- supplies readable timing even when subsequent queries return secret values.
local secretTiming = {}
issecretvalue = function(value) return value == secretTiming end
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    if name == "Seal 20154" then
        return {duration = secretTiming, expirationTime = secretTiming}
    end
end
scripts.OnEvent(widget, "UNIT_AURA", "player")
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 1, "Unknown secret timing cannot trigger native audio")
now = 2200
scripts.OnEvent(widget, "UNIT_SPELLCAST_SUCCEEDED", "player", "secret-timing", 20154)
now = 2225
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 2, "Cast reminder survives secret aura timing")
issecretvalue = nil

-- A precombat observed seal retains its deadline through restricted combat.
scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
now = 2300
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    if name == "Seal 20154" then return {duration = 30, expirationTime = 2330} end
end
scripts.OnEvent(widget, "UNIT_AURA", "player")
C_UnitAuras.GetAuraDataBySpellName = function() return nil end
scripts.OnEvent(widget, "PLAYER_REGEN_DISABLED")
now = 2325
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 3, "Precombat seal warns during empty combat queries")

scripts.OnEvent(widget, "PLAYER_REGEN_ENABLED")
now = 2400
C_UnitAuras.GetAuraDataBySpellName = function(_, name)
    if name == "Seal 21082" then return {duration = 30, expirationTime = 2430} end
end
scripts.OnEvent(widget, "UNIT_AURA", "player")
now = 2425
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 3, "Combat-only preference blocks out-of-combat audio")
nativeDB.refreshCombatOnly = false
nativeDB.hideOutOfCombat = true
scripts.OnUpdate(widget, 0.5)
scripts.OnUpdate(widget, 0.5)
assert(soundCount == nativeSounds + 4, "Out-of-combat warning plays once with tracker hidden")
io.write("Native refresh sound regression tests passed.\n")
