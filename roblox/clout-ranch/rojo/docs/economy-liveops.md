# Clout Ranch — Monetization + Live-Ops Design Doc

**Game:** Clout Ranch (Roblox steal / idle collect, Brainrot-style loop)  
**Modes:** Aura Flex rounds + weekly original clout pets  
**Goal:** Top-earner revenue **without** pure P2W feel; maximize D1 / D7 retention  
**Constraints:** Original creatures only (no Italian-brainrot named IP, no NFL marks); no gen-AI doomscroll-for-power; competitive edge sells; free players must still have fun  
**Owner:** Brad Parlette  
**Doc version:** 1.0 · 2026-09-04

---

## Design principles (non-negotiable)

1. **Cash is the grind currency.** Robux buys *time, cosmetics, convenience, and limited FOMO*—never exclusive combat win conditions.
2. **VIP lock time is OK.** Paying for longer safe-claim / ranch protection is proven and fair if steal skill still beats AFK whales.
3. **Free players peak fun at ~70–80% of paid power band** in Aura Flex; whales buy *frequency and flair*, not auto-wins.
4. **Original IP only.** Clout pets, auras, ranch themes are first-party. No licensed marks, no gen-AI scroll mechanics.
5. **First spend should feel smart, not desperate.** Soft gate at minute 4–7 with a high-value starter pack.

---

## 1. Soft currency (Cash) — sinks & faucets

### 1.1 Naming & units

| Currency | Type | Source |
|----------|------|--------|
| **Cash** | Soft | Idle ranch, steals, quests, events |
| **Clout Tokens** | Soft (season) | Battle pass, weekly challenges |
| **Robux** | Hard | Purchases only |

Cash display: whole numbers with K/M/B suffixes. Cap inventory Cash at **9.99B** (soft cap; excess converts 100:1 to Clout Tokens up to weekly token cap).

### 1.2 Faucets (Cash/hour equivalent)

Tune for a **median active session length of 18–22 min**, 1.8 sessions/day early, 2.4 mid.

| Stage | Definition | Passive ranch Cash/hr | Active steal Cash/hr (skilled) | Daily quest Cash | Login / streak Cash/day | Total expected Cash/day (active free) |
|-------|------------|----------------------|--------------------------------|------------------|-------------------------|--------------------------------------|
| **Early** | Level 1–15, days 0–3 | 8,000–15,000 | 25,000–45,000 | 40,000 | 15,000 → 45,000 (day 7 streak) | **90,000–180,000** |
| **Mid** | Level 16–40, days 4–21 | 45,000–90,000 | 120,000–220,000 | 120,000 | 60,000 (streak max) | **400,000–700,000** |
| **Late** | Level 41+, day 22+ | 180,000–350,000 | 400,000–800,000 | 250,000 | 100,000 | **1.2M–2.5M** |

**Steal multipliers (skill-facing):**
- Clean steal (no detection): **×1.5** Cash from victim’s claimed stack
- Counter-steal (steal back within 30s): **×2.0** + 5 Clout Tokens
- Aura Flex round win (top 3): **50k / 30k / 15k** early; scale ×3 mid, ×8 late

**Idle formula (ranch):**  
`Cash/min = BaseYield × PetPower × AuraBonus × EventMult × IdleMult`  
- BaseYield early: 150 Cash/min → mid 900 → late 3,500  
- PetPower: 1.0–4.5 (free path reaches ~3.2; paid cosmetics don’t raise power)  
- AuraBonus: 1.0–1.35 (Aura Flex earned + seasonal auras; paid auras max +0.05 cosmetic-adjacent, **no combat stats**)  
- IdleMult: from 2×Cash (×2 ranch idle) + rebirth/other non-VIP mults — **VIP contributes 0% idle**  
- VIP Lock: timer-only (45s F2P / 120s VIP); protects the yield *window*, does **not** multiply Cash

### 1.3 Sinks (Cash costs)

| Sink | Early | Mid | Late | Notes |
|------|-------|-----|------|-------|
| Unlock next ranch plot | 25k / 75k / 200k | 500k / 1.2M / 3M | 8M / 20M / 50M | 3 tiers per stage |
| Upgrade pet power (T1→T2→T3) | 40k / 120k / 350k | 800k / 2M / 5M | 12M / 30M / 75M | Free path; time-gated by materials |
| Aura Flex entry fee | 5,000 | 25,000 | 100,000 | Refunded if match cancel |
| Reroll weekly pet egg (1 free/week) | 50,000 | 250,000 | 1,000,000 | After free egg |
| Ranch decoration (cosmetic) | 10k–80k | 100k–800k | 1M–15M | Pure vanity sink |
| Steal cooldown skip (soft) | 8,000 | 40,000 | 150,000 | Or wait 90s free |
| Name ranch / title plate | 100,000 | 500,000 | 2,000,000 | Vanity |
| Season shop rotation item | — | 200k–1.5M | 2M–10M | Cosmetics + 1 convenience item |

