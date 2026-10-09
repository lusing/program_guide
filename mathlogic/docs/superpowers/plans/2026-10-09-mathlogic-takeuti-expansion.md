# mathlogic 第十轮扩充：Takeuti《Proof Theory》92→99 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 Takeuti《Proof Theory》2e 扩充 mathlogic：七新章（17/28/36/37/61/64/65）+五深化+两注记+99 收官，全书 92→99 章、235→250 单元全绿。

**Architecture:** 块内生长重排（第八次）后按批次添加新章（每章 examples 双/三通道+docs 教程正文），深化扩展既有单元不加账，收官改写 92→99 收官章并五文件对账。

**Tech Stack:** Rocq 9.1 coqc（`/g/rocq/Rocq-Platform~9.1~2026.01/bin/coqc.exe`）/ Lean 4.25 裸 core / SWI-Prolog 10（仅 37 章）；验证 `pwsh -NoProfile -Command '& ./build.ps1 -Chapter NN'` 与 `-All`。

**Spec:** `docs/superpowers/specs/2026-10-09-mathlogic-takeuti-expansion-design.md`（含重排映射 GAPS={17,28,36,37,61,64,65}、七章五节结构、机器件清单、风险预案）。细读材料：`.scratch/tkt/digest_{A,B,C,D}.md`（含 OCR 存疑清单——取材前必读对应节）。

## Global Constraints

- 教程非代码罗列：docs 正文引用全部要讲的代码；每章 docs ≥200 行、文字多于代码（用户硬要求）。
- 每章 examples 自包含（不跨章 Require/imports；序数件 61 章自含重做 55 章同构底座）。
- Coq：`Example ... = true` 全真即判定通过；拷 build/coq/。Lean：裸 core 无 Mathlib、`#print axioms` 无账单（零公理件要交代）。Prolog：`:- encoding(...)` 物理第一行、入口 main、stdout ASCII、末行 `END ====`。
- OCR 残缺区一律〔⚠〕标注+回读 `G:\book\计算机\Proof Theory (Takeuti G.) (z-library.sk, 1lib.sk, z-lib.sk).pdf` 原图（PDF 页=书页+9）；机器面只覆盖已确证区（宁缺毋滥，87 章判例）。
- 书内交叉引用有八处原书排版错位（digest_A §10.6）：docs 引用以实际内容为准并注明原编号。
- 章号=示例号；docs/NN-slug.md；examples/NN_slug/exNN_slug.{v,lean,pl}；build.ps1 自动路由。
- Windows bash：`export PYTHONUTF8=1`；cd 粘滞坑（build 后回 /g/code/guide/mathlogic）。

---

### Task 0: 第八次全书重排 92→99

**Files:**
- Modify: `tools/renumber_k.py`（MAP 92→99、GAPS、NEW_TITLES）
- Create: `examples/17_intcomp/`、`examples/28_redtree/`、`examples/36_sopt/`、`examples/37_inflogic/`、`examples/61_gentzen/`、`examples/64_midsequent/`、`examples/65_beth/`（空占位目录+占位 .v）
- Modify: 全部 92 个 docs/NN-*.md 改名与相互链接、README/PLAN 频谱引用

**Interfaces:**
- Produces: 新章位 17=intcomp、28=redtree、36=sopt、37=inflogic、61=gentzen、64=midsequent、65=beth；旧章映射 old 1-16→1-16、17-26→18-27、27-33→29-35、34-55→38-59、56→60、57-58→62-63、59-92→66-99。

