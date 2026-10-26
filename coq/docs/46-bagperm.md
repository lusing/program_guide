# 46 · Bag 与置换的代数

对应示例：`../examples/46_bagperm.v`（`Module Ex46BagPerm`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

第 37 章给了排序正确性的另一种规格风格：不再说「输出是输入的**重排**」（第 33 章的 `Permutation`），而是说「输出与输入含有**同一个多重集**」。VFA 原书其实为这个主题准备了两份材料：`Multiset`（第 37 章的底本，把多重集表示成 `nat -> nat` 的函数，证相等要请出函数外延性公理）和 `BagPerm`（本章的底本）。`BagPerm` 走更朴素的一条路：**bag 就是 `list nat` 本身**，多重集的「含量」用 `count` 直接数——于是「同一个多重集」变成一条逐点的计数等式 `forall n, count n b1 = count n b2`，全程**不需要任何公理**。本章的主线是 VFA 收官前的一段规格论证明：先照原书用计数规格重新验证插入排序，再证明两个方向——`Permutation al bl -> bag_eqv al bl`（对置换证据归纳，顺着第 33 章的路子）与反方向 `bag_eqv al bl -> Permutation al bl`（原书标注 advanced，思路归功于 Zhong Sheng Hu）——最终合龙成 `bag_eqv al bl <-> Permutation al bl`，并顺手推出：**用 Permutation 写的排序规格与用 bag 写的排序规格完全等价**。在 VFA 篇（33–47）的地图上，本章（46）位于排序三部曲（34–36）与数据结构章（39–45）之后，是第 37 章的姊妹章：37 章问「换一种规格长什么样」，本章回答「两种规格其实说的是同一件事」。原书的 `bdestruct`/`inv` 自定义战术在本章全部换成标准战术（`destruct ... eqn:`、`Nat.eqb_spec`/`Nat.leb_spec` 的 reflect 拆分、`rewrite`/`lia`），全部断言无 `Admitted`、无 `Axiom`。

### 46.1 bag 抽象：count、remove 与计数定律

文件头与两件基础定义：

```coq
(* 46 Bag 与置换的代数 —— 计数规格与 Permutation 等价 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex46BagPerm.

(* ---------- 46.1 bag 抽象：count、remove 与计数定律 ---------- *)

Definition bag := list nat.

Fixpoint count (v : nat) (s : bag) : nat :=
  match s with
  | [] => 0
  | h :: t => (if h =? v then 1 else 0) + count v t
  end.

Fixpoint remove (v : nat) (s : bag) : bag :=
  match s with
  | [] => []
  | h :: t => if h =? v then t else h :: remove v t
  end.
```

`bag` 只是 `list nat` 的别名——多重集不是新数据结构，而是**同一个列表换一种问法**：集合问「元素在不在」，bag 问「元素出现几次」。`count v s` 沿表累加，表头等于 `v` 就记 1；`remove v s` 撤掉**第一个** `v`（注意它删的是一次出现，不是全部），这两个函数与第 8 章列表篇的同名概念同源。注意 `count` 的布尔测试写的是 `h =? v`（表头在左），后面反复与 `Nat.eqb_spec`/`Nat.eqb_refl` 配合时要留意方向。

两条 `reflexivity` 小例先固定直觉——`remove` 只删一个 `1`：

```coq
Example count_example : count 1 [3; 1; 4; 1; 5] = 2.
Proof. reflexivity. Qed.

Example remove_example : remove 1 [3; 1; 4; 1; 5] = [3; 4; 1; 5].
Proof. reflexivity. Qed.
```

接下来三条是本章自备的「计数定律」，原书 `BagPerm.v` 里没有它们也能走通，但有了 `count_app`，46.5 的反向证明里 `count` 穿过拼接就不用再手算。`count_nonzero` 把「计数为正」与「成员关系」接通（呼应第 37 章「多重集含量」与 `In` 的关系）；`count_remove` 说 `remove` 恰好把计数减一：

