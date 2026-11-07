# Development and release workflow

Features and fixes are developed and tested in game before establishing a new
release version. Git commits track development independently of release numbers.

## Development cycle

1. Make a focused change and add regression coverage for changed behavior.
2. Run the local Lua tests. Record what passed and what still needs the client.
3. Leave the change uncommitted in the working tree. Do not commit each edit;
   iterate on the working tree through deployment and in-game testing.
4. When in-game deployment is requested, confirm the actual client addon path,
   back up its existing addon folder outside the source tree, and copy only the
   `PallySealCooldowns` folder, including its sound assets. Do not bump the TOC
   version or build a release archive for this step.
5. Record the base Git commit (`git rev-parse --short HEAD`), the uncommitted
   changes deployed on top of it (`git status --short`), client build, date,
   scenarios, and observed results. Compare timers with actual buffs; test
   combat entry, recasts, seal switches, cancellation, expiration, sound
   controls, both layouts, and settings after `/reload`.
6. Fix problems, rerun relevant local tests, redeploy, and repeat in-game
   testing until the user accepts the results. Record untested cases as pending.
7. After the user accepts the in-game results, commit the source, tests,
   documentation, and required assets together, and update the unreleased work
   below with the scope and verification status.

Run all local suites from the repository root with Lua 5.1:

```powershell
Get-ChildItem tests/*_test.lua | ForEach-Object {
    lua $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "Test failed: $($_.Name)" }
}
```

The recent local runs used Lupa's Lua 5.1 runtime because no standalone `lua`
executable was installed. Test dependencies are not shipped with the addon.

## Release gate

After in-game acceptance and a request to prepare a release:

1. Choose the next version with the user and update the TOC, release changelog,
   and current upload metadata together. Do not infer a released baseline from
   an old archive or upload guide.
2. Run the local suites and check that the release content matches the accepted
   test build, apart from release metadata and documentation.
3. Commit the release changes, tag that commit as `v<version>`, and create the
   matching archive under ignored `dist/`. Include only the addon folder and its
   required assets.
4. Publish only when requested. Record publication separately from preparation.

## Current unreleased work

### 2026-11-07: 0.1.23 release preparation

- User requested release packaging. Assigned next patch version 0.1.23,
  following the 0.1.22 precedent. No in-game results were reported for the
  test deployment before the request, so the request is recorded as release
  authorization, not as test confirmation.
- Scope since `v0.1.22`: more alert sounds (ten generated sounds, cat meow,
  Ready check, Alarm clock, SharedMedia sounds), dropdown menus for all
  settings choices, and the code review fixes (entries below).
- Updated the TOC, README, `release/changelog-0.1.23.md` (new),
  `release/curseforge-description.md` (sound features), and
  `release/UPLOAD-GUIDE.md`.
- Runtime files match the build deployed to `_forever_` earlier today
  (`diff -r` shows only the TOC version line).
- Ten Lua 5.1 suites (Lupa) and three Python exporter tests passed; TOC files
  present; `git diff --check` clean.
- Release archive: `dist/PallySealCooldowns-0.1.23.zip`, built with
  `git archive` from tag `v0.1.23`. Public upload is a separate step; the
  commit, tag, and archive are local.

### 2026-11-07: test deployment of dropdowns, ten new sounds, and review fixes

