# 33 · 置换与排序推理

对应示例：`../examples/33_perm.v`（`Module Ex33Perm`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

从本章起进入 **VFA 篇**（33–47 章，取材自 _Software Foundations_ 第三卷 *Verified Functional Algorithms*）。这一卷的问题只有一个：**怎么证明一个「真的会跑」的算法是对的**——不是玩具演算，而是插入排序、选择排序、归并排序、二叉搜索树、红黑树、优先队列这些数据结构课上的常客。全卷的方法论在本章一次备齐：线性算术自动化 `lia` 的能力边界（33.1）、把布尔比较「破坏性」案例分析的 `reflect` 桥（33.3）、以及贯穿全卷的排序规格核心关系 `Permutation`（33.5–33.6）。

第 23 章证插入排序时已经用过 `Permutation`（彼时直接取自标准库）；本章把它当主角系统拆解：归纳定义的四条构造子、四大引理（保长、对称、传递、保元素）全部亲手重证一遍，再学 butterfly 一题演示 `::` 与 `++` 混合时的「约分」技术。预备知识：第 11–12 章的归纳证明、第 15 章的 `reflect`、第 23 章的排序规格。

### 33.1 lia 的能与不能

文件头与本章第一组定理：

```coq
(* 33 置换与排序推理 —— lia 的边界、reflect 案例分析、Permutation 关系 *)

From Stdlib Require Import Arith Bool Strings.String Lia List Permutation.
Import ListNotations.

Module Ex33Perm.

(* ---------- 33.1 lia 的能与不能 ---------- *)

Theorem lia_example2 :
 forall i j k,
    i < j ->
    ~ (k - 3 <= j) ->
   k > i.
Proof.
  intros. lia.
Qed.
```

导入行的顺序有讲究：`Strings.String` 必须排在 `List` **之前**——两个模块都导出 `length`，后导入者胜出；若 `List` 在前，本章到处要用的 `length`（33.4 保长引理）会被 `String.length : string -> nat` 顶掉，编到那里才发现（实测坑，见 33.7）。`Lia` 提供 `lia`，`Permutation` 提供本章主角及其构造子 `perm_nil/perm_skip/perm_swap/perm_trans`。

`lia_example2` 展示 `lia` 的甜：三个变量、截断减法 `k - 3`、双重假设，人推要分几步，`lia` 一发收掉。它是线性整数算术的决策过程（第 20 章介绍过），对 `+`、`*常数`、`min/max/`截断减法构成的线性目标全包。但它的边界同样重要，看下两个定理：

```coq
Theorem truncated_subtraction : ~ (forall k:nat, k > k - 3).
Proof.
  intros contra.
  specialize (contra 0).
  simpl in contra.
  inversion contra.
Qed.

Theorem lia_example_3 : forall (f : nat -> nat -> nat) a b x y,
    f x y > a * b -> f x y + 3 >= a * b.
Proof.
  intros. lia.
Qed.
```

`truncated_subtraction` 证的是 `lia` 的第一条边界：**全称命题不是线性算术**。要否定 `forall k, k > k - 3`，`lia` 帮不上忙——它不处理量词；正确的做法是给反例：`specialize (contra 0)` 把全称实例化到 `k := 0`，`simpl in contra` 算出 `0 > 0 - 3` 即 `0 > 0`，`inversion contra` 从矛盾假设里直接撞出证据。

`lia_example_3` 是第二条边界：**`lia` 看不见函数内部**。未知函数应用 `f x y` 在它眼里只是一个不透明原子，于是「`f x y > a * b` 推出 `f x y + 3 >= a * b`」就是一次平凡的原子运算，`lia` 一发通过。但如果把结论里的 `f x y` 换成 `f y x`（两个语法上不同的原子），这命题本身就不成立（`f` 可以对两个参数给完全不同的值），`lia` 实测报 `Tactic failure: Cannot find witness.`。教训有两条：`lia` 只按**语法相同**匹配原子项；以及遇到它在看似显然的目标上失败时，先检查目标里的函数应用是否真的和假设里是**同一个**表达式。

### 33.2 maybe_swap：一个最小的排序内核

全卷的验证对象从一个两行函数开始：

