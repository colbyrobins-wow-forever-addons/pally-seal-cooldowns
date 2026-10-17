local addon = {}
local combat = false
InCombatLockdown = function() return combat end
UIParent = {}
UISpecialFrames = {}
local methods = {}
function methods:SetText(text) self.text = text end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:IsShown() return self.shown end
for _, name in ipairs({"SetSize", "SetPoint", "SetFrameStrata", "SetClampedToScreen",
    "SetMovable", "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
    "SetWidth", "SetJustifyH", "RegisterEvent"}) do methods[name] = function() end end
local function Widget()
    return setmetatable({scripts = {}}, {__index = methods})
end
function methods:CreateFontString() return Widget() end
CreateFrame = function()
    local frame = Widget()
    frame.Text, frame.TitleText = Widget(), Widget()
    return frame
end
assert(loadfile("ForeverXP/Settings.lua"))("ForeverXP", addon)
local db = {mouseoverOnly = false, tall = false}
local applied = 0
local function GetSettings() return db end
local function Apply() applied = applied + 1 end
local window = addon.OpenSettings(GetSettings, Apply)
assert(window.shown and window.always.checked and not window.mouseover.checked)
assert(#UISpecialFrames == 1 and UISpecialFrames[1] == "ForeverXPSettingsWindow")
window.mouseover.scripts.OnClick(window.mouseover)
assert(db.mouseoverOnly and window.mouseover.checked and not window.always.checked)
window.mouseover.checked = false
window.mouseover.scripts.OnClick(window.mouseover)
assert(window.mouseover.checked, "Selected visibility option cannot be unchecked into no selection")
window.always.scripts.OnClick(window.always)
assert(not db.mouseoverOnly and window.always.checked and not window.mouseover.checked)
combat = true
window.tall.checked = true
window.tall.scripts.OnClick(window.tall)
assert(db.tall and window.notice.text:find("after combat", 1, true))
combat = false
window.scripts.OnEvent(window)
assert(window.notice.text:find("immediately", 1, true))
assert(applied == 4, "Each click applies preferences once")
db = {mouseoverOnly = true, tall = false}
local reopened = addon.OpenSettings(GetSettings, Apply)
assert(reopened == window and #UISpecialFrames == 1, "Reopen reuses window and Escape registration")
assert(window.mouseover.checked and not window.tall.checked, "Reopen reflects current saved preferences")
io.write("Forever XP settings tests passed.\n")
