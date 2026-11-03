# 概率论与统计学教程重排融合 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 `probability/` 重排为 44 章研究生向中文教程，完整融合 Miller 的概率训练与洪永淼的统计推断、经济解释和回归主线，并保持五通道可运行验证。

**Architecture:** 以 `chapters.json` 为章节唯一清单，以 `docs/NN-slug.md` 为自包含正文，以 `examples/<channel>/NN_slug.*` 为可执行单元。先记录基线和建立文档检查，再按概念依赖分篇迁移；旧稿通过基线提交读取，重编号用临时扩展名避让碰撞，最后统一检查链接、导航、代码引用和全量构建。

**Tech Stack:** Markdown、Python 3.13 + SciPy、Lean 4.33.1 + 本地 mathlib4、Isabelle2025-2、Julia、SWI-Prolog、PowerShell 7、RapidOCR（扫描页交叉取材）。

**Spec:** `docs/superpowers/specs/2026-11-02-probability-hong-restructure-design.md`

## Global Constraints

- 全部工作位于现有 `probability/`，根 `README.md` 只更新入口描述，不新增教程计数。
- 共 44 章，编号 00–43；研究生为主，不把测度论作为前置课程。
- 每章不少于 200 行，正文文字多于代码；定义、假设、证明、例题和经济解释自包含。
- 每个示例的核心代码必须在对应正文中出现并解释；读者无需打开源码才能理解。
- 不依赖联网数据；模拟固定种子，精确概率优先使用有理数或完全穷举。
- Lean 使用 `H:/Lang/lean4/mathlib4-4.33.1`，定向导入，零 error、零 warning。
- Python 使用 `G:\scoop\apps\python313\current\python.exe -I`，不依赖当前目录导入第三方文件。
- Julia／Python／Prolog 单元输出 `==== NN` 和 `END ====`；PowerShell 全量报告不得有 FAIL。
- 洪书 PDF 页 = 书页 + 16；公式与数值必须回看扫描页，OCR 文本只作检索和初稿辅助。
- 重命名冲突一律先改为 `.migrating`，不得覆盖尚未整合的旧文件；基线提交中的旧稿用于核对遗漏。
- 每批提交只暂存本批文件，提交信息末尾带 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

---

## 文件责任图

- `probability/chapters.json`：44 章编号、slug、标题的唯一清单。
- `probability/PLAN.md`：两书页码、旧章去向、批次状态、验证数和实测坑账。
- `probability/tools/check_docs.py`：章节、链接、导航、示例引用及篇幅检查。
- `probability/tools/test_check_docs.py`：文档检查器的隔离单元测试。
- `probability/docs/NN-slug.md`：唯一必需阅读材料，包含全部讲解代码。
- `probability/examples/`：五通道可执行版本，不承担独立教学责任。
- `probability/build.ps1`：沿用按章号发现单元的入口；仅在文档检查接入或通道发现变化时修改。
- `probability/README.md`：双书定位、44 章目录、运行方法与最终验证状态。
- `README.md`：根索引中的教程名称与摘要。

### Task 1: 固定基线、原书页码与章节清单

**Files:**
- Create: `probability/chapters.json`
- Modify: `probability/PLAN.md`
- Read: `probability/README.md`, `probability/build.ps1`
- Source: `G:\book\数学\概率论与数理统计\概率论与统计学-洪永淼.pdf`

**Interfaces:**
- Produces: JSON 对象 `{"chapters": [{"number": "NN", "slug": "kebab-case", "title": "..."}]}`，严格 44 项。
- Produces: `PLAN.md` 顶部的 `Baseline commit` 和 `Baseline verification`，供所有迁移任务引用。

- [ ] **Step 1: 运行迁移前全量验证**

Run:

```powershell
pwsh -NoProfile -Command '& ./probability/build.ps1 -All'
```

Expected: 所有既有单元 PASS；将实际总数、工具版本和当前提交哈希写入 `PLAN.md`。若已有失败，先记录并修复基线，不把旧失败带入重排。

- [ ] **Step 2: 写入完整章节清单**

Create `probability/chapters.json`，`chapters` 数组依次包含以下 44 行对应的对象：

```text
00 intro 经济随机系统与统计推断
01 events 随机试验、事件与 σ 代数
02 axioms 概率公理、解释与基本定律
03 conditional 条件概率、全概率与贝叶斯
04 independence 独立性、条件独立与信息
05 counting 计数原理、排列与组合
06 inclusion-exclusion 容斥与组合恒等式
07 counting-lab 计数实验：扑克、生日与著名问题
08 random-variables 随机变量、分布函数与密度
09 expectation 数学期望、矩、分位数与风险
10 transformations 一元随机变量变换
11 inequalities 概率不等式与矩的界限
12 discrete-dists 离散分布族
13 continuous-dists 连续分布族：均匀、指数、Γ 与 Beta
14 normal-stable 正态、对数正态、柯西与稳定分布
15 generating-functions 母函数、矩生成函数与特征函数
16 convolutions 卷积与微分恒等式
17 joint-distributions 联合、边际与条件分布
18 multivariate-transformations 多元变换与 Jacobian
19 covariance 协方差、相关与独立
20 conditional-expectation 条件期望与条件方差
21 multivariate-normal 二元与多元正态
22 sampling-distributions 随机样本与抽样分布
23 sufficiency 充分统计量与数据简化
24 markov-chains 随机序列与马尔可夫链
25 convergence 收敛模式及其关系
26 lln 大数定律
27 clt 中心极限定理
28 fourier-clt Fourier 分析与特征函数极限
29 asymptotic-tools 连续映射、Slutsky 与 Delta 方法
30 stirling Stirling 公式与渐近近似
31 estimation-models 参数模型、估计量与风险
32 mle 极大似然估计
33 gmm 矩估计与广义矩估计
34 efficiency 最优无偏估计与 Cramér–Rao 下界
35 asymptotic-estimation 估计量的渐近性质
36 hypothesis-testing 假设检验与 Neyman–Pearson 理论
37 asymptotic-tests Wald、LM、LR 检验与置信区间
38 ols 经典线性回归与普通最小二乘
39 ols-properties 拟合优度、模型选择与 Gauss–Markov
40 ols-inference OLS 抽样分布、t 检验与 F 检验
41 gls 线性约束、遗漏变量与广义最小二乘
42 synthesis 综合案例与概率证明方法
43 cheatsheet 全书速查与定理地图
```

