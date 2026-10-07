# mathlogic EFT 扩充 + 全书主题重排 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 EFT 3e 扩充 mathlogic 教程 8 个新主题章，同时全书按主题流重编号 51→58 章（收官章后置、新章插主题位、原 23+Henkin 合并），最终 58 章 158 单元全绿。

**Architecture:** 批次〇先做纯结构重排（映射表脚本+多重集校验+全量回归，独立 commit）；批次一~八按新号位写新章（每章：读 PDF 对应节 → Coq 先行 → Lean 镜像 →（P）→ docs → 登记四件 → 章级回归 → commit）；批次九收官对账（58-wrapup 重写为真正收官章）。结构变更与内容变更分开提交。

**Tech Stack:** Rocq/Coq 9.1（build.ps1 拷 ex_ 前缀）、Lean 4.25 裸 core、SWI-Prolog 10（`-q -f 文件 -g main -t halt` + `END ====` ASCII 标记）、pypdf 取材。书源 PDF：`G:\book\数学\Mathematical Logic v3.pdf`（文本层好；代入分数记法提取乱序按数学实体校读；页偏移随章漂移，定位一律用节标题）。

**Spec:** `docs/superpowers/specs/2026-10-08-mathlogic-eft-expansion-design.md`

## Global Constraints

- 用户三要求：(a) 教程非代码罗列，所讲代码全部正文引用；(b) 原书核心自包含讲清，不指路原书；(c) 无篇幅限制。
- docs/NN-*.md ≥200 行、文字行>代码行、禁「自行/见原书/读者自己看」；正文代码逐字符摘自可编译文件。
- 章末「坑位速记」节；Zig 式页脚导航（按新章序）；CRLF 规范化（写后 `python -I -c "…replace(b'\r\n',b'\n')"`）。
- 账本文化：`Print Assumptions`/`#print axioms`；choice/classical 传递显式记账。
- commit 尾行 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 引用书一律用节号（书 §IV.4 式），禁页码（PDF 偏移漂移）。
- Prolog 文件首行 `:- encoding(utf8).`，运行期输出纯 ASCII。

---

### Task 0: 批次〇——全书结构重排（纯结构，51 章重编号+收官后置）

**Files:**
- Modify: `examples/`（35 个目录改名）、`docs/`（35 个文件改名+内部引用）、`examples/ROOT`（session MLNN+路径）、`README.md`、`PLAN.md`、`CHEATSheet.md`、全部示例源码内交叉引用
- Create: `tools/renumber.py`（一次性脚本，用后即弃也可留档）

**Interfaces:**
- Produces: 新章号体系（后续任务在新号位写新章）；映射表（本文件内，权威）。

**映射表（旧号 → 新号，slug 不变）：**

```
01-18 → 01-18 不变
19_resolution   → 26   20_herbrand     → 27   21_decidability → 33
22-incompleteness(doc) → 34-incompleteness
23-completeness(doc)   → 22-completeness   # 批次三重写扩充+新建 examples/22_completeness
24_temporal     → 35   25_hoare        → 46   26-wrapup(doc) → 58-wrapup
27_ltl          → 36   28_mcalgo       → 37   29_ctlstar   → 38
30_totalcorrect → 47   31_modal        → 43   32_correspondence → 44
33_modalnd      → 45   34_symbolicmc   → 42   35_foltableau → 19
36_ltltab       → 39   37_ltlded       → 40   38_buechi     → 41
39_conc         → 48   40_sldprolog    → 30   41_rescomp    → 28
42_synthsem     → 31   43_induction..51_graphs → 49..57（+6 平移）
```

新章号位（本计划新建）：`20_seqfol` `21_interp` `22_completeness`（examples 新建）
`23_lscompact` `24_efgame` `25_secondorder` `29_freemodel` `32_regmachine`。

- [ ] **Step 1: 写 tools/renumber.py**

脚本要素（单遍映射替换，严禁顺序替换造成链式污染）：
1. 两阶段改名：旧 `NN_slug` → 临时 `tmp_NN_slug` → 新 `MM_slug`（docs 文件与 examples 目录都如此；`26-wrapup.md`→`58-wrapup.md` 等 doc-only 章含在内）。
2. 文本替换六形态（对 docs/*.md、README.md、PLAN.md、CHEATSheet.md、examples/**/*.{v,agda,lean,thy,sml,pl}、examples/ROOT）：
   - `第 ?(\d{1,2}) 章` → 查映射；
   - `(\d{2})-([a-z]+)` 且 (num,slug) 是旧对 → 换新号（覆盖 `docs/NN-slug.md` 与相对链接 `NN-slug.md`）；
   - `ex(\d{2})_([a-z]+)` → 换新号（Coq/Lean/Agda 文件名+模块行）；
   - `(\d{2})_([a-z]+)` 且是旧目录对 → 换新号；
   - `ML(\d{2})` → session 名；
   - `Ex(\d{2})` → HOL4 `new_theory "ExNN…"`。
