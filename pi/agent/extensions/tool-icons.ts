import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, type Component } from "@earendil-works/pi-tui";

// Plain, single-cell glyphs avoid inconsistent emoji widths across terminals.
const icons: Record<string, string> = {
  read: "▤",
  write: "✎",
  edit: "✎",
  bash: "⌘",
  grep: "⌕",
  find: "⌕",
  ls: "▣",
  subagent: "◇",
  codemode: "◇",
};

export default function (pi: ExtensionAPI) {
  pi.registerToolRenderer((toolName, next) => {
    const renderer = next();
    // Leave self-framed tools alone: they own their complete layout.
    if (!renderer?.renderCall || renderer.renderShell === "self") return renderer;

    return {
      ...renderer,
      renderCall(args, theme, context): Component {
        // Preserve Pi's argument formatting, partial-call handling and expanded view.
        const original = renderer.renderCall!(args, theme, context);
        const prefix = theme.fg("accent", `${icons[toolName] ?? "•"} `);
        const indent = " ".repeat(visibleWidth(prefix));
        return {
          render(width) {
            const available = Math.max(1, width - visibleWidth(prefix));
            return original.render(available).map((line, index) =>
              (index === 0 ? prefix : indent) + truncateToWidth(line, available, "…"),
            );
          },
          invalidate() {
            original.invalidate();
          },
        };
      },
    };
  });
}
