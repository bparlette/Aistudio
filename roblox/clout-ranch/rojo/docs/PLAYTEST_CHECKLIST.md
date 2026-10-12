# Clout Ranch — PLAYTEST BIBLE
**Ruthless pass/fail. Checkbox = you actually ran it. No vibes-only green.**

Numbers from code: newbie lock **45s**, F2P lock **45s**, VIP lock **120s**, soft protect **15s**, Aura flex **20s** / podium **8s** / idle gap **180s**, Carpet RF every **~2s**, Feedback payload `{ message, tone }`.

Mark each item: `[ ]` untested · `[x]` PASS · `[F]` FAIL (log note) · `[N/A]` not in build

---

## 0) Preflight (Studio / 2+ clients)

- [ ] Play Solo then Local Server **2 players** (steal/flex need a victim)
- [ ] Output shows `[CloutRanch] BOOT OK` + remotes list including `Feedback` + `GetCarpetStock(RF)`
- [ ] `workspace.Ranches` has **Ranch1..Ranch6** after MapBootstrap (ring, PrimaryPart set)
- [ ] `workspace.Carpet` + `workspace.AuraStage` exist
- [ ] `ReplicatedStorage.Remotes` folder created at runtime (not missing)
- [ ] `ReplicatedStorage.CloutState` has `Phase`, `EndsAt`, `ServerTime`
- [ ] Player gets `CloutStats` with `Cash` (+ `DailyStreak` after sync)

**FAIL if:** BOOT never prints, Ranches empty, Remotes missing → stop; do not score funnel.

---

## 1) First 10 minutes — funnel pass/fail

Run cold join (new UserId / wipe DataStore stub). Timer starts at character spawn.

| Gate | Deadline | Pass criteria | Result |
|------|----------|---------------|--------|
| Understand loop | **≤10s** | Can say: pets print cash → unlocked ranches stealable → Flex is a show | [ ] |
| Claim / assigned ranch | **≤30s** | Plot owned; newbie lock ticking (~45s); tips or onboard step visible | [ ] |
| First pet | **≤90s** | Buy from Carpet → pet in ranch slot → rarity color readable | [ ] |
| First income | **≤120s** | Cash ticks up (≥1 $/tick visible); cash counter animates | [ ] |
| First lock **or** steal attempt | **≤4 min** | LOCK fires `RequestLock` **or** STEAL/`StealClosest` attempts enemy plot | [ ] |
| Steal complete (if attempted) | **≤6 min** | Carry slows → DEPOSIT at own ranch → ownership transferred | [ ] |
| HUD mobile-readable | whole 10m | Emulator phone **or** device: ActionBar taps ≥44px feel, no critical text clipped, cash + carpet readable | [ ] |

### Funnel hard fails (any one = FAIL section)
- [ ] Cannot buy first pet without Robux
- [ ] Cash never increases with pet parked
- [ ] Player cannot tell locked vs unlocked ranch
- [ ] Steal button no-ops with no toast / no console reason
- [ ] ActionBar / Daily / Carpet unusable at 812×375 (or phone)

### Funnel soft fails (note severity)
- [ ] Onboard tips fight trend banner / toasts (overlap)
- [ ] First carpet stock empty >5s after join
- [ ] Newbie lock ends with zero UI warning

**SECTION PASS:** all gates hit + zero hard fails.

---

## 2) Fairness — steal vs VIP; no hard paywall on core verbs

Core verbs (must work **with $0 Robux spent**): BuyCarpet, StealClosest/StealPet, DepositPet, SlapThief/SlapPetPrompt, RequestLock, VoteAura, DoRebirth (when cash enough), ClaimDaily.

### Contested VIP (lock is time, not immunity)
- [ ] Non-VIP lock ≈ **45s**; VIP lock ≈ **120s** — measure with stopwatch
- [ ] After VIP lock expires, F2P can steal successfully (≥1 completed steal in session)
- [ ] Vision bar: **≥30%** of timed attempts against a VIP ranch that *just unlocked* succeed (steal start, not necessarily deposit) — sample **n≥10**
- [ ] Soft protect: second steal on same victim within **15s** rejected with clear feedback
- [ ] Carry slow applies; owner slap forces drop / pet returns rules match design
- [ ] Newbie 45s protect cannot be stolen through

### Paywall audit (FAIL if any blocked for F2P)
- [ ] Steal — free
- [ ] Deposit — free
- [ ] Lock — free (shorter duration OK)
- [ ] Slap — free (VIP may shorten CD only)
- [ ] Aura vote — free (1 vote)
- [ ] Rebirth — cash cost only, no gamepass gate
- [ ] Daily claim — free
- [ ] Carpet Commons/Uncommons purchaseable with earned cash

