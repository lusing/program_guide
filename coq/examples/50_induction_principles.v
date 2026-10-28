(* 35 归纳原则解剖 —— Inductive 一声明，Rocq 就送你一条 t_ind；本章拆开看它从哪来、长什么样、怎么手搓 *)

From Stdlib Require Import Arith List.
Import ListNotations.

Module Ex50IndPrinciples.

(* ---------- 50.1 nat_ind：induction 背后那条定理 ---------- *)

Check nat_ind :
  forall P : nat -> Prop,
    P 0 ->
    (forall n : nat, P n -> P (S n)) ->
    forall n : nat, P n.

Theorem mul_0_r' : forall n : nat,
  n * 0 = 0.
Proof.
  apply nat_ind.
  - (* n = O *) reflexivity.
  - (* n = S n' *) simpl. intros n' IHn'. rewrite -> IHn'.
    reflexivity. Qed.

(* 若先 intros n 再 apply nat_ind：不报错，但 P 被选成 fun n0 => n * 0 = n0，
   归纳假设成了 n * 0 = n0 -> n * 0 = S n0，一步也用不上。 *)
Theorem mul_0_r'_after_intro : forall n : nat,
  n * 0 = 0.
Proof.
  intros n. apply nat_ind.
Abort.

Theorem plus_one_r' : forall n : nat,
  n + 1 = S n.
Proof.
  apply nat_ind.
  - reflexivity.
  - simpl. intros n' IHn'. rewrite -> IHn'. reflexivity.
Qed.

(* ---------- 50.2 每个构造子一格：time / rgb / natlist / natlist' ---------- *)

Inductive time : Type :=
  | day
  | night.

Check time_ind :
  forall P : time -> Prop,
    P day ->
    P night ->
    forall t : time, P t.

Inductive rgb : Type :=
  | red
  | green
  | blue.

Check rgb_ind.

Inductive natlist : Type :=
  | nnil
  | ncons (n : nat) (l : natlist).

Check natlist_ind :
  forall P : natlist -> Prop,
    P nnil ->
    (forall (n : nat) (l : natlist),
        P l -> P (ncons n l)) ->
    forall n : natlist, P n.

Inductive natlist' : Type :=
  | nnil'
  | nsnoc (l : natlist') (n : nat).

Check natlist'_ind :
  forall P : natlist' -> Prop,
    P nnil' ->
    (forall l : natlist', P l -> forall n : nat, P (nsnoc l n)) ->
    forall n : natlist', P n.

(* ---------- 50.3 逆向工程：从归纳原则反推 Inductive ---------- *)

Inductive booltree : Type :=
  | bt_empty
  | bt_leaf (b : bool)
  | bt_branch (b : bool) (t1 t2 : booltree).

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

Theorem booltree_ind_type_correct : booltree_ind_type.
Proof. exact booltree_ind. Qed.

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

(* ---------- 50.4 多态：参数化的归纳原则 ---------- *)

Check list_ind :
  forall (X : Type) (P : list X -> Prop),
    P [] ->
    (forall (x : X) (l : list X), P l -> P (x :: l)) ->
    forall l : list X, P l.

Inductive tree (X : Type) : Type :=
  | leaf (x : X)
  | node (t1 t2 : tree X).

Check tree_ind :
  forall (X : Type) (P : tree X -> Prop),
    (forall x : X, P (leaf X x)) ->
    (forall t1 : tree X,
        P t1 -> forall t2 : tree X, P t2 -> P (node X t1 t2)) ->
    forall t : tree X, P t.

Inductive foo' (X : Type) : Type :=
  | C1 (l : list X) (f : foo' X)
  | C2.

Check foo'_ind :
  forall (X : Type) (P : foo' X -> Prop),
    (forall (l : list X) (f : foo' X), P f -> P (C1 X l f)) ->
    P (C2 X) ->
    forall f : foo' X, P f.

(* ---------- 50.5 归纳假设：给 P 起个名字 ---------- *)

Definition P_m0r (n : nat) : Prop :=
  n * 0 = 0.

Definition P_m0r' : nat -> Prop :=
  fun n => n * 0 = 0.

Theorem mul_0_r'' : forall n : nat,
  P_m0r n.
Proof.
  apply nat_ind.
  - (* n = O *) reflexivity.
  - (* n = S n' *)
    intros n IHn.
    unfold P_m0r in IHn. unfold P_m0r. simpl. apply IHn.
Qed.

(* ---------- 50.6 induction 的再概括：谁被泛化、谁被引入 ---------- *)

Theorem add_assoc' : forall n m p : nat,
  n + (m + p) = (n + m) + p.
Proof.
  intros n m p.
  induction n as [| n'].
  - (* n = O *) reflexivity.
  - (* n = S n' *)
    simpl. rewrite -> IHn'. reflexivity. Qed.

Theorem add_comm' : forall n m : nat,
  n + m = m + n.
Proof.
  induction n as [| n'].
  - (* n = O *) intros m. rewrite -> Nat.add_0_r. reflexivity.
  - (* n = S n' *) intros m. simpl. rewrite -> IHn'.
    rewrite <- plus_n_Sm. reflexivity. Qed.

Theorem add_comm'' : forall n m : nat,
  n + m = m + n.
Proof.
  (* 对 m 归纳，n 由 induction 自动引入 *)
  induction m as [| m'].
  - (* m = O *) simpl. rewrite -> Nat.add_0_r. reflexivity.
  - (* m = S m' *) simpl. rewrite <- IHm'.
    rewrite <- plus_n_Sm. reflexivity. Qed.

(* ---------- 50.7 命题的归纳原则：ev / ev' / le2 ---------- *)

Inductive ev : nat -> Prop :=
  | ev_0 : ev 0
  | ev_SS : forall n : nat, ev n -> ev (S (S n)).

Print ev.

Check ev_ind :
  forall P : nat -> Prop,
    P 0 ->
    (forall n : nat, ev n -> P n -> P (S (S n))) ->
    forall n : nat, ev n -> P n.

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

Scheme ev_dep := Induction for ev Sort Prop.
Check ev_dep.

(* ---------- 50.8 手写归纳原则：从 build_proof 到 nat_ind2 ---------- *)

Print nat_ind.

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

Theorem mul_0_r''' : forall n : nat,
  n * 0 = 0.
Proof.
  induction n as [ | n' IHn'] using nat_ind_tidy.
  - reflexivity.
  - simpl. rewrite -> IHn'. reflexivity.
Qed.

Fixpoint evenb (n : nat) : bool :=
  match n with
  | O => true
  | S O => false
  | S (S n') => evenb n'
  end.

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

Lemma even_ev : forall n, evenb n = true -> ev n.
Proof.
  intros n H.
  induction n as [ | | n'] using nat_ind2.
  - (* n = 0 *) apply ev_0.
  - (* n = 1 *) simpl in H. inversion H.
  - (* n = S (S n') *) simpl in H. apply ev_SS.
    apply IHn'. exact H.
Qed.

(* ---------- 50.9 非标准原则实战：t_tree 的自定义归纳 ---------- *)

Inductive t_tree (X : Type) : Type :=
  | t_leaf
  | t_branch : (t_tree X * X * t_tree X) -> t_tree X.

Arguments t_leaf {X}.
Arguments t_branch {X}.

Check t_tree_ind.

Fixpoint reflect {X : Type} (t : t_tree X) : t_tree X :=
  match t with
  | t_leaf => t_leaf
  | t_branch (l, v, r) => t_branch (reflect r, v, reflect l)
  end.

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

End Ex50IndPrinciples.
