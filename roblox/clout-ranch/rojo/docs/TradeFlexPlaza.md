# Trade Flex Plaza — design stub

**Status:** stub / not in MVP loop  
**Goal:** A social hub where players show off pinned pets, queue drip, and eventually trade — without pay-to-win leverage.

## Space

- Central plaza between ranch ring and Aura Flex stage.
- Soft spawn pads + camera-friendly backdrop for clips.
- Billboard pylons that mirror `ShowcaseService` pins (read-only replicas).

## Loops (future)

1. **Flex booths** — stand on a pad → auto-play idle DuoFlex if crew is present (cosmetic).
2. **Trade kiosks** — propose pet ↔ pet or pet ↔ cash with confirm UI; server validates ownership + soft-protect timers.
3. **Spectator rail** — watch steals on nearby unlocked ranches with killfeed piped to plaza screens.
4. **Season drop teaser** — rotating mannequin of next week’s Secret (visual only).

## Explicit non-goals

- No romance / dating sim mechanics.
- No forced social graph or contact scraping.
- No trading of Robux or real money.
- No aura vote boosting from plaza presence.

## MVP bridge

Ship `ShowcaseService` pin billboards on ranches first. Plaza can later aggregate the same pin data into a gallery wall.
