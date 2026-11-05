// 用 KaTeX 逐段渲染 docs/*.md 与 README.md 中的全部数学公式，
// throwOnError 抓 TeX 语法问题。用法：bun katex_check.js <root>
// 依赖仅在临时目录安装；本脚本不进仓库常规流程（tools/ 已 gitignore）。
// 与 probability 版的差别：单行展示公式允许 `> $$…$$` 引用形态。
// 展示公式为单行 $$…$$（Codeberg 不认多行 $$ 块）。
const { readdirSync, readFileSync, existsSync, statSync } = require("fs");
const path = require("path");
const katex = require("katex");

const root = process.argv[2] || path.join(__dirname, "..");

function walk(dir) {
  let out = [];
  for (const name of readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) out = out.concat(walk(p));
    else if (name.endsWith(".md")) out.push(p);
  }
  return out;
}

function stripCode(text) {
  // 去掉围栏代码块
  text = text.replace(/^[ \t]*(```|~~~)[\s\S]*?^[ \t]*\1[ \t]*$/gm, "");
  // 去掉行内代码（反向引用强制等长 run，与 CommonMark 一致；数学内
  // 孤立的 `` 像集记号也会被一并挖空，其原形已单独人工验证可渲染）
  text = text.replace(/(`+)([^`\n]*)\1/g, "");
  return text;
}

const DISPLAY_ONE_LINE = /^\s*(?:>\s*)*\$\$(.+?)\$\$\s*$/;
const QUOTE_RE = /^(?:[ \t]*>[ \t]?)+/;

const errors = [];
let nInline = 0, nDisplay = 0;

for (const file of walk(path.join(root, "docs"))) checkFile(file);
const readme = path.join(root, "README.md");
if (existsSync(readme)) checkFile(readme);

function checkFile(file) {
  const raw = stripCode(readFileSync(file, "utf8").replace(/\r\n/g, "\n"));
  const lines = raw.split("\n");
  const inDisplay = new Array(lines.length).fill(false);

  // 展示公式：$$…$$ 单行（可带 > 引用前缀；Codeberg 不解析多行 $$ 块）
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(DISPLAY_ONE_LINE);
    if (m) {
      inDisplay[i] = true;
      nDisplay++;
      render(file, i + 1, m[1], true);
    } else if (lines[i].includes("$$")) {
      errors.push(`${file}:${i + 1}: $$ not single-line display: ${lines[i].slice(0, 60)}`);
    }
  }

  // 行内公式
  for (let i = 0; i < lines.length; i++) {
    if (inDisplay[i]) continue;
    const line = lines[i].replace(QUOTE_RE, "");
    for (const m of line.matchAll(/(?<!\\)\$([^$\n]+)(?<!\\)\$/g)) {
      nInline++;
      render(file, i + 1, m[1], false);
    }
  }
}

function render(file, line, tex, display) {
  try {
    katex.renderToString(tex, {
      displayMode: display,
      throwOnError: true,
      strict: false,
      output: "html",
    });
  } catch (e) {
    errors.push(
      `${file}:${line}: ${e.message.split("\n")[0]} :: ${tex
        .slice(0, 100)
        .replace(/\n/g, " ")}`
    );
  }
}

if (errors.length) {
  console.log(errors.join("\n"));
  console.log(`\n${errors.length} ERRORS (inline ${nInline}, display ${nDisplay})`);
  process.exit(1);
}
console.log(`KaTeX OK: ${nInline} inline, ${nDisplay} display`);
