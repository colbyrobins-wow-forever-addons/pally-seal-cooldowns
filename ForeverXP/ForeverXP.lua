local _, addon = ...
local events = CreateFrame("Frame")
local bar, label
local updating = false
local warned = false

local function Update()
    if not label or updating then return end
    local text = addon.FormatXP(UnitXP("player"), UnitXPMax("player"))
    updating = true
    -- Use Blizzard's existing label. Never change bar values, layout, CVars,
    -- or tooltip handlers. Hidden/zero-XP bars must not leave floating text.
    label:SetText(text or "")
    if text and bar:IsShown() then label:Show() else label:Hide() end
    updating = false
end

local function Attach()
    if label then return true end
    if InCombatLockdown and InCombatLockdown() then return false end
    local candidate = MainMenuExpBar
    local candidateLabel = candidate and (candidate.TextString or MainMenuBarExpText)
    if not candidateLabel then return false end
    bar, label = candidate, candidateLabel
    -- Post-hooks preserve Blizzard's handlers and restore our text after its
    -- XP updates, hover text, and text-visibility settings run.
    hooksecurefunc(label, "SetText", Update)
    hooksecurefunc(label, "SetFormattedText", Update)
    hooksecurefunc(label, "Show", Update)
    hooksecurefunc(label, "Hide", Update)
    bar:HookScript("OnShow", Update)
    bar:HookScript("OnHide", Update)
    return true
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_XP_UPDATE" and unit and unit ~= "player" then return end
    if Attach() then
        Update()
    elseif event == "PLAYER_ENTERING_WORLD" and not warned
        and not (InCombatLockdown and InCombatLockdown()) then
        warned = true
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd36aForever XP:|r Blizzard's XP bar was not found. "
            .. "This addon requires the default Forever beta action bar.")
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD",
    "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "CVAR_UPDATE"}) do
    events:RegisterEvent(event)
end
if Attach() then Update() end
