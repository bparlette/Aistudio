# Clout Ranch — 15-minute Studio playtest script (Brad)

**Setup:** Rojo synced. Start **Local Server, 2 players**. You = Player1 (F2P). Player2 window = victim / VIP later. Phone emulator on Player1 once.

Timer = wall clock from first character load. Check boxes as you go. Failures → sticky note with timestamp.

---

## Minute 0:00–1:00 — Boot + understand

1. Press Play (2-player). Watch **Server** Output for `[CloutRanch] BOOT OK`.
2. Confirm Explorer: `Workspace.Ranches` = Ranch1..6, `Carpet`, `AuraStage`.
3. Confirm `ReplicatedStorage.Remotes` + `CloutState` (`Phase`, `EndsAt`, `ServerTime`).
4. Out loud in ≤10s: “Pets print cash; unlocked ranches get stolen; Flex is a show.”
5. Note your plot + newbie lock (~45s).

- [ ] Boot OK
- [ ] 6 ranches
- [ ] Loop understood

---

## Minute 1:00–3:00 — First pet + income

6. Open Carpet HUD. Wait ≤5s for stock (or invoke RF in command bar if empty).
7. Buy cheapest pet with cash (starter grant / wait ticks if broke).
8. Confirm pet in your ranch slot + rarity color.
9. Watch cash counter climb ≥5 seconds.
10. Tap **LOCK**. Confirm lock engages (~20s non-VIP).

- [ ] First pet
- [ ] Income ticks
- [ ] Lock works

---

## Minute 3:00–6:00 — Steal loop (2-player)

11. On **Player2**: buy a pet, let lock expire (or skip newbie by waiting).
12. On **Player1**: stand near Player2 plot → **STEAL** (StealClosest).
13. Confirm: carry slow, killfeed line, soft toast.
14. Sprint home → **DEPOSIT**. Pet on your ranch; Player2 slot empty.
15. Steal again within 15s on same victim → must fail (“Recently stolen”).
16. Player2 steals from you; you **Slap** while they carry → drop / return rules.

- [ ] Steal → deposit
- [ ] Soft protect
- [ ] Slap works

---

## Minute 6:00–9:00 — Fairness + VIP spot-check

17. Give Player2 VIP (Studio: grant gamepass / Monetization test hook / attribute you use).
18. Player2 LOCK → measure duration ≈ **30s**.
19. When it expires, Player1 completes ≥1 steal start. Note success/fail.
20. Confirm Player1 never needed Robux for: buy, steal, deposit, lock, slap.
21. Command bar (Player1):  
    `print(game.ReplicatedStorage.Remotes.GetCarpetStock:InvokeServer())`  
    Expect table of up to 4 `{id,name,rarity,price}`.

- [ ] VIP lock longer, still stealable
- [ ] Core verbs free
- [ ] GetCarpetStock OK

---

## Minute 9:00–12:00 — Daily, quests, trend, Feedback

22. Tap **Daily claim**. Toast tone daily; `CloutStats.DailyStreak` updates.
23. Claim again → reject.
24. Progress/claim a quest if UI live (steal/lock/deposit).
25. Check trend banner copy (or Season/Trend stub). No IP names.
26. Trigger Feedback toast path (buy/steal/daily) — payload must not nil-index HUD.
27. Server Output: no Heartbeat error spam.

- [ ] Daily once/day
- [ ] Streak replicated
- [ ] Feedback toasts OK
- [ ] Trend/IP clean

---

## Minute 12:00–15:00 — Aura Flex + mobile + ship call

28. Wait for Flex (or advance Aura phase in Studio if you have a debug). Else note idle countdown using:  
    `local s=game.ReplicatedStorage.CloutState; print(s.Phase.Value, s.EndsAt.Value - workspace:GetServerTimeNow())`
29. On flex: vote once on other player; second vote fails.
30. Podium ~8s: readable winners; clip/juice if Secret/podium wired.
31. Switch Player1 to **phone resolution**. Retap ActionBar (STEAL/LOCK/DEPOSIT). Cash + carpet must stay readable.
32. Ship call from `PLAYTEST_CHECKLIST.md` gate:

| Call | When |
|------|------|
| **NO SHIP** | Funnel break, paywalled verb, Remotes/RF/EndsAt/DailyStreak broken, IP risk |
| **SOFT ONLY** | Must clear; Should bugs listed |
| **PUBLIC OK** | Must-fix all green |

- [ ] EndsAt countdown sane
- [ ] Vote once
- [ ] Mobile HUD OK
- [ ] Final call: _______________

---

## End — paste into notes

```
Date:
Build/commit:
Funnel 10m: PASS/FAIL
Fairness: PASS/FAIL
Top bugs found:
Ship call: NO SHIP / SOFT / PUBLIC
```
