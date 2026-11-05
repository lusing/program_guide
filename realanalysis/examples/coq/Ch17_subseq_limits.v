(* 第 17 章 子序列极限：Coq/Rocq 通道。
   4² 已经超过 10，-5*4 低于 -10，
   (-1)^n 的偶次是 1、奇次是 -1，偶数项 2,4,6 给出 4,8,12。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma four_sq : 4 * 4 > 10.
Proof.
  lra.
Qed.

Lemma neg_five_past : -5 * 4 < -10.
Proof.
  lra.
Qed.

Lemma even_sign : (-1) * (-1) = 1.
Proof.
  lra.
Qed.

Lemma odd_sign : (-1) * (-1) * (-1) = -1.
Proof.
  lra.
Qed.

Lemma alt_stays_small : Rabs ((-1) * (-1)) < 10.
Proof.
  replace ((-1) * (-1)) with 1 by lra.
  rewrite Rabs_right; lra.
Qed.

Lemma spike_even : (1 + 1) * 2 = 4 /\ (1 + 1) * 4 = 8 /\ (1 + 1) * 6 = 12.
Proof.
  lra.
Qed.

Lemma spike_odd : ((-1) + 1) * 1 = 0.
Proof.
  lra.
Qed.