**Target sink rate:** Spend **65–80%** of daily Cash on upgrades/plots; leave **20–35%** for vanity + Flex entry so wallet feels alive.

**Anti-inflation:** Every season (see §4), raise late sinks **+12–18%** and late faucets **+8–10%** so net pressure stays slightly sink-heavy. Never raise early faucets more than +5%/season.

### 1.4 Soft-currency balance rules

- Free player reaches **ranch plot 6** by day 3 without purchase (scripted funnel).
- Paid player with Starter Pack reaches plot 6 ~**40% faster**, not exclusive access.
- Steal success rate target: free skilled **42–48%** vs free AFK; whale VIP lock reduces *exposure time* but skilled free still steals **≥30%** of attempts vs locked ranch (lock = timer, not immunity).

---

## 2. Robux products

### 2.1 What NEVER goes behind a paywall

| Never paid-only | Why |
|-----------------|-----|
| Core steal / Aura Flex participation | Skill loop must stay open |
| Weekly original clout pet **species** (at least 1 free acquisition path) | Retention + fairness |
| Combat stats on cosmetics | Avoids P2W perception |
| Chat / social features | Platform + retention |
| Ability to win Aura Flex rounds | Whales buy cosmetics / queues, not trophies |
| Gen-AI or doomscroll power loops | Roblox ToS / ban risk |

### 2.2 Gamepasses (permanent)

| SKU ID | Name | Perk list | Suggested Robux | Notes |
|--------|------|-----------|-----------------|-------|
| GP-VIP | **VIP Ranch** | 0% idle (lock-only) Cash from ranch idle; VIP badge; exclusive VIP ranch theme; **VIP Lock** base duration **120s** (free lock = 45s); +1 daily quest slot | **799** | Core whale + mid spender. Lock is timer-only. |
| GP-X2Cash | **2× Cash** | ×2 Cash from *passive ranch only* (not steal PvP payouts) | **449** | VIP is 0% idle — idle stack is ×2 from this pass alone (+ other non-VIP mults); steal remains skill-facing |
| GP-AutoCollect | **Auto-Collect** | Auto-pickup ranch Cash within plot radius every 8s | **249** | Convenience; free players tap |
| GP-ExtraPet | **+1 Pet Slot** | Equip 4 pets instead of 3 | **349** | Power-adjacent but free can still field 3 strong originals |
| GP-FastTravel | **Ranch Hopper** | Instant travel between owned plots | **149** | QoL |
| GP-FlexQueue | **Flex Priority** | Priority matchmaking into Aura Flex; **does not** alter Elo or match rewards | **199** | Competitive edge = queue time, not power |

**Stacking rules:** VIP adds **lock only** (0% idle). 2×Cash alone = ×2 ranch idle (plus other non-VIP mults). Steal Cash never gets ×2 from gamepass. Extra pet slot: 4th pet power capped at **75%** of average of other three so free 3-pet builds stay competitive.

### 2.3 Dev products (consumables)

| SKU ID | Name | Perk | Suggested Robux | Soft alt |
|--------|------|------|-----------------|----------|
| DP-Cash-S | Cash Bundle S | **150,000** Cash | **49** | ~1 day early grind |
| DP-Cash-M | Cash Bundle M | **900,000** Cash | **149** | ~1.5 days mid |
| DP-Cash-L | Cash Bundle L | **5,000,000** Cash | **399** | Late convenience |
| DP-Cash-XL | Cash Bundle XL | **25,000,000** Cash | **999** | Whale filler; soft-cap awareness |
| DP-Egg-1 | Clout Egg | 1 weekly-pool pet egg (current week species) | **99** | 1 free egg/week via play |
| DP-Egg-3 | Clout Egg ×3 | 3 eggs | **249** | Bundle discount ~16% |
| DP-Lock-Refill | VIP Lock Refill | +3 lock charges (120s each if VIP; 60s if not) | **79** | Free: 3 locks/day from play |
| DP-SkipCD | Steal CD Skip ×5 | Skip 90s steal cooldown 5 times | **49** | Cash sink alt exists |
| DP-FlexTicket | Aura Flex Ticket ×3 | Waive entry fee ×3 | **39** | Cash entry always available |
| DP-Reroll | Egg Reroll Token | Reroll traits on 1 egg hatch (not species) | **59** | Trait FOMO, not species lockout |
| DP-Starter | **Starter Pack** (one-time) | See §6 | **175** | Highest LTV lever |
| DP-Comeback | Comeback Pack (returning 7d+) | 500k Cash + 1 egg + 1 lock refill | **99** | D7+ re-engagement |

