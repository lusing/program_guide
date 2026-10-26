# 42 · 抽象数据类型

对应示例：`../examples/42_adt.v`（`Module Ex42ADT`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

到第 41 章为止，每一种数据结构（排序表、BST、红黑树）都是**一次性**地定义、证明、使用。本章换一个软件工程的视角：**接口与实现分离**。Coq 的模块系统（`Module Type` / `Module` / functor）能把「一个 table 应该提供哪些操作、满足哪些定律」写成**签名**，把具体数据结构写成**实现**，再让编译器机器检查「实现满足签名」。一条签名可以配多种实现（函数、关联表、BST——本章三种），一套客户代码不改动一个字就能换实现；实现里凡是签名声明过的公理，都必须真刀真枪证出来。

主线四步：签名怎么写（42.1）；三种实现与 functor（42.2–42.4）；**表示不变量**为什么必须进接口（42.5）；`<:` 与 `:` 一字之差的**封装**与共享约束（42.6）。第 43 章优先队列将直接复用本章的方法论（`Module Type` 签名 + 表示不变量 + 表征定理）。

### 42.1 接口即 Module Type：Table 签名

文件头与签名：

```coq
(* 42 抽象数据类型 —— Module Type 签名、functor、表示不变量与封装 *)

From Stdlib Require Import Arith Bool Lia List Strings.String.
Import ListNotations.

Module Ex42ADT.

(* ---------- 42.1 接口即 Module Type：Table 签名 ---------- *)

Module Type Table.

  Parameter table : Type.

  Definition key := nat.

  Parameter V : Type.

  Parameter default : V.

  Parameter empty : table.

  Parameter get : key -> table -> V.

  Parameter set : key -> V -> table -> table.

  Axiom get_empty_default : forall (k : key),
      get k empty = default.

  Axiom get_set_same : forall (k : key) (v : V) (t : table),
      get k (set k v t) = v.

  Axiom get_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> get k' (set k v t) = get k' t.

End Table.
```

`Module Type` 声明的是**接口**（VFA 用 table 这个词避免与 map 混名）。三类成员各司其职：**`Parameter`** 只声明类型不绑定值——`table`（表示类型）、`V`（值类型）、`default`、`empty`、`get`、`set` 都留给实现去定义；**`Definition`**（`key := nat`）直接在接口里定死，所有实现共享；**`Axiom`** 声明定律的类型而不给证明——三条公理正是第 39 章 39.3 节的「lookup 三方程」：空表查默认、查刚设的键得新值、查别的键不受影响。**接口里的 Axiom 不是作弊**——它是对实现者的「欠条」：任何 `Module ... : Table` 必须逐条兑现。这就是本章的核心契约：**规格写在签名里，证明落在实现里**。

### 42.2 函数式实现：ValType 与 FunTable

```coq
(* ---------- 42.2 函数式实现：ValType 与 FunTable ---------- *)

Module Type ValType.
  Parameter V : Type.
  Parameter default : V.
End ValType.

Module FunTable (VT : ValType) <: Table.

  Definition V := VT.V.
  Definition default := VT.default.
  Definition key := nat.

  Definition table := key -> V.

  Definition empty : table :=
    fun _ => default.

  Definition get (k : key) (t : table) : V :=
    t k.

  Definition set (k : key) (v : V) (t : table) : table :=
    fun k' => if k =? k' then v else t k'.

  Theorem get_empty_default : forall (k : key),
      get k empty = default.
  Proof. intros. reflexivity. Qed.

  Theorem get_set_same : forall (k : key) (v : V) (t : table),
      get k (set k v t) = v.
  Proof.
    intros. unfold get, set.
    destruct (k =? k) eqn:E.
    - reflexivity.
    - rewrite Nat.eqb_refl in E. discriminate.
  Qed.

  Theorem get_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> get k' (set k v t) = get k' t.
  Proof.
    intros. unfold get, set.
    destruct (k =? k') eqn:E.
    - apply Nat.eqb_eq in E. exfalso. apply H; exact E.
    - reflexivity.
  Qed.
End FunTable.
```

实现接口的第一种方式最俭省：**表就是函数** `key -> V`（第 48 章 total_map 的思想）。`FunTable` 是 **functor**（带模块参数的模块）：参数 `VT : ValType` 提供值类型与默认值，`<: Table` 让 Coq 在模块收尾时逐项核对签名。三条定理的证明就是第 48 章式的一步计算加布尔拆分：`get_set_same` 里 `destruct (k =? k) eqn:E` 撕开比较，真分支两侧相同，假分支 `Nat.eqb_refl` 把 `k =? k = false` 化成 `true = false` 直接 `discriminate`；`get_set_other` 的真分支用 `Nat.eqb_eq` 把布尔等式升格为 `k = k'`，与 `H : k <> k'` 当面冲突。**签名里欠的三条，functor 里全数还清。**

