# 0.1.19

- Integrated Blizzard-managed seal displays into both the icon and horizontal
  bar layouts to handle active seals and removal during restricted combat.
- Added a native missing-seal display with combat glow and bounce, without
  reading restricted aura state in addon Lua.
- Fixed Seal of Command's damage effect incorrectly restarting the seal timer.
- Fixed the native gold/custom border error caused by secret frame dimensions;
  custom borders now use textures sized from saved settings.
- Preserved position, scale, appearance presets, text visibility, and countdown
  controls. Layout/appearance changes made during combat apply after combat ends.
- Added separate refresh/missing sound settings, a bundled gentle chime,
  previews, and optional diagnostic captures. Unsupported native clients retain
  the estimated tracker.

Sound limitation: in native mode, refresh sounds require readable observed
timing. Automatic combat cancellation/dispel and combat-entry missing sounds
are pending native sound integration. Previews and readable out-of-combat
missing sounds remain available.

Targets Forever beta 1.60.1, interface 16001. Native manual cancellation was
confirmed in game using the prototype; the user authorized release of the
repaired integration. Enemy dispel has not been independently confirmed in the
recorded tests. Eight Lua suites and three Python exporter tests pass locally.