JSON 示例形状固定为：

```json
{"number":"00","slug":"intro","title":"经济随机系统与统计推断"}
```

- [ ] **Step 3: 写入洪书取材页码和旧章映射**

在 `PLAN.md` 写入：

```text
ch1 书1–9 / PDF17–25；ch2 书10–48 / PDF26–64
ch3 书49–115 / PDF65–131；ch4 书116–151 / PDF132–167
ch5 书152–237 / PDF168–253；ch6 书238–280 / PDF254–296
ch7 书281–319 / PDF297–335；ch8 书320–369 / PDF336–385
ch9 书370–397 / PDF386–413；ch10 书398–448 / PDF414–464
ch11 书449–452 / PDF465–468
```

复制规格文档第 4.2 节旧章去向表，并增加每章机器文件去向。任何一对多迁移均标注“从 Baseline commit 复读旧稿”。

- [ ] **Step 4: 校验清单并提交**

Run:

```powershell
G:\scoop\apps\python313\current\python.exe -I -c "import json; p=json.load(open('probability/chapters.json',encoding='utf-8')); assert [x['number'] for x in p['chapters']]==[f'{i:02d}' for i in range(44)]; print('44 chapters OK')"
git add probability/chapters.json probability/PLAN.md
git commit -m "probability: 固定重排基线与章节清单" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: 输出 `44 chapters OK`，提交只含两个文件。

### Task 2: 用测试驱动加入文档检查器

**Files:**
- Create: `probability/tools/test_check_docs.py`
- Create: `probability/tools/check_docs.py`
- Modify: `probability/build.ps1`

**Interfaces:**
- Consumes: `chapters.json` 的 `chapters` 数组。
- Produces: CLI `python -I probability/tools/check_docs.py --root probability [--final]`；成功退出 0，问题逐行输出并退出 1。
- Produces: `build.ps1 -Docs` 开关，只运行检查器单元测试与文档检查。

- [ ] **Step 1: 写失败测试**

Create `probability/tools/test_check_docs.py`：

```python
import json
import tempfile
import unittest
from pathlib import Path

from check_docs import check


class CheckDocsTest(unittest.TestCase):
    def make_root(self):
        tmp = tempfile.TemporaryDirectory()
        root = Path(tmp.name)
        (root / "docs").mkdir()
        (root / "chapters.json").write_text(json.dumps({"chapters": [
            {"number": "00", "slug": "intro", "title": "导论"}
        ]}), encoding="utf-8")
        self.addCleanup(tmp.cleanup)
        return root

    def test_missing_chapter_fails_in_final(self):
        errors = check(self.make_root(), final=True)
        self.assertTrue(any("missing chapter" in e for e in errors))

    def test_example_requires_citation_and_code(self):
        root = self.make_root()
        (root / "docs" / "00-intro.md").write_text("x\n" * 220, encoding="utf-8")
        example = root / "examples" / "python" / "00_intro.py"
        example.parent.mkdir(parents=True)
        example.write_text("print('END ====')\n", encoding="utf-8")
        errors = check(root, final=False)
        self.assertTrue(any("uncited example" in e for e in errors))

    def test_dangling_link_fails(self):
        root = self.make_root()
        (root / "docs" / "00-intro.md").write_text(
            "[下一章](01-events.md)\n", encoding="utf-8")
        self.assertTrue(any("dangling link" in e for e in check(root)))


if __name__ == "__main__":
    unittest.main()
```

Run:

```powershell
G:\scoop\apps\python313\current\python.exe -I -m unittest discover -s probability/tools -p "test_*.py" -v
```

Expected: FAIL，错误为无法导入 `check_docs`。

- [ ] **Step 2: 实现检查器**

Create `probability/tools/check_docs.py`，实现以下确定行为：

```python
import argparse
import json
import re
import sys
from pathlib import Path

LANGS = {"julia": ".jl", "python": ".py", "prolog": ".pl"}