```coq
Module StringVal.
  Definition V := string.
  Definition default := ""%string.
End StringVal.

Module FunTableExamples.

  Module StringFunTable := FunTable StringVal.
  Import StringFunTable.
  Open Scope string_scope.

  Example ex1 : get 0 empty = "".
  Proof. reflexivity. Qed.

  Example ex2 : get 0 (set 0 "A" empty) = "A".
  Proof. reflexivity. Qed.

  Example ex3 : get 1 (set 0 "A" empty) = "".
  Proof. reflexivity. Qed.

End FunTableExamples.

Module NatVal.
  Definition V := nat.
  Definition default := 0.
End NatVal.

Module NatFunTableExamples.

  Module NatFunTable := FunTable NatVal.
  Import NatFunTable.

  Example ex1 : get 0 empty = 0.
  Proof. reflexivity. Qed.

  Example ex2 : get 0 (set 0 7 empty) = 7.
  Proof. reflexivity. Qed.

  Example ex3 : get 1 (set 0 7 empty) = 0.
  Proof. reflexivity. Qed.

End NatFunTableExamples.
```

`FunTable StringVal` 把 functor 应用到具体值模块，得到字符串表；`Import` 之后 `get/set/empty` 就像普通定义一样可用，三个 Example 纯计算。`NatVal`/`NatFunTableExamples` 是同一 functor 的第二种实例化——**换值类型不改动 functor 一行**，这就是参数化的回报。

### 42.3 关联表实现：ListsTable

```coq
(* ---------- 42.3 关联表实现：ListsTable ---------- *)

Module ListsTable (VT : ValType) <: Table.

  Definition V := VT.V.
  Definition default := VT.default.
  Definition key := nat.
  Definition table := list (key * V).

  Definition empty : table := [].

  Fixpoint get (k : key) (t : table) : V :=
    match t with
    | [] => default
    | (k', v) :: t' => if k =? k' then v else get k t'
    end.

  Definition set (k : key) (v : V) (t : table) : table :=
    (k, v) :: t.

  Theorem get_empty_default : forall (k : key),
      get k empty = default.
  Proof. intros. reflexivity. Qed.

  Theorem get_set_same : forall (k : key) (v : V) (t : table),
      get k (set k v t) = v.
  Proof.
    intros. simpl. rewrite Nat.eqb_refl. reflexivity.
  Qed.

  Theorem get_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> get k' (set k v t) = get k' t.
  Proof.
    intros. simpl. destruct (k' =? k) eqn:E.
    - apply Nat.eqb_eq in E. exfalso. apply H. symmetry. exact E.
    - reflexivity.
  Qed.

End ListsTable.

Module StringListsTableExamples.

  Module StringListsTable := ListsTable StringVal.
  Import StringListsTable.
  Open Scope string_scope.

  Example ex1 : get 0 empty = "".
  Proof. reflexivity. Qed.

  Example ex2 : get 0 (set 0 "A" empty) = "A".
  Proof. reflexivity. Qed.

  Example ex3 : get 1 (set 0 "A" empty) = "".
  Proof. reflexivity. Qed.

End StringListsTableExamples.
```

第二种实现是最朴素的**关联表**：`set` 直接头插（新绑定遮蔽旧绑定），`get` 沿表找第一个匹配。三条定理照旧三行内解决——注意 `get_set_other` 的比较方向：这里撕的是 `k' =? k`（查询键在前），`Nat.eqb_eq` 兑出的是 `k' = k`，喂给 `H : k <> k'` 前**要先 `symmetry`**（实测坑，见 42.8）。同一个签名、两套实现、两套各自通过的证明——「接口稳定、实现可换」在这个文件里已经是既成事实。

### 42.4 BST 实现：TreeTable（自备迷你SearchTree）

第三种实现要动真格：用第 39 章的 BST。本章自备一份迷你版（定义与定理都是 39 章的精简复刻，细节请回看 39.1–39.3 节，此处引用以保持自包含）：

