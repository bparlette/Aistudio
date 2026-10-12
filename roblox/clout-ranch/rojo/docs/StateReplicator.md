# StateReplicator — what the server must expose for the client HUD

Thin contract between `ServerBootstrap` / services and `StarterPlayerScripts` HUD.

## Already expected (Bootstrap creates most of these)

### `ReplicatedStorage.Remotes` (Folder)

| Name | Class | Client use |
|------|--------|------------|
| `BuyCarpet` | RemoteEvent | FireServer(stockIndex: number) 1..4 |
| `DepositPet` | RemoteEvent | FireServer() |
| `DoRebirth` | RemoteEvent | FireServer() |
| `RequestLock` | RemoteEvent | FireServer() |
| `StealClosest` | RemoteEvent | FireServer() — action bar STEAL |
| `StealPet` | RemoteEvent | FireServer(plotName, slotIndex) — optional / world prompts |
| `SlapThief` | RemoteEvent | FireServer(targetUserId) |
| `VoteAura` | RemoteEvent | FireServer(targetUserId) |
| `ClaimDaily` | RemoteEvent | FireServer() — daily claim button |
| `Feedback` | RemoteEvent | **Server → client** `FireClient(player, { message: string, tone: Tone })` |

`Tone` values used by HUD: `info` \| `success` \| `warn` \| `error` \| `clout` \| `clip` (also accepts kind aliases `steal`/`buy`/`rebirth`/`daily`/`aura`).

Legacy alias: `ListenFeedback` (RemoteEvent or BindableEvent) is still listened to if present.

### `ReplicatedStorage.CloutState` (Folder)

| Name | Class | Notes |
|------|--------|------|
| `Phase` | StringValue | `"idle"` \| `"flex"` \| `"podium"` — HUD shows Aura Flex banner on change |
| `EndsAt` | NumberValue | Prefer **`workspace:GetServerTimeNow()`-compatible unix seconds**. If you write `os.clock()`, clients cannot countdown accurately (HUD falls back to local 20s/8s timers). |
| `TrendTitle` | StringValue | Trend Week banner (`TREND WEEK · {displayName}`); empty when no active drop |
| `TrendEndsAt` | NumberValue | Active drop `endsAt` unix (GetServerTimeNow scale) |
| `ServerTime` | NumberValue | Mirrored `workspace:GetServerTimeNow()` for client countdowns |

### `Player.CloutStats` (Folder, per player)

| Name | Class | Notes |
|------|--------|------|
| `Cash` | NumberValue | Animated cash counter; EconomyService already sets this |

---

## Gaps the HUD needs (add on server if missing)

### 1. `Remotes.GetCarpetStock` — **RemoteFunction** (missing)

Client polls every ~2s. Return an array of up to 4 entries:

```lua
{
  { id = "c1", name = "Drip Mutt", rarity = "Common", price = 25 },
  ...
}
```

Suggested Bootstrap wiring:

```lua
local function ensureRF(name: string): RemoteFunction
  local r = remotes:FindFirstChild(name)
  if not r then
    r = Instance.new("RemoteFunction")
    r.Name = name
    r.Parent = remotes
  end
  return r :: RemoteFunction
end

local GetCarpetStock = ensureRF("GetCarpetStock")
GetCarpetStock.OnServerInvoke = function(_player)
  local out = {}
  for i, petId in CarpetService.GetStock() do
    local def = PetCatalog.Get(petId)
    table.insert(out, {
      id = petId,
      name = def and def.name or petId,
      rarity = def and def.rarity or "Common",
      price = CarpetService.GetPrice(petId) or 0,
    })
  end
  return out
end
```

Optional: also push stock into `CloutState` StringValues / a Folder of ValueBases if you prefer replication over RF.

### 2. `Player.CloutStats.DailyStreak` — **NumberValue / IntValue** (missing)

Daily claim UI reads this for the streak label. `DailyService.GetStreak(player)` exists but is not replicated yet — after claim / on join, write:

```lua
local streak = folder:FindFirstChild("DailyStreak") or Instance.new("IntValue")
streak.Name = "DailyStreak"
streak.Value = DailyService.GetStreak(player)
streak.Parent = folder
```

### 3. Feedback on buy / steal / rebirth / daily

Wire `FeedbackService.Tell(player, msg, tone)` from `CarpetService.TryBuy`, `StealService`, `RebirthService.TryRebirth`, and `DailyService.TryClaim` so the center toast pops on success/fail (HUD already listens to `Remotes.Feedback`).

### 4. `EndsAt` clock domain

Change Aura tick to store absolute time, e.g. `endsVal.Value = workspace:GetServerTimeNow() + remaining`, so the banner countdown is correct.

---

## Client file map

```
StarterPlayerScripts/
  ClientHud.client.lua          — LocalScript bootstrap
  HudModules/                   — ModuleScripts
    Theme.lua
    Util.lua
    CashCounter.lua
    CarpetShop.lua
    DailyClaim.lua
    AuraBanner.lua
    FeedbackToast.lua
    TutorialTips.lua
    ActionBar.lua
```
