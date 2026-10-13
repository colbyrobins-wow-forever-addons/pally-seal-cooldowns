local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/Appearance.lua"))("PallySealCooldowns", addon)
local db = {timerSize = math.huge, nameSize = -5, borderSize = 0 / 0,
    font = "media:Missing", border = "invalid", outline = "invalid", threshold = 7}
addon.NormalizeAppearance(db)
assert(db.timerSize == 0 and db.nameSize == 0 and db.borderSize == 2)
assert(db.font == "media:Missing" and db.border == "default" and db.outline == "default")
assert(addon.MediaPath("font", db.font) == nil, "Missing packs fall back without losing selection")
assert(#addon.MediaChoices("font") == 4)
local paths = {font = {Community = "community.ttf"}, border = {Community = "community.tga"},
    statusbar = {Community = "bar.tga"}}
local media = {
    List = function() return {"Community"} end,
    Fetch = function(_, kind, name, noDefault)
        assert(noDefault == true)
        return paths[kind][name]
    end,
}
LibStub = function(name, silent)
    assert(name == "LibSharedMedia-3.0" and silent)
    return media
end
assert(#addon.MediaChoices("font") == 5, "Media registered later appears on the next query")
assert(addon.MediaPath("font", "media:Community") == "community.ttf")
assert(addon.MediaPath("border", "media:Community") == "community.tga")
assert(addon.MediaPath("statusbar", "media:Community") == "bar.tga")
local applied, shadow
local region = {
    GetFont = function() return "default.ttf", 12, "OUTLINE" end,
    SetFont = function(_, path, size, flags)
        if path == "community.ttf" then return false end
        applied = {path, size, flags}
        return true
    end,
    SetShadowOffset = function(_, x, y) shadow = {x, y} end,
}
db.font, db.timerSize, db.outline, db.fontShadow = "media:Community", 20, "none", false
addon.ApplyFont(region, db, db.timerSize)
assert(applied[1] == "default.ttf" and applied[2] == 20 and applied[3] == "")
assert(shadow[1] == 0 and shadow[2] == 0, "Text shadow can be disabled")
addon.ApplyPreset(db, "contrast")
assert(db.borderSize == 3 and db.outline == "THICKOUTLINE" and db.threshold == 7)
db.borderColor = "black"
local r, g, b = addon.BorderRGB(db, true)
assert(r == 1 and g == 0.3 and b == 0.15, "Warnings override custom border colors")
addon.ApplyPreset(db, "default")
addon.ApplyFont(region, db, db.timerSize)
assert(applied[2] == 12 and applied[3] == "OUTLINE", "Default restores layout font settings")
LibStub = nil
assert(addon.MediaPath("font", "media:Community") == nil)
for _, choice in ipairs(addon.PresetChoices) do
    addon.ApplyPreset(db, "contrast")
    addon.ApplyPreset(db, choice.key)
    local snapshot = {}
    for key, value in pairs(db) do snapshot[key] = value end
    addon.NormalizeAppearance(db)
    addon.ApplyPreset(db, choice.key)
    for key, value in pairs(snapshot) do
        assert(db[key] == value, "Preset must be valid and repeatable: " .. choice.key)
    end
    for _, kind in ipairs({"font", "border", "statusbar"}) do
        local key = db[kind]
        assert(key == "default" or key == "none" or addon.MediaPath(kind, key),
            "Presets must work without SharedMedia: " .. choice.key)
    end
    assert(db.threshold == 7, "Presets must preserve warning settings")
end
addon.ApplyPreset(db, "unknown")
assert(db.font == "arial" and db.border == "none", "Unknown presets must not change settings")
io.write("Appearance tests passed.\n")