def check(root: Path, final: bool = False) -> list[str]:
    manifest = json.loads((root / "chapters.json").read_text(encoding="utf-8"))
    chapters = manifest["chapters"]
    errors = []
    for index, meta in enumerate(chapters):
        number, slug = meta["number"], meta["slug"]
        doc = root / "docs" / f"{number}-{slug}.md"
        if not doc.exists():
            if final:
                errors.append(f"missing chapter: {doc}")
            continue
        text = doc.read_text(encoding="utf-8")
        lines = text.splitlines()
        if final and len(lines) < 200:
            errors.append(f"short chapter: {doc} has {len(lines)} lines")
        for target in re.findall(r"\[[^]]*\]\(([^)]+)\)", text):
            if "://" in target or target.startswith("#"):
                continue
            clean = target.split("#", 1)[0]
            if clean and not (doc.parent / clean).resolve().exists():
                errors.append(f"dangling link: {doc}: {target}")
        if final and index > 0:
            prev = f"{chapters[index-1]['number']}-{chapters[index-1]['slug']}.md"
            if prev not in text:
                errors.append(f"missing previous navigation: {doc}: {prev}")
        if final and index + 1 < len(chapters):
            nxt = f"{chapters[index+1]['number']}-{chapters[index+1]['slug']}.md"
            if nxt not in text:
                errors.append(f"missing next navigation: {doc}: {nxt}")
        for lang, suffix in LANGS.items():
            folder = root / "examples" / lang
            if not folder.exists():
                continue
            expected_name = f"{number}_{slug.replace('-', '_')}{suffix}"
            for example in folder.glob(f"{number}_*{suffix}"):
                if example.name != expected_name:
                    if final:
                        errors.append(f"unexpected example name: {example}")
                    continue
                relative = example.relative_to(root).as_posix()
                if relative not in text:
                    errors.append(f"uncited example: {doc}: {relative}")
                fence = f"```{ {'julia':'julia','python':'python','prolog':'prolog'}[lang] }"
                if fence not in text:
                    errors.append(f"missing explained code block: {doc}: {lang}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--final", action="store_true")
    args = parser.parse_args()
    errors = check(args.root, args.final)
    for error in errors:
        print(error)
    print(f"docs: {'PASS' if not errors else 'FAIL'} ({len(errors)} errors)")
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())
```

Run the unittest command again. Expected: 3 tests PASS。

- [ ] **Step 3: 接入 `-Docs` 并验证开关**

在 `build.ps1` 的参数区加入 `[switch]$Docs`，在清理逻辑之后加入：

```powershell
if ($Docs) {
    & $python313 -I -m unittest discover -s (Join-Path $root 'tools') -p 'test_*.py' -v
    if ($LASTEXITCODE -ne 0) { exit 1 }
    & $python313 -I (Join-Path $root 'tools\check_docs.py') --root $root
    exit $LASTEXITCODE
}
```

Run:

```powershell
pwsh -NoProfile -Command '& ./probability/build.ps1 -Docs'
```

Expected: 单元测试 PASS；已有文档只报告真实的新规则问题。修复由旧章迁移引起的引用错误，不放宽检查器。

- [ ] **Step 4: 提交检查器**

```powershell
git add probability/tools probability/build.ps1
git commit -m "probability: 增加文档与示例引用检查" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

### Task 3: 重写导论与概率模型（00–04）

**Files:**
- Create: `probability/docs/00-intro.md`, `01-events.md`, `04-independence.md`
- Rewrite/rename: `02-axioms.md`, `05-conditional.md → 03-conditional.md`
- Migrate: 对应 Lean `Ch05Conditional → Ch03Conditional`、Isabelle `MT05 → MT03`、Julia／Python／Prolog 的 01–05 相关文件
- Source: 洪书 PDF17–64；Miller 旧 00–05 章

**Interfaces:**
- Consumes: 章节清单、Baseline commit 旧稿。
- Produces: 03 章条件概率单元的新章号与结束哨兵；05 章计数文件保留给 Task 4。

- [x] **Step 1: 处理 03／05 重编号碰撞**

将旧 `03-counting` 的文档与示例先加 `.migrating`，再把旧 `05-conditional` 移到 03，最后把暂存的 counting 文件移到 05。同步 Isabelle ROOT、Lean 模块名和全部结束哨兵。

- [x] **Step 2: 写 00 导论**

讲清描述统计／推断统计、两个经济统计公理、数据生成过程、随机系统与确定性混沌的差别、经济模型的解释边界。复算几何随机游走与 logistic 映射的零相关但不独立例子，代码与输出放入正文。

- [x] **Step 3: 写 01–02**

01 包含随机试验、样本空间、事件运算、σ 代数及“事件是可获得信息”的解释。02 包含三种概率解释、三公理及补集／单调／加法／连续性后果；证明不能只给公式。

- [x] **Step 4: 写 03–04**

03 完整推导条件概率、乘法链、全概率、Bayes，保留医学基率和 Monty Hall 穷举。04 区分两两／相互／条件独立，给出两点与四点反例，并解释“不相关”“独立”“不可预测”不是同义词。

- [x] **Step 5: 验证并提交**

Run:

```powershell
pwsh -NoProfile -Command '& ./probability/build.ps1 -Chapter 00,01,02,03,04'
pwsh -NoProfile -Command '& ./probability/build.ps1 -Docs'
```

Expected: 所有已存在单元 PASS，03 不再出现旧 05 哨兵或 MT05。提交本批文档、清单状态与示例。

### Task 4: 重写组合计数与有限实验（05–07）

**Files:**
- Rewrite: `probability/docs/05-counting.md`, `06-inclusion-exclusion.md`
- Create: `probability/docs/07-counting-lab.md`
- Migrate: 旧 01、04、06、07 及旧 25 的有限穷举内容到 05–07

