local _, addon = ...

function addon.CreateMinimapButton(db, openSettings)
    if not Minimap then return end
    local button = CreateFrame("Button", "PallySealCooldownsMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\Spell_Holy_SealOfMight")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function Position()
        local radius = Minimap:GetWidth() / 2 + 5
        local angle = math.rad(db.minimapAngle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(angle) * radius, math.sin(angle) * radius)
    end

    button:SetScript("OnClick", openSettings)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Pally Seal Cooldowns")
        GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local centerX, centerY = Minimap:GetCenter()
            local x, y = cursorX / scale - centerX, cursorY / scale - centerY
            local atan2 = math.atan2 or math.atan
            db.minimapAngle = math.deg(atan2(y, x)) % 360
            Position()
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    Position()
    return button
end
