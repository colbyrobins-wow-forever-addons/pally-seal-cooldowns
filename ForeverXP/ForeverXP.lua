local _, addon = ...
local events = CreateFrame("Frame")
local bindings = {}
local warned = false

local function Settings()
    if type(ForeverXPDB) ~= "table" then ForeverXPDB = {} end
    ForeverXPDB.mode = ForeverXPDB.mode == "full" and "full" or "compact"
    ForeverXPDB.tall = ForeverXPDB.tall == true
    return ForeverXPDB
end

local function StyleAll()
    for _, binding in pairs(bindings) do addon.StyleXP(binding, Settings()) end
end

local function UpdateBinding(binding)
    if binding.updating then return end
    local bar, label = binding.bar, binding.label
    local text = addon.StyledXP(addon.ReadXP(), binding.hovered or Settings().mode == "full")
    binding.updating = true
    -- Hidden/zero-XP bars must not leave floating text.
    label:SetText(text or "")
    if text and bar:IsShown() then label:Show() else label:Hide() end
    binding.updating = false
    if binding.hovered and GameTooltip
        and GameTooltip:IsOwned(binding.hoverTarget or binding.bar) then
        addon.ShowXPTooltip(binding)
    end
end

local function Update()
    for _, binding in pairs(bindings) do UpdateBinding(binding) end
end

local function AttachBar(bar, label)
    if not bar or not label or bindings[bar] then return end
    local binding = {bar = bar, label = label}
    bindings[bar] = binding
    local function Refresh() UpdateBinding(binding) end
    -- Post-hooks preserve Blizzard's handlers and restore our text after its
    -- XP updates, hover text, and text-visibility settings run.
    hooksecurefunc(label, "SetText", Refresh)
    hooksecurefunc(label, "SetFormattedText", Refresh)
    hooksecurefunc(label, "Show", Refresh)
    hooksecurefunc(label, "Hide", Refresh)
    if label.SetShown then hooksecurefunc(label, "SetShown", Refresh) end
    bar:HookScript("OnShow", Refresh)
    bar:HookScript("OnHide", Refresh)
    addon.HookXPHover(binding, Refresh)
    addon.StyleXP(binding, Settings())
end

local function Attach()
    if InCombatLockdown and InCombatLockdown() then return next(bindings) ~= nil end
    -- Forever's newer UI keeps one XP bar per tracking container. Bind all
    -- copies so tracking reputation or rearranging bars cannot lose the text.
    local index = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
        and StatusTrackingBarInfo.BarsEnum.Experience
    if index and StatusTrackingBarManager then
        for _, container in ipairs(StatusTrackingBarManager.barContainers or {}) do
            local bar = container.bars and container.bars[index]
            if bar then
                AttachBar(bar, bar.OverlayFrame and bar.OverlayFrame.Text
                    or bar.StatusBar and bar.StatusBar.TextString)
            end
        end
    end
    if MainMenuExpBar then
        AttachBar(MainMenuExpBar, MainMenuExpBar.TextString or MainMenuBarExpText)
    end
    return next(bindings) ~= nil
end

SLASH_FOREVERXP1 = "/foreverxp"
SlashCmdList.FOREVERXP = function(input)
    local command = (input or ""):lower():match("^%s*(.-)%s*$")
    local settings = Settings()
    if command == "compact" or command == "full" then settings.mode = command
    elseif command == "tall" then settings.tall = true
    elseif command == "normal" then settings.tall = false
    elseif command ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage("Forever XP: /foreverxp compact | full | tall | normal")
        return
    end
    Attach()
    StyleAll()
    Update()
    if command ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage("Forever XP: " .. settings.mode .. " text, "
            .. (settings.tall and "taller" or "normal") .. " bar."
            .. ((InCombatLockdown and InCombatLockdown()) and " Layout applies after combat." or ""))
        return
    end
    local count, visible = 0, 0
    for bar in pairs(bindings) do
        count = count + 1
        if bar:IsShown() then visible = visible + 1 end
    end
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "Forever XP: %d XP bars attached, %d shown. %s", count, visible,
        addon.FormatXP(UnitXP("player"), UnitXPMax("player")) or "XP unavailable."))
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("XPForever") then
        DEFAULT_CHAT_FRAME:AddMessage("Forever XP: XPForever is loaded and can hide Blizzard's XP bar. "
            .. "Disable XPForever and reload to use Blizzard's bar.")
    end
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_XP_UPDATE" and unit and unit ~= "player" then return end
    if Attach() then
        if event == "ADDON_LOADED" or event == "PLAYER_REGEN_ENABLED"
            or event == "PLAYER_ENTERING_WORLD" then StyleAll() end
        Update()
    elseif event == "PLAYER_ENTERING_WORLD" and not warned
        and not (InCombatLockdown and InCombatLockdown()) then
        warned = true
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd36aForever XP:|r Blizzard's XP bar was not found. "
            .. "Run /foreverxp for attachment status.")
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD",
    "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "CVAR_UPDATE",
    "UPDATE_FACTION", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING"}) do
    events:RegisterEvent(event)
end
if Attach() then Update() end
