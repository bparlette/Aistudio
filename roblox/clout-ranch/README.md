# Clout Ranch (Roblox)

Viral collect/steal tycoon with weekly original Clout Pets + Aura Flex rounds.

## Docs
- `GDD-one-pager.md` — design
- `mvp-systems.md` — MVP systems
- `src/` — Luau module stubs for Studio

## Studio setup (MVP)
1. Create a place (Baseplate is fine).
2. Add folders: `ReplicatedStorage/Modules`, `ServerScriptService/Services`.
3. Drop `PetCatalog.lua` into ReplicatedStorage/Modules as a ModuleScript named `PetCatalog`.
4. Drop `EconomyService.lua` into ServerScriptService/Services as a ModuleScript named `EconomyService`.
5. Next modules to add: RanchService, CarpetService, StealService, AuraService, RebirthService.

## Roblox rules we respect
- Original creatures only (no Italian-brainrot named IP, no NFL marks)
- No reward-for-doomscroll / continuous AI feed patterns

## Module map (Studio)

```
ReplicatedStorage/
  Modules/
    PetCatalog          <- src/PetCatalog.lua
  Remotes/              <- auto-created at runtime
ServerScriptService/
  Services/
    EconomyService
    RanchService
    CarpetService
    StealService
    AuraService
    RebirthService
    Monetization
  ServerBootstrap       <- src/ServerBootstrap.server.lua (Script)
Workspace/
  Ranches/
    Ranch1 .. Ranch6    <- empty Models/Folders for plots
```

Paste each `.lua` body into a ModuleScript of the same name (Bootstrap is a Script).
