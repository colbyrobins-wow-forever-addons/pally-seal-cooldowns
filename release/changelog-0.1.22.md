# 0.1.22

- The icon countdown now shows plain numbers (for example, `28` instead of
  `28s`). Whole seconds round up like the game's own countdown. Warning colors
  and the "REFRESH SEAL" text are unchanged.

Sound limitation: if a seal is removed early in combat and the game does not
report it (for example, an unseen dispel), the refresh sound can still play at
the seal's expected refresh time. Recasting or switching seals resets it.
Combat-entry missing-seal sounds remain pending native sound integration.

Targets Forever beta 1.60.1, interface 16001. Ten Lua suites and three Python
exporter tests pass locally.
