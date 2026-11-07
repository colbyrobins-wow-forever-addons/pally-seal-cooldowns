local _, addon = ...
local margin = 64
local methods = {}

local function CreateWidgets(parent)
    local view = {frame = parent}
    view.icon = parent:CreateTexture(nil, "ARTWORK")
    view.cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
    view.cooldown:SetDrawEdge(false)
    view.cooldown:SetDrawBling(false)
    view.cooldown:SetHideCountdownNumbers(true)
    view.cooldown:SetReverse(true)
    view.bar = CreateFrame("StatusBar", nil, parent)
    view.back = view.bar:CreateTexture(nil, "BACKGROUND")
    view.back:SetAllPoints(view.bar)
    view.back:SetColorTexture(0.06, 0.07, 0.09, 0.95)
    view.overlay = CreateFrame("Frame", nil, parent)
    view.overlay:SetAllPoints(parent)
    view.overlay:SetFrameLevel(view.cooldown:GetFrameLevel() + 1)
    -- BackdropTemplate reads inherited geometry in Lua, which is secret for
    -- native aura descendants. Draw borders from fixed configuration instead.
    view.edges = {}
    for index = 1, 8 do
        view.edges[index] = view.overlay:CreateTexture(nil, "OVERLAY")
    end
    view.border = view.overlay:CreateTexture(nil, "OVERLAY")
    if C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("UI-HUD-CoolDownManager-IconOverlay") then
        view.border:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
    else
        view.border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    end
    -- Essential-matching style crops the icon with Blizzard's own mask.
    if parent.CreateMaskTexture and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("UI-HUD-CoolDownManager-Mask") then
        view.mask = parent:CreateMaskTexture()
        view.mask:SetAllPoints(view.icon)
        view.mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
        view.masked = false
    end
    view.name = view.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    view.timer = view.overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightHugeOutline")
    view.status = view.overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    return view
end

-- Icon edge length, fixed for each Apply so every region agrees.
local function IconSize(db)
    return db.displayStyle == "bar" and 30 or addon.IconLayoutSize(db)
end

local function Dimensions(db, iconSize)
    if db.displayStyle == "bar" then return db.barWidth + 32, 30 end
    -- The matched style has no padding, so snapped icons sit flush.
    local size = db.displayStyle == "essential" and iconSize or 56
    return size, size
end

local function StyleBorder(view, db, missing, iconSize)
    local path = addon.MediaPath("border", db.border)
    local size = db.borderSize
    local span = math.max(1, iconSize + 4 - 2 * size)
    local definitions = {
        {"TOPLEFT", 0, -size, size, span},
        {"TOPRIGHT", 0, -size, size, span},
        {"TOPLEFT", size, 0, span, size},
        {"BOTTOMLEFT", size, 0, span, size},
        {"TOPLEFT", 0, 0, size, size},
        {"TOPRIGHT", 0, 0, size, size},
        {"BOTTOMLEFT", 0, 0, size, size},
        {"BOTTOMRIGHT", 0, 0, size, size},
    }
    for index, definition in ipairs(definitions) do
        local texture = view.edges[index]
        texture:ClearAllPoints()
        texture:SetShown(path ~= nil)
        if path then
            local point, x, y, width, height = unpack(definition)
            texture:SetSize(width, height)
            -- The surrounding box is iconSize+4; anchors use configured offsets.
            if point:find("LEFT", 1, true) then x = x - 2 else x = x + 2 end
            if point:find("TOP", 1, true) then y = y + 2 else y = y - 2 end
            texture:SetPoint(point, view.icon, point, x, y)
            if db.border == "solid" then
                texture:SetColorTexture(addon.BorderRGB(db, missing))
            else
                texture:SetTexture(path)
                local left, right = (index - 1 + 0.0625) / 8, (index - 0.0625) / 8
                if index == 3 or index == 4 then
                    texture:SetTexCoord(left, 0.9375, right, 0.9375,
                        left, 0.0625, right, 0.0625)
                else
                    texture:SetTexCoord(left, right, 0.0625, 0.9375)
                end
                texture:SetVertexColor(addon.BorderRGB(db, missing))
            end
        end
    end
end

