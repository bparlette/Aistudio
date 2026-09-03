/** Calibrated against public/game-video.mp4 (730x1320 H.264, 5.96s @ 60fps). */

export const CATCH_VIDEO = "game-video.mp4";
export const DROP_VIDEO = "drop-video.mp4";

export const BEST_SCORE_KEY = "beachCatchBest";

/** Full clip length — one round is the run + catch, no extra dead air. */
export const LOOP_DURATION = 5.96;

/**
 * Verified on public/game-video.mp4:
 *   ~3.00s ball enters, hands go up
 *   4.00s catch is secured in stride
 * Tap window is ball-in-air until just after the secure.
 */
export const WINDOW_START = 3.0;
export const WINDOW_END = 4.2;

/** Idle live-preview loops only the sprint-toward-camera. */
export const IDLE_LOOP_END = 0.98;

/** Cut to the drop insert before the real catch is secured. */
export const DROP_CUT_IN = 2.95;

export const SPEED_STEP = 0.12;
export const SPEED_CAP = 2.2;

export function assetUrl(file: string): string {
  const base = import.meta.env.BASE_URL || "/";
  return base.endsWith("/") ? `${base}${file}` : `${base}/${file}`;
}
