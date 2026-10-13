local _, addon = ...

-- Query only known seals, avoiding unrelated secret combat auras.
function addon.FindSeal(names, query, diagnostics)
    local restricted = false
    local results = diagnostics and {} or nil
    for name in pairs(names) do
        local ok, aura = pcall(query, "player", name, "HELPFUL")
        if results then
            local outcome = not ok and "error" or
                (not addon.IsReadable(aura) and "restricted" or (aura and "found" or "empty"))
            results[#results + 1] = name .. "=" .. outcome
        end
        if not ok or not addon.IsReadable(aura) then
            restricted = true
        elseif aura then
            if results then table.sort(results) end
            return {
                name = name,
                icon = aura.icon,
                duration = aura.duration,
                expirationTime = aura.expirationTime,
                auraInstanceID = aura.auraInstanceID,
            }, false, results and table.concat(results, "; ")
        end
    end
    if results then table.sort(results) end
    return nil, restricted, results and table.concat(results, "; ")
end

function addon.IsReadable(value)
    return not (issecretvalue and issecretvalue(value))
end

function addon.IsFiniteNumber(value)
    return addon.IsReadable(value) and type(value) == "number"
        and value == value and value > -math.huge and value < math.huge
end

-- Like the totem tracker, reconcile readable data and retain only a live
-- estimate when the API is restricted. Allow new casts time to reach the API.
function addon.ResolveSeal(previous, current, restricted, now)
    if previous and previous.castTime and now - previous.castTime < 0.5 then
        local stale = not current or current.name ~= previous.name
        if current and addon.IsFiniteNumber(current.duration)
            and addon.IsFiniteNumber(current.expirationTime) then
            stale = stale or current.expirationTime - current.duration < previous.castTime - 0.1
        end
        if stale then return previous end
    end
    if current then
        local state = addon.GetState(current.duration, current.expirationTime, now, 0)
        if state ~= "restricted" then return current end
        -- A different seal must never inherit the previous seal's countdown.
        if previous and previous.name == current.name
            and addon.IsFiniteNumber(previous.expirationTime)
            and previous.expirationTime > now then
            previous.estimated = true
            previous.auraInstanceID = current.auraInstanceID
            return previous
        end
        return current
    end
    if restricted and previous and addon.IsFiniteNumber(previous.expirationTime)
        and previous.expirationTime > now then
        previous.estimated = true
        return previous
    end
    return nil
end

function addon.WasSealRemoved(aura, update)
    if not aura or not addon.IsFiniteNumber(aura.auraInstanceID)
        or not addon.IsReadable(update) or type(update) ~= "table" then return false end
    local removed = update.removedAuraInstanceIDs
    if not addon.IsReadable(removed) or type(removed) ~= "table" then return false end
    for _, instanceID in ipairs(removed) do
        if addon.IsFiniteNumber(instanceID) and instanceID == aura.auraInstanceID then
            return true
        end
    end
    return false
end

-- Delta events can identify a new seal even when name queries return nil.
function addon.FindAddedSeal(names, update)
    if not addon.IsReadable(update) or type(update) ~= "table" then return nil end
    local added = update.addedAuras
    if not addon.IsReadable(added) or type(added) ~= "table" then return nil end
    local found
    for _, aura in ipairs(added) do
        if addon.IsReadable(aura) and type(aura) == "table"
            and addon.IsReadable(aura.name) and type(aura.name) == "string"
            and names[aura.name] and addon.IsReadable(aura.isHelpful)
            and aura.isHelpful ~= false then
            found = {
                name = aura.name, icon = aura.icon, duration = aura.duration,
                expirationTime = aura.expirationTime, auraInstanceID = aura.auraInstanceID,
            }
        end
    end
    return found
end

function addon.IsSealCombatRemoval(aura, event, playerGUID, destinationGUID, name, auraType)
    if not aura then return false end
    local function ReadableString(value)
        return addon.IsReadable(value) and type(value) == "string"
    end
    return ReadableString(event) and ReadableString(playerGUID)
        and ReadableString(destinationGUID) and ReadableString(name)
        and ReadableString(auraType) and ReadableString(aura.name)
        and event == "SPELL_AURA_REMOVED" and playerGUID == destinationGUID
        and name == aura.name and auraType == "BUFF"
end

function addon.GetState(duration, expiration, now, threshold)
    if not addon.IsReadable(duration) or not addon.IsReadable(expiration) then
        return "restricted"
    end
    if not addon.IsFiniteNumber(duration) or not addon.IsFiniteNumber(expiration) then
        return "restricted"
    end
    if duration <= 0 or expiration <= 0 then
        return "permanent"
    end
    local remaining = math.max(0, expiration - now)
    if remaining == 0 then
        return "missing", 0
    end
    if remaining <= threshold then
        return "refresh", remaining
    end
    return "active", remaining
end