### Allowed paid edges (must still feel contestable)
- [ ] VIP = lock time + badge only (0% idle) — not permanent unstealable ranch
- [ ] 2x Cash / luck minutes expire or stack-capped
- [ ] Limited/Secret packs = FOMO flex, not sole meta income path
- [ ] No doomscroll / “watch feed for power” mechanic present

**SECTION PASS:** all core verbs free + VIP lock contestable ≥30% sample + no immunity.

---

## 3) Addiction checks — daily / quests / trend / clips (legal retention)

### Daily streak
- [ ] ClaimDaily once → toast tone `daily` + reward applied
- [ ] Second claim same UTC day → reject (“Already claimed”)
- [ ] `CloutStats.DailyStreak` updates on claim **and** on join sync
- [ ] Return bonus window feels juicier first ~10m after claim (if SessionService wired)
- [ ] No client clock trust: spoofing local day does not double-claim

### Quests (3 daily)
- [ ] Three quest slots visible / claimable when ready
- [ ] Progress on: buy / steal_pet / lock_ranch / deposit_steal / aura podium (as implemented)
- [ ] Claim grants cash/aura — toast fires
- [ ] Cannot claim twice

### Trend banner (weekly culture)
- [ ] Active TrendDrop banner title readable (`TREND WEEK · …`)
- [ ] Ends timer uses server time (not frozen / not negative)
- [ ] Featured pet id bias on Carpet while drop active (or documented stub)
- [ ] No licensed IP names on pets / banner

### Clip moments (without banned doomscroll-for-power)
- [ ] Secret steal OR Aura podium fires clip juice / toast (`clip` / clout tone)
- [ ] Podium Top 3 readable + VFX long enough for vertical capture (~8s hold)
- [ ] Killfeed line appears for steal/slap/flex
- [ ] **FAIL if** any “watch / scroll feed to earn power / speed / luck” loop exists

**SECTION PASS:** daily+quests claimable; trend visible; ≥1 clip-bait moment; zero banned feed-for-power.

---

## 4) Social — killfeed, party, flex readability

### Killfeed
- [ ] Steal announces (`yeeted/yoinked/…`) via `CloutFeed` and/or `FeedEvent`
- [ ] Slap announce readable
- [ ] Aura podium announce (if wired)
- [ ] Max ~12 lines prune; no runaway StringValues
- [ ] Text readable on mobile (not truncated to garbage)

### Party
- [ ] Invite → accept → both see party sync payload
- [ ] Cap 4; 5th invite fails with toast
- [ ] Leave / leader migrate works
- [ ] Nearby huddle cash bonus (~1.1×) only when mates in range (if live)
- [ ] Lock assist seconds only with mate nearby (if live) — not global free VIP

### Aura Flex readability
- [ ] Phase banner: idle → flex → podium transitions
- [ ] Countdown matches `EndsAt` vs `workspace:GetServerTimeNow()` (±1s)
- [ ] Vote once; second vote rejected
- [ ] Flex stage findable; showcase pet/emote readable from spectator distance
- [ ] Winners + aura grant correct; killfeed/clip optional but preferred

**SECTION PASS:** killfeed fires on steal; flex countdown correct; party invite path works or marked N/A with bug filed.

---

## 5) Top 15 bug hunts — our systems

Run each. Log repro in FAIL notes.

1. **Remotes class mismatch**  
   - [ ] Every name in Bootstrap is correct class: Events vs `GetCarpetStock` **RemoteFunction**. Destroy/recreate if wrong class. Client ActionBar must not silent-fail.

2. **MapBootstrap ranches**  
   - [ ] Idempotent: Play → Stop → Play does not duplicate Ranch plots. Still exactly 6. `BootstrapFromWorkspace` registers all 6 names. 7th player gets clear “no plot” behavior.

3. **GetCarpetStock RF**  
   - [ ] Invoke returns array ≤4 of `{ id, name, rarity, price }` (or documented detailed shape). Never nil / never string error. Client shop refreshes ≤2s after Rotate.

4. **DailyStreak replication**  
   - [ ] On join before any claim: NumberValue exists and matches server streak. After claim: value increments without requiring rejoin. HUD label not stuck at 0.

5. **EndsAt server time**  
   - [ ] `EndsAt` is **unix / GetServerTimeNow domain**, not `os.clock()`. Client AuraBanner countdown agrees with server (±1s). Force flex; verify no 20s local fallback unless EndsAt broken.

