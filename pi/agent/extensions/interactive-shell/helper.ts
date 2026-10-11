import { DEFAULT_INTERACTIVE_COMMANDS } from "./constants.js";

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