```coq
(* ---------- 42.4 BST 实现：TreeTable（自备迷你SearchTree） ---------- *)

Module MiniSearchTree.

  Definition key := nat.

  Inductive tree (V : Type) : Type :=
  | E
  | T (l : tree V) (k : key) (v : V) (r : tree V).

  Arguments E {V}.
  Arguments T {V}.

  Definition empty_tree {V : Type} : tree V := E.

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

  Theorem lookup_empty : forall (V : Type) (d : V) (k : key),
      lookup d k empty_tree = d.
  Proof. intros. reflexivity. Qed.

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

  Theorem lookup_insert_neq :
    forall (V : Type) (t : tree V) (d : V) (k k' : key) (v : V),
     k <> k' -> lookup d k' (insert k v t) = lookup d k' t.
  Proof.
    induction t as [ | l IHl x v' r IHr]; intros d k k' v Hne; simpl.
    - destruct (k' <? k) eqn:E1.
      + reflexivity.
      + destruct (k <? k') eqn:E2.
        * reflexivity.
        * exfalso.
          apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2. lia.
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
          assert (Hkx : k = x) by lia. subst x. simpl.
          destruct (k' <? k) eqn:E3.
          -- reflexivity.
          -- destruct (k <? k') eqn:E4.
             ++ reflexivity.
             ++ exfalso.
                apply Nat.ltb_ge in E3. apply Nat.ltb_ge in E4. lia.
  Qed.

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

  Theorem empty_tree_BST : forall (V : Type),
      BST (@empty_tree V).
  Proof. intros V. unfold empty_tree. apply BST_E. Qed.

  Lemma ForallT_insert :
    forall (V : Type) (P : key -> V -> Prop) (t : tree V),
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

End MiniSearchTree.
```

这块「迷你 39 章」保留了三样东西：`bound/lookup/insert` 三个操作、lookup 的两条插入定理（`lookup_insert_eq/neq`，证明战术与 39.3 节逐字相同——destruct 布尔、Nat.ltb_lt/ltb_ge 兑换、lia 收矛盾）、以及 `BST` 不变量与 `insert_BST`（42.5 要用）。把它包在独立 `Module MiniSearchTree` 里有两个好处：命名空间干净（`bound` 不与外面的定理撞名）、42.6 讲封装时有真实的「内部实现」可藏。

```coq
Module TreeTable (VT : ValType) <: Table.

  Definition V := VT.V.
  Definition default := VT.default.
  Definition key := nat.
  Definition table := MiniSearchTree.tree V.

  Definition empty : table :=
    @MiniSearchTree.empty_tree V.

  Definition get (k : key) (t : table) : V :=
    MiniSearchTree.lookup default k t.

  Definition set (k : key) (v : V) (t : table) : table :=
    MiniSearchTree.insert k v t.

  Theorem get_empty_default : forall (k : key),
      get k empty = default.
  Proof. apply MiniSearchTree.lookup_empty. Qed.

  Theorem get_set_same : forall (k : key) (v : V) (t : table),
      get k (set k v t) = v.
  Proof. intros. apply MiniSearchTree.lookup_insert_eq. Qed.

  Theorem get_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> get k' (set k v t) = get k' t.
  Proof.
    intros. apply MiniSearchTree.lookup_insert_neq. assumption.
  Qed.

End TreeTable.
```

`TreeTable` 是本章最想让你看见的一件事：**接口实现薄得像纸**。`table/get/set` 全是对 MiniSearchTree 的一行委托，三条定理是对 39 章已证定理的一行引用——**前期在数据结构上投入的证明资本，在这里以「零成本换接口」的方式变现**。对比 `FunTable`（三行计算证明）与 `ListsTable`（三行表归纳），三种实现的「接口适配层」都只有十几行，重量全在各自的表示层。

### 42.5 表示不变量进接口：ETable

`Table` 的三条公理对三种实现都成立，但那只覆盖了 `get`。想给接口加 `bound`（以及原书还有的 `elements`）就会撞上第 39 章的老问题：**`elements` 的正确性只在 BST 上成立**——`bound/elements` 的定理需要「这棵树满足 BST」作为前提，而 `Table` 接口里根本没有这个概念。解法是把**表示不变量本身**写进接口：

```coq
(* ---------- 42.5 表示不变量进接口：ETable ---------- *)

Module Type ETable.

  Include Table.

  Parameter rep_ok : table -> Prop.

  Parameter bound : key -> table -> bool.

  Axiom empty_ok : rep_ok empty.

  Axiom set_ok : forall (k : key) (v : V) (t : table),
      rep_ok t -> rep_ok (set k v t).

  Axiom bound_empty : forall (k : key),
      bound k empty = false.

  Axiom bound_set_same : forall (k : key) (v : V) (t : table),
      bound k (set k v t) = true.

  Axiom bound_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> bound k' (set k v t) = bound k' t.

End ETable.
```

