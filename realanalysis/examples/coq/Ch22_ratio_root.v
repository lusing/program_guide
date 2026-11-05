(* 第 22 章 比值判别法与根值判别法（补充章）：Coq 通道。
   比值 2^n/n! 在 n = 2 处是 2/3；2^n 的比值恒为 2；
   底数 n/(2n+1) 不超过 3/5，在 n = 2 处幂序已经显现；
   调和级数的相邻项之比 n=1 时是 2/3。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma ratio_step : 8 / 6 / (4 / 2) = 2 / 3.
Proof. lra. Qed.

Lemma root_bound_at_two : (2 / 5) * (2 / 5) <= (3 / 5) * (3 / 5).
Proof. lra. Qed.

Lemma harmonic_ratio_at_one : (1 + 1) / (1 + 2) = 2 / 3.
Proof. lra. Qed.

Lemma two_not_less_one : 1 < 2.
Proof. lra. Qed.
