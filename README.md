# Pally Seal Cooldowns

Development follows [the test-before-version workflow](DEVELOPMENT.md): changes
are tracked in Git and tested in game before a new release version is assigned.

Version **0.1.24** uses Blizzard-managed aura displays for the main
icon and bar when supported by the client. Seal visibility, name, countdown, and
bar progress update natively, including removal during restricted combat. The
missing-seal icon/text and combat animation use native layout clipping, without
reading the restricted buff state in Lua. No `/psc native on` command is needed
for the main tracker. That command retains the separate diagnostic prototype.

Layout and appearance changes made during combat apply after combat ends.
Saved position, scale, layout, font, border, bar texture, text visibility, and
refresh-only countdown settings remain supported. Unsupported clients retain
the older estimated tracker described below.

Refresh sounds use observed timing or a
successful cast's estimated deadline when combat timing becomes unavailable.
An early removal hidden by the client can still leave that reminder scheduled;
readable removal cancels it, and a new seal cast replaces the deadline.
Refresh sounds default to combat-only; uncheck **Refresh sound only in combat**
to hear them outside combat. Sound previews still work. Automatic cancellation/
dispel sounds and combat-entry missing sounds are pending native sound
integration; they are not driven by the restricted native display. The
missing-seal sound plays once outside combat after a seal ends, including one
lost during combat. It stays quiet at login until a seal has been active, and
when a seal is lost to death.
**Missing sound only in combat** applies only to the older tracker, so it is
hidden on this display.

A lightweight paladin seal refresh tracker targeting WoW Forever beta interface
16001. Tracks buff expiration, rather than spell cast cooldowns: the time you
need for refreshing a seal.

The display uses a compact 52-pixel cooldown-manager-style icon with native
rounded mask and metallic border when available, a radial duration swipe,
centered countdown, and a thin duration bar. The border and timer turn the
warning color (red by default) at the refresh threshold. The seal name and
status appear beneath the icon.
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

The compatibility probe runs only with diagnostics enabled. It compares seal
lookups by spell ID (including ranks cast this session) and by a known aura
instance ID, recording safe found/empty/restricted/error results. Cast a seal
outside combat first to establish an instance ID, enter combat, wait two seconds,
then cancel the buff and wait two seconds. Separately cast and cancel in combat
to test spell-ID lookups without a precombat instance. Probes do not change the
timer or infer removal from empty results. Stop diagnostics and logout to save.

### Native seal display prototype

Outside combat, use `/psc native on` to show a second icon labelled
**NATIVE SEAL TEST**, 150 pixels to the right of the saved tracker position.
Blizzard manages this icon's seal selection, cooldown, name, and visibility;
the addon never reads its restricted state. Cancel/dispel the seal in combat
and check whether this second icon disappears immediately. The existing tracker
remains available for comparison. `/psc native off` hides the prototype outside
combat; it starts disabled after reload. Unsupported clients report an error
and retain the existing tracker.

The prototype has a fixed icon layout and no sound alerts or missing-seal
animation. It tests native visibility before integrating those features.
Its seal rank ID data is adapted from talentsforever.com via the installed
ForeverAuras dataset under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

### Copy addon files

Copy the entire `PallySealCooldowns` folder into your Forever client's
`Interface/AddOns` directory. The resulting path must be
`Interface/AddOns/PallySealCooldowns/PallySealCooldowns.toc`.
Restart the client, enable **Pally Seal Cooldowns** on the character selection
AddOns screen, and log into a paladin.

## Use

