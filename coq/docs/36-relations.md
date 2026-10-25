# 36 · 关系、闭包与确定性

对应示例：`../examples/36_relations.v`（`Module Ex36Relations`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38 章的 `ceval` 是一个**关系**（`st =[ c ]=> st'`），40 章的 `step` 也是关系，44 章的
类型关系还是关系。本章把"关系"本身当成研究对象，回答三组问题：

1. **关系是什么形状的命题？**——`relation X := X -> X -> Prop`，二元谓词。
2. **关系有哪些代数性质？**——自反、对称、反对称、传递；这些性质组合出**等价关系**
   和**（偏）序**。`le` 会逐条验证。
3. **怎么从一个关系造出新关系？**——最重要的构造是**自反传递闭包**：把"走一步"扩成
   "走零步或多步"。40 章的 `multi`、`star` 就是它的化身。

一个贯穿全章的具体问题：**什么样的关系是"确定性"的？**——答案"偏函数"（同一个输入
不能有两个输出）正是 38 章 `ceval_deterministic`、40 章 `step_deterministic` 的抽象
原型。

### 关系：关于一对值的命题族

文件头只要算术和标准库的关系模块：

```coq
(* 36 关系、闭包与确定性 —— 关系 = 关于一对值的命题族；确定性 = 偏函数；闭包 = 多步化 *)

From Stdlib Require Import Arith Relations.

Module Ex36Relations.

(* ---------- 关系：关于一对值的命题族 ---------- *)

Definition relation (X : Type) := X -> X -> Prop.
```

一个元素类型为 `X` 的（二元）关系，就是把一对 `X` 映到命题的函数。最熟悉的例子是
`le`。先看它的定义和归纳原则：

```coq
Print le.
```

repl 输出：

```
Inductive le (n : nat) : nat -> Prop :=
    le_n : n <= n | le_S : forall m : nat, n <= m -> n <= S m.

Arguments le (n _)%_nat_scope
Arguments le_n n%_nat_scope
Arguments le_S (n m)%_nat_scope _
```

两条构造子：`le_n`（自己 ≤ 自己）和 `le_S`（右端加一保持 ≤）。**注意 `le` 的第一个
参数是"参数"（parameter，在冒号前），第二个是"索引"（index，在冒号后）**——所以
`2 <= 4` 的推导树只能从 `2 <= 2` 起步逐步加一，这正是后面 `le_trans` 归纳形状的来源。

同一棵树换个视角看：

```coq
Check le : nat -> nat -> Prop.
Check le : relation nat.
Locate relation.
```

repl 输出：

```
le : nat -> nat -> Prop
     : nat -> nat -> Prop

le : relation nat
     : relation nat

Constant Top.Ex36Relations.relation
Constant Corelib.Relations.Relation_Definitions.relation
```

前两个 `Check` 是同一个项的两种读法——`relation nat` 按**定义**展开就是
`nat -> nat -> Prop`。`Locate relation` 揭示一个事实：标准库的
`Relation_Definitions` 模块**已经**定义了 `relation`，我们本地的定义把它遮蔽了（两个
Constant 并存，当前上下文优先用短的）。这个模块稍后会再见面，坑清单第 3 条。

### 偏函数：同一个输入不能有两个输出

**偏函数**是"确定性"的抽象：同一个 `x` 若能关联到 `y1` 又能关联到 `y2`，则 `y1 = y2`。

```coq
(* ---------- 偏函数：同一个输入不能有两个输出 ---------- *)

Definition partial_function {X : Type} (R : relation X) :=
  forall x y1 y2 : X, R x y1 -> R x y2 -> y1 = y2.
```

三个测试对象。第一个：`next_nat`——"恰好大 1"：

```coq
Inductive next_nat : nat -> nat -> Prop :=
  | nn (n : nat) : next_nat n (S n).

Check next_nat : relation nat.

Theorem next_nat_partial_function : partial_function next_nat.
Proof.
  unfold partial_function.
  intros x y1 y2 H1 H2.
  inversion H1. inversion H2.
  reflexivity.
Qed.
```

它是偏函数：反演两个推导都只能来自 `nn`，于是 `y1 = S x = y2`。第二个反例是 `le`
本身：