```coq
Lemma count_nonzero : forall v s, 0 < count v s <-> In v s.
Proof.
  intros v s. induction s as [ | h t IH].
  - simpl. split; [ lia | intros [] ].
  - simpl. split.
    + intro H. destruct (Nat.eqb_spec h v) as [E | E].
      * left. exact E.
      * right. apply IH. simpl in H. lia.
    + intros [E | Hin].
      * rewrite E. rewrite Nat.eqb_refl. simpl. lia.
      * apply IH in Hin. destruct (h =? v); simpl; lia.
Qed.

Lemma count_app : forall (l1 l2 : bag) (v : nat),
    count v (l1 ++ l2) = count v l1 + count v l2.
Proof.
  induction l1 as [ | h t IH]; intros l2 v; simpl.
  - reflexivity.
  - rewrite IH. destruct (h =? v); simpl; lia.
Qed.

Lemma count_remove : forall v s,
    0 < count v s -> count v s = S (count v (remove v s)).
Proof.
  intros v s. induction s as [ | h t IH]; intro H.
  - simpl in H. lia.
  - simpl in H. simpl. destruct (h =? v) eqn:E.
    + simpl. reflexivity.
    + simpl in H |- *. rewrite E. simpl.
      apply IH. exact H.
Qed.
```

三个证明的共同姿势是「先 simpl 摊开 count，再拆布尔」：`destruct (Nat.eqb_spec h v) as [E | E]` 一步到位——既把 `h =? v` 换成 `true`/`false`（让 `if` 能归约），又白送一条 `h = v` 或 `h <> v` 的命题证据，这正是第 33 章 `reflect` 案例分析的标准用法，替代原书的 `bdestruct`。`count_remove` 的 false 分支值得盯一眼：`simpl in H |- *` 把目标里 `count v (h :: remove v t)` 重新摊开、**又生出一个新的 `if h =? v`**，所以必须先 `rewrite E`（布尔等式此时才有用武之地）、再 `simpl` 归约掉 `if false`，`apply IH` 才对得上形状——顺序颠倒的报错见 46.8 第 4 条。顺带一提，`lia` 对「不透明布尔 if」有自己的小聪明：同一个 if-项在等式两侧同时出现时，它直接当成同一个原子就完事（实测 `count_app` 里去掉 `destruct` 只留 `lia` 也能过）；但若想**单独**知道这个 if 等于 0 还是 1，就必须先 destruct（46.8 第 2 条）。

### 46.2 bag_eqv：计数规格下的等价关系

```coq
(* ---------- 46.2 bag_eqv：计数规格下的等价关系 ---------- *)

Definition bag_eqv (b1 b2 : bag) : Prop :=
  forall n, count n b1 = count n b2.

Example bag_eqv_example : bag_eqv [1; 2; 1] [2; 1; 1].
Proof.
  intro n. simpl.
  destruct (1 =? n); destruct (2 =? n); simpl; lia.
Qed.
```

「两个 bag 相等」定义为**每个可能元素的计数都相等**。与第 37 章的函数式多重集对比一下就懂这一步的分量：37 章（VFA `Multiset.v`）里多重集是 `nat -> nat` 的函数，证 `contents al = contents bl` 得靠函数外延性公理把两个函数逐点掰开；本章的 `bag_eqv` 从定义起**就是**逐点等式，`apply H` 即可，全程 `Print Assumptions` 干净。`bag_eqv_example` 证明 `[1;2;1]` 与 `[2;1;1]` 是同一个 bag：intro 掉任意的 `n`，simpl 后四次布尔组合各归约成数字，`lia` 结账（实测这个例子里连两次 `destruct` 都可以省——两侧出现的 if-项两两相同，`lia` 按原子处理即可；但保留 destruct 的写法不依赖这份运气，更稳）。

`bag_eqv` 是等价关系，且「两边同时 cons 同一个元素」保持等价——四条都是原书练习（bag_eqv_properties / bag_eqv_cons），这里全部补全：

```coq
Lemma bag_eqv_refl : forall b, bag_eqv b b.
Proof. intros b n. reflexivity. Qed.

Lemma bag_eqv_sym : forall b1 b2, bag_eqv b1 b2 -> bag_eqv b2 b1.
Proof. intros b1 b2 H n. symmetry. apply H. Qed.

Lemma bag_eqv_trans : forall b1 b2 b3,
    bag_eqv b1 b2 -> bag_eqv b2 b3 -> bag_eqv b1 b3.
Proof.
  intros b1 b2 b3 H12 H23 n. rewrite (H12 n). apply H23.
Qed.

Lemma bag_eqv_cons : forall x b1 b2,
    bag_eqv b1 b2 -> bag_eqv (x :: b1) (x :: b2).
Proof.
  intros x b1 b2 H n. simpl. rewrite (H n). reflexivity.
Qed.
```

