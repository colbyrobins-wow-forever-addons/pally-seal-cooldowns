local addon = {}
assert(loadfile("ForeverXP/XPText.lua"))("ForeverXP", addon)
assert(addon.FormatXP(12500, 20000) == "12,500 / 20,000 XP -- 62.5% -- 7,500 XP till level")
assert(addon.FormatXP(0, 400) == "0 / 400 XP -- 0.0% -- 400 XP till level")
assert(addon.FormatXP(1000000, 2000000) == "1,000,000 / 2,000,000 XP -- 50.0% -- 1,000,000 XP till level")
assert(addon.FormatXP(500, 400) == "400 / 400 XP -- 100.0% -- 0 XP till level")
assert(addon.FormatXP(0, 0) == nil)
assert(addon.FormatXP(-1, 400) == nil)
assert(addon.FormatXP(nil, 400) == nil)
assert(addon.FormatXP(5, "400") == nil)
assert(addon.FormatXP(math.huge, 400) == nil)
assert(addon.FormatXP(0 / 0, 400) == nil)
local secret = {}
issecretvalue = function(value) return value == secret end
assert(addon.FormatXP(secret, 400) == nil)
assert(addon.FormatXP(0, secret) == nil)
assert(addon.XPDetails(secret, 400, 21, 0) == nil)
assert(addon.XPDetails(0, 400, secret, secret).nextLevel == nil)
assert(addon.XPDetails(0, 400, 21, -5).rested == 0)