```coq
(* ---------- 33.2 maybe_swap：一个最小的排序内核 ---------- *)

Definition maybe_swap (al: list nat) : list nat :=
  match al with
  | a :: b :: ar => if b <? a then b :: a :: ar else a :: b :: ar
  | _ => al
  end.

Example maybe_swap_123 :
  maybe_swap [1; 2; 3] = [1; 2; 3].
Proof. reflexivity. Qed.

Example maybe_swap_321 :
  maybe_swap [3; 2; 1] = [2; 3; 1].
Proof. reflexivity. Qed.
```

`maybe_swap` 检查列表**前两个元素**：逆序就交换，否则原样返回，尾部 `ar` 原封不动。它是所有相邻交换排序（冒泡、插入排序内层）的原子步。两个 Example 用 `reflexivity` 直接算——这一章的函数都是真的可执行程序，`Compute` 随时能跑，这是 VFA 卷的基调：**先有算法，再谈证明**，而不是先写规格再抽实现。

注意模式 `a :: b :: ar`：它对**任意长度 ≥ 2** 的列表都匹配并归约（`ar` 是变量），这一点与「恰好两元素」的写法 `[a; b]`（即 `a :: b :: nil`）不同——33.4 的归纳证明能那么顺，全靠定义选了这个模式。另外比较方向用的是 `b <? a`（b 小于 a 才换）：stdlib 9.3 没给 nat 导入 `>?` 记法，写 `a >? b` 会报 `Not in scope`（实测坑，见 33.7）。

### 33.3 reflect：布尔与命题的桥

要证 `maybe_swap` 的性质，第一道障碍是那个 `if b <? a`：`<?` 是 **bool** 世界的东西，证明需要的是 **Prop** 世界的 `b < a`。桥就是 `reflect`：

```coq
(* ---------- 33.3 reflect：布尔与命题的桥 ---------- *)

Print reflect.

Check iff_reflect : forall (P : Prop) (b : bool),
    P <-> b = true -> reflect P b.

Lemma ltb_reflect : forall x y, reflect (x < y) (x <? y).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.ltb_lt.
Qed.

Lemma leb_reflect : forall x y, reflect (x <= y) (x <=? y).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.leb_le.
Qed.

Lemma gtb_reflect : forall x y, reflect (y < x) (y <? x).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.ltb_lt.
Qed.
```

`Print reflect` 的实测输出：

```
Inductive reflect (P : Prop) : bool -> Set :=
    ReflectT : P -> reflect P true | ReflectF : ~ P -> reflect P false.
```

第 15 章见过它，这里补一个 9.x 的新观察：`reflect` 的类型是 `bool -> Set` 而**不是** `bool -> Prop`——两个构造子一个携带 `P` 的证据、一个携带 `~ P` 的证据，按 `b` 的取值编入不同的构造子，这个「证据随布尔值分流」的结构要在 `Set` 里才容得下。也正因如此，`destruct` 一个 reflect 项是**依赖模式匹配**：Coq 会顺手用构造子里的布尔等式改写目标里的 `if`——这是它比「先 `destruct b` 再搬等式」好用的根源。

`iff_reflect` 是造桥流水线：把「`P` 与 `b = true` 等价」升级成 reflect。`ltb_reflect` 用它两行造出 `<` 的桥——`symmetry` 把目标 `reflect (x<y) (x<?y)` 转成 `iff_reflect` 要的方向，`Nat.ltb_lt : (x <? y) = true <-> x < y` 正是现成的等价。`leb_reflect`（`<=`）同理，用 `Nat.leb_le`。`gtb_reflect` 造「y < x」的桥：注意参数顺序——它说的还是 `<?`，只是命题写成 `y < x`，本质与 `ltb_reflect` 同型，放在这里是为了展示「同一个比较函数可以配不同命题的桥」。

桥的用法见真章：

```coq
Example reflect_example1 : forall a,
    (if a <? 5 then a else 2) < 6.
Proof.
  intros a.
  assert (R: reflect (a < 5) (a <? 5)) by apply ltb_reflect.
  remember (a <? 5) as guard.
  destruct R as [H|H] eqn:HR.
  - lia.
  - lia.
Qed.

Example reflect_example1' : forall a,
    (if a <? 5 then a else 2) < 6.
Proof.
  intros a. destruct (ltb_reflect a 5); lia.
Qed.
```