四条证明都在「计数世界」里机械行走：自反对每个 `n` 都是 `reflexivity`；对称把等式掉头；传递先把 `count n b1` 改写成 `count n b2` 再交给另一条假设；`bag_eqv_cons` 则是 cons 的计数定律——表头同一元素在两侧各贡献同一个 `if x =? n then 1 else 0`，剩下的尾表用归纳假设对齐。这一节同时是 46.3 的工具箱：`sort_bag` 的归纳步骤要靠 `bag_eqv_trans` 换乘、`bag_eqv_cons` 接力。

### 46.3 用计数规格验证插入排序

原书这一节回答「bag 规格能不能当真用」：把第 34 章的插入排序原样搬来（自包含起见在此重述），把规格里的 `Permutation` 换成 `bag_eqv`，照样能证：

```coq
(* ---------- 46.3 用计数规格验证插入排序 ---------- *)

Fixpoint insert (i : nat) (l : list nat) : list nat :=
  match l with
  | [] => [i]
  | h :: t => if i <=? h then i :: h :: t else h :: insert i t
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | h :: t => insert h (sort t)
  end.

Example sort_pi :
  sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof. reflexivity. Qed.
```

`sort_pi` 用 π 的前几位做冒烟测试。接着重述 `sorted` 与**两种**排序规格——带撇号的是计数版，这正是第 37 章引入、本章要与之等价化的那一种（37 章写成 `contents al = contents (f al)`，这里写成 `bag_eqv al (f al)`，语义相同）：

```coq
Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall x, sorted [x]
| sorted_cons : forall x y l,
    x <= y -> sorted (y :: l) -> sorted (x :: y :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) : Prop :=
  forall al, Permutation al (f al) /\ sorted (f al).

Definition is_a_sorting_algorithm' (f : list nat -> list nat) : Prop :=
  forall al, bag_eqv al (f al) /\ sorted (f al).
```

有序那一半的证明与第 34 章逐字同型（`insert_sorted`/`sort_sorted`），此处照抄——唯一差别是把 `destruct (Nat.leb ...)` 换成 `destruct (Nat.leb_spec ...)` 的 reflect 拆分，布尔与命题证据一次拿全：

```coq
Lemma insert_sorted : forall a l, sorted l -> sorted (insert a l).
Proof.
  intros a l S. induction S as [ | x | x y l Hxy S0 IHS0]; simpl.
  - apply sorted_1.
  - destruct (Nat.leb_spec a x) as [E | E].
    + apply sorted_cons; [exact E | apply sorted_1].
    + apply sorted_cons; [lia | apply sorted_1].
  - destruct (Nat.leb_spec a x) as [Ex | Ex].
    + apply sorted_cons; [exact Ex | apply sorted_cons; [exact Hxy | exact S0]].
    + destruct (Nat.leb_spec a y) as [Ey | Ey].
      * apply sorted_cons; [lia | apply sorted_cons; [exact Ey | exact S0]].
      * simpl in IHS0. destruct (Nat.leb_spec a y) as [Ey' | Ey'].
        -- lia.
        -- apply sorted_cons; [exact Hxy | exact IHS0].
Qed.

Theorem sort_sorted : forall l, sorted (sort l).
Proof.
  induction l as [ | x t IH].
  - apply sorted_nil.
  - simpl. apply insert_sorted. exact IH.
Qed.
```

真正的新东西是计数那一半。`insert_bag`（原书 3 星练习）：插入一个元素等价于把它 cons 到前面——两个 bag 计数相同：

```coq
Lemma insert_bag : forall x l, bag_eqv (x :: l) (insert x l).
Proof.
  intros x l. induction l as [ | y t IH]; intro n; simpl.
  - reflexivity.
  - destruct (x <=? y).
    + reflexivity.
    + simpl. rewrite <- (IH n). simpl.
      destruct (x =? n); destruct (y =? n); simpl; lia.
Qed.
```

注意 `bag_eqv` 是 `forall n, ...`，所以归纳前不动 `n`，每个分支里再 `intro n`。`x <= y` 时 `insert` 原样摆回 `x :: y :: t`，两侧列表逐字相同，`reflexivity` 直接收；`y < x` 时插入进尾部，`rewrite <- (IH n)` 把 `count n (insert x t)` 换回 `count n (x :: t)`，两侧各自摊开后是同一个多重集的两笔账——`x` 与 `y` 各贡献一次 0/1，顺序不同、总和相同，`lia` 对四个布尔组合逐一结清。`sort_bag`（原书 2 星练习）一行归纳接上：

