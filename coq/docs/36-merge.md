# 36 · 归并排序：终止性递归

对应示例：`../examples/36_merge.v`（`Module Ex36Merge`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

归并排序是 O(N log N) 的分治算法：把表对半**split**、两边递归排序、再把两个有序表**merge** 成一个。它是 VFA 排序三部曲里证明难度最高的一章，难点全不在算法本身，而在**让 Coq 接受定义**：`split` 的自然证明需要一种列表上没有的归纳法（36.1 的「二步归纳」）；`merge` 的自然定义两个参数交替递减，`Fixpoint` 死活不肯收（36.2 的「内嵌 fix」）；`mergesort` 递归于算出来的子表，需要第 35 章的 `Function measure` 且要缴**两份**终止税（36.3）。三条阵线各有一件兵器，36.4 再把第 33–35 章的全部置换与有序装备拉出来打正确性总攻。

规格仍是 `is_a_sorting_algorithm = Permutation + sorted`。本章新增的「库存」：自定义归纳原理（呼应第 50 章对归纳原则的解剖）、`merge2/merge2'` 两条「一步展开」引理、以及 `perm_mid` 这个把元素从表中间搬到表头的置换小五金。

### 36.1 split 与二步归纳原理

文件头与对半拆分函数：

```coq
(* 36 归并排序 —— 二步归纳原理、局部递归 Function 与双重正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation Recdef.
Import ListNotations.

Module Ex36Merge.

(* ---------- 36.1 split 与二步归纳原理 ---------- *)

Fixpoint split {X : Type} (l : list X) : list X * list X :=
  match l with
  | [] => ([], [])
  | [x] => ([x], [])
  | x1 :: x2 :: l' =>
    let (l1, l2) := split l' in
    (x1 :: l1, x2 :: l2)
  end.
```

`split` 是多态的（拆表与元素类型无关），按**交替发牌**把元素分进左右两堆：`[x]` 全给左边，两个以上时第一个进左、第二个进右、其余继续。它自己终止得很规矩——每次剥掉**两个**元素再看尾部，所以对 `l` 的递归隔了一层。问题出在证明它性质的时候：

```coq
Lemma split_len_first_try : forall {X : Type} (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  induction l; intros.
  - inversion H. simpl. lia.
  - destruct l as [ | x l'].
    + inversion H.
      split; simpl; auto.
    + simpl in H.
      destruct (split l') as [m1 m2] eqn:E. simpl in H.
      injection H as Ha Hb. subst. simpl.
      (* 卡住了：IH 覆盖的是 split (x::l')，这里需要 split l' 的事实。 *)
Abort.
```

`split_len_first_try` 想证「两半都不比原表长」——显然为真，但标准列表归纳**够不着**：`induction l` 的归纳假设只保证「对**尾部** 成立」，而 `split (x1::x2::l')` 的递归调用作用在 `l'`（尾部的尾部）上。注释行就是卡死的现场：手里有 `split l'` 的分量（`m1/m2`，第三行 destruct 出来的），IH 却只肯谈 `split (x::l')`。**每次剥两层的函数，需要每次剥两层的归纳法**：

```coq
Definition list_ind2_principle :=
  forall (A : Type) (P : list A -> Prop),
    P [] ->
    (forall a : A, P [a]) ->
    (forall (a b : A) (l : list A), P l -> P (a :: b :: l)) ->
    forall l : list A, P l.

Definition list_ind2 :
  forall (A : Type) (P : list A -> Prop),
      P [] ->
      (forall a : A, P [a]) ->
      (forall (a b : A) (l : list A), P l -> P (a :: b :: l)) ->
      forall l : list A, P l :=
  fun (A : Type)
      (P : list A -> Prop)
      (H : P [])
      (H0 : forall a : A, P [a])
      (H1 : forall (a b : A) (l : list A), P l -> P (a :: b :: l)) =>
    fix IH (l : list A) : P l :=
    match l with
    | [] => H
    | [x] => H0 x
    | x :: y :: l' => H1 x y l' (IH l')
    end.
```

