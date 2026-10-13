-- Run from the repository root: lua tests/seal_logic_test.lua
local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
local function check(expected, duration, expiration, now, threshold, seconds)
    local state, remaining = addon.GetState(duration, expiration, now, threshold)
    assert(state == expected, "Expected " .. expected .. ", got " .. state)
    if seconds then assert(remaining == seconds) end
end
check("active", 30, 130, 100, 5, 30)
check("refresh", 30, 130, 125, 5, 5)
check("missing", 30, 130, 130, 5, 0)
check("missing", 30, 130, 140, 5, 0)
check("permanent", 0, 0, 100, 5)
check("restricted", nil, 130, 100, 5)
check("restricted", 30, "hidden", 100, 5)
check("restricted", math.huge, 130, 100, 5)
check("restricted", 30, 0 / 0, 100, 5)
-- A recast immediately returns to a full timer.
check("active", 30, 155, 125, 5, 30)
local secret = {}
issecretvalue = function(value) return value == secret end
check("restricted", secret, secret, 100, 5)
local aura = {name = "Seal of Righteousness"}
local found, blocked = addon.FindSeal({[aura.name] = true}, function(unit, name, filter)
    assert(unit == "player" and name == aura.name and filter == "HELPFUL")
    return aura
end)
assert(found.name == aura.name and not blocked)
found, blocked = addon.FindSeal({[aura.name] = true}, function() return nil end)
assert(found == nil and not blocked)
found, blocked = addon.FindSeal({[aura.name] = true}, function()
    error("Auras cannot be accessed when secret while tainted")
end)
assert(found == nil and blocked)
found, blocked = addon.FindSeal({[aura.name] = true}, function() return secret end)
assert(found == nil and blocked)
local previous = {name = "Seal", duration = 30, expirationTime = 130, castTime = 100}
assert(addon.ResolveSeal(previous, nil, false, 100.2) == previous,
    "New casts tolerate delayed aura updates")
assert(addon.ResolveSeal(previous, nil, false, 100.5) == nil,
    "Confirmed absence clears a cast after the grace period")
assert(addon.ResolveSeal(previous, nil, true, 110) == previous and previous.estimated,
    "Restricted data preserves a live estimate")
assert(addon.ResolveSeal(previous, nil, true, 130) == nil,
    "Restricted data must not retain an expired estimate")
local current = {name = "Seal", duration = 45, expirationTime = 145, auraInstanceID = 7}
assert(addon.ResolveSeal(previous, current, false, 110) == current)
local hidden = {name = "Seal", duration = secret, expirationTime = secret, auraInstanceID = 7}
assert(addon.ResolveSeal(previous, hidden, false, 110) == previous)
hidden.name = "Other seal"
assert(addon.ResolveSeal(previous, hidden, false, 110) == hidden,
    "A different seal with hidden timing cannot inherit the old countdown")
assert(addon.WasSealRemoved(current, {removedAuraInstanceIDs = {6, 7}}))
assert(not addon.WasSealRemoved(current, {removedAuraInstanceIDs = {secret, 6}}))
assert(not addon.WasSealRemoved(current, secret))
assert(not addon.WasSealRemoved(current, {removedAuraInstanceIDs = secret}))
local stale = {name = "Seal", duration = 30, expirationTime = 125}
assert(addon.ResolveSeal(previous, stale, false, 100.2) == previous,
    "A stale snapshot cannot undo a successful recast")
io.write("Seal logic tests passed.\n")
local names = {Seal = true}
assert(addon.FindAddedSeal(names, {addedAuras = {{name = "Other"}}}) == nil)
local addition = addon.FindAddedSeal(names, {addedAuras = {
    {name = "Seal", auraInstanceID = 88, duration = secret, expirationTime = secret},
}})
assert(addition.auraInstanceID == 88)
assert(addon.FindAddedSeal(names, {addedAuras = secret}) == nil)
assert(addon.FindAddedSeal(names, {addedAuras = {{name = secret}}}) == nil)
assert(addon.FindAddedSeal(names, {addedAuras = {{name = "Seal", isHelpful = false}}}) == nil)
assert(addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_REMOVED", "player", "player", "Seal", "BUFF"))
assert(not addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_REMOVED", "player", "other", "Seal", "BUFF"))
assert(not addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_REMOVED", "player", "player", "Other", "BUFF"))
assert(not addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_APPLIED", "player", "player", "Seal", "BUFF"))
assert(not addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_REMOVED", nil, secret, "Seal", "BUFF"))
assert(not addon.IsSealCombatRemoval({name = "Seal"}, "SPELL_AURA_REMOVED", "player", secret, "Seal", "BUFF"))
