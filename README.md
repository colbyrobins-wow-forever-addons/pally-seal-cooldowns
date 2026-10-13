# Pally Seal Cooldowns

Development follows [the test-before-version workflow](DEVELOPMENT.md): changes
are tracked in Git and tested in game before a new release version is assigned.

A lightweight paladin seal refresh tracker targeting WoW Forever beta interface
16001. Tracks buff expiration, rather than spell cast cooldowns: the time you
need for refreshing a seal.

The display uses a compact 56-pixel cooldown-manager-style icon with native
rounded mask and metallic border when available, a radial duration swipe,
centered countdown, and a thin duration bar. The border and timer turn red at
the refresh threshold. The seal name and status appear beneath the icon.
In combat, a confirmed missing or expired seal makes the icon glow and bounce
until a seal is detected or combat ends. Unavailable seal data does not trigger
this alert. The animation does not change the saved position.

## Install

### Diagnostic test mode

For a false missing-seal warning, run `/psc debug on`, cast a seal outside combat,
then enter combat. Compare the tracker with the actual buff, and try recasting
in combat. Run `/psc debug off`, then `/psc debug dump` to print the capture.
Share the output along with the seal/rank and whether the real buff stayed active.

Diagnostics retain the latest 100 entries, suppress unchanged polling results,
and do not print automatically during combat. The capture records resolved seal
names, client build, cast recognition, query outcomes, and timer transitions.
It does not record character names or raw API errors. `/psc debug clear` removes
the capture; enabling diagnostics starts a fresh capture. Diagnostics turn off
on reload, but the captured entries are retained in the addon's saved variables
when WoW saves them on reload/logout. This mode does not fix detection itself.

For a text file, run `/psc debug off` and `/reload` after reproducing. Export
the saved capture from a terminal with:

```powershell
python scripts/export_diagnostics.py "<client>/WTF/Account/<account>/SavedVariables/PallySealCooldowns.lua" "capture.txt"
```

The exporter reads only diagnostic strings without executing Lua or exporting
other settings. It replaces the output file on a successful export. Use the
ignored `diagnostics/` directory for local reports.

### Copy addon files

Copy the entire `PallySealCooldowns` folder into your Forever client's
`Interface/AddOns` directory. The resulting path must be
`Interface/AddOns/PallySealCooldowns/PallySealCooldowns.toc`.
Restart the client, enable **Pally Seal Cooldowns** on the character selection
AddOns screen, and log into a paladin.

## Use

Open **Options > AddOns > Pally Seal Cooldowns**, click the paladin seal icon
beside the minimap, or type `/psc` or `/psc settings` to open the same settings
page. General settings, alerts, appearance, and presets share one scrollable
view: two columns in wider windows, stacked sections in narrower windows.
Drag the minimap icon to reposition it; its position is saved.
Changes apply immediately and are saved automatically.
Enable **Small icon with horizontal timer bar** to use a 30-pixel seal icon
with a horizontal duration bar on its right. Uncheck it to restore the large
icon layout. Countdown visibility, refresh warnings, and combat animation work
in either layout; Display size scales the whole tracker.
Enable **Hide outside combat** to show the tracker only during combat. The
minimap settings button stays available. This setting is off by default.
Settings also include bar width (120–360 pixels before scaling), independent
seal-name and status-text visibility, and separate refresh and missing-seal
sounds (gentle chime, raid warning, whisper, or soft UI click). New settings use
the bundled gentle chime for refresh and raid warning for a missing seal;
existing refresh sound selections are preserved. Each alert has its own enable
and combat-only checkbox. Both default to combat-only. If refresh sounds were
previously disabled, the new missing-seal sound starts disabled too.
A refresh warning plays once per seal timer when the warning threshold is reached.
The missing-seal warning plays once for a confirmed missing or expired seal,
including combat entry without a seal, and rearms when a seal becomes active.
With combat-only enabled, it also rearms after leaving combat. Restricted aura
data and expired estimates do not trigger missing-seal sounds. Audio settings
apply even when the tracker is hidden outside combat.
Click the sound and audio-channel buttons to cycle choices. Use **Test refresh
sound** or **Test missing sound** to preview on the shared Master, SFX, or Dialog
channel. Previews work regardless of enable and combat-only settings.
The bar style uses Retail cooldown-manager bar and frame textures when present,
with a compact 220-by-30 layout, gold fill, white name, and right-aligned timer.
The window includes position lock, sound, countdown visibility, warning time,
size, and position reset. `/psc` also opens it.