`list_ind2_principle` 把「二步归纳」写成命题：要证 `P l`，只需证三个基例——`P []`、`P [a]`、以及「`P l'` ⇒ `P (a::b::l')`」（**一步跳过两个**）。`list_ind2` 是它的证明，而且是**手写的证明项**：一个 `fix` 局部递归函数 `IH`，按 `l` 的三种形状分别返回三个前提的实例——递归调用 `IH l'` 落在 `l'` 上、`l'` 是 `x::y::l'` 的子项，终止检查放行。这正是第 50 章「归纳原则就是证明项」的预告：**归纳法不是上天赐的，是一个类型为『forall P, 前提 ⇒ 结论』的项**；你随时可以自己造。

有了二步归纳，卡死的证明一路畅通：

```coq
Lemma split_len' :
  list_ind2_principle ->
  forall (X : Type) (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  unfold list_ind2_principle. intro IP.
  induction l as [ | x | x1 x2 l' IH] using IP; intros l1 l2 H.
  - inversion H. simpl. lia.
  - inversion H. simpl. lia.
  - simpl in H. remember (split l') as p. destruct p as [m1 m2].
    simpl in H. injection H as Ha Hb. subst.
    clear Heqp.
    destruct (IH m1 m2 eq_refl) as [P1 P2]. simpl. lia.
Qed.

Lemma split_len : forall (X : Type) (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  apply (@split_len' list_ind2).
Qed.
```

`split_len'` 先把原理当**假设**用（`induction l ... using IP`——`using` 子句指定非默认的归纳原理，三个分支的 `as` 模式 `[ | x | x1 x2 l' IH]` 恰好对应三个前提）；`split_len` 再把 `list_ind2` 塞进去把假设兑现。「假设原理 → 证明 → 兑现」的三段式把「需要什么归纳法」与「它为什么成立」分离开，这是造自定义归纳原理的标准工作流。

第三个分支的五行浓缩了本章最多的战术细节，值得逐行慢放。`simpl in H`：把 `H : split (x1::x2::l') = (l1,l2)` 化成 `let (a,b) := split l' in ... = (l1,l2)`——注意 `simpl` 只展开到 `split l'` 为止（`l'` 是变量，再展不动）。`remember (split l') as p`：把 `split l'` 冻结成新变量 `p`，**这一步是护 IH 用的**——直接 `destruct (split l')` 会把 IH 前提里的 `split l'` 一并换成 `(m1,m2)`，IH 变成 `(m1,m2) = l1'' -> ...`（实测坑，见 36.6）；remember 之后 `destruct p` 只动 `p`。`simpl in H. injection H as Ha Hb. subst.`：`H` 变成 `(x1::m1, x2::m2) = (l1,l2)`，injection 拆对、subst 代入。`clear Heqp`：remember 留下的等式 `p = split l'` 用不上了，清场。最后一行是全段的戏眼：`IH m1 m2 eq_refl`——尽管 remember 已经尽力，IH 的前提仍被 destruct 改写成了 `(m1,m2) = ?`，给它喂 `eq_refl`（自反性）正好满足。`P1/P2` 就是两半的长度账，`simpl. lia` 结账。

```coq
Lemma perm_mid : forall (X : Type) (m1 : list X) (a : X) (m2 : list X),
  Permutation (m1 ++ a :: m2) (a :: m1 ++ m2).
Proof.
  intros X m1. induction m1 as [ | y m1' IH]; intros a m2.
  - apply Permutation_refl.
  - simpl. apply perm_trans with (y :: a :: m1' ++ m2).
    + apply perm_skip. apply IH.
    + apply perm_swap.
Qed.

Lemma split_perm : forall (X : Type) (l l1 l2 : list X),
    split l = (l1, l2) -> Permutation l (l1 ++ l2).
Proof.
  intros X l.
  induction l as [ | x | x1 x2 l' IH] using list_ind2; intros l1 l2 H.
  - inversion H. subst. apply perm_nil.
  - inversion H. subst. apply perm_skip. apply perm_nil.
  - simpl in H. remember (split l') as p. destruct p as [m1 m2].
    simpl in H. injection H as Ha Hb. subst.
    clear Heqp.
    simpl. apply perm_skip.
    apply perm_trans with (x2 :: m1 ++ m2).
    + apply perm_skip. apply (IH m1 m2 eq_refl).
    + apply Permutation_sym. apply perm_mid.
Qed.
```

