# 39 · 二叉搜索树的验证

对应示例：`../examples/39_searchtree.v`（`Module Ex39SearchTree`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

VFA 篇的排序线（33–37）证完了「排出来对不对」，本章回到第 28 章的老朋友**二叉搜索树**，问一套更工程的问题：一个真实的数据结构（不止排序，还有查询、插入、遍历）该怎么**全面**验证。第 28 章做过 BST 的谓词建模与剪枝查找；第 38 章给「有序」「无重复」配过 bool 判定机。本章把这些零件组装成完整的验证工程，两条规格方法论并行推进：

**代数规格**（39.3）——不谈树的内部形状，只写 `lookup` 与 `empty/insert` 之间的方程，与第 48 章 total_map 的 `t_update` 三定律逐条对应；**遍历规格**（39.4–39.5）——`elements` 把树摊平成关联表，要证三重性质：**完备**（树里有的都在表里）、**正确**（表里有的都在树里）、**有序且无重复**。骨架还是第 34 章的老三样（表示 + 不变量 + 定理链），但密度升一档：`BST` 不变量、`ForallT` 树谓词、`uncurry` 柯里化转换这些新工具都会在这章反复出场。39.6 再送一条工程上极常用的方法论：**先证慢的实现，再证快的与慢的等价**。

### 39.1 表示与操作：bound、lookup、insert

文件头与数据结构：

```coq
(* 39 二叉搜索树 —— BST 不变量、代数规格与 elements 的三重正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation Strings.String.
Import ListNotations.

Module Ex39SearchTree.

(* ---------- 39.1 表示与操作：bound、lookup、insert ---------- *)

Definition key := nat.

Inductive tree (V : Type) : Type :=
| E
| T (l : tree V) (k : key) (v : V) (r : tree V).

Arguments E {V}.
Arguments T {V}.

Definition ex_tree : tree string :=
  (T (T E 2 "two" E) 4 "four" (T E 5 "five" E))%string.

Definition empty_tree {V : Type} : tree V :=
  E.

Fixpoint bound {V : Type} (k : key) (t : tree V) : bool :=
  match t with
  | E => false
  | T l x v r => if k <? x then bound k l
                else if x <? k then bound k r
                     else true
  end.

Fixpoint lookup {V : Type} (d : V) (k : key) (t : tree V) : V :=
  match t with
  | E => d
  | T l x v r => if k <? x then lookup d k l
                else if x <? k then lookup d k r
                     else v
  end.

Fixpoint insert {V : Type} (k : key) (v : V) (t : tree V) : tree V :=
  match t with
  | E => T E k v E
  | T l x v' r => if k <? x then T (insert k v l) x v' r
                 else if x <? k then T l x v' (insert k v r)
                      else T l k v r
  end.
```

BST 是**多态**的：值类型 `V` 任意，键是 `nat`（起别名 `key` 只为可读）。树只有两个构造子——空 `E` 与节点 `T 左树 键 值 右树`；`Arguments E {V}`/`Arguments T {V}` 把类型参数设为隐式，此后 `E`、`T l k v r` 直接写。三个操作各司其职：`bound k t` 问「k 绑了吗」（bool，给程序用）；`lookup d k t` 查值、查不到给默认值 `d`（**全函数**——这正是第 34 章 `sorted'` 讨论过的「默认值换 totality」在数据结构层的再现）；`insert k v t` 是**持久化**的——不修改旧树，返回共享未动子树的新树（第 34 章 34.1 讨论过共享）。三者沿同一条比较路径下行：`k <? x` 往左、`x <? k` 往右（注意 stdlib 9.2 已删 `>?` 记法，比较一律反写操作数）。

```coq
Module Tests.
  Open Scope string_scope.

  Example bst_ex1 :
    insert 5 "five" (insert 2 "two" (insert 4 "four" empty_tree)) = ex_tree.
  Proof. reflexivity. Qed.

  Example bst_ex2 : lookup "" 5 ex_tree = "five".
  Proof. reflexivity. Qed.

  Example bst_ex3 : lookup "" 3 ex_tree = "".
  Proof. reflexivity. Qed.

  Example bst_ex4 : bound 3 ex_tree = false.
  Proof. reflexivity. Qed.
End Tests.
```

四个单元测试纯计算：三次 insert 恰好搭出 `ex_tree`、查到值/查默认值/查绑定性。单测只能抽查，通用的保证要靠下面两节的不变量与定理。

### 39.2 BST 不变量

第 28 章就知道：`tree` 类型本身**不保证**搜索性质——手工 `T` 出来的乱序树照样合法，而 `lookup` 在其上会给出错误答案。先把「错误答案」演示成定理：

