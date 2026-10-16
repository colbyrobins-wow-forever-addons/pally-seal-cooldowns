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

local function RunScenario(late, combat, globalLabel)
    local current, maximum = 12500, 20000
    local handler, hooks, messages = nil, 0, 0
    local text = {shown = false}
    function text:SetText(value) self.value = value end
    function text:SetFormattedText(format, ...) self.value = string.format(format, ...) end
    function text:Show() self.shown = true end
    function text:Hide() self.shown = false end
    local bar = {shown = true, scripts = {}}
    function bar:IsShown() return self.shown end
    function bar:HookScript(event, callback) self.scripts[event] = callback end
    if not globalLabel then bar.TextString = text end
    MainMenuExpBar = not late and bar or nil
    MainMenuBarExpText = globalLabel and text or nil
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
    assert(loadfile("ForeverXP/ForeverXP.lua"))("ForeverXP", addon)
    if late or combat then
        assert(hooks == 0, "No attachment until the bar is ready outside combat")
        handler(nil, "PLAYER_ENTERING_WORLD")
        handler(nil, "PLAYER_ENTERING_WORLD")
        assert(messages == (combat and 0 or 1), "Missing bar warning is emitted only once")
        MainMenuExpBar, combat = bar, false
        handler(nil, late and "ADDON_LOADED" or "PLAYER_REGEN_ENABLED")
    end
    assert(text.value == addon.FormatXP(current, maximum) and text.shown)
    handler(nil, "ADDON_LOADED")
    assert(hooks == 4, "Repeated addon loads do not duplicate hooks")
    current = 15000
    handler(nil, "PLAYER_XP_UPDATE", "pet")
    assert(text.value == addon.FormatXP(12500, maximum), "Other units are ignored")
    combat = true
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == addon.FormatXP(current, maximum), "Attached text updates during combat")
    text:SetText("Blizzard hover text")
    assert(text.value == addon.FormatXP(current, maximum))
    text:SetFormattedText("XP %d", 1)
    assert(text.value == addon.FormatXP(current, maximum))
    text:Hide()
    assert(text.shown, "Mouse leave must not hide the XP label")
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
    assert(text.value == "0 / 25,000 XP -- 0.0% -- 25,000 XP till level")
    maximum = 0
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == "" and not text.shown, "Zero maximum does not divide by zero")
    maximum, current = 25000, secret
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.value == "" and not text.shown, "Restricted XP stays blank")
    current = 100
    handler(nil, "PLAYER_XP_UPDATE", "player")
    assert(text.shown and text.value == addon.FormatXP(current, maximum))
end

RunScenario(false, false, false)
RunScenario(true, false, false)
RunScenario(false, true, true)
io.write("Forever XP tests passed.\n")
