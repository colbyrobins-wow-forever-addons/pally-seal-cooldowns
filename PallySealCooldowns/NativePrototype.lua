local _, addon = ...
local panel, container
local failure

-- Forever beta rank IDs from talentsforever.com/data.json, adapted from the
-- installed ForeverAuras rank dataset dated 2026-09-24 (CC BY 4.0).
-- Only spell ID data is reused; native display implementation is independent.
-- Attribution: https://talentsforever.com / https://creativecommons.org/licenses/by/4.0/
local sealRanks = {
    20375, 20915, 20918, 20919, 20920, -- Command
    1311649, 1311656, 20163, 20419, 20421, 20422, 20423, -- Fury
    20164, -- Justice
    20165, 20347, 20348, 20349, -- Light
    20154, 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293, -- Righteousness
    20166, 20356, 20357, -- Wisdom
    21082, 20162, 20305, 20306, 20307, 20308, -- Crusader
}

local function SealFilters()
    local ids = {}
    for _, id in ipairs(sealRanks) do ids[id] = true end
    return {includeSpellIDs = ids}
end

local function InitializeButton(button)
    button:SetSize(52, 52)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    button:EnableMouse(false)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button:SetIcon(icon)
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetReverse(true)
    button:SetDurationCooldown(cooldown)
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local countdown = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightHugeOutline")
    countdown:SetPoint("CENTER", button, "CENTER")
    button:SetDurationText(countdown, {})
    local name = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("TOP", button, "BOTTOM", 0, -4)
    name:SetWidth(180)
    button:SetSpellName(name)
end

local function CreatePrototype(db)
    if not CustomAuraContainerAuraProcessingPolicy
        or not AuraContainerSortMethod or not AuraContainerSortDirection then
        error("This client does not expose the native aura-container enums.")
    end
    panel = CreateFrame("Frame", "PallySealCooldownsNativePrototype", UIParent)
    panel:SetSize(56, 56)
    panel:SetPoint("CENTER", UIParent, "CENTER", db.x + 150, db.y)
    panel:SetScale(db.scale)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(false)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", panel, "TOP", 0, 8)
    label:SetText("NATIVE SEAL TEST")
    container = CreateFrame("AuraContainer", nil, panel, "CustomAuraContainerTemplate")
    container:SetEnabled(false)
    container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
    container:SetPoint("TOPLEFT", panel, "TOPLEFT")
    container:SetUnit("player")
    container:AddAuraSlot("Seal", "HELPFUL", {
        candidateFilters = SealFilters(),
        sortMethod = AuraContainerSortMethod.Default,
        sortDirection = AuraContainerSortDirection.Normal,
        initializeFrame = InitializeButton,
    })
    container:SetAuraSlotEnabled("Seal", true)
end

function addon.NativePrototypeCommand(argument, db, message)
    argument = argument:lower()
    if argument ~= "on" and argument ~= "off" then
        message("/psc native on | off (configure outside combat)")
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        message("Configure the native test display after combat ends.")
        return
    end
    if argument == "off" then
        if container then pcall(container.SetEnabled, container, false) end
        if panel then panel:Hide() end
        message("Native test display disabled.")
        return
    end
    if failure then
        message("Native test display unavailable: " .. failure .. " Retry after /reload.")
        return
    end
    local ok, problem = pcall(function()
        if not container then CreatePrototype(db) end
        container:SetEnabled(true)
        panel:Show()
    end)
    if not ok then
        failure = addon.IsReadable(problem) and type(problem) == "string"
            and problem or "native initialization failed"
        if container then pcall(container.SetEnabled, container, false) end
        if panel then panel:Hide() end
        message("Native test display unavailable: " .. failure)
        return
    end
    message("Native test display enabled beside the tracker. Its icon should disappear when the seal is removed.")
    addon.DebugRecord(db, "native-test", "enabled; appearance managed by Blizzard")
end
