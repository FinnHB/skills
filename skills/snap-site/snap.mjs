#!/usr/bin/env node
// Screenshot pages of a local dev server at multiple viewport widths.
// Usage: node snap.mjs [--url http://localhost:1313] [--paths /,/blog/] [--widths 1920,768,375] [--out ./.screenshots]
import { mkdirSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

// Resolve playwright from this skill's own node_modules regardless of cwd
const require = createRequire(join(dirname(fileURLToPath(import.meta.url)), 'package.json'));
const { chromium } = require('playwright');

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

const url = arg('url', 'http://localhost:1313').replace(/\/$/, '');
const paths = arg('paths', '/').split(',').map((p) => p.trim());
const widths = arg('widths', '1920,768,375').split(',').map(Number);
const out = resolve(arg('out', './.screenshots'));

const slug = (p) => (p === '/' ? 'home' : p.replace(/^\/|\/$/g, '').replace(/[^a-zA-Z0-9_-]+/g, '-'));

mkdirSync(out, { recursive: true });

const browser = await chromium.launch();
const consoleErrors = [];
let failures = 0;

for (const path of paths) {
  for (const width of widths) {
    const page = await browser.newPage({ viewport: { width, height: 1080 } });
    page.on('console', (msg) => {
      if (msg.type() === 'error') consoleErrors.push(`[${path} @ ${width}w] ${msg.text()}`);
    });
    page.on('pageerror', (err) => consoleErrors.push(`[${path} @ ${width}w] ${err.message}`));
    const target = url + path;
    try {
      const resp = await page.goto(target, { waitUntil: 'networkidle', timeout: 15000 });
      if (!resp || !resp.ok()) throw new Error(`HTTP ${resp ? resp.status() : 'no response'}`);
      const file = join(out, `${slug(path)}-${width}w.png`);
      await page.screenshot({ path: file, fullPage: true });
      console.log(`wrote ${file}`);
    } catch (err) {
      failures++;
      console.error(`FAILED ${target} @ ${width}w: ${err.message}`);
    }
    await page.close();
  }
}

await browser.close();

console.log('\nCONSOLE ERRORS:');
if (consoleErrors.length === 0) console.log('(none)');
else consoleErrors.forEach((e) => console.log(e));

process.exit(failures > 0 ? 1 : 0);
