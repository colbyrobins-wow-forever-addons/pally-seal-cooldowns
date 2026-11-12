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
    {key = "swing", label = "Swing timer bar"},
    -- Blizzard's Cooldown Manager shows the seal; this addon only plays alerts.
    {key = "blizzard", label = "Blizzard Cooldown Manager"},
}

-- True when Blizzard's Cooldown Manager displays the seal and this addon draws
-- nothing, keeping only its sound alerts.
function addon.AlertsOnly(db)
    return db.displayStyle == "blizzard"
end
addon.MissingAlertChoices = {
    {key = "both", label = "Glow and bounce"},
    {key = "glow", label = "Glow only"},
    {key = "bounce", label = "Bounce only"},
    {key = "none", label = "None"},
}
addon.MissingSymbols = {
    {key = "bang", label = "Exclamation (!)", text = "!"},
    {key = "none", label = "None", text = ""},
    -- Reads like Blizzard's idle swing timer, including its white text.
    {key = "zero", label = "Zero time (0.0)", text = "0.0", rgb = {1, 1, 1}},
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
    -- These two are mostly an icon border look, which the swing bar lacks.
    {key = "gold", label = "Classic Gold", iconBorder = true},
    {key = "pink", label = "Paladin Pink", iconBorder = true},
    {key = "clean", label = "Clean Text"},
}
-- Bar artwork a preset leaves alone in the swing layout, so Blizzard's swing
-- timer art (fill and frame) survives; presets there change only text.
local swingKept = {"statusbar", "border", "borderColor", "borderSize"}

-- The presets that suit the chosen layout.
function addon.PresetChoicesFor(db)
    local choices = {}
    -- Nothing of this addon's is drawn, so there is nothing to style.
    if addon.AlertsOnly(db) then return choices end
    for _, choice in ipairs(addon.PresetChoices) do
        if not (choice.iconBorder and db.displayStyle == "swing") then choices[#choices + 1] = choice end
    end
    return choices
end
local defaults = {font = "default", border = "default", statusbar = "default",
    outline = "default", fontShadow = true, timerSize = 0, nameSize = 0,
    borderSize = 2, borderColor = "white", warningColor = "red"}

local function SharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- SharedMedia's "None" sound is silence, which would quietly disable an alert.
function addon.IsSilentMedia(kind, key)
    return kind == "sound" and key == "media:None"
end

-- Built-in choices (this file's, or the caller's) followed by SharedMedia ones.
function addon.MediaChoices(kind, base)
    local choices = {}
    for _, choice in ipairs(base or builtins[kind]) do choices[#choices + 1] = choice end
    local media = SharedMedia()
    if media then
        for _, name in ipairs(media:List(kind)) do
            if not addon.IsSilentMedia(kind, "media:" .. name) then
                choices[#choices + 1] = {key = "media:" .. name, label = name}
            end
        end
    end
    return choices
end

function addon.MediaPath(kind, key)
    for _, choice in ipairs(builtins[kind] or {}) do
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
    local kept = {}
    if db.displayStyle == "swing" then
        for _, key in ipairs(swingKept) do kept[key] = db[key] end
    end
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
    for key, value in pairs(kept) do db[key] = value end
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
    local width = addon.IsFiniteNumber(db.swingWidth) and db.swingWidth or addon.SwingDefaultWidth
    db.swingWidth = math.floor(math.max(213, math.min(852, width)) + 0.5)
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

function addon.MissingSymbolRGB(db)
    local choice = Choice(addon.MissingSymbols, db.missingSymbol)
    if choice and choice.rgb then return unpack(choice.rgb) end
    return addon.WarningRGB(db)
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

-- Swing timer bar layout: Forever's main-hand swing timer (Blizzard_SwingTimer)
-- rebuilt from the same atlases, with no Blizzard template or Edit Mode hooks.
-- Sizes come from settings, never from frame geometry, so the art is safe on
-- native aura buttons. Clients without the atlases get a drawn bronze frame.
addon.SwingInsetX, addon.SwingInsetY = 5, 4
-- Edit Mode's Modern main-hand timer: stored 213 x 15, added to the sliders' 213
-- and 15 minimums (Blizzard_EditMode's ConvertValueDiffFromMin).
addon.SwingDefaultWidth = 426
addon.SwingLabel = "Seal Timer"
addon.SwingAtlas = {
    background = "ui-swingtimerbar-background",
    frame = "ui-swingtimerbar-frame",
    fill = "ui-swingtimerbar-filling-mainhand",
    pip = "ui-swingtimerbar-pip",
    shadow = "ui-swingtimerbar-textshadow-left",
}
local swingRings = {
    -- inset, thickness, color
    {0, 1, {0.15, 0.1, 0.04}},
    {1, 2, {0.34, 0.26, 0.17}},
    {3, 1, {0.04, 0.01, 0}},
}
local swingCorners = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}

function addon.HasSwingAtlas()
    return C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo(addon.SwingAtlas.frame) and true or false
end

function addon.SwingSize(db)
    return db.swingWidth, 30
end

-- Fill texture for the bar: the main-hand fill unless a texture is chosen.
function addon.SwingFill(db)
    if db.statusbar == "default" and addon.HasSwingAtlas() then return addon.SwingAtlas.fill end
end

-- Active fill color: the atlas fill keeps its own color; plain fills are gold.
function addon.ActiveBarRGB(db)
    if db.displayStyle == "swing" and addon.SwingFill(db) then return 1, 1, 1 end
    return 1, 0.72, 0.25
end

function addon.CreateSwingArt(parent, bar)
    local art = {back = parent:CreateTexture(nil, "BACKGROUND"),
        frame = parent:CreateTexture(nil, "BACKGROUND", nil, 1), edges = {}, corners = {},
        shadow = bar:CreateTexture(nil, "OVERLAY"), pip = bar:CreateTexture(nil, "OVERLAY", nil, 1)}
    for index = 1, #swingRings * 4 do art.edges[index] = parent:CreateTexture(nil, "BORDER") end
    for index = 1, #swingCorners do art.corners[index] = parent:CreateTexture(nil, "BORDER", nil, 1) end
    return art
end

local function StyleDrawnFrame(art, parent, shown)
    for _, texture in ipairs(art.edges) do texture:SetShown(shown) end
    for _, texture in ipairs(art.corners) do texture:SetShown(shown) end
    if not shown then return end
    for ring, definition in ipairs(swingRings) do
        local inset, size, rgb = unpack(definition)
        local top, bottom, left, right = unpack(art.edges, ring * 4 - 3, ring * 4)
        for _, texture in ipairs({top, bottom, left, right}) do
            texture:ClearAllPoints()
            texture:SetColorTexture(rgb[1], rgb[2], rgb[3], 1)
        end
        top:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
        top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
        top:SetHeight(size)
        bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
        bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
        bottom:SetHeight(size)
        left:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset - size)
        left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset + size)
        left:SetWidth(size)
        right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset - size)
        right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset + size)
        right:SetWidth(size)
    end
    -- Bright gold glints sit on the bronze band at each corner.
    for index, point in ipairs(swingCorners) do
        local texture = art.corners[index]
        texture:ClearAllPoints()
        texture:SetSize(2, 2)
        texture:SetPoint(point, parent, point, point:find("LEFT", 1, true) and 1 or -1,
            point:find("TOP", 1, true) and -1 or 1)
        texture:SetColorTexture(0.95, 0.83, 0.66, 1)
    end
