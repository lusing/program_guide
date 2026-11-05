(* 第 21 章 收官：Coq/Rocq 通道。
   三个三分之一加回 1。5 后面还有 6。
   两半加回 1。1 / (1 - 1/2) = 2。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma thirds : 1 / 3 + 1 / 3 + 1 / 3 = 1.
Proof.
  lra.
Qed.

Lemma past_five : 5 < 6.
Proof.
  lra.
Qed.

Lemma eps_split : 1 / 2 + 1 / 2 = 1.
Proof.
  lra.
Qed.

Lemma geometric_sum : 1 / (1 - 1 / 2) = 2.
Proof.
  lra.
Qed.
