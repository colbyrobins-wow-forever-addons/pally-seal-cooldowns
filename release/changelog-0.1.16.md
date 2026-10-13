# 0.1.16

- Added an Appearance panel under `/psc` with font choices, independent timer
  and seal-name sizes, outlines, and text shadows.
- Added border styles, four border colors, custom border thickness, and bar textures.
- Added Default, Minimal, and High Contrast appearance presets.
- Added optional LibSharedMedia-3.0 integration for installed fonts, borders,
  and bar textures, with defaults when a media pack is unavailable.
- Preserved refresh warning colors and existing gameplay settings.

All five Lua regression suites pass under Lua 5.1. Visual layout and optional
media compatibility still require in-game validation on the Forever beta client.
