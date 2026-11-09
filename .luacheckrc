-- Lints the addon only. Tests stub the WoW API with globals on purpose.
std = "lua51"
max_line_length = false

ignore = {
    "212/self", -- Frame methods keep self for a consistent signature.
    "431",      -- Short-lived locals may reuse an outer name.
}

-- Globals the addon writes.
globals = {
    "PallySealCooldownsDB",
    "SLASH_PALLYSEALCOOLDOWNS1",
    "SlashCmdList",
}

-- WoW API. Add new names here so typos still fail the lint.
read_globals = {
    "AuraContainerSortDirection",
    "AuraContainerSortMethod",
    "C_CurveUtil",
    "C_Spell",
    "C_StringUtil",
    "C_Texture",
    "C_Timer",
    "C_UnitAuras",
    "CombatLogGetCurrentEventInfo",
    "CreateColor",
    "CreateFrame",
    "CustomAuraContainerAuraProcessingPolicy",
    "DEFAULT_CHAT_FRAME",
    "DoesTemplateExist",
    "Enum",
    "GameTooltip",
    "GetBuildInfo",
    "GetCursorPosition",
    "GetTime",
    "hooksecurefunc",
    "InCombatLockdown",
    "InterfaceOptions_AddCategory",
    "InterfaceOptionsFrame_OpenToCategory",
    "issecretvalue",
    "LibStub",
    "Minimap",
    "PlaySound",
    "PlaySoundFile",
    "Settings",
    "SOUNDKIT",
    "UIParent",
    "UISpecialFrames",
    "UnitAffectingCombat",
    "UnitClass",
    "UnitGUID",
    "UnitIsDeadOrGhost",
    "wipe",
}
