import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import path from "path";
import { defineConfig, Plugin } from "vite";

const INDEX_PAGE_URL = "https://bparlette.github.io/Aistudio/";
const PLAY_PAGE_URL = "https://bparlette.github.io/Aistudio/play.html";

function omitIphoneMov(): Plugin {
  return {
    name: "omit-iphone-mov",
    closeBundle() {
      const mov = path.resolve(__dirname, "dist/game-video.mov");
      if (fs.existsSync(mov)) fs.unlinkSync(mov);
    },
  };
}

/** Copy index.html to play.html so X can scrape an uncached share URL. */
function emitPlayHtml(): Plugin {
  return {
    name: "emit-play-html",
    closeBundle() {
      const index = path.resolve(__dirname, "dist/index.html");
      const dest = path.resolve(__dirname, "dist/play.html");
      if (!fs.existsSync(index)) return;
      const source = fs.readFileSync(index, "utf8");
      const needle = `property="og:url" content="${INDEX_PAGE_URL}"`;
      if (!source.includes(needle)) {
        throw new Error("emit-play-html: og:url on index.html did not match");
      }
      fs.writeFileSync(
        dest,
        source.replace(needle, `property="og:url" content="${PLAY_PAGE_URL}"`),
      );
    },
  };
}

export default defineConfig(({ command, isPreview }) => ({
  // Project Pages URL: https://bparlette.github.io/Aistudio/
  base: command === "build" || isPreview ? "/Aistudio/" : "/",
  plugins: [react(), tailwindcss(), omitIphoneMov(), emitPlayHtml()],
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
