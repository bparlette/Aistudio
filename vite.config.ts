import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import path from "path";
import { defineConfig, Plugin } from "vite";

const INDEX_PAGE_URL = "https://bparlette.github.io/Aistudio/";
const PLAY_PAGE_URL = "https://bparlette.github.io/Aistudio/play.html";
const TAP_PAGE_URL = "https://bparlette.github.io/Aistudio/tap.html";
const INDEX_OG_IMAGE = "https://bparlette.github.io/Aistudio/og-preview.jpg";
const INDEX_TWITTER_IMAGE =
  "https://cdn.jsdelivr.net/gh/bparlette/Aistudio@gh-pages/og-preview.jpg";
const TAP_IMAGE_URL = "https://bparlette.github.io/Aistudio/og-x.jpg";

function omitIphoneMov(): Plugin {
  return {
    name: "omit-iphone-mov",
    closeBundle() {
      const mov = path.resolve(__dirname, "dist/game-video.mov");
      if (fs.existsSync(mov)) fs.unlinkSync(mov);
    },
  };
}

function readBuiltIndex(): string | null {
  const index = path.resolve(__dirname, "dist/index.html");
  if (!fs.existsSync(index)) return null;
  return fs.readFileSync(index, "utf8");
}

/** Copy index.html to play.html so X can scrape an uncached share URL. */
function emitPlayHtml(): Plugin {
  return {
    name: "emit-play-html",
    closeBundle() {
      const source = readBuiltIndex();
      if (!source) return;
      const dest = path.resolve(__dirname, "dist/play.html");
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

/**
 * tap.html is a never-shared path. Same game as index, but both og:image and
 * twitter:image are same-origin og-x.jpg (cache-bust copy of og-preview.jpg).
 */
function emitTapHtml(): Plugin {
  return {
    name: "emit-tap-html",
    closeBundle() {
      const source = readBuiltIndex();
      if (!source) return;
      const dest = path.resolve(__dirname, "dist/tap.html");
      const ogUrlNeedle = `property="og:url" content="${INDEX_PAGE_URL}"`;
      const cardNeedle = `<meta name="twitter:card" content="summary_large_image" />`;
      if (!source.includes(ogUrlNeedle)) {
        throw new Error("emit-tap-html: og:url on index.html did not match");
      }
      if (!source.includes(INDEX_OG_IMAGE)) {
        throw new Error("emit-tap-html: og-preview.jpg not found on index.html");
      }
      if (!source.includes(INDEX_TWITTER_IMAGE)) {
        throw new Error("emit-tap-html: jsDelivr twitter:image not found on index.html");
      }
      if (!source.includes(cardNeedle)) {
        throw new Error("emit-tap-html: twitter:card not found on index.html");
      }

      let html = source.replace(ogUrlNeedle, `property="og:url" content="${TAP_PAGE_URL}"`);
      html = html.split(INDEX_OG_IMAGE).join(TAP_IMAGE_URL);
      html = html.split(INDEX_TWITTER_IMAGE).join(TAP_IMAGE_URL);
      html = html.replace(
        cardNeedle,
        `${cardNeedle}\n    <meta name="twitter:site" content="@bparlette1" />`,
      );
      fs.writeFileSync(dest, html);
    },
  };
}

export default defineConfig(({ command, isPreview }) => ({
  // Project Pages URL: https://bparlette.github.io/Aistudio/
  base: command === "build" || isPreview ? "/Aistudio/" : "/",
  plugins: [react(), tailwindcss(), omitIphoneMov(), emitPlayHtml(), emitTapHtml()],
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