`perm_mid` 是本章自造的置换小五金：**把 `a` 从拼接的中缝搬到最前头**（`m1 ++ a::m2 ~ a :: m1++m2`）。证明对 `m1` 归纳，一步「skip + swap」走两格——与标准库的 `Permutation_middle` 互为方向，自己造一遍的好处是 36.4 里用起来不用猜库版的参数朝向。`split_perm`（split 是重排）第三分支的手法与 `split_len'` 逐字相同（remember 五连），置换部分：目标 `x1::x2::l' ~ (x1::m1) ++ (x2::m2)`，`simpl` 后 skip 掉共同的 `x1`，剩下 `x2::l' ~ m1 ++ x2::m2`——中转站 `(x2 :: m1++m2)`：前半段 skip + IH，后半段正好是 `perm_mid` 的对称。

### 36.2 merge：让 Fixpoint 低头的一步

```coq
(* ---------- 36.2 merge：让 Fixpoint 低头的一步 ---------- *)

Fail Fixpoint merge_bad (l1 l2 : list nat) : list nat :=
  match l1, l2 with
  | [], _ => l2
  | _, [] => l1
  | a1 :: l1', a2 :: l2' =>
      if a1 <=? a2 then a1 :: merge_bad l1' l2
      else a2 :: merge_bad l1 l2'
  end.

Fixpoint merge (l1 l2 : list nat) {struct l1} : list nat :=
  let fix merge_aux l2 :=
  match l1, l2 with
  | [], _ => l2
  | _, [] => l1
  | a1 :: l1', a2 :: l2' =>
      if a1 <=? a2 then a1 :: merge l1' l2 else a2 :: merge_aux l2'
  end
  in merge_aux l2.
```

教科书式定义直接被拒：实测报错 `Error: Cannot guess decreasing argument of fix.`。`merge` 明明终止——每步**要么**左表短一截**要么**右表短一截——但 `Fixpoint` 要求递减发生在**单一固定**的参数上，`l1`、`l2` 都不够格。不是 Coq 笨，是它只检查「结构递减」这一种它无法推理出错的形式。解法很巧：外层 `Fixpoint` 声明 `{struct l1}`（对 `l1` 结构递减），体内用 **`let fix` 定义局部递归函数 `merge_aux`**（只对 `l2` 递归）。于是「比谁小就动谁」变成「左小动外层、右小动内层」：`a1 <= a2` 走外层递归（`merge l1' l2`，左表短了），否则走内层（`merge_aux l2'`，右表短了而 `l1` 原封不动）。代价在下一组引理里付。

```coq
Lemma merge2 : forall (x1 x2 : nat) (r1 r2 : list nat),
    x1 <= x2 ->
    merge (x1 :: r1) (x2 :: r2) = x1 :: merge r1 (x2 :: r2).
Proof.
  intros x1 x2 r1 r2 H. simpl.
  destruct (x1 <=? x2) eqn:E.
  - reflexivity.
  - apply Nat.leb_gt in E. exfalso. lia.
Qed.

Lemma merge2' : forall (x1 x2 : nat) (r1 r2 : list nat),
    x2 < x1 ->
    merge (x1 :: r1) (x2 :: r2) = x2 :: merge (x1 :: r1) r2.
Proof.
  intros x1 x2 r1 r2 H. simpl.
  destruct (x1 <=? x2) eqn:E.
  - apply Nat.leb_le in E. exfalso. lia.
  - destruct r2; reflexivity.
Qed.

Lemma merge_nil_l : forall l, merge [] l = l.
Proof.
  intros l. simpl. destruct l.
  - reflexivity.
  - reflexivity.
Qed.
```

