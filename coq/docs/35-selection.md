# 35 · 选择排序：燃料与 measure

对应示例：`../examples/35_selection.v`（`Module Ex35Selection`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

插入排序（第 34 章）每步把新元素**插进**已排好的前缀；选择排序反其道而行：每步从剩余元素里**选出最小**的放到输出头部。两种都是二次复杂度，但选择排序在 Coq 里定义会撞上一堵墙——**递归调用不在结构上递减**，第 30 章「一般递归」预告过的场景在这里真实上演。本章两条主线：用**燃料**（fuel）绕过终止检查并完成全部正确性证明（35.1–35.2）；再用 `Function ... {measure ...}` 把燃料彻底扔掉，看同一套证明如何几乎原样平移（35.3）。

规格沿用第 34 章的定稿：`is_a_sorting_algorithm = Permutation + sorted`（本章就地复述定义，不依赖 34 章文件）；Permutation 的操作引理是第 33 章练熟的 `perm_skip/perm_swap/perm_trans`。全章的证明密度是 VFA 卷前几章之最——七条 `select` 引理排成一条链，层层喂给总装证明，这条「引理链」的排布本身就是本章的教学内容。

### 35.1 程序：select、燃料版 selsort 与 selection_sort

文件头与算法：

```coq
(* 35 选择排序 —— 燃料递归、选择引理链与 Function measure *)

From Stdlib Require Import Arith Bool Lia List Permutation Recdef.
Import ListNotations.

Module Ex35Selection.

(* ---------- 35.1 程序：select、燃料版 selsort 与 selection_sort ---------- *)

Fixpoint select (x : nat) (l : list nat) : nat * list nat :=
  match l with
  | [] => (x, [])
  | h :: t =>
    if x <=? h
    then let (j, l') := select x t
         in (j, h :: l')
    else let (j, l') := select h t
         in (j, x :: l')
  end.

Fail Fixpoint selsort_bad (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: r => let (y, r') := select x r
            in y :: selsort_bad r'
  end.

Fixpoint selsort (l : list nat) (n : nat) : list nat :=
  match l, n with
  | _, O => []
  | [], _ => []
  | x :: r, S n' => let (y, r') := select x r
                  in y :: selsort r' n'
  end.
```

`select x l` 返回**二元组**：`(x :: l)` 中最小的元素 + 剩余元素组成的表。它自己走路得很规矩：每步留下较大的那个守门（`x <=? h` 成立时 `h` 靠边站，否则 `x` 靠边站），候选者（较小者）继续往尾部走，所以对 `t` 的递归是结构递减的，`Fixpoint` 直接放行。

`Fail Fixpoint selsort_bad` 是本章的「案发现场」：想当然的选择排序——选出最小、放在递归排序剩余部分的前面——**编不过**。去掉 `Fail` 单独编译，rocq 9.3 的实测报错是：

```
Recursive definition of selsort_bad is ill-formed.
...
Recursive call to selsort_bad has principal argument equal to
"r'" instead of "r".
```

终止检查器说得直白：递归调用的主参数是 `r'`——一个由 `select` **算出来**的表——而不是输入 `x :: r` 的任何子项。`Fixpoint` 只认结构递减，`select` 会产出什么表它无从知晓（`select` 甚至可能返回不更短的表吗？不会，但要到 35.2 的 `select_rest_length` 才**证明**得了——注意这里的循环依赖：定义要先过终止检查，证明在定义之后）。

出路是第 30 章的**燃料**模式：给 `selsort` 加一个没有任何算法含义的参数 `n`，每轮递归消耗一单位。终止性由 `n` 的结构递减担保，`l` 是什么已经不重要。代价全在语义：燃料烧完了怎么办？