```coq
(* ---------- 39.2 BST 不变量 ---------- *)

Module NotBst.
  Open Scope string_scope.

  Definition t : tree string :=
    T (T E 5 "five" E) 4 "four" (T E 2 "two" E).

  Example not_bst_lookup_wrong :
    lookup "" 2 t <> "two".
  Proof.
    simpl. unfold not. intros contra. discriminate.
  Qed.
End NotBst.
```

`t` 把 5 放在左、2 放在右——`lookup "" 2 t` 沿比较路径找 2 会**往左走**（2 < 4），左子树里只有 5，于是返回默认值空串；`not_bst_lookup_wrong` 用 `discriminate` 一步证死这个反例。形式化「不乱」需要两层定义：

```coq
Fixpoint ForallT {V : Type} (P : key -> V -> Prop) (t : tree V) : Prop :=
  match t with
  | E => True
  | T l k v r => P k v /\ ForallT P l /\ ForallT P r
  end.

Inductive BST {V : Type} : tree V -> Prop :=
| BST_E : BST E
| BST_T : forall l x v r,
    ForallT (fun y _ => y < x) l ->
    ForallT (fun y _ => y > x) r ->
    BST l ->
    BST r ->
    BST (T l x v r).

Example is_BST_ex :
  BST ex_tree.
Proof.
  unfold ex_tree.
  repeat (constructor; try lia).
Qed.

Example not_BST_ex :
  ~ BST NotBst.t.
Proof.
  unfold NotBst.t. intros contra.
  inversion contra. inversion H3. lia.
Qed.
```

`ForallT P t` 是 `Forall`（列表版，第 34 章用过）的树版：**每个节点** `(k,v)` 都满足 `P k v`（注意 `fun y _ => ...` 的第二参数占位——谓词只关心键）。`BST` 用它说人话：空树合法；`T l x v r` 合法当且仅当**左子树所有键 < x**、**右子树所有键 > x**、且两个子树递归合法。`is_BST_ex` 的证明是「构造子轰炸」：`repeat (constructor; try lia)` 反复拆 BST_T/ForallT 的合取，每片键序不等式交给 `lia`——四节点的例子瞬间铺开又收拢。`not_BST_ex` 反面：对证据 `inversion` 两次剥到 `5 < 4` 一类的不等式，`lia` 收尸。

不变量定义好了，第一定理是**操作保持不变量**：

```coq
Theorem empty_tree_BST : forall (V : Type),
    BST (@empty_tree V).
Proof.
  intros V. unfold empty_tree. apply BST_E.
Qed.

Lemma ForallT_insert : forall (V : Type) (P : key -> V -> Prop) (t : tree V),
    ForallT P t -> forall (k : key) (v : V),
      P k v -> ForallT P (insert k v t).
Proof.
  intros V P t. induction t as [ | l IHl x v' r IHr]; intros H k v Hk.
  - simpl. split; [exact Hk | split; exact I].
  - destruct H as [Hx [Hl Hr]]. simpl.
    destruct (k <? x) eqn:E1.
    + simpl. split.
      * exact Hx.
      * split; [apply (IHl Hl k v Hk) | exact Hr].
    + destruct (x <? k) eqn:E2.
      * simpl. split.
        -- exact Hx.
        -- split; [exact Hl | apply (IHr Hr k v Hk)].
      * simpl. split.
        -- exact Hk.
        -- split; [exact Hl | exact Hr].
Qed.
```

`empty_tree_BST` 一行。`ForallT_insert` 是个**可复用的万金油**：insert 保住**任意**逐节点谓词 `P`（不只 `<`）——这条通用性让下一个定理几乎白送。证明对 `t` 归纳，注意 `as` 模式 `[ | l IHl x v' r IHr]`——**IH 紧跟在递归参数之后**（这是 `tree_ind` 的生成规则，写成 `[| l x v' r IHl IHr]` 会整体错位，实测坑见 39.8）。递归步按 insert 的三分支走：插左则只有左子树的 ForallT 换成 IH 的实例、其余照抄；插右对称；键相等则新节点 `(k,v)` 直接用 `Hk : P k v`，两侧原样。

```coq
Theorem insert_BST : forall (V : Type) (k : key) (v : V) (t : tree V),
    BST t -> BST (insert k v t).
Proof.
  intros V k v t H.
  induction H as [ | l x v' r Hl Hr HBl IHl HBr IHr].
  - apply BST_T.
    + simpl. exact I.
    + simpl. exact I.
    + apply BST_E.
    + apply BST_E.
  - simpl.
    destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply BST_T.
      * exact (ForallT_insert V (fun y _ => y < x) l Hl k v E1).
      * exact Hr.
      * exact IHl.
      * exact HBr.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply BST_T.
        -- exact Hl.
        -- exact (ForallT_insert V (fun y _ => y > x) r Hr k v E2).
        -- exact HBl.
        -- exact IHr.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        apply BST_T.
        -- exact Hl.
        -- exact Hr.
        -- exact HBl.
        -- exact HBr.
Qed.
```

