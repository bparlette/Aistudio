import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import path from "path";
import { defineConfig, Plugin } from "vite";

const INDEX_PAGE_URL = "https://bparlette.github.io/Aistudio/";
const PLAY_PAGE_URL = "https://bparlette.github.io/Aistudio/play.html";
const TAP_PAGE_URL = "https://bparlette.github.io/Aistudio/tap.html";

function omitIphoneMov(): Plugin {
  return {
    name: "omit-iphone-mov",
    closeBundle() {
      const mov = path.resolve(__dirname, "dist/game-video.mov");
      if (fs.existsSync(mov)) fs.unlinkSync(mov);
    },
  };
}

/** Copy index.html to play.html / tap.html so share scrapers get an uncached URL. */
function emitShareHtml(): Plugin {
  return {
    name: "emit-share-html",
    closeBundle() {
      const index = path.resolve(__dirname, "dist/index.html");
      if (!fs.existsSync(index)) return;
      const source = fs.readFileSync(index, "utf8");
      const needle = `property="og:url" content="${INDEX_PAGE_URL}"`;
      if (!source.includes(needle)) {
        throw new Error("emit-share-html: og:url on index.html did not match");
      }
      fs.writeFileSync(
        path.resolve(__dirname, "dist/play.html"),
        source.replace(needle, `property="og:url" content="${PLAY_PAGE_URL}"`),
      );
      // tap.html is the X cache-bust URL: same-origin og-x.jpg + twitter:site
      const tap = source
        .replace(needle, `property="og:url" content="${TAP_PAGE_URL}"`)
        .replaceAll("og-preview.jpg", "og-x.jpg")
        .replace(
          `<meta name="twitter:card" content="summary_large_image" />`,
          `<meta name="twitter:card" content="summary_large_image" />\n    <meta name="twitter:site" content="@bparlette1" />`,
        )
        .replace(
          "https://cdn.jsdelivr.net/gh/bparlette/Aistudio@gh-pages/og-x.jpg",
          "https://bparlette.github.io/Aistudio/og-x.jpg",
        );
      fs.writeFileSync(path.resolve(__dirname, "dist/tap.html"), tap);
    },
  };
}

export default defineConfig(({ command, isPreview }) => ({
  // Project Pages URL: https://bparlette.github.io/Aistudio/
  base: command === "build" || isPreview ? "/Aistudio/" : "/",
  plugins: [react(), tailwindcss(), omitIphoneMov(), emitShareHtml()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
  build: {
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, "index.html"),
        BenDaDonnn: path.resolve(__dirname, "BenDaDonnn/index.html"),
      },
    },
  },
  server: {
    hmr: process.env.DISABLE_HMR !== "true",
    watch: process.env.DISABLE_HMR === "true" ? null : {},
  },
}));
