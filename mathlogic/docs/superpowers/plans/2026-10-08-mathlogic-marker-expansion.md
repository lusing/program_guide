# mathlogic Marker 全谱扩充实施计划（63→73 章 / 193 单元）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 David Marker《An Invitation to Mathematical Logic》(GTM 301) 完成第六轮书本扩充：10 新章（C/L，26/47 另有 P）+ 3 原位深化 + 全书重排 63→73。

**Architecture:** 块内生长——模型论 4 章插 25 后、可计算性 3 章插 39 后、不完备深化 3 章插 44 后；每章「docs 教程为纲 + examples 机器件」双件；零公理纪律（Coq 无 Axiom/Admit）。

**Tech Stack:** Coq=Rocq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe -q`，先拷贝到 build/coq/）；Lean 4.25 裸 core（无 mathlib：多项式恒等用系数表反射 + native_decide）；Prolog=SWI 10（`swipl -q -f 文件 -g main -t halt`，stdout 须含 `END ====`）。

**Spec:** `docs/superpowers/specs/2026-10-08-mathlogic-marker-expansion-design.md`

## Global Constraints

- 零公理：Coq 件 `Print Assumptions` 无 Axiom/Admit；省略时在章末「诚实记账」注明。
- 教程为纲：每章 docs ≥200 行、文字多于代码；所有讲解代码在正文引用（文件名+定理名）。
- 章件命名：`examples/NN_slug/exNN_slug.{v,lean,pl}`；docs `NN-slug.md`；标题行 `# 第 NN 章 …`。
- 新章 slug（入册后不得改）：26 `categoricity`、27 `ultraproduct`、28 `quantelim`、29 `realclosed`、40 `undecidable`、41 `hierarchy`、42 `degrees`、45 `diophantine`、46 `epsilon`、47 `models`。
- 每任务一个 commit，消息末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 全量回归：`pwsh -NoProfile -Command '& ./build.ps1 -All'` 全绿 0 SKIP exit 0。
- 书源页偏移恒定 +16（book p → pdf index = p+16−1）；公式连字乱码按数学实体校读。

---

### Task 0: 全书重排 63→73（批次〇）

**Files:**
- Create: `tools/renumber_k.py`
- Rename: 38 个章目录/文档（映射见下）+ 目录内全部源文件（含 .agda/.thy/.sml/.agdai 清理）
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`、`examples/ROOT`（session 名 MLNN）

**Interfaces:**
- Produces: 空位 26-29/40-42/45-47；旧章新号位全部内容不变可编译。

MAP（旧→新）：`{26:30, 27:31, 28:32, 29:33, 30:34, 31:35, 32:36, 33:37, 34:38, 35:39, 36:43, 37:44, 38:48, 39:49, 40:50, 41:51, 42:52, 43:53, 44:54, 45:55, 46:56, 47:57, 48:58, 49:59, 50:60, 51:61, 52:62, 53:63, 54:64, 55:65, 56:66, 57:67, 58:68, 59:69, 60:70, 61:71, 62:72, 63:73}`
GAPS = `{26,27,28,29,40,41,42,45,46,47}`；NEW_TITLES 用上文 slug 表（页脚重生成需要）。

- [ ] **Step 1: 写 `tools/renumber_k.py`**——从 `tools/renumber_m.py` 复制改造：
  1. 换 MAP/GAPS/NEW_TITLES；
  2. **新增目录内文件改名**（Mendelson 轮 130 件教训）：对 `examples/NN_slug/` 内每个 `exNN_slug.*` 改 `exMM_slug.*`；`.agdai` 等编译产物直接删除；两阶段（`.tmp~`）防碰撞，**按旧号降序**执行；
  3. 文本替换 PATTERNS 沿用九类（zh章组/zh章/enum章/doc文件/ex文件/目录名/session/hol4/链接标签）——单遍有序，替换文本不被后续重匹配；
  4. 页脚重生成改为 73 序（空位章用 NEW_TITLES）；
  5. 校验：docs 章号无重复、GAPS 为空、`oldpairs` 残留为 0。
- [ ] **Step 2: dry-run 审计**——`python -I tools/renumber_k.py`，逐类看替换统计；抽查 docs/24-lscompact.md（含「iso_eeq」引用 34 章旧号处）、README 表、ex50 五文件改名计划。
- [ ] **Step 3: `--apply` 执行**后 `grep -rn "ex33_\|ex34_\|第 33 章\|第 37 章" docs/ README.md PLAN.md` 复核——旧号引用应全部指向新号位语义（37=RM、44=不完备）。
- [ ] **Step 4: 全量回归**——`pwsh -NoProfile -Command '& ./build.ps1 -All'`；171 单元全绿 0 SKIP。
- [ ] **Step 5: Commit** `refactor(mathlogic): 批次〇——全书重排 63→73（Marker 轮，空位 26-29/40-42/45-47）`

### Task 1: ★26 完备理论与范畴性（C/L/P）

**Files:** Create `docs/26-categoricity.md`、`examples/26_categoricity/ex26_categoricity.{v,lean,pl}`

**Interfaces:**
- Consumes: 24 章 `trueZn`/结构求值器模式（`ex24_lscompact.v` 的 evf/interp_rel）；34 章（旧 24）iso_eeq 思想。
- Produces: `veciso`（F_p 空间同构）、`ax_check`（多项式单满射对账）、`graph_frac`（0-1 律频率）。

**书内容（提炼入 docs，全自包含）**：完备理论/公理化定义（Def 5.6 区）；DAG κ-范畴（Prop 5.8：Q-向量空间维数定同构）；ACF_p κ-范畴（Prop 5.9：超越度）；**Vaught 测试**（Th 5.10）及「无有限模型」侧条件反例（阶 2 群）；完备+RE 公理 ⟹ 可判定；**Ax 定理**（Th 5.16：单射多项式 C^n→C^n 满射，有限域+紧致性传递证明路线）；back-and-forth 与 DLO 可数范畴性；**随机图 0-1 律**（Th 5.21 区）。

- [ ] **Step 1: docs 教程**（≥260 行）：上述内容 + 机器件讲解 + 与 24/25 章衔接。
- [ ] **Step 2: Coq 件 `ex26_categoricity.v`**（核心骨架）：

```coq
(* F_p 上向量空间同构 ⟺ 同维数（DAG 范畴性的有限影子） *)
Definition vpoly (p k : nat) : list nat := seq 0 p.   (* 域元素表 *)
Definition vzero (k : nat) : list nat := repeat 0 k.
Definition vadd (p k : nat) (u v : list nat) : list nat :=  (* 逐分量 mod p *)
  map2 (fun a b => (a + b) mod p) u v.
