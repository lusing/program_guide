# 37 · 多重集：另一种规格风格

对应示例：`../examples/37_multiset.v`（`Module Ex37Multiset`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

排序规格说「输出是输入的**重排**」——第 33–36 章都用 `Permutation` 表达它。本章换一种说法：**多重集**（multiset，又称 bag）。集合不管顺序、不许重复；多重集不管顺序、**允许重复**——`{1,1,2}` 与 `{2,1,1}` 是同一个多重集，正如 `[1;1;2]` 与 `[2;1;1]` 互为重排。「不增不减元素」于是可以换说成「排序前后**内容相同**（contents 相等）」。

两条主线：用多重集把插入排序**重新验证一遍**（37.2–37.3，与第 34 章的 Permutation 版并排对比手感）；再证两种规格**数学上等价**——`contents al = contents bl ⟺ Permutation al bl`（37.4，逆向出人意料地难，是全卷著名的证明攻坚）。规格没有唯一正解，但等价性一旦建立，两套证法就可以按顺手程度自由挑选——这是第 34 章「规格风格决定证明难度」主题的续篇。

### 37.1 多重集：把「元素集合」写成函数

文件头与多重集的表示：

```coq
(* 37 多重集 —— contents 规格风格与 Permutation 的等价 *)

From Stdlib Require Import Arith Bool Lia List Permutation
  FunctionalExtensionality.
Import ListNotations.

Module Ex37Multiset.

(* ---------- 37.1 多重集：把「元素集合」写成函数 ---------- *)

Definition value := nat.

Definition multiset := value -> nat.

Definition empty : multiset :=
  fun x => 0.

Definition singleton (v : value) : multiset :=
  fun x => if x =? v then 1 else 0.

Definition union (a b : multiset) : multiset :=
  fun x => a x + b x.
```

表示法直接得惊人：**多重集就是函数** `value -> nat`——输入一个值，输出它的**重数**（multiplicity，出现次数）。`empty` 处处为零；`singleton v` 在 `v` 处为一、别处为零（`x =? v` 的布尔判断）；`union` 是**逐点加法**。这个表示对性能毫无兴趣（查询重数要扫全表？不，是函数调用即答案，但构造 union 是闭包叠加）——但多重集在这里只当**规格**用、不当数据结构用，简单性就是一切。

`value` 是 `nat` 的别名，纯粹为了阅读时分清「这是值还是重数」。接下来三条代数定律是后续所有证明的口粮：

```coq
Lemma union_assoc : forall a b c : multiset,
   union a (union b c) = union (union a b) c.
Proof.
  intros.
  extensionality x.
  unfold union. lia.
Qed.

Lemma union_comm : forall a b : multiset,
   union a b = union b a.
Proof.
  intros.
  extensionality x.
  unfold union. lia.
Qed.

Lemma union_swap : forall a b c : multiset,
    union a (union b c) = union b (union a c).
Proof.
  intros.
  rewrite union_assoc.
  rewrite (union_comm a b).
  rewrite <- union_assoc.
  reflexivity.
Qed.
```

第一课立刻到来：**两个多重集相等，是两个函数相等**。证函数相等的标准姿势是 `extensionality x`（来自 `FunctionalExtensionality` 库）：把目标 `f = g` 降为 `forall x, f x = g x`，然后逐点算。`union_assoc/union_comm` 逐点展开后就是加法的结合律/交换律，`lia` 一发；`union_swap` 不必逐点——用前两条定律**代数地**改写三步到位（assoc 右结合、交换 `a b`、再 assoc 左结合）。注意 `extensionality` 依赖的**函数外延公理**——本章末尾 `Print Assumptions` 会把这笔账亮出来，这是 VFA 篇第一次真正动用公理。

### 37.2 contents 与排序的新规格

```coq
(* ---------- 37.2 contents 与排序的新规格 ---------- *)

Fixpoint contents (al : list value) : multiset :=
  match al with
  | [] => empty
  | a :: bl => union (singleton a) (contents bl)
  end.

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

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Example sort_pi_same_contents :
  contents (sort [3;1;4;1;5;9;2;6;5;3;5]) = contents [3;1;4;1;5;9;2;6;5;3;5].
Proof.
  extensionality x.
  repeat (destruct x; try reflexivity).
Qed.

Definition is_a_sorting_algorithm' (f : list nat -> list nat) := forall al,
    contents al = contents (f al) /\ sorted (f al).
```

