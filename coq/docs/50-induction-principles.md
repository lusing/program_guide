# 50 · 归纳原则解剖

对应示例：`../examples/50_induction_principles.v`（`Module Ex50IndPrinciples`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

12 章学会了按下 `induction n` 之后目标自动裂成两半，49 章又看到"证明就是项"。把
两件事放在一起，一个很自然的问题冒出来：**`induction` 按下去的那一瞬，到底
`apply` 了什么东西？** 答案是：每当你用 `Inductive` 声明一个类型 `t`，Rocq 就
**自动生成**一条叫 `t_ind` 的定理——`induction` 的核心动作就是对它做 `apply`。
这条定理不是战术魔法，它是一条普通的引理，有类型、有证明项，可以被 `Check`、
`Print`、被你亲手重写。

本章沿三条线解剖它：

1. **生成配方**（50.1–50.4）：`t_ind` 的形状由构造子完全决定——每个构造子一格、
   每个递归参数一份归纳假设（IH）。看懂配方，就能从 `Inductive` 抄写出 `t_ind`，
   也能反过来从 `t_ind` 反推出 `Inductive`。
2. **IH 到底是什么**（50.5–50.6）：把归纳命题 `P` 起个名字让它现形；看清
   `induction` 替你做了哪些簿记（谁被再泛化、谁被自动引入）。
3. **自动的不够用就手搓**（50.7–50.9）：命题（`Prop`）的归纳原则长什么样、
   参数与索引如何影响原则强弱、以及怎么用 `fix` 手写一条"隔一步"的 `nat_ind2`、
   给嵌套元组树配一条带子树 IH 的原则。

51 章的 `Print le_ind`、53 章对 `ceval` 推导的归纳，用的全是本章的机制；本章把
那层"魔法"拆到底。

### 50.1 nat_ind：induction 背后那条定理

示例文件开头：

```coq
(* 35 归纳原则解剖 —— Inductive 一声明，Rocq 就送你一条 t_ind；本章拆开看它从哪来、长什么样、怎么手搓 *)

From Stdlib Require Import Arith List.
Import ListNotations.

Module Ex50IndPrinciples.

(* ---------- 50.1 nat_ind：induction 背后那条定理 ---------- *)
```

两个 import 的分工：`Arith` 提供 50.6 要用的 `Nat.add_0_r`；`List` + `ListNotations`
是为了 50.4 的 `Check list_ind` 断言里能写 `[]` 和 `::` 记号（缺了它实测报
`Syntax error: '.' expected after [lconstr]`，坑清单第 7 条）。本章不需要 `Lia`
——所有证明都是手工结构归纳，不碰算术决策过程。

第一条要看的东西是 `nat` 的归纳原则本身：

```coq
Check nat_ind :
  forall P : nat -> Prop,
    P 0 ->
    (forall n : nat, P n -> P (S n)) ->
    forall n : nat, P n.
```

`Check` 带 `:` 断言的写法（11 章介绍过）一边查询一边**验证**我们手抄的陈述和
Rocq 生成的一字不差。翻成中文：设 `P` 是关于自然数的一个性质（对每个 `n`，
`P n` 是一个命题）。要证 `P n` 对**所有** `n` 成立，只需证两件事：

- `P` 对 `0` 成立（`P 0`）；
- 对任意 `n`，若 `P` 对 `n` 成立，则 `P` 对 `S n` 成立。

这就是数学课上的归纳法，只不过被做成了**一条定理**。下面直接 `apply` 它来证明
12 章见过的老朋友——右乘零：

```coq
Theorem mul_0_r' : forall n : nat,
  n * 0 = 0.
Proof.
  apply nat_ind.
  - (* n = O *) reflexivity.
  - (* n = S n' *) simpl. intros n' IHn'. rewrite -> IHn'.
    reflexivity. Qed.
```

`apply nat_ind` 把目标按归纳原则的两个前提切成两个子目标：第一个是 `0 * 0 = 0`，
`reflexivity` 直接算掉；第二个是 `forall n, n * 0 = 0 -> S n * 0 = 0`，`simpl` 把
`S n' * 0` 归约成 `n' * 0`，`intros` 引入 `n'` 和归纳假设 `IHn'`，`rewrite` 之后
两边相同。和 12 章的 `induction n` 版本相比，证明骨架一模一样，但有**三处簿记
差异**值得逐条看清楚，它们正是 `induction` tactic 替你做的事：

1. **`intros` 要自己做**：`induction` 会自动引入 `n'` 和 IH 并命名；`apply` 不会。
2. **归纳变量不能提前 `intros`**：`apply` 匹配的是结论 `forall n : nat, P n`，
   所以目标必须还带着量词。
3. **原则要自己点名**：`apply nat_ind` 得写出名字，`induction` 自己推断。

其中第 2 条在原书（LF）里的说法是"提前 `intros` 会让 `apply` 失败"。**实测
rocq 9.3.0 它不失败，而是更糟**——看下面这个故意写坏的版本：

```coq
(* 若先 intros n 再 apply nat_ind：不报错，但 P 被选成 fun n0 => n * 0 = n0，
   归纳假设成了 n * 0 = n0 -> n * 0 = S n0，一步也用不上。 *)
Theorem mul_0_r'_after_intro : forall n : nat,
  n * 0 = 0.
Proof.
  intros n. apply nat_ind.
Abort.
```

repl 里 `intros n. apply nat_ind.` 之后的目标（真实输出节选）：

```text
  n : nat
  ============================
  n * 0 = 0

goal 2 is:
 forall n0 : nat, n * 0 = n0 -> n * 0 = S n0
```

