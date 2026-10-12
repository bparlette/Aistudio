# Clout Ranch — MVP systems outline

## Modules (Luau)
- `PetCatalog` — id, rarity, income/sec, carrySpeed, modelId
- `RanchService` — slots, lockUntil, owner, petIds[]
- `EconomyService` — cash, multipliers, purchase handlers
- `CarpetService` — rotating stock every N seconds
- `StealService` — grab, carry, drop, return-to-owner rules
- `AuraService` — round timer, entries, votes, rewards
- `RebirthService` — cost curve, permanent bonuses
- `Monetization` — gamepasses + dev products (PromptProductPurchase)

## Starter pet roster (original names — placeholders)
| Id | Name | Rarity | $/sec |
|----|------|--------|-------|
| c1 | Drip Mutt | Common | 5 |
| c2 | Cap Crab | Common | 6 |
| u1 | Ratio Raven | Uncommon | 15 |
| u2 | Main Character | Uncommon | 18 |
| r1 | Aura Gator | Rare | 45 |
| r2 | Timeline Titan | Rare | 55 |
| e1 | Clout Kraken | Epic | 120 |
| s1 | Viral Wisp | Secret | 400 |

## Steal rules (fairness)
- Ranch unlocks after lock expires; newbie first lock = 45s free
- Carried pet slows thief; owner slap = force drop
- Stolen pet must reach thief ranch to transfer ownership
- Soft target protection: you can’t be stolen twice within 15s

## Aura Flex (20s)
1. Bell → stage opens
2. Players emote + showcase top pet
3. Others tap vote (1 vote each)
4. Top 3 get Aura currency + podium VFX for clips
