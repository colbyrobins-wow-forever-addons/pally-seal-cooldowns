# CurseForge upload kit

Current prepared release: **0.1.26**. Follow `../DEVELOPMENT.md` for development,
in-game acceptance, and release preparation. Public upload is a separate step.

## Automated upload

Pushing a `v<version>` tag runs `.github/workflows/ci-release.yml`, which creates the GitHub Release and uploads `PallySealCooldowns-v<version>-forever.zip` to CurseForge as Forever / 1.60.1, type Release, with `changelog-<version>.md` as its changelog. CurseForge upload needs the `CF_API_TOKEN` repository secret and `## X-Curse-Project-ID` in the TOC; without them the job warns and skips CurseForge. The file upload fields below are for manual uploads. The project description, logo, and other project fields are still updated by hand.

## Project fields

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Name | Pally Seal Cooldowns |
| Suggested slug | pally-seal-cooldowns |
| Summary | Tracks paladin seal duration with countdowns, refresh alerts, and a glowing combat reminder in WoW Forever. |
| Project class | Addons |
| Main category | Paladin |
| Additional category | Buffs & Debuffs |
| Logo | `project-icon.png` in this folder; original 512 × 512 PNG |
| Description | Paste `curseforge-description.md` using Markdown mode |
| Comments | Enabled for feedback |
| Experimental | Off for normal distribution |
| License | MIT License (matches `LICENSE` in the repository). The seal rank data keeps its CC BY 4.0 attribution in `NOTICE.md`. |
| Source / issue URL | Source: https://github.com/colbyrobins-wow-forever-addons/pally-seal-cooldowns · Issues: https://github.com/colbyrobins-wow-forever-addons/pally-seal-cooldowns/issues |
| Dependencies | None |

Check that the proposed name is available before submitting.

## File upload fields

- File: `dist/PallySealCooldowns-0.1.26.zip` in the repository.
- Display name: **Pally Seal Cooldowns 0.1.26 — Forever**.
- Game version type/flavor: **Forever**.
- Supported game version: **1.60.1** (interface 16001).
- Release type: **Release** for the initial public file to be available normally in the CurseForge app. The game client being a beta does not require a Beta addon file. Choose Beta instead if you deliberately want opt-in beta distribution.
- Changelog: paste `changelog-0.1.26.md`.
- Dependencies / related projects: none required.

If Forever or 1.60.1 is unavailable in your upload form, stop and verify the game/project selection or contact CurseForge support. Do not substitute Retail or Classic Era.

## Submission steps

1. Sign into the CurseForge author dashboard and open the existing Pally Seal Cooldowns project.
2. If a project has not been created, create it using the project fields above.
3. Update the project description with the current copy, including the sound limitations.
4. Preserve the existing project license and settings; for a new project choose the license before submission.
5. Open Files and upload the ZIP with the version/flavor and changelog above.
6. Submit for moderation and watch the project notifications for approval or requested changes.

The ZIP contains one top-level `PallySealCooldowns` folder with its matching TOC and Lua files. It includes required sound assets and the rank-data attribution notice. It excludes tests, development dependencies, old builds, and private settings.

## Optional screenshots

Capture actual in-game screenshots of an active timer, the refresh reminder, and the missing-seal combat alert. These are useful for the listing, but are not required for an addon submission. Avoid presenting a mockup as an in-game screenshot.

## Copy-ready upload assistant prompt

```text
Help me open the existing CurseForge World of Warcraft addon project named Pally Seal Cooldowns and prepare its 0.1.26 update on the existing project. Use the metadata and exact copy in release/UPLOAD-GUIDE.md, release/curseforge-description.md, and release/changelog-0.1.26.md. Upload release/project-icon.png as the project logo and dist/PallySealCooldowns-0.1.26.zip as the addon file. Select Forever / 1.60.1 only, with Release as the file type. There are no required addon dependencies. Preserve the existing project license; the archive includes a separate rank-data attribution notice. Include the documented sound limitations. Set the source link to https://github.com/colbyrobins-wow-forever-addons/pally-seal-cooldowns and the issues link to https://github.com/colbyrobins-wow-forever-addons/pally-seal-cooldowns/issues. Do not claim compatibility with Retail or Classic Era. Prepare all fields for review and stop before final public submission.
```

## Optional replacement icon prompt

```text
Create an original 1024 × 1024 square PNG project icon for a paladin seal timer addon named Pally Seal Cooldowns. Center a luminous golden hourglass inside a circular holy seal, on a deep navy background with restrained warm light. Strong silhouette, clean edges, readable at small sizes, polished fantasy UI styling. No text, no game logos, no copied spell icons, no existing project artwork. Opaque background.
```

## Announcement copy

```text
I made Pally Seal Cooldowns for WoW Forever: a compact seal timer with refresh warnings and a gold glow/bounce when you're missing a seal in combat. Casting a seal starts the countdown immediately. Move it with /psc unlock and set your warning with /psc warn 5. Available on CurseForge: [paste your approved project link]
```

## References

- https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
- https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips
