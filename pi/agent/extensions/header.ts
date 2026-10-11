
/**
 * RAEK Neon Header Extension
 *
 * Geometric ASCII logo with a smooth
 * pink -> magenta -> purple -> blue gradient.
 *
 * Commands:
 *   /raek-header
 *   /builtin-header
 */

import type {
  ExtensionAPI,
  Theme,
} from "@earendil-works/pi-coding-agent";

import {
  VERSION,
} from "@earendil-works/pi-coding-agent";

// ─────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────

const CONFIG = {
  paddingLeft: 2,
  paddingTop: 1,
  paddingBottom: 1,

  showSubtitle: true,
  showVersion: true,

  // Gradient colors
  colors: [
    "#FF6B90", // Pink
    "#EF45B5", // Hot magenta
    "#C246CB", // Purple pink
    "#875BE4", // Violet
    "#4299FF", // Electric blue
  ],
};

// ─────────────────────────────────────
// ASCII ART
// ─────────────────────────────────────

const LOGO = [
  "███████████     █████████   ██████████ █████   ████",
  "░░███░░░░░███   ███░░░░░███ ░░███░░░░░█░░███   ███░",
  " ░███    ░███  ░███    ░███  ░███  █ ░  ░███  ███  ",
  " ░██████████   ░███████████  ░██████    ░███████   ",
  " ░███░░░░░███  ░███░░░░░███  ░███░░█    ░███░███   ",
  " ░███    ░███  ░███    ░███  ░███ ░   █ ░███ ░░███ ",
  " █████   █████ █████   █████ ██████████ █████ ░░████",
  "░░░░░   ░░░░░ ░░░░░   ░░░░░ ░░░░░░░░░░ ░░░░░   ░░░░ ",
];

// ─────────────────────────────────────
// COLOR UTILITIES
// ─────────────────────────────────────

type RGB = [number, number, number];

function hexToRgb(hex: string): RGB {
  const value = hex.replace("#", "");

  return [
    parseInt(value.slice(0, 2), 16),
    parseInt(value.slice(2, 4), 16),
    parseInt(value.slice(4, 6), 16),
  ];
}

function lerp(a: number, b: number, t: number) {
  return Math.round(a + (b - a) * t);
}

const PALETTE = CONFIG.colors.map(hexToRgb);
const TAU = Math.PI * 2;
const ANIMATION_PERIOD_MS = 4500;
const FRAME_INTERVAL_MS = 33;

function gradientColor(position: number, phase: number): RGB {
  const scaled = position * (PALETTE.length - 1);
  const index = Math.min(Math.floor(scaled), PALETTE.length - 2);
  const fraction = scaled - index;
  const start = PALETTE[index];
  const end = PALETTE[index + 1];

  // Keep the pink-to-blue gradient in place; sweep a soft highlight over it.
  // A periodic wave has no visible jump when the animation loops.
  const wave = (1 + Math.cos(TAU * (position * 1.25 - phase))) / 2;
  const glow = 0.24 * wave * wave * wave;

  return [
    lerp(lerp(start[0], end[0], fraction), 255, glow),
    lerp(lerp(start[1], end[1], fraction), 255, glow),
    lerp(lerp(start[2], end[2], fraction), 255, glow),
  ];
}

function ansiColor(
  char: string,
  rgb: RGB,
): string {
  const [r, g, b] = rgb;

  return `\x1b[38;2;${r};${g};${b}m${char}`;
}

// ─────────────────────────────────────
// GRADIENT RENDERER
// ─────────────────────────────────────

function renderGradient(
  text: string,
  totalWidth: number,
  phase = 0,
): string {
  let output = "";

  for (let x = 0; x < text.length; x++) {
    const char = text[x];

    if (char === " ") {
      output += char;
      continue;
    }

    const position =
      totalWidth > 1
        ? x / (totalWidth - 1)
        : 0;

    const rgb = gradientColor(position, phase);

    output += ansiColor(char, rgb);
  }

  // Reset ANSI color
  return output + "\x1b[0m";
}

// ─────────────────────────────────────
// HEADER RENDERER
// ─────────────────────────────────────

function createHeader(
  theme: Theme,
  width: number,
  phase = 0,
): string[] {
  const lines: string[] = [];

  const padding = " ".repeat(CONFIG.paddingLeft);

  const logoWidth = Math.max(
    ...LOGO.map((line) => line.length),
  );

  // Top spacing
  for (let i = 0; i < CONFIG.paddingTop; i++) {
    lines.push("");
  }

  // Render logo
  for (const line of LOGO) {
    const availableWidth = Math.max(
      0,
      width - CONFIG.paddingLeft,
    );

    const visibleLine = line.slice(
      0,
      availableWidth,
    );

    lines.push(
      padding + renderGradient(visibleLine, logoWidth, phase),
    );
  }

  // Subtitle
  if (CONFIG.showSubtitle) {
    lines.push("");

    const title = theme.fg(
      "muted",
      "RAEK'S PI AGENT",
    );

    const version = CONFIG.showVersion
      ? theme.fg("dim", `  v${VERSION}`)
      : "";

    lines.push(
      padding + title + version,
    );
  }

  // Bottom spacing
  for (let i = 0; i < CONFIG.paddingBottom; i++) {
    lines.push("");
  }

  return lines;
}

// ─────────────────────────────────────
// EXTENSION
// ─────────────────────────────────────

export default function(pi: ExtensionAPI) {
  let animationTimer: ReturnType<typeof setInterval> | undefined;

  function installHeader(ctx: any) {
    if (ctx.mode !== "tui") return;

    if (animationTimer) clearInterval(animationTimer);

    ctx.ui.setHeader((tui, theme) => {
      const startedAt = performance.now();
      animationTimer = setInterval(() => tui.requestRender(), FRAME_INTERVAL_MS);

      return {
        render(width: number): string[] {
          const phase = ((performance.now() - startedAt) / ANIMATION_PERIOD_MS) % 1;
          return createHeader(theme, width, phase);
        },

        invalidate() {},
      };
    });
  }

  pi.on("session_shutdown", async () => {
    if (animationTimer) clearInterval(animationTimer);
    animationTimer = undefined;
  });

  // Automatically install on startup
  pi.on("session_start", async (_event, ctx) => {
    installHeader(ctx);
  });

  // Restore custom header
  pi.registerCommand("raek-header", {
    description: "Enable the RAEK neon header",

    handler: async (_args, ctx) => {
      installHeader(ctx);

      ctx.ui.notify(
        "RAEK neon header enabled",
        "info",
      );
    },
  });

  // Restore built-in header
  pi.registerCommand("builtin-header", {
    description: "Restore the default Pi header",

    handler: async (_args, ctx) => {
      if (animationTimer) clearInterval(animationTimer);
      animationTimer = undefined;
      ctx.ui.setHeader(undefined);

      ctx.ui.notify(
        "Built-in header restored",
        "info",
      );
    },
  });
}