`contents` 把列表「忘记顺序」压成多重集：逐个元素 `singleton` 进 `union`。`insert/sort/sorted` 从第 34 章原样搬来（本章自包含，不跨文件依赖）。`sort_pi_same_contents` 是一个会让人愣一下的证明：证 π 的排序列表与原表 contents 相同，脚本只有 `extensionality x. repeat (destruct x; try reflexivity).`——逐点比较两个多重集在 `x` 处的重数，而 `x` 是具体 nat 时两边都**算得出具体数字**：`destruct x` 不断把 `S x'` 剥开（0, 1, 2, …），每层两边若算出相等数字 `reflexivity` 就地关闭，如此重复直到穷尽所有数字。这个证明能成立，正因为两边都是**有限列表的 contents**——在有限个 `x` 之外重数恒为 0+0。一个 `Example` 演示了「函数相等也可以纯计算地证」。

新规格 `is_a_sorting_algorithm'` 与第 34 章的 `is_a_sorting_algorithm` 只差一个词：`Permutation al (f al)` 换成 `contents al = contents (f al)`。

### 37.3 用多重集验证插入排序

有序那一半照搬第 34 章（`insert_sorted` 的证明逐字相同，此处不再重复讲解——四条构造子、两次 `destruct (Nat.leb ...)` 的结构见第 34 章 34.3 节）：

```coq
(* ---------- 37.3 用多重集验证插入排序 ---------- *)

Lemma insert_sorted : forall a l, sorted l -> sorted (insert a l).
Proof.
  intros a l S. induction S as [ | x | x y l Hxy S0 IHS0]; simpl.
  - apply sorted_1.
  - destruct (Nat.leb a x) eqn:E.
    + apply Nat.leb_le in E. apply sorted_cons; [exact E | apply sorted_1].
    + apply Nat.leb_gt in E. apply sorted_cons; [lia | apply sorted_1].
  - destruct (Nat.leb a x) eqn:Ex.
    + apply Nat.leb_le in Ex.
      apply sorted_cons; [exact Ex | apply sorted_cons; [exact Hxy | exact S0]].
    + apply Nat.leb_gt in Ex.
      destruct (Nat.leb a y) eqn:Ey.
      * apply Nat.leb_le in Ey.
        apply sorted_cons; [lia | apply sorted_cons; [exact Ey | exact S0]].
      * simpl in IHS0. rewrite Ey in IHS0.
        apply sorted_cons; [exact Hxy | exact IHS0].
Qed.

Theorem sort_sorted : forall l, sorted (sort l).
Proof.
  induction l as [ | x t IH].
  - apply sorted_nil.
  - simpl. apply insert_sorted. exact IH.
Qed.
```

新的是 contents 那一半，对读第 34 章的 `insert_perm/sort_perm` 时你会发现**短了一截**：

```coq
Lemma insert_contents : forall x l,
     contents (insert x l) = contents (x :: l).
Proof.
  intros x l. induction l as [ | a t IH]; simpl.
  - reflexivity.
  - destruct (x <=? a) eqn:E.
    + reflexivity.
    + simpl. rewrite IH. apply union_swap.
Qed.

Theorem sort_contents : forall l,
    contents l = contents (sort l).
Proof.
  induction l as [ | x t IH]; simpl.
  - reflexivity.
  - rewrite insert_contents. rewrite IH. reflexivity.
Qed.

Theorem insertion_sort_correct' : is_a_sorting_algorithm' sort.
Proof.
  unfold is_a_sorting_algorithm'. intros al.
  split.
  - apply sort_contents.
  - apply sort_sorted.
Qed.

Print Assumptions insertion_sort_correct'.
```

`insert_contents`（插入不改变 contents）：对 `l` 归纳。空表两边是同一个表达式，`reflexivity`。一般情形按 `x <=? a` 分流：插在前头两边又是同一个表达式；插在后头则目标为 `union (singleton a) (contents (insert x t)) = union (singleton x) (union (singleton a) (contents t))`——`rewrite IH` 换掉内层，剩下的正是 37.1 的 `union_swap`。对比第 34 章 `insert_perm` 需要 swap/skip/swap 三段拼装，这里**一条代数定律一步到位**。`sort_contents` 同样是两行：每步 `insert_contents` + IH。总装 `insertion_sort_correct'` 合取两半。

`Print Assumptions` 的实测输出是本章第一处亮账：

```
Axioms:
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  (forall x : A, f x = g x) -> f = g
```

**不再 Closed**。`contents` 规格把「相等」放在函数空间里，每一次 `extensionality` 都在动用函数外延公理（第 15 章逻辑篇介绍过它：从「逐点相等」推「函数相等」，这是 Coq 基础理论推不出来的命题，只能作为公理引入）。Permutation 版的正确性（第 34 章）是**无公理**的构造性证明；multiset 版简洁的代价在这里交付。两条路线的可信度都够用（函数外延是几乎所有人都愿意接受的公理），但「用了什么假设」必须心里有数——这正是 `Print Assumptions` 作为每章固定仪式的意义。

