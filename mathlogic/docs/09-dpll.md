# 09 DPLL 与 SAT：从通用回溯到 Horn 线性求解

> 对书：Ben-Ari 3e Ch6 / H&R §1.5.3（Horn 可满足性）/ §1.6（SAT 求解器）
> 通道：C/L/I（DPLL 三定理链）+ C/L（Horn 标记算法新单元 ex09_horn）

08 章把任意公式化成子句集，本章回答「子句集的可满足性怎么判」。
先讲通用武器 DPLL（回溯搜索，最坏指数），再讲 H&R §1.5.3 的
观察：**Horn 子句集可以线性判**——一个标记算法 + 两条正确性
定理，最后抬头看 §1.6 的三次标记求解器如何把标记思想推广回
全命题逻辑。两条线共用一个思想：**不枚举赋值，而是推导约束**。

## 子句集与 DPLL 三板斧

子句集 = 文字的表的表（每个内层表是一个子句=文字析取）。
DPLL 的三板斧：

1. **冲突检测**——出现空子句（所有文字都被赋值杀光）即回溯；
2. **单元传播**——单文字子句逼出该文字的赋值；
3. **分裂**——取首文字，真/假两路递归。

化简 `fmlStep` 一石二鸟：文字变真 → 删掉整个子句（已满足）；
文字变假 → 从子句里删掉该文字（不再有贡献）。

## 实现的关键反转（07/08 章教训的结晶）

赋值**不在过程里累积，而在返回时用 upd 复合装配**：

```text
dpll k (fmlStep F n s) 返回 Some e  ⟹  整体返回 Some (upd e n s)
```

从根上消灭 07 章那种「lookup 遮蔽/一致性问题」——化简式无该
变元文字（`fmlStep_var_free`）保证 upd 不碰已满足的子句语义。
这是「正确性靠架构而不是靠补丁」的现场：数据流设计对了，
引理族自然就短。

## 旗舰三定理（Coq 通道，零公理）

```text
dpll_sound     报 Some e 则 e 真满足
dpll_complete  有模型且 msize F < fuel 则不报 None
dpll_decides   dpll (S (msize F)) F = None ⟺ 全体 e 不可满足
```

度量 = 文字总数 `msize`：每次单元/分裂都删掉至少一个文字
（`fmlStep_size`：决定变元在子句中有出现）。complete 的分裂
分支按模型落点反证：`e n = negb s ∨ e n = s`，哪路 None 就用
哪路的化简式 + IH 逼出矛盾——**无须重排尝试顺序**。这套骨架
与 07 章表列的三定理链同构（sound/complete/decides），可以
对照着读：回溯搜索的正确性证明套路是可迁移的。

## Horn 子句：一个能线性判的片段

DPLL 是通用的，代价是最坏指数。H&R §1.5.3 指出一个工程上
极重要的特例：**Horn 公式**（得名于逻辑学家 Alfred Horn）。
按 H&R 定义 1.46，Horn 公式是形如

```text
P ::= ⊥ | ⊤ | p          （命题性原子，允许 ⊥/⊤）
A ::= P | P ∧ A           （前提：原子合取）
C ::= A → P               （子句：合取前提推出原子结论）
H ::= C | C ∧ H           （公式：子句合取）
```

的公式。直读：**每条子句是「一组合取的命题推出一个命题」**。
`(p∧q∧s→p) ∧ (q∧r→p) ∧ (⊤→s)` 是 Horn；`p∧s→¬s`（结论带
否定）、`¬q∧r→p`（前提带否定）、`p₂∧p₃→(p₅∨p₁₃)`（结论是
析取）都不是。用子句集的语言说：**每个子句至多一个正文字**
（正文字=结论，负文字=前提）。这正好是逻辑式程序设计（20 章
Prolog 桥）与硬件验证里最常见的公式形态——所以「线性」不是
象牙塔优惠。

机器表示（`examples/09_dpll/ex09_horn.v`）把 Horn 公式直接
压缩成它的语义骨架：

```coq
Definition horn : Type := (list nat * option nat)%type.
```

`(ps, Some q)` 编码 `p₁∧…∧pₖ → q`；`(ps, None)` 编码
`p₁∧…∧pₖ → ⊥`（目标子句：前提不能全真）。整个 Horn 公式是
`list horn`——注意这是**抽象语法上的简化**：top 层合取和前提
层合取都被列表吸收，等价性显然，教程直接从子句集层面开工。

