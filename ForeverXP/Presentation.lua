local _, addon = ...
local tooltipUpdating = false
local hovered

function addon.ReadXP()
    return addon.XPDetails(UnitXP("player"), UnitXPMax("player"),
        UnitLevel("player"), GetXPExhaustion())
end

function addon.ShowXPTooltip(binding)
    if tooltipUpdating or not GameTooltip or not binding.hovered then return end
    local data = addon.ReadXP()
    if not data then
        if GameTooltip:IsOwned(binding.hoverTarget or binding.bar) then GameTooltip:Hide() end
        return
    end
    tooltipUpdating = true
    GameTooltip:SetOwner(binding.hoverTarget or binding.bar, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Experience", 1, 0.83, 0.42)
    GameTooltip:AddDoubleLine("Current XP", addon.GroupDigits(data.current) .. " / "
        .. addon.GroupDigits(data.maximum), 0.9, 0.9, 0.9, 1, 1, 1)
    GameTooltip:AddDoubleLine("Level progress", string.format("%.1f%%", data.percent),
        0.9, 0.9, 0.9, 1, 0.83, 0.42)
    GameTooltip:AddDoubleLine(data.nextLevel and "XP to level " .. data.nextLevel or "XP to next level",
        addon.GroupDigits(data.remaining), 0.9, 0.9, 0.9, 1, 1, 1)
    GameTooltip:AddDoubleLine("Rested bonus XP", data.rested and addon.GroupDigits(data.rested) or "None",
        0.9, 0.9, 0.9, 0.4, 0.75, 1)
    GameTooltip:AddLine("Rested XP grants bonus experience from eligible kills.", 0.4, 0.75, 1, true)
    GameTooltip:Show()
    tooltipUpdating = false
end

function addon.StyleXP(binding, settings)
    if InCombatLockdown and InCombatLockdown() then return end
    local label = binding.label
    if label.GetFont then
        local font, size = label:GetFont()
        if font then label:SetFont(font, math.max(size or 12, 12), "OUTLINE") end
        label:SetShadowColor(0, 0, 0, 0.8)
        label:SetShadowOffset(1, -1)
        label:SetJustifyH("CENTER")
    end
    binding.heights = binding.heights or {}
    for _, region in pairs({bar = binding.bar, fill = binding.bar.StatusBar,
        rested = binding.bar.ExhaustionLevelFillBar}) do
        if region.GetHeight and region.SetHeight then
            local height = region:GetHeight()
            if addon.IsNumber(height) then
                if not binding.heights[region] then binding.heights[region] = height end
                region:SetHeight(settings.tall and math.max(binding.heights[region], 18)
                    or binding.heights[region])
            end
        end
    end
end

function addon.HookXPHover(binding, refresh)
    local function Enter(target)
        binding.hovered, binding.hoverTarget = true, target
        hovered = binding
        refresh()
        addon.ShowXPTooltip(binding)
    end
    local function Leave()
        binding.hovered = false
        if hovered == binding then hovered = nil end
        refresh()
        if GameTooltip and GameTooltip:IsOwned(binding.hoverTarget or binding.bar) then
            GameTooltip:Hide()
        end
    end
    binding.bar:HookScript("OnEnter", Enter)
    binding.bar:HookScript("OnLeave", Leave)
    binding.bar:HookScript("OnHide", Leave)
    if binding.bar.ExhaustionTick then
        binding.bar.ExhaustionTick:HookScript("OnEnter", Enter)
        binding.bar.ExhaustionTick:HookScript("OnLeave", Leave)
    end
end

-- Blizzard can refresh rested tooltip text after OnEnter. Restore our details
-- only while the tooltip is still owned by the hovered XP bar or rested tick.
if GameTooltip then
    hooksecurefunc(GameTooltip, "SetText", function()
        if hovered and not tooltipUpdating
            and GameTooltip:IsOwned(hovered.hoverTarget or hovered.bar) then
            addon.ShowXPTooltip(hovered)
        end
    end)
end