```coq
Theorem le_not_a_partial_function : ~ (partial_function le).
Proof.
  unfold not. unfold partial_function. intros Hc.
  assert (0 = 1) as Nonsense.
  { apply Hc with (x := 0).
    - apply le_n.
    - apply le_S. apply le_n. }
  discriminate Nonsense.
Qed.
```

证明"不是偏函数"的标准套路：`assert` 一个明显荒谬的等式，用 `apply Hc with (x := 0)`
从反证假设里**生产**它（0 ≤ 0 用 `le_n`，0 ≤ 1 用 `le_S`），最后 `discriminate`。
两个极端反例把这个概念的两端钉死：

```coq
Inductive total_relation : nat -> nat -> Prop :=
  | tr : forall n m : nat, total_relation n m.

Theorem total_relation_not_partial_function :
  ~ (partial_function total_relation).
Proof.
  unfold not. unfold partial_function. intros Hc.
  assert (0 = 1) as Nonsense.
  { apply Hc with (x := 0).
    - apply tr.
    - apply tr. }
  discriminate Nonsense.
Qed.

Inductive empty_relation : nat -> nat -> Prop :=.

Theorem empty_relation_partial_function :
  partial_function empty_relation.
Proof.
  unfold partial_function.
  intros x y1 y2 H1 H2.
  inversion H1.
Qed.
```

- `total_relation`（全关系）：所有对都成立——最"不确定"的关系，照样用同一套
  `assert (0 = 1)` 套路。
- `empty_relation`（空关系）：**零构造子**的归纳类型（注意 `:=.` 这个写法），没人能
  证明 `empty_relation x y`，所以 `inversion H1` 零分支直接关闭目标——空关系是偏函数
  的**平凡**例子。"真空确定性"也是确定性，这解释了为什么偏函数叫"**偏**"：它不保证
  有输出，只保证输出唯一。

### 自反与传递

```coq
(* ---------- 自反与传递 ---------- *)

Definition reflexive {X : Type} (R : relation X) :=
  forall a : X, R a a.

Theorem le_reflexive : reflexive le.
Proof.
  unfold reflexive. intros n. apply le_n.
Qed.
```

`le` 自反是 `le_n` 的直接复述。传递性有意思得多：

```coq
Definition transitive {X : Type} (R : relation X) :=
  forall a b c : X, R a b -> R b c -> R a c.

Print le_ind.

Theorem le_trans : transitive le.
Proof.
  unfold transitive. intros n m o Hnm Hmo.
  induction Hmo.
  - apply Hnm.
  - apply le_S. apply IHHmo.
Qed.
```

先看 `Print le_ind.` 的输出，它是本节的钥匙：

```
le_ind =
fun (n : nat) (P : nat -> Prop) (le_n : P n)
  (le_S : forall m : nat, n <= m -> P m -> P (S m)) =>
fix F (n0 : nat) (l : n <= n0) {struct l} : P n0 :=
  match l in _ <= n1 return P n1 with
  | Peano.le_n _ => le_n
  | Peano.le_S _ m l0 => le_S m l0 (F m l0)
  end
     : forall (n : nat) (P : nat -> Prop), ...
```

读法：对 `n <= m0` 的推导做归纳，动因（motive）是 `P m := n <= m`；两个分支分别对应
`le_n`（`m0 = n`，目标 `n <= n` 就是 `Hnm`）和 `le_S`（`m0 = S m`，前提给了
`n <= m` 的 IH，套一层 `le_S` 即可）。**对推导归纳，而不是对数字归纳**——这是 35 章
的主题在 `le` 上的第一次实战。

同一件事换三个证法，感受归纳对象的选择如何改变证明形状：

```coq
Theorem lt_trans : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  apply le_S in Hnm.
  apply le_trans with (a := S n) (b := S m) (c := o).
  - apply Hnm.
  - apply Hmo.
Qed.

Theorem lt_trans' : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  induction Hmo.
  - apply le_S. apply Hnm.
  - apply le_S. exact IHHmo.
Qed.

Theorem lt_trans'' : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  revert Hmo. induction o as [| o' IH]; intro H.
  - inversion H.
  - inversion H; subst.
    + apply le_S. apply Hnm.
    + apply le_S. apply IH. assumption.
Qed.
```