local function Style(view, db, missing, iconSize)
    local width, height = Dimensions(db, iconSize)
    view.frame:SetSize(width, height)
    for _, region in ipairs({view.icon, view.cooldown, view.bar, view.name, view.timer, view.status}) do
        region:ClearAllPoints()
    end
    if db.displayStyle == "bar" then
        view.icon:SetSize(30, 30)
        view.icon:SetPoint("LEFT", view.frame, "LEFT")
        view.bar:SetSize(db.barWidth, 19)
        view.bar:SetPoint("LEFT", view.icon, "RIGHT", 2, 0)
        view.name:SetPoint("LEFT", view.bar, "LEFT", 5, 0)
        view.name:SetWidth(db.barWidth - 50)
        view.name:SetJustifyH("LEFT")
        view.timer:SetFontObject("GameFontHighlightOutline")
        view.timer:SetPoint("RIGHT", view.bar, "RIGHT", -5, 0)
        view.status:SetPoint("TOPLEFT", view.bar, "BOTTOMLEFT", 5, -7)
        view.status:SetJustifyH("LEFT")
    else
        view.icon:SetSize(iconSize, iconSize)
        view.icon:SetPoint("CENTER", view.frame, "CENTER")
        view.bar:SetSize(width, 2)
        view.bar:SetPoint("TOPLEFT", view.frame, "BOTTOMLEFT", 0, -2)
        view.name:SetPoint("TOP", view.frame, "BOTTOM", 0, -8)
        view.name:SetWidth(180)
        view.name:SetJustifyH("CENTER")
        view.timer:SetFontObject("GameFontHighlightHugeOutline")
        view.timer:SetPoint("CENTER", view.frame, "CENTER")
        view.status:SetPoint("TOP", view.name, "BOTTOM", 0, -3)
        view.status:SetJustifyH("CENTER")
    end
    view.cooldown:SetAllPoints(view.icon)
    -- Alpha, not Hide: the native button drives the bound bar's updates.
    view.bar:SetAlpha((db.displayStyle == "bar" or db.showIconBar ~= false) and 1 or 0)
    local masked = db.displayStyle == "essential"
    if view.mask and view.masked ~= masked then
        if masked then view.icon:AddMaskTexture(view.mask)
        else view.icon:RemoveMaskTexture(view.mask) end
        view.masked = masked
    end
    view.bar:SetStatusBarTexture(addon.MediaPath("statusbar", db.statusbar)
        or "Interface\\TargetingFrame\\UI-StatusBar")
    view.bar:SetStatusBarColor(1, 0.72, 0.25)
    -- Missing-seal text also needs its own toggle; active text ignores it.
    local missingText = not missing or db.showMissingText ~= false
    view.name:SetShown(db.showSealName and missingText)
    view.status:SetShown(db.showStatusText and missingText)
    addon.ApplyFont(view.name, db, db.nameSize)
    addon.ApplyFont(view.timer, db, db.timerSize)
    addon.ApplyFont(view.status, db, 0)
    view.border:ClearAllPoints()
    -- Overlay art margins scale with the icon (8/7 px at the 52 px default).
    local outsetX = math.floor(8 * iconSize / 52 + 0.5)
    local outsetY = math.floor(7 * iconSize / 52 + 0.5)
    view.border:SetPoint("TOPLEFT", view.icon, "TOPLEFT", -outsetX, outsetY)
    view.border:SetPoint("BOTTOMRIGHT", view.icon, "BOTTOMRIGHT", outsetX, -outsetY)
    view.border:SetShown(db.border == "default")
    view.border:SetVertexColor(addon.BorderRGB(db, missing))
    StyleBorder(view, db, missing, iconSize)
    if missing then
        view.icon:SetTexture(addon.MissingIconPath(db))
        view.icon:SetDesaturated(true)
        view.name:SetText("No active seal")
        view.timer:SetText(addon.MissingSymbol(db))
        view.status:SetText("CAST A SEAL")
        view.timer:SetTextColor(addon.WarningRGB(db))
        view.status:SetTextColor(addon.WarningRGB(db))
        view.bar:SetMinMaxValues(0, 1)
        view.bar:SetValue(0)
        view.cooldown:Hide()
    end
end

-- Plain countdown numbers: the native default appends a unit ("12s").
-- Whole seconds round up like the game's countdown; a minute or more is M:SS.
local countdownFormatter
local function CountdownFormatter()
    if countdownFormatter ~= nil then return countdownFormatter or nil end
    countdownFormatter = false
    if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter
        and Enum and Enum.NumericRuleFormatRounding) then return nil end
    local up = Enum.NumericRuleFormatRounding.Up
    local ok, formatter = pcall(function()
        local created = C_StringUtil.CreateNumericRuleFormatter()
        created:SetBreakpoints({
            {threshold = 0, format = "%d", step = 1, rounding = up},
            {threshold = 60, format = "%d:%02d", step = 1, rounding = up,
                components = {{div = 60}, {mod = 60}}},
        })
        return created
    end)
    if ok and formatter then countdownFormatter = formatter end
    return countdownFormatter or nil
