# Clout Ranch — Play Feel (what makes the loop crack)

First-session addiction is not more systems — it is **readable stakes**, **instant juice**, and a **guided loop** that never hard-blocks.

## The crack loop (60–180s)

1. **Claim ranch** — plot + newbie lock. You own turf immediately.
2. **Buy first pet** — Red Carpet (ProximityPrompt `OpenShop` or HUD). Cash → pet → visible slot.
3. **Earn ~10s** — idle tick on the cash counter. Dopamine without a button mash.
4. **Steal OR Lock** — touch an enemy `Slot` Prompt / STEAL button, *or* Lock pad. Agency + risk.
5. **Claim Daily** — streak hook so tomorrow has a reason.

`OnboardingService` tracks flags on `player.CloutStats` (`OnboardingStep` NumberValue + bools). Soft toasts only — **nothing permanently blocked**.

## Steal feel (must stay fair-readable)

| Rule | Why it cracks |
|------|----------------|
| **Clear lock copy** | Locked = wait it out; **VIP = longer lock time only** (not a permanent vault / not idle power) — rage is directed, not confused |
| **Readable carry slow** | Amplified `carrySlow`, floor ~7 WalkSpeed — chase is a skill read, not a blur |
| **0.5s i-frames after drop** | Slap → drop → brief immunity — no chain-stun cheese; thief can peel |
| **Soft protect 15s** | Victim isn't farmed; thief rotates targets |

Deposit at own ranch auto-locks briefly — reward the risk.

## Juice (every big beat)

`JuiceService` on buy / steal / deposit / rebirth / daily / lock:

- `FeedbackService.Tell` → big center toast (`FeedbackToast`)
- `Remotes.Juice` `{ kind }` → client camera shake (intensity by kind)
- Optional `CloutBindables.Juice` Bindable for tests / FX listeners

If it prints cash, steals a pet, or claims a streak — **something moves on screen**.

## World affordances

- **Enemy Slot parts** — `Steal` ProximityPrompt (Hold ~0.35s)
- **Own DepositPad / LockPad** — Deposit + Lock without hunting HUD
- **Carpet** — `OpenShop` fires client; shop panel pops

HUD ActionBar remains the mobile fallback. Remotes stay stable: never rename existing events.

## Session glue

- `SessionService` first-session + tutorial flags
- `TutorialTips` prefers `CloutStats.OnboardingStep`; timed tips are fallback
- `JoinFunnel` sticky NEXT + ActionBar highlight the live verb **BUY → STEAL → LOCK → DEPOSIT** (carry forces DEPOSIT) — pre-alpha-onboard-1
- Daily claim arms return-bonus window (see `RetentionGDD.md`)

## Design non-negotiables

- Soft guide ≠ soft lockout
- VIP = longer lock time only (clearer wait) — not unstealable forever, not idle mult
- Carry weight is the skill tax; slap is the counterplay
- First session ends on a **claim** (daily), not a dead end

Wire order in `ServerBootstrap`: Map → Ranch → WorldInteract → remotes → tryRequire Onboarding / Juice / Daily / Session.
