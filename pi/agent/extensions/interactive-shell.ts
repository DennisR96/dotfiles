/**
 * Interactive Shell Commands Extension
 *
 * Runs interactive commands with full terminal access, suspending the TUI while
 * they run. Use !vim file.txt for automatic detection or !i command to force
 * interactive mode.
 *
 * Configuration:
 *   INTERACTIVE_COMMANDS - Additional commands (comma-separated)
 *   INTERACTIVE_EXCLUDE  - Commands to exclude (comma-separated)
 *
 * Only user-entered `!` commands are intercepted, not agent bash calls.
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEFAULT_INTERACTIVE_COMMANDS = [
    // Editors
    "vim", "nvim", "vi", "nano", "emacs", "pico", "micro", "helix", "hx", "kak",
    // Pagers
    "less", "more", "most",
    // Git interactive operations
    "git commit", "git rebase", "git merge", "git cherry-pick", "git revert",
    "git add -p", "git add --patch", "git add -i", "git add --interactive",
    "git stash -p", "git stash --patch", "git reset -p", "git reset --patch",
    "git checkout -p", "git checkout --patch", "git difftool", "git mergetool",
    // System monitors and file managers
    "htop", "top", "btop", "glances", "ranger", "nnn", "lf", "mc", "vifm",
    // Git TUIs and fuzzy finders
    "tig", "lazygit", "gitui", "fzf", "sk",
    // Remote sessions
    "ssh", "telnet", "mosh",
    // Database clients
    "psql", "mysql", "sqlite3", "mongosh", "redis-cli",
    // Kubernetes/Docker
    "kubectl edit", "kubectl exec -it", "docker exec -it", "docker run -it",
    // Other
    "tmux", "screen", "ncdu",
];

function getInteractiveCommands(): string[] {
    const additional = process.env.INTERACTIVE_COMMANDS?.split(",").map((s) => s.trim()).filter(Boolean) ?? [];
    const excluded = new Set(process.env.INTERACTIVE_EXCLUDE?.split(",").map((s) => s.trim().toLowerCase()) ?? []);
    return [...DEFAULT_INTERACTIVE_COMMANDS, ...additional].filter((cmd) => !excluded.has(cmd.toLowerCase()));
}

export function isInteractiveShellCommand(command: string): boolean {
    if (command.startsWith("i ") || command.startsWith("i\t")) return true;
    return isInteractiveCommand(command);
}

function isInteractiveCommand(command: string): boolean {
    const trimmed = command.trim().toLowerCase();
    for (const cmd of getInteractiveCommands()) {
        const cmdLower = cmd.toLowerCase();
        if (trimmed === cmdLower || trimmed.startsWith(`${cmdLower} `) || trimmed.startsWith(`${cmdLower}\t`)) {
            return true;
        }
        const pipeIdx = trimmed.lastIndexOf("|");
        if (pipeIdx !== -1) {
            const afterPipe = trimmed.slice(pipeIdx + 1).trim();
            if (afterPipe === cmdLower || afterPipe.startsWith(`${cmdLower} `)) return true;
        }
    }
    return false;
}

export default function (pi: ExtensionAPI) {
    pi.on("user_bash", async (event, ctx) => {
        if (!isInteractiveShellCommand(event.command)) return;
        // The ! prefix is removed before this event; !i arrives as "i ".
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
            return { render: () => [], invalidate: () => {} };
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
