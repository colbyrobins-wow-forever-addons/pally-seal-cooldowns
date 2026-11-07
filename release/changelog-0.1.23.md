# 0.1.23

- **More alert sounds**, by community request. **Refresh sound** and
  **Missing sound** now offer 17 built-in choices:
  - New original sounds: **Double chime**, **Bright bell**, **Glass ping**,
    **Rising arpeggio**, **Holy shimmer**, **Harp pluck**, **Soft gong**,
    **Wood block**, **Bubble pop**, **Urgent beeps**, and a **Cat meow**.
  - New game sounds: **Ready check** and **Alarm clock**.
  - Sounds from installed **SharedMedia** packs now appear after the built-in
    choices.
- **Dropdown menus** replace left/right-click cycling for every choice in the
  settings (layout, textures, sounds, channel, fonts, borders, colors, and
  more). Picking a sound from its dropdown plays it so you can hear it.
- If a chosen sound can't play (for example, a SharedMedia pack was removed),
  the refresh alert now falls back to the **Gentle chime** instead of a raid
  warning. The missing-seal alert still falls back to raid warning.
- Your existing sound choices are kept.

After updating, fully restart WoW (not just `/reload`) so the game can find the
new sound files.

Sound limitation: if a seal is removed early in combat and the game does not
report it (for example, an unseen dispel), the refresh sound can still play at
the seal's expected refresh time. Recasting or switching seals resets it.
Combat-entry missing-seal sounds remain pending native sound integration.

Targets Forever beta 1.60.1, interface 16001. Ten Lua suites and three Python
exporter tests pass locally.
