import { readFileSync, writeFileSync } from "node:fs";

const dir = process.argv[2] ?? ".";

function replaceOrThrow(input, pattern, replacement, label) {
  if (!pattern.test(input)) {
    throw new Error(`html-to-markdown demo: could not find ${label}`);
  }
  return input.replace(pattern, replacement);
}

let html = readFileSync(`${dir}/index.html`, "utf8");
html = replaceOrThrow(
  html,
  /[ \t]*<link rel="preconnect" href="https:\/\/fonts\.googleapis\.com" \/>\r?\n[ \t]*<link rel="preconnect" href="https:\/\/fonts\.gstatic\.com" crossorigin \/>\r?\n[ \t]*<link\s+href="https:\/\/fonts\.googleapis\.com\/css2\?[^"]*"\s+rel="stylesheet"\s*\/>\r?\n/,
  '    <link rel="stylesheet" href="fonts.css" />\n',
  "the Google Fonts <link> block",
);
writeFileSync(`${dir}/index.html`, html);

let js = readFileSync(`${dir}/script.js`, "utf8");
js = replaceOrThrow(
  js,
  /from "https:\/\/cdn\.jsdelivr\.net\/npm\/@xberg-io\/html-to-markdown-wasm@latest\/pkg\/web\/html_to_markdown_wasm\.js";/,
  'from "./html_to_markdown_wasm.js";',
  "the jsDelivr WASM import",
);
writeFileSync(`${dir}/script.js`, js);
