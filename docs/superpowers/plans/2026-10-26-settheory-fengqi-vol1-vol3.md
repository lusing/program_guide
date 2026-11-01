# 冯琦第一卷补全与第三卷高阶无穷扩充 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 补齐第一卷 79–83，新增第三卷 93–122，并将收官章重编号为 123，形成 00–123 连续、正文自包含且七通道全绿的集合论教程。

**Architecture:** 先建立第三卷 OCR 页段缓存并完成 93→123 的无回归重编号，再按数学依赖逐章交付。每章是一个独立单元：一份 docs 教程、七个同章号示例、正文代码引用、构建登记和章末导航；既有 `build.ps1` 自动发现全部单元，不另建平行构建系统。

**Tech Stack:** Markdown、RapidOCR/PyMuPDF、Lean 4.33.1 + mathlib4、Isabelle2025-2/ZF、Coq 8.20.1、Agda 2.8、Julia 1.13、Python 3.13/scipy、SWI-Prolog 10.0.2、PowerShell 7。

**Spec:** `docs/superpowers/specs/2026-10-26-settheory-fengqi-vol1-vol3-design.md`

## Global Constraints

- 每章至少 200 行、文字多于代码；只读 docs 即可学习，所有教学代码必须在对应正文引用并解释。
- 原书编号仅作溯源，不用“见原书”代替证明；大基数假设、相对一致性和 ZFC 定理严格区分。
- 新章固定七文件：Lean `ChNN<Slug>.lean`、Isabelle `STNN/<Slug>.thy`、Coq `ChNN_<slug>.v`、Agda `ChNN_<slug>.agda`、Julia/Python/Prolog `NN_<slug>.{jl,py,pl}`。
- Julia/Python 输出 `==== NN` 与 `END ====`，Prolog 输出 `END ====`；计算输出使用 ASCII，中文只写 Markdown。
- 不用 `sorry/admit` 或隐蔽 `postulate/axiomatization` 取得证明通道绿色；有限实验必须声明不能推出的无穷命题。
- Lean 使用 `H:/Lang/lean4/mathlib4-4.33.1`；Agda 走 WSL Ubuntu-26.04；Python 一律 `G:/scoop/apps/python313/current/python.exe -I`。
- RapidOCR 在 Git Bash 中以 `PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH"` 运行；第三卷 PDF 页 = 书页 + 20，第一卷 PDF 页 = 书签名页。
- 每章 `-Chapter NN` 的报告为 7 个章单元 + 1 个 Lean 整工程单元，即 **8/8**；N 章同验为 **7N+1**。既有全量基线 624，新增 35×7=245，最终目标 **869/869**。
- 每批更新 `settheory/PLAN.md` 的真实完成状态和实测坑；不删除失败日志、不放宽断言、不排除旧章制造全绿。
- 不自动 commit 或 push；只有用户明确要求时才提交。所有命令从 `G:/code/guide/settheory` 运行，Git 路径操作从 `G:/code/guide` 运行。

## File Structure and Artifact Contract

每个章任务中的 `NN` 和 `slug` 按下表展开，不多建辅助示例来逃避正文解释：

| 章 | slug / Lean-Isabelle Slug | docs 文件 |
|---|---|---|
| 79 | trees / Trees | `79-trees.md` |
| 80 | reals / Reals | `80-reals.md` |
| 81 | regularity / Regularity | `81-regularity.md` |
| 82 | polish / Polish | `82-polish.md` |
| 83 | twolines / Twolines | `83-twolines.md` |
| 93 | higherinfinity / Higherinfinity | `93-higherinfinity.md` |
| 94 | measurable / Measurable | `94-measurable.md` |
| 95 | zerosharp / Zerosharp | `95-zerosharp.md` |
| 96 | covering / Covering | `96-covering.md` |
| 97 | iterated / Iterated | `97-iterated.md` |
| 98 | lu / Lu | `98-lu.md` |
| 99 | strongcompact / Strongcompact | `99-strongcompact.md` |
| 100 | supercompact / Supercompact | `100-supercompact.md` |
| 101 | strong / Strong | `101-strong.md` |
| 102 | woodin / Woodin | `102-woodin.md` |
| 103 | levy / Levy | `103-levy.md` |
| 104 | prikry / Prikry | `104-prikry.md` |
| 105 | silver / Silver | `105-silver.md` |
| 106 | schcounter / Schcounter | `106-schcounter.md` |
| 107 | proper / Proper | `107-proper.md` |
| 108 | pfa / Pfa | `108-pfa.md` |
| 109 | genericultrapower / Genericultrapower | `109-genericultrapower.md` |
| 110 | nssaturation / Nssaturation | `110-nssaturation.md` |
| 111 | projective / Projective | `111-projective.md` |
| 112 | sigma12 / Sigma12 | `112-sigma12.md` |
| 113 | sigma13 / Sigma13 | `113-sigma13.md` |
| 114 | solovay / Solovay | `114-solovay.md` |
| 115 | invariance / Invariance | `115-invariance.md` |
| 116 | tower1 / Tower1 | `116-tower1.md` |
| 117 | tower2 / Tower2 | `117-tower2.md` |
| 118 | itertree1 / Itertree1 | `118-itertree1.md` |
| 119 | itertree2 / Itertree2 | `119-itertree2.md` |
| 120 | pd1 / Pd1 | `120-pd1.md` |
| 121 | pd2 / Pd2 | `121-pd2.md` |
| 122 | adlr / Adlr | `122-adlr.md` |
| 123 | topic / Topic（沿用旧示例主体） | `123-cheatsheet.md` |

每章共同修改：`examples/lean/Settheory.lean` 添加对应 import，`examples/isabelle/ROOT` 添加 `STNN` 会话，`README.md` 添加目录行，前后章修改导航。每章共同验收命令为：

