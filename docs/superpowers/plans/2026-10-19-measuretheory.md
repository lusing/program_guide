# measuretheory 教程实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以严加安《测度论讲义》第二版为纲，在 `G:\code\guide\measuretheory\` 建 51 篇自包含中文教程 + 五通道（Lean4+mathlib4 / Isabelle HOL-Analysis / Julia / Python / Prolog）机器验证工程。

**Architecture:** 每章一篇 docs（≥200 行、讲解为主、代码全在正文引用），按 spec §2 章表配通道文件；`build.ps1` 做 章×通道 矩阵对账；按批 B0-B10 提交。OCR 只作取材骨架，数学公式按领域知识重建。

**Tech Stack:** Lean 4 v4.33.1 + mathlib（钉版 `H:/Lang/lean4/mathlib4-4.33.1`）；Isabelle2025-2 HOL-Analysis（pwsh→cygwin bash -lc）；julia / python(-I) / swipl（+WSL gprolog 抽查）；rapidocr GPU 单进程。

**Spec:** `docs/superpowers/specs/2026-10-19-measuretheory-design.md`（章表/通道分工/质量门/风险都在 spec，本计划不复述，执行时两份都读）

## Global Constraints

- 工作目录 `G:\code\guide\measuretheory\`；shell 为 Git Bash（pwsh 单独调用）。
- 书页 N（N≥2）↔ PDF 奇数页 `2·ceil((N+15)/2)−1`（对页重复扫描，只 OCR 奇数页）。
- OCR：`export PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH"` + `G:/scoop/apps/python313/current/python.exe -I tools/ocr_yan.py …`，**单进程串行**（双进程显存炸——前科）。
- Lean 文件命名 `examples/lean/Measuretheory/ChNN<Slug>.lean`，根模块 `Measuretheory.lean` 逐批追加 import；mathlib 依赖 `require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"`，toolchain `leanprover/lean4:v4.33.1`；换依赖后 `rm lake-manifest.json && rm -rf .lake/packages && lake update`。
- Isabelle：ROOT 手写/Edit（禁 python 写盘，CRLF 前科）；会话 `session MTNN in "MTNN" = "HOL-Analysis" +`；理论文件 `examples/isabelle/MTNN/TNN_<Slug>.thy`；构建必须 pwsh 调 `G:\xulun3\isabelle\Isabelle2025-2\contrib\cygwin\bin\bash.exe -lc`；不强杀 poly（堆重建 53 分钟前科）。
- Julia 文件头尾标记：`println("==== NN <slug>")` … `println("END ====")`；`julia --startup-file=no` 跑。
- Python：`python -I`，文件头 `sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')`（GBK 控制台前科），同样首尾标记。
- Prolog：`swipl -q -f <file> -g main -t halt`；`format/2` 必带 `[]`；main 尾 `!`；输出含 `END ====`；谓词/原子名跨库一致。
- 数值纪律：随机实验钉种子（Julia `Random.seed!` / Py `np.random.default_rng(42)`）；断言前心算理论值；理论等值点的严格不等断言留 ≥25% 余量。
- **通道分工章**（14/15/21/22/24部分/34/43/45/46）：无机器基础设施不硬造形式化，数值/有限通道承载 + docs 如实标注（funanalysis vN 代数先例）。
- **"视侦察"章**（24/26/33/40/42/44/47/48/49）：该批开工前先做锚点侦察（Task 2 的命令模板）再定 Lean 是否承载，结论写 PLAN.md。
- 质量门（每批必过）：① `pwsh -NoProfile -Command '& ./build.ps1 -Chapter <本批章号列表>'` 全 PASS；② `wc -l docs/<本批 NN-*.md>` 每篇 ≥200 且文字行多于代码行；③ Julia/Python 文件 `wc -l` ≥40 且含实质数值断言；④ 抽 2 章核对 docs 引用的 examples 路径存在且与讲解一致。
- 每批提交一笔：`docs(measuretheory): <批次名>（NN-NN 章）——<一句话>；批内全绿 N/N`，结尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 提交只 add measuretheory/ 与根 .gitignore 的本工程条目，不碰其他目录未提交改动。

## 文件结构（全部 51 章的命名，一次锁死）