Definition vsmul (p : nat) (a : nat) (v : list nat) : list nat :=
  map (fun b => (a * b) mod p) v.
(* 显式双射：基 e0,e1 ↦ w0,w1（线性无关向量） *)
Definition iso2 (p : nat) (w0 w1 : list nat) (v : list nat) : list nat :=
  (* v = a·e0 + b·e1 ↦ a·w0 + b·w1，分量 a=nth 0 v, b=nth 1 v *)
  vadd p 2 (vsmul p (nth 0 v 0) w0) (vsmul p (nth 1 v 0) w1).
Example iso2_bij_p3 : (* F_3^2 上 w0=[1;0],w1=[1;1]：iso2 双射 *)
  forallb (fun v => existsb (fun u => Bool.eqb (iso2 3 [1;0] [1;1] u) v)
            (list_prod (seq 0 3) (seq 0 3) |> map (fun ab => [fst ab; snd ab])))
    (...) = true.
Proof. reflexivity. Qed.
(* 更简单可证的表述：map (iso2 …) 全表 = 全表（排列判定） *)
Example iso2_perm : NoDup (map (iso2 3 [1;0] [1;1]) Vs) = true.
```

Ax 有限域脚印：

```coq
(* 多项式映射 F_p^2→F_p^2 的表值求值（多项式=系数表） *)
Fixpoint pevalc (cs : list nat) (x : nat) : nat :=  (* Horner mod p *)
  match cs with [] => 0 | c :: rest => (c + x * pevalc rest x) mod p end.
Definition pmap (p : nat) (fx fy : list (list nat)) (x y : nat) : nat * nat :=
  (pevalc fx x + p * pevalc fy y, 0). (* 改为二元组正规写法见实现 *)
(* 单射 ⟹ 满射：有限域上鸽笼原理的逐表验证 *)
Example ax_f5_x3 :  (* x↦x³ 在 F_5 单射（gcd(3,4)=1） *)
  forallb (fun x => negb (existsb (fun y => andb (Nat.eqb (pevalc [0;0;0;1] x) (pevalc [0;0;0;1] y))
    (negb (Nat.eqb x y))) (seq 0 5))) (seq 0 5) = true.
Proof. reflexivity. Qed.
Example ax_f7_x3_not_inj :  (* x↦x³ 在 F_7 非单射（3 | 6）：1³=2³=1 … 现场对账 *)
  existsb (fun xy => andb (Nat.eqb (pevalc [0;0;0;1] (fst xy)) (pevalc [0;0;0;1] (snd xy)))
    (negb (Nat.eqb (fst xy) (snd xy)))) (list_prod (seq 0 7) (seq 0 7)) = true.