`reflect_example1` 把每一步摆到明面：`assert` 拿到桥 `R`，`remember` 把 `if` 里的布尔表达式冻结成变量 `guard`（否则 `destruct R` 改写目标时可能对不上语法），然后 `destruct R`——两种情况各带一份命题证据：`H : a < 5`（then 分支，目标变 `a < 6`）或 `H : ~ a < 5`（else 分支，目标 `2 < 6`），各自 `lia`。`reflect_example1'` 是同一件事的惯用简写：`destruct (ltb_reflect a 5); lia` 一行搞定。VFA 原书把这封装成 `bdestruct` Ltac；本教程不另造战术，直接 `destruct (ltb_reflect x y)` 或 `destruct (leb_reflect x y)`，语义一样、少一层包装。

### 33.4 maybe_swap 的两条性质：幂等与保长

现在证 `maybe_swap` 的性质。第一条：做两遍等于做一遍：

```coq
(* ---------- 33.4 maybe_swap 的两条性质：幂等与保长 ---------- *)

Theorem maybe_swap_idempotent : forall al,
    maybe_swap (maybe_swap al) = maybe_swap al.
Proof.
  intros [ | a [ | b al]]; simpl; try reflexivity.
  destruct (ltb_reflect b a) as [H1|H1]; simpl.
  - (* 第一轮确实换了：b < a *)
    destruct (ltb_reflect a b) as [H2|H2]; simpl.
    + lia.
    + reflexivity.
  - (* 第一轮没换：~(b < a) *)
    destruct (ltb_reflect b a) as [H2|H2]; simpl.
    + lia.
    + reflexivity.
Qed.
```

开场白 `intros [ | a [ | b al]]` 是嵌套 intro 模式（第 8 章的老朋友）：把 `al` 按长度拆成 `[]`、`[a]`、`a :: b :: al` 三种情况——前两种 `maybe_swap` 直接走 `_` 分支原样返回，`simpl; try reflexivity` 秒杀。真正要证的只剩三元素以上的情形，而且 `simpl` 能归约**两轮** `maybe_swap`（这就是 33.2 选 `a :: b :: ar` 模式的红利），目标变成两个 `if` 的嵌套。

于是做两轮 reflect 案例分析。第一轮换了（`H1 : b < a`）：第二轮比较的是 `a` 与 `b`——顺序已经倒过来了。若 `H2 : a < b`，与 `H1 : b < a` 矛盾，`lia` 收；若 `H2 : ~ a < b`，第二轮不换，目标两边归约成同一个列表，`reflexivity`。第一轮没换（`H1 : ~ b < a`）：第二轮还是比 `b` 和 `a`，若 `H2 : b < a` 与 `H1` 矛盾 `lia`，否则两轮都没换，`reflexivity`。四种情况里两种靠 `lia` 撞矛盾、两种靠计算——**桥案例分析 + 线性算术**的组合拳是全卷反复出现的节奏。

第二条性质顺手就到：

```coq
Theorem maybe_swap_length : forall al,
  length (maybe_swap al) = length al.
Proof.
  intros [ | a [ | b al]]; simpl; try reflexivity.
  destruct (Nat.ltb b a); reflexivity.
Qed.
```

保长性不需要知道比较结果——换了也是 `a :: b :: ar` 变 `b :: a :: ar`，长度不动。所以这里连桥都不用，直接 `destruct (Nat.ltb b a)` 把 bool 撕开（不拿命题证据，目标里也不需要），两个分支都 `reflexivity`。对比 33.4 第一条：**要命题推理时用 reflect 桥，只看计算形状时裸 destruct bool 就够**。

### 33.5 Permutation：列表重排的标准库关系

`maybe_swap` 是「排序一步」；「排序」的全局规格说的是：输出是输入的**重排**。这个关系就是 `Permutation`：

```coq
(* ---------- 33.5 Permutation：列表重排的标准库关系 ---------- *)

Print Permutation.

Example permutation_example1 :
  Permutation [1;2;3] [3;2;1].
Proof.
  apply perm_trans with [3;1;2].
  - apply perm_trans with [1;3;2].
    + apply perm_skip. apply perm_swap.
    + apply perm_swap.
  - apply perm_skip. apply perm_swap.
Qed.

Example permutation_example2 :
  Permutation [1;2] [2;1].
Proof. apply perm_swap. Qed.

Example permutation_example3 :
  Permutation [1;2;3] [2;3;1].
Proof.
  apply perm_trans with [2;1;3].
  - apply perm_swap.
  - apply perm_skip. apply perm_swap.
Qed.
```

`Print Permutation` 的实测输出：