- [ ] **Step 1: 改造 renumber_k.py**：MAP 段、GAPS={17,28,36,37,61,64,65}、NEW_TITLES 七条（17 fitch→intcomp 直觉主义完备性、28 redtree 归约树、36 sopt 二阶证明论、37 inflogic 无穷逻辑、61 gentzen 一致性证明、64 midsequent 中矢列、65 beth 可定义性）；expect=set(range(1,100))-GAPS。
- [ ] **Step 2: 备份+跑脚本**：`git commit` 空树→`python tools/renumber_k.py`→检查 docs/examples/ROOT 改名与引用替换（`NN 章`后缀形式自动；括号编号"(NN)"与全角区间不映射——留收官手校清单）。
- [ ] **Step 3: 占位新章目录**（每目录一个最小占位 exNN_*.v：`Example placeholder : true = true. Proof. reflexivity. Qed.`，保证 build 可路由）。
- [ ] **Step 4: 全量回归**：`pwsh -NoProfile -Command '& ./build.ps1 -All'` 期望 **235/235 全绿 0 SKIP**（旧单元一个不少；若某章因文件名路由失败，查 build.ps1 的 NN 归档正则）。
- [ ] **Step 5: Commit**: `refactor(mathlogic): 批次〇——第十轮全书重排 92→99（Takeuti 轮）`

### Task 1: 新 17 章 intcomp 直觉主义完备性（C/L）

**Files:**
- Create: `examples/17_intcomp/ex17_intcomp.v` / `.lean`
- Create: `docs/17-intcomp.md`

**对书**: §8 p52-66（LJ' Def 8.12、Prop 8.13、Kripke Def 8.14、Prop 8.15-8.16、Thm 8.17、Ex 8.18；cHa Def 8.19-8.27）+Takeuti-Titani 8.28-8.31 文档线。取材前读 digest_A §5.6-5.8。

**Interfaces（两通道同名同语义）:**
```coq
(* 有限偏序: 世界=nat 上由链表给 le；力迫 kf : (nat->bool)赋值 -> poset -> kform -> nat -> bool *)
Inductive kform := kp (n:nat) | kneg (a:kform) | kand (a b:kform) | kor (a b:kform) | kimp (a b:kform).
Fixpoint kf (v:nat->bool) (le:nat->nat->bool) (a:kform) (w:nat) : bool
  (* kp: v 原子且单调沿 le 验证——预计算单调闭包或对可达世界全查 *)
  (* kneg/kimp: 对一切 w'>=w 检查（有限域全枚举 future w le w'） *)
  (* kand/kor: 点态 *)
Definition ikValid (le:nat->nat->bool) (n:nat) (a:kform) : bool  (* 全世界全赋值 *)
Definition kRefute (a:kform) : bool  (* 对小偏序族（2/3 世界 4 形）搜反例 *)
Definition upsetOf (S:list nat) : list nat  (* 上集 *)
Definition gdValid (a:kform) : bool  (* [0,1] 线序 cHa: Gödel-Dummett 语义（p=>q: p<=q?1:q 的有理格） *)
```
账例（必须全 true / 全枚举）：`ikValid` 对 `kimp (kp 0) (kp 0)`=true；`kRefute (kor (kp 0) (kneg (kp 0)))`=true（双世界反例）；`kRefute (kimp (kneg (kneg (kp 0))) (kp 0))`=true；`upsetOf` 上集封闭账；`gdValid (kor (kimp p q) (kimp q p))`=true（前线性）；`kRefute` 对 `kimp (kp 0) (kp 1)` 加权式传递检查；`kValid` vs `gdValid` 对照（ intuitionistic ⊂ GD：DP 公式 `(p→q)∨(q→p)` GD 有效而一般 Kripke 无 `kRefute`=false 检查器行为呈现）。

**docs/17-intcomp.md 五节**（spec §三.17）：一、LJ' 与临界推理；二、Kripke 力迫（b)-g) 不对称）；三、可靠性与典范反模型；四、cHa 与 Rasiowa-Sikorski（Lindenbaum 代数 |A| 与嵌入引理文档线）；五、Kripke↔cHa（[A] 上集族+E-相对化）+[0,1] 一瞥（〔⚠〕公理 4 残缺标注）。Ex 8.18 三条反模型做章末习题（机器面 kRefute 对第 (1) 条自动出反例）。

- [ ] Step 1: 写 ex17_intcomp.v（kf→ikValid→kRefute→upsetOf→gdValid 五件+账例）编译循环至绿
- [ ] Step 2: 写 ex17_intprop.lean 同构件（注意 Lean 的 `Seq`/`Poset` 命名冲突——用 `KPo`；def-by-pattern 内层 match 括号）至绿
- [ ] Step 3: `build.ps1 -Chapter 17` 双通道绿
- [ ] Step 4: 写 docs/17-intcomp.md（≥200 行，全部代码入正文）
- [ ] Step 5: Commit

