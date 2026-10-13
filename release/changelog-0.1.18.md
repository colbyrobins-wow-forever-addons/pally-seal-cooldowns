# 0.1.18

- Combined general settings, alerts, appearance, and presets in one scrollable page.
- Added Options > AddOns > Pally Seal Cooldowns, using the same page as `/psc`
  and the minimap button.
- Added responsive columns: side by side in wider windows, stacked in narrower ones.
- Retained legacy AddOns menu support and a standalone fallback when neither
  settings API is available. Registration waits until combat ends when necessary.

All five Lua regression suites pass, including native and legacy registration,
shared navigation, responsive layout, and existing appearance controls.
In-game visual verification is still required.
