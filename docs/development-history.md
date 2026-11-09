# Development history

Dated entries moved from `DEVELOPMENT.md` once their release shipped, newest
first, including in-game test records. Each entry describes the project as it
was then. Current process and open work are in `DEVELOPMENT.md`.

## Development log

### 2026-11-08: 0.1.25 release preparation

- User accepted the in-game results ("love it") and requested a new version. Chose
  patch version 0.1.25 following the 0.1.x pattern. Scope since `v0.1.24`: the
  entries below.
- Updated the TOC, `release/changelog-0.1.25.md`, `release/curseforge-description.md`
  (also its stale sound limitations and client folder), and `release/UPLOAD-GUIDE.md`.
- `v0.1.24` was tagged locally but never pushed, and GitHub had no releases, so this
  is the pipeline's first real upload. Which versions CurseForge already has was not
  checked.

### 2026-11-08: Swing bar size and zero time when no seal is active

- The swing bar was half the width of Blizzard's main-hand timer: 213 was the stored
  Edit Mode value, which `ConvertValueDiffFromMin` adds to the slider's 213 minimum.
  The Modern layout's default is 426 x 30 (the Classic layout's would be 333 x 21).
  Forever source 1.60.1.70862. New `swingWidth` setting, default 426, range 213–852
  like Edit Mode, shown as **Swing bar width**. **Bar width** now applies only to the
  small icon layout. Existing swing bars move to 426, including customized ones.
- New **Missing symbol** choice, **Zero time (0.0)**, in white like Blizzard's idle
  swing timer, on every layout. The default stays "!".
- Added regression tests, which failed before the changes. `scripts/check.ps1` passes.
- User reported "love it" after a checklist covering the size beside the main-hand
  timer, "0.0" with no seal, and **Swing bar width** and reset. No per-item results
  were reported.

### 2026-11-08: Essential Cooldowns icon matches Blizzard's by default

- Matched `CooldownViewerEssentialItemTemplate` from Blizzard's public UI source. The
  values were first read from retail 12.1.5.70783, then confirmed unchanged in the
  Forever branch (1.60.1.70862): overlay margins of 9/8 px at 50 px, scaling with the icon; the rounded swipe
  texture; the swipe drawn over the overlay; and `ITEM_COOLDOWN_COLOR` unreversed.
  The user first chose Blizzard's gold active-buff color, then decided against it.
  Other layouts keep their look.
- The bar, seal name, and status text below the icon now default off on this layout.
  New `cdmShowBar`, `cdmShowName`, and `cdmShowStatus` hold its choices, so existing
  Essential users lose those extras until they re-enable them, and other layouts'
  settings are unchanged. Choosing a layout now refreshes the settings checkboxes.
- Kept on purpose: the missing-seal state (placeholder icon, warning-colored overlay,
  "!", combat alert), which Blizzard's icons have no equivalent for; the countdown
  turning the warning color at the refresh threshold; and the saved border and font
  choices.
- **Gap from bar** now defaults to 1 px, Blizzard's default icon spacing in that
  source (`iconPadding` 5, offset -4). A saved 2 px, the old default, updates to 1 px
  once, chosen by the user.
- User reported that reset does not work for all layouts. It reset only position and
  scale, which the Essential icon ignores or compensates for, and never bar width.
  **Reset position and size** and `/psc reset` now also restore the current layout's
  bar width, or the Essential icon's size, snap position, and gap.
- Added regression tests, which failed before the changes. `scripts/check.ps1`
  passes. Mock tests cannot show how it looks.
- User reported "i like it hkow it is" after a checklist covering the icon beside the
  bar's icons, the swipe, nothing below the icon, reset on each layout, and other
  layouts unchanged. No per-item results were reported.

### 2026-11-08: no missing-seal sound on death

- On the native display, the missing-seal sound now stays silent when a seal is
  lost to death, and after resurrection until a seal has been active again. Added a
  regression test, which failed before the fix. `scripts/check.ps1` passes.
