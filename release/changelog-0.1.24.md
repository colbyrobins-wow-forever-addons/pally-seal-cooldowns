# 0.1.24

- **New Swing timer bar layout.** Pick **Swing timer bar** on the Layout page
  (or type `/psc style swing`) for a seal bar that looks like Forever's own
  main-hand swing timer. It is built from Blizzard's swing timer artwork: the
  bronze frame, background, fill, the bright pip at the fill's edge, and the
  label shadow. The bar reads **Seal Timer** on the left and shows the time
  left in tenths of a second on the right (`18.2`). The fill turns your warning
  color when a refresh is due. It uses **Bar width**, **Bar texture**, and
  **Bar counts down**, and setting **Border** to None removes the frame.
- **Settings show only what applies to your layout.** Switching layouts hides
  options that do nothing for it, and the rest move up to close the gap. For
  example, the swing bar hides the placeholder icon, the seal-name toggle, and
  border color, and the Layout page heading names the chosen layout.
- **Presets respect the swing bar.** On the Swing timer bar, presets change
  only fonts, outlines, shadows, and text sizes, and keep Blizzard's bar art.
  **Classic Gold** and **Paladin Pink**, which are border looks, are hidden
  there.
- **Snapping is now part of the Essential Cooldowns icon.** The Essential
  Cooldowns icon always attaches to Blizzard's Essential Cooldowns bar, using
  **Snap position** and **Gap from bar** under its options. The **Snap to
  Essential Cooldowns bar** checkbox is gone, and the other layouts no longer
  snap.

Upgrading: if you snapped the Large icon or Small icon with timer bar layouts,
the tracker now returns to its saved free position. Use `/psc unlock` to move
it. If you used the Essential Cooldowns icon without snapping, it now attaches
to the bar.

Sound limitation: if a seal is removed early in combat and the game does not
report it (for example, an unseen dispel), the refresh sound can still play at
the seal's expected refresh time. Recasting or switching seals resets it.
Combat-entry missing-seal sounds remain pending native sound integration.

Targets Forever beta 1.60.1, interface 16001. Ten Lua suites and three Python
exporter tests pass locally.
