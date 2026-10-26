(* 36 关系、闭包与确定性 —— 关系 = 关于一对值的命题族；确定性 = 偏函数；闭包 = 多步化 *)

From Stdlib Require Import Arith Relations.

Module Ex51Relations.

(* ---------- 关系：关于一对值的命题族 ---------- *)

Definition relation (X : Type) := X -> X -> Prop.

Print le.

Check le : nat -> nat -> Prop.
Check le : relation nat.
Locate relation.

(* ---------- 偏函数：同一个输入不能有两个输出 ---------- *)

Definition partial_function {X : Type} (R : relation X) :=
  forall x y1 y2 : X, R x y1 -> R x y2 -> y1 = y2.

Inductive next_nat : nat -> nat -> Prop :=
  | nn (n : nat) : next_nat n (S n).

Check next_nat : relation nat.

Theorem next_nat_partial_function : partial_function next_nat.
Proof.
  unfold partial_function.
  intros x y1 y2 H1 H2.
  inversion H1. inversion H2.
  reflexivity.
Qed.

Theorem le_not_a_partial_function : ~ (partial_function le).
Proof.
  unfold not. unfold partial_function. intros Hc.
  assert (0 = 1) as Nonsense.
  { apply Hc with (x := 0).
    - apply le_n.
    - apply le_S. apply le_n. }
  discriminate Nonsense.
Qed.

Inductive total_relation : nat -> nat -> Prop :=
  | tr : forall n m : nat, total_relation n m.

Theorem total_relation_not_partial_function :
  ~ (partial_function total_relation).
Proof.
  unfold not. unfold partial_function. intros Hc.
  assert (0 = 1) as Nonsense.
  { apply Hc with (x := 0).
    - apply tr.
    - apply tr. }
  discriminate Nonsense.
Qed.

Inductive empty_relation : nat -> nat -> Prop :=.

Theorem empty_relation_partial_function :
  partial_function empty_relation.
Proof.
  unfold partial_function.
  intros x y1 y2 H1 H2.
  inversion H1.
Qed.

(* ---------- 自反与传递 ---------- *)

Definition reflexive {X : Type} (R : relation X) :=
  forall a : X, R a a.

Theorem le_reflexive : reflexive le.
Proof.
  unfold reflexive. intros n. apply le_n.
Qed.

Definition transitive {X : Type} (R : relation X) :=
  forall a b c : X, R a b -> R b c -> R a c.

Print le_ind.

Theorem le_trans : transitive le.
Proof.
  unfold transitive. intros n m o Hnm Hmo.
  induction Hmo.
  - apply Hnm.
  - apply le_S. apply IHHmo.
Qed.

Theorem lt_trans : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  apply le_S in Hnm.
  apply le_trans with (a := S n) (b := S m) (c := o).
  - apply Hnm.
  - apply Hmo.
Qed.

Theorem lt_trans' : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  induction Hmo.
  - apply le_S. apply Hnm.
  - apply le_S. exact IHHmo.
Qed.

