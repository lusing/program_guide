(* 第 18 章 特殊序列：Coq/Rocq 通道。
   1/121 已经小于 1/10，并且仍小于 1/11，所以平方项夹在 0 和调和项之间。
   (1/2)^10 = 1/1024 小于 1/100。
   (3/2)*(3/2) 大于 1 + 2*(1/2)，这是二项式展开丢掉正项之后留下的不等式。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma eleven_square : 1 / 121 < 1 / 10.
Proof.
  lra.
Qed.

Lemma squeeze_slot : 0 < 1 / 121 /\ 1 / 121 < 1 / 11.
Proof.
  lra.
Qed.

Lemma half_ten : 1 / 1024 < 1 / 100.
Proof.
  lra.
Qed.

Lemma binomial_step : 1 + 2 * (1 / 2) < (3 / 2) * (3 / 2).
Proof.
  lra.
Qed.
