// 用 KaTeX 逐段渲染 docs/*.md 与 README.md 中的全部数学公式，
// throwOnError 抓 TeX 语法问题。用法：bun katex_check.js <root>
// 依赖仅在临时目录安装；本脚本不进仓库常规流程。
const { readdirSync, readFileSync, statSync } = require("fs");
const path = require("path");
const katex = require("katex");

const root = process.argv[2] || path.join(__dirname, "..");

function* walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) yield* walk(p);
    else if (name.endsWith(".md")) yield p;
  }
}

function stripCode(text) {
  // 去掉围栏代码块
  text = text.replace(/^[ \t]*(```|~~~)[\s\S]*?^[ \t]*\1[ \t]*$/gm, "");
  // 去掉行内代码
  text = text.replace(/`+[^`\n]*`+/g, "");
  return text;
}

const errors = [];
let nInline = 0, nDisplay = 0;

for (const file of walk(path.join(root, "docs"))) checkFile(file);
checkFile(path.join(root, "README.md"));

function checkFile(file) {
  const text = stripCode(readFileSync(file, "utf8"));
  const lines = text.split("\n");

  // 展示公式：$$ 独占行
  for (let i = 0; i < lines.length; i++) {
    if (/^\$\$\s*$/.test(lines[i])) {
      const body = [];
      let j = i + 1;
      while (j < lines.length && !/^\$\$\s*$/.test(lines[j])) {
        body.push(lines[j]);
        j++;
      }
      if (j >= lines.length) {
        errors.push(`${file}:${i + 1}: unclosed display block`);
        break;
      }
      nDisplay++;
      render(file, i + 1, body.join("\n"), true);
      i = j;
    } else if (lines[i].includes("$$")) {
      errors.push(`${file}:${i + 1}: inline $$ outside fence: ${lines[i].slice(0, 60)}`);
    }
  }

  // 行内公式（逐行，跨行对仅 1 处且已合并）
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (/^\$\$/.test(line)) continue;
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
    errors.push(`${file}:${line}: ${e.message.split("\n")[0]} :: ${tex.slice(0, 80).replace(/\n/g, " ")}`);
  }
}

if (errors.length) {
  console.log(errors.join("\n"));
  console.log(`\n${errors.length} ERRORS (inline ${nInline}, display ${nDisplay})`);
  process.exit(1);
}
console.log(`KaTeX OK: ${nInline} inline, ${nDisplay} display`);