Use **Appearance & presets** on the settings page for font, outline, shadow, border, and bar
texture controls. Countdown and seal-name font sizes are independent; 0 keeps
the layout's original size, and custom sizes start at 8 pixels. Left-click a
choice to advance or right-click to go back. Border colors include white,
gold, black, and paladin pink. Thickness applies to custom borders; the default
icon artwork keeps its original shape. Refresh warnings still use red.

**Default**, **Minimal**, and **High Contrast** apply built-in appearance
presets immediately, without changing timing, sounds, positioning, or visibility.
Default restores the original layout fonts and artwork.
Three additional presets are included: **Classic Gold** uses a gold tooltip
border with outlined text; **Paladin Pink** uses Arial Narrow and a pink solid
border; **Clean Text** uses Arial Narrow, text shadows, and no border. All six
preset buttons appear at the bottom of the appearance section and work without
extra media packs.

Optional **LibSharedMedia-3.0** support adds fonts, border textures, and bar
textures registered by installed media packs. The library is not bundled;
install it or use another addon that provides it, alongside your media packs.
Choices refresh when the settings page opens. Missing media falls back to
the original appearance while retaining the saved choice. Masque support is
not included in this release.

On older clients, the page uses the legacy AddOns options category. If neither
settings API is available, `/psc` opens the unified page in a standalone window.
Open settings outside combat; registration deferred during combat is retried
after combat ends.

- `/psc unlock`: drag the tracker with the left mouse button.
- `/psc lock`: lock its position (default).
- `/psc warn 5`: refresh warning threshold, from 1 to 30 seconds.
- `/psc counter refresh`: hide the countdown number until the warning threshold.
- `/psc counter always`: always show the countdown number (default).
- `/psc sound`: toggle the refresh warning sound (default on); the missing-seal sound has a separate settings checkbox.
- `/psc scale 1`: set size, from 0.5 to 2.
- `/psc reset`: reset position and size.
- `/psc status`: report the client version, build, interface, and aura API.

The display turns red when a seal needs refreshing and shows **CAST A SEAL**
when none is found. Recasting or switching seals starts a new cast estimate;
readable buff data corrects the timer both in and out of combat.
Base spell IDs resolve localized names for Righteousness, Command, Justice,
Light, Wisdom, the Crusader, and Fury.
Settings use WoW SavedVariables and are written on logout or `/reload`.

## Beta limitations and verification

The combat cast tracking has been confirmed working by the author in the
Forever beta client (1.60.1.70170). Verify your
interface with `/psc status`; future beta builds may require TOC/API changes.
The addon queries known seals by name rather than enumerating all buffs, which
can encounter unrelated secret auras. Scans run on aura events; frame updates
refresh the display every 0.1 seconds and retry aura scans every 0.5 seconds,
including during combat. Readable cancellations, replacements, and duration
changes reconcile the timer. Readable removal events for the tracked aura also
clear its timer when a fresh aura query is blocked.
Successful player seal casts immediately start/reset the timer and stop the
missing-seal animation. Cast estimates use the last observed
duration for that seal, or the Forever beta baseline of 30 seconds until a
duration is learned. **ESTIMATED TIMER** identifies a countdown retained while
live data is restricted. A successful cast has a 0.5-second grace period for
the aura API to catch up before an empty or stale snapshot replaces it.
If both aura queries and removal information are restricted, early cancellation,
dispels, or changes cannot be confirmed and the estimate may differ from the buff.
Expired estimates show unavailable status instead of a confirmed missing-seal
alert. If aura timing is secret and no matching live estimate remains, the addon
displays **Timing unavailable**. Threshold
warnings require readable timing. If seal names are restricted, it displays
**Seal status unavailable**, rather than claiming that no seal is active.
It never casts spells automatically.

Manual checks before relying on it:

1. Cast each learned seal and compare the countdown with its buff tooltip.
2. Recast, switch seals, and cancel the buff; confirm immediate updates.
3. In combat, check expiration warnings and any restricted-data messages.
4. Confirm only one sound per expiration and a fresh sound after recasting.
5. Move/scale the frame, `/reload`, and confirm saved settings.
6. Log into a non-paladin and confirm the tracker stays hidden.

Focused timer regression tests: `lua tests/seal_logic_test.lua` (Lua 5.1 or newer).

API reference:
[Blizzard UI aura API declarations](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).