`simpl` 面对 `let fix` 定义的 `merge` 会把内层函数整个抖出来（目标里出现 `(fix merge_aux ...)` 的大项），观感很差但**转换关系是对的**——三条引理各处理一种「一步展开」：`merge2` 是左头胜出（`x1 <= x2`）时的一步方程；`merge2'` 是右头胜出（注意前提是**严格** `x2 < x1`——若写成 `<=`，等值时走的是左支，引理直接为假）；`merge_nil_l` 是左空表的恒等式。三个证明的共同姿势：`destruct (x1 <=? x2) eqn:E` 撕开布尔（它出现在 simpl 后的项里，destruct 会替换之），然后要么 `reflexivity`（两侧转换等价），要么矛盾（前提 `H` 与 `E` 兑出的命题打架，`exfalso. lia`——注意目标是**列表等式**不是算术命题，直接 `lia` 不接，必须先 `exfalso` 转成 `False`）。`merge2'` 的 false 分支多一步 `destruct r2`：内层 `fix` 套在变量 `r2` 上不归约，给它一个构造子形状（`[]` 或 `b::t`）才能继续化简——**「Coq 拒绝化简一个显然的应用？把参数 destruct 开」**是本章的第二条 moral。

这三条「一步方程」就是 36.4 全部证明的地基：`merge` 的定义因为 `let fix` 不可直接 `simpl`/`unfold`，一切关于它的推理都改成 `rewrite merge2 / merge2' / merge_nil_l`——把不可控的展开变成可控的、带前提的方程。

### 36.3 mergesort：Function measure 的双递归

```coq
(* ---------- 36.3 mergesort：Function measure 的双递归 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) :=
  forall al, Permutation al (f al) /\ sorted (f al).

Function mergesort (l : list nat) {measure length l} : list nat :=
  match l with
  | [] => []
  | [x] => [x]
  | _ => let (l1, l2) := split l in
         merge (mergesort l1) (mergesort l2)
  end.
Proof.
  - intros l x l0 n l1 Hl0 Hl l2 l3 Hsplit.
    simpl in Hsplit.
    destruct (split l1) as [m1 m2] eqn:E. simpl in Hsplit.
    injection Hsplit as Ha Hb. subst l2 l3.
    destruct (split_len _ _ _ _ E) as [H1 H2]. simpl. lia.
  - intros l x l0 n l1 Hl0 Hl l2 l3 Hsplit.
    simpl in Hsplit.
    destruct (split l1) as [m1 m2] eqn:E. simpl in Hsplit.
    injection Hsplit as Ha Hb. subst l2 l3.
    destruct (split_len _ _ _ _ E) as [H1 H2]. simpl. lia.
Defined.

Example mergesort_pi :
  mergesort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof. reflexivity. Qed.

Check mergesort_equation.

Check mergesort_ind.
```

直接写 `let (l1,l2) := split l in merge (mergesort l1) (mergesort l2)` 会被终止检查器再次拒收（`Recursive call to mergesort has principal argument equal to "l1" instead of a subterm of "l"`）；而且**这次 Coq 拒得有理**——`split []` 返回 `([],[])`，对空表无限递归的定义根本不终止，是 totality 检查逼我们补上 `[]` 和 `[x]` 两个基例。于是定义成形：两元素以上才 split。`Function ... {measure length l}` 与第 35 章 `selsort'` 同款，但这次有**两个递归调用点**，Coq 开出**两份**终止义务，实测形状（第一份，第二份把 `l3` 换成 `l2`）：