3. 页脚导航整体重生成：每章 `# 第 NN 章 标题` 行换号；`上一章：…· 下一章：…` 按新序统一重建（标题取自映射后的章标题表，去掉「（回到收官章）」类过期后缀）。
4. README/PLAN/CHEATSheet 表格行手工重排（脚本只换号，行序在 Step 3 手工调）。
5. 校验输出：替换前后「第 N 章」多重集按映射逐项一致；`grep -E "(\d{2})_(slug 旧对)|(\d{2})-(slug 旧对)"` 残留=0；映射后 51 个 docs 文件名无重复。

- [ ] **Step 2: 跑脚本+修 README/PLAN/CHEATSheet 行序**

README「已交付章节」表、PLAN「章节蓝图」表按新号重排行（内容不变）；CHEATSheet 三节标题（27-34/35-42/43-51 章新坑 → 新号段 35-42/26-31+33-48/49-57）与节内章号引用换新；PLAN 状态行改「51 章重排完成（58 章号位预留）」。docs/58-wrapup.md 本批只换号，内容不动（批次九重写）。

- [ ] **Step 3: 全量回归**

Run: `pwsh -NoProfile -Command '& ./build.ps1 -All'`
Expected: 140/140 单元通过、0 SKIP、exit 0（重排不增减单元；Isabelle session 改名后重新构建通过）。

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor(mathlogic): 批次〇——全书主题重排 51 章（收官后置、散章归队、新章号位预留）"
```

---

### Task 1: 批次一——新 20 章 FOL 矢列演算与等词（C/L）

**Files:**
- Create: `examples/20_seqfol/ex20_seqfol.v`、`examples/20_seqfol/ex20_seqfol.lean`、`docs/20-seqfol.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`（登记行/节）

**书源：** EFT ch IV（§IV.1-IV.7；PDF 近似 p61-78，以节标题定位）。核心提炼：矢列 Γ⊢φ（有限前件+单后件）；规则全套=结构（Assm/Ant/Ctr/Ch）+联结词（¬A/Ctr'/∨A/PC）+量词（∃S 见证式/∃A 新变元侧条件——反例 ∃x x≡fy y≡fy 展示侧条件不可去）+等词（≡ 反身、Sub 替换）；可导规则（3.4 析取 MP、5.5 量词等价族代表）；IV.6 群例推导；IV.7 协调性（Inc Φ ⟺ ∀ϕ Φ⊢ϕ；演算本身协调）。

**Interfaces（两通道同名同义）：**

```coq
Inductive tm : Type := var (n:nat) | fun_ (f:nat) (ts:list tm).
Fixpoint substt (t:tm) (x:nat) (u:tm) : tm.          (* 项代入 *)
Inductive fm : Type :=
| r_atom (r:nat) (ts:list tm) | eq_atom (t1 t2:tm)
| neg (φ:fm) | disj (φ ψ:fm) | exq (x:nat) (φ:fm).  (* ∀ 用 ¬∃¬ 编码 *)
Fixpoint fv (φ:fm) : list nat.  Fixpoint substf (φ:fm) (x:nat) (u:tm) : fm.
Inductive der : list fm -> fm -> Prop :=              (* EFT 矢列演算 S *)
| Assm Γ φ : In φ Γ -> der Γ φ
| Ant Γ Δ φ : incl Γ Δ -> der Γ φ -> der Δ φ
| Ctr Γ ψ φ : der Γ φ -> der (ψ::Γ) φ
| Ch Γ φ ψ : der Γ ψ φ -> der (ψ::Γ) φ
| PC Γ φ : der (neg φ :: Γ) φ                        (* 命题级取 06 章同构件 *)
| OrA Γ φ ψ : der Γ φ -> der (neg φ::Γ) ψ -> der Γ (disj φ ψ)
| ExS Γ x φ t : der Γ (substf φ x t) -> der Γ (exq x φ)
| ExA Γ x φ ψ y : ~In y (fv_l (exq x φ :: ψ :: Γ)) ->
    der (substf φ x (var y) :: Γ) ψ -> der (exq x φ :: Γ) ψ