```coq
Example out_of_fuel : selsort [3;1;4;1;5] 3 <> [1;1;3;4;5].
Proof.
  simpl. intro. discriminate.
Qed.

Example extra_fuel : selsort [3;1;4;1;5] 10 = [1;1;3;4;5].
Proof.
  simpl. reflexivity.
Qed.

Definition selection_sort (l : list nat) : list nat :=
  selsort l (length l).

Example sort_pi :
  selection_sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof.
  unfold selection_sort.
  simpl. reflexivity.
Qed.
```

`out_of_fuel` 证明燃料不足会**半途而废**：给 5 个元素只加 3 单位燃料，输出只排了前几个（`simpl` 后两边是具体的表，`intro. discriminate` 一撞即中）。`extra_fuel` 说明**多给燃料无害**——燃料只是上界。精确定额是「表长」单位：`selection_sort` 就把 `length l` 当燃料。`sort_pi` 再次用 π 检验，`unfold` 一步展开定义后纯计算。注意从现在起，凡要证 `selsort` 的性质，都得**同时**交代两件事：列表确实排完了（长度对得上燃料）、燃料递减带来的归纳原理。这就是 35.2 里 `length l = n` 处处出现的原因。

### 35.2 正确性：选择引理链

规格复述（与 34 章逐字相同，本章自包含）：

```coq
(* ---------- 35.2 正确性：选择引理链 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) :=
  forall al, Permutation al (f al) /\ sorted (f al).

Example pairs_example : forall (a c x : nat) (b d l : list nat),
    (a, b) = (let (c, d) := select x l in (c, d)) ->
    (a, b) = select x l.
Proof.
  intros. destruct (select x l) as [c' d'] eqn:E. auto.
Qed.
```

先热身：`select` 返回**二元组**，后续证明要反复把它拆开。`pairs_example` 演示标准姿势——`destruct (select x l) as [c' d'] eqn:E`：既拿到两个分量（`c'`、`d'`），又用 `E` 把「`select x l` 就是 `(c',d')`」记在案。目标里的 `let (c,d) := ... in (c,d)` 在 destruct 之后归约成 `(c',d')`，与假设 `H` 相同，`auto` 收。这组 `destruct ... as [...] eqn:` 是全章出现频率最高的战术组合。

第一条真引理——`select` 是重排：

```coq
Lemma select_perm : forall x l y r,
    select x l = (y, r) -> Permutation (x :: l) (y :: r).
Proof.
  intros x l. revert x.
  induction l as [ | h t IH]; intros x y r H.
  - simpl in H. injection H as Hy Hr. subst.
    apply perm_skip. apply perm_nil.
  - simpl in H. destruct (x <=? h) eqn:E.
    + destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hr. subst.
      apply perm_trans with (h :: x :: t).
      * apply perm_swap.
      * apply perm_trans with (h :: y :: r').
        -- apply perm_skip. apply (IH x y r'). exact Et.
        -- apply perm_swap.
    + destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hr. subst.
      apply perm_trans with (x :: y :: r').
      * apply perm_skip. apply (IH h y r'). exact Et.
      * apply perm_swap.
Qed.
```

三点读法。**其一**，开头 `intros x l. revert x.`：先把 `x` 撤回量词再做对 `l` 的归纳，让 IH 对**任意候选者**成立——两个分支里递归的候选者不同（`x <= h` 时继续考察 `x`，否则换成 `h`），不 generalize 就只有死路。**其二**，`injection H as Hy Hr. subst.` 把二元组等式 `(y', h :: r') = (y, r)` 拆成两条标量等式并代入——此后上下文里只剩 `y`（`y'` 已被 `subst` 消掉，后面引用一律写 `y`，实测写 `y'` 报 `The variable y' was not found`）。**其三**，也是本章最值得记的**置换拼装套路**：目标 `Permutation (x :: h :: t) (y :: h :: r')` 两侧头都不相同，一步 `perm_skip` 咬不住；正确走法是三段式——`perm_swap` 把 `h` 换到头（`x::h::t → h::x::t`），`perm_skip` + IH 对齐尾部（`h::x::t → h::y::r'`，此时两头都是 `h`），再一次 `perm_swap` 交换到目标形状（`h::y::r' → y::h::r'`）。第二个分支同理但只要两段：`perm_skip` 直接把 IH（关于候选者 `h`）顶上去（`x::h::t → x::y::r'`，两头都是 `x`），最后一步 `perm_swap`。**先造一个「两头相同」的中间站，再换最后一步**——这是 `perm_skip` 世界的通用兵法。

