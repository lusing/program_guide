# Haskell 教程 Bird 书扩充实施计划（24 → 31 章六篇）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按《Haskell函数式程序设计》（Bird, TFwH 中译本）把 Haskell 教程从 24 章扩为 31 章六篇：原书 12 章核心全部自包含提炼（7 新章 + 5 深改章），导航对齐 Ada/Zig 标准，工具链升到 GHC 9.14.1。

**Architecture:** 先 OCR 全书落盘取材 → 9.14.1 基线构建修回归 → 一次性重编号（docs+examples+模块名+交叉引用+导航页脚+README 六篇）→ 逐章写作（每章 docs+示例+单验+提交）→ 收官全量审计。

**Tech Stack:** GHC 9.14.1（scoop current）、stack 3.11.1（TUNA 镜像）、纯 boot 库主线（mtl/parsec/text/containers）、pdftoppm + rapidocr-onnxruntime 1.2.3（CUDA，cudnn 9.24）。

**Spec:** `docs/superpowers/specs/2026-10-06-haskell-bird-enrichment-design.md`

## Global Constraints（每个任务隐含遵守）

- GHC **9.14.1**（`G:\scoop\apps\haskell\current`）；主线只用 boot 库，零 hackage 依赖。
- 每个示例 main 开头 `hSetEncoding stdout utf8` + `hSetEncoding stderr utf8`（控制台 GBK）；写文件显式 UTF-8 句柄。
- GHC 9.12+ 默认 `-Wx-partial`：禁 head/last/tail/init，全函数替代（`foldr (\x _ -> x)` 取首、`foldl (\_ x -> x)` 取末）。
- 验证六条判定：编译 0 / 运行 0 / stderr 空 / stdout 非空无控制字符 / `==== NN 结束 ====` 标记 / 无诊断字样。命令 `pwsh ./build.ps1 -Example NN_topic`、全量 `-All`。
- docs 新写/深改章：≥200 行、文字行多于代码行、全部讲解代码正文内嵌、段段有"为什么/在做什么"、章末"对应示例（可选）：…"指路放结尾。
- 章头标注书源：`> 本章对应原书第 N 章〈标题〉…`（仅书映射章）。页脚导航（所有章）：
  `---` 换行后 `上一章：[XX 标题](xx-slug.md) ｜ 下一章：[XX 标题](xx-slug.md) ｜ 返回：[README](../README.md)`；第 01 章省"上一章"，第 31 章写 `下一章：（完）`。
- 每章一个 `examples/NN_topic/`（章号=目录号）：`ChNN.hs`（库）+ `main.hs`（演示+自检+结束标记）+ `runtests.hs`（断言），非 stack 工程（27/31 除外）。
- 新坑位随手追加进 `CHEATSheet.md` 坑位表（现象/原因/后果三段）。
- 提交信息格式 `feat(haskell): 批次N——…`，结尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## 章号映射与最终目录（Task 3 的唯一事实源）

**docs 重命名**（旧→新）：
`10-laziness→12-laziness`、`11-containers→14-containers`、`12-strings→15-strings`、`13-fam→16-fam`、`14-mtl→17-mtl`、`15-parsec→22-parsec`、`16-files→19-files`、`17-errors→20-errors`、`18-th→24-th`、`19-performance→25-performance`、`20-stack→27-stack`、`21-testing→28-testing`、`22-concurrency→29-concurrency`、`23-ffi→30-ffi`、`24-capstone→31-capstone`（均 `.md`）。

**examples 目录重命名**：`10_laziness→12_laziness`、`11_containers→14_containers`、`12_strings→15_strings`、`13_fam→16_fam`、`14_mtl→17_mtl`、`15_parsec→22_parsec`、`16_files→19_files`、`17_errors→20_errors`、`18_th→24_th`、`19_performance→25_performance`、`20_stackenv→27_stackenv`、`21_testing→28_testing`、`22_concurrency→29_concurrency`、`23_ffi→30_ffi`、`24_capstone→31_capstone`。

**新建**（Task 8–15 逐个落位）：`10-sudoku/10_sudoku`、`11-proofs/11_proofs`、`13-infinite/13_infinite`、`18-st/18_st`、`21-miniparser/21_miniparser`、`23-calculator/23_calculator`、`26-pretty/26_pretty`。

**数字映射表**（01–09 恒等）：10→12、11→14、12→15、13→16、14→17、15→22、16→19、17→20、18→24、19→25、20→27、21→28、22→29、23→30、24→31。

