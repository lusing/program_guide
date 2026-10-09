# mathlogic 第七轮扩充实施计划：Müller-Stach 八新章（73→80）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 Müller-Stach《The Code of Mathematics: Proof and Truth》完成第七轮扩充：八新章块内生长（73→80）+12 章指向微调+收官五文件对账。

**Architecture:** 沿用六轮既定节奏：批次〇全书重排（renumber 脚本新映射）→四批次新章（每章 C/L 双通道机器件+docs 教程正文）→收官对账。机器件纪律=有限影子/表格对账/可判定小宇宙/组合子恒等式，零公理或显式记账。

**Tech Stack:** Coq (Rocq 9.1 coqc -q)、Lean 4.25 裸 core（native_decide 允许）、Prolog SWI 10（71 章一件）、build.ps1 (-All/-Chapter)。

**Spec:** docs/superpowers/specs/2026-10-09-mathlogic-proof-truth-expansion-design.md（章位映射/每章内容与机器件清单/批次表全部以 spec 为准）

## Global Constraints

- 教程三铁律：正文引用全部讲解代码；对书内容自包含讲清；无篇幅限制。
- 每章 docs ≥240 行、文字多于代码；页脚由脚本重排后手工确认。
- Coq 零公理纪律（Print Assumptions = Closed 于旗舰件）；Lean 无 mathlib。
- Prolog：首行 :- encoding(utf8)、stdout 纯 ASCII、末行 `==== ... END ====`。
- 验收：每章 `-Chapter NN` 三（或两）通道全 OK；收官 `-All` 全绿。
- commit 归属：每批次一个 commit，消息含批次号与章目。

---

### Task 1: 批次〇——全书重排 73→80

**Files:**
- Modify: `tools/renumber_k.py`（新 MAP/GAPS/NEW_TITLES/expect 80/docs 改名/表行模式/文件先于目录改名）
- Rename: 30 个 `examples/NN_*` 目录、30 个 `docs/NN-*.md`、其内 `exNN_*.v/.lean/.pl/...`
- Rewrite: 全部交叉引用文本（docs/*.md、README/PLAN/CHEATSheet、examples/ROOT、examples/**/*.v|.lean|.pl|.thy|.agda|.sml）

**Interfaces:**
- Produces: 空位 43/44/47/48/49/71/79（新建章用）；旧 73 收官→80 位（内容待 Task 9 改写）