```coq
Lemma select_rest_length : forall x l y r,
    select x l = (y, r) -> length l = length r.
Proof.
  intros x l y r H.
  assert (Hp : Permutation (x :: l) (y :: r)).
  { apply select_perm. exact H. }
  assert (Hlen : length (x :: l) = length (y :: r)).
  { apply Permutation_length. exact Hp. }
  simpl in Hlen. lia.
Qed.

Lemma selsort_perm : forall n l,
    length l = n -> Permutation l (selsort l n).
Proof.
  induction n as [ | n IHn]; intros l Hl.
  - destruct l as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply perm_nil.
  - destruct l as [ | x r].
    + simpl. apply perm_nil.
    + simpl in Hl. simpl.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply perm_trans with (y :: r').
      * apply (select_perm x r y r' E).
      * apply perm_skip. apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Lemma selection_sort_perm : forall l,
    Permutation l (selection_sort l).
Proof.
  intros l. unfold selection_sort.
  apply selsort_perm. reflexivity.
Qed.
```

`select_rest_length` 是「不重新归纳、白嫖前人」的示范：`select` 保重排（刚证的 `select_perm`）⇒ 两侧同长（第 33 章 `Permutation_length`）⇒ 去掉两边的 `x`/`y`（`simpl` + `lia`）。它就是 35.1 里悬而未决的「`select` 不会把表变长」——注意它**只能**在定义之后补证，因为燃料版的定义根本没依赖它。

`selsort_perm` 的归纳对象是**燃料 `n`**，不是列表！`length l = n` 这条伴随等式把两者锁死：`n = 0` 时列表必空（`simpl in Hl; discriminate` 拍死非空分支）；`n = S n'` 时列表 `x :: r` 递归一步，燃料、表长同步减一。递归调用作用在 `r'` 上——它的长度由 `select_rest_length + lia` 从 `Hl` 兑出 `length r' = n'`，喂给 IHn。`destruct (select x r) as [y r'] eqn:E. simpl.` 与 35.1 的热身完全同款。`selection_sort_perm` 按定额供油，`reflexivity` 核账，重排半场结束。

下半场「有序」要难一档——`select` 的输出**头部是最小元**，这个事实要拆成两条引理才好接：

```coq
Lemma select_fst_leq : forall al bl x y,
    select x al = (y, bl) ->
    y <= x.
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst. lia.
  - simpl in H. destruct (x <=? h) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      assert (Hy' := IH r' x y Et). lia.
    + apply Nat.leb_gt in E.
      destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      assert (Hy' := IH r' h y Et). lia.
Qed.

Definition le_all (x : nat) (xs : list nat) : Prop :=
  Forall (fun y => x <= y) xs.

Infix "<=*" := le_all (at level 70, no associativity).

Lemma le_all__le_one : forall lst y n,
    y <=* lst -> In n lst -> y <= n.
Proof.
  intros lst y n H Hin. unfold le_all in H.
  rewrite Forall_forall in H. apply H. exact Hin.
Qed.
```

`select_fst_leq`：输出头 `y` 不超过**初始候选者** `x`。对 `al` 归纳（候选者作 `revert` 后 IH 通用——注意这里归纳时 `x` 在 `intros bl x y` 里才引入，天然通用）：递归继续考察同一个候选者（真分支）时 IH 直接给 `y <= x`；候选者换成更小的 `h`（假分支）时 IH 给 `y <= h`，再拼上 `Nat.leb_gt` 兑出的 `h < x`，`lia` 串线。