**Interfaces:**
- Produces: 新 07 的扑克／生日／秘书问题单元；旧 07 不得残留为另一套组合章。

- [x] **Step 1: 写 05–06 的完整推导**

05 讲乘法／加法原理、排列与组合的 k! 去重、多项系数、Pascal 和二项定理。06 用逐点覆盖次数证明容斥，并给 Vandermonde、曲棍球棒和错排公式；旧 07 的恒等式证明全部核对后并入。

- [x] **Step 2: 写 07 计数实验**

保留九型牌型的结构化计数、生日 22／23 阈值、桥牌分布、秘书问题有限 n 修正和至少一个著名反例。每个手算闭式必须由精确穷举或模拟审计，正文展示核心循环与概率账。

- [x] **Step 3: 迁移并验证**

Run:

```powershell
pwsh -NoProfile -Command '& ./probability/build.ps1 -Chapter 05,06,07'
pwsh -NoProfile -Command '& ./probability/build.ps1 -Docs'
```

Expected: PASS；迷你扑克 1140 手、C(52,5)=2598960、生日阈值和秘书 n=4 的 11/24 均有验证。提交本批。

### Task 5: 重写一元随机变量基础（08–11）

**Files:**
- Create/rewrite: `probability/docs/08-random-variables.md`, `09-expectation.md`, `10-transformations.md`, `11-inequalities.md`
- Migrate: 旧 08–11、18 的相关示例

**Interfaces:**
- Produces: 08–11 新 slug 示例；09 不再表示连续随机变量，11 不再表示卷积。

- [x] **Step 1: 用 `.migrating` 完成 08–11 重排**

旧 08／09 合并为 08，旧 10 移入 09，旧 09／11 的变换内容移入 10，旧 18 的不等式内容复制到 11。先暂存冲突文件，再落新章号，更新所有代码标题与哨兵。

- [x] **Step 2: 写 08–09**

08 统一 pmf、pdf、CDF，证明 CDF 四性质，解释单点零概率与混合型。09 讲可积性、期望、矩、方差、分位数和期望效用；Cauchy 均值不存在、E[1/X] 与组合风险例子必须给出完整条件。

- [x] **Step 3: 写 10–11**

10 用 CDF 法推出单调与非单调变换公式，包含绝对 Jacobian、逆变换采样和多支反函数。11 证明 Markov、Chebyshev、Jensen、并界，比较界的紧度，说明 Chebyshev 如何通向大数定律。

- [x] **Step 4: 验证并提交**

Run `build.ps1 -Chapter 08,09,10,11` 与 `build.ps1 -Docs`。Expected: PASS；两骰 8/36、抛物线矩账、X² 密度、Markov 紧度反例均有正文代码与结果。

### Task 6: 重写分布族与变换工具（12–16）

**Files:**
- Create/rewrite: `probability/docs/12-discrete-dists.md` 至 `16-convolutions.md`
- Migrate: 旧 12–16、20 及卷积相关单元
- Source: 洪书 PDF97–167；Miller 旧 11–16、20 章

- [x] **Step 1: 写 12–14 分布地图**

12 完整覆盖 Bernoulli、二项、几何、负二项、Poisson，推导 pmf、矩与 Poisson 极限。13 覆盖均匀、指数、Weibull、Γ、广义 Γ、Beta、Laplace，说明参数化和无记忆性。14 覆盖正态、对数正态、Cauchy 与稳定分布，区分厚尾、均值不存在和正态稳定性。

- [x] **Step 2: 写 15–16 工具章**

15 并排讲 PGF／MGF／CF 的定义、存在域、矩提取、唯一性和独立和；Cauchy 无 MGF 但 CF 存在的对照不可省略。16 证明卷积公式与分组思想，展示参数求导提取阶乘矩和正态偶矩，注明积分／求导交换条件。

- [x] **Step 3: 校验数值与公式**

保留 Γ／Beta 归一化、正态标准化、Poisson 独立和、Fibonacci 生成函数、四骰卷积与微分恒等式。对重尾积分采用闭式配平或变量代换，不用大区间朴素 Simpson 冒充验证。

- [x] **Step 4: 验证并提交**

Run `build.ps1 -Chapter 12,13,14,15,16`、`build.ps1 -Docs` 和一次 `build.ps1 -All`。Expected: 本章及回归单元全部 PASS，记录实际单元总数。

实际结果：`-Chapter 12,13,14,15,16` 中本批非 Lean 20/20 PASS、Lean 5 个目标均通过；`-Docs` PASS（0 errors）；隔离未跟踪的后续 Task 7/8 示例后，`-All` 为 92/92 PASS，随后已原样恢复 37 个隔离文件。

### Task 7: 新建多元随机结构主线（17–21）

**Files:**
- Create: `probability/docs/17-joint-distributions.md` 至 `21-multivariate-normal.md`
- Create: 对应 Julia、Python；为条件期望和多元正态增加 Lean 或 Isabelle 锚
- Source: 洪书 PDF168–253；Miller 旧 10–11、15 章

- [x] **Step 1: 写 17–18**

17 从联合分布出发定义边际与条件分布，分别处理离散、连续和混合情形，证明归一化。18 推导多元 Jacobian，完整计算和、积、商变换，说明多对一变换分区求和及坐标选择。

- [x] **Step 2: 写 19–20**