**Cash bundle efficiency (Cash per Robux):** S ≈ 3,061 · M ≈ 6,040 · L ≈ 12,531 · XL ≈ 25,025. Intentionally steeper for whales; early S is *worse* value so players prefer Starter Pack / VIP.

### 2.4 Limiteds (timed / stock)

| SKU ID | Name | Window | Perk | Robux | Stock |
|--------|------|--------|------|-------|-------|
| LM-Aura-Week | Weekly Flex Aura (cosmetic) | Fri 12:00 ET → Mon 00:00 ET | Unique trail + emote; **0 combat stats** | **349** | Unlimited during window |
| LM-Pet-Skin | Alt skin for current weekly pet | Week of pet drop | Skin only | **299** | Unlimited |
| LM-Ranch-UGC | Limited ranch prop (UGC-ready) | Season midpoint 72h | Vanity prop | **499** | **2,500** copies |
| LM-Title | Season title plate | Last 5 days of season | Title + name color | **199** | Unlimited |

**FOMO rules (anti-scam):** Timers accurate to the second; no fake “1 left”; stocked limiteds show remaining count; never extend a “ending soon” sale more than once, and only with clear “extended 24h” banner.

### 2.5 Battle pass (season)

| Track | Price | Contents summary |
|-------|-------|------------------|
| Free | 0 | 30 levels; Cash, 2 weekly-pool eggs, cosmetics (common/rare), 1 Aura Flex emote |
| Premium | **799 Robux** | All free + exclusive aura set, exclusive ranch theme, **4** premium eggs, VIP Lock charges ×10, title, 2× daily quest XP for season |
| Premium+ Bundle | **1,199 Robux** | Premium + **instant +10 levels** + exclusive pet **skin** (not exclusive species) |

**XP:** Level 1→30 = **45,000** season XP. Daily play cap ~2,200 XP so free dedicated players finish ~day 28–32 of a 5-week season; Premium 2× quest XP finishes ~day 18–22.

---

## 3. Daily / weekly live-ops calendar

All times **America/New_York (ET)**.

### 3.1 Daily login & streak

| Day in streak | Reward |
|---------------|--------|
| 1 | 15,000 Cash |
| 2 | 20,000 Cash |
| 3 | 1 Steal CD Skip |
| 4 | 35,000 Cash |
| 5 | 1 Lock charge |
| 6 | 45,000 Cash |
| 7 | **Weekly Clout Egg (guaranteed current species)** + 100,000 Cash |
| Miss 1 day | Streak pauses once (grace); miss 2nd = reset to day 1 |

**Login UI:** Claim within 10s of join; don’t force modal before first ranch collect (retention).

### 3.2 Daily quests (refresh 00:00 ET)

Player gets **3 free** (+1 if VIP). Examples with targets:

| Quest | Early target | Mid | Late | Reward |
|-------|--------------|-----|------|--------|
| Collect ranch Cash | 50k | 300k | 1.5M | 40k / 120k / 250k Cash |
| Successful steals | 3 | 5 | 8 | Same Cash band + 15 Clout Tokens |
| Play Aura Flex rounds | 2 | 3 | 4 | Flex Ticket ×1 or Cash |
| Hatch or upgrade pet | 1 | 1 | 1 | Materials + Cash |
| Visit 3 other ranches | 3 | 3 | 3 | Social XP + Cash |

**Complete-all daily bonus:** +50% of sum of quest Cash + 25 Clout Tokens.

### 3.3 Weekly structure