「一个数压制一整张表」需要新记号：`le_all x xs` 定义为 `Forall (fun y => x <= y) xs`——第 33 章 butterfly 用 `Permutation` 对付「表的重排」，`Forall` 是标准库对「逐元素谓词」的官方包装。`Infix "<=*"` 给它一个二元运算符的模样（`x <=* xs` 读作「x 压制 xs」）。`le_all__le_one` 是它的「拆箱」引理：`Forall_forall` 把归纳式 `Forall` 兑换成全称式 `forall n, In n lst -> ...`（又一次「两种规格、自由兑换」），配合 `In n lst` 立刻拿到点对点的 `y <= n`。

```coq
Lemma select_smallest : forall al bl x y,
    select x al = (y, bl) ->
    y <=* bl.
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst.
    constructor.
  - simpl in H. destruct (x <=? h) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      constructor.
      * assert (Hy' := select_fst_leq t r' x y Et). lia.
      * apply (IH r' x y Et).
    + apply Nat.leb_gt in E.
      destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      constructor.
      * assert (Hy' := select_fst_leq t r' h y Et). lia.
      * apply (IH r' h y Et).
Qed.

Lemma select_in : forall al bl x y,
    select x al = (y, bl) ->
    In y (x :: al).
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst.
    left. reflexivity.
  - simpl in H. destruct (x <=? h) eqn:E.
    + destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      destruct (IH r' x y Et) as [Hex | Hin].
      * left. exact Hex.
      * right. right. exact Hin.
    + destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      destruct (IH r' h y Et) as [Hex | Hin].
      * right. left. exact Hex.
      * right. right. exact Hin.
Qed.
```

`select_smallest`：输出头压制**输出尾**的每个元素——「最小元」的正式含义。对 `al` 归纳，递归步 `constructor` 把 `y <=* h :: r'` 拆成两条子目标：`y <= h` 与 `y <=* r'`。前者是真功夫：真分支里 IH 只给 `y <= x`（尾部的头 `y` 压制不了递归输出头——它就是 `y` 自己！），需要 `select_fst_leq` 补上 `y <= x` 加上 `E : x <= h`，`lia` 连乘；假分支对偶（`y <= h` 由 `select_fst_leq` 的 `h` 版本给出，`h < x` 由 `E` 兑出）。后者交给 IH。**一条引理链就此成形：`select_fst_leq` 挂在 `select_smallest` 下面**。

`select_in`：输出的最小元确实是**输入里的**元素（不是凭空捏造，比如取了两个数的 min 之外的东西）。对 `al` 归纳，每步把 IH 的析取 `x = y \/ In y t` 按「候选者守门顺序」搬进大列表的对应位置——真分支候选者一直是 `x`（`Hex : x = y` 落第一格），假分支换头后 `Hex : h = y` 落第二格。四条 `left/right` 摆位就是 `In` 定义的三层析取。

总装时刻：

```coq
Lemma cons_of_small_maintains_sort : forall bl y n,
    n = length bl ->
    y <=* bl ->
    sorted (selsort bl n) ->
    sorted (y :: selsort bl n).
Proof.
  intros bl y n Hn Hle Hs.
  assert (Hp : Permutation bl (selsort bl n)).
  { apply selsort_perm. symmetry. exact Hn. }
  destruct (selsort bl n) as [ | h t] eqn:E.
  - apply sorted_1.
  - apply sorted_cons.
    + assert (Hin : In h bl).
      { apply Permutation_sym in Hp.
        assert (Hin' : In h (h :: t)).
        { left. reflexivity. }
        exact (Permutation_in h Hp Hin'). }
      apply (le_all__le_one bl y h Hle Hin).
    + exact Hs.
Qed.

Lemma selsort_sorted : forall n al,
    length al = n -> sorted (selsort al n).
Proof.
  induction n as [ | n IHn]; intros al Hl.
  - destruct al as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply sorted_nil.
  - destruct al as [ | x r].
    + simpl. apply sorted_nil.
    + simpl in Hl. simpl.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply cons_of_small_maintains_sort.
      * assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
      * exact (select_smallest r r' x y E).
      * apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Lemma selection_sort_sorted : forall al,
    sorted (selection_sort al).
Proof.
  intros al. unfold selection_sort.
  apply selsort_sorted. reflexivity.
Qed.

Theorem selection_sort_is_correct :
  is_a_sorting_algorithm selection_sort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply selection_sort_perm.
  - apply selection_sort_sorted.
Qed.

Print Assumptions selection_sort_is_correct.
```

