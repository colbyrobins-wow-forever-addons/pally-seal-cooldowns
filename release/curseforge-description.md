# Pally Seal Cooldowns

Keep track of your paladin seals with clear countdowns, refresh reminders, and a display you can customize to match your UI. Built for **WoW Forever beta**.

## Features

- **Four display layouts:** a large icon with a radial timer, a compact horizontal duration bar, an icon that matches Blizzard's Essential Cooldowns bar, or a **Swing timer bar** built from the artwork of Forever's main-hand swing timer, labeled "Seal Timer" with a countdown in tenths of a second.
- **Attaches to the Essential Cooldowns bar:** the Essential Cooldowns icon layout attaches to any side of Blizzard's bar with an adjustable gap and follows the bar when you move it in Edit Mode.
- **Native seal tracking:** Blizzard manages the main icon and bar directly, including removal while combat aura data is restricted. Unsupported clients retain estimated tracking.
- **Seal changes:** native bindings update the icon, name, countdown, and bar when the active seal changes. The fallback tracker uses cast estimates.
- **Refresh reminders:** configurable warning threshold, a choice of warning colors, a warning sound that works in combat, and optional countdown numbers that appear only when a refresh is due.
- **Missing-seal visuals:** shows a placeholder icon, text, glow, and bounce without reading restricted buff state in addon Lua. Choose the combat alert (glow, bounce, both, or none), the placeholder icon, and whether the "!" and text appear, or hide the tracker until a seal is cast.
- **Sound settings:** separate refresh/missing sounds chosen from dropdown menus, with 17 built-in choices: game sounds (raid warning, whisper, soft UI click, ready check, alarm clock) and original bundled sounds (gentle chime, double chime, bright bell, glass ping, rising arpeggio, holy shimmer, harp pluck, soft gong, wood block, bubble pop, urgent beeps, and a cat meow). Installed SharedMedia sounds are listed too. Picking a sound plays it; audio-channel selection and test buttons are included. Combat sound limitations are described below.
- **Flexible layout:** movable tracker, adjustable scale and bar width, a duration bar that fills up or counts down, an optional thin bar under the large icon, optional combat-only visibility, and separate toggles for the seal name and status text.
- **Saved preferences:** settings and minimap button position persist between sessions. No additional addons are required.

## Make it match your UI

Choose a font, set countdown and seal-name sizes independently, and adjust outlines and text shadows. Customize border style, color, and thickness, choose a different bar texture, or make the bar count down so it starts full and drains as the seal expires. Warning colors remain active with every style.

Six built-in presets make it easy to get started (on the Swing timer bar, presets change only text styling and keep Blizzard's bar art, and the two border looks are hidden):

- **Default:** the original game-style fonts and icon border.
- **Minimal:** a thin dark border and flat bar with no text outline or shadow.
- **High Contrast:** a thicker white border and bold text outlines.
- **Classic Gold:** a gold tooltip-style border and outlined text.
- **Paladin Pink:** a pink border, Arial Narrow, and a flat bar.
- **Clean Text:** a borderless layout with Arial Narrow and text shadows.

All presets work without extra downloads. Optional **LibSharedMedia-3.0** support adds fonts, borders, bar textures, and alert sounds provided by installed media packs. If a selected media pack is unavailable, the display falls back to its defaults.

## Settings

Open **Options > AddOns > Pally Seal Cooldowns**, type **`/psc`**, or click the minimap seal icon.

Settings are organized into pages:

- **General:** position lock, combat-only visibility, text toggles, warning time, and size.
- **Layout:** the four layouts with each one's options: bar width, texture, and direction, and where the Essential Cooldowns icon attaches to Blizzard's bar.
- **Alerts:** refresh and missing-seal sounds, combat-only options, audio channel, sound previews, and what the tracker shows when no seal is active.
- **Appearance:** fonts, outlines, borders, and warning color.
- **Presets:** the six built-in styles.

Each page shows only the options that apply to the chosen layout. Changes apply immediately outside combat; native layout/appearance changes made during combat apply afterward. Presets change appearance without altering your timing, sound, position, or visibility settings.

## Compatibility

Targets **WoW Forever beta 1.60.1**, interface **16001**. Other WoW versions have not been tested, and future beta builds may require updates.

Recognizes localized names for Seal of Righteousness, Command, Justice, Light, Wisdom, the Crusader, and Fury. Display labels and commands are in English.

## How combat tracking works

On supported Forever clients, Blizzard's native aura container filters paladin seal ranks and drives the icon, countdown, name, and duration bar. Native layout also shows the missing-seal presentation when the seal is absent. The addon does not inspect restricted native frame state. The native manual-cancellation prototype was verified in game; enemy dispel has not been independently confirmed in the recorded tests.

Clients without the required native display retain the previous estimated tracker. Empty combat lookups can retain a live estimate until readable data returns. This fallback cannot reliably identify cancellation/dispel when all removal information is restricted.

**Sound limitations:** when the game hides seal timing in combat, the refresh sound uses the timer from your seal cast. If a seal is removed early and the game does not report it (for example, an unseen dispel), the refresh sound can still play at the expected time; recasting or switching seals resets it. Combat-entry missing sounds are pending native sound integration. Sound previews and readable out-of-combat missing sounds remain available. Saved sound choices are preserved.

**The addon never casts or refreshes spells automatically.** No WeakAuras or ForeverAuras installation is required.

## Commands

| Command | Action |
| --- | --- |
| `/psc` | Open settings |
| `/psc unlock` | Unlock the icon for dragging |
| `/psc lock` | Lock its position |
| `/psc warn 5` | Warn with 5 seconds remaining; accepts 1–30 |
| `/psc counter refresh` | Show countdown numbers only at the warning threshold |
| `/psc counter always` | Always show countdown numbers (default) |
| `/psc sound` | Toggle the refresh warning sound |
| `/psc scale 1` | Set display scale; accepts 0.5–2 |
| `/psc reset` | Reset position and size |
| `/psc style icon` | Use the large icon layout (also `bar`, `essential`, or `swing`) |
| `/psc status` | Show client version, build, interface, aura API, and Essential Cooldowns bar status |

The default warning threshold is **5 seconds**, sound is enabled, and position is locked.

## Manual installation

Extract the `PallySealCooldowns` folder into your Forever client's `_classic_beta_/Interface/AddOns` directory. Restart WoW and enable **Pally Seal Cooldowns** on the character selection AddOns screen. Log into a paladin; the tracker stays hidden on other classes.

## Feedback

Forever is a beta client and future builds may need addon updates. Report problems or ideas on [GitHub](https://github.com/colbyrobins-wow-forever-addons/pally-seal-cooldowns/issues), and include your client build (`/psc status`), addon version, game language, seal name, steps to reproduce, and any Lua error text. The source code is public under the MIT License.

## Data attribution

Native seal rank data is adapted from talentsforever.com under CC BY 4.0. The addon includes `NOTICE.md` with source, license, and modification details.