### Task 2: 新 28 章 redtree 归约树（C/L）

**Files:**
- Create: `examples/28_redtree/ex28_redtree.v` / `.lean`
- Create: `docs/28-redtree.md`

**对书**: §8 p40-52（Def 8.1、Lemma 8.3 归约树、Thm 8.2；Prob 8.4/Cor 8.6 一瞥）。取材前读 digest_A §5.1-5.3。

**Interfaces:**
```coq
(* FOL 片段: 单变元谓词语言（个人常量 c0 与自由变元 a0..aN——「可用变元」机制） *)
Inductive tform := tp | tnot (a:tform) | tand | tor | timp (a b:tform) | tall (a:tform) | tex (a:tform).
(* 13 阶段: stage k mod 13 → 0/1 ¬左右 2/3 ∧ 4/5 ∨ 6/7 → 8/9 ∀ 10/11 ∃ 12 停/复制 *)
Definition rstage (k:nat) (s:sequent) : list sequent   (* 上矢列列表；对全部未归约主公式批量 *)
Fixpoint rtree (fuel:nat) (s:sequent) : rtree   (* RtLeaf 公理叶 | RtNode s [sub] | RtSat 饱和 *)
Definition rextract (t:rtree) : option countermodel  (* 全分支饱和→反模型: 前件=真/后件=假 *)
```
账例：命题重言 `tp→tp` 有限树（深度≤3 全封口）；`tnot tp ∧ tp ⇒` 矛盾封口；`tall (tex A(x,y)) ⇒` fuel 耗尽呈现非终止（RtSat 或深树——诚实展示+文档解释 ∀:left 用项例化/∃:left 新变元的交替）；反模型提取对 `⇒ tp ∨ tnot tp`（经典可证——树有限）；对 `tnot tnot tp ⇒ tp` 片段行为；`tall (timp (tp) (tp)) ⇒` 有限。

**docs/28-redtree.md 五节**（spec §三.28）：一、第三条路（vs 27 Henkin/08 tableau 亲缘）；二、13 阶段循环（表格 0-12）；三、两分支定理（Lemma 8.3 机制+∪Γ/∪Δ 反模型）；四、非终止与可判定片段；五、Feferman 极性插值与 Łoś-Tarski 一瞥（〔⚠〕）。

- [ ] Step 1-5: 同 Task 1 流程（v/lean/docs/commit）

### Task 3: 新 36 章 sopt 二阶算术证明论（C/L）

**Files:**
- Create: `examples/36_sopt/ex36_sopt.v` / `.lean`
- Create: `docs/36-sopt.md`

**对书**: §15-§21（p165-207；核心 §15 规则、§16.7/16.9 有限实例化、§17 相对化、§18 分层真值、§19 S₁S₂S₃、§20/21 文档线）。取材前读 digest_C 全文（含 §20 代入双重归纳+§21 三法对照表）。

