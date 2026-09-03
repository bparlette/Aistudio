/** Calibrated against public/game-video.mp4 (730x1320 H.264, 5.96s @ 60fps). */

export const CATCH_VIDEO = "game-video.mp4";
export const DROP_VIDEO = "drop-video.mp4";

export const BEST_SCORE_KEY = "beachCatchBest";

/** Full clip length — one round is the run + catch, no extra dead air. */
export const LOOP_DURATION = 5.96;

/**
 * Ball is in the air ~4.5s; it arrives in his hands ~4.55–4.70s.
 * Window is tight around that arrival (not the earlier shoulder-look).
 */
export const WINDOW_START = 4.2;
export const WINDOW_END = 4.75;

/** Idle live-preview loops only the sprint-toward-camera, so the catch stays a surprise. */
export const IDLE_LOOP_END = 1.85;

/** After a miss, cut to the drop insert once we reach the pre-catch beat. */
export const DROP_CUT_IN = 4.18;

export const SPEED_STEP = 0.12;
export const SPEED_CAP = 2.2;

export function assetUrl(file: string): string {
  const base = import.meta.env.BASE_URL || "/";
  return base.endsWith("/") ? `${base}${file}` : `${base}/${file}`;
}
