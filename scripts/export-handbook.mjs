// Export the repository-authored web handbook as offline Markdown.
import { guides } from '../website/guides.js';
import { writeFile } from 'node:fs/promises';
const decode = text => text.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"');
const inline = html => decode(html
  .replace(/<a href="docs.html\?guide=([^"]+)">(.*?)<\/a>/gs, '[$2](#$1)')
  .replace(/<a href="themes.html">(.*?)<\/a>/gs, '[$1](../website/themes.html)')
  .replace(/<a href="([^"]+)">(.*?)<\/a>/gs, '[$2]($1)')
  .replace(/<(?:code|kbd)>(.*?)<\/(?:code|kbd)>/gs, '`$1`')
  .replace(/<[^>]+>/g, '').trim());
function markdown(html) {
  const blocks = [];
  let text = html.replace(/<pre><code>(.*?)<\/code><\/pre>/gs, (_, code) => {
    blocks.push(`\n\n\`\`\`sh\n${decode(code)}\n\`\`\`\n\n`);
    return `BLOCKTOKEN${blocks.length - 1}END`;
  }).replace(/<table>(.*?)<\/table>/gs, (_, table) => {
    const rows = [...table.matchAll(/<tr>(.*?)<\/tr>/gs)].map(match => [...match[1].matchAll(/<t[dh]>(.*?)<\/t[dh]>/gs)].map(cell => inline(cell[1])));
    return '\n\n' + rows.map((row, i) => '| ' + row.join(' | ') + ' |' + (i === 0 ? '\n|' + row.map(() => ' --- ').join('|') + '|' : '')).join('\n') + '\n\n';
  });
  text = text.replace(/<h1>(.*?)<\/h1>/gs,'### $1\n\n')
    .replace(/<h2>(.*?)<\/h2>/gs,'\n\n#### $1\n\n')
    .replace(/<h3>(.*?)<\/h3>/gs,'\n\n##### $1\n\n')
    .replace(/<p>(.*?)<\/p>/gs,(_, p) => '\n\n'+inline(p)+'\n\n')
    .replace(/<li>(.*?)<\/li>/gs,(_, li) => '\n- '+inline(li))
    .replace(/<div class="doc-note">(.*?)<\/div>/gs,(_, note) => '\n\n> '+inline(note)+'\n\n')
    .replace(/<\/?(?:ol|ul)>/g,'\n')
    .replace(/<[^>]+>/g,'')
    .replace(/^[ \t]+/gm,'').replace(/\n{3,}/g,'\n\n');
  text = text.replace(/BLOCKTOKEN(\d+)END/g, (_, index) => blocks[Number(index)]);
  return text.replace(/\n{3,}/g, "\n\n").trim();
}
const toc = guides.map(g => `- [${g.title}](#${g.id})`).join('\n');
const output = '# Specter handbook\n\nGenerated from `website/guides.js` with `node scripts/export-handbook.mjs`.\n\n'+toc+'\n\n'+guides.map(g => `<a id="${g.id}"></a>\n\n## ${g.title}\n\n${markdown(g.body)}`).join('\n\n---\n\n')+'\n';
await writeFile(new URL('../docs/handbook.md', import.meta.url), output);
console.log(`Exported ${guides.length} chapters to docs/handbook.md`);

const styles = `:root{font:15px/1.75 -apple-system,BlinkMacSystemFont,sans-serif;color:#282a24;background:#f7f7f2}body{margin:0}a{color:#3d5e46}a:focus-visible{outline:3px solid #688675;outline-offset:4px}.layout{display:grid;grid-template-columns:220px minmax(0,780px);gap:55px;max-width:1100px;margin:45px auto;padding:0 28px}nav{position:sticky;top:28px;align-self:start;display:flex;flex-direction:column;gap:10px}nav strong{font-size:24px;margin-bottom:15px}nav a{text-decoration:none;font-size:13px}h1{font-size:42px;font-weight:400;letter-spacing:-2px}h2{font-size:30px;font-weight:400;line-height:1.3}h3{font-size:20px;font-weight:500;margin-top:28px}p,li{color:#575c51}article{padding:22px 0 38px;border-bottom:1px solid #dddfd5}pre{padding:20px;background:#232c25;color:#e2e8dc;border-radius:6px;white-space:pre-wrap}code,kbd{font:12px/1.7 ui-monospace,Menlo,monospace}table{border-collapse:collapse;width:100%;font-size:13px}td,th{text-align:left;padding:12px 8px;border-bottom:1px solid #dddfd5;vertical-align:top}.doc-note{padding:16px;border-left:3px solid #708060;background:#eaeedf}section{scroll-margin-top:20px}@media(max-width:720px){.layout{grid-template-columns:1fr;gap:25px;margin:24px auto;padding:0 20px}nav{position:static;display:grid;grid-template-columns:1fr 1fr}nav strong{grid-column:1/-1}h1{font-size:34px}}`;
const standaloneBody = guides.map(g => `<article id="${g.id}"><h2>${g.title}</h2>${g.body
  .replace(/<h1>.*?<\/h1>/s, '')
  .replaceAll('<h2>', '<h3>').replaceAll('</h2>', '</h3>')
  .replace(/href="docs.html\?guide=([^"]+)"/g, 'href="#$1"')
  .replaceAll('<a href="themes.html">web theme browser</a>', 'website’s theme browser')}</article>`).join('\n');
const standalone = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Specter — Offline handbook</title><style>${styles}</style></head><body><div class="layout"><nav aria-label="Handbook chapters"><strong>specter / handbook</strong>${guides.map(g => `<a href="#${g.id}">${g.title}</a>`).join('')}</nav><main><h1>A little guidance.</h1><p>This handbook is included with Specter and works offline. No scripts, accounts, or network connection are needed to read it.</p>${standaloneBody}</main></div></body></html>`;
await writeFile(new URL('../Resources/Handbook.html', import.meta.url), standalone.replace(/[ \t]+$/gm, ''));
console.log('Exported self-contained Resources/Handbook.html for the app Help menu.');
