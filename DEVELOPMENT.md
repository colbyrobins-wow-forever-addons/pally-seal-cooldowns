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
| False missing-seal display from empty combat lookups | Captured client 1.60.1/build 70338 returned empty after casts and recovered the matching expiration on combat exit. Fix preserves live estimates, honors known removal events, and reconciles outside combat; all six Lua suites pass | Fix awaiting in-game retest; the original reporter's exact seal/rank remains unknown |
| Optional `/psc debug` capture for combat-entry detection | Bounded, deduplicated capture and query classification covered by diagnostics and event tests | Pending reproduction; detection behavior unchanged |
| Cancellation/dispel during empty combat lookups | Added-aura instance tracking and guarded player combat-log removal covered by regression tests | Pending client confirmation of available removal signals |
| Saved diagnostic capture export to UTF-8 text | Python exporter tested for extraction, escapes, malformed data, and source/output safety; exported 40 saved entries | Report saved locally under ignored `diagnostics/`; diagnosis pending review |

No new release is ready based on local tests alone.

## In-game test record

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
