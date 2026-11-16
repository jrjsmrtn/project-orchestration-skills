// SPDX-FileCopyrightText: 2026 Georges Martin <jrjsmrtn@gmail.com>
// SPDX-License-Identifier: MIT
// usage: node validate-mermaid.mjs FILE.md...    exit 0 every diagram renders | 1 one failed | 2 usage or nothing found
import { readFileSync } from 'node:fs';
import { PeleError, render } from 'pele';

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error('usage: validate-mermaid.mjs FILE.md...');
  process.exit(2);
}
let blocks = 0;
let failed = 0;
for (const file of files) {
  const lines = readFileSync(file, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (!/^\s*```mermaid\s*$/.test(lines[i])) continue;
    const start = i + 2; // 1-based line of the first diagram line
    const body = [];
    for (i++; i < lines.length && !/^\s*```\s*$/.test(lines[i]); i++) body.push(lines[i]);
    blocks++;
    try {
      const { svg } = render(body.join('\n'));
      if (!svg || !svg.includes('<svg')) throw new Error('render() returned no SVG');
      console.log(`ok    ${file}:${start - 1} (${body.length} lines, ${svg.length} bytes of SVG)`);
    } catch (error) {
      failed++;
      if (error instanceof PeleError) {
        const at = error.line ? ` at diagram line ${error.line}, column ${error.column} (file line ${start - 1 + error.line})` : '';
        console.log(`FAIL  ${file}:${start - 1} ${error.code}${at}: ${String(error.message).split('\n')[0]}`);
      } else console.log(`FAIL  ${file}:${start - 1} ${error.message}`);
    }
  }
}
if (blocks === 0) {
  console.error('FAIL  no ```mermaid block found: nothing was checked');
  process.exit(2);
}
console.log(`${blocks - failed} of ${blocks} diagram(s) render`);
process.exit(failed ? 1 : 0);
