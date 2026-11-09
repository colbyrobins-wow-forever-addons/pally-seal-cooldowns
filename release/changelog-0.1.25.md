# 0.1.25

- **The Essential Cooldowns icon now looks like Blizzard's.** It uses the same
  border, rounded dark swipe, and spacing as the icons on the Essential Cooldowns
  bar, with nothing below the icon by default. **Show seal name**, **Show status
  text**, and **Show duration bar under icon** add those back for this layout.
- **The Swing timer bar now matches the main-hand timer's size.** It defaults to
  426 by 30 pixels, the size of Blizzard's main-hand timer in the Modern Edit Mode
  layout. **Swing bar width** on the Layout page sets it from 213 to 852 pixels.
- **Show 0.0 when no seal is active.** Choose **Zero time (0.0)** under **Missing
  symbol** on the Alerts page for a white "0.0", like Blizzard's idle swing timer.
  The red "!" stays the default.
- **The missing-seal sound now plays on the native display.** It plays once outside
  combat after a seal ends, including one lost during combat. It stays quiet at
  login until a seal has been active, and when a seal is lost to death.
- **Reset now works on every layout.** **Reset position and size** and `/psc reset`
  also restore the current layout's bar width, or the Essential Cooldowns icon's
  size, snap position, and gap.

Upgrading: these changes replace some saved settings.

- The Essential Cooldowns icon hides its bar, seal name, and status text until you
  turn them back on.
- A gap of 2 pixels from the Essential Cooldowns bar, the old default, changes to 1.
- The Swing timer bar changes to 426 pixels wide, even if you had resized it.

Sound limitation: the missing-seal sound cannot play at the moment a seal is lost
in combat, because the game hides that from addons. It plays after combat ends. If
a seal is removed early in combat and the game does not report it (for example, an
unseen dispel), the refresh sound can still play at the seal's expected refresh
time. Recasting or switching seals resets it.

Targets Forever beta 1.60.1, interface 16001.
