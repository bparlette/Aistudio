export const PLAY_URL = "https://bparlette.github.io/Aistudio/tap.html";

export type Rank = {
  min: number;
  name: string;
};

/** Chase the title. Thresholds are cumulative streak, not a counter label. */
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
  const title = rank?.name ?? "Unsigned";
  return `${title}. ${score} streak. Beat this.\n\nBeach Catch Live\n${PLAY_URL}`;
}