`insert_BST`：**对 BST 证据归纳**（不是对树！——`as` 模式 `[| l x v' r Hl Hr HBl IHl HBr IHr]`：四个字段、两条 ForallT 前提、两棵子树的 BST 及其 IH，IH 跟在各自 BST 后面）。空树分支直接造叶子；一般分支三分支——插左时左子树的「全部 < x」前提由 `ForallT_insert` 以 `P := (fun y _ => y < x)` 实例化一步拿到（新键 `k < x` 来自 `Nat.ltb_lt` 兑换的 `E1`），左子树的 BST 性用 IH；插右对称；键相等时 `k = x`（两个 `Nat.ltb_ge` 加 lia），新节点沿用原节点的两侧前提。**万金油引理 + 证据归纳 = 不变量保持几乎免证**。

### 39.3 代数规格：lookup 的三方程

```coq
(* ---------- 39.3 代数规格：lookup 的三方程 ---------- *)

Theorem lookup_empty : forall (V : Type) (d : V) (k : key),
    lookup d k empty_tree = d.
Proof.
  intros. reflexivity.
Qed.

Theorem lookup_insert_eq :
  forall (V : Type) (t : tree V) (d : V) (k : key) (v : V),
    lookup d k (insert k v t) = v.
Proof.
  induction t as [ | l IHl x v' r IHr]; intros d k v; simpl.
  - destruct (k <? k) eqn:E1.
    + apply Nat.ltb_lt in E1. lia.
    + reflexivity.
  - destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1. simpl.
      destruct (k <? x) eqn:E2.
      * exact (IHl d k v).
      * apply Nat.ltb_ge in E2. lia.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2. simpl.
        destruct (k <? x) eqn:E3.
        -- apply Nat.ltb_lt in E3. lia.
        -- destruct (x <? k) eqn:E4.
           ++ exact (IHr d k v).
           ++ apply Nat.ltb_ge in E4. lia.
      * simpl. destruct (k <? k) eqn:E3.
        -- apply Nat.ltb_lt in E3. lia.
        -- reflexivity.
Qed.
```

代数规格不描述树长什么样，只规定操作之间的方程——与第 48 章 total_map 的 `t_apply_empty`/`t_update_eq`/`t_update_neq` 三定律**逐条同构**：查空表得默认值（`lookup_empty`，计算一步）；查刚插入的键得新值（`lookup_insert_eq`）；查别的键不受插入影响（`lookup_insert_neq`，下一条）。`lookup_insert_eq` 的证明值得慢读，它是全章「布尔路径推理」的模板：`destruct (k <? x) eqn:E1` 选定 insert 的走向后，**目标里 lookup 自己的比较又冒出同一个布尔**（`simpl` 展开新节点的 lookup 时新出现的），必须再 destruct/兑换一次；矛盾分支全部交给「`Nat.ltb_lt`/`Nat.ltb_ge` 兑成命题 + lia」——比如 `k < x` 与 `~ k < x` 同台，`lia` 一步。原书把这套重复劳动封装成 `bdall` Ltac 自动扫 if；本章保持手动展开，因为**看清每一层布尔的来历**正是这章要练的功夫。

```coq
Theorem lookup_insert_neq :
  forall (V : Type) (t : tree V) (d : V) (k k' : key) (v : V),
   k <> k' -> lookup d k' (insert k v t) = lookup d k' t.
Proof.
  induction t as [ | l IHl x v' r IHr]; intros d k k' v Hne; simpl.
  - destruct (k' <? k) eqn:E1.
    + reflexivity.
    + destruct (k <? k') eqn:E2.
      * reflexivity.
      * exfalso. apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2. lia.
  - destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1. simpl.
      destruct (k' <? x) eqn:E2.
      * exact (IHl d k k' v Hne).
      * reflexivity.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2. simpl.
        destruct (k' <? x) eqn:E3.
        -- reflexivity.
        -- destruct (x <? k') eqn:E4.
           ++ exact (IHr d k k' v Hne).
           ++ reflexivity.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        simpl.
        destruct (k' <? k) eqn:E3.
        -- reflexivity.
        -- destruct (k <? k') eqn:E4.
           ++ reflexivity.
           ++ exfalso. apply Nat.ltb_ge in E3. apply Nat.ltb_ge in E4. lia.
Qed.

Theorem bound_default :
  forall (V : Type) (k : key) (d : V) (t : tree V),
    bound k t = false ->
    lookup d k t = d.
Proof.
  intros V k d t. induction t as [ | l IHl x v' r IHr]; intros H.
  - reflexivity.
  - simpl in H. simpl.
    destruct (k <? x) eqn:E1.
    + apply IHl. exact H.
    + destruct (x <? k) eqn:E2.
      * apply IHr. exact H.
      * discriminate H.
Qed.
```