docs：`00-intro` `01-setclasses` `02-monotone-class` `03-measures` `04-extension` `05-stieltjes` `06-approximation` `07-measurable-maps` `08-functional-monotone-class` `09-convergence-modes` `10-integral` `11-limit-theorems` `12-signed-measures` `13-lp-spaces` `14-linfty-dual` `15-daniell` `16-bochner-integral` `17-product-sigma` `18-fubini` `19-kernels` `20-infinite-products` `21-kolmogorov-tulcea` `22-projective-limits` `23-topology-borel` `24-riesz` `25-regular-measures` `26-c0-dual` `27-lusin` `28-product-topological` `29-polish` `30-euclidean-convergence` `31-weak-convergence` `32-tightness-prohorov` `33-metrization` `34-vague-convergence` `35-independence` `36-conditional-expectation` `37-regular-conditional` `38-uniform-integrability` `39-esssup` `40-analytic-sets` `41-martingale-inequalities` `42-martingale-convergence` `43-local-martingales` `44-bochner-theorem` `45-minlos-sazonov` `46-minlos` `47-gaussian-measures` `48-clt` `49-slln` `50-cheatsheet`

Lean 模块名 = `Ch` + 章号 + Slug 的 PascalCase（`Ch01Setclasses`、`Ch13LpSpaces`…，以 PLAN.md 锚点表为准）；Isabelle 理论 = `T` + 章号 + `_<Slug>`；julia/python/prolog = `<NN>_<slug 用下划线>.jl/.py/.pl`。

---

### Task 1: B0.1 OCR 全书

**Files:**
- Create: `build/ocr/yan_full/*.txt`（每 PDF 奇数页一个，产物在 gitignore 的 build/ 内）
- Modify: `tools/ocr_yan.py`（增加 full 子命令或直接分窗调用）

**Interfaces:**
- Produces: 后续所有批次写作的取材骨架（grep-able 文本）。断点续扫：已存在的输出页跳过。

- [ ] **Step 1: 扩展 ocr_yan.py 支持逐页输出与断点续扫**

在 `ocr()` 中改为每页写 `build/ocr/yan_full/p%03d.txt`（已存在且非空则跳过），不再写合并大文件；`render` 不变（已渲染页跳过：加 `if img.exists(): continue`）。

- [ ] **Step 2: 渲染奇数页 17-303**

```bash
cd G:/code/guide/measuretheory && G:/scoop/apps/python313/current/python.exe -I tools/ocr_yan.py render 17 303
```

注意 render 的 first/last 是连续区间；渲染后删除偶数页 PNG（`find build/ocr/img -name 'p0???.png' | awk -F/ 'NR%2==0' | xargs rm` 需按页号奇偶判断，写一行 python 处理更稳）。

- [ ] **Step 3: OCR 全部已渲染奇数页（串行，~10-15 分钟）**

```bash
cd G:/code/guide/measuretheory && export PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" && G:/scoop/apps/python313/current/python.exe -I tools/ocr_yan.py ocr 17 303
```

- [ ] **Step 4: 校验覆盖**

```bash
ls build/ocr/yan_full/ | wc -l   # 期望 144
grep -l "习题" build/ocr/yan_full/*.txt | wc -l   # 各章习题均应出现
grep -l "Radon" build/ocr/yan_full/*.txt   # 12 章附近应命中
```

抽查 3 页：书 p.54（符号测度起）、p.108（Kolmogorov）、p.235（鞅不等式）对应 PDF 奇数页 69、131、255 的 OCR 文本，确认章标题可读。

### Task 2: B0.2 mathlib/Isabelle 锚点侦察

**Files:**
- Create: `PLAN.md`（含锚点表 + 51 章通道定案表 + 批次进度）

**Interfaces:**
- Consumes: spec §2 章表（"视侦察"列）。
- Produces: 锚点表（每行：章 | 库 | 精确名 | import 路径 | 一句话用途），后续所有 Lean/Isabelle 任务的 API 名以此为准。

- [ ] **Step 1: mathlib 侦察（bash，逐条跑并记录命中）**

```bash
ML=H:/Lang/lean4/mathlib4-4.33.1
for pat in caratheodory Measure.completion measureStieltjes ext_of_generateFrom egoRov induction_on lintegral_supr integral_dominatedConvergence SignedMeasure hahnDecomposition rnDeriv haveLebesgueDecomposition "MeasureTheory.Lp" essSup condexp condKernel UniformIntegrable "Measure.prod" lintegral_prod "Kernel.comp" Kernel.prod "Measure.pi" WeakConvergence Tight Prohorov KolmogorovZeroOne IndepSets Submartingale submartingale_max upcrossing bochnerIntegral AEStronglyMeasurable charFun centralLimit gaussMeasure "Measure.Regular" Lusin RieszRepresentation IsAnalytic birkhoff; do
  echo "== $pat"; grep -rl "$pat" $ML/Mathlib --include='*.lean' | head -3
done
```

