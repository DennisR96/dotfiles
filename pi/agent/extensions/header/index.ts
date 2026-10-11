import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  ANIMATION_PERIOD_MS,
  createHeader,
  FRAME_INTERVAL_MS,
} from "./header.js";

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

  pi.on("session_start", async (_event, ctx) => installHeader(ctx));

  pi.registerCommand("raek-header", {
    description: "Enable the RAEK neon header",
    handler: async (_args, ctx) => {
      installHeader(ctx);
      ctx.ui.notify("RAEK neon header enabled", "info");
    },
  });

  pi.registerCommand("builtin-header", {
    description: "Restore the default Pi header",
    handler: async (_args, ctx) => {
      if (animationTimer) clearInterval(animationTimer);
      animationTimer = undefined;
      ctx.ui.setHeader(undefined);
      ctx.ui.notify("Built-in header restored", "info");
    },
  });
}
