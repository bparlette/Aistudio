# Clout Ranch — Rojo

## Connect
1. Install the **Rojo** plugin in Roblox Studio (Creator Store, search "Rojo").
2. In a terminal in this folder: `rojo serve`
3. In Studio: Plugins → Rojo → Connect (default `localhost:34872`)
4. **Farms are baked on disk** under `src/Workspace/Ranches/Ranch1..6` — they appear in Edit after sync (no manual empty Models).
5. Press Play — `MapBootstrap.Build` upgrades labels/slots; Carpet + AuraStage stay runtime-created.

## Notes
- Monetization GamePass IDs are placeholders in `Services/Monetization.lua` (Brad-only paste — see `docs/MARKETPLACE_IDS.md`).
- Overnight autonomy: `docs/OVERNIGHT_AUTONOMY.md`.
- Steal targeting needs a client prompt later; use remotes from the HUD for buy/deposit/rebirth/lock.
