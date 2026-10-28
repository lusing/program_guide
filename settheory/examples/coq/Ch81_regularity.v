(* 第 81 章：有限布尔理想与实数模有理数等价关系。 *)
From Coq Require Import QArith Qreals Reals Lra.

Module Ch81.

Definition subset := bool -> Prop.
Definition empty : subset := fun _ => False.
Definition union (A B : subset) : subset := fun x => A x \/ B x.
Definition inter (A B : subset) : subset := fun x => A x /\ B x.

Record Ideal (I : subset -> Prop) : Prop := {
  ideal_empty : I empty;
  ideal_down : forall A B, I A -> (forall x, B x -> A x) -> I B;
  ideal_union : forall A B, I A -> I B -> I (union A B)
}.

(* 理想对交也封闭：交只是任一成员的子集，不需要另加一条公理。 *)
Theorem ideal_inter : forall I (H : Ideal I) A B,
  I A -> I B -> I (inter A B).
Proof.
  intros I H A B HA HB.
  apply (ideal_down I H A); auto.
  intros x Hx. exact (proj1 Hx).
Qed.

Open Scope R_scope.

Definition qmod (x y : R) : Prop := exists q : Q, x - y = Q2R q.

Lemma qmod_refl : forall x, qmod x x.
Proof.
  intro x. exists 0%Q. unfold Q2R. cbn. ring.
Qed.

Lemma qmod_sym : forall x y, qmod x y -> qmod y x.
Proof.
  intros x y [q Hq]. exists (-q)%Q.
  rewrite Q2R_opp. lra.
Qed.

Lemma qmod_trans : forall x y z, qmod x y -> qmod y z -> qmod x z.
Proof.
  intros x y z [q Hq] [r Hr]. exists (q+r)%Q.
  rewrite Q2R_plus. lra.
Qed.

(* 离散样本：4/3 与 1/3 模 Q 同余，差恰为有理数 1。 *)
Example qmod_sample : qmod (Q2R (4#3)) (Q2R (1#3)).
Proof. exists 1%Q. unfold Q2R. cbn. field. Qed.

End Ch81.