`Include Table` 把整个旧接口原样搬进来（改 `Table` 一处、处处生效）。新增的 `rep_ok : table -> Prop` 是一个**抽象的**表示不变量——接口不规定它是什么，只规定两条公理：`empty_ok`（空表合法）与 `set_ok`（**操作保持合法性**）。这正是第 39 章 `empty_tree_BST` 与 `insert_BST` 的签名抽象版。加 `bound` 的三条公理与 `get` 三条同构（原书完整版还有 `elements` 的完备/正确两公理，其证明正是 39.4 节的 `elements_complete/elements_correct`——它们同样以 `rep_ok` 为前提，这就是表示不变量非进接口不可的原因）。

```coq
Module TreeETable (VT : ValType) <: ETable.

  Include TreeTable VT.

  Definition rep_ok (t : table) : Prop :=
    MiniSearchTree.BST t.

  Definition bound (k : key) (t : table) : bool :=
    MiniSearchTree.bound k t.

  Theorem empty_ok : rep_ok empty.
  Proof. apply MiniSearchTree.empty_tree_BST. Qed.

  Theorem set_ok : forall (k : key) (v : V) (t : table),
      rep_ok t -> rep_ok (set k v t).
  Proof. apply MiniSearchTree.insert_BST. Qed.

  Theorem bound_empty : forall (k : key),
      bound k empty = false.
  Proof. intros. reflexivity. Qed.

  Theorem bound_set_same : forall (k : key) (v : V) (t : table),
      bound k (set k v t) = true.
  Proof.
    intros k v t. unfold bound, set.
    induction t as [ | l IHl x v' r IHr]; simpl.
    - destruct (k <? k) eqn:E1.
      + apply Nat.ltb_lt in E1. lia.
      + reflexivity.
    - destruct (k <? x) eqn:E1.
      + simpl. rewrite E1. exact IHl.
      + destruct (x <? k) eqn:E2.
        * simpl. rewrite E1. rewrite E2. exact IHr.
        * simpl. destruct (k <? k) eqn:E3.
          -- apply Nat.ltb_lt in E3. lia.
          -- reflexivity.
  Qed.

  Theorem bound_set_other : forall (k k' : key) (v : V) (t : table),
      k <> k' -> bound k' (set k v t) = bound k' t.
  Proof.
    intros k k' v t Hne. unfold bound, set.
    induction t as [ | l IHl x v' r IHr]; simpl.
    - destruct (k' <? k) eqn:E1.
      + reflexivity.
      + destruct (k <? k') eqn:E2.
        * reflexivity.
        * exfalso. apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
          apply Hne. lia.
    - destruct (k <? x) eqn:E1.
      + destruct (k' <? x) eqn:E2.
        * simpl. rewrite E2. exact IHl.
        * simpl. rewrite E2. reflexivity.
      + destruct (x <? k) eqn:E2.
        * destruct (k' <? x) eqn:E3.
          -- simpl. rewrite E3. reflexivity.
          -- destruct (x <? k') eqn:E4.
             ++ simpl. rewrite E3. rewrite E4. exact IHr.
             ++ simpl. rewrite E3. rewrite E4. reflexivity.
        * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
          assert (Hkx : k = x) by lia. subst x.
          simpl. destruct (k' <? k) eqn:E3.
          -- reflexivity.
          -- destruct (k <? k') eqn:E4.
             ++ reflexivity.
             ++ exfalso. apply Nat.ltb_ge in E3. apply Nat.ltb_ge in E4.
                apply Hne. lia.
  Qed.

End TreeETable.
```

`Include TreeTable VT` 把 42.4 的全部定义与定理继承进来（`Include` 在 functor 体里同样工作）。`rep_ok` 落地为 `BST`，两条不变量公理立即由 39 章的 `empty_tree_BST/insert_BST` 一行兑现——**表示不变量「进接口」的代价几乎为零，因为证明早在表示层就备好了**。`bound` 的两条 set 公理是对树归纳的布尔推理（与 `lookup_insert_eq/neq` 同构，多一层「destruct 出的布尔在 simpl 之后又冒出新出现处，要 `rewrite E1` 对齐」的处理）；`bound_set_other` 最末分支里 `k = x` 时新旧值不同，靠 `Hne : k <> k'` 的矛盾收场。这个模块就是第 43 章优先队列验证的模板：**接口 = 代数定律 + 表示不变量 + 操作表征**。

