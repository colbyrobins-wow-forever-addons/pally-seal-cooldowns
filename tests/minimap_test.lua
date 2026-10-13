local button = {scripts = {}}
setmetatable(button, {__index = function(_, name)
    if name == "CreateTexture" then return function() return button end end
    if name == "SetScript" then
        return function(self, event, handler) self.scripts[event] = handler end
    end
    return function() end
end})
CreateFrame = function() return button end
Minimap = {
    GetWidth = function() return 140 end,
    GetEffectiveScale = function() return 2 end,
    GetCenter = function() return 100, 100 end,
}
GameTooltip = {Hide = function() end}
GetCursorPosition = function() return 200, 350 end
local addon = {}
assert(loadfile("PallySealCooldowns/Minimap.lua"))("PallySealCooldowns", addon)
local opened = 0
local db = {minimapAngle = 225}
addon.CreateMinimapButton(db, function() opened = opened + 1 end)
button.scripts.OnClick()
assert(opened == 1, "Minimap click must open settings")
button.scripts.OnDragStart(button)
button.scripts.OnUpdate()
assert(math.abs(db.minimapAngle - 90) < 0.01, "Drag must use scaled cursor coordinates")
button.scripts.OnDragStop(button)
assert(button.scripts.OnUpdate == nil, "Dragging must not leave an update loop running")
io.write("Minimap interaction tests passed.\n")