```
Inductive Permutation (A : Type) : list A -> list A -> Prop :=
    perm_nil : Permutation [] []
  | perm_skip : forall (x : A) (l l' : list A),
                Permutation l l' -> Permutation (x :: l) (x :: l')
  | perm_swap : forall (x y : A) (l : list A),
                Permutation (y :: x :: l) (x :: y :: l)
  | perm_trans : forall l l' l'' : list A,
                 Permutation l l' -> Permutation l' l'' -> Permutation l l''.

Arguments Permutation [A]%_type_scope (_ _)%_list_scope
Arguments perm_skip [A]%_type_scope x [l l']%_list_scope _
Arguments perm_swap [A]%_type_scope x y l%_list_scope
Arguments perm_trans [A]%_type_scope [l l' l'']%_list_scope _ _
```

四条构造子读作：**两边同时为空**（`perm_nil`）；**两边头部相同，尾部互为重排**（`perm_skip`——「同头约分」）；**交换前两个元素**（`perm_swap`——最小重排单元）；**拼接两段重排**（`perm_trans`）。注意 `Arguments` 行：`A`、三条列表参数全是**隐式**的——`perm_trans H1 H2` 就能调用，写成 `perm_trans _ _ _ H1 H2` 反而报错（实测坑，见 33.7）。

三个 Example 是手感练习，`permutation_example1` 最有代表性：证 `[1;2;3]` 与 `[3;2;1]` 互为重排，策略是**找中转站**——`apply perm_trans with [3;1;2]` 把大重排拆成两段小重排，每段再用 skip 约头 + swap 换邻。画出来就是：`[1;2;3] → [1;3;2] → [3;1;2] → [3;2;1]`，每步一次相邻交换。冒泡排序的每次交换都是一步 `perm_swap`，整个排序过程就是这条链的加长版。

构造子练完，四大引理全部亲手证一遍（标准库里都有，重证是为了把归纳结构吃透）：

```coq
Theorem Permutation_length : forall (A : Type) (l1 l2 : list A),
  Permutation l1 l2 -> length l1 = length l2.
Proof.
  intros A l1 l2 H. induction H.
  - reflexivity.
  - simpl. rewrite IHPermutation. reflexivity.
  - reflexivity.
  - rewrite IHPermutation1. rewrite IHPermutation2. reflexivity.
Qed.
```

**保长**：对重排证据 `H` 做归纳，而不是对列表。四个分支对应四条构造子：nil 两边长度都为 0；skip 两边同时加一（`simpl` 后 `rewrite IHPermutation`）；swap 两边都是 `x :: y :: l`，`reflexivity`；trans 是等式传递，先重写左半再右半。此后归纳假设自动叫 `IHPermutation` / `IHPermutation1` / `IHPermutation2`——对**证据归纳**（把 `induction` 用在类型类索引的证据上）是本章最重要的证明姿势：列表在变，证据的形状才是归纳的骨架。

```coq
Theorem Permutation_sym : forall (A : Type) (l1 l2 : list A),
  Permutation l1 l2 -> Permutation l2 l1.
Proof.
  intros A l1 l2 H. induction H.
  - apply perm_nil.
  - apply perm_skip. exact IHPermutation.
  - apply perm_swap.
  - apply perm_trans with l'.
    + exact IHPermutation2.
    + exact IHPermutation1.
Qed.

Theorem Permutation_trans : forall (A : Type) (l1 l2 l3 : list A),
  Permutation l1 l2 -> Permutation l2 l3 -> Permutation l1 l3.
Proof.
  intros A l1 l2 l3 H1 H2. exact (perm_trans H1 H2).
Qed.
```

**对称**：最有意思的是 trans 分支——`IH1 : Permutation l2 l'`（注意方向翻过来了）、`IH2 : Permutation l' l1`，拼回去要**倒序使用**两个 IH：`apply perm_trans with l'` 先接 `IH2` 再接 `IH1`。**传递**则根本不用归纳——它就是构造子 `perm_trans` 本身（标准库版正是我们的 `H1 H2` 直接喂给 `perm_trans`）。这两个名字与标准库重名，我们重证后在本模块内**遮蔽**了库版本——后面 `maybe_swap_perm` 里调用的 `Permutation_refl` 则还是库的。

