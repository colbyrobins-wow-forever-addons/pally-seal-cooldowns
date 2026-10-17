local _, addon = ...
local window

function addon.OpenSettings(getSettings, apply)
    if not window then
        window = CreateFrame("Frame", "ForeverXPSettingsWindow", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(440, 300)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetClampedToScreen(true)
        window:SetMovable(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window.TitleText:SetText("Forever XP")
        UISpecialFrames[#UISpecialFrames + 1] = "ForeverXPSettingsWindow"

        local function Text(text, y, font)
            local label = window:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", 24, y)
            label:SetWidth(392)
            label:SetJustifyH("LEFT")
            label:SetText(text)
            return label
        end
        Text("XP text visibility", -48, "GameFontNormal")
        local function Check(text, y, change)
            local control = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
            control:SetPoint("TOPLEFT", 20, y)
            control.Text:SetText(text)
            control:SetScript("OnClick", function(self)
                change(window.getSettings(), self:GetChecked() == true)
                window.apply()
                window:Refresh()
            end)
            return control
        end
        window.always = Check("Always show XP text", -70, function(db) db.mouseoverOnly = false end)
        window.mouseover = Check("Show XP text only on mouseover", -102, function(db) db.mouseoverOnly = true end)
        Text("Bar appearance", -154, "GameFontNormal")
        window.tall = Check("Use a taller XP bar", -176, function(db, checked) db.tall = checked end)
        Text("Full XP details and the hover tooltip are available with either visibility option.", -220)
        window.notice = Text("", -260)
        function window:Refresh()
            local db = self.getSettings()
            self.always:SetChecked(not db.mouseoverOnly)
            self.mouseover:SetChecked(db.mouseoverOnly)
            self.tall:SetChecked(db.tall)
            self.notice:SetText(InCombatLockdown and InCombatLockdown()
                and "Saved. Bar height changes apply after combat." or "Changes apply immediately and are saved automatically.")
        end
        window:SetScript("OnShow", function(self) self:Refresh() end)
        window:RegisterEvent("PLAYER_REGEN_ENABLED")
        window:RegisterEvent("PLAYER_REGEN_DISABLED")
        window:SetScript("OnEvent", function(self) if self:IsShown() then self:Refresh() end end)
    end
    window.getSettings, window.apply = getSettings, apply
    window:Refresh()
    window:Show()
    return window
end