| Ref Γ t : der Γ (eq_atom t t)
| Sub Γ x φ t t' : der Γ (substf φ x t) ->
    der (eq_atom t t' :: Γ) (substf φ x t').
```

机器件（每个都要编译过并在 docs 正文引用）：(1) `der` 全构造子；(2) 可导规则 `der_or_mp`（3.4：der Γ (disj (neg φ) ψ) → der Γ φ → der Γ ψ）、`der_ex_dne`（5.5 代表成员）；(3) 群例核心段：Γgrp（结合律/幺元/逆元）⊢ ∀x∃y y·x≡e 的**完整推导项**（IV.6 的 17-34 行段）；(4) 协调性 `inc_derives_all`（Inc Φ → ∀ϕ der Φ ϕ，7.2）+ 命题片段可靠性（der Γ φ → 闭公式布尔赋值下有效——接 06 章可靠性的老配方，限定命题级构造子）⇒ 演算协调（某闭原子式不可导）。∀/∧/→ 用缩写定义展开。

- [ ] **Step 1: 读 PDF §IV.1-IV.7**（重点 IV.4 量词/等词规则正确性论证、IV.6 群例逐行、IV.7 引理链）
- [ ] **Step 2: 写 ex20_seqfol.v → `build.ps1 -File` 迭代全绿**（先 der 定义+小引理，再可导规则，最后群例推导项——推导项是本章最重件，预计要按书逐行翻成构造子嵌套）
- [ ] **Step 3: 写 ex20_seqfol.lean 镜像全绿 + `#print axioms` 账本**（Lean 版侧条件同法：构造子参数；账本预期 [propext] 级）
- [ ] **Step 4: 写 docs/20-seqfol.md**（≥200 行：与 06 章分工表开场→规则即构造子→侧条件反例→群例推导逐行讲→协调性→坑位速记→Zig 页脚 19←→21）
- [ ] **Step 5: 登记+章回归+commit**

```bash
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 20'
git add -A && git commit -m "feat(mathlogic): 批次一——新 20 章 FOL 矢列演算与等词（C/L）"
```

---

### Task 2: 批次二——新 21 章 语法解释、范式与 ZF（C/L）