`apply` 试图把 `nat_ind` 的结论 `forall n, P n` 和目标 `n * 0 = 0` 统一，于是
选了 **`P := fun n0 => n * 0 = n0`**——用上下文里那个**固定的** `n` 充当被乘数。
第一步 `P 0` 变成 `n * 0 = 0`（碰巧就是目标，能证），但第二步的归纳假设成了
`n * 0 = n0 -> n * 0 = S n0`，与想证的命题毫无关系，这条线走不通。教训比原书
更狠：**`apply` 归纳原则之前先 `Show` 一眼它选的 `P`；选错 `P` 时它往往不报错，
只是给你一个证不出来的目标。** 这里用 `Abort` 放弃，回到正确版本。

同一骨架再练一遍（原书留的练习，这里补全）：

```coq
Theorem plus_one_r' : forall n : nat,
  n + 1 = S n.
Proof.
  apply nat_ind.
  - reflexivity.
  - simpl. intros n' IHn'. rewrite -> IHn'. reflexivity.
Qed.
```

`0 + 1 = S 0` 是计算；归纳步里 `S n' + 1` 被 `simpl` 展成 `S (n' + 1)`，
`rewrite -> IHn'` 把内层换成 `S n'`，两边相同。注意这个证明**全程没写
`induction` 这个词**——你已经会绕过 tactic 直接用原则了。

### 50.2 每个构造子一格：time / rgb / natlist / natlist'

`Inductive` 声明的**每个**类型都有归纳原则——包括完全不递归的枚举。递归与否只
影响"格子里有没有 IH"，不影响"每个构造子一格"这个骨架。先看零参数构造子：

```coq
(* ---------- 50.2 每个构造子一格：time / rgb / natlist / natlist' ---------- *)

Inductive time : Type :=
  | day
  | night.

Check time_ind :
  forall P : time -> Prop,
    P day ->
    P night ->
    forall t : time, P t.
```

`time` 没有递归，`time_ind` 仍然有意义：它是"证 `P` 对 `time` 的**每个**值成立"
的方法——白昼一格、黑夜一格，证满即得。事实上 Rocq 每声明一个 `Type` 里的归纳
类型会生成**一整个家族**，repl 的回显（真实输出）是：

```text
time is defined
time_rect is defined
time_ind is defined
time_rec is defined
time_sind is defined
```

四条 `_rect`/`_ind`/`_rec`/`_sind` 分别服务于 `Type`/`Prop`/`Set` 消除与 `SProp`
消除——本章只关心 `Prop` 的 `_ind`，其余知道存在即可。三构造子的枚举也一样：

```coq
Inductive rgb : Type :=
  | red
  | green
  | blue.

Check rgb_ind.
```

```text
rgb_ind
     : forall P : rgb -> Prop,
       P red -> P green -> P blue -> forall r : rgb, P r
```

一格一构造子，没有任何惊喜。接下来是带参数的构造子：

```coq
Inductive natlist : Type :=
  | nnil
  | ncons (n : nat) (l : natlist).

Check natlist_ind :
  forall P : natlist -> Prop,
    P nnil ->
    (forall (n : nat) (l : natlist),
        P l -> P (ncons n l)) ->
    forall n : natlist, P n.
```

`ncons` 的两个参数里，`n : nat` 不是 `natlist`，**不产生** IH；`l : natlist` 是
递归参数，**产生**一份 `P l`。所以这一格读作："对任意 `n` 和 `l`，若 `P` 对
`l` 成立，则 `P` 对 `ncons n l` 成立。" IH 的份数 = 递归参数的个数，与参数总数
无关。

最后是本章第一个精细观察：**IH 插在哪个位置？** 把 `ncons` 的参数倒过来写：

```coq
Inductive natlist' : Type :=
  | nnil'
  | nsnoc (l : natlist') (n : nat).

Check natlist'_ind :
  forall P : natlist' -> Prop,
    P nnil' ->
    (forall l : natlist', P l -> forall n : nat, P (nsnoc l n)) ->
    forall n : natlist', P n.
```

`nsnoc` 的格子不再是"先量化全部参数、再列全部 IH"（`forall l n, P l -> P (nsnoc l n)`），
而是 **`forall l : natlist', P l -> forall n : nat, P (nsnoc l n)`**——关于 `l`
的 IH 紧贴在 `l` 被量化之后，然后才轮到 `n`。这不是排版巧合，是生成算法的忠实
输出：**量化一个参数，就立刻挂上它的 IH（如果有），再量化下一个。** 两条原则
逻辑上等价，但**类型不转换**（conversion 不会重排乘积），50.3 会用一个真实的
编译报错来证明这一点。综合起来，生成配方可以一表说尽：

| 构造子形状 | 生成的格子 |
|---|---|
| 无参数 `c` | `P c` |
| 带参数 `c (x1:a1) ... (xk:ak)` | `forall x1:a1, (P x1 ->)? ... forall xk:ak, (P xk ->)? P (c x1 ... xk)`，其中 `?` 处仅在 `ai = t`（被定义的类型本身）时出现 |

### 50.3 逆向工程：从归纳原则反推 Inductive

配方看懂之后可以做两个方向的练习。正向：给定 `Inductive`，**先在纸上**写出
`t_ind`，再和 Rocq 的输出对答案。反向：给定归纳原则，反推 `Inductive` 长什么样。
本节两个都做。

先正向。目标类型是"叶子带布尔、分支带布尔和两棵子树的树"：

```coq
(* ---------- 50.3 逆向工程：从归纳原则反推 Inductive ---------- *)

Inductive booltree : Type :=
  | bt_empty
  | bt_leaf (b : bool)
  | bt_branch (b : bool) (t1 t2 : booltree).
```

照配方，三个构造子三格。为了逼自己逐格写清楚，把每格做成一个独立的
`Definition`（这正是原书练习的形态，这里补全）：

