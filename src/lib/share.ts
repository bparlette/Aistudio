import { type Rank } from "./ranks";
import { getVariant } from "./variant";

export function captureVideoFrame(video: HTMLVideoElement): string | null {
  if (!video.videoWidth) return null;
  const canvas = document.createElement("canvas");
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;
  ctx.drawImage(video, 0, 0);
  try {
    return canvas.toDataURL("image/jpeg", 0.84);
  } catch {
    return null;
  }
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("still failed"));
    img.src = src;
  });
}

/** 9:16 story card: helmet still + rank + streak + beat this. */
export async function composeShareCard(
  still: string | null,
  score: number,
  rank: Rank | null,
): Promise<Blob> {
  const w = 720;
  const h = 1280;
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("no canvas");

  ctx.fillStyle = "#0a0a0a";
  ctx.fillRect(0, 0, w, h);

  if (still) {
    try {
      const img = await loadImage(still);
      const scale = Math.max(w / img.width, h / img.height);
      const dw = img.width * scale;
      const dh = img.height * scale;
      ctx.drawImage(img, (w - dw) / 2, (h - dh) / 2, dw, dh);
    } catch {
      /* solid fallback */
    }
  }

  const fade = ctx.createLinearGradient(0, h * 0.42, 0, h);
  fade.addColorStop(0, "rgba(0,0,0,0)");
  fade.addColorStop(0.45, "rgba(0,0,0,0.45)");
  fade.addColorStop(1, "rgba(0,0,0,0.88)");
  ctx.fillStyle = fade;
  ctx.fillRect(0, 0, w, h);

  const variant = getVariant();

  ctx.fillStyle = "rgba(255,255,255,0.9)";
  ctx.font = "700 22px system-ui, sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(variant.title.toUpperCase(), w / 2, 72);

  const title = rank?.name ?? "Unsigned";
  ctx.fillStyle = "#fbbf24";
  ctx.font = "900 64px system-ui, sans-serif";
  ctx.fillText(title.toUpperCase(), w / 2, h * 0.68);

  ctx.fillStyle = "#fff";
  ctx.font = "800 44px system-ui, sans-serif";
  ctx.fillText(`${score} streak`, w / 2, h * 0.68 + 64);

  ctx.fillStyle = "#fecaca";
  ctx.font = "800 36px system-ui, sans-serif";
  ctx.fillText("beat this", w / 2, h * 0.68 + 118);

  ctx.fillStyle = "rgba(255,255,255,0.55)";
  ctx.font = "600 18px system-ui, sans-serif";
  ctx.fillText(variant.playUrl.replace("https://", ""), w / 2, h - 48);

  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error("blob"))), "image/jpeg", 0.88);
  });
}

export async function shareRun(opts: {
  text: string;
  still: string | null;
  score: number;
  rank: Rank | null;
}): Promise<"shared" | "copied"> {
  let file: File | undefined;
  try {
    const blob = await composeShareCard(opts.still, opts.score, opts.rank);
    file = new File([blob], "catch-share.jpg", { type: "image/jpeg" });
  } catch {
    file = undefined;
  }

  const nav = navigator as Navigator & {
    canShare?: (data: ShareData) => boolean;
  };
  const variant = getVariant();
  const shareData: ShareData = {
    title: variant.title,
    text: opts.text,
    url: variant.playUrl,
  };

  await copyText(opts.text);

  try {
    if (file && typeof nav.canShare === "function" && nav.canShare({ files: [file] })) {
      await navigator.share({ ...shareData, files: [file] });
      return "shared";
    }
    if (typeof navigator.share === "function") {
      await navigator.share(shareData);
      return "shared";
    }
  } catch (err) {
    if ((err as { name?: string })?.name === "AbortError") return "copied";
  }

  return "copied";
}

async function copyText(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    try {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      const ok = document.execCommand("copy");
      document.body.removeChild(ta);
      return ok;
    } catch {
      return false;
    }
  }
}
