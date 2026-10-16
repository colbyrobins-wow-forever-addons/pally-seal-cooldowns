local _, addon = ...

local function IsNumber(value)
    return not (issecretvalue and issecretvalue(value))
        and type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function GroupDigits(value)
    local digits = string.format("%.0f", value)
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (grouped:gsub("^,", ""))
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