**Interfaces:**
```coq
Inductive s2f :=                                  (* 二阶命题级片段（谓词变元 0 元+1 元） *)
  | svar (n:nat)                                  (* 命题变元 *)
  | papp (p:nat) (t:nat)                          (* 谓词变元 p 应用于个体变元（项=nat 编号） *)
  | sand | sor | simp (a b:s2f)
  | pforall (p:nat) (a:s2f) | pexists (p:nat) (a:s2f)  (* 二阶量词；一阶量词文档线 *)
Inductive bcr : list s2f * list s2f -> Prop       (* BC 规则: 公理 D⇒D + 八联结词 + 二阶 ∀:left(代任意谓词)/∀:right(本征) *)
Definition bcChk (d:bcder) : bool                 (* 推导树逐节点对账: mprems 按规则名算期望前件 *)
(* 相对化: relTr r0 (量词挂闸门) *)
Fixpoint rel (r0:s2f) (a:s2f) : s2f               (* ∀xA→r0⊃xAᶜ 命题级演示: papp→(r0 ⊃ ·) *)
Definition relClosed (r0:s2f) : bool              (* Φ_r 域闭包样本检查 *)
(* 模式=代入像 *)
Definition eqSchema : s2f    (* ∀p∀x∀y(x=y⊃(p x≡p y)) 的片段 *)
Definition indSchema : s2f   (* ∀p(p 0 ∧ ∀x(p x⊃p x') ⊃ ∀x p x) 命题级近似 *)
Definition instOf (sch:s2f) (v:s2f) : s2f         (* 抽象代入 *)
(* 分层真值 *)
Fixpoint tf (alpha:nat->bool) (a:tfml) (n:nat) : bool   (* F(α,n): n 层真值——深嵌入小公式 *)
Definition tExtend (alpha:...) : ...              (* E 扩张一层 *)
Definition tDef (a:tfml) : bool                   (* T=∃层 对小宇宙 *)
```
账例：`bcChk` 对「∀:left 代任意谓词实例」与「∀:right 本征变元」两推导对账（违反本征条件的一个反例=false）；`rel` 对 `∀x P(x)` 给 `∀x(r0(x)⊃P(x))` 型输出+量词全挂闸门账；`instOf indSchema (抽象 {|x| Q(x)∧R(x)})` 输出归纳公理实例；`tf`/`tExtend` 三条款逐层扩张账（∧/¬ 条款在 n+1 层由 n 层定义）。

**docs/36-sopt.md 五节**（spec §三.36）：一、BC 规则（左右对偶表）；二、comprehension 谱系（谱系表+模式三连+16.7 有限实例化语义读法+保守性三连）；三、相对化机器（翻译器+闸门+17.5 搬运+17.8/17.10）；四、分层真值定义（18.5-18.17 全链+52 章正反合）；五、S₁S₂S₃+Takeuti 猜想史话（Takahashi-Prawitz 语义法+半赋值+pre-Henkin 序对+三法对照表——digest_C §21 对照表直接转化）。

- [ ] Step 1-5: 同 Task 1 流程

### Task 4: 新 37 章 inflogic 无穷逻辑与决定逻辑（C/L/P）

**Files:**
- Create: `examples/37_inflogic/ex37_inflogic.v` / `.lean` / `.pl`
- Create: `docs/37-inflogic.md`

**对书**: §22-§24（p208-293；例 22.2 依赖选择、g.c.、Malitz 反例、DL/例 23.3、Gale-Stewart、开博弈例 24.14、Thm 23.34、BDL Prop 23.39）。取材前读 digest_D §2-§4。〔⚠〕打包规则 OCR 残缺：规则形以「语义可靠性+例 22.2/23.3 交叉」重构，docs 标注。

**Interfaces:**
```coq
(* 打包规则一步关系（γ=2 样本）: pand_left 打包 *)
Definition packAndL (up:list sequent) (down:sequent) : bool  (* [A1,B1...;A2,B2...] ⇒ [A1∧A2,...] *)
Definition packOrR (up:list sequent) (down:sequent) : bool
Definition heightOk (h:nat->nat) (d:mder) : bool   (* 条件 II: 本征变元高度>主公式变元 *)
(* Henkin 依赖量词与博弈 *)
Definition henkinSem (f:bool->bool->bool) : bool   (* (Vx∃u/Vy∃v) 的 Skolem 语义样本 *)
Fixpoint gsWin (depth:nat) (g:game) (pos:nat) : option player  (* 有限开博弈胜策略搜索——Zermelo *)
Definition adStep : bool                            (* →Q^f xA ∨ Q^f̄ x¬A 的玩具两步推导检查 *)
```
账例：`packAndL` 对 {[p,q⇒r],[s,t⇒r]} ⇒ [p∧s,q∧t⇒r] 的打包对账=true；`heightOk` 对例 22.2 依赖选择证明的 h(aₘ)=m 账=true（构造三节点小推导）；`henkinSem` 对 Mostowski 例（良基性表达）在两结构上的真假分离账；`gsWin` 4 深度开博弈（I 胜集={1∘∘∘} 型）双方判定——先手有策略/后手有策略两局；`adStep`=true。

Prolog 通道：`gsWin` 的回溯搜索版（?- main. 输出两局判定+`END ====`）。encoding 首行！