| Day | Live-ops beat |
|-----|----------------|
| **Mon** | New weekly original clout pet species drops (free egg path + Robux eggs). Season XP week starts. |
| **Tue** | “Steal Surge” 18:00–21:00 ET — steal Cash ×1.5, CD −20% |
| **Wed** | Midweek Aura Flex cup (bracket cosmetic title for top 100) |
| **Thu** | Double daily quest Cash 12:00–23:59 |
| **Fri** | Weekend kickoff — Limited Flex Aura on sale; Flex entry Cash −50% |
| **Sat** | **Ranch Raid Weekend** — server events every 2h; boss ranch NPC drop materials |
| **Sun** | Streak push messaging; Premium pass spotlight; season XP ×1.25 16:00–22:00 |

### 3.4 Weekend events (recurring)

| Event | Cadence | Free value | Paid hook |
|-------|---------|------------|-----------|
| Ranch Raid | Every weekend | Materials, Cash, 1 egg fragment (3 = egg) | Egg bundles, lock refills |
| Aura Flex Marathon | Alt weekends | Extra Flex tickets via play | Flex Priority pass, tickets |
| Skin Spotlight | 1 weekend/month | Free common skin via quest | Limited skin 299 R$ |

---

## 4. Season structure (5 weeks default; 4–6 OK)

**Recommended:** **5 weeks** (35 days). Align weekly pets = 5 original species/season.

### 4.1 Season beat sheet

| Week | Theme beat | Free track highlight | Premium highlight | FOMO (ethical) |
|------|------------|----------------------|-------------------|----------------|
| 1 | Launch + tutorial polish | Levels 1–6 Cash/eggs | Exclusive aura T1 | “Season 1 aura only craftable this season” (returns as non-craftable shop later at 2× price) |
| 2 | Pet focus | Egg ×1 free track | Premium eggs ×2 | Weekly pet skin limited |
| 3 | Mid-season event | Ranch Raid unique material | Ranch theme unlock | UGC prop limited stock 2,500 |
| 4 | Competitive | Flex emote free | Title plate | Flex Marathon leaderboard skins (top 500 earn free variant) |
| 5 | Finale | Catch-up XP ×1.5 on free track days 30–35 | Premium+ upsell | Clear countdown; no fake scarcity |

### 4.2 Track rewards (compressed)

| Level | Free | Premium |
|-------|------|---------|
| 1 | 25k Cash | Season badge |
| 5 | Common ranch prop | Exclusive prop |
| 10 | Clout Egg ×1 | Egg ×1 + Lock ×3 |
| 15 | Aura Flex emote | Emote set |
| 20 | Rare skin (current pet) | Legendary aura T2 |
| 25 | 500k Cash (scales by season) | Ranch theme |
| 30 | Egg ×1 + title (common) | Exclusive title + Egg ×2 + skin |

### 4.3 FOMO without scams

- All timers server-authoritative and visible.
- “Returning next season as legacy shop” labeled on exclusive craft auras.
- No lootbox odds below **documented** rates; eggs show species pool (weekly pool is known; traits use published weights).
- Trait weights example: Common 60% / Rare 28% / Epic 10% / Legendary 2%. Legendary **does not** gate win rate alone (+pet power within published caps).
- No pay-to-skip for *required* story; only convenience.

---

## 5. Anti-whale fairness

### 5.1 Allowed paid advantages

| Advantage | Cap | Why OK |
|-----------|-----|--------|
| VIP Lock duration | 120s VIP vs 45s free; max 6 charges/hour from mix of earn+buy | Time window, not immunity |
| Ranch Cash multipliers | 2×Cash → ×2 idle (VIP = 0% idle / lock-only) | Idle only |
| Queue priority | Flex Priority | Time, not Elo |
| Extra pet slot | 4th at 75% power contribution | Soft power, not hard lockout |
| Cosmetic flex | Unlimited vanity | Status sells |

### 5.2 What skill still decides

- **Steal minigame:** timing + pathing + counter-steal window (30s). Lock only delays start of vulnerable state.
- **Aura Flex:** movement, aura timing, reading opponents. Matchmaking by **Flex Rating** (hidden MMR); gamepasses do not add MMR.
- **Pet power ceiling:** Free path reaches **~85%** of max PetPower by end of season via play; paid reaches 100% ~2 weeks earlier.
- **Anti-snipe:** After lock expires, **8s grace** where owner gets movement buff (not damage) so AFK whales aren’t free food—but skilled stealers still land.

### 5.3 Whale soft brakes

- Cash XL purchases: max **3 / day**.
- Lock refills: max **10 charges owned**.
- Steal CD skips: max **20 owned**.
- Public leaderboards: separate **“Unspent Robux flex”** cosmetic board vs **Flex Rating** skill board—never merge.

---

## 6. First 10-minute funnel