`lt` 在 Coq 里**定义为** `lt n m := S n <= m`（所以开头要 `unfold lt`）。

- `lt_trans`：完全不用归纳——把 `S n <= m`（即 `lt n m` 的展开）用 `le_S` 抬成
  `S n <= S m`，然后复用刚证好的 `le_trans`。**能用已有引理就别重新归纳**。
- `lt_trans'`：对第二个推导 `Hmo : m < o`（即 `S m <= o`）归纳，两个分支同 `le_trans`
  的形状。
- `lt_trans''`：**对 `o`（一个 nat）归纳**，所以要先 `revert Hmo`（它依赖 o；不 revert
  的话 IH 会太弱——"先归纳、后 intro"的老规矩）。两个分支里再用 `inversion H` 按
  `le` 的构造子拆。

三个证明都合法，工程上选**最省**的那个；教学上它们展示了"归纳什么"的自由度。

### 从传递性挤出三条小引理

下面三条引理后面反复用（反对称性、`le_Sn_n` 都靠它们）：

```coq
(* ---------- 从传递性挤出三条小引理 ---------- *)

Theorem le_Sn_le : forall n m, S n <= m -> n <= m.
Proof.
  intros n m H. apply le_trans with (S n).
  - apply le_S. apply le_n.
  - apply H.
Qed.

Theorem le_S_n : forall n m, S n <= S m -> n <= m.
Proof.
  intros n m H. inversion H as [ | m' Hm' ].
  - apply le_n.
  - apply le_Sn_le. assumption.
Qed.

Theorem le_Sn_n : forall n, ~ (S n <= n).
Proof.
  intros n H. induction n as [| n' IH].
  - inversion H.
  - apply IH. apply le_S_n. exact H.
Qed.
```

- `le_Sn_le`：左端剥一层。中间状态用 `le_trans with (S n)` 指定。
- `le_S_n`：两端同时剥一层。`inversion H as [ | m' Hm' ]` 命名分支——le 的推导要么
  是 `le_n`（那 `S n = S m`，`le_n` 收尾），要么是 `le_S`（前提 `S n <= m'` 且
  `S m = S m'`，用 `le_Sn_le` 剥左边）。
- `le_Sn_n`：**没有数严格小于自己**。对 n 归纳；`n = 0` 时 `S 0 <= 0` 反演即矛盾；
  归纳步用 `le_S_n` 把 `S (S n') <= S n'` 削成 `S n' <= n'`，正好是 IH。

标准库里多半已经有这些引理——用 `Search` 找，别自己造轮子：

```coq
Search (S _ <= S _ -> _ <= _).
Fail Check Nat.le_S_n.
Check Nat.nle_succ_diag_l.
Check Nat.le_trans.
```

repl 输出（第一段是 Search 的两条命中，第二段是 `Fail` 的真实报错——
`rocq compile` 下 `Fail` 静默，要看文本须进 repl）：

```
le_S_n: forall n m : nat, S n <= S m -> n <= m
Peano.le_S_n: forall n m : nat, S n <= S m -> n <= m

The command has indeed failed with message:
The reference Nat.le_S_n was not found in the current environment.
Did you mean Nat.le_1_r, Nat.le_0_r, Nat.le_0_l, ...?

Nat.nle_succ_diag_l
     : forall n : nat, ~ S n <= n

Nat.le_trans
     : forall n m p : nat, n <= m -> m <= p -> n <= p
```

**`Nat.le_S_n` 不存在**——它住在 `Peano` 命名空间里。否定形式 `~ S n <= n` 的标准名
是 `Nat.nle_succ_diag_l`。按名字猜引理是常见死法，`Search` 按形状找才可靠（坑清单
第 2 条）。

### 对称、反对称、等价与序

```coq
(* ---------- 对称、反对称、等价与序 ---------- *)

Definition symmetric {X : Type} (R : relation X) :=
  forall a b : X, R a b -> R b a.

Theorem le_not_symmetric : ~ (symmetric le).
Proof.
  unfold not. unfold symmetric. intros Hc.
  assert (1 <= 0) as Nonsense.
  { apply Hc. apply le_S. apply le_n. }
  inversion Nonsense.
Qed.
```