```coq
Theorem sort_bag : forall l, bag_eqv l (sort l).
Proof.
  induction l as [ | x t IH].
  - apply bag_eqv_refl.
  - simpl.
    apply bag_eqv_trans with (x :: sort t).
    + apply bag_eqv_cons. exact IH.
    + apply insert_bag.
Qed.

Theorem insertion_sort_correct : is_a_sorting_algorithm' sort.
Proof.
  unfold is_a_sorting_algorithm'. intro al. split.
  - apply sort_bag.
  - apply sort_sorted.
Qed.
```

归纳步骤的目标是 `bag_eqv (x :: t) (insert x (sort t))`——它**不是** `insert_bag` 能一步对上的形状（`insert_bag` 的左边是 `x :: l`，这里左边是 `x :: t` 而 `insert` 作用在 `sort t` 上，中间隔着归纳假设没接），所以走三段式：`IH : bag_eqv t (sort t)` 经 `bag_eqv_cons` 升级成 `bag_eqv (x :: t) (x :: sort t)`，再经 `bag_eqv_trans` 换乘 `insert_bag` 直接得到的 `bag_eqv (x :: sort t) (insert x (sort t))`。想省掉中转站直接 `apply insert_bag` 的报错见 46.8 第 6 条。合龙后的 `insertion_sort_correct` 与第 34 章同名定理并列：同一算法，两种规格，各自成立。

### 46.4 正向：Permutation 蕴含计数相等

```coq
(* ---------- 46.4 正向：Permutation 蕴含计数相等 ---------- *)

Lemma perm_bag : forall al bl : list nat,
    Permutation al bl -> bag_eqv al bl.
Proof.
  intros al bl H.
  induction H as [ | x l l' Hp IH | x y l | l l' l'' H1 IH1 H2 IH2 ]; intro n.
  - reflexivity.
  - simpl. rewrite (IH n). reflexivity.
  - simpl. destruct (y =? n); destruct (x =? n); simpl; lia.
  - rewrite (IH1 n). apply IH2.
Qed.
```

`perm_bag` 是原书 3 星练习，套路与第 33 章 `Permutation_length`/`Permutation_in` 完全一致：**对置换证据本身归纳**。`induction H as [ | x l l' Hp IH | x y l | l l' l'' H1 IH1 H2 IH2 ]` 的四个分支对应 `Permutation` 的四个构造子——空表、头部共有的 skip、相邻交换的 swap、以及传递的 trans。nil 分支两边都是 `[]`，计数恒零；skip 分支两侧表头同为 `x`，`simpl` 后共同的 `if x =? n then 1 else 0` 抵消，尾表交给归纳假设；swap 分支是 `count n (y :: x :: l) = count n (x :: y :: l)`，两次 `destruct` 把两个布尔拆开，四种组合全是 0/1 加法的重排，`lia` 通杀；trans 分支把第一段的计数等式改写进第二段。顺带一个实测情报：不写 `as` 模式直接 `induction H` 时，rocq 9.3.0 自动命名的归纳假设就叫 `IHPermutation`、`IHPermutation1`、`IHPermutation2`（第 33 章用的正是这些默认名），显式 `as` 模式只是把名字攥在自己手里。

### 46.5 反向：计数相等蕴含 Permutation

```coq
(* ---------- 46.5 反向：计数相等蕴含 Permutation ---------- *)

Lemma bag_nil_inv : forall b, bag_eqv [] b -> b = [].
Proof.
  intros [ | x t] H.
  - reflexivity.
  - specialize (H x). simpl in H.
    rewrite Nat.eqb_refl in H. simpl in H.
    exfalso. lia.
Qed.
```

反方向原书标注 advanced，思路归功于 Zhong Sheng Hu：既然正向「重排保计数」是结构归纳，反向就得把「计数相等」**反过来榨出结构信息**。三件辅助工具打头。第一件 `bag_nil_inv`：与空表计数相等的表必是空表。证明对 `b` 拆形——`x :: t` 情形下，把全称假设特化到 `x` 自己：`count x [] = count x (x :: t)`，左边是 0，右边 `simpl` 出 `(if x =? x then 1 else 0) + count x t`，`rewrite Nat.eqb_refl` 把布尔点亮成 `true`、再 `simpl` 归约成 `1 + count x t`，与 0 矛盾，`exfalso. lia` 收（实测此处 `lia` 也能直接吃掉 `if true` 项，`exfalso` 是为了把非算术的列表等式目标换成 `False`——见 36 章坑位清单同款结论，两版都过，这里保留更显式的写法）。

