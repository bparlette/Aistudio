# Data Persistence (DataService)

Server-authoritative DataStore saves with **session locking** (Miner's Haven / Roblox best practice) so progress no longer wipes on leave.

Pass tag: **pre-alpha-datastore-tighten-1** (lock re-check on save, BindToClose ≤~8s parallel saves, Studio mock documented as in-memory only).

## Store

- Name: `CloutRanch_Player_v1`
- Key: `u_<userId>`
- Preferred write API: `UpdateAsync`
- Autosave: every **60s** when dirty
- Also saves on `PlayerRemoving` and `BindToClose`

## Profile schema v1

| Field | Meaning |
| --- | --- |
| `schemaVersion` | Always `1` for this layout |
| `sessionVersion` | Increments on each successful save |
| `cash` | Economy wallet cash |
| `incomeMult` | Idle income multiplier (rebirth + 2×Cash, etc.) |
| `pets` | Map `slotIndex` (string) → `petId` on the ranch |
| `maxSlots` | Ranch slot capacity |
| `rebirths` | Rebirth level |
| `aura` | Aura currency |
| `daily` | `{ streak, lastClaimDay, graceUsed }` |
| `luckBoosts` | `{ mult, expiresUnix }[]` (absolute expiry) |
| `battlePass` | `{ seasonId, xp, tier, premium, claimedFree, claimedPremium }` |
| `gamePasses` | Optional owned-flag cache (Marketplace remains source of truth) |
| `lastSeen` | Unix time of last save |
| `lock` | Session lock `{ jobId, timestamp }` |

Carry / mid-steal state is **not** persisted (ephemeral chase). Ranch pets are the inventory of record.

## Session lock rules

1. On join, `Get`/`UpdateAsync` loads the profile and binds `lock = { jobId = this server, timestamp = now }`.
2. If another server holds a lock younger than **30 minutes**, this server **retries** (~8 × 2.5s). Soft messaging: player is waiting on data load.
3. If the lock cannot be acquired, the player is **soft-kicked**: *"Data is loading on another server. Please rejoin in a moment."*
4. Lock is released (cleared) on leave save and on `BindToClose`.
5. Stale locks (≥30 min) are stolen safely by a new server on **acquire** only.
6. **Every save `UpdateAsync` re-checks lock ownership** before writing. If `lock.jobId` belongs to another server (e.g. after TTL expiry and a steal), this server **aborts** the write and keeps the stored profile — no blind overwrite of another server’s lock or progress (`pre-alpha-datastore-tighten-1`).

Only the locking server should mutate and save that profile while the session is live.

## Dirty → save

Economy / ranch pets / rebirth / daily / aura / luck / battle pass / game-pass flags call `DataService.MarkDirty`. Autosave flushes dirty sessions; leave / shutdown always flush.

### BindToClose (shutdown)

- Saves are the **priority** work in `BindToClose` (no other teardown ahead of them).
- All connected players (plus any orphan loaded sessions) are **release-saved in parallel**.
- Budget: aim to finish under **~8 seconds** (`BIND_CLOSE_BUDGET`). Poll ~0.1s until all finishes or budget exhausts.
- Leave/shutdown waits briefly for an in-flight autosave before forcing the release path so a concurrent save does not skip the lock clear.

## Studio / mock mode (in-memory only)

If DataStores are unavailable (Studio without **Studio Access to API Services**, probe `GetAsync` fails, or `GetDataStore` fails), DataService switches to an **in-memory mock** and prints **once**:

`[DataService] … using in-memory mock (game still runs)`

**What the mock is**

- A Lua table in the current server process (`mockStore`) — **not** a DataStore, **not** disk, **not** shared across Studio Play sessions.
- Same session-lock / `UpdateAsync`-shaped API as live so join/save/leave paths keep working.
- Progress restores only while that same Studio server process stays up (Stop Play → Start Play wipes mock data).

**What the mock is not**

- Not durable persistence. Not a substitute for publishing or API-enabled Studio tests.
- Does not invent Marketplace / GamePass IDs; monetization flags still come from `Monetization.lua` / live Marketplace when configured.

Enable **Game Settings → Security → Studio Access to API Services** for real DataStore round-trips in Studio.

## Join order (ServerBootstrap)

1. `DataService.Bootstrap()` (autosave + BindToClose)
2. `DataService.LoadPlayer` — acquire lock, apply profile
3. Existing `InitPlayer` paths (Economy InitPlayer is a no-op if wallet already loaded)
4. Ranch plot assign only if DataService did not already assign + spawn pets (`PetVisualService`)

## Verify in Studio

1. Sync/build the Rojo place; start Play (server).
2. Output should show `[DataService] Bootstrap OK` (mock or live).
3. Earn cash / buy a carpet pet / claim daily.
4. Stop Play → Start Play again.
   - **With API access:** cash, pets, streak, rebirths restore.
   - **Mock mode:** restores only within the same Studio server process; expect the one-time mock print.
5. Optional: two Studio servers / Team Test — second join while first holds lock should wait or soft-kick within the 30‑minute window.

Do **not** invent Marketplace / GamePass IDs; paste real Creator Dashboard IDs into `Monetization.lua` before publish.
