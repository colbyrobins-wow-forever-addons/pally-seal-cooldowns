# Development and release workflow

Features and fixes are developed and tested in game before establishing a new
release version. Git commits track development independently of release numbers.

## Development cycle

1. Make a focused change and add regression coverage for changed behavior.
2. Run the local Lua tests. Record what passed and what still needs the client.
3. Commit the source, tests, documentation, and required assets. Update the
   unreleased work below when scope or verification status changes.
4. When in-game deployment is requested, confirm the actual client addon path,
   back up its existing addon folder outside the source tree, and copy only the
   `PallySealCooldowns` folder, including its sound assets. Do not bump the TOC
   version or build a release archive for this step.
5. Record the tested Git commit (`git rev-parse --short HEAD`), any uncommitted
   changes, client build, date, scenarios, and observed results. Compare timers
   with actual buffs; test combat entry, recasts, seal switches, cancellation,
   expiration, sound controls, both layouts, and settings after `/reload`.
6. Fix problems, rerun relevant local tests, and repeat in-game testing until the
   user accepts the results. Record untested cases as pending.

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

The TOC remains at **0.1.18**. The first Git commit captures the current working
snapshot, including unreleased work; it is not a release tag or proof of in-game
acceptance. No remote repository is configured.

| Work | Local verification | In-game status |
| --- | --- | --- |
| Gentle refresh chime and separate missing-seal alert, independent choices/toggles/combat filters and previews | All five Lua suites pass; WAV validated and Windows playback succeeded | Pending |
| Sound settings persistence, restricted-data silence, hidden-tracker audio, channels, and fallback | Regression checks pass; see `tests/SOUND-VERIFICATION.md` | Pending |
| Report of false missing-seal display on combat entry for a level 22 paladin | Cause unconfirmed; waiting for seal/rank, addon version, and reproduction details | Unresolved |

No new release is ready based on local tests alone.

## In-game test record

For each test session, append a dated record here containing:

- Git commit and whether the deployed source had uncommitted changes.
- Client version/build and relevant character level, seal, and rank.
- Scenarios tested, expected versus observed behavior, and errors if any.
- Remaining issues and whether the user accepted the build for release.

No in-game results for the unreleased sound changes have been recorded yet.