## 标记算法：线性时间的可满足性判定

H&R 的算法（定理 1.47）维护一个**标记集** m（原子表），规则：

1. 初始为空；
2. **sweep**：扫描全部子句，凡有子句 `p₁∧…∧pₖ → P` 的前提
   全在 m 里而结论 P 未标记，就把 P 标记上（⊥ 被触发则直接
   报不可满足）；
3. 重复 2 直到一轮下来没有新标记（**不动点**）；
4. ⊥ 被标记过 → 不可满足；否则 → 可满足。

机器版三层装配（`ex09_horn.v`）：

```coq
Definition sweep1 (c : horn) (m : list nat) : list nat * bool :=
  match c with
  | (ps, cq) =>
      if allMarked ps m then
        match cq with
        | None => (m, true)
        | Some q => if marked m q then (m, false) else (q :: m, false)
        end
      else (m, false)
  end.

Fixpoint sweep (cs : list horn) (m : list nat) : list nat * bool := ...

Fixpoint close (fuel : nat) (cs : list horn) (m : list nat)
  : list nat * bool := ...
```

`sweep1` 处理单子句（返回新标记集+是否触发 ⊥），`sweep` 扫
全表，`close` 反复 sweep 到不动点——燃料=原子数+1（每遍至少
多标一个原子，标记集有界，所以够）。

**手算 trace**（H&R §1.5.3 的例）：子句集
`{(p₂∧p₃∧p₅→p₁₃), (⊤→p₅), (p₅∧p₁₁→⊥)}`：

| 遍 | 动作 | 标记集 |
|---|---|---|
| 1 | 空前提子句 `(⊤→p₅)` 直接触发；其余前提未全 | {p₅} |
| 2 | 第一条前提 p₂/p₃ 缺、第三条缺 p₁₁——无新标记，不动点 | {p₅} |

⊥ 未触发 → 可满足；标记集 {p₅} 读出的赋值（p₅=真其余假）
就是模型。追加一条 `(⊤→p₁₁)` 再走：第 1 遍标记 {p₅,p₁₁}，
第 2 遍 `(p₅∧p₁₁→⊥)` 前提全真——⊥ 触发，**不可满足**。
机器现场（同文件）：

```coq
Example horn_demo_sat :
  hsat [([2;3;5], Some 13); ([], Some 5); ([5;11], None)] = true.
Proof. reflexivity. Qed.

Example horn_demo_unsat :
  hsat [([2;3;5], Some 13); ([], Some 5); ([5;11], None);
        ([], Some 11)] = false.
Proof. reflexivity. Qed.
```

复杂度为什么线性：每个原子至多被标记一次（NoDup 引理保证
标记集不重复），每遍至少多标一个，所以 sweep 至多 |原子|+1
遍、每遍 O(子句总长)——合计 O(公式尺寸)。

## 正确性：不变量「标记即必真」

H&R 定理 1.47 的证明核心是一个不变量（书中式 1.8）：

> **所有被标记的 P，在任何满足 φ 的赋值下都为真。**

「标记」的语义身份是**约束**：φ 若想可满足，标记原子就被逼
着取真。两条定理的证明骨架（机器版 `ex09_horn.v`）：

**完备方向** `hsat_complete`：⊥ 被标记 → 不可满足。对 close
的迭代维护上面的不变量（`sweep_inv`/`close_inv`：满足赋值
下被标记者必真），基例是空前提子句——⊥ 与空前提合取给出
矛盾，不变量起步就成立；归纳步里 sweep 新标的 q 来自前提
全真的子句，而前提全真+子句成立逼 q 真。结束时若 ⊥ 在
标记集里：触发它的子句前提全真而结论是 ⊥——该子句在任何
满足赋值下为假，无赋值能满足 φ。

```coq
Theorem hsat_complete : forall cs,
  hsat cs = false -> ~ (exists v, allsat v cs).
```

**可靠方向** `hsat_sound`：不动点 + ⊥ 未标记 → 可满足。
见证赋值就是「标记即真、未标记即假」（`fun n => marked mF n`）。
要证它满足全部子句：反设某子句 `ps → q` 在此赋值下假——
前提全真（全在标记集）而 q 假（未标记）。但不动点性质
（`fixpoint_clause`）说：前提全标记的子句，其结论必然已
标记——矛盾。这个「不动点处无漏标」引理是可靠方向的全部
技术内容，Coq 证明要处理 sweep 的表头/表尾双层结构和
标记的 NoDup（长度严格增长才迭代，`close_fixpoint` 用
`NoDup_length_incl` 锁死不动点条件）。