```coq
Definition booltree_property_type : Type := booltree -> Prop.

Definition base_case (P : booltree_property_type) : Prop :=
  P bt_empty.

Definition leaf_case (P : booltree_property_type) : Prop :=
  forall b : bool, P (bt_leaf b).

Definition branch_case (P : booltree_property_type) : Prop :=
  forall (b : bool) (t1 : booltree),
    P t1 -> forall t2 : booltree, P t2 -> P (bt_branch b t1 t2).

Definition booltree_ind_type :=
  forall (P : booltree_property_type),
    base_case P ->
    leaf_case P ->
    branch_case P ->
    forall (b : booltree), P b.
```

`base_case` 无参数构造子，直接 `P bt_empty`。`leaf_case` 的 `b : bool` 不是
booltree，无 IH。`branch_case` 是关键：按 50.2 的"IH 紧贴量化"规则，它必须是
`forall b, forall t1, P t1 -> forall t2, P t2 -> P (bt_branch b t1 t2)`。我第一版
图省事写成了"先量化 `t1 t2` 再并排 `P t1 -> P t2`"，`exact` 时实测报：

```text
Error:
The term "booltree_ind" has type
 "forall P : booltree -> Prop,
  P bt_empty ->
  (forall b : bool, P (bt_leaf b)) ->
  (forall (b : bool) (t1 : booltree),
   P t1 -> forall t2 : booltree, P t2 -> P (bt_branch b t1 t2)) ->
  forall b : booltree, P b"
while it is expected to have type "booltree_ind_type" (cannot unify
"P t1" and "booltree").
```

错误信息把正确答案整个打印出来了——`cannot unify "P t1" and "booltree"` 正是
"量词结构错位"的体现。修正后，验证只要一条 tactic：

```coq
Theorem booltree_ind_type_correct : booltree_ind_type.
Proof. exact booltree_ind. Qed.
```

`exact booltree_ind` 能过，说明手写的 `booltree_ind_type` 和自动生成的
`booltree_ind` **类型完全一致**（`exact` 要求逐字转换，不放宽）。纸上练习的
对答案方式就是这一行。

再反向。给定原则（改写自原书练习）：

```text
  forall P : Toy -> Prop,
    (forall b : bool, P (f b)) ->
    (forall (n : nat) (t : Toy), P t -> P (g n t)) ->
    forall t : Toy, P t
```

两个构造子：`f` 吃一个 `bool`、不吃 `Toy`，所以格子无 IH；`g` 吃一个 `nat`
和一个 `Toy`，后者给一份 IH。反推出的定义与验证：

```coq
Inductive Toy : Type :=
  | con1 (b : bool)
  | con2 (n : nat) (t : Toy).

Theorem Toy_correct : exists f g,
  forall P : Toy -> Prop,
    (forall b : bool, P (f b)) ->
    (forall (n : nat) (t : Toy), P t -> P (g n t)) ->
    forall t : Toy, P t.
Proof.
  exists con1, con2.
  exact Toy_ind.
Qed.
```

陈述用 `exists f g` 把两个构造子**藏起来**（练习不许你直接写 `con1`/`con2`，
逼你从原则反推），`exists con1, con2.` 一次提供两个见证，剩下 `exact Toy_ind`
收尾——能一行过，证明反推正确。（原书另有两个同型练习 mytype/foo，手法与
`Toy` 完全相同，本章舍去以免重复。）

### 50.4 多态：参数化的归纳原则

多态列表是**一族**类型——对每个 `X` 有一个 `list X`。它的归纳原则也相应地整条
被 `X` 参数化：

```coq
(* ---------- 50.4 多态：参数化的归纳原则 ---------- *)

Check list_ind :
  forall (X : Type) (P : list X -> Prop),
    P [] ->
    (forall (x : X) (l : list X), P l -> P (x :: l)) ->
    forall l : list X, P l.
```

读法：`list_ind` 是一个**多态函数**——喂它一个类型 `X`，它还你一条专属于
`list X` 的归纳原则。注意与 50.2 的 `natlist_ind` 逐字对照：把 `X` 换成 `nat`、
`[]`/`::` 换回 `nnil`/`ncons`，两条原则一模一样。声明里 `(X : Type)` 放在冒号前
（**参数**，处处相同）还是冒号后（**索引**，随构造子变化），会深刻影响原则的
形状——50.7 的 `le1`/`le2` 对比会把这一点说透。

参数化自己的树：

```coq
Inductive tree (X : Type) : Type :=
  | leaf (x : X)
  | node (t1 t2 : tree X).

Check tree_ind :
  forall (X : Type) (P : tree X -> Prop),
    (forall x : X, P (leaf X x)) ->
    (forall t1 : tree X,
        P t1 -> forall t2 : tree X, P t2 -> P (node X t1 t2)) ->
    forall t : tree X, P t.
```

两个细节。其一，`node` 的格子是 `forall t1, P t1 -> forall t2, P t2 -> ...`——
又是"IH 紧贴量化"，这次两份 IH 交错在两个量词之间，比 `booltree` 那次更醒目。
其二，`leaf X x`、`node X t1 t2` 里**构造子的参数 `X` 是显式的**：打印原则时
`X` 会出现。如果你在 `Check` 断言里写 `P (node t1 t2)`（漏掉 `X`），实测报：

```text
Error:
In environment
X : Type
P : foo' X -> Prop
The term "C2" has type "forall X : Type, foo' X"
while it is expected to have type "foo' X".
```

（这是另一个构造子 `C2` 上截获的同型报错。）记住不对称的规则：**项位置构造子
参数显式，模式位置可以省**。最后看"构造子参数里嵌了别的归纳类型"：

```coq
Inductive foo' (X : Type) : Type :=
  | C1 (l : list X) (f : foo' X)
  | C2.

Check foo'_ind :
  forall (X : Type) (P : foo' X -> Prop),
    (forall (l : list X) (f : foo' X), P f -> P (C1 X l f)) ->
    P (C2 X) ->
    forall f : foo' X, P f.
```

