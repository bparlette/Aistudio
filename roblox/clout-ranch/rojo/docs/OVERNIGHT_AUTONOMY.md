# Overnight Autonomy — Ownership Split

**Rule:** Agents own almost everything overnight. Brad only does Creator Dashboard / publish / human-eye gates that cannot be automated.

---

## Brad-only (do not invent, do not skip)

| Gate | Why Brad | Where |
|------|----------|-------|
| **Marketplace IDs** | Must paste real Pass / DevProduct IDs from Creator Dashboard — never invent `0` replacements | `docs/MARKETPLACE_IDS.md` → `Monetization.lua` |
| **64px Offline Brain stamp** | Human eye-read at stamp size (skull + crack readable in CarpetShop ViewportFrame) | `docs/OFFLINE_BRAIN_SILHOUETTE.md` — Studio crop / approve |
| **Publish** | Place publish + live security (API Services, third-party sales) after IDs + 64px clear | Creator Dashboard / Studio File → Publish |

Brad checklist (≤15 min when unblocked):

1. Paste Marketplace IDs from Dashboard into `PASS` / `PRODUCT` (see `MARKETPLACE_IDS.md`).
2. Spawn Offline Brain → confirm **64px** silhouette read in shop + world.
3. Publish place only after IDs non-zero on live purchase paths + 64px PASS.

---

## Agents own (overnight / async)

- Rojo project + disk world: `src/Workspace/Ranches/` Ranch1..Ranch6 (Edit-mode visible), `default.project.json` Workspace → Ranches `$path`
- MapBootstrap Play upgrade (`Build` / `EnsureWorld`); ServerBootstrap `ensureRanchesExist` fallback (`≥6` children); **Color3.fromRGB only** in MapBootstrap (no `fromHex`)
- Systems, HUD, juice, DataStore, carpet shop, steal/lock, economy, playtest docs, packs (`*.tgz`)
- Copy / LiveOps staging that stays **DARK** until Brad 64px + IDs + publish

---

## Edit-mode farms (this pack)

`Workspace.Ranches` is Rojo-synced so Studio **Edit** shows Ranch1..6 without Play:

- RING=56, SPAWN_RING=16, angles `(i-1)/6 * 2π - π/2`
- Base `40×1.2×40` grass, gold neon BaseRim, SpawnLocation lookAt Base
- **Density pads now on disk** (overnight-autonomy-2): per ranch `Slot1..3` (7×0.45×7 lilac neon + gold Rim + SlotLabel), `DepositPad` (8×0.5×8 mint + Rim + label), `LockPad` (8×0.5×8 purple + Rim + label) — offsets match MapBootstrap `SLOT_OFFSETS` / `ensureActionPad`
- MapBootstrap Play upgrade stays **idempotent** (`ensurePart` / `ensureRim` / `ensureBillboard`); path lights still runtime
- `ignoreUnknownInstances` on Ranches folder + each Ranch model; no Marketplace IDs / VIP idle / endsAt changes

Pack: `/workspace/overnight-autonomy-2.tgz`
