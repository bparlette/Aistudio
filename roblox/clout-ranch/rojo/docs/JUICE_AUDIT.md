# Clout Ranch — Juice Audit (juice-2 + pre-alpha-polish-1)

**Date:** 2026-09-04 (America/New_York)  
**Verdict:** **Already solid — Option B.** Cosmetic steal / place / flex client feedback is wired end-to-end. DemoRival uses the same StealService → JuiceService path as PvP. Client feedback is FOV punch + camera shake + VFX only (no economy / VIP idle / endsAt extend / paywall / client-trust changes in this pass). highs-1 pack left intact.

**CloutDev rails (unchanged):** no VIP idle mult · no endsAt extend · no X/Twitter/TikTok player copy · highs-1 intact.

**Sound stings:** **CLOSED** by **juice-2-stings-1** / `SoundHooksApi` (see below). Cosmetic rails unchanged.

---

## Wired juice (server → Remotes.Juice → client)

### Server owners (`JuiceService.lua`)

| API | Juice `kind`(s) | Fired from |
|-----|-----------------|------------|
| `Steal` | `steal` (+ toast) | `StealService` (remotes + WorldInteract E-steal; DemoRival plots included) |
| `Deposit` | **`place` only** (single pad-pop) | `StealService.afterDepositHooks` |
| `Hatch` | `hatch_drip` / `hatch_burst` / `mythic` + always `place_burst` | `CarpetService.TryBuy` (+ bootstrap fallback) |
| `Buy` | `buy` | Bootstrap fallback only if Hatch missing |
| `Lock` | `lock` | `WorldInteract` LockPad · bootstrap |
| `Rebirth` | `rebirth` | `RebirthService` · bootstrap |
| `Daily` | `daily` | bootstrap daily claim |
| `Clip` | `clip` | `ClipMomentService` |
| `VotePunch` | `vote_punch` | `AuraService` vote confirm (rival or player) |
| `FlexShock` | `flex_shock` (broadcast) | `AuraService.startFlex` |
| `AuraBeams` | `aura_beams` (broadcast) | `AuraService` podium |
| `Play` / `Slap` | `slap` | `StealService` slap (attacker + target) |

Payload convention: `{ kind, message?, subjectUserId?, targetUserId?, rarity?, petId?, winners?, rival? }`. Steal/Deposit pass `subjectUserId` so DemoRival + PvP share StealCreamFlash trail/highlight.

### Client consumers (same remote)

| Layer | File | Role |
|-------|------|------|
| Camera shake | `ClientHud.client.lua` | Kind → magnitude map (`steal` 0.35, `place_burst` 0.28, `flex_shock` 0.32, `vote_punch` 0.42, …) |
| FOV / VFX | `HudModules/VfxService.lua` | `StealCreamFlash`, `PlaceBurst`, `FlexShockRing` / `AuraPodiumBeams`, `vote_punch` FOV+stamp, hatch/mythic/rebirth |
| SFX (primary) | `HudModules/SoundHooksApi.lua` via `SoundHooks.client.lua` | Debounced buses + BigJuice mutex; `SoundService.Start` is no-op (anti-double) |
| Toast | `FeedbackService` ← JuiceService helpers | Center toast tones only |

### DemoRival same path

- `DemoRivalService` seeds foreign unlocked plots + Flex rival dummy only.
- Steal/deposit juice is **not** a special case: `StealService.TrySteal` → `JuiceService.Steal`; deposit → `JuiceService.Deposit` (`place` only).
- Client `VfxService.StealCreamFlash` resolves `subjectUserId` then local player — DemoRival steals still trail/highlight.

### Cosmetic-only confirmation

Juice handlers do **not** grant cash, extend locks, trust client rarity, or touch VIP idle. `vote_punch` / FOV / shake are presentation only.

---

## Three CloutSound sting gaps — **CLOSED** (juice-2-stings-1 / SoundHooksApi)

Per `docs/AUDIO_MIX_BIBLE.md` + `SoundHooksApi` ALIAS/BUSES. Cleared in pack **juice-2-stings-1**.

### 1) Rare/Epic hatch → rare bus — **CLOSED**

- **Was:** `hatch_burst` / `hatch_drip` aliased → `buy`; Rare/Epic sounded like Common.
- **Now:** `PlayKind` rarity-branches before Play — Rare/Epic/Legendary → **`rare`** bus (`9116384757`); Common → buy; Mythic/Secret → mythic stack. Pointer: `SoundHooksApi.resolveHatchKind` + juice-2-stings-1.

### 2) Slap → slap / Wood Impact — **CLOSED**

- **Was:** `ALIAS.slap = "lock"` (lock click character).
- **Now:** `slap` bus `9120907213` Wood Impact 2 (speed 1.05); `backupId` `9114111252` wired as primary-fail fallback in `playBus`. Pointer: juice-2-stings-1 / `SoundHooksApi` BUSES.slap.

### 3) Deposit → single place — **CLOSED**

- **Was:** `Deposit` fired `deposit` then `place_burst` → lock + buy same frame (bible violation).
- **Now:** `JuiceService.Deposit` fires **`place` only**; ALIAS maps `deposit` / `place` / `place_burst` → **place** pad-pop; slap+place share **impact** 0.15s debounce (replace-don't-stack). Pointer: juice-2-stings-1 / `JuiceService.Deposit` + `SoundHooksApi`.

---

## Remaining NOTES (non-blocking)

- **Feedback dual-path tones:** **CLEARED** (pre-alpha-polish-1) — Feedback listener SFX-skips juice-owned tones; soft UI allowlist only (`buy`/`lock`/`success`/`pop`/`info`/`warn`/`error`). Toast visuals unchanged via FeedbackToast. Juice remains sole sting owner for juice moments.
- **slap.backupId:** **CLEARED** — confirmed wired in `playBus` (primary-fail → `9114111252`). Ear-confirm ALT only if primary hated in playtest.
- **Legendary hatch toast:** **CLEARED** (pre-alpha-polish-1) — `JuiceService.Hatch` Rare/Epic/**Legendary** toast tone `"rare"` (was buy-path for Legendary); FeedbackToast gold `rare` color. SoundHooks already played rare bus.
- **Brad Get Audio ear confirm:** Studio listen-through still owed — Rare/Legendary hatch chime, slap Wood Impact, deposit single thud (not lock+buy).

---

## Out of scope / do not regress

- No VIP idle multiplier, no offer `endsAt` extend, no paywall juice, no client-trusted economy.
- No X / Twitter / TikTok player-facing copy.
- Leave `/workspace/playtest-highs-1.tgz` and highs-1 wiring alone.
- SoundHooks remains sole Juice SFX owner (`SoundService.Start` stays no-op).

## Quick Studio sanity

1. Solo Play → steal DemoRival pet → cream flash + shake + steal whoosh; deposit → PLACED stamp + FOV + **one** place thud (not lock+buy).
2. Buy Rare+ → FOV/VFX rarity punch + **rare** crystal chime (not buy-blip).
3. Slap a carrier → cream flash + **Wood Impact** slap (not lock click).
4. Aura Flex ≤45s → flex_shock ring; Vote Rival → vote_punch FOV/stamp.
