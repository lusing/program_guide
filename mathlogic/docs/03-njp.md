# 03 自然演绎 NJp：每条规则都是一个程序

> 对书：Huth&Ryan §1.2 / Mints §2.2 / Ben-Ari 3e Ch3（对照用）/ Mendelson §1.4（Hilbert 对照）
> 通道：C/A/L/I/H4（HOL4 首秀）

02 章用真值表回答了「什么时候为真」，本章回答另一个问题：
「怎么**推**」。自然演绎（natural deduction，中译本同名）是一套
证明演算——它不管公式意味着什么，只管公式能怎么变形。这套
演算由 Gentzen 在 1934 年发明，设计目标是**模仿人类数学论证的
自然结构**：每个连接词配一对「引入/消除」规则，外加处理否定与
矛盾的几条。本章把 H&R §1.2 的全套规则讲透，并揭示一个事实：
在类型论系证明助手里，**每条规则都字面地是一个程序**。

## 证明框：演算的纸面记法

H&R 用纸面的**证明框**（proof box）记法写 ND 推导：每行一个
公式加一行理由，假设开一个矩形框圈住其作用域。例如 →I 的使用：

```text
1  p        premise（前提）
2  ┌ q      assumption（开框假设）
3  │ p      1 行重述（repeat）
4  └ q → p  →i 2-3（关框：把框内假设变成蕴含的前件）
```

框的纪律只有一条：**关框之后，框内的行一律作废**——它们依赖的
假设已经被 →i「放电」（discharge）进了蕴含式。这条纪律是 ND
最微妙的机制：假设有生灭，结论不携带。后面会看到，它在证明
助手里对应「λ 绑定的变量不出现在类型里」。

## 九条基础规则逐个讲

### 合取 ∧：配对与投影

```text
  φ   ψ        φ ∧ ψ        φ ∧ ψ
 ------- ∧i    ----- ∧e₁    ----- ∧e₂
  φ ∧ ψ          φ             ψ
```

∧i 说「两边的证据都有，就合成对的证据」；∧e₁/∧e₂ 说「对的
证据可以拆出任何一边」。Curry–Howard 直读：**∧i 是配对，
∧e 是投影**。机器现场（`examples/03_njp/ex03_njp.v`）：

```coq
Definition andI {P Q : Prop} (p : P) (q : Q) : P /\ Q := conj p q.
Definition andE1 {P Q : Prop} (h : P /\ Q) : P := proj1 h.
Definition andE2 {P Q : Prop} (h : P /\ Q) : Q := proj2 h.
```

`conj` 就是配对构造子，`proj1/proj2` 就是投影——规则与程序的
对应是**定义级**的（`Definition` 右侧就是左侧类型的居民）。

### 析取 ∨：注入与分情况

```text
   φ             ψ          φ ∨ ψ   [φ]…χ   [ψ]…χ
 ------- ∨i₁   ------- ∨i₂  -------------------- ∨e
  φ ∨ ψ         φ ∨ ψ                 χ
```

∨i 说「一边的证据足够造析取」；∨e 是**分情况讨论**：要吃掉
`φ ∨ ψ`，必须准备两个分支——φ 情形给 χ、ψ 情形也给 χ——才能
结论 χ。∨e 是 ND 里第一个「开框」规则：两个分支各是一个证明
框，框内假设出框即废。Curry–Howard：∨i 是注入（`inl/inr`），
∨e 是模式匹配。机器现场（`ex03_njp.lean`）：

```lean
theorem orComm {p q : Prop} (h : p ∨ q) : q ∨ p := h.elim Or.inr Or.inl
```

`h.elim` 一行做完 ∨e：两个 continuation 分别处理左右注入，
`Or.inr`/`Or.inl` 把它们重新注入成 `q ∨ p`。

### 蕴含 →：λ 与应用

```text
  [φ]…ψ          φ → ψ    φ
 --------- →i    ------------ →e
   φ → ψ              ψ
```

→i 是整个演算的心脏：**要证 φ → ψ，假设 φ（开框），推出 ψ，
关框**。假设被放电进蕴含式——这就是为什么证明可以有「局部
前提」。→e 就是 modus ponens：有蕴含、有前件，得后件。
Curry–Howard：→i 是 λ 抽象（假设变成绑定变量），→e 是函数
应用。机器现场（`ex03_njp.v`）：

```coq
Definition impI {P Q : Prop} (f : P -> Q) : P -> Q := f.
Definition impE {P Q : Prop} (hpq : P -> Q) (hp : P) : Q := hpq hp.
```

`impI` 的定义体就是 `f` 自己——在类型论里 →i 什么都不用做，
因为「从 φ 到 ψ 的推导」和「φ → ψ 的居民」**本来就是同一个东西**。
这是 Curry–Howard 同构最锋利的一刀（12 章专门展开）。

