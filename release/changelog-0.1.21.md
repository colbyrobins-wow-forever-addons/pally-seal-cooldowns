# 0.1.21

- Added an **Essential Cooldowns icon** layout that matches the icons on
  Blizzard's Essential Cooldowns bar. It can follow Blizzard's icon size
  automatically, or you can set the size yourself.
- Added **Snap to Essential Cooldowns bar**. The tracker attaches to the right,
  left, top, or bottom of Blizzard's bar with an adjustable gap, follows the
  bar when you move it in Edit Mode, and returns to your saved position if the
  bar is unavailable. Works with every layout.
- Added options for when no seal is active: choose the combat alert (glow and
  bounce, glow only, bounce only, or none), hide the tracker until you cast a
  seal, hide the missing-seal text separately, remove the "!" symbol, and pick
  the placeholder icon.
- Added **Warning color** (red, orange, yellow, Paladin pink, or white) for
  refresh warnings and the missing-seal display.
- Added **Show duration bar under icon** to remove the thin bar beneath the
  large icon.
- Reorganized settings into **General**, **Layout**, **Alerts**, **Appearance**,
  and **Presets** pages. A single **Layout** choice replaces the timer-bar
  checkbox, and each layout's options are grouped together. Existing settings
  carry over.
- `/psc style essential` switches to the new layout, and `/psc status` reports
  whether Blizzard's Essential Cooldowns bar was found.

Sound limitation: if a seal is removed early in combat and the game does not
report it (for example, an unseen dispel), the refresh sound can still play at
the seal's expected refresh time. Recasting or switching seals resets it.
Combat-entry missing-seal sounds remain pending native sound integration.

Targets Forever beta 1.60.1, interface 16001. Ten Lua suites and three Python
exporter tests pass locally.
