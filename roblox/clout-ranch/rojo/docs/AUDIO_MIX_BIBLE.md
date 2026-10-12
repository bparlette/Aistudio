# Clout Ranch — Audio Mix Bible (CloutSound)
Clout Ranch only. Free Toolbox audio. No licensed songs. No Sundog assets.

## Mix (mobile-first)
- Phone speakers + earbuds. Bright gold sparkle + purple bass thump. Short tails. Cut mud under 120 Hz on UI/juice.
- Juice stings peak ~-6 to -3 dBFS short; beds ~-18 to -14 feel under SFX.
- Duck music 3–6 dB for 200–400 ms on big juice (steal, rare, Aura Flex, rebirth, mythic).
- One juice layer wins — never stack two big stings same frame.
- Cooldowns: steal/lock ≤1 sting/action; daily claim once.
- UI/juice mostly 2D center; beds low stereo width.
- One-shots <1.5s (rebirth/mythic ≤3s).

## Stack order (top wins)
1. Critical UI (buy confirm, lock)
2. Juice sting
3. Podium / flex sting
4. Ambient ranch bed

## Moment → Toolbox search keywords
| Moment | Keywords |
|--------|----------|
| Steal | `whoosh swipe`, `swoosh short`, `coin collect sparkle`, `magic poof soft` |
| Lock | `UI click soft`, `lock click`, `metal latch short` |
| Buy | `cash register`, `coin drop cascade`, `purchase success chime` |
| Rare drop | `rare item chime`, `crystal sparkle`, `magic shine rise`, `loot sparkle` |
| Aura Flex | `power up bass`, `energy surge short`, `aura whoosh`, `magic burst sparkle` |
| Podium | `victory fanfare short`, `win sting`, `rank up chime`, `podium cheer short` |
| Rebirth | `rebirth power`, `level up epic short`, `phoenix rise soft`, `transform whoosh` |
| Daily claim | `daily reward chime`, `claim success`, `bonus coin`, `gift open soft` |
| Mythic entrance | `mythic entrance`, `legendary appear`, `epic reveal short`, `portal open sparkle` |

## Beds
- Ranch: `farm ambient soft`, `countryside birds quiet`, `soft wind loop`
- Shop: `shop ambience soft`, `ui pad soft loop`

## Asset names
`SFX_Steal_*`, `SFX_Lock_*`, `SFX_Buy_*`, `SFX_RareDrop_*`, `SFX_AuraFlex_*`, `SFX_Podium_*`, `SFX_Rebirth_*`, `SFX_DailyClaim_*`, `SFX_MythicEntrance_*`, `BED_Ranch_*`, `BED_Shop_*`

## Optional ALT pack (CloutSound — swap only if Get Audio fails / playtest hates)
- Lock: 15675059323 / 15675032796 (Roblox UI clicks)
- Buy: 9113728042 / 9113728049
- Rare/Aura/Mythic rise: 9125805579
- Rare/Podium UI whoosh: 15674975792
- Aura Flex UI whoosh: 15675012262
- Steal coin layer: 9113849579
Keep BED_Ranch 9118752742 (do not map bed to coin/UI).

## Dual-path anti-double (CRITICAL — overnight harden)
Juice must never fire twice from SoundHooks **and** a legacy SoundService / Feedback path.

### Ownership (one path wins)
| Moment | Owner | Must NOT also play |
|---|---|---|
| Steal, RareDrop, AuraFlex, Podium, Rebirth, DailyClaim, MythicEntrance | `Remotes.Juice` → SoundHooks only | SoundService one-shots, Feedback remote, server-played Sound for that client |
| Lock, Buy (dry UI) | `Remotes.Feedback` → SoundHooks Feedback tones only | Juice remote for same action |
| Beds | SoundHooks bed bus only | Duplicate looping Sounds in Workspace/SoundService |

### Rules
1. **Single client owner:** only `SoundHooks.client.lua` creates/plays juice Sounds. `SoundService.Start` is a no-op.
2. **One remote per action:** Juice OR Feedback for the same player/frame — never both for the same sting.
3. **Server silence for juice:** server fires remotes only; never parents a Sound to the player for that sting.
4. **Debounce:** Steal/Lock/Buy/Impact(slap+place) 0.15s · Rare/AuraFlex/Podium/Daily 0.35s · Rebirth/Mythic 0.80s
5. **Replace, don’t stack:** stop active Sound for same moment key before replay (or ignore in cooldown).
6. **BigJuice mutex:** Mythic / Rebirth / AuraFlex — starting one stops the others.
7. **Duck once:** bed duck from SoundHooks only.

### Studio sanity
Steal 5× fast → one whoosh per press. If doubled, grep moment/asset id outside SoundHooks.


### Code enforcement (`SoundHooks.client.lua`)
- `lastPlayed[moment]` debounce: Steal/Lock/Buy/Impact(slap+place) **0.15s**; Rare/AuraFlex/Podium/Daily **0.35s**; Rebirth/Mythic **0.80s**
- Replace-don't-stack: `stopMoment(moment)` before replay
- BigJuice mutex: Mythic / Rebirth / AuraFlex — starting one stops the other two
- `HudModules/SoundService.Start` remains a **no-op**; only SoundHooks listens to `Remotes.Juice`


## JUICE-2 STING FIX (slap / place / rare hatch)

Cosmetic audio only — no economy / VIP / endsAt / paywall / client-trust.

| Rule | Detail |
|------|--------|
| Rare/Epic/**Legendary** hatch | `hatch_*` + `payload.rarity` → **rare** bus `9116384757` @0.78; optional sparkle `9126090298` @0.45 +40ms. Server toast tone `rare` (not buy). Common → **buy** `7112275565` @0.65. Mythic/Secret → existing mythic stack. Never buy-alias above Common. |
| Slap | Dedicated **slap** bus `9120907213` Wood Impact 2 @0.70 speed 1.05 (backup `9114111252`). **Not** lock. Lock buses = lock UI only. |
| Deposit / place | **One** sting: Juice `place` → pad-pop `9120907213` @0.68 (thud, not kaching). No deposit+place_burst double; no lock/buy on deposit. |
| Impact family debounce | `slap` + `place`/`deposit`/`place_burst` share **impact** moment **0.15s** (replace-dont-stack). |

SoundHooks remains sole Juice SFX owner (`SoundService.Start` no-op). See `docs/SoundHooks.md` alias table.
