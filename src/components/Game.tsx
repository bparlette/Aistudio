import { useCallback, useEffect, useRef, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { Eye, Heart, Settings, Volume2, VolumeX, X } from "lucide-react";
import { BeachSimulation } from "./BeachSimulation";
import { CatchJuice } from "./CatchJuice";
import { FakeChat } from "./FakeChat";
import { LiveReactions } from "./LiveReactions";
import { ShareCard } from "./ShareCard";
import { sound } from "../lib/audio";
import { rankForScore } from "../lib/ranks";
import { captureVideoFrame } from "../lib/share";
import {
  assetUrl,
  BEST_SCORE_KEY,
  CATCH_VIDEO,
  DROP_CUT_IN,
  DROP_VIDEO,
  IDLE_LOOP_END,
  LOOP_DURATION,
  SPEED_CAP,
  SPEED_STEP,
  WINDOW_END,
  WINDOW_START,
} from "../lib/timing";

const JUICE_MS = 400;

type Phase = "idle" | "playing" | "caught" | "dropping" | "failed";

const CATCH_SRC = assetUrl(CATCH_VIDEO);
const DROP_SRC = assetUrl(DROP_VIDEO);

function loadBest(): number {
  try {
    return Number(localStorage.getItem(BEST_SCORE_KEY) || 0) || 0;
  } catch {
    return 0;
  }
}

function saveBest(n: number) {
  try {
    localStorage.setItem(BEST_SCORE_KEY, String(n));
  } catch {
    /* private mode */
  }
}

export function Game() {
  const [phase, setPhase] = useState<Phase>("idle");
  const [score, setScore] = useState(0);
  const [best, setBest] = useState(loadBest);
  const [speed, setSpeed] = useState(1);
  const [muted, setMuted] = useState(true);
  const [useSim, setUseSim] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [viewers, setViewers] = useState(14820);
  const [likes, setLikes] = useState(862);
  const [simProgress, setSimProgress] = useState(0);
  const [showTapNow, setShowTapNow] = useState(false);
  const [juicing, setJuicing] = useState(false);
  const [shareStill, setShareStill] = useState<string | null>(null);

  const catchRef = useRef<HTMLVideoElement | null>(null);
  const dropRef = useRef<HTMLVideoElement | null>(null);
  const phaseRef = useRef<Phase>("idle");
  const scoreRef = useRef(0);
  const speedRef = useRef(1);
  const lastTapRef = useRef(0);
  const progressRef = useRef(0);
  const pendingDropRef = useRef(false);
  const rafRef = useRef<number | null>(null);
  const startLockUntilRef = useRef(0);
  const tapArmedRef = useRef(false);
  const juiceTimerRef = useRef<number | null>(null);
  const helmetStillRef = useRef<string | null>(null);
  const dropHoldTimerRef = useRef<number | null>(null);

  const setPhaseBoth = (p: Phase) => {
    phaseRef.current = p;
    setPhase(p);
  };

  useEffect(() => {
    scoreRef.current = score;
  }, [score]);

  useEffect(() => {
    return () => {
      if (juiceTimerRef.current) window.clearTimeout(juiceTimerRef.current);
      if (dropHoldTimerRef.current) window.clearTimeout(dropHoldTimerRef.current);
    };
  }, []);

  useEffect(() => {
    speedRef.current = speed;
  }, [speed]);

  useEffect(() => {
    const v = catchRef.current;
    if (!v) return;
    v.setAttribute("webkit-playsinline", "true");
    v.setAttribute("playsinline", "true");
    v.muted = muted;
    v.playsInline = true;
    v.play().catch(() => {});
    if (dropRef.current) dropRef.current.muted = muted;
  }, [useSim, muted]);

  useEffect(() => {
    const tick = setInterval(() => {
      const p = phaseRef.current;
      if (p === "dropping" || p === "failed") {
        setViewers((n) => Math.max(180, n - (18 + Math.floor(Math.random() * 48))));
        return;
      }
      setViewers((n) => n + Math.floor(Math.random() * 17) - 4);
      setLikes((n) => n + (p === "caught" ? 8 + Math.floor(Math.random() * 14) : Math.random() > 0.6 ? 1 : 0));
    }, 700);
    return () => clearInterval(tick);
  }, []);

  const playCatchVideo = useCallback((rate: number, from = 0) => {
    const v = catchRef.current;
    if (!v) return;
    v.playbackRate = rate;
    try {
      v.currentTime = from;
    } catch {
      /* ignore seek race */
    }
    v.play().catch(() => {});
  }, []);

  const resetCatchClock = useCallback(
    (from = 0, rate = 1) => {
      pendingDropRef.current = false;
      tapArmedRef.current = false;
      progressRef.current = from;
      setShowTapNow(false);
      if (!useSim) {
        playCatchVideo(rate, from);
      } else {
        setSimProgress(from);
      }
    },
    [playCatchVideo, useSim],
  );

  const isRunStarting = useCallback(() => performance.now() < startLockUntilRef.current, []);

  const beginRound = useCallback(
    (nextSpeed: number, lockMs = 220) => {
      pendingDropRef.current = false;
      tapArmedRef.current = false;
      progressRef.current = 0;
      setShowTapNow(false);
      setJuicing(false);
      setSpeed(nextSpeed);
      speedRef.current = nextSpeed;
      startLockUntilRef.current = performance.now() + lockMs;
      setPhaseBoth("playing");
      if (!useSim) {
        playCatchVideo(nextSpeed, 0);
      }
      if (!muted) sound.playCountdown();
    },
    [muted, playCatchVideo, useSim],
  );

  const startRun = useCallback(() => {
    setScore(0);
    scoreRef.current = 0;
    setShareStill(null);
    setJuicing(false);
    resetCatchClock(0, 1);
    beginRound(1, 480);
  }, [beginRound, resetCatchClock]);

  const succeedCatch = useCallback(() => {
    if (phaseRef.current !== "playing") return;
    setShowTapNow(false);
    setPhaseBoth("caught");
    const next = scoreRef.current + 1;
    scoreRef.current = next;
    setScore(next);
    setBest((b) => {
      const hi = Math.max(b, next);
      if (hi !== b) saveBest(hi);
      return hi;
    });
    setLikes((n) => n + 90 + Math.floor(Math.random() * 70));
    setViewers((n) => n + 160 + Math.floor(Math.random() * 220));
    setJuicing(true);
    if (juiceTimerRef.current) window.clearTimeout(juiceTimerRef.current);
    juiceTimerRef.current = window.setTimeout(() => setJuicing(false), JUICE_MS);
    if (!muted) sound.playCatch();
  }, [muted]);

  const holdDropFrame = useCallback(() => {
    const drop = dropRef.current;
    if (drop) {
      drop.pause();
      const hold = Math.max(0, (Number.isFinite(drop.duration) ? drop.duration : 1.45) - 0.05);
      try {
        drop.currentTime = hold;
      } catch {
        /* ignore */
      }
      const sand = captureVideoFrame(drop);
      if (sand && !helmetStillRef.current) helmetStillRef.current = sand;
    }
    setShowTapNow(false);
    setShareStill(helmetStillRef.current);
    setPhaseBoth("failed");
  }, []);

  const startDrop = useCallback(() => {
    if (phaseRef.current === "dropping" || phaseRef.current === "failed") return;
    pendingDropRef.current = false;
    setJuicing(false);
    setShowTapNow(false);
    setViewers((n) => Math.max(420, n - (320 + Math.floor(Math.random() * 280))));
    setPhaseBoth("dropping");
    const live = catchRef.current;
    if (live) live.pause();
    const drop = dropRef.current;
    if (drop) {
      drop.currentTime = 0;
      drop.playbackRate = 1;
      drop.play().catch(() => {});
    }
    if (dropHoldTimerRef.current) window.clearTimeout(dropHoldTimerRef.current);
    dropHoldTimerRef.current = window.setTimeout(holdDropFrame, 1650);
    if (!muted) sound.playDrop();
  }, [holdDropFrame, muted]);

  const failNow = useCallback(() => {
    const live = catchRef.current;
    const t = live && !useSim ? live.currentTime : progressRef.current;
    if (!useSim && t < DROP_CUT_IN) {
      pendingDropRef.current = true;
      return;
    }
    startDrop();
  }, [startDrop, useSim]);

  const handleTap = useCallback(() => {
    const now = performance.now();
    if (now - lastTapRef.current < 200) return;
    lastTapRef.current = now;

    const p = phaseRef.current;
    if (p === "idle" || p === "failed") {
      resetCatchClock(0, 1);
      startRun();
      return;
    }
    if (p !== "playing") return;
    // Swallow leftover events from the start tap. Second+ taps are catch/miss.
    if (now < startLockUntilRef.current) return;
    tapArmedRef.current = true;

    const t = useSim ? progressRef.current : catchRef.current?.currentTime ?? progressRef.current;
    progressRef.current = t;
    if (t >= WINDOW_START && t <= WINDOW_END) {
      succeedCatch();
    } else {
      failNow();
    }
  }, [failNow, resetCatchClock, startRun, succeedCatch, useSim]);

  const onCatchTime = useCallback(() => {
    const v = catchRef.current;
    if (!v) return;
    const t = v.currentTime;
    progressRef.current = t;
    const p = phaseRef.current;

    if (p === "idle") {
      if (t >= 0.32 && t <= 0.72) {
        const shot = captureVideoFrame(v);
        if (shot) helmetStillRef.current = shot;
      }
      if (t >= IDLE_LOOP_END) {
        v.currentTime = 0;
      }
      return;
    }

    if (p === "playing") {
      if (isRunStarting()) {
        setShowTapNow(false);
        return;
      }
      setShowTapNow(!pendingDropRef.current && t >= WINDOW_START && t <= WINDOW_END);
      if (pendingDropRef.current && t >= Math.min(DROP_CUT_IN, WINDOW_START)) {
        startDrop();
        return;
      }
      if (!pendingDropRef.current && t > WINDOW_END) {
        failNow();
      }
    } else {
      setShowTapNow(false);
    }

    if (p === "caught" && t >= LOOP_DURATION - 0.08) {
      const next = Math.min(speedRef.current + SPEED_STEP, SPEED_CAP);
      beginRound(next);
    }
  }, [beginRound, failNow, isRunStarting, startDrop]);

  const onCatchEnded = useCallback(() => {
    if (phaseRef.current === "caught") {
      const next = Math.min(speedRef.current + SPEED_STEP, SPEED_CAP);
      beginRound(next);
    } else if (phaseRef.current === "playing") {
      if (!isRunStarting()) failNow();
    } else if (phaseRef.current === "idle") {
      playCatchVideo(1, 0);
    }
  }, [beginRound, failNow, isRunStarting, playCatchVideo]);

  const onDropEnded = useCallback(() => {
    if (phaseRef.current === "dropping") {
      if (dropHoldTimerRef.current) window.clearTimeout(dropHoldTimerRef.current);
      holdDropFrame();
    }
  }, [holdDropFrame]);

  // Tight clock: timeupdate is too coarse for a 0.5s window at 2.2x.
  useEffect(() => {
    if (useSim) return;
    if (phase !== "playing" && phase !== "caught" && phase !== "idle") return;
    const loop = () => {
      onCatchTime();
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [useSim, phase, onCatchTime]);

  useEffect(() => {
    if (!useSim) return;
    if (phase !== "playing" && phase !== "caught" && phase !== "idle") return;

    let last = performance.now();
    const loop = (now: number) => {
      const dt = ((now - last) / 1000) * (phaseRef.current === "idle" ? 1 : speedRef.current);
      last = now;
      progressRef.current += dt;
      const t = progressRef.current;
      const p = phaseRef.current;
      setSimProgress(t);

      if (p === "idle" && t >= IDLE_LOOP_END) {
        progressRef.current = 0;
      }
      if (p === "playing") {
        if (isRunStarting()) {
          setShowTapNow(false);
        } else {
          setShowTapNow(!pendingDropRef.current && t >= WINDOW_START && t <= WINDOW_END);
          if (pendingDropRef.current && t >= Math.min(DROP_CUT_IN, WINDOW_START)) {
            startDrop();
            return;
          }
          if (!pendingDropRef.current && t > WINDOW_END) {
            startDrop();
            return;
          }
        }
      } else {
        setShowTapNow(false);
      }
      if (p === "caught" && t >= LOOP_DURATION) {
        const next = Math.min(speedRef.current + SPEED_STEP, SPEED_CAP);
        progressRef.current = 0;
        beginRound(next);
        return;
      }
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [useSim, phase, beginRound, isRunStarting, startDrop]);

  useEffect(() => {
    if (phase !== "playing") setShowTapNow(false);
  }, [phase]);

  const showDrop = phase === "dropping" || phase === "failed";
  const roasting = showDrop;
  const rank = rankForScore(score);

  return (
    <div
      className="relative w-full h-[100dvh] overflow-hidden bg-black text-white select-none touch-none"
      data-catch-window={`${WINDOW_START.toFixed(1)}-${WINDOW_END.toFixed(1)}`}
    >
      <div className="absolute inset-0 z-0">
        {useSim ? (
          <BeachSimulation
            progress={simProgress}
            hasCaught={phase === "caught"}
            isFailed={phase === "dropping" || phase === "failed"}
          />
        ) : (
          <motion.div
            className="absolute inset-0"
            animate={juicing ? { scale: [1, 1.22, 1.08] } : { scale: 1 }}
            transition={juicing ? { duration: 0.4, times: [0, 0.36, 1], ease: [0.16, 1, 0.3, 1] } : { duration: 0.18 }}
          >
            <video
              ref={catchRef}
              src={CATCH_SRC}
              className={`absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[124%] h-[124%] max-w-none object-cover ${showDrop ? "opacity-0" : "opacity-100"}`}
              playsInline
              muted={muted}
              autoPlay
              preload="auto"
              loop={false}
              onTimeUpdate={onCatchTime}
              onEnded={onCatchEnded}
              onError={() => setUseSim(true)}
            />
            <video
              ref={dropRef}
              src={DROP_SRC}
              className={`absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[124%] h-[124%] max-w-none object-cover ${showDrop ? "opacity-100" : "opacity-0"}`}
              playsInline
              muted={muted}
              preload="auto"
              onEnded={onDropEnded}
            />
          </motion.div>
        )}
        <div className="absolute inset-x-0 top-0 h-36 bg-gradient-to-b from-black/70 to-transparent pointer-events-none" />
        <div className="absolute inset-x-0 bottom-0 h-48 bg-gradient-to-t from-black/65 to-transparent pointer-events-none" />
      </div>

      <div
        className="absolute inset-0 z-10"
        onPointerUp={(e) => {
          if ((e.target as HTMLElement).closest("[data-chrome]")) return;
          handleTap();
        }}
        onClick={(e) => {
          if ((e.target as HTMLElement).closest("[data-chrome]")) return;
          handleTap();
        }}
      />

      {/* Live stream header */}
      <div className="absolute top-0 inset-x-0 z-20 pt-[max(10px,env(safe-area-inset-top))] px-3 flex items-start justify-between pointer-events-none">
        <div className="flex items-center gap-2 min-w-0">
          <div className="relative shrink-0">
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-amber-400 via-red-600 to-red-800 ring-2 ring-white" />
            <span className="absolute -bottom-1 left-1/2 -translate-x-1/2 text-[8px] font-black tracking-widest bg-red-600 px-1 rounded-[3px] leading-none py-0.5">
              LIVE
            </span>
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              <span className="font-semibold text-[13px] truncate">49ersBeachCatcher</span>
              <span className="text-[10px] font-bold bg-white/15 px-1.5 py-0.5 rounded-md leading-none">
                Follow
              </span>
            </div>
            <p className="text-[10px] text-white/70 truncate">Ocean Beach</p>
          </div>
        </div>

        <div className="flex items-center gap-1.5 pointer-events-auto" data-chrome>
          <div className="flex items-center gap-1 bg-black/50 backdrop-blur-md px-2.5 py-1 rounded-full text-[11px] font-semibold">
            <Eye className="w-3.5 h-3.5 text-white/80" />
            {viewers.toLocaleString()}
          </div>
          <button
            type="button"
            aria-label={muted ? "Unmute" : "Mute"}
            className="p-1.5 rounded-full bg-black/50 backdrop-blur-md"
            onClick={() => setMuted((m) => !m)}
          >
            {muted ? <VolumeX className="w-4 h-4 text-white/80" /> : <Volume2 className="w-4 h-4" />}
          </button>
          <button
            type="button"
            aria-label="Settings"
            className="p-1 rounded-full bg-black/30 text-white/50"
            onClick={() => setSettingsOpen(true)}
          >
            <Settings className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Score chip — chase the title, not the number */}
      <div className="absolute top-[4.6rem] left-3 z-20 pointer-events-none">
        <div className="bg-black/40 backdrop-blur-md rounded-2xl px-3 py-1.5 border border-white/10">
          <p className="text-[10px] uppercase tracking-wider text-amber-300 font-bold">
            {rank ? rank.name : "This run"}
          </p>
          <p className="text-2xl font-black leading-none tabular-nums">{score}</p>
          <p className="text-[10px] text-white/60 mt-0.5">Best {best}</p>
          {speed > 1 && phase !== "idle" && phase !== "failed" && (
            <p className="text-[10px] text-red-300 font-semibold">{speed.toFixed(2)}x</p>
          )}
        </div>
      </div>

      <div className="absolute right-3 bottom-28 z-20 pointer-events-none flex flex-col items-center gap-2">
        <div className={`flex flex-col items-center ${roasting ? "opacity-35 grayscale" : ""}`}>
          <Heart className="w-7 h-7 fill-rose-500 text-rose-500 drop-shadow" />
          <span className="text-[11px] font-semibold mt-0.5">{likes}</span>
        </div>
      </div>

      <FakeChat
        active={phase === "playing" || phase === "caught" || roasting}
        roast={roasting}
        rank={rank}
        endScreen={phase === "failed"}
      />
      <LiveReactions
        burst={phase === "caught"}
        detonate={juicing}
        ambient={phase === "playing" || phase === "idle"}
      />
      <CatchJuice juicing={juicing} caught={phase === "caught"} rank={rank} />

      <div className="absolute inset-0 z-30 flex items-center justify-center pointer-events-none">
        <AnimatePresence>
          {phase === "idle" && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="absolute top-[42%] inset-x-0 text-center px-6"
            >
              <p className="text-[11px] tracking-[0.25em] uppercase text-white/70 mb-1">Live · Beach Catch</p>
              <p className="text-xl font-black uppercase tracking-wide drop-shadow-lg">Tap to play along</p>
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence mode="popLayout">
          {showTapNow && phase === "playing" && (
            <motion.div
              key="tap-now"
              initial={{ opacity: 0, scale: 0.82 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.92, transition: { duration: 0.1 } }}
              className="absolute top-[38%] inset-x-0 text-center z-40 pointer-events-none"
            >
              <p
                className="tap-now-pulse text-6xl sm:text-7xl font-black text-amber-300 uppercase tracking-widest drop-shadow-[0_4px_24px_rgba(251,191,36,0.95)]"
                style={{ WebkitTextStroke: "2px #000" }}
              >
                TAP NOW
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {roasting && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="absolute top-[26%] inset-x-0 text-center px-6"
            >
              <h2
                className="text-5xl font-black text-red-500 uppercase tracking-tight drop-shadow-xl"
                style={{ WebkitTextStroke: "1px #450a0a" }}
              >
                Dropped
              </h2>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {phase === "failed" && (
        <>
          <div className="absolute inset-x-0 top-[30%] z-40 flex flex-col items-center pointer-events-none">
            <ShareCard still={shareStill} score={score} />
          </div>
          <p className="absolute inset-x-0 bottom-[5.5rem] z-50 text-center text-[11px] font-semibold tracking-[0.18em] uppercase text-white/95 pointer-events-none drop-shadow-[0_2px_8px_rgba(0,0,0,0.9)]">
            Tap anywhere to retry
          </p>
        </>
      )}

      <AnimatePresence>
        {settingsOpen && (
          <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-end sm:items-center justify-center p-4" data-chrome>
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 24 }}
              className="bg-neutral-900 border border-white/15 rounded-3xl p-5 w-full max-w-sm"
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold">Settings</h3>
                <button type="button" aria-label="Close settings" onClick={() => setSettingsOpen(false)}>
                  <X className="w-5 h-5" />
                </button>
              </div>
              <p className="text-xs text-white/60 leading-relaxed">
                Source: <span className="text-white/90">public/{CATCH_VIDEO}</span>
                <br />
                Catch window: {WINDOW_START.toFixed(2)}s – {WINDOW_END.toFixed(2)}s
                <br />
                Round length: {LOOP_DURATION.toFixed(2)}s
              </p>
              <button
                type="button"
                className="mt-4 w-full py-2.5 rounded-xl bg-white/10 text-sm font-semibold"
                onClick={() => {
                  saveBest(0);
                  setBest(0);
                }}
              >
                Reset best run
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