- Base commit `2229e14` plus uncommitted `Appearance.lua`, `Settings.lua`,
  `PallySealCooldowns.lua`, and new sounds `CatMeow.wav`, `BrightBell.wav`,
  `DoubleChime.wav`, `RisingArpeggio.wav`, `HolyShimmer.wav`, `SoftGong.wav`,
  `HarpPluck.wav`, `WoodBlock.wav`, `BubblePop.wav`, `GlassPing.wav`,
  `UrgentBeeps.wav` (tests, docs, and scripts are not shipped). Supersedes the
  earlier sound-options test deployment today.
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup (the earlier test deployment):
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-2229e14-uncommitted-a74fc2d9-c494-4b56-a03f-f313c792f02e`;
  all 13 files matched by SHA-256.
- All 23 deployed files match the source by SHA-256. Saved variables and other
  addons untouched; TOC version unchanged (0.1.22); no archive built.
- In-game checklist: fully restart the client (new sound files); every choice
  on Layout, Alerts, and Appearance is a dropdown that lines up with its label
  and opens above the window, both from `/psc` and inside Blizzard Settings;
  picking a sound plays it once; each of the 17 built-in sounds plays and is a
  reasonable volume; Ready check and Alarm clock exist on this client (else
  refresh falls back to the chime); SharedMedia sounds appear and scroll, with
  no "None"; choices persist after `/reload`; the Appearance hint no longer
  mentions left/right click.
- In-game acceptance pending.

### 2026-11-07: code review fixes for sounds and dropdowns

- Cycling buttons (clients without the dropdown template) no longer play a
  preview on every click; only picking a sound from a dropdown previews it.
- A sound that cannot play (removed SharedMedia sound, sound kit missing from
  the client, failed file) now falls back to that alert's own default: gentle
  chime for refresh, raid warning for missing seal. Previously every failure
  played raid warning. Defaults live in `addon.SoundDefaults`, which reload
  repair also uses.
- SharedMedia's silent "None" sound is rejected as a saved choice and repaired
  to the default on reload, so an alert cannot be silently disabled.
- Sound lists reuse `addon.MediaChoices`/`addon.MediaPath` from
  `Appearance.lua` instead of a second copy of the SharedMedia lookup.
- Both sound generators write next to the addon regardless of the current
  directory; regenerating from `scripts/` produced byte-identical WAVs.
- Skipped review items: regenerating all dropdown menus on page show (cheap,
  page-show only) and restructuring the sound list literal (style only).
- Ten Lua 5.1 suites pass with new regression checks for each fix. Not
  deployed. No version change.

### 2026-11-07: ten more bundled alert sounds

- User asked for a variety of chimes for the community. Added Double chime,
  Bright bell, Glass ping, Rising arpeggio, Holy shimmer, Harp pluck, Soft
  gong, Wood block, Bubble pop, and Urgent beeps, listed right after Gentle
  chime in both sound dropdowns.
- All ten are synthesized from scratch by `scripts/make_alert_sounds.py`
  (stdlib only, seeded randomness, reproducible), 0.35-1.8 s mono 16-bit
  44.1 kHz WAV, about 800 KB together. Levels are normalized to a common RMS
  (about -19 dBFS) between the gentle chime and the cat meow, peak capped at
  about -4.4 dBFS.
- New test checks that every bundled sound file exists in the addon, has a
  RIFF header, and that sound keys and labels are unique; reload test covers
  two new keys. Ten Lua 5.1 suites pass.
- In game pending: how each sound actually sounds and its volume relative to
  game audio. Not deployed. No version change.

### 2026-11-07: dropdown menus for settings choices

- User found left/right-click cycling awkward. All 14 choice selectors
  (layout, textures, snap side, sounds, channel, missing-seal options, font,
  outline, border, colors) are now Blizzard dropdowns
  (`WowStyle1DropdownTemplate` with `SetupMenu`/`CreateRadio`), the same API
  Questie and Bagnon use on the installed Forever client. Label on the left,
  dropdown on the right, same row positions.
- Choosing a refresh or missing sound plays it once. Long lists (SharedMedia)
  scroll. A saved but unavailable media choice shows "<name> (unavailable)".
- If `DoesTemplateExist` reports no template, the old cycling buttons are kept
  (and the Appearance hint still mentions left/right click).
- Ten Lua 5.1 suites pass, with new tests for the dropdown path (choices,
  selected mark, sound previews, silent non-sound choices, unavailable media,
  no write on refresh) alongside the unchanged fallback tests.
- In game pending: dropdown appearance and alignment on each page, menus
  opening above the settings window both standalone and inside Blizzard
  Settings, sound preview on choose, and scrolling with many SharedMedia sounds.
- Not deployed yet (the earlier sound-options deployment does not include this).
  No version change.

### 2026-11-07: test deployment of more alert sounds

- Base commit `2229e14` plus uncommitted `PallySealCooldowns/Settings.lua`,
  `PallySealCooldowns/PallySealCooldowns.lua`, and new
  `PallySealCooldowns/Sounds/CatMeow.wav` (tests, docs, and the generator
  script are not shipped).
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup: `<workspace>/addon-deployment-backups/PallySealCooldowns-before-2229e14-uncommitted-d1b29095-9a5e-4563-9638-22428bcd427b`;
  all 12 files matched the prior install by SHA-256.
- All 13 deployed files match the source by SHA-256. Saved variables and other
  addons untouched; TOC version unchanged (0.1.22); no archive built.
- In-game checklist: `/reload`; on the Alerts page cycle **Refresh sound** and
  **Missing sound** through Ready check, Alarm clock, and Cat meow and use the
  Test buttons on each audio channel; judge the meow's volume against the
  chime; with a SharedMedia sound pack installed, confirm its sounds appear after
  the built-ins (no "None") and play; `/reload` and confirm choices persist;
  confirm the longer hint fits on the Alerts page.
- In-game acceptance pending.

### 2026-11-07: more alert sounds (community request)

- Community feedback asked for more sound options, such as a cat meow. Both
  sound selectors now offer **Ready check**, **Alarm clock**, and a bundled
  **Cat meow**, followed by any installed SharedMedia sounds (same pattern as
  fonts and textures; LSM's "None" entry is skipped).
- `Sounds/CatMeow.wav` is synthesized from scratch by
  `scripts/make_cat_meow.py` (no third-party recording), 0.72 s mono 16-bit
  44.1 kHz, peak about -9 dBFS. Windows playback succeeded.
- Saved SharedMedia choices survive reloads even before the media pack
  registers; empty or non-string choices are repaired to defaults. A missing
  SharedMedia sound or a sound kit absent from the client falls back to raid
  warning. Alerts page height grew for the longer hint.
- Ten Lua 5.1 suites (Lupa) pass, including new settings and reload
  regression checks; TOC files present; `git diff --check` clean.
- In game pending: the cat meow's sound and volume, the Ready check and Alarm
  clock sounds on Forever 1.60.1, and SharedMedia sound listing and playback.
- Not deployed. No version change.

### 2026-11-06: 0.1.22 release preparation

- User requested a new release version. Assigned next patch version 0.1.22.
  Updated the TOC, README, changelog, and upload guide together. The
  CurseForge description needed no change.
- Scope since `v0.1.21`: plain countdown numbers (entry below).
- Runtime Lua matches the build deployed to `_forever_` earlier today
  (`diff -r` shows only the TOC version line). No in-game results were reported
  before the release request, so the request is recorded as release
  authorization, not as test confirmation.
- Ten Lua 5.1 suites (Lupa) and three Python exporter tests passed.
- Release archive: `dist/PallySealCooldowns-0.1.22.zip`, built with
  `git archive` from tag `v0.1.22`. Public upload is a separate step; the
  commit, tag, and archive are local.

### 2026-11-06: plain countdown numbers

- The native countdown's default format appends a unit ("12s"). The countdown
  is now bound with a `C_StringUtil.CreateNumericRuleFormatter` formatter
  (`%d` rounded up, `%d:%02d` from 60 seconds), the same API ForeverAuras and
  BetterBlizzPlates use on this client. If the client rejects the
  formatter, the default binding is kept. The "REFRESH SEAL" text binding is
  unchanged. The estimated (non-native) display already showed bare numbers.
- All ten suites pass, with new coverage for the bound formatter, its rules,
  and the fallback. The TOC remains 0.1.21.
- 2026-11-06: deployed base commit `a79034f` (`v0.1.21`) plus uncommitted
  `PallySealCooldowns/NativeDisplay.lua` (with `tests/native_display_test.lua` and
  `DEVELOPMENT.md` changed but not shipped) to
  `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
  Verified by `diff -r`. Backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-forever-before-plain-countdown-on-a79034f-20261106190813`.
  Client build not recorded. No in-game testing performed yet.

### 2026-11-06: 0.1.21 release preparation

- User requested release packaging. Assigned next patch version 0.1.21,
  following the 0.1.x pattern; the user declined a version question and asked
  to package. Updated the TOC, README, changelog, CurseForge description, and
  upload guide together.
- Scope since `v0.1.20`: Essential Cooldowns icon layout and snapping, hideable
  icon bar, missing-seal options, warning color, and the five-page settings
  layout (entries below).
- Runtime Lua matches the build deployed to `_forever_` earlier today
  (`diff -r` shows only the TOC version line). No in-game results were reported
  before the release request. As with 0.1.20, the request is recorded as
  release authorization, not as test confirmation. All in-game checks listed
  below remain unconfirmed.
- Ten Lua 5.1 suites (Lupa) and three Python exporter tests passed.
- Release archive: `dist/PallySealCooldowns-0.1.21.zip`, built with
  `git archive` from tag `v0.1.21`. Public upload is a separate step; no remote
  is configured, so the commit, tag, and archive are local.

### 2026-11-06: Essential Cooldowns style and snapping

- New `CooldownManager.lua` with saved, default-off settings: `cdmStyle`
  (match Essential icon style), `cdmIconSize` (0 follows Blizzard, else 16–80),
  `snapToCDM`, `snapSide` (right/left/top/bottom), and `snapGap` (0–20).
- Snapping anchors the tracker frame to `EssentialCooldownViewer` (name
  confirmed in the installed ForeverAuras source for this client). It never
  calls the viewer's methods, since that taints Blizzard's refresh path. Relayouts
  are observed with a `hooksecurefunc` post-hook on `RefreshLayout` and
  re-applied only when the matched size changes. `ADDON_LOADED` for
  `Blizzard_CooldownViewer`, `EDIT_MODE_LAYOUTS_UPDATED`, and
  `COOLDOWN_VIEWER_DATA_LOADED` also re-apply the anchor.
- The matched size is read from an active Essential icon's width and effective
  scale with secret-value and error guards. It falls back to the last readable
  size, then to 50 px. Native widget geometry is still never read.
- All ten Lua 5.1 suites pass through Lupa. The new `cooldown_manager_test.lua`
  covers normalization, anchors on every side, gap scaling, size reading,
  secret geometry, and the single hook. The other suites add matched-style
  native sizing and masking, settings controls, and snap and fallback behavior
  with drag blocking.
- Pending in-game: whether the Essential icon geometry is readable on Forever,
  whether the mask and overlay outsets look like Blizzard's icons, whether
  anchoring to the viewer avoids taint during combat, and Edit Mode follow
  behavior.
- 2026-11-06: deployed base commit `d66b956` plus uncommitted changes to
  `NativeDisplay.lua`, `PallySealCooldowns.lua`, `PallySealCooldowns.toc`,
  `Settings.lua`, and new `CooldownManager.lua` to
  `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
  The tests, `README.md`, and `DEVELOPMENT.md` also changed but are not shipped.
  The installed folder matched the source by `diff -r` after copying. Backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-forever-before-cdm-snap-on-d66b956-20261106183124`.
  Client build not recorded. No in-game testing performed yet.
- Added saved **Show duration bar under icon (icon layout)** appearance checkbox
  (`showIconBar`, on by default). When off, the thin icon-layout bar is hidden
  with alpha 0 so it stays bound to the native timer. The bar layout always shows
  its bar. All ten suites pass. Redeployed on top of `d66b956` with the same
  uncommitted file set and verified by `diff -r`. Backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-forever-before-iconbar-toggle-on-d66b956-20261106183839`.
  Pending in-game: confirm the native bar stays hidden while the timer runs.
