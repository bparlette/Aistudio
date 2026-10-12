# Clout Ranch — Weekly Trend Drop Pipeline

**Owner:** Brad Parlette (+ this agent for code/catalog/docs)  
**Hook:** Every week the game ships a new **ORIGINAL** pet inspired by whatever is loud in kid internet culture — **never** licensed IP names, NFL marks, doll brands, or Italian-brainrot trademarks.

**Player-copy law:** Never say X, Twitter, or TikTok in HUD, banners, trailers, Discover, or kid ads (most Roblox players don’t have those accounts). Research sources stay internal; player wording = “weekly trend / viral vibe / internet culture.”  
**Systems:** `TrendDropService` · `SeasonService` (Trend Week banner) · `CarpetService` featured Secret · `ClipMomentService` · `PetCatalog`

---

## Cadence (UTC weeks)

| Day | Who | Do this |
|-----|-----|---------|
| **Mon** | Brad + agent | **Research** — skim viral internet *patterns* privately (sports-fraud energy, aura-farming, blind-box charm, soft-reveal vibes). Capture 3–5 mood refs. **No trademarked names. Never name research platforms in player copy.** |
| **Tue** | Brad | **Name + art brief** — pick an original display name + silhouette notes. Agent drafts `trailerLine` + weekId. |
| **Wed** | Agent | **Code pet id** — add Secret to `PetCatalog`, append `TrendDropService` DROPS row (`weekId`, `petId`, `displayName`, `startsAt`, `endsAt`, `trailerLine`). Verify carpet inject. |
| **Thu** | Brad + agent | **Ship** — publish place / config. Confirm `CloutState.TrendTitle` + `TrendEndsAt` on a live server. |
| **Fri–Sun** | Brad | **Push clips** (Roblox share / short video / whatever channel Brad uses) — Secret steals + Aura podium. Use in-game clip toasts (`kind = "clip"`). No platform names in the in-game toast. |

Week windows are **Mon 00:00 UTC → next Mon 00:00 UTC** (`startsAt` / `endsAt` unix, matched to `workspace:GetServerTimeNow()`).

**Hard kill:** `endsAt` is fixed in the DROPS table. `TrendDropService` exposes **no** Extend / SetEndsAt API — do not add one.

---

## Checklist — Brad

- [ ] Trend is a *vibe*, not a brand (no team names, no doll IP, no licensed characters)
- [ ] Display name is first-party and searchable
- [ ] Art brief has silhouette + 1 color beat + 1 gag
- [ ] Trailer line is one short, clip-friendly sentence (no platform names)
- [ ] Thu: spot-check Carpet stock for featured Secret bias
- [ ] Fri–Sun: post ≥3 clips (steal / podium / hatch-or-buy if available)
- [ ] Sunday night: note next week’s candidate vibes for Mon research

## Checklist — Agent

- [ ] `PetCatalog` Secret entry (`id`, `name`, `rarity = "Secret"`, income, carrySlow, auraBonus)
- [ ] `TrendDropService` DROPS entry with correct unix window
- [ ] No licensed / trademarked strings anywhere (ids, names, trailerLine, docs)
- [ ] `SeasonService` banner syncs `CloutState.TrendTitle` / `TrendEndsAt`
- [ ] `CarpetService.SetFeaturedPetId` wired via `TrendDropService.BindCarpet`
- [ ] Weight transform includes `TrendDropService.ApplyFeaturedWeights`
- [ ] `ClipMomentService` still fires on Secret steal + Aura podium
- [ ] Bootstrap tryRequire + loaded print includes TrendDrop / ClipMoment
- [ ] Update this doc’s “Seeded drops” table when shipping

---

## How it works in-game

1. **Active drop** = `TrendDropService.GetActive()` where `now ∈ [startsAt, endsAt)`.
2. **Carpet** — Secret weight ×2.5; when Secret (matching rarity) rolls, ~60% chance the featured `petId` is picked (`SetFeaturedPetId`).
3. **HUD banner** — `SeasonService` writes:
   - `ReplicatedStorage.CloutState.TrendTitle` (StringValue) e.g. `TREND WEEK · Whistle Fraudling`
   - `ReplicatedStorage.CloutState.TrendEndsAt` (NumberValue) = drop `endsAt` (GetServerTimeNow scale)
4. **Clip moments** — `ClipMomentService`:
   - Secret stolen → Feedback + Juice `kind = "clip"`
   - Aura podium → same for winners + lobby ping

Remotes used: existing `Feedback`, `Juice` (no new remotes required for MVP).

---

## Seeded example drops (ORIGINAL names)

| weekId | petId | displayName | vibe (generic) | window (UTC) |
|--------|-------|-------------|----------------|--------------|
| 2026-W36 | `trend_offline_brain` | Offline Brain | AI-down / offline meme energy | Sep 4–8 2026 |
| 2026-W37 | `st_fraud_whistle` | Whistle Fraudling | sports-fraud meme energy | Sep 8–15 2026 |
| 2026-W38 | `st_aura_harvester` | Aura Harvester | aura farming | Sep 15–22 2026 |
| 2026-W39 | `st_capsule_charm` | Capsule Charmling | blind-box charm | Sep 22–29 2026 |
| 2026-W40 | `st_ribbon_reveal` | Ribbon Debutante | soft-reveal / unbox vibes | Sep 29–Oct 6 2026 |

Unix: `1788825600` → `1791244800` (see `TrendDropService.lua`).

---

## Naming rules (non-negotiable)

1. Original creature / object mashups only.
2. Describe the *meme energy*, never the mark.
3. If legal would pause, rename before ship.
4. Pet ids: `st_<slug>` for trend Secrets.

---

## Quick add template

```lua
-- PetCatalog
st_example = { id = "st_example", name = "Example Pet", rarity = "Secret", incomePerSec = 520, carrySlow = 0.37, auraBonus = 7 },

-- TrendDropService DROPS
{
  weekId = "2026-W41",
  petId = "st_example",
  displayName = "Example Pet",
  startsAt = 1791244800,
  endsAt = 1791849600,
  trailerLine = "One line. Zero trademarks. Pure clip bait.",
},
```

---

## Related docs

- `RetentionGDD.md` — FOMO weekly pet / featured rotation
- `economy-liveops.md` — Mon drop calendar + season length
- `MASTER_VISION.md` — live culture pillar