对每个"视侦察"章追加定向 grep（如 24 章：`grep -rn "RieszMarkov\|CurrencyMeasure\|boundedVariation" $ML/Mathlib --include='*.lean' | head`；42 章：`grep -rn "convergence_ae\|submartingale.*converge" ...`）。Isabelle 同法：

```bash
ISA=G:/xulun3/isabelle/Isabelle2025-2/src/HOL
grep -rln "central_limit_theorem\|weak_convergence\|RN_deriv\|conditional_expectation\|Bochner_Integration\|has_integral_lebesgue\|integral_fubini\|PiM\|LPspace\|characteristic_function" $ISA/Analysis $ISA/Probability | head -40
```

- [ ] **Step 2: 定案并写 PLAN.md**

PLAN.md 结构：① 51 章表（章 | slug | 书节 | L/I/J/P/R 定案 | 状态）；② 锚点表（上述 grep 结论）；③ 批次进度勾选框。定案规则：mathlib/Isabelle 有可用锚点 → Lean/Isabelle ✓（该章至少 1 个锚点引证 + ≥2 个自包含 example/lemma）；无锚点 → 标"通道分工"，由 J/P/R 承载并写入 docs 标注。

- [ ] **Step 3: 提交**

```bash
git add measuretheory/PLAN.md && git commit -m "docs(measuretheory): B0 锚点侦察——mathlib/Isabelle 覆盖定案与 51 章通道表"
```

### Task 3: B0.3 工程骨架 + 通道冒烟

**Files:**
- Create: `examples/lean/lakefile.lean`、`examples/lean/lean-toolchain`、`examples/lean/Measuretheory.lean`、`examples/lean/Measuretheory/Ch00Intro.lean`
- Create: `examples/isabelle/ROOT`、`examples/isabelle/MT00/T00_Intro.thy`
- Modify: 根 `.gitignore`（追加 measuretheory 条目）

- [ ] **Step 1: lakefile.lean（内容照抄 funanalysis 模式改名）**

```lean
import Lake
open Lake DSL

/-!
# 测度论教程 · Lean 4 示例工程

本工程是《测度论：编程与自动证明教程》的 Lean 主证明通道。
依赖本地 mathlib4 发布版（H:/Lang/lean4/mathlib4-4.33.1，钉版 tag），
lean-toolchain 与之对齐为 v4.33.1。
-/

package «measuretheory-lean» where

require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

@[default_target]
lean_lib «Measuretheory» where
  roots := #[`Measuretheory]
  globs := #[.submodules `Measuretheory]
```

`lean-toolchain` 内容一行：`leanprover/lean4:v4.33.1`。`Measuretheory.lean` 首版只 `import Measuretheory.Ch00Intro`。`Ch00Intro.lean`：模块 doc + `import Mathlib.MeasureTheory.Measure.MeasureSpace` + 两个 example（`example (s : Set ℕ) : MeasurableSet s ∅.elim` 不行就写真的：`example : ∀ n : ℕ, (MeasureTheory.measureSpace).volume {k : ℕ | k < n} = n := by intro n; simp`——以能编过为准的真断言）。

- [ ] **Step 2: lake 构建冒烟**

```bash
cd G:/code/guide/measuretheory/examples/lean && lake exe cache get && lake build
```

预期退出码 0、无 error:/warning:。首跑较慢（缓存下载+编译根模块）。

- [ ] **Step 3: Isabelle ROOT + 冒烟理论**

`examples/isabelle/ROOT`：

```
session MT00 in "MT00" = "HOL-Analysis" +
  options [document = false]
  theories
    T00_Intro
```

`examples/isabelle/MT00/T00_Intro.thy`：

```isabelle
theory T00_Intro
  imports "HOL-Analysis.Analysis"
begin

lemma smoke_measure_finite:
  fixes A :: "real set"
  assumes "finite A"
  shows "emeasure (lebesgue_on A) A \<le> real (card A)"
  using assms by (simp add: finite_imp_measurable ... )