19 推导协方差矩阵、方差和、相关系数界，给不相关不独立反例与投资组合公式。20 将条件期望定义为条件的函数，证明全期望、全方差和 L² 最优预测，解释条件期望随信息变化而非固定常数。

- [x] **Step 3: 写 21 多元正态**

给出密度、均值向量、协方差矩阵、线性变换和边际分布；推导二元正态条件均值／方差，证明联合正态下零相关等价独立，并用非联合正态反例限定结论。

- [x] **Step 4: 验证并提交**

机器锚至少包括：二维有限联合表边际化、Jacobian 行列式、条件期望塔性质、二元正态条件公式、两个非联合正态反例。Run `build.ps1 -Chapter 17,18,19,20,21` 与 `-Docs`，全部 PASS 后提交。

实际结果：`-Docs` PASS（0 errors）；目标章 Julia 9/9、Python 9/9、Prolog 5/5 PASS（含旧同号章回归）；隔离 4 个未跟踪 Task 8 Lean 文件后，整工程 Lean 构建 PASS（目标报告 8/8，lake build 260.9s），随后已原样恢复；五个新 Lean 模块均已纳入根导入。

### Task 8: 建立精确抽样理论与充分性（22–23）

**Files:**
- Create/rewrite: `probability/docs/22-sampling-distributions.md`, `23-sufficiency.md`
- Migrate: 旧 17 χ² 与旧 23 的双样本分布内容
- Source: 洪书 PDF254–296

- [x] **Step 1: 写 22 抽样分布**

定义总体、随机样本、统计量；推导正态样本均值分布、样本方差 χ² 分布及两者独立性。用正交变换说明自由度，再由 Z／√(χ²ν/ν) 与 χ² 比定义 t、F，给双样本场景。

- [x] **Step 2: 写 23 充分统计量**

解释数据简化的目标，证明并使用 Neyman–Fisher 因子分解；完成 Bernoulli、Poisson、正态模型例子。补充最小充分、完备性及 Rao–Blackwell 的接口，为 34 章 UMVU 做准备。

- [x] **Step 3: 验证并提交**

至少验证 (n−1)s²/σ² 的 χ² 模拟、t 与 F 的关系、自由度加权合并方差、Bernoulli 充分统计量的条件分布不依赖 p。Run `build.ps1 -Chapter 22,23`、`-Docs`，PASS 后提交。

实际结果：`-Docs` PASS（0 errors）；目标章 Julia 4/4、Python 4/4、Prolog 2/2 PASS（含旧同号章回归）；隔离 2 个未跟踪未来 Lean 文件后，整工程 Lean 构建 PASS（目标报告 2/2，lake build 655.0s），随后已原样恢复；两个新 Lean 模块均已纳入根导入。首次整工程验证曾因系统内存不足被后台任务回收器终止，不计为代码失败；重试成功。

### Task 9: 重排随机序列、收敛与大数定律（24–26）

**Files:**
- Create/rewrite: `probability/docs/24-markov-chains.md`, `25-convergence.md`, `26-lln.md`
- Migrate: 旧 24 的 Markov 部分、旧 18 的收敛与 LLN 部分
- Source: 洪书 PDF297–319；Miller 旧 18、24 章

- [x] **Step 1: 写 24 Markov 链**

保留差分方程、转移矩阵、平稳分布、首次到达与 Leslie 矩阵例子；区分 Markov 链长期行为与后续 iid 极限定理，不混用平稳性和依分布收敛。

- [x] **Step 2: 写 25 四种收敛**

定义 Lp／均方、依概率、几乎处处、依分布收敛，画清蕴含方向，并用移动区间、独立序列和常数目标反例否定逆向。说明依分布收敛对 CDF 连续点的要求。

- [x] **Step 3: 写 26 大数定律**

从 Chebyshev 证明 WLLN，陈述并比较 Khinchin 与 Kolmogorov SLLN 的条件；用固定路径和重复试验分别解释两种收敛。给 Monte Carlo 误差 1/√n 的解释，不宣称模拟证明 SLLN。

- [x] **Step 4: 验证并提交**

验证移动区间反例、四种收敛的有限样本指标、WLLN 偏差与 SLLN 路径、Cauchy 均值不收敛。Run `build.ps1 -Chapter 24,25,26`、`-Docs` 和 `-All`，PASS 后提交。

实际结果：`-Docs` PASS（0 errors）；目标章 Lean 3/3、Julia 6/6、Python 6/6、Prolog 4/4 PASS（含旧同号章回归）；`-All` 129/129 PASS，其中 Lean 整工程增量构建 PASS（2.8s），五个 Isabelle 会话及全部 Julia/Python/Prolog 单元全绿。修复了 Ch24 的 `pn` 基例展开与有限量化 `decide` 归约问题，以及 Ch25 的多余 `field_simp`；修复后 Ch24/Ch25 单文件及整工程均通过。

### Task 10: 完成渐近工具链（27–30）

**Files:**
- Rewrite/create: `probability/docs/27-clt.md`, `28-fourier-clt.md`, `29-asymptotic-tools.md`, `30-stirling.md`
- Migrate: 旧 19、21、22 章及示例
- Source: 洪书 PDF297–335；Miller 旧 18–22 章

- [x] **Step 1: 写 27–28**