`le` 不对称（1 ≤ 0 是荒谬的：`le_S (le_n)` 造出 `0 <= 1`，喂给反证假设翻个面）。
注意结尾这次用 `inversion Nonsense` 而不是 `discriminate`——`1 <= 0` 的矛盾要靠
**归纳构造子的不可匹配**（`0` 是字面 `O`，`le_S` 造出的右端是 `S _`），`inversion`
能看穿，`discriminate` 只管构造子等式。

```coq
Definition antisymmetric {X : Type} (R : relation X) :=
  forall a b : X, R a b -> R b a -> a = b.

Theorem le_antisymmetric : antisymmetric le.
Proof.
  unfold antisymmetric. intros n.
  induction n as [| n' IH]; intros m Hnm Hmn.
  - inversion Hmn. reflexivity.
  - destruct m as [| m'].
    + inversion Hnm.
    + f_equal. apply IH.
      * exact (le_S_n _ _ Hnm).
      * exact (le_S_n _ _ Hmn).
Qed.
```

反对称：双向 ≤ 强制相等。证明对 n 归纳：`n = 0` 时反演 `0 <=? no Hmn : 0 <= m`……
具体看：`m` 若为 0，`inversion Hmn`（`0 <= 0` 只能是 le_n）后 `reflexivity`；`m = S m'`
时两侧用 `le_S_n` 各剥一层，`f_equal` 把目标 `S n' = S m'` 削成 `n' = m'`，交给 IH。
`exact (le_S_n _ _ Hnm)` 用下划线让 Coq 自己填 n、m——引理类型已经把形状钉死了。

三个组合定义收拢术语：

```coq
Definition equivalence {X : Type} (R : relation X) :=
  (reflexive R) /\ (symmetric R) /\ (transitive R).

Definition order {X : Type} (R : relation X) :=
  (reflexive R) /\ (antisymmetric R) /\ (transitive R).

Definition preorder {X : Type} (R : relation X) :=
  (reflexive R) /\ (transitive R).

Locate reflexive.
Check Relation_Definitions.transitive.
Check Relation_Definitions.preorder.

Theorem le_order : order le.
Proof.
  unfold order. split.
  - apply le_reflexive.
  - split.
    + apply le_antisymmetric.
    + apply le_trans.
Qed.

Theorem le_preorder : preorder le.
Proof.
  unfold preorder. split.
  - apply le_reflexive.
  - apply le_trans.
Qed.
```

- **等价关系** = 自反 + 对称 + 传递（例：相等、`iff`、44 章的类型等价）。
- **（偏）序** = 自反 + 反对称 + 传递——`le` 就是一个，`le_order` 把三件已证的成品拼
  起来（`split` 两层对应合取的右结合）。
- **预序** = 自反 + 传递（不含反对称）——`le_preorder`。为什么单独要它？因为很多
  自然的关系（比如"双方互推"之前的子类型关系）只到预序。

`Locate reflexive` 的 repl 输出：

```
Constant Corelib.Relations.Relation_Definitions.reflexive
  (shorter name to refer to it in current context is Relation_Definitions.reflexive)
```

和开头的 `Locate relation` 呼应：标准库这套定义真实存在且全名可达——`Check
Relation_Definitions.transitive` / `Check Relation_Definitions.preorder` 直接给出
类型。自己造轮子前先 `Locate` 一下（坑清单第 3 条）。

### 自反传递闭包

**闭包**是本章的压轴构造：给定 R，造一个"最小的自反传递关系包住 R"。标准库
`Relation_Operators` 里有两个版本，先看定义：

```coq
(* ---------- 自反传递闭包 ---------- *)

Print clos_refl_trans.
Print clos_refl_trans_1n.
Print clos_refl_trans_ind.
Search clos_refl_trans.
```

repl 输出（节选）：

```
clos_refl_trans (A : Type) (R : Relation_Definitions.relation A) 
(x : A) : A -> Prop :=
    rt_step : forall y : A, R x y -> clos_refl_trans A R x y
  | rt_refl : clos_refl_trans A R x x
  | rt_trans : forall y z : A,
               clos_refl_trans A R x y ->
               clos_refl_trans A R y z -> clos_refl_trans A R x z.

clos_refl_trans_1n (A : Type) (R : Relation_Definitions.relation A) 
(x : A) : A -> Prop :=
    rt1n_refl : clos_refl_trans_1n A R x x
  | rt1n_trans : forall y z : A,
                 R x y ->
                 clos_refl_trans_1n A R y z -> clos_refl_trans A R x z.
```

