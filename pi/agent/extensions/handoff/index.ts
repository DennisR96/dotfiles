import { readFileSync } from "node:fs";
import { getHandoffMessages } from "./messages.js";
import { type Message, uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@earendil-works/pi-coding-agent";

const SYSTEM_PROMPT = readFileSync(new URL("./system-prompt.md", import.meta.url), "utf8").trim();

export default function(pi: ExtensionAPI) {
  pi.registerCommand("handoff", {
    description: "Transfer context to a new focused session",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("handoff requires interactive mode", "error");
        return;
      }

      if (!ctx.model) {
        ctx.ui.notify("No model selected", "error");
        return;
      }

      const goal = args.trim();
      if (!goal) {
        ctx.ui.notify("Usage: /handoff <goal for new thread>", "error");
        return;
      }

      const messages = getHandoffMessages(ctx.sessionManager.getBranch());

      if (messages.length === 0) {
        ctx.ui.notify("No conversation to hand off", "error");
        return;
      }

      const llmMessages = convertToLlm(messages);
      const conversationText = serializeConversation(llmMessages);
      const currentSessionFile = ctx.sessionManager.getSessionFile();

      const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
        const loader = new BorderedLoader(tui, theme, `Generating handoff prompt...`);
        loader.onAbort = () => done(null);

        const doGenerate = async () => {
          const userMessage: Message = {
            role: "user",
            content: [
              {
                type: "text",
                text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
              },
            ],
            timestamp: Date.now(),
          };

          const response = await ctx.modelRegistry.complete(
            ctx.model!,
            { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
            {
              signal: loader.signal,
              cacheRetention: "none",
              sessionId: uuidv7(),
            },
          );

          if (response.stopReason === "aborted") {
            return null;
          }

          return response.content
            .filter((c): c is { type: "text"; text: string } => c.type === "text")
            .map((c) => c.text)
            .join("\n");
        };

        doGenerate()
          .then(done)
          .catch((err) => {
            console.error("Handoff generation failed:", err);
            done(null);
          });

        return loader;
      });

      if (result === null) {
        ctx.ui.notify("Cancelled", "info");
        return;
      }

      const editedPrompt = await ctx.ui.editor("Edit handoff prompt", result);

      if (editedPrompt === undefined) {
        ctx.ui.notify("Cancelled", "info");
        return;
      }

      const newSessionResult = await ctx.newSession({
        parentSession: currentSessionFile,
        withSession: async (replacementCtx) => {
          replacementCtx.ui.setEditorText(editedPrompt);
          replacementCtx.ui.notify("Handoff ready. Submit when ready.", "info");
        },
      });

      if (newSessionResult.cancelled) {
        ctx.ui.notify("New session cancelled", "info");
      }
    },
  });
}
