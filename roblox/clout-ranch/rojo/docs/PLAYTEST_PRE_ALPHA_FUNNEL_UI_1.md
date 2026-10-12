# Playtest — pre-alpha-funnel-ui-1

**Goal:** Soft funnel UI safe while Marketplace IDs = 0.

## Checks

| # | Check | Pass? |
|---|-------|-------|
| 1 | Boot Output: `Marketplace IDs unset: N` warn (Monetization hoist) | |
| 2 | No runtime halt / no HARD FAIL crash from unset IDs | |
| 3 | SoftOffer Starter card after dopamine + ~6m; CTA **Coming soon** | |
| 4 | Click Coming soon → toast only; no PromptGamePass/Product with id 0 | |
| 5 | VIP SoftOffer ~8m: lock time + badge copy; not idle mult | |
| 6 | Maybe later / auto-dismiss works; core loop unblocked | |
| 7 | BUY/STEAL/LOCK/DEPOSIT free (no paywall) | |
| 8 | No X/Twitter/TikTok in player-facing funnel copy | |

## Notes

Brad paste of Creator Dashboard IDs flips `live=true` per SKU; until then soft Coming soon is correct.
