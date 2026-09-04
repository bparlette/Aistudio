# Beach Catch Live

Phone web game that plays like a live stream of a fake-49ers-player beach catch. **Tap the screen when the ball arrives.** That is the only control.

**Play:** [https://bparlette.github.io/Aistudio/](https://bparlette.github.io/Aistudio/)

## How to play

1. Open the URL on a phone (portrait). The clip is the graphics.
2. Tap anywhere to start a run.
3. Tap again in the catch window — **catch juice** (~0.4s): zoom punch, hearts detonate, fake Super Chat, CAUGHT stamp. Speed goes up, next round starts.
4. Tap early/late, or miss — drop clip plays, then **freezes on the ball in the sand**. Chat roasts him (FRAUD / fake 49er). Hearts stop. Share card: helmet + rank + streak + “beat this.” Tap the card to copy a tweet (Web Share on phones). Tap elsewhere to retry.

**Streak ranks** (HUD + chat, reset on drop): 1 Practice squad · 3 UDFA · 5 Starting WR · 8 Super Bowl.

Scores this run and your **best run** are stored in `localStorage` (`beachCatchBest`). Each catch adds `+0.12` playback rate, capped at `2.2`.

## Source video (committed)

| File | Use |
| --- | --- |
| `public/game-video.mp4` | **Playable live-stream.** 730×1320 H.264, 60fps, 5.96s, ~1.9MB. |
| `public/game-video.mov` | iPhone original (1320×730 + 90° rotation). **Not** the playable source. |
| `public/drop-video.mp4` | Generated miss insert. Freeze of the pre-catch reach + composited ball slip / sand hit. |
| `public/og.jpg` | Portrait still (~1080 wide) at ~0.4s — sprint toward camera. |
| `public/og-card.jpg` | 1200×630 landscape crop for `og:image` / `twitter:image`. |

Do not use the `.mov` in `<video>` — Safari/Chrome often show it sideways.

## Catch-window timestamps

Verified on `public/game-video.mp4`:

| Beat | Time |
| --- | --- |
| Sprint toward camera (gold helmet) | 0.00s – 1.00s |
| Passes camera, turns, sprints toward ocean | 1.00s – 2.00s |
| Football enters; hands go up | ~3.00s |
| **Catch secured in stride** | **4.00s** |
| Runs with the ball; clip cuts | 4.00s – 5.96s |

**Game constants** (`src/lib/timing.ts`):

- `loopDuration` = **5.96s**
- `windowStart` = **3.50s** (0.5s before the catch)
- `windowEnd` = **4.00s** (catch secured — looks over his shoulder)
- Exactly **0.5s of video time**. Does **not** scale with playbackRate.
- **TAP NOW** flash only during that half second. First tap only starts the run.

Video stays **muted by default** (clip audio talks over the play). Unmute is the speaker toggle. Blurred pillarbox bars are cropped with a 124% `object-cover` so the beach fills the phone.

## Hosting

Static Vite build on **GitHub Pages**. Production files are on the `gh-pages` branch.

- **Live URL:** [https://bparlette.github.io/Aistudio/](https://bparlette.github.io/Aistudio/)
- Build base path: `/Aistudio/`
- Workflow (after merge to `main`): `.github/workflows/deploy-pages.yml`

**One click if the URL 404s:** GitHub → this repo → **Settings → Pages → Branch: `gh-pages` / `/` (root) → Save**.

The Pages API is not writable from this agent (403). The production build is already pushed to `gh-pages`.

Local:

```bash
npm install
npm run dev      # http://localhost:3000
npm run build    # writes dist/ with /Aistudio/ base
npm run preview  # http://localhost:4173/Aistudio/
```

## Notes

- First paint is the live-stream chrome (LIVE badge, viewers, chat). Settings sit behind the small gear. No upload / GitHub debug on the play view.
- Three.js `BeachSimulation` is last-resort only (if the mp4 fails to load).
- Audio is synthesized Web Audio cues; the video stays muted so iOS Safari can autoplay inline.