```coq
Theorem hsat_sound : forall cs,
  hsat cs = true -> exists v, allsat v cs.
Print Assumptions hsat_sound.    (* Closed under the global context *)
Print Assumptions hsat_complete. (* Closed *)
```

一个值得停留的注记：**标记集恰好是 φ 的最小模型**（在「真
原子集合」的偏序下）。sound 的见证赋值取的就是它——Horn
语义的单模型性（20 章 T_P 最小不动点的预演）在这里第一次
露头。

Lean 版（`ex09_horn.lean`）同构重演，账单有诚实差异：
`hsatComplete` 只带 `propext, Quot.sound`（Lean 结构公理，
一切 simp/omega 证明都带）；`hsatSound` 额外带
`Classical.choice`——来源是 core 的 `List.length_erase_of_mem`
（裸 core 无 Nodup 长度引理，自证时引用了标准库这条带经典
账的引理），**不是**本章推理引入的经典步骤。Coq 版两定理
均真零公理（Closed）。

## §1.6 的两级推广：从 Horn 标记到全命题标记

H&R §1.6 把标记思想沿两个方向推广（文档级讲解，不机器化）：

**§1.6.1 线性求解器**：先把公式翻译到只含 `¬, ∧, ∨` 的片段
（消 →），再把语法树**共享相同子公式**压成 DAG（例 1.48：
`p ∧ ¬(q ∨ ¬p)` 的两个 p 节点合并）。然后在 DAG 节点上做
**约束传播**：给节点标 T/F，规则族形如「T(φ∧ψ) 强制
T(φ) 与 T(ψ)」（te/ti/fl/fr/fll/frr 等力迫律，图 1.14）。
传播到矛盾（同节点被迫 T 又 F）即不可满足；全部节点标满
且一致，还要**自底向上重算一遍**验证标记真是原公式的见证
（标记一致 ≠ 见证，例 1.48 的图 1.13 演示了闭环核查）。
这就是 Stålmarck 风格算法的教学版——工业 SAT 的另一条
谱系（与 DPLL 的搜索式路线互补：DPLL 靠分裂回溯，标记法
靠约束推导）。

**§1.6.2 三次求解器**：完整版对「任意两个约束组合」做闭包，
复杂度 O(n³)——每一对 (节点, 标记) 组合至多处理一次，每次
处理扫全部力迫律。H&R 用它判矢列有效性（例：`p∧q∧r ⊢ p∨q∨r`
⟺ 其否定不可满足），DAG 上时间戳（1:、2:…）展示推导顺序。
线性（Horn）/三次（全命题）/指数（DPLL 最坏）三级台阶的
全景：**片段越受限，约束推导收敛越快**。

## 三家分工

| 通道 | 内容 |
|---|---|
| Coq/Rocq | DPLL 完整三定理链 + **Horn 双定理零公理**（本章旗舰） |
| Lean | DPLL 同构实现 + native_decide 现场；Horn 同构（账单注记如上） |
| Isabelle | DPLL 同构实现 + eval 现场；化简引理手动 Isar 六轮未收口——如实记边界；Horn 未做（C/L 已覆盖主线） |

## Davis-Putnam 的另一条腿（Ben-Ari §6.2 对照）

DPLL 的「D」有两位父亲：分裂（本章的猜文字+回溯）之外，
原版 DP 还有**变量消元**——把 p 的一切出现换成 (C∪{p}) 与
(D∪{¬p}) 的归结式集合。消元换空间（子句可能增多）、分裂换
时间（搜索树指数）——现代求解器（CDCL）走分裂+学习，但
学习子句本质是「按需造归结式」，DP 的思想以另一种形态复活。
41 章把消元规则机器化并演示其在鸽笼公式上的形态；BDD 的
存在量词消元（10 章 exb）是同一思想在图上的化身。三条
SAT 战线（DPLL/DP/BDD）在 34 章 μ 演算的不动点视角下统一。
## 本章小结

- DPLL：冲突/单元/分裂三板斧；upd 复合装配让正确性靠架构；
  三定理链与 07 章同构。
- Horn 片段：每子句至多一正文字；标记算法 O(公式尺寸) 判
  可满足性——「标记即必真」不变量撑起双方向正确性。
