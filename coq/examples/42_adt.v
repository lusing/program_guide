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

Module TreeETableFullyEncapsulated (VT : ValType) : ETable :=
  TreeETable VT.

Module OverlyEncapsulatedExample.

  Module StringTreeETableFullyEncapsulated :=
    TreeETableFullyEncapsulated StringVal.
  Import StringTreeETableFullyEncapsulated.

  Fail Example ex1 : get 0 empty = ""%string.

End OverlyEncapsulatedExample.

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
