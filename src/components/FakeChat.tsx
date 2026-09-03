import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

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

const HYPE = [
  "bro is fast 🏃‍♂️💨",
  "helmet at the beach crazy 😂",
  "He's gonna drop it",
  "W catch incoming",
  "hands like glue!",
  "W stream",
  "tap the screen yall!",
  "too easy for him",
  "oakley visor is clean 🔥",
  "he got hands tho",
  "LET'S GOOO 🏈",
];

/** Roast the fake catcher only — comedy, no real player/victim names. */
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
  "this dude is a bit",
  "FRAUD ALERT",
];

type Line = { id: number; user: string; text: string; roast?: boolean };

function pick(list: string[]): string {
  return list[Math.floor(Math.random() * list.length)];
}

function line(text: string, roast = false): Line {
  return {
    id: Date.now() + Math.random(),
    user: USERS[Math.floor(Math.random() * USERS.length)],
    text,
    roast,
  };
}

export function FakeChat({
  active,
  roast,
}: {
  active: boolean;
  roast?: boolean;
}) {
  const [messages, setMessages] = useState<Line[]>([]);

  useEffect(() => {
    if (!active) {
      setMessages([]);
      return;
    }

    if (roast) {
      setMessages([
        line(pick(ROASTS), true),
        line("helmet at the beach", true),
        line("FRAUD", true),
        line("he's a fake 49er", true),
      ]);
    } else {
      setMessages([]);
    }

    const interval = setInterval(
      () => {
        if (Math.random() > (roast ? 0.12 : 0.3)) {
          setMessages((prev) => {
            const next = line(pick(roast ? ROASTS : HYPE), !!roast);
            return [...prev, next].slice(-5);
          });
        }
      },
      roast ? 380 : 620,
    );
    return () => clearInterval(interval);
  }, [active, roast]);

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