- CI now installs `python3` explicitly, matching `scripts/check.ps1`.
- From a code review, not seen in game and deliberately not fixed. Fix one only if
  it shows up in play:
  - One empty lookup at combat exit, on zoning, or during a seal switch could play a
    false alert. A one-second confirmation handled this in a discarded build.
  - After a `/reload` in combat, a seal lost in that fight may not warn.
  - A loss seen with the sound off can play when the sound is enabled.
  - With **Hide outside combat** on, the hidden tracker stops polling, so the
    out-of-combat sound checks run only on aura events.
- In game pending: dying with a seal up plays no sound. The check relies on the game
  reporting death by the time the seal's removal is seen. Committed at the user's
  request before this in-game result. No version change.

### 2026-11-08: missing-seal sound on the native display

- Fixed: with the native display and default settings, the missing-seal sound
  never played automatically. `Render` checks it only outside combat, while
  `missingCombatOnly` (default on) requires combat.
- The native display now ignores that option and hides its checkbox. The saved
  value is kept, and the older tracker still honors it. The sound plays once after
  a seal ends outside combat, or after combat for one lost during combat. Login
  and `/reload` without a seal stay quiet until a seal has been active, including
  for players who had already unchecked the box.
- Added regression tests; the sound test failed on the old code. `scripts/check.ps1`
  passes with the fix. The new settings hint text has no test.
- User reported after the in-game checklist: "I think everything checks out". The
  checklist covered the sound after a seal expires outside combat and after combat;
  no sound at login, `/reload`, or in combat; no false alert on loading screens;
  and the checkbox hidden on the Alerts page. No per-item results were reported.
- At release, update `release/curseforge-description.md`, whose sound limitations
  text predates this. No version change.

### 2026-11-08: README corrections

- Corrected the README's icon size, warning color, bar size, test command, and
  missing-seal sound descriptions. No runtime or version change.

### 2026-11-08: Development log trimmed to open work

- Moved entries through the 0.1.24 release, unchanged, to
  `docs/development-history.md`, and added `docs` to the `.pkgmeta` ignore list.
  No runtime changes, version change, or in-game testing needed.
- Carried forward from the history: the log shows these as pending, with no
  specific later confirmation found. Release acceptance may have covered some, so
  they may be stale. Not a complete list; search the history for "pending".
  - Command damage (spell 20424) no longer resets the seal timer: retest.
  - Sound checks: how each bundled sound sounds and its volume against game audio,
    Ready check and Alarm clock on Forever 1.60.1, and SharedMedia listing and
    playback.
  - Essential Cooldowns icon: no taint in combat, and Edit Mode follow behavior.
  - Combat cancellation and dispel: which removal signals the client provides.
    Enemy dispel remains a documented limitation.

### 2026-11-08: Local check script and linked in-game testing

- Added `scripts/check.sh`, now called by CI, and `scripts/check.ps1`, which runs
  it in Docker. Added `.gitattributes` and `.vscode/extensions.json`. The
  in-game process now uses a junction instead of copied deployments.
- `scripts/check.ps1` passes locally. In throwaway copies, a lint typo, a failing
  test, and a missing TOC file each stop it with a non-zero exit at the expected
  stage. A `release.sh -d` dry run produced a ZIP with one `PallySealCooldowns`
  folder and no development files.
- The updated workflow has not run on GitHub yet. No runtime changes, version
  change, or in-game testing needed.
