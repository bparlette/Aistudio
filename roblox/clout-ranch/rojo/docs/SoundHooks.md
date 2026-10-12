# Clout Ranch — Sound Hooks

**`HudModules/SoundHooksApi.lua`** (booted by `SoundHooks.client.lua`) is the **sole** Juice / Feedback SFX owner.  
`HudModules/SoundService.Start` is a **no-op** — do not dual-listen `Remotes.Juice` (anti-double).

All asset IDs are free Toolbox stubs — swap only via CloutSound ALT pack if Get Audio fails.

## Ownership

| Layer | Role |
|-------|------|
| `SoundHooks.client.lua` | Boots `SoundHooksApi.Start()` once |
| `SoundHooksApi` | Debounced buses, BigJuice mutex, bed duck; listens Juice + Feedback |
| `SoundService.lua` | Optional `Play`/`Handle` helpers only — **`Start` no-op** |

## Juice payload

```lua
Remotes.Juice:FireClient(player, {
  kind = string,           -- see alias table
  subjectUserId = number?,
  targetUserId = number?,
  rarity = string?,        -- Common…Secret — drives hatch bus branch
  petId = string?,
  winners = { number }?,
  message = string?,
})
```

Hatch: `PlayKind` receives the full payload and **branches on `rarity` before Play**. Hatch never uses the buy bus above Common.

## Buses (SoundHooksApi)

| Bus | Asset | Vol | Notes |
|-----|-------|-----|-------|
| steal | 9120708094 | 0.70 | + sparkle 9126090298 @0.45 +40ms |
| lock / lockClick | 9114881879 / 140910211 | 0.60 / 0.40 | Lock / deposit-lock UI **only** |
| buy | 7112275565 | 0.65 | Carpet confirm + **Common** hatch |
| rare | 9116384757 Magic Burst | 0.78 | Rare/Epic/**Legendary** hatch (+ sparkle); server toast tone `rare` |
| slap | 9120907213 Wood Impact 2 | 0.70 | speed 1.05; backup 9114111252 |
| place | 9120907213 | 0.68 | Pad-pop **thud** (not kaching / cash win) |
| aura / podium / daily / rebirth / mythic* | (unchanged) | — | BigJuice mutex on mythic/rebirth/aura |
| bedRanch | 9118752742 | 0.22 | Looped; duck on big juice |

## Kind → bus alias (juice-2-stings)

| `kind` | Alias / bus | Debounce moment |
|--------|-------------|-----------------|
| `steal`, `steal_trail` | steal | steal 0.15s |
| `lock` | lock (+ lockClick) | lock 0.15s |
| `buy`, `success`, `pop` | buy | buy 0.15s |
| `hatch_drip` / `hatch_burst` | **by rarity** → buy (Common) / rare (Rare/Epic/Legendary) / mythic (Mythic/Secret) | buy / rare / mythic |
| `rare`, `clip` | rare | rare 0.35s |
| `slap` | **slap** (NOT lock) | **impact** 0.15s |
| `place`, `place_burst`, `deposit` | **place** pad-pop | **impact** 0.15s (shared w/ slap) |
| `aura`, `flex`, `flex_shock`, `vote_punch` | aura | aura 0.35s |
| `podium`, `aura_beams` | podium | podium 0.35s |
| `rebirth`, `rebirth_flash`, `clout` | rebirth | rebirth 0.80s |
| `daily` | daily | daily 0.35s |
| `mythic`, `mythic_entrance` | mythic stack | mythic 0.80s |

### Killed stale aliases (do not restore)

- ~~`slap` → lock~~ → slap bus
- ~~`deposit` → lock~~ → place
- ~~`place` / `place_burst` → buy~~ → place
- ~~`hatch_burst` / `hatch_drip` → buy~~ unconditionally → rarity branch

## Deposit = one sting

`JuiceService.Deposit` emits **one** Juice key: `place`.  
Do **not** also fire `deposit` + `place_burst` same frame (was lock + buy double).  
Do **not** fire lock or buy on deposit. Hatch may still append `place_burst` for pad VFX after buy.

## Server fire sites

| Service | Event |
|---------|-------|
| `StealService.TrySteal` | `steal` |
| `StealService.Slap` | `slap` |
| `StealService.TryDeposit` | **`place` only** |
| `CarpetService.TryBuy` → `JuiceService.Hatch` | `hatch_*` / `mythic` + `place_burst` |
| `RebirthService` | `rebirth` |
| `AuraService` | `flex_shock`, `aura_beams`, `vote_punch` |
| Lock pad | `lock` |

## Art-canon kind aliases (VfxService)

| Art moment | Juice `kind` |
|------------|--------------|
| Hatch drip | `hatch_drip` / `hatch_burst` |
| Pad pop | `place` / `place_burst` |
| Flex shock ring | `flex_shock` / `aura_beams` |
| Steal cream flash | `steal_trail` / `steal` / `slap` |
| Rebirth flash | `rebirth_flash` |
| Mythic heat-pink | `mythic` |
