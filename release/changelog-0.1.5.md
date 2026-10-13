# 0.1.5 — Initial public release

- Paladin seal countdown and refresh reminders for WoW Forever beta.
- Compact cooldown-manager-style icon, radial timer, and centered countdown.
- Configurable warning threshold and optional sound.
- Gold glow and bounce when a seal is missing or expires in combat.
- Cast-based combat tracking supports applying, refreshing, and switching seals without querying restricted combat auras.
- Actual buff timing is restored outside combat; observed durations are saved for later casts.
- Position, scale, and settings controls through `/psc`.

Combat timers are estimated from successful casts and cannot confirm early seal removal or duration changes while aura data is restricted.