**31 章标题表**（页脚导航与 README 索引用）：
01 全景、02 第一个程序、03 数值、04 控制流、05 函数、06 模式匹配、07 代数数据类型、08 类型类、09 列表与折叠、10 数独解题器、11 证明与归纳、12 惰性求值、13 无穷列表、14 容器、15 字符串、16 函子·应用·单子、17 单子变换器、18 命令式函数式：State 与 ST、19 文件、20 错误处理、21 手写解析器组合子、22 parsec、23 交互式计算器、24 Template Haskell、25 性能、26 优美打印、27 Stack 工程、28 测试、29 并发与 STM、30 FFI、31 实战：MiniLang。

**六篇**：一 语言基础 01–08 ｜ 二 列表与推理 09–15 ｜ 三 单子与结构 16–20 ｜ 四 解析与实战 21–23 ｜ 五 工程与性能 24–30 ｜ 六 收官 31。

---

### Task 1: OCR 全书落盘

**Files:**
- Create: `haskell/materials/book/ch01.txt` … `ch12.txt`、`answers.txt`（按书章合并的 UTF-8 文本）
- Create: `F:\temp\hsbird\pages\p-NNN.png`（200dpi 渲染，仅临时，不进库）、`F:\temp\hsbird\ocr_pages.py`

**Interfaces:**
- Produces: 12 个书章文本 + 答案文本，供 Task 4–15 取材。书页 → PDF 页偏移 **+8**。

- [x] **Step 1: 渲染全部 241 页**（已完成 1–12，续跑 13–241；分批防超时）

```bash
cd /f/temp/hsbird && pdftoppm -png -r 200 -f 13 -l 241 "G:/book/计算机/haskell/Haskell函数式程序设计 (理查德·伯德) (z-library.sk, 1lib.sk, z-lib.sk).pdf" pages/p
```

- [x] **Step 2: 批量 OCR 脚本**（逐页写 `pages_txt/p-NNN.txt`，断点续跑；输出落盘不走控制台）

```python
# ocr_pages.py — 用法: PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" python ocr_pages.py
import glob, os
from rapidocr_onnxruntime import RapidOCR
ocr = RapidOCR()
os.makedirs('pages_txt', exist_ok=True)
for img in sorted(glob.glob('pages/p-*.png')):
    out = 'pages_txt/' + os.path.basename(img).replace('.png', '.txt')
    if os.path.exists(out):
        continue
    res, _ = ocr(img)
    with open(out, 'w', encoding='utf-8') as f:
        for item in (res or []):
            try: sc = float(item[2])
            except Exception: sc = -1
            if sc > 0.55:
                f.write(item[1] + '\n')
    print(img, 'done', flush=True)
```

- [x] **Step 3: 按书章合并**（PDF 页区间，偏移 +8）

| 文件 | PDF 页 | 文件 | PDF 页 |
|---|---|---|---|
| ch01 | 9–22 | ch08 | 129–147 |
| ch02 | 23–40 | ch09 | 148–166 |
| ch03 | 41–49 | ch10 | 167–191 |
| ch04 | 50–70 | ch11 | 192–206 |
| ch05 | 71–80 | ch12 | 207–232 |
| ch06 | 81–104 | answers | 233–241 |
| ch07 | 105–128 | | |

```bash
mkdir -p G:/code/guide/haskell/materials/book
cd /f/temp/hsbird
declare -A M=([ch01]="9 22" [ch02]="23 40" [ch03]="41 49" [ch04]="50 70" [ch05]="71 80" [ch06]="81 104" [ch07]="105 128" [ch08]="129 147" [ch09]="148 166" [ch10]="167 191" [ch11]="192 206" [ch12]="207 232" [answers]="233 241")
for k in "${!M[@]}"; do set -- ${M[$k]}; { for ((p=$1; p<=$2; p++)); do printf '\n===== PDF %d =====\n' "$p"; cat "pages_txt/p-$(printf %03d $p).txt"; done; } > "G:/code/guide/haskell/materials/book/$k.txt"; done
```

- [x] **Step 4: 校验**：每章文件头部 grep 关键词（ch01 何谓、ch05 数独、ch06 证明、ch07 效率、ch08 打印、ch09 无穷、ch10 单子或状态、ch11 语法分析、ch12 计算）。任何一章对不上即核对页界并修合并脚本。
- [x] **Step 5: 提交**：`git add haskell/materials` → `feat(haskell): 批次一a——Bird 书全书 OCR 落盘（materials/book）`。

### Task 2: GHC 9.14.1 基线构建 + stack 工程升版

**Files:**
- Modify: `haskell/examples/20_stackenv/stack.yaml`、`haskell/examples/24_capstone/stack.yaml`（compiler 行 ghc-9.12.1 → ghc-9.14.1；resolver 视 global-hints 可用性决定是否升）
- Modify: 受 9.14 回归影响的示例源码（届时定位）

**Interfaces:**
- Produces: 23 例在 9.14.1 全绿的基线；两个 stack 工程可离线构建。