### 37.4 等价性：contents 相同当且仅当互为重排

既然两套规格并存，自然要问它们是否一回事。目标：`contents al = contents bl <-> Permutation al bl`。**正向**（重排 ⇒ 内容相同）常规难度：

```coq
(* ---------- 37.4 等价性：contents 相同当且仅当互为重排 ---------- *)

Lemma perm_contents : forall al bl : list nat,
    Permutation al bl -> contents al = contents bl.
Proof.
  intros al bl H.
  induction H as [ | x l l' Hp IH | x y l | l l' l'' H1 IH1 H2 IH2].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
  - simpl. extensionality v. unfold singleton, union.
    destruct (v =? x); destruct (v =? y); lia.
  - transitivity (contents l').
    + exact IH1.
    + exact IH2.
Qed.
```

对**重排证据**归纳（第 33 章的姿势），四条构造子四个分支：nil 与 skip 直接；swap 分支逐点比较 `(if v =? x then 1 else 0) + (if v =? y then 1 else 0) + ...` 对称的两项，两个布尔各撕一次、四种组合交给 `lia`；trans 用等式传递。`as` 模式给四条构造子的参数起了名（`Hp IH` 是 skip 的重排前提与归纳假设，`H1 IH1 H2 IH2` 是 trans 的两半）。

**逆向**（内容相同 ⇒ 互为重排）是原书标注「surprisingly difficult」的硬骨头，思路（Zhong Sheng Hu）是**从 contents 里把列表重建出来**。四条引理搭梯子：

```coq
Lemma contents_nil_inv : forall l, (forall x, 0 = contents l x) -> l = nil.
Proof.
  intros l H. destruct l as [ | a t].
  - reflexivity.
  - exfalso. specialize (H a). simpl in H.
    unfold singleton, union in H.
    rewrite Nat.eqb_refl in H. lia.
Qed.

Lemma contents_cons_inv : forall l x n,
    S n = contents l x ->
    exists l1 l2,
      l = l1 ++ x :: l2
      /\ contents (l1 ++ l2) x = n.
Proof.
  induction l as [ | a t IH]; intros x n H.
  - simpl in H. unfold empty in H. discriminate.
  - simpl in H. unfold singleton, union in H.
    destruct (x =? a) eqn:E.
    + apply Nat.eqb_eq in E. subst a.
      exists [], t. split.
      * reflexivity.
      * simpl. lia.
    + assert (H' : S n = contents t x) by lia.
      destruct (IH x n H') as [l1 [l2 [Heq Hc]]].
      exists (a :: l1), l2. split.
      * simpl. rewrite Heq. reflexivity.
      * simpl. unfold singleton, union.
        rewrite E. rewrite Hc. reflexivity.
Qed.
```

`contents_nil_inv`：处处重数为零的表必是空表——只要反证：非空则头元素在 `a` 处重数至少为 1（`Nat.eqb_refl` 把 `a =? a` 化成 true），与零矛盾。注意 `simpl in H` 之后还要 `unfold singleton, union in H`——simpl 停在 `union (singleton a) (contents t) a` 就不动了（实测坑，见 37.6），`a =? a` 藏在两层定义之下，不展开就 rewrite 不进去。

`contents_cons_inv`：若 `x` 的重数是 `S n`，则表一定能**拆**成 `l1 ++ x :: l2`，且拆掉这个 `x` 后重数恰为 `n`。对 `l` 归纳：头就是 `x`（`x =? a` 真，`Nat.eqb_eq` 兑成等式后 `subst`）则 `l1 = []`、`l2 = t`，重数从 `S n = 1 + contents t x` 交给 `lia`；否则重数全在尾部，IH 拆出 `t = l1 ++ x :: l2`，头再顶回 `l1` 上（`(a :: l1) ++ x :: l2`），重数用 `rewrite E`（`x =? a = false`，头不贡献）接上 IH 的账。