```bash
G:/scoop/apps/python313/current/python.exe -I - NN <<'PY'
from pathlib import Path
import sys
n = sys.argv[1]
root = Path.cwd()
docs = list((root / "docs").glob(n + "-*.md"))
assert len(docs) == 1, docs
text = docs[0].read_text(encoding="utf-8")
assert len(text.splitlines()) >= 200
inside = False
code = 0
for line in text.splitlines():
    if line.startswith("```"):
        inside = not inside
    elif inside:
        code += 1
assert len(text.splitlines()) - code > code
patterns = [
    ("examples/lean/Settheory", "Ch" + n + "*.lean"),
    ("examples/isabelle", "ST" + n + "/*.thy"),
    ("examples/coq", "Ch" + n + "_*.v"),
    ("examples/agda", "Ch" + n + "_*.agda"),
    ("examples/julia", n + "_*.jl"),
    ("examples/python", n + "_*.py"),
    ("examples/prolog", n + "_*.pl"),
]
for directory, pattern in patterns:
    files = list((root / directory).glob(pattern))
    assert len(files) == 1, (directory, files)
    assert files[0].name in text, (docs[0], files[0].name)
assert "上一章" in text and "下一章" in text
print("DOC-PASS", n)
PY
pwsh -NoProfile -Command '& ./build.ps1 -Chapter NN'
```

预期先打印 `DOC-PASS NN`，随后构建 `PASS 8 / FAIL 0`。全局检查证明文件：

```bash
G:/scoop/apps/python313/current/python.exe -I - <<'PY'
from pathlib import Path
root = Path("examples")
for pattern in ("**/Ch*.lean", "**/ST*/*.thy", "**/Ch*.v", "**/Ch*.agda"):
    for path in root.glob(pattern):
        if path.name[:2] in {"Ch", "ST"} and path.name[2:4].isdigit() and int(path.name[2:4]) >= 79:
            text = path.read_text(encoding="utf-8").lower()
            for token in ("sorry", "admit"):
                assert token not in text, (path, token)
print("NO-PLACEHOLDER-PROOFS")
PY
```

---

### Task 1: 第三卷 OCR 工具与全谱页段缓存

**Files:**
- Create: `settheory/tools/ocr_fengqi3.py`
- Create: `settheory/build/ocr/fq3_021-164.txt`, `fq3_165-271.txt`, `fq3_272-512.txt`
- Modify: `settheory/PLAN.md`

**Interfaces:**
- Consumes: 第三卷 PDF、`G:\cudnn\9.24\bin\12.9\x64`。
- Produces: `render FIRST LAST` / `ocr FIRST LAST` 两个 1 基 PDF 页码命令；后续任务以 `===== PDF page N =====` 定位原书。

- [x] **Step 1: 先运行不存在的工具，固定失败形态**

```bash
G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py
```

预期：文件不存在，退出码非零；不得把这次探测记为 OCR 成功。

- [x] **Step 2: 实现 1 基页码、断点跳过和分段输出**

以 `ocr_fengqi2.py` 为模板，但将 `PDF` 指向第三卷，`IMG` 改为 `img_fq3`，输出前缀改为 `fq3_`。核心循环必须如下，避免旧脚本的 0 基索引歧义：

```python
def render(first: int, last: int) -> None:
    import pymupdf
    BUILD.mkdir(parents=True, exist_ok=True)
    IMG.mkdir(parents=True, exist_ok=True)
    with pymupdf.open(PDF) as doc:
        for page in range(first, last + 1):
            out = IMG / ("p%03d.png" % page)
            if out.exists():
                continue
            doc[page - 1].get_pixmap(dpi=250).save(str(out))
    print("rendered", first, "-", last)
```

`ocr` 对同一页段逐个读取 `p%03d.png`，每个结果写入 `fq3_FIRST-LAST.txt`，页标使用真实 1 基页码；缺图立即 `FileNotFoundError`，不静默跳页。

- [x] **Step 3: 小页段试跑并核对目录**

```bash
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py render 19 22
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py ocr 19 22
```

预期：`fq3_019-022.txt` 含第 1–3 章标题与页码；核对书页 1、3、145、252 分别落在 PDF 21、23、165、272。

- [x] **Step 4: 生成三大页段缓存并检查完整性**

```bash
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py render 23 512
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py ocr 23 164
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py ocr 165 271
PATH="/g/cudnn/9.24/bin/12.9/x64:$PATH" G:/scoop/apps/python313/current/python.exe -I tools/ocr_fengqi3.py ocr 272 512
G:/scoop/apps/python313/current/python.exe -I - <<'PY'
from pathlib import Path
for a, b in ((23, 164), (165, 271), (272, 512)):
    text = Path(f"build/ocr/fq3_{a:03d}-{b:03d}.txt").read_text(encoding="utf-8")
    missing = [n for n in range(a, b + 1) if f"===== PDF page {n} =====" not in text]
    assert not missing, missing
print("OCR-PASS 23-512")
PY
```

在 PLAN 记录三段缓存和“公式须回读页面”的边界。

### Task 2: 93→123 重编号与 624 单元基线回归

**Files:**
- Rename: `docs/93-cheatsheet.md` → `docs/123-cheatsheet.md`
- Rename: 七通道所有 `93`/`Ch93`/`ST93` 示例为 `123`/`Ch123`/`ST123`，slug 保持 `topic/Topic`
- Modify: `examples/isabelle/ROOT`, `examples/lean/Settheory.lean`, `docs/92-boolval.md`, `README.md`, `PLAN.md`
- Modify: `settheory/build.ps1`（实测发现三位章号被两位正则误归到 12）
- Test: `settheory/tools/test_three_digit_chapter.py`（串章、8 单元、数字标记边界三项回归）

**Interfaces:**
- Produces: 可独立验证的收官章 123；章号 93 留给新导引，其他既有章不变。

- [x] **Step 1: 盘点旧引用并保存基线清单**

```bash
pwsh -NoProfile -Command '& ./build.ps1 -All'
git -C G:/code/guide status --short
```

预期基线 624/624；若基线不绿，先修复既有回归，不执行重编号。

- [x] **Step 2: 用 Git 路径移动保留历史**

```bash
git mv settheory/docs/93-cheatsheet.md settheory/docs/123-cheatsheet.md
git mv settheory/examples/lean/Settheory/Ch93Topic.lean settheory/examples/lean/Settheory/Ch123Topic.lean
git mv settheory/examples/isabelle/ST93 settheory/examples/isabelle/ST123
git mv settheory/examples/coq/Ch93_topic.v settheory/examples/coq/Ch123_topic.v
git mv settheory/examples/agda/Ch93_topic.agda settheory/examples/agda/Ch123_topic.agda
git mv settheory/examples/julia/93_topic.jl settheory/examples/julia/123_topic.jl
git mv settheory/examples/python/93_topic.py settheory/examples/python/123_topic.py
git mv settheory/examples/prolog/93_topic.pl settheory/examples/prolog/123_topic.pl
```

将 ROOT 的 `session ST93 in "ST93"` 改为 ST123，文件标题和计算标记改为 123，92 章下一章指向 `93-higherinfinity.md`；此时允许该链接短暂待 Task 4 落地，但不得保留指向旧收官的误导文本。

- [x] **Step 3: 验证重编号章和全量基线**

```bash
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 123'
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