- Settings reorganized into five pages: General, Layout, Alerts (was "Alerts &
  sounds"), Appearance, and Presets. Tabs are narrower to fit the standalone
  window. The bar checkbox and the Essential style checkbox became one
  `displayStyle` selector with `icon`, `bar`, and `essential` values. A saved
  test-build `cdmStyle = true` migrates to `essential`. Layout-specific options
  are grouped under headings on the Layout page.
- New missing-seal options, normalized by `addon.NormalizeDisplayOptions` and
  kept out of presets: `missingAlert` (both/glow/bounce/none),
  `hideWhenMissing`, `showMissingText`, `missingSymbol` (bang/none), and
  `missingIcon`. New `warningColor` appearance option (presets reset it to red).
  It drives warning borders, countdown and status curves, and the missing
  symbol. The default red border shifts slightly from (1, 0.3, 0.15) to match
  the text red (1, 0.35, 0.2).
- Native hide-when-missing sets alpha 0 on the missing clip's frame, so the
  native presence gate is unchanged. Native `Apply` resets the combat alert, so
  a changed alert choice takes effect on the next update.
- All ten suites pass, with new coverage for normalization and migration, alert
  parts on both displays, native and legacy hiding, the missing-text split, the
  symbol, icon, and color bindings, and the five-page settings structure.
- 2026-11-06: deployed base commit `d66b956` plus uncommitted changes to
  `Appearance.lua`, `CooldownManager.lua` (new), `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, `PallySealCooldowns.toc`, and `Settings.lua` to
  `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
  The tests, `README.md`, and `DEVELOPMENT.md` also changed but are not shipped.
  Verified by `diff -r`. Backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-forever-before-layout-missing-options-on-d66b956-20261106185520`.
  Client build not recorded. No in-game testing performed yet.

### 2026-11-05: 0.1.20 release preparation

- User requested a release with a changelog and updated CurseForge description.
  Assigned next patch version 0.1.20; updated the TOC, changelog, README,
  project description, and upload guide together.
- Scope since `v0.1.19`: combat refresh sounds from cast timers (`63620a5`),
  optional draining duration bar (`a1ec025`), and settings sub-pages (below).
- Runtime Lua matches the build deployed to `_forever_` earlier today; only the
  TOC version changed. No in-game results were reported for the sub-pages,
  bar direction, or combat refresh sound before the release request; that
  request is recorded as release authorization, not as test confirmation.
- Eight Lua 5.1 suites (Lupa) and three Python exporter tests passed.
- Release archive: `dist/PallySealCooldowns-0.1.20.zip`, built with
  `git archive` from tag `v0.1.20`. Public upload is a separate step; no remote
  is configured, so the commit, tag, and archive are local.

### 2026-11-05: settings sub-pages

- The single two-column settings view is split into four single-column pages.
  **General** (lock, countdown mode, layout, combat visibility, name/status
  text, warning time, size, bar width, reset) is the addon category itself.
  **Alerts & sounds**, **Appearance**, and **Presets** register beneath it with
  `Settings.RegisterCanvasLayoutSubcategory`, or as legacy categories whose
  `parent` is the addon name. Every saved control and key is unchanged.
- If the modern API lacks sub-categories, and in the standalone fallback window,
  the same pages are shown behind four tabs. Controls on all pages stay in sync,
  so presets and reset refresh the other pages.
- All eight Lua 5.1 suites pass through Lupa. The settings suite now finds
  controls by label and checks page placement, tab switching, sub-page
  registration on the modern, legacy, and standalone paths, and late
  registration. Actual client layout, sub-page navigation, and sub-page
  refresh on show remain pending in-game verification.
- 2026-11-05: deployed base commit `a1ec025` plus uncommitted changes to
  `PallySealCooldowns/Settings.lua` (with `tests/settings_test.lua`,
  `README.md`, `DEVELOPMENT.md`, and `AGENTS.md` changed but not shipped) to
  `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
  The installed copy matched `a1ec025` apart from line endings; backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-forever-before-subpages-on-a1ec025-20261105220832`.
  Client build not recorded. No in-game testing performed yet.

### 2026-11-05: optional draining duration bar

- New saved **Bar counts down** appearance checkbox (`barCountdown`, off by
  default). When on, the native duration bar binds with
  `Enum.StatusBarTimerDirection.RemainingTime`, so it starts full and drains
  right to left; when off, the existing native binding is unchanged.
- The estimated-timer fallback now follows the same choice; it previously
  always drained, so with the default it now fills like the native bar.
- All eight Lua 5.1 suites pass through Lupa, covering native bind options,
  estimated bar values both ways, and checkbox save/restore. In-game
  confirmation of native fill direction in both layouts remains pending.

### 2026-10-16: Forever XP settings window

- `/foreverxp` and `/foreverxp settings` open a movable window with mutually
  exclusive always/mouseover visibility choices and a taller-bar checkbox.
  Changes save and apply immediately; height changes still defer in combat.
  The window supports Escape/close and refreshes saved values when reopened.
- Diagnostic output moved to `/foreverxp status`; existing setting shortcuts
  remain available. All ten Lua 5.1 suites pass, including window control state,
  callback application, reopening, combat notices, and slash-command routing.
- Actual client layout and interaction remain pending in-game verification.

### 2026-10-16: XP text visibility setting

- Added saved `/foreverxp always` (default) and `/foreverxp mouseover` options.
  The full text format and default-position tooltip are preserved. Only the
  text hides when idle in mouseover mode; the XP bar remains visible.
- Focused Lua coverage verifies native refresh suppression, hover/leave,
  persistence through settings normalization, and switching during combat.
  In-game verification remains pending.

### 2026-10-16: one permanent full XP display

- Full styled XP totals, percentage, and XP to next level now show at all times.
  Hover changes only the tooltip. Removed compact/full commands and retired
  the saved mode preference; tall/normal height choices remain available.
- Focused Forever XP Lua 5.1 suite covers full text without hover, unchanged
  text on hover/leave, and migration from the old compact preference.
  In-game confirmation remains pending.

### 2026-10-16: Forever XP default tooltip position

- Use Blizzard's default screen tooltip anchor for expanded XP details instead
  of anchoring above the bar. Retains ownership for refresh and leave handling.
- Focused Forever XP Lua 5.1 suite passes, including default-anchor coverage.
  In-game positioning confirmation remains pending.

### 2026-10-16: Forever XP presentation and tooltip

- User confirmed the container discovery repair works, then requested styled
  compact/full text, optional taller bar, and expanded hover information.
- Compact default: gold percentage and soft-white XP remaining/next level;
  hover expands current/required XP. Text uses an outline and subtle shadow.
- Tooltip shows current/required XP, percentage, next-level XP, and rested bonus
  XP. Includes rested tick hover and guards against delayed native tooltip text
  overwrites. It never replaces unrelated owned tooltips during XP updates.
- Saved `/foreverxp compact|full` and `/foreverxp tall|normal` controls. Normal
  height remains the default; tall is 18 pixels minimum. Height/font changes
  defer during combat; native bar colors and rested indicator remain intact.
- All nine Lua 5.1 suites pass, including hover transitions, tooltip refreshes,
  formatting, combat-deferred height, and restoring original height. Visual fit,
  tooltip behavior, tall-bar layout, and persistence still need in-game retest.

### 2026-10-16: Forever XP bar discovery repair

- First in-game report: addon loaded but did not change the bar. Initial
  discovery only supported `MainMenuExpBar`; installed XPForever code identifies
  the newer status-tracking manager and its per-container experience bars.
- Added discovery and independent bindings for all manager XP bar copies,
  including reputation layout changes, plus native SetShown handling.
- Added `/foreverxp` attachment/XP status and a warning when XPForever is loaded.
  XPForever is installed and its code hides Blizzard's bar; whether it is enabled
  in the user's current session is not known. Other addons are left unchanged.
- All nine Lua suites pass, now including newer container discovery, late
  loading, combat deferral, multiple XP copies, and the conflict diagnostic.
  Actual client verification remains pending after redeployment.

### 2026-10-16: Forever XP development addon

- Added the independent `ForeverXP` addon for interface 16001. It changes the
  existing Blizzard XP label to current/maximum XP, percentage, and XP till
  level. The text remains visible while Blizzard shows the XP bar.
- Uses post-hooks on the existing label; leaves bar fill, layout, rested XP,
  tooltips, and CVars intact. Requires the default `MainMenuExpBar`; does not
  claim compatibility with replacement action bars.
- All nine Lua 5.1 suites passed through Lupa, including the new formatting and
  event tests. See `ForeverXP/README.md` for installation and in-game checks.
- No deployment or in-game verification yet. No release version or archive
  assigned. Pally Seal Cooldowns source and release version are unchanged.

### 2026-10-15: restore native refresh sound reminders

- Reporter confirms combat display works, but refresh sound played in only
  2 of 14 fights on a level 21 paladin using Crusader and Righteousness.
  Exact client build and installed version were not supplied.
- Native mode now permits refresh warnings from live cast-based or previously
  observed timers retained through restricted combat queries. The native
  display continues to own visual state. Sound enable/combat-only settings
  remain unchanged; both alert types default to combat-only.
- Known limitation: an early cancellation/dispel hidden by the client can
  leave the estimated refresh reminder scheduled. Readable removal cancels it;
  recasts/switches replace the deadline. Expired estimates do not emit missing
  alerts. This is a timer-based reminder, not native sound integration.
- Local verification: all eight Lua 5.1 suites pass through Lupa, including
  14 successive combat warnings, recast/switch, disabled audio, confirmed
  removal, secret timing, precombat seals, and hidden out-of-combat trackers.
- Pending in-game verification: repeat the reporter's seal/rank combinations,
  casts/expiration inside and outside combat, and early removal. Version stays
  0.1.19; no deployment, release preparation, or publication performed.

Release **0.1.19** was authorized on 2026-10-12 from repaired runtime commit
`80a1059`. The user requested release after the repair was installed; that is
recorded as acceptance for release preparation, not as a detailed test report
for every pending scenario. Enemy dispel and native combat sounds remain the
documented limitations. The work/status notes below preserve the development
history leading to this release.

The TOC remains at **0.1.18**. The first Git commit captures the current working
snapshot, including unreleased work; it is not a release tag or proof of in-game
acceptance. No remote repository is configured.

| Work | Local verification | In-game status |
| --- | --- | --- |
| Gentle refresh chime and separate missing-seal alert, independent choices/toggles/combat filters and previews | All five Lua suites pass; WAV validated and Windows playback succeeded | Pending |
| Sound settings persistence, restricted-data silence, hidden-tracker audio, channels, and fallback | Regression checks pass; see `tests/SOUND-VERIFICATION.md` | Pending |
| False missing-seal display from empty combat lookups | Captured client 1.60.1/build 70338 returned empty after casts and recovered the matching expiration on combat exit. Fix preserves live estimates, honors known removal events, and reconciles outside combat; all six Lua suites pass | Fix awaiting in-game retest; the original reporter's exact seal/rank remains unknown |
| Optional `/psc debug` capture for combat-entry detection | Bounded, deduplicated capture and query classification covered by diagnostics and event tests | Pending reproduction; detection behavior unchanged |
| Cancellation/dispel during empty combat lookups | Added-aura instance tracking and guarded player combat-log removal covered by regression tests | Pending client confirmation of available removal signals |
| Command damage effect incorrectly resets seal timer | Spell 20424 excluded from buff-cast recognition; regression test verifies no timer reset | Pending retest |
| Saved diagnostic capture export to UTF-8 text | Python exporter tested for extraction, escapes, malformed data, and source/output safety; exported 40 saved entries | Report saved locally under ignored `diagnostics/`; diagnosis pending review |

No new release is ready based on local tests alone.

## In-game test record

### 2026-10-16: settings window deployment

- Deployed clean source commit `5db969d` to beta `AddOns/ForeverXP`; all five
  runtime files verified by SHA-256. All ten Lua suites pass.
- Previous installation backed up and verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-5db969d-28e8ea1853ac48d8838600fea3179866`.
- Pending: reload, open `/foreverxp`, exercise both visibility options and bar
  height, close/reopen, and confirm persistence after reload. No release assigned.

### 2026-10-16: XP visibility setting deployment

- Deployed clean source commit `ac7301a` to beta `AddOns/ForeverXP`; all four
  runtime files verified by SHA-256. Focused Forever XP Lua suite passes.
- Previous installation backed up and verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-ac7301a-2c682df50d6648ae97bd920c8b260149`.
- Pending: reload, test `/foreverxp mouseover` and `/foreverxp always`, then
  verify persistence after another reload. No release assigned.

### 2026-10-16: permanent full XP display deployment

- Deployed clean source commit `db8616c` to beta `AddOns/ForeverXP`; all four
  runtime file hashes match. Focused Forever XP Lua suite passes.
- Previous installation backed up and verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-db8616c-d5c29f19e97b4364a90efd6c8d6605ae`.
- Pending: reload and confirm full text stays unchanged on hover/leave while
  the expanded tooltip remains at its default screen anchor. No release assigned.

### 2026-10-16: default tooltip anchor deployment

- Deployed clean source commit `0de4553` to beta `AddOns/ForeverXP`; all four
  runtime file hashes match. Focused Forever XP Lua suite passes.
- Previous installation backed up and verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-0de4553-037dfed241164d52bccf2d6b6911640c`.
- Pending: reload and confirm the expanded tooltip appears at the default
  screen location. No version or release assigned.

### 2026-10-16: Forever XP presentation test deployment

- Deployed clean source commit `9b731b2` to the beta `AddOns/ForeverXP` folder.
  All four runtime files, including the new presentation module and TOC,
  verified by SHA-256 against source.
- Previous installation backed up and verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-9b731b2-9c4e676747c24d999c21ea91b4ef13af`.
- Nine Lua suites pass. Pending: reload, hover the bar/rested tick, gain XP,
  test compact/full and tall/normal, confirm choices survive reload, and check
  reputation layout and combat. No release version assigned.

### 2026-10-16: Forever XP compatibility repair deployment

- Deployed source commit `cd6db65` to the same beta `AddOns/ForeverXP` folder.
  All three installed runtime files match source by SHA-256.
- Previous installation backed up and hashes verified at
  `<workspace>/addon-deployment-backups/ForeverXP-before-cd6db65-91dec53ae2944ca595394b67277c700d`.
- Nine Lua suites pass. Reload and check the bar; use `/foreverxp` if unchanged.
  Disable XPForever if enabled because it hides the default bar. No other
  addons were modified. In-game acceptance and client build remain pending.

### 2026-10-16: Forever XP test deployment

- Installed clean source commit `88475ea` to
  `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/ForeverXP`.
- No existing Forever XP installation was present, so no backup was needed.
  Copied the TOC and two Lua files; all three installed hashes match source.
- All nine Lua suites passed before deployment. No in-game testing performed.
  Enable Forever XP and verify XP gains, level changes, hovering, and combat.
- Client build, visual fit, and user acceptance remain pending. This is an
  unversioned development installation, not a release.

For each test session, append a dated record here containing:

- Git commit and whether the deployed source had uncommitted changes.
- Client version/build and relevant character level, seal, and rank.
- Scenarios tested, expected versus observed behavior, and errors if any.
- Remaining issues and whether the user accepted the build for release.

No in-game results for the unreleased sound changes have been recorded yet.

### 2026-10-12: diagnostic test deployment

- Deployed source commit: `507c2c1`, clean at deployment; TOC remains 0.1.18.
- Target: `C:/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns/PallySealCooldowns`.
- Existing installation backed up to
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-507c2c1-9abda78800f44a12b1c25d367ae4189a`.
- Backup hashes verified before copying; all eight source files verified by hash
  against the installed files afterward. Deployment includes the unreleased
  sound changes and diagnostic mode.
- All six local Lua 5.1 suites passed. No client gameplay was performed.
- Pending: reload/restart the client, enable `/psc debug on`, cast a seal outside
  combat, enter combat, compare the tracker with the buff, then recast in combat.
  Use `/psc debug off` and `/psc debug dump` to collect the results.
- Client build, character level, seal/rank, observed results, and acceptance
  remain pending. This deployment is not a release or a confirmed detection fix.

### 2026-10-12: combat lookup fix deployment

- Deployed clean source commit `bc87432` to the same Forever beta addon folder;
  version remains 0.1.18. All eight source file hashes matched after copying.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-bc87432-35850e4f929845ae89e106335dfc6dd5`.
- All six Lua suites passed, including the captured cast/empty lookup/combat-exit
  sequence, precombat seal retention, confirmed removal, expired uncertain
  estimates without false audio, seal switching, and out-of-combat absence.
- Pending in-game retest: `/reload`, enable diagnostics, cast and enter combat,
  recast/switch/cancel, then leave combat and compare against actual buffs.
  Cancellation without readable removal events may remain estimated until
  reconciliation; this limitation is documented. User acceptance is pending.

### 2026-10-12: cancellation/dispel test deployment

- User confirmed the combat countdown fix works; reported cancellation/dispel
  still retained the estimate.
- Deployed clean source commit `43cbefc` to the same Forever beta addon folder;
  version remains 0.1.18. All eight installed source file hashes verified.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-43cbefc-3e5f4d99e5254276bdd6304e278987af`.
- Six Lua suites passed with new coverage for added-aura instance IDs, matched
  removal, player-specific combat-log removal, unrelated events, secret values,
  and unavailable combat-log reads.
- Pending: reload, enable diagnostics, cast during combat and cancel/dispel the
  buff. Verify immediate removal and one missing-seal alert, then save the capture
  with `/psc debug off` and `/reload`. Client support for these removal signals
  remains unconfirmed; no release acceptance is recorded.

### 2026-10-12: removal retest failed in combat

- Exported 44 entries to ignored `diagnostics/seal-removal-retest.txt`.
- Capture confirms matched UNIT_AURA removal outside combat. During combat,
  casts produce estimates with no observed additions or recognized removals;
  the user confirmed the timer kept counting after cancellation/dispel.
- Combat-log availability was omitted when the API was absent, so the previous
  capture cannot fully establish client capabilities. Expanded diagnostics now
  always report capabilities and UNIT_AURA payload availability/counts.
- The capture also shows spell 20424 repeatedly refreshing the Command estimate.
  Its damage effect now cannot start or restart a seal timer.
- Cancellation/dispel remains unresolved until a usable combat removal signal
  is identified. Expanded diagnostics require a short focused retest.

- Expanded diagnostic source commit `19024ad` deployed clean to the same beta
  addon folder; all eight file hashes verified, version still 0.1.18.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-19024ad-6a1540b0dfe24b5a959bd0025699ab41`.
- Next capture: reload, enable diagnostics, cast in combat, manually cancel the
  buff, disable diagnostics, and reload. This is an investigation build, not a
  confirmed combat cancellation/dispel fix.

### 2026-10-12: combat removal signals are restricted

- Fresh capture exported as 20 entries to ignored
  `diagnostics/seal-removal-capabilities-latest.txt`.
- Client 1.60.1/build 70338 reports `combat-log-api=false registered=false`.
- Combat cast at 1350.5 reports restricted `isFullUpdate` and `addedAuras`;
  no readable instance ID can be attached to this cast.
- Cancellation event at 1353.4 reports restricted `removedAuraInstanceIDs`.
  The event arrives, but the addon cannot identify the removed buff.
- The available alternative aura APIs have not been verified to return usable
  data in this client. Availability alone does not establish readable combat
  results; no automatic combat cancellation/dispel fix is confirmed.
- Do not clear a seal on every UNIT_AURA event, inspect restricted values, or
  treat empty combat queries as proof of removal. These would reintroduce
  false warnings or depend on unsupported access.
- Further implementation requires a supported readable presence/removal signal
  or a native UI mechanism that can consume restricted aura data. A manual
  reset could be offered separately but would not solve automatic dispel tracking.

### Compatibility probe implementation

- Diagnostics now compare GetPlayerAuraBySpellID, GetUnitAuraBySpellID,
  GetAuraDataByAuraInstanceID, and the known-instance HELPFUL filter result.
- Use only readable known seal/rank and instance IDs; record safe outcomes
  without raw errors or restricted-value inspection. Deduplicate stable probes.
- Retain a known instance for an after-removal comparison, and explicitly report
  unknown instances for casts not observed outside combat. Probes do not change
  detection logic, timers, or release version.
- Pending: compare active versus cancelled seals in combat, first with a known
  precombat instance, then with a fresh cast made entirely in combat.
- All six Lua 5.1 suites passed. Deployed clean source commit `5788153` to the
  same beta addon folder, with all eight file hashes verified; version is 0.1.18.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-5788153-a943a360fb534f56a8b3e702d5363a5d`.
- In-game compatibility results and cancellation/dispel acceptance remain pending.

### 2026-10-12: compatibility results

- Fresh capture: 65 entries exported to ignored
  `diagnostics/seal-compatibility-final.txt`.
- Command instance 139 was found outside combat at 1951.6 and briefly on combat
  entry at 1954.3. By 1954.6 both spell-ID queries returned empty and both the
  instance lookup and HELPFUL filter probe returned errors. Command damage
  spell 20424 occurred at 1955.5, supporting that empty queries were not proof
  the seal was absent. The damage effect was correctly ignored as a buff cast.
- Restricted removal events arrived during combat without readable IDs. No
  successful alternative lookup distinguished cancellation in combat.
- On combat exit at 1972.4, instance lookup returned empty and filter returned
  true, and the tracker reconciled to missing. That does not solve immediate
  combat cancellation/dispel tracking.
- This capture contains one observed seal application; it does not separately
  verify a fresh seal cast entirely during combat. Repeating that case is not
  needed to justify rejecting empty lookup results as confirmed removal.
- Remaining investigation: a supported native aura display that can consume
  restricted data. Such a mechanism has not been established for this client.
  Current estimate tracking remains the verified fallback; cancellation/dispel
  acceptance is still unresolved. Do not establish a release from these results.

### Native aura-container prototype

- `/psc native on|off` controls a separate session-only test icon outside combat.
  It uses CustomAuraContainerTemplate, a HELPFUL slot filtered to seal ranks,
  and native icon, duration, and spell-name bindings. It never reads restricted
  button state, visibility, geometry, or text.
- Rank IDs are attributed to talentsforever.com via the installed ForeverAuras
  dataset under CC BY 4.0; implementation uses Blizzard's public container API
  independently, with no ForeverAuras runtime dependency.
- Fixed-size icon appears beside the existing tracker. Sound, missing-seal
  animation, bar layout, and replacement of the original display are deferred
  until native presence/removal is verified in this client.
- Seven Lua 5.1 suites pass, including native binding setup, rank filtering,
  combat guards, repeated enable/disable, and graceful initialization failure.
- Pending: enable outside combat, test precombat and in-combat casts, cancel and
  dispel, and confirm the native icon disappears immediately while its label
  remains. Do not interpret initialization tests as in-game acceptance.
- Deployed clean source commit `244e5a4` to the same beta addon folder. All nine
  source hashes verified after copying; version remains 0.1.18.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-244e5a4-94cd2f8107e54ad88b55ee3a964e10d9`.

### 2026-10-12: native manual cancellation confirmed

- User confirmed that the NATIVE SEAL TEST icon disappears immediately when
  the seal is cancelled during the requested in-game trial of `244e5a4`.
- This validates native visual removal for manual cancellation in combat,
  without requiring Lua to inspect restricted aura state.
- Enemy dispel, all seal ranks, both production layouts, and sound behavior
  remain unverified. The existing estimated tracker has not been replaced.
- Next implementation step: integrate native aura bindings into the production
  display, then verify the icon/bar layouts and missing-seal presentation.
  Sound notifications require a supported native trigger and separate testing.
- Version remains 0.1.18; this confirmation is prototype acceptance, not release
  acceptance for the complete addon.

### Native display integration

- Main tracker initializes a native aura slot automatically on supported clients,
  binding the seal icon, countdown, name, and duration bar. The existing Lua
  tracker is retained as an initialization fallback and a source of readable
  diagnostics; its rendering is disabled when native owns presentation.
- Native HELPFUL presence-group geometry clips the missing-seal icon/text and
  combat glow/bounce without observing secret visibility, text, size, or values.
- Both icon and bar layouts preserve saved position/scale and appearance/text
  controls. Refresh-only countdown and warning text use native duration color
  curves. Configuration changes during combat defer until combat ends.
- No sound is inferred from restricted native visibility. Previews remain;
  refresh sounds use only an observed timer, outside-combat missing sounds use
  readable absence. Native combat removal/entry sounds remain pending rather
  than issuing alerts from obsolete estimates.
- Eight Lua 5.1 suites pass, including native layout/binding configuration,
  missing clipping anchors, combat deferral, initialization fallback, stable
  animations, and suppression of legacy renders. Actual native clipping and
  layout must still be checked in game.
- Pending acceptance: main icon and bar with active seals, combat casts and
  cancellation, enemy dispel, missing presentation, refresh countdown/warning,
  saved settings and visibility after reload. Version remains 0.1.18.
- Deployed clean source commit `b69846d` to the same beta addon folder. All ten
  addon file hashes verified against the source after copying.
- Verified backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-b69846d-b9536051a40c4769ad43ba61f4adac41`.
- After reload the main tracker uses native display automatically when available;
  no prototype command is required. In-game integration acceptance is pending.

### 2026-10-12: native integration failure and recovery

- User reported the integrated build failed and supplied a Backdrop.lua error:
  native descendant width was secret during a SetBackdrop call from Apply.
  The native gold/tooltip border with thickness 12 reproduced the path.
- Restored the nine-file pre-integration `244e5a4` backup and verified hashes.
  Preserved the failed installation at
  `<workspace>/addon-deployment-backups/PallySealCooldowns-failed-b69846d-14a2f530b332428d8fa243a3612b2dec`.
- Recovery restored the legacy main tracker and its known cancellation limitation;
  this was not acceptance or a fix of the native integration.
- Repair removes BackdropTemplate and backdrop calls from native descendants.
  Borders use eight precreated textures with sizes/coordinates derived only from
  configured icon size and border thickness, without querying frame geometry.
- Regression tests now reject backdrop templates/calls and all native size/scale
  queries. Reapplying the gold border, switching icon/bar layouts, and selecting
  none/solid borders pass. All eight Lua 5.1 suites pass after the repair.
- Repaired native integration still needs in-game cancellation and appearance
  confirmation. Earlier mock-only acceptance missed the backdrop dependency.
- User noted recovery no longer detected cancellation; explained that the restored
  legacy build retains that limitation. Deployed repaired native source commit
  `80a1059` to the same beta addon folder, clean at deployment; ten hashes verified.
- Verified recovery backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-80a1059-cdb5bfca1b0f4fc98194b6954251e4ad`.
- Pending: reload, use the gold preset, move/restyle the main tracker, and cancel
  a seal during combat. Native integration acceptance is still pending.

### 2026-10-12: 0.1.19 release preparation

- User requested release of the repaired integration. Assigned next patch
  version 0.1.19; updated the TOC, changelog, README, project description, and
  upload guide together.
- Runtime Lua code matches `80a1059`; only release metadata/documentation and
  the packaged rank-data notice were added. No new behavior was introduced.
- Eight Lua 5.1 suites and three Python exporter tests passed.
- Release archive: `dist/PallySealCooldowns-0.1.19.zip`, built from the release
  Git tag `v0.1.19`; one top-level addon folder, required sound asset and NOTICE,
  no tests, scripts, settings captures, backups, or development dependencies.
- Public upload/publishing is separate from preparation. No remote is configured;
  the archive, commit, and tag are local. Native combat sound integration and
  independently documented enemy-dispel confirmation remain outstanding.

## 2026-10-17: Forever XP project relocation

ForeverXP and its two tests moved to ../wow-addons-foreverXpBar.
Earlier entries above are historical; future Forever XP work belongs in that project. Git history through 5db969d remains here.