第二件工具 `count_insert_other`（原书 advanced 练习）：往拼接中缝塞一个 `x`，**别的**元素 `y` 的计数不受影响：

```coq
Lemma count_insert_other : forall l1 l2 x y,
    y <> x -> count y (l1 ++ x :: l2) = count y (l1 ++ l2).
Proof.
  induction l1 as [ | z t IH]; intros l2 x y Hne.
  - simpl. destruct (Nat.eqb_spec x y) as [E | E].
    + exfalso. apply Hne. symmetry. exact E.
    + simpl. reflexivity.
  - simpl. rewrite (IH l2 x y Hne). reflexivity.
Qed.
```

对前段 `l1` 归纳：基例里中缝元素就是表头，`Nat.eqb_spec` 拆出 `x = y`（与 `y <> x` 矛盾，`exfalso` 收掉）或 `x <> y`（计数差一个 `if x =? y then 1 else 0` = 0）；归纳步骤两侧表头同为 `z`，共同的 `if z =? y` 抵消，尾部交给归纳假设。原书用它拼装 `bag_perm`；本章 46.5 的最终证明走了 `Nat.eqb_spec` 的直接拆分路线（见 `bag_perm` 的 `a <> n` 分支），但它作为独立的计数定律仍然值得证一遍——它是「bag 视角下，元素只影响自己的计数」这句话的形式化。

第三件也是最关键的一件，`bag_cons_inv`（原书 3 星 advanced）：如果 `x` 在 `l` 里至少出现 `S n` 次，那么 `l` 一定能拆成「某段 ++ x :: 某段」，且拆掉这个 `x` 后恰好剩 `n` 次：

```coq
Lemma bag_cons_inv : forall l x n,
    S n = count x l ->
    exists l1 l2,
      l = l1 ++ x :: l2
      /\ count x (l1 ++ l2) = n.
Proof.
  induction l as [ | y t IH]; intros x n H.
  - simpl in H. discriminate.
  - simpl in H. destruct (y =? x) eqn:E.
    + apply Nat.eqb_eq in E. subst y.
      exists [], t. simpl. split.
      * reflexivity.
      * simpl in H. lia.
    + destruct (IH x n H) as [l1 [l2 [Ht Hc]]].
      exists (y :: l1), l2. simpl. split.
      * rewrite Ht. reflexivity.
      * rewrite E. simpl. exact Hc.
Qed.
```

这就是「从计数反推结构」的发动机：表头 `y = x` 时，要找的 `x` 就在头上，取 `l1 = []`、`l2 = t`，剩下的计数义务由 `H` 直接给出；表头 `y <> x` 时，`S n = 0 + count x t` 把义务原样传给尾部，归纳假设交回 `t = l1 ++ x :: l2` 与计数事实，拼上头部的 `y` 即 `l = (y :: l1) ++ x :: l2`——第二个分量的证明里，`simpl` 摊开 `count x ((y :: l1) ++ l2)` 又生出一个新的 `if y =? x`，`rewrite E` 把它归约为 0 后正好等于 `Hc`（与 46.1 `count_remove` 同款「simpl 再生 if、rewrite 布尔等式补刀」的节奏）。

三件工具备齐，主菜上桌（原书 3 星 advanced）：

```coq
Lemma bag_perm : forall al bl, bag_eqv al bl -> Permutation al bl.
Proof.
  intros al. induction al as [ | a tl IH]; intros bl H.
  - rewrite (bag_nil_inv bl H). apply perm_nil.
  - assert (Ha : S (count a tl) = count a bl).
    { specialize (H a). simpl in H.
      rewrite Nat.eqb_refl in H. simpl in H. exact H. }
    destruct (bag_cons_inv bl a (count a tl) Ha) as [l1 [l2 [Hbl Hc]]].
    rewrite Hbl.
    apply perm_trans with (a :: l1 ++ l2).
    + apply perm_skip. apply IH. intro n.
      destruct (Nat.eqb_spec a n) as [Ea | Ea].
      * subst n. symmetry. exact Hc.
      * specialize (H n). rewrite Hbl in H. rewrite count_app in H.
        simpl in H.
        assert (E : (a =? n) = false).
        { apply Nat.eqb_neq. exact Ea. }
        rewrite E in H. simpl in H.
        rewrite count_app. exact H.
    + apply Permutation_middle.
Qed.
```

