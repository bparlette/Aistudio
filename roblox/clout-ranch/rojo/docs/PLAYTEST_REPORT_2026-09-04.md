# Clout Ranch Playtest Report — 2026-09-04 (RanchPlay)

**Build:** Rojo serve localhost:34872 · Studio Place1 live (HUD confirmed via screenshot)  
**Canon:** VIP = lock+badge only (no idle mult) · F2P lock 45s / VIP 120s · Starter soft ≥6m · no platform names in kid UI  
**Method:** Live Solo HUD capture + full code gate audit. Dual-client steal **not** stopwatch-verified in-session (Brad dismissed live checklist).

---

## Scores

| Gate | Verdict |
|------|---------|
| 1) F2P first-10-min funnel | **PASS WITH NOTES** |
| 2) Dual-client VIP contested steal | **PASS WITH NOTES** (timers OK in code; lock-spam **FAIL risk**) |
| 3) Offline Brain silhouette | **PASS** (code/trend path) — live eye **unconfirmed** |
| 4) Sound/juice | **PASS WITH NOTES** |
| Kid-facing copy (no X/TikTok) | **PASS** |
| Doc drift (checklist vs code) | **FAIL** |
| **Ship call** | **NO soft-launch** — Studio continue OK |

---

## 1) Funnel — PASS WITH NOTES

**Live Solo HUD (screenshot):** Carpet stock (Based Frog / Cap Crab / Cope Corgi / Flex Fox), $50 cash, quests Buy Carpet + Win Aura Flex, STEAL/LOCK/REBIRTH, Daily streak 0, Clout Crew panel. BOOT+HUD green.

**Notes / bugs:**
- Starter cash **50** = Common price **50** → first buy goes to $0 (tight; OK if Commons stocked).
- `OfferService.MarkDopamine` **never called** → Starter@6m / VIP@8m soft toasts **dead** (High).
- WorldInteract Deposit bypasses Bootstrap `afterDeposit` (quests/dopamine incomplete) (High).
- DEPOSIT button may sit under Clout Crew on left stack (UI clip risk — verify).
- Checklist still says VIP ~30s — **stale** vs code 45/120.

---

## 2) Fairness VIP — PASS WITH NOTES

**Code PASS:** GetLockSeconds 45/120; IsLocked time-only; VIP excluded from GetIdleMult; soft protect 15s; carry/slap/deposit wired.

**FAIL risk (High):** `RequestLock` / WorldInteract Lock have **no cooldown** → mash LOCK refreshes `lockUntil` forever → behaviorally unstealable. Contested ≥30% vision fails under spam until CD exists.

Live 2P steal→deposit + post-120s VIP steal: **not stopwatch-confirmed this session**.

---

## 3) Offline Brain — PASS (code)

`trend_offline_brain` in PetCatalog + PetFactory `buildOfflineBrain`; TrendDropService W36 featured; Carpet featured weight path. Banner: `TREND WEEK · Offline Brain`. Spawn Command Bar in `OFFLINE_BRAIN_SILHOUETTE.md`. Live 64px eye still needed.

---

## 4) Sound/juice — PASS WITH NOTES

Steal/lock/deposit juice paths wired. Missing `JuiceService.Hatch` / `FlexShock` / `AuraBeams` (Med). Dual SoundHooks + SoundService risk double SFX (Med). Live audio not ear-verified.

---

## Concrete bugs (priority)

1. **High** — Lock no CD → permanent lock spam  
2. **High** — `MarkDopamine` never called → soft offers dead  
3. **High** — WorldInteract Deposit skips `afterDeposit`  
4. **Med** — Hatch/Flex Juice methods missing  
5. **Med** — Possible double SFX  
6. **Med** — No-Common carpet + $50 softlock window  
7. **Low** — Marketplace IDs all 0; unused `newbieProtectedUntil`  
8. **Doc** — PLAYTEST_CHECKLIST lock numbers wrong (20/30 vs 45/120)

---

## Next verify (when 2P available)

1. Stopwatch F2P 45 vs VIP 120; steal after expiry (no lock mash).  
2. Steal→deposit + soft-15s reject.  
3. Spawn Offline Brain → 64px skull+crack read.  
4. Confirm DEPOSIT visible; listen steal/lock/flex once.

---

## Addendum — Brad screenshot #2 (Roblox relay)

**Carpet:** Offline Brain listed as Secret **$8000** — matches `CarpetService.PRICES.Secret = 8000`. Featured trend path live. F2P with $50 cannot buy it (correct FOMO, not required for loop).

