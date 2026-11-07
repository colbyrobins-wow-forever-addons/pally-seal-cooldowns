local addonName, addon = ...
local frame = CreateFrame("Frame", "PallySealCooldownsFrame", UIParent)
frame:Hide()
local db, activeAura, warnedKey
local sealNames = {}
local sealSpellIDs = {}
-- Base spell IDs resolve localized names; all ranks share those names.
local sealIDs = {20154, 21084, 20375, 20164, 20165, 20166, 21082, 20163}
local elapsedTotal = 0
local pollElapsed = 0
local accessRestricted = false
local combatLookupUncertain = false
local inCombat = false
local missingAlertPlaying = false
local missingSoundPlayed = false
local ApplyLayout
local nativeDisplay
local pendingNativeSettings = false
local nativeAttempted = false
local HideLegacyDisplay
local snapped = false
local worldEntered = false
local snapWarned = false
local appliedIconSize

local function Message(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd36aPally Seals:|r " .. text)
end

local function BuildSealNames()
    wipe(sealNames)
    wipe(sealSpellIDs)
    for _, spellID in ipairs(sealIDs) do
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
        if addon.IsReadable(name) and type(name) == "string" then
            sealNames[name], sealSpellIDs[spellID] = true, true
        end
    end
end

local function ApplyPosition()
    if nativeDisplay and InCombatLockdown and InCombatLockdown() then
        pendingNativeSettings = true
        return
    end
    frame:ClearAllPoints()
    frame:SetScale(db.scale)
    snapped = addon.SnapToCooldownViewer(frame, db)
    if not snapped then frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y) end
    -- Blizzard's viewer may load after this addon; only report once the world is up.
    if db.snapToCDM and not snapped and worldEntered and not snapWarned then
        snapWarned = true
        Message("Essential Cooldowns bar not found; using the saved position. "
            .. "Enable the Cooldown Manager in Options to snap.")
    end
    if snapped then snapWarned = false end
    frame:EnableMouse(not db.locked and not snapped)
    appliedIconSize = db.displayStyle == "essential" and addon.IconLayoutSize(db) or nil
    if ApplyLayout then ApplyLayout() end
    if nativeDisplay then
        nativeDisplay:Apply(db)
        HideLegacyDisplay()
        pendingNativeSettings = false
    end
end

frame:SetSize(56, 56)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetColorTexture(0.03, 0.03, 0.04, 0.95)
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 2, -2)
icon:SetPoint("BOTTOMRIGHT", -2, 2)

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

if HasAtlas("UI-HUD-CoolDownManager-Mask") and frame.CreateMaskTexture then
    local mask = frame:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
    icon:AddMaskTexture(mask)
end

-- Keep text and border above the child cooldown swipe.
local overlay = CreateFrame("Frame", nil, frame)
overlay:SetAllPoints()
overlay:SetFrameLevel(10)
local border = overlay:CreateTexture(nil, "OVERLAY")
local customBorder = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
customBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
customBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
customBorder:EnableMouse(false)
if HasAtlas("UI-HUD-CoolDownManager-IconOverlay") then
    border:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
    border:SetPoint("TOPLEFT", -9, 8)
    border:SetPoint("BOTTOMRIGHT", 9, -8)
else
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("TOPLEFT", -9, 9)
    border:SetPoint("BOTTOMRIGHT", 9, -9)
end
local title = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", frame, "BOTTOM", 0, -8)
title:SetWidth(180)
title:SetJustifyH("CENTER")
title:SetShadowOffset(1, -1)
local status = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
status:SetPoint("TOP", title, "BOTTOM", 0, -3)
status:SetWidth(180)
status:SetJustifyH("CENTER")
status:SetShadowOffset(1, -1)
local timer = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightHugeOutline")
timer:SetPoint("CENTER", frame, "CENTER", 0, 0)
local bar = CreateFrame("StatusBar", nil, frame)
bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
bar:SetSize(56, 2)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
local barBackground = bar:CreateTexture(nil, "BACKGROUND")
local nativeBar = HasAtlas("UI-HUD-CoolDownManager-Bar")
local nativeBarBackground = HasAtlas("UI-HUD-CoolDownManager-Bar-BG")
if nativeBarBackground then
    barBackground:SetAtlas("UI-HUD-CoolDownManager-Bar-BG")