6. **Feedback payload shape**  
   - [ ] Server→client: table `{ message: string, tone: string }` only. Tones: `info|success|warn|error|clout|steal|buy|rebirth|daily|aura|clip`.  
   - [ ] Client→server Submit: string ≤500. Non-string ignored. Toast does not error on unexpected keys.

7. **StealClosest range / empty**  
   - [ ] No steal when >STEAL_RANGE (~28). Empty unlocked ranch → toast, not hang. Already carrying → reject.

8. **Deposit without carry**  
   - [ ] DepositPet no-op + feedback; does not wipe ranch slots.

9. **Lock spam**  
   - [ ] RequestLock while locked is **rejected** (SoftFeedback; no refresh/stack) — no negative timers; VIP flag only via Monetization.IsVIP.

10. **Carpet buy race**  
    - [ ] Two clients buy same stock index during rotate: one fails cleanly; no duplicate pet / negative cash.

11. **Income while stolen**  
    - [ ] Pet removed from victim slots immediately; victim income drops; thief does not earn until Deposit.

12. **Aura vote exploit**  
    - [ ] Cannot vote self if disallowed; cannot vote after phase idle; voter flag sticks for round.

13. **Party desync**  
    - [ ] Invitee leaves server mid-invite; leader state sane; no ghost member UserIds.

14. **TrendDrop clock**  
    - [ ] Outside drop window: no featured force. Inside window: banner + weight bias. `startsAt/endsAt` unix consistent with ServerTime.

15. **Rebirth gate**  
    - [ ] Insufficient cash → reject toast; sufficient → slots/mult update; pets/economy not soft-locked.

**SECTION PASS:** 0 open **Must-fix** from this list; all 15 executed.

---

## 6) Ship gate — before public

### Must-fix (blocks public)
- [ ] Funnel section PASS (10m)
- [ ] Core verbs free; VIP lock contestable
- [ ] Remotes + GetCarpetStock + Feedback shape green
- [ ] MapBootstrap 6 ranches stable across restart
- [ ] EndsAt countdown correct (no clock-domain bug)
- [ ] DailyStreak replicates; claim once/day
- [ ] Steal → carry → deposit works 2-player
- [ ] Slap drops thief carry
- [ ] No Robux required to complete first steal + first flex vote
- [ ] No banned doomscroll-for-power
- [ ] No licensed IP / lawsuit-bait names in catalog or trend copy
- [ ] Mobile ActionBar usable; cash readable
- [ ] Server does not error-spam Heartbeat (clean Output 10m)

### Should-fix (soft launch OK only with known workaround)
- [ ] Killfeed on every steal/slap
- [ ] Party invite/accept/leave
- [ ] Quest claim UX + 3 quests
- [ ] Trend banner + featured carpet bias
- [ ] Clip toast on Secret steal / podium
- [ ] Soft pity / luck minutes visible
- [ ] Battle Pass XP on podium/steal (if SKU live)
- [ ] Newbie lock UI countdown
- [ ] Carpet empty-slot UX during rotate
- [ ] Feed prune / no CloutFeed leak

### Nice (polish; do not delay public if Must clear)
- [ ] Podium camera / thumbnail poses
- [ ] Steal cam juice
- [ ] Party huddle VFX
- [ ] Rarity particle drip
- [ ] Tutorial tip timing polish
- [ ] Comeback / soft pity UX copy
- [ ] Showcase ranch flex props

---

## Scoring card (fill after session)

| Section | PASS/FAIL | Notes |
|---------|-----------|-------|
| 1 Funnel 10m | | |
| 2 Fairness | | |
| 3 Addiction | | |
| 4 Social | | |
| 5 Top 15 bugs | | |
| 6 Ship gate | | |

**PUBLIC SHIP:** all Must-fix checked + sections 1–2 PASS + section 5 Must bugs closed.  
**SOFT ONLY:** Must open ≤0; Should failures listed with owners.  
**NO SHIP:** any funnel hard fail, paywalled core verb, EndsAt/Remotes/RF broken, or IP risk.

---

## Quick repro commands (Studio command bar)

```lua
-- Carpet RF
print(game.ReplicatedStorage.Remotes.GetCarpetStock:InvokeServer())

-- CloutState clock domain
local s=game.ReplicatedStorage.CloutState
print(s.Phase.Value, s.EndsAt.Value, s.ServerTime.Value, workspace:GetServerTimeNow())

-- Daily streak value
print(game.Players.LocalPlayer.CloutStats.DailyStreak.Value)
```