- `clos_refl_trans`：三构造子版（一步 / 零步 / 拼接）——就是 40 章引 ours 的 `star`
  的标准库原形。
- `clos_refl_trans_1n`：**1n 版**（"一步 + 余下"的右嵌套），形状和 40 章的 `multi`
  一致。

注意 `x` 是**参数**而终点是索引。于是下面的裸调用会挂：

```coq
Fail Check (clos_refl_trans next_nat 2 5).
Check (clos_refl_trans nat next_nat 2 5).
```

repl 输出：

```
The command has indeed failed with message:
The term "next_nat" has type "nat -> nat -> Prop"
while it is expected to have type "Type".

clos_refl_trans nat next_nat 2 5
     : Prop
```

`clos_refl_trans` 的 `A` 是**显式**参数（`Arguments clos_refl_trans A%_type_scope R x _`），
裸调用时 Coq 把 `next_nat` 塞给了 `A`。多写一个 `nat` 就好。坑清单第 1 条。

第一个实质定理：`next_nat` 的闭包**就是** `le`——"逐步 +1 到达"当且仅当"≤"：

```coq
Theorem next_nat_closure_is_le : forall n m,
  (n <= m) <-> (clos_refl_trans nat next_nat n m).
Proof.
  intros n m. split.
  - (* 把 <= 的证据拆成 next_nat 的若干步 *)
    intro H. induction H as [ | m' Hm' IH ].
    + apply rt_refl.
    + apply rt_trans with m'.
      * apply IH.
      * apply rt_step. apply nn.
  - (* 把闭包证据折回 <= *)
    intro H. induction H as [ x y Hxy | x | x y z Hxy IH1 Hyz IH2 ].
    + inversion Hxy. apply le_S. apply le_n.
    + apply le_n.
    + apply le_trans with y.
      * apply IH1.
      * apply IH2.
Qed.
```

两个方向各是一次归纳：

- `→`：对 `n <= m` 的推导归纳（又是推导归纳！）。`le_n` 分支零步（`rt_refl`）；
  `le_S` 分支：IH 给 `n ⇒ m'` 的闭包，再补一步 `next_nat m' (S m')`，用 `rt_trans
  with m'` 拼接。**中间点必须显式给**（`with m'`），`rt_trans` 的量词顺序不允许可试。
- `←`：对闭包推导归纳。`rt_step` 分支：`next_nat x y` 反演出 `y = S x`，目标是
  `x <= S x`（`le_S + le_n`）；`rt_refl` 分支 `le_n`；`rt_trans` 分支用 `le_trans
  with y` 拼 IH。

一个把 1n 版拆开用的小引理对：

```coq
Check rt1n_trans.
Check Relation_Operators.rt1n_trans.

Lemma rsc_R : forall (X : Type) (R : relation X) (x y : X),
  R x y -> clos_refl_trans_1n X R x y.
Proof.
  intros X R x y H.
  apply Relation_Operators.rt1n_trans with y.
  - apply H.
  - apply rt1n_refl.
Qed.
```

`Check rt1n_trans.` 输出：

```
rt1n_trans
     : forall (A : Type) (R : relation A) (x y z : A),
       R x y -> clos_refl_trans_1n A R y z -> clos_refl_trans_1n A R x z
```

两个细节：

- 构造子的 `A R x y z` 全是显式量词，但 `apply` 时它们都能从目标解出来，真正需要
  手写的只有**中间点**：`apply Relation_Operators.rt1n_trans with y`。全名前缀
  `Relation_Operators.` 在这里是必需的——`About rt1n_trans.` 实测显示这个短名还牵扯
  标准库的另一处同名缩写（见坑清单第 9 条）。
- `rsc_R` 把"单步"升级成"1n 闭包"：一步 + 立即 `rt1n_refl`。

