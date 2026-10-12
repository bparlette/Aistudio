# Clout Ranch — Standing Playtest Protocol (RanchPlay)

Test against design docs only. Pass/fail + evidence. No invented features.

Sources of truth: `GDD-one-pager.md`, `mvp-systems.md`, `MASTER_VISION.md`, `USP.md`, `RetentionGDD.md`, `REVENUE_AND_RETENTION.md`, `MonetizationCatalog.md`.

---

## 0. Session setup (before every Studio Play)

- [ ] Fresh alt (no VIP / 2x / Slap+ / Extra Slot / BP) unless the case needs paid
- [ ] Note build: Rojo sync time + which services loaded (Onboarding, Daily, Steal, Aura, Carpet, Economy, Monetization)
- [ ] Record: first-cash timestamp, first-steal attempt, first Flex bell, first paywall prompt
- [ ] Fail any case that crashes, softlocks, or desyncs ranch ownership

**Verdict language:** PASS / FAIL / LEAK / SMELL (paywall) / BLOCKER

---

## 1. First 10 minutes funnel (D0)

Goal: instant read in ~10s; buy → earn → steal → Flex → rebirth path clear without a guide.

| Minute | Expected beat | Fail if |
|--------|---------------|---------|
| 0:00–0:10 | Understand: pets print cash, unlocked ranches stealable, Flex is a show | Confused freeze >15s; no tip / Onboarding |
| 0:10–1:00 | Reach Carpet, see stock + price, afford or clear path to first pet | Softlock under first price; shop empty/broken |
| 1:00–3:00 | Slot pet → visible income tick → cash HUD updates | Idle silent (no $/sec feel); HUD wrong |
| 3:00–6:00 | First lock awareness + at least one steal attempt (own or rival) | Can't find unlock state; steal never teaches |
| 6:00–8:00 | Aura Flex bell → stage → emote/showcase → vote | Miss Flex entirely; no vote UX; round dead |
| 8:00–10:00 | Know next dopamine (streak/quest banner OR Carpet rotate OR rebirth tease) | Session feels finished with nowhere to go |

**Funnel KPIs (playtest proxies):** time-to-first-pet, time-to-first-income, time-to-first-steal-attempt, saw-Flex-yes/no, quit-reason if early exit.

---

## 2. Fairness (VIP / steal / carpet)

Pillar: VIP buys **time & comfort**, never “you can’t play.” Steal vs VIP target ≥30% contested success.

| Case | Method | Pass bar |
|------|--------|----------|
| F2P vs VIP lock | Alt A VIP, Alt B F2P; wait lock expiry; attempt steal | Steal remains possible after VIP lock; not unstealable |
| Carry + slap | Steal carry slows; owner slap force-drops | Drop works; no godmode VIP slap gap that nullifies all steals |
| Soft steal protection | Steal same ranch twice <15s | Second steal blocked briefly, then opens again |
| Newbie first lock | New plot lock = 45s free (doc) | Newbies not farmed in first 45s |
| Carpet soft pity | Long Common drought as F2P | Rare+ eventually appears; no Robux-only Secret path |
| Luck boost | Paid luck timed + stack-capped | Expires; F2P still rolls without it |
| Power gate check | Attempt steal / rebirth / Flex vote without passes | Never paywalled |

**Smell flags:** VIP lock so long contested steals ≈0%; Extra Slot mandatory for competitive CPS; limited Secret = only income meta; Slap+ makes defense free win.

---

## 3. Addiction ethics (daily ritual without dark patterns)

Allowed: streak, 3 quests, featured/weekly FOMO with **honest timers**, return bonus window, BP prestige (not power-lock).

Forbidden (auto FAIL): doomscroll-for-power feeds; fake scarcity; hard reset wipe on miss; paywall to keep streak; infinite admin spam as product.

| Case | Pass |
|------|------|
| Daily claim | One claim/day key; escalating 1..7 then soft cycle; grace for 1 miss |
| Return bonus | Claim arms ~1.5× ~10 min; feels juicy then normal — not infinite grind bait |
| Featured / limited | Timer visible (“Gone Sunday UTC”); no fake stock |
| Battle Pass | Free track claimable; miss day = prestige lag, not combat/income lockout |
| Session length | Avg feel 10–20 min exit with wanting tomorrow — not hostage loops |

---

## 4. Social + clip bait

| Case | Pass |
|------|------|
| Aura Flex rhythm | Bell ~every 3 min; 20s flex; votes; podium VFX |
| Steal cam / killfeed | YEETED-style readable names; clip-worthy camera if present |
| Party / showcase | Friends readable; ranch showcase doesn't break steal rules |
| Trend banner | Weekly featured visible; original pets only — no licensed IP names/marks |

**IP FAIL:** Italian-brainrot character names, NFL/49ers marks, doll IP, romance-scam patterns.

---

## 5. Ship gate (vertical slice)

Must PASS before soft-launch gate:

1. 8-player / 6 ranch plot bootstrap stable
2. Full loop once: buy → earn → steal deposit → Flex podium → rebirth once
3. Fair VIP contested steal ≥30% in scripted dual-client tests
4. F2P can complete loop with zero purchases
5. No crash/desync on steal transfer or Flex vote
6. Monetization prompts: only edge/QoL/cosmetics — never on steal/rebirth/vote
7. Zero banned patterns / IP in catalog strings
8. Onboarding + Daily claim remotes fire; HUD toasts readable on mobile-ish aspect

**BLOCKER = any of 2, 3, 4, 5, 6 failing.**

---

## Reporting template (every run)

```
Build:
Role: F2P | VIP | mixed
Funnel: t_pet / t_income / t_steal / Flex YN / early quit?
Fairness: contested steal rate notes
Ethics: streak/FOMO/BP smells
Social: Flex/killfeed/party notes
Bugs (sev): BLOCKER > High > Med > Low
Ship gate: PASS / FAIL
Top 3 next verifies:
```
