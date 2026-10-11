import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const constants = readFileSync(new URL("./constants.ts", import.meta.url), "utf8");
const helper = readFileSync(new URL("./helper.ts", import.meta.url), "utf8")
  .replace('./constants.js', `data:text/javascript,${encodeURIComponent(constants)}`)
  .replace(/: string\[\]/g, "")
  .replace(/: (?:boolean|string)/g, "");
const { isInteractiveShellCommand } = await import(`data:text/javascript,${encodeURIComponent(helper)}`);

function withEnv(values, fn) {
  const previous = Object.fromEntries(Object.keys(values).map((key) => [key, process.env[key]]));
  for (const [key, value] of Object.entries(values)) {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
  try {
    fn();
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

test("recognizes default interactive commands and their arguments", () => {
  withEnv({ INTERACTIVE_COMMANDS: undefined, INTERACTIVE_EXCLUDE: undefined }, () => {
    assert.equal(isInteractiveShellCommand("vim"), true);
    assert.equal(isInteractiveShellCommand("  GIT COMMIT -m 'message'  "), true);
    assert.equal(isInteractiveShellCommand("kubectl edit deployment/app"), true);
    assert.equal(isInteractiveShellCommand("echo hello"), false);
  });
});

test("recognizes the explicit i prefix", () => {
  withEnv({ INTERACTIVE_COMMANDS: undefined, INTERACTIVE_EXCLUDE: undefined }, () => {
    assert.equal(isInteractiveShellCommand("i echo hello"), true);
    assert.equal(isInteractiveShellCommand("i\techo hello"), true);
    assert.equal(isInteractiveShellCommand("i"), false);
  });
});

test("recognizes interactive commands at the end of a pipeline", () => {
  withEnv({ INTERACTIVE_COMMANDS: undefined, INTERACTIVE_EXCLUDE: undefined }, () => {
    assert.equal(isInteractiveShellCommand("printf 'x' | less"), true);
    assert.equal(isInteractiveShellCommand("printf 'x' | less -R"), true);
    assert.equal(isInteractiveShellCommand("lesser file"), false);
  });
});

test("supports additional commands and case-insensitive exclusions", () => {
  withEnv({ INTERACTIVE_COMMANDS: "my-editor, custom tool", INTERACTIVE_EXCLUDE: "VIM, MY-EDITOR" }, () => {
    assert.equal(isInteractiveShellCommand("my-editor file"), false);
    assert.equal(isInteractiveShellCommand("vim file"), false);
    assert.equal(isInteractiveShellCommand("custom tool arg"), true);
    assert.equal(isInteractiveShellCommand("custom-tool"), false);
  });
});