骨架：对 `al` 归纳。空表情形交给 `bag_nil_inv`——`bl` 也只能是空表。cons 情形 `a :: tl` 分三步走：

1. **定位**：`assert (Ha : S (count a tl) = count a bl)` 把全称假设特化到表头 `a` 自己（注意用 `assert` 块做局部 `specialize`，特化只发生在花括号里，外面的 `H` 保持全称——直接 `specialize (H a)` 会把假设「烧掉」，46.8 第 3 条有实测报错）。`Ha` 说 `a` 在 `bl` 里至少出现一次，于是 `bag_cons_inv` 从 `bl` 里挖出一个具体的 `a`：`bl = l1 ++ a :: l2`，且 `count a (l1 ++ l2) = count a tl`（`Hc`）。
2. **递归**：证 `bag_eqv tl (l1 ++ l2)` 后由 IH 得 `tl ~ l1 ++ l2`，再 `perm_skip` 补回公共头部。计数义务对任意 `n` 分两案：`a = n` 时就是 `Hc` 掉个头；`a <> n` 时把 `H` 特化到 `n`、改写进 `bl` 的分解、经 `count_app` 穿过拼接——`simpl` 摊开后同一个 `if a =? n then 1 else 0` 在两侧各出现一次，`assert (E : (a =? n) = false). rewrite E in H` 双双归零，两侧剩下的分别是 `count n tl` 与 `count n l1 + count n l2`，后者再 `rewrite count_app` 回拼接送还 `H`。这里 `simpl in H` 之前**必须**先 `rewrite count_app in H`——`simpl` 对「`count` 作用在 `l1 ++ ...`（`l1` 是变量）」无能为力，46.8 第 1 条就是这条路径上的实测报错。
3. **合龙**：`a :: (l1 ++ l2) ~ l1 ++ a :: l2` 恰是标准库 `Permutation_middle`（第 36 章自造过它的孪生兄弟 `perm_mid`，方向相反），一步收官。

### 46.6 主定理：两种排序规格等价

```coq
(* ---------- 46.6 主定理：两种排序规格等价 ---------- *)

Theorem bag_eqv_iff_perm :
  forall al bl, bag_eqv al bl <-> Permutation al bl.
Proof.
  intros al bl. split.
  - apply bag_perm.
  - apply perm_bag.
Qed.

Theorem sort_specifications_equivalent :
  forall f, is_a_sorting_algorithm f <-> is_a_sorting_algorithm' f.
Proof.
  intros f. unfold is_a_sorting_algorithm, is_a_sorting_algorithm'.
  split.
  - intros Hf al. destruct (Hf al) as [Hperm Hsorted]. split.
    + apply bag_eqv_iff_perm. exact Hperm.
    + exact Hsorted.
  - intros Hf al. destruct (Hf al) as [Hbag Hsorted]. split.
    + apply bag_eqv_iff_perm. exact Hbag.
    + exact Hsorted.
Qed.

Print Assumptions bag_eqv_iff_perm.

End Ex46BagPerm.
```

两个方向缝合，主定理 `bag_eqv_iff_perm` 落地：**计数相等当且仅当互为重排**。`sort_specifications_equivalent` 再把它注入规格层：对任意函数 `f`，Permutation 版与 bag 版的「排序算法」定义互推——两个方向都只是把合取拆开、用主定理改写一半、再合回去（`sorted` 那一半原样搬运）。推论直接回答了 46.3 结尾悬着的问题：第 33–36 章用 `Permutation` 证的一切排序正确性，与第 37 章和本章用多重集证的，**选哪种都行**。收尾的 `Print Assumptions bag_eqv_iff_perm` 实测输出 `Closed under the global context`——整条「count 定律 → 正向归纳 → 反向三件套 → 主定理 → 推论」的链路零公理，这一点上比第 37 章函数式多重集（每条等式都要函数外延性）走得更干净。

### 46.7 本章小结

