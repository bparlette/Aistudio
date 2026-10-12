# NOTES — pre-alpha-funnel-ui-1 re-spot (double modal)

**Date:** 2026-09-04 (America/New_York)  
**Pack:** `/workspace/funnel-ui-1-notes.tgz`  
**For:** CloutDev re-spot  
**Issue:** SoftOffer + SoftFunnel both listened to `Remotes.SoftOffer` → possible double modal.

## Fix

| Piece | Change |
|-------|--------|
| **Owner** | `HudModules/SoftOffer.lua` is sole client funnel modal owner |
| **SoftFunnel** | Stubbed no-op (no UI, no `OnClientEvent`); warn if `mount` called |
| **ClientHud** | Mounts SoftOffer only; SoftFunnel require/mount removed |
| **OfferService** | Still `FireClient` once to `Remotes.SoftOffer` only (no dual remote) |

### Merged from SoftFunnel → SoftOffer

- VIP status note: `Lock time only — not idle`
- 8s auto-hide (token-guarded)
- Pulse on show

### Rails kept

- ID 0 → Coming soon, no Prompt* / no RequestPurchase until `live`
- VIP lock-time copy (not idle / not wins)
- Post-`MarkDopamine` Starter ~6m / VIP ~8m
- No invent Marketplace IDs; VIP ∉ idle; no endsAt; no X/Twitter/TikTok player copy

## Re-spot checklist (CloutDev)

1. Grep client: only `SoftOffer.lua` binds `SoftOffer` `OnClientEvent` (SoftFunnel stub has none).
2. ClientHud mounts SoftOffer once; SoftFunnel not required.
3. OfferService `fireSoftOffer` → single `ev:FireClient` on SoftOffer remote.
4. Studio: MarkDopamine + wait → **one** modal; Coming soon when IDs 0; VIP status shows lock-time note; Maybe later / 8s auto-hide; core verbs free.

## Files in this notes pack

- `src/StarterPlayer/.../HudModules/SoftOffer.lua`
- `src/StarterPlayer/.../HudModules/SoftFunnel.lua` (deprecated stub)
- `src/StarterPlayer/.../ClientHud.client.lua`
- `src/ServerScriptService/Services/OfferService.lua`
- `docs/NOTES_pre-alpha-funnel-ui-1.md`
- `docs/FUNNEL_UI_ZERO_IDS.md` (updated owner note)
- `SUMMARY.txt`