- [ ] **Step 1:** 更新 `tools/renumber_k.py`：
  MAP = {43:45,44:46, 45:50,46:51,47:52,48:53, 49:54,50:55,51:56,52:57,53:58,54:59, 55:60,56:61,57:62,58:63,59:64,60:65,61:66,62:67, 63:68,64:69,65:70, 66:72,67:73,68:74,69:75,70:76,71:77,72:78, 73:80}
  GAPS = {43,44,47,48,49,71,79}
  NEW_TITLES 七项（complexity/wordproblem/goedel2/truth/constructive/crypto/identity，标题照 spec 三节）
  expect = set(range(1,81)) - GAPS
  新增 docs/*.md 改名函数（与 examples 目录改名同款两阶段防碰撞）
  新增表行模式 `(?m)^\| (\d{2}) \|`
  **改名顺序改为 rename_files → rename_dirs**（上轮双重改名 bug 的根治：文件在旧号目录内时用旧号查 MAP）
- [ ] **Step 2:** dry-run 检查输出（目录/文件改名清单与映射表一致、替换统计合理）
- [ ] **Step 3:** `python -I tools/renumber_k.py --apply`；git status 核对改名清单（30 目录+30 docs）
- [ ] **Step 4:** `pwsh -NoProfile -Command '& ./build.ps1 -All'` —— 193 单元全绿（纯重排不改语义）
- [ ] **Step 5:** 提交批次〇

### Task 2: 批次一——新 43 章 复杂度：P 与 NP

**Files:**
- Create: `examples/43_complexity/ex43_complexity.v` / `.lean`、`docs/43-complexity.md`

**Interfaces:**
- Produces（Coq/Lean 同名镜像）:
  - `cnfSat : list (list (nat * bool)) -> list bool -> bool`——CNF 求值（赋值=按变元号取位）
  - `satVerify`（证书验证步数账）/`satBruteSteps`（蛮力 2^n 步数账）双账本
  - `sat3Of : list (list (nat*bool)) -> list (list (nat*bool))`——SAT→3SAT 链式填充组合子
  - 保满足双向表：小 CNF 宇宙全枚举 `sat F = sat (sat3Of F)`
  - `cliqueOfSat3`：3SAT→图（子句×文字 3 团图）+`hasClique`+witnessing 对账（团→赋值→CNF 真）
  - `redTrans`：归约复合传递小样本

- [ ] Step 1: 写 `.v`（CNF AST 求值+归约组合子+全枚举账 Example rfl/零公理）→ coqc 过
- [ ] Step 2: 写 `.lean`（同款，native_decide 允许）→ lean 过
- [ ] Step 3: `-Chapter 43` 两通道 OK
- [ ] Step 4: 写 `docs/43-complexity.md`（≥240 行：P 的位代价口径/NP=可验证/归约与 NP 完全/Cook–Levin/千禧问题与 71 章埋线/Grzegorczyk 与 51 章 Hardy 亲缘；代码全引用）
- [ ] Step 5: 提交批次一（43+44 合一 commit）

### Task 3: 批次一——新 44 章 字问题与重写

**Files:**
- Create: `examples/44_wordproblem/ex44_wordproblem.v` / `.lean`、`docs/44-wordproblem.md`

**Interfaces:**
- Produces:
  - `RS : list (word * word)`——Tseytin 九关系（word=list nat，字母 0..4=a..e）
  - `rew1 : RS -> word -> list word`——一步双向重写（位置×规则全枚举）
  - `rewStar : nat -> RS -> word -> list word`——深度界 BFS 闭包
  - 样本账：`cdca→cdcae` 一趟、`ce→eca` 两趟、等式链 Example
  - `aaaProbe`：典型起始词深度 d 内 `aaa ∉ 闭包` 的搜索账
  - `conflShadow`：两路径汇合小样本

- [ ] Step 1-4: 同 Task 2 节奏（.v → .lean → 验证 → docs：Thue 1910/呈示与字问题/Tseytin 半群书原例/与 53 章 PCP 表亲/hypercomputing 收尾）
- [ ] Step 5: 并入批次一 commit

### Task 4: 批次二——新 47 章 Gödel 第二不完备与一致性扩张

**Files:**
- Create: `examples/47_goedel2/ex47_goedel2.v` / `.lean`、`docs/47-goedel2.md`

**Interfaces:**
- Produces:
  - `bachEncode : list nat -> nat`（素数幂：字母编号 1..8 作第 i 个素数指数；BACH↦8647201500）
  - `bachDecode`（唯一分解回环）+ `roundtrip` Example
  - `provU`——程序表宇宙可证性谓词影子（句子索引集上的证明搜索）
  - `conLadder`——S→S+Con(S)→S″ 三级扩张的 Gödel 句逐层逃逸账
  - `d1Shadow`——D1 机制账（φ⊢ψ ⟹ Prov(⌜φ⌝)→Prov(⌜ψ⌝) 表宇宙成立）

- [ ] Step 1-4: 同节奏（docs：Con 的定义与 Gödel I 重读/von Neumann 信史/Hilbert–Bernays/Gödel–Lucas–Penrose 全文档线/BACH 编码与 45 章平方配对对照）
- [ ] Step 5: 提交批次二（47+48 合一）

### Task 5: 批次二——新 48 章 真理理论

**Files:**
- Create: `examples/48_truth/ex48_truth.v` / `.lean`、`docs/48-truth.md`

**Interfaces:**
- Produces:
  - `tschemaChain`——小句子宇宙 T(⌜φ⌝)↔φ 全枚举对账
  - `tarskiShadow`——真集 vs 每个可定义谓词 extension 全枚举，验证 idx f 处分歧（语义侧对角）
  - `t3`（T/F/U 三值归纳类型）+`k3eval`——强 Kleene 求值器
  - `kripkeFix`——自指句子集不动点迭代收敛全表（说谎者恒 U、「本句真」双固定点）
  - `grounded`——接地性检查（最小不动点成员）

- [ ] Step 1-4: 同节奏（docs：真理概念史/Tarski 1933 分层与 T-模式/不可定义性定理证明骨架/Kripke 1975 语言塔/Hösle 自驳/Weyl 不变性/与 14 章直觉主义 Kripke 同姓两物辨析）
- [ ] Step 5: 并入批次二 commit

### Task 6: 批次三——新 49 章 构造性与 Heyting 语义

**Files:**
- Create: `examples/49_constructive/ex49_constructive.v` / `.lean`、`docs/49-constructive.md`
- Modify: `docs/12-glivenko.md`（章末两行指向）

**Interfaces:**
- Produces:
  - `nnFol`——Gödel–Gentzen 双否定 FOL 翻译器（七行规则，含 ∃/∀）
  - Coq 直觉语境样本：翻译后公式 Goal 用无 Classic tactic 证（Print Assumptions = Closed）
  - `heytingOpen`——4 点 Sierpinski 型空间开集格（bitmask）：¬¬U≠U 样本+`¬A∨B ≤ (A⇒B)` 全枚举
  - `boolVsHeyting`——同一格两种结构真值对照表
  - `fourSquares`——n≤100 搜索器+恒等式 ring/反射验证

- [ ] Step 1-4: 同节奏（docs：直觉主义抵抗/双否定翻译与 DPA=HA 一致/Heyting 代数不等式化/开集语义/Brouwer 连续性与 χ_Q/Hilbert 1899 信/四平方构造面）
- [ ] Step 5: 提交批次三（49+71 合一）

### Task 7: 批次三——新 71 章 密码与信任机器

**Files:**
- Create: `examples/71_crypto/ex71_crypto.v` / `.lean` / `.pl`、`docs/71-crypto.md`

**Interfaces:**
- Produces:
  - `powmod`——平方-乘快速模幂
  - `rsaFlow`——p=11,q=13,n=143,φ=120,e=7,d=103 全流程消息表对账
  - `fermatEuler`——费马/欧拉定理小素数实例枚举账（一般陈述文档线）
  - `shamir3`——三趟协议四步状态机（显式逆元数值）
  - `hashChain`——toy 哈希链+整链验证+篡改级联检测
  - `entangleCone`——2-qubit 四元整数小宇宙锥方程检查器
  - `perceptron`——AND/OR 整数权重+XOR 四点枚举反例
  - `dlpEnum`（P）——小群离散对数枚举表

- [ ] Step 1-5: 同节奏（docs：Hardy 讽刺剧/RSA 机制/AKS 与 Miller–Rabin/Shamir 三趟/区块链与 PoW/量子纠缠锥与 Shor/感知器与不可判定/TDA barcode 文档线）
- [ ] Step 6: 并入批次三 commit

### Task 8: 批次四——新 79 章 同一性与结构主义

**Files:**
- Create: `examples/79_identity/ex79_identity.v` / `.lean`、`docs/79-identity.md`

**Interfaces:**
- Produces:
  - `leibEq`——Leibniz 等词（∀P. P a→P b）与内建 eq 等价（零公理 iff）
  - `humeCard`——{0,1,2} 全集子集按双射分块=基数等价类全表+Caesar 现场注
  - `natThree`——von Neumann/Zermelo/Dedekind 三编码 0..3 保后继双射对账
  - `fermatGcd`——F₅=641·6700417 因子账+两两 gcd=1+`F_m=F₀…F_{m−1}+2` ring 验证
  - `zQuot`——(a,b)~(c,d)⟺a+d=b+c 商构造的负数算术对账
  - `dualNum`——对偶数 (a,b)·(c,d)=(ac,ad+bc) 与 Leibniz 法则账

- [ ] Step 1-5: 同节奏（docs：两种等式/Leibniz 两原理拉丁原文/外延性缺陷/Frege 数概念全套与 Caesar 问题/Russell 信/Benacerraf/同构即同一/三化身/附加法两步/univalence 桥指向类型论指南）
- [ ] Step 6: 提交批次四（79+80+五文件）

### Task 9: 批次四——80 收官改写+五文件对账

**Files:**
- Rewrite: `docs/80-wrapup.md`（原 73 收官内容：频谱图 stale 编号清零+七轮书表+九章逐节对账+Lingua Universalis 时间线+三基础互译圆环+总坑位更新）
- Modify: `README.md`（七轮状态行+80 行全表）、`PLAN.md`（第七轮状态+书表 Müller-Stach 行+章表 8 新行）、`CHEATSheet.md`（新坑节）、`G:\xulun\.claude\projects\G--code-guide\memory\`（记忆落盘+MEMORY.md 索引）

- [ ] Step 1: `-All` 全量回归（~220 单元全绿）
- [ ] Step 2: 五文件收官对账
- [ ] Step 3: 提交批次四（收官）

## Self-Review

- Spec 覆盖：八新章=Task 2-9 对应 43/44/47/48/49/71/79/80；重排=Task 1；12 章微调在 Task 6。✓
- 占位符：无 TBD；机器件行为以 spec 三节清单为准（本计划不重复内容描述）。
- 类型一致： Interfaces 命名在 Task 内自洽；跨章引用（45 章 cpe/40 章表宇宙风格）为文档线引用非代码依赖。