**docs/37-inflogic.md 五节**（spec §三.37）。注意与 38（旧 35 归结）、69（μ 演算）互指。

- [ ] Step 1: .v/.lean/.pl 三通道至绿（P 注意历轮五坑：encoding 首行/ASCII/END/main/行号）
- [ ] Step 2: build.ps1 -Chapter 37 三通道绿
- [ ] Step 3: docs/37-inflogic.md（≥200 行）
- [ ] Step 4: Commit

### Task 5: 新 61 章 gentzen Gentzen 一致性证明（C/L）

**Files:**
- Create: `examples/61_gentzen/ex61_gentzen.v` / `.lean`
- Create: `docs/61-gentzen.md`

**对书**: §11-§13（p86-155；§11 消除子文档线+可达性层谱、§12 o(S) 六条+五步归约+Wainer/Cichon、§13 可证良序文档线）+Ch5/6 尾节文档线。取材前读 digest_B 全文。**序数底座自含**（cnf/oeq/olt/oadd/自然和 osum 与 55 章同构、不跨章引用）。

**Interfaces:**
```coq
Inductive onf := cnf : list (onf * nat) -> onf.    (* Cantor 范式 *)
Definition oeq / olt / oadd / osum (自然和: 指数合并重排不吸收) / otower (ω_n(α): n 层塔)
(* o(S;P) 六条赋值 *)
Inductive pa : sequent -> rname -> list pa -> pa.  (* 小 PA 型推导: axP|wkL|andR|cutP|indP 五规则样本 *)
Fixpoint hgt (d:pa) : nat                           (* h(S): 下方 cut/ind 的 grade 最大值 *)
Fixpoint oassign (d:pa) : onf                       (* 六条: ax=1/wk 同/单前提+1/andR=osum/cut=otower(k−l)(osum μν)/ind=otower(k−l+1)(μ+1) *)
Definition indExpand (d:pa) (m:nat) : pa * onf      (* Step 2: ind 展开 m 链+前后序数 *)
(* 可达性层谱 *)
Fixpoint naccess (n:nat) (a:onf) : Prop             (* Def 11.3: 1-可达=可达; (n+1)-可达=∀ν n-可达→ν·ω^n n-可达 *)
Lemma nacc_down : ... Lemma naccess_lim : ...       (* 11.4/11.5 *)
Prop wk_accessible / prop_omega_k                   (* 11.7/11.9: ω_k (n−k)-可达 *)
(* Cichon *)
Definition gval (x:nat) (a:onf) : nat               (* G_x: 正规形 ω 逐位换 x——与 55 章 evalb 同构 *)
Definition pstep (x:nat) (m:nat) : nat              (* 基 x 抬基减 1 的数侧 *)
Lemma gval_pow : gval x (oexp ω a) = x ^ gval x a   (* 12.39 *)
Definition hardy (a:onf) (n:nat) : nat              (* h_α+基础列 fseq *)
Definition fseq (a:onf) (n:nat) : onf               (* {α}(n) 基础列 *)
Example cichon_acct : ... = true                    (* μx 轨道长 = h_α(n+1)−1 数值对账若干组 *)
```
账例：`oassign` 对六情形各一推导全账（ax=1、wk 不变、单前提 μ+1、andR 自然和不吸收账 (ω+1)#(ω+1)=ω·2+2、cut 塔账、ind 塔账）；`indExpand` 单例：ind(a) 展开成 F(0)→F(1)→F(2) 链后 o 从 ω_{k−l+1}(μ+1) 降到 ω_{k−l}(μ#m+q)——数值 onf 比较为 true；`naccess` 引理族四条 Prop 证明；`gval_pow` 对 α=ω/ω²/ω^ω 数值账；`cichon_acct` 对 α∈{ω, ω+1, ω·2, ω²} 的 m₀=26 型实例轨道长=Hardy−1 全对账；`wainerDom`（复合/原始递归样本被 h_{ω^ω} 支配的小数值账）。

**docs/61-gentzen.md 五节**（spec §三.61；§五尾节含 PH/Kruskal 机制地图+序数图一瞥全部陈述级〔⚠〕标注「文档线」）。

