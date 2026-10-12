# Overnight-1 live retest (Brad — after Rojo sync + Stop→Play)

Game Settings → Security → **Enable Studio Access to API Services** = ON (needed for real DataStore restore; otherwise mock only survives in-session).

## 1) Shop Offline Brain icon (≤1 min)
- Open Red Carpet. Find **Offline Brain** (Secret ~$8k) or any stocked pet.
- **PASS:** row shows ViewportFrame pet silhouette (skull+crack for Offline Brain), not text-only / not blank rarity orb forever.
- **FAIL:** text-only or empty icon after stock loads.

## 2) DataStore Stop→Play restore (≤2 min)
- Buy a pet / earn cash note values: Cash=____ Pets=____
- **Stop** → **Play** (same place, API Services ON).
- **PASS:** cash + ranch pets restore (not reset to $50 empty).
- **FAIL:** wipe to defaults, or Output shows mock-only when API Services were ON.
- Note Output line: `[DataService] Bootstrap OK — store=... mock=true/false`

## 3) Mash LOCK (30s)
- LOCK once → mash 5×.
- **PASS:** SoftFeedback `Already locked — Ns left`; timer does not refresh to full.
- **FAIL:** forever refresh.

## 4) Steal ×5 single SFX (≤3 min — needs 2P or unlocked victim)
- Complete 5 steals (or steal attempts that fire juice).
- **PASS:** one steal sting per event (no stacked double-hit).
- **FAIL:** doubled SFX each steal.

## Paste to RanchPlay
```
Sync: overnight-1 Y/N
1 Shop icon Offline Brain: PASS/FAIL
2 DataStore restore (API on): PASS/FAIL  mock=?
3 Mash LOCK: PASS/FAIL
4 Steal×5 single SFX: PASS/FAIL
```

---

## Live mash card — juice-2-stings-1 (when Studio up)

Code already **PASS**. Ear-only:

1. **Steal ×5** — one whoosh/press (sparkle layer OK). Doubles → leftover second listener, not ALIAS.
2. **Deposit** — single pad thud (`place`), not lock+buy stack.
3. Optional: Rare hatch → rare chime; slap → impact (not lock click).
