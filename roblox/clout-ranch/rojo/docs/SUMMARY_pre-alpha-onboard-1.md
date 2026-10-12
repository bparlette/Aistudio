# pre-alpha-onboard-1 — SUMMARY

**Date:** 2026-09-04 (America/New_York)
**Pack:** /workspace/onboard-1.tgz
**Scope:** Cosmetic/UX only — first-session sticky NEXT always names next verb **BUY → STEAL → LOCK → DEPOSIT** so solo Play needs no Brad. No Marketplace IDs, VIP idle, endsAt, paywall core verbs, or X/Twitter/TikTok player copy. highs-1 + juice-2-stings-1 untouched.

## Done (vs feel-dense-1 baseline)

1. **JoinFunnel** — Verb ladder strip; chip title `ONBOARD · NEXT → {VERB}`; body one next verb; **carry (`CarryPet_*`) forces DEPOSIT** + mint beam → DepositPad; step 3 beams STEAL (earn soft-parallel); DepositPad in Ranch1 fallback.
2. **ActionBar** — Added **📦 DEPOSIT** (`DepositPet`, SFX `place` per juice-2). NextHint = single verb; gold stroke highlights active button; carry → DEPOSIT.
3. **TutorialTips** — Verb-first tips; sticky CARRY_TIP while carrying; fallbacks spell BUY→STEAL→LOCK→DEPOSIT.
4. **OnboardingService** — Toast **copy only** (same step machine); mirrors client NEXT verbs. No flag/step logic changes.

## Rails (unchanged)

- No Monetization / MARKETPLACE_IDS
- No VIP idle mult / endsAt extend
- No paywall on BUY/STEAL/LOCK/DEPOSIT
- No player-facing X/Twitter/TikTok copy
- StealService / JuiceService / SoundHooks / RanchService / WorldInteract not in pack

## Files in this pack

- src/StarterPlayer/StarterPlayerScripts/HudModules/JoinFunnel.lua
- src/StarterPlayer/StarterPlayerScripts/HudModules/TutorialTips.lua
- src/StarterPlayer/StarterPlayerScripts/HudModules/ActionBar.lua
- src/ServerScriptService/Services/OnboardingService.lua
- docs/SUMMARY_pre-alpha-onboard-1.md
- docs/PLAYTEST_PRE_ALPHA_ONBOARD_1.md
- docs/PLAY_FEEL.md
- SUMMARY.txt

## Studio sanity (Brad / CloutDev)

1. Solo Play ≤5s: chip ladder + **NEXT → BUY**; ActionBar BUY gold-stroked; Red Carpet auto-opens.
2. Post-buy (step 3 earn): NEXT → **STEAL** + pink beam to demo Slot.
3. STEAL demo → chip/tip **NEXT → DEPOSIT** + mint beam; ActionBar DEPOSIT highlighted.
4. Deposit / Lock → NEXT → LOCK then CLAIM DAILY; chip hides at step 6 (unless carrying).
5. Deposit SFX = one place thud (juice-2); no double; no Robux on core verbs.