`lookup_insert_neq` 同款骨架、多一层「查询键 `k'` 与树键 `x` 的比较」：只要 `k'` 与 `k` 走**同一条**比较路径，两边就逐字相同（`reflexivity`）；只有在 `k = x`（insert 换节点）且 `k' = k` 时新旧值才不同——恰好被 `Hne` 排除。有趣的是：**这两条定理完全没用 BST 不变量**——lookup 和 insert 沿同一路径下行，乱树上也「错得一致」。不变量的用武之地在 39.4 的 `elements`。`bound_default` 顺手证「没绑就返回默认值」：bound 与 lookup 的布尔分支同步，等值分支里 bound 恒为 true 与 `H` 直接 `discriminate`。

### 39.4 elements 的三重规格 I：完备与正确

```coq
(* ---------- 39.4 elements 的三重规格 I：完备与正确 ---------- *)

Fixpoint elements {V : Type} (t : tree V) : list (key * V) :=
  match t with
  | E => []
  | T l k v r => elements l ++ [(k, v)] ++ elements r
  end.

Example elements_ex :
    elements ex_tree = [(2, "two"); (4, "four"); (5, "five")]%string.
Proof. reflexivity. Qed.

Definition elements_complete_broken_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    lookup d k t = v ->
    In (k, v) (elements t).

Theorem elements_complete_broken : elements_complete_broken_spec.
Proof.
  unfold elements_complete_broken_spec. intros. induction t.
  - simpl.
    (* 卡住了：未绑定的键也会要求出现在 elements 里，表就得无限长。 *)
Abort.
```

`elements` 是**中序遍历**（左 ++ [根] ++ 右）——`elements_ex` 实测输出恰好按键升序，这不是巧合，39.5 会证。给「elements 包含树里的一切」写规格时有个著名的坑：第一版 `elements_complete_broken_spec` 直接说「`lookup d k t = v` 就该 `In (k,v)`」——但 `lookup` 对**未绑定**的键也返回默认值 `d`，照这个规格每个 nat 键都得出现在表里，表得无限长。卡住的现场就在 `Abort` 那行：空树上 `lookup d k E = d = v` 恒成立，而 `elements E = []` 什么都没有。解法是先问 `bound`：

```coq
Definition elements_complete_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    bound k t = true ->
    lookup d k t = v ->
    In (k, v) (elements t).

Theorem elements_complete : elements_complete_spec.
Proof.
  unfold elements_complete_spec.
  intros V k v d t. induction t as [ | l IHl x v' r IHr]; intros Hb Hl.
  - discriminate Hb.
  - simpl in Hb. simpl in Hl. simpl.
    destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply in_or_app. left. apply IHl; assumption.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply in_or_app. right. apply in_cons. apply IHr; assumption.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        simpl in Hl. subst v'.
        apply in_or_app. right. apply in_eq.
Qed.
```

`elements_complete`（**完备性**）：对树归纳，`bound`/`lookup` 的布尔路径与 elements 的结构同步三分支——键在左就 `in_or_app` 的左半边 + IH；在右就右半边 + `in_cons` + IH；键等于根（`k = x`，`subst` 后 `lookup` 的 `Hl` 退化成 `v' = v`，再 `subst`）就是中缝那个元素 `in_eq`。这条定理**不需要 BST**——它对乱树也成立（每个节点照样被收进表里）。

正确性（表里有的都在树里）才是 BST 的主场，需要先造两件 ForallT↔Forall 的桥：

```coq
Definition uncurry {X Y Z : Type} (f : X -> Y -> Z) '(a, b) :=
  f a b.

Lemma elements_preserves_forall :
  forall (V : Type) (P : key -> V -> Prop) (t : tree V),
    ForallT P t ->
    Forall (uncurry P) (elements t).
Proof.
  intros V P t H. induction t as [ | l IHl x v r IHr].
  - simpl. constructor.
  - destruct H as [Hx [Hl Hr]]. simpl.
    apply Forall_forall. intros kv Hin.
    apply in_app_or in Hin. destruct Hin as [Hi | Hi].
    + apply (proj1 (Forall_forall _ _) (IHl Hl)). exact Hi.
    + destruct Hi as [Heq | Hi].
      * destruct kv as [a b]. simpl in Heq.
        injection Heq as Ha Hb. subst a. subst b. simpl. exact Hx.
      * apply (proj1 (Forall_forall _ _) (IHr Hr)). exact Hi.
Qed.

Lemma elements_preserves_relation :
  forall (V : Type) (k k' : key) (v : V) (t : tree V)
    (R : key -> key -> Prop),
    ForallT (fun y _ => R y k') t
    -> In (k, v) (elements t)
    -> R k k'.
Proof.
  intros V k k' v t R Hall Hin.
  assert (H := elements_preserves_forall V (fun y _ => R y k') t Hall).
  rewrite Forall_forall in H.
  specialize (H (k, v) Hin). simpl in H. exact H.
Qed.
```