end

local function BindDurationText(button, view, db)
    local options = {textFormatter = CountdownFormatter()}
    local statusOptions
    if C_CurveUtil and CreateColor and Enum and Enum.LuaCurveType
        and Enum.DurationTextBindingProperty then
        local remaining = Enum.DurationTextBindingProperty.RemainingDuration
        local red, green, blue = addon.WarningRGB(db)
        local countdown = C_CurveUtil.CreateColorCurve()
        countdown:SetType(Enum.LuaCurveType.Step)
        countdown:AddPoint(0, CreateColor(red, green, blue, 1))
        countdown:AddPoint(db.threshold + 0.001,
            CreateColor(1, 1, 1, db.counterMode == "refresh" and 0 or 1))
        options.textColor = {curve = countdown, property = remaining}
        local warning = C_CurveUtil.CreateColorCurve()
        warning:SetType(Enum.LuaCurveType.Step)
        warning:AddPoint(0, CreateColor(red, green, blue, 1))
        warning:AddPoint(db.threshold + 0.001, CreateColor(red, green, blue, 0))
        statusOptions = {textFormat = {formatString = "REFRESH SEAL", components = {}},
            textColor = {curve = warning, property = remaining}}
    end
    if not (options.textFormatter and pcall(button.SetDurationText, button, view.timer, options)) then
        -- Keep the native countdown even if a client rejects the formatter.
        options.textFormatter = nil
        button:SetDurationText(view.timer, options)
    end
    -- A separate slot supplies status text because a button has one duration binding.
    return statusOptions
end

function addon.CreateNativeDisplay(root, db, message)
    if not CustomAuraContainerAuraProcessingPolicy or not AuraContainerSortMethod
        or not AuraContainerSortDirection then return nil end
    if InCombatLockdown and InCombatLockdown() then return nil end
    local native = setmetatable({root = root}, {__index = methods})
    local ok, problem = pcall(function()
        native.stage = CreateFrame("Frame", nil, root)
        native.stage:SetAllPoints(root)
        native.container = CreateFrame("AuraContainer", nil, native.stage, "CustomAuraContainerTemplate")
        native.container:SetEnabled(false)
        native.container:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
        native.container:SetPoint("TOPLEFT", root, "TOPLEFT")
        native.container:SetUnit("player")
        native.container:AddAuraSlot("Seal", "HELPFUL", {
            candidateFilters = addon.NativeSealFilters(),
            initializeFrame = function(button)
                native.button, native.present = button, CreateWidgets(button)
                button:EnableMouse(false)
                button:SetPoint("TOPLEFT", root, "TOPLEFT")
            end,
        })
        native.container:AddAuraSlot("Warning", "HELPFUL", {
            candidateFilters = addon.NativeSealFilters(),
            initializeFrame = function(button)
                native.warningButton = button
                button:EnableMouse(false)
                button:SetAllPoints(root)
                native.warningText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            end,
        })
        native.presence = CreateFrame("AuraContainer", nil, native.stage, "CustomAuraContainerTemplate")
        native.presence:SetEnabled(false)
        native.presence:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.None)
        native.presence:SetPoint("TOPLEFT", root, "TOPLEFT", -margin, 0)
        native.presence:SetUnit("player")
        native.presence:AddAuraGroup("Presence", "HELPFUL", {
            candidateFilters = addon.NativeSealFilters(), maxFrameCount = 1,
            layout = {elementWidth = 56 + 1 + 2 * margin, elementHeight = 56},
            initializeFrame = function(button)
                button:SetSize(56 + 1 + 2 * margin, 56)
                button:SetAlpha(0)
                button:EnableMouse(false)
            end,
        })
        native.clip = CreateFrame("Frame", nil, native.stage, "DisableUntrustedLayoutScriptsTemplate")
        native.clip:SetClipsChildren(true)
        native.clip:SetPoint("TOPLEFT", native.presence, "TOPRIGHT", -1, 0)
        native.clip:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", margin, -55)
        local missingFrame = CreateFrame("Frame", nil, native.clip, "DisableUntrustedLayoutScriptsTemplate")
        missingFrame:SetPoint("TOPLEFT", root, "TOPLEFT")
        native.missing = CreateWidgets(missingFrame)
        local glow = native.missing.overlay:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(1, 0.65, 0.1)
        glow:SetPoint("TOPLEFT", native.missing.icon, "TOPLEFT", -20, 20)
        glow:SetPoint("BOTTOMRIGHT", native.missing.icon, "BOTTOMRIGHT", 20, -20)
        glow:Hide()
        native.glow = glow
        native.pulse = glow:CreateAnimationGroup()
        native.pulse:SetLooping("BOUNCE")
        local alpha = native.pulse:CreateAnimation("Alpha")
        alpha:SetFromAlpha(0.35)
        alpha:SetToAlpha(1)
        alpha:SetDuration(0.45)
        native.bounce = missingFrame:CreateAnimationGroup()
        native.bounce:SetLooping("BOUNCE")
        local lift = native.bounce:CreateAnimation("Translation")
        lift:SetOffset(0, 8)
        lift:SetDuration(0.3)
        native:Apply(db)
        native.container:SetEnabled(true)
        native.presence:SetEnabled(true)
    end)
    if not ok then
        if native.container then pcall(native.container.SetEnabled, native.container, false) end
        if native.presence then pcall(native.presence.SetEnabled, native.presence, false) end
        if native.stage then native.stage:Hide() end
        message("Native display unavailable; using estimated tracker. "
            .. (addon.IsReadable(problem) and type(problem) == "string" and problem or "Initialization failed."))
        return nil
    end
    return native
