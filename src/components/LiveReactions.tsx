import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Heart, ThumbsUp } from "lucide-react";

type Reaction = {
  id: string;
  type: "heart" | "like";
  x: number;
  duration: number;
  scale: number;
  drift: number;
};

function spawn(count: number): Reaction[] {
  return Array.from({ length: count }, () => ({
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    type: Math.random() > 0.42 ? ("heart" as const) : ("like" as const),
    x: 8 + Math.random() * 72,
    duration: 1.4 + Math.random() * 1.6,
    scale: 0.75 + Math.random() * 0.85,
    drift: Math.random() * 50 - 25,
  }));
}

export function LiveReactions({
  burst,
  ambient,
  detonate,
}: {
  burst: boolean;
  ambient?: boolean;
  detonate?: boolean;
}) {
  const [reactions, setReactions] = useState<Reaction[]>([]);

  useEffect(() => {
    if (!burst && !ambient) return;

    const tick = () => {
      const n = detonate ? 10 : burst ? 5 : Math.random() > 0.55 ? 1 : 0;
      if (n === 0) return;
      setReactions((prev) => [...prev, ...spawn(n)].slice(-56));
    };

    tick();
    const interval = setInterval(tick, detonate ? 50 : burst ? 90 : 420);
    return () => clearInterval(interval);
  }, [burst, ambient, detonate]);

  useEffect(() => {
    if (burst || ambient) return;
    if (reactions.length === 0) return;
    const t = setTimeout(() => setReactions([]), 2200);
    return () => clearTimeout(t);
  }, [burst, ambient, reactions.length]);

  return (
    <div className="absolute right-1 bottom-0 top-16 w-20 sm:w-28 pointer-events-none overflow-hidden z-40">
      <AnimatePresence>
        {reactions.map((r) => (
          <motion.div
            key={r.id}
            initial={{ opacity: 0, y: 24, x: r.x, scale: 0.4 }}
            animate={{
              opacity: [0, 1, 1, 0],
              y: -280 - Math.random() * 220,
              x: r.x + r.drift,
              scale: r.scale,
            }}
            exit={{ opacity: 0 }}
            transition={{ duration: r.duration, ease: "easeOut" }}
            className="absolute bottom-28 drop-shadow-lg"
          >
            {r.type === "heart" ? (
              <Heart
                fill="#fb7185"
                className="text-rose-400"
                style={{ width: 26 * r.scale, height: 26 * r.scale }}
              />
            ) : (
              <div
                className="bg-sky-500 rounded-full flex items-center justify-center p-1.5 shadow-md"
                style={{ transform: `scale(${r.scale})` }}
              >
                <ThumbsUp fill="white" className="text-white w-4 h-4" />
              </div>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
