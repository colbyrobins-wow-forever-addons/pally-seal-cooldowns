local _, addon = ...
local events = CreateFrame("Frame")
local bindings = {}
local warned = false

local function UpdateBinding(binding)
    if binding.updating then return end
    local bar, label = binding.bar, binding.label
    local text = addon.FormatXP(UnitXP("player"), UnitXPMax("player"))
    binding.updating = true
    -- Use Blizzard's existing label. Never change bar values, layout, CVars,
    -- or tooltip handlers. Hidden/zero-XP bars must not leave floating text.
    label:SetText(text or "")
    if text and bar:IsShown() then label:Show() else label:Hide() end
    binding.updating = false
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
SlashCmdList.FOREVERXP = function()
    Attach()
    Update()
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
    "UPDATE_FACTION"}) do
    events:RegisterEvent(event)
end
if Attach() then Update() end