```

（以能过为准的**真**引理——最简可用 `lemma smoke: "(1::real) = 1" by simp` 起步，若想带 Measure 内容用 `emeasure count_space {1::nat} {1} = 1` 的真断言。）

- [ ] **Step 4: Isabelle 冒烟（pwsh+cygwin，首建 HOL-Analysis 堆约 8 分钟，勿中途杀）**

```bash
pwsh -NoProfile -Command '& "G:\xulun3\isabelle\Isabelle2025-2\contrib\cygwin\bin\bash.exe" -lc "/cygdrive/g/xulun3/isabelle/Isabelle2025-2/bin/isabelle build -d G:/code/guide/measuretheory/examples/isabelle MT00"'
```

预期 `MT00` 构建成功、无 failed。

- [ ] **Step 5: julia/python/swipl 可用性检查**

```bash
julia --startup-file=no -e 'println(versioninfo()); using Random; Random.seed!(1); println(rand())'
python -I -c "import numpy, scipy; print(numpy.__version__, scipy.__version__)"
swipl -q -g "format('swipl ok ~w~n', [42])" -t halt
```

任一失败：按 funanalysis 前科排障（scoop python 回落 3.13 等）。

- [ ] **Step 6: .gitignore 追加**

根 `.gitignore` 末尾追加：

```
# measuretheory tutorial build artifacts
measuretheory/examples/lean/.lake/
measuretheory/examples/lean/lake-manifest.json
```

### Task 4: B0.4 build.ps1 + README + docs/00

**Files:**
- Create: `build.ps1`（全文照 funanalysis 模板，改动仅三处：根模块目录 `Measuretheory`、Isabelle 会话前缀 `MT`、注释头改测度论）、`README.md`、`docs/00-intro.md`

**Interfaces:**
- Produces: 验证入口 `pwsh -NoProfile -Command '& ./build.ps1 -All|-Chapter NN|-Lang X|-List|-Clean'`（后续每批的质量门①用）。

- [ ] **Step 1: 写 build.ps1**

复制 `G:/code/guide/funanalysis/build.ps1` 全文到 `measuretheory/build.ps1`，做如下替换：`Funanalysis`→`Measuretheory`（lean 部分）、`FANN`→`MTNN`（正则 `^session\s+(MT\d+)`、`-replace '^MT'`）、`funanalysis-lean` 注释改 `measuretheory-lean`、文件头注释块改写为本工程用法。其余（矩阵发现/过滤/执行/汇总/python 自愈/gprolog 抽查）不动。

- [ ] **Step 2: 验证 -List 与 -All 冒烟**

```bash
cd G:/code/guide/measuretheory && pwsh -NoProfile -Command '& ./build.ps1 -List' && pwsh -NoProfile -Command '& ./build.ps1 -All'
```

预期：矩阵显示 00 章 lean/isabelle 两单元，全 PASS。

- [ ] **Step 3: README.md**

内容：工程定位（严书为纲 51 章）、目录结构、五通道角色、构建命令、章表（51 行简表：章号/主题/书节）、纪律声明（OCR 骨架/公式重建/通道分工标注）。~120 行。

- [ ] **Step 4: docs/00-intro.md（≥200 行）**

必须覆盖：测度论是什么/为什么（长度→面积→概率的公理化动机）；历史主线（Lebesgue 1902 → Radon 1913 → Fréchet 1915 抽象测度 → RN 1930 → Daniell 1918/Bochner 1933/Pettis 1938 → Kolmogorov 1933 概率公理化——严书第一版前言的史料线，OCR 可核）；严书结构与三部分分法（一般测度积分/拓扑测度/概率选讲+鞅+无穷维）；本教程 51 章地图（带每批范围）；五通道各自角色与"通道分工"约定；如何构建与阅读；记号约定（μ, σ-代数, Ē, a.e., ⇏ 等）。无代码，纯正文。

### Task 5: B0.5 收官对账 + 提交

- [ ] **Step 1: 全量对账**

```bash
cd G:/code/guide/measuretheory && pwsh -NoProfile -Command '& ./build.ps1 -All' && wc -l docs/00-intro.md README.md PLAN.md
```

- [ ] **Step 2: 提交**

```bash
cd G:/code/guide && git add measuretheory/ .gitignore && git commit -m "docs(measuretheory): B0 基建——OCR 全书取材、五通道骨架冒烟、build.ps1、00 导言；2/2 全绿"
```

---

## 批次任务（Task 6-15，共用执行协议）

每批的步骤模板（各任务内按本批章号实例化）：

1. **取材**：`grep -n "定理\|命题\|引理\|定义\|例子\|习题" build/ocr/yan_full/pXXX.txt`（本批书页区间），结合领域知识列本章必覆盖清单。
2. **docs**：逐章写 `docs/NN-<slug>.md`（模板见 spec §8；≥200 行；所有代码段在正文引用并讲解；章末"对应示例"可选节）。
3. **Lean**：`examples/lean/Measuretheory/ChNN*.lean`（按 PLAN.md 定案的章），根模块追加 import；`lake build` 至绿。
4. **Isabelle**：ROOT 追加 session（Edit 工具，勿脚本写盘），`MTNN/TNN_*.thy`，pwsh 冒烟。
5. **Julia/Python/Prolog**：`examples/<lang>/NN_<slug>.*`，首尾标记+实质断言，逐文件跑绿。
6. **批内对账**：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter <列表>'` 全 PASS。
7. **质量门**：`wc -l docs/<批内文件>` ≥200/篇、julia/python ≥40 行/件；抽 2 章核 docs↔examples 一致；PLAN.md 勾进度。
8. **提交**：一笔，消息格式见 Global Constraints。