else
    barBackground:SetColorTexture(0.06, 0.07, 0.09, 0.95)
end
barBackground:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
barBackground:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -7)
local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
cooldown:SetAllPoints(icon)
cooldown:SetFrameLevel(5)
cooldown:SetDrawEdge(false)
cooldown:SetHideCountdownNumbers(true)
cooldown:SetReverse(true)
cooldown:SetSwipeColor(0, 0, 0, 0.65)

local glow = overlay:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetVertexColor(1, 0.65, 0.1)
glow:SetPoint("TOPLEFT", -22, 22)
glow:SetPoint("BOTTOMRIGHT", 22, -22)
glow:Hide()
local pulse = glow:CreateAnimationGroup()
pulse:SetLooping("BOUNCE")
local fade = pulse:CreateAnimation("Alpha")
fade:SetFromAlpha(0.35)
fade:SetToAlpha(1)
fade:SetDuration(0.45)
fade:SetSmoothing("IN_OUT")
-- Animation offsets do not change the frame's saved anchor or position.
local bounce = frame:CreateAnimationGroup()
bounce:SetLooping("BOUNCE")
local lift = bounce:CreateAnimation("Translation")
lift:SetOffset(0, 8)
lift:SetDuration(0.3)
lift:SetSmoothing("IN_OUT")

ApplyLayout = function()
    icon:ClearAllPoints()
    title:ClearAllPoints()
    timer:ClearAllPoints()
    status:ClearAllPoints()
    bar:ClearAllPoints()
    border:ClearAllPoints()
    glow:ClearAllPoints()
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -8, 7)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 8, -7)
    glow:SetPoint("TOPLEFT", icon, "TOPLEFT", -20, 20)
    glow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 20, -20)
    if db.displayStyle == "bar" then
        frame:SetSize(db.barWidth + 32, 30)
        background:Hide()
        icon:SetSize(30, 30)
        icon:SetPoint("LEFT", frame, "LEFT")
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", icon, "TOPLEFT", -6, 5)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -5)
        bar:SetSize(db.barWidth, 19)
        bar:SetPoint("LEFT", icon, "RIGHT", 2, 0)
        bar:SetAlpha(1)
        if nativeBar then
            bar:SetStatusBarTexture(nativeBar.file)
            bar:GetStatusBarTexture():SetAtlas("UI-HUD-CoolDownManager-Bar")
        end
        barBackground:Show()
        title:SetPoint("LEFT", bar, "LEFT", 5, 0)
        title:SetWidth(db.barWidth - 50)
        title:SetFontObject("GameFontHighlightSmall")
        title:SetTextColor(1, 1, 1)
        title:SetJustifyH("LEFT")
        timer:SetFontObject("GameFontHighlightOutline")
        timer:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
        status:SetFontObject("GameFontDisableSmall")
        status:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 5, -7)
        status:SetJustifyH("LEFT")
    else
        local iconSize = addon.IconLayoutSize(db)
        -- The matched style has no padding, so snapped icons sit flush.
        local essential = db.displayStyle == "essential"
        local frameSize = essential and iconSize or 56
        frame:SetSize(frameSize, frameSize)
        background:SetShown(not essential)
        barBackground:Hide()
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("CENTER", frame, "CENTER")
        local outsetX = math.floor(8 * iconSize / 52 + 0.5)
        local outsetY = math.floor(7 * iconSize / 52 + 0.5)
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", icon, "TOPLEFT", -outsetX, outsetY)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", outsetX, -outsetY)
        bar:SetSize(frameSize, 2)
        bar:SetAlpha(db.showIconBar and 1 or 0)
        bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
        title:SetPoint("TOP", frame, "BOTTOM", 0, -8)
        title:SetWidth(180)
        title:SetFontObject("GameFontNormalSmall")
        title:SetTextColor(1, 0.82, 0.5)
        title:SetJustifyH("CENTER")
        timer:SetFontObject("GameFontHighlightHugeOutline")
        timer:SetPoint("CENTER", frame, "CENTER")
        status:SetPoint("TOP", title, "BOTTOM", 0, -3)
        status:SetFontObject("GameFontNormalSmall")
        status:SetJustifyH("CENTER")
    end
    addon.ApplyFont(title, db, db.nameSize)
    addon.ApplyFont(timer, db, db.timerSize)
    addon.ApplyFont(status, db, 0)
    local edge = addon.MediaPath("border", db.border)
    border:SetShown(db.border ~= "none" and not edge)
    customBorder:SetShown(edge ~= nil)
    customBorder:SetBackdrop(edge and {edgeFile = edge, edgeSize = db.borderSize} or nil)
    local texture = addon.MediaPath("statusbar", db.statusbar)
    if texture then bar:SetStatusBarTexture(texture) end
    -- Restart a running combat alert with the chosen parts on the next render.
    if missingAlertPlaying then
        pulse:Stop()
        bounce:Stop()
        glow:Hide()
        missingAlertPlaying = false
    end