预期分别 8/8、624/624。搜索 `93-cheatsheet|Ch93Topic|Ch93_topic|ST93|==== 93`，只准出现 Task 4 的新导引计划，不准出现旧文件引用。

### Task 3: 79 树、苏斯林树、马丁公理与划分定理

**Files:** 按 Artifact Contract 创建 `79-trees` 七示例与 `docs/79-trees.md`；修改 78/80 导航、ROOT、Lean 根、README、PLAN。

**Interfaces:** 取材 `build/ocr/fq_153-236.txt` PDF 211–236；产出有限树高度/层/枝、K6 染色、有限泛型相遇等公共定义，供 82、103、107 复用概念但不跨语言 import。

- [x] **Step 1:** 提炼 §2.5–2.6：树的高度与层、链/反链、Aronszajn/Suslin、MA 的组合形式、小划分与大划分定理；正文完整解释 Ramsey 箭头、苏斯林树与直线接口及选定练习。
- [x] **Step 2:** 七通道实现并证明/断言：Lean 有限树父节点秩递减，Isabelle/ZF 有限树层互不相交，Coq 可决定 K6 二染色，Agda 树递归计算高度，Julia 穷举 K6 得 `R(3,3)>5` 且 `≤6`，Python 独立枚举同一双色 Ramsey 命题，Prolog 搜索有限泛型滤子与树分支。
- [x] **Step 3:** 在正文逐一引用七个文件名，解释有限树和 K6 实验为何不能证明苏斯林树存在；运行全局 DOC-PASS 检查。
- [x] **Step 4:** 运行 `-Chapter 79`，预期 8/8；将 PLAN 的 F7 状态改成真实结果。

### Task 4: 93 高阶无穷导引

**Files:** `93-higherinfinity` 七示例与 `docs/93-higherinfinity.md`；连接 92→93→94。

**Interfaces:** 取材 `fq3_019-022.txt`；产出大基数强度 DAG 与“假设—技术—实数后果”三列表，供 94–122 的导语使用。

- [x] **Step 1:** 自包含讲解无穷公理为何形成层级、组合/逻辑/哲学三面、内模型与外模型、连续统与可定义实数正则性两条主线；明确一致性强度不是基数大小也不是真值概率。
- [x] **Step 2:** 七通道分别实现同一小型强度 DAG：Lean/Isabelle/Coq/Agda 证明可达关系传递及无环有限图，Julia/Python 独立拓扑排序，Prolog 查询 `ZFC→可测→超紧→武丁见证` 路径；节点只表示本书采用的相对强度含义。
- [x] **Step 3:** 正文列出三条证明链的阅读地图，并解释 DAG 是知识组织工具而非一致性证明；DOC-PASS。
- [x] **Step 4:** `-Chapter 93` 8/8；README 将第十二篇起始章标为 93。

### Task 5: 80 实数轴、连续统与拓扑

**Files:** `80-reals` 七示例与 `docs/80-reals.md`；连接 79→80→81。

**Interfaces:** 第一卷 PDF 237–250；产出有理区间、嵌套区间和 Dedekind 截断的有限实验。

- [x] **Step 1:** 提炼 §3.1–3.4：序完备、康托尔唯一性、实数代数运算、连续统势、序拓扑、距离完备、区间套与有限交紧致性；实数构造不得只引用前文。
- [x] **Step 2:** Lean 锚定实数条件完备与 Archimedean，Isabelle/ZF 验证有限 Dedekind 截断，Coq 验证有理截断运算样本，Agda 实现有符号区间端点归纳，Julia/Python 用不同二分实现验证区间套与 `sqrt 2` 截断，Prolog 检查有限交性质。
- [x] **Step 3:** 解释数值近似不证明实数完备性，正文给出真正证明；DOC-PASS。
- [x] **Step 4:** `-Chapter 80` 8/8；PLAN 的 F7 两项均真实收官。

### Task 6: 94 可测基数、正规超滤子与超幂

**Files:** `94-measurable` 七示例与 `docs/94-measurable.md`；取材第三卷 PDF 23–43。

- [x] **Step 1:** 完整讲解非平凡 κ-完全正规超滤子、可测→不可达及 κ 下不可达集聚测、完全超滤到正规超滤、Łoś、良基超幂、Mostowski 坍缩与初等嵌入。
- [x] **Step 2:** 四证明通道实现有限幂集代数与主超滤商；Coq/Agda 额外证明有限集上每个超滤皆主；Julia/Python 穷举有限超滤并核对主超幂退化，Prolog 求有限商等价类。
- [x] **Step 3:** 正文以定理 1.1–1.3 的证明账为主，机器只承担有限 Łoś/超滤部分；DOC-PASS。
- [x] **Step 4:** `-Chapter 94` 8/8；记录任何超幂符号 OCR 校订。

