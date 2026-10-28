(* 第 80 章：有理 Dedekind 下截断的加法、相反数与 √2 样本。 *)
From Coq Require Import QArith Lqa.

Module Ch80.

Definition qcut (a : Q) : Q -> Prop := fun q => (q < a)%Q.

Definition cadd (A B : Q -> Prop) (q : Q) : Prop :=
  exists x y, A x /\ B y /\ (q == x + y)%Q.

(* 统一的相反数下截断：s 在补集，q 严格小于 -s。
   严格量词同时处理有理截断，避免补集最小元变成 -A 的最大元。 *)
Definition cneg (A : Q -> Prop) (q : Q) : Prop :=
  exists s, ~ A s /\ (q < -s)%Q.

Lemma cadd_q : forall a b q,
  cadd (qcut a) (qcut b) q <-> qcut (a + b) q.
Proof.
  intros a b q. unfold cadd, qcut. split.
  - intros [x [y [Hx [Hy Hq]]]]. lra.
  - intro H.
    exists (a - (1#2) * (a + b - q)),
           (b - (1#2) * (a + b - q)).
    repeat split; lra.
Qed.

Lemma cneg_q : forall a q, cneg (qcut a) q <-> qcut (-a) q.
Proof.
  intros a q. unfold cneg, qcut. split.
  - intros [s [Hs Hq]]. lra.
  - intro H. exists a. lra.
Qed.

Definition sqrt2cut (q : Q) : Prop :=
  (q < 0)%Q \/ (0 <= q)%Q /\ (q * q < 2)%Q.

Example cadd_sample : cadd (qcut (1#2)) (qcut (1#3)) (3#4).
Proof. apply (proj2 (cadd_q _ _ _)). now compute. Qed.

Example cneg_sample : cneg (qcut (3#2)) (-2#1).
Proof. apply (proj2 (cneg_q _ _)). now compute. Qed.

Example sqrt2_inside : sqrt2cut (7#5).
Proof. unfold sqrt2cut. right. split; now compute. Qed.

Example sqrt2_outside : ~ sqrt2cut (3#2).
Proof. unfold sqrt2cut. intros [H | [H0 H2]]; now compute. Qed.

End Ch80.