- Junction created 2026-11-08 with the client closed, on base commit `4ae7613` plus
  the uncommitted changes in `git status`. The client addon folder now points to
  this repository's `PallySealCooldowns` folder. All 23 files read through the link
  match the source by SHA-256, and the 23-file backup matches the original by
  SHA-256. Backup:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-junction-4ae7613-4bd0a701-e503-47cc-8727-98de09db86f7`.
- User reported "I think everything checks out" after a checklist that included
  the addon loading through the link and an edit appearing after `/reload`.

### 2026-11-08: CI and release pipeline

- Added `.github/workflows/ci-release.yml`, `.pkgmeta`, and `.luacheckrc`. Pushes
  and pull requests run luacheck, the Lua and Python tests, and the TOC check.
  Pushing a `v*` tag also packages with `BigWigsMods/packager`.
- The TOC keeps its literal version, not `@project-version@`, so test deployments
  still show the last released version.
- Tested in an Ubuntu 24.04 container: the check steps and `release.sh -d` pass,
  and the failure cases (Lua test, lint typo, missing TOC file, tag mismatch,
  missing changelog) each stop the job. The ZIP matches the addon folder apart
  from CRLF line endings added by the packager.
- User reported the push and tag workflows passing on GitHub Actions in a
  private test repo, from a commit without the project ID so that no upload was
  possible. A real CurseForge upload is still unverified.
- Added `X-Curse-Project-ID` to the TOC; `CF_API_TOKEN` is a repository secret. No
  runtime changes, version change, or in-game testing needed.

### 2026-11-07: 0.1.24 release preparation

- User accepted the in-game results ("looks great") for the Essential-only
  snapping deployment, which contains all work below, and requested a
  release. Chose patch version 0.1.24 with the user, following the
  0.1.21–0.1.23 precedent.
- Scope since `v0.1.23`: the Swing timer bar layout built on Blizzard's swing
  timer atlases with the fixed "Seal Timer" label and tenths countdown;
  layout-aware settings; swing-safe presets; snapping only for the Essential
  Cooldowns icon with the snap checkbox removed (entries below).
- Updated the TOC, README, `release/changelog-0.1.24.md` (new),
  `release/curseforge-description.md` (four layouts, Essential-only
  snapping, presets, `/psc style swing`), and `release/UPLOAD-GUIDE.md`. Also
  repaired a non-UTF-8 byte in the upload guide's source/issues separator.
- Runtime files match the accepted test build (`diff -r` shows only the TOC
  version line).
- Ten Lua 5.1 suites (Lupa) and three Python exporter tests passed; TOC files
  present; `git diff --check` clean.
- Release archive: `dist/PallySealCooldowns-0.1.24.zip`, built with
  `git archive` from tag `v0.1.24`. Public upload is a separate step; the
  commit, tag, and archive are local.

### 2026-11-07: test deployment of Essential-only snapping

- Base commit `c0703df` plus uncommitted `Appearance.lua`,
  `CooldownManager.lua`, `NativeDisplay.lua`, `PallySealCooldowns.lua`, and
  `Settings.lua` (everything in the entries below). Supersedes the
  layout-aware settings deployment.
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup of the previous test build:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-b54ccea3-382b-4865-9d85-4ab1a2572b6d`;
  all 23 files matched by SHA-256. All 23 deployed files match the source by
  SHA-256, with no extra files. TOC version unchanged (0.1.23); no archive.
- In-game checklist: `/reload`; Essential icon attaches to the bar and
  follows it in Edit Mode, with Snap position and Gap from bar under its
  options; the other three layouts show no snap options, stay at their saved
  position, drag when unlocked, and never print the bar-not-found message;
  `/psc status`; no snap checkbox anywhere.
- In-game acceptance pending.

### 2026-11-07: snapping is the Essential Cooldowns icon's behavior

- User decided only the Essential Cooldowns icon should snap, and that
  snapping should not be a setting. Supersedes the swing-only snap change
  below. `SnapToCooldownViewer` now snaps exactly when the layout is
  `essential`; the Snap to Essential Cooldowns bar checkbox is removed and
  `NormalizeCooldownManager` drops the saved `snapToCDM` value. Snap
  position, Gap from bar, and the placement note now sit under Essential
  icon size and show only for that layout. The bar-not-found warning and
  `/psc status` snap state apply only to the Essential icon.
- Behavior change for existing users: a Large icon or Small icon with timer
  bar tracker that was snapped now uses its saved free position; an
  Essential icon that was not snapped now attaches to the bar.
- Ten Lua 5.1 suites (Lupa) passed with updated cooldown manager, addon
  event, and settings tests; `git diff --check` clean. Not deployed;
  in-game check pending. `release/curseforge-description.md` still
  describes snapping as an option and is updated at release.

