import { createLocalBashOperations, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, type AutocompleteItem } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { realpathSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { isInteractiveShellCommand } from "./interactive-shell.ts";

const ENTRY_TYPE = "cwd-change";
const REQUIRED_PATH_TOOLS = new Set(["read", "write", "edit"]);
const OPTIONAL_PATH_TOOLS = new Set(["grep", "find", "ls"]);
const CWD_LINE = /Current working directory: .+/;

let originalCwd = process.cwd();
let effectiveCwd = originalCwd;
let localBashOps = createLocalBashOperations();
let customFooterInstalled = false;
let previousCwd: string | undefined;
const execFileAsync = promisify(execFile);

// Capture standalone directory commands; leave compound shell commands alone.
function directoryCommand(command: string): { name: "cd" | "z"; args: string[] } | null {
  const match = command.trim().match(/^(cd|z)(?:\s+(.*))?$/s);
  if (!match) return null;
  const args: string[] = [];
  let word = "";
  let started = false;
  let quote: "'" | '"' | null = null;
  const input = match[2] ?? "";
  for (let i = 0; i < input.length; i++) {
    const ch = input[i];
    if (ch === "\\" && quote !== "'") {
      if (++i >= input.length) return null;
      word += input[i];
      started = true;
    } else if (ch === quote) {
      quote = null;
    } else if ((ch === "'" || ch === '"') && !quote) {
      quote = ch;
      started = true;
    } else if (!quote && /\s/.test(ch)) {
      if (started) args.push(word);
      word = "";
      started = false;
    } else {
      if (!quote && /[;&|<>`$(){}]/.test(ch)) return null;
      if (quote === '"' && /[`$]/.test(ch)) return null;
      word += ch;
      started = true;
    }
  }
  if (quote) return null;
  if (started) args.push(word);
  return { name: match[1] as "cd" | "z", args };
}

function changeDirectory(target: string, ctx: ExtensionContext, pi: ExtensionAPI): string {
  const path = resolve(effectiveCwd, expandTilde(target));
  if (!statSync(path).isDirectory()) throw new Error(`Not a directory: ${path}`);
  const next = realpathSync(path);
  process.chdir(next);
  previousCwd = effectiveCwd;
  effectiveCwd = next;
  pi.appendEntry(ENTRY_TYPE, { cwd: effectiveCwd });
  updateFooter(ctx);
  return effectiveCwd;
}

function expandTilde(value: string): string {
  return value.startsWith("~") && process.env.HOME
    ? process.env.HOME + value.slice(1)
    : value;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

function formatTokens(count: number): string {
  if (count < 1000) return String(count);
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function updateFooter(ctx: ExtensionContext): void {
  if (ctx.mode !== "tui") return;
  if (effectiveCwd === originalCwd) {
    if (customFooterInstalled) ctx.ui.setFooter(undefined);
    customFooterInstalled = false;
    return;
  }
  customFooterInstalled = true;

  // The built-in footer reads the session's original cwd, not process.cwd().
  ctx.ui.setFooter((tui, theme, footerData) => {
    const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
    let cached: { sessionId: string; leafId: string | null; count: number; parts: string[] } | undefined;
    return {
      dispose: unsubscribe,
      invalidate() { cached = undefined; },
      render(width: number): string[] {
        const home = process.env.HOME || process.env.USERPROFILE;
        const fromHome = home ? relative(home, effectiveCwd) : "";
        const insideHome = home && (fromHome === "" || (fromHome !== ".." && !fromHome.startsWith(`..${sep}`) && !isAbsolute(fromHome)));
        const path = insideHome ? (fromHome ? `~${sep}${fromHome}` : "~") : effectiveCwd;
        const branch = footerData.getGitBranch();
        const name = ctx.sessionManager.getSessionName();
        const heading = `${path}${branch ? ` (${branch})` : ""}${name ? ` • ${name}` : ""}`;

        const manager = ctx.sessionManager;
        const sessionId = manager.getSessionId();
        const leafId = manager.getLeafId();
        const count = manager.getEntryCount();
        if (!cached || cached.sessionId !== sessionId || cached.leafId !== leafId || cached.count !== count) {
          let input = 0, output = 0, cacheRead = 0, cacheWrite = 0, cost = 0;
          let hitRate: number | undefined;
          const add = (usage: { input: number; output: number; cacheRead: number; cacheWrite: number; cost: { total: number } }) => {
            input += usage.input;
            output += usage.output;
            cacheRead += usage.cacheRead;
            cacheWrite += usage.cacheWrite;
            cost += usage.cost.total;
          };
          for (const entry of manager.getEntries()) {
            if (entry.type === "usage") add(entry.usage);
            else if (entry.type === "message" && entry.message.role === "assistant") {
              const usage = entry.message.usage;
              add(usage);
              const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
              hitRate = promptTokens ? usage.cacheRead / promptTokens * 100 : undefined;
            } else if (entry.type === "message" && entry.message.role === "toolResult" && entry.message.usage) {
              add(entry.message.usage);
            } else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
              add(entry.usage);
            }
          }
          const parts: string[] = [];
          if (input) parts.push(`↑${formatTokens(input)}`);
          if (output) parts.push(`↓${formatTokens(output)}`);
          if (cacheRead) parts.push(`R${formatTokens(cacheRead)}`);
          if (cacheWrite) parts.push(`W${formatTokens(cacheWrite)}`);
          if ((cacheRead || cacheWrite) && hitRate !== undefined) parts.push(`CH${hitRate.toFixed(1)}%`);
          if (cost) parts.push(`$${cost.toFixed(3)}`);
          cached = { sessionId, leafId, count, parts };
        }
        const usage = ctx.getContextUsage();
        const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
        const percent = usage?.percent;
        const contextText = `${percent == null ? "?" : `${percent.toFixed(1)}%`}/${formatTokens(contextWindow)} (auto)`;
        const contextColored = percent != null && percent > 90
          ? theme.fg("error", contextText)
          : percent != null && percent > 70 ? theme.fg("warning", contextText) : contextText;
        const stats = [...cached.parts, contextColored].join(" ");
        const model = ctx.model?.id ?? "no-model";
        const thinking = ctx.model?.reasoning ? ` • ${ctx.thinkingLevel ?? "off"}` : "";
        const rightWithoutProvider = model + thinking;
        let left = visibleWidth(stats) > width ? truncateToWidth(stats, width, "...") : stats;
        let right = footerData.getAvailableProviderCount() > 1 && ctx.model
          ? `(${ctx.model.provider}) ${rightWithoutProvider}` : rightWithoutProvider;
        if (visibleWidth(left) + 2 + visibleWidth(right) > width) right = rightWithoutProvider;
        const available = width - visibleWidth(left) - 2;
        right = available > 0 ? truncateToWidth(right, available, "") : "";
        const padding = " ".repeat(Math.max(0, width - visibleWidth(left) - visibleWidth(right)));
        const lines = [
          truncateToWidth(theme.fg("dim", heading), width, theme.fg("dim", "...")),
          theme.fg("dim", left) + theme.fg("dim", padding + right),
        ];
        const statuses = [...footerData.getExtensionStatuses().entries()]
          .sort(([a], [b]) => a.localeCompare(b))
          .map(([, text]) => text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim());
        if (statuses.length) lines.push(truncateToWidth(statuses.join(" "), width, theme.fg("dim", "...")));
        return lines;
      },
    };
  });
}

function restoreFromBranch(ctx: ExtensionContext): string | undefined {
  try {
    const branch = ctx.sessionManager.getBranch();
    for (let i = branch.length - 1; i >= 0; i--) {
      const entry = branch[i];
      if (entry?.type !== "custom" || entry.customType !== ENTRY_TYPE) continue;
      const cwd = (entry.data as { cwd?: unknown } | undefined)?.cwd;
      if (typeof cwd !== "string") continue;
      try {
        if (statSync(cwd).isDirectory()) return realpathSync(cwd);
      } catch { /* Ignore paths that no longer exist. */ }
    }
  } catch { /* A missing/unavailable branch falls back to the initial directory. */ }
  return undefined;
}

function getCompletions(prefix: string): AutocompleteItem[] | null {
  const expanded = expandTilde(prefix);
  const trailingSlash = expanded.endsWith("/");
  const searchDir = trailingSlash || !expanded || expanded === "."
    ? (isAbsolute(expanded) ? expanded : resolve(effectiveCwd, expanded.slice(0, -1) || "."))
    : (isAbsolute(expanded) ? dirname(expanded) : resolve(effectiveCwd, dirname(expanded) || "."));
  const partial = trailingSlash || !expanded || expanded === "." ? "" : basename(expanded);
  try {
    if (!statSync(searchDir).isDirectory()) return null;
    const entries = readdirSync(searchDir).filter((name) => {
      if (partial && !name.toLowerCase().startsWith(partial.toLowerCase())) return false;
      try { return statSync(join(searchDir, name)).isDirectory(); } catch { return false; }
    });
    if (!entries.length) return null;
    return entries.map((name) => {
      let value: string;
      if (isAbsolute(expanded) || prefix.startsWith("~")) {
        value = join(searchDir, name);
        if (prefix.startsWith("~") && process.env.HOME) {
          value = value.replace(new RegExp(`^${process.env.HOME.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&")}`), "~");
        }
      } else if (trailingSlash) value = `${prefix}${name}`;
      else {
        const dir = dirname(prefix || "");
        value = dir === "." ? name : join(dir, name);
      }
      return { label: name, value };
    });
  } catch { return null; }
}

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("cd", {
    description: "Show or change the effective working directory (/cd <path>)",
    handler: async (args, ctx) => {
      const raw = args.trim();
      if (!raw) {
        ctx.ui.notify(`Current working directory: ${effectiveCwd}`, "info");
        return;
      }
      try {
        changeDirectory(raw === "-" ? previousCwd ?? effectiveCwd : raw, ctx, pi);
      } catch (error) {
        ctx.ui.notify(`Cannot change directory: ${String(error)}`, "error");
      }
    },
    getArgumentCompletions: getCompletions,
  });

  pi.on("tool_call", (event) => {
    if (effectiveCwd === originalCwd) return;
    if (event.toolName === "bash") {
      event.input.command = `cd ${shellQuote(effectiveCwd)} && ${event.input.command}`;
    } else if (REQUIRED_PATH_TOOLS.has(event.toolName)) {
      if (!isAbsolute(event.input.path)) event.input.path = resolve(effectiveCwd, event.input.path);
    } else if (OPTIONAL_PATH_TOOLS.has(event.toolName)) {
      if (!event.input.path) event.input.path = effectiveCwd;
      else if (!isAbsolute(event.input.path)) event.input.path = resolve(effectiveCwd, event.input.path);
    }
  });

  pi.on("before_agent_start", (event) => {
    if (effectiveCwd === originalCwd) return;
    return { systemPrompt: event.systemPrompt.replace(CWD_LINE, `Current working directory: ${effectiveCwd}`) };
  });

  pi.on("user_bash", async (event, ctx) => {
    const parsed = directoryCommand(event.command);
    if (parsed?.name === "cd" && parsed.args.length > 1) {
      return {
        result: {
          output: "cd accepts at most one path argument; use /cd <path> to change the working directory.",
          exitCode: 1,
          cancelled: false,
          truncated: false,
        },
      };
    }
    if (parsed) {
      try {
        let target: string;
        if (parsed.name === "cd") {
          target = parsed.args[0] === "-" ? previousCwd ?? effectiveCwd : parsed.args[0] || process.env.HOME || effectiveCwd;
        } else if (!parsed.args.length) {
          target = process.env.HOME || effectiveCwd;
        } else if (parsed.args.length === 1 && ["-", "..", "."].includes(parsed.args[0])) {
          target = parsed.args[0] === "-" ? previousCwd ?? effectiveCwd : parsed.args[0];
        } else {
          const { stdout } = await execFileAsync("zoxide", ["query", ...parsed.args], { cwd: effectiveCwd });
          target = stdout.trim();
        }
        const cwd = changeDirectory(target, ctx, pi);
        return { result: { output: cwd, exitCode: 0, cancelled: false, truncated: false } };
      } catch (error) {
        return { result: { output: `Cannot change directory: ${String(error)}`, exitCode: 1, cancelled: false, truncated: false } };
      }
    }
    // Let interactive-shell own terminal programs; its child inherits process.cwd().
    if (effectiveCwd === originalCwd || isInteractiveShellCommand(event.command)) return;
    return {
      operations: {
        exec: (command, cwd, options) =>
          localBashOps.exec(`cd ${shellQuote(effectiveCwd)} && ${command}`, cwd, options),
      },
    };
  });

  pi.on("session_start", (event, ctx) => {
    const inheritedCwd = effectiveCwd;
    originalCwd = ctx.cwd;
    const restoredCwd = restoreFromBranch(ctx);
    if (restoredCwd) {
      effectiveCwd = restoredCwd;
    } else if (event.reason === "new") {
      // /new retains the selected directory, but starts with an empty branch.
      try {
        effectiveCwd = statSync(inheritedCwd).isDirectory() ? realpathSync(inheritedCwd) : originalCwd;
      } catch { effectiveCwd = originalCwd; }
      // Record the inherited directory so tree navigation and resuming this session retain it.
      if (effectiveCwd !== originalCwd) pi.appendEntry(ENTRY_TYPE, { cwd: effectiveCwd });
    } else {
      effectiveCwd = originalCwd;
    }
    previousCwd = undefined;
    process.chdir(effectiveCwd);
    updateFooter(ctx);
  });
  pi.on("session_tree", (_event, ctx) => {
    effectiveCwd = restoreFromBranch(ctx) ?? originalCwd;
    previousCwd = undefined;
    process.chdir(effectiveCwd);
    updateFooter(ctx);
  });
}
