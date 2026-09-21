# 15 · 谓词逻辑与 reflect

对应示例：`../examples/15_predicates.v`

### 15.1 归纳谓词：命题也能带参数

`Inductive` 造的类型可以住在 `Prop` 里，且**结论可以依赖参数**——这叫归纳谓词：

```coq
Inductive even : nat -> Prop :=
  | even_O : even 0
  | even_SS : forall n : nat, even n -> even (S (S n)).
```

读法：「是偶数」由两条规则定义：0 是偶数；n 是偶数则 n+2 是偶数。**没有其他途径**——一个数是偶数，当且仅当它能被这两条规则有限次推导出来。

造证据像搭积木：

```coq
Example even_4 : even 4.
Proof.
  apply even_SS. apply even_SS. apply even_O.
Qed.
```

与 bool 的根本区别（第 4 章的伏笔正式揭晓）：

| | `evenb n`（bool） | `even n`（Prop） |
|---|---|---|
| 本质 | 程序，跑起来算 true/false | 命题，靠规则推导 |
| 用途 | 写代码时分支 | 陈述与证明数学性质 |
| 表达力 | 有限（具体值） | 无穷（forall/exists 随意组合） |
| 代价 | 不能直接用于推理 | 不能直接拿来计算 |

两套并存不是冗余——**分别服务「算」与「证」**，本章末尾的 reflect 把它们焊在一起。

### 15.2 证「函数保性质」：归纳谓词遇上归纳证明

```coq
Theorem even_double : forall n : nat, even (double n).
Proof.
  induction n as [| n IH].
  - apply even_O.
  - simpl. apply even_SS. exact IH.
Qed.
```

对 n 归纳（第 12 章套路），步例里 `apply even_SS` 把目标 `even (S (S (double n)))` 退回 `even (double n)`——apply 对**带参数的构造子**照样工作：目标与构造子结论对齐，剩余参数自动补全，前提 `even n` 变新目标。

### 15.3 对证据本身做归纳

真正的新武器：`induction` 可以作用在**证明**上：

```coq
Theorem even_evenb : forall n : nat, even n -> evenb n = true.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - reflexivity.              (* evenb 0 = true *)
  - simpl. exact IH.          (* evenb (S (S n')) 化简就是 evenb n' *)
Qed.
```

`induction H`（H : even n 的证据）按 even 的两条规则分裂：基例对应 `even_O`；步例的 as 模式 `[| n' Hev IH]` 收下构造子的三样东西——参数 n'、子证据 Hev、归纳假设 IH（「even n' ⇒ 结论」）。**对规则的归纳**正是数学里「对推导结构归纳」的直译。

（此处的 `evenb` 是本章自定义的两步 bool 函数；标准库的 `Nat.even` 用取模实现，`simpl` 行为不直观，教学上自造的更清楚。）

### 15.4 存在量词 exists

```coq
Theorem even_exists_double : forall n : nat,
  even n -> exists k : nat, n = double k.
Proof.
  intros n H.
  induction H as [| n' Hev IH].
  - exists 0. reflexivity.
  - destruct IH as [k Hk].
    exists (S k). simpl. rewrite <- Hk. reflexivity.
Qed.
```

- **证 exists**：`exists 证人.`——把目标降级为「该证人满足性质」。选证人是你的活（这里选 S k）；
- **用 exists**：`destruct ... as [k Hk]`——拆出证人与性质。

Curry–Howard 视角：`forall` 是「任给 x 交付 P x」的函数（依赖函数类型），`exists` 是「证人与证明的打包」（依赖对偶 `{k : nat & n = double k}` 的 Prop 版）。两个量词都是**依赖类型**的日常形态——你已经用依赖类型编程半小时了。

### 15.5 强化命题：两步归纳（全书第一个「技巧」）

反向定理 `evenb_even : evenb n = true -> even n` 藏着经典陷阱。朴素做法 `induction n` 拿到的 IH 只谈**直接前驱** n'，而 `evenb (S (S n)) = evenb n` 谈的是**隔一代**的前驱——IH 够不着，证不动。

标准解法是本章标题级的内容——**把命题加强成两倍，再归纳**：

