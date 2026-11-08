local addon = {}
assert(loadfile("PallySealCooldowns/SealLogic.lua"))("PallySealCooldowns", addon)
assert(loadfile("PallySealCooldowns/CooldownManager.lua"))("PallySealCooldowns", addon)

-- Normalization: invalid values repaired, sizes clamped. Snapping is no longer
-- a setting, so an old saved checkbox is dropped.
local db = {scale = 1}
addon.NormalizeCooldownManager(db)
assert(db.snapToCDM == nil)
assert(db.snapSide == "right" and db.cdmIconSize == 0 and db.snapGap == 2)
db.snapToCDM, db.snapSide = true, "diagonal"
db.cdmIconSize, db.snapGap = 0 / 0, 99
addon.NormalizeCooldownManager(db)
assert(db.snapToCDM == nil and db.snapSide == "right", "The old snap checkbox is removed")
assert(db.cdmIconSize == 0 and db.snapGap == 20)
db.cdmIconSize = 7
addon.NormalizeCooldownManager(db)
assert(db.cdmIconSize == 16, "Manual sizes start at 16")
db.cdmIconSize, db.snapGap = 2, 2

-- Only the Essential Cooldowns icon snaps; other layouts keep their placement.
local frame = {SetPoint = function(self, ...) self.point = {...} end}
EssentialCooldownViewer = {}
for _, style in ipairs({"icon", "bar", "swing"}) do
    db.displayStyle = style
    assert(not addon.SnapToCooldownViewer(frame, db) and frame.point == nil, style .. " never snaps")
end
db.displayStyle = "essential"
EssentialCooldownViewer = nil
assert(not addon.SnapToCooldownViewer(frame, db), "Missing bar falls back to saved position")
EssentialCooldownViewer = {IsForbidden = function() return true end}
assert(not addon.SnapToCooldownViewer(frame, db), "Forbidden bar is never touched")

-- Each side anchors the facing edges; the gap is in screen units.
local viewer = {}
EssentialCooldownViewer = viewer
local expected = {
    right = {"LEFT", viewer, "RIGHT", 2, 0},
    left = {"RIGHT", viewer, "LEFT", -2, 0},
    top = {"BOTTOM", viewer, "TOP", 0, 2},
    bottom = {"TOP", viewer, "BOTTOM", 0, -2},
}
for side, point in pairs(expected) do
    db.snapSide = side
    assert(addon.SnapToCooldownViewer(frame, db))
    for index = 1, 5 do assert(frame.point[index] == point[index], side .. " anchor " .. index) end
end
db.snapSide, db.scale = "right", 2
assert(addon.SnapToCooldownViewer(frame, db) and frame.point[4] == 1,
    "Offsets are divided by the tracker scale so the visible gap stays constant")
db.scale = 1

-- Icon size: manual size wins; otherwise follow an active Blizzard icon.
assert(addon.IconLayoutSize({displayStyle = "icon"}) == 52, "Large icon keeps the 52 px icon")
db.displayStyle, db.cdmIconSize = "essential", 40
assert(addon.IconLayoutSize(db) == 40)
db.cdmIconSize = 0
assert(addon.IconLayoutSize(db) == 50, "Without visible Blizzard icons use its default size")
local width, itemScale = 45, 1.2
local item = {GetWidth = function() return width end,
    GetEffectiveScale = function() return itemScale end}
local active = {}
viewer.itemFramePool = {EnumerateActive = function() return pairs(active) end}
UIParent = {GetEffectiveScale = function() return 0.9 end}
assert(addon.IconLayoutSize(db) == 50, "Empty bar keeps the default size")
active[item] = true
assert(addon.IconLayoutSize(db) == 60, "45 px at 1.2 scale equals 60 px under UIParent at 0.9")
db.scale = 1.5
assert(addon.IconLayoutSize(db) == 40, "Matched size accounts for the tracker scale")
db.scale = 1
local secret = {}
issecretvalue = function(value) return value == secret end
width = secret
assert(addon.IconLayoutSize(db) == 60, "Secret geometry keeps the last readable size")
issecretvalue = nil
item.GetWidth = function() error("geometry unavailable") end
assert(addon.IconLayoutSize(db) == 60, "Errors reading Blizzard frames are contained")

-- Relayout watching uses a single secure post-hook and never calls Blizzard methods.
local hooks, calls = {}, 0
hooksecurefunc = function(target, method, hook)
    assert(target == viewer and method == "RefreshLayout")
    hooks[#hooks + 1] = hook
end
C_Timer = {After = function(delay, callback) assert(delay == 0); callback() end}
viewer.RefreshLayout = function() error("Addon code must not call Blizzard relayout") end
addon.WatchCooldownViewer(function() calls = calls + 1 end)
addon.WatchCooldownViewer(function() calls = calls + 1 end)
assert(#hooks == 1, "The bar is hooked once")
hooks[1]()
assert(calls == 1, "Relayouts notify the tracker on the next frame")
io.write("Cooldown manager tests passed.\n")
