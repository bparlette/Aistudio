import React from "react";
import { motion } from "motion/react";

interface BeachSimulationProps {
  progress: number; // Current seconds in round (0 to loop duration)
  hasCaught: boolean;
  isFailed: boolean;
}

export function BeachSimulation({ progress, hasCaught, isFailed }: BeachSimulationProps) {
  // Cycle timing:
  // 0.0 - 1.5: Running towards camera on sand
  // 1.5 - 2.8: Hard cut towards ocean (left/right)
  // 2.8 - 4.0: Catch window (ball comes in from top)
  // 4.0+: Catch follow-through or drop

  // Calculate runner position based on progress
  const runPhase = Math.min(progress, 4.5);
  
  // Cut direction
  let runnerX = 0;
  let runnerScale = 1;
  let runnerRotation = 0;
  let isCutting = false;

  if (runPhase < 1.5) {
    // Running straight forward towards camera
    const p = runPhase / 1.5;
    runnerX = -20 + p * 10;
    runnerScale = 0.85 + p * 0.45;
    runnerRotation = Math.sin(runPhase * 12) * 4;
  } else if (runPhase < 2.8) {
    // Sharp cut towards ocean (moves right)
    isCutting = true;
    const p = (runPhase - 1.5) / 1.3;
    runnerX = -10 + p * 90;
    runnerScale = 1.3 - p * 0.25;
    runnerRotation = -15 + Math.sin(runPhase * 12) * 5;
  } else {
    // Running deep down the beach toward water
    const p = (runPhase - 2.8) / 1.7;
    runnerX = 80 + p * 60;
    runnerScale = 1.05 - p * 0.3;
    runnerRotation = -8 + Math.sin(runPhase * 10) * 3;
  }

  // Ball trajectory: arrives between 2.6s and 3.8s
  const ballProgress = Math.max(0, Math.min(1, (progress - 2.2) / 1.4));
  const ballVisible = progress >= 2.2;
  const ballX = 140 - ballProgress * 70;
  const ballY = -60 + Math.sin(ballProgress * Math.PI * 0.9) * 180 + ballProgress * 80;

  return (
    <div className="absolute inset-0 overflow-hidden bg-gradient-to-b from-sky-400 via-sky-200 to-amber-100 select-none pointer-events-none">
      {/* Sky & Sun */}
      <div className="absolute top-8 right-16 w-28 h-28 bg-yellow-100 rounded-full blur-xl opacity-80" />
      <div className="absolute top-12 right-20 w-16 h-16 bg-yellow-300 rounded-full shadow-[0_0_50px_rgba(253,224,71,0.8)]" />

      {/* Ocean in background */}
      <div className="absolute top-[32%] left-0 right-0 h-[22%] bg-gradient-to-b from-blue-700 via-teal-600 to-cyan-500 overflow-hidden">
        {/* Ocean Waves */}
        <div className="absolute inset-x-0 bottom-0 h-4 bg-white/40 blur-xs animate-pulse" />
        <div className="absolute inset-x-0 bottom-2 h-1 bg-white/60" />
        <div className="absolute inset-x-0 top-1/2 h-[1px] bg-white/20" />
      </div>

      {/* Lifeguard Tower on Horizon */}
      <div className="absolute top-[28%] left-[12%] z-5 opacity-70 transform scale-75">
        <div className="w-10 h-10 bg-cyan-100 border-2 border-cyan-800 rounded-sm relative">
          <div className="absolute -top-3 left-1/2 -translate-x-1/2 w-14 h-3 bg-cyan-800 rounded-t-sm" />
          <div className="absolute inset-x-1 top-1 h-3 bg-sky-200 border border-cyan-800" />
        </div>
        {/* Stilts */}
        <div className="w-1 h-8 bg-cyan-900 absolute left-1 top-10" />
        <div className="w-1 h-8 bg-cyan-900 absolute right-1 top-10" />
      </div>

      {/* Beach Sand */}
      <div className="absolute top-[48%] inset-x-0 bottom-0 bg-gradient-to-b from-[#e5c596] via-[#d6b27e] to-[#bfa068] shadow-inner">
        {/* Sand texture lines */}
        <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#855b27_1px,transparent_1px)] [background-size:16px_16px]" />
        
        {/* Orange Cones on Sand */}
        <div className="absolute top-[18%] left-[30%] transform -translate-x-1/2 scale-75">
          <div className="w-0 h-0 border-l-[10px] border-l-transparent border-r-[10px] border-r-transparent border-b-[24px] border-b-orange-600 relative">
            <div className="absolute top-2 -left-[6px] w-3 h-1.5 bg-white/90" />
          </div>
          <div className="w-6 h-1.5 bg-orange-700 rounded-sm -mt-0.5 -ml-1" />
        </div>

        <div className="absolute top-[28%] right-[22%] transform -translate-x-1/2 scale-90">
          <div className="w-0 h-0 border-l-[12px] border-l-transparent border-r-[12px] border-r-transparent border-b-[28px] border-b-orange-600 relative">
            <div className="absolute top-2.5 -left-[7px] w-3.5 h-2 bg-white/90" />
          </div>
          <div className="w-7 h-2 bg-orange-700 rounded-sm -mt-0.5 -ml-0.5" />
        </div>
      </div>

      {/* ATHLETE: RUNNER ON THE BEACH */}
      <div
        className="absolute z-10 transition-transform duration-75 ease-out"
        style={{
          top: "42%",
          left: `calc(50% + ${runnerX}px)`,
          transform: `translate(-50%, -30%) scale(${runnerScale}) rotate(${runnerRotation}deg)`,
        }}
      >
        {/* Runner Shadow */}
        <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 w-28 h-6 bg-black/25 rounded-full blur-xs" />

        {/* Athlete Silhouette & Gear */}
        <div className="relative flex flex-col items-center">
          
          {/* 49ers HELMET */}
          <div className="relative z-20">
            {/* Gold Helmet Shell */}
            <div className="w-20 h-20 rounded-[45%] bg-gradient-to-br from-[#ffd700] via-[#c5a059] to-[#8a6828] border-2 border-[#5c4314] shadow-md relative overflow-hidden flex items-center justify-center">
              {/* Red & White Center Striping */}
              <div className="absolute inset-y-0 w-4 bg-red-700 left-1/2 -translate-x-1/2 border-x border-white" />
              
              {/* SF Logo Area */}
              <div className="absolute right-2 top-4 w-4 h-3 bg-red-700 rounded-full border border-white flex items-center justify-center">
                <span className="text-[6px] font-black text-white italic">SF</span>
              </div>
            </div>

            {/* Red Chrome Reflective Visor (Oakley style) */}
            <div className="absolute top-7 -left-1 w-20 h-8 rounded-b-xl bg-gradient-to-r from-red-600 via-amber-500 to-red-700 border-t-2 border-black shadow-[0_2px_8px_rgba(239,68,68,0.7)] flex items-center justify-center overflow-hidden transform -rotate-3">
              {/* Chrome visor shine reflection */}
              <div className="w-24 h-2 bg-white/60 transform -rotate-12 translate-y-1" />
            </div>

            {/* White Facemask Grill */}
            <div className="absolute top-11 -left-1 w-22 h-6 border-b-4 border-l-4 border-r-4 border-white/90 rounded-b-lg">
              <div className="w-full h-1 bg-white/90 mt-1" />
            </div>
          </div>

          {/* ATHLETE BODY (Bare skin back / shoulders) */}
          <div className="relative z-10 -mt-2 flex flex-col items-center">
            {/* Shoulders & Traps */}
            <div className="w-32 h-14 bg-[#7a4f32] rounded-t-3xl shadow-md border-t border-[#966341] relative flex justify-between px-3 pt-2">
              {/* Left Arm */}
              <motion.div 
                animate={{ rotate: isCutting ? [15, -25, 15] : [-30, 30, -30] }}
                transition={{ repeat: Infinity, duration: 0.5, ease: "linear" }}
                className="w-5 h-20 bg-[#7a4f32] rounded-full origin-top -ml-2 shadow-sm"
              />
              
              {/* Right Arm (Reaches up during catch window!) */}
              <motion.div 
                animate={
                  progress >= 2.8 && !isFailed
                    ? { rotate: -120, y: -15 } // Reaching up to catch!
                    : { rotate: isCutting ? [-25, 20, -25] : [30, -30, 30] }
                }
                transition={{ duration: 0.2 }}
                className="w-5 h-20 bg-[#7a4f32] rounded-full origin-top -mr-2 shadow-sm"
              />
            </div>

            {/* Torso */}
            <div className="w-24 h-16 bg-[#684127] rounded-b-lg relative -mt-4" />

            {/* Nike Black Pro Athletic Shorts */}
            <div className="w-26 h-18 bg-neutral-900 rounded-b-xl border-t-4 border-neutral-700 flex justify-between px-2 pt-1 shadow-md -mt-1">
              <div className="w-9 h-14 bg-neutral-900 rounded-b-lg border-b border-neutral-800" />
              <div className="w-9 h-14 bg-neutral-900 rounded-b-lg border-b border-neutral-800" />
            </div>

            {/* Bare legs & feet churning sand */}
            <div className="w-24 flex justify-between px-3 -mt-2">
              <motion.div 
                animate={{ y: [0, -12, 0], rotate: [-5, 10, -5] }}
                transition={{ repeat: Infinity, duration: 0.35, ease: "easeInOut" }}
                className="w-5 h-16 bg-[#7a4f32] rounded-b-md"
              />
              <motion.div 
                animate={{ y: [-12, 0, -12], rotate: [10, -5, 10] }}
                transition={{ repeat: Infinity, duration: 0.35, ease: "easeInOut" }}
                className="w-5 h-16 bg-[#7a4f32] rounded-b-md"
              />
            </div>

            {/* Sand kicking up behind feet */}
            <motion.div 
              animate={{ opacity: [0.3, 0.8, 0.3], scale: [0.8, 1.3, 0.8] }}
              transition={{ repeat: Infinity, duration: 0.25 }}
              className="absolute -bottom-4 -left-6 w-16 h-8 bg-amber-200/50 rounded-full blur-xs"
            />
          </div>
        </div>
      </div>

      {/* FLYING FOOTBALL */}
      {ballVisible && (
        <motion.div
          className="absolute z-30 pointer-events-none"
          style={{
            top: `${ballY}px`,
            left: `calc(50% + ${ballX}px)`,
          }}
        >
          {/* Football graphic */}
          <div className="w-12 h-7 bg-gradient-to-r from-amber-900 via-amber-700 to-amber-950 rounded-[50%] shadow-lg relative flex items-center justify-center transform -rotate-12 border border-amber-950">
            {/* Laces */}
            <div className="w-6 h-1.5 bg-white/90 relative flex items-center justify-center">
              <div className="w-full h-0.5 bg-white absolute top-1/2 -translate-y-1/2" />
              <div className="w-0.5 h-2 bg-neutral-900 mx-0.5 z-10" />
              <div className="w-0.5 h-2 bg-neutral-900 mx-0.5 z-10" />
              <div className="w-0.5 h-2 bg-neutral-900 mx-0.5 z-10" />
            </div>
            {/* White tip stripes */}
            <div className="absolute left-1 w-1.5 h-5 bg-white/80 rounded-[50%]" />
            <div className="absolute right-1 w-1.5 h-5 bg-white/80 rounded-[50%]" />
          </div>
        </motion.div>
      )}

      {/* Sand Dust Storm Particle Overlay */}
      <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-t from-amber-200/20 to-transparent pointer-events-none" />
    </div>
  );
}