`C1` 的两个参数里只有 `f : foo' X` 拿到 IH（`P f`）；`l : list X` 不是 `foo' X`，
一份 IH 都没有。**自动生成器只对"被定义类型本身"的参数给 IH，嵌套进来的
`list X` 不给**——这半句话是 50.9 全部麻烦的根源。

### 50.5 归纳假设：给 P 起个名字

"归纳假设"（induction hypothesis）这个词终于可以精确定义了。回到 `nat_ind`：
它对所有 `P` 都成立，每次使用时我们**选定**一个 `P : nat -> Prop`。把这个选择
显式写出来，IH 就现形了：

```coq
(* ---------- 50.5 归纳假设：给 P 起个名字 ---------- *)

Definition P_m0r (n : nat) : Prop :=
  n * 0 = 0.

Definition P_m0r' : nat -> Prop :=
  fun n => n * 0 = 0.
```

两种写法等价：第一种是"带参定义"（26 章之前的常规形态），第二种直接给出
`nat -> Prop` 的匿名函数——`P_m0r` 和 `P_m0r'` 展开后是同一个东西。用它重述
定理：

```coq
Theorem mul_0_r'' : forall n : nat,
  P_m0r n.
Proof.
  apply nat_ind.
  - (* n = O *) reflexivity.
  - (* n = S n' *)
    intros n IHn.
    unfold P_m0r in IHn. unfold P_m0r. simpl. apply IHn.
Qed.
```

`apply nat_ind` 之后，第一个子目标是 `P_m0r 0`——**字面上**的"零也满足性质"；
第二个是 `forall n', P_m0r n' -> P_m0r (S n')`。`intros n IHn` 引入后，`IHn` 的
类型是 `P_m0r n`，还裹在定义里；`unfold P_m0r in IHn` 把它拆成 `n * 0 = 0`，
`unfold P_m0r` 拆目标，`simpl` 之后两边都是 `n * 0 = 0`，`apply IHn` 收尾。于是
得到 IH 的定义：**归纳假设就是归纳步那一格里的前提 `P n'`——"性质对前驱成立"
这条可以被免费使用的假设。** 平时写证明不需要这个起名仪式，但做过一两次，
"IH 从哪来、是什么"就再也不会模糊。

### 50.6 induction 的再概括：谁被泛化、谁被引入

`induction` tactic 比上一节看到的还多做一层簿记。回忆 12 章的加法结合律：

```coq
(* ---------- 50.6 induction 的再概括：谁被泛化、谁被引入 ---------- *)

Theorem add_assoc' : forall n m p : nat,
  n + (m + p) = (n + m) + p.
Proof.
  intros n m p.
  induction n as [| n'].
  - (* n = O *) reflexivity.
  - (* n = S n' *)
    simpl. rewrite -> IHn'. reflexivity. Qed.
```

`intros n m p` 先把三个变量**全部**引进上下文——"考虑任意的 `n`、`m`、`p`"。
紧接着 `induction n` 却要证关于**所有** `n` 的事。Rocq 内部做的事叫**再概括**
（re-generalization）：把 `n` 从上下文里抽回目标，套用 `nat_ind`，再把结果特化回
当前的 `n`。你写两行，它替你完成了"引进—抽出—归纳—放回"的整个循环。

如果归纳变量是**目标里的量词**而非上下文变量，`induction` 也能直接下手：

```coq
Theorem add_comm' : forall n m : nat,
  n + m = m + n.
Proof.
  induction n as [| n'].
  - (* n = O *) intros m. rewrite -> Nat.add_0_r. reflexivity.
  - (* n = S n' *) intros m. simpl. rewrite -> IHn'.
    rewrite <- plus_n_Sm. reflexivity. Qed.
```

注意第一个分支里 `intros m` 出现在 bullet **之后**：`induction n` 只对 `n` 下手，
`m` 仍以量词留在两个子目标里——所以每个分支要各自 `intros m`。相应地，归纳步
的 `IHn'` 是 `forall m, n' + m = m + n'`：**`m` 留在量词里，IH 就对一切 `m`
成立**，这个细节常常是证明能否续下去的关键。收尾用两条标准库引理：`Nat.add_0_r`
（`n + 0 = n`）正向重写消掉 `m + 0`；`plus_n_Sm`（`S (n + m) = n + S m`）反向
重写把 `m + S n'` 搬成 `S (m + n')`，两边对齐。原书（LF）这两条引理来自它自己的
Basics 章，这里升级为标准库现成货——效果完全相同。

第三种阵型：归纳目标出现在**别的量词之后**：

```coq
Theorem add_comm'' : forall n m : nat,
  n + m = m + n.
Proof.
  (* 对 m 归纳，n 由 induction 自动引入 *)
  induction m as [| m'].
  - (* m = O *) simpl. rewrite -> Nat.add_0_r. reflexivity.
  - (* m = S m' *) simpl. rewrite <- IHm'.
    rewrite <- plus_n_Sm. reflexivity. Qed.
```

这次对 `m` 归纳，而 `m` 排在 `n` 后面——`induction` 会**自动把挡在前面的量词
引入**上下文（注释里那行说的就是这件事），所以开头一个 `intros` 都不用写。
两个分支的形状与 `add_comm'` 镜像对称：`IHm'` 里不再有量词（`n` 已固定），
反向重写 `<- IHm'` 把右边的 `m' + n` 换成 `n + m'`，再 `<- plus_n_Sm` 收尾。
三种阵型（上下文变量 / 目标量词 / 目标量词但非首个）`induction` 全部接得住——
这就是它比手工 `apply t_ind` 好用的全部原因，而代价只是你要清楚它替你做了什么。

### 50.7 命题的归纳原则：ev / ev' / le2

`Inductive` 不只能定义数据（`Type`），还能定义**命题**（`Prop`，15 章的归纳
谓词）。命题同样自动获得归纳原则，而且形状里藏着新东西。定义"偶数"的证据：