| Time | Player action | System goal | Spend opportunity |
|------|---------------|-------------|-------------------|
| 0:00–0:45 | Load → name ranch → meet mascot **Clout Pup** (original) | Identity + delight | None |
| 0:45–2:00 | Collect first Cash piles; unlock Pet Slot 1; hatch **tutorial pet** (guaranteed) | Dopamine of collect | None |
| 2:00–3:30 | Place pet on plot; see Cash/min tick; guided steal on **NPC ranch** (100% success) | Teach steal safely | None |
| 3:30–5:00 | First PvP steal attempt on low-level real player; win or lose both grant tutorial Cash | Social hook | Soft: “VIP Lock protects your pile” tooltip (no modal) |
| 5:00–6:30 | Enter **Aura Flex practice round** (bots); earn badge | Competitive fantasy | None |
| 6:30–7:30 | Daily quest “Collect 50k” almost done; plot upgrade affordance | Sink tease | **Starter Pack modal** (one-time): 175 R$ — 500k Cash + VIP Lock ×3 + Clout Egg ×1 + 2×Cash 30-min trial. Dismissible; don’t re-show until min 20 if declined |
| 7:30–9:00 | Upgrade plot or pet with earned Cash; second steal | Agency | If pack declined: offer **Cash Bundle S** only after failed upgrade affordance (49 R$) |
| 9:00–10:00 | Claim day-1 login; set streak; show weekly pet teaser | Retention hook | Battle pass banner (non-blocking): “Season ends in Xd” |

**Conversion targets for this funnel:** see §7. Starter Pack is the **only** hard CTA before minute 10.

---

## 7. KPIs and target conversion rates

### 7.1 Retention

| Metric | Target (soft launch) | Target (scaled) |
|--------|----------------------|-----------------|
| D1 retention | **40%** | **45%** |
| D7 retention | **15%** | **18%** |
| D30 retention | **6%** | **8%** |
| Day-0 playtime median | **18 min** | **22 min** |
| Sessions / DAU | **1.8** | **2.2** |

### 7.2 Monetization

| Metric | Target |
|--------|--------|
| Payer conversion (R$ spenders / DAU) | **4.5–6%** |
| Starter Pack attach (of new users who reach min 6) | **8–12%** |
| Starter Pack → VIP within 7d | **25%** of Starter buyers |
| Battle pass attach (of WAU in season) | **3–5%** |
| ARPPU (28-day) | **$18–28** (≈ 1,800–2,800 R$ equiv. depending on regional) |
| ARPDAU | **$0.35–0.55** early live; **$0.70+** with mature live-ops |
| Whale share (top 1% payers of revenue) | **≤45%** (healthy); investigate if >55% |
| Cash sink rate (Cash spent / Cash earned) | **0.70–0.85** |

### 7.3 Fairness / health

| Metric | Target |
|--------|--------|
| Free player Aura Flex winrate vs paid (same Flex Rating bucket) | **47–53%** (near parity) |
| Steal success free→VIP ranch | **≥30%** for players with >50 steals |
| Support tickets “P2W” / 1k DAU / week | **<3** |
| Refund rate on Starter Pack | **<2%** |

### 7.4 Instrumentation (must ship with economy)

- Funnel steps 0–10 min with drop-off %.
- SKU purchase events with `sku_id`, `price_robux`, `session_minute`, `player_level`.
- Flex Rating + paywall flags on match end (for fairness audits).
- Economy ledger: faucet_id / sink_id per Cash grant/spend.

---

## 8. Weekly original clout pets (ops note)

- **1 new original species per week**, designed in-house; names/themes avoid third-party IP.
- Free: streak day 7 egg **or** 3 raid fragments **or** battle pass free egg.
- Paid: DP eggs accelerate collection / traits; **species never Robux-exclusive**.
- Traited legendaries: power within global cap; flex is visual + slight yield, not Flex combat dominance.

---

## 9. Launch checklist (economy)

- [ ] Cash faucet/sink spreadsheet locked for Early numbers  
- [ ] Starter Pack one-time flag server-side  
- [ ] VIP Lock timer desync tests  
- [ ] Trait odds published in-game  
- [ ] Season 1 pass rewards table in CMS  
- [ ] KPI dashboard (D1/D7, conversion, ARPDAU, fairness winrate)  
- [ ] Legal/IP pass on all pet names & NFL/brainrot lookalikes  

---

*End of design doc. Companion: `monetization-sku-table.md`.*