```coq
Theorem Permutation_in : forall (A : Type) (x : A) l1 l2,
  Permutation l1 l2 ->
  In x l1 -> In x l2.
Proof.
  intros A x l1 l2 H. induction H.
  - intros [].
  - intros [E|Hin].
    + left. exact E.
    + right. apply IHPermutation. exact Hin.
  - intros [E|Hin].
    + right. left. exact E.
    + destruct Hin as [E|Hin].
      * left. exact E.
      * right. right. exact Hin.
  - intros Hin. apply IHPermutation2. apply IHPermutation1. exact Hin.
Qed.
```

**保元素**：重排不丢元素、不造元素。前三个分支要手动搬 `In` 的析取（`intros [E|Hin]` 撕开假设，`left`/`right` 摆进目标），swap 分支里嵌套的 `In x (y :: x :: l)` 展开是三层析取，需要 `destruct ... as [E|Hin]` 再内层 `as [E|Hin]` 二段撕。这是本章最琐碎的一段，但方向感清晰：**每一层析取对应「x 在列表的哪个位置」**。

保元素立刻有战斗力——它能证**否定**：

```coq
Theorem not_permutation_112_12 :
  ~ Permutation [1;1] [1;2].
Proof.
  intro H.
  assert (H2 : In 2 [1;2] -> In 2 [1;1]).
  { apply (Permutation_in nat 2 [1;2] [1;1] (Permutation_sym nat [1;1] [1;2] H)). }
  assert (H3 : In 2 [1;1]).
  { apply H2. apply in_cons. apply in_eq. }
  simpl in H3. destruct H3 as [E|[E|E]];
    [ discriminate E | discriminate E | exact E ].
Qed.
```

`[1;1]` 与 `[1;2]` 长度相同、`Permutation` 无法仅凭保长排除，必须动用元素集合。思路：若它们互为重排，`Permutation_sym` 翻转方向后用 `Permutation_in`，把「2 在右边」搬成「2 在左边」——但左边 `[1;1]` 根本没有 2，矛盾。`H2` 的构造里三个全显式参数一次说清（标准库版 `Permutation_in` 的 `A` 与列表参数位置如此）；`H3` 的证明是「正向造 In」：`apply in_cons` 把目标 `In 2 [1;2]`（即 `1 = 2 \/ In 2 [2]`）约到右支 `In 2 [2]`，`in_eq` 一步收掉。收尾 `simpl in H3` 后 `In 2 [1;1]` 展开成**三层析取** `1 = 2 \/ (1 = 2 \/ False)`——所以 destruct 模式是 `[E|[E|E]]` 三通道，前两个 `discriminate E`（等式两边构造子不同），第三个 `exact E`（证据直接是 `False`）。这里 `discriminate` 不能无参串行使用：第三分支没有等式可辨，实测报 `No primitive equality found`（见 33.7）。

最后把两半合体——`maybe_swap` 确实是重排：

```coq
Theorem maybe_swap_perm : forall al,
  Permutation al (maybe_swap al).
Proof.
  intros [ | a [ | b al]]; simpl.
  - apply perm_nil.
  - apply perm_skip. apply perm_nil.
  - destruct (ltb_reflect b a); simpl.
    + apply perm_swap.
    + apply Permutation_refl.
Qed.
```

三种长度拆开后：空表 `perm_nil`；单元素 `perm_skip` + `perm_nil`；两个以上则桥分析——换了就是一步 `perm_swap`（注意统一方向：目标 `Permutation (a::b::al) (b::a::al)` 与 `perm_swap` 的 `(y::x::l) → (x::y::l)` 对齐，`y:=a, x:=b`），没换用**库的** `Permutation_refl`。为什么这里不能 `perm_skip. apply perm_nil.`？因为尾部 `al` 是变量不是 `[]`，`Permutation al al` 没法归约到 `perm_nil`（实测报 `Unable to unify "Permutation [] []" with "Permutation (b :: al) (b :: al)"`，见 33.7）。

至此 `maybe_swap` 集齐三条已证性质：幂等（33.4）、保长（33.4）、重排（本条）。「排序一步」的**全部**数学内容就这些——后面的排序算法章节（34 插入、35 选择、36 归并）不过是把这个原子步装进循环/递归，再处理「重复做直到有序」的部分。

### 33.6 butterfly：Permutation 的拼接技术

排序算法的规格常常长成 `Permutation (x :: l) (something ++ [y] ++ rest)`——`::`、`++` 与重排搅在一起。VFA 用一个 deliberately 花哨的例子演示标准技术：

