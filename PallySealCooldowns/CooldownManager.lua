local _, addon = ...

-- Blizzard's Cooldown Manager. Only anchor to it and read guarded values:
-- calling its Edit Mode methods from addon code taints Blizzard's refresh path.
local viewerName = "EssentialCooldownViewer"
local fallbackSize = 50
local lastVisibleSize
addon.SnapSides = {
    {key = "right", label = "Right of bar"},
    {key = "left", label = "Left of bar"},
    {key = "top", label = "Above bar"},
    {key = "bottom", label = "Below bar"},
}
local anchors = {
    right = {"LEFT", "RIGHT", 1, 0},
    left = {"RIGHT", "LEFT", -1, 0},
    top = {"BOTTOM", "TOP", 0, 1},
    bottom = {"TOP", "BOTTOM", 0, -1},
}

function addon.NormalizeCooldownManager(db)
    -- Snapping is the Essential Cooldowns icon's behavior, not a setting.
    db.snapToCDM = nil
    if not anchors[db.snapSide] then db.snapSide = "right" end
    for key, limits in pairs({cdmIconSize = {0, 80, 0}, snapGap = {0, 20, 2}}) do
        local value = db[key]
        if not addon.IsFiniteNumber(value) then value = limits[3] end
        db[key] = math.floor(math.max(limits[1], math.min(limits[2], value)) + 0.5)
    end
    -- 0 follows Blizzard's icon size; manual sizes start at 16.
    if db.cdmIconSize > 0 and db.cdmIconSize < 16 then db.cdmIconSize = 16 end
end

function addon.CooldownViewer()
    local viewer = _G[viewerName]
    if type(viewer) ~= "table" or (viewer.IsForbidden and viewer:IsForbidden()) then return nil end
    return viewer
end

local function Number(value)
    if addon.IsFiniteNumber(value) and value > 0 then return value end
end

-- Visible size of an active Essential icon in UIParent units, or nil.
local function BlizzardIconSize(viewer)
    local pool = viewer and viewer.itemFramePool
    if not pool or type(pool.EnumerateActive) ~= "function" then return nil end
    local ok, size = pcall(function()
        for item in pool:EnumerateActive() do
            local width, scale = Number(item:GetWidth()), Number(item:GetEffectiveScale())
            local parent = Number(UIParent:GetEffectiveScale())
            if width and scale and parent then return width * scale / parent end
        end
    end)
    return ok and Number(size) or nil
end

-- Icon edge length for the Essential-matching style, in tracker units.
function addon.CooldownIconSize(db)
    if db.cdmIconSize > 0 then return db.cdmIconSize end
    -- Remember the on-screen size so it stays valid if the tracker scale changes.
    lastVisibleSize = BlizzardIconSize(addon.CooldownViewer()) or lastVisibleSize
    if not lastVisibleSize then return fallbackSize end
    return math.floor(lastVisibleSize / db.scale + 0.5)
end

-- Edge length of the square icon layout: 52 by default, or the matched size.
function addon.IconLayoutSize(db)
    if db.displayStyle == "essential" then return addon.CooldownIconSize(db) end
    return 52
end

-- Calls back after Blizzard relayouts the bar (e.g. an Edit Mode icon size
-- change). A secure post-hook observes without calling Blizzard's methods.
local watched
function addon.WatchCooldownViewer(callback)
    local viewer = addon.CooldownViewer()
    if not viewer or watched == viewer or type(viewer.RefreshLayout) ~= "function"
        or type(hooksecurefunc) ~= "function" then return end
    watched = viewer
    hooksecurefunc(viewer, "RefreshLayout", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, callback) else callback() end
    end)
end

-- Anchors the tracker to the Essential bar. Returns false to keep the free position.
function addon.SnapToCooldownViewer(frame, db)
    -- Only the Essential Cooldowns icon snaps; other layouts keep their position.
    if db.displayStyle ~= "essential" then return false end
    local viewer = addon.CooldownViewer()
    if not viewer then return false end
    local anchor = anchors[db.snapSide]
    local gap = db.snapGap / db.scale
    frame:SetPoint(anchor[1], viewer, anchor[2], anchor[3] * gap, anchor[4] * gap)
    return true
end
