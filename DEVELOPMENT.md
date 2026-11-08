# Development and release workflow

Features and fixes are developed and tested in game before establishing a new
release version. Git commits track development independently of release numbers.

## Development cycle

1. Make a focused change and add regression coverage for changed behavior.
2. Run the local checks. Record what passed and what still needs the client.
3. Leave the change uncommitted in the working tree. Do not commit each edit;
   iterate on the working tree through in-game testing.
4. The Forever client loads the addon through a directory junction to this
   repository's `PallySealCooldowns` folder, so saved edits go live on the next
   `/reload`. Restart the client after adding files or changing the TOC. Do not
   bump the TOC version or build a release archive for this step. Remove the link
   only with `cmd /c rmdir "<client addon folder>"`, never a recursive delete,
   which can delete the source files.
5. Record the base Git commit (`git rev-parse --short HEAD`), the uncommitted
   changes under test (`git status --short`), client build, date, scenarios, and
   observed results. Compare timers with actual buffs; test combat entry,
   recasts, seal switches, cancellation, expiration, sound controls, both
   layouts, and settings after `/reload`.
6. Fix problems, rerun the relevant local checks, `/reload`, and repeat in-game
   testing until the user accepts the results. Record untested cases as pending.
7. After the user accepts the in-game results, commit the source, tests,
   documentation, and required assets together, and update the unreleased work
   below with the scope and verification status.

Run all local checks from the repository root with Docker Desktop running:

```powershell
scripts/check.ps1
```

This runs `scripts/check.sh` in the same Ubuntu release and packages as CI:
luacheck, the Lua and Python tests, and the TOC check. Test dependencies are not
shipped with the addon.

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
   Pushing a `v*` tag is the publish step: `.github/workflows/ci-release.yml`
   reruns the checks, requires the tag to match the TOC version and
   `release/changelog-<version>.md`, then creates the GitHub Release and uploads
   to CurseForge. Push one tag by name, and never push a tag while preparing.
5. After publishing, move that release's entries below unchanged to the top of
   `docs/development-history.md`, and carry anything still pending forward as a
   new entry.

## Current unreleased work

Log what Git cannot show: in-game results, uncommitted test builds, and release
status. Entries from shipped releases are in `docs/development-history.md`.

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
