import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import type { Rank } from "../lib/ranks";

const USERS = [
  "nfl_fan99",
  "bro_what",
  "49ersFaithful",
  "speedyz",
  "user10293",
  "beast_mode88",
  "sandlot_sf",
  "camp_cut",
];

const HYPE: Record<string, string[]> = {
  none: [
    "bro is fast 🏃‍♂️💨",
    "helmet at the beach crazy 😂",
    "He's gonna drop it",
    "W catch incoming",
    "tap the screen yall!",
    "oakley visor is clean 🔥",
    "W stream",
  ],
  "Practice squad": [
    "practice squad HANDS",
    "camp body cooking",
    "PS catch tho",
    "keep this dude up",
    "practice squad speed",
  ],
  UDFA: [
    "UDFA and he's COOKING",
    "undrafted legend",
    "cut this tape",
    "UDFA energy fr",
    "who let him go",
  ],
  "Starting WR": [
    "STARTING WR",
    "put him in the lineup",
    "that's WR1",
    "route of the year",
    "starting lineup NOW",
  ],
  "Super Bowl": [
    "SUPER BOWL",
    "parade in the sand",
    "rings incoming",
    "confetti on the beach",
    "he just won it",
  ],
};

/** Roast the fake catcher only — no real player/victim names. */
const ROASTS = [
  "FRAUD",
  "UDFA",
  "helmet at the beach",
  "he's a fake 49er",
  "ball in the SAND",
  "camp cut tomorrow",
  "hands of stone",
  "CONTENT 49er",
  "practice squad bounce",
  "send him home",
  "this dude is a bit",
  "FRAUD ALERT",
];

type Line = { id: number; user: string; text: string; roast?: boolean };

function pick(list: string[]): string {
  return list[Math.floor(Math.random() * list.length)];
}

function line(text: string, roast = false, user?: string): Line {
  return {
    id: Date.now() + Math.random(),
    user: user ?? USERS[Math.floor(Math.random() * USERS.length)],
    text,
    roast,
  };
}

export function FakeChat({
  active,
  roast,
  rank,
}: {
  active: boolean;
  roast?: boolean;
  rank?: Rank | null;
}) {
  const [messages, setMessages] = useState<Line[]>([]);
  const lastRankRef = useRef<string | null>(null);
  const rankNameRef = useRef(rank?.name ?? "none");
  rankNameRef.current = rank?.name ?? "none";

  useEffect(() => {
    if (!active) {
      setMessages([]);
      lastRankRef.current = null;
      return;
    }

    if (roast) {
      setMessages([line(pick(ROASTS), true), line(pick(ROASTS), true), line("FRAUD", true)]);
    } else {
      setMessages([]);
      lastRankRef.current = null;
    }

    const interval = setInterval(
      () => {
        if (Math.random() > (roast ? 0.12 : 0.3)) {
          setMessages((prev) => {
            const pool = roast ? ROASTS : HYPE[rankNameRef.current] ?? HYPE.none;
            const next = line(pick(pool), !!roast);
            return [...prev, next].slice(-5);
          });
        }
      },
      roast ? 380 : 620,
    );
    return () => clearInterval(interval);
  }, [active, roast]);

  useEffect(() => {
    if (!active || roast || !rank) return;
    if (lastRankRef.current === rank.name) return;
    const prev = lastRankRef.current;
    lastRankRef.current = rank.name;
    if (!prev) return;
    setMessages((m) => [...m, line(`↑ ${rank.name}`, false, "LIVE")].slice(-5));
  }, [active, roast, rank]);

  return (
    <div className="absolute bottom-5 left-3 z-20 w-[62%] max-w-[240px] h-40 overflow-hidden flex flex-col justify-end pointer-events-none">
      <AnimatePresence>
        {messages.map((m) => (
          <motion.div
            key={m.id}
            initial={{ opacity: 0, x: -16, scale: 0.94 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0 }}
            className={`mb-1.5 text-[11px] drop-shadow px-2.5 py-1.5 rounded-2xl backdrop-blur-md w-fit max-w-full leading-tight ${
              m.roast ? "bg-red-950/70 text-red-50" : "bg-black/45 text-white"
            }`}
          >
            <span className={`font-semibold mr-1 ${m.roast ? "text-red-300" : "text-amber-300"}`}>
              {m.user}
            </span>
            <span className={m.roast ? "text-red-50 font-semibold uppercase tracking-wide" : "text-white/95"}>
              {m.text}
            </span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