- [ ] Step 1-5: 同 Task 1 流程（本章最重；序数件先行——oeq/olt/osum/otower 四件先绿再 oassign）

### Task 6: 新 64 章 midsequent + 新 65 章 beth（C/L×2）

**Files:**
- Create: `examples/64_midsequent/ex64_midsequent.v` / `.lean`；`examples/65_beth/ex65_beth.v` / `.lean`
- Create: `docs/64-midsequent.md`；`docs/65-beth.md`

**对书**: 64 章=§6 Thm 6.4+Ex 6.7（p29-31/33-34）；65 章=§6 Def 6.10-Prop 6.12+Thm 6.14+Prob 8.4/Cor 8.6（p34-36/45-47）。读 digest_A §3.2/3.5/3.6/3.8/5.3。

**64 Interfaces:**
```coq
Inductive mder := mnode (s:sequent) (r:mrule) (subs:list mder).  (* 分层: 命题规则 prule | 量词规则 qrule *)
Definition qfree (s:sequent) : bool
Fixpoint orderOf (d:mder) : nat    (* 量词推理的 order=其下命题推理数; P 的 order=总和 *)
Definition isMid (d:mder) (ms:sequent) : bool  (* ms 在 d 中: 无量词+上命题/下量词 *)
Definition permStep (d:mder) : mder * bool     (* 换位: 量词推理与紧下命题推理交换→order 降 *)
Definition herbExpand (ms:sequent) : sequent   (* midsequent→Herbrand 实例化样本 *)
```
账例：一个 ∃∀ 前束矢列的两层 mder（上部命题到原子、下部量词）`isMid`=true；`orderOf` 数值账；`permStep` 对「∀:right 在 ∧:left 之上」换位后 order 下降账=true；`herbExpand` 对 `∃x∀y(P(x)∨¬P(y))⇒` 型样本产出 Herbrand 式。

**65 Interfaces:**
```coq
Definition implicitDef (ax:list (struct*fml)) (struct 族) : bool   (* 两结构上 ∀x̄(R↔R′) *)
Definition bethDemo : ...    (* 隐定义→插值子（复用 58 章 Maehara 思路自含小件）→显定义公式 *)
Definition robinsonAcct (s1 s2:list fml) : bool   (* 小宇宙: 两一致+无公共矛盾句→联合一致 *)
Definition harropPos (a:fml) : bool               (* 极性条件 (*): ∨/∃ 在 ¬ 辖域或 → 左辖域 *)
Definition dpCheck (a:fml) : bool                 (* DP 验证: 用小 g4 式搜索器或 wlojc *)
```
账例：`implicitDef` 在两元素结构族上真账；`bethDemo` 端到端出显定义公式=期望值；`robinsonAcct` 正反两账（相容对=true；冲突对=false 呈现）；`harropPos` 对 Harrop 公式/非 Harrop 公式各样本；`dpCheck` 对 ¬(A∧B) 型 Harrop 前提的 DP 验证+Thm 6.14(2) 五条非 LJ 矢列的不可证账。

**docs**: 64 四节/65 五节（spec §三.64/65）。两章 docs 与 63（插值）、38（Herbrand）互指。

- [ ] Step 1: 64 章 v/lean 至绿→Step 2: build→Step 3: docs→Step 4: 65 章同流程→Step 5: 一并 Commit

### Task 7: 五深化+两注记（既有单元扩展不加账）

**Files:**
- Modify: `examples/60_cutelim/ex60_cutelim.{v,lean}`（原 56 章文件随重排已改名——以实际路径为准）+`docs/60-cutelim.md`
- Modify: `examples/29_seqfol/…`（原 25 章等词章——重排后 29？**以 Task 0 后实际章号为准**：old 25→新 29）+docs
- Modify: `examples/57_epsilon/…`（old 55→新 57）+docs
- Modify: `docs/54-truth.md`（old 52→新 54）注记节；`docs/40-herbrand.md`（old 36→新 40）注记节