```coq
Lemma contents_insert_other : forall l1 l2 x y,
    y <> x -> contents (l1 ++ x :: l2) y = contents (l1 ++ l2) y.
Proof.
  induction l1 as [ | a t IH]; intros l2 x y Hne.
  - simpl. unfold singleton, union.
    destruct (y =? x) eqn:E.
    + apply Nat.eqb_eq in E. contradiction.
    + reflexivity.
  - simpl. unfold union. rewrite (IH l2 x y Hne). reflexivity.
Qed.

Lemma perm_cons_app : forall (l1 l2 : list nat) (a : nat),
  Permutation (a :: (l1 ++ l2)) (l1 ++ a :: l2).
Proof.
  induction l1 as [ | b l1' IH]; intros l2 a.
  - apply Permutation_refl.
  - simpl. apply perm_trans with (b :: a :: (l1' ++ l2)).
    + apply perm_swap.
    + apply perm_skip. apply IH.
Qed.
```

两条小梯子：`contents_insert_other` 说**在拼接缝上插入一个 `y ≠ x` 的无关元素不改变 `x` 的重数**（对 `l1` 归纳，头部的 `y =? a` 两种情况各一行）；`perm_cons_app` 是置换版的老朋友——把头元素搬到拼接中缝（36 章 `perm_mid` 的对偶），skip/swap 两步。它们分别是主证明里「管别人的账」和「摆列表形状」的工具。

主角登场：

```coq
Lemma contents_perm : forall al bl,
    contents al = contents bl -> Permutation al bl.
Proof.
  intros al bl H0.
  assert (H : forall x, contents al x = contents bl x).
  { rewrite H0. auto. }
  clear H0.
  generalize dependent bl.
  induction al as [ | a t IH]; intros bl H.
  - assert (Hbl : bl = []).
    { apply contents_nil_inv. intros x.
      specialize (H x). simpl in H. exact H. }
    rewrite Hbl. apply perm_nil.
  - assert (Ha : S (contents t a) = contents bl a).
    { specialize (H a). simpl in H.
      unfold singleton, union in H.
      rewrite Nat.eqb_refl in H. exact H. }
    destruct (contents_cons_inv bl a (contents t a) Ha)
      as [l1 [l2 [Hbl Hc]]].
    rewrite Hbl.
    apply perm_trans with (a :: (l1 ++ l2)).
    + apply perm_skip.
      apply (IH (l1 ++ l2)).
      intros y. destruct (Nat.eq_dec y a) as [Heq | Hne].
      * rewrite Heq. symmetry. exact Hc.
      * specialize (H y). simpl in H.
        unfold singleton, union in H.
        destruct (y =? a) eqn:Ey.
        -- apply Nat.eqb_eq in Ey. contradiction.
        -- simpl in H.
           rewrite Hbl in H.
           rewrite (contents_insert_other l1 l2 a y Hne) in H.
           lia.
    + apply perm_cons_app.
Qed.
```

开场三步是「把函数等式拆成逐点等式」的标准预处理：`assert (H : forall x, contents al x = contents bl x)` 把全局等式降为逐点（内部 `rewrite H0` 一次用掉原等式），`clear H0` 清掉已耗尽的全局版，`generalize dependent bl` 把 `bl` 撤回量词——此后对 `al` 归纳时 IH 对**任意 bl** 成立（bl 在递归中会换成拆出来的 `l1 ++ l2`，不 generalize 就锁死）。

空表分支：`contents [] x` 处处为零，`contents_nil_inv` 判定 `bl` 也必空，`perm_nil` 收。一般分支是整个证明的心脏，读作一句话：**「`bl` 里必有一个 `a`，把它挖出来放到头上，剩下的部分用归纳假设」**。`Ha` 先算出 `bl` 在 `a` 处的重数是 `S (contents t a)`（`a =? a` 处白送的 1 加上尾部的账）；`contents_cons_inv` 据此把 `bl` 拆成 `l1 ++ a :: l2` 并附带「拆后重数」`Hc`。然后 `rewrite Hbl` 把目标变成 `Permutation (a::t) (l1 ++ a :: l2)`，中转站 `a :: (l1 ++ l2)`：前半段 `perm_skip` 需要 `Permutation t (l1++l2)`，交给 IH——但 IH 要的是**逐点**相等，于是现场构造：对任意 `y`，`y = a` 时就是 `Hc`（symmetry 转向），`y ≠ a` 时左边 `contents (a::t) y` 的头不贡献（`y =? a` 假，contradiction 关掉真分支）、右边 `bl = l1 ++ a::l2` 里那个 `a` 也不贡献（`contents_insert_other`），两边都退化为 `contents t y = contents (l1++l2) y`，`lia` 结账。后半段 `perm_cons_app` 把 `a` 搬进中缝。整个证明没有一行「聪明」的魔法，全是「挖元素、对剩下的归纳」的笨功夫——但每一步的工具都得先造好。

