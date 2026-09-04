import { getVariant } from "./variant";

export const PLAY_URL = "https://bparlette.github.io/Aistudio/";

export type Rank = {
  min: number;
  name: string;
};

/** Catch thresholds (cumulative streak). */
export const RANKS: Rank[] = [
  { min: 1, name: "Practice squad" },
  { min: 3, name: "UDFA" },
  { min: 5, name: "Starting WR" },
  { min: 8, name: "Super Bowl" },
];

export function rankForScore(score: number): Rank | null {
  let found: Rank | null = null;
  for (const r of RANKS) {
    if (score >= r.min) found = r;
  }
  return found;
}

export function tweetForRun(score: number, rank: Rank | null): string {
  const variant = getVariant();
  const title = rank?.name ?? "Unsigned";
  return `${title}. ${score} streak. Beat this.\n\n${variant.title}\n${variant.playUrl}`;
}
