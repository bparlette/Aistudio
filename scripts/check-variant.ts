import assert from "node:assert/strict";
import {
  BENDADONNN_VARIANT,
  BEACH_VARIANT,
  pathIsBenDaDonnn,
  variantForPath,
} from "../src/lib/variant.ts";

const yes = [
  "/Aistudio/BenDaDonnn/",
  "/Aistudio/BenDaDonnn",
  "/Aistudio/BenDaDonnn/index.html",
  "/BenDaDonnn/",
  "/BenDaDonnn",
  "/BenDaDonnn/index.html",
];
const no = [
  "/",
  "/Aistudio/",
  "/Aistudio/play.html",
  "/Aistudio/tap.html",
  "/Aistudio/index.html",
  "/play.html",
];

for (const p of yes) assert.equal(pathIsBenDaDonnn(p), true, p);
for (const p of no) assert.equal(pathIsBenDaDonnn(p), false, p);

const benda = variantForPath("/Aistudio/BenDaDonnn/");
assert.equal(benda.id, "bendadonnn");
assert.equal(benda.catchVideo, "BenDaDonnn/game-video.mp4");
assert.equal(benda.windowStart, 2.0);
assert.equal(benda.windowEnd, 2.5);
assert.equal(benda.windowEnd - benda.windowStart, 0.5);
assert.equal(benda.playUrl, "https://bparlette.github.io/Aistudio/BenDaDonnn/");
assert.equal(benda.title, "BenDaDonnn Catch");

const beach = variantForPath("/Aistudio/");
assert.equal(beach.id, "beach");
assert.equal(beach.catchVideo, BEACH_VARIANT.catchVideo);
assert.equal(beach.windowStart, 3.5);
assert.equal(beach.windowEnd, 4.0);
assert.equal(beach.playUrl, "https://bparlette.github.io/Aistudio/");
assert.notEqual(beach.catchVideo, BENDADONNN_VARIANT.catchVideo);

console.log("variant checks ok");
