import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { SessionEntry } from "@earendil-works/pi-coding-agent";

function entryToMessage(entry: SessionEntry): AgentMessage | undefined {
  if (entry.type === "message") {
    return entry.message;
  }
  if (entry.type === "compaction") {
    return {
      role: "compactionSummary",
      summary: entry.summary,
      tokensBefore: entry.tokensBefore,
      timestamp: new Date(entry.timestamp).getTime(),
    };
  }
  return undefined;
}

export function getHandoffMessages(branch: SessionEntry[]): AgentMessage[] {
  let compactionIndex = -1;
  for (let i = branch.length - 1; i >= 0; i--) {
    if (branch[i].type === "compaction") {
      compactionIndex = i;
      break;
    }
  }
  if (compactionIndex < 0) {
    return branch.map(entryToMessage).filter((message) => message !== undefined);
  }

  const compaction = branch[compactionIndex];
  const firstKeptIndex =
    compaction.type === "compaction" ? branch.findIndex((entry) => entry.id === compaction.firstKeptEntryId) : -1;
  const compactedBranch = [
    compaction,
    ...(firstKeptIndex >= 0 ? branch.slice(firstKeptIndex, compactionIndex) : []),
    ...branch.slice(compactionIndex + 1),
  ];
  return compactedBranch.map(entryToMessage).filter((message) => message !== undefined);
}