### 2026-11-07: no Essential Cooldowns snapping for the Swing timer bar

- User asked that snapping not be an option for the swing bar. The snap
  heading, checkbox, position, gap, and hint are hidden on that layout,
  and `SnapToCooldownViewer` returns false for it, so a saved snap setting
  neither anchors the bar nor prints the "bar not found" warning; the bar
  stays free and draggable. `/psc status` omits the snap state there.
  Switching to another layout snaps again with the saved setting.
- Ten Lua 5.1 suites (Lupa) passed, with new coverage in the cooldown
  manager, addon event, and settings tests; `git diff --check` clean.
  Not deployed; in-game check pending.

### 2026-11-07: test deployment of layout-aware settings and presets

- Base commit `c0703df` plus uncommitted `Appearance.lua`, `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, and `Settings.lua` (everything in the entries
  below). Supersedes the "Seal Timer" label deployment.
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup of the previous test build:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-1c5ba2f9-9fba-433b-b24d-fd91aa1e8cd1`;
  all 23 files matched by SHA-256. All 23 deployed files match the source by
  SHA-256, with no extra files. TOC version unchanged (0.1.23); no archive.
- In-game checklist: `/reload`; in both the `/psc` window and Options >
  AddOns, switch each layout and confirm only its options show with no gaps
  or overlaps; the Layout heading names the layout; toggling Show duration
  bar under icon and Border None hide their dependent options at once; on
  the swing bar, presets keep Blizzard's fill and frame and Classic Gold and
  Paladin Pink are hidden; settings persist after `/reload`.
- In-game acceptance pending.

### 2026-11-07: layout-aware settings and presets

- User asked that settings show only what applies to the chosen layout,
  and that presets be cleaned up. Settings rows now register with an
  optional condition; `panel:Relayout()` (after every change and on
  Synchronize) hides rows that do not apply and moves later rows up.
- Hidden by layout: Show seal name (swing); Show duration bar under icon
  (bar, swing); Essential icon size (all but Essential); Bar width (icon,
  Essential); Bar texture and Bar counts down (icon layouts with the icon
  bar off); Placeholder icon (swing); Border color (swing, or Border None);
  Custom border thickness (swing, Border None, or default border). The
  Layout page heading names the chosen layout; the name font slider reads
  "Label font size" on the swing bar.
- Presets: on the swing bar they keep `statusbar`, `border`, `borderColor`,
  and `borderSize`, so Blizzard's fill and frame survive (Minimal, High
  Contrast, Paladin Pink, and Clean Text used to switch the fill to flat
  gold). Classic Gold and Paladin Pink are hidden there.
- Ten Lua 5.1 suites (Lupa) passed, with new coverage in the settings and
  appearance tests; `git diff --check` clean. Not deployed; in-game check
  pending (both the standalone window and Blizzard Settings pages).

### 2026-11-07: "Seal Timer" label visibility fix and test deployment

- User reported the label still missing (with `/fstack` showing the overlay
  frame on top). Actual cause, from the client's saved variables: Show seal
  name and Show missing-seal text were both off, and the label followed those
  options. The previous entry's native-binding theory was not the cause (the
  separate font string is kept). "Seal Timer" is now a fixed title in the
  swing layout, shown regardless of those options, like Blizzard's "Main
  Hand"; the label shadow follows it. Other layouts unchanged.
- Ten Lua 5.1 suites (Lupa) passed, with regressions for both options off in
  the native display and addon event tests; `git diff --check` clean.