### Task 7: 81 实数子集正则性

**Files:** `81-regularity` 七示例与 `docs/81-regularity.md`；第一卷 PDF 251–266。

- [x] **Step 1:** 讲解 Baire 纲定理、稀疏 σ-理想、MA 下稠密开集交、Baire 特性、Lebesgue 零测/可测、Vitali 反例、完备子集特性及闭集二分定理。
- [x] **Step 2:** Lean 锚定 Baire 与测度官方定理，Isabelle/Coq 验证有限理想闭包和模有理等价，Agda 构造完备二叉树分支，Julia/Python 分别做 Cantor 集与 Vitali 有限商实验，Prolog 判定有限对称差。
- [x] **Step 3:** 三种正则性分别说明“无反例”的精确点类，不混为可定义性；DOC-PASS。
- [x] **Step 4:** `-Chapter 81` 8/8；PLAN 的 F8 首章标记完成。

### Task 8: 95 `0#` 与 Silver 不可辨别元

**Files:** `95-zerosharp` 七示例与 `docs/95-zerosharp.md`；第三卷 PDF 44–74。

- [x] **Step 1:** 从 L 的不可辨别元讲到 EM 蓝图、`0#`、Silver 不可辨别元、L 的非平凡初等自嵌入及其等价表述；每个方向均解释所需假设。
- [x] **Step 2:** 四证明通道实现有限结构上的同型 n-元组与不可辨别集判定，Coq/Agda 对有限二染色做可决定搜索；Julia/Python 独立枚举小模型不可辨别集，Prolog 生成蓝图候选并检查公式一致性。
- [x] **Step 3:** 明确有限不可辨别实验不构造 `0#`；正文给出从可测到 `0#` 的逻辑接口和反向后果；DOC-PASS。
- [x] **Step 4:** `-Chapter 95` 8/8。

### Task 9: 82 贝尔空间、波兰空间、投影集与博弈

**Files:** `82-polish` 七示例与 `docs/82-polish.md`；第一卷 PDF 267–299。

- [x] **Step 1:** 覆盖 Baire 空间同胚、树表示、Polish 空间、解析/余解析、Suslin 运算、投影集层级、Banach–Mazur 博弈与正则性刻画。
- [x] **Step 2:** Lean 锚定 Baire 空间/完备度量，Isabelle 检查有限树产生闭集，Coq/Agda 实现有限 Gale–Stewart 逆向归纳，Julia/Python 独立求解同一博弈并比较策略，Prolog 搜索必胜策略与树投影。
- [x] **Step 3:** 正文把“树枝—闭集—投影—解析集”连成一条图，不只定义点类；DOC-PASS。
- [x] **Step 4:** `-Chapter 82` 8/8；PLAN 的 F8 完整收官。

### Task 10: 96 Jensen 覆盖引理

**Files:** `96-covering` 七示例与 `docs/96-covering.md`；第三卷 PDF 75–86。

- [x] **Step 1:** 以 `0#` 不存在为阈值假设，陈述并拆解覆盖引理、L 中覆盖、奇异基数保持/奇异化后果及其与 SCH 的关系；证明路线图覆盖每个归约。
- [x] **Step 2:** 四证明通道验证有限集覆盖、基数上界和链式并的有限引理；Julia/Python 独立搜索“无小覆盖”的反例族，Prolog 生成覆盖证书，Agda 给出结构归纳覆盖构造。
- [x] **Step 3:** 明确有限覆盖不模拟 Jensen 定理的 L 层归纳；DOC-PASS。
- [x] **Step 4:** `-Chapter 96` 8/8。

### Task 11: 83 非标准实数直线与苏斯林直线

**Files:** `83-twolines` 七示例与 `docs/83-twolines.md`；第一卷 PDF 300–313；连接 83→84，并删除 84 的待写提示。

- [x] **Step 1:** 从自由超滤构造超实数、Łoś/转移、无穷小与标准部分，讲清非 Archimedean；再定义苏斯林直线、可分/ccc/完备之间的关系和苏斯林假设。
- [x] **Step 2:** 四证明通道验证主超滤超幂退化和有限非 Archimedean 序，Coq/Agda 实现有限超有理算术，Julia/Python 用形式化截断超有理数核对无穷小不等式，Prolog 检查有限 ccc 区间族。
- [x] **Step 3:** 说明截断超有理数不是完整超实数，自由超滤存在性与 AC 的关系写入正文；DOC-PASS。
- [x] **Step 4:** `-Chapter 83` 8/8；再验 `-Chapter @('78','79','80','81','82','83','84')`，预期 50/50，PLAN 的 F9 第一卷部分收官。

### Task 12: 97 迭代超幂

**Files:** `97-iterated` 七示例与 `docs/97-iterated.md`；第三卷 PDF 87–107。

- [x] **Step 1:** 定义线性迭代超幂的 successor/limit 阶段、直接极限、自然嵌入、正规测度序列、良基性和临界点轨迹；解释为何不能用任意 ω 序列下降。
- [x] **Step 2:** 四证明通道实现有限直接系统与主嵌入迭代，Agda 证明有限链嵌入复合，Julia/Python 对拍直接极限代表元，Prolog 检查临界点表和极限阶段代表依赖。
- [x] **Step 3:** 正文完整解释良基性定理，不以有限恒等迭代冒充一般定理；DOC-PASS。
- [x] **Step 4:** `-Chapter 97` 8/8。

### Task 13: 98 可测基数内模型 `L[U]`

**Files:** `98-lu` 七示例与 `docs/98-lu.md`；第三卷 PDF 108–118。

- [x] **Step 1:** 从第二卷 L[A] 回顾相对可构造层级，讲清 `L[U]=L[Ũ]` 截断、正规测度、凝聚、GCH 与可测内模型的典范性。
- [x] **Step 2:** Isabelle/ZF 锚定 Constructible/DPow，Lean/Coq/Agda 实现有限层级和谓词截断，Julia/Python 对拍同一测度不同外延表示的层级输出，Prolog 验证有限截断不变量。
- [x] **Step 3:** 区分“U 是谓词”与“U 是内模型中的真正超滤”，正文完整解释二者差异；DOC-PASS。
- [x] **Step 4:** `-Chapter 98` 8/8。

