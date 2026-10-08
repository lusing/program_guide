# mathlogic Mendelson 扩充 实施计划（第五轮书本扩充：58→63 章）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 Mendelson 6e 扩充 mathlogic：新 5 章（09 完备集与独立性、34 图灵机、35 递归函数、36 算术化、62 NBG 集合论）+ 37 不完备性升级（文档→机器）+ 五处原位深化，全书重编号 58→63 章，最终 63 章 179 单元全绿。

**Architecture:** 批次〇纯结构重排（旧→新映射+33/34 交换+空位预留，独立 commit）；批次一~五新章（每章：读 PDF 对应节 → Coq 先行 → Lean 镜像 →（P）→ docs → 登记 → 章级回归 → commit）；批次四同批做 36+37（β-编码↔对角强耦合）；批次六深化（05 文档节+18/23/24/26 机器件——深化章一律用**新号**）；批次七收官对账（63-wrapup 重写）。

**Tech Stack:** Rocq/Coq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`，build.ps1 拷 ex_ 前缀）、Lean 4.25 裸 core、SWI-Prolog 10（`G:\scoop\apps\swipl\current\bin\swipl.exe`，`-q -f 文件 -g main -t halt` + `END ====` ASCII 标记）、pypdf 取材。书源 PDF：`G:\book\数学\Introduction to Mathematical Logic, Sixth Edition (Elliott Mendelson) (z-library.sk, 1lib.sk, z-lib.sk).pdf`（499 页；文本层好但公式符号乱序——按数学实体校读；页偏移**恒定 +25**，定位用节标题）。

**Spec:** `docs/superpowers/specs/2026-10-08-mathlogic-mendelson-expansion-design.md`

## Global Constraints

- 用户三要求：(a) 教程非代码罗列，所讲代码全部正文引用；(b) 原书核心自包含讲清，不指路原书；(c) 无篇幅限制。
- docs/NN-*.md ≥200 行、文字行>代码行、禁「自行/见原书/读者自己看」；正文代码逐字符摘自可编译文件。
- 章末「坑位速记」节；Zig 式页脚导航（按 63 章新序）；CRLF 规范化（写后 `python -I -c "…replace(b'\r\n',b'\n')"`）。
- 账本文化：`Print Assumptions`/`#print axioms`；choice/classical 传递显式记账（62 章有限 AC 零公理是预期亮点）。
- commit 尾行 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 引用书一律用节号（书 §3.4 式），禁页码。
- Prolog 文件首行 `:- encoding(utf8).`，输出纯 ASCII；撇号变量名禁用（Cfg'→Cfg2 教训）。
- 嵌套归纳 guard 前科（EFT 五撞）：prec 递归/深 match 实例归约卡死 → 测度/fuel/native_decide 三件套预案。

---

### Task 0: 批次〇——全书结构重排（58→63 号位，33/34 交换，纯结构）

**Files:**
- Modify: `examples/`（49 个目录改名）、`docs/`（58 个文件改名+内部引用）、`examples/ROOT`（session MLNN）、`README.md`、`PLAN.md`、`CHEATSheet.md`
- Create: `tools/renumber_m.py`（新映射版脚本）

**Interfaces:**
- Produces: 63 章号位体系（09/34/35/36/62 空位+README 标施工中）；本任务内映射表为权威。

**映射表（旧号→新号，slug 不变）：**

```
01-08 → 01-08 不变
09_dpll→10  10_bdd→11  11_glivenko→12  12_ch→13  13_kripke→14
14_folsyntax→15  15_folsem→16  16_folnd→17  17_folhilbert→18  18_prenex→19
19_foltableau→20  20_seqfol→21  21_interp→22  22_completeness→23
23_lscompact→24  24_efgame→25  25_secondorder→26
26_resolution→27  27_herbrand→28  28_rescomp→29  29_freemodel→30
30_sldprolog→31  31_synthsem→32  32_regmachine→33
33_decidability→38   34-incompleteness(doc)→37-incompleteness   # 交换：37 不完备性、38 SMT
35_temporal→39  36_ltl→40  37_mcalgo→41  38_ctlstar→42  39_ltltab→43
40_ltlded→44  41_buechi→45  42_symbolicmc→46  43_modal→47
44_correspondence→48  45_modalnd→49  46_hoare→50  47_totalcorrect→51  48_conc→52
49_induction→53  50_pa→54  51_divisibility→55  52_setscount→56
53_infinity→57  54_funequiv→58  55_posetlattice→59  56_boole→60  57_graphs→61
58-wrapup(doc)→63-wrapup
```

