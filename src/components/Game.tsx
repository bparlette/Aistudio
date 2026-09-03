import React, { useState, useEffect, useRef, useCallback } from "react";
import { LiveReactions } from "./LiveReactions";
import { BeachSimulation } from "./BeachSimulation";
import { sound } from "../lib/audio";
import { motion, AnimatePresence } from "motion/react";
import { 
  Eye, 
  User, 
  Upload, 
  Settings, 
  X, 
  Volume2, 
  VolumeX, 
  Flame, 
  CheckCircle2, 
  AlertCircle,
  Video,
  Sparkles,
  Trophy
} from "lucide-react";

export type GameState = "IDLE" | "PLAYING" | "FAILED";
export type VideoMode = "simulation" | "uploaded" | "github" | "youtube";

function FakeLiveChat({ active }: { active: boolean }) {
  const [messages, setMessages] = useState<{ id: number; user: string; text: string }[]>([]);
  const USERS = ["nfl_fan99", "bro_what", "49ersFaithful", "speedyz", "user10293", "jimmy_g", "beast_mode88"];
  const TEXTS = [
    "bro is fast 🏃‍♂️💨", "helmet at the beach crazy 😂", "He's gonna drop it", 
    "W catch incoming", "hands like glue!", "SF 49ers sign this man", 
    "W stream", "tap the screen yall!", "too easy for him", 
    "oakley visor is clean 🔥", "he got hands tho", "LET'S GOOO 🏈"
  ];

  useEffect(() => {
    if (!active) {
      setMessages([]);
      return;
    }
    const interval = setInterval(() => {
      if (Math.random() > 0.35) {
        setMessages((prev) => {
          const newMsg = {
            id: Date.now(),
            user: USERS[Math.floor(Math.random() * USERS.length)],
            text: TEXTS[Math.floor(Math.random() * TEXTS.length)],
          };
          return [...prev, newMsg].slice(-5);
        });
      }
    }, 550);
    return () => clearInterval(interval);
  }, [active]);

  return (
    <div className="absolute bottom-6 left-4 z-20 w-64 h-48 overflow-hidden flex flex-col justify-end pointer-events-none">
      <AnimatePresence>
        {messages.map((m) => (
          <motion.div
            key={m.id}
            initial={{ opacity: 0, x: -20, scale: 0.9 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="mb-1.5 text-xs text-white drop-shadow bg-black/50 p-2 rounded-xl backdrop-blur-md w-fit max-w-[210px] leading-tight border border-white/10"
          >
            <span className="font-bold text-amber-400 mr-1.5">{m.user}:</span>
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
  const [streak, setStreak] = useState(0);
  const [speedMultiplier, setSpeedMultiplier] = useState(1);
  const [audioEnabled, setAudioEnabled] = useState(true);
  
  // Video Source Management
  const [videoMode, setVideoMode] = useState<VideoMode>("simulation");
  const [uploadedVideoUrl, setUploadedVideoUrl] = useState<string | null>(null);
  const [uploadedFileName, setUploadedFileName] = useState<string>("");
  const [isUploading, setIsUploading] = useState(false);
  const [uploadMessage, setUploadMessage] = useState<string>("");
  
  const [githubUrl, setGithubUrl] = useState<string>(
    "https://raw.githubusercontent.com/bparlette/Aistudio/main/ScreenRecording_09-02-2026%2022-08-41_1.mov"
  );
  const [githubStatus, setGithubStatus] = useState<"idle" | "testing" | "ok" | "error">("idle");
  const [githubErrorMessage, setGithubErrorMessage] = useState<string>("");

  // Timing Configuration (seconds) calibrated to the beach video
  const [windowStart, setWindowStart] = useState<number>(2.2);
  const [windowEnd, setWindowEnd] = useState<number>(3.3);
  const [loopDuration, setLoopDuration] = useState<number>(5.9);

  const [hasCaughtThisRound, setHasCaughtThisRound] = useState(false);
  const [showTapHint, setShowTapHint] = useState(false);
  const [currentProgress, setCurrentProgress] = useState(0);
  const [showSettings, setShowSettings] = useState(false);

  // Check if hosted video already exists on server on startup
  useEffect(() => {
    fetch("/api/video-status")
      .then((res) => res.json())
      .then((data) => {
        if (data.exists && data.url) {
          setUploadedVideoUrl(data.url);
          setUploadedFileName("ScreenRecording_09-02-2026.mp4 (Hosted)");
          setVideoMode("uploaded");
          setWindowStart(2.2);
          setWindowEnd(3.3);
          setLoopDuration(5.9);
          setUploadMessage("✓ Official 49ers Beach Video loaded and hosted with app");
        }
      })
      .catch(() => {});
  }, []);

  // References
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const animFrameRef = useRef<number | null>(null);
  const roundStartTimeRef = useRef<number>(0);
  const progressRef = useRef<number>(0);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Stop / start animation loop
  const stopLoop = () => {
    if (animFrameRef.current) {
      cancelAnimationFrame(animFrameRef.current);
      animFrameRef.current = null;
    }
  };

  // Handle successful catch
  const handleCatch = useCallback(() => {
    if (hasCaughtThisRound) return;
    setHasCaughtThisRound(true);
    setScore((s) => {
      const next = s + 1;
      setHighScore((h) => Math.max(h, next));
      return next;
    });
    setStreak((st) => st + 1);
    setShowTapHint(false);

    if (audioEnabled) {
      sound.playCatch();
    }
  }, [hasCaughtThisRound, audioEnabled]);

  // Handle drop / fail
  const handleFail = useCallback(() => {
    stopLoop();
    setGameState("FAILED");
    setStreak(0);
    setShowTapHint(false);

    if (videoRef.current) {
      videoRef.current.pause();
    }

    if (audioEnabled) {
      sound.playDrop();
    }

    // Auto reset to IDLE after 2.5s
    setTimeout(() => {
      setGameState("IDLE");
      setHasCaughtThisRound(false);
      setCurrentProgress(0);
      progressRef.current = 0;
      if (videoRef.current) {
        videoRef.current.currentTime = 0;
      }
    }, 2500);
  }, [audioEnabled]);

  // Advance to next round
  const startNextRound = useCallback(() => {
    setHasCaughtThisRound(false);
    setSpeedMultiplier((prev) => Math.min(prev + 0.12, 2.2));
    roundStartTimeRef.current = performance.now();
    setCurrentProgress(0);
    progressRef.current = 0;

    if (videoRef.current) {
      videoRef.current.currentTime = 0;
      videoRef.current.playbackRate = Math.min(speedMultiplier + 0.12, 2.2);
      videoRef.current.play().catch(() => {});
    }
  }, [speedMultiplier]);

  // Simulation tick loop
  useEffect(() => {
    if (gameState !== "PLAYING" || (videoMode !== "simulation" && videoMode !== "youtube")) {
      return;
    }

    roundStartTimeRef.current = performance.now();

    const loop = () => {
      const now = performance.now();
      const elapsed = ((now - roundStartTimeRef.current) / 1000) * speedMultiplier;
      progressRef.current = elapsed;
      setCurrentProgress(elapsed);

      // Check tap window
      if (elapsed >= windowStart && elapsed <= windowEnd && !hasCaughtThisRound) {
        setShowTapHint(true);
      } else {
        setShowTapHint(false);
      }

      // Passed catch window without tapping
      if (elapsed > windowEnd && !hasCaughtThisRound) {
        handleFail();
        return;
      }

      // Reached loop end after successful catch -> Next Round
      if (elapsed >= loopDuration && hasCaughtThisRound) {
        startNextRound();
      }

      animFrameRef.current = requestAnimationFrame(loop);
    };

    animFrameRef.current = requestAnimationFrame(loop);

    return () => stopLoop();
  }, [gameState, videoMode, speedMultiplier, windowStart, windowEnd, loopDuration, hasCaughtThisRound, handleFail, startNextRound]);

  // Video element timeupdate handler (for local or github video files)
  const handleVideoTimeUpdate = () => {
    if (!videoRef.current || gameState !== "PLAYING") return;
    const time = videoRef.current.currentTime;
    progressRef.current = time;
    setCurrentProgress(time);

    if (time >= windowStart && time <= windowEnd && !hasCaughtThisRound) {
      setShowTapHint(true);
    } else {
      setShowTapHint(false);
    }

    if (time > windowEnd && !hasCaughtThisRound) {
      handleFail();
    }
  };

  const handleVideoEnded = () => {
    if (hasCaughtThisRound) {
      startNextRound();
    } else {
      handleFail();
    }
  };

  // Start the game
  const startGame = () => {
    setScore(0);
    setStreak(0);
    setSpeedMultiplier(1);
    setHasCaughtThisRound(false);
    setShowTapHint(false);
    setCurrentProgress(0);
    progressRef.current = 0;
    setGameState("PLAYING");

    if (videoRef.current) {
      videoRef.current.currentTime = 0;
      videoRef.current.playbackRate = 1;
      videoRef.current.play().catch(() => {});
    }

    if (audioEnabled) {
      sound.playCountdown();
    }
  };

  // Tap handler
  const handleTap = (e: React.MouseEvent | React.TouchEvent) => {
    e.stopPropagation();

    if (gameState === "IDLE") {
      startGame();
    } else if (gameState === "PLAYING") {
      const p = progressRef.current;
      if (p >= windowStart && p <= windowEnd) {
        handleCatch();
      } else {
        handleFail();
      }
    }
  };

  // File Upload Handlers (for .mov or .mp4)
  const handleFileUpload = async (file: File) => {
    if (!file) return;
    // 1. Play immediately via local object URL for instant zero-lag response
    const localUrl = URL.createObjectURL(file);
    setUploadedVideoUrl(localUrl);
    setUploadedFileName(file.name);
    setVideoMode("uploaded");
    setWindowStart(2.0);
    setWindowEnd(3.2);
    setLoopDuration(4.5);
    setShowSettings(false);

    // 2. Persist to server filesystem so it remains forever across reloads
    setIsUploading(true);
    setUploadMessage("Saving video to project filesystem...");
    try {
      const res = await fetch("/api/upload-video", {
        method: "POST",
        body: file,
      });
      const data = await res.json();
      if (data.success) {
        setIsUploading(false);
        setUploadMessage("✓ Video permanently saved to project (/game-video.mov)!");
      } else {
        setIsUploading(false);
        setUploadMessage("Local playback active (Server save: " + (data.error || "error") + ")");
      }
    } catch {
      setIsUploading(false);
      setUploadMessage("Local playback active.");
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  };

  // GitHub Pull / Downloader Handler
  const pullFromGithub = async () => {
    setGithubStatus("testing");
    setGithubErrorMessage("");
    try {
      const res = await fetch("/api/pull-github", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url: githubUrl }),
      });
      const data = await res.json();
      if (data.success) {
        setGithubStatus("ok");
        setUploadedVideoUrl("/game-video.mov?t=" + Date.now());
        setUploadedFileName("game-video.mov (from GitHub)");
        setVideoMode("uploaded");
        setUploadMessage("✓ Downloaded and saved directly from GitHub!");
      } else {
        setGithubStatus("error");
        if (data.error?.includes("404")) {
          setGithubErrorMessage(
            "GitHub returned 404 (Not Found). Your repository 'bparlette/Aistudio' is currently Private, which prevents external downloads. Either change the repo to Public in GitHub Settings > Danger Zone, or click 'Choose File from Computer' below to upload directly!"
          );
        } else {
          setGithubErrorMessage("Could not download: " + (data.error || "Unknown error"));
        }
      }
    } catch (e: any) {
      setGithubStatus("error");
      setGithubErrorMessage("Connection failed: " + e.message);
    }
  };

  return (
    <div 
      className="relative w-full h-[100dvh] overflow-hidden bg-black text-white font-sans select-none touch-none"
      onDragOver={(e) => e.preventDefault()}
      onDrop={handleDrop}
    >
      {/* Hidden file picker */}
      <input
        ref={fileInputRef}
        type="file"
        accept="video/mp4,video/quicktime,video/mov,video/webm"
        className="hidden"
        onChange={(e) => {
          if (e.target.files?.[0]) {
            handleFileUpload(e.target.files[0]);
          }
        }}
      />

      {/* BACKGROUND MEDIA LAYER */}
      <div className="absolute inset-0 z-0 flex items-center justify-center overflow-hidden">
        {videoMode === "simulation" && (
          <BeachSimulation 
            progress={currentProgress} 
            hasCaught={hasCaughtThisRound}
            isFailed={gameState === "FAILED"}
          />
        )}

        {(videoMode === "uploaded" && uploadedVideoUrl) && (
          <video
            ref={videoRef}
            src={uploadedVideoUrl}
            playsInline
            muted
            onTimeUpdate={handleVideoTimeUpdate}
            onEnded={handleVideoEnded}
            className="w-full h-full object-cover"
          />
        )}

        {videoMode === "github" && (
          <video
            ref={videoRef}
            src={githubUrl}
            playsInline
            muted
            onTimeUpdate={handleVideoTimeUpdate}
            onEnded={handleVideoEnded}
            className="w-full h-full object-cover"
            onError={() => {
              setVideoMode("simulation");
              setGithubErrorMessage("Failed to load GitHub video. Reverted to Beach Simulation.");
            }}
          />
        )}

        {videoMode === "youtube" && (
          <div className="w-full h-full pointer-events-none scale-125">
            <iframe
              src="https://www.youtube-nocookie.com/embed/4RJpXqEGP4Y?autoplay=1&mute=1&controls=0&loop=1&playlist=4RJpXqEGP4Y&playsinline=1"
              title="Beach Catch YouTube"
              className="w-full h-full pointer-events-none"
              allow="autoplay; encrypted-media; picture-in-picture"
            />
          </div>
        )}
      </div>

      {/* FULL SCREEN TAP HITBOX */}
      <div 
        id="tap-hitbox"
        className="absolute inset-0 z-10 cursor-pointer touch-manipulation active:bg-white/5 transition-colors"
        onClick={handleTap}
      />

      {/* TOP STREAM HEADER */}
      <div className="absolute top-0 inset-x-0 z-20 p-4 md:p-6 flex justify-between items-start pointer-events-none">
        
        {/* Streamer Profile Pill */}
        <div className="flex items-center gap-2 bg-black/60 backdrop-blur-md p-1.5 pr-4 rounded-full border border-white/15 shadow-xl">
          <div className="w-10 h-10 bg-gradient-to-tr from-amber-600 via-red-600 to-red-500 rounded-full flex items-center justify-center relative shadow-[0_0_15px_rgba(220,38,38,0.6)]">
            <User className="w-6 h-6 text-white" />
            <div className="absolute -bottom-1 bg-red-600 text-[9px] font-black px-1.5 rounded-sm tracking-widest border border-black uppercase text-white shadow">
              Live
            </div>
          </div>
          <div className="flex flex-col ml-1">
            <span className="font-bold text-sm tracking-wide flex items-center gap-1">
              49ersBeachCatcher
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            </span>
            <span className="text-[11px] text-white/70 font-medium">
              {videoMode === "uploaded" ? "Official Beach Video 🏈" : "Beach Simulation 🏈"}
            </span>
          </div>
        </div>

        {/* Right Controls & Score */}
        <div className="flex flex-col items-end gap-2 pointer-events-auto">
          
          <div className="flex items-center gap-2">
            {/* Viewers Badge */}
            <div className="flex items-center gap-1.5 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/15">
              <Eye className="w-4 h-4 text-red-400" />
              <span className="font-bold text-xs tracking-wider">{(14.2 + score * 0.4).toFixed(1)}K</span>
            </div>

            {/* Audio Toggle */}
            <button
              id="audio-toggle-btn"
              onClick={() => setAudioEnabled(!audioEnabled)}
              className="p-2 bg-black/60 hover:bg-black/80 backdrop-blur-md rounded-full border border-white/15 text-white/80 hover:text-white transition-all shadow"
              title={audioEnabled ? "Mute audio" : "Unmute audio"}
            >
              {audioEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4 text-red-400" />}
            </button>

            {/* Video & Timing Settings Button */}
            <button
              id="settings-btn"
              onClick={() => setShowSettings(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-black/60 hover:bg-black/80 backdrop-blur-md rounded-full border border-white/15 text-xs font-semibold text-white/90 hover:text-white transition-all shadow"
            >
              <Settings className="w-4 h-4 text-amber-400" />
              <span>Source & Timing</span>
            </button>
          </div>

          {/* Live Scorecard */}
          <div className="bg-black/60 backdrop-blur-md px-4 py-2.5 rounded-2xl border border-white/15 text-right shadow-2xl min-w-[130px]">
            <div className="flex items-baseline justify-end gap-1.5">
              <span className="text-xs font-bold text-white/60 uppercase">Score</span>
              <span className="text-3xl font-black text-white leading-none tracking-tight">{score}</span>
            </div>
            
            {streak > 1 && (
              <div className="flex items-center justify-end gap-1 text-xs font-black text-amber-400 mt-1">
                <Flame className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
                <span>{streak} STREAK</span>
              </div>
            )}

            {speedMultiplier > 1 && gameState === "PLAYING" && (
              <p className="text-[11px] font-bold text-red-400 mt-0.5">
                Speed: {speedMultiplier.toFixed(2)}x
              </p>
            )}
          </div>
        </div>
      </div>

      {/* TIMING WINDOW PROGRESS BAR (Active during gameplay) */}
      {gameState === "PLAYING" && (
        <div className="absolute top-20 inset-x-0 z-20 flex flex-col items-center pointer-events-none px-6">
          <div className="w-full max-w-xs h-2 bg-black/60 backdrop-blur-md rounded-full overflow-hidden border border-white/20 relative">
            {/* Target Catch Zone Highlight */}
            <div 
              className="absolute inset-y-0 bg-emerald-500/50 border-x border-emerald-400"
              style={{
                left: `${(windowStart / loopDuration) * 100}%`,
                width: `${((windowEnd - windowStart) / loopDuration) * 100}%`,
              }}
            />
            {/* Current Playhead Needle */}
            <div 
              className="absolute inset-y-0 w-1 bg-white shadow-[0_0_8px_#ffffff]"
              style={{
                left: `${Math.min(100, (currentProgress / loopDuration) * 100)}%`,
              }}
            />
          </div>
          <span className="text-[10px] text-white/70 font-semibold tracking-wider mt-1 uppercase">
            {showTapHint ? "🟢 IN CATCH WINDOW!" : "Catch Window"}
          </span>
        </div>
      )}

      {/* FAKE LIVE CHAT STREAM */}
      <FakeLiveChat active={gameState !== "IDLE"} />

      {/* FLOATING HEARTS & LIKES ON CATCH */}
      <LiveReactions active={hasCaughtThisRound} />

      {/* GAME OVERLAYS */}
      <div className="absolute inset-0 z-30 flex items-center justify-center pointer-events-none">
        
        {/* START SCREEN */}
        <AnimatePresence>
          {gameState === "IDLE" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.05 }}
              className="text-center bg-black/75 p-6 md:p-8 rounded-3xl backdrop-blur-xl border border-white/20 shadow-2xl max-w-sm mx-4 pointer-events-auto"
            >
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-600/30 border border-red-500/40 text-red-300 text-xs font-bold tracking-widest uppercase mb-3">
                <Sparkles className="w-3.5 h-3.5" /> 49ers Beach Edition
              </div>

              <h1 className="text-4xl md:text-5xl font-black text-white uppercase tracking-tight mb-2 drop-shadow-md">
                BEACH CATCH
              </h1>

              <p className="text-sm text-white/80 mb-5 leading-relaxed">
                Watch the runner cut across the sand. Tap the screen the exact millisecond the ball arrives!
              </p>

              {/* High Score */}
              {highScore > 0 && (
                <div className="flex items-center justify-center gap-1.5 text-amber-400 font-bold text-sm mb-3 bg-amber-950/40 py-1.5 px-4 rounded-full border border-amber-500/30 w-fit mx-auto">
                  <Trophy className="w-4 h-4 text-amber-400" />
                  <span>High Score: {highScore}</span>
                </div>
              )}

              {/* Upload Status Banner */}
              {uploadMessage && (
                <div className="mb-4 text-xs font-semibold text-emerald-300 bg-emerald-950/50 p-2.5 rounded-xl border border-emerald-500/30 flex items-center justify-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-400" />
                  <span className="truncate">{uploadMessage}</span>
                </div>
              )}

              {/* Tap to Start Action */}
              <button
                id="start-game-btn"
                onClick={startGame}
                className="w-full bg-gradient-to-r from-red-600 to-amber-600 hover:from-red-500 hover:to-amber-500 text-white py-4 rounded-2xl text-lg font-black uppercase tracking-wider shadow-[0_0_35px_rgba(220,38,38,0.6)] active:scale-95 transition-all mb-3 cursor-pointer"
              >
                Tap to Catch 🏈
              </button>

              {/* Quick Upload Video Shortcut */}
              <div className="flex flex-col gap-2">
                <button
                  id="quick-upload-btn"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isUploading}
                  className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-amber-600/30 hover:bg-amber-600/40 border border-amber-500/40 text-xs font-bold text-amber-200 transition-all cursor-pointer shadow"
                >
                  <Upload className="w-4 h-4 text-amber-400" />
                  <span>{isUploading ? "Uploading to project..." : (uploadedVideoUrl ? "Change Video (.mov / .mp4)" : "Upload Video File (.mov / .mp4)")}</span>
                </button>

                <button
                  onClick={() => setShowSettings(true)}
                  className="w-full flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg bg-white/5 hover:bg-white/10 text-[11px] font-medium text-white/70 hover:text-white transition-all"
                >
                  <Settings className="w-3.5 h-3.5 text-white/60" />
                  <span>GitHub & Timing Settings</span>
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* TAP NOW FLASH HINT */}
        <AnimatePresence>
          {showTapHint && gameState === "PLAYING" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: [1, 1.1, 1] }}
              exit={{ opacity: 0, scale: 1.3 }}
              transition={{ repeat: Infinity, duration: 0.3 }}
              className="absolute bottom-1/3 z-40 text-5xl md:text-7xl font-black text-amber-300 drop-shadow-[0_4px_25px_rgba(245,158,11,0.9)] uppercase tracking-widest stroke-black"
              style={{ WebkitTextStroke: "2.5px black" }}
            >
              TAP NOW!
            </motion.div>
          )}
        </AnimatePresence>

        {/* CATCH CONFIRMATION NOTIFICATION */}
        <AnimatePresence>
          {hasCaughtThisRound && gameState === "PLAYING" && (
            <motion.div
              initial={{ opacity: 0, y: 15, scale: 0.9 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0 }}
              className="absolute top-28 bg-emerald-600/90 text-white px-5 py-2 rounded-full font-black text-lg tracking-wider border border-emerald-400 shadow-2xl flex items-center gap-2"
            >
              <CheckCircle2 className="w-5 h-5" />
              CAUGHT! +1
            </motion.div>
          )}
        </AnimatePresence>

        {/* DROPPED / FAILED POPUP */}
        <AnimatePresence>
          {gameState === "FAILED" && (
            <motion.div
              initial={{ opacity: 0, scale: 0.6 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="text-center absolute z-40 bg-black/85 p-8 rounded-3xl backdrop-blur-xl border border-red-500/40 shadow-2xl"
            >
              <h2 className="text-6xl md:text-7xl font-black text-red-500 uppercase tracking-tight drop-shadow-xl mb-2">
                DROPPED!
              </h2>
              <p className="text-xl text-white/90 font-bold mb-1">
                Final Score: <span className="text-amber-400">{score}</span>
              </p>
              <p className="text-xs text-white/60">
                Resetting live stream...
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* TUMBLING FOOTBALL ON DROP */}
        <AnimatePresence>
          {gameState === "FAILED" && (
            <motion.div
              className="absolute z-50 pointer-events-none"
              initial={{ x: 0, y: "-20vh", scale: 1.1, rotate: 0 }}
              animate={{ y: "55vh", rotate: 420 }}
              transition={{ duration: 1.1, ease: "easeIn" }}
            >
              <div className="w-28 h-16 bg-gradient-to-r from-amber-800 via-amber-700 to-amber-950 rounded-[50%] shadow-2xl relative flex items-center justify-center transform rotate-[-25deg] border border-amber-950">
                <div className="absolute top-1/2 -translate-y-1/2 w-14 h-3 flex items-center justify-between">
                  <div className="w-full h-1 bg-white/90 absolute top-1/2 -translate-y-1/2" />
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="w-1.5 h-full bg-white z-10 rounded-sm" />
                  ))}
                </div>
                <div className="absolute left-2 w-2.5 h-12 bg-white/80 rounded-[50%] rotate-12" />
                <div className="absolute right-2 w-2.5 h-12 bg-white/80 rounded-[50%] -rotate-12" />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* SOURCE & TIMING CONFIGURATION DRAWER / MODAL */}
      <AnimatePresence>
        {showSettings && (
          <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="bg-neutral-900 border border-white/20 rounded-3xl p-6 w-full max-w-md shadow-2xl text-white max-h-[90vh] overflow-y-auto"
            >
              <div className="flex justify-between items-center mb-5 border-b border-white/10 pb-3">
                <h3 className="text-lg font-black uppercase tracking-wider flex items-center gap-2">
                  <Settings className="w-5 h-5 text-amber-400" />
                  Video Source & Timing
                </h3>
                <button
                  onClick={() => setShowSettings(false)}
                  className="p-1.5 rounded-full hover:bg-white/10 text-white/70 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Video Source Picker */}
              <div className="mb-6">
                <label className="text-xs font-bold text-white/70 uppercase mb-2 block tracking-wider">
                  Select Video Mode
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => setVideoMode("simulation")}
                    className={`p-3 rounded-xl border text-left flex flex-col gap-1 transition-all ${
                      videoMode === "simulation" 
                        ? "bg-amber-500/20 border-amber-400 text-white" 
                        : "bg-white/5 border-white/10 text-white/70 hover:bg-white/10"
                    }`}
                  >
                    <span className="text-xs font-bold flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 text-amber-400" /> Beach Simulation
                    </span>
                    <span className="text-[10px] text-white/50">Guaranteed 100% playable</span>
                  </button>

                  <button
                    onClick={() => {
                      if (uploadedVideoUrl) {
                        setVideoMode("uploaded");
                      } else {
                        fileInputRef.current?.click();
                      }
                    }}
                    className={`p-3 rounded-xl border text-left flex flex-col gap-1 transition-all ${
                      videoMode === "uploaded" 
                        ? "bg-amber-500/20 border-amber-400 text-white" 
                        : "bg-white/5 border-white/10 text-white/70 hover:bg-white/10"
                    }`}
                  >
                    <span className="text-xs font-bold flex items-center gap-1.5">
                      <Upload className="w-3.5 h-3.5 text-amber-400" /> Uploaded Video
                    </span>
                    <span className="text-[10px] text-white/50">
                      {uploadedFileName ? uploadedFileName.slice(0, 14) + "..." : "Select .mov / .mp4"}
                    </span>
                  </button>

                  <button
                    onClick={() => setVideoMode("youtube")}
                    className={`p-3 rounded-xl border text-left flex flex-col gap-1 transition-all ${
                      videoMode === "youtube" 
                        ? "bg-amber-500/20 border-amber-400 text-white" 
                        : "bg-white/5 border-white/10 text-white/70 hover:bg-white/10"
                    }`}
                  >
                    <span className="text-xs font-bold flex items-center gap-1.5">
                      <Video className="w-3.5 h-3.5 text-red-500" /> YouTube Embed
                    </span>
                    <span className="text-[10px] text-white/50">Shorts Clip 4RJpXqEGP4Y</span>
                  </button>

                  <button
                    onClick={() => setVideoMode("github")}
                    className={`p-3 rounded-xl border text-left flex flex-col gap-1 transition-all ${
                      videoMode === "github" 
                        ? "bg-amber-500/20 border-amber-400 text-white" 
                        : "bg-white/5 border-white/10 text-white/70 hover:bg-white/10"
                    }`}
                  >
                    <span className="text-xs font-bold flex items-center gap-1.5">
                      <AlertCircle className="w-3.5 h-3.5 text-blue-400" /> GitHub URL
                    </span>
                    <span className="text-[10px] text-white/50">Raw repository file</span>
                  </button>
                </div>
              </div>

              {/* Direct File Picker Upload Box */}
              <div className="mb-6 p-4 rounded-2xl bg-white/5 border border-dashed border-white/20 text-center">
                <Upload className="w-6 h-6 text-amber-400 mx-auto mb-1.5" />
                <p className="text-xs font-semibold text-white/90 mb-1">
                  Drag & Drop <span className="text-amber-400">ScreenRecording_09-02-2026 22-08-41_1.mov</span> here
                </p>
                <p className="text-[11px] text-white/50 mb-3">
                  Plays immediately with hardware acceleration & zero network latency
                </p>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="px-4 py-2 rounded-xl bg-amber-600 hover:bg-amber-500 text-white text-xs font-bold transition-all shadow cursor-pointer"
                >
                  Choose File from Computer
                </button>
              </div>

              {/* GitHub Link & One-Click Downloader */}
              <div className="mb-6 p-4 rounded-2xl bg-white/5 border border-white/10">
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-bold text-white/80 flex items-center gap-1.5">
                    <span>Pull from GitHub Repository</span>
                  </label>
                  <span className="text-[10px] text-amber-400 font-medium">Requires Public Repo</span>
                </div>
                <div className="flex gap-2 mb-2">
                  <input
                    type="text"
                    value={githubUrl}
                    onChange={(e) => setGithubUrl(e.target.value)}
                    className="flex-1 bg-black/50 border border-white/20 rounded-xl px-3 py-2 text-xs text-white/90 focus:outline-none focus:border-amber-400"
                    placeholder="https://github.com/bparlette/Aistudio/..."
                  />
                  <button
                    onClick={pullFromGithub}
                    disabled={githubStatus === "testing"}
                    className="px-3.5 py-2 bg-amber-600 hover:bg-amber-500 disabled:bg-white/10 rounded-xl text-xs font-bold text-white shadow cursor-pointer transition-all"
                  >
                    {githubStatus === "testing" ? "Pulling..." : "Pull & Save"}
                  </button>
                </div>

                <p className="text-[11px] text-white/50 leading-relaxed mb-2">
                  Tip: GitHub gives a 404 if the repo is Private. In GitHub, go to <strong className="text-white/80">Settings &gt; Danger Zone &gt; Change visibility &gt; Make public</strong>, then click Pull &amp; Save!
                </p>

                {githubStatus === "error" && (
                  <div className="mt-2 text-[11px] text-amber-300 bg-amber-950/40 p-3 rounded-xl border border-amber-500/30 leading-relaxed">
                    {githubErrorMessage}
                  </div>
                )}
                {githubStatus === "ok" && (
                  <div className="mt-2 text-[11px] text-emerald-400 bg-emerald-950/40 p-2.5 rounded-xl border border-emerald-500/30 flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>Video pulled from GitHub &amp; saved as /game-video.mov!</span>
                  </div>
                )}
              </div>

              {/* Reaction Timing Calibration */}
              <div className="mb-4">
                <div className="flex justify-between items-center mb-2">
                  <label className="text-xs font-bold text-white/70 uppercase tracking-wider">
                    Catch Window Timing (Seconds)
                  </label>
                  <button
                    onClick={() => {
                      setWindowStart(2.2);
                      setWindowEnd(3.3);
                      setLoopDuration(4.8);
                    }}
                    className="text-[10px] text-amber-400 hover:underline"
                  >
                    Reset Defaults
                  </button>
                </div>

                <div className="space-y-3 bg-white/5 p-3.5 rounded-2xl border border-white/10 text-xs">
                  <div>
                    <div className="flex justify-between text-white/80 mb-1">
                      <span>Window Start:</span>
                      <span className="font-bold text-amber-400">{windowStart.toFixed(1)}s</span>
                    </div>
                    <input
                      type="range"
                      min="0.5"
                      max="4.5"
                      step="0.1"
                      value={windowStart}
                      onChange={(e) => setWindowStart(parseFloat(e.target.value))}
                      className="w-full accent-amber-500"
                    />
                  </div>

                  <div>
                    <div className="flex justify-between text-white/80 mb-1">
                      <span>Window End (Cutoff):</span>
                      <span className="font-bold text-amber-400">{windowEnd.toFixed(1)}s</span>
                    </div>
                    <input
                      type="range"
                      min="1.0"
                      max="5.5"
                      step="0.1"
                      value={windowEnd}
                      onChange={(e) => setWindowEnd(parseFloat(e.target.value))}
                      className="w-full accent-amber-500"
                    />
                  </div>

                  <div>
                    <div className="flex justify-between text-white/80 mb-1">
                      <span>Round Loop Reset:</span>
                      <span className="font-bold text-amber-400">{loopDuration.toFixed(1)}s</span>
                    </div>
                    <input
                      type="range"
                      min="2.5"
                      max="8.0"
                      step="0.1"
                      value={loopDuration}
                      onChange={(e) => setLoopDuration(parseFloat(e.target.value))}
                      className="w-full accent-amber-500"
                    />
                  </div>
                </div>
              </div>

              <button
                onClick={() => setShowSettings(false)}
                className="w-full py-3 bg-amber-600 hover:bg-amber-500 text-white rounded-xl text-xs font-bold uppercase tracking-wider transition-all shadow"
              >
                Save & Close
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