```
forall (l : list nat) (x : nat) (l0 : list nat) (n : nat) (l1 : list nat),
l0 = n :: l1 ->
l = x :: n :: l1 ->
forall l2 l3 : list nat,
split (x :: n :: l1) = (l2, l3) -> length l3 < length (x :: n :: l1)
```

`intros` 九连把义务里的模式变量与等式全部领进上下文，然后是熟悉的拆对五步——但这次有个新坎：义务要的是**严格** `<`，而 `split_len` 只给 `<=`，`lia` 拼不出来。必须把 split 的输出形状抖出来：`simpl in Hsplit` 后 destruct `split l1`，`injection` 得到 `l2 = x::m1`、`l3 = n::m2`——`l3` 至少有一个元素，结合 `split_len` 的 `length m2 <= length l1`，`length (n::m2) < length (x::n::l1)` 便是 `lia` 一步的事。**「≤ 加上结构里白送的一个元素 = <」**，这是 fuel/measure 义务的常见收尾套路。`Defined` 收尾（要能算），`mergesort_pi` 的 `reflexivity` 实测跑通——归并排序真的在 kernel 里算完了 π 的十个数字。

`Function` 顺手生成的两件赠品，实测类型如下：

```
mergesort_equation
     : forall l : list nat,
       mergesort l =
       match l with
       | [] => []
       | [x] => [x]
       | x :: _ :: _ =>
           let (l2, l3) := split l in merge (mergesort l2) (mergesort l3)
       end
```

`mergesort_equation` 是官方的一步展开（同 `selsort'_equation`），36.4 里想动 `mergesort` 一律 rewrite 它。`mergesort_ind` 则是本章真正的宝贝——**为 mergesort 量身定制的归纳原理**：

```
mergesort_ind
     : forall P : list nat -> list nat -> Prop,
       (forall l : list nat, l = [] -> P [] []) ->
       (forall (l : list nat) (x : nat), l = [x] -> P [x] [x]) ->
       (forall l _x : list nat,
        l = _x ->
        match _x with
        | _ :: _ :: _ => True
        | _ => False
        end ->
        forall l1 l2 : list nat,
        split l = (l1, l2) ->
        P l1 (mergesort l1) ->
        P l2 (mergesort l2) -> P _x (merge (mergesort l1) (mergesort l2))) ->
       forall l : list nat, P l (mergesort l)
```

读法：要对 `mergesort` 证性质 `P`（注意 `P` 是**二元**的——把输入和输出一起当索引），证三个分支：空表、单元素、以及「`split l = (l1,l2)` 且两半各自归纳成立 ⇒ 合并结果成立」。它把「递归结构」原样搬进「证明结构」——第 36.1 节手造 `list_ind2` 是为了 `split`，这里 `Function` 免费送了一个给 `mergesort`。**自定义归纳原理不是花活，是分治证明的刚需**。

### 36.4 正确性：sorted 与 Permutation 两线

```coq
(* ---------- 36.4 正确性：sorted 与 Permutation 两线 ---------- *)

Lemma sorted_tail : forall x l, sorted (x :: l) -> sorted l.
Proof.
  intros x l H. inversion H; subst.
  - apply sorted_nil.
  - assumption.
Qed.
```

先备一件小工具：有序表去头仍有尾序（`sorted_1` 分支尾部是 `[]`，`sorted_cons` 分支尾部就是前提）。inversion 出的两种情况各一行。

