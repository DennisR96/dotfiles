import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { SessionEntry } from "@earendil-works/pi-coding-agent";

function preview(entry: Extract<SessionEntry, { type: "message" }>): string {
  const msg = entry.message;
  const content = Array.isArray(msg.content)
    ? msg.content.map((part) => part.type === "text" ? part.text : `[${part.type}]`).join(" ")
    : String(msg.content ?? "");
  const clean = content.replace(/\s+/g, " ").trim();
  return `${msg.role}: ${clean.slice(0, 110)}${clean.length > 110 ? "…" : ""}`;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("slice", {
    description: "Copy the selected message and the rest of the active branch into a new session",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/slice needs an interactive message picker.", "warning");
        return;
      }
      await ctx.waitForIdle();
      const branch = ctx.sessionManager.getBranch();
      const choices = branch.filter((entry): entry is Extract<SessionEntry, { type: "message" }> =>
        entry.type === "message" && entry.message.role !== "system",
      );
      if (!choices.length) {
        ctx.ui.notify("No messages in the active branch.", "info");
        return;
      }
      // Numbering makes identical message previews unambiguous in ui.select().
      const labels = choices.map((entry, index) => `${index + 1}. ${preview(entry)}`);
      const selected = await ctx.ui.select("Start new session at (inclusive)", labels);
      if (selected === undefined) return;
      const index = labels.indexOf(selected);
      if (index < 0) return;

      const suffix = branch.slice(branch.findIndex((entry) => entry.id === choices[index].id));
      const parentSession = ctx.sessionManager.getSessionFile();
      await ctx.newSession({
        parentSession,
        setup: async (manager) => {
          const copiedIds = new Map<string, string>();
          for (const entry of suffix) {
            let id: string | undefined;
            switch (entry.type) {
              case "message":
                // Pi will generate a fresh system prompt for the next request.
                if (entry.message.role !== "system") id = manager.appendMessage(entry.message);
                break;
              case "model_change":
                id = manager.appendModelChange(entry.provider, entry.modelId);
                break;
              case "thinking_level_change":
                id = manager.appendThinkingLevelChange(entry.thinkingLevel);
                break;
              case "custom":
                id = manager.appendCustomEntry(entry.customType, entry.data);
                break;
              case "custom_message":
                id = manager.appendCustomMessageEntry(entry.customType, entry.content, entry.display, entry.details);
                break;
              case "context_edit": {
                const target = copiedIds.get(entry.targetId);
                if (target) id = manager.appendContextEdit(target, entry.replacement);
                break;
              }
              case "label": {
                const target = copiedIds.get(entry.targetId);
                if (target) id = manager.appendLabelChange(target, entry.label);
                break;
              }
              case "session_info":
                if (entry.name) id = manager.appendSessionInfo(entry.name);
                break;
              // Compaction and branch summaries can describe messages *before* the
              // chosen boundary. Copy the raw suffix instead, without those summaries.
              // Usage entries are accounting rather than conversation history.
            }
            if (id) copiedIds.set(entry.id, id);
          }
        },
        withSession: async (replacementCtx) => {
          replacementCtx.ui.notify("Created a new session with the selected message and later messages.", "info");
        },
      });
    },
  });
}
