import React, { useState, useEffect, useRef, useCallback } from "react";
import ReactPlayer from "react-player";
import { LiveReactions } from "./LiveReactions";
import { motion, AnimatePresence } from "motion/react";
import { Eye, User } from "lucide-react";
import { cn } from "../lib/utils";

// ============================================================================
// TIMING CONFIGURATION - ADJUST THESE IF THE CATCH WINDOW FEELS OFF
// ============================================================================
// We estimate the timing based on the new uploaded video. 
// If he catches it too early or late in the video, adjust these numbers!
const TIMING = {
  START: 0,           // When the loop begins
  WINDOW_START: 1.0,  // Seconds into video when tap is allowed
  WINDOW_END: 2.0,    // Seconds into video when tap window closes
  LOOP_END: 2.5       // Seconds into video when the successful round resets
};

// We will use the GitHub raw video link
const VIDEO_URL = "https://github.com/bparlette/Aistudio/raw/main/ScreenRecording_09-02-2026%2022-08-41_1.mov";

export type GameState = "IDLE" | "PLAYING" | "FAILED";

function FakeLiveChat({ active }: { active: boolean }) {
  const [messages, setMessages] = useState<{ id: number; user: string; text: string }[]>([]);
  const USERS = ["nfl_fan99", "bro_what", "49ersFaithful", "speedyz", "user10293", "jimmy_g"];
  const TEXTS = [
    "bro is fast 🏃‍♂️💨", "fraud!! 😂", "He's gonna drop it", 
    "W catch incoming", "nah he tripping", "speed is crazy", 
    "W stream", "hit that like button yall", "too easy", 
    "fake video", "he got hands tho", "LET'S GOOO"
  ];

  useEffect(() => {
    if (!active) return;
    const interval = setInterval(() => {
      if (Math.random() > 0.4) {
        setMessages((prev) => {
          const newMsg = {
            id: Date.now(),
            user: USERS[Math.floor(Math.random() * USERS.length)],
            text: TEXTS[Math.floor(Math.random() * TEXTS.length)],
          };
          return [...prev, newMsg].slice(-5); // Keep last 5 messages
        });
      }
    }, 600);
    return () => clearInterval(interval);
  }, [active]);

  return (
    <div className="absolute bottom-8 left-4 z-20 w-64 h-48 overflow-hidden flex flex-col justify-end pointer-events-none">
      <AnimatePresence>
        {messages.map((m) => (
          <motion.div
            key={m.id}
            initial={{ opacity: 0, x: -20, scale: 0.9 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="mb-2 text-sm text-white drop-shadow-md bg-black/30 p-2 rounded-xl backdrop-blur-sm w-fit max-w-[200px] leading-tight"
          >
            <span className="font-bold text-white/80 mr-2">{m.user}</span>
            <span className="text-white font-medium">{m.text}</span>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

export function Game() {
  const [gameState, setGameState] = useState<GameState>("IDLE");
  const [score, setScore] = useState(0);
  const [highScore, setHighScore] = useState(0);
  const [speedMultiplier, setSpeedMultiplier] = useState(1);
  const [isPlaying, setIsPlaying] = useState(false);
  
  const [hasCaughtThisRound, setHasCaughtThisRound] = useState(false);
  const [showTapHint, setShowTapHint] = useState(false);

  const playerRef = useRef<ReactPlayer>(null);
  const progressRef = useRef<number>(0);

  const startGame = () => {
    setScore(0);
    setSpeedMultiplier(1);
    setHasCaughtThisRound(false);
    setGameState("PLAYING");
    setIsPlaying(true);
    playerRef.current?.seekTo(TIMING.START, "seconds");
  };

  const startNextRound = useCallback(() => {
    setSpeedMultiplier((prev) => Math.min(prev + 0.15, 2.5)); // Cap max speed
    setHasCaughtThisRound(false);
    playerRef.current?.seekTo(TIMING.START, "seconds");
  }, []);

  const handleFail = useCallback(() => {
    setGameState("FAILED");
    setIsPlaying(false); // Pause the video to show drop
    setShowTapHint(false);
    setHighScore((prev) => Math.max(prev, score));

    // Reset back to idle after 3 seconds
    setTimeout(() => {
      setGameState("IDLE");
    }, 3000);
  }, [score]);

  const handleProgress = useCallback(
    (state: { playedSeconds: number }) => {
      progressRef.current = state.playedSeconds;

      if (gameState !== "PLAYING") return;

      const progress = state.playedSeconds;

      // Show the hint if we are in the window and haven't caught it yet
      if (progress >= TIMING.WINDOW_START && progress <= TIMING.WINDOW_END && !hasCaughtThisRound) {
        setShowTapHint(true);
      } else {
        setShowTapHint(false);
      }

      // If we completely passed the window and didn't tap -> FAILED
      if (progress > TIMING.WINDOW_END && !hasCaughtThisRound) {
        handleFail();
      }

      // If we reached the end of the looping clip and we DID catch it -> NEXT ROUND
      if (progress >= TIMING.LOOP_END && hasCaughtThisRound) {
        startNextRound();
      }
    },
    [gameState, hasCaughtThisRound, handleFail, startNextRound]
  );

  const handleTap = () => {
    if (gameState === "IDLE") {
      startGame();
    } else if (gameState === "PLAYING") {
      const progress = progressRef.current;

      if (progress >= TIMING.WINDOW_START && progress <= TIMING.WINDOW_END) {
        // SUCCESSFUL CATCH
        if (!hasCaughtThisRound) {
          setHasCaughtThisRound(true);
          setScore((s) => s + 1);
          setShowTapHint(false);
          // We leave the video playing so it naturally shows the catch!
        }
      } else {
        // TAPPED TOO EARLY OR TOO LATE
        handleFail();
      }
    }
  };

  return (
    <div className="relative w-full h-[100dvh] overflow-hidden bg-black text-white font-sans touch-none select-none">
      
      {/* BACKGROUND VIDEO PLAYER */}
      <div className="absolute inset-0 z-0 flex items-center justify-center overflow-hidden pointer-events-none opacity-80 md:opacity-100">
        <div className="w-[300vw] h-[300vh] md:w-[150vw] md:h-[150vh] flex items-center justify-center pointer-events-none transform scale-100 md:scale-125">
          <ReactPlayer
            ref={playerRef}
            url={VIDEO_URL}
            playing={isPlaying}
            playbackRate={speedMultiplier}
            progressInterval={50} // 50ms granularity for tight reaction windows
            onProgress={handleProgress}
            onEnded={handleFail} // Just in case it runs off the end without looping
            width="100%"
            height="100%"
            controls={false}
            playsinline
            muted // Muted helps with autoplay issues in browsers
          />
        </div>
      </div>

      {/* TAP AREA: Covers everything to capture clicks safely */}
      <div 
        className="absolute inset-0 z-10 cursor-pointer touch-manipulation" 
        onClick={handleTap} 
      />

      {/* LIVE STREAM UI OVERLAY */}
      <div className="absolute inset-0 z-20 pointer-events-none flex flex-col justify-between p-4 md:p-8">
        
        {/* Top Header Area */}
        <div className="flex justify-between items-start">
          <div className="flex items-center gap-2 bg-black/40 backdrop-blur-md p-1.5 pr-4 rounded-full border border-white/10">
            <div className="w-10 h-10 bg-red-600 rounded-full flex items-center justify-center relative shadow-[0_0_15px_rgba(220,38,38,0.5)]">
              <User className="w-6 h-6 text-white" />
              <div className="absolute -bottom-1 bg-red-600 text-[10px] font-black px-1.5 rounded-sm tracking-widest border border-black uppercase">
                Live
              </div>
            </div>
            <div className="flex flex-col ml-1">
              <span className="font-bold text-sm leading-tight">49ersFraud</span>
              <span className="text-xs text-white/70 font-medium">Beach Vibes 🏈</span>
            </div>
          </div>
          
          <div className="flex flex-col items-end gap-2">
            <div className="flex items-center gap-1.5 bg-black/40 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/10">
              <Eye className="w-4 h-4 text-white/90" />
              <span className="font-bold text-sm">{(12.4 + score * 0.3).toFixed(1)}K</span>
            </div>
            <div className="text-right bg-black/40 backdrop-blur-md px-4 py-2 rounded-2xl border border-white/10 mt-2">
              <p className="text-2xl font-black uppercase text-white drop-shadow-md">Score: {score}</p>
              {speedMultiplier > 1 && gameState === "PLAYING" && (
                <p className="text-yellow-400 font-bold text-sm">Speed: {speedMultiplier.toFixed(1)}x</p>
              )}
            </div>
          </div>
        </div>

      </div>

      {/* CHAT OVERLAY */}
      <FakeLiveChat active={gameState !== "IDLE"} />

      {/* HEARTS/REACTIONS (Only active on successful catch) */}
      <LiveReactions active={hasCaughtThisRound} />

      {/* GAME OVERLAYS */}
      <div className="absolute inset-0 z-30 flex items-center justify-center pointer-events-none">
        
        {/* Start Screen */}
        <AnimatePresence>
          {gameState === "IDLE" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.1 }}
              className="text-center bg-black/50 p-8 rounded-3xl backdrop-blur-md border border-white/10 shadow-2xl"
            >
              <h1 className="text-6xl font-black text-white uppercase tracking-tighter mb-2 drop-shadow-lg">
                Live Catch
              </h1>
              <p className="text-xl text-white/80 mb-6 max-w-sm mx-auto">
                Wait for the exact moment. Tap the screen to catch the ball. Don't tap early!
              </p>
              {highScore > 0 && (
                <p className="text-yellow-400 font-bold text-xl mb-6 uppercase tracking-widest">
                  High Score: {highScore}
                </p>
              )}
              <div className="bg-red-600 text-white px-10 py-4 rounded-full text-2xl font-bold uppercase tracking-widest shadow-[0_0_40px_rgba(220,38,38,0.6)]">
                Tap anywhere to start
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Drop / Game Over Screen */}
        <AnimatePresence>
          {gameState === "FAILED" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.5 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="text-center absolute z-40 bg-black/60 p-8 rounded-3xl backdrop-blur-md border border-red-500/30"
            >
              <h2 className="text-7xl font-black text-red-500 uppercase tracking-tighter drop-shadow-xl mb-2">
                DROPPED!
              </h2>
              <p className="text-2xl text-white font-bold drop-shadow-md">
                Final Score: {score}
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Tap Hint */}
        <AnimatePresence>
          {showTapHint && gameState === "PLAYING" && (
            <motion.div
              initial={{ opacity: 0, y: 20, scale: 0.8 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, scale: 1.2 }}
              className="absolute bottom-1/3 text-6xl font-black text-white drop-shadow-[0_4px_10px_rgba(0,0,0,1)] uppercase tracking-widest stroke-black"
              style={{ WebkitTextStroke: "2px black" }}
            >
              TAP NOW!
            </motion.div>
          )}
        </AnimatePresence>

        {/* The Falling Football (Drop Animation) */}
        <AnimatePresence>
          {gameState === "FAILED" && (
            <motion.div
              className="absolute z-50 pointer-events-none"
              initial={{ x: 0, y: "-20vh", scale: 1.2, rotate: 0 }} // Center screen
              animate={{ 
                  y: "60vh", 
                  rotate: 360,
              }}
              transition={{ duration: 1.2, ease: "easeIn" }}
            >
              <div className="w-32 h-20 bg-gradient-to-r from-amber-800 via-amber-700 to-amber-900 rounded-[50%] shadow-2xl relative flex items-center justify-center transform rotate-[-20deg]">
                <div className="absolute top-1/2 -translate-y-1/2 w-16 h-3 flex items-center justify-between">
                  <div className="w-full h-1 bg-white/80 absolute top-1/2 -translate-y-1/2"></div>
                  {[1,2,3,4,5].map(i => (
                    <div key={i} className="w-2 h-full bg-white/90 z-10 rounded-sm"></div>
                  ))}
                </div>
                <div className="absolute left-2 w-3 h-14 bg-white/80 rounded-[50%] rotate-12"></div>
                <div className="absolute right-2 w-3 h-14 bg-white/80 rounded-[50%] -rotate-12"></div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
