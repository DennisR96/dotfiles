import type {
  Theme,
} from "@earendil-works/pi-coding-agent";

import {
  VERSION,
} from "@earendil-works/pi-coding-agent";

const CONFIG = {
  paddingLeft: 2,
  paddingTop: 1,
  paddingBottom: 1,

  showSubtitle: true,
  showVersion: true,

  colors: [
    "#FF6B90",
    "#EF45B5",
    "#C246CB",
    "#875BE4",
    "#4299FF",
  ],
};

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
export const ANIMATION_PERIOD_MS = 4500;
export const FRAME_INTERVAL_MS = 33;

function gradientColor(position: number, phase: number): RGB {
  const scaled = position * (PALETTE.length - 1);
  const index = Math.min(Math.floor(scaled), PALETTE.length - 2);
  const fraction = scaled - index;
  const start = PALETTE[index];
  const end = PALETTE[index + 1];
  const wave = (1 + Math.cos(TAU * (position * 1.25 - phase))) / 2;
  const glow = 0.24 * wave * wave * wave;

  return [
    lerp(lerp(start[0], end[0], fraction), 255, glow),
    lerp(lerp(start[1], end[1], fraction), 255, glow),
    lerp(lerp(start[2], end[2], fraction), 255, glow),
  ];
}

function ansiColor(char: string, rgb: RGB): string {
  const [r, g, b] = rgb;
  return `\x1b[38;2;${r};${g};${b}m${char}`;
}

function renderGradient(text: string, totalWidth: number, phase = 0): string {
  let output = "";
  for (let x = 0; x < text.length; x++) {
    const char = text[x];
    if (char === " ") {
      output += char;
      continue;
    }
    const position = totalWidth > 1 ? x / (totalWidth - 1) : 0;
    output += ansiColor(char, gradientColor(position, phase));
  }
  return output + "\x1b[0m";
}

export function createHeader(theme: Theme, width: number, phase = 0): string[] {
  const lines: string[] = [];
  const padding = " ".repeat(CONFIG.paddingLeft);
  const logoWidth = Math.max(...LOGO.map((line) => line.length));

  for (let i = 0; i < CONFIG.paddingTop; i++) lines.push("");

  for (const line of LOGO) {
    const availableWidth = Math.max(0, width - CONFIG.paddingLeft);
    const visibleLine = line.slice(0, availableWidth);
    lines.push(padding + renderGradient(visibleLine, logoWidth, phase));
  }

  if (CONFIG.showSubtitle) {
    lines.push("");
    const title = theme.fg("muted", "RAEK'S PI AGENT");
    const version = CONFIG.showVersion ? theme.fg("dim", `  v${VERSION}`) : "";
    lines.push(padding + title + version);
  }

  for (let i = 0; i < CONFIG.paddingBottom; i++) lines.push("");
  return lines;
}