```coq
Lemma rsc_trans : forall (X : Type) (R : relation X) (x y z : X),
  clos_refl_trans_1n X R x y ->
  clos_refl_trans_1n X R y z ->
  clos_refl_trans_1n X R x z.
Proof.
  intros X R x y z H1.
  induction H1 as [ | x' y' z' Hx' Hy'z' IH ].
  - intro H2. exact H2.
  - intro H2. apply Relation_Operators.rt1n_trans with y'.
    + apply Hx'.
    + apply IH. exact H2.
Qed.
```

1n 版的传递性：对第一段归纳——零步直接返回第二段；一步则把这一步放到最前面、其余
交给 IH。注意归纳时 `y`（拼接点）被 IH 泛化了，所以每个分支先 `intro H2`。

两个定义等价：

```coq
Theorem rtc_rsc_coincide : forall (X : Type) (R : relation X) (x y : X),
  clos_refl_trans X R x y <-> clos_refl_trans_1n X R x y.
Proof.
  intros X R x y. split.
  - intro H. induction H as [ | | x' y' z' H1 IH1 H2 IH2].
    + apply rsc_R. assumption.
    + apply rt1n_refl.
    + apply rsc_trans with y'.
      * apply IH1.
      * apply IH2.
  - intro H. induction H as [ | x' y' z' Hx' Hy'z' IH ].
    + apply rt_refl.
    + apply rt_trans with y'.
      * apply rt_step. exact Hx'.
      * exact IH.
Qed.
```

读法：→ 方向对三构造子版归纳，`rt_step` 分支用 `rsc_R`、`rt_trans` 分支用刚证的
`rsc_trans`；← 方向对 1n 版归纳，`rt1n_trans` 分支展开成 `rt_step` + `rt_trans`。
**两个方向各用各的归纳对象**——等价性证明的常规阵型。

手工铺一条具体的闭包链（`2 ⇒ 3 ⇒ 4 ⇒ 5`，末尾零步）：

```coq
Example closure_of_next_nat_from_2_to_5 :
  clos_refl_trans_1n nat next_nat 2 5.
Proof.
  apply Relation_Operators.rt1n_trans with 3.
  - apply nn.
  - apply Relation_Operators.rt1n_trans with 4.
    + apply nn.
    + apply Relation_Operators.rt1n_trans with 5.
      * apply nn.
      * apply rt1n_refl.
Qed.
```

三层嵌套的 `rt1n_trans`，中间点 3、4、5 全部显式——闭包的"运行轨迹"读起来就是执行
顺序，这正是 40 章 `multi` 手工链的预演。

### 正则闭包 star：多步语义的形状

标准库的两个版本都好用，但为教学起见自己造一个**参数化的** star——它是 40 章
`multi` / 标准库 `clos_refl_trans` 的直系亲属：

```coq
(* ---------- 正则闭包 star：多步语义的形状 ---------- *)

Inductive star {A : Type} (R : A -> A -> Prop) : A -> A -> Prop :=
  | nilr : forall x : A, star R x x
  | oner : forall x y : A, R x y -> star R x y
  | comp : forall x y z : A,
      star R x y -> star R y z -> star R x z.

Print star.

Lemma star_rt_same : forall (X : Type) (R : relation X) (x y : X),
  star R x y -> clos_refl_trans X R x y.
Proof.
  intros X R x y H. induction H as [ | | x' y' z' H1 IH1 H2 IH2].
  - apply rt_refl.
  - apply rt_step. assumption.
  - apply rt_trans with (y := y').
    + apply IH1.
    + apply IH2.
Qed.

End Ex36Relations.
```

`Print star.` 的 repl 输出：

```
Inductive star (A : Type) (R : A -> A -> Prop) : A -> A -> Prop :=
    nilr : forall x : A, star R x x
  | oner : forall x y : A, R x y -> star R x y
  | comp : forall x y z : A, star R x y -> star R y z -> star R x z.
```

- `A` 隐式（`{A : Type}`）、`R` 显式——**和标准库相反**。所以 `star next_nat 2 5`
  能直接写（对比坑 1 的 `clos_refl_trans nat next_nat 2 5`）。隐式/显式的选择直接
  决定使用体验。