- [x] **Step 1: 跑基线** `cd G:/code/guide/haskell && pwsh -File build.ps1 -All`，逐例记录失败（预期风险：stack 钉 9.12.1 报"compiler not found"、新默认警告、boot 库 API 变动）。
- [x] **Step 2: stack 升版**：两个 stack.yaml `compiler: ghc-9.14.1`；若 pantry 缺 global-hints，按 20 章既有手册从 TUNA（fpco/stackage-content 路径）手动下载 `ghc-9.14.1.yaml` 放入 pantry 缓存；resolver 保持 `lts-24.59`（纯 boot 库可跨版本）。单独验证 `pwsh -File build.ps1 -Example 20_stackenv`、`-Example 24_capstone`。
- [x] **Step 3: 修非 stack 回归**：新警告→全函数化/局部 `{-# OPTIONS_GHC -Wno-xxx #-}` 仅当确属误报教学取舍；API 变动→按 9.14 改写并回填文档相应段落。
- [x] **Step 4: 全量绿** `pwsh -File build.ps1 -All`。
- [x] **Step 5: 提交** `feat(haskell): 批次一b——GHC 9.14.1 基线迁移与 stack 钉版升级`。

### Task 3: 重编号 + 全套导航 + README 六篇

**Files:**
- Rename: 上表全部 docs/examples（`git mv` 两段式）
- Modify: 全部 docs/*.md（标题号 `# NN ·`、节号 `## NN.x`、交叉引用）、examples 内 `ChNN` 模块名与 `==== NN 结束 ====` 标记、`build.ps1`、`run-all.sh`（`20_stackenv`/`24_capstone` 特判字符串）、`README.md`、`CHEATSheet.md`
- Create: `haskell/tools/nav_audit.py`（导航与链接审计）

**Interfaces:**
- Produces: 31 个 docs 文件名（10/11/13/18/21/23/26 七个新章文件此时尚不存在，页脚与 README 已按最终编号指向，Task 8–15 逐个补齐）、31 个 examples 目录号位。

- [x] **Step N: 两段式移动**（先全部 `git mv` 到 `__tmp_*`，再落最终名，避免 10↔12↔15 碰撞）。docs 同规则。
- [x] **Step N: 目录内改名**：每个被移动示例目录内 `ChNN.hs` 改名+`module ChNN` 改名；`main.hs`/`runtests.hs` 的 `import ChNN`、`==== NN 结束 ====`、自述文本同步。
- [x] **Step N: 引用清扫脚本**（python，映射表见上）：
  1. 路径引用 `examples/(\d{2})_[a-z]+` → 新号；
  2. `Ch(\d{2})` → 新号；
  3. 被移动 docs 自身标题 `^# (\d{2})`、节号 `^(#{2,4}) (\d{2})\.(\d)` → 新号；
  4. 全库 prose 引用 `(?<![\d.])(\d{2})(?=\s*章)` 与 `第 ?(\d{2}) ?章` → 新号；`NN/NN 章` 列表逐个数字过映射；
  5. `build.ps1`/`run-all.sh` 内 `'20_stackenv'`/`'24_capstone'` 字符串 → `27_stackenv`/`31_capstone`；
  6. 排除误伤白名单：版本号 `9.12`、代码行、日期、`Float` 等——脚本只动满足上述上下文的匹配。
- [x] **Step N: 人工审计**：`grep -rnoE '[0-9]{2} ?章' haskell/docs haskell/CHEATSheet.md haskell/README.md` 逐条核对；重点四类漏网（cpp20 教训）：README/CHEATSheet 表、章内"见 NN.N 节"小节号、examples 自述文本、页脚导航。
- [x] **Step N: 页脚导航**：按 31 章标题表给全部 31 个 docs 文件加页脚（新章文件未建，先跳过；已存在章全部加）。
- [x] **Step N: README 重写**：六篇分组章节索引表（Ada 式 `| **篇一 语言基础** | | |` 分组行 + ⭐ 标注 + 书源标注 `(书N)`），新章行尾标 `（本轮新增）`；目录结构、工具链表（GHC 9.14.1 / stack 3.11.1 / 清华镜像）更新。
- [x] **Step N: nav_audit.py**：校验 docs/*.md 页脚 prev/next 目标存在（新章暂缺的白名单跳过）、README 表链接存在、`# NN ·` 标题号=文件名号。
- [x] **Step 8: 验证** `pwsh -File build.ps1 -All`（30 个目录全绿——新章目录还不存在）+ `bash run-all.sh` 干跑一轮（本机 Git Bash 可跑 GHC 路径）。
- [x] **Step N: 提交** `feat(haskell): 批次二——24→31 章六篇重编号与全套导航`。

### Task 4: 深改 01 全景（书1）

**Files:**
- Modify: `haskell/docs/01-overview.md`（86 → ≥200 行）
- 无示例（保持 01 无示例）。

**Interfaces:**
- Consumes: `materials/book/ch01.txt`（函数的实质、应用记号、例子思想、Haskell 平台）。
- Produces: 章头书源标注 + 新节"计算即代入"。

- [x] **Step 1: 读 ch01.txt**，提炼：函数即映射 `f :: X -> Y` 的数学观、应用记号（`f x` 空格、`logBase 2 10`、`add (3,4)` 元组对照）、两个动机例子（书 1.3/1.4）的思想骨架。
- [x] **Step 2: 写正文**：在现有结构上增补——1.x"函数的实质：从调用到代入"（含 sin3 推导示例的文字版）、1.x"Haskell Platform 兴衰与现代安装"（书讲 Platform，按现实改写：Platform 已废弃 → GHCup/stack，保留书的历史叙述一句话）。书源标注 + 练习 2–3 题（选自书 ch1 习题）。
- [x] **Step 3: 自检**：行数 ≥200、无未讲解代码块、页脚导航完好。
- [x] **Step 4: 提交** `feat(haskell): 批次三——01 全景按书1 深改`。

### Task 5: 深改 02 第一个程序（书2）

**Files:**
- Modify: `haskell/docs/02-hello.md`、`haskell/examples/02_hello/`（如需补演示：GHCi 会话、show/print、模块）

**Interfaces:**
- Consumes: `materials/book/ch02.txt`（GHCi 会话、命名与 let、类型与 kind、打印值、模块、Haskell 词法）。
- Produces: 节 2.x GHCi 会话系统、2.x 打印值与 show、2.x 模块与 import。

- [x] **Step 1: 读 ch02.txt** 提炼五节：GHCi 会话（it 变量、`:t`/`:i`/`:set +m` 多行 `:{ :}`）、打印值（show/print/putStr 区别、字符串转义）、模块（module/export/import 明暗列表）、`let` 与 where 绑定对照。
- [x] **Step 2: 正文扩写**（≥200 行），每点配 GHCi 实录片段（可实测截取）；示例 02_hello 增补对应演示行（保持六条判定绿）。
- [x] **Step 3: 验证** `pwsh -File build.ps1 -Example 02_hello`。
- [x] **Step 4: 提交** `feat(haskell): 批次三——02 第一个程序按书2 深改`。

### Task 6: 深改 03 数值（书3）

**Files:**
- Modify: `haskell/docs/03-numbers.md`、`haskell/examples/03_numbers/`

**Interfaces:**
- Consumes: `materials/book/ch03.txt`（Num 类族、取整、自然数、浮点、下溢/溢出）。
- Produces: 节 3.x 取整家族（含银行家舍入）、3.x 自然数 Nat 归纳类型与互转。

- [x] **Step 1: 读 ch03.txt**，提炼：`Num`/`Fractional`/`Integral`/`Floating` 层次与 `fromInteger`/`fromRational` 自动提升、`floor/ceiling/round/truncate` 四兄弟（round 到最近偶数——必实测展示）、自然数 `data Nat = Zero | Succ Nat` 与 `fromNat/toNat`、浮点比较陷阱。
- [x] **Step 2: 正文扩写 + Ch03.hs 增补 Nat/取整演示 + runtests 断言**（round 2.5 == 2、round 3.5 == 4 之类）。
- [x] **Step 3: 验证** `-Example 03_numbers`。
- [x] **Step 4: 提交** `feat(haskell): 批次三——03 数值按书3 深改`。

### Task 7: 深改 09 列表与折叠（书4）

**Files:**
- Modify: `haskell/docs/09-lists.md`、`haskell/examples/09_lists/`

**Interfaces:**
- Consumes: `materials/book/ch04.txt`（序列记法、concat/map/filter、zip/zipWith、文档化设计、关联列表、串联实现）。
- Produces: 重排后的 09 章节序列 + 经典函数族定义（Task 8 数独直接依赖）。

- [x] **Step 1: 读 ch04.txt**，按书重组：语法糖 `[a,b,c] = a:b:c:[]`、`++`/concat 右结合代价、`map/filter` 与组合律预备、`zip/zipWith`、comprehension 与 filter/map 等价、经典定义族（`inits/tails/segments/permutations/subsequences` 中选书内出现的）。
- [x] **Step 2: 正文大改**（≥200 行），Ch09.hs/runtests.hs 同步补演示与断言。
- [x] **Step 3: 验证** `-Example 09_lists`。
- [x] **Step 4: 提交** `feat(haskell): 批次三——09 列表按书4 深改`。

### Task 8: 新章 10 数独解题器（书5）★

**Files:**
- Create: `haskell/docs/10-sudoku.md`、`haskell/examples/10_sudoku/`（Ch10.hs + main.hs + runtests.hs）

**Interfaces:**
- Consumes: Task 7 的 09 章列表函数；`materials/book/ch05.txt`。
- Produces: `Ch10.hs` 导出——`type Matrix a = [[a]]`、`type Grid = Matrix Int`、
  `rows :: Matrix a -> Matrix a`、`cols = transpose`、`boxs :: Matrix a -> Matrix a`（group/ungroup 实现）、
  `group, ungroup :: [a] -> [[a]]`（定长 3 分块）、`nodups :: Eq a => [a] -> Bool`、
  `choices :: Grid -> Matrix [Int]`、`valid :: Matrix [Int] -> Bool`、
  `collapse :: Matrix [Int] -> [Grid]`、`cp :: [[a]] -> [[a]]`、
  `solve1 :: Grid -> [Grid]`（暴力笛卡尔积版）、`prune :: Matrix [Int] -> Matrix [Int]`、
  `solve2 :: Grid -> [Grid]`（剪枝搜索版）。

- [x] **Step 1: 读 ch05.txt**，核对书版实现细节（建模→rows/cols/boxs 的 law：`boxs . boxs . boxs . boxs = id` 等）。
- [x] **Step 2: 写 Ch10.hs**（核心骨架，执行时按 OCR 校准）：

```haskell
type Matrix a = [Row a]
type Row a = [a]
type Grid  = Matrix Int

group   :: [a] -> [[a]]          -- 3 个一组
ungroup :: [[a]] -> [a]
boxs    :: Matrix a -> Matrix a  -- group . map group → transpose → ungroup

choices :: Grid -> Matrix [Int]  -- 0 → [1..9]，否则单元素
solve1  = filter valid . collapse . choices
         -- collapse = cp . map cp（笛卡尔积）
pruneBy :: (Matrix [Int] -> Matrix [Int]) -> Matrix [Int] -> Matrix [Int]
prune   = pruneBy boxs . pruneBy cols . pruneBy rows
         -- 单格确定值从同行/列/宫其余候选中剔除
solve2  = search . prune . choices
  where search m | not (safe m) = []
                | complete m   = collapse m
                | otherwise    = [g | m' <- expansions m, g <- search (prune m')]
```

- [x] **Step 3: main.hs**：演示 group/boxs 在符号矩阵上的变换；解一个简单谜题与书的主例题；打印 solve1/solve2 各自耗时对比（`getCPUTime`）；`==== 10 结束 ====`。runtests.hs：`transpose.transpose = id`、`boxs^4 = id`、已知谜题解等断言、解的有效性验证。
- [x] **Step 4: 验证** `pwsh -File build.ps1 -Example 10_sudoku`（六条判定）。
- [x] **Step 5: 写 docs/10-sudoku.md**（≥200 行）：问题与建模（矩阵=列表的列表）→ 三个视图函数及定律 → 有效性 → 第一版暴力求解（为什么慢：候选笛卡尔积 9^51）→ 剪枝思想 → 搜索骨架 → 耗时对照表解读 → 书源标注 + 精选练习（书 ch5 习题 2–3 题带提示）+ 页脚导航。
- [x] **Step 6: 提交** `feat(haskell): 批次四——10 数独解题器（书5）`。

### Task 9: 新章 11 证明与归纳（书6）★

**Files:**
- Create: `haskell/docs/11-proofs.md`、`haskell/examples/11_proofs/`

**Interfaces:**
- Consumes: Task 7 的 09 章；`materials/book/ch06.txt`。
- Produces: `Ch11.hs` 导出——性质库：`propMapFusion`、`propFilterAppend`?、`propFoldFusion`、`propReverseTwice`、`propSumConcat`、`propTakeDrop`、`propScanlFoldl`、`propIdTake`? 以及确定性样本生成器（xorshift，沿用 17_mtl→现 17 章 xorshift 模式）与 `checkAll :: [(String, Bool)]` 汇总。

- [x] **Step 1: 读 ch06.txt**：等式推理格式（`={...}` 依据标注）、自然数归纳、列表归纳、map 融合、foldr 融合律、foldl 定律、scanl 定律、一般化融合。
- [x] **Step 2: Ch11.hs**：每条定律 = 纯函数在样本集上验证 + main 打印对/错；另含 2 个"手算推导"演示（`reverse (reverse xs)`、`sum (map (1+) xs) = length xs + sum xs` 之类，推给 steps 列表逐行打印）。
- [x] **Step 3: runtests.hs**：固定断言（空表/单表/重复元素边界）。
- [x] **Step 4: 验证** `-Example 11_proofs`。
- [x] **Step 5: docs/11-proofs.md**（≥200 行）：为什么函数式能"算"出程序（等式即程序性质）→ 推导链记号教学（逐行读一个完整证明）→ 归纳法两例（自然数 sum 公式、列表 reverse²）→ 融合律族（foldr f e . map g = foldr (f.g) e 的证明骨架 + 为什么它值钱：一趟替代两趟）→ "机器只能抽查，证明才全覆盖"的边界讨论 → 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次四——11 证明与归纳（书6）`。

### Task 10: 新章 13 无穷列表（书9）★

**Files:**
- Create: `haskell/docs/13-infinite.md`、`haskell/examples/13_infinite/`

**Interfaces:**
- Consumes: 12 章惰性求值（现 10 章已重编号）；`materials/book/ch09.txt`。
- Produces: `Ch13.hs` 导出——`primes :: [Integer]`（筛法）、`fibs :: [Integer]`（zipWith 打结）、`nats/natsFrom`、`cycle` 手写 `myCycle`、RPS 家族：`data Hand = Rock | Paper | Scissors`、`beats/beatenBy :: Hand -> Hand`、`type Strategy = [Hand] -> [Hand]`、`rock/scissors/paper/cycleRps/beatLast :: Strategy`、`score :: [Hand] -> [Hand] -> (Int, Int)`、`table :: Int -> String`（策略循环赛表）。

- [x] **Step 1: 读 ch09.txt**：循环列表定义图解、素数筛、iterate 与流交互、石头剪刀布策略、两两（双）队列。
- [x] **Step 2: Ch13.hs**（骨架）：

```haskell
myCycle :: [a] -> [a]
myCycle xs = ys where ys = xs ++ ys      -- 共享 thunk 的循环结构
primes = sieve [2..]
  where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
beatLast _ [] = [Rock]                    -- 书中策略：后手克制对手上一手
beatLast me (o:os) = beats o : beatLast (beats o) os
score = foldl step (0,0) . uncurry zip    -- 按胜负计分，双方无穷流
```

- [x] **Step 3: main/runtests**：take 20 素数、fibs!!30 == 832040、RPS 循环赛固定对局表断言、演示 `ones = 1:ones` 与 `length (take 5 ones)`。
- [x] **Step 4: 验证** `-Example 13_infinite`。
- [x] **Step 5: docs/13-infinite.md**（≥200 行）：递归等式即定义（打结图解）→ 循环列表与共享 → 筛法两版对比（书里的 prime 筛优化叙述）→ 无穷流上的策略游戏（类型设计的教益）→ 惰性为何不断死循环（回扣 12 章 thunk）→ 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次五——13 无穷列表（书9）`。

### Task 11: 新章 18 命令式函数式：State 与 ST（书10）★

**Files:**
- Create: `haskell/docs/18-st.md`、`haskell/examples/18_st/`

**Interfaces:**
- Consumes: 16 章 FAM（手写 State 已有）；`materials/book/ch10.txt`。
- Produces: `Ch18.hs` 导出——State 版表达式求值器（书例：带计数的求值 `evalCount :: Expr -> State Int Integer`）、ST 家族演示：`factST :: Integer -> Integer`（STRef 循环阶乘）、`sumST :: [Integer] -> Integer`、`bsortST :: Ord a => [a] -> [a]`（STArray 冒泡）、`shuffleST :: [a] -> Int -> [a]`（xorshift 种子洗牌）、`freshLabels :: [a] -> [(Int, a)]`。

- [x] **Step 1: 读 ch10.txt**：状态单子计算模型、ST 单子引入动机、runST 的 rank-2 类型、可变数组两节。
- [x] **Step 2: Ch18.hs**（骨架，注意 boot 库 `Data.STRef`）：

```haskell
import Data.STRef
import Data.Array.ST          -- newArray/readArray/writeArray/getElems
factST n = runST $ do
    r <- newSTRef 1
    mapM_ (\k -> modifySTRef' r (* k)) [1 .. n]
    readSTRef r
bsortST xs = runST $ do
    a <- newListArray (1, n) xs :: ST s (STArray s Int e)  -- Ord e 约束版执行时定
    -- 冒泡双循环 readArray/compare/writeArray，禁部分函数
    getElems a
```

- [x] **Step 3: main/runtests**：三件套断言（factST 10 == 3628800、bsortST 乱序表 == sort、shuffleST 固定种子可复现）；main 打印 State 与 ST 两版求值对照。
- [x] **Step 4: 验证** `-Example 18_st`。
- [x] **Step 5: docs/18-st.md**（≥200 行）：函数式里"命令式"是什么意思 → State 回顾（16 章）与新例子 → ST：真可变、但 runST 用 `forall s` 把效应封在纯表达式里（类型逐字讲解）→ STRef 三例 → STArray 排序 → 什么时候用（局部可变加速）/什么时候不用 → 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次五——18 命令式函数式 State/ST（书10）`。

### Task 12: 新章 21 手写解析器组合子（书11）★

**Files:**
- Create: `haskell/docs/21-miniparser.md`、`haskell/examples/21_miniparser/`

**Interfaces:**
- Consumes: 16 章 Monad/Alternative；`materials/book/ch11.txt`。
- Produces: `Ch21.hs` 导出——`newtype Parser a = Parser { parse :: String -> [(a, String)] }`、Functor/Applicative/Monad/Alternative 实例、`item :: Parser Char`、`sat :: (Char -> Bool)`、`char/string/digit/letter/lower/upper/space/spaces`、`token :: Parser a -> Parser a`（跳空白）、`natural/int :: Parser Integer`、`identifier`、`expr/term/factor :: Parser Integer`（四则带优先级）、`runExpr :: String -> Either String Integer`。

- [x] **Step 1: 读 ch11.txt**：组合子逐步构造、选择与重复、表达式文法。
- [x] **Step 2: Ch21.hs**（骨架）：

```haskell
newtype Parser a = Parser { parse :: String -> [(a, String)] }
-- Monad: item >>= f；失败 = []
-- Alternative: some p = (:) <$> p <*> many p；many p = some p <|> pure []
-- 零消耗回溯由列表单子天然给出（取第一个成功分支 = head 替代方案 take 1）
first :: Parser a -> String -> Either String (a, String)  -- 全函数版取首
expr   = chainl1 term (add <|> sub)   -- 手写 chainl1，不用 parsec
term   = chainl1 factor (mul <|> div) -- 整除安全版：0 除数返回失败 Parser
factor = token (parens expr <|> natural <|> neg)
```

- [x] **Step 3: main/runtests**：断言表 `["1+2*3"→7, "(1+2)*3"→9, "10-4-3"→3（左结合）, "8/2/2"→2, "1+"→语法错 Left]`。
- [x] **Step 4: 验证** `-Example 21_miniparser`。
- [x] **Step 5: docs/21-miniparser.md**（≥200 行）：解析器为什么是函数 → newtype 与读取函数 → Monad 实例逐步推导（bind = 顺序、失败传播）→ Alternative 与回溯（列表单子的"多世界"）→ many/some 的不动点定义 → 表达式文法与左结合的处理（chainl）→ 结尾一节"从手写到 parsec"（22 章预告：位置跟踪/错误消息/流类型）→ 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次六——21 手写解析器组合子（书11）`。

### Task 13: 新章 23 交互式计算器（书12）★

**Files:**
- Create: `haskell/docs/23-calculator.md`、`haskell/examples/23_calculator/`

**Interfaces:**
- Consumes: Task 12 的 Ch21 解析器（`import Ch21`？否——本目录自包含，`Ch23.hs` 内嵌精简解析器或直接用 boot 库 parsec；**决定：自包含，内嵌 Task 12 的核心组合子精简版**，教学上重写一遍更稳）。
- Consumes: `materials/book/ch12.txt`。
- Produces: `Ch23.hs` 导出——`data Cmd = Set String Expr | Show String | Eval Expr`、`type Env = Map String Double`、`parseCmd :: String -> Either String Cmd`、`exec :: Env -> Cmd -> Either String (Maybe Double, Env)`、`replay :: [String] -> [String]`（整个会话纯函数回放）、`session :: String`（内置演示脚本）。

- [x] **Step 1: 读 ch12.txt**：计算器需求、文法（赋值/求值/清屏）、错误处理设计。
- [x] **Step 2: Ch23.hs**：词法层（跳空白+换行续接 `\`）→ 语法层（复用手写组合子骨架）→ 求值层（Env = Map，`eval :: Env -> Expr -> Either String Double`，除零/未定义变量 → Left 中文消息）→ 回放层 fold。
- [x] **Step 3: main/runtests**：断言脚本会话——`x = 3+4`、`x*2` → 14、`y` → 未定义错、`1/0` → 除零错、`x = x+1` 重赋值 → 8；main 打印整场回放。
- [x] **Step 4: 验证** `-Example 23_calculator`。
- [x] **Step 5: docs/23-calculator.md**（≥200 行）：需求到文法（交互循环的命令语言）→ 分层架构图（词法/语法/求值/回放）→ 逐层实现讲解 → 错误通道设计（Either 一条到底）→ REPL 的纯函数化（会话=状态×输入流→输出流，为 31 章 MiniLang 铺垫）→ 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次六——23 交互式计算器（书12）`。

### Task 14: 深改 25 性能（书7）

**Files:**
- Modify: `haskell/docs/25-performance.md`（重编号后文件）、`haskell/examples/25_performance/`

**Interfaces:**
- Consumes: `materials/book/ch07.txt`（惰性代价、空间耗费、时间测试、累积参数、元组化、排序案例）；现有 profiling/RTS 内容保留。
- Produces: 重排后的 25 章节序列（书 7 为主轴 + GHC 工具收尾）。

- [x] **Step 1: 读 ch07.txt**：按书重组主轴——`sum [1..n]` 的惰性栈增长图解、空间/时间测试方法（书用 `getCPUTime`；升级为 GHC `-s` RTS 统计对照）、累积参数（`reverse`/`reverse2` O(n²)→O(n) 实测）、元组化（朴素 fib 树形→线性 fib2）、归并排序的 `merge`/`sort` 推导。
- [x] **Step 2: Ch25.hs 补演示函数**（reverse/reverse2、fib/fibPair、msort）+ runtests 断言等价 + main 计时对照表。
- [x] **Step 3: 验证** `-Example 25_performance`。
- [x] **Step 4: 正文重排**（≥200 行）+ 书源标注 + 练习 + 页脚。
- [x] **Step 5: 提交** `feat(haskell): 批次七——25 性能按书7 重构`。

### Task 15: 新章 26 优美打印（书8）★

**Files:**
- Create: `haskell/docs/26-pretty.md`、`haskell/examples/26_pretty/`

**Interfaces:**
- Consumes: 11 章融合律（为什么 O(n²) 版能被算成 O(n) 版）；`materials/book/ch08.txt`。
- Produces: `Ch26.hs` 导出——`data Doc = Nil | Text String | Line | Cat Doc Doc | Nest Int Doc | Group Doc`、`nil/text/line/(<>)/nest/group` 构造族、`layoutNaive :: Int -> Doc -> String`（书 8.3 直接实现）、`pretty :: Int -> Doc -> String`（高效版）、`prettyTree :: TreeS -> Doc`、`prettyExpr :: ExprS -> Doc`（示例数据构造器）。

- [x] **Step 1: 读 ch08.txt**：问题背景（何处换行）、文档类型设计、直接实现、一行的度量、高效表示。
- [x] **Step 2: Ch26.hs**：直接版（每行重组字符串，O(n²) 直白可读）；高效版（书的高效算法改写，`Group` 尝试扁平化装得下则单行）；两者对同一 Doc 输出**逐字节相同**。
- [x] **Step 3: main/runtests**：嵌套 lambda 表达式/树两份数据，宽度 20/40/80 三档渲染；断言 naive == pretty；深嵌套 5000 节点计时对照（打印两版耗时，断言结果仍相同）。
- [x] **Step 4: 验证** `-Example 26_pretty`。
- [x] **Step 5: docs/26-pretty.md**（≥200 行）：自由文本布局问题 → Doc 代数的"组合子式 API 设计"（与 21 章解析器互为镜像：一个吃文本产结构、一个吃结构产文本）→ 朴素版为何 O(n²) → 高效版推导（宽度判断前移）→ 两版对账即"计算等价"的实证（回扣 11 章）→ 练习 + 页脚。
- [x] **Step 6: 提交** `feat(haskell): 批次七——26 优美打印（书8）`。

### Task 16: 收官——README 定稿、CHEATSheet 汇总、全量审计

**Files:**
- Modify: `haskell/README.md`（去"（本轮新增）"旗标、定稿叙述）、`haskell/CHEATSheet.md`（新章坑位汇总索引 + 书源对照表）
- Modify: `haskell/tools/nav_audit.py`（移除新章白名单）

**Interfaces:**
- Consumes: Task 3–15 全部产物。
- Produces: 31 章/30 例全绿 + 导航零断链的最终态。

- [x] **Step 1: 全量构建** `pwsh -File build.ps1 -All`（30 例含两个 stack 工程）+ `bash run-all.sh`。
- [x] **Step 2: nav_audit 零断链**、全部 31 章页脚格式一致；`wc -l` 校验 12 个书映射章 ≥200 行且文字行多于代码行。
- [x] **Step 3: README 定稿**：六篇表去旗标、书章映射列（原书 1–12 → 教程章号一览）、工具链表 9.14.1 叙述定稿。
- [x] **Step 4: CHEATSheet**：本轮新坑位（OCR/9.14 迁移/新章实测坑）补进坑位索引表。
- [x] **Step 5: 提交** `feat(haskell): 批次八——31 章收官：README 定稿与全量审计`。
- [x] **Step 6: 更新记忆** `haskell-tutorial-build.md`（结构 31 章六篇、Bird 书取材、9.14.1 迁移与新坑）。

## Self-Review 记录

- 规格覆盖：31 章结构✓（Task 3）、7 新章✓（Task 8–13、15）、5 深改✓（Task 4–7、14）、书 12 章映射✓、GHC 9.14.1✓（Task 2）、OCR✓（Task 1）、导航 Ada/Zig✓（Task 3 Step 5–7）、练习（各章 Step 内）✓、收官✓（Task 16）。
- 无占位符：示例代码给到签名+算法骨架，正文按 OCR 取材逐章展开（教程散文在执行时成文，属交付物本体）。
- 命名一致性：docs slug 与 examples 目录名全局唯一对照表固定于头部；`ChNN` 模块号=目录号。
