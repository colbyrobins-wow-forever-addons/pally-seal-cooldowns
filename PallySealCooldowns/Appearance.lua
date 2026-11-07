local _, addon = ...

local builtins = {
    font = {
        {key = "default", label = "Game default"},
        {key = "arial", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF"},
        {key = "skurri", label = "Skurri", path = "Fonts\\SKURRI.TTF"},
        {key = "morpheus", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF"},
    },
    border = {
        {key = "default", label = "Default icon border"},
        {key = "none", label = "None"},
        {key = "solid", label = "Solid", path = "Interface\\Buttons\\WHITE8X8"},
        {key = "tooltip", label = "Tooltip", path = "Interface\\Tooltips\\UI-Tooltip-Border"},
    },
    statusbar = {
        {key = "default", label = "Game default"},
        {key = "flat", label = "Flat", path = "Interface\\Buttons\\WHITE8X8"},
    },
}
addon.BorderColors = {
    {key = "white", label = "White", rgb = {1, 1, 1}},
    {key = "gold", label = "Gold", rgb = {1, 0.72, 0.25}},
    {key = "black", label = "Black", rgb = {0.1, 0.1, 0.1}},
    {key = "pink", label = "Paladin pink", rgb = {0.96, 0.55, 0.73}},
}
-- Shared by refresh warnings and the missing-seal state.
addon.WarningColors = {
    {key = "red", label = "Red", rgb = {1, 0.35, 0.2}},
    {key = "orange", label = "Orange", rgb = {1, 0.6, 0.1}},
    {key = "yellow", label = "Yellow", rgb = {1, 0.9, 0.2}},
    {key = "pink", label = "Paladin pink", rgb = {0.96, 0.55, 0.73}},
    {key = "white", label = "White", rgb = {1, 1, 1}},
}
addon.LayoutChoices = {
    {key = "icon", label = "Large icon"},
    {key = "bar", label = "Small icon with timer bar"},
    {key = "essential", label = "Essential Cooldowns icon"},
}
addon.MissingAlertChoices = {
    {key = "both", label = "Glow and bounce"},
    {key = "glow", label = "Glow only"},
    {key = "bounce", label = "Bounce only"},
    {key = "none", label = "None"},
}
addon.MissingSymbols = {
    {key = "bang", label = "Exclamation (!)", text = "!"},
    {key = "none", label = "None", text = ""},
}
addon.MissingIcons = {
    {key = "might", label = "Default", path = "Interface\\Icons\\Spell_Holy_SealOfMight"},
    {key = "righteousness", label = "Seal of Righteousness", path = "Interface\\Icons\\Ability_ThunderBolt"},
    {key = "command", label = "Seal of Command", path = "Interface\\Icons\\Ability_Warrior_InnerRage"},
    {key = "crusader", label = "Seal of the Crusader", path = "Interface\\Icons\\Spell_Holy_HolySmite"},
    {key = "justice", label = "Seal of Justice", path = "Interface\\Icons\\Spell_Holy_SealOfWrath"},
    {key = "light", label = "Seal of Light", path = "Interface\\Icons\\Spell_Holy_HealingAura"},
    {key = "wisdom", label = "Seal of Wisdom", path = "Interface\\Icons\\Spell_Holy_RighteousnessAura"},
}
addon.OutlineChoices = {
    {key = "default", label = "Game default"},
    {key = "none", label = "None"},
    {key = "OUTLINE", label = "Outline"},
    {key = "THICKOUTLINE", label = "Thick outline"},
}
addon.PresetChoices = {
    {key = "default", label = "Default"},
    {key = "minimal", label = "Minimal"},
    {key = "contrast", label = "High Contrast"},
    {key = "gold", label = "Classic Gold"},
    {key = "pink", label = "Paladin Pink"},
    {key = "clean", label = "Clean Text"},
}
local defaults = {font = "default", border = "default", statusbar = "default",
    outline = "default", fontShadow = true, timerSize = 0, nameSize = 0,
    borderSize = 2, borderColor = "white", warningColor = "red"}

local function SharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

function addon.MediaChoices(kind)
    local choices = {}
    for _, choice in ipairs(builtins[kind]) do choices[#choices + 1] = choice end
    local media = SharedMedia()
    if media then
        for _, name in ipairs(media:List(kind)) do
            choices[#choices + 1] = {key = "media:" .. name, label = name}
        end
    end
    return choices
end

function addon.MediaPath(kind, key)
    for _, choice in ipairs(builtins[kind]) do
        if choice.key == key then return choice.path end
    end
    if type(key) == "string" and key:sub(1, 6) == "media:" then
        local media = SharedMedia()
        return media and media:Fetch(kind, key:sub(7), true) or nil
    end
end

function addon.NormalizeAppearance(db)
    for key, value in pairs(defaults) do
        if type(db[key]) ~= type(value) then db[key] = value end
    end
    for _, key in ipairs({"font", "border", "statusbar"}) do
        local valid = db[key]:sub(1, 6) == "media:" and #db[key] > 6
        for _, choice in ipairs(builtins[key]) do valid = valid or db[key] == choice.key end
        if not valid then db[key] = defaults[key] end
    end
    for key, choices in pairs({outline = addon.OutlineChoices, borderColor = addon.BorderColors,
        warningColor = addon.WarningColors}) do
        local valid = false
        for _, choice in ipairs(choices) do valid = valid or db[key] == choice.key end
        if not valid then db[key] = defaults[key] end
    end
    for key, limits in pairs({timerSize = {0, 40}, nameSize = {0, 24}, borderSize = {1, 16}}) do
        local value = db[key]
        if not addon.IsFiniteNumber(value) then value = defaults[key] end
        db[key] = math.floor(math.max(limits[1], math.min(limits[2], value)))
        if key ~= "borderSize" and db[key] > 0 and db[key] < 8 then db[key] = 8 end
    end
end

function addon.ApplyPreset(db, preset)
    local valid = false
    for _, choice in ipairs(addon.PresetChoices) do
        if choice.key == preset then valid = true; break end
    end
    if not valid then return end
    for key, value in pairs(defaults) do db[key] = value end
    if preset == "minimal" then
        db.border, db.statusbar, db.outline = "solid", "flat", "none"
        db.borderSize, db.borderColor, db.fontShadow = 1, "black", false
    elseif preset == "contrast" then
        db.border, db.statusbar, db.outline = "solid", "flat", "THICKOUTLINE"
        db.borderSize, db.timerSize, db.nameSize = 3, 18, 14
    elseif preset == "gold" then
        db.border, db.borderColor, db.borderSize = "tooltip", "gold", 12
        db.outline = "OUTLINE"
    elseif preset == "pink" then
        db.font, db.border, db.borderColor = "arial", "solid", "pink"
        db.statusbar, db.outline = "flat", "OUTLINE"
    elseif preset == "clean" then
        db.font, db.border, db.statusbar = "arial", "none", "flat"
        db.outline, db.fontShadow = "none", true
        db.timerSize, db.nameSize = 16, 12
    end
end

local function Choice(choices, key)
    for _, choice in ipairs(choices) do
        if choice.key == key then return choice end
    end
end

-- Layout and missing-seal behavior; presets never change these.
function addon.NormalizeDisplayOptions(db)
    -- Test builds saved the Essential style as a separate checkbox.
    if db.cdmStyle == true then db.displayStyle = "essential" end
    db.cdmStyle = nil
    local defaults = {displayStyle = "icon", missingAlert = "both",
        missingSymbol = "bang", missingIcon = "might"}
    local sources = {displayStyle = addon.LayoutChoices, missingAlert = addon.MissingAlertChoices,
        missingSymbol = addon.MissingSymbols, missingIcon = addon.MissingIcons}
    for key, choices in pairs(sources) do
        if not Choice(choices, db[key]) then db[key] = defaults[key] end
    end
    db.showIconBar = db.showIconBar ~= false
    db.showMissingText = db.showMissingText ~= false
    db.hideWhenMissing = db.hideWhenMissing == true
end

function addon.WarningRGB(db)
    return unpack((Choice(addon.WarningColors, db.warningColor) or addon.WarningColors[1]).rgb)
end

function addon.MissingIconPath(db)
    return (Choice(addon.MissingIcons, db.missingIcon) or addon.MissingIcons[1]).path
end

function addon.MissingSymbol(db)
    return (Choice(addon.MissingSymbols, db.missingSymbol) or addon.MissingSymbols[1]).text
end

-- Returns whether the in-combat missing alert glows and whether it bounces.
function addon.MissingAlertParts(db)
    local alert = db.missingAlert or "both"
    return alert == "both" or alert == "glow", alert == "both" or alert == "bounce"
end

function addon.BorderRGB(db, warning)
    if warning then return addon.WarningRGB(db) end
    for _, choice in ipairs(addon.BorderColors) do
        if choice.key == db.borderColor then return unpack(choice.rgb) end
    end
    return 1, 1, 1
end

function addon.ApplyFont(region, db, size)
    local originalPath, originalSize, originalFlags = region:GetFont()
    local path = addon.MediaPath("font", db.font) or originalPath
    local flags = db.outline
    if flags == "default" then flags = originalFlags or "" end
    if flags == "none" then flags = "" end
    local targetSize = size > 0 and size or originalSize
    if not region:SetFont(path, targetSize, flags) then
        region:SetFont(originalPath, targetSize, flags)
    end
    local offset = db.fontShadow and 1 or 0
    region:SetShadowOffset(offset, -offset)
end
