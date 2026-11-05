(* 第 14 章 序列与收敛：Coq/Rocq 通道。
   ε = 1/10 时 1/11 已经更小；20² 越过 100；
   交错项到 1 的距离等于 1/11；常数项到自己的距离是 0。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma inv_eleven_lt_inv_ten : 1 / 11 < 1 / 10.
Proof.
  lra.
Qed.

Lemma twenty_sq_past_hundred : 100 < 20 * 20.
Proof.
  lra.
Qed.

Lemma alternating_distance : Rabs ((1 + (-1) / 11) - 1) = 1 / 11.
Proof.
  replace ((1 + (-1) / 11) - 1) with (- (1 / 11)) by lra.
  rewrite Rabs_left; lra.
Qed.

Lemma constant_distance : Rabs (1 - 1) = 0.
Proof.
  replace (1 - 1) with 0 by lra.
  apply Rabs_R0.
Qed.