```coq
(* ---------- 50.7 命题的归纳原则：ev / ev' / le2 ---------- *)

Inductive ev : nat -> Prop :=
  | ev_0 : ev 0
  | ev_SS : forall n : nat, ev n -> ev (S (S n)).

Print ev.
```

```text
Inductive ev : nat -> Prop :=
    ev_0 : ev 0 | ev_SS : forall n : nat, ev n -> ev (S (S n)).

Arguments ev _%_nat_scope
Arguments ev_SS n%_nat_scope _
```

（原书从它的 IndProp 章导入 `ev`，本章按自包含原则就地重定义。）回显里的两行
`Arguments` 是 Rocq 自动补的作用域纪律：`ev` 的那个 `_` 占位参数按 `nat_scope`
解析，`ev_SS` 的 `n` 同理、证据参数无作用域。注意 `Prop` 里的归纳类型回显只生成
**两条**方案（`ev_ind`、`ev_sind`）而非 `Type` 的四条——没有 `ev_rect`/`ev_rec`，
因为原则上 `Prop` 里的证据不允许被消除出任意类型（49 章证明项视角的又一次呼应）。
看原则本身：

```coq
Check ev_ind :
  forall P : nat -> Prop,
    P 0 ->
    (forall n : nat, ev n -> P n -> P (S (S n))) ->
    forall n : nat, ev n -> P n.
```

与 `nat_ind` 相比有两处结构变化，都源于"`ev` 是**索引**在 `nat` 上的命题"：

- 结论不是 `forall n, P n`，而是 `forall n, ev n -> P n`——原则只对**有偶性证据**
  的数字作保证；
- 归纳步的格子里除了 `P n -> P (S (S n))`，还多出一个前提 `ev n`——构造子
  `ev_SS` 自己携带的那份子证据。

也就是说：**构造子的每个递归前提贡献两样东西——前提本身一份、对应 IH 一份。**
用它直接证明 `ev` 蕴含另一个定义的偶数谓词 `ev'`：

```coq
Inductive ev' : nat -> Prop :=
  | ev'_0 : ev' 0
  | ev'_2 : ev' 2
  | ev'_sum n m (Hn : ev' n) (Hm : ev' m) : ev' (n + m).

Theorem ev_ev' : forall n, ev n -> ev' n.
Proof.
  apply ev_ind.
  - (* ev_0 *)
    apply ev'_0.
  - (* ev_SS *)
    intros m Hm IH.
    apply (ev'_sum 2 m).
    + apply ev'_2.
    + apply IH.
Qed.
```

`ev'` 用"零、二、和"三条规则定义偶性，与 `ev` 的"零、加二"风格不同。
`apply ev_ind` 切出两格：零格直接 `ev'_0`；加二格引入 `m`、子证据 `Hm`、IH，
目标 `ev' (S (S m))`。关键一步是 `apply (ev'_sum 2 m)`——`ev'_sum` 的结论是
`ev' (n + m)`，`n + m` 无法与字面 `S (S m)` 统一，所以必须**显式实例化**两个
参数（`2` 与 `m`），把目标变成 `ev' 2` 与 `ev' m` 两个子目标，前者 `ev'_2`、
后者交给 IH。

接下来是定义写法对原则的影响。同一个"小于等于"写成两种等价定义：

```coq
Inductive le1 : nat -> nat -> Prop :=
  | le1_n : forall n, le1 n n
  | le1_S : forall n m, (le1 n m) -> (le1 n (S m)).

Notation "m <=1 n" := (le1 m n) (at level 70).

Inductive le2 (n : nat) : nat -> Prop :=
  | le2_n : le2 n n
  | le2_S m (H : le2 n m) : le2 n (S m).

Notation "m <=2 n" := (le2 m n) (at level 70).

Check le1_ind :
  forall P : nat -> nat -> Prop,
    (forall n : nat, P n n) ->
    (forall n m : nat, n <=1 m -> P n m -> P n (S m)) ->
    forall n n0 : nat, n <=1 n0 -> P n n0.

Check le2_ind :
  forall (n : nat) (P : nat -> Prop),
    P n ->
    (forall m : nat, n <=2 m -> P m -> P (S m)) ->
    forall n0 : nat, n <=2 n0 -> P n0.
```

`le1` 把两个参数都写在冒号后（全是索引），`le2` 观察到左参数在两条构造子里
从不变化，把它**提升为参数**放在冒号前。两个记号 `<=1`/`<=2`（`at level 70`，
与 `<=` 同级）只是让断言可读。对比两条原则：`le1_ind` 的 `P` 是**二元**谓词
`nat -> nat -> Prop`，每格都要对两个索引全称量化；`le2_ind` 的 `n` 被 frozen 成
参数，`P` 只是一元 `nat -> Prop`，格子干净得多。**同样的关系，定义摆放方式
直接决定归纳原则的复杂度**——51 章 `Print le` 时你会看到标准库选的正是 `le2`
这种摆法（`le (n : nat) : nat -> Prop`）。

最后看"原则的另一形态"。`ev_ind` 的 `P` 只以 `n` 为参数；其实原则还可以让
`P` 以**证据本身**为参数（依赖消除），`Scheme` 命令能把它现生成出来：

```coq
Scheme ev_dep := Induction for ev Sort Prop.
Check ev_dep.
```

```text
ev_dep
     : forall P : forall n : nat, ev n -> Prop,
       P 0 ev_0 ->
       (forall (n : nat) (e : ev n), P n e -> P (S (S n)) (ev_SS n e)) ->
       forall (n : nat) (e : ev n), P n e
```

