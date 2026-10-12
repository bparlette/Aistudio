# pre-alpha-polish-1 — SUMMARY

**Date:** 2026-09-04 (America/New_York)
**Pack:** /workspace/polish-1.tgz
**Scope:** Cosmetic toast/SFX polish only. No economy, VIP idle, endsAt, paywall, Marketplace IDs, or X/Twitter/TikTok player copy. highs-1 untouched.

## Done

1. **Legendary hatch toast ↔ rare path** — JuiceService.Hatch toasts Rare/Epic/Legendary with tone "rare" (was buy-path for Legendary while SoundHooks already played rare). FeedbackToast maps rare→gold / mythic→HeatPink.
2. **Feedback dual-path soften** — SoundHooksApi Feedback listener SFX-skips juice-owned tones; soft UI allowlist only (buy/lock/success/pop/info/warn/error). Toast visuals still via FeedbackToast.
3. **slap.backupId** — Confirmed wired in playBus primary-fail fallback (9114111252). No further code change.

## Docs

- docs/JUICE_AUDIT.md — cleared Feedback dual-path / slap.backupId / Legendary toast NOTES; Brad Studio ear-confirm still owed.
- docs/SoundHooks.md + docs/AUDIO_MIX_BIBLE.md — polish-1 dual-path note aligned.

## Files in this pack

- src/ServerScriptService/Services/JuiceService.lua
- src/StarterPlayer/StarterPlayerScripts/HudModules/SoundHooksApi.lua
- src/StarterPlayer/StarterPlayerScripts/HudModules/FeedbackToast.lua
- docs/JUICE_AUDIT.md
- docs/SoundHooks.md
- docs/AUDIO_MIX_BIBLE.md
- SUMMARY.txt

## Studio sanity (Brad)

1. Buy Legendary → rare crystal chime + gold rare toast (not buy-blip / mint buy toast).
2. Steal → one whoosh (Feedback path no longer doubles juice tones).
3. Slap → Wood Impact; if silent, backupId should swap ~150ms.
