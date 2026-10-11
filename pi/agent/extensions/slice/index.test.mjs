import test from "node:test";
import assert from "node:assert/strict";
import sliceExtension from "./index.ts";

function harness({ branch = [], hasUI = true, selectedIndex = 0 } = {}) {
  let command;
  const notifications = [];
  const appended = [];
  let pickerLabels;
  let sessionOptions;
  let waited = false;

  sliceExtension({
    registerCommand(name, definition) {
      assert.equal(name, "slice");
      command = definition;
    },
  });

  const manager = Object.fromEntries([
    ["appendMessage", (message) => { appended.push(["message", message]); return `new-${appended.length}`; }],
    ["appendModelChange", (...args) => { appended.push(["model_change", ...args]); return `new-${appended.length}`; }],
    ["appendThinkingLevelChange", (...args) => { appended.push(["thinking_level_change", ...args]); return `new-${appended.length}`; }],
    ["appendCustomEntry", (...args) => { appended.push(["custom", ...args]); return `new-${appended.length}`; }],
    ["appendCustomMessageEntry", (...args) => { appended.push(["custom_message", ...args]); return `new-${appended.length}`; }],
    ["appendContextEdit", (...args) => { appended.push(["context_edit", ...args]); return `new-${appended.length}`; }],
    ["appendLabelChange", (...args) => { appended.push(["label", ...args]); return `new-${appended.length}`; }],
    ["appendSessionInfo", (...args) => { appended.push(["session_info", ...args]); return `new-${appended.length}`; }],
  ]);

  const ctx = {
    hasUI,
    ui: {
      notify: (...args) => notifications.push(args),
      select: async (_prompt, labels) => {
        pickerLabels = labels;
        return selectedIndex === null ? undefined : labels[selectedIndex];
      },
    },
    waitForIdle: async () => { waited = true; },
    sessionManager: { getBranch: () => branch, getSessionFile: () => "/tmp/parent.jsonl" },
    newSession: async (options) => {
      sessionOptions = options;
      await options.setup(manager);
      await options.withSession({ ui: ctx.ui });
    },
  };

  return {
    run: () => command.handler("", ctx),
    notifications, appended, get pickerLabels() { return pickerLabels; },
    get sessionOptions() { return sessionOptions; }, get waited() { return waited; },
  };
}

const message = (id, role, content) => ({ id, type: "message", message: { role, content } });

test("warns and returns when there is no UI", async () => {
  const h = harness({ hasUI: false });
  await h.run();
  assert.deepEqual(h.notifications, [["/slice needs an interactive message picker.", "warning"]]);
  assert.equal(h.waited, false);
  assert.equal(h.sessionOptions, undefined);
});

test("reports an empty active branch", async () => {
  const h = harness({ branch: [{ id: "sys", type: "message", message: { role: "system", content: "hidden" } }] });
  await h.run();
  assert.deepEqual(h.notifications, [["No messages in the active branch.", "info"]]);
  assert.equal(h.pickerLabels, undefined);
});

test("copies the selected message and later entries, remapping linked IDs", async () => {
  const branch = [
    message("before", "user", "skip me"),
    message("selected", "assistant", [{ type: "text", text: "  hello\\n world " }, { type: "image" }]),
    { id: "model", type: "model_change", provider: "p", modelId: "m" },
    { id: "edit", type: "context_edit", targetId: "selected", replacement: "changed" },
    { id: "label", type: "label", targetId: "selected", label: "checkpoint" },
    message("system", "system", "omit"),
    message("later", "user", "keep me"),
  ];
  const h = harness({ branch, selectedIndex: 1 });
  await h.run();

  assert.deepEqual(h.pickerLabels, ["1. user: skip me", "2. assistant: hello\\n world [image]", "3. user: keep me"]);
  assert.equal(h.sessionOptions.parentSession, "/tmp/parent.jsonl");
  assert.deepEqual(h.appended, [
    ["message", branch[1].message],
    ["model_change", "p", "m"],
    ["context_edit", "new-1", "changed"],
    ["label", "new-1", "checkpoint"],
    ["message", branch[6].message],
  ]);
  assert.deepEqual(h.notifications.at(-1), ["Created a new session with the selected message and later messages.", "info"]);
});

test("does not create a session when the picker is cancelled", async () => {
  const h = harness({ branch: [message("one", "user", "hello")], selectedIndex: null });
  await h.run();
  assert.equal(h.sessionOptions, undefined);
});
