# Clout Ranch — Social Systems

Massively multiplayer fun without creepy surveillance. Crews huddle for vibe bonuses; steals go viral on the killfeed; flex stays fair.

## Party / Clout Crew (`PartyService`)

| Rule | Detail |
|------|--------|
| Size | Max **4** players |
| Invite | `PartyInvite` with **userId** or **fuzzy username / DisplayName** (exact → prefix → contains) |
| Accept / Leave | `PartyAccept`, `PartyLeave` |
| Sync | Server → client `PartySync` payload `{ party, pendingFrom, cashBonusActive }` |
| Lock assist | **+5s** ranch lock if any party mate is within ~42 studs when you lock |
| Cash huddle | **+10%** income when **2+** crew members are nearby each other |
| Not included | No friend-list scraping, no forced follows, no vote boosting |

UI: `HudModules/PartyPanel.lua` — invite box + ACCEPT/LEAVE.

## Killfeed (`KillfeedService`)

- Folder `ReplicatedStorage.CloutFeed` — rolling `StringValue` lines (late-join seed).
- Remote `FeedEvent` — live push to all clients.
- Tone examples: `brad yeeted Sam's Aura Gator`, slap recovers, Aura podium.
- UI: `HudModules/Killfeed.lua` — top-right scrolling lines.

Hooked from steals / slaps / deposits / Aura podium when Bootstrap wires it.

## DuoFlex (`FlexEmoteService`) — cosmetic only

During **Aura Flex**, nearby party pairs trigger a **DuoFlex** pose sync:

- `ReplicatedStorage.Social.DuoFlex` BindableEvent (server systems / VFX)
- `Remotes.DuoFlex` RemoteEvent (clients)

**Hard rule:** Flex stays fair. DuoFlex does **not** change vote weight, Aura gain, or podium ranking. Payload always includes `cosmeticOnly = true`.

## Ranch showcase (`ShowcaseService`)

Pin **one** pet from your ranch slots to a billboard above your plot:

- Remote `PinShowcase` — `FireServer(slotIndex)` or `FireServer(petId)`
- Billboard shows pet name + rarity color + owner DisplayName
- Pure flex — no income or steal protection change

## Trade Flex Plaza (design stub)

See `docs/TradeFlexPlaza.md`. Future social hub for pet showcases and fair trade booths — not shipped in MVP code beyond this stub + ShowcaseService.

## Bootstrap wiring

```lua
local PartyService = tryRequire("PartyService")
local KillfeedService = tryRequire("KillfeedService")
local FlexEmoteService = tryRequire("FlexEmoteService")
local ShowcaseService = tryRequire("ShowcaseService")
```

Remotes ensured: `PartyInvite`, `PartyAccept`, `PartyLeave`, `PartySync`, `FeedEvent`, `DuoFlex`, `PinShowcase`.

## Safety / vibe

Original, fun, not creepy: opt-in invites only, no location sharing outside gameplay proximity checks, no private chat logging, killfeed is public slapstick not doxxing.
