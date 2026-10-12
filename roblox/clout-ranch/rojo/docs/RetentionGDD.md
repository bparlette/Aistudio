# Clout Ranch — Retention GDD (Daily Loop)

Season 1 focus: **open every day**, play 10–20 minutes, leave wanting tomorrow’s carpet / streak / featured pet. No gen-AI doomscroll-for-power. No licensed NFL / Italian-brainrot IP.

Related: `REVENUE_AND_RETENTION.md` (short ladder), `MonetizationCatalog.md` (SKU table).

---

## Why they open every day

| Beat | Time | Hook |
|------|------|------|
| **1. Daily streak claim** | ~30s | `DailyService.TryClaim` — escalating cash / luck minutes / aura across days **1..7**, then **soft cycle** back to day 1 (grace restores). Claim arms **SessionService** return bonus (**1.5× for 10 min**). |
| **2. Return-bonus window** | 10 min | First minutes after claim feel juicy (idle tick / live-ops). Creates a short “worth staying” session without infinite grind. |
| **3. Featured / weekly FOMO pet** | check-in | `SeasonService.GetFeatured()` rotates weekly; limited Secrets (`IsLimitedActive`) create calendar FOMO — miss the window, miss the drip (cosmetics / flex income, not hard locked content forever). |
| **4. Defend overnight income** | emotional | Pets print while offline/away; unlocked ranches are stealable. Fear of loss drives return **and** VIP lock spend — contestable passive income. |
| **5. Battle Pass XP** | background | XP from steals (deposit), rebirths, aura podium. Falling a day behind hurts **prestige track progress**, not the ability to win fights or earn base income. |
| **6. Aura Flex social** | live ops | Periodic flex rounds → podium aura + BP XP. Reason to hop with friends / clip moments. |
| **7. Daily quests** | 5–15 min | `QuestService` — 3 rotating goals (steal / earn / podium / buy / lock / deposit). Claim cash/aura/BP XP. |
| **8. Comeback bundle** | return | Away **>48h** → one soft cash+luck grant via `ComebackService` (Feedback toast). |

---

## Soft pity (fair Carpet)

- Base rarity weights live in `CarpetService`; player luck via `LuckService.GetLuck` → `ApplyToWeights`.
- Boosts are **timed**, **stack-capped** (product clamp) — paid luck spikes sessions; F2P still rolls Secrets over volume + soft pity policy:
  - **`SoftPityService`**: after **8 Commons in a row** on Carpet buys, force **Uncommon+** on the next replacement roll; streak resets on Uncommon+.
  - Counter replicated as `CloutStats.PityCommonStreak` (honest, visible).
  - Daily streak luck minutes + free BP luck tiers supply F2P edge without Robux.
- Never sell the only path to a meta pet; limiteds are time-gated flex, duplicates convert or flex.
- Prefer bad-luck protection over guaranteed pay-only Secrets.

---

## FOMO weekly pet

- **Weekly featured** (`SeasonService` rotation): spotlight on Carpet / HUD — higher salience, not exclusive spawn monopoly.
- **Limited Secret windows**: wall-clock `startUnix`/`endUnix`; market + aura drip SKUs sync copy to the window.
- Messaging: “Gone Sunday UTC” — scarcity without dark patterns (show timer; no fake stock).

---

## Anti-whale-only design

| Allowed | Forbidden |
|---------|-----------|
| VIP lock time, slap cooldown, luck duration, extra slot, BP premium track | Paywall on steal / rebirth / aura vote |
| Cosmetics, aura drip, limited flex pets | Permanent exclusive income pets only whales can own |
| Convenience 2x cash | Infinite admin cash as the product |
| Soft pity + free streak luck | Doomscroll feeds that grant power |

Whales accelerate and flex; skilled free players still steal, podium, and clear free BP. Competitive edge purchases must be **contestable** (lock expires, slap is interactive, luck expires).