**内容**:
1. **mix 版切消**（60 章）：`mixSim`（cut+contraction↔mix 双向模拟小推导账）+`rankOf`（thread 连续段计数：对三节点样本算 rank_l/rank_r）+docs 深化节（mix 的「一次删光」与 2.1.2 推过机制+与 G0 版对照表）。
2. **等词切消**（29 章）：`eqSeq`（等词公理矢列账：s=t→t=s 等三律推导）+`cutKind`（essential/inessential 分类检查）+docs 深化节（Thm 7.6 机制：等词 cut 保留无害）。
3. **基础列与半共轭**（57 章）：`fseq`（{α}(n) 计算+Lemma 12.39 G_x(ω^α)=x^{G_x(α)} 数值账——与本章既有 evalb 对接呈现「同一函数的两个化身」）+docs 深化节。
4. **52→54 真值分层注记**：docs 节「S₁ 内可定义 PA 真（→新 36）与 PA 内不可定义的分层相容」。
5. **36→40 Herbrand 互指注记**：docs 节「Herbrand 宇宙（本话语义侧）与中矢列定理（→新 64 证明侧）」。

- [ ] Step 1: 三机器深化逐章至绿（-Chapter 各自）
- [ ] Step 2: 两 docs 注记节
- [ ] Step 3: Commit

### Task 8: 收官——99 章合拢+五文件对账+全量回归+记忆

**Files:**
- Modify: `docs/99-wrapup.md`（原 92 收官随重排；十轮合拢改写）
- Modify: `README.md` / `PLAN.md` / `CHEATSheet.md` / `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-takeuti-expansion.md` + `MEMORY.md`

**内容**:
1. **99 收官**：频谱括号编号全面手校（"(NN)"式不被脚本映射——第九轮教训清单复用：DPLL/CTL/LTL/μ/自动机/霍尔/不完备等全部旧号逐条 grep 核对）；新增第十轮新章线（17/28/36/37/61/64/65）进频谱与导读；新增「三点十三 第十轮：Takeuti 逐章对账」节（六章对账表+独特贡献+新坑清单）；十书→十四书导读表加 Takeuti 行。
2. **README**：第十轮状态段+250 口径+七新章表行+99 收官行。
3. **PLAN**：十四书标题+十轮状态+Takeuti 行+七新章行+第九轮口径历史行。
4. **CHEATSheet**：新增「Takeuti 轮新章坑位」节（执行中实测绘制——预计含：打包规则 OCR 重构法、oassign 六条赋值实现坑、Lean 命名冲突续录、rtree fuel 边界、序数自然和不吸收等）。
5. **全量回归**：`build.ps1 -All` 期望 **250/250 全绿 0 SKIP**。
6. **记忆落盘**：mathlogic-takeuti-expansion.md+MEMORY.md 索引行。

- [ ] Step 1: 收官章改写；Step 2: README/PLAN/CHEATSheet；Step 3: 全量回归 250/250；Step 4: 记忆；Step 5: Commit `feat(mathlogic): 批次四——新 64/65 章+五深化+两注记+99 收官十轮合拢（C/L/P）`

---

## Self-Review

1. **Spec 覆盖**：七章=Task 1-6（64/65 合于 Task 6）；重排=Task 0；五深化两注记=Task 7（其中 52/36 注记在 Task 7 步 2）；收官五文件=Task 8。序数图/反射/BDL 直接证明等文档线全部落在 Task 5 docs 尾节与 Task 4 docs 五节——spec「文档线」要求全覆盖。✓
2. **占位扫描**：无 TBD/TODO；每任务给出数据结构与账例（执行者零上下文可做）。Task 7 中「以 Task 0 后实际章号为准」的旧章号映射已给出换算规则（old 25→29、old 36→40、old 52→54、old 55→57、old 56→60）。✓
3. **类型一致性**：kf/ikValid/kRefute（17）；rstage/rtree/rextract（28）；bcChk/rel/instOf/tf（36）；packAndL/heightOk/gsWin（37）；oassign/naccess/gval/hardy（61）；isMid/orderOf/herbExpand（64）；implicitDef/bethDemo/harropPos（65）——跨章无同名冲突；onf 序数在 57（旧 55）与 61 章各自文件内自含定义（同构不互引）。✓

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-10-09-mathlogic-takeuti-expansion.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