27 用特征函数完成 iid 有限方差 CLT 的证明，解释 Taylor 二阶项、标准化与极限乘积；给连续性修正和格点近似误差。28 讲 Fourier 核、反演、唯一性、卷积乘法、Gaussian 自反与 Cauchy 稳定性，并说明特征函数极限如何给出依分布收敛。

- [x] **Step 2: 写 29 渐近拼接工具**

定义 Op／op，证明连续映射与 Slutsky，给 Delta 方法及渐近方差公式；至少计算样本均值函数、方差稳定化变换和估计量标准化三个例子，指出 Delta 方法在导数为零处失效。

- [x] **Step 3: 写 30 Stirling 与近似**

推导 Stirling 主项并解释修正项，计算中心二项系数渐近；保留平票概率和有限尺寸效应，明确 n 小时的近似误差。

- [x] **Step 4: 验证并提交**

验证 CF 极限、格点桶效应、Delta 方差、Stirling 误差幂律。Run `build.ps1 -Chapter 27,28,29,30`、`-Docs`，PASS 后提交。

实际结果：目标章 11/11 PASS（Lean 27/29、Isabelle MT27、Julia 27–30、Python 27–30），`-Docs` PASS（0 errors）。旧示例已映射为 27/28/30，新 29 增加 Delta 与二阶退化单元。修复 Lean 的多余 `ring` 与泛化 `simp` 副作用；数值断言按 Poisson `O(λ^-1/2)`、中心二项 `1/(8n)` 修正和有限样本偏态校准。Stirling 使用严格积分夹逼 `e(n/e)^n ≤ n! ≤ en(n/e)^n`，并以梯形误差和 Wallis 公式确定完整常数。

### Task 11: 建立统计模型与极大似然（31–32）

**Files:**
- Create: `probability/docs/31-estimation-models.md`, `32-mle.md`
- Create: Julia、Python 估计与优化单元；选择有限模型增加 Lean／Prolog 精确锚
- Source: 洪书 PDF336–353

- [x] **Step 1: 写 31 统计模型与风险**

区分总体、参数空间、参数、估计量和估计值；定义识别、损失、偏差、方差、风险和 MSE，推导偏差—方差分解。给模型误设与抽样波动的不同来源，避免把无偏等同于最优。

- [x] **Step 2: 写 32 MLE**

从联合密度构造似然和对数似然，定义得分与 Fisher 信息；完整计算 Bernoulli、Poisson、正态例子，证明参数变换不变性。说明边界、多峰、不可识别和数值优化失败，正文给出固定数据的一次 Newton／网格优化。

- [x] **Step 3: 验证并提交**

验证 Bernoulli MLE=x̄、正态 MLE、得分在真参数处零均值、信息等式及不变性；模拟只用于抽样性质。Run `build.ps1 -Chapter 31,32`、`-Docs`，PASS 后提交。

实际结果：目标章 6/6 PASS（Lean 31/32、Julia 31/32、Python 31/32），`-Docs` PASS（0 errors）。第 31 章以 `cS²` 的完全平方风险差证明正态方差最优缩放，并用固定种子审计有限样本风险；第 32 章用精确有理数核对得分与信息、固定数据 Newton 历史、正态/Poisson MLE，并在 Lean 中证明双射重参数化的不变性。正文明确边界、无界似然、多峰、不可识别和误设下信息等式的限制。

### Task 12: 完成 GMM、有效性与渐近估计（33–35）

**Files:**
- Create: `probability/docs/33-gmm.md`, `34-efficiency.md`, `35-asymptotic-estimation.md`
- Create: GMM／信息不等式／sandwich 的 Julia、Python 单元与至少一个形式化代数锚
- Source: 洪书 PDF353–385

- [x] **Step 1: 写 33 矩估计与 GMM**

由总体矩条件推导样本矩估计，区分恰好识别与过度识别；定义 GMM 目标函数，推导一步、两步和最优权重，解释权重矩阵维数及奇异矩阵处理。给线性矩条件的完整数值例子。

- [x] **Step 2: 写 34 UMVU 与信息下界**

证明 Rao–Blackwell 改进方向，说明完备充分统计量如何给出 UMVU；在正则条件下推导 Cramér–Rao 下界，明确得分与参数求导交换的关键一步，并用 Bernoulli／正态例计算有效性。

- [x] **Step 3: 写 35 渐近性质**

定义一致性、渐近正态和渐近有效性；用“得分均值 + 导数项 + 余项”推导 MLE 渐近分布，用矩条件展开推导 GMM sandwich 方差。解释模型误设时伪真值和稳健方差，不把正确模型下的信息矩阵等式机械套用。

- [x] **Step 4: 验证并提交**

验证偏差—方差账、CR 下界等号条件、最优 GMM 权重、J 统计量自由度、MLE／GMM 渐近方差矩阵。Run `build.ps1 -Chapter 33,34,35`、`-Docs` 和 `-All`，PASS 后提交。

实际结果：目标章 9/9 PASS（Lean/Julia/Python 各 3 章），`-Docs` PASS（0 errors），全量 `-All` 147/147 PASS、FAIL 0。第 33 章用线性两矩一例精确核对一步、两步和最优 GMM，Lean 证明逆方差权重的完全平方最优性；第 34 章精确枚举 Rao–Blackwell 改进与 Bernoulli CR 等号，并区分正态方差“未达到下界”与“仍是 UMVU”；第 35 章推导 MLE/GMM sandwich，固定种子模拟显示误设正态标准误覆盖率约 0.67、稳健覆盖率约 0.94。精确代数检查纠正了 Poisson 伪似然方差中重复除以 λ² 的初稿错误：最终 \(\sqrt n\) 渐近方差为真实 Var(X)。