end

local function UpdateMissingAlert(state)
    local shouldPlay = inCombat and state == "missing" and not accessRestricted
    if shouldPlay == missingAlertPlaying then return end
    missingAlertPlaying = shouldPlay
    if shouldPlay then
        local useGlow, useBounce = addon.MissingAlertParts(db)
        if useGlow then
            glow:Show()
            pulse:Play()
        end
        if useBounce then bounce:Play() end
    else
        pulse:Stop()
        bounce:Stop()
        glow:Hide()
    end
end

local function SetVisualState(state)
    UpdateMissingAlert(state)
    local warning = state == "refresh" or state == "missing"
    icon:SetDesaturated(state == "missing" or state == "restricted")
    border:SetVertexColor(addon.BorderRGB(db, warning))
    customBorder:SetBackdropBorderColor(addon.BorderRGB(db, warning))
    if warning then
        timer:SetTextColor(addon.WarningRGB(db))
        status:SetTextColor(addon.WarningRGB(db))
    else
        timer:SetTextColor(1, 1, 1)
        status:SetTextColor(1, 0.82, 0.5)
    end
    -- Only the missing state hides its own text; other states keep the base toggles.
    local missingText = state ~= "missing" or db.showMissingText
    title:SetShown(db.showSealName and missingText)
    status:SetShown(db.showStatusText and missingText)
    barBackground:SetVertexColor(1, warning and 0.45 or 1, warning and 0.35 or 1)
end
frame:SetScript("OnDragStart", function(self)
    if not db.locked and not snapped then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local centerX, centerY = self:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    local scale = self:GetScale()
    db.x, db.y = centerX * scale - parentX, centerY * scale - parentY
    ApplyPosition()
end)

local function UpdateSoundAlerts(state)
    if state == "active" or state == "refresh" or state == "permanent"
        or (db.missingCombatOnly and not inCombat) then
        missingSoundPlayed = false
    end
    if state == "missing" and db.missingSound and not missingSoundPlayed
        and (not db.missingCombatOnly or inCombat) then
        missingSoundPlayed = true
        addon.PlayWarning(db, "missing")
    end
    if state == "refresh" and db.sound and (not db.refreshCombatOnly or inCombat) then
        local key = activeAura.name .. ":" .. activeAura.expirationTime
        if warnedKey ~= key then
            warnedKey = key
            addon.PlayWarning(db)
        end
    end
end

HideLegacyDisplay = function()
    for _, region in ipairs({background, icon, overlay, bar, cooldown}) do region:Hide() end
    pulse:Stop()
    bounce:Stop()
    missingAlertPlaying = false
end