### Task 6: B1 集类与测度（01-06 章）

**Files:**
- Create: `docs/01-setclasses.md` … `docs/06-approximation.md`；`examples/lean/Measuretheory/Ch0{1..6}*.lean`（6 个，03-06 为 Lean 主力）；`examples/julia/0{1..6}_*.jl`、`examples/python/0{1..6}_*.py`（各 6）；`examples/prolog/0{1,2,3,4,6}_*.pl`（5 个）；julia/python 命名按文件结构节的 slug 下划线化。
- Modify: `examples/lean/Measuretheory.lean`（追加 6 个 import）

**内容要点（必覆盖，来自严书 §1.1-1.6 + OCR 核对）：**
- 01：环/代数/σ环/σ代数/半环/π系/λ系 定义+独立反例；生成 σ-代数；可测空间例（Borel、可数-余可数）；de Morgan。J/P：有限 Ω 上各集类闭包枚举对比；R：闭包迭代不动点。
- 02：单调类、λ系-π系定理（Dynkin）、单调类定理、两定理互推；"检查生成系即可"应用范式。R：有限格单调类迭代步数；J：π-λ 有限模型对拍。
- 03：测度定义、可数可加 ⇒ 单调/次可加/上下连续；σ-有限、半σ-有限；完备；半环上预测度→环上测度（延拓引理）。L：`measure_iUnion_le`、`measure_iUnion_null`、连续性引理正名。R：有限测度表验证上下连续。
- 04：外测度、Carathéodory 可测判据、扩张定理全文证明、Lebesgue 测度构造（区间长度→外测度→限制）、完备化定理。L：`OuterMeasure`/`caratheodory`/`Measure.completion`（锚点表正名）。J：格点覆盖 inf 外测度数值；P：同题对拍不同算法。
- 05：分布函数↔LS 测度构造与唯一性、右连续性的作用、离散/连续/混合例子、与概率测度的对应。L：`measureStieltjes`（锚点表正名）。J：阶梯/混合 F 的 LS 测度数值；P：scipy rv 对拍。
- 06：有限测度被生成代数上的值逼近（逼近定理）、扩张唯一性证明用法、μ-外测度正则性侧面。L：`Measure.ext`/`ext_of_generateFrom` 族。R：有限模型逼近链；J：数值逼近。

- [ ] Step 1-8：按共用执行协议（章列表 01,02,03,04,05,06）。
- [ ] 提交：`docs(measuretheory): B1 集类与测度（01-06 章）——Carathéodory 扩张/LS 测度/逼近；批内全绿 N/N`

### Task 7: B2 可测映射（07-09 章）

同协议。要点：
- 07：可测映射、σ(f) 初 σ-代数、复合可测、在生成系上检查、Borel 映射、像测度 distr。L：`Measurable` 复合/`MeasurableSpace.comap`/`measurable_from_generate` 类锚点。R：有限映射 σ(f) 计算；J：数值。
- 08：有界函数单调类定理（线性格+常数+指示 → 全体有界可测）、推论（可测函数格性质）、应用范式。L：`MeasurableSpace.induction_on`（锚点表正名，若无则手写小自包含件）。R：函数格迭代。
- 09：四种收敛（逐点/a.e./依测度/近一致+a.e. 一致?）定义与反例矩阵；Egorov 定理（μ 有限）、Riesz 子列定理、依测度 Cauchy 判据。L：Egorov 锚点。J：滑动脊反例族数值（‖fₙ‖∞=1 依测度→0）；P：对拍；R：有限模型依测度收敛枚举。
- 提交：`docs(measuretheory): B2 可测映射（07-09 章）——函数单调类/收敛方式矩阵/Egorov；批内全绿 N/N`

### Task 8: B3 积分与 Lp（10-16 章，大批）