`cons_of_small_maintains_sort` 是把整条引理链拧在一起的关键引理：**压制全表的数，接到排好的表前面仍然有序**。思路：`y <=* bl` 说 `y` 压制**输入**，但目标是压制**输出**——中间隔着 `selsort`，靠 `Permutation` 翻译（`Hp` 由 `selsort_perm` 提供，注意前提方向是 `length bl = n` 而 `Hn : n = length bl`，`symmetry` 转一下）。输出非空时设头为 `h`：`In h bl`（`Permutation_in` 沿对称化后的 `Hp` 把 `In h (h::t)` 搬回输入侧——`exact (Permutation_in h Hp Hin')` 全参数应用，因为 `apply` 半参会让源列表无从推断），于是 `y <= h` 由 `le_all__le_one` 现场兑出，`sorted_cons` 的第二条前提直接就是 `Hs`。

`selsort_sorted` 与 `selsort_perm` 同骨架（对燃料归纳、`length al = n` 锁边），递归步把三个部件各就各位：燃料账目（`select_rest_length` + `lia`）、`y <=* r'`（`select_smallest` 全参数应用 `exact (select_smallest r r' x y E)`——它的结论 `y <=* bl` 里**不含** `al/x`，半参 `apply` 实测报 `Unable to find an instance for the variables al, x`）、尾部有序（IHn）。`selection_sort_sorted` 定额供油，`selection_sort_is_correct` 合取收官，`Print Assumptions` 实测 `Closed under the global context`。

值得回看一眼这条链的**形状**：`select_perm → selsort_perm`（重排线），`select_fst_leq → select_smallest + le_all__le_one → cons_of_small_maintains_sort → selsort_sorted`（有序线），两条线在总装定理汇合。`select_in` 独立在旁（它保证最小元来自输入，是完备性的一部分，本条的证明路线经由 Permutation 绕开了它）。**先把「关于一步的真相」全部证完，再证「循环不变量」**——这就是验证命令式循环的老套路（第 42 章 Hoare 逻辑的前奏）在函数式世界的样子。

### 35.3 Function 与 measure：摆脱燃料

燃料能过终止检查，但污染了类型（`selsort` 多扛一个 `n`）、污染了证明（处处 `length l = n` 对账）。Coq 标准库的 `Function` 命令支持**良基递归**的另一种写法——`{measure 长度}`：

```coq
(* ---------- 35.3 Function 与 measure：摆脱燃料 ---------- *)

Function selsort' (l : list nat) {measure length l} : list nat :=
  match l with
  | [] => []
  | x :: r => let (y, r') := select x r
            in y :: selsort' r'
  end.
Proof.
  intros l x r HL y r' Hsel.
  apply select_rest_length in Hsel. inversion Hsel; subst. simpl. lia.
Defined.
```

这就是 35.1 里被拒稿的 `selsort_bad` 原文——只多了 `{measure length l}` 标注。`Function` 编译时生成一个**终止义务**（obligation），实测形状：

```
forall (l : list nat) (x : nat) (r : list nat),
l = x :: r ->
forall (y : nat) (r' : list nat),
select x r = (y, r') -> length r' < length (x :: r)
```

