# Clout Ranch — Monetization SKU Table

Quick reference for Robux products. Full design: `economy-liveops.md`.  
Prices in Robux. **Never paywalled:** steal/Flex play, weekly pet *species*, combat stats on cosmetics, Flex win eligibility.

## Gamepasses (permanent)

| SKU ID | Name | Robux | Perks |
|--------|------|------:|-------|
| GP-VIP | VIP Ranch | **799** | VIP badge + theme; Lock **120s** (no idle mult) (free 45s); +1 daily quest |
| GP-X2Cash | 2× Cash | **449** | ×2 *ranch idle* Cash only (not steal PvP) |
| GP-AutoCollect | Auto-Collect | **249** | Auto-pickup ranch Cash every 8s |
| GP-ExtraPet | +1 Pet Slot | **349** | 4th pet @ 75% power contribution |
| GP-FastTravel | Ranch Hopper | **149** | Instant travel between owned plots |
| GP-FlexQueue | Flex Priority | **199** | Priority Flex queue; no Elo/reward buff |

## Dev products (consumable)

| SKU ID | Name | Robux | Contents | Limits |
|--------|------|------:|----------|--------|
| DP-Starter | Starter Pack (1×) | **175** | 500k Cash + Lock×3 + Egg×1 + 2×Cash 30m trial | One-time |
| DP-Comeback | Comeback Pack | **99** | 500k Cash + Egg×1 + Lock refill×1 | Returning 7d+ |
| DP-Cash-S | Cash Bundle S | **49** | 150,000 Cash | — |
| DP-Cash-M | Cash Bundle M | **149** | 900,000 Cash | — |
| DP-Cash-L | Cash Bundle L | **399** | 5,000,000 Cash | — |
| DP-Cash-XL | Cash Bundle XL | **999** | 25,000,000 Cash | Max 3/day |
| DP-Egg-1 | Clout Egg | **99** | 1 current-week species egg | Species also free via play |
| DP-Egg-3 | Clout Egg ×3 | **249** | 3 eggs (~16% off) | — |
| DP-Lock-Refill | VIP Lock Refill | **79** | +3 lock charges (120s VIP / 60s non-VIP) | Max 10 charges owned |
| DP-SkipCD | Steal CD Skip ×5 | **49** | Skip 90s CD ×5 | Max 20 owned |
| DP-FlexTicket | Aura Flex Ticket ×3 | **39** | Waive entry fee ×3 | Cash entry always OK |
| DP-Reroll | Egg Reroll Token | **59** | Reroll traits (not species) | — |

## Limiteds (timed)

| SKU ID | Name | Robux | Window / stock |
|--------|------|------:|----------------|
| LM-Aura-Week | Weekly Flex Aura (cosmetic) | **349** | Fri 12:00–Mon 00:00 ET; unlimited in window |
| LM-Pet-Skin | Weekly pet alt skin | **299** | Pet drop week; unlimited |
| LM-Ranch-UGC | Limited ranch prop | **499** | Season midpoint 72h; **2,500** stock |
| LM-Title | Season title plate | **199** | Last 5 days of season; unlimited |

## Battle pass (per 5-week season)

| SKU ID | Name | Robux | Notes |
|--------|------|------:|-------|
| BP-Free | Free track | **0** | 30 levels; Cash, 2 eggs, cosmetics, 1 emote |
| BP-Premium | Premium track | **799** | Free + exclusive aura/theme, 4 eggs, Lock×10, title, 2× quest XP |
| BP-PremiumPlus | Premium+ Bundle | **1,199** | Premium + +10 levels + exclusive pet *skin* |

## Stacking & fairness (summary)

| Rule | Detail |
|------|--------|
| VIP + 2×Cash | VIP adds lock only; 2×Cash alone = ×2 idle |
| Steal Cash | Never multiplied by gamepass |
| Locks | Timer protection only; skilled steal success vs VIP target **≥30%** |
| Eggs | Species always earnable free; Robux = speed/traits |

## Primary conversion funnel SKUs

| Priority | SKU | Target attach |
|----------|-----|---------------|
| 1st spend (≤10 min) | DP-Starter @ 175 | 8–12% of players past min 6 |
| Mid spend | GP-VIP @ 799 | 25% of Starter buyers within 7d |
| Season | BP-Premium @ 799 | 3–5% of season WAU |
