import { useRef } from "react";
import { AnimatePresence, motion } from "motion/react";
import type { Rank } from "../lib/ranks";

const GIFTS = [
  { user: "sandlot_sf", amount: "$50", note: "HANDS" },
  { user: "beast_mode88", amount: "$20", note: "W CATCH" },
  { user: "speedyz", amount: "$100", note: "KEEP HIM" },
  { user: "49ersFaithful", amount: "$75", note: "THAT'S IT" },
];

function giftFor(rank: Rank | null) {
  const g = GIFTS[Math.floor(Math.random() * GIFTS.length)];
  if (!rank) return { ...g, note: "CAUGHT" };
  if (rank.name === "Super Bowl") return { ...g, amount: "$200", note: "SUPER BOWL" };
  if (rank.name === "Starting WR") return { ...g, note: "WR1" };
  if (rank.name === "UDFA") return { ...g, note: "UDFA" };
  return { ...g, note: "PRACTICE SQUAD" };
}

export function CatchJuice({
  juicing,
  caught,
  rank,
}: {
  juicing: boolean;
  caught: boolean;
  rank: Rank | null;
}) {
  const giftRef = useRef(GIFTS[0]);
  const wasJuicing = useRef(false);
  if (juicing && !wasJuicing.current) giftRef.current = giftFor(rank);
  wasJuicing.current = juicing;
  const gift = giftRef.current;

  return (
    <>
      <AnimatePresence>
        {juicing && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: [0, 0.55, 0] }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.4, times: [0, 0.2, 1] }}
            className="absolute inset-0 z-30 bg-white pointer-events-none mix-blend-overlay"
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {juicing && (
          <motion.div
            initial={{ opacity: 0, y: -18, scale: 0.92 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.18 }}
            className="absolute top-[7.2rem] left-[6.5rem] right-3 z-40 pointer-events-none"
          >
            <div className="mx-auto max-w-[22rem] rounded-xl overflow-hidden shadow-[0_8px_28px_rgba(0,0,0,0.45)] border border-amber-200/40">
              <div className="bg-gradient-to-r from-amber-300 via-yellow-300 to-amber-400 px-3 py-1.5 flex items-center justify-between">
                <p className="text-[12px] font-black text-black truncate">
                  {gift.user} <span className="font-semibold opacity-70">Super Chat</span>
                </p>
                <p className="text-[12px] font-black text-black">{gift.amount}</p>
              </div>
              <div className="bg-amber-200 px-3 py-1.5">
                <p className="text-[13px] font-black text-black tracking-wide">{gift.note}</p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {caught && (
          <motion.div
            initial={{ opacity: 0, scale: 0.55, rotate: -6 }}
            animate={{ opacity: 1, scale: juicing ? [1.15, 1] : 1, rotate: -3 }}
            exit={{ opacity: 0, scale: 1.2 }}
            transition={{ duration: 0.22 }}
            className="absolute top-[36%] inset-x-0 text-center z-40 pointer-events-none"
          >
            <p
              className="text-6xl sm:text-7xl font-black text-emerald-300 uppercase tracking-widest drop-shadow-[0_4px_24px_rgba(16,185,129,0.95)]"
              style={{ WebkitTextStroke: "2px #052e16" }}
            >
              CAUGHT
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