新章号位（本计划新建）：`09_adequate` `34_turing` `35_recfn` `36_goedel` `62_nbg`；
`37_incompleteness` 批次四升级为机器章（新建 examples/37_incompleteness）。

- [ ] **Step 1: 写 tools/renumber_m.py**（复用 EFT 轮 renumber 协议，改映射）
  1. 两阶段改名（旧 `NN_slug` → `tmpN_slug` → 新 `MM_slug`；docs 文件与 examples 目录同法；每文件只写一次盘防 MAP²）。
  2. 文本单遍替换（对 docs/*.md、README/PLAN/CHEATSheet、examples/**/*.{v,agda,lean,thy,sml,pl,ROOT}）：`第 ?(\d{1,2}) 章` 查映射；`(\d{2})-(slug 旧对)`（含 `docs/NN-slug.md` 与相对链接，(?:docs/)? 前缀可选）；`ex(\d{2})_slug`；`(\d{2})_slug` 目录对；`ML(\d{2})` session；`Ex(\d{2})` HOL4 new_theory。**章号模式合并单形态**（防 slash→bare 链式重匹配）。
  3. 页脚 Zig 导航按 63 章新序整体重生成（标题表驱动）。
  4. 校验：「第 N 章」多重集按映射逐项一致；旧 (号,slug) 对 grep 残留=0；58 个 docs 换名后无重复。
- [ ] **Step 2: README/PLAN/CHEATSheet 行序重排**（表行按新号排；README 状态行改「63 章号位中 09/34/35/36/62 五章为 Mendelson 扩充预留（施工中）」；PLAN 加本轮批次行。docs/63-wrapup.md 只换号不重写）
- [ ] **Step 3: 全量回归** — `pwsh -NoProfile -Command '& ./build.ps1 -All'` → 158/158、0 SKIP、exit 0（重排不增减单元；33_decidability 的 Isabelle session ML33→ML38 后重构建通过）
- [ ] **Step 4: Commit** `refactor(mathlogic): 批次〇——Mendelson 扩充全书重排 58→63 号位（33/34 交换、五空位预留）`

---

### Task 1: 批次一——新 09 章 完备连接词集与公理独立性（C/L）

