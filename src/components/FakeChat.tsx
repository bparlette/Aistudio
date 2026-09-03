import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

const USERS = [
  "nfl_fan99",
  "bro_what",
  "49ersFaithful",
  "speedyz",
  "user10293",
  "jimmy_g",
  "beast_mode88",
  "sandlot_sf",
];

const TEXTS = [
  "bro is fast 🏃‍♂️💨",
  "helmet at the beach crazy 😂",
  "He's gonna drop it",
  "W catch incoming",
  "hands like glue!",
  "SF 49ers sign this man",
  "W stream",
  "tap the screen yall!",
  "too easy for him",
  "oakley visor is clean 🔥",
  "he got hands tho",
  "LET'S GOOO 🏈",
];

export function FakeChat({ active }: { active: boolean }) {
  const [messages, setMessages] = useState<{ id: number; user: string; text: string }[]>([]);

  useEffect(() => {
    if (!active) {
      setMessages([]);
      return;
    }
    const interval = setInterval(() => {
      if (Math.random() > 0.32) {
        setMessages((prev) => {
          const next = {
            id: Date.now() + Math.random(),
            user: USERS[Math.floor(Math.random() * USERS.length)],
            text: TEXTS[Math.floor(Math.random() * TEXTS.length)],
          };
          return [...prev, next].slice(-4);
        });
      }
    }, 620);
    return () => clearInterval(interval);
  }, [active]);

  return (
    <div className="absolute bottom-5 left-3 z-20 w-[68%] max-w-[240px] h-40 overflow-hidden flex flex-col justify-end pointer-events-none">
      <AnimatePresence>
        {messages.map((m) => (
          <motion.div
            key={m.id}
            initial={{ opacity: 0, x: -16, scale: 0.94 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0 }}
            className="mb-1.5 text-[11px] text-white drop-shadow bg-black/45 px-2.5 py-1.5 rounded-2xl backdrop-blur-md w-fit max-w-full leading-tight"
          >
            <span className="font-semibold text-amber-300 mr-1">{m.user}</span>
            <span className="text-white/95">{m.text}</span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