```coq
Theorem same_contents_iff_perm : forall al bl,
    contents al = contents bl <-> Permutation al bl.
Proof.
  intros al bl. split.
  - apply contents_perm.
  - apply perm_contents.
Qed.

Theorem sort_specifications_equivalent : forall sort,
    is_a_sorting_algorithm' sort -> forall al,
      Permutation al (sort al) /\ sorted (sort al).
Proof.
  intros sort H al. destruct (H al) as [Hcont Hsorted].
  split.
  - apply same_contents_iff_perm. apply Hcont.
  - exact Hsorted.
Qed.

Print Assumptions same_contents_iff_perm.

End Ex37Multiset.
```

`same_contents_iff_perm` 把两个方向拼成 iff；`sort_specifications_equivalent` 立刻兑现价值：**用 contents 规格验证过的排序算法，自动获得 Permutation 规格的验收证书**（反向同样成立，证法对称）。`Print Assumptions` 再次亮出 `functional_extensionality_dep`——等价性本身也是站在公理上的（顺带一提：`contents_perm` 的**结论**是构造性的 Permutation 证据，真正动用公理的是正向 `perm_contents` 里那几处 `extensionality`）。

收个尾。本章的对比一目了然：**Permutation 是归纳定义的「证据」，多重集是函数定义的「计数」**——前者证明要拼构造子（swap/skip/trans 的搭积木），后者证明是代数改写（assoc/comm/swap 三定律）加逐点算术；前者无公理，后者背一条函数外延；前者逆向构造自然，后者连「相等」都要先拆成逐点。没有孰优孰劣——规格等价性 `same_contents_iff_perm` 保证两边的证书互相通用，验证算法时挑顺手的用即可。VFA 篇的排序主线到此收束（33 置换、34 插入、35 选择、36 归并、37 多重集）；下一章转向**判定**：第 38 章问「规格能不能跑」——给 `sorted`、`Permutation` 这些 Prop 世界的谓词配上 bool 世界的判定机。

### 37.5 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`simpl in H` 停在半路：`union (singleton a) (contents t) a` 不再往下化**（37.3/37.4）：`simpl` 展开了 `contents (a::t)` 就收工，`union`/`singleton` 原样躺着，此时 `rewrite Nat.eqb_refl in H` 实测报 `Found no subterm matching "?M =? ?M"`——`a =? a` 藏在两层定义之下。对策：`simpl in H` 后补 `unfold singleton, union in H`，再 rewrite。
2. **`union` 不先展开，子项对不上**（37.4）：目标 `union (singleton a) (contents (t ++ x :: l2)) y` 里 `contents (t ++ x :: l2)` **没有应用到 y**（y 应用在整个 union 上），拿 `contents (t ++ x::l2) y` 去 rewrite 实测报 `Found no subterm matching`。对策：先 `unfold union` 让 beta 归约把 y 送进加法两臂。
3. **`rewrite <- union_assoc` 方向搞反**（37.1）：`union_swap` 的证明里先 `rewrite <- union_assoc` 实测报 `Found no subterm matching "union (union ?a ?b) ?c"`——目标里根本没有这个形状。正向 `rewrite union_assoc` 才是把 `union a (union b c)` 换成 `union (union a b) c` 的那一步。
4. **`rewrite IH` 之前目标可能还没展开到能匹配**（37.3）：`contents (a :: insert x t)` 整个套在 contents 里时，`contents (insert x t)` 不是子项，实测报 `Found no subterm matching "contents (insert x t)"`。先 `simpl` 把外层 contents 展开成 union，内层才露出来。
5. **`rewrite <- insert_contents` 匹配不到已展开的形状**（37.3）：归纳步的 `simpl` 已把 LHS `contents (x::t)` 展开成 `union (singleton x) (contents t)`，`contents (?x :: ?l)` 模式不存在；改为正向 `rewrite insert_contents` 改写 RHS 的 `contents (insert x (sort t))`。
6. **函数等式的证明必然引公理**（37.3）：`Print Assumptions` 实测输出 `functional_extensionality_dep`——`extensionality` 战术每用一次都从 FunctionalExtensionality 库借一次公理。这不是 bug，但写进教程的每个「Axioms:」都要如实向读者交代。
7. **`union_swap` 逐点证法也可行，但代数证法更稳**（37.1）：逐点 `extensionality x; unfold union; lia` 对 swap 同样有效；用 assoc/comm 改写的好处是不引入公理——定律的证明链里公理越少，依赖它的定理越容易看清真账。

---
上一章：[36 · 归并排序：终止性递归](36-merge.md) ｜ 下一章：[38 · 可判定规格](38-decide.md) ｜ 返回：[README](../README.md)