- Deployed on base commit `c0703df` plus uncommitted `Appearance.lua`,
  `NativeDisplay.lua`, `PallySealCooldowns.lua`, and `Settings.lua`. Backup of
  the previous test build:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-6eb7d61c-8f95-4cac-9f46-677d9cf15fcd`;
  all 23 files matched by SHA-256. All 23 deployed files match the source by
  SHA-256, with no extra files. TOC version unchanged (0.1.23); no archive.
- In-game checklist: `/reload`; "Seal Timer" shows with and without a seal
  while Show seal name is off; other layouts still hide the seal name.
- In-game acceptance pending.

### 2026-11-07: fix and test deployment for the missing "Seal Timer" label

- User reported in game that the "Seal Timer" text did not appear. Likely
  cause: the label was written into the font string the native button binds
  for the spell name, which the native button clears after the binding is
  removed. The swing layout now uses its own font string (`view.label`) that
  is never natively bound; the bound name string is hidden in this layout.
  Not confirmed in game which state (with or without a seal) was affected.
- Ten Lua 5.1 suites (Lupa) passed; `git diff --check` clean.
- Deployed `NativeDisplay.lua` change on top of the previous build (base
  commit `c0703df` plus uncommitted `Appearance.lua`, `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, and `Settings.lua`). Backup of the previous test
  build:
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-debf760c-dbc3-410c-9a71-e76b70ee419a`;
  all 23 files matched by SHA-256. All 23 deployed files match the source by
  SHA-256, with no extra files. TOC version unchanged (0.1.23); no archive.
- In-game checklist: `/reload`; "Seal Timer" shows with a seal, after a seal
  switch, and with no seal; Show seal name hides it; other layouts show the
  seal name.
- In-game acceptance pending.

### 2026-11-07: test deployment of the "Seal Timer" label

- User reported the atlas-based Swing timer bar "looks good" in game and
  asked for "Seal Timer" on the left of the bar. The swing layout now shows
  the fixed label "Seal Timer" (like Blizzard's "Main Hand") instead of the
  seal name, in every state; the native seal-name binding is cleared for this
  layout. Show seal name still toggles the label. Other layouts unchanged.
- Ten Lua 5.1 suites (Lupa) passed, with label coverage in the native display
  and addon event tests; `git diff --check` clean.
- Base commit `c0703df` plus uncommitted `Appearance.lua`, `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, and `Settings.lua`. Supersedes the atlas-based
  test deployment below.
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup (the atlas-based test build):
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-e9ff03bf-f149-41e7-9947-f452bf2be28e`;
  all 23 files matched by SHA-256.
- All 23 deployed files match the source by SHA-256, with no extra files.
  Saved variables and other addons untouched; TOC version unchanged
  (0.1.23); no archive built.
- In-game checklist: `/reload`; the bar reads "Seal Timer" with a seal, after
  a seal switch, and with no seal; other layouts still show the seal name.
- In-game acceptance pending.

### 2026-11-07: test deployment of the atlas-based Swing timer bar

- Base commit `c0703df` plus uncommitted `Appearance.lua`, `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, and `Settings.lua`. Supersedes the drawn-frame
  test deployment earlier today.
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup (the drawn-frame test build):
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-382f20af-ff36-467c-a4a8-571869ae716b`;
  all 23 files matched by SHA-256.
- All 23 deployed files match the source by SHA-256, with no extra files.
  Saved variables and other addons untouched; TOC version unchanged
  (0.1.23); no archive built.
- In-game checklist: `/reload`; with Swing timer bar chosen, compare side by
  side with Blizzard's main-hand bar (frame, background, fill color, pip at
  the fill edge, label shadow, font, 213 x 30 size); tenths countdown on the
  native display; warning color at the refresh threshold; no pip and the
  glow/bounce when no seal is active in combat; Bar texture and Border None
  options; switching to and from the other layouts; persists after `/reload`.
- In-game acceptance pending.

### 2026-11-07: test deployment of the Swing timer bar layout

- Base commit `c0703df` plus uncommitted `Appearance.lua`, `NativeDisplay.lua`,
  `PallySealCooldowns.lua`, and `Settings.lua` (tests and docs are not shipped).
- Target: `C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/PallySealCooldowns`.
- Backup (the 0.1.23 release build):
  `<workspace>/addon-deployment-backups/PallySealCooldowns-before-c0703df-uncommitted-f47abfbb-a755-409b-83bc-18fc292b3163`;
  all 23 files matched by SHA-256.
- All 23 deployed files match the source by SHA-256, with no extra files.
  Saved variables and other addons untouched; TOC version unchanged
  (0.1.23); no archive built.
- In-game checklist: `/reload`; pick Swing timer bar from the Layout
  dropdown and with `/psc style swing`; compare with the built-in swing
  timer; countdown shows tenths (`12.3`) on the native display; fill and
  warning color at the refresh threshold; missing state, glow, and bounce
  in combat; Border None removes the frame; Bar width, texture, and
  countdown options; switching back to the other three layouts restores
  their icons; choice persists after `/reload`.
- In-game acceptance pending.
- Superseded in source: this build used the drawn bronze frame. The layout
  was then rebuilt on Blizzard's swing timer atlases (entry below), which is
  not yet deployed.

### 2026-11-07: Swing timer bar layout

- New fourth layout, **Swing timer bar** (`/psc style swing`), matching
  Forever's built-in main-hand swing timer (`SwingTimerMainHandFrame`, found
  with `/fstack`). Its art and geometry follow `Blizzard_SwingTimer.xml` in
  the public UI source mirror (Gethe/wow-ui-source, `forever` branch): atlases
  `ui-swingtimerbar-background`, `-frame`, `-filling-mainhand`, `-pip`, and
  `-textshadow-left` (171 px); bar inset 5/4 px; `GameFontHighlightSmall`
  labels 10 px inside; tenths countdown. Only atlas names and layout values
  are reused; Blizzard's template is not inherited, so no Edit Mode or swing
  event code runs. Size is 30 px tall and Bar width + 25 (213 at the default,
  Blizzard's minimum width).
- The atlas fill keeps its own color (white vertex) until the refresh
  warning; a chosen Bar texture replaces it with the gold fill. The pip
  follows the fill's edge and hides without a seal. Border None removes the
  frame. Clients without the atlases fall back to a drawn bronze frame.
- Works for the native display and the estimated tracker. The native icon
  and swipe stay bound but use alpha 0; the missing-seal glow surrounds the
  whole bar. Settings Layout page lists it and shares the bar width,
  texture, and countdown options with it.
- Ten Lua 5.1 suites (Lupa) passed with new coverage in the native display
  (atlases, size, pip, fill, fallback frame), addon event, appearance, and
  settings tests; `git diff --check` clean.
- Pending in game: the look against the real swing timer, the pip position,
  that the native `%.1f` countdown renders, warning colors, missing state
  and glow, and switching layouts in and out.
- Not deployed; no version change.

### 2026-11-07: public repository preparation

- Added the MIT `LICENSE`; README, upload guide, and `NOTICE.md` now name it.
  The rank data keeps its CC BY 4.0 attribution.
- Rewrote the unpublished Git history before the first push: commit and tag
  emails now use the GitHub noreply address, and local paths in this file
  were replaced with `<workspace>/` in every commit. File contents otherwise
  match, and the shipped addon folder is identical at every release tag. A
  stray local undo-checkpoint ref from another tool was removed. Backup
  bundles of the old history are kept outside the repository.
- Commit IDs changed, so IDs in older entries refer to the old history. Old to
  new: 2229e14 → 38c85a9 (v0.1.22), a79034f → 4ae62e5 (v0.1.21),
  d66b956 → 03c54a8 (v0.1.20), a1ec025 → eafb044, 5db969d → 5cebbf7,
  ac7301a → 8c9e3fc, db8616c → 141b0b2, 0de4553 → a6d055b,
  9b731b2 → 14c92b1, cd6db65 → b7fc7a2, 88475ea → 5cf4a44,
  63620a5 → e38c97f, 80a1059 → da8d40c, b69846d → 90a4466,
  244e5a4 → a6107f5, 5788153 → d22d9df, 19024ad → f976594,
  43cbefc → 04b82ce, bc87432 → 018722a, 507c2c1 → 92854ac,
  e40ea62 → 88c5045 (v0.1.23).
- `AGENTS.md` now forbids personal paths and identifiers in committed files.
- No runtime code change; `NOTICE.md` wording changes in the next release.

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