```coq
(* ---------- 33.6 butterfly：Permutation 的拼接技术 ---------- *)

Example butterfly : forall b u t e r f l y : nat,
  Permutation ([b;u;t;t;e;r]++[f;l;y]) ([f;l;u;t;t;e;r]++[b;y]).
Proof.
  intros.
  change [b;u;t;t;e;r] with ([b]++[u;t;t;e;r]).
  change [f;l;u;t;t;e;r] with ([f;l]++[u;t;t;e;r]).
  remember [u;t;t;e;r] as utter. clear Hequtter.
  change [f;l;y] with ([f;l]++[y]).
  remember [f;l] as fl. clear Heqfl.
  replace ((fl ++ utter) ++ [b;y]) with (fl ++ utter ++ [b;y])
    by apply app_assoc.
  apply perm_trans with (fl ++ [y] ++ ([b] ++ utter)).
  - replace (fl ++ [y] ++ [b] ++ utter) with ((fl ++ [y]) ++ [b] ++ utter).
    + apply Permutation_app_comm.
    + rewrite <- app_assoc. reflexivity.
  - apply Permutation_app_head.
    apply perm_trans with (utter ++ [y] ++ [b]).
    + replace ([y] ++ [b] ++ utter) with (([y] ++ [b]) ++ utter).
      * apply Permutation_app_comm.
      * rewrite app_assoc. reflexivity.
    + apply Permutation_app_head.
      apply perm_swap.
Qed.
```

命题本身：`butterfly`（蝴蝶）这个词正是把 `[u;t;t;e;r]`「utter」飞到右边。证明策略分五步，每步一个战术、各学一招：

1. **`change` 重组语法**：`change [b;u;t;t;e;r] with ([b]++[u;t;t;e;r])` 把字面列表改写成拼接形式——两边必须**可转换**（计算等价），这里 `++` 的展开即验证。目的：让共同段显式成 `++` 的操作数。
2. **`remember` + `clear` 抽象共同段**：把 `[u;t;t;e;r]` 冻结成变量 `utter`（`clear Hequtter` 丢掉等式——后面不需要它变回去），同样把 `[f;l]` 变 `fl`。此后证明与「utter 里到底是什么」无关。
3. **`replace ... by` 矫正结合律**：`replace ((fl ++ utter) ++ [b;y]) with (fl ++ utter ++ [b;y]) by apply app_assoc` 把右边的括号移到与目标一致的位置，旁证由 `app_assoc` 一发提供。
4. **`perm_trans with` 走中转站**：中转 `fl ++ [y] ++ ([b] ++ utter)`。左半用库的 `Permutation_app_comm`（前后两大段整体对调），右半用库的 `Permutation_app_head`（前段相同则约掉，只剩后段的重排）。
5. **递归约分**：`Permutation_app_head` 约掉 `fl` 后，剩 `utter ++ [y] ++ [b]` 再来一轮 comm + head 约掉 `utter`，最后只剩 `[y]` 与 `[b]` 一步 `perm_swap`。

两个库引理的实测类型（本章文件里 `Check` 过）：

```coq
Check Permutation_app_comm :
  forall (A : Type) (l l' : list A),
    Permutation (l ++ l') (l' ++ l).
```

注意 stdlib 9.2 的 `Permutation_app_comm` 是**两段版**（`l ++ l' ↔ l' ++ l`），不是一些老教材里的三段版 `l1 ++ l2 ++ l3 ↔ l2 ++ l1 ++ l3`——`Check` 的类型标注若按三段写会 unify 失败（实测坑，见 33.7）。`Permutation_app_head` 标准库也有，本章仍亲手证一遍——它把「前缀相同」变成了可约分的等式：

```coq
Theorem Permutation_app_head : forall (A : Type) (l1 l2 l3 : list A),
  Permutation l1 l2 ->
  Permutation (l1 ++ l3) (l2 ++ l3).
Proof.
  intros A l1 l2 l3 H. induction H.
  - reflexivity.
  - simpl. apply perm_skip. exact IHPermutation.
  - simpl. apply perm_swap.
  - apply perm_trans with (l' ++ l3).
    + exact IHPermutation1.
    + exact IHPermutation2.
Qed.

Print Assumptions butterfly.

End Ex33Perm.
```

又是一次对证据的归纳：nil 直接算（`[] ++ l3 = l3`）；skip 两边各推一个头；swap 两边各交换前两元；trans 用中转 `l' ++ l3` 拼接两个 IH。结构与 `Permutation_sym` 完全平行——**四大引理的证明骨架其实都是这同一个四分支模板**，变化的只是每个分支里怎么把 IH 组装回去。

