# 0.1.15

- Reconcile seal timers from readable aura data during combat, using the same
  live-data-first approach as ForeverTotems.
- Retry aura reads every half second and on player aura events so readable
  cancellations, replacements, and duration changes update the tracker.
- Clear tracked seals on readable matching aura-removal events, even when a
  fresh aura query is restricted.
- Allow half a second for successful casts to appear in the aura API.
- Label fallback countdowns as estimated and show unavailable status when an
  estimate expires without readable confirmation.
- Validate finite timing values and retain estimates only for the same seal.

Validated with all four Lua regression suites under Lua 5.1. In-game validation
on the Forever beta client is still required, especially when aura data and
removal events are both restricted.