local function Render()
    if nativeDisplay then
        nativeDisplay:UpdateCombat(inCombat)
        frame:SetShown(not db.hideOutOfCombat or inCombat)
        -- Native widgets own presentation, but successful casts still provide
        -- a refresh deadline when combat aura timing is unavailable. Confirmed
        -- removals clear activeAura; an unobservable early removal can leave
        -- this reminder scheduled until reconciliation or the next cast.
        if activeAura then
            local state = addon.GetState(activeAura.duration, activeAura.expirationTime, GetTime(), db.threshold)
            if state == "active" or state == "refresh" or state == "permanent" then
                UpdateSoundAlerts(state)
            end
        elseif not inCombat and not accessRestricted and not activeAura then
            UpdateSoundAlerts("missing")
        end
        return
    end
    local state, remaining
    if activeAura then
        state, remaining = addon.GetState(activeAura.duration,
            activeAura.expirationTime, GetTime(), db.threshold)
        if state == "missing" and activeAura.estimated then state = "restricted" end
    else
        state = accessRestricted and "restricted" or "missing"
    end
    UpdateSoundAlerts(state)
    title:SetShown(db.showSealName)
    status:SetShown(db.showStatusText)
    if (db.hideOutOfCombat and not inCombat) or (state == "missing" and db.hideWhenMissing) then
        UpdateMissingAlert("active")
        frame:Hide()
        return
    end
    frame:Show()
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    status:SetText("")
    if not activeAura then
        if accessRestricted then
            title:SetText("Seal status unavailable")
            timer:SetText("?")
            status:SetText("Beta API restricted")
            SetVisualState("restricted")
            icon:SetTexture("Interface\\Icons\\Spell_Holy_SealOfMight")
            return
        end
        title:SetText("No active seal")
        timer:SetText(addon.MissingSymbol(db))
        status:SetText("CAST A SEAL")
        SetVisualState("missing")
        icon:SetTexture(addon.MissingIconPath(db))
        return
    end
    title:SetText(activeAura.name)
    icon:SetTexture(activeAura.icon)
    if state == "restricted" and activeAura.estimated then
        cooldown:Hide()
    end
    SetVisualState(state)
    if state == "restricted" then
        timer:SetText("?")
        status:SetText("Timing unavailable")
    elseif state == "permanent" then
        timer:SetText("")
        status:SetText("ACTIVE")
        bar:SetValue(1)
        bar:SetStatusBarColor(1, 0.72, 0.25)
    elseif state == "missing" then
        timer:SetText(addon.MissingSymbol(db))
        status:SetText("REFRESH SEAL")
    else
        if activeAura.estimated then status:SetText("ESTIMATED TIMER") end
        local fraction = remaining / activeAura.duration
        bar:SetValue(db.barCountdown and fraction or 1 - fraction)
        if state == "refresh" then bar:SetStatusBarColor(addon.WarningRGB(db))
        else bar:SetStatusBarColor(1, 0.72, 0.25) end
        if db.counterMode == "refresh" and state == "active" then
            timer:SetText("")
        else
            timer:SetText(remaining < 10 and string.format("%.1f", remaining)
                or tostring(math.ceil(remaining)))
        end
        if state == "refresh" then
            status:SetText("REFRESH SEAL")
        end
    end
end

local function ScanAuras(addedSeal)
    local current, diagnostic
    current, accessRestricted, diagnostic = addon.FindSeal(sealNames,
        C_UnitAuras.GetAuraDataBySpellName, addon.DebugEnabled())
    if addedSeal then current = addedSeal end
    if addon.DebugEnabled() then
        addon.DebugProbe(db, inCombat, current or activeAura, sealSpellIDs)
    end
    -- Forever can return nil for an active seal throughout combat. Once a
    -- known seal disappears from queries, absence alone cannot confirm removal.
    if current then
        combatLookupUncertain = false
    elseif inCombat and (activeAura or combatLookupUncertain) then
        combatLookupUncertain = true
        accessRestricted = true
    end
    local previous = diagnostic and addon.DebugAura(activeAura)
    activeAura = addon.ResolveSeal(activeAura, current, accessRestricted, GetTime())
    if diagnostic then
        addon.DebugRecord(db, "scan", "combat=" .. tostring(inCombat)
            .. " queries=[" .. diagnostic .. "] previous=" .. previous
            .. " uncertain=" .. tostring(combatLookupUncertain)
            .. " resolved=" .. addon.DebugAura(activeAura))
    end
    cooldown:Hide()
    if activeAura then
        if not activeAura.estimated and addon.IsFiniteNumber(activeAura.duration)
            and activeAura.duration > 0 then
            db.sealDurations[activeAura.name] = activeAura.duration
        end
        local state = addon.GetState(activeAura.duration,
            activeAura.expirationTime, GetTime(), db.threshold)
        if state == "active" or state == "refresh" then
            cooldown:SetCooldown(activeAura.expirationTime - activeAura.duration,
                activeAura.duration)
            if not nativeDisplay then cooldown:Show() end
        end
    end
    Render()
