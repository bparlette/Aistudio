import { useState } from "react";
import { motion } from "motion/react";
import { rankForScore, tweetForRun } from "../lib/ranks";
import { shareRun } from "../lib/share";

export function ShareCard({
  still,
  score,
}: {
  still: string | null;
  score: number;
}) {
  const rank = rankForScore(score);
  const title = rank?.name ?? "Unsigned";
  const [status, setStatus] = useState<"idle" | "shared" | "copied">("idle");

  const onShare = async () => {
    const text = tweetForRun(score, rank);
    try {
      const result = await shareRun({ text, still, score, rank });
      setStatus(result);
    } catch {
      try {
        await navigator.clipboard.writeText(text);
        setStatus("copied");
      } catch {
        setStatus("copied");
      }
    }
    window.setTimeout(() => setStatus("idle"), 2200);
  };

  return (
    <motion.button
      type="button"
      data-chrome
      onClick={(e) => {
        e.stopPropagation();
        void onShare();
      }}
      initial={{ opacity: 0, y: 16, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      className="pointer-events-auto mx-auto w-[46%] max-w-[200px] aspect-[9/16] rounded-2xl overflow-hidden border border-white/25 shadow-[0_12px_40px_rgba(0,0,0,0.55)] text-left relative"
    >
      {still ? (
        <img src={still} alt="" className="absolute inset-0 w-full h-full object-cover" />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-b from-sky-700 to-amber-900" />
      )}
      <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/25 to-black/20" />
      <div className="absolute inset-x-0 bottom-0 p-2.5 text-center">
        <p className="text-[9px] font-bold tracking-[0.2em] uppercase text-white/70">Beach Catch</p>
        <p className="text-[15px] font-black uppercase leading-tight text-amber-300">{title}</p>
        <p className="text-[12px] font-extrabold text-white tabular-nums">{score} streak</p>
        <p className="text-[11px] font-black uppercase tracking-wider text-red-300 mt-0.5">beat this</p>
        <p className="mt-1.5 text-[9px] font-semibold uppercase tracking-wider text-white/80">
          {status === "shared" ? "Shared" : status === "copied" ? "Tweet copied" : "Tap to copy tweet"}
        </p>
      </div>
    </motion.button>
  );
}
