# Clout Ranch — Marketplace ID Paste Checklist

**Rule (CloutDev):** never invent IDs. Paste from Creator Dashboard only.  
**SHIP / publish:** HARD FAIL if any live purchase path still has `0`.  
**Pre-alpha:** PASS WITH NOTES while zeros remain.

Paste into `src/ServerScriptService/Services/Monetization.lua` → `PASS` / `PRODUCT` tables.

## Creator Dashboard steps (Brad)
1. Open [Creator Dashboard](https://create.roblox.com/) → your Clout Ranch experience
2. **Monetization → Passes** — create each Game Pass with the exact name below; copy numeric ID
3. **Monetization → Developer Products** — create each Dev Product; copy numeric ID
4. Paste IDs into `Monetization.lua` (replace every `0`)
5. In Studio: **Game Settings → Security → Allow HTTP / third party sales** as needed; test with a test account
6. Ping CloutDev / Roblox agent — they verify non-zero + `ProcessReceipt` wiring

## Game Passes → `PASS`

| Dashboard name (suggested) | Key | ~Robux | Paste ID |
|----------------------------|-----|-------:|----------|
| Clout Ranch — VIP Lock | `VIP` | 799 | `_______` |
| Clout Ranch — 2× Cash | `DoubleCash` | 449 | `_______` |
| Clout Ranch — Auto-Collect | `AutoCollect` | 249 | `_______` |
| Clout Ranch — Extra Pet Slot | `ExtraPet` | 349 | `_______` |
| Clout Ranch — Ranch Hopper | `FastTravel` | 149 | `_______` |
| Clout Ranch — Flex Priority | `FlexQueue` | 199 | `_______` |

## Developer Products → `PRODUCT`

| Dashboard name (suggested) | Key | ~Robux | Paste ID |
|----------------------------|-----|-------:|----------|
| Clout Ranch — Starter Pack | `Starter` | 175 | `_______` |
| Clout Ranch — Comeback Pack | `Comeback` | 99 | `_______` |
| Clout Ranch — Cash S | `CashS` | 49 | `_______` |
| Clout Ranch — Cash M | `CashM` | 149 | `_______` |
| Clout Ranch — Cash L | `CashL` | 399 | `_______` |
| Clout Ranch — Cash XL | `CashXL` | 999 | `_______` |
| Clout Ranch — Clout Egg | `Egg1` | 99 | `_______` |
| Clout Ranch — Clout Egg ×3 | `Egg3` | 249 | `_______` |
| Clout Ranch — Lock Refill | `LockRefill` | 79 | `_______` |
| Clout Ranch — Steal CD Skip ×5 | `SkipCD` | 49 | `_______` |
| Clout Ranch — Flex Ticket ×3 | `FlexTicket` | 39 | `_______` |
| Clout Ranch — Egg Reroll | `Reroll` | 59 | `_______` |
| Clout Ranch — Season BP | `BattlePass` | 799 | `_______` |
| Clout Ranch — Season BP+ | `BattlePassPlus` | 1199 | `_______` |
| Clout Ranch — Weekly Aura | `WeeklyAura` | 349 | `_______` |
| Clout Ranch — Weekly Pet Skin | `WeeklyPetSkin` | 299 | `_______` |

## Launch-critical first (min set for soft funnel)
1. `VIP` · `DoubleCash` · `Starter` · `BattlePass`  
2. Then cash packs + lock refill  
3. Then limiteds / extras  

## Code helpers
`Monetization.CountUnsetIds()` / `Monetization.HasLivePurchaseIds()` / `Monetization.TryPrompt` — see `Monetization.lua`.
Unset-ID boot **warn** is hoisted onto `Monetization` require (WARN only — not a runtime halt).
Soft funnel UI (`SoftOffer` + `SoftFunnel`): ID `0` → dark **Coming soon** CTA; **never** Prompt* until Brad pastes real IDs.
Pre-alpha: soft prompts stay OK with zeros; **never** enable live Prompt* for a SKU still at 0 in a published place.