`P` 的类型变成了 `forall n, ev n -> Prop`，两个格子也相应带上 `ev_0`、
`ev_SS n e` 这些**构造子项**。这给了原则更多自由——它可以证明"同时涉及数字
**和**其偶性证据"的命题（例如"任何 `ev n` 的证据都规约到 `ev_0`/`ev_SS` 的
某个组合"这类关于证据结构的断言）。但我们平时关心的只是数字的性质，用不到
这份自由，所以 Rocq 默认生成的是更简单的 `ev_ind`。原书对这一节只用文字描述
（还把假想的类型里的构造子写作 `ev''`/`even`），本教程升级为直接 `Scheme`
生成、`Check` 验证——看得见摸得着。

### 50.8 手写归纳原则：从 build_proof 到 nat_ind2

至此 `t_ind` 一直被视为"Rocq 送的"。现在拆穿它：**它没有任何魔法，只是一条
需要证明的普通引理，证明项是一个 `fix`。** 看真身：

```coq
(* ---------- 50.8 手写归纳原则：从 build_proof 到 nat_ind2 ---------- *)

Print nat_ind.
```

```text
nat_ind =
fun (P : nat -> Prop) (O : P 0) (S : forall n : nat, P n -> P (S n)) =>
fix F (n : nat) : P n :=
  match n as n0 return P n0 with
  | 0 => O
  | Datatypes.S n0 => S n0 (F n0)
  end
     : forall P : nat -> Prop,
       P 0 -> (forall n : nat, P n -> P (S n)) -> forall n : nat, P n

Arguments nat_ind P%_function_scope O S%_function_scope n%_nat_scope
```

逐块读：取三个参数 `P`、零的证明、归纳步的证明（注意绑定名就叫 `O` 和 `S`，
**遮蔽**了构造子——Rocq 生成的代码也玩这种把戏）；然后一个 `fix F` 对 `n`
结构递归：`n = 0` 时返回零证明，`n = S n0` 时递归调用 `F n0` 得到 `P n0` 的
证明，喂给归纳步 `S n0 (F n0)` 得到 `P (S n0)`。`match n as n0 return P n0`
是依赖匹配的注记（26 章）。这个证明项我们完全可以自己写一遍，甚至更好读：

```coq
Fixpoint build_proof
         (P : nat -> Prop)
         (evPO : P 0)
         (evPS : forall n : nat, P n -> P (S n))
         (n : nat) : P n :=
  match n with
  | 0 => evPO
  | S k => evPS k (build_proof P evPO evPS k)
  end.

Definition nat_ind_tidy := build_proof.
```

`build_proof` 与上面 `Print` 出的项**逐结构相同**，只是参数名起了有意义的名字
（证据-`P`-零、证据-`P`-步），并用 `Fixpoint` 语法代替裸 `fix`。它自己的归纳
原则就是它自己——用 `Definition` 起个别名，就能当归纳原则用：

```coq
Theorem mul_0_r''' : forall n : nat,
  n * 0 = 0.
Proof.
  induction n as [ | n' IHn'] using nat_ind_tidy.
  - reflexivity.
  - simpl. rewrite -> IHn'. reflexivity.
Qed.
```

`induction ... using <原则>` 让 `induction` 改用我们指定的原则（顺带验证：
手搓的和官方的可以无缝互换）。既然原理已经透明，就能造**官方不提供**的原则。
动机例子：判定函数版偶数与证据版偶数的桥接。先自造判定函数（原书用的是它
Basics 章的 `even`，标准库 `Nat.even` 也行，但为了全章自包含这里就地定义）：

```coq
Fixpoint evenb (n : nat) : bool :=
  match n with
  | O => true
  | S O => false
  | S (S n') => evenb n'
  end.
```

想证 `evenb n = true -> ev n`。用**普通** `nat_ind` 试一次，看它死在哪：

```coq
Lemma even_ev_first_try : forall n : nat,
  evenb n = true -> ev n.
Proof.
  induction n as [| n' IHn']; intros H.
  - (* n = O *) apply ev_0.
  - (* n = S n' *)
    destruct n' as [| n''].
    + simpl in H. inversion H.
    + simpl in H. apply ev_SS.
      (* 卡住：IHn' 只说 evenb (S n'') = true -> ev (S n'')，
         而目标是 ev n'' —— 普通归纳的 IH 永远“差一步”。 *)
Abort.
```

零格 `ev_0` 收；`S` 格里 `evenb (S n')` 归约不动（匹配要看到 `n'` 的形状），
`destruct` 再劈一刀：`n' = 0` 时 `evenb 1 = false = true` 被 `inversion` 干掉；
`n' = S n''` 时 `simpl in H` 得 `evenb n'' = true`，目标 `ev (S (S n''))`，
`apply ev_SS` 之后剩 `ev n''`——而 IH 说的却是 `evenb (S n'') = true -> ev (S n'')`
（关于 `S n''`，不是 `n''`）。**归纳假设永远"差一步"**，证不下去。绕路的办法
不是没有（把命题加强成"对 `n` 和 `S n` 同时成立"再归纳），但更漂亮的做法是
造一条**步长为 2** 的归纳原则：

```coq
Definition nat_ind2 :
  forall (P : nat -> Prop),
  P 0 ->
  P 1 ->
  (forall n : nat, P n -> P (S (S n))) ->
  forall n : nat, P n :=
  fun P P0 P1 PSS =>
    fix f (n : nat) :=
      match n with
      | 0 => P0
      | 1 => P1
      | S (S n') => PSS n' (f n')
      end.
```

读法和 `build_proof` 一模一样，只有两处不同：多一个 `P 1` 基例（步长 2 的归纳
需要**两个**起点），递归匹配的最后一格是 `S (S n')`——对 `n'`（而非 `S n'`）
递归，所以守卫检查照常通过。类型部分照抄官方配方，`:=` 右边直接给**证明项**
（`fun P P0 P1 PSS => fix f ...`），不用任何 tactic——原书说得对：这种原则
**用 tactic 证反而别扭，写项是直觉的**。用它一步拿下：