**Files:**
- Create: `examples/09_adequate/ex09_adequate.v`、`examples/09_adequate/ex09_adequate.lean`、`docs/09-adequate.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §1.3（完备集；PDF 44-52）+ §1.5（独立性 Prop 1.17；PDF 61-63）+ §1.6（其他公理化；PDF 63-69）。两矩阵九项 ⇒ 表已在 spec 抄录。

**Interfaces（两通道同义）：**

```coq
Inductive fm : Type := v (n:nat) | neg (φ:fm) | imp (φ ψ:fm).  (* ∧∨↔缩写；Mendelson 原生 ¬,⇒ *)
(* —— 完备集 —— *)
(* Shannon 构造：n 变元真值表 f:(list bool->bool) 的 {¬,∧,∨} 公式表示 *)
Fixpoint shannon (n:nat) (f:list bool->bool) : fm
Theorem shannon_ok : ∀ n f asg, beval (shannon n f) asg = f asg     (* 表示定理 *)
Definition tNA (φ:fm) : fm        (* ∨/∧/→ 全部消到 {¬,∧} *)
Fixpoint tUp (φ:fm) : fmUp        (* 消到单连接词 ↑（A↑B:=¬(A∧B)），fmUp 只有 vn/up *)
(* —— 独立性 —— *)
Definition neg1 : nat->nat := (* 0→1,1→1,2→0 *)   Definition imp1 : nat->nat->nat (* 9 项表 *)
Definition neg2 : nat->nat := (* 0→1,1→0,2→1 *)   Definition imp2 : nat->nat->nat (* 9 项表 *)
Fixpoint ev3 (neg) (imp) (φ:fm) (asg:nat->nat) : nat
Theorem mp_sel1 : ev3 B=0 -> ev3 (imp B C)=0 -> ev3 C=0            (* 27 案查表 *)
Theorem A2_sel1 : ∀ B C D asg, ev3 … (A2 实例形状) … = 0            (* 对 B C D 取值分 27 案 *)
Theorem A3_sel1 : 同上
Example a1_not_sel1 : ev3 (A1 实例 v0 (v1)) [0↦1;1↦2] = 2
(* 矩阵二同构三件：A1_grot2/A3_grot2 + a2_not_grot2 (0,0,1) *)
(* —— super 擦负号（A3 独立）—— *)
Fixpoint h (φ:fm) : fm                  (* neg φ ↦ h φ *)
Theorem h_taut_A1A2 : istaut (h (A1 实例)) ∧ istaut (h (A2 实例))   (* 2 值重言，复用 02 章配方 *)
Example a3_not_super : istaut (h ((¬A⊃¬A)⊃((¬A⊃A)⊃A)) 实例) = false
```

机器件：`shannon_ok`（表示定理真证：表归纳）+ `tUp` 翻译对账（小公式全指派）+ 矩阵三件×2 + super 三件。docs 含「与 05/08 章分工表」（05 讲推导、08 讲范式、本章讲**连接词代数面与公理不可省**）+ L1-L4/单公理文档节。

- [ ] **Step 1: 读 PDF §1.3/§1.5/§1.6**
- [ ] **Step 2: ex09_adequate.v 全绿**（先 Shannon 件，再矩阵件——27 案分案用 `destruct` 值组合+表计算）
- [ ] **Step 3: ex09_adequate.lean 镜像+账本**（深 match 实例归约若卡 → native_decide 预案）
- [ ] **Step 4: docs/09-adequate.md**（≥200 行；页脚 08←→10）
- [ ] **Step 5: `build.ps1 -Chapter 09` 全绿 + commit** `feat(mathlogic): 批次一——新 09 章 完备连接词集与公理独立性（C/L）`

---

### Task 2: 批次二——新 34 章 图灵机：四元组与纸带（C/L/P）

**Files:**
- Create: `examples/34_turing/ex34_turing.v`、`examples/34_turing/ex34_turing.lean`、`examples/34_turing/ex34_turing.pl`、`docs/34-turing.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §5.1（Turing 机定义；PDF 336-342）+ §5.2（图示与书例；PDF 342-350）。四元组语义：停机=无适用四元组。

**Interfaces（三通道同义）：**

```coq
Inductive act : Type := wr (b:nat) | movL | movR.
Inductive quad : Type := qd (qs rd qs' : nat) (a:act).
Record tape := { lft:list nat; cur:nat; rgt:list nat }.   (* 双向表；空白=0 *)
Record cfg  := { st:nat; tp:tape }.
Definition find (p:list quad) (s a:nat) : option (nat*act)  (* 首匹配 *)
Definition step (p:list quad) (c:cfg) : option cfg           (* None=停机 *)
Fixpoint run (p:list quad) (c:cfg) (fuel:nat) : option cfg
Definition tleft (a:nat) (tp:tape) : tape                    (* 左移：lft 头入 cur *)
Definition tright (a:nat) (tp:tape) : tape
```

机器件：(1) step/run；(2) 书例（§5.2 图示程序逐行移植：一元后继/复制/加法）+ 逐输入对账；(3) 不停机例（无匹配死循环/横跳）；(4) **与 33 章 RM 对照表**（指令密度、状态显式性、停机语义：pc 不动 vs 无匹配）；(5) 通用机/对角文档线（停机不可判定——接 33 章 Ploop 实证与 57 章 Cantor）。Prolog：`tstep/trun`+可达配置 `findall` 搜索面。

