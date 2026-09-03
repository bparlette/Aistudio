import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Heart, ThumbsUp } from "lucide-react";

type Reaction = {
  id: string;
  type: "heart" | "like";
  left: number;
  duration: number;
  scale: number;
};

export function LiveReactions({ active }: { active: boolean }) {
  const [reactions, setReactions] = useState<Reaction[]>([]);

  useEffect(() => {
    if (!active) return;

    // Burst of reactions
    const generateReactions = () => {
      const newReactions = Array.from({ length: 3 }).map(() => ({
        id: Math.random().toString(36).substring(7),
        type: Math.random() > 0.5 ? ("heart" as const) : ("like" as const),
        left: 10 + Math.random() * 80, // Percentage width of the container
        duration: 1.5 + Math.random() * 1.5,
        scale: 0.8 + Math.random() * 0.7,
      }));

      setReactions((prev) => [...prev, ...newReactions].slice(-30)); // Keep max 30 on screen
    };

    const interval = setInterval(generateReactions, 150);

    return () => clearInterval(interval);
  }, [active]);

  useEffect(() => {
    if (!active && reactions.length > 0) {
        const timeout = setTimeout(() => {
            setReactions([]);
        }, 3000);
        return () => clearTimeout(timeout);
    }
  }, [active, reactions.length]);

  return (
    <div className="absolute right-0 bottom-0 top-0 w-24 md:w-48 pointer-events-none overflow-hidden flex flex-col justify-end pb-24 z-50">
      <AnimatePresence>
        {reactions.map((r) => (
          <motion.div
            key={r.id}
            initial={{ opacity: 0, y: 50, x: r.left - 50, scale: 0.5 }}
            animate={{ 
                opacity: [0, 1, 1, 0], 
                y: -300 - Math.random() * 300,
                x: r.left - 50 + (Math.random() * 60 - 30)
            }}
            exit={{ opacity: 0 }}
            transition={{ duration: r.duration, ease: "easeOut" }}
            className="absolute bottom-10 drop-shadow-md"
            style={{ left: `${r.left}%` }}
          >
            {r.type === "heart" ? (
              <Heart 
                fill="#ef4444" 
                className="text-red-500 drop-shadow-sm" 
                style={{ width: 28 * r.scale, height: 28 * r.scale }} 
              />
            ) : (
              <div 
                className="bg-blue-500 rounded-full flex items-center justify-center p-1.5 shadow-md"
                style={{ transform: `scale(${r.scale})`}}
              >
                <ThumbsUp fill="white" className="text-white w-5 h-5" />
              </div>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