```coq
Lemma even_ev : forall n, evenb n = true -> ev n.
Proof.
  intros n H.
  induction n as [ | | n'] using nat_ind2.
  - (* n = 0 *) apply ev_0.
  - (* n = 1 *) simpl in H. inversion H.
  - (* n = S (S n') *) simpl in H. apply ev_SS.
    apply IHn'. exact H.
Qed.
```

`induction ... using nat_ind2` 切出**三**格（`as [ | | n']` 对应 0 / 1 / 加二，
两个基例不绑定名字）；`induction` 自动把依赖归纳变量的 `H` 再泛化、在各格
重新引入，所以第三格里 `H : evenb (S (S n')) = true`、`IHn' : evenb n' = true ->
ev n'`——**正好对上**：`simpl in H` 后 `evenb n' = true` 就是 IH 要的前提。
差一步的问题被原则本身的结构消掉了。

### 50.9 非标准原则实战：t_tree 的自定义归纳

最后一场实战：自动生成的原则**不够用**时，手搓一条并完成原书留作四星练习的
定理。类型是"分支把左右子树、标签打成一个三元组"的树：

```coq
(* ---------- 50.9 非标准原则实战：t_tree 的自定义归纳 ---------- *)

Inductive t_tree (X : Type) : Type :=
  | t_leaf
  | t_branch : (t_tree X * X * t_tree X) -> t_tree X.

Arguments t_leaf {X}.
Arguments t_branch {X}.

Check t_tree_ind.
```

```text
t_tree_ind
     : forall (X : Type) (P : t_tree X -> Prop),
       P t_leaf ->
       (forall p : t_tree X * X * t_tree X, P (t_branch p)) ->
       forall t : t_tree X, P t
```

（两条 `Arguments ... {X}` 把构造子的参数设为隐式，之后写 `t_leaf`、
`t_branch p` 不必带 `X`——18 章 Arguments 的老朋友。）问题一目了然：
`t_branch` 的参数是一个**整体的三元组** `p`，按 50.4 末尾的配方，`p : t_tree X
* X * t_tree X` 不是 `t_tree X`，**一份 IH 都没有**。用这条原则对树做归纳，
等于对每个分支只拿到"某个三元组存在"，完全推不动。麻烦还不止这个：声明
本身在编译时刷了四遍警告（每生成一条方案一遍，真实文本）：

```text
Warning: t_tree is nested using prod. No scheme for prod is registered as
All. It can be generated using command "Scheme All" e.g. "Scheme All for
prod.". [register-all,automation,default]
```

`prod` 被"嵌套"使用（构造子参数里出现了 `t_tree X * ...`），而 `prod` 没注册
全套方案——警告无害，想消除可以照提示 `Scheme All for prod.`，本章选择留着它
当作观测样本。先定义镜像函数（交换左右子树）：

```coq
Fixpoint reflect {X : Type} (t : t_tree X) : t_tree X :=
  match t with
  | t_leaf => t_leaf
  | t_branch (l, v, r) => t_branch (reflect r, v, reflect l)
  end.
```

`match` 的模式 `t_branch (l, v, r)` 用嵌套模式直接把三元组拆开（7 章）；
递归调用发生在 `l`、`r` 上，它们是 `t` 的结构子项，守卫检查放行。要证的目标
是"镜像两次回到原树"——用自动原则做不到（没有子树 IH），所以手搓一条带 IH
的原则，**类型照抄 50.2 的配方（这次三个参数摊开而不是打包），证明项照抄
`build_proof` 的骨架**：

```coq
Definition t_tree_ind_better :
  forall (X : Type) (P : t_tree X -> Prop),
  P t_leaf ->
  (forall (l : t_tree X) (v : X) (r : t_tree X),
      P l -> P r -> P (t_branch (l, v, r))) ->
  forall t : t_tree X, P t :=
  fun X P Hleaf Hbranch =>
    fix F (t : t_tree X) : P t :=
      match t with
      | t_leaf => Hleaf
      | t_branch (l, v, r) => Hbranch l v r (F l) (F r)
      end.
```

对照着读：分支格现在是 `forall l v r, P l -> P r -> P (t_branch (l, v, r))`
——两份 IH，正是 `tree_ind`（50.4）该有的样子。证明项里 `fix F` 对 `t` 递归，
`F l`、`F r` 递归于嵌套模式解构出的两棵子树，守卫检查认可（10 章的"结构
递归"对嵌套模式同样生效）。拿它证定理：

```coq
Theorem reflect_involution : forall (X : Type) (t : t_tree X),
  reflect (reflect t) = t.
Proof.
  intros X t.
  induction t using t_tree_ind_better.
  - (* t_leaf *) reflexivity.
  - (* t_branch (t1, v, t2) *) simpl. rewrite IHt1. rewrite IHt2.
    reflexivity.
Qed.

Print Assumptions reflect_involution.
```

`induction t using t_tree_ind_better` 两格：叶子格 `reflexivity` 计算
`reflect (reflect t_leaf) = t_leaf`；分支格**不需要 `intros`**——`using` 的方案
会把格子里的量词和 IH 全部自动引入（名字自动取 `t1`、`v`、`t2`、`IHt1`、
`IHt2`，见坑清单第 4 条），`simpl` 把 `reflect (reflect (t_branch ...))` 展成
`t_branch (reflect (reflect t1), v, reflect (reflect t2))`，两条 IH 一改写，
两边相同。结尾的问询实测输出 `Closed under the global context`——整个证明
（包括手搓的原则）不依赖任何公理。

收尾一行：

```coq
End Ex50IndPrinciples.
```

三行总结本章：`t_ind` 是 `Inductive` 赠送的、由构造子配方决定的普通定理；
`induction` 是它的一层贴心包装；包装不合身（IH 差一步、嵌套类型不给 IH）时，
配方 + `fix` 就能自己造。

