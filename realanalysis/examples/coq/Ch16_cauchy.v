(* 第 16 章 柯西序列与单调序列：Coq/Rocq 通道。
   第 11、12 项的距离小于 1/10，三点集与区间的跨度，
   调和序列递减，1-1/(n+1) 递增并且到 1 的距离是 1/11。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma eleven_twelve : Rabs (1 / 11 - 1 / 12) < 1 / 10.
Proof.
  replace (1 / 11 - 1 / 12) with (1 / 132) by lra.
  rewrite Rabs_right; lra.
Qed.

Lemma three_point_span : Rabs (3 - 1) = 2.
Proof.
  replace (3 - 1) with 2 by lra.
  rewrite Rabs_right; lra.
Qed.

Lemma interval_span : Rabs (3 - (-3)) = 6.
Proof.
  replace (3 - (-3)) with 6 by lra.
  rewrite Rabs_right; lra.
Qed.

Lemma harmonic_decreases : 1 / 12 < 1 / 11.
Proof.
  lra.
Qed.

Lemma approach_increases : 1 - 1 / 11 < 1 - 1 / 12.
Proof.
  lra.
Qed.

Lemma trunc_gap : Rabs (141 / 100 - 1414 / 1000) < 1 / 100.
Proof.
  replace (141 / 100 - 1414 / 1000) with (- (1 / 250)) by lra.
  rewrite Rabs_left; lra.
Qed.

Lemma approach_gap : Rabs ((1 - 1 / 11) - 1) = 1 / 11.
Proof.
  replace ((1 - 1 / 11) - 1) with (- (1 / 11)) by lra.
  rewrite Rabs_left; lra.
Qed.