`uncurry` 解决一个纯类型学的不匹配：`ForallT` 的谓词吃**两个参数**（键、值），`Forall` 的谓词吃**一个二元组**——`uncurry P` 就是「拆开二元组再喂 P」。`elements_preserves_forall`（对树归纳，Forall 版逐元素展开）说**树上的逐节点性质会传给遍历表**；注意第 34 章的老朋友 `Forall_forall`（归纳式 ↔ 全称式）再次出场当兑换机，`in_app_or` 把 `In kv (A ++ B)` 拆成两侧，中缝元素则 `injection` 拆二元组等式后 `subst`。`elements_preserves_relation` 是它的一步推论：全树键都与 `k'` 满足 `R`，则**表里任何一个键**也与 `k'` 满足 `R`——注意 `specialize (H (k, v) Hin)` 先把实例喂进去、`simpl in H` 把 `uncurry` 的模式匹配归约成 `R k k'`（直接 `apply H` 会让 unify 卡在没归约的 `let '(a,b) := ...` 上，实测坑见 39.8）。这条引理马上就是「挖矛盾」的铲子：

```coq
Definition elements_correct_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    In (k, v) (elements t) ->
    bound k t = true /\ lookup d k t = v.

Theorem elements_correct : elements_correct_spec.
Proof.
  unfold elements_correct_spec.
  intros V k v d t H.
  induction H as [ | l x v' r Hl Hr HBl IHl HBr IHr]; intros Hin.
  - destruct Hin.
  - simpl in Hin. apply in_app_or in Hin.
    destruct Hin as [Hi | Hi].
    + destruct (IHl Hi) as [Hb Hlk]. simpl.
      assert (Hkl : k < x).
      { exact (elements_preserves_relation V k x v l
                 (fun a b => a < b) Hl Hi). }
      rewrite (proj2 (Nat.ltb_lt k x) Hkl).
      split; [exact Hb | exact Hlk].
    + destruct Hi as [Heq | Hi].
      * injection Heq as Hkx Hvv. subst k. subst v.
        simpl. rewrite (Nat.ltb_irrefl x).
        split; reflexivity.
      * destruct (IHr Hi) as [Hb Hlk]. simpl.
        assert (Hkx : x < k).
        { exact (elements_preserves_relation V k x v r
                   (fun a b => b < a) Hr Hi). }
        rewrite (proj2 (Nat.ltb_ge k x) (Nat.lt_le_incl _ _ Hkx)).
        rewrite (proj2 (Nat.ltb_lt x k) Hkx).
        split; [exact Hb | exact Hlk].
Qed.
```

`elements_correct`（**正确性**，VFA 4 星）对 BST 证据归纳。表元素来自左半、右半或中缝三种：来自左半时 IH 给出「`k` 在左子树且绑定」，而 **BST 前提说左子树所有键 < x**——`elements_preserves_relation` 以 `R := (fun a b => a < b)` 挖出 `k < x`，于是 `k` 的查询路径必然向左（`proj2 (Nat.ltb_lt ...)` 把命题兑回布尔、`rewrite` 进目标），IH 的 `bound/lookup` 结论原样搬出。右半对称（`R := (fun a b => b < a)` 挖出 `x < k`，两个方向都要兑）。中缝元素 `injection` 出 `x = k`、`v' = v`，查询在根直接命中——`Nat.ltb_irrefl` 把 `x <? x` 一步清成 false（**一次 rewrite 清掉所有出现**，写两次会报 no subterm，实测坑）。**BST 在这里不可省略**：没有「左小右大」，来自左半的键完全可能大于根，查询路径就对不上了。

### 39.5 elements 的三重规格 II：有序与无重复