- 标记集=最小模型：20 章 T_P 不动点的直系预演。
- §1.6 标记求解器谱系：线性(Horn)→三次(全命题闭包)→
  指数(DPLL 最坏)；约束推导与搜索回溯是 SAT 的两条技术路线。
- Lean 裸 core 的账单文化：结构公理与 core 引理的经典账要
  分开记账（`#print axioms` 逐条溯源）。

## 坑位速记（本章实测）

- **Coq/Rocq**（DPLL）：
  - `xorb_false_iff` 不存在——xorb 的真/假分解要走
    `destruct (fst l0); destruct s` 布尔四路 bash；
  - match-on-option 的假设先 destruct 内层（eqb/xorb/递归值）
    才可用；
  - `clauseStep_size_le` 的 apply 会撞目标 `S (csize rest)`——
    改 `pose proof` + lia；
  - `Nat.eqb (e n) s` 里两边是 bool——要先 `destruct (e n)`；
  - `dpll_sound _ _ E` 的下划线数 = 显式参数数（fuel/F/e 三个）。
- **Coq/Rocq**（Horn 新增）：
  - `subst` 对 `q = Some q0`（option 等式）在 Rocq 9.1 报
    「Not an inductive definition」——改 `rewrite Heq` 后再
    处理；atomsOf_spec 实测踩中；
  - `cases h : e`（Lean）只代换目标不动假设；Coq 的
    `destruct ... eqn:` 则会把 scrutinee 在 IH 里抽象掉——
    两家的 eqn: 语义方向相反，跨语言搬证明时高发坑；
  - `NoDup_length_incl` 的隐式参数在 apply 位会歧义——
    `apply (NoDup_length_incl (l:=m) (l':=m1) Hnd)` 具名钉死；
  - `NoDup_nil` 在 9.1 是 `forall A, NoDup []` 要显式给类型
    参数（`(NoDup_nil nat)`）。
- **Lean**（Horn 新增，裸 core 重灾区）：
  - `||` 的 `Bool.or_eq_true` rw 后第二析取支呈
    `decide (b = true) = true` 形态——干脆 `cases b1` 让
    `(m2, true || b2).2 = true` 以 defeq 直收，别走 rw；
  - **pair-match 的力迫律钉子**：`close` 用
    `match sweep cs m with | (m1,true) => ...` 定义后，
    cases 出的等式假设 iota 不自动归约、`dsimp only` 常报
    no progress——正解是给定义配 **if 风格 + 方程引理**
    （`close_step`/`sweep1_some`/`sweep1_none`，全部 := rfl），
    证明里 rw 方程引理进假设再拆 ite；
  - `cases h : e` 只改目标——ite 长在假设里时先 `rw [h] at h'`
    再 `rw [if_pos rfl] at h'`；
  - `cases (h : n ∈ c :: l)` 的 head 分支会把**较新的变量
    统一掉**（c 消失、全contexts 变 n）——引用被统一变量时
    用 `_` 回指（`exact hq _ rfl`），别按原名找；
  - core `List.erase` 是 bif/match 不是 ite——`rw [if_pos]`
    不燃，按 `b == a` 分情况后 `exact` 靠 defeq 收；
  - 裸 core 无 `rcases`/`rintro`——全部 `cases X with |
    intro a b` 手写；`List.nodup_nil`（小写）才是名，
    `List.Nodup.nil` 不存在；
  - `Classical.choice` 可能从 core 引理渗入（实测
    `List.length_erase_of_mem` 带账）——交货前
    `#print axioms` 逐条溯源并在文档记账。
- **Isabelle**：
  - 字面 Unicode（× ⇒ ≠ ∧ ∨ ¬ λ）在本机词法层 **Inner lexical
    error 二次实锤**——全部 ASCII/`\<xxx>` 转义；
  - `has_conflict` 的 `∃c ∈ set F` 让 eval 代码生成报
    Ill-typed instantiation——改 `list_ex is_empty F`；
  - `rule: clause_step.induct` 与 `arbitrary:` 相互打架；
  - lit_val 展开后的 `if s then s else ¬s`（s 是变量）卡死
    simp/auto——这是六轮未收口的根因。
- **Lean**（DPLL）：`l.1 != s` 是 Bool 的异或语义（`≠` 是
  Prop 不能用在代码分支）；嵌套 match 的 option 层层展开
  Lean 比 Coq 温顺。
