# Sound verification

## 2026-10-15 development regression check

All eight Lua 5.1 suites pass through Lupa. Native refresh reminders now use
live estimated timers as well as readable observations. Regression coverage
includes 14 successive combat casts alternating Crusader and Righteousness,
replacement deadlines, sound enable/combat filters, confirmed removal,
restricted timing, precombat seals, and a hidden out-of-combat tracker.
Early removal with no readable signal can still leave a scheduled reminder.
In-game verification is pending; no deployment or version change was made.

## Previous verification record

Local verification completed on 2026-10-12 using Lua 5.1 through Lupa.
All five `tests/*_test.lua` suites passed. No production code changes were
needed during this verification pass.

## Covered locally

- One refresh warning per timer and one missing-seal warning per missing episode.
- Independent enable and combat-only preferences, including hidden trackers.
- No missing-seal audio for restricted queries, secret aura results, or expired
  estimated timers.
- Existing sound choices and disabled preferences survive initialization;
  independent alert preferences survive repeated addon initialization.
- Both preview buttons bypass automatic alert filters and use their respective
  selections on Master, SFX, and Dialog.
- Successful chime playback does not also play a fallback. Failed playback or a
  missing file-playback API falls back to one raid warning on the selected channel.

The bundled `RefreshChime.wav` is mono, uncompressed 16-bit PCM at 44,100 Hz,
with 35,280 samples (0.800 seconds). Peak amplitude is -8.56 dBFS and RMS is
-22.92 dBFS, with zero clipped samples and zero-valued first and last samples.
Windows synchronous playback completed successfully. This confirms local
playback support, not perceived loudness or game-client compatibility.

## Pending in-game verification

After deployment is separately authorized:

1. Preview both sounds on each channel and check volume against ordinary combat
   audio, including the client's channel mute and volume controls.
2. Check that every new control is visible and reachable in wide and narrow
   settings windows, and both tracker layouts behave consistently.
3. Exercise combat entry, seal refresh, confirmed expiration, and cancellation;
   confirm one appropriate alert and no repeated polling sounds.
4. Reload the UI and confirm saved choices and toggles remain intact.

The reported false missing-seal display remains unresolved pending player
details and in-game reproduction. Mocked aura tests cannot establish that the
reporter's client returns reliable aura data in combat.

Version remains 0.1.18. No deployment or release packaging was performed.