**Carpet shop icons: FAIL (Med/High UX)**  
`CarpetShop.lua` builds name + rarity text + BUY only — **zero** `ViewportFrame` / `ImageLabel` / pet preview. Text-only rows by implementation, not a sync miss. Blocks 64px silhouette stamp in-shop.

**Silhouette gate:** Still open. Need cropped **3D pet model** shot (Command Bar `PetFactory.BuildModel("trend_offline_brain")` or ranch slot spawn), not HUD text row.

**F2P/VIP continue:** Prior High bugs unchanged (lock no CD; MarkDopamine dead; WorldInteract deposit path). No new dual-client evidence this addendum.

---

## Retest — pre-alpha-playtest-highs-1 (code)

| # | Gate | Verdict | Evidence |
|---|------|---------|----------|
| 1 | Mash LOCK no forever refresh; 45/120 | **PASS** | `RanchService.Lock` refuses if `IsLocked` → `"Already locked — Ns left"`; Bootstrap + WorldInteract SoftFeedback warn. Durations via `GetLockSeconds` 45/120. |
| 2 | MarkDopamine wired; Starter ≥6m | **PASS WITH NOTES** | Call sites: steal, deposit, buy, lock. `STARTER_AFTER=6*60` requires `dopamine` + session elapsed ≥6m (not a post-dopamine timer). Aura podium still does **not** MarkDopamine (comment leftover). |
| 3 | WorldInteract Deposit = remote afterDeposit | **PASS** | DepositPad → `StealService.TryDeposit` → shared `afterDepositHooks`. |
| 4 | Checklist 45/120 | **PASS** | `PLAYTEST_CHECKLIST.md` header + contested VIP row updated. |

**Ship call (Highs):** code **PASS** for the three Highs + checklist. Live Studio Stop→Play + mash LOCK toast + 2P contested steal still needed for full Fairness PASS.

**Open:** CarpetShop icons, Offline Brain 64px crop, Aura podium→MarkDopamine (Low), Juice Hatch/Flex methods (Med).

---

## Retest addendum — Aura podium MarkDopamine

**PASS** — `AuraService.tallyWinners` calls `OfferService.MarkDopamine(plr, "podium")` for podium winners (`AuraService.lua` ~101–102). Prior PASS WITH NOTES on MarkDopamine coverage cleared (steal/deposit/buy/lock/podium).

Still open live: Brad Stop→Play mash-LOCK toast + 2P contested steal.

---

## Code pre-audit — pre-alpha-overnight-1 (awaiting Brad live sync)

| Gate | Code verdict | Evidence |
|------|--------------|----------|
| Shop Offline Brain icon | **PASS** (code) | `CarpetShop.lua` ViewportFrame + `PetFactory.BuildModel`; OfflineBrain skull framing via Silhouette |
| DataStore Stop→Play | **PASS WITH NOTES** | `DataService` Load/Save/session lock; Studio mock if API off. Live needs API Services ON |
| Mash LOCK | **PASS** | `RanchService.Lock` still refuses while locked |
| Steal ×5 single SFX | **PASS WITH NOTES** | SoundService.Start no-op; SoundHooks primary + debounce/mutex — live ear required |

Live card: `PLAYTEST_OVERNIGHT1_LIVE.md`

---

## Re-audit (fresh) — overnight-1 + datastore-tighten-1 on box

Baseline no longer stale. CarpetShop.lua 456 lines, mtime Sep 5 00:01 UTC.

| Gate | Verdict |
|------|---------|
| Lock anti-mash + 45/120 | **PASS** |
| Deposit shared afterDepositHooks | **PASS** |
| MarkDopamine steal/deposit/buy/lock/podium | **PASS** |
| CarpetShop Offline Brain ViewportFrame 52px FOV38 | **PASS** (code) |
| SoundHooks sole juice (Start no-op) | **PASS** (code) |
| DataService session-lock tighten | **PASS** (code; live needs API Services) |

Still blocked on: Brad laptop Rojo reconnect + live overnight-1 card.

---

## Code pre-audit — pre-alpha-blueprint-1

Doc: `BLUEPRINT_ADOPTIONS.md`. Explicitly skips Sol uncapped auto-roll / paid pity.

| Piece | Verdict | Notes |
|-------|---------|-------|
| ProfileStore optional | **PASS WITH NOTES** | `USE_PROFILE_STORE=true` → DataServiceProfile; legacy fallback. **New store name** `CloutRanch_ProfileStore_v1` — overnight-1 live restore may not migrate old keys. Studio Mock when NoAccess. |
| Config tables | **PASS** | EconomyConfig 45/120/15 wired into Ranch/Monetization/Steal; SoftPity + CarpetWeights extracted. Canon timings preserved. |
| FomoBroadcast | **PASS WITH NOTES** | Secret steal / mythic hatch / aura #1; 8s rate limit; kid-safe sanitize; no platform brands. Ethics OK if not spammy — live watch banner frequency. |
| Juice Hatch/FlexShock/AuraBeams | **PASS** | Missing Med juice methods now exist (+ FOMO on Secret/Mythic hatch). |

