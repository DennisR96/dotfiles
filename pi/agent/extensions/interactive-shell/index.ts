import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isInteractiveShellCommand } from "./helper.js";

export default function(pi: ExtensionAPI) {
  pi.on("user_bash", async (event, ctx) => {
    if (!isInteractiveShellCommand(event.command)) return;
    const command = event.command.startsWith("i ") || event.command.startsWith("i\t")
      ? event.command.slice(2).trim()
      : event.command;
    if (ctx.mode !== "tui") {
      return {
        result: { output: "(interactive commands require TUI)", exitCode: 1, cancelled: false, truncated: false },
      };
    }

    const exitCode = await ctx.ui.custom<number | null>((tui, _theme, _kb, done) => {
      tui.stop();
      process.stdout.write("\x1b[2J\x1b[H");
      const shell = process.env.SHELL || "/bin/sh";
      const result = spawnSync(shell, ["-c", command], { stdio: "inherit", env: process.env, cwd: process.cwd() });
      tui.start();
      tui.requestRender(true);
      done(result.status);
      return { render: () => [], invalidate: () => { } };
    });

    return {
      result: {
        output: exitCode === 0
          ? "(interactive command completed successfully)"
          : `(interactive command exited with code ${exitCode})`,
        exitCode: exitCode ?? 1,
        cancelled: false,
        truncated: false,
      },
    };
  });
}
