# Beach Catch Live

Phone web game that plays like a live stream of a fake-49ers-player beach catch. **Tap the screen when the ball arrives.** That is the only control.

**Play:** [https://bparlette.github.io/Aistudio/](https://bparlette.github.io/Aistudio/)

## How to play

1. Open the URL on a phone (portrait). The clip is the graphics.
2. Tap anywhere to start a run.
3. Tap again in the catch window — he catches, likes/loves spam the **right** side, speed goes up, next round starts.
4. Tap early/late, or miss the window — a **created drop** plays (ball slips and hits the sand). Game over. Tap to retry.

Scores this run and your **best run** are stored in `localStorage` (`beachCatchBest`). Each catch adds `+0.12` playback rate, capped at `2.2`.

## Source video (committed)

| File | Use |
| --- | --- |
| `public/game-video.mp4` | **Playable live-stream.** 730×1320 H.264, 60fps, 5.96s, ~1.9MB. |
| `public/game-video.mov` | iPhone original (1320×730 + 90° rotation). **Not** the playable source. |
| `public/drop-video.mp4` | Generated miss insert. Freeze of the pre-catch reach + composited ball slip / sand hit. |

Do not use the `.mov` in `<video>` — Safari/Chrome often show it sideways.

## Catch-window timestamps

Calibrated by watching `public/game-video.mp4` frame-by-frame:

| Beat | Time |
| --- | --- |
| Sprint toward camera | 0.00s – ~2.00s |
| Whip / he runs toward the ocean | ~2.00s – ~3.50s |
| Looks over the shoulder, ball not yet in hands | ~3.60s – ~4.20s |
| **Ball in the air** | ~4.45s – ~4.60s |
| **Ball arrives in his hands (catch)** | ~4.55s – ~4.70s |
| Ball tucked, he runs | ~5.00s – 5.96s |

**Game constants** (`src/lib/timing.ts`):

- `loopDuration` = **5.96s** (full clip — the round *is* the run + catch)
- `windowStart` = **4.20s**
- `windowEnd` = **4.75s**

Earlier guesses of `2.2–3.3s` / `3.6–4.4s` were off: at 3.6–4.4s he is still running away and looking back. The tap is the moment the ball gets to his hands.

## Hosting

Static Vite build on **GitHub Pages**.

- Site: `https://bparlette.github.io/Aistudio/`
- Workflow: `.github/workflows/deploy-pages.yml` (builds on push to `main`)
- Build base path: `/Aistudio/`

Local:

```bash
npm install
npm run dev      # http://localhost:3000
npm run build    # writes dist/ with /Aistudio/ base
npm run preview
```

If Pages is not enabled yet: **Settings → Pages → GitHub Actions** as the source. After the workflow runs, the URL above is the durable public host.

## Notes

- First paint is the live-stream chrome (LIVE badge, viewers, chat). Settings sit behind the small gear. No upload / GitHub debug on the play view.
- Three.js `BeachSimulation` is last-resort only (if the mp4 fails to load).
- Audio is synthesized Web Audio cues; the video stays muted so iOS Safari can autoplay inline.
