# pre-alpha-funnel-ui-1 — SUMMARY

**Date:** 2026-09-04 (America/New_York)  
**Pack:** `/workspace/funnel-ui-1.tgz`  
**Scope:** Soft monetization UI when Marketplace IDs are 0. Hide/disable Prompt paths; kid-safe Coming soon / soft CTA; VIP = lock time only. Boot unset-ID warn stays (Monetization hoist). No inventing IDs, VIP idle, endsAt, paywall core verbs, or X/Twitter/TikTok player copy.

## Done

1. **Monetization Prompt gate** — `PromptPass` / `PromptProduct` / `TryPrompt` refuse ID `0` (`coming_soon`). Soft allowlist via `SOFT_SKU`. Unset-ID warn hoisted on module require.
2. **SoftOffer HUD** — dismissible modal; zero-ID → Coming soon soft CTA (no Prompt*); live ID → `RequestPurchase`.
3. **OfferService** — post-dopamine Starter (~6m) + VIP (~8m) fire SoftOffer with lock-only VIP copy.
4. **VIP copy scrub** — `LOCKED — VIP timer` in JuiceService / StealService / Bootstrap fallback (not vault / not idle).
5. **Bootstrap** — `SoftOffer` + `RequestPurchase` remotes; RequestPurchase allowlist → `TryPrompt`.

## Docs

- `docs/FUNNEL_UI_ZERO_IDS.md` — full audit + Studio sanity

## Studio sanity (Brad)

1. Boot warn for unset Marketplace IDs (Monetization hoist).
2. SoftOffer with zeros: Coming soon + dismiss; core loop free.
3. VIP lock toast: timer language only.
