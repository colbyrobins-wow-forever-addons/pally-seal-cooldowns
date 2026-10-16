# Forever XP

Adds always-visible XP text to Blizzard's existing XP bar in WoW Forever beta
(interface 16001). Works independently of Pally Seal Cooldowns, on any class.

Always displayed: `12,500 / 20,000 XP • 62.5% • 7,500 to level 22`

The bar has one display format. Hovering opens the detailed tooltip without
changing the bar text. Previous compact/full preferences are removed automatically.

The denominator is the total XP required for the level; the final number is
remaining XP. Updates on XP gains, level changes, login, and Blizzard text
refreshes. Gold percentage, soft-white numbers, a thin outline, and subtle
shadow improve readability. Keeps the bar's native fill, rested indicator,
position, and visibility. The expanded tooltip shows current/required XP,
percentage, XP to next level, and exact rested bonus XP.
The tooltip uses Blizzard's default screen anchor rather than floating above the bar.
Disable Forever XP and reload to restore Blizzard's text behavior.

## Display commands

- `/foreverxp tall`: increase the bar and fill to at least 18 pixels.
- `/foreverxp normal`: restore the original bar height (default).

Choices persist across reloads. Height changes requested during combat apply
after combat ends. The taller layout needs testing with your action-bar and
reputation layout; use `normal` to revert. There are no addon dependencies.

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
attachment deferred during combat, tooltips, persistent full details during hover,
and deferred/restored heights. Actual Forever beta behavior and visual
fit still require in-game testing.

In-game checklist: gain XP from kills and quests, level up, hover/leave the bar,
toggle XP text settings, track reputation, enter combat, and reload. Check that
the label stays legible and that the tooltip/rested fill still work. At maximum
level or with XP disabled, Blizzard may hide the bar; this addon does not force
it visible. Record the Git commit, client build, results, and acceptance before
requesting a version or release.

API reference inspected: Blizzard's mirrored
[beta XP bar definition](https://github.com/Gethe/wow-ui-source/blob/classic_beta/Interface/AddOns/Blizzard_ActionBar/Classic/MainMenuBar.xml).
