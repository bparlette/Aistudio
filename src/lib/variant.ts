import {
  BEST_SCORE_KEY as BEACH_BEST,
  CATCH_VIDEO as BEACH_CATCH,
  DROP_CUT_IN as BEACH_DROP_CUT,
  DROP_VIDEO as BEACH_DROP,
  IDLE_LOOP_END as BEACH_IDLE,
  LOOP_DURATION as BEACH_LOOP,
  WINDOW_END as BEACH_WINDOW_END,
  WINDOW_START as BEACH_WINDOW_START,
} from "./timing";

export type GameVariant = {
  id: "beach" | "bendadonnn";
  title: string;
  shortTitle: string;
  handle: string;
  location: string;
  playUrl: string;
  catchVideo: string;
  dropVideo: string | null;
  bestScoreKey: string;
  windowStart: number;
  windowEnd: number;
  loopDuration: number;
  idleLoopEnd: number;
  dropCutIn: number;
  idleStillStart: number;
  idleStillEnd: number;
};

export const BEACH_VARIANT: GameVariant = {
  id: "beach",
  title: "Beach Catch Live",
  shortTitle: "Beach Catch",
  handle: "49ersBeachCatcher",
  location: "Ocean Beach",
  playUrl: "https://bparlette.github.io/Aistudio/",
  catchVideo: BEACH_CATCH,
  dropVideo: BEACH_DROP,
  bestScoreKey: BEACH_BEST,
  windowStart: BEACH_WINDOW_START,
  windowEnd: BEACH_WINDOW_END,
  loopDuration: BEACH_LOOP,
  idleLoopEnd: BEACH_IDLE,
  dropCutIn: BEACH_DROP_CUT,
  idleStillStart: 0.32,
  idleStillEnd: 0.72,
};

/** BenDaDonnn clip: 3.00s portrait. Arms out ~2.0s, tuck ~2.5s. */
export const BENDADONNN_VARIANT: GameVariant = {
  id: "bendadonnn",
  title: "BenDaDonnn Catch",
  shortTitle: "BenDaDonnn",
  handle: "BenDaDonnn",
  location: "South Beach",
  playUrl: "https://bparlette.github.io/Aistudio/BenDaDonnn/",
  catchVideo: "BenDaDonnn/game-video.mp4",
  dropVideo: null,
  bestScoreKey: "benDaDonnnCatchBest",
  windowStart: 2.0,
  windowEnd: 2.5,
  loopDuration: 3.0,
  idleLoopEnd: 0.7,
  dropCutIn: 1.5,
  idleStillStart: 0.35,
  idleStillEnd: 0.65,
};

export function pathIsBenDaDonnn(pathname: string): boolean {
  const p = pathname.split("?")[0].split("#")[0];
  return /\/BenDaDonnn(?:\/index\.html)?\/?$/i.test(p);
}

export function variantForPath(pathname: string): GameVariant {
  return pathIsBenDaDonnn(pathname) ? BENDADONNN_VARIANT : BEACH_VARIANT;
}

function currentPathname(): string {
  if (typeof window === "undefined") return "/";
  return window.location.pathname;
}

let cached: GameVariant | null = null;

export function getVariant(): GameVariant {
  if (!cached) cached = variantForPath(currentPathname());
  return cached;
}

/** Test-only: clear the pathname cache. */
export function resetVariantCache(): void {
  cached = null;
}
