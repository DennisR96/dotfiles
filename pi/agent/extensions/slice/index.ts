import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";

type MessageEntry = Extract<SessionEntry, { type: "message" }>;

function preview(entry: MessageEntry): string {
  const { message } = entry;
  const contentText = Array.isArray(message.content)
    ? message.content.map((part) => part.type === "text" ? part.text : `[${part.type}]`).join(" ")
    : String(message.content ?? "");
  const normalizedText = contentText.replace(/\s+/g, " ").trim();
  const excerpt = normalizedText.slice(0, 110);
  const ellipsis = normalizedText.length > 110 ? "…" : "";
  return `${message.role}: ${excerpt}${ellipsis}`;
}

export default function(pi: ExtensionAPI) {
  pi.registerCommand("slice", {
    description: "Copy the selected message and the rest of the active branch into a new session",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/slice needs an interactive message picker.", "warning");
        return;
      }

      await ctx.waitForIdle();
      const branch = ctx.sessionManager.getBranch();
      const choices = branch.filter((entry): entry is MessageEntry =>
        entry.type === "message" && entry.message.role !== "system",
      );
      if (choices.length === 0) {
        ctx.ui.notify("No messages in the active branch.", "info");
        return;
      }

      const labels = choices.map((entry, index) => `${index + 1}. ${preview(entry)}`);
      const selected = await ctx.ui.select("Start new session at (inclusive)", labels);
      if (selected === undefined) return;

      const selectedIndex = labels.indexOf(selected);
      if (selectedIndex < 0) return;

      const startIndex = branch.findIndex((entry) => entry.id === choices[selectedIndex].id);
      if (startIndex < 0) return;

      const suffix = branch.slice(startIndex);
      const parentSession = ctx.sessionManager.getSessionFile();
      await ctx.newSession({
        parentSession,
        setup: async (manager) => {
          const copiedIds = new Map<string, string>();
          const copyEntry = (entry: SessionEntry): string | undefined => {
            switch (entry.type) {
              case "message":
                return entry.message.role !== "system" ? manager.appendMessage(entry.message) : undefined;
              case "model_change":
                return manager.appendModelChange(entry.provider, entry.modelId);
              case "thinking_level_change":
                return manager.appendThinkingLevelChange(entry.thinkingLevel);
              case "custom":
                return manager.appendCustomEntry(entry.customType, entry.data);
              case "custom_message":
                return manager.appendCustomMessageEntry(entry.customType, entry.content, entry.display, entry.details);
              case "context_edit": {
                const targetId = copiedIds.get(entry.targetId);
                return targetId ? manager.appendContextEdit(targetId, entry.replacement) : undefined;
              }
              case "label": {
                const targetId = copiedIds.get(entry.targetId);
                return targetId ? manager.appendLabelChange(targetId, entry.label) : undefined;
              }
              case "session_info":
                return entry.name ? manager.appendSessionInfo(entry.name) : undefined;
            }
          };

          for (const entry of suffix) {
            const copiedId = copyEntry(entry);
            if (copiedId) copiedIds.set(entry.id, copiedId);
          }
        },
        withSession: async (replacementCtx) => {
          replacementCtx.ui.notify("Created a new session with the selected message and later messages.", "info");
        },
      });
    },
  });
}