### 否定 ¬ 与矛盾 ⊥：证伪器与空消解

¬φ 不是原生连接词，而是**定义**：¬φ ≜ φ → ⊥（「φ 会导致矛盾」）。
于是 ¬i 是 →i 的特例（假设 φ 推出 ⊥，关框得 ¬φ），¬e 是 →e
的特例（¬φ 与 φ 对撞出 ⊥）。⊥ 只有一条规则：

```text
   ⊥
 ----- ⊥e（ex falso quodlibet：矛盾推出一切）
   φ
```

直觉：如果前提已经矛盾，那么前提集合是「空的可满足集」，
任何结论都（空洞地）跟着成立。Curry–Howard：⊥e 是空类型的
消解子（`False.elim`/`False_ind`）——「没有居民的类型可以模式
匹配出任何类型」。

## 定理即程序组合

规则讲完，看它们怎么组装成定理。交换律两件（`ex03_njp.v`）：

```coq
Theorem and_comm : forall P Q : Prop, P /\ Q -> Q /\ P.
Proof. intros P Q [HP HQ]. split. exact HQ. exact HP. Qed.

Theorem or_comm : forall P Q : Prop, P \/ Q -> Q \/ P.
Proof. intros P Q [HP | HQ].
  - right. exact HP.
  - left. exact HQ. Qed.
```

`intros` 是 →i/∀i 的战术化身；`[HP | HQ]` 在引入模式里直接做
∨e 分情况；`split` 是 ∧i；`left/right` 是 ∨i。读这两个证明就像
读证明框的压缩版。再看一对构造性成立的 de Morgan（**注意只有
这个方向构造性成立**——`¬(p∧q) → ¬p∨¬q` 方向是 11 章的坎）：

```coq
Theorem de_morgan_1 : forall P Q : Prop, ~ (P \/ Q) -> ~ P /\ ~ Q.
Proof. intros P Q H. split.
  - intros HP. apply H. left. exact HP.
  - intros HQ. apply H. right. exact HQ. Qed.
```

直觉：`¬(p∨q)` 是一台「析取证伪器」——喂它 `inl hp` 或
`inr hq` 都吐 ⊥。所以要证 ¬p，就假设 p（`intros HP`），注入成
p∨q 喂给证伪器（`apply H. left.`）。**「¬ 是证伪器」这个操作
性读法**，是直觉主义证明技术里最有用的心法。

## 派生规则：宏，不是新公理

§1.2.2 的关键概念：有些规则不在基础集里，但能从基础规则
**推导**出来——它们是宏（macro），用起来像规则，展开后全是
基础规则的组合。这解决了演算设计的一对张力：基础规则越少越
好分析（元定理好证），但越多越顺手（证明好写）。派生规则两头
都占。

**拒取式 MT**：从 φ→ψ 和 ¬ψ 得 ¬φ。推导（§1.2.2 原文）：
假设 φ（开框），由 →e 得 ψ，再与 ¬ψ 对撞（¬e）得 ⊥，关框
¬i 得 ¬φ。机器件（`ex03_njp.v`）：

```coq
Theorem mt : forall P Q : Prop, (P -> Q) -> ~ Q -> ~ P.
Proof. intros P Q HPQ HNQ HP. apply HNQ. apply HPQ. exact HP. Qed.
```

**¬¬i**：从 φ 得 ¬¬φ。推导：假设 ¬φ，与 φ 对撞得 ⊥，关框
得 ¬¬φ。构造性成立、零公理：

```coq
Theorem nn_i : forall P : Prop, P -> ~ ~ P.
Proof. intros P HP HNP. exact (HNP HP). Qed.
```

**PBC（反证法，reductio ad absurdum）**：从「¬φ 推出 ⊥」得 φ。
注意它与 ¬i 的微妙差别：¬i 从「φ 推出 ⊥」得 **¬φ**；PBC 从
「¬φ 推出 ⊥」得 **φ**——跨过了一个 ¬¬φ → φ 的裂缝，所以
**PBC 是经典规则**，在构造内核下必须由经典公理背书：

```coq
From Stdlib Require Import Classical_Prop.

Theorem pbc : forall P : Prop, (~ P -> False) -> P.
Proof. intros P H. apply NNPP. exact H. Qed.

Print Assumptions pbc.     (* 依赖 classic *)
```

H&R 把 PBC 列为派生规则（从 ¬i/¬e/¬¬e 导出），其中 ¬¬e 正是
经典部分——我们的机器账本把这一点照得通明：`nn_i` 是 Closed，
`pbc` 记着 `classic`。