```coq
(* ---------- 39.5 elements 的三重规格 II：有序与无重复 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Lemma sorted_app : forall l1 l2 x,
  sorted l1 -> sorted l2 ->
  Forall (fun n => n < x) l1 -> Forall (fun n => n > x) l2 ->
  sorted (l1 ++ x :: l2).
Proof.
  induction l1 as [ | a t IH]; intros l2 x Hs1 Hs2 Hall1 Hall2.
  - simpl.
    destruct l2 as [ | b t2].
    + apply sorted_1.
    + inversion Hall2 as [| n l Htail Hn]; subst.
      apply sorted_cons; [lia | exact Hs2].
  - destruct t as [ | b t2].
    + inversion Hall1 as [| n l Htail Hn]; subst.
      simpl. apply sorted_cons.
      * lia.
      * exact (IH l2 x sorted_nil Hs2 Hn Hall2).
    + inversion Hs1 as [ | | i j l Hab Hs1' Heq]; subst.
      inversion Hall1 as [| n l Htail Hn]; subst.
      simpl. apply sorted_cons.
      * exact Hab.
      * exact (IH l2 x Hs1' Hs2 Hn Hall2).
Qed.
```

第二重性质：elements 输出按键**有序**（`elements_ex` 里已经见过）。`sorted` 用第 34 章同款相邻式归纳定义。核心引理 `sorted_app`：**两个有序表、中间插一个「左边全小于、右边全大于」的隔板值，拼起来仍有序**——这正是中序遍历的递归结构。证明对 `l1` 归纳，两个小陷阱都在「头元素与隔板的关系」上：`l1 = []` 时要证 `sorted (x :: l2)`，`x` 与 `l2` 头的大小关系**不在 `sorted l2` 里**而在 `Hall2` 里（inversion `Forall_cons` 拿头元素性质 `Hn`，`lia` 收 `x <= b`）；`l1` 非空时新头 `a` 与拼接缝的衔接同样从 `Hall1` 的尾性质 + IH 拼出。`inversion ... as [| n l Htail Hn]` 的两个名字要分清：`Htail` 是头元素性质、`Hn` 是尾部 Forall（实测坑见 39.8）。

```coq
Definition list_keys {V : Type} (lst : list (key * V)) :=
  map fst lst.

Lemma keys_lt : forall (V : Type) (t : tree V) (x : key),
    ForallT (fun y _ => y < x) t ->
    Forall (fun n => n < x) (list_keys (elements t)).
Proof.
  intros V t x H.
  assert (Hf := elements_preserves_forall V (fun y _ => y < x) t H).
  rewrite Forall_forall in Hf |- *.
  intros k Hk. apply in_map_iff in Hk. destruct Hk as [kv [Heq Hin]].
  destruct kv as [a b]. simpl in Heq. subst a.
  specialize (Hf (k, b) Hin). simpl in Hf. exact Hf.
Qed.

Lemma keys_gt : forall (V : Type) (t : tree V) (x : key),
    ForallT (fun y _ => y > x) t ->
    Forall (fun n => n > x) (list_keys (elements t)).
Proof.
  intros V t x H.
  assert (Hf := elements_preserves_forall V (fun y _ => y > x) t H).
  rewrite Forall_forall in Hf |- *.
  intros k Hk. apply in_map_iff in Hk. destruct Hk as [kv [Heq Hin]].
  destruct kv as [a b]. simpl in Heq. subst a.
  specialize (Hf (k, b) Hin). simpl in Hf. exact Hf.
Qed.

Theorem sorted_elements : forall (V : Type) (t : tree V),
    BST t -> sorted (list_keys (elements t)).
Proof.
  intros V t H.
  induction H as [ | l x v r Hl Hr HBl IHl HBr IHr].
  - simpl. apply sorted_nil.
  - simpl. unfold list_keys.
    rewrite map_app. simpl.
    apply sorted_app.
    + exact IHl.
    + exact IHr.
    + apply keys_lt. exact Hl.
    + apply keys_gt. exact Hr.
Qed.
```

有序说的是**键列** `list_keys (elements t) = map fst ...`。`keys_lt/keys_gt` 是「BST 的 ForallT 前提 → 表键的 Forall」搬运工：`in_map_iff`（第 34 章用过）把 `In k (map fst L)` 兑成「存在二元组」，`destruct kv as [a b]` 把二元组拆开才能让 `uncurry` 归约（实测坑同 39.4）。`sorted_elements` 于是四行组装：`map_app`（map 与 ++ 交换）把键列摆成 `sorted_app` 的形状，两半的有序来自 IH、两个隔板条件来自搬运工——**BST 证据的 ForallT 前提与遍历表的结构严丝合缝**。

```coq
Definition disjoint {X : Type} (l1 l2 : list X) :=
  forall (x : X), In x l1 -> ~ In x l2.

Lemma NoDup_append : forall (X : Type) (l1 l2 : list X),
  NoDup l1 -> NoDup l2 -> disjoint l1 l2 ->
  NoDup (l1 ++ l2).
Proof.
  intros X l1. induction l1 as [ | a t IH]; intros l2 H1 H2 Hd.
  - exact H2.
  - simpl. inversion H1 as [| x l Hnd Hnin Heq]; subst.
    constructor.
    + intro Hin. apply in_app_or in Hin.
      destruct Hin as [Hi | Hi].
      * apply Hnd. exact Hi.
      * apply (Hd a).
        -- left. reflexivity.
        -- exact Hi.
    + apply IH.
      * exact Hnin.
      * exact H2.
      * intros y Hy. apply Hd. right. exact Hy.
Qed.
```

