(* 第 128 章 Coq：等价关系与划分的双向构造（书 2.3.8/2.3.9），
   外加 nat 上 ≤ 的偏序/线序判定（书 2.4）。

   为了避免商类型与函数外延性的机器负担，等价类以谓词呈现、
   划分以块列表呈现；两者之间的转换（类由划分诱导、块由类回收）
   全部可证。 *)

Require Import List Arith Lia.
Import ListNotations.

(* ---------- 一、等价类的两条基本引理（书 2.3.5） ---------- *)

Section Equivalence.
Variable A : Type.
Variable R : A -> A -> Prop.
Hypothesis Rrefl : forall x, R x x.
Hypothesis Rsym : forall x y, R x y -> R y x.
Hypothesis Rtrans : forall x y z, R x y -> R y z -> R x z.

Definition classOf (x : A) : A -> Prop := fun y => R x y.

(* 有关系则类相等 *)
Lemma classes_eq : forall x y, R x y ->
  forall z, classOf x z <-> classOf y z.
Proof.
  intros x y H z. unfold classOf. split; intros Hz.
  - apply (Rtrans y x z); [apply Rsym; exact H | exact Hz].
  - apply (Rtrans x y z); [exact H | exact Hz].
Qed.

(* 无关系则类不交 *)
Lemma classes_disjoint : forall x y, ~ R x y ->
  forall z, ~ (classOf x z /\ classOf y z).
Proof.
  intros x y H z [Hz1 Hz2]. apply H.
  apply (Rtrans x z y); [exact Hz1 | apply Rsym; exact Hz2].
Qed.

End Equivalence.

(* ---------- 二、划分诱导等价（书 2.3.9）与回收 ---------- *)

Section Partitions.
Variable A : Type.

(* 划分：两两不交（共享元素即同块）且覆盖 *)
Definition pairwise_disjoint (bl : list (list A)) : Prop :=
  forall B1 B2, In B1 bl -> In B2 bl ->
    forall x, In x B1 -> In x B2 -> B1 = B2.

Definition covers (bl : list (list A)) : Prop :=
  forall x, exists B, In B bl /\ In x B.

Definition Partition (bl : list (list A)) : Prop :=
  pairwise_disjoint bl /\ covers bl.

(* 书 2.3.9：由划分诱导的关系 *)
Definition relOf (bl : list (list A)) (x y : A) : Prop :=
  exists B, In B bl /\ In x B /\ In y B.

Lemma relOf_equiv : forall bl, Partition bl ->
  (forall x, relOf bl x x) /\
  (forall x y, relOf bl x y -> relOf bl y x) /\
  (forall x y z, relOf bl x y -> relOf bl y z -> relOf bl x z).
Proof.
  intros bl [HD HC]. unfold relOf in *. split; [| split].
  - intro x. destruct (HC x) as [B [HB Hx]]. exists B. auto.
  - intros x y [B [HB [Hx Hy]]]. exists B. auto.
  - intros x y z [B1 [H1 [Hx Hy]]] [B2 [H2 [Hy' Hz]]].
    assert (B1 = B2) by (eapply HD; eauto).
    subst B2. exists B1. auto.
Qed.

(* 每个块恰是某个元素的等价类（回收方向，书 2.3.9(1)） *)
Lemma block_eq_class : forall bl, Partition bl ->
  forall B x, In B bl -> In x B ->
    forall y, In y B <-> relOf bl x y.
Proof.
  intros bl [HD HC] B x HB Hx y. split.
  - intro Hy. exists B. auto.
  - intros [B' [HB' [Hx' Hy]]].
    assert (B = B') by (eapply HD; eauto).
    subst B'. assumption.
Qed.

End Partitions.

(* ---------- 三、nat 上 ≤ 是线序（书 2.4.1/2.4.3(1)） ---------- *)

Lemma nat_le_partial :
  (forall n, n <= n) /\
  (forall m n, m <= n -> n <= m -> m = n) /\
  (forall m n p, m <= n -> n <= p -> m <= p).
Proof.
  split; [| split]; intros; lia.
Qed.

Lemma nat_le_linear : forall m n, m <= n \/ n <= m.
Proof. intros; lia. Qed.
