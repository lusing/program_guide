(* 第 20 章 总结：Coq/Rocq 通道。
   5 后面还有 6。|3 + (-1)| = 2，不超过 3 + 1。
   两半误差加回去是 1。丢掉正项后 (3/2)*(3/2) 仍大于 2。
   1 / (1/2) = 2，这是公比 1/2 的几何级数之和。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma past_five : 5 < 6.
Proof.
  lra.
Qed.

Lemma triangle_numbers : 2 <= 3 + 1.
Proof.
  lra.
Qed.

Lemma eps_split : 1 / 2 + 1 / 2 = 1.
Proof.
  lra.
Qed.

Lemma binomial_drop : 1 + 2 * (1 / 2) < (3 / 2) * (3 / 2).
Proof.
  lra.
Qed.

Lemma geometric_sum : 1 / (1 - 1 / 2) = 2.
Proof.
  lra.
Qed.