- [ ] **Step 1: 读 PDF §5.1/§5.2**（抄录书例程序清单——图示程序按数学实体校读）
- [ ] **Step 2: ex34_turing.v 全绿**（纸带不变式首步定稿：lft 头=紧邻左侧格）
- [ ] **Step 3: Lean 镜像+账本；ex34_turing.pl（`END ====`）**
- [ ] **Step 4: docs/34-turing.md**（≥200 行；RM 对照表开场；页脚 33←→35）
- [ ] **Step 5: 章回归+commit** `feat(mathlogic): 批次二——新 34 章 图灵机：四元组与纸带（C/L/P）`

---

### Task 3: 批次三——新 35 章 递归函数与部分递归（C/L）

**Files:**
- Create: `examples/35_recfn/ex35_recfn.v`、`examples/35_recfn/ex35_recfn.lean`、`docs/35-recfn.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §3.2（数论函数；PDF 194-199）+ §3.3（PR/递归；PDF 199-217）+ §5.3（部分递归/不可解；PDF 350-366）+ §5.4（层级；PDF 366-380，文档线）。

**Interfaces（两通道同义）：**

```coq
Inductive prf : Type :=
| pz | ps | prj (n i:nat) | comp (f:prf) (gs:list prf) | prec (g h:prf).
Fixpoint peval (f:prf) (args:list nat) {struct f} : nat :=
  match f with
  | prec g h => match args with
                | [] => 0 | a::xs =>
                    (fix it (k:nat) := match k with            (* 局部 fix 递归于首变元 *)
                    | 0 => peval g xs | S m => peval h (m :: it m :: xs) end) a
                end
  | ... end                                                    (* 嵌套归纳 guard 预案 *)
Definition pr_add pr_mul pr_pred pr_sub pr_fact pr_sg : prf   (* 全部构造子组装 *)
Fixpoint ack (m n:nat) : nat                                   (* 三元倒递归或 fuel *)
Definition mu (f:nat->nat) (fuel:nat) : option nat             (* 有界最小化 *)
```

机器件：(1) `peval`+六书例函数**逐表对账**（add/mul 对 0..6、pred/sub 截断行为、fact）；(2) `pr_add_is_add : ∀a b, peval pr_add [a;b] = a+b`（归纳真证——本章最重证明件）；(3) Ackermann 求值+`ack3 : ack 3 n = 2^(n+3)-3` 对账（非 PR 对角 d(n)=φₙ(n)+1 文档线）；(4) μ 有界搜索 Option 语义+部分递归封包文档线；(5) Kleene 正规形/T 谓词/Σₙ 层级文档线（§5.3-5.4 讲透）+「PR⊂递归⊂TM 可计算」等价链接 33/34 章。

- [ ] **Step 1: 读 PDF §3.2/§3.3**（PR 定义链+书例函数清单）**+§5.3-5.4 扫读**
- [ ] **Step 2: ex35_recfn.v 全绿**（peval 的局部 fix 若被 guard 拒 → 测度/fuel 预案，EFT 五撞经验）
- [ ] **Step 3: Lean 镜像+账本（`let rec`/termination_by 预案）**
- [ ] **Step 4: docs/35-recfn.md**（≥200 行；「三台机器一台代数」开场：33 RM/34 TM/本章语法模型；页脚 34←→36）
- [ ] **Step 5: 章回归+commit** `feat(mathlogic): 批次三——新 35 章 递归函数与部分递归（C/L）`

---

### Task 4: 批次四——新 36 章 算术化与哥德尔编码 + 37 章不完备性升级（C/L ×2）

**Files:**
- Create: `examples/36_goedel/ex36_goedel.v`、`examples/36_goedel/ex36_goedel.lean`、`examples/37_incompleteness/ex37_incompleteness.v`、`examples/37_incompleteness/ex37_incompleteness.lean`、`docs/36-goedel.md`
- Modify: `docs/37-incompleteness.md`（重写扩充：原三步文档线保留+新机器件节）、`README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §3.4（算术化；PDF 217-230）+ §3.5（不动点+Gödel I；PDF 230-243）+ §3.6（Church；PDF 243-256）+ §3.7（非标准模型，文档线）。S1-S9 已在 spec 抄录。