### Task 13: 重建假设检验与置信推断（36–37）

**Files:**
- Rewrite/create: `probability/docs/36-hypothesis-testing.md`, `37-asymptotic-tests.md`
- Migrate: 旧 23 的 z／t／χ²／双样本／功效代码
- Source: 洪书 PDF386–413；Miller 旧 23 章

- [x] **Step 1: 写 36 检验基本理论**

定义简单／复合假设、拒绝域、两类错误、size、power、p 值；证明 Neyman–Pearson 引理并计算 Bernoulli 和正态例。解释 UMP、单侧／双侧、统计显著与实际显著，以及“不拒绝不等于接受”。

- [x] **Step 2: 写 37 三大渐近检验与区间**

从同一参数约束分别构造 Wald、LM、LR，说明三者的渐近 χ² 分布、自由度和有限样本差异；证明检验—置信集对偶并计算正态均值区间。保留多重比较警告和功效曲线。

- [x] **Step 3: 验证并提交**

验证 NP 临界似然比、第一类错误率、功效、三大统计量数值、置信区间覆盖率与 p 值方向。Run `build.ps1 -Chapter 36,37`、`-Docs`，PASS 后提交。

实际结果：目标章 6/6 PASS（Lean/Julia/Python 各 2 章），`-Docs` PASS（0 errors）。第 36 章以五点 Bernoulli 完全枚举证明并核对 NP 拒绝域，size/功效为 1/64 与 81/128，随机化后为 17/512 与 351/512；正态右侧 UMP 在 mu=12 的功效为 0.638760，固定种子审计与理论一致。第 37 章精确对照 Bernoulli 的 W=5/6、LM=4/5、LR=0.805420542，证明检验—置信集对偶，z/t 区间模拟覆盖率均约 0.95。机器检查纠正了 K=4 概率漏乘一次失败概率 3/4 的初稿错误；Lean 另修复临界等号分支的 0≤0 收尾、field_simp 后多余 ring 和未使用假设警告。

### Task 14: 建立 OLS 几何与有限样本性质（38–39）

**Files:**
- Create: `probability/docs/38-ols.md`, `39-ols-properties.md`
- Migrate: 旧 24 最小二乘代码到 38，新增矩阵与 Monte Carlo 单元
- Source: 洪书 PDF414–440

- [x] **Step 1: 写 38 OLS**

逐条说明经典线性模型假设，区分随机生成假设与代数计算；由投影几何和正规方程两条路线推导 β̂，定义 P、M、拟合值与残差，证明 X′e=0、P+M=I、幂等和对称性。

- [x] **Step 2: 写 39 拟合与 Gauss–Markov**

推导 TSS／ESS／RSS 与 R² 的成立条件，解释调整 R² 和模型选择；证明 OLS 无偏、协方差矩阵 σ²(X′X)⁻¹ 和 Gauss–Markov，指出无偏依赖外生性而投影恒等式不依赖。

- [x] **Step 3: 验证并提交**

用固定小矩阵手算 β̂、e、P、M，再由 SciPy／Julia 对拍；验证扰动使 X′e=0 但无偏性失效的例子。Run `build.ps1 -Chapter 38,39`、`-Docs`，PASS 后提交。

实际结果：目标章 6/6 PASS（Lean/Julia/Python 各 2 章），`-Docs` PASS（0 errors）。三点固定例全程精确分数：β̂=(5/6,3/2)、e=(1/6,-1/3,1/6)、e'e=1/6、P=(1/6)[[5,2,-1],[2,2,2],[-1,2,5]]、tr P=2、TSS=14/3=ESS 9/2+RSS 1/6、R²=27/28、调整 R²=13/14、s²=1/6。Gauss–Markov 完整证明加对照估计（OLS 斜率方差 σ²/2 对 y₂-y₁ 的 2σ²，MC 0.499 vs 2.008）；内生性例 plim=2.5 的 MC 均值 2.499 且逐样本 X'e=0 成立。机器纠正三处：E2/E3 对照数据的残差须偏斜（对称数据两度量截距重合）；Julia 顶层循环赋值须封装函数；Lean 矩阵断言 kernel decide 对 Rat 链式求和停滞，改 native_decide（10s 全绿），另修 `•` 整数矩阵类型不合、正规方程括号（`*ᵥ` 结合力高于 `*`）与 mathlib 4.33 `dotProduct` 移出 Matrix 命名空间。

### Task 15: 完成 OLS 推断、约束与 GLS（40–41）

**Files:**
- Create: `probability/docs/40-ols-inference.md`, `41-gls.md`
- Create: t／F、受约束回归和 GLS 的 Julia、Python 单元
- Source: 洪书 PDF430–464

- [x] **Step 1: 写 40 正态回归精确推断**

在正态误差下推导 β̂ 与 s² 的分布及独立性，构造单个系数 t 检验、置信区间和一般线性约束 F 检验；解释 F 与多个 t 的区别，给联合显著性和参数约束例。

- [x] **Step 2: 写 41 误设与 GLS**

推导受约束 OLS、遗漏变量偏误和加入无关变量的代价；由 Cov(ε)=σ²Ω 给出 GLS／Aitken 估计和协方差，解释 Ω=diag(wᵢ) 时的 WLS 变换，比较 OLS 与 GLS 的目标和假设。