```coq
Lemma sorted_merge1 : forall x x1 l1 x2 l2,
    x <= x1 -> x <= x2 ->
    sorted (merge (x1 :: l1) (x2 :: l2)) ->
    sorted (x :: merge (x1 :: l1) (x2 :: l2)).
Proof.
  intros x x1 l1 x2 l2 Hx1 Hx2 Hm.
  destruct (Nat.leb x1 x2) eqn:E.
  - apply Nat.leb_le in E.
    rewrite (merge2 x1 x2 l1 l2 E) in Hm |- *.
    apply sorted_cons; [exact Hx1 | exact Hm].
  - apply Nat.leb_gt in E.
    rewrite (merge2' x1 x2 l1 l2 E) in Hm |- *.
    apply sorted_cons; [exact Hx2 | exact Hm].
Qed.

Lemma sorted_merge : forall l1, sorted l1 ->
                     forall l2, sorted l2 ->
                     sorted (merge l1 l2).
Proof.
  induction l1 as [ | a1 l1' IH1]; intros H1 l2 H2.
  - rewrite merge_nil_l. exact H2.
  - revert H2. induction l2 as [ | a2 l2' IH2]; intro H2.
    + simpl. exact H1.
    + destruct (Nat.leb a1 a2) eqn:E.
      * apply Nat.leb_le in E.
        rewrite (merge2 a1 a2 l1' l2' E).
        destruct l1' as [ | c l1''].
        -- rewrite merge_nil_l.
           apply sorted_cons; [exact E | exact H2].
        -- inversion H1 as [ | | i j l Hac Hs1 Heq1]; subst.
           apply (sorted_merge1 a1 c l1'' a2 l2' Hac E).
           apply IH1; [exact Hs1 | exact H2].
      * apply Nat.leb_gt in E.
        rewrite (merge2' a1 a2 l1' l2' E).
        destruct l2' as [ | b l2''].
        -- simpl. apply sorted_cons; [lia | exact H1].
        -- inversion H2 as [ | | i j l Hab Hs2 Heq2]; subst.
           apply (sorted_merge1 a2 a1 l1' b l2''
                    (Nat.lt_le_incl _ _ E) Hab).
           apply IH2. exact Hs2.
Qed.
```

`sorted_merge1` 是「有序合并」的核心一步：**同时压制两个头的数 `x`，接到合并结果前面仍然有序**——合并结果的头要么是 `x1` 要么是 `x2`，两个都被 `x` 压住。证明就是用 `merge2/merge2'` 把 `Hm` 与目标**同步**展开一步（`rewrite ... in Hm |- *` 的 `|- *` 表示「假设和目标都改写」），然后 `sorted_cons` 收。

`sorted_merge` 是 VFA 标注 4 星的难题，难点在**归纳结构**：对 `l1` 归纳之后，`a1 <= a2` 分支的递归调用是 `merge l1' (a2::l2')`（左短了，外层 IH1 管），但 `a2 < a1` 分支的递归调用是 `merge (a1::l1') l2'`（**左表没动、右表短了**，外层 IH1 根本不管辖！）。所以 cons 分支里必须 `revert H2. induction l2` 做**嵌套归纳**——内层 IH2 专门接住「右表递减」的调用。两个分支各自的 `destruct l1'`/`destruct l2'` 是给 `sorted_merge1` 补弹药：`x` 要压制的头必须真的存在（`l1' = c::l1''` 时用 inversion 从 `H1` 挖出 `a1 <= c`；`l2' = b::l2''` 时从 `H2` 挖出 `a2 <= b`），而表为空时合并结果直接是另一边、`sorted_cons` 一步收。四处 `inversion ... as [ | | i j l 前提1 前提2 等式]`——六个名：三个元素变量、两条前提、一条索引等式（实测 `?` 占位符不允许用在等式槽，见 36.6）。

```coq
Lemma mergesort_sorts : forall l, sorted (mergesort l).
Proof.
  apply mergesort_ind.
  - intros. apply sorted_nil.
  - intros. apply sorted_1.
  - intros. apply sorted_merge; assumption.
Qed.
```

`mergesort_sorts` 三行——**这就是 mergesort_ind 的回报**。三个分支严格对齐递归的三个分支：基例构造 `sorted`，递归分支一句 `sorted_merge` 加 `assumption`（两个 IH 就在上下文里）。对比第 35 章 `selsort_sorted` 还要自己对燃料归纳、自己 destruct select 的输出，量身定制的归纳原理把管道工程全省了。

