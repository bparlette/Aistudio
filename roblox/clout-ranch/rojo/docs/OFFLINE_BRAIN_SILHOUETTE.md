# Offline Brain — 64px Silhouette Gate (CloutDev)

**Pet id:** `trend_offline_brain`  
**Factory:** `ReplicatedStorage/Modules/PetFactory.lua` → `BuildModel("trend_offline_brain")`  
**Art law:** gold `#F5C84B` / purple `#5B2A9E` / cream `#FFF6E0` / heat pink rim only (Highlight)

## What must read at 64×64

| Beat | Part(s) | Why it passes |
|------|---------|---------------|
| Empty skull dome | Neon purple ball + dark inner void | Hollow “offline” head, not a licensed mascot |
| Eye punches | Two dark sockets + tiny gold iris | Face reads as skull holes at phone distance |
| Signature spike | Gold crack line + raised dome shard | **One** spike — cracked skull dome |
| Cream belly/trim | Belly ball + jaw plate + foot pads | Cream = readability on purple night |
| Secret rim | Highlight heat-pink fill + gold outline | Thin Mythic/Secret rim — not wallpaper |
| Idle FX | Single `SecretDrip` emitter | One drip OK; no particle soup |

Height target: **~4 studs** (ranch Slot scale).

## Studio verify (64px read) — **CloutDev SHIP required**

1. Sync Rojo → open place → Play (server).
2. Command Bar (or a throwaway LocalScript):

```lua
local PF = require(game.ReplicatedStorage.Modules.PetFactory)
local m = PF.BuildModel("trend_offline_brain")
m.Parent = workspace
m:PivotTo(CFrame.new(0, 4, 0))
```

3. Camera: frame the model so it fills roughly a **64×64** thumbnail (or use Studio Device Emulator at phone res and stand ~35–45 studs back so the pet is stamp-sized on screen).
4. **Pass if** you can name it in <1s without UI: *glowing skull + crack spike + cream belly*.  
   **Fail if** it looks like a licensed character, a glitter blob, or a featureless sphere.

### Optional viewport thumb

In Studio: select model → right-click → **Save to Roblox** / or Screenshot the viewport at low zoom. Crop to 64×64. Dark eye sockets + gold crack must still be visible.

> **Ship gate:** Studio **64×64 crop** of Offline Brain is still the CloutDev SHIP proof. Do not skip it.

## Secondary proof — CarpetShop ViewportFrame (~52px)

`HudModules/CarpetShop.lua` mounts a left-side **ViewportFrame** per stock card and parents `PetFactory.BuildModel(id)` into a `WorldModel`, front-lit for silhouette. Secret / Offline Brain uses a tighter FOV so eye punches + crack spike stay readable at stamp size. If `BuildModel` fails (or Modules not ready), the card falls back to a rarity-colored orb — **not** a substitute for the Studio 64px crop.

- Path: Rojo → `ReplicatedStorage.Modules.PetFactory` (client `require` via FindFirstChild).
- Cleanup: previous viewport / WorldModel contents are destroyed on each stock refresh (maid-like).

## Runtime path

- Ranch place → `RanchService.TryPlacePet` → `PetVisualService.SpawnOnSlot` (Slot1..N markers).
- Steal → slot cleared, `AttachCarry` welds to HumanoidRootPart.
- Deposit / slap-drop → `ClearCarry`; slot respawn via place or Drop return.
- Red Carpet shop → client `CarpetShop` ViewportFrame thumbs (secondary; see above).

## Kill list (do not regress)

- Licensed / trademarked lookalikes  
- Busy face decals  
- Particle soup on idle (more than one drip)  
- Heat pink as body fill  
- Dark-on-dark with no cream trim  
- Shop cards that are text-only (no icon / orb) when stock has a pet id  
