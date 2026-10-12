# Clout Ranch — Monetization Catalog

Wire real Creator Dashboard IDs into `Services/Monetization.lua` (`PASS` / `PRODUCT`). Prices are **guidance** for Season 1 launch; tune after first payer cohort.

**Design rule:** free-to-win core loop (idle income, steal, carpet, aura, rebirth). Paid SKUs buy **edge** (time, lock, luck, slots, slap), **cosmetics / flex**, and **FOMO limiteds** — never exclusive win conditions.

IDs start at `0` (disabled) until pasted.

---

## GamePasses (permanent)

| Key | Type | ~Robux | What it buys |
|-----|------|--------|--------------|
| **DoubleCash** (`2× Cash`) | GamePass | **449** | ×2 ranch idle Cash only via `EconomyService.SetIncomeMult` (not steal PvP). VIP has **no** idle mult, so idle stack is just ×2 from this pass (+ other non-VIP mults). |
| **VIP** | GamePass | **799** | Lock-only PvP edge: F2P lock 45s → VIP lock **120s** + VIP badge (`RanchService.Lock` / `Monetization.GetLockSecs`). **No idle cash multiplier.** Primary ARPPU pass — defend overnight pets. |
| **ExtraSlot** | GamePass | **299** | Soft power: +1 ranch pet slot (more parallel idle income). Never the only path to high CPS — rebirth also expands slots. |
| **StealSlapPlus** (`Slap+`) | GamePass | **149** | Defense edge: stronger / faster slap on thieves (range or cooldown). Skill + presence still matter; pass shortens recoveries. |

---

## Developer Products (consumable / season)

| Key | Type | ~Robux | What it buys |
|-----|------|--------|--------------|
| **CashPackSmall** | DevProduct | **49–99** | Instant ~500 cash. Impulse top-up when stuck under a carpet price — not a whale dump. |
| **LuckBoost30m** | DevProduct | **49–99** | `LuckService.AddBoost(1.5, 1800)` — Carpet rarity bias for 30 minutes. Stacks capped (`LuckService` MAX_LUCK). Soft pity elsewhere keeps F2P viable. |
| **StarterPack** | DevProduct | **~175** | One-time oriented: ~750 cash + short luck (20m @ 1.35). Optional: seed Uncommons via ranch place if inventory allows. Best early conversion SKU. |
| **BattlePass** | DevProduct | **799** | Season premium track unlock (`Monetization.Has(player,"BattlePass")` / `BattlePassService.SetPremium`). Free track remains fully claimable; premium = edge cash/luck/aura + FOMO pets. |
| **LimitedAuraDrip** | DevProduct | **99–400** | Pure flex: burst aura currency for Aura Flex podium vibes / cosmetics drip. Price ladder by drop rarity; rotate copy with SeasonService limited windows. |

---

## Suggested Creator Dashboard naming

| Dashboard name | Internal key |
|----------------|--------------|
| Clout Ranch — 2x Cash | `DoubleCash` |
| Clout Ranch — VIP Lock | `VIP` |
| Clout Ranch — Extra Slot | `ExtraSlot` |
| Clout Ranch — Slap+ | `StealSlapPlus` |
| Cash Pack (S) | `CashPackSmall` |
| Luck Boost 30m | `LuckBoost30m` |
| Starter Pack | `StarterPack` |
| Season 1 Battle Pass | `BattlePass` |
| Limited Aura Drip | `LimitedAuraDrip` |

---

## Receipt / ownership map

- **GamePasses:** `UserOwnsGamePassAsync` on join + `PromptGamePassPurchaseFinished` → `Monetization` flags → `ApplyOwned` / VIP lock.
- **DevProducts:** single `MarketplaceService.ProcessReceipt` handler in `Monetization.lua` (idempotent grants; BattlePass sets flag + `SetPremium`).
- **Luck:** always through `LuckService` (timed, capped) — never permanent secret rate from a one-off product without a season pass story.

---

## Ladder (player-facing)

1. Starter Pack (session 1) → 2. Luck Boost when chasing Carpet Secret → 3. VIP when first rage-stolen → 4. Battle Pass mid-season → 5. Limited Aura / Extra Slot as flex & scale.