```coq
Lemma merge_perm : forall (l1 l2 : list nat),
    Permutation (l1 ++ l2) (merge l1 l2).
Proof.
  induction l1 as [ | a1 l1' IH1]; intros l2.
  - rewrite merge_nil_l. simpl. apply Permutation_refl.
  - induction l2 as [ | a2 l2' IH2].
    + rewrite app_nil_r. simpl. apply Permutation_refl.
    + destruct (Nat.leb a1 a2) eqn:E.
      * apply Nat.leb_le in E.
        rewrite (merge2 a1 a2 l1' l2' E).
        simpl. apply perm_skip. apply (IH1 (a2 :: l2')).
      * apply Nat.leb_gt in E.
        rewrite (merge2' a1 a2 l1' l2' E).
        simpl.
        apply perm_trans with (a1 :: a2 :: l1' ++ l2').
        -- apply perm_skip. apply perm_mid.
        -- apply perm_trans with (a2 :: (a1 :: l1') ++ l2').
           ++ apply perm_swap.
           ++ apply perm_skip. exact IH2.
Qed.
````merge_perm` 与 `sorted_merge` 同构：左头胜出（`merge2`）时 `a1 :: (l1' ++ a2::l2')` skip 一步交给外层 IH1；右头胜出（`merge2'`）时走 `perm_mid` 的三段拼装——`a1::(l1'++a2::l2') → a1::a2::(l1'++l2')`（skip + perm_mid），再 `→ a2::(a1::l1')++l2'`（swap），最后 skip + 内层 IH2 落到 `merge (a1::l1') l2'`。左空/右空两个基例注意 `app_nil_r`——`simpl` 对 `(a1::l1') ++ []` 只会化到 `a1 :: (l1' ++ [])` 就卡住（`l1'` 是变量），必须 rewrite 库引理 `l ++ [] = l` 才能露出真身（实测坑，见 36.6）。

```coq
Lemma mergesort_perm : forall l, Permutation l (mergesort l).
Proof.
  apply mergesort_ind.
  - intros. apply perm_nil.
  - intros. apply Permutation_refl.
  - intros l lx Heq Hcond la lb Hsplit IH1 IH2.
    subst l.
    apply perm_trans with (la ++ lb).
    + apply (split_perm nat lx la lb Hsplit).
    + apply perm_trans with (mergesort la ++ lb).
      * apply Permutation_app_tail. exact IH1.
      * apply perm_trans with (mergesort la ++ mergesort lb).
        -- apply Permutation_app_head. exact IH2.
        -- apply merge_perm.
Qed.

Theorem mergesort_correct :
  is_a_sorting_algorithm mergesort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply mergesort_perm.
  - apply mergesort_sorts.
Qed.

Print Assumptions mergesort_correct.

End Ex36Merge.
```

`mergesort_perm` 的递归分支是一条**四段换乘线**：`lx ~ la++lb`（36.1 的 `split_perm`）→ `mergesort la ++ lb`（标准库 `Permutation_app_tail`：后缀不动、前段换）→ `mergesort la ++ mergesort lb`（`Permutation_app_head`：前缀不动、后段换）→ `merge_perm` 合并收官。注意 `subst l`：`mergesort_ind` 的义务里 `split l` 用的是外层变量 `l`，先把 `Heq : l = lx` 代掉再喂 `split_perm`。`mergesort_correct` 合取两线，`Print Assumptions` 实测 `Closed under the global context`——含着 `let fix`、`Function`、自定义归纳原理的整个证明，无公理。

收个尾。本章的三个「终止性兵器」已集齐三件：燃料（第 35 章，自己动手）、`let fix`（本章 36.2，巧劲）、`Function measure`（两章通用，官方代办，代价是 equation 引理 + Defined）。证明侧的两件新库存：自定义归纳原理（`list_ind2` 手造、`mergesort_ind` 自动）与「不可 simpl 的函数配一组一步方程引理」（`merge2/merge2'`）。下一章暂别算法、回到规格层：第 37 章用**多重集**把 `Permutation` 换一种说法，看看同一份正确性还能怎么写。