**Files:**
- Create: `examples/21_interp/ex21_interp.v`、`examples/21_interp/ex21_interp.lean`、`docs/21-interp.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch VIII（§VIII.1-8.4；PDF 近似 p117-139）+ ch VII（§VII.3-7.4 ZF；PDF 近似 p102-116）。核心提炼：词项化简（∀x fgx≡y ⟹ ∀x∃u(gx≡u ∧ fu≡y)）；关系化符号集（函词消去）；语法解释 π: L^S→L^S' 保持有效性；定义扩张保守；ZF 公理作为 FOL 句子（外延/配对/并/分离）。

**Interfaces：** 复用 20 章 `tm/fm`（每章自包含复制，教程纪律）。新增：

```coq
(* 关系化翻译：函词 f ↦ 关系 R_f，项方程 t≡t' 逐层拆存在量词 *)
Fixpoint trew (t:tm) (x:nat) : fm      (* 为项 t 引新变元 x：t≡x 的关系化合取式 *)
Fixpoint relf (φ:fm) : fm              (* 公式级翻译：原子/逻辑词逐层 *)
(* 翻译正确性的可判定现场：在有限具体结构上 eval (relf φ) = eval φ *)
(* ZF 公理即公式 *)
Definition zf_ext : fm := ∀x ∀y (∀z (z∈x ↔ z∈y) → x≡y)   (* ↔/→/∧ 用缩写展开 *)
Definition zf_pair, zf_union, zf_sep : fm.
```

机器件：(1) `trew/relf` 翻译器（对固定小语言：一元 f、g + 二元 R）；(2) 翻译保真的**数值对账**——书例 ∀x fgx≡y ⟹ ∀x∃u(gx≡u∧fu≡y) 在 3 元结构（f,g,R 全枚举）上逐点验证两式同值（Compute/decide 输出）；(3) 定义扩张现场：语言加常量 c_φ 定义式 φ(c)，翻译回去消去后与原式等价（小现场数值验证）；(4) ZF 四公理写成 `fm` + Compute 打印展示 + 各公理的一句话语义讲透。

- [ ] **Step 1: 读 PDF §VIII.1-8.4 + §VII.3-7.4**
- [ ] **Step 2: ex21_interp.v 全绿**（翻译器+有限结构 eval+对账输出；eval 的结构编码沿用 15 章配方）
- [ ] **Step 3: ex21_interp.lean 镜像全绿+账本；docs/21-interp.md（≥200 行）**（开场：与 14/15 章分工→词项化简现场→翻译器逐段讲→定义扩张→ZF 终节→坑位→页脚 20←→22）
- [ ] **Step 4: 登记+章回归+commit**（同 Task 1 模式，消息 `批次二——新 21 章 语法解释、范式与 ZF（C/L）`）

---

### Task 3: 批次三——新 22 章 完备性：Henkin 构造（C/L，原 23 重写合并）

**Files:**
- Create: `examples/22_completeness/ex22_completeness.v`、`examples/22_completeness/ex22_completeness.lean`
- Modify: `docs/22-completeness.md`（原 23 文档重写扩充：保留七步文档线骨架，新增机器件章节）
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch V（§V.1-V.4；PDF 近似 p79-98）。核心提炼：Henkin 定理（含见证的协调集有模型）；词项解释 IΦ=（T^Φ,β^Φ）——t∼t′ iff Φ⊢t≡t′ 商结构；Lemma 1.7（IΦ(t)=t；原子式 IΦ⊨ϕ ⟺ Φ⊣ϕ）；可数情形（逐公式枚举+见证常项添加）；一般情形（Zorn）；完备性合拢（Φ⊢ϕ ⟺ Φ⊨ϕ）。

**Interfaces：**

```coq
(* 具体小语言：常量 c0,c1 + 一元 f + 二元 R；Φ 取一组基方程（如 f(c0)≡c1 类） *)
Definition Phi : list fm.
Definition dermeq (t1 t2:tm) : Prop := der Phi (eq_atom t1 t2).   (* ~ 关系 *)
(* 商表示：以「最小代表」函数 canonicalize（基项有限时闭包可算）*)
(* 机器件一：Lemma 1.7(a) 型定理 —— 解释函数求值 [t] = canonicalize t *)
(* 机器件二：原子式双向 —— dermeq t1 t2 <-> closure 成员 <-> interp 满足 *)
(* 机器件三：见证式 Henkin 化有限片段 —— 命题级类比：
   给定公式表 [∃x φ1; ∃x φ2]，产出扩张公式表 [φ1(c1); φ2(c2)]，
   可满足性等价在命题语义下机器证明（finite valuation eval） *)
```

选 Φ 的纪律：**闭基项有限**（例：c0,c1,f(c0),f(c1),f(f(c0))… 截断到固定深度），使 derivability=congruence closure 可算；这样 1.7 的「⟺」两侧都能 decide/归纳证真。完备性主定理（无限构造+Zorn）保持文档级——docs 讲清 EFT 路线（含 ch V 可数情形的逐步描述），并明确「机器件覆盖定理的哪一半、其余为何诚实止步」。

- [ ] **Step 1: 读 PDF §V.1-V.4**（1.1-1.7 定义链+可数情形构造+一般情形+V.4 合拢）
- [ ] **Step 2: ex22_completeness.v 全绿**（canonicalize+closure+双向定理+命题级 Henkin 化片段）
- [ ] **Step 3: Lean 镜像+账本；docs/22-completeness.md 重写**（≥260 行：七步文档线保留收敛+词项解释机器件两节+可数/一般情形+与 20 章矢列的接口+坑位+页脚 21←→23）
- [ ] **Step 4: 登记+章回归+commit**（消息 `批次三——新 22 章 完备性 Henkin 构造（原 23 重写合并，C/L）`）

---

### Task 4: 批次四——新 23 章 L-S、紧致性与初等等价（C/L）

**Files:**
- Create: `examples/23_lscompact/ex23_lscompact.v`、`examples/23_lscompact/ex23_lscompact.lean`、`docs/23-lscompact.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch VI（§VI.1-6.4；PDF 近似 p91-102）。核心提炼：向下 L-S（可数语言→可数模型；Skolem 化思想）、向上 L-S、紧致性（EFT 版证明走 Henkin/完备性路线：Φ 有限可满足 ⟹ 每有限子集协调 ⟹（引理）整体协调 ⟹ 有模型）；初等类 EC/EC_Δ；初等等价 ≡；Lindström 的伏笔。

**机器件：** (1) **不可有限公理化证词（DLO 无端点）**——线性序公理+稠密+无端点的句子组 Φ_DLO；对每个有限子集（按公理枚举的 n 个）在有限线序族 {Z_1..Z_8} 上 decide 验证「有模型」，而全组在全部有限结构上无模型（数值穷举输出）；紧致性 ⟹ Φ_DLO 有模型必无限——「有限可满足 ⟹ 无限模型」的机器脚印。(2) 初等等价的**有界版本**：`eeq_rank m`（量化秩 ≤m 公式同值）在有限结构对上的检查器（枚举 m=0,1,2 的句子空间），为 24 章 EF 博弈埋线（此处只做检查器+现场数值，等价定理留 24 章）。(3) 向下 L-S 的 Skolem 化小现场：给一个具体结构，其可数初等子结构的存在性思想（文档级讲清，配「闭于 Skolem 函数」的数值演示：从 {a} 出发闭包生成表）。

- [ ] **Step 1: 读 PDF §VI.1-6.4**（向下 L-S 证明、紧致性引理链、初等类）
- [ ] **Step 2: ex23_lscompact.v 全绿**（DLO 公理化+有限子集/有限结构两张穷举表+eeq_rank 检查器+现场输出）
- [ ] **Step 3: Lean 镜像+账本；docs/23-lscompact.md**（≥200 行：两定理陈述+证明思想→机器证词逐段讲→eeq_rank 埋线→坑位→页脚 22←→24）
- [ ] **Step 4: 登记+章回归+commit**（消息 `批次四——新 23 章 L-S、紧致性与初等等价（C/L）`）

---

### Task 5: 批次五——新 24 章 EF 博弈与 Fraïssé 定理（C/L/P）

**Files:**
- Create: `examples/24_efgame/ex24_efgame.v`、`examples/24_efgame/ex24_efgame.lean`、`examples/24_efgame/ex24_efgame.pl`、`docs/24-efgame.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch XII（§XII.1-12.4；PDF 近似 p256-280）。核心提炼：部分同构（A≅p B：一簇带 back-and-forth 的部分映射）；有限同构（A≅f B：(I_n) 序列）；Fraïssé 定理 A≡B ⟺ A≅f B（有限符号集）；Ehrenfeucht 博弈 n 轮（spoiler/duplicator）；(n,<) 量化秩分离；DLO 部分同构（Lemma 1.7：稠密线序两两 ≅p）。

**Interfaces（三通道同义）：**

```coq
(* 有限结构：论域 bound nat + 关系表（二元关系编码：nat->nat->bool 限界） *)
Record fstruct := mk { size : nat; rel : nat -> nat -> bool }.   (* 单个二元关系起见 *)
(* 部分映射：已选点对表 pairs；诱导子结构同构检查 pi_ok *)
Definition pi_ok (A B:fstruct) (ps:list (nat*nat)) : bool
(* duplicator n 轮赢策略（归纳定义=游戏树最小不动点） *)
Fixpoint dup_wins (m:nat) (A B:fstruct) (ps:list (nat*nat)) : bool :=
  match m with
  | 0 => pi_ok A B ps
  | m'+1 => (forall a < size A, exists b < size B, dup_wins m' A B ((a,b)::ps))
        && (forall b < size B, exists a < size A, dup_wins m' A B ((a,b)::ps))
  end.
```

注意 Fixpoint 结构性：m 递减但 ps 增长——用 `Fixpoint … (m:nat) : list _ -> bool` 内层 ps 或改 struct on m 的非依赖写法； Lean 同理。机器件：(1) `dup_wins` 求解器；(2) **经典分离定理现场**：(Z_n,<) vs (Z_m,<)：dup 赢 m 轮 ⟺ n,m ≥ 2^m −1（书 XII 例）——对 n,m ∈ 1..8、m 轮 ∈ 1..3 全表 Compute，与定理对照；(3) 低秩等价现场（Z_4 ≡_2 Z_5 之类）+ 与 23 章 eeq_rank 检查器**双向对账**（dup_wins m A B = true ⟺ eeq_rank m A B——在有限小结构上全枚举验证，这就是 Fraïssé 定理有限片段的机器脚印）；(4) DLO 部分同构现场：[0,1]∩Q vs [0,1]∩(Q\{中点}) 手工 back-and-forth 的数值演示（有界域离散化）。Prolog 通道：`dup_win(M, A, B, Pairs)` 回溯搜索（spoiler 两侧选点、duplicator 应对，输出策略踪迹）+ main 输出分离表若干行。

- [ ] **Step 1: 读 PDF §XII.1-12.4**（定义 1.1-1.3、Lemma 1.7、Thm 2.1、XII.3 ϕ^m_B、XII.4 博弈）
- [ ] **Step 2: ex24_efgame.v 全绿**（pi_ok+dup_wins+分离表+eeq 对账；dup_wins 的 Fixpoint 结构若受阻，转 Inductive 两构造子定义+Compute）
- [ ] **Step 3: ex24_efgame.lean 镜像+账本；ex24_efgame.pl（回溯搜索+`END ====`）**
- [ ] **Step 4: docs/24-efgame.md**（≥220 行：部分/有限同构定义讲透→博弈规则→求解器→分离定理全表→Fraïssé 两方向证明思想（全证文档级）→与 23 章对账→坑位→页脚 23←→25）
- [ ] **Step 5: 登记+章回归+commit**（消息 `批次五——新 24 章 EF 博弈与 Fraïssé 定理（C/L/P）`）

---

### Task 6: 批次六——新 25 章 二阶逻辑与弱二阶系统（C/L）

**Files:**
- Create: `examples/25_secondorder/ex25_secondorder.v`、`examples/25_secondorder/ex25_secondorder.lean`、`docs/25-secondorder.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch IX（§IX.1-9.3；PDF 近似 p138-151）+ §X.5（二阶不完备/Trakhtenbrot 伏笔）。核心提炼：二阶全语义（关系变量跑全部关系）；表达力跃升（Dedekind 完备、有限性 INC_FIN、范畴性二阶 PA）；二阶有效不可枚举/不可完备；L_ω1ω（可数合取、更多表达力、无完备演算）；L_Q（「存在不可数多」；在可数结构上退化为空量词）。区分一阶/二阶语义（Henkin vs full）讲透。

**Interfaces：**

```coq
Inductive sofm : Type :=
| so_atom (r:nat) (ts:list tm)
| so_eq (t1 t2:tm) | so_neg (φ:sofm) | so_disj (φ ψ:sofm)
| so_ex (x:nat) (φ:sofm)                    (* 一阶 ∃ *)
| so_exr (k:nat) (X:nat) (φ:sofm).          (* 二阶 ∃X^k *)
(* 有限结构求值：k 元关系域 = 论域 k 元组列表 -> bool（有限幂集枚举） *)
Definition relenv := nat -> (list (list nat)) -> bool.   (* 环境查关系变量 *)
Fixpoint soeval (S:fstruct) (ve:numenv) (re:relenv) (φ:sofm) : bool.
```

机器件：(1) `soeval` 求值器；(2) **表达力现场一（EVEN）**：二阶句 ψ_even：论域可分两无交无穷…有限版：∃X（X 与补 X 间有双射）太重——取**归纳式**：∃X（0∈X ∧ 相邻交替 ∧ 最后点∈X）在 (Z_n,Succ) 上定义偶性，Compute 验证 n=1..8；(3) **表达力现场二（图连通性）**：∃R（R 含边 ∧ 传递 ∧ 全域）在 4 点图对（连通/非连通）上验证；(4) **一阶不可定义的机器脚印**：EVEN 不可一阶定义——用 24 章 dup_wins 在纯等值结构 (Z_n,=) 上数值验证「∀m ∃n,n′ 同 m 秩等价但一奇一偶」（引 24 章定理+输出对照表）；(5) L_Q 现场：在可数（有限）结构上 Qx φ 恒假/恒真的退化行为 Compute 展示。

- [ ] **Step 1: 读 PDF §IX.1-9.3**（二阶语义定义、范畴性例子、L_ω1ω/L_Q 定理陈述）
- [ ] **Step 2: ex25_secondorder.v 全绿**（sofm+soeval+EVEN/连通两现场+L_Q 退化）
- [ ] **Step 3: Lean 镜像+账本；docs/25-secondorder.md**（≥200 行：一阶天花板→二阶语义→求值器→两现场→不可定义脚印→L_ω1ω/L_Q 讲透→坑位→页脚 24←→26）
- [ ] **Step 4: 登记+章回归+commit**（消息 `批次六——新 25 章 二阶逻辑与弱二阶系统（C/L）`）

---

### Task 7: 批次七——新 29 章 自由模型与逻辑编程的代数（C/L）

**Files:**
- Create: `examples/29_freemodel/ex29_freemodel.v`、`examples/29_freemodel/ex29_freemodel.lean`、`docs/29-freemodel.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch XI（§XI.1-11.7；PDF 近似 p208-234，重点 §XI.1-11.3+11.7）。核心提炼：Herbrand 定理（可满足性归约到命题实例）；自由模型定理（universal Horn 理论 Φ 的词项解释 IΦ 是**最小模型**：信息序下只含必需元素；对任意模型 B 存在同态 IΦ→B——初始性）；Herbrand 结构；归结/SLD 是算法面（已在 26/27/30 章）——本章讲**代数面**：初始语义=归纳原理=Prolog 最小 Herbrand 模型的根。

**Interfaces：**

```coq
(* 载体理论：幺半群公理（universal Horn/方程） *)
Definition mono_ax : list fm := [结合律; c 为左幺; 一元 g 为左逆 → 都写成 ∀ 方程]
(* 自由模型：ground 项代数（= 词表 List gen）＋ 解释 f:=append、c:=[] *)
(* 机器件一：term model 满足公理 —— append 结合律就是 List.append_assoc *)
(* 机器件二：初始性——任意满足公理的结构 (B,·B,eB)，
   唯一同态 h : words -> B，h = fold eB ·B （递归定义+两定理：h 保运算、唯一） *)
(* 机器件三：信息序/最小性片段—— IΦ 的元素恰是「必需」闭项（数值：公理闭包演示） *)
```

选幺半群（不用群——自由群的字问题不可判定，正好在 docs 里讲这个对照！EFT XI 的精神：Horn 的可满足性有词项模型、一般没有）。机器件以 `List` 为自由模型：`h_preserves : h (a++b) = h a ·B h b`、`h_unique : (∀w, h' w = h w)`——归纳法直落。docs 必有一节「分工表」：26 章归结算法/27 章 Herbrand/30 章 SLD 语义 vs 本章初始模型代数。

- [ ] **Step 1: 读 PDF §XI.1-11.3+11.7**（Herbrand 定理形式、Thm 2.3 自由模型、XI.7 LP 观）
- [ ] **Step 2: ex29_freemodel.v 全绿**（公理化+词项模型+初始性两定理+必需性演示）
- [ ] **Step 3: Lean 镜像+账本；docs/29-freemodel.md**（≥200 行：Horn 与词项模型→自由模型定理→初始性机器件→与 26/27/30 分工表→Prolog 根基→坑位→页脚 28←→30）
- [ ] **Step 4: 登记+章回归+commit**（消息 `批次七——新 29 章 自由模型与逻辑编程的代数（C/L）`）

---

### Task 8: 批次八——新 32 章 寄存器机与可计算性（C/L/P）

**Files:**
- Create: `examples/32_regmachine/ex32_regmachine.v`、`examples/32_regmachine/ex32_regmachine.lean`、`examples/32_regmachine/ex32_regmachine.pl`、`docs/32-regmachine.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** EFT ch X（§X.1-10.4, 10.6-10.9；PDF 近似 p151-207）。核心提炼：寄存器机（字母表 A={a0..ar}、寄存器 R0..Rm 存 A* 字、五指令：(1) L LET R_i=R_i+a (2) L LET R_i=R_i−a (首字母为 a 则删) (3) L IF R_i=□ THEN L′ ELSE L″ (4) L PRINT (5) L HALT）；程序=带标号指令表；P:ζ→halt / P:ζ→∞ / P:ζ→η；书例 P_0 奇偶判定（| 计数逐删）；可判定/可枚举（dove-tailing）；停机问题不可判定（对角线）；FOL 不可判定（Φ_π 植入+半可判定对照⇒不可判定）；Trakhtenbrot；Presburger/WS1S 可判定接 33/49 章。

**Interfaces（三通道同义）：**

```coq
Inductive inst : Type :=
| radd (r:nat) (a:nat)                         (* R_r := R_r + a *)
| rdel (r:nat) (a:nat)                         (* R_r := R_r - a *)
| rife (r:nat) (l1 l2:nat)                     (* IF R_r = □ THEN l1 ELSE l2 *)
| rprint | rhalt.
Definition prog := list inst.                  (* 指令 α_i 标号 i *)
Record cfg := mkc { pc:nat; regs:list word; out:list word }.  (* word = list nat *)
Definition step (p:prog) (c:cfg) : cfg.         (* 单步：rife 跳转/rdel 条件删 *)
Fixpoint run (p:prog) (c:cfg) (fuel:nat) : option cfg.        (* None=未停 *)
```

机器件：(1) 解释器 `step/run`；(2) **书例 P_0 奇偶程序逐字移植**（8 条指令，标号 0-7）+ Compute 对账 n=0..10 输出 □/|；(3) **P_0 正确性定理**：`p0_correct : ∀n fuel(足量), run p0 (start n) = Some (out=[n 奇偶标记])`——循环不变式（R0 = n−2k）归纳法（本章最重证明件）；(4) 加法程序（R0+R1→R0）同法；(5) 停机对角线：**程序-输入表的对角构造**文档级讲透+`busy_prog` 玩具示例（对角程序的雏形：读自描述编号）Compute 演示思路；(6) Φ_π 植入+FOL 不可判定（Church）思想链文档级（33/34 章接口）。Prolog：`step/run` 状态谓词+`halts(Prog, In)` 有界搜索+main 输出 P_0 对账表与一个不停机示例（`END ====`）。

- [ ] **Step 1: 读 PDF §X.1-10.4**（指令定义、P_0、halt 集、对角线）+**§X.6-10.9** 扫读（理论可判定性、Presburger/WS1S 定位）
- [ ] **Step 2: ex32_regmachine.v 全绿**（step/run+P_0+不变式正确性——正确性若全量归纳过重，允许定理对 fuel≥n+2 形式陈述，但归纳核心必须真做）
- [ ] **Step 3: Lean 镜像+账本；ex32_regmachine.pl**
- [ ] **Step 4: docs/32-regmachine.md**（≥220 行：可计算性的精确定义需求→五指令讲透→解释器→P_0 逐行+不变式定理→停机对角线→FOL 不可判定链→Presburger/WS1S 接口→坑位→页脚 31←→33）
- [ ] **Step 5: 登记+章回归+commit**（消息 `批次八——新 32 章 寄存器机与可计算性（C/L/P）`）

---

### Task 9: 批次九——收官对账（58-wrapup 重写+四文件+全量回归+记忆）

**Files:**
- Modify: `docs/58-wrapup.md`（由原 26-wrapup 内容重写为真正收官章）、`README.md`、`PLAN.md`、`CHEATSheet.md`
- Create: 记忆文件 `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-eft-expansion.md` + MEMORY.md 索引行

- [ ] **Step 1: docs/58-wrapup.md 重写**（≥260 行：十篇图景总览（按新篇章序）+从命题到不完备性的主线重述+总坑位清单（分通道）+十书导读（EFT 行新增：元理论线 20-25/29/32）+EFT 逐节对账表（§IV→20 章、§V→22、§VI→23、§VII/VIII→21、§IX→25、§X→32+33/34 接口、§XI→29、§XII→24、§XIII→23/58 文档级）+全书账本尾段（各通道单元计数））
- [ ] **Step 2: README/PLAN/CHEATSheet 终稿**（README 十书+58 章 158 单元+全章表按新序；PLAN 状态行「58 章 158 单元全绿」+EFT 定位行+新章行；CHEATSheet 增「20-25/29/32 章新坑（EFT 扩充）」节）
- [ ] **Step 3: 全量回归**

Run: `pwsh -NoProfile -Command '& ./build.ps1 -All'`
Expected: **158/158 单元通过、0 SKIP、exit 0**。

- [ ] **Step 4: 记忆落盘+commit**

记忆内容：EFT 扩充收官（58 章/158 单元）、全书重排映射要点、本轮实测坑 top5、与前三轮的记忆互链 [[mathlogic-jongsma-expansion]] [[mathlogic-benari-expansion]] [[mathlogic-tutorial-build]]。

```bash
git add -A && git commit -m "docs(mathlogic): 批次九——EFT 扩充收官对账（58 章/158 单元全绿，全书主题重排定稿）"
```

---

## Self-Review 记录

- Spec 覆盖：spec 第二节 8 新章 ↔ Task 1-8 一一对应；重排 ↔ Task 0；对账四文件 ↔ Task 9；Lindström 文档级落 23 章（eeq/L-S 极大性语境）+58 收官导读——Task 4/9 Step 内有交代。✓
- 占位符：无 TBD；每任务给出确切文件、接口签名、验收命令、commit 消息。证明的最终 tactic 由编译迭代产生（历轮模式），计划的「接口」即契约。✓
- 类型一致性：20 章 `tm/fm/der` 定义被 21/22 章复用（各章自包含复制为纪律，接口签名一致）；24 章 `fstruct/pi_ok/dup_wins` 被 25 章引用（同签名）。✓
- 风险预置：24 章 Fixpoint 结构性预案（转 Inductive）写入任务；32 章正确性定理的 fuel 形式化弹性写入任务；22 章 Φ 选型纪律（闭基项有限）写入任务。✓
