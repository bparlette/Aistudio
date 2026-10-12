# pre-alpha-feel-dense-1 — Solo density pass

**Date:** 2026-09-04 (America/New_York)  
**Goal:** Solo Studio Play feels busy + obvious within 10 seconds. No new core loop. No Marketplace IDs invented. VIP not idle mult. Lock/dopamine/deposit paths preserved.

## Root causes (Brad: empty tiny squares)

1. **Tiny unlabeled pads** — Slot parts were 3.5 stud neon squares; Deposit/Lock were 5 stud; ranch bases 28×28 with no SLOT / BUY / STEAL / LOCK world labels.
2. **Pets orphaned / invisible** — PetVisual fell back to world origin when Slot missing; slots only created late in WorldInteract.
3. **Shop buried** — OpenShop only fired from Carpet ProximityPrompt; no auto-open join funnel; Offline Brain not pinned in stock UI.
4. **Solo dead loops** — No foreign pets → STEAL no-ops; Aura Flex first idle was 180s; no rival vote target.
5. **RING void** — Spawns sat on ranch ring (~60 studs); carpet felt distant; no path lights / world beams.
6. **Toast-only onboard** — Tips auto-hid in 10s; no sticky NEXT chip; no floating $/s after place.

## Files changed

### Server
- `Services/MapBootstrap.lua` — 40×40 pads, RING 42, spawn ring 16 (≤20 to Carpet), 7-stud slots + rims + SLOT labels, 8-stud Deposit/Lock, BUY CARPET billboards, path lights, plaza floor, always-upgrade existing Studio plots
- `Services/WorldInteract.lua` — enlarge pads, STEAL/EMPTY labels, readable prompts, periodic label refresh
- `Services/DemoRivalService.lua` **(new)** — seed stealable demo pets on foreign ranches; Flex rival dummy; top-up loop
- `Services/RanchService.lua` — reclaim demo plots; teleport to owned spawn facing Carpet; IncomePerSec replicate; slot label refresh on place
- `Services/AuraService.lua` — first Flex idle ≤45s; `ForceEarlyFlex`; Vote accepts RivalUserId
- `Services/CarpetService.lua` — pin featured Offline Brain in stock[1]
- `Services/OnboardingService.lua` — FireClient OpenShop on ranch claim
- `Services/PetVisualService.lua` — plot-base fallback; floating `+$N/s` billboards
- `Services/StealService.lua` — STEAL_RANGE 45; demo owners skip soft-protect
- `Services/JuiceService.lua` — `place_burst` after Hatch
- `ServerBootstrap.server.lua` — DemoRival bootstrap; join OpenShop + ForceEarlyFlex

### Client
- `HudModules/JoinFunnel.lua` **(new)** — auto-open shop, sticky NEXT chip, world beams YOUR RANCH → BUY HERE → LOCK/STEAL
- `HudModules/ActionBar.lua` — always-on BUY / STEAL / LOCK + hint strip
- `HudModules/CarpetShop.lua` — featured Offline Brain banner + highlight
- `HudModules/CashCounter.lua` — `+$/s` from IncomePerSec
- `HudModules/TutorialTips.lua` — sticky while onboard step &lt; 6; immediate tip
- `HudModules/AuraBanner.lua` — solo Flex copy + **VOTE RIVAL** button
- `HudModules/VfxService.lua` — PlaceBurst (shock ring + PLACED stamp)
- `ClientHud.client.lua` — wires JoinFunnel + ActionBar shop open

## Brad Stop/Play checklist (what you should SEE)

1. **Stop → Play** (solo Studio).
2. **≤3s:** Spawn on yellow pad **near Carpet** (not stranded on a tiny far square). Gold path lamps toward center.
3. **≤5s:** **Red Carpet shop auto-opens** (top-right) with **★ Offline Brain featured** in slot 1 (expensive FOMO) + affordable commons below.
4. **≤5s:** Sticky **ONBOARD · NEXT** chip (left) + bottom tip; ActionBar shows **BUY · STEAL · LOCK**.
5. **World:** Big grass pads (~40 stud), **SLOT 1/2/3** neon with gold rims, **DEPOSIT** / **🔒 LOCK** pads labeled, carpet reads **✨ BUY CARPET**.
6. **Foreign ranches:** Pets visible with **🥷 STEAL** / **STEAL ZONE · DEMO** + `+$N/s` floaters.
7. **Gold beam** from you → Carpet (**▼ BUY HERE**). Buy a cheap Common.
8. **Post-buy:** Shock ring + **🐾 PLACED!**; pet on your SLOT with **+$/s**; CashCounter shows income rate ticking; beam shifts toward **LOCK**.
9. **STEAL:** Walk/beam to a pink STEAL pad or tap ActionBar STEAL — should grab a demo pet (carry), then Deposit on mint pad.
10. **≤45s:** **AURA FLEX** banner + **VOTE RIVAL** (dummy on Aura stage). Or tip if 2P preferred.
11. Ranch must **not** look like empty tiny squares.

### If something missing
- Output: `[CloutRanch] MapBootstrap dense pads` + `DemoRivalService seeded` + `BOOT OK` with `DemoRival`.
- Re-Play once so MapBootstrap upgrades old persisted tiny plots.
