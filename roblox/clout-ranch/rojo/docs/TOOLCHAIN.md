# Toolchain (production slice)

Short map of what’s **installed / pinned** vs **deferred**. Brad is out of the Studio loop for this — configs land on disk under `/workspace/clout-ranch/rojo/`.

## Installed / pinned (this pack)

| Tool | How | Pin / path |
| --- | --- | --- |
| **Rojo** | Aftman | `rojo-rbx/rojo@7.4.4` — already in `aftman.toml`; do not change project map |
| **Selene** | Aftman + `selene.toml` | `Kampfkarren/selene@0.31.0` — Roblox std, low-noise overnight defaults |
| **StyLua** | Aftman + `stylua.toml` | `JohnnyMorganz/stylua@2.5.2` — tabs, width 120 (matches existing Luau) |
| **Wally** | Aftman + `wally.toml` stub | `UpliftGames/wally@0.3.2` — **no runtime deps** yet |
| **ProfileStore** | Vendored (not Wally) | `src/ReplicatedStorage/Packages/ProfileStore.lua` (Mad Studio raw → `.lua`) |

### ProfileStore / Wally (offline pin)

- There is **no official Mad Studio Wally publish** for ProfileStore. Community forks exist; we **do not pin them**.
- `wally.toml` is a **stub** for the future. `wally install` resolves **0 packages** and writes `wally.lock` (empty dep graph).
- Source of truth stays the vendored module under Rojo’s `ReplicatedStorage.Packages` path. When Mad Studio publishes officially, pin under `[server-dependencies]` and migrate off the vendor copy.
- Do **not** point Wally’s install root at `src/ReplicatedStorage/Packages` until that migration is intentional — it would risk clobbering the vendor file.

### Local install

```bash
cd /workspace/clout-ranch/rojo
aftman trust rojo-rbx/rojo Kampfkarren/selene JohnnyMorganz/stylua UpliftGames/wally  # once
aftman install
# optional checks:
selene src/ReplicatedStorage/Config
stylua --check src/ReplicatedStorage/Config
wally install   # no-op deps; keeps lock current
rojo serve
```

## Deferred (later)

| Item | Why deferred |
| --- | --- |
| **React-Roblox / UI libs via Wally** | HUD is hand-rolled Luau; React migration is a separate product slice |
| **Blender / DCC pipeline** | Art stays Brad/asset-pipeline; no headless Blender on the overnight box |
| **Lune CI** | Lint/format CI runners (selene/stylua in GitHub Actions or Lune) after first green local loop |
| **Official ProfileStore Wally pin** | Waiting on Mad Studio publish — keep vendor until then |
| **Marketplace IDs** | Brad-only Creator Dashboard paste — never invent (`docs/MARKETPLACE_IDS.md`) |

## Explicit non-goals (this slice)

- Do **not** break Rojo (`default.project.json` untouched).
- Do **not** invent Marketplace / GamePass IDs.
- Do **not** touch `endsAt` / VIP idle economy knobs.

Pack: `/workspace/toolchain-1.tgz`
