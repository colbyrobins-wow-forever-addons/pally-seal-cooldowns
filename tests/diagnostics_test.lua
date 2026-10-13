local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Diagnostics.lua"))("PallySealCooldowns", addon)
GetTime = function() return 123 end
GetBuildInfo = function() return "test-client", "12345", "date", 16001 end
local db, messages = {}, {}
local function Message(value) messages[#messages + 1] = value end
addon.DebugRecord(db, "scan", "disabled")
assert(db.debugLog == nil and not addon.DebugEnabled())
addon.DebugCommand(db, "on", Message, {Seal = true})
assert(addon.DebugEnabled() and #db.debugLog == 8 and #messages == 1)
assert(db.debugLog[2]:find("1 resolved: Seal", 1, true))
addon.DebugRecord(db, "scan", "empty")
for index = 1, 1000 do addon.DebugRecord(db, "scan", "empty") end
assert(#db.debugLog == 9 and #messages == 1, "Repeated scans must not spam logs or chat")
addon.DebugRecord(db, "combat", "enter")
addon.DebugRecord(db, "scan", "empty")
assert(#db.debugLog == 11, "Capture scans again after combat transition")
for index = 1, 150 do addon.DebugRecord(db, "cast", tostring(index)) end
assert(#db.debugLog == 100 and db.debugLog[1]:find("cast 51", 1, true))
addon.DebugCommand(db, "off", Message, {})
addon.DebugRecord(db, "cast", "ignored")
assert(#db.debugLog == 100 and not addon.DebugEnabled())
local before = #messages
addon.DebugCommand(db, "dump", Message, {})
assert(#messages == before + 101, "Explicit dump prints retained entries while disabled")
assert(loadfile("PallySealCooldowns/Diagnostics.lua"))("PallySealCooldowns", addon)
assert(not addon.DebugEnabled() and #db.debugLog == 100,
    "Reload keeps captured data but does not enable diagnostics")
addon.DebugCommand(db, "clear", Message, {})
assert(#db.debugLog == 0)
addon.DebugCommand(db, "invalid", Message, {})
assert(not addon.DebugEnabled())

local secret = setmetatable({}, {__tostring = function() error("Secret string conversion") end})
issecretvalue = function(value) return value == secret end
assert(addon.DebugAura({name = secret, expirationTime = secret}) ==
    "restricted:expires=restricted:observed")
assert(addon.DebugAuraUpdate(secret) == "update=restricted")
assert(addon.DebugAuraUpdate(nil) == "update=unavailable")
assert(addon.DebugAuraUpdate({removedAuraInstanceIDs = secret}):find("removedAuraInstanceIDs=restricted", 1, true))
assert(addon.DebugAuraUpdate({removedAuraInstanceIDs = {1, 2}}):find("removedAuraInstanceIDs=2", 1, true))
for _, outcome in ipairs({"empty", "error", "restricted", "found"}) do
    local aura, restricted, detail = addon.FindSeal({Seal = true}, function()
        if outcome == "error" then error("Do not copy raw error content") end
        if outcome == "restricted" then return secret end
        if outcome == "found" then return {duration = secret, expirationTime = secret} end
    end, true)
    assert(detail == "Seal=" .. outcome)
    assert(restricted == (outcome == "error" or outcome == "restricted"))
    assert((aura ~= nil) == (outcome == "found"))
end
local _, _, detail = addon.FindSeal({Seal = true}, function() return nil end)
assert(detail == nil, "Disabled diagnostics do not collect query text")
io.write("Diagnostics tests passed.\n")
-- Compare supported APIs without executing probes when diagnostics are off.
local calls = 0
local result = {auraInstanceID = 77, expirationTime = secret}
C_UnitAuras = {
    GetPlayerAuraBySpellID = function(id)
        calls = calls + 1
        assert(id == 20375)
        return result
    end,
    GetUnitAuraBySpellID = function(unit, id)
        assert(unit == "player" and id == 20375)
        return result
    end,
    GetAuraDataByAuraInstanceID = function(unit, id)
        assert(unit == "player" and id == 77)
        return result
    end,
    IsAuraFilteredOutByInstanceID = function(unit, id, filter)
        assert(unit == "player" and id == 77 and filter == "HELPFUL")
        return false
    end,
}
addon.DebugProbe(db, true, {auraInstanceID = 77}, {[20375] = true})
assert(calls == 0, "Disabled diagnostics make no compatibility API calls")
addon.DebugCommand(db, "on", Message, {Seal = true})
local tracked = {auraInstanceID = 77, expirationTime = 200}
addon.DebugProbe(db, true, tracked, {[20375] = true})
local entry = db.debugLog[#db.debugLog]
assert(entry:find("player-spell[20375]=found:instance=77:expires=restricted", 1, true))
assert(entry:find("instance[77]=found", 1, true))
assert(entry:find("filtered[77]=false", 1, true))
assert(tracked.expirationTime == 200, "Probe must not mutate the tracked timer")
local count = #db.debugLog
addon.DebugRecord(db, "scan", "stable")
addon.DebugProbe(db, true, tracked, {[20375] = true})
assert(#db.debugLog == count + 1, "Scan recording must not defeat probe deduplication")
result = nil
addon.DebugProbe(db, true, nil, {[20375] = true})
assert(db.debugLog[#db.debugLog]:find("instance[77]=empty", 1, true),
    "Retain last instance for the after-removal comparison")
result = secret
addon.DebugProbe(db, true, tracked, {[20375] = true})
assert(db.debugLog[#db.debugLog]:find("player-spell[20375]=restricted", 1, true))
C_UnitAuras.GetPlayerAuraBySpellID = function() error("Do not log raw error") end
addon.DebugProbe(db, true, {}, {[20375] = true})
assert(db.debugLog[#db.debugLog]:find("player-spell[20375]=error", 1, true))
assert(db.debugLog[#db.debugLog]:find("instance=unknown", 1, true))
C_UnitAuras = {}
addon.DebugProbe(db, true, nil, {[20375] = true})
assert(db.debugLog[#db.debugLog]:find("player-spell[20375]=unsupported", 1, true))