第三重性质：键**无重复**。标准库的 `NoDup`（归纳谓词：`~In` 头 + 尾部 NoDup）配一条自制引理 `NoDup_append`：两段各自无重复且**互不相交**（`disjoint`），拼接仍无重复。证明对 `l1` 归纳：新头 `a` 要不在尾、要不在 `l2`——前者用 inversion 出的 `Hnd : ~ In a t`，后者用不相交性（`Hd a` 配上 `In a (a::t)` 的左支 `left. reflexivity.`）。

```coq
Theorem elements_nodup_keys : forall (V : Type) (t : tree V),
    BST t ->
    NoDup (list_keys (elements t)).
Proof.
  intros V t H.
  induction H as [ | l x v r Hl Hr HBl IHl HBr IHr].
  - simpl. constructor.
  - simpl. unfold list_keys.
    rewrite map_app. simpl.
    apply NoDup_append.
    + exact IHl.
    + constructor.
      * intro Hin.
        assert (HG := keys_gt V r x Hr).
        rewrite Forall_forall in HG. specialize (HG x Hin). lia.
      * exact IHr.
    + intros k Hk1 Hk2.
      assert (HF := keys_lt V l x Hl). rewrite Forall_forall in HF.
      assert (HG := keys_gt V r x Hr). rewrite Forall_forall in HG.
      specialize (HF k Hk1).
      destruct Hk2 as [Hk2 | Hk2].
      * rewrite <- Hk2 in HF. lia.
      * specialize (HG k Hk2). lia.
Qed.
```

`elements_nodup_keys` 与 `sorted_elements` 同骨架，但多一个弯：键列的结构是 `左键列 ++ x :: 右键列`——**外层是 `++` 不是 `::`**，不能直接 `constructor`（NoDup_cons 咬不住），要先 `NoDup_append` 拆成「两半各自 NoDup + 不相交」。不相交的证明是漂亮的三角矛盾：`k` 在左半 ⇒ `k < x`（keys_lt）；`k` 在右半 ⇒ `k > x`（keys_gt）——`lia` 收 `x < x`；`k` 恰为隔板 `x` 时把 `Hk2 : x = k` 代回左半的 `k < x`，还是 `lia`。三重规格（完备、正确、有序无重复）到此集齐——它们合起来说的就是：**`elements t` 是 `t` 的「标准形式」**。

### 39.6 fast_elements：证慢的，兑快的

```coq
(* ---------- 39.6 fast_elements：证慢的，兑快的 ---------- *)

Fixpoint fast_elements_tr {V : Type} (t : tree V)
         (acc : list (key * V)) : list (key * V) :=
  match t with
  | E => acc
  | T l k v r => fast_elements_tr l ((k, v) :: fast_elements_tr r acc)
  end.

Definition fast_elements {V : Type} (t : tree V) : list (key * V) :=
  fast_elements_tr t [].

Lemma fast_elements_tr_helper :
  forall (V : Type) (t : tree V) (lst : list (key * V)),
    fast_elements_tr t lst = elements t ++ lst.
Proof.
  intros V t. induction t as [ | l IHl x v r IHr]; intros lst.
  - reflexivity.
  - simpl. rewrite IHr. rewrite IHl.
    rewrite <- app_assoc. reflexivity.
Qed.

Lemma fast_elements_eq_elements : forall (V : Type) (t : tree V),
    fast_elements t = elements t.
Proof.
  intros V t. unfold fast_elements.
  rewrite (fast_elements_tr_helper V t []).
  rewrite app_nil_r. reflexivity.
Qed.

Corollary fast_elements_correct :
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    In (k, v) (fast_elements t) ->
    bound k t = true /\ lookup d k t = v.
Proof.
  intros V k v d t H Hin.
  rewrite fast_elements_eq_elements in Hin.
  exact (elements_correct V k v d t H Hin).
Qed.

Print Assumptions fast_elements_correct.

End Ex39SearchTree.
```