**LEM（排中律）作为派生规则**：φ ∨ ¬φ 本身在经典 ND 里可由
PBC 推出（证 ¬(φ∨¬φ) 导致矛盾——这正是 11 章 `nn_lem` 的
构造性内核）。它的典型用法是分情况：

```coq
Theorem lem_use : forall P Q : Prop, (P -> Q) -> (~ P -> Q) -> Q.
Proof.
  intros P Q HPQ HNQ. destruct (classic P) as [HP | HNP].
  - exact (HPQ HP).
  - exact (HNQ HNP).
Qed.
```

「P 成立能证 Q，¬P 成立也能证 Q，那 Q 无条件成立」——这个
论证模式在数学里天天用（「若 n 是偶数…若 n 是奇数…」），它
的构造性代价就是一笔 classic 账。

## 可证等价与替换

§1.2.4：φ 与 ψ **可证等价**（provably equivalent，记 φ ⊣⊢ ψ；
中译本译「逻辑等价」，⚠️ 易与语义等价混）当且仅当两个方向的
矢列都可证。它是证明层面的等价关系，作用类似代数里的等号：
在一个更大的证明中，可以把出现的 φ 换成 ψ 而不改变可证性
（替换原理）。这与 08 章的**语义等价**（≡，真值表相同）是两
个层面的事——完备性定理（22 章）把它们缝合，但在缝合之前，
写作时要区分：⊣⊢ 是演算内的事，≡ 是模型层的事。

## 旁白：反证法的地位

§1.2.5 的 aside 值得单独一节，因为它是全书构造/经典暗线的
第一个关隘。H&R 承认：ND 基础规则里 ¬e+PBC 允许**非构造性
的间接证明**——「假设反面，推出矛盾，于是成立」没有给出任何
见证。直觉主义者（Brouwer 一系）拒绝把 ¬¬φ → φ 当逻辑真理：
「没法证伪」不等于「有证据」。本章的机器现场把分歧量化得
干干净净：`Print Assumptions` 下，构造件全 Closed，经典件全
记 classic。04 章把五个经典原理排成等价矩阵，11 章证明
「命题层上经典证明总能 ¬¬ 化成直觉证明」（Glivenko），
13 章用 Kripke 模型给出 ¬¬P→P 不可构造证的**语义反例**——
这条线从这里开始。

## 五通道现场与坑位速记

- **Coq**：`intros [HP | HQ]` 直接做 ∨E；`split` 即 ∧I；
  全部构造定理 `Print Assumptions` 均 Closed——NJp 片段零公理；
  de_morgan_2 依赖 pattern matching 位置双分支的缩进深度。
- **Lean**：`⟨_, _⟩` 匿名构造子语法同时吃 ∧i 与 ∨e 的 elim 桥；
  `h.elim Or.inr Or.inl` 一行做完 ∨e；λ 模式匹配 `fun ⟨hp, hq⟩ =>`
  在 Lean 4 完全合法；`Classical.byContradiction` 直接是 PBC
  （`#print axioms` 记 `Classical.choice` 系）。
- **Agda**：点式书写每行就是一个 ND 推导——`deMorgan₂` 的
  λ⟨ , ⟩ 模式即 ∧e 拆解；where 块按依赖顺序排。
- **Isabelle**：对象逻辑 HOL 的 ND 规则是 `conjI/conjE/disjE/
  impI/mp`——名字与 Gentzen 一一对应；`by (rule impI)` 显式
  走规则可练规则感，`auto` 则一把梭。
- **HOL4 首秀五连坑**（保留实录）：`ASM_REWRITE_TAC` 只吃
  「等式」假设，原子布尔假设要用 `ACCEPT_TAC`；`STRIP_TAC`
  双向拆目标（连 ¬ 都展开）；`DISJ1_TAC/DISJ2_TAC` 签名与直觉
  相反；「Can't alpha convert」报错要用 `PROVE_TAC` 收尾而不是
  手拼项；`hol run` 脚本必须 `set_trace` 降噪再 `open` 库。

## 本章小结

- ND = 每个连接词的引入/消除规则对 + 否定与矛盾的几条；
  证明框纪律=假设生灭管理。
- Curry–Howard 在类型论系是字面事实：∧=积、∨=和、→=函数、
  ⊥=空类型；规则即程序。
- 派生规则是宏：MT/¬¬i 构造白送，PBC/LEM 记账 classic——
  机器账本让「经典性」精确到每个定理。
- 可证等价（⊣⊢）≠ 语义等价（≡）：演算层与模型层，22 章缝合。
- 反证法 aside 是构造/经典暗线的第一关隘。

---

上一章：[02 命题逻辑：语法、语义与蛮力判定器](docs/02-propsem.md) · 下一章：[04 经典加成：等价矩阵与六家账本](docs/04-classical.md)