end

-- Define Apply on the native object before initialization invokes it.
function methods:Apply(db)
    if InCombatLockdown and InCombatLockdown() then return false end
    self.container:SetEnabled(false)
    self.presence:SetEnabled(false)
    local iconSize = IconSize(db)
    local width, height = Dimensions(db, iconSize)
    Style(self.present, db, false, iconSize)
    Style(self.missing, db, true, iconSize)
    self.button:SetIcon(self.present.icon)
    self.button:SetDurationCooldown(self.present.cooldown)
    local barOptions = {}
    if db.barCountdown and Enum and Enum.StatusBarTimerDirection then
        barOptions.direction = Enum.StatusBarTimerDirection.RemainingTime
    end
    self.button:SetDurationBar(self.present.bar, barOptions)
    if db.showSealName then self.button:SetSpellName(self.present.name)
    else self.button:ClearSpellName() end
    local warningOptions = BindDurationText(self.button, self.present, db)
    self.present.status:Hide()
    self.warningText:ClearAllPoints()
    if db.displayStyle == "bar" then
        self.warningText:SetPoint("TOPLEFT", self.root, "BOTTOMLEFT", 37, -7)
    else
        self.warningText:SetPoint("TOP", self.root, "BOTTOM", 0, -25)
    end
    addon.ApplyFont(self.warningText, db, 0)
    self.warningButton:ClearDurationText()
    if warningOptions and db.showStatusText then
        self.warningButton:SetDurationText(self.warningText, warningOptions)
        self.warningText:Show()
    else self.warningText:Hide() end
    self.presence:SetAuraGroupLayout("Presence", {
        elementWidth = width + 1 + 2 * margin, elementHeight = height,
    })
    -- Hiding the missing clip's contents leaves nothing on screen without a
    -- seal; the native presence gate still decides when they would appear.
    self.missing.frame:SetAlpha(db.hideWhenMissing and 0 or 1)
    -- Restart the combat alert with the chosen parts on the next update.
    self.alertGlow, self.alertBounce = addon.MissingAlertParts(db)
    self.glow:Hide()
    self.pulse:Stop()
    self.bounce:Stop()
    self.combat = nil
    self.container:SetEnabled(true)
    self.presence:SetEnabled(true)
    return true
end

function methods:UpdateCombat(combat)
    if self.combat == combat then return end
    self.combat = combat
    if combat then
        -- Animation lives in the native missing clip. Its pixels remain clipped
        -- while a seal exists; Lua never reads whether the missing clip is visible.
        if self.alertGlow then
            self.glow:Show()
            self.pulse:Play()
        end
        if self.alertBounce then self.bounce:Play() end
    else
        self.glow:Hide()
        self.pulse:Stop()
        self.bounce:Stop()
    end
end