- **bag 是列表换一种问法**：`bag := list nat` 不引入新类型，「多重集相等」定义为逐点计数等式 `bag_eqv := forall n, count n b1 = count n b2`，比函数式多重集（第 37 章）少一层外延性公理。
- **计数定律是通行证**：`count_nonzero`（计数正 ⟺ 是成员）、`count_app`（count 穿拼接）、`count_remove`（删一次计数减一）、`count_insert_other`（插入不影响他人计数）四条定律让「算账」不用每次从头归纳。
- **正向容易**：`Permutation -> bag_eqv` 对置换证据归纳，四构造子四分支，skip/swap 两分支的全部算术交给 `lia`。
- **反向难在「从计数反推结构」**：`bag_nil_inv`（空表反转）、`bag_cons_inv`（把一次出现挖成分解）是从数字世界回到列表世界的桥；`bag_perm` 的「定位 → 递归 → `Permutation_middle` 合龙」三步是原书 advanced 路线的标准走法。
- **规格自由是有定理背书的**：`bag_eqv_iff_perm` ⟹ `sort_specifications_equivalent`——Permutation 规格与计数规格在排序验证中完全 interchangeable，选哪种只看哪种证明顺手（经验上：cons/insert 型算法两种都行，拼接密集的算法计数法往往更顺）。
- 战术层面：原书 `bdestruct`/`inv` 的替身是 `destruct (Nat.eqb_spec _ _)` / `destruct (Nat.leb_spec _ _)`（布尔改写与命题证据一步拿全）加上 `destruct ... eqn:` + `rewrite` 处理 simpl 再生出来的 if。

### 46.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或复现过。

1. **`simpl` 化不动「count 作用在 `l1 ++ ...` 上」（46.5 `bag_perm`）**：`l1` 是变量时 `count n (l1 ++ a :: l2)` 原样不动，指望 `simpl in H` 摊开它必然落空——本文件首次编译就死在这里，实测报错 `The term "H" has type "count n tl = count n (l1 ++ a :: l2)" while it is expected to have type "count n tl = count n l1 + count n l2".` 对策：先 `rewrite count_app in H` 再 `simpl in H`。
2. **`lia` 把不透明布尔 if 抽象成无界原子**：同一个 if-项在等式两侧同时出现时 `lia` 白嫖成功（实测 `count_app`、`bag_eqv_example` 去掉 destruct 只留 `lia` 也能过）；但想单独界定它时（如 `count v (h :: t) <= S (count v t)`），实测报 `Error: Tactic failure:  Cannot find witness.`——原子没有 0/1 的界，必须先 `destruct` 布尔。
3. **`specialize` 会把全称假设「烧掉」**（46.5 `bag_perm`）：`specialize (H a)` 之后 `H` 变成一条具体等式，再 `specialize (H 0)` 实测报 `Error: Illegal application (Non-functional construction): The expression "H" of type "(if a =? a then 1 else 0) + count a tl = count a bl" cannot be applied to the term "0" : "nat".` 对策：把特化放进 `assert (Ha : ...) { specialize ... }` 块里，外面的 `H` 保持全称。
4. **`apply IH` 跨不过 simpl 重新生成的 if**（46.1 `count_remove`）：`simpl in H |- *` 把 `count v (h :: remove v t)` 摊开时**又生出一个新的 `if h =? v`**（destruct 时换掉的是旧项），直接 `apply IH` 实测报 `Unable to unify "count v t = S (count v (remove v t))" with "count v t = S ((if h =? v then 1 else 0) + count v (remove v t))".` 对策：先 `rewrite E`（`E : (h =? v) = false`）再 `simpl` 再 `apply IH`。
5. **忘了 `bag_eqv` 是 `forall` 就去拆布尔**（46.2 `bag_eqv_example`）：`Proof. destruct (1 =? n); ...` 直接实测报 `Error: The variable n was not found in the current environment.` ——先 `intro n`（或 `intros b1 b2 H n` 全套引入）再动布尔。
6. **`sort_bag` 想一步 `apply insert_bag`**（46.3）：目标 `bag_eqv (x :: t) (insert x (sort t))` 与 `insert_bag` 的结论 `bag_eqv (x :: l) (insert x l)` 只差在归纳假设没接，实测报 `Error: Unable to unify "sort t" with "t".`（unifier 试图把 `?l` 同时配成 `sort t` 与 `t`）。对策：`bag_eqv_trans with (x :: sort t)` 中转，先 `bag_eqv_cons` 接 IH，再 `insert_bag`。

---
上一章：[45 · Trie：字符串键的映射](45-trie.md) ｜ 下一章：[47 · 四色定理](47-color.md) ｜ 返回：[README](../README.md)