- [x] **Step 3: 验证并提交**

验证 t／F 的单约束等价、联合 F、受约束残差、遗漏变量偏误方向、GLS 加权估计及模拟覆盖率。Run `build.ps1 -Chapter 40,41`、`-Docs` 和 `-All`，PASS 后提交。

实际结果：目标章 6/6 PASS，`-Docs` PASS（0 errors），全量 `-All` 165/165 PASS、FAIL 0。第 40 章推导正态下 β̂/s² 分布与独立性（P、M 正交 + 正态零协方差⇒独立），五点例 t₁²=49/18、t₂²=16/3、临界值 10.128=3.1824²、β₂ 区间 (-0.3024,1.9024)、t 区间覆盖率 MC 0.95075；联合 F=16/3=k=2 退化单约束。第 41 章受约束闭式 β̃=(1,1)、RSS_R-RSS_U 二次型恒等式=2/5、F=1/3；遗漏偏误 (-2/5,1) MC 短模型均值 (0.5955,2.0005)；方差膨胀 28/3；GLS=(364/269,199/269)、Aitken 方差 56/269<1/4（MC 0.2477/0.2071）。机器纠正四笔手算错：F(1,ν) 临界对应双侧 t 分位（非单侧 0.95）、k=2 联合 F=16/3 非 8/3、GLS 加权和 S_wx=19/4 与 S_wxy=59/4（两次滑数由精确断言抓出）；联合显著/单个不显著演示改为固定数据集（t=-0.502/1.356 双不显著、F=4.621>3.16）避免随机运气。

### Task 16: 综合收官、全量文档审计与五通道验收

**Files:**
- Rewrite/create: `probability/docs/42-synthesis.md`, `43-cheatsheet.md`
- Modify: `probability/README.md`, `probability/PLAN.md`, `README.md`
- Migrate: 旧 25、26、27 的内容与机器单元
- Verify: `probability/docs/`, `probability/examples/`, `probability/build.ps1`

- [x] **Step 1: 写 42 综合案例与证明方法**

用一个完整合成经济数据贯穿 DGP、抽样、MLE／GMM、检验和 OLS／GLS，公开全部生成参数和代码。将旧证明十一式及著名问题归入对应证明策略，强调反例、归纳、变换、生成函数、渐近展开和机器审计各自能证明什么。

- [x] **Step 2: 写 43 速查与定理地图**

按“模型假设 → 定理 → 可用结论 → 常见误用”整理全书法则；列出主要分布、矩、抽样分布、收敛关系、估计和检验公式、OLS 矩阵恒等式。验证索引只登记实际通过的单元。

- [x] **Step 3: 更新入口并清除旧编号残留**

将 `probability/README.md` 改为双书为纲的 44 章目录，根 `README.md` 摘要改为“概率模型、渐近推断、GMM 与经典回归”。搜索旧标题、旧 Isabelle 会话、旧示例名和 `.migrating`；每项残留必须改为新引用或说明其保留理由。

- [x] **Step 4: 执行最终文档检查**

Run:

```powershell
G:\scoop\apps\python313\current\python.exe -I probability/tools/check_docs.py --root probability --final
pwsh -NoProfile -Command '& ./probability/build.ps1 -Docs'
```

Expected: `docs: PASS (0 errors)`。另外逐章人工核对：每个示例的核心代码确已出现在正文，证明链未指向原书，文字多于代码；自动检查不能替代这一项。

- [x] **Step 5: 执行全量五通道验证**

Run:

```powershell
pwsh -NoProfile -Command '& ./probability/build.ps1 -All'
pwsh -NoProfile -Command '& ./probability/build.ps1 -List'
```

Expected: 全量 PASS、FAIL 0；矩阵覆盖所有应有单元，无空章误判。把实际 PASS 数、工具版本和检查命令写入 README／PLAN／43 章。

- [x] **Step 6: 检查差异并提交收官**

Run:

```powershell
git diff --check
git status --short
git add probability README.md
git commit -m "probability: 完成洪永淼主线融合与44章重排" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

Expected: 工作区只剩用户明确保留的无关改动；最终提交包含 44 章、五通道、清单、检查器和双索引。

实际结果：42 章以公开 DGP 的合成劳动力市场贯通全程（plim 短回归 1/5、IV 1/10、长回归无偏，MC 4000 次对账 0.2000/0.0992/0.1001；MSE 偏误主导 0.0101 vs 2.5e-4；WLS 方差 3.0e-5→2.6e-5），证明方法六族地图与名题复训收编旧 25/26；43 章速查含假设→定理→结论→误用总表、公式六表、坑账 20 条与验证状态。残留清理：5 篇旧 docs、22 个旧示例删除，Lean 三件按迁移映射改名（17→22、18→26、26→42）。收官验证：`check_docs.py --final` 首跑 0 errors；`-All` 145/145 PASS（Lean 39 模块/Isabelle 5/Julia 41/Python 43/Prolog 17）；`-List` 矩阵覆盖 00–42 章位（43 为纯文档章）。机器纠正两笔：MSE 误用 `.var()`（围绕均值而非真值，偏误被悄悄扣掉）；样本均值等式的容差须按 σ/√n 放宽（单样本 ε̄ ≠ 0）。提交 `92d01dd8`。