local function RunScenario(late, combat, globalLabel, modern)
    local current, maximum = 12500, 20000
    ForeverXPDB = nil
    local level, rested = 21, 4000
    UnitLevel = function() return level end
    GetXPExhaustion = function() return rested end
    local function Expected(value, cap, full)
        return addon.StyledXP(addon.XPDetails(value, cap, level, rested), full)
    end
    local handler, hooks, messages = nil, 0, 0
    local text = {shown = false}
    function text:SetText(value) self.value = value end
    function text:SetFormattedText(format, ...) self.value = string.format(format, ...) end
    function text:Show() self.shown = true end
    function text:Hide() self.shown = false end
    function text:SetShown(value) self.shown = value end
    local bar = {shown = true, scripts = {}}
    function bar:IsShown() return self.shown end
    function bar:HookScript(event, callback)
        local previous = self.scripts[event]
        self.scripts[event] = function(...)
            if previous then previous(...) end
            callback(...)
        end
    end
    local height = 13
    function bar:GetHeight() return height end
    function bar:SetHeight(value) assert(not combat); height = value end
    function text:GetFont() return "test-font", 10 end
    function text:SetFont(font, size, flags) self.fontSize, self.flags = size, flags end
    function text:SetShadowColor() end
    function text:SetShadowOffset() end
    function text:SetJustifyH() end
    if not globalLabel then bar.TextString = text end
    MainMenuExpBar = not late and bar or nil
    MainMenuBarExpText = globalLabel and text or nil
    StatusTrackingBarManager, StatusTrackingBarInfo = nil, nil
    SlashCmdList = {}
    C_AddOns = nil
    if modern then
        MainMenuExpBar, MainMenuBarExpText = nil, nil
        bar.TextString = nil
        bar.OverlayFrame = {Text = text}
        StatusTrackingBarInfo = {BarsEnum = {Experience = 7}}
        StatusTrackingBarManager = {barContainers = late and {} or {{bars = {[7] = bar}}}}
    end
    UnitXP = function(unit) assert(unit == "player"); return current end
    UnitXPMax = function(unit) assert(unit == "player"); return maximum end
    InCombatLockdown = function() return combat end
    DEFAULT_CHAT_FRAME = {AddMessage = function() messages = messages + 1 end}
    CreateFrame = function()
        return {
            RegisterEvent = function() end,
            SetScript = function(_, event, callback)
                assert(event == "OnEvent")
                handler = callback
            end,
        }
    end
    hooksecurefunc = function(object, method, callback)
        hooks = hooks + 1
        local original = assert(object[method])
        object[method] = function(...)
            original(...)
            callback(...)
        end
    end
    GameTooltip = {lines = {}}
    function GameTooltip:SetOwner(owner) self.owner = owner end
    function GameTooltip:IsOwned(owner) return self.owner == owner end
    function GameTooltip:ClearLines() self.lines = {} end
    function GameTooltip:SetText(value) self.title = value end
    function GameTooltip:AddDoubleLine(left, right) self.lines[#self.lines + 1] = {left, right} end
    function GameTooltip:AddLine(value) self.lines[#self.lines + 1] = {value} end
    function GameTooltip:Show() self.shown = true end
    function GameTooltip:Hide() self.shown = false end
    GameTooltip_SetDefaultAnchor = function(tooltip, owner)
        tooltip:SetOwner(owner)
        tooltip.defaultAnchored = true
    end
    assert(loadfile("ForeverXP/Presentation.lua"))("ForeverXP", addon)
    hooks = 0
    assert(loadfile("ForeverXP/ForeverXP.lua"))("ForeverXP", addon)
    if late or combat then
        assert(hooks == 0, "No attachment until the bar is ready outside combat")
        handler(nil, "PLAYER_ENTERING_WORLD")
        handler(nil, "PLAYER_ENTERING_WORLD")
        assert(messages == (combat and 0 or 1), "Missing bar warning is emitted only once")
        combat = false
        if modern then
            StatusTrackingBarManager.barContainers = {{bars = {[7] = bar}}}
        else MainMenuExpBar = bar end
        handler(nil, late and "ADDON_LOADED" or "PLAYER_REGEN_ENABLED")
    end
    assert(text.value == Expected(current, maximum) and text.shown)
    handler(nil, "ADDON_LOADED")
    assert(hooks == 5, "Repeated addon loads do not duplicate hooks")
    current = 15000
    handler(nil, "PLAYER_XP_UPDATE", "pet")
    assert(text.value == Expected(12500, maximum), "Other units are ignored")
    combat = true
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == Expected(current, maximum), "Attached text updates during combat")
    text:SetText("Blizzard hover text")
    assert(text.value == Expected(current, maximum))
    text:SetFormattedText("XP %d", 1)
    assert(text.value == Expected(current, maximum))
    text:Hide()
    assert(text.shown, "Mouse leave must not hide the XP label")
    text:SetShown(false)
    assert(text.shown, "Native SetShown cannot hide the XP label")
    bar.shown = false
    bar.scripts.OnHide()
    assert(not text.shown and not bar.shown, "Hidden bar remains hidden")
    text:Show()
    assert(not text.shown, "Blizzard cannot leave text visible on a hidden bar")
    bar.shown = true
    bar.scripts.OnShow()
    assert(text.shown)
    current, maximum = 0, 25000
    handler(nil, "PLAYER_LEVEL_UP", 22)
    assert(text.value == Expected(0, 25000))
    maximum = 0
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == "" and not text.shown, "Zero maximum does not divide by zero")
    maximum, current = 25000, secret
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == "" and not text.shown, "Restricted XP stays blank")
    current = 100
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.shown and text.value == Expected(current, maximum))
    if modern then
        combat = false
        local secondText = {}
        -- Fresh methods: don't inherit the first label's post-hooks.
        function secondText:SetText(value) self.value = value end
        function secondText:SetFormattedText() end
        function secondText:Show() self.shown = true end
        function secondText:Hide() self.shown = false end
        local secondBar = {OverlayFrame = {Text = secondText}, scripts = {}}
        function secondBar:IsShown() return true end
        secondBar.HookScript = bar.HookScript
        StatusTrackingBarManager.barContainers[2] = {bars = {[7] = secondBar}}
        handler(nil, "UPDATE_FACTION")
        assert(secondText.value == Expected(current, maximum) and secondText.shown,
            "Reputation layout can introduce another XP bar copy")
        current = 200
        handler(nil, "PLAYER_XP_UPDATE", "player")
        assert(text.value == secondText.value, "Both container copies update")
    end
    combat = false
    assert(text.flags == "OUTLINE" and text.fontSize == 12)
    bar.scripts.OnEnter(bar)
    assert(text.value == Expected(current, maximum, true), "Hover expands compact text")
    assert(GameTooltip.shown and #GameTooltip.lines == 5)
    assert(GameTooltip.defaultAnchored and GameTooltip:IsOwned(bar),
        "Expanded tooltip uses Blizzard's default anchor and retains XP ownership")
    assert(GameTooltip.lines[4][2] == "4,000", "Tooltip includes rested XP")
    GameTooltip:SetText("Delayed Blizzard rested text")
    assert(GameTooltip.title == "Experience" and #GameTooltip.lines == 5,
        "Delayed tooltip updates retain details without accumulating lines")
    rested = 0
    handler(nil, "UPDATE_EXHAUSTION")
    assert(GameTooltip.lines[4][2] == "0", "Hovered tooltip updates rested amount")
    GameTooltip:SetOwner({})
    GameTooltip:SetText("Other tooltip")
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(GameTooltip.title == "Other tooltip", "XP updates do not steal unrelated tooltips")
    bar.scripts.OnEnter(bar)
    bar.scripts.OnLeave()
    assert(text.value == Expected(current, maximum) and not GameTooltip.shown)
    SlashCmdList.FOREVERXP("full")
    assert(ForeverXPDB.mode == "full" and text.value == Expected(current, maximum, true))
    SlashCmdList.FOREVERXP("compact")
    combat = true
    SlashCmdList.FOREVERXP("tall")
    assert(height == 13, "Height changes defer in combat")
    combat = false
    handler(nil, "PLAYER_REGEN_ENABLED")
    assert(height == 18, "Deferred height applies outside combat")
    SlashCmdList.FOREVERXP("normal")
    assert(height == 13, "Normal mode restores the captured bar height")
    local previousMessages = messages
    C_AddOns = {IsAddOnLoaded = function(name) return name == "XPForever" end}
    SlashCmdList.FOREVERXP()
    assert(messages == previousMessages + 2, "Status reports attachment and loaded XPForever conflict")
end

RunScenario(false, false, false)
RunScenario(true, false, false)
RunScenario(false, true, true)
RunScenario(false, false, false, true)
RunScenario(true, false, false, true)
RunScenario(false, true, false, true)
io.write("Forever XP tests passed.\n")
