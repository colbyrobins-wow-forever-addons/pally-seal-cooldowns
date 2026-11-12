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

Without Docker, run each `tests/*_test.lua` from the repository root with any Lua
5.1 runtime, such as `lua` or Lupa's `lupa.lua51.LuaRuntime().execute(...)`. This
skips luacheck, so say so when recording results.

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

### 2026-11-11: 0.1.26 release preparation

- User requested a release ("push a new release") without reporting in-game
  results. Recorded as release authorization, not in-game confirmation: the
  Blizzard Cooldown Manager layout below is untested in game.
- Chose patch version 0.1.26 following the 0.1.x pattern. Scope since `v0.1.25`:
  the entry below.
- Updated the TOC, README version, `release/changelog-0.1.26.md`,
  `release/curseforge-description.md`, and `release/UPLOAD-GUIDE.md`.
- Local Lua suites pass under Lupa; luacheck runs in CI because Docker Desktop was
  not running.

### 2026-11-11: Blizzard Cooldown Manager layout (alerts only)

- New fifth layout, **Blizzard Cooldown Manager** (`/psc style blizzard`), for
  seals tracked by Blizzard's own Cooldown Manager. The addon draws nothing: the
  tracker frame is set to alpha 0, is not clickable, and ignores **Hide outside
  combat** and **Hide tracker when no seal is active**, so its update loop keeps
  polling auras. The refresh and missing-seal sounds and the **Refresh warning**
  time still apply. Settings pages hide every option for the tracker's look and
  position. Presets are not offered. A missing-seal placeholder was tried and
  removed at the user's request.
- Local tests: all Lua suites pass under Lupa. Docker Desktop was not running, so
  luacheck was not run.
- In game, pending: Blizzard's Cooldown Manager shows the seal while this addon
  shows nothing; refresh and missing-seal sounds still play on the native display
  and the estimated tracker; Refresh warning changes when the refresh sound plays;
  switching to and from the layout outside combat; settings pages list only the
  alert options.
- No version change. Uncommitted.

### 2026-11-08: Carried forward from 0.1.25

- Published `v0.1.25` by tag. GitHub Actions passed and created the GitHub Release
  with `PallySealCooldowns-v0.1.25-forever.zip`. The upload step passed with no
  skipped-upload warning, but the public CurseForge listing still showed 0.1.24
  right after the run, so the file was not confirmed there.
- The CurseForge project description is updated by hand from
  `release/curseforge-description.md`; not done yet.
- In game, with no specific result reported: dying with a seal up plays no sound.
- Known limitations from code review, not seen in game; fix only if they show up:
  - One empty lookup at combat exit, on zoning, or during a seal switch could play a
    false missing-seal alert.
  - After a `/reload` in combat, a seal lost in that fight may not warn.
  - A loss seen with the sound off can play when the sound is enabled.
  - With **Hide outside combat** on, the hidden tracker stops polling, so the
    out-of-combat sound checks run only on aura events.
- Older items with no specific later confirmation; they may be stale:
  - Command damage (spell 20424) no longer resets the seal timer: retest.
  - Sound checks: how each bundled sound sounds and its volume against game audio,
    Ready check and Alarm clock on Forever 1.60.1, and SharedMedia listing and
    playback.
  - Essential Cooldowns icon: no taint in combat, and Edit Mode follow behavior.
  - Combat cancellation and dispel: which removal signals the client provides.
    Enemy dispel remains a documented limitation.
