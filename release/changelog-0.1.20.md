# 0.1.20

- Fixed the refresh warning sound rarely playing during combat. When the game
  hides seal timing in combat, the reminder now uses the timer from your seal
  cast instead of staying silent.
- Added **Bar counts down** in Appearance settings. When enabled, the duration
  bar starts full and drains from right to left as the seal expires. It is off
  by default, so the bar keeps filling up unless you turn it on.
- Split settings into pages: **General** under Options > AddOns > Pally Seal
  Cooldowns, with **Alerts & sounds**, **Appearance**, and **Presets** listed
  beneath it. All existing settings and saved choices carry over unchanged.

Sound limitation: if a seal is removed early in combat and the game does not
report it (for example, an unseen dispel), the refresh sound can still play at
the seal's expected refresh time. Recasting or switching seals resets it.
Combat-entry missing-seal sounds remain pending native sound integration.

Targets Forever beta 1.60.1, interface 16001. Eight Lua suites and three Python
exporter tests pass locally.
