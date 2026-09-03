import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import path from "path";
import { defineConfig, Plugin } from "vite";

function omitIphoneMov(): Plugin {
  return {
    name: "omit-iphone-mov",
    closeBundle() {
      const mov = path.resolve(__dirname, "dist/game-video.mov");
      if (fs.existsSync(mov)) fs.unlinkSync(mov);
    },
  };
}

export default defineConfig(({ command }) => ({
  // Project Pages URL: https://bparlette.github.io/Aistudio/
  base: command === "build" ? "/Aistudio/" : "/",
  plugins: [react(), tailwindcss(), omitIphoneMov()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
  server: {
    hmr: process.env.DISABLE_HMR !== "true",
    watch: process.env.DISABLE_HMR === "true" ? null : {},
  },
}));