同协议。要点：
- 10：简单函数→非负→一般的三步构造、线性/单调/正齐次、可积判据、Markov 不等式、绝对连续性。L：`lintegral` 构造链+`integral`；I：`has_integral_lebesgue`。R：有限值函数积分表。
- 11：MCT、Fatou、DCT（+严书的推广形式：Vitali 型/一致可积版）、三者关系与反例。L：`lintegral_tendsto_of_tendsto`? /`integral_dominated_convergence`（正名）；I：单调收敛。J：MCT 反例（无单调失效）数值。
- 12：符号测度、Hahn/Jordan 分解、全变差、绝对连续/奇异/Lebesgue 分解、RN 定理全文+导数性质。L：`SignedMeasure`/`hahnDecomposition`/`rnDeriv`（正名）；I：`RN_deriv`。J/P：离散两点格 RN 数值。
- 13：Lp 完备性（Riesz-Fischer）、Hölder/Minkowski、对偶 (1≤p<∞)（p=1 需 σ-有限的反例讨论）、L²。L：`MeasureTheory.Lp` API；I：`LPspace`（若有）。J：离散 Lp 对偶数值；P：对拍。
- 14：L∞(Ω,ℱ) 对偶=ba、ba 局部化、纯有限可加荷的构造思路、与 L¹≠L∞* 的关系。**通道分工**：J 自然密度荷数值（非可数可加展示）；R 有限 ba/ca 对比；docs 如实标注无形式化。
- 15：Daniell 泛函/Stone 条件/Daniell 扩张、与 Carathéodory 平行。**通道分工**：J 从阶梯函数正线性泛函数值构造测度；R 有限格 Daniell 模型。
- 16：强可测（可分值+Borel）、Pettis 可测定理、Bochner 积分构造/控制收敛、Pettis 积分。L：`bochnerIntegral`/`SimpleFunc.bintegral`/`AEStronglyMeasurable`；I：`Bochner_Integration`。J：向量值数值积分。
- 提交：`docs(measuretheory): B3 积分与 Lp（10-16 章）——极限定理/RN/ba/Daniell/Bochner；批内全绿 N/N`

### Task 9: B4 乘积空间（17-22 章）

同协议。要点：
- 17：可测矩形、乘积 σ-代数、截口可测、任意族乘积。L：`MeasurableSpace.prod`/`measurable_prod`/`Measurable.fst` 族。
- 18：乘积测度构造、截口定理、Tonelli/Fubini、σ-有限必要性反例、换序反例。L：`Measure.prod`/`lintegral_prod`（正名）；I：Fubini。J：级数换序反例数值。
- 19：可测核/概率核、由核产生测度、核复合与乘积。L：`Kernel` API（`Kernel.comp`/`Kernel.prod` 正名）。R：有限核复合表；J：马氏链两步分布数值。
- 20：可数无穷乘积测度存在唯一、柱集、独立坐标。L：`Measure.pi` 族；I：`PiM`（若有）。J：无穷硬币柱集数值逼近。
- 21：Kolmogorov 相容性定理 + Tulcea 定理（核版构造证明）全文自包含。**通道分工**（mathlib 无）：J 相容有限维数值；R 有限指标集相容性检查器；docs 标注。
- 22：投影极限（逆极限）+ 随机 Daniell 积分及核表示（严的研究成果）——以讲清陈述与证明思路为主。**通道分工**：J 高斯投影极限数值。
- 提交：`docs(measuretheory): B4 乘积空间（17-22 章）——Fubini/核/无穷乘积/Kolmogorov-Tulcea；批内全绿 N/N`

### Task 10: B5 拓扑测度（23-29 章）

同协议。要点：
- 23：拓扑词汇（本教程所需子集：网/邻域/局部紧/波兰）、Borel 与 Baire σ-代数、可分度量化。L：`BorelSpace`/`borel`。R：有限拓扑 Borel 生成；J：区间代数→Borel 逼近数值。
- 24：局部紧 Hausdorff、正线性泛函→Radon 测度（Riesz 表现定理）。按 Task 2 定案：mathlib 有锚→L 承载；无→J（C[0,1] 泛函→LS 测度数值重建）+P 对拍。
- 25：内/外/正则、Radon 测度性质、紧逼近。L：`Measure.Regular`（正名）。J：格点测度紧逼近数值。
- 26：C₀(X) 对偶=符号 Radon 测度。视 24 的侦察结论同进退。J：对偶配对数值。
- 27：Lusin 型定理（连续函数逼近可测函数）、简单函数+Urysohn 路线。L：Lusin 锚点（正名）；J：阶梯函数连续延拓逼近数值；P 对拍。
- 28：乘积拓扑上测度（可分传递、拓扑版 Fubini）。L：`Measure.prod` 相关正则性引理。
- 29：Polish 上有限 Borel 测度正则性。L：锚点正名（Prohorov 文件族）。J：数值。
- 提交：`docs(measuretheory): B5 拓扑测度（23-29 章）——Riesz/正则性/Lusin/波兰空间；批内全绿 N/N`

### Task 11: B6 测度收敛（30-34 章）