---

## Streak rules (server authority)

- Day key = `floor(os.time() / 86400)` (UTC).
- Claim once per day key; rewards from table day `1..7`.
- Consecutive yesterday → advance; after 7 → soft reset to 1 and refresh grace.
- **One missed-day grace** per cycle (`lastClaimDay == today - 2` and `graceUsed == false`).
- Longer gap → streak soft-resets to 1 (not account wipe).

Exports: `TryClaim`, `GetStreak`, `GetState` (+ preview helper).

---

## Bootstrap wiring (Daily claim)

Already in `ServerBootstrap.server.lua`:

1. `local DailyService = tryRequire("DailyService")` (pulls `SessionService` / `LuckService` / `AuraService` via requires).
2. `ClaimDaily = ensureRemote("ClaimDaily")`
3. `DailyClaimResult = ensureRemote("DailyClaimResult")` — server fires `(ok, msg, reward, state)` after claim for HUD.
4. Client: on button → `ClaimDaily:FireServer()`; listen `DailyClaimResult.OnClientEvent` to toast streak / rewards.
5. Optional: replicate streak via `CloutStats` NumberValues later; do not trust client day clocks.

Battle Pass: `ClaimBattlePass:FireServer("free"|"premium")` → `BattlePassService.TryClaimTier`.

Luck: Bootstrap sets `CarpetService.SetWeightTransform` from `LuckService.ApplyToWeights` when a buying player is known.

---

---

## Daily quests (QuestService)

Three quests rotate each UTC day from a fixed pool (deterministic per `dayKey + userId`):

| Kind | Goal | Typical reward |
|------|------|----------------|
| `steal_pet` | Steal 1 pet | cash + BP XP |
| `earn_cash` | Earn $500 | cash + aura + BP XP |
| `win_aura` | Place on Aura Flex podium | aura + BP XP |
| `buy_carpet` | Buy from Carpet | cash + BP XP |
| `lock_ranch` | Lock ranch twice (manual `RequestLock`) | cash + aura + BP XP |
| `deposit_steal` | Deposit a stolen pet | cash + BP XP |

- Replicated under `player.CloutQuests` (`DayKey`, `Slot1..3` with Id/Kind/Label/Progress/Target/Claimed/Ready).
- Client: `HudModules/QuestPanel` → `ClaimQuest:FireServer(slotIndex)`.
- Progress hooks: Bootstrap (steal/buy/lock/deposit), `EconomyService.AddCash` (`earn_cash`), `AuraService` podium (`win_aura`).
- Ethical FOMO: clear targets, claimable when ready, no fake timers / bait-and-switch.

---

## Comeback bundle (ComebackService)

- `SessionService` tracks `LastSeen` unix in memory + `CloutStats.LastSeen` IntValue (touch on leave + after comeback gap check on join).
- If gap **> 48h**, player is eligible once for a soft welcome-back bundle: **$400 + timed luck**.
- Soft `Feedback` toast only (no countdown pressure, no paywall to claim). Auto-grants once per return.

---

## Soft pity (SoftPityService + Carpet)

Concrete policy (Season 1):

- Track consecutive **Common** purchases on the Carpet (`CloutStats.PityCommonStreak`).
- After **8 Commons in a row**, the next Carpet **purchase** that would be Common is upgraded to **Uncommon+** (still pay listed Common price); replacement rolls also bias Uncommon+.
- Any Uncommon+ purchase resets the streak.
- Global stock rotate (no player) does **not** consume pity — only buy → replacement does.
- Paid luck (`LuckService`) still stacks on weights; pity is a free bad-luck floor, not a Secret guarantee.

---

## KPIs (Season 1 targets)

- D1 ≥ 30%, D7 ≥ 10%
- Payer conversion ≥ 3%
- ARPPU: VIP + Battle Pass + limiteds
- Streak claim rate among D1 retainers ≥ 60%