### 形式证明与非形式证明

本章一直在"引擎盖下"看形式证明，正好把**写给人看的**非形式证明说清楚。两者的
关系是：非形式证明应当把读者理解并复现形式证明所需的一切**教**给他。详略没有
唯一标准——一头是把形式证明逐 tactic 翻译成文字（读者能照抄，但学不到东西），
另一头是"定理显然成立"（读者会在你发现证明的那个洞察前放弃）。黄金中间带是：
**写全所有关键洞察 + 每格的 IH 与目标 + 例行步骤的提示，但不淹没主线。** 两个
模板（以 51 章证过的 `le_trans` 为例）。

对**数据**（归纳对象在 `Type` 里）归纳的模板：

- **定理**：形如"对所有 `x : S`，`P(x)`"，`S` 是归纳定义的集合。
- **证明**：对 `x` 归纳。
  - 设 `x = c a1 ... ak`（构造子 `c` 的参数），其中类型为 `S` 的参数各有一份
    IH（"设 `a` 满足 P"）。要证 `P(c a1 ... ak)`。**（此处完成该格）**
  - 其余构造子同样处理。

对**证据**（归纳对象在 `Prop` 里，通常叫"对推导归纳"）归纳的模板：

- **定理**：形如 `Q -> P`，`Q` 是归纳定义的命题（一般化为"对所有 `x y z`，
  `Q x y z -> P x y z`"）。
- **证明**：对 `Q` 的推导归纳。
  - 设最后一条用的是构造子 `c`。此时推导的形状给出一组等式（从 `c` 的定义
    得知各索引的值）和每个递归前提对应的 IH。要证 `P`。**（此处完成该格）**
  - 其余构造子同样处理。

对照 `le_trans`（51 章）：对 `m <= o` 的推导归纳——`le_n` 格推出 `m = o`，目标
变成手头的假设 `n <= m`；`le_S` 格推出 `o = S o'` 且有 IH `n <= o'`，套一层
`le_S` 得 `n <= S o'`。这两句话足以让读者重建 51 章的四行 tactic 证明——
这就是"教"与"抄"的区别。

### 50.10 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **IH 的插入位置紧跟参数量化，"先量化后并列 IH"的类型不转换**（50.3）：
   `branch_case` 第一版写成 `forall b (t1 t2 : booltree), P t1 -> P t2 -> ...`，
   `exact booltree_ind` 实测报 `cannot unify "P t1" and "booltree"`（全文见
   50.3）。两个陈述逻辑等价，但 conversion 不重排乘积——手抄归纳原则必须按
   "量化一个、挂一个 IH"的原样抄。
2. **`intros` 之后再 `apply nat_ind` 不会失败，而是选一个没用的 motive**
   （50.1）：实测生成 `goal 2 is: forall n0 : nat, n * 0 = n0 -> n * 0 = S n0`
   （`P := fun n0 => n * 0 = n0`）。比报错危险——你只看到两个证不动的目标，
   不知道 `P` 早已走偏。原书"apply 需要目标带量词否则失败"的说法在 9.3 已
   不准确。
3. **`induction ... using ... as ...` 的语序**（50.9）：`as` 必须放在 `using`
   **之前**。写成 `induction t using t_tree_ind_better as [...]` 实测报
   `Error: Syntax error: [ltac_use_default] expected after [tactic] (in [tactic_command]).`；
   正确语序 `induction t as [...] using t_tree_ind_better` 则正常生效。
4. **`induction ... using` 会自动引入格子里的量词和 IH**（50.9）：以为还要
   `intros l v r IHl IHr`，实测报 `Error: v is already used.`（已自动引入）。
   且自动命名**不采用方案里的绑定名**——方案里写的 `l v r`，实际得到
   `t1 v t2 IHt1 IHt2`。要么直接用自动名，要么用第 3 条的 `as` 显式命名。
5. **原书"`induction ... using` 可能报 Cannot recognize an induction scheme，
   建议改用 apply"的提醒已过时**（50.9）：实测 `Fail induction t using
   t_tree_ind_better.` 报 `Error: The command has not failed!`——rocq 9.3 直接
   接受这条自定义方案。抄旧书代码时先用 `Fail` 试一下再决定绕路。
6. **嵌套 `prod` 的构造子触发 `register-all` 警告，且连刷四遍**（50.9）：
   `t_tree` 声明后每生成一条方案（`_rect`/`_ind`/`_rec`/`_sind`）各报一次
   `Warning: t_tree is nested using prod. No scheme for prod is registered as
   All. ... [register-all,automation,default]`。无害；要消除按提示
   `Scheme All for prod.`。
7. **`Check` 断言里写 `[]`/`::` 需要先 `Import ListNotations`**（文件头）：
   缺失时 `P [] ->` 实测报 `Error: Syntax error: '.' expected after [lconstr]
   (in [query_command]).`——记号存在与否是解析期问题，比"未知解释"更早爆。
8. **`Check` 断言里构造子的参数是显式的**（50.4）：写 `P C2` 漏掉 `X`，实测报
   `The term "C2" has type "forall X : Type, foo' X" while it is expected to
   have type "foo' X".`。规则不对称：**项位置必须带参数，模式位置可以省**。
9. **`Prop` 与 `Type` 生成的方案家族不同**（50.7）：`Type` 里的 `time` 回显
   `time_rect/time_ind/time_rec/time_sind` 四条；`Prop` 里的 `ev` 只有
   `ev_ind/ev_sind` 两条——`Prop` 证据原则上不能消除出大类型，所以没有
   `_rect`/`_rec`。在 `Prop` 上找 `_rec` 会扑空。

---

上一章：[49 · 证明即项：Curry–Howard 落地](49-proof-terms.md) ｜ 下一章：[51 · 关系、闭包与确定性](51-relations.md) ｜ 返回：[README](../README.md)