翻译：对每个递归调用点，证明「measure 在调用处更小」。`Proof.` 之后直接进入这个目标的证明：`intros` 六个变量（`HL : l = x :: r` 记录调用点所在的 match 分支，`Hsel : select x r = (y, r')` 是 let 绑定带来的等式），然后——正是 35.2 备好的零件——`select_rest_length` 把 `Hsel` 兑成 `length r = length r'`，`inversion Hsel; subst` 清场，`simpl` 展开右侧 `length (x :: r)`，`lia` 收掉 `length r < S (length r)`。**`Defined` 收尾，不是 `Qed`**：终止证明要参与函数的计算（展开递归），不透明（Qed）的证明会让 `selsort'` 在 `reflexivity` 下卡死。

```coq
Example selsort'_example :
  selsort' [3;1;4;1;5;9;2;6;5] = [1;1;2;3;4;5;5;6;9].
Proof. reflexivity. Qed.

Check selsort'_equation.
```

`reflexivity` 直接算通——燃料版要 `unfold` + 定额，measure 版连这些都没有。但便利有代价：`Function` 生成的底层项很复杂，直接 `unfold selsort'` 或 `simpl` 会陷进生成的辅助函数（`selsort'_terminate` 等）出不来。官方出口是它顺手生成的**方程引理**，实测类型：

```
selsort'_equation
     : forall l : list nat,
       selsort' l =
       match l with
       | [] => []
       | x :: r => let (y, r') := select x r in y :: selsort' r'
       end
```