**Interfaces：**

```coq
(* —— 36 章 —— *)
Inductive fm : Type := ...  (* 20 章最小式自包含复制 *)
Fixpoint gcode (t/f:…) : nat        (* 素数幂：2^tag·3^a·5^b… *)
Theorem gcode_inj : ∀ a b, gcode a = gcode b -> a = b   (* 素因子唯一——真证 *)
Definition beta (b c i:nat) : nat := b mod (1+(i+1)*c)
Definition benc (xs:list nat) : nat (* 选 (b,c) 使 beta 还原 xs *)
Theorem beta_rt : ∀ xs(短), bdec (benc xs) = xs          (* CRT 对账，长度≤8 *)
Definition csub (n x:nat) : nat    (* 编码层代换——小实例对账 *)
Example diag_fp : gcode (sub 自己) 型具体不动点现场
(* —— 37 章 —— *)
Definition rep_add : fm := x0+x1≡x2 型（S 语言）      (* 表示性样板 *)
Theorem rep_add_ok : N ⊨ rep_add ↔ 真加法（标准模型逐点验证）
Theorem tarski_diag : （有限句子空间上的对角现场——若真=枚举则矛盾的具体计算）
```

机器件 36：(1) gcode/inj；(2) β-函数 CRT 编解码往返；(3) csub 小实例；(4) 不动点具体现场。机器件 37：(1) **表示性样板**（add/mul/≤ 三公式的标准模型正确性——「每个 PR 函数可表示」定理的机器样板+文档线）；(2) Tarski 风格对角有限现场（借 57 章 Cantor 三化身手法）；(3) 不动点接 36；(4) Church（TM 停机→FOL 可满足归约链）、Rosser、Gödel II、非标准模型文档线；(5) 与 54 章（旧 50）PA 分工表：S1-S9 那边是定理、这边是语法对象。

- [ ] **Step 1: 读 PDF §3.4/§3.5/§3.6**（编码方案、β 引理、不动点引理、Church 归约）
- [ ] **Step 2: ex36_goedel.v 全绿**（mod/div 引理族对齐 stdlib）
- [ ] **Step 3: ex37_incompleteness.v 全绿**（表示性+对角现场）
- [ ] **Step 4: 两章 Lean 镜像+账本；docs/36-goedel.md+docs/37-incompleteness.md 重写**（各≥200 行；37 页脚 36←→38）
- [ ] **Step 5: 章回归+commit** `feat(mathlogic): 批次四——新 36 章 算术化与哥德尔编码 + 37 章不完备性升级为机器章（C/L）`

---

### Task 5: 批次五——新 62 章 公理集合论 NBG 与序数（C/L）

**Files:**
- Create: `examples/62_nbg/ex62_nbg.v`、`examples/62_nbg/ex62_nbg.lean`、`docs/62-nbg.md`
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §4.1（NBG 公理组 T/P/N/B1-B7/U/S/Inf/Reg/AC+类存在定理；PDF 256-282）+ §4.2（序数；文档线为主）+ §4.4（Hartogs 文档线）+ §4.5（AC 等价族；PDF 307-318）+ §4.6（MK/ZF/ST/NF/UR 对照；PDF 318-336）。

**Interfaces（两通道同义）：**

```coq
(* —— 有限集合项代数：原子+分支 —— *)
Inductive fset := at (n:nat) | br (xs:list fset).
Fixpoint fmemb (x y:fset) : bool                 (* y∈x：br xs 的成员表，外延 *)
Fixpoint beq (x y:fset) : bool                   (* 外延相等：互为成员 *)
Definition kur (x y:fset) := br [br [x]; br [x;y]]
Theorem kur_char : beq (kur x y) (kur u v) = true -> beq x u && beq y v = true  (* Prop 4.3 *)
Fixpoint vn (n:nat) : fset                       (* von Neumann：vn n = br [vn 0..n-1] *)
Definition is_ord (x:fset) : bool                (* 传递+∈-线序 *)
Theorem vn_ord : ∀ n, is_ord (vn n) = true
(* —— 有限论域类代数（成员表 cls=nat->bool，域 U=0..K-1）—— *)
Definition op_E op_inter op_compl (K:nat) : cls  (* B1 ∈-关系（表给定）/B2/B3 *)
Definition op_dom op_cross op_rot op_swap : cls->cls  (* B4-B7：序对用配对函数编码 *)
Theorem b2_ok : ∀ K u, (pair u v ∈ op_inter X) ⟺ (u∈X ∧ u∈Y) 型逐点验证（B1-B7 七件）
(* —— 有限 AC —— *)
Theorem fin_ac : (∀i<n, ∃x, f i ∈ A i) → ∃g, ∀i<n, g i ∈ A i   (* 结构归纳，零公理 *)
```