### Task 14: 99 强紧基数

**Files:** `99-strongcompact` 七示例与 `docs/99-strongcompact.md`；第三卷 PDF 119–128。

- [x] **Step 1:** 覆盖超紧基数的章节引言、强紧定义、λ-完全滤子/超滤扩展、无穷语言紧性和初等嵌入刻画；比较强紧与超紧的定义资源。
- [x] **Step 2:** 四证明通道实现有限滤基扩展与有限理论可满足性，Coq/Agda 做有限紧性归纳，Julia/Python 独立搜索滤基和反例，Prolog 检查有限理论任意有限子集可满足。
- [x] **Step 3:** 说明有限紧性只是无穷语言紧性的骨架；DOC-PASS。
- [x] **Step 4:** `-Chapter 99` 8/8。

### Task 15: 100 超紧基数

**Files:** `100-supercompact` 七示例与 `docs/100-supercompact.md`；第三卷 PDF 129–132。

- [x] **Step 1:** 定义 `P_κ(λ)` 上正规精细超滤、超紧嵌入、目标模型 λ-闭包和反射后果；逐条翻译“精细”“正规”“κ-完全”。
- [x] **Step 2:** 四证明通道验证有限 `P_κ(λ)` 的精细锥与回归函数，Julia/Python 穷举小型正规/非正规测度候选，Prolog 检查有限对角线交，Agda 构造有限支集。
- [x] **Step 3:** 正文用同一回归函数例子连接 Fodor、正规测度和超幂表示；DOC-PASS。
- [x] **Step 4:** `-Chapter 100` 8/8。

### Task 16: 101 强基数与超强基数

**Files:** `101-strong` 七示例与 `docs/101-strong.md`；第三卷 PDF 133–153。

- [x] **Step 1:** 定义 λ-强、强、超强，解释 `V_λ⊆M`、目标闭包、extender 见证和这些条件的强度差异；补齐书中相关嵌入引理。
- [x] **Step 2:** 四证明通道验证有限秩层包含、嵌入复合和见证条件，Julia/Python 生成有限强度矩阵，Prolog 查询某见证满足哪些条款，Agda 实现秩层递归。
- [x] **Step 3:** 用表区分“单个 λ 的见证”“对所有 λ 有见证”“目标模型闭包”，不把有限矩阵当强度证明；DOC-PASS。
- [x] **Step 4:** `-Chapter 101` 8/8。

### Task 17: 102 武丁基数

**Files:** `102-woodin` 七示例与 `docs/102-woodin.md`；第三卷 PDF 154–164（含选定练习）。

- [x] **Step 1:** 以函数 `f:κ→κ` 和局部见证嵌入定义 Woodin，解释临界点、`j(f)(κ)`、`V_{j(f)(κ)}` 与目标闭包；连接强基数和后续决定性假设。
- [x] **Step 2:** 四证明通道实现有限函数索引见证表和秩层约束，Coq/Agda 检查 `j(f)(crit j)` 的有限代入模型，Julia/Python 独立搜索伪见证并列失败原因，Prolog 验证局部见证族。
- [x] **Step 3:** 重点解释“每个函数都有足够强见证”是全称量词，单一嵌入不够；DOC-PASS。
- [x] **Step 4:** `-Chapter 102` 8/8；`-Chapter @('93','94','95','96','97','98','99','100','101','102')` 预期 71/71。

### Task 18: 103 小型扩张与 Lévy 崩塌

**Files:** `103-levy` 七示例与 `docs/103-levy.md`；第三卷 PDF 165–175。

- [x] **Step 1:** 讲小力迫保持大基数的嵌入提升机制、`Col(ω,<κ)` 条件、链条件/闭包、因子引理与不可达基数变为 `ω₁` 的精确过程。
- [x] **Step 2:** 四证明通道验证有限偏序嵌入/提升图，Julia/Python 独立生成 Lévy 有限条件和泛型相遇，Prolog 检查支撑相容性，Agda 证明有限支撑拼接。
- [x] **Step 3:** 正文区分“保持基数”“把旧基数可数化”和“保持大基数见证”三本账；DOC-PASS。
- [x] **Step 4:** `-Chapter 103` 8/8。

### Task 19: 104 Prikry 力迫

**Files:** `104-prikry` 七示例与 `docs/104-prikry.md`；第三卷 PDF 176–180。

- [x] **Step 1:** 定义 `(s,A)` 条件、stem 延长与纯延长、Prikry 性质、泛型 ω-序列、共尾度改变、不加有界集和保基数证明。
- [x] **Step 2:** 四证明通道验证 stem 序与纯延长自反传递，Julia/Python 穷举有限纯决策，Prolog 生成泛型候选，Agda 实现 stem 列表递归和相容判定。
- [x] **Step 3:** 用同一条件例子逐步展示“决定语句而不动 stem”；DOC-PASS。
- [x] **Step 4:** `-Chapter 104` 8/8。

### Task 20: 105 Silver 力迫构思

**Files:** `105-silver` 七示例与 `docs/105-silver.md`；第三卷 PDF 181–192。

- [x] **Step 1:** 从可测基数上的 Silver 条件、相容与泛型对象讲起，给出与 Prikry 的条件结构对照及连续统函数控制的证明账。
- [x] **Step 2:** 四证明通道验证有限部分函数相容/合并，Coq/Agda 证明条件延长的偏序律，Julia/Python 独立搜索泛型滤子，Prolog 输出相遇稠密集的条件链。
- [x] **Step 3:** 明确有限部分函数实验对应哪一条力迫引理，不声称已经验证可测基数上的连续统定理；DOC-PASS。
- [x] **Step 4:** `-Chapter 105` 8/8。

### Task 21: 106 力迫 SCH 最小反例