**Fairness regression check:** lock refuse-while-locked + EconomyConfig 45/120 still present. Soft pity F2P-only (CommonStreakForce=8).

**Live when Brad syncs:** ProfileStore Stop→Play with API ON (expect mock=false / Access); FOMO local banner on Secret steal; confirm no double whoosh still.

---

## Solo Studio dead-feel gaps (density pass input)

Brad live: empty — walks to tiny squares/carpets, nothing to do. FAIL on Master Vision "instant read ≤10s" in solo.

| Gap | Why solo feels dead | Density pass ask |
|-----|---------------------|------------------|
| **Tiny Slot pads** | `WorldInteract` Slot = **3.5×0.4×3.5** — reads as litter, not pet beds | ≥6–8 stud pads + glowing rim + "SLOT 1" billboard |
| **Empty foreign ranches** | Solo = 5 dead plots, no pets | Seed **demo/NPC pets** on unowned plots (or ghost ranch showcases) so steal targets exist |
| **Steal loop dead solo** | No victim → STEAL no-ops / quests stuck | Studio: auto Local Server tip **or** dummy rancher bot; HUD "need a rival" toast |
| **Aura Flex ~180s idle** | Solo waits 3 min for the USP spectacle | First-session Flex force ≤45s; or "Flex soon" countdown always visible world-side |
| **Next-action invisible in world** | HUD knows Buy Carpet / quests; world is unlabeled pads | World arrows/beams: **YOUR RANCH** → **BUY HERE (Carpet)** → **LOCK** after first pet; big billboards not just "Ranch 3" |
| **Spawn far from meaning** | RING_RADIUS **60**, night void — long walk to Carpet | Spawn facing Carpet ≤20 studs; path lights / gold arrows |
| **One Common then silence** | $50 → one pet → cash 0 → wait ticks; no celebrate | Bigger first-pet VFX on slot; floating "$/sec" on pet; pulse next tip |
| **Deposit/Lock pads small** | 5×0.4×5 easy to miss | Bigger pads + neon ActionText always-on when relevant |
| **Onboarding toast-only** | Easy to miss while camera-wandering void | Persistent step card in world OR sticky HUD step until complete |
| **No "what now" after buy** | Loop crack requires steal OR lock in ≤4 min | After first place: force highlight LockPad + enemy slot (or dummy) |

**Playtest add:** Solo density gate — cold join ≤30s can point at Carpet + own ranch + next verb without opening Discord.

---

## Code retest — pre-alpha-feel-dense-1

Against cold solo ≤30s card:

| Gate | Verdict | Evidence |
|------|---------|----------|
| Pads readable ≥6–8 + labels | **PASS** | Slot 7, Deposit/Lock 8, SLOT/DEPOSIT/LOCK/BUY CARPET billboards |
| Demo steal targets | **PASS** | `DemoRivalService` seeds foreign ranches; soft-protect skip for demo |
| Flex ≤45s first session | **PASS** | `FIRST_FLEX_IDLE=45` + `ForceEarlyFlex(40/45)` on join; VOTE RIVAL |
| Beams ranch→buy→lock | **PASS** | `JoinFunnel.lua` Beam sequence |
| Spawn ≤20 Carpet | **PASS** | `SPAWN_RING=16`, RING 42, BASE 40 |
| Post-buy sticky + $/s | **PASS** | sticky TutorialTips/JoinFunnel NEXT; IncomePerSec + PlaceBurst |
| Bigger deposit/lock | **PASS** | ACTION_PAD_SIZE 8 |

**Overall code: PASS.** Live Stop→Play still required (upgrade old tiny plots: Re-Play once). Fairness Highs not regressed by density.

---

## Live regression — farms “gone” (feel-dense-1)

Brad: only self + star carpet. **Not** PLOT_COUNT collapse (still 6).

Root causes:
1. Spawn at SPAWN_RING 16 faces Carpet; ranch bases at RING 42 are **behind camera**.
2. RING 60→42 + BASE 28→40 → adjacent centers ~42 with 40 pads ≈ merged donut.
3. Dark night plaza hides outer grass without rim light.

Fix: face spawn to own ranch; widen ring or shrink pads; light ranch rims.