想要「selsort' 一步展开」，一律 `rewrite selsort'_equation`。其余证明呢？VFA 的提示是「相对燃料版只有几处一行级改动」——眼见为实：

```coq
Lemma selsort'_perm : forall n l,
    length l = n -> Permutation l (selsort' l).
Proof.
  induction n as [ | n IHn]; intros l Hl.
  - destruct l as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply perm_nil.
  - destruct l as [ | x r].
    + simpl. apply perm_nil.
    + simpl in Hl. rewrite selsort'_equation.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply perm_trans with (y :: r').
      * apply (select_perm x r y r' E).
      * apply perm_skip. apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.
```

与 `selsort_perm` 逐行对照：只有一处不同——`simpl` 换成 `rewrite selsort'_equation`（`simpl` 展不动 `Function` 生成的项）。归纳仍对 `n` 做：`length l = n` 从「燃料账」退化成纯粹的**归纳度量**，`selsort'` 本身已无燃料参数。账还是那本账，只是不用再管「烧没烧完」。

```coq
Lemma cons_of_small_maintains_sort' : forall bl y,
    y <=* bl ->
    sorted (selsort' bl) ->
    sorted (y :: selsort' bl).
Proof.
  intros bl y Hle Hs.
  assert (Hp : Permutation bl (selsort' bl)).
  { apply (selsort'_perm (length bl)). reflexivity. }
  destruct (selsort' bl) as [ | h t] eqn:E.
  - apply sorted_1.
  - apply sorted_cons.
    + assert (Hin : In h bl).
      { apply Permutation_sym in Hp.
        assert (Hin' : In h (h :: t)).
        { left. reflexivity. }
        exact (Permutation_in h Hp Hin'). }
      apply (le_all__le_one bl y h Hle Hin).
    + exact Hs.
Qed.

Lemma selsort'_sorted : forall n al,
    length al = n -> sorted (selsort' al).
Proof.
  induction n as [ | n IHn]; intros al Hl.
  - destruct al as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply sorted_nil.
  - destruct al as [ | x r].
    + simpl. apply sorted_nil.
    + simpl in Hl. rewrite selsort'_equation.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply cons_of_small_maintains_sort'.
      * exact (select_smallest r r' x y E).
      * apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Theorem selsort'_is_correct :
  is_a_sorting_algorithm selsort'.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply (selsort'_perm (length al)). reflexivity.
  - apply (selsort'_sorted (length al)). reflexivity.
Qed.

Print Assumptions selsort'_is_correct.

End Ex35Selection.
```

`cons_of_small_maintains_sort'` 少了 `n = length bl` 前提（无燃料可对账），`selsort'_sorted` 的三处改动同款同型，`selsort'_is_correct` 两行合取。`Print Assumptions` 再次 `Closed under the global context`。

对照总结：**燃料**是自己动手的土办法——定义可读、证明里全程背账；**measure** 是标准库代办的良基递归——定义最贴近直觉，代价是计算/展开要走 `selsort'_equation` 这扇官方门、终止义务必须 `Defined`。第 30 章讲过燃料与良基的理论（`well_founded`、`lt_wf`），本章是它们在真实算法上的第一次实战；后面第 36 章归并排序还会遇到第三种终止难题（双递归各取一半），到时候三件兵器就凑齐两件半了。

### 35.4 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`perm_skip` 要求两侧同头，先造同头中间站**（35.2）：目标 `Permutation (x::h::t) (y::h::r')` 直接 `apply perm_skip` 实测报 `Unable to unify "y" with "x"`。解法：swap → skip(IH) → swap 三段式，或先 `perm_trans with (x :: y :: r')` 造同头站。
2. **`injection ... as` + `subst` 会消灭新引入的分量名**（35.2）：`destruct ... as [y' r']` 后 `injection H as Hy Hr. subst.` 把 `y'` 替换成既有的 `y`，之后写 `y'` 实测报 `The variable y' was not found in the current environment`。写证明脚本时以 subst **之后**的名字为准。
3. **引理前提的等式方向要对齐**（35.2）：`cons_of_small_maintains_sort` 的前提是 `n = length bl`，喂给要 `length bl = n` 的 `selsort_perm` 实测报 `The term "Hn" has type "n = length bl" while it is expected to have type "length bl = n"`。`symmetry. exact Hn.` 或直接 `lia`。
4. **`apply (Permutation_in h)` 半参推断失败**（35.2）：源列表只出现在前提里，结论 `In h bl` 推不出来，实测报 `Cannot infer the implicit parameter l`。用 `exact (Permutation_in h Hp Hin')` 全参数应用。
5. **`destruct ... eqn:E` 会连带改写所有假设里的该项**（35.2）：destruct `selsort bl n` 后 `Hs`/`Hp` 已变成 `sorted (h::t)`/`Permutation (h::t) bl`，再 `rewrite E in Hs` 实测报 `Found no subterm matching "selsort bl n" in Hs`。写脚本前先看 destruct 后的上下文长什么样。
6. **`In h (h :: t)` 的证明是 `left. reflexivity.`**（35.2）：写成 `apply in_cons. apply in_eq` 会去证第二层析取 `In h t`（实测卡 unify）。`In a (b::l)` 的定义是 `b = a \/ In a l`——元素正好是头时走左支。
7. **`select_smallest` 半参 `apply` 推不出 `al/x`**（35.2）：结论 `y <=* bl` 不含输入侧变量，实测报 `Unable to find an instance for the variables al, x`；且参数顺序是 `al bl x y`（先两个表后两个数），全参 `exact (select_smallest r r' x y E)`，写错顺序报 `The term "x" ... expected "list nat"`。
8. **VFA 的 `inv` 战术不是内置**（35.3）：原书脚本 `inv Hsel` 在本环境实测报 `The reference inv was not found`——那是 VFA 自己的 `Ltac inv H := inversion H; subst; clear H`。平替写法 `inversion Hsel; subst`。
9. **`Function` 的终止证明必须 `Defined`**（35.3）：换成 `Qed` 则 `selsort'_example` 的 `reflexivity` 卡死——不透明证明挡住了计算展开（与第 38 章判定机同一原理：想算就必须透明）。
10. **`Require` 写在 `Module` 里会告警**（35.3）：`Use of "Require" inside a module is fragile`。`Recdef` 这类支撑库的导入一律放文件头。

---
上一章：[34 · 插入排序与规格模式](34-sort.md) ｜ 下一章：[36 · 归并排序：终止性递归](36-merge.md) ｜ 返回：[README](../README.md)