**Files:** `106-schcounter` 七示例与 `docs/106-schcounter.md`；第三卷 PDF 193–216。

- [x] **Step 1:** 将 §2.5 写成完整证明链：准备可测/强基数、改变共尾度、控制幂集、定位最小奇异反例、验证 κ 以下 SCH 与 κ 处失败；逐一交代大基数假设如何使用。
- [x] **Step 2:** 四证明通道验证有限“最小反例”归约和指数约束表，Julia/Python 独立实现同一有限 SCH 账簿并搜索最小失败节点，Prolog 检查所有更小节点满足约束。
- [x] **Step 3:** 正文把“数值指数实验”和“真实奇异基数证明”分栏，不把有限失败称作 SCH 反例；DOC-PASS。
- [x] **Step 4:** `-Chapter 106` 8/8。

### Task 22: 107 恰当力迫

**Files:** `107-proper` 七示例与 `docs/107-proper.md`；第三卷 PDF 217–223。

- [x] **Step 1:** 定义可数传递模型、主条件、`(M,P)`-泛型、properness，讲清保持 `ω₁` 与保持荟萃集的证明及经典例子。
- [x] **Step 2:** 四证明通道实现有限模型上的主条件证书，Julia/Python 独立搜索 `(M,P)`-泛型条件，Prolog 检查泛型性与相容性，Agda 证明条件复合保持证书。
- [x] **Step 3:** 逐个解释 `p`、`M`、`q≤p` 在主条件定义里的角色；DOC-PASS。
- [x] **Step 4:** `-Chapter 107` 8/8。

### Task 23: 108 恰当迭代与 PFA

**Files:** `108-pfa` 七示例与 `docs/108-pfa.md`；第三卷 PDF 224–229。

- [x] **Step 1:** 讲可数支撑迭代、proper 保持、PFA 的稠密集表述、与 MA 的强弱关系及典型应用；迭代保持定理给完整归约。
- [x] **Step 2:** 四证明通道验证有限支撑限制和拼接，Julia/Python 对拍有限迭代条件，Prolog 搜索稠密集相遇，Coq/Agda 证明支撑并集仍有限。
- [x] **Step 3:** 正文明确 PFA的“ℵ₁ 个稠密集”不能在有限实验中直接出现；DOC-PASS。
- [x] **Step 4:** `-Chapter 108` 8/8。

### Task 24: 109 非荟萃理想与泛型超幂

**Files:** `109-genericultrapower` 七示例与 `docs/109-genericultrapower.md`；第三卷 PDF 230–239。

- [x] **Step 1:** 由 `NS_κ^+` 条件定义泛型超滤与泛型超幂，讲清代表函数、Łoś、良基性/precipitous 的接口和临界点计算。
- [x] **Step 2:** 四证明通道验证有限正测集代数、商关系与有限 Łoś，Julia/Python 独立构造泛型超滤候选，Prolog 检查所有稠密集相遇和下降链。
- [x] **Step 3:** 区分普通超幂与泛型超幂：后者先在扩张中取滤子；DOC-PASS。
- [x] **Step 4:** `-Chapter 109` 8/8。

### Task 25: 110 NS 峭壁、饱和与投影光影原理

**Files:** `110-nssaturation` 七示例与 `docs/110-nssaturation.md`；第三卷 PDF 240–271（含选定练习）。

- [x] **Step 1:** 讲 precipitous 与 saturated 的不同逻辑内容、NS 峭壁/饱和的力迫构造、饱和数、投影荟萃集与光影原理；给出泛型超幂后果的证明链。
- [x] **Step 2:** 四证明通道验证有限理想正测集反链和投影/提升，Julia/Python 独立计算有限饱和界与投影像，Prolog 检查光影原理的有限实例。
- [x] **Step 3:** 明确“峭壁”译名对应 precipitous，不把饱和与峭壁混为同义；DOC-PASS。
- [x] **Step 4:** `-Chapter 110` 8/8；`-Chapter @('103','104','105','106','107','108','109','110')` 预期 57/57。

### Task 26: 111 投影精细分层与余解析集合

**Files:** `111-projective` 七示例与 `docs/111-projective.md`；第三卷 PDF 272–291。

- [x] **Step 1:** 从树表示重建投影层，讲余解析集的良基树、秩、有界性、规范范数和完美子集/可测/Baire 正则性。
- [x] **Step 2:** Lean 锚定拓扑/测度，Isabelle/Coq/Agda 实现有限树良基判定与秩递归，Julia/Python 独立计算秩并构造完美子树，Prolog 搜索下降链和投影见证。
- [x] **Step 3:** 正文明确余解析与解析补集的关系，机器秩计算只验证有限树引理；DOC-PASS。
- [x] **Step 4:** `-Chapter 111` 8/8。

### Task 27: 112 `Σ^1_2` 集合

**Files:** `112-sigma12` 七示例与 `docs/112-sigma12.md`；第三卷 PDF 292–318。

- [x] **Step 1:** 讲 `Σ^1_2` 的双层树表示、Shoenfield 绝对性、可测基数提供的资源及相应正则性定理；证明每个投影/补集转换。
- [x] **Step 2:** 四证明通道实现有限两级树和跨有限扩张的绝对求值，Julia/Python 独立比较两模型真值，Prolog 查询投影/补集见证，Agda 实现公式结构递归。
- [x] **Step 3:** 正文说明有限绝对性测试不是 Shoenfield 定理本身，但每个有限断言对应证明中的树表示等式；DOC-PASS。
- [x] **Step 4:** `-Chapter 112` 8/8。

### Task 28: 113 `Σ^1_3` 集合与广泛贝尔特性

**Files:** `113-sigma13` 七示例与 `docs/113-sigma13.md`；第三卷 PDF 319–342。