Theorem lt_trans'' : transitive lt.
Proof.
  unfold lt. unfold transitive.
  intros n m o Hnm Hmo.
  revert Hmo. induction o as [| o' IH]; intro H.
  - inversion H.
  - inversion H; subst.
    + apply le_S. apply Hnm.
    + apply le_S. apply IH. assumption.
Qed.

(* ---------- 从传递性挤出三条小引理 ---------- *)

Theorem le_Sn_le : forall n m, S n <= m -> n <= m.
Proof.
  intros n m H. apply le_trans with (S n).
  - apply le_S. apply le_n.
  - apply H.
Qed.

Theorem le_S_n : forall n m, S n <= S m -> n <= m.
Proof.
  intros n m H. inversion H as [ | m' Hm' ].
  - apply le_n.
  - apply le_Sn_le. assumption.
Qed.

Theorem le_Sn_n : forall n, ~ (S n <= n).
Proof.
  intros n H. induction n as [| n' IH].
  - inversion H.
  - apply IH. apply le_S_n. exact H.
Qed.

Search (S _ <= S _ -> _ <= _).
Fail Check Nat.le_S_n.
Check Nat.nle_succ_diag_l.
Check Nat.le_trans.

(* ---------- 对称、反对称、等价与序 ---------- *)

Definition symmetric {X : Type} (R : relation X) :=
  forall a b : X, R a b -> R b a.

Theorem le_not_symmetric : ~ (symmetric le).
Proof.
  unfold not. unfold symmetric. intros Hc.
  assert (1 <= 0) as Nonsense.
  { apply Hc. apply le_S. apply le_n. }
  inversion Nonsense.
Qed.

Definition antisymmetric {X : Type} (R : relation X) :=
  forall a b : X, R a b -> R b a -> a = b.

Theorem le_antisymmetric : antisymmetric le.
Proof.
  unfold antisymmetric. intros n.
  induction n as [| n' IH]; intros m Hnm Hmn.
  - inversion Hmn. reflexivity.
  - destruct m as [| m'].
    + inversion Hnm.
    + f_equal. apply IH.
      * exact (le_S_n _ _ Hnm).
      * exact (le_S_n _ _ Hmn).
Qed.

Definition equivalence {X : Type} (R : relation X) :=
  (reflexive R) /\ (symmetric R) /\ (transitive R).

Definition order {X : Type} (R : relation X) :=
  (reflexive R) /\ (antisymmetric R) /\ (transitive R).

Definition preorder {X : Type} (R : relation X) :=
  (reflexive R) /\ (transitive R).

Locate reflexive.
Check Relation_Definitions.transitive.
Check Relation_Definitions.preorder.

Theorem le_order : order le.
Proof.
  unfold order. split.
  - apply le_reflexive.
  - split.
    + apply le_antisymmetric.
    + apply le_trans.
Qed.

Theorem le_preorder : preorder le.
Proof.
  unfold preorder. split.
  - apply le_reflexive.
  - apply le_trans.
Qed.

(* ---------- 自反传递闭包 ---------- *)

Print clos_refl_trans.
Print clos_refl_trans_1n.
Print clos_refl_trans_ind.
Search clos_refl_trans.

Fail Check (clos_refl_trans next_nat 2 5).
Check (clos_refl_trans nat next_nat 2 5).

Theorem next_nat_closure_is_le : forall n m,
  (n <= m) <-> (clos_refl_trans nat next_nat n m).
Proof.
  intros n m. split.
  - (* 把 <= 的证据拆成 next_nat 的若干步 *)
    intro H. induction H as [ | m' Hm' IH ].
    + apply rt_refl.
    + apply rt_trans with m'.
      * apply IH.
      * apply rt_step. apply nn.
  - (* 把闭包证据折回 <= *)
    intro H. induction H as [ x y Hxy | x | x y z Hxy IH1 Hyz IH2 ].
    + inversion Hxy. apply le_S. apply le_n.
    + apply le_n.
    + apply le_trans with y.
      * apply IH1.
      * apply IH2.
Qed.

Check rt1n_trans.
Check Relation_Operators.rt1n_trans.

Lemma rsc_R : forall (X : Type) (R : relation X) (x y : X),
  R x y -> clos_refl_trans_1n X R x y.
Proof.
  intros X R x y H.
  apply Relation_Operators.rt1n_trans with y.
  - apply H.
  - apply rt1n_refl.
Qed.

Lemma rsc_trans : forall (X : Type) (R : relation X) (x y z : X),
  clos_refl_trans_1n X R x y ->
  clos_refl_trans_1n X R y z ->
  clos_refl_trans_1n X R x z.
Proof.
  intros X R x y z H1.
  induction H1 as [ | x' y' z' Hx' Hy'z' IH ].
  - intro H2. exact H2.
  - intro H2. apply Relation_Operators.rt1n_trans with y'.
    + apply Hx'.
    + apply IH. exact H2.
Qed.

Theorem rtc_rsc_coincide : forall (X : Type) (R : relation X) (x y : X),
  clos_refl_trans X R x y <-> clos_refl_trans_1n X R x y.
Proof.
  intros X R x y. split.
  - intro H. induction H as [ | | x' y' z' H1 IH1 H2 IH2].
    + apply rsc_R. assumption.
    + apply rt1n_refl.
    + apply rsc_trans with y'.
      * apply IH1.
      * apply IH2.
  - intro H. induction H as [ | x' y' z' Hx' Hy'z' IH ].
    + apply rt_refl.
    + apply rt_trans with y'.
      * apply rt_step. exact Hx'.
      * exact IH.
Qed.

Example closure_of_next_nat_from_2_to_5 :
  clos_refl_trans_1n nat next_nat 2 5.
Proof.
  apply Relation_Operators.rt1n_trans with 3.
  - apply nn.
  - apply Relation_Operators.rt1n_trans with 4.
    + apply nn.
    + apply Relation_Operators.rt1n_trans with 5.
      * apply nn.
      * apply rt1n_refl.
Qed.

(* ---------- 正则闭包 star：多步语义的形状 ---------- *)

Inductive star {A : Type} (R : A -> A -> Prop) : A -> A -> Prop :=
  | nilr : forall x : A, star R x x
  | oner : forall x y : A, R x y -> star R x y
  | comp : forall x y z : A,
      star R x y -> star R y z -> star R x z.

Print star.

Lemma star_rt_same : forall (X : Type) (R : relation X) (x y : X),
  star R x y -> clos_refl_trans X R x y.
Proof.
  intros X R x y H. induction H as [ | | x' y' z' H1 IH1 H2 IH2].
  - apply rt_refl.
  - apply rt_step. assumption.
  - apply rt_trans with (y := y').
    + apply IH1.
    + apply IH2.
Qed.

End Ex51Relations.
