(* 第 12 章 海涅–博雷尔定理：Coq/Rocq 通道。
   左端点的候选 1 仍不超过右端点 1+1/2；
   三次对分之后，长度 1/8 已经小于半径 1/2；
   2 不在 [0,1] 里。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma inv_pos_two : 0 < / 2.
Proof.
  apply Rinv_0_lt_compat. lra.
Qed.

Lemma inv_pos_eight : 0 < / 8.
Proof.
  apply Rinv_0_lt_compat. lra.
Qed.

(* 定理 12.1 的一个数：1 是左端点列的上界候选，它仍 ≤ 1 + 1/2。 *)
Lemma one_inside_expanded : 0 <= 1 /\ 1 <= 1 + / 2.
Proof.
  split.
  - lra.
  - assert (H : 0 < / 2) by exact inv_pos_two.
    lra.
Qed.

(* 三次对分：区间长度从 1 变成 1/8，小于半径 1/2。 *)
Lemma eighth_lt_half : / 8 < / 2.
Proof.
  apply Rinv_lt_contravar.
  - assert (H2 : 0 < 2) by lra.
    assert (H8 : 0 < 8) by lra.
    apply Rmult_lt_0_compat; assumption.
  - lra.
Qed.

(* 2 不在闭区间 [0,1] 里。有界是相对某个格子而言的。 *)
Lemma two_outside_unit : ~ (0 <= 2 /\ 2 <= 1).
Proof.
  lra.
Qed.