- [x] **Step 1:** 讲 `Σ^1_3` 的表示难点、广泛贝尔集合的两种树在力迫扩张中仍给出互补投影、与 Baire 特性及投影正则性的关系。
- [x] **Step 2:** 四证明通道实现有限双树互补条件和外延稳定性，Julia/Python 独立枚举反例，Prolog 检查扩张前后投影不变，Coq/Agda 证明有限补集交为空。
- [x] **Step 3:** 正文突出“广泛”是所有相关力迫扩张的量化，不能只验证当前宇宙；DOC-PASS。
- [x] **Step 4:** `-Chapter 113` 8/8。

### Task 29: 114 Solovay 内模型与 `HOD(Ω)`

**Files:** `114-solovay` 七示例与 `docs/114-solovay.md`；第三卷 PDF 343，并用 103 的 Lévy 崩塌证明接口。

- [x] **Step 1:** 定义 `L(ℝ)^{Col(ω,<κ)}`、对称对象、OD/HOD 及 `HOD(Ω)`，解释不可达 κ 与实数集正则性模型的构造。
- [x] **Step 2:** 四证明通道验证有限群作用下的不变对象与 HOD 闭包，Julia/Python 独立计算轨道稳定子，Prolog 搜索可定义代表，Agda 实现轨道递归。
- [x] **Step 3:** 正文交代为何取对称/遗传可定义子模型而不是整个泛型扩张；DOC-PASS。
- [x] **Step 4:** `-Chapter 114` 8/8。

### Task 30: 115 Lévy 扩张正则性与 `L(ℝ)` 理论不变性

**Files:** `115-invariance` 七示例与 `docs/115-invariance.md`；第三卷 PDF 344–351。

- [x] **Step 1:** 完成 §3.2.2 的可测/可定义实数正则性证明，再讲 `L(ℝ)`-理论在指定大基数和力迫下不变的假设、对称论证与结论边界。
- [x] **Step 2:** 四证明通道实现有限公式在两个泛型求值点的不变证书，Julia/Python 独立枚举滤子并比较理论片段，Prolog 检查对称映射保真。
- [x] **Step 3:** 不变性必须限定公式和扩张类型，不泛化成“所有力迫都不改变实数理论”；DOC-PASS。
- [x] **Step 4:** `-Chapter 115` 8/8；`-Chapter @('111','112','113','114','115')` 预期 36/36。

### Task 31: 116 荟萃塔 I：定义、力迫与泛型超幂

**Files:** `116-tower1` 七示例与 `docs/116-tower1.md`；第三卷 PDF 352–410，取材到塔泛型超幂和良基性证明结束。

- [x] **Step 1:** 定义荟萃塔条件、支撑、相容/投影、塔泛型与超幂，逐步证明临界点、代表函数及良基性相关引理。
- [x] **Step 2:** 四证明通道实现有限支撑塔和投影相容，Julia/Python 独立搜索有限塔链，Prolog 验证泛型相遇，Agda 证明支撑单调与复合。
- [x] **Step 3:** 用一张“条件→泛型超滤→超幂→嵌入”图串联所有符号；DOC-PASS。
- [x] **Step 4:** `-Chapter 116` 8/8；在 PLAN 记下与 117 的精确分界定理。

### Task 32: 117 荟萃塔 II：表示与正则性接口

**Files:** `117-tower2` 七示例与 `docs/117-tower2.md`；承接 116 的分界定理至 PDF 410。

- [x] **Step 1:** 完成荟萃塔表示定理、Woodin 假设的使用、泛型超幂对实数点类的表示及后续投影决定性的接口；不重复 116 的基础定义。
- [x] **Step 2:** 四证明通道验证有限塔投影诱导的表示等式，Julia/Python 对拍同一集合的两种树表示，Prolog 检查见证提升和临界点小模型表。
- [x] **Step 3:** 正文明确每个表示等式在后续 Martin–Steel 证明中消费的位置；DOC-PASS。
- [x] **Step 4:** `-Chapter 117` 8/8；联合 `-Chapter @('116','117')` 预期 15/15。

### Task 33: 118 迭代树 I：非线性迭代、分支与比较

**Files:** `118-itertree1` 七示例与 `docs/118-itertree1.md`；第三卷 PDF 411–455，取材到比较法所需树结构完备。

- [x] **Step 1:** 定义树序、节点模型、extender 应用、stretching、分支与 cofinal 分支，解释与 97 线性迭代的差别及比较法为什么需要树。
- [x] **Step 2:** 四证明通道实现有限迭代树和合法边约束，Coq/Agda 证明根到节点路径唯一，Julia/Python 独立枚举合法树，Prolog 搜索 cofinal 分支和非法下降链。
- [x] **Step 3:** 正文以一个真实形状的有限树逐层画清模型和嵌入，不把树简化成列表；DOC-PASS。
- [x] **Step 4:** `-Chapter 118` 8/8；PLAN 记录与 119 的分界。

### Task 34: 119 迭代树 II：可迭代性与武丁表示

**Files:** `119-itertree2` 七示例与 `docs/119-itertree2.md`；承接 118 至 PDF 455。

- [x] **Step 1:** 完成比较、分支选择、可迭代策略、所需正规化/唯一性结论及武丁表示接口；明确哪些是原书完整证明、哪些作为后续 Martin–Steel 的技术引理。
- [x] **Step 2:** 四证明通道实现有限策略函数和比较树终止证书，Julia/Python 独立对拍策略，Prolog 搜索坏分支，Agda 用结构递归证明有限比较终止。
- [x] **Step 3:** 解释“存在良分支”与“策略系统选择良分支”的强度差别；DOC-PASS。
- [x] **Step 4:** `-Chapter 119` 8/8；联合 `-Chapter @('118','119')` 预期 15/15。

### Task 35: 120 投影集合稳赢性 I：博弈基础与层级归纳

**Files:** `120-pd1` 七示例与 `docs/120-pd1.md`；第三卷 PDF 456–499 前半，至投影层归纳所需的闭博弈/开闭结果完整。