机器件：(1) `kur_char`（序对特征性质真证——本章最重件，需 beq 传递/同余引理族）；(2) `vn/is_ord`；(3) B1-B7 七算子逐点验证；(4) `fin_ac` 零公理账本；(5) NBG 公理即公式全列（T/P/N/B1-B7 打印展示+每条一句话语义）+类存在定理派生现场；(6) AC 等价族（良序/Zorn/选择函数）文档线+Hartogs 陈述；(7) MK/ZF/ST/NF 对照表文档节（NF 三反直觉）；(8) 诚实边界节：有限现场只验证构造子语义，真类/Russell 化身是无限现象（22 章 ZF 公理现场的姐妹篇）。

- [ ] **Step 1: 读 PDF §4.1 全+§4.5/§4.6 扫读**（公理组逐条抄录校读）
- [ ] **Step 2: ex62_nbg.v 全绿**（beq 同余引理族先做——kur_char 的前置）
- [ ] **Step 3: Lean 镜像+账本（fin_ac 打印零公理）**
- [ ] **Step 4: docs/62-nbg.md**（≥220 行；页脚 61←→63）
- [ ] **Step 5: 章回归+commit** `feat(mathlogic): 批次五——新 62 章 公理集合论 NBG 与序数（C/L）`

---

### Task 6: 批次六——深化五处（05 文档节 + 18/23/24/26 机器件，全用新号）