```coq
Lemma two_step : forall P : nat -> Prop,
  P 0 -> P 1 ->
  (forall n : nat, P n -> P (S (S n))) ->
  forall n : nat, P n.
Proof.
  intros P H0 H1 HSS.
  assert (Hboth : forall n : nat, P n /\ P (S n)).
  { induction n as [| n [IH1 IH2]].
    - split.
      + exact H0.
      + exact H1.
    - split.
      + exact IH2.
      + apply HSS. exact IH1. }
  intros n. destruct (Hboth n) as [Hn _]. exact Hn.
Qed.

Theorem evenb_even : forall n : nat, evenb n = true -> even n.
Proof.
  apply (two_step (fun n => evenb n = true -> even n)).
  - intros _. apply even_O.
  - intros H. simpl in H. discriminate H.   (* evenb 1 = false，矛盾 *)
  - intros n IH H. simpl in H. apply even_SS. apply IH. exact H.
Qed.
```

值得逐行品味：`P n /\ P (S n)`（「相邻两个都成立」）比 `P n`（「单个成立」）**更强**，但更强反而好证——归纳步从 `P (S n)` 和 `P n` 两块积木里拿料（IH2 当燃料，IH1 喂给 HSS）。这个模式叫**归纳强化**（strengthening the induction hypothesis），是归纳证明最重要的心法：**证不动时，别死磕——把命题改强**。第 20 章的 `rev` 定理会再次用到这个思想。

### 15.6 reflect：bool 与 Prop 的官方桥梁

两套世界需要频繁互通。标准库的方案是归纳类型 `reflect`：

```coq
Theorem evenb_reflect : forall n : nat, reflect (even n) (evenb n).
Proof.
  intros n.
  destruct (evenb n) eqn:E.          (* 按 evenb n 的值分情况，记住 E *)
  - apply ReflectT. apply evenb_even. exact E.
  - apply ReflectF.
    intros Hev.
    rewrite (even_evenb n Hev) in E. (* 两个世界的知识对流 *)
    discriminate E.
Qed.
```

`reflect P b` 打包了两个方向：`ReflectT`（b = true 且 P 成立）与 `ReflectF`（b = false 且 P 不成立）。有了它：

- **算出来再说**：运行期用 `evenb` 分支（高效），需要推理时用 reflect 定理换轨到 `even`；
- **一处封装，处处受益**：标准库对常用判定给的是 **iff 形态**的桥（实测：`Nat.eqb_eq : (n =? m) = true <-> n = m`、`Nat.leb_le : (n <=? m) = true <-> n <= m`，需 `Arith`）——reflect 是更结构化的同款思想，把「是/否」与「成立/不成立」各装一盒。

`destruct (evenb n) eqn:E` 的 `eqn:E` 是重要小技巧：分情况的同时**记住**等式 `evenb n = true/false`——之后 `rewrite ... in E` 让两个世界的证据对流，最后 `discriminate E` 引爆矛盾。这一套组合拳（destruct eqn / rewrite in / discriminate）是谓词证明的高频三连。

### 15.7 本章坑位清单（实测）

1. **归纳谓词的构造子不是函数**：`even_SS` 不能 `Compute`——它是逻辑规则不是程序；想要可计算版另写 bool 函数 + reflect 桥；
2. **朴素归纳证两步递归性质**：IH 只谈直接前驱，`evenb (S (S n))` 够不着——用 15.5 的强化技巧（`P n /\ P (S n)`）；
3. **`destruct (evenb n) eqn:E` 忘写 eqn:E**：分支里没有 `evenb n = ...` 的记录，后续想 rewrite 无从下手；
4. **exists 的证人选错**：`exists 0.` 之后目标降级为具体等式，选错证人只能 Abort 重来（没有「换证人」的策略，实际上可以 `clear` 后重来，但重新 exists 更直接）；
5. **标准库 `Nat.even` 的 simpl 不直观**（按取模实现）：教学与自造谓词配套时，bool 版也自造（本章 `evenb`），别混用。

---
上一章：[14 · 命题逻辑](14-logic.md) ｜ 下一章：[16 · 高阶函数及其证明](16-higher-order.md) ｜ 返回：[README](../README.md)
