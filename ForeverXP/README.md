# Forever XP

Adds always-visible XP text to Blizzard's existing XP bar in WoW Forever beta
(interface 16001). Works independently of Pally Seal Cooldowns, on any class.

Example: `12,500 / 20,000 XP -- 62.5% -- 7,500 XP till level`

The denominator is the total XP required for the level; the final number is
remaining XP. Updates on XP gains, level changes, login, and Blizzard text
refreshes. Uses the existing font and position. Keeps the bar's fill, rested XP,
tooltip, and visibility under Blizzard's control. No settings or dependencies.
Disable Forever XP and reload to restore Blizzard's text behavior.

## Installation for testing

Copy this `ForeverXP` folder into the Forever beta client's `Interface/AddOns`
folder. Enable **Forever XP** on the character screen and log in (or reload
if the client already recognizes the addon). It requires Blizzard's default
XP bar; replacement action-bar addons are not supported. Both the newer
status-tracking containers and the older `MainMenuExpBar` are supported.

Run `/foreverxp` to refresh attachment and report the number of XP bars found,
their shown state, and current XP. If XPForever is loaded, the command also
reports that conflict: XPForever hides Blizzard's XP bar. Disable XPForever and
reload when using this addon. A shown bar may still be transparent because of
another addon; this addon does not override other addons' bar visibility.

## Development and verification

This is an unversioned development addon, tracked by the containing Git
repository. No release archive or deployment is implied by its creation.
Run `tests/forever_xp_test.lua` from the repository root with Lua 5.1.

Local tests cover formatting, invalid/restricted inputs, XP gains, level
rollover, default text overwrites, hover hiding, bar visibility, late loading,
and attachment deferred during combat. Actual Forever beta behavior and visual
fit still require in-game testing.

In-game checklist: gain XP from kills and quests, level up, hover/leave the bar,
toggle XP text settings, track reputation, enter combat, and reload. Check that
the label stays legible and that the tooltip/rested fill still work. At maximum
level or with XP disabled, Blizzard may hide the bar; this addon does not force
it visible. Record the Git commit, client build, results, and acceptance before
requesting a version or release.

API reference inspected: Blizzard's mirrored
[beta XP bar definition](https://github.com/Gethe/wow-ui-source/blob/classic_beta/Interface/AddOns/Blizzard_ActionBar/Classic/MainMenuBar.xml).