- [x] **Step 1:** 自包含重建 Gale–Stewart、策略、开闭决定性、补充/投影对博弈的变换，并启动 Martin–Steel 的投影层归纳。
- [x] **Step 2:** 四证明通道实现有限完美信息博弈逆向归纳，Coq/Agda 证明开集策略胜负判定，Julia/Python 独立求解同一博弈，Prolog 生成必胜策略证书。
- [x] **Step 3:** 正文解释开闭决定性为何不直接给出全部投影决定性，归纳还需哪些大基数表示；DOC-PASS。
- [x] **Step 4:** `-Chapter 120` 8/8；记录与 121 的归纳命题接口。

### Task 36: 121 投影集合稳赢性 II：Martin–Steel 与投影决定性

**Files:** `121-pd2` 七示例与 `docs/121-pd2.md`；承接 120 至 PDF 499。

- [x] **Step 1:** 以 116–120 的表示和迭代工具完成 Martin–Steel 证明路线：武丁假设→辅助博弈→策略转移→投影层归纳→PD；交代每个假设的消耗位置。
- [x] **Step 2:** 四证明通道验证有限辅助博弈与策略提升/拉回，Julia/Python 对拍原博弈和辅助博弈的胜负，Prolog 检查策略证书在两层间保持一致。
- [x] **Step 3:** 明确有限对拍只测试策略变换的保赢等式，不声称形式化 Martin–Steel；DOC-PASS。
- [x] **Step 4:** `-Chapter 121` 8/8；联合 `-Chapter @('120','121')` 预期 15/15。

### Task 37: 122 `AD^{L(ℝ)}` 与全书主线汇合

**Files:** `122-adlr` 七示例与 `docs/122-adlr.md`；第三卷 PDF 500–512（含选定练习）。

- [x] **Step 1:** 从大基数与迭代假设推到 `L(ℝ)` 中 AD，讲清 Woodin 表示定理、`L(ℝ)` 的特殊性及 AD 给出的实数正则性；回扣 CH、可定义秩序和全书两条主线。
- [x] **Step 2:** 四证明通道验证有限 AD 后果的博弈模型，Julia/Python 独立计算有限点类策略和正则性证书，Prolog 检查“每个相关博弈一方有必胜策略”的有限实例。
- [x] **Step 3:** 明确 `AD` 与 AC 的冲突层次及“在 `L(ℝ)` 内”不可省略；DOC-PASS。
- [x] **Step 4:** `-Chapter 122` 8/8；`-Chapter @('93','94','95','96','97','98','99','100','101','102','103','104','105','106','107','108','109','110','111','112','113','114','115','116','117','118','119','120','121','122')` 预期 211/211。

### Task 38: 123 六书收官、全书链接与 869 单元最终对账

**Files:**
- Modify: `docs/123-cheatsheet.md`, `docs/00-intro.md`, `README.md`, `PLAN.md`
- Modify: `examples/lean/Settheory/Ch123Topic.lean`, `examples/isabelle/ST123/Topic.thy`, `examples/coq/Ch123_topic.v`, `examples/agda/Ch123_topic.agda`, `examples/julia/123_topic.jl`, `examples/python/123_topic.py`, `examples/prolog/123_topic.pl`

**Interfaces:** 消费全部章目录、PLAN 实测坑和最终 `-All` 报告；产出唯一全书入口与六书/三卷对照总表。

- [ ] **Step 1:** 将 123 写成不少于 200 行的真实收官教程：六书总表、冯琦三卷表、大基数强度轴、力迫技术轴、实数正则性轴、七通道职责与机器化边界、全项目实测坑索引；删除“暂名”“五书”“00 到 56”等旧表述。
- [ ] **Step 2:** 更新 123 七示例为实际对账程序：Lean/Isabelle/Coq/Agda 验证有限三轴关系，Julia/Python/Prolog 分别断言 124 个章号连续、35 个新章和最终单元公式 `624+35*7=869`；正文逐个引用并解释，不能保留仅打印标题的旧 stub。
- [ ] **Step 3:** README 写成六底本、十二篇、124 章（00–123），列全 93–122；PLAN 将 H0–H19 全标为实际完成并记录真实失败/修复。检查链接和旧章号：

```bash
G:/scoop/apps/python313/current/python.exe -I - <<'PY'
from pathlib import Path
import re
root = Path.cwd()
docs = list((root / "docs").glob("[0-9][0-9]-*.md"))
numbers = sorted(int(p.name[:2]) for p in docs)
assert numbers == list(range(124)), (len(numbers), sorted(set(range(124)) - set(numbers)))
for path in docs:
    text = path.read_text(encoding="utf-8")
    for target in re.findall(r"\]\(([^)#]+\.md)", text):
        assert (path.parent / target).exists(), (path, target)
for path in (root / "README.md", root / "PLAN.md", *docs):
    text = path.read_text(encoding="utf-8")
    assert "79–83 写作中" not in text and "79-83 写作中" not in text
    assert "93-cheatsheet.md" not in text
print("LINK-PASS 00-123")
PY
```

- [ ] **Step 4:** 运行章级收官、全量验证和最终 Git 状态审计：

```bash
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 123'
pwsh -NoProfile -Command '& ./build.ps1 -All'
git -C G:/code/guide status --short
```

预期章级 8/8，全量 **总计 869 单元：PASS 869 / FAIL 0**、退出码 0。最终交付说明必须引用真实报告；若数目因合理新增单元变化，先解释每个额外单元，再写实际总数，不硬改文档凑数。

## Plan Self-Review Notes

- Spec §3 的 OCR 与页码要求由 Task 1 覆盖；93→123 和基线由 Task 2 覆盖。
- 第一卷五章为 Tasks 3、5、7、9、11；第三卷三十章按依赖穿插为 Tasks 4、6、8、10、12–37，全部有独立七通道验收。
- 每个章任务均使用全局 Artifact Contract、DOC-PASS 和 `-Chapter`，没有只靠源码而不进正文的示例。
- 最终章数、245 个新增通道单元、869 全量目标、六书总表和旧接缝清理由 Task 38 覆盖。
- 不设置自动提交步骤，遵守“用户明确要求后才 commit/push”。
