local _, addon = ...
local enabled = false
local lastScan
local limit = 100

function addon.DebugEnabled()
    return enabled
end

local function SafeValue(value)
    if not addon.IsReadable(value) then return "restricted" end
    if type(value) == "string" then return value end
    if type(value) == "boolean" then return tostring(value) end
    if addon.IsFiniteNumber(value) then return tostring(value) end
    return "unavailable"
end

function addon.DebugAura(aura)
    if not aura then return "none" end
    return SafeValue(aura.name) .. ":expires=" .. SafeValue(aura.expirationTime)
        .. (aura.estimated and ":estimated" or ":observed")
        .. (addon.IsFiniteNumber(aura.auraInstanceID) and ":instance=" .. aura.auraInstanceID or "")
end

function addon.DebugAuraUpdate(update)
    if not addon.IsReadable(update) then return "update=restricted" end
    if type(update) ~= "table" then return "update=unavailable" end
    local fields = {"full=" .. SafeValue(update.isFullUpdate)}
    for _, key in ipairs({"addedAuras", "updatedAuraInstanceIDs", "removedAuraInstanceIDs"}) do
        local values = update[key]
        local description = "unavailable"
        if not addon.IsReadable(values) then
            description = "restricted"
        elseif type(values) == "table" then
            description = tostring(#values)
        end
        fields[#fields + 1] = key .. "=" .. description
    end
    return table.concat(fields, " ")
end

function addon.DebugRecord(db, event, detail)
    if not enabled then return end
    local entry = event .. " " .. detail
    if event == "scan" then
        if entry == lastScan then return end
        lastScan = entry
    else
        lastScan = nil
    end
    if type(db.debugLog) ~= "table" then db.debugLog = {} end
    while #db.debugLog >= limit do table.remove(db.debugLog, 1) end
    db.debugLog[#db.debugLog + 1] = string.format("%.1f %s", GetTime(), entry)
end

function addon.DebugCommand(db, argument, message, names)
    argument = argument:lower()
    if argument == "on" then
        enabled, lastScan = true, nil
        db.debugLog = {}
        local version, build, _, interface = GetBuildInfo()
        addon.DebugRecord(db, "client", SafeValue(version) .. " build=" .. SafeValue(build)
            .. " interface=" .. SafeValue(interface))
        local known = {}
        for name in pairs(names) do known[#known + 1] = name end
        table.sort(known)
        addon.DebugRecord(db, "seal-names", #known .. " resolved: " .. table.concat(known, ", "))
        addon.DebugRecord(db, "removal-signals", "combat-log-api="
            .. tostring(type(CombatLogGetCurrentEventInfo) == "function")
            .. " registered=" .. tostring(addon.CombatLogAvailable == true))
        local apis = C_UnitAuras or {}
        for _, key in ipairs({"GetAuraDataByAuraInstanceID", "GetAuraDataByIndex",
            "GetPlayerAuraBySpellID", "GetAuraSlots", "IsAuraFilteredOutByInstanceID"}) do
            addon.DebugRecord(db, "aura-api", key .. "=" .. tostring(type(apis[key]) == "function"))
        end
        message("Diagnostics enabled for this session. Reproduce the issue, then /psc debug dump.")
    elseif argument == "off" then
        enabled, lastScan = false, nil
        message("Diagnostics disabled; captured entries retained.")
    elseif argument == "clear" then
        db.debugLog, lastScan = {}, nil
        message("Diagnostic entries cleared.")
    elseif argument == "dump" then
        local entries = type(db.debugLog) == "table" and db.debugLog or {}
        message("Diagnostics: " .. #entries .. " entries (latest " .. limit .. ").")
        for _, entry in ipairs(entries) do
            if type(entry) == "string" then message(entry) end
        end
    else
        message("/psc debug on | off | dump | clear")
    end
end
