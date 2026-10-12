# Clout Ranch — 2P Contested Steal (FAST checklist)

**Goal:** Brad runs this in ≤8 minutes after Stop→Play. RanchPlay scores PASS/FAIL from your notes.

**Setup:** Rojo connected → **Stop → Play** → Test → **Clients and Players** → **Start** Local Server **2 Players**.

Canon: F2P lock **45s** · VIP lock **120s** · VIP = lock+badge only (no idle mult) · soft protect **15s**.

---

## A) Mash LOCK (30s) — Player1

1. Claim ranch → tap **LOCK** once. Confirm toast / vault sealed.
2. Mash LOCK 5× in 2s.
3. **PASS** if second+ show SoftFeedback like `Already locked — Ns left` and lock timer does **not** reset to full.
4. **FAIL** if timer refreshes / stays forever sealed by mash.

Note time left on first refuse: ____ s

---

## B) F2P lock duration (≈50s) — Player1

1. Wait for unlock (or use a fresh lock after A expires).
2. LOCK once → stopwatch until unlockable / stealable again.
3. **PASS** ≈ **45s** (±3s). Note: ____ s

---

## C) Steal → deposit (2 min) — both clients

1. **P2:** buy a Common, wait newbie/lock expire (or wait out 45s).
2. **P1:** stand at P2 plot → **STEAL** → carry slow → home → **DEPOSIT** (button or DepositPad E).
3. **PASS** if pet on P1 ranch, P2 slot empty, toast/juice fires.
4. Steal same victim again within **15s** → must fail (“Recently stolen” / soft protect).
5. **PASS** soft protect. **FAIL** if second steal lands.

---

## D) VIP contested (≈3 min) — fairness closer

1. Grant P2 VIP (Studio attribute / Monetization test / own pass if wired).
2. **P2:** LOCK once → stopwatch. Expect ≈ **120s**. Note: ____ s
3. During lock: **P1** STEAL → must fail (`LOCKED — VIP vault` or sealed).
4. After expiry (do **not** mash LOCK on P2): **P1** completes ≥1 steal start (carry OK).
5. **PASS** if steal works after 120s. **FAIL** if still immune / P2 can mash-refresh.

Optional: confirm P2 cash income unchanged by VIP (no idle mult) — eyeball $/sec vs F2P peer.

---

## E) Quick dopamine sanity (optional, 30s)

After a deposit or steal, no need to wait 6m overnight — just confirm no crash. Soft Starter toast is session≥6m + dopamine (code-audited).

---

## Paste back to RanchPlay

```
Build/sync:
A mash LOCK: PASS/FAIL — note:
B F2P lock s:
C steal→deposit: PASS/FAIL
C soft 15s: PASS/FAIL
D VIP lock s:
D steal during VIP lock: blocked Y/N
D steal after expiry: PASS/FAIL
Ship Fairness live: PASS / FAIL
```