`elements` 的 `++` 实现在平衡树上代价不小（每层拼接线性扫）。`fast_elements_tr` 换成**累加器**风格：从右往左把节点 cons 进 `acc`，全程无 `++`。直接验证它要重打一遍 39.4–39.5 的全部战役吗？不用——**证「快的 = 慢的」一条就够**：`fast_elements_tr_helper`（对树归纳，右半先兑 IH、`(k,v) :: (elements r ++ lst)` 与 `((k,v) :: elements r) ++ lst` 之间差一个 `app_assoc`）说明累加器版就是把慢版的结果**后缀拼接**；`fast_elements_eq_elements` 取 `lst = []` 再消掉 `++ []`（`app_nil_r`——`++` 卡在变量上不能自己归约，实测坑）。于是 `fast_elements_correct` 两行：把假设里的 `fast_elements` rewrite 成 `elements`，39.4 的定理直接复用。**「先证简单实现，再证等价，正确性免费传导」**——这条工程方法论在后面章节（以及现实项目）里反复回本。`Print Assumptions` 实测 `Closed under the global context`：整棵定理树无公理。

收个尾。本章把第 28 章的 BST 验证升级成完整工程：表示（39.1）、不变量与保持（39.2）、代数规格（39.3）、遍历的三重规格（39.4–39.5）、性能实现的等价兑换（39.6）。方法论清单：**证据归纳**（对 BST/ForallT 推导而不是对树）、**万金油引理**（ForallT_insert 一条抵一族）、**布尔路径同步**（destruct + 兑换 + lia 的三连）、**证慢兑快**。下一章（40 抽取）把这棵验证过的树用 `Extraction` 抽到 OCaml 真机运行；第 42 章（ADT）则把本章的定理包装成 Module Type 接口。

### 39.7 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`tree_ind` 的 IH 紧跟递归参数**（39.2）：生成原则把每个递归参数的 IH 插在该参数之后，`induction t as [ | l x v' r IHl IHr]` 实测绑定整体错位（x 落到 IH 槽、后续全歪）；正确写法 `[ | l IHl x v' r IHr]`。BST 证据归纳同理是 `[| l x v r Hl Hr HBl IHl HBr IHr]`（每棵子树的 BST 后面紧跟它的 IH）。
2. **`Nat.ltb_lt` 只吃 `= true`**（39.3）：对 `(k <? x) = false` 用它实测报 `Unable to apply lemma ... on hypothesis of type "(k <? x) = false"`——false 方向要用 `Nat.ltb_ge`。
3. **lia 读不懂裸布尔等式**（39.3）：上下文只有 `(k' <? k) = false`、`(k <? k') = false` 时直接 `lia` 实测报 `Tactic failure: Cannot find witness.`——先 `apply Nat.ltb_ge in` 兑换成 `<=` 命题再 lia。
4. **`uncurry` 套在变量二元组上不归约**（39.4）：`apply H` 想统一 `R k k'` 与 `let '(a, b) := ?x in ...` 实测报 `Unable to unify "let '(a, b) := ?x in ..."`——先 `specialize (H (k, v) Hin). simpl in H.`，或 `destruct kv as [a b]` 拆开二元组。
5. **`rewrite (Nat.ltb_irrefl x)` 一次清掉所有出现**（39.4）：bound 与 lookup 两处同项 `x <? x`，连写两次第二个实测报 `Found no subterm matching "x <? x"`——一次 rewrite 后靠转换即可。
6. **`apply (IH ...)` 过不了转换时改全参数 `exact`**（39.5）：`apply (IH [] x)` 统一 `sorted ([] ++ x :: l2)` 与 `sorted (x :: l2)` 实测报 `Unable to unify`（`++` 卡在变量上不自动归约）；`exact (IH l2 x sorted_nil Hs2 Hn Hall2)` 全参数 + exact 的转换检查可通过。
7. **`inversion ... as [| n l Htail Hn]` 的名字易混**（39.5）：`Forall_cons` 的槽位是「头元素性质、尾部 Forall」，写反后实测报 `The term "Hs2" has type "sorted l2" while it is expected to have type "sorted (b :: t2)"` 一类错位。
8. **`NoDup (L1 ++ x :: L2)` 不能直接 `constructor`**（39.5）：外层结构是 `++` 不是 `::`，实测报 `Unable to unify "NoDup (?x :: ?l)"`——先 `NoDup_append` 拆成两半各自 NoDup + disjoint。
9. **`reflexivity` 关不掉变量上的 if**（39.3）：`lookup d k' (insert k v E)` 的比较布尔是变量表达式，基例也必须 destruct 布尔后才能归约（实测报 `Unable to unify "d" with "if k' <? k then ..."`）。
10. **`>?` 记法已删**（39.1）：stdlib 9.2 无 `Nat.geb`，`x >? k` 直接语法错——比较一律写成 `k <? x`（本书 35/43/44 章同此）。

---
上一章：[38 · 可判定规格](38-decide.md) ｜ 下一章：[40 · 抽取：把验证代码变成 OCaml](40-extract.md) ｜ 返回：[README](../README.md)