同协议。要点：
- 30：分布函数收敛、Helly 选择、质量逃逸。L：`cdf` API（正名）。J：Helly 子列数值；P 对拍。
- 31：弱收敛定义（有界连续检验）、Portmanteau 全套等价、映像连续性。L：`WeakConvergence`/Portmanteau 文件（正名）；I：`weak_convergence`。J：经验测度各条款数值验证。
- 32：胎紧、Prohorov（紧↔相对紧）、Polish 情形。L：`Tight`/Prohorov（正名）。J：胎紧/非胎紧族数值。
- 33：Lévy-Prohorov 度量、度量化与完备性。视侦察定 L；J：经验 CDF 的 Lévy 距离数值。
- 34：Radon 测度淡收敛、C_c/C_0 对偶刻画、逃逸例子。**通道分工**：J 指数逃逸数值。
- 提交：`docs(measuretheory): B6 测度收敛（30-34 章）——Portmanteau/Prohorov/度量化/淡收敛；批内全绿 N/N`

### Task 12: B7 概率选讲（35-40 章）

同协议。要点：
- 35：独立事件/σ代数/变量族、Borel-Cantelli（两版）、Kolmogorov 0-1 律。L：`Indep` 族+0-1（正名）。R：有限独立性检查；J：BC 数值。
- 36：条件期望存在唯一（RN 路线）、塔性质/Jensen/凸性、投影观点、条件独立。L：`condexp` API；I：`conditional_expectation`。J/P：有限划分条件期望数值。
- 37：正则条件概率、存在性（Polish）、条件分布、例子（离散/连续）。L：`condKernel`（正名）。J：二元高斯条件分布数值。
- 38：一致可积定义、de la Vallée-Poussin 判据、UI⇔L¹ 紧、Vitali 收敛。L：`UniformIntegrable` API；I：视侦察。J：截断尾部积分数值。
- 39：本性上确界、ess sup 与格运算、ess lim。L：`essSup` API。R：有限格 essSup；J：ess sup vs sup 数值。
- 40：解析集、Souslin 运算、Lusin 分离定理、Choquet 容度与可容度性。视侦察（mathlib `IsAnalytic`?）；R：有限 Souslin 模型；docs 以讲清证明为主。
- 提交：`docs(measuretheory): B7 概率选讲（35-40 章）——0-1律/条件期望/UI/essSup/解析集；批内全绿 N/N`

### Task 13: B8 鞅（41-43 章）

同协议。要点：
- 41：鞅/下鞅/上鞅、Doob 极大不等式（L^p 版）、（若严书含）上穿不等式。L：`Submartingale` API（`submartingale_max_mul_le` 等正名，上穿侦察）。R：有限路径 Doob 验证；J：随机游走极大值频率验证。
- 42：下鞅收敛定理、L¹ 收敛↔UI、应用（Pólya 罐/分枝过程灭绝）。L：视侦察（收敛定理有无）；J：Pólya 极限/灭绝概率模拟；R：有限鞅收敛。
- 43：离散局部鞅、停时与可料变换、局部鞅性质。**通道分工**：J 停时变换数值；R 有限停时检查。
- 提交：`docs(measuretheory): B8 离散时间鞅（41-43 章）——Doob 不等式/收敛定理/局部鞅；批内全绿 N/N`

### Task 14: B9 无穷维（44-47 章）

同协议。要点：
- 44：特征函数、正定性、Bochner 定理（ℝⁿ）、唯一性与反转。L：视侦察（`charFun`）；I：`characteristic_function`（正名）。P：FFT 特征函数↔密度往返；J：对拍。
- 45：Sazonov 拓扑、Minlos-Sazonov 定理（正泛函连续⇔可数可加）。**通道分工**：J 协方差算子迹类数值。
- 46：核空间与 Minlos 定理。**通道分工**：J 柱面 Gauss 相容截断数值。
- 47：Hilbert 上 Gauss 测度、均值/协方差、Cameron-Martin 空间、拟不变性、无穷维无 Lebesgue。L：视侦察（`gaussMeasure` ℝⁿ 锚点）；J：Cameron-Martin 有限截断 RKHS 数值。
- 提交：`docs(measuretheory): B9 无穷维测度（44-47 章）——Bochner/Minlos-Sazonov/Minlos/Gauss；批内全绿 N/N`

### Task 15: B10 袁下册 I（48-50 章：概率不等式/特征函数/弱大数律）

**2026-10-19 用户二次指令扩充**：原 48-50（clt/slln/cheatsheet）扩为
48-57 十章（袁下册 13-25 全谱，收官移 57）。袁书两册均有文字层
（已实测：上 338 页/下 373 页，get_text 直出）——免 OCR，取材用
`tools/extract_yuan.py`（落 build/ocr/yuan_v{1,2}_pNNN.txt）。