### 42.6 封装：`<:` 与 `:`，共享约束

```coq
(* ---------- 42.6 封装：<: 与 : ，共享约束 ---------- *)

Module StringTreeETableExample.

  Module StringTreeETable := TreeETable StringVal.
  Import StringTreeETable.
  Open Scope string_scope.

  (* Include 的实现是透明的：T 构造子在模块外仍然可用。 *)
  Example exposed_trees_ex :
    StringTreeETable.get 0
      (MiniSearchTree.T MiniSearchTree.E 0 "A" MiniSearchTree.E) = "A".
  Proof. reflexivity. Qed.

End StringTreeETableExample.
```

`<:` 是**透明**实现：签名只要求「至少有这些成员」，其余全部公开——`exposed_trees_ex` 证明客户代码能直接用树的构造子 `T`/`E` 造一棵「表」、并看穿 `get` 就是 `lookup`。数据结构课的直觉说这很危险：客户一旦用了 `T`，换实现就全崩。Coq 的封装只改一个字符：

```coq
Module TreeETableFullyEncapsulated (VT : ValType) : ETable :=
  TreeETable VT.

Module OverlyEncapsulatedExample.

  Module StringTreeETableFullyEncapsulated :=
    TreeETableFullyEncapsulated StringVal.
  Import StringTreeETableFullyEncapsulated.

  Fail Example ex1 : get 0 empty = ""%string.

End OverlyEncapsulatedExample.
```

`:` 是**不透明**实现：签名之外的成员一律隐藏。`Module F (VT) : ETable := TreeETable VT.` 一行就把现成 functor 密封起来（等价于原书整模块重抄一遍再加密封——`:=` 模块定义让我们免于复制 60 行）。但马上**矫枉过正**：`Fail Example ex1` 实测编不过——`ETable` 里 `V` 只是个抽象 `Type`，客户根本不知道 `""` 就是合法值，连 `default` 是什么都看不见了。

出路是**共享约束**（sharing constraint）——`with` 子句把接口里的抽象成员钉死成具体定义：

```coq
Module Type SimpleTable.
  Parameter key : Type.
  Parameter V : Type.
  Parameter default : V.
  Parameter table : Type.
End SimpleTable.

Module SimpleStringTable1 : SimpleTable.
  Definition key := nat.
  Definition V := string.
  Definition default : string := "".
  Definition table := list (key * V).
End SimpleStringTable1.

Module Type SimpleTable2 := SimpleTable with Definition V := string.

Module SimpleStringTable2 : SimpleTable2.
  Definition key := nat.
  Definition V := string.
  Definition default : string := "".
  Definition table := list (key * V).
End SimpleStringTable2.

Module Type SimpleTable3 := SimpleTable
  with Definition V := string
  with Definition default := ""%string.

Module SimpleStringTable3 : SimpleTable3.
  Definition key := nat.
  Definition V := string.
  Definition default : string := "".
  Definition table := list (key * V).
End SimpleStringTable3.
```

三个小模块是共享约束的三档：`SimpleStringTable1`（纯 `:`）把 `V`/`default` 全部封死；`SimpleTable2` 用 `with Definition V := string` 只放行 `V`；`SimpleTable3` 再放行 `default`。`with` 派生出新接口类型，密封度逐档放宽——**封装不是开关，是旋钮**。

```coq
Module TreeETableEncapsulated (VT : ValType)
  : (ETable with Definition V := VT.V
             with Definition default := VT.default) :=
  TreeETable VT.

Module NicelyEncapsulatedExample.

  Module StringTreeETableEncapsulated :=
    TreeETableEncapsulated StringVal.
  Import StringTreeETableEncapsulated.
  Open Scope string_scope.

  Example ex1 : get 0 empty = "".
  Proof.
    Fail reflexivity.
    apply get_empty_default.
  Qed.

  (* 封装后 tree 的构造子不可用：只能通过接口操作建表。 *)
  Fail Example ex2 : get 0 (T E 0 "A" E) = "A".

End NicelyEncapsulatedExample.

Module Check42 := TreeETable StringVal.
Print Assumptions Check42.set_ok.

End Ex42ADT.
```

