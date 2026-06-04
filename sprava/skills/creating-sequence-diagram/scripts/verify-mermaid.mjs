#!/usr/bin/env node
// Validate every ```mermaid block in the given markdown file(s) with mermaid's own parser, headless.
//
// Run it from a directory whose node_modules has `mermaid` and `jsdom` (e.g. the app package — in this
// repo, `ide/`). Module resolution is anchored at the CWD, so the script works wherever it is bundled.
//
// Exit codes: 0 = all blocks parse, 1 = a block failed, 2 = could not verify (deps missing / bad usage).
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { join } from 'node:path';

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('usage: verify-mermaid.mjs <file.md> [...]  (run from a dir with mermaid + jsdom)');
  process.exit(2);
}

// Resolve mermaid/jsdom from the CWD's node_modules, not the script's location.
const requireFromCwd = createRequire(pathToFileURL(join(process.cwd(), '_resolve_.js')));
let JSDOM;
try {
  ({ JSDOM } = await import(pathToFileURL(requireFromCwd.resolve('jsdom')).href));
} catch {
  console.error('✗ cannot verify: install `mermaid` and `jsdom`, or run from a dir that has them.');
  process.exit(2);
}

// Mirror the jsdom window onto globalThis so mermaid's browser code finds every global it expects
// (document, navigator, Option, DOMParser, …). A missing global throws a ReferenceError that
// masquerades as a diagram syntax error — so mirror the WHOLE window, not just document/navigator.
// This MUST happen BEFORE importing mermaid: its bundled DOMPurify reads `window` at module-load time
// and silently degrades (DOMPurify.addHook missing) if the window isn't there yet.
const dom = new JSDOM('<!DOCTYPE html><body></body>', { pretendToBeVisual: true });
for (const key of Object.getOwnPropertyNames(dom.window)) {
  if (key in globalThis) continue;
  try {
    Object.defineProperty(globalThis, key, { get: () => dom.window[key], configurable: true });
  } catch {
    /* read-only window prop — skip */
  }
}

let mermaid;
try {
  mermaid = (await import(pathToFileURL(requireFromCwd.resolve('mermaid')).href)).default;
} catch {
  console.error('✗ cannot verify: install `mermaid` and `jsdom`, or run from a dir that has them.');
  process.exit(2);
}
mermaid.initialize({ startOnLoad: false });

function extractBlocks(md) {
  const re = /```mermaid\r?\n([\s\S]*?)```/g;
  const blocks = [];
  let m;
  while ((m = re.exec(md)) !== null) {
    blocks.push({ line: md.slice(0, m.index).split('\n').length, code: m[1] });
  }
  return blocks;
}

let failures = 0;
for (const file of files) {
  const blocks = extractBlocks(readFileSync(file, 'utf8'));
  if (blocks.length === 0) {
    console.log(`• ${file}: no mermaid blocks`);
    continue;
  }
  for (const { line, code } of blocks) {
    try {
      await mermaid.parse(code);
      console.log(`✓ ${file}:${line} OK`);
    } catch (err) {
      failures++;
      console.log(`✗ ${file}:${line} ${(err?.message ?? String(err)).split('\n')[0]}`);
    }
  }
}
process.exit(failures > 0 ? 1 : 0);
