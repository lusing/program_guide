(* 第 97 章：有限直接系统与直接极限商。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch97.

(* 直接系统：索引 0≤1≤2 定向；三层有限集合与相容映射。 *)
Definition M0 := list nat.
Definition M1 := list nat.
Definition M2 := list nat.

(* 相容映射 e_{0,1}：按模 2 归并；e_{1,2}：按模 3 归并。 *)
Definition e01 (x : nat) : nat := x mod 2.
Definition e12 (x : nat) : nat := x mod 3.

(* 复合 e_{0,2} = e_{1,2} ∘ e_{0,1}：交换图的实现。 *)
Definition e02 (x : nat) : nat := e12 (e01 x).

(* 交换律：直接系统的定义公理 j_{β,δ} = j_{γ,δ} ∘ j_{β,γ}。 *)
Lemma commute : forall x, e02 x = e12 (e01 x).
Proof. reflexivity. Qed.

(* A = {(i, x)} 等价：(i,x) ~ (k,y) ⟺ 在共同延伸 l 处像相等。 *)
Definition push (i x : nat) : nat :=
  match i with
  | 0 => e02 x
  | 1 => e12 x
  | 2 => x mod 1
  | _ => 0
  end.

Definition dleq (i x j y : nat) : bool :=
  Nat.eqb (push i x) (push j y).

(* 等价关系三律（有限系统上的可判定版本）。 *)
Lemma dleq_refl : forall i x, dleq i x i x = true.
Proof. intros. apply Nat.eqb_refl. Qed.

Lemma dleq_sym : forall i x j y, dleq i x j y = true -> dleq j y i x = true.
Proof.
  intros i x j y H. unfold dleq in *.
  apply Nat.eqb_eq in H. apply Nat.eqb_eq. symmetry. exact H.
Qed.

Lemma dleq_trans : forall i x j y k z,
  dleq i x j y = true -> dleq j y k z = true -> dleq i x k z = true.
Proof.
  intros i x j y k z H1 H2. unfold dleq in *.
  apply Nat.eqb_eq in H1. apply Nat.eqb_eq in H2.
  apply Nat.eqb_eq. rewrite H1. exact H2.
Qed.

(* 临界点表：j(x)=x+1 的迭代轨迹严格递增。 *)
Fixpoint jiter (n x : nat) : nat :=
  match n with
  | 0 => x
  | S k => S (jiter k x)
  end.

Lemma traj_strict : forall n x, x < jiter (S n) x.
Proof.
  induction n; intros x.
  - simpl. lia.
  - simpl. assert (H := IHn x). simpl in H. lia.
Qed.

Lemma traj_decompose : forall m n x, jiter (m + n) x = jiter m (jiter n x).
Proof.
  induction m; intros n x.
  - reflexivity.
  - simpl. rewrite IHm. reflexivity.
Qed.

End Ch97.
