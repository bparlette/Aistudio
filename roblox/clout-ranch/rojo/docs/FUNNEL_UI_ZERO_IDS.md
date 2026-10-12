# FUNNEL_UI_ZERO_IDS — pre-alpha-funnel-ui-1 audit

**Date:** 2026-09-04 (America/New_York)  
**Pack:** `/workspace/funnel-ui-1.tgz` · notes re-spot `/workspace/funnel-ui-1-notes.tgz`  
**Scope:** Soft monetization UI when Marketplace IDs are `0`. No inventing IDs, no VIP idle, no endsAt, no paywall on core verbs, no X/Twitter/TikTok player copy.

## Verdict: SOLID (with this pack)

| Gate | Status | Where |
|------|--------|-------|
| Prompt* disabled when ID == 0 | PASS | `Monetization.PromptPass` / `PromptProduct` / `TryPrompt` |
| Soft funnel allowlist only | PASS | `SOFT_SKU` + `RequestPurchase` allowlist (Starter / DoubleCash / VIP / BattlePass) |
| Kid-safe Coming soon / soft CTA | PASS | `HudModules/SoftOffer.lua` sole owner (`SoftFunnel` stubbed) when `payload.live == false` |
| Single SoftOffer listener (no double modal) | PASS | SoftOffer only; SoftFunnel no-op; OfferService FireClient once |
| SoftOffer fires post-dopamine | PASS | `OfferService` @ ~6m Starter, ~8m VIP |
| VIP = lock time only (not idle) | PASS | Offer VIP bullets + toast; lock copy `LOCKED — VIP timer` (Juice / Steal / Bootstrap fallback) |
| VIP never in idle mult | PASS | `Monetization.GetIdleMult` — Rebirth + DoubleCash only |
| Boot unset-ID warn | PASS | Hoisted on `Monetization` require (fires at Bootstrap top require) |
| No paywall BUY/STEAL/LOCK/DEPOSIT | PASS | SoftOffer is dismissible overlay only; core remotes untouched |
| No invented Marketplace IDs | PASS | All `PASS` / `PRODUCT` remain `0` until Brad pastes Dashboard IDs |
| No endsAt / no X-Twitter-TikTok player copy | PASS | SoftOffer + OfferService copy scrubbed |

## Flow (zero IDs)

1. Player hits dopamine → `OfferService.MarkDopamine`
2. After timing gates, server toasts + fires `Remotes.SoftOffer` with `{ sku, title, tag, bullets, cta, priceHint, live=false, comingSoon=true }`
3. Client modal shows **Coming soon** CTA (soft dismiss) + **Maybe later** — never calls `RequestPurchase` / Prompt*
4. If Brad later pastes non-zero IDs → same modal sets `live=true` → CTA fires `RequestPurchase` → `Monetization.TryPrompt` → Prompt* only for that SKU

## Live IDs path (when pasted)

`Monetization.IsSkuLive(sku)` / `HasSoftFunnelIds()` / `CountUnsetIds()` remain the source of truth. Soft min set: VIP · DoubleCash · Starter · BattlePass. Paste checklist: `docs/MARKETPLACE_IDS.md`.

## Studio sanity (Brad / CloutDev)

1. Boot Output: warn `Marketplace IDs unset: N — paste from Creator Dashboard…` (hoist on Monetization require).
2. Force SoftOffer (MarkDopamine + wait / or `SoftOffer:FireClient` in Studio): modal shows **Coming soon**, dismiss works, free BUY/STEAL/LOCK/DEPOSIT still work.
3. Lock as VIP flag owner → toast `LOCKED — VIP timer` (not “vault”, not idle power).
4. After pasting a real Starter product ID only: SoftOffer Starter CTA prompts; VIP still Coming soon.

## Files

- `src/ServerScriptService/Services/Monetization.lua`
- `src/ServerScriptService/Services/OfferService.lua`
- `src/ServerScriptService/Services/JuiceService.lua`
- `src/ServerScriptService/Services/StealService.lua`
- `src/ServerScriptService/ServerBootstrap.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/HudModules/SoftOffer.lua` (sole SoftOffer remote owner)
- `src/StarterPlayer/StarterPlayerScripts/HudModules/SoftFunnel.lua` (deprecated no-op stub)
- `src/StarterPlayer/StarterPlayerScripts/ClientHud.client.lua`
- `docs/FUNNEL_UI_ZERO_IDS.md`
- `docs/SUMMARY_pre-alpha-funnel-ui-1.md`

## funnel-ui-1-notes
- **SoftOffer** is the sole SoftOffer remote listener / modal.
- **SoftFunnel.mount** is a no-op stub (ClientHud no longer mounts it).