`TreeETableEncapsulated` 把旋钮拧到正解：藏掉 `tree`/构造子/`lookup`，放行 `V` 与 `default`（用 functor 参数钉死，而非硬编码 string——functor 依然对任意值类型可用）。`NicelyEncapsulatedExample` 里两件事值得盯着看：`ex1` 的证明里 `Fail reflexivity` 实测成立——**封装之后 `get` 展不开了，纯计算的路被掐断**，但 `apply get_empty_default` 一步即中——**接口公理就是为客户准备的全部推理素材**，这正是「按规格编程」的滋味；`Fail Example ex2` 说明树的构造子彻底不可用，客户再也无法绕过接口手搓表示。收尾 `Print Assumptions`（注意要拿到**实例化后**的模块上查——functor 本身没有定理，实测对 `TreeETable.set_ok` 直接 Print 报 `The reference ... was not found`）输出 `Closed under the global context`：签名里的 `Axiom` 只是接口插槽，实现模块兑现后无任何公理残留。

### 42.7 本章小结

ADT 验证的两套配方（原书总结，本章全部实操过第一套）：**方程式规格**——定义表示不变量 `rep_ok`，证明每个操作保持它（`empty_ok/set_ok`），再借它验证操作方程（`bound` 三条）；**模型式规格**——再定义一个抽象函数 `Abs` 把表示映到易推理的模型（如第 48 章的函数式映射），证明每个操作与模型操作「交换」（第 43 章的 relate 定理正是这个配方）。模块系统三件套各就各位：`Module Type` 写契约（Parameter 声明、Axiom 欠条、Include 复用），functor 参数化实现并让签名机器核对，`:`/`<:`/`with` 三档密封度按需选择。**接口是给客户的规格，实现是给证明的战场，封装保证两者永远隔着一层可替换的膜**——下一章优先队列将用同一套模块语法，验证一个真正需要表示不变量的数据结构。

### 42.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`Nat.eqb_eq` 兑出的等式方向要跟 `<>` 假设对齐**（42.2/42.3）：`k =? k'` 给 `k = k'` 可直接喂 `H : k <> k'`；`k' =? k` 给 `k' = k`，实测报 `The term "E" has type "k' = k" while it is expected to have type "k = k'"`——先 `symmetry` 再喂。
2. **destruct 之后 simpl 会暴露**新的**布尔出现处**（42.5）：`bound k (T (insert k v l) x v' r)` 只有 simpl 展开后才露出内层 `k <? x`，直接 `exact IHl` 实测报 `The term "IHl" ... expected ... "MiniSearchTree.bound k (MiniSearchTree.T ...)"`。对策：`simpl. rewrite E1. exact IHl.`。
3. **有的分支里布尔已被简化吃掉**（42.5）：`k = x` 分支（insert 换节点）里 simpl 后只剩 `k <? k`，前面的 `rewrite E1` 实测报 `Found no subterm matching "k <? x"`——各分支要按 simpl **之后**的形状写，不能整段复制。
4. **基表的 if 卡在变量上，`reflexivity` 不够**（42.5）：`bound_set_other` 空表情形目标是 `(if k' <? k then false else ...) = false`，实测报 `Unable to unify "false" with "if ..."`——destruct 两个布尔、等值分支用 `Hne` 收矛盾。
5. **归纳时已在上下文的假设不会进 IH 的参数**（42.5）：`intros ... Hne` 之后 `induction t`，IH 是纯等式（无 `Hne` 参数），`exact (IHl Hne)` 实测报 `Illegal application (Non-functional construction)`——直接 `exact IHl`。
6. **嵌套模块的构造子在客户侧要全名**（42.6）：`T E 0 "A" E` 在 Example 模块里实测报 `The reference T was not found in the current environment`——MiniSearchTree 未 Import，写全 `MiniSearchTree.T MiniSearchTree.E ...`。
7. **密封模块掐断计算**（42.6）：`:` 密封后 `reflexivity` 实测失败（`get` 展不开），必须改走接口公理 `apply get_empty_default`；同理 `Print Assumptions` 不能打在 functor 上（实测 `The reference TreeETable.set_ok was not found`），要先 `Module Check42 := TreeETable StringVal.` 拿实例。
8. **`with Definition default := ""%string` 的记法要带 scope 标注**（42.6）：接口派生里的字符串字面量若不写 `%string`，会与后续模块定义的类型对不上——共享约束两侧的「定义」必须约化到同一个项。

---
上一章：[41 · 红黑树](41-redblack.md) ｜ 下一章：[43 · 优先队列](43-priqueue.md) ｜ 返回：[README](../README.md)
