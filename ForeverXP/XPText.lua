local _, addon = ...

local function IsNumber(value)
    return not (issecretvalue and issecretvalue(value))
        and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

addon.IsNumber = IsNumber

local function GroupDigits(value)
    local digits = string.format("%.0f", value)
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (grouped:gsub("^,", ""))
end

addon.GroupDigits = GroupDigits

function addon.XPDetails(current, maximum, level, rested)
    if not IsNumber(current) or not IsNumber(maximum) or current < 0
        or maximum < 1 then return nil end
    maximum = math.floor(maximum)
    current = math.min(math.floor(current), maximum)
    return {current = current, maximum = maximum, remaining = maximum - current,
        percent = current / maximum * 100,
        nextLevel = IsNumber(level) and level > 0 and math.floor(level) + 1 or nil,
        rested = IsNumber(rested) and math.max(0, math.floor(rested)) or nil}
end

function addon.StyledXP(data, full)
    if not data then return nil end
    local target = data.nextLevel and "to level " .. data.nextLevel or "to next level"
    local progress = string.format("|cffffd36a%.1f%%|r", data.percent)
    local remaining = "|cffe6e6e6" .. GroupDigits(data.remaining) .. " " .. target .. "|r"
    local separator = " |cff888888•|r "
    if not full then return progress .. separator .. remaining end
    return "|cffe6e6e6" .. GroupDigits(data.current) .. " / "
        .. GroupDigits(data.maximum) .. " XP|r" .. separator .. progress .. separator .. remaining
end

function addon.FormatXP(current, maximum)
    if not IsNumber(current) or not IsNumber(maximum)
        or maximum <= 0 or current < 0 then return nil end
    maximum = math.floor(maximum)
    if maximum == 0 then return nil end
    current = math.min(math.floor(current), maximum)
    return string.format("%s / %s XP -- %.1f%% -- %s XP till level",
        GroupDigits(current), GroupDigits(maximum), current / maximum * 100,
        GroupDigits(maximum - current))
end