- [ ] Step 1: 袁书取材：`extract_yuan.py v1 247 329`（上册 10-12 章）+
  `extract_yuan.py v2 11 66`（下册 13-15 章）等按批取页；袁14（pdf34-64）、
  袁17-18（pdf111-159）、袁19（pdf159-184）。
- [ ] Step 2: docs/48 概率不等式（袁14：Chebyshëv 截尾/c_r/Lévy/对称化/
  MZ/Rosenthal/Etemadi/Ottaviani/Kolmogorov 最大值/Hájek-Rényi/
  Hoffmann-Jørgensen；L=分工（Markov 手作先例），J/P/R 承载）。
- [ ] Step 3: docs/49 特征函数（袁17-18：定义计算/不等式族/唯一性/
  Lévy 连续性/Bochner/Pólya/矩-导数/Lévy 等价/正态抽样分布/χ²；
  L `charFun`+`LevyConvergence`；I `Characteristic_Functions`；P FFT 往返）。
- [ ] Step 4: docs/50 弱大数律（袁19：Markov/B-K/Khinchin/MZ/阵列/
  退化收敛/圣彼得堡/K-F；L 视侦察+Markov 三行内核；J/P 模拟）。
- [ ] Step 5: 对账+质量门+提交：`docs(measuretheory): B10 袁下册 I
  （48-50 章）——概率不等式/特征函数/弱大数律；批内全绿 N/N`

### Task 16: B11 袁下册 II（51-53 章：强大数律/CLT/无穷可分）

同协议。要点：
- 51：Kolmogorov 收敛准则/三级数定理/子序列方法/Kronecker 引理/
  Kolmogorov SLLN/MZ SLLN/正规数/蒙特卡罗/更新/Glivenko-Cantelli/
  分位数强相合/核密度（袁20）。L `StrongLaw`；J/P 模拟。
- 52：De Moivre-Laplace/Lindeberg-Lévy/L-F/Lyapunov/阵列/分位数渐近
  正态/多维 CLT/Delta 方法/Berry-Esseen（袁21）。L
  `tendstoInDistribution_inv_sqrt_mul_sum_sub`；I
  `Central_Limit_Theorem`；J/P 模拟+Esseen 界数值。
- 53：无穷可分（袁22：定义性质/构造定理/Lévy-Khinchin/Lévy/Kolmogorov
  三表示/收敛条件）。L=分工；J/P/R 承载（Poisson/正态/Cauchy 族封闭性）。
- 提交：`docs(measuretheory): B11 袁下册 II（51-53 章）——SLLN/CLT/无穷可分；批内全绿 N/N`

### Task 17: B12 袁下册 III（54-57 章：普遍极限/稳定/重对数律/收官）

同协议。要点：
- 54：普遍极限问题（袁23：古典→普遍/(K₀) 条件/无穷小条件/中心收敛
  准则/正态-退化-Poisson 收敛准则）。L=分工；J/P/R 承载。
- 55：半稳定族与稳定分布族（袁24：特征函数刻画/吸引场/慢变函数）。
  L=分工；J/P/R 承载。
- 56：重对数律（袁25：Kolmogorov LIL/Hartman-Wintner/逆问题/广义）。
  L=分工；J/P 蒙特卡罗上下包络。
- 57：CHEATSheet（≥250 行）：全书定理地图（58 章一句一定理）、严/袁
  书对照表、五通道速查、累计实测坑总账汇总。
- [ ] 收官 Step：全量对账 `pwsh -NoProfile -Command '& ./build.ps1 -All'`；
  质量门全项；PLAN.md 全勾；提交
  `docs(measuretheory): B12 收官——袁下册 III（54-57 章）+ CHEATSheet；全量 N/N 全绿`；
  收官报告给用户（总章数/单元数/通道分布/坑账条数），工程经验写入
  memory（新建 measuretheory-tutorial-build.md + MEMORY.md 索引行）。

## Self-Review 记录

- 覆盖核对：spec §2 表 51 章 → Task 4（00）+ Task 6-14（01-47）；spec §4 侦察清单 → Task 2；spec §5 质量门 → Global Constraints + 每批步骤 6-7；spec §6 批次 → Task 1-14 一一对应；spec §1.2 袁书 → Task 15-17（2026-10-19 二次指令扩充为 48-57 十章，袁下册 13-25 全谱）。无缺口。
- 占位符扫描：无 TBD/TODO；"视侦察"是 spec 定义的决策程序（Task 2 落地），不是占位。
- 命名一致性：docs slug / Lean 模块 / Isabelle 理论 / 脚本文件名三处统一以"文件结构"节与 PLAN.md 为准。
