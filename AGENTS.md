# Repository workflow

- Develop features and fixes without assigning a new version.
- Follow `DEVELOPMENT.md` for local checks, in-game testing, and release gates.
- Keep the TOC version at the last established version during development and
  in-game testing. Identify test builds by Git commit and record uncommitted
  changes, if any.
- Do not commit each change. Keep work uncommitted through deployment and
  in-game testing, and commit only after the user accepts the in-game results.
- Keep source, tests, documentation, and required addon assets in Git. Exclude
  build archives, deployment backups, and local dependencies.
- Add focused regression tests for behavior changes and record verification
  results honestly. Distinguish local tests from in-game confirmation.
- Deployment for in-game testing is separate from creating a release. Deploy
  when requested, with a backup of the target addon directory; do not infer
  deployment authorization from a request to implement a feature.
- Only assign a new version, create release archives or tags, or publish after
  the user accepts in-game results and requests release preparation or publishing
  as applicable. Do not automatically publish when preparing a release.
- Keep changes surgical, preserve existing patterns, and do not log secrets.