- 三条构造子与 `clos_refl_trans` 逐条对得上，多出的 `oner`（一步直达）其实是
  `rt_step` + `rt_refl` 的语法糖——`star_rt_same` 的 `oner` 分支正是
  `apply rt_step. assumption.`（剩下的自反由 `rt_step` 的目标端 `rt_refl` 补……准确说：
  `oner` 分支的结论 `clos_refl_trans X R x y` 直接用 `rt_step`，因为 `rt_step` 的结论
  本身就是闭包，无需再补零步）。
- `comp` 分支的 `rt_trans with (y := y')` 用**具名参数**统一中间点——`rt_trans` 的
  量词名就叫 `y`。

40 章会在 `multi_iff_star` 里证明：`multi R x y <-> star R x y`。本章的
`star_rt_same` 把 star 接回标准库的 `clos_refl_trans`——三条通道（star / multi /
clos_refl_trans / clos_refl_trans_1n）从此互相打通。

### 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`clos_refl_trans` 的 `A` 是显式参数**：`Check (clos_refl_trans next_nat 2 5).` 报
   `The term "next_nat" has type "nat -> nat -> Prop" while it is expected to have
   type "Type"`。必须写 `clos_refl_trans nat next_nat 2 5`。自造的 `star` 把 A 设成
   隐式就没有这个问题——设计归纳类型时**参数的隐显**是 API 设计的一部分。
2. **标准库引理的命名空间会骗人**：`Nat.le_S_n` 不存在（`Fail Check` 实测报
   `The reference Nat.le_S_n was not found`），它住在 `Peano.le_S_n`；否定形式另有其名
   `Nat.nle_succ_diag_l`。按名字猜引理不如 `Search (S _ <= S _ -> _ <= _)` 按形状搜。
3. **本地定义遮蔽 `Relation_Definitions`**：`relation`、`reflexive`、`transitive`、
   `preorder` 在标准库里全都存在，本地 `Definition` 会把它们遮住；`Locate` 能看到两个
   Constant 并存。要用库版本时写全名 `Relation_Definitions.transitive`。教学文件自造
   是为了暴露定义，工程文件应当复用。
4. **对推导归纳 vs 对数字归纳**：`le_trans`（对 `Hmo : m <= o` 归纳）和 `lt_trans''`
   （对 `o` 归纳，先 `revert Hmo`）证的是同一类命题。选错对象时最常见的症状是 IH 太
   弱或分支里出现推导树无关的 case（`inversion H` 一堆）。先 `Print le_ind` 看清归纳
   原则的形状再动手。
5. **`inversion` 与 `discriminate` 的分工**：`1 <= 0` 的矛盾 `discriminate` 关不掉
   （不是构造子等式），`inversion` 可以；反之 `0 = 1` 这类构造子等式两者都行，习惯用
   `discriminate`（更便宜）。
6. **`Fail` 的报错文本只在 repl 里可见**：`rocq compile -q` 对 `Fail Check ...` 静默
   通过。本章引用的 `Did you mean ...` 列表来自 repl 实测。
7. **1n 版闭包的归纳会自动泛化拼接点**：`rsc_trans` 里 `induction H1` 之后每个分支要
   先 `intro H2`——第二段的起点 y 被归纳吃掉了。忘了 intro 会以为"目标里没有 H2 可用"。
8. **`empty_relation` 的零构造子定义**：`Inductive empty_relation : nat -> nat -> Prop
   :=.`——`:=` 后直接句号。空关系的偏函数性证明是 `inversion H1` 零分支，**没有**
   bullet 也没有后续 tactic；第一次写很容易误以为漏了东西。
9. **短名 `rt1n_trans` 一名两义**：`About rt1n_trans.` 实测显示它是
   `Operators_Properties` 里某个已证引理的**缩写**（`clos_rt1n_rt`，内容是"1n 版蕴含
   三构造子版"），而 `Relation_Operators.rt1n_trans` 是 `clos_refl_trans_1n` 的**构造子**
   ——两者类型不同。当前上下文里裸短名解析到构造子（`Check` 的输出可以确认），要引用
   构造子时写全名最稳。与坑 3 同族：Require Import 之后，短名归属要 `About` 一下。

---
上一章：[35 · 归纳原则解剖](35-induction-principles.md) ｜ 下一章：[37 · 自定义记号与语法](37-notation.md) ｜ 返回：[README](../README.md)
