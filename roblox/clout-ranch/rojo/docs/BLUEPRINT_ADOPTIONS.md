# Blueprint Adoptions (overnight) — useful pieces, not Sol’s RNG

Clout Ranch borrows **proven infrastructure and FOMO juice** from the tycoon/steal genre — not the uncapped auto-roll dopamine core.

## Took

### A) Vendor ProfileStore (Mad Studio / loleris)

| Piece | Where |
| --- | --- |
| Vendored module | `src/ReplicatedStorage/Packages/ProfileStore.lua` (raw main `.luau` → `.lua`, attribution kept) |
| Optional backend | `src/ServerScriptService/Services/DataServiceProfile.lua` |
| Flag / fallback | `DataService.lua` — `USE_PROFILE_STORE = true` when `Packages.ProfileStore` + `DataServiceProfile` load; else legacy session-lock DataStore |

**Behavior**

- `StartSessionAsync` on join; mutate `Profile.Data` in memory (`Capture` from Economy / Ranch / etc.).
- Prefer ProfileStore autosave (~**300s**) + `EndSession` flush on leave / BindToClose.
- Keeps `ApplyLoaded` / `ApplyPets` wiring to Economy, Ranch, Rebirth, Aura, Daily, Luck, BattlePass, Monetization.
- Studio: `ProfileStore.Mock` when DataStore state is `NoAccess` / `NoInternet`.
- Store name: `CloutRanch_ProfileStore_v1` (separate from legacy `CloutRanch_Player_v1` so formats don’t collide).

Set `USE_PROFILE_STORE = false` in `DataService.lua` to force the legacy path.

### B) Shared Config (no magic numbers)

| Module | Keys |
| --- | --- |
| `ReplicatedStorage/Config/EconomyConfig.lua` | StarterCash, LockSecondsF2P/VIP, NewbieLockSeconds, SoftProtectSeconds |
| `ReplicatedStorage/Config/CarpetWeights.lua` | Weights, Prices, RotateEvery, StockSize, FeaturedPickChance |
| `ReplicatedStorage/Config/SoftPityConfig.lua` | CommonStreakForce, ForcedMinRarity, RarityOrder |

**Wired**

- `SoftPityService` ← SoftPityConfig
- `CarpetService` ← CarpetWeights
- `EconomyService` / `RanchService` / `Monetization.GetLockSeconds` / `StealService` SoftProtect ← EconomyConfig

### C) MessagingService FOMO

| Piece | Where |
| --- | --- |
| Service | `ServerScriptService/Services/FomoBroadcastService.lua` |
| Topic | `CloutRanchFomo` |
| Payload | `{ kind, displayName, playerName }` — kid-safe, no platform brands |
| Rate limit | ~8s per server publish |
| Client juice | Feedback broadcast + Juice `fomo_banner` |

**Hooks (pcall)**

- `StealService` — Secret steal success → `secret_steal`
- `JuiceService.Hatch` — Secret / Mythic → `mythic_hatch`
- `AuraService` podium — winners[1] → `aura_podium`
- `ServerBootstrap` — `FomoBroadcastService.Bootstrap()`

Studio without MessagingService: local banner only.

## Skipped (on purpose — not Sol’s RNG)

- **Uncapped auto-roll / auto-hatch core** — no AFK roll machine, no infinite carpet spin loop as the primary loop.
- **Pay-to-skip pity / paid force-Mythic** — soft pity stays F2P (`CommonStreakForce` only).
- **Brand-name FOMO copy** or cross-promo spam in MessagingService payloads.
- **Full ProfileStore cutover without flag** — legacy DataService remains the safe fallback.
- **Migrating** legacy `CloutRanch_Player_v1` keys into ProfileStore in this pass (new store name; migrate later if needed).
- **Sol-style** multi-currency gacha boards, index-chase as the only retention, or server-wide uncapped luck stacking as core identity.

## Rojo

`default.project.json` maps:

- `ReplicatedStorage/Packages` → `src/ReplicatedStorage/Packages`
- `ReplicatedStorage/Config` → `src/ReplicatedStorage/Config`

No laptop sync required for this overnight drop — files live under `/workspace/clout-ranch/rojo/`.
