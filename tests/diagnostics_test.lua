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
assert(addon.DebugEnabled() and #db.debugLog == 2 and #messages == 1)
assert(db.debugLog[2]:find("1 resolved: Seal", 1, true))
addon.DebugRecord(db, "scan", "empty")
for index = 1, 1000 do addon.DebugRecord(db, "scan", "empty") end
assert(#db.debugLog == 3 and #messages == 1, "Repeated scans must not spam logs or chat")
addon.DebugRecord(db, "combat", "enter")
addon.DebugRecord(db, "scan", "empty")
assert(#db.debugLog == 5, "Capture scans again after combat transition")
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