`Print Assumptions butterfly.` 实测输出 `Closed under the global context`：整个证明没借助任何公理，全靠构造。这也是 VFA 卷每一章结束时的固定仪式——验证算法正确性的证明应当是构造性的，能被 `Print Assumptions` 盖章。

收个尾。本章备齐了 VFA 卷的全部工具：`lia` 处理线性算术但看不见函数内部与量词（33.1）；`reflect` 桥 + `destruct` 把布尔决策升级成命题案例分析（33.3）；`Permutation` 四构造子 + 四大引理 + app_comm/app_head 约分术构成排序规格的代数（33.5–33.6）；`maybe_swap` 作为最小排序核证了幂等、保长、重排三性质（33.2/33.4）。下一章起把这些工具装进真算法：第 34 章插入排序，你会发现「证明排序正确」=「证输出有序 + 证输出是输入的 Permutation」，而后者正是本章练熟的活。

### 33.7 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`>?` 记法不在作用域**（33.2）：VFA 原书写 `a >? b`，实测 9.3 报 not-in-scope（stdlib 未给 nat 导入 `>?`）。对策：反写操作数用 `b <? a`，或走 `Nat.ltb b a` 全名。
2. **`Strings.String` 与 `List` 的导入顺序决定 `length` 归属**（文件头）：两者都导出 `length`，`List` 在后则 `length` 指 `String.length : string -> nat`，编到保长引理才报类型错误。对策：`Strings.String` 排在 `List` 之前。
3. **`perm_trans` 的隐式参数**（33.5）：`Arguments perm_trans [A] [l l' l''] _ _`——类型与三条列表全隐式，正确调用是 `perm_trans H1 H2`；照老书写法 `perm_trans _ _ _ H1 H2` 会把第一个 `_` 当成证据而报类型错。
4. **`In x [a;b]` 是三层析取，destruct 模式要三通道**（33.5）：`simpl in H3` 后 `In 2 [1;1]` 是 `1 = 2 \/ (1 = 2 \/ False)`，`destruct H3 as [E|E]` 只撕一层，内层析取留在目标里编不过；正确写法 `as [E|[E|E]]`。
5. **无参 `discriminate` 串行用在含 `False` 分支的目标上会失败**（33.5）：`destruct H3 as [E|[E|E]]; discriminate` 实测报 `No primitive equality found`——第三分支的证据是 `False` 不是等式，`discriminate` 无等式可辨。对策：显式三通道 `[discriminate E | discriminate E | exact E]`。
6. **`try apply perm_nil` 后接 `destruct (ltb_reflect b a)` 会跑错目标**（33.5）：单元素分支上 `try` 没收掉目标、`b` 又未绑定，实测报 `The variable b was not found in the current environment`。对策：别用 `; try` 串联，老老实实三个 `-` 子弹头各写各的。
7. **尾部是变量时约分终点用 `Permutation_refl` 而非 `perm_skip; perm_nil`**（33.5）：`Permutation (b :: al) (b :: al)` skip 一步后剩 `Permutation al al`，`al` 是变量不能归约到 `[]`，实测报 `Unable to unify "Permutation [] []" with "Permutation (b :: al) (b :: al)"`。库里现成的 `Permutation_refl` 一步收。
8. **stdlib 9.2 的 `Permutation_app_comm` 是两段版**（33.6）：类型为 `Permutation (l ++ l') (l' ++ l)`；`Check ... : forall A l1 l2 l3, Permutation (l1++l2++l3) (l2++l1++l3)` 的三段标注实测 unify 失败。butterfly 里两处 `replace ... by apply app_assoc` 就是为了把目标摆成两段版能咬住的形状。
9. **手搓 butterfly 中转链容易方向对反**（33.6）：自己拼 `perm_skip`/`perm_swap` 链不借助 `Permutation_app_head` 时，`apply perm_swap` 反复报 `Unable to unify "y" with "b"` 一类错误——swap 构造子的 `x y` 与目标方向极易对反。对策：优先用库引理 comm + head「约分」，最后只剩两元素才手写 swap。

---
上一章：[32 · 综合实战：表达式解释器与优化器](32-project.md) ｜ 下一章：[34 · 插入排序与规格模式](34-sort.md) ｜ 返回：[README](../README.md)
