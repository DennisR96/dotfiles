const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync(require.resolve('./service_worker.js'), 'utf8');
const start = source.indexOf('const pendingFileChoosers = new Map();');
const end = source.indexOf('function waitForFileChooser(', start);
const listeners = {};
const context = vm.createContext({
  chrome: {
    tabs: { onRemoved: { addListener: (fn) => { listeners.removed = fn; } } },
    debugger: { onEvent: { addListener: (fn) => { listeners.event = fn; } } },
  },
  Date, Map, Set,
});
vm.runInContext(`const attachedTabs = new Map([[1, {debuggee: {tabId: 1}}], [2, {debuggee: {targetId: 'target-2'}}]]);\n${source.slice(start, end)}`, context);
const list = (tab) => vm.runInContext(`browserConsoleByTab.get(${tab})?.messages || []`, context);

test('captures browser resource failures by tab and collapses duplicate Log/Network reports', () => {
  listeners.event({ tabId: 1 }, 'Network.requestWillBeSent', { requestId: 'r', request: { url: 'https://example.org/app.js' } });
  listeners.event({ tabId: 1 }, 'Network.loadingFailed', { requestId: 'r', errorText: 'net::ERR_CONNECTION_REFUSED' });
  listeners.event({ tabId: 1 }, 'Log.entryAdded', { entry: { source: 'network', level: 'error', text: 'Failed to load resource: net::ERR_CONNECTION_REFUSED', url: 'https://example.org/app.js', timestamp: Date.now() / 1000 } });
  assert.equal(list(1).length, 1);
  assert.equal(list(1)[0].args[0], 'Failed to load resource: net::ERR_CONNECTION_REFUSED');
  assert.equal(list(1)[0].url, 'https://example.org/app.js');
  listeners.event({ tabId: 1 }, 'Network.requestWillBeSent', { requestId: 'retry', request: { url: 'https://example.org/app.js' } });
  listeners.event({ tabId: 1 }, 'Network.loadingFailed', { requestId: 'retry', errorText: 'net::ERR_CONNECTION_REFUSED' });
  assert.equal(list(1).length, 2, 'separate failed attempts must remain visible');
  listeners.event({ targetId: 'target-2' }, 'Log.entryAdded', { entry: { source: 'network', text: 'another failure' } });
  assert.equal(list(2).length, 1);
  listeners.event({ tabId: 3 }, 'Log.entryAdded', { entry: { text: 'unattached' } });
  assert.equal(list(3).length, 0);
  listeners.removed(1);
  assert.equal(list(1).length, 0);
});

test('skips canceled requests and JS errors; caps messages and request URL lookup', () => {
  listeners.event({ tabId: 1 }, 'Network.loadingFailed', { requestId: 'c', canceled: true, errorText: 'net::ERR_ABORTED' });
  listeners.event({ tabId: 1 }, 'Log.entryAdded', { entry: { source: 'javascript', text: 'page error' } });
  assert.equal(list(1).length, 0);
  for (let i = 0; i < 505; i++) listeners.event({ tabId: 1 }, 'Log.entryAdded', { entry: { source: 'network', text: `failure ${i}` } });
  assert.equal(list(1).length, 500);
  assert.equal(list(1)[0].args[0], 'failure 5');
  for (let i = 0; i < 1005; i++) listeners.event({ tabId: 1 }, 'Network.requestWillBeSent', { requestId: `r${i}`, request: { url: `https://example.org/${i}` } });
  assert.equal(vm.runInContext('browserConsoleByTab.get(1).requests.size', context), 1000);
});