Open **Options > AddOns > Pally Seal Cooldowns**, click the paladin seal icon
beside the minimap, or type `/psc` or `/psc settings` to open the same settings
page. Settings are split into a **General** page (the addon's own category)
and **Layout**, **Alerts**, **Appearance**, and **Presets** sub-pages listed
beneath it. Each page scrolls on its own.
Drag the minimap icon to reposition it; its position is saved.
Changes apply immediately and are saved automatically.
Enable **Hide outside combat** to show the tracker only during combat. The
minimap settings button stays available. This setting is off by default.

The **Layout** page picks one of four layouts. Each page shows only the
settings that apply to the chosen layout (and hides, for example, border color
when Border is None), so changing layout changes which options are listed.
Display size on the General page scales every layout.
- **Large icon** (default): a 52-pixel icon. Uncheck **Show duration bar under
  icon** to remove the thin bar beneath it.
- **Small icon with timer bar**: a 30-pixel icon with a horizontal duration bar
  (120–360 pixels wide before scaling) on its right.
- **Essential Cooldowns icon**: matches the icons on Blizzard's Essential
  Cooldowns bar, with no padding or background and Blizzard's icon mask and
  overlay. **Essential icon size** at 0 follows Blizzard's icon size, or 50
  pixels until one is visible. Any other value (16–80) sets the size. This
  layout always attaches to Blizzard's bar (see below).
- **Swing timer bar**: built from the same artwork as Forever's main-hand
  swing timer (frame, background, fill, edge pip, and label shadow), with no
  icon, "Seal Timer" on the left (a fixed title like Blizzard's "Main Hand",
  shown even when **Show seal name** is off), and the time left in tenths of a
  second on the right. It is 213 pixels wide at the default bar width, like Blizzard's.
  It uses **Bar width**, **Bar texture** (Game default keeps the main-hand
  fill), and **Bar counts down**; setting **Border** to None on the
  Appearance page removes the frame.

**Bar texture** and **Bar counts down** apply to all duration bars. Bar counts
down starts the bar full and drains it from right to left; by default it fills
up instead. `/psc style icon`, `/psc style bar`, `/psc style essential`, and
`/psc style swing` switch layouts.
The **Essential Cooldowns icon** always attaches to Blizzard's Essential
Cooldowns bar; this is no longer a setting, and the other layouts never attach.
**Snap position** puts it on the right, left, top, or bottom of the bar, and
**Gap from bar** sets the spacing. It moves with the bar in Edit Mode and
cannot be dragged.
If the bar is missing (for example, the Cooldown Manager is disabled), the saved
position is used and chat notes it once. `/psc status` reports whether the bar
was found.

The **Alerts** page's **When no seal is active** section controls the
missing-seal state:
- **Combat alert**: glow and bounce (default), glow only, bounce only, or none.
- **Hide tracker when no seal is active**: shows nothing until a seal is cast.
  Missing-seal sounds still play.
- **Show missing-seal text**: hides "No active seal" and "CAST A SEAL" without
  hiding the seal name or status while a seal is active.
- **Missing symbol**: the red "!", or none.
- **Placeholder icon**: the default icon or one of the seal icons.

**Warning color** on the Appearance page sets the color for a due refresh and a
missing seal: red (default), orange, yellow, Paladin pink, or white.
Settings also include independent
seal-name and status-text visibility, and separate refresh and missing-seal
sounds. Game sounds: raid warning, whisper, soft UI click, ready check, and
alarm clock. Bundled original sounds: gentle chime, double chime, bright bell,
glass ping, rising arpeggio, holy shimmer, harp pluck, soft gong, wood block,
bubble pop, urgent beeps, and cat meow. Installed SharedMedia sounds are listed after the
built-in choices; if a chosen SharedMedia sound is later removed, the alert
falls back to raid warning. New settings use
the bundled gentle chime for refresh and raid warning for a missing seal;
existing refresh sound selections are preserved. Each alert has its own enable
and combat-only checkbox (the Blizzard-managed display has none for the missing
sound). Both default to combat-only. If refresh sounds were
previously disabled, the new missing-seal sound starts disabled too.
A refresh warning plays once per seal timer when the warning threshold is reached.
On the older estimated tracker, the missing-seal warning plays once for a
confirmed missing or expired seal, including combat entry without a seal, and
rearms when a seal becomes active. With combat-only enabled, it also rearms after
leaving combat. The Blizzard-managed display plays it only outside combat, as
described at the top of this page. Restricted aura data and expired estimates do not trigger
missing-seal sounds. Audio settings apply even when the tracker is hidden outside
combat.
Choosing a sound from its dropdown plays it once so you can hear it. Use **Test refresh
sound** or **Test missing sound** to preview on the shared Master, SFX, or Dialog
channel. Previews work regardless of enable and combat-only settings.
The bar style uses Retail cooldown-manager bar and frame textures when present,
with a compact layout (220 by 30 pixels at the default bar width), gold fill,
white name, and right-aligned timer.
The window includes position lock, sound, countdown visibility, warning time,
size, and position reset. `/psc` also opens it.

Use the **Appearance** sub-page for font, outline, shadow, border, and bar
texture controls. Countdown and seal-name font sizes are independent; 0 keeps
the layout's original size, and custom sizes start at 8 pixels. Choices such as
font, border, and colors are dropdown menus; on a client without Blizzard's
dropdown menu, left-click a choice to advance or right-click to go back. Border colors include white,
gold, black, and paladin pink. Thickness applies to custom borders; the default
icon artwork keeps its original shape.

**Default**, **Minimal**, and **High Contrast** apply built-in appearance
presets immediately, without changing timing, sounds, positioning, or visibility.
Default restores the original layout fonts and artwork.
Three additional presets are included: **Classic Gold** uses a gold tooltip
border with outlined text; **Paladin Pink** uses Arial Narrow and a pink solid
border; **Clean Text** uses Arial Narrow, text shadows, and no border. All six
preset buttons are on the **Presets** sub-page and work without extra media
packs. On the **Swing timer bar** layout, presets change only text styling and
keep Blizzard's bar art (fill and frame), and Classic Gold and Paladin Pink,
which are border looks, are hidden.

Optional **LibSharedMedia-3.0** support adds fonts, border textures, and bar
textures registered by installed media packs. The library is not bundled;
install it or use another addon that provides it, alongside your media packs.
Choices refresh when the settings page opens. Missing media falls back to
the original appearance while retaining the saved choice. Masque support is
not included in this release.

On older clients, the pages use the legacy AddOns options category and its
nested sub-categories. If the settings API cannot nest sub-pages, or neither
settings API is available, `/psc` shows the same pages behind tabs in one view
(a standalone window in the latter case).
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

The display turns the warning color when a seal needs refreshing and shows **CAST A SEAL**
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
including during combat. Readable replacements and duration changes reconcile
the timer. Empty combat lookups after a known seal retain its live estimate,
because Forever can return empty results while the buff remains active. Empty
lookups outside combat clear the timer after the cast grace period. Readable
removal events for the tracked aura also
clear its timer when a fresh aura query is blocked.
Readable aura-addition events attach an instance ID to combat cast estimates,
so later cancellation or dispel removal events can clear them. When the client
supports combat-log events, a matching buff-removal event for the player's
current seal also clears the timer, including estimates without an instance ID.
Successful player seal casts immediately start/reset the timer and stop the
missing-seal animation. Cast estimates use the last observed
duration for that seal, or the Forever beta baseline of 30 seconds until a
duration is learned. **ESTIMATED TIMER** identifies a countdown retained while
live data is restricted. A successful cast has a 0.5-second grace period for
the aura API to catch up before an empty out-of-combat or stale snapshot replaces it.
If combat aura queries are empty/restricted and both aura-removal and combat-log
information are unavailable, early cancellation,
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

To run all local checks, including the Lua tests, use `scripts/check.ps1` with
Docker Desktop running. See [DEVELOPMENT.md](DEVELOPMENT.md).

API reference:
[Blizzard UI aura API declarations](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).

## License

Released under the [MIT License](LICENSE). The native seal rank data is
adapted from talentsforever.com under CC BY 4.0; see
[NOTICE.md](PallySealCooldowns/NOTICE.md).