### 36.5 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`simpl` 展得比你以为的深**（36.1）：`simpl in H` 处理 `split (x1::x2::l')` 时会一路化到 scrutinee 为 `split l'`（把 `(x::l')` 那层也剥掉），照直觉去 `destruct (split (x::l'))` 对不上 `H` 里的语法。destruct/rewrite 的目标必须与 simpl **之后**的形状一致。
2. **`destruct (split l')` 会改写 IH 的前提但改不动 let 底下的 H**（36.1）：IH 前提变成 `(m1,m2) = l1`（喂 `eq_refl` 是标准解法），而 `H : (let (a,b) := split l' in ...) = ...` 原样不动、`injection` 实测报 `Nothing to inject`。对策：`simpl in H` 先让 `split l'` 露头，再 `remember (split l') as p. destruct p`，最后 `IH m1 m2 eq_refl`。
3. **`forall a b : A (l : list A)` 不是合法绑定组**（36.1）：漏写一对括号实测在 Definition 的类型里报 `The reference l was not found`——多变量绑定必须 `forall (a b : A) (l : list A)`。
4. **`inversion ... as` 的等式槽不许用 `?`**（36.4）：`as [ | | ? ? ? Hac Hs1 ?]` 实测报 `Anonymous pattern not allowed for inversion equations`——最后一个槽位是索引等式，必须给实名（如 `Heq1`）。
5. **`split_len` 的 `X` 是显式参数**（36.3）：全参应用要**四个**下划线 `split_len _ _ _ _ E`（X、l、l1、l2）；三个下划线实测把 `E` 塞进 `l2` 槽，报 `The term "E" ... expected "list ?X"`。
6. **measure 义务要严格 `<`，`split_len` 的 `<=` 不够**（36.3）：只 lia 拼不出 `length l3 < length (x::n::l1)`；必须 destruct split 输出的形状（`l3 = n::m2` 白送一个元素）再 lia。
7. **目标是列表等式时矛盾分支要 `exfalso`**（36.2）：`merge2` 的矛盾分支直接 `lia` 实测不接——`lia` 只证算术目标；`exfalso. lia.` 先把目标换成 `False`。
8. **内层 `fix` 套在变量上不化简**（36.2）：`merge2'` 的 false 分支 `reflexivity` 卡在 `(fix merge_aux ...) r2`，`destruct r2` 给出构造子形状后才能归约。
9. **`merge2'` 的前提必须严格小于**（36.2）：写成 `x2 <= x1` 时引理为假（等值情形走左支），构造证明会在 true 分支暴露矛盾——恰好也是用 `exfalso. lia` 关掉的。
10. **`simpl` 化不动 `l ++ []`**（36.4）：`(a1::l1') ++ []` 只化到 `a1 :: (l1' ++ [])`（`l1'` 变量卡住），`Permutation_refl` 对不上；`rewrite app_nil_r` 先把 `l ++ [] = l` 用掉。
11. **`sorted_merge` 必须**嵌套**归纳**（36.4）：只对 `l1` 归纳时，`a2 < a1` 分支的递归调用 `merge (a1::l1') l2'` 左表未减、外层 IH 不适用（实测 unify 失败 `expected "sorted (merge (a1 :: l1') (a2 :: l2'))"`）。`revert H2. induction l2` 让内层 IH 专门接住右表递减。
12. **`mergesort_ind` 义务里 `split` 作用在原始变量上**（36.4）：义务给出 `Heq : l = lx` 且 `Hsplit : split l = ...`，不 `subst l` 就把 `Hsplit` 喂给 `split_perm` 会类型不合。

---
上一章：[35 · 选择排序：燃料与 measure](35-selection.md) ｜ 下一章：[37 · 多重集：另一种规格风格](37-multiset.md) ｜ 返回：[README](../README.md)