Proof. reflexivity. Qed.
```

0-1 律：

```coq
(* n 点图边位向量枚举；扩张公理 σ1（无孤立点）频率 *)
Fixpoint bits (m : nat) : list (list bool) := (* m 位全部 0/1 串 *)
  match m with 0 => [[]] | S m' => map (cons false) (bits m') ++ map (cons true) (bits m') end.
Definition edges (n : nat) (b : list bool) : nat -> nat -> bool := (* 编号对查位 *)
  fun i j => nth (pairidx n i j) b false.
Definition no_isolated (n : nat) (b : list bool) : bool := ...
Example frac_sigma1 : (* n=2..5 频率 [0.5;0.25;0.1875;0.15234…] → 递减趋 0（补群公式版趋 1） *)
  map (fun n => frac_true (map (no_isolated n) (bits (n*(n-1)/2)))) [2;3;4;5] = [...] .
Proof. reflexivity. Qed.
```

- [ ] **Step 3: Lean 镜像** `ex26_categoricity.lean`（同件；`decide`/`native_decide` 按体量）。
- [ ] **Step 4: Prolog 面** `ex26_categoricity.pl`：n≤5 全图枚举+σ₁/σ₂ 计数+自编 boolean 打印频率表，`END ====`。
- [ ] **Step 5: 验证**：拷 .v 到 build/coq/ 后 coqc；`lean ex26_categoricity.lean`；swipl；全量回归。
- [ ] **Step 6: Commit** `feat(mathlogic): 批次一——新 26 章 完备理论与范畴性（C/L/P）`

### Task 2: ★27 超积与 Łoś 定理 + ★28 量词消去（批次二）

**Files:** Create `docs/27-ultraproduct.md`、`examples/27_ultraproduct/ex27_ultraproduct.{v,lean}`、`docs/28-quantelim.md`、`examples/28_quantelim/ex28_quantelim.{v,lean}`

**Interfaces:**
- Consumes: 24 章 evf 有限结构求值器；16 章（深化后）嵌入术语。
- Produces: `ultrafilters_on`（有限集全枚举）、`los_principal`（主超滤 Łoś）、`dlo_qe`（DLO 量词消去函数）、`has_root_Fp`。

**27 章书内容**：滤子/超滤定义与主超滤；**Łoś 定理**（超积保持一阶真值；第 (4) 步 ¬ 情形是唯一用超滤性处）；超积证紧致性（Th 6.18 前节路线）；**超幂与初等嵌入**（Prop 6.17：对角元 [id] 非标准）；Keisler–Shelah（陈述）；Ax–Kochen/Eršov 一瞥；超自然数（Th(N) 模型含无限元素）。

**28 章书内容**：QE 定义；**判据 Th 7.7**（子结构保持 ⟺ QE）与 **Cor 7.9 测试**；一次一个量词 Lemma 7.8；DAG 的 QE；**ACF 的 QE**（Euclid 除法+引理 7.10 区）；**强极小性**（Def 7.18 区：一维可定义集有限或余有限）；模型完备性。

- [ ] **Step 1: docs 两章教程**（各 ≥240 行）。
- [ ] **Step 2: `ex27_ultraproduct.v` 核心件**：

```coq
(* I=[0;n) 的子集 = 位串；滤子/超滤判定 *)
Definition subsetn (n : nat) (b : list bool) (i : nat) : bool := nth i b false.
Definition is_filter (n : nat) (F : list (list bool)) : bool :=
  (* 含 I、不含 ∅、上闭、交封闭 *)
Definition is_ultra (n : nat) (F : list (list bool)) : bool :=
  andb (is_filter n F) (forallb (fun b => orb (mem b F) (mem (map negb b) F)) (bits n)).
(* 旗舰①：n=3 全枚举——恰 3 个超滤，全主超滤 *)
Theorem ultra_principal_3 :
  filter (fun F => is_ultra 3 F) (all_families (bits 8)) =  (* 2^8=256 族 *)
  map principal [0;1;2].
Proof. reflexivity. Qed.  (* vm 级穷举 *)
(* 旗舰②：主超滤 Łoś——ultraprod 在主超滤= 第 i 因子 *)
Definition ev_atom (Ms : list stru) (phi : fm) (i : nat) : bool := ...
Example los_principal : forallb ... = true. Proof. reflexivity. Qed.
(* 旗舰③：Fréchet 滤子 Łoś 失败现场——Z_n 链上「x 是偶数阶」型句子 *)
(* 旗舰④：超幂对角元——截断 N 上 [id] 最终大于每个常函数 *)
Example diag_dominates :
  forallb (fun k => forallb (fun i => (i >? k)) (seq k 8)) (seq 0 8) = true.
Proof. reflexivity. Qed.
```

- [ ] **Step 3: `ex28_quantelim.v` 核心件**：

```coq
(* DLO 量词消去：单变量存在式 ∃z(文字合取) → 无量词等价 *)
Definition lit := (cmp (* lt|eq|ne *) * (side (* z vs 参数 *)) * nat (* 参数编号 *))%type.
Fixpoint dlo_qe1 (ls : list lit) : option qf := (* 区间推理：矛盾检测 *)
  ...  (* ∃z(x<z∧z<y) ↦ Some(x<y)；z<z ↦ None(假)；无约束 ↦ Some(真) *)
(* 对账器：稠密样本 D={0,1,…,20}（承 24 章 Z_n 求值）上逐赋值验证 qe 前后同值 *)
Example dlo_qe_sound_samples :
  forallb (fun f => Bool.eqb (ev_ex f) (ev_qf (dlo_qe1 f))) sample_forms = true.
Proof. reflexivity. Qed.
(* ACF：F_p[x] 多项式除法 + 根存在 *)
Fixpoint pdivmod (p : nat) (f g : list nat) : list nat * list nat := ...
Definition has_root_Fp (p : nat) (f : list nat) : bool :=
  (* f 与 x^p−x 的 gcd ≠ 1 *)
Example has_root_f3 : map (has_root_Fp 3) [[0;0;1]; [1;0;1]; [0;1;1]; [2;0;1]]
  = [true; false; true; true].   (* x²、x²+1、x²+x、x²+x+2 over F_3 *)
Proof. reflexivity. Qed.
(* 强极小性影子：F_9 = F_3[t]/(t²+1) 上多项式零点集「有限或余有限」枚举对账 *)
```

- [ ] **Step 4: Lean 镜像两件。**
- [ ] **Step 5: 验证 + Commit** `feat(mathlogic): 批次二——新 27 章 超积与 Łoś + 28 章 量词消去（C/L）`

### Task 3: ★29 实闭域与 o-minimality + 深化 16 章（批次三）

**Files:** Create `docs/29-realclosed.md`、`examples/29_realclosed/ex29_realclosed.{v,lean}`；Modify `docs/16-folsem.md`、`examples/16_folsem/ex16_folsem.v`

**Interfaces:**
- Consumes: 28 章 `dlo_qe`（区间结构）；stdlib QArith（Coq）。
- Produces: `polyQ`（Q 系数多项式）、`ivt_bisect`（二分求根）、`sos_verify`（SOS 恒等系数反射）、`interval_union_of`（区间结构判定）。

**书内容**：有序域/实闭域（奇次多项式有根+正元有平方根，附录 C 对照）；**RCF 量词消去**（Tarski，证明 doc 级）；**半代数集**（一维=有限区间并）；**o-minimality**（Def 8.23；Cor 8.24 RCF o-minimal ⟹ **Z 在 R 中不可定义**——tame 叙事主轴）；分段连续（Lemma 8.25/Cor 8.26）；**Hilbert 第 17 问题**（Th 8.22：正半定有理函数=有理函数 SOS 和；Artin–Schreier 定理陈述；Robinson 模型论证明路线）。

- [ ] **Step 1: docs 29 章教程**（≥260 行， tame vs wild 叙事）。
- [ ] **Step 2: `ex29_realclosed.v`**：
  1. `polyQ` 加乘（`Q` 系数表）；`pevalQ`；
  2. `ivt_bisect f a b depth`：符号相反区间二分 20 层，端点收缩验证（Q 精确算术）；
  3. 半代数区间结构：`signtable`（网格符号变化点）+ `interval_union_of`（网格子集是否为区间并）——枚举若干 Boolean 组合验证；
  4. o-minimal 有限影子：有限稠密链上无量词可定义集全枚举 → 全部区间布尔组合（`rfl` 级）；
  5. **旗舰——Motzkin 多项式**：`M(x,y) = x⁴y²+x²y⁴−3x²y²+1`；
     a. `.scratch` 用 Python sympy 求显式有理函数 SOS 分解（查 Reznick 已知式亦可）；
     b. 分母通分后转为多项式恒等式 `M·D² = Σ hᵢ²`；
     c. Coq 系数反射验证：`vm_compute` 展开两侧系数表相等 + `poly_ext`（系数相等 ⟹ 多项式相等，归纳证明，零公理）；
  6. `Print Assumptions` 清账。
- [ ] **Step 3: Lean 镜像**（系数表反射 + `native_decide` 网格抽查 M≥0）。
- [ ] **Step 4: 深化 16 章**（Marker Ch2）：docs 加「嵌入、初等映射与图方法」节（≥60 行：嵌入 vs 初等嵌入 vs 同构三分、Diag/初等图、图扩充引理 Lemma 7.5 陈述与有限示意）；`ex16_folsem.v` 追加 `embed_preserves_qf`（无量词式在子结构保持——有限结构枚举验证）。
- [ ] **Step 5: 验证 + Commit** `feat(mathlogic): 批次三——新 29 章 实闭域与 o-minimality + 16 章嵌入深化（C/L）`

### Task 4: ★40 通用性与不可判定性 + ★41 CE 集与算术层级（批次四）

**Files:** Create `docs/40-undecidable.md`、`examples/40_undecidable/ex40_undecidable.{v,lean}`、`docs/41-hierarchy.md`、`examples/41_hierarchy/ex41_hierarchy.{v,lean}`

**Interfaces:**
- Consumes: 37 章 RM（`radd/rdel/rife/rprint/rhalt`、`step/run`）；43 章 `cp` 配对。
- Produces: `enc/dec`（程序↔nat）、`urun`（通用机）、`rh_witness`（递归定理见证）、`kcomplexity`（Kolmogorov）。

**40 章书内容**：通用机；**停机问题不可判定**（K 对角）；**index set 与 Rice 定理**（Th 10.11：可计算 index set 只有 ∅/ℕ）；**Church 定理**（FOL 有效性不可判定：θ_P 构造路线）；**Kleene 递归定理**（Th 10.12：任意全可计算 f 有不动点 e，φ_e=φ_{f(e)}）+ 参数化引理。

**41 章书内容**：CE 集与 W_e；**算术层级 Σₙ/Πₙ/Δₙ**；具体集归属（K∈Σ₁、Tot∈Π₂、Fin∈Σ₂、Comp∈Σ₃，Ex 11.19–22）；**Γ-完全集**（Def 11.23；K Σ₁-完全、Tot Π₂-完全、Fin Σ₂-完全）；通用集+**层级严格性**（对角）；**Kolmogorov 复杂度**（Def 11.29：K(x)≥|x| 为随机；Prop 11.30 非随机集 CE；Prop 11.31 随机数存在；Prop 11.32 随机数集 Π₁ 非可计算——Chaitin 不完备现象衔接 44 章）。

- [ ] **Step 1: docs 两章教程**（各 ≥260 行）。
- [ ] **Step 2: `ex40_undecidable.v`**：

```coq
(* 编码：指令→nat（cp 复合），程序=指令表→nat（迭代 cp） *)
Definition enc_inst (i : inst) : nat := ... Definition dec_inst (k : nat) : inst := ...
Definition enc_prog (p : prog) : nat := ... Definition dec_prog : nat -> prog := ...
(* 通用机：直接解释编码 *)
Definition ustep (e : nat) (c : cfg) : cfg := step (dec_prog e) c.
Fixpoint urun (e : nat) (x : nat) (fuel : nat) : option cfg := ...
(* ① 对角现场：对「声称全部停机」的 h，构造 dh：urun dh dh 永不停（编译进 h 分支） *)
Example diag_htrue_diverges :
  forallb (fun s => match urun 42 42 s with Some _ => false | None => true end)
    (seq 0 20) = true.   (* 42 := enc(「if h(e,e)=1 then 自转 else halt」的 h=恒真实例=纯自转程序) *)
Proof. reflexivity. Qed.
(* ② Rice 影子：语法不同、语义相同的两个程序在「行为谓词」上同值 *)
Example rice_shadow : forallb (fun x => Nat.eqb (out_of (urun e1 x 50)) (out_of (urun e2 x 50)))
  (seq 0 10) = true.   (* e1/e2 = id 的两种写法 *)
Proof. reflexivity. Qed.
(* ③ 旗舰——递归定理见证：按书证明显式构造 e，验证 φ_e = φ_{f(e)} *)
Definition kleene_e (f : nat -> nat) : nat :=
  enc_prog (compile_diag f).   (* 「input y: z := urun-代码(p,p) 字面内嵌; output urun z y」 *)
Theorem rh_witness : forall (f : nat -> nat) (y s : nat),
  urun (kleene_e f) y s = urun (f (kleene_e f)) y s.  (* 两边逐步同一 *)
Proof. ... Qed.   (* 构造使两解释路径同构：归纳/反射 *)
(* quine 实例：f := g = code(output-x) ⟹ e 输出 e *)
Example quine_demo : out_of (urun (kleene_e g) 0 100) = [kleene_e g].
Proof. reflexivity. Qed.
```

（`rh_witness` 若逐步同构证明过重：退为「对全部测试输入同输出」的 `forallb` 版本 + 逐步等价记文档级——诚实记账。）

- [ ] **Step 3: `ex41_hierarchy.v`**：K_s 阶段枚举器；`Tot/Fin` 见证函数与样本对账（id 程序 ∈ Tot、自转 ∉ Tot）；多一归约样本验证；**Kolmogorov**：`kcomplexity x bound`（描述=编码对，urun 输出 x）；计数论证 `exists_random`（M≤10 枚举鸽笼）；非随机集枚举器。
- [ ] **Step 4: Lean 镜像两件。**
- [ ] **Step 5: 验证 + Commit** `feat(mathlogic): 批次四——新 40 章 通用性与不可判定 + 41 章 算术层级（C/L）`

### Task 5: ★42 图灵度与优先法 + ★45 Hilbert 第十问题（批次五）

**Files:** Create `docs/42-degrees.md`、`examples/42_degrees/ex42_degrees.{v,lean}`、`docs/45-diophantine.md`、`examples/45_diophantine/ex45_diophantine.{v,lean}`

**Interfaces:**
- Consumes: 40 章 `urun`（oracle 化改造）；43 章 `cp`；29 章系数反射法。
- Produces: `ostep`（oracle 机）、`kp_build`（Kleene–Post 构造）、`pell_next`、`fib_pair`。

**42 章书内容**：Turing 归约 A≤_T B 与跳跃 X′=K^X；Post 定理陈述（Δ_{n+1}=≤_T 0⁽ⁿ⁾）；**Kleene–Post 不可比较度**（有限延伸构造）；König 引理（Prop 12.25 左极路径）；**低基定理**（Jockusch–Soare，陈述）；**Friedberg–Muchnik**（Th 12.31 有穷损害优先法）+ 最小对（Th 12.33 陈述）。

**45 章书内容**：Diophantine 集；**Diophantine ⟹ CE**；例子；**DPRM 定理**（CE=Diophantine，陈述+三段史）；**DPR 阶段**（假设 y=2ˣ Diophantine ⟹ 每一 CE 集 Diophantine——合取/析取/有界量词保持引理）；**Pell 方程**（Th 14.15 存在非平凡解；Lemma 14.16 ⊗ 群法则；Lemma 14.17/18 序结构；解=基本解幂）；Dirichlet 逼近（Th 14.13 区）；Fibonacci 桥（Matiyasevich 定理：y=2ˣ Diophantine 的 Pell 编码思想）；H10 否定解推论（不可判定）。

- [ ] **Step 1: docs 两章教程**（各 ≥260 行）。
- [ ] **Step 2: `ex42_degrees.v`**：
  1. `ostep (o : nat -> bool) (p : prog) (c : cfg) : cfg`（rife 增加 oracle 查询指令 `roq r l1 l2`）；
  2. 跳跃阶段枚举：`jstage o e s : bool`；
  3. **旗舰——Kleene–Post**：`kp_build (H : nat -> bool) (reqs : nat) : list bool * list bool`——第 2e 需求：用 H 判定「φ_e^{B_s}(x)↓（oracle 用量内）」，选新鲜 x 反 diagonal；对构造出的前缀验证需求满足（`forallb` over 前几个需求，H 取具体实例）；
  4. König：`leftmost (infiniteb : list nat -> bool) (d : nat) : list bool`——左极下降 + 每层无限性不变式（可计算无限树=「每深度 k≤d 有节点」截断版）；
  5. Friedberg–Muchnik：`fm_stage : fmstate -> fmstate`（A_s/B_s/损害计数/需求账本）+ 前 30 阶段演化 Compute + 需求满足对账。
- [ ] **Step 3: `ex45_diophantine.v`**：
  1. `hasol (p : poly2) (bx by : nat) : bool` 穷举；
  2. **闭包引理恒等式 rfl**：`(x²−dy²)(u²−dv²)=(xu+dvy)²−d(xv+yu)²`（`ring`）——⊗ 保 Pell-1；解序列生成 `pell_pow d n` + 前 8 项 Compute + 增长率（下界 `(x₁)ⁿ` 归纳）；
  3. 合取/析取保持：`p₁²+p₂²=0 ↔ (p₁=0 ∧ p₂=0)`、`p₁p₂=0 ↔ (p₁=0 ∨ p₂=0)`——有界解集双射对账（枚举两侧集合相等）；
  4. DPR 组合子：`dioConj/dioDisj/dioBExi` 造多项式 + 语义对账（小规模）；
  5. Fibonacci：Cassini `F_{n+1}F_{n−1}−F_n²=(−1)^n` 归纳、`F_{2n}=F_n·L_n` 归纳；X²−2Y²=±1 解与 (1+√2)^n 联系数值对账；
  6. H10 否定解推论 doc（连 44 章）。
- [ ] **Step 4: Lean 镜像两件**（⊗ 恒等式用整数展开或系数反射；Pell 前项 native）。
- [ ] **Step 5: 验证 + Commit** `feat(mathlogic): 批次五——新 42 章 图灵度与优先法 + 45 章 Hilbert 第十问题（C/L）`

### Task 6: ★46 PA 与 ε₀ + ★47 算术的模型 + 深化 44 章（批次六）

**Files:** Create `docs/46-epsilon.md`、`examples/46_epsilon/ex46_epsilon.{v,lean}`、`docs/47-models.md`、`examples/47_models/ex47_models.{v,lean,pl}`；Modify `docs/44-incompleteness.md`、`examples/44_incompleteness/ex44_incompleteness.v`

**Interfaces:**
- Consumes: 40 章 `urun`（47 章不需要）；64 章（旧 54）PA 术语；24 章有限结构求值器（47 章 fsat）。
- Produces: `onf/olt/onf_base`（CNF 序数）、`hardy`、`herbase/gstep`、`good_shadow_desc`（影子下降）、`ph_search`（PH 数搜索）。

**46 章书内容**：序数算术与 **Cantor 范式**；**ε₀**；**基础序列** α[n] 与 Hardy 层谱 H_α（Def 15.24 区；H_{α+β}=H_α∘H_β）；τ 复杂度（Def 15.21）与 Ex 15.22；**Goodstein 定理**（遗传基表示、基抬升、减一；终止性；PA 不可证）；Gentzen：PA+TI(ε₀)⊢Con(PA)、**Th 15.15**（PA 证全的函数被某 H_α 支配——序数分析）；Kreisel α-递归；Z∞ 无穷证明系统与切消（doc 级）。

**47 章书内容**：非标准模型存在（紧致性）；overspill；初等段与 **MacDowell–Specker**（Th 16.18）；**Paris–Harrington**（加强 Ramsey「相对大」hom 集；模型论独立性证明骨架；Ketonen–Solovay：g 支配一切 H_α——与 Goodstein 的共同 Π₂ 模式）。

- [ ] **Step 1: docs 两章教程**（各 ≥280 行）。
- [ ] **Step 2: `ex46_epsilon.v`**：

```coq
(* Cantor 范式：ω^γ·c 项表（指数递降）。有限树 ⟺ < ε₀ *)
Inductive onf : Type := onf : list (onf * nat) -> onf.
Definition ozero := onf [].
Fixpoint olt (a b : onf) : bool := (* 递降字典序 *) ...
Fixpoint onf_base (a : onf) (n : nat) : onf := (* 基础序列：α[n] *)
  match a with
  | onf ((onf [], 1) :: rest) => ...               (* ω·1 的极限：n *)
  | onf ((g, 1) :: rest) => (* ω^g·1 且 g 极限/后继的分层处理 *)
      ... (* ω^(h+1) ↦ ω^h·n；ω^λ ↦ ω^(λ[n]) *)
  | ... end.
Fixpoint hardy (a : onf) (n : nat) : nat :=
  match a with
  | onf [] => n
  | _ => hardy (onf_base a n) (n + 1)   (* Marker Def 15.24 形；实现时按书定稿 *)
  end.
Example hardy_growth : map (hardy (onf [(onf [(ozero,1)],1)])) [1;2;3] = [...]. (* H_ω *)
(* Goodstein *)
Fixpoint herbase (n b : nat) : onf := (* n 的 b 进制遗传展开=CNF（ω↔b） *) ...
Definition gstep (n b : nat) : nat := heredec (bump (herbase n b) (S b)). (* 影子上抬+数值减一 *)
Theorem good_shadow_desc : forall n b, olt (herbase (gstep n b) (S b)) (herbase n b) = true.
Proof. ... Qed.   (* 旗舰：CNF 结构归纳+onf_base 单调性；零公理 *)
Example good_runs : (* G(1),G(2),G(3) 全程 Compute 到 0 *)
  (good_terminates 1 2, good_terminates 2 2, good_terminates 3 2) = (0,0,0).
Proof. reflexivity. Qed.  (* 数值面；G(4) 前三步 Compute 记账（第 3 步=26、第 4 步=4^4 级） *)
```

- [ ] **Step 3: `ex47_models.v`**：`fsat`（Th(N) 截断句子+{c>n̄} 有限可满足：c:=N+1 见证）；overspill 有限影子（M_k=[0..k]∪{∞} 上含全标准段的可定义集必含 ∞——小公式枚举验证）；PH：`minhom` 判定 + `ph_min k r m`（m 点全染色存在反例？）+ **R(3,3)=6 对账**（2^15 染色穷举）+ PH(3,2) 分离表（m=5,6 穷举；Prolog 回溯搜反例到 m=7）；MacDowell–Specker/Ketonen–Solovay doc。
- [ ] **Step 4: Lean 镜像两件**（Goodstein 数值面 native_decide 更远；onf 结构同构移植）。
- [ ] **Step 5: Prolog 面** `ex47_models.pl`：`no_ph_coloring/2` 回溯搜索（剪枝：按字典序最左反例）m=5..7 + R(3,3) 交叉对账，`END ====`。
- [ ] **Step 6: 深化 44 章**（Marker Ch13 前半）：docs 加「层级化路线的强不完备性」节（≥70 行：PR 图可定义 ⟹ 可定义=算术集 ⟹ Th(N) 不可判定不可递归公理化；与 36→43 章算术化路线对照表；第二定理 Hilbert–Bernays/Kreisel 细化）；`ex44_incompleteness.v` 追加 `arith_class` 件（把 44 章现有表示性样板映射到 Σ₁ 形式的归属检查）。
- [ ] **Step 7: 验证 + Commit** `feat(mathlogic): 批次六——新 46 章 PA 与 ε₀ + 47 章 算术的模型 + 44 章层级化深化（C/L/P）`

### Task 7: 深化 37 章（RAM 等价）+ 收官对账（批次七）

**Files:** Modify `docs/37-regmachine.md`、`examples/37_regmachine/ex37_regmachine.v`、`README.md`、`PLAN.md`、`CHEATSheet.md`、`docs/73-wrapup.md`；Create memory `G:\xulun\.claude\projects\G--code-guide\memory\mathlogic-marker-expansion.md`

**Interfaces:**
- Consumes: 43 章 `cp`（数组编码进单寄存器）。
- Produces: 73 章 193 单元全绿 + 五文件收官对账。

- [ ] **Step 1: 深化 37 章**（Marker Ch9）：docs 加「RAM 与 Church–Turing 论题」节（≥60 行：RAM 指令集、间接寻址、RM 模拟 RAM 的数组编码思想）；`ex37_regmachine.v` 追加 `ram2rm` 件——RAM（LOAD/STORE/ADD/CJUMP，数组用 `cp` 编码进 R1）求和程序 → RM 程序，小数组等价对账（bounded fuel 双跑同输出）。
- [ ] **Step 2: README 终稿**：73 章全表（10 新章行）+193 单元计数+六轮书本扩充状态行（Marker 定位）。
- [ ] **Step 3: PLAN 终稿**：状态行 73 章 193 单元；新章 ✅；深化章标注 🔁。
- [ ] **Step 4: `docs/73-wrapup.md`**：追加「Marker GTM 301 逐章对账表」（16 章+附录 → 本教程章号映射）+ 193 计数 + tame vs wild 总叙事线。
- [ ] **Step 5: CHEATSheet**：新增 26/27/28/29/40/41/42/45/46/47 章坑位节（各章实测坑随写随记）。
- [ ] **Step 6: 全量回归** `pwsh -NoProfile -Command '& ./build.ps1 -All'`——193 单元全绿 0 SKIP exit 0。
- [ ] **Step 7: 记忆落盘** `mathlogic-marker-expansion.md`（结构/大坑/收官五文件/关联链接）+ `MEMORY.md` 索引行。
- [ ] **Step 8: Commit** `docs(mathlogic): 批次七——Marker 扩充收官对账（73 章/193 单元全绿）`

---

## Self-Review 结论

1. **Spec 覆盖**：spec §3 重排→Task 0；§4 十新章→Task 1–6（26/27+28/29/40+41/42+45/46+47）；§5 三深化→Task 3(16)/6(44)/7(37)；§6 批次表逐行对应；§8 完工定义→Task 7。
2. **占位符扫描**：无 TBD/TODO；所有代码块给到签名+代表性现场（具体 Example 期望值实现时以 Compute 先探实值再写定——Mendelson 轮 iso_eeq 教训内建为各任务纪律）。
3. **类型一致性**：RM 五指令名（radd/rdel/rife/rprint/rhalt）、cp 配对、evf 求值器签名均与现库实件核对（examples/33、36 章源文件 2026-10-08 读取）。