end

frame:SetScript("OnUpdate", function(_, elapsed)
    if not db then return end
    pollElapsed = pollElapsed + elapsed
    if pollElapsed >= 0.5 then
        pollElapsed = 0
        ScanAuras()
    end
    elapsedTotal = elapsedTotal + elapsed
    if elapsedTotal < 0.1 then return end
    elapsedTotal = 0
    Render()
end)

-- Blizzard relayouts its bar often; re-apply only when the matched size changes.
-- Position needs no work here because the snap anchor follows the bar natively.
local function RefreshCooldownViewer()
    if not db or db.displayStyle ~= "essential" or db.cdmIconSize > 0 then return end
    if addon.IconLayoutSize(db) ~= appliedIconSize then ApplyPosition() end
end

local function ApplySettings()
    ApplyPosition()
    Render()
end

local function OpenSettings()
    if not db then return end
    addon.OpenSettings(db, ApplySettings)
end

SLASH_PALLYSEALCOOLDOWNS1 = "/psc"
SlashCmdList.PALLYSEALCOOLDOWNS = function(input)
    if not db then return end
    local command, argument = input:match("^(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "" or command == "settings" then
        OpenSettings()
    elseif command == "debug" then
        addon.DebugCommand(db, argument, Message, sealNames)
        if argument:lower() == "on" then ScanAuras() end
    elseif command == "native" then
        addon.NativePrototypeCommand(argument, db, Message)
    elseif command == "lock" or command == "unlock" then
        db.locked = command == "lock"
        ApplyPosition()
    elseif command == "sound" then
        db.sound = not db.sound
        Message("Refresh sound " .. (db.sound and "enabled." or "disabled."))
    elseif command == "style" then
        argument = argument:lower()
        if argument ~= "icon" and argument ~= "bar" and argument ~= "essential" then
            Message("Use /psc style icon, /psc style bar, or /psc style essential.")
            return
        end
        db.displayStyle = argument
        ApplyPosition()
        Render()
    elseif command == "counter" then
        argument = argument:lower()
        if argument ~= "always" and argument ~= "refresh" then
            Message("Use /psc counter refresh or /psc counter always.")
            return
        end
        db.counterMode = argument
        if nativeDisplay then ApplyPosition() end
        Render()
        Message(argument == "refresh" and "Countdown appears at the refresh warning threshold."
            or "Countdown is always visible.")
    elseif command == "warn" or command == "scale" then
        local value = tonumber(argument)
        local minimum, maximum = 1, 30
        if command == "scale" then minimum, maximum = 0.5, 2 end
        if not value or value ~= value or value < minimum or value > maximum then
            Message(command .. " requires a number from " .. minimum .. " to " .. maximum .. ".")
            return
        end
        if command == "warn" then db.threshold = value else db.scale = value end
        ApplyPosition()
    elseif command == "reset" then
        db.x, db.y, db.scale = 0, -160, 1
        ApplyPosition()
    elseif command == "status" then
        local version, build, _, interface = GetBuildInfo()
        Message(string.format("Client %s / build %s / interface %s; aura API %s.",
            version, build, interface, C_UnitAuras and "available" or "missing"))
        Message("Essential Cooldowns bar " .. (addon.CooldownViewer() and "found" or "not found")
            .. (db.snapToCDM and ("; snap " .. (snapped and "active" or "inactive")) or "")
            .. (db.displayStyle == "essential" and ("; icon size " .. addon.IconLayoutSize(db)) or "") .. ".")
    else
        Message("/psc unlock | lock | warn 5 | counter refresh/always | sound | scale 1 | reset | status | debug | native")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if event == "ADDON_LOADED" then
        if unit == "Blizzard_CooldownViewer" and db then
            addon.WatchCooldownViewer(RefreshCooldownViewer)
            ApplyPosition()
            return
        end
        if unit ~= addonName then return end
        local _, class = UnitClass("player")
        if class ~= "PALADIN" then frame:UnregisterAllEvents(); return end
        PallySealCooldownsDB = type(PallySealCooldownsDB) == "table" and PallySealCooldownsDB or {}
        db = PallySealCooldownsDB
        addon.NormalizeAppearance(db)
        addon.NormalizeCooldownManager(db)
        addon.NormalizeDisplayOptions(db)
        for key, value in pairs({x = 0, y = -160, scale = 1, threshold = 5}) do
            if type(db[key]) ~= "number" or db[key] ~= db[key] then db[key] = value end
        end
        db.scale = math.max(0.5, math.min(2, db.scale))
        db.threshold = math.max(1, math.min(30, db.threshold))
        db.sealDurations = type(db.sealDurations) == "table" and db.sealDurations or {}
        db.locked = db.locked ~= false
        db.sound = db.sound ~= false
        db.counterMode = db.counterMode == "refresh" and "refresh" or "always"
        db.hideOutOfCombat = db.hideOutOfCombat == true
        db.showSealName = db.showSealName ~= false
        db.showStatusText = db.showStatusText ~= false
        db.barCountdown = db.barCountdown == true
        if type(db.barWidth) ~= "number" or db.barWidth ~= db.barWidth then db.barWidth = 188 end
        db.barWidth = math.max(120, math.min(360, db.barWidth))
        db.refreshCombatOnly = db.refreshCombatOnly ~= false
        db.missingCombatOnly = db.missingCombatOnly ~= false
        if db.missingSound == nil then db.missingSound = db.sound end
        db.missingSound = db.missingSound == true
        for key, fallback in pairs({soundChoice = addon.SoundDefaults.refresh,
            missingSoundChoice = addon.SoundDefaults.missing}) do
            if not addon.IsValidSoundChoice(db[key]) then db[key] = fallback end
        end
        if db.soundChannel ~= "Master" and db.soundChannel ~= "SFX"
            and db.soundChannel ~= "Dialog" then db.soundChannel = "Master" end
        if type(db.minimapAngle) ~= "number" or db.minimapAngle ~= db.minimapAngle
            or db.minimapAngle == math.huge or db.minimapAngle == -math.huge then
            db.minimapAngle = 225
        end
        if not C_UnitAuras or not C_UnitAuras.GetAuraDataBySpellName then
            Message("This client lacks the required aura API; tracker disabled.")
            frame:UnregisterAllEvents()
            return
        end
        BuildSealNames()
        ApplyPosition()
        if addon.CreateNativeDisplay then
            nativeDisplay = addon.CreateNativeDisplay(frame, db, Message)
            nativeAttempted = not (InCombatLockdown and InCombatLockdown())
            if nativeDisplay then HideLegacyDisplay() end
        end
        addon.CreateMinimapButton(db, OpenSettings)
        addon.RegisterSettings(db, ApplySettings)
        frame:RegisterEvent("UNIT_AURA")
        if type(CombatLogGetCurrentEventInfo) == "function" and type(UnitGUID) == "function" then
            addon.CombatLogAvailable = pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED")
        end
        frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("SPELLS_CHANGED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        for _, cooldownEvent in ipairs({"EDIT_MODE_LAYOUTS_UPDATED", "COOLDOWN_VIEWER_DATA_LOADED"}) do
            pcall(frame.RegisterEvent, frame, cooldownEvent)
        end
        addon.WatchCooldownViewer(RefreshCooldownViewer)
        inCombat = UnitAffectingCombat("player") == true
        frame:Show()
        ScanAuras()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" or not addon.IsReadable(spellID)
            or type(spellID) ~= "number" then return end
        local name = C_Spell.GetSpellName(spellID)
        -- 20424 is the Command damage effect, not application of its buff.
        local recognized = spellID ~= 20424 and addon.IsReadable(name)
            and type(name) == "string" and sealNames[name] == true
        if addon.DebugEnabled() and addon.IsReadable(name) and type(name) == "string" then
            addon.DebugRecord(db, "cast", "spell=" .. spellID .. " name=" .. name
                .. " recognized=" .. tostring(recognized))
        end
        if not recognized then return end
        sealSpellIDs[spellID] = true
        local duration = db.sealDurations[name]
        if not addon.IsFiniteNumber(duration) or duration <= 0 then
            duration = 30 -- Forever beta baseline; replaced by observed aura duration.
        end
        local now = GetTime()
        activeAura = {
            name = name,
            icon = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
                or "Interface\\Icons\\Spell_Holy_SealOfMight",
            duration = duration,
            expirationTime = now + duration,
            castTime = now,
            estimated = true,
        }
        accessRestricted, warnedKey = false, nil
        cooldown:SetCooldown(now, duration)
        if not nativeDisplay then cooldown:Show() end
        Render()
    elseif event == "UNIT_AURA" then
        if unit == "player" then
            if addon.DebugEnabled() then
                addon.DebugRecord(db, "aura-event", addon.DebugAuraUpdate(castGUID))
            end
            local addedSeal = addon.FindAddedSeal(sealNames, castGUID)
            if addon.WasSealRemoved(activeAura, castGUID) then
                addon.DebugRecord(db, "removal", "source=UNIT_AURA")
                activeAura = nil
                combatLookupUncertain = false
                accessRestricted = false
                cooldown:Hide()
            end
            if addedSeal then addon.DebugRecord(db, "addition", addon.DebugAura(addedSeal)) end
            ScanAuras(addedSeal)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not activeAura or not addon.CombatLogAvailable then return end
        local data = {pcall(CombatLogGetCurrentEventInfo)}
        local ok, playerGUID = pcall(UnitGUID, "player")
        if data[1] and ok and addon.IsSealCombatRemoval(activeAura,
            data[3], playerGUID, data[9], data[14], data[16]) then
            addon.DebugRecord(db, "removal", "source=combat-log")
            activeAura = nil
            combatLookupUncertain, accessRestricted = false, false
            cooldown:Hide()
            Render()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        if addon.DebugEnabled() then
            addon.DebugRecord(db, "combat", "enter previous=" .. addon.DebugAura(activeAura))
        end
        inCombat = true
        ScanAuras()
        Render()
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
        addon.DebugRecord(db, "event", event)
        combatLookupUncertain = false
        if not nativeAttempted and addon.CreateNativeDisplay
            and not (InCombatLockdown and InCombatLockdown()) then
            nativeAttempted = true
            nativeDisplay = addon.CreateNativeDisplay(frame, db, Message)
            if nativeDisplay then HideLegacyDisplay() end
        end
        if nativeDisplay and pendingNativeSettings then ApplyPosition() end
        addon.RegisterSettings(db, ApplySettings)
        if event == "PLAYER_ENTERING_WORLD" then
            worldEntered = true
            addon.WatchCooldownViewer(RefreshCooldownViewer)
            ApplyPosition()
        end
        inCombat = event == "PLAYER_ENTERING_WORLD" and UnitAffectingCombat("player") == true
        ScanAuras()
    elseif event == "EDIT_MODE_LAYOUTS_UPDATED" or event == "COOLDOWN_VIEWER_DATA_LOADED" then
        addon.WatchCooldownViewer(RefreshCooldownViewer)
        ApplyPosition()
    elseif event == "SPELLS_CHANGED" then
        BuildSealNames()
        ScanAuras()
    elseif event ~= "UNIT_AURA" or unit == "player" then
        ScanAuras()
    end
end)