end

-- Call after the bar's fill texture is set; the pip follows the fill's edge.
function addon.StyleSwingArt(art, parent, bar, db, missing)
    local shown = db.displayStyle == "swing"
    local atlas = shown and addon.HasSwingAtlas()
    local framed = shown and db.border ~= "none"
    art.back:SetShown(shown)
    art.frame:SetShown(atlas and framed)
    art.shadow:SetShown(atlas)
    -- Like Blizzard's, the pip shows only while a timer runs.
    art.pip:SetShown(atlas and not missing)
    StyleDrawnFrame(art, parent, framed and not atlas)
    if not shown then return end
    art.back:ClearAllPoints()
    if atlas then
        art.back:SetAtlas(addon.SwingAtlas.background)
        art.back:SetAllPoints(parent)
        art.frame:SetAtlas(addon.SwingAtlas.frame)
        art.frame:ClearAllPoints()
        art.frame:SetAllPoints(parent)
        art.shadow:SetAtlas(addon.SwingAtlas.shadow)
        art.shadow:ClearAllPoints()
        art.shadow:SetPoint("TOPLEFT", bar, "TOPLEFT")
        art.shadow:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
        art.shadow:SetWidth(math.min(171, db.swingWidth - 2 * addon.SwingInsetX))
        art.pip:SetAtlas(addon.SwingAtlas.pip, true)
        art.pip:ClearAllPoints()
        art.pip:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    else
        art.back:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -1)
        art.back:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1, 1)
        art.back:SetColorTexture(0.05, 0.04, 0.03, 0.85)
    end
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
