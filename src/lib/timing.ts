/** Calibrated against public/game-video.mp4 (730x1320 H.264, 5.96s @ 60fps). */

export const CATCH_VIDEO = "game-video.mp4";
export const DROP_VIDEO = "drop-video.mp4";

export const BEST_SCORE_KEY = "beachCatchBest";

/** Full clip length — one round is the run + catch, no extra dead air. */
export const LOOP_DURATION = 5.96;

/**
 * 1x window — wide enough for a phone thumb.
 * Ball enters ~3.0s, catch secured at 4.0s.
 */
export const WINDOW_START = 2.7;
export const WINDOW_END = 4.4;
export const CATCH_SECURED = 4.0;

/** Idle live-preview loops only the sprint-toward-camera. */
export const IDLE_LOOP_END = 0.98;

/** Cut to the drop insert before the real catch is secured. */
export const DROP_CUT_IN = 2.55;

/**
 * Expand the video-time window with playbackRate so wall-clock
 * tap time stays about 1.7s (2.7–4.4 at 1x). Faster rounds stay fair.
 */
export function windowForRate(rate: number): { start: number; end: number } {
  const baseDur = WINDOW_END - WINDOW_START;
  const videoDur = Math.min(baseDur * Math.max(rate, 1), 4.3);
  const beforeShare = (CATCH_SECURED - WINDOW_START) / baseDur;
  let start = CATCH_SECURED - videoDur * beforeShare;
  let end = start + videoDur;
  start = Math.max(1.35, start);
  end = Math.min(LOOP_DURATION - 0.15, end);
  return { start, end };
}

export const SPEED_STEP = 0.12;
export const SPEED_CAP = 2.2;

export function assetUrl(file: string): string {
  const base = import.meta.env.BASE_URL || "/";
  return base.endsWith("/") ? `${base}${file}` : `${base}/${file}`;
}
