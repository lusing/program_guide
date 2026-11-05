(* 第 15 章 极限与子序列：Coq/Rocq 通道。
   和的误差就是 1/11，三倍仍小于 3/10，
   积与倒数靠近极限，偶次方是 +1、奇次方是 -1，下标 2<4<6。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma sum_shift : Rabs ((1 / 11 + 1) - 1) = 1 / 11.
Proof.
  replace ((1 / 11 + 1) - 1) with (1 / 11) by lra.
  rewrite Rabs_right; lra.
Qed.

Lemma scale_small : Rabs (3 * (1 / 11)) < 3 / 10.
Proof.
  rewrite Rabs_right; lra.
Qed.

Lemma product_gap : Rabs ((1 + 1 / 10) * (2 + 1 / 10) - 2) < 1 / 2.
Proof.
  rewrite Rabs_right; lra.
Qed.

Lemma reciprocal_gap : Rabs (1 / (1 + 1 / 10) - 1) = 1 / 11.
Proof.
  replace (1 / (1 + 1 / 10) - 1) with (- (1 / 11)) by lra.
  rewrite Rabs_left; lra.
Qed.

Lemma even_sign : (-1) * (-1) = 1.
Proof.
  lra.
Qed.

Lemma odd_sign : (-1) * (-1) * (-1) = -1.
Proof.
  lra.
Qed.

Lemma even_indices : 2 < 4 /\ 4 < 6.
Proof.
  lra.
Qed.

Lemma pair_second : Rabs (3 - 3) = 0.
Proof.
  replace (3 - 3) with 0 by lra.
  apply Rabs_R0.
Qed.