**Files:**
- Modify: `docs/05-hilbert.md`（L 对照+L1-L4/单公理文档节）
- Modify: `examples/18_folhilbert/ex18_folhilbert.{v,lean}`、`docs/18-folhilbert.md`（Rule C）
- Modify: `examples/23_completeness/ex23_completeness.{v,lean}`、`docs/23-completeness.md`（Lindenbaum）
- Modify: `examples/24_lscompact/ex24_lscompact.{v,lean}`、`docs/24-lscompact.md`（同构⇒初等等价+范畴性）
- Modify: `examples/26_secondorder/ex26_secondorder.{v,lean}`、`docs/26-secondorder.md`（二阶归纳范畴性）
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`

**书源：** §2.5/§2.6（A4/E4/Rule C；PDF 98-107）+ §2.7（Mendelson 完备性；PDF 107-118）+ §2.11/§2.13/§2.14（范畴性/初等扩张/超积；PDF 136-165）+ App A（PDF 404-420）。

**机器件：**
- **18（旧 17）Rule C**：`derC` 归纳（derives + 构造子 `RC Γ x φ c : derC Γ (exq x φ) -> derC Γ (sub c) -> …` 新常量侧条件）+ **derC 可靠性**（对有限结构语义归纳加一案）⇒ C 语义可容；句法消去（定理 2.11 线）文档线。A4/E4 可导规则两小件。
- **23（旧 22）Lindenbaum**：`lin_ext : list fm -> fuel -> list fm`（逐句加入保一致，一致性判定=02 章命题化 eval）；`lin_max`（对候选句表极大）+`lin_cons`（保持一致）两定理——命题片段级；Mendelson 版 Henkin 常量法与 EFT 见证式**逐点对照表**文档节。
- **24（旧 23）**：`iso_implies_eeq`（有限结构对+秩≤1 句集逐句同真值验证）+ 有限线序同构类计数（n 元线序全同构于标准链）；DLO ℵ₀-范畴、初等扩张、**超积/超幂/非标准分析**文档线（Łoś 陈述+有限主超滤=对角小件）。
- **26（旧 25）**：二阶归纳公理 `soInd : sofm`（∀X(X0∧∀k(Xk→X(Sk))→∀x Xx)）；在标准截段 (Z_n,S,0) 上 soeval=真（幂枚举验证）+在「N+尾巴」形状（Z_n⊎Z_m 断链）上=假——二阶把 N 钉死的机器脚印；一阶归纳只有可数条（S9 脚注）文档线。

- [ ] **Step 1: 读 PDF §2.5-2.7+§2.11/2.13/2.14+App A**
- [ ] **Step 2: 18/23/24/26 四件逐章全绿**（每章先 Coq 后 Lean；沿用各章既有定义，只增不删）
- [ ] **Step 3: 五 docs 增补节**（每章新增「Mendelson 深化」节，05 为纯文档节）
- [ ] **Step 4: 章回归（18/23/24/26/05 五章）+commit** `feat(mathlogic): 批次六——Mendelson 原位深化五处（05 L 对照/18 Rule C/23 Lindenbaum/24 范畴性/26 二阶归纳）`

---

### Task 7: 批次七——收官对账（63-wrapup 重写+四文件+全量回归+记忆）

**Files:**
- Modify: `docs/63-wrapup.md`（重写为第五轮收官章）、`README.md`、`PLAN.md`、`CHEATSheet.md`
- Create: `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-mendelson-expansion.md` + MEMORY.md 索引行

- [ ] **Step 1: docs/63-wrapup.md 重写**（≥260 行：十一篇图景总览+主线重述+总坑位清单（分通道）+十书导读（Mendelson 行做实）+**Mendelson 逐节对账表**（1.3/1.5→09、1.4/1.6→05 深化、2.5/2.6→18、2.7→23、2.11/2.13/2.14→24、3.1→54 对照、3.3→35、3.4→36、3.5/3.6→37、3.7→37 文档线、4.1-4.6→62、5.1/5.2→34、5.3/5.4→35 文档线、App A→26、App B→47-49 已覆盖、App C→收官彩蛋）+全书账本尾段（+本轮 21 单元））
- [ ] **Step 2: README/PLAN/CHEATSheet 终稿**（63 章表+179 计数；PLAN 状态行「63 章 179 单元全绿」；CHEATSheet 增「09/34/35/36/37/62 新坑（Mendelson 扩充）」节+深化四节）
- [ ] **Step 3: 全量回归** — `pwsh -NoProfile -Command '& ./build.ps1 -All'` → **179/179、0 SKIP、exit 0**
- [ ] **Step 4: 记忆落盘+commit** `docs(mathlogic): 批次七——Mendelson 扩充收官对账（63 章/179 单元全绿）`
  记忆内容：本轮收官、重排映射要点、实测坑 top5、互链 [[mathlogic-eft-expansion]] [[mathlogic-jongsma-expansion]] [[mathlogic-tutorial-build]]。

---

## Self-Review 记录

- Spec 覆盖：spec 二节 5 新章 ↔ Task 1/2/3/4(36)/5；37 升级 ↔ Task 4；深化五处 ↔ Task 6（新号口径 05/18/23/24/26）；重排 ↔ Task 0；对账四文件 ↔ Task 7。✓
- 占位符：无 TBD；每任务有确切文件、接口签名、验收命令、commit 消息；tactic 细节由编译迭代产生（历轮模式），接口即契约。✓
- 类型一致性：09 章 `fm` 与 37 章 `gcode` 消费的 fm 同形（20 章最小式，各章自包含复制纪律）；36 的 `csub/diag` 被 37 引用（同签名）；62 章 `fset/beq` 自封闭。✓
- 风险预置：peval 嵌套递归 guard（局部 fix→测度/fuel 预案写入 Task 3）；Lean 深匹配 native_decide（Task 1）；β-函数 mod/div 引理族（Task 4）；kur_char 前置 beq 同余族（Task 5）；33/34 交换的交叉引用由多重集校验兜底（Task 0）。✓
