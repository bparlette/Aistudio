# pre-alpha-onboard-1 — CloutDev NOTES (re-spot)

**Date:** 2026-09-04 (America/New_York)
**Pack:** `/workspace/onboard-1-notes.tgz`
**Rails:** no Marketplace IDs · no VIP idle · no endsAt · no paywall · no X/Twitter/TikTok

## NOTE 1 — ActionBar nextVerb / gold stroke (fixed)

**Bug:** `nextVerb` fell through to `"buy"` for step ≥5 while NextHint showed `LOCK · CLAIM DAILY` (or the full ladder). Gold stroke highlighted BUY — wrong verb.

**Fix:**
- `ActionBar.nextVerb`: step 4 **and** 5 → `"lock"`; step ≥6 → `"done"` (matches no button).
- Gold stroke only when verb ∈ {buy, steal, lock, deposit} and step < 6.
- `JoinFunnel.activeVerb` same ladder (step 5 = lock, not `"daily"`).
- `OnboardingService` step-5 toast: `LOCK · CLAIM DAILY` (copy only).

**Re-spot:** at OnboardingStep=5 (not carrying) → NextHint `LOCK · CLAIM DAILY` + purple LOCK gold-stroked; BUY must **not** be stroked.

## NOTE 2 — JoinFunnel Ranch1 DepositPad fallback (fixed)

**Bug:** if owned-plot lookup missed, Ranch1 pads were used → mint beam to wrong ranch while player owned Ranch2+.

**Fix:**
- Scan for `OwnerUserId == player.UserId` first (`typeof` number).
- If owned plot found → **only** that plot’s pads (recursive `DepositPad` / `LockPad`).
- Ranch1 fallback **only** when no owned plot exists (pre-claim).

**Re-spot:** claim Ranch2+ → carry pet → mint beam / ▼ DEPOSIT lands on **owned** DepositPad, never Ranch1.

## NOTE 3 — PLAY_FEEL.md VIP vault scrub (fixed)

**Bug:** design-doc used `"LOCKED — VIP vault"` language (vault metaphor).

**Fix:** scrubbed to kid-safe / accurate: **VIP = longer lock time only** (not permanent vault, not idle power). HUD / StealService live copy untouched by this notes pack.

## Files in this notes pack

- `src/StarterPlayer/.../HudModules/ActionBar.lua`
- `src/StarterPlayer/.../HudModules/JoinFunnel.lua`
- `src/ServerScriptService/Services/OnboardingService.lua`
- `docs/PLAY_FEEL.md`
- `docs/NOTES_pre-alpha-onboard-1.md`
- `SUMMARY.txt`
