(* 第 19 章 级数：Coq/Rocq 通道。
   几何部分和 1 + 1/2 + 1/4 = 7/4，闭式同样是 7/4。
   (2/3)/(1 - 2/3) = 2。
   调和前四项大于 2；把 1/3 换成 1/4 之后刚好等于 2。
   常数项 1 并不小于 1/2，所以不能当通项趋于 0。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma half_partial : 1 + 1 / 2 + 1 / 4 = 7 / 4.
Proof.
  lra.
Qed.

Lemma half_closed : (1 - 1 / 8) / (1 / 2) = 7 / 4.
Proof.
  lra.
Qed.

Lemma two_thirds : (2 / 3) / (1 - 2 / 3) = 2.
Proof.
  lra.
Qed.

Lemma harmonic_group : 1 + 1 / 2 + 1 / 4 + 1 / 4 = 2.
Proof.
  lra.
Qed.

Lemma harmonic_four : 1 + 1 / 2 + 1 / 3 + 1 / 4 > 2.
Proof.
  lra.
Qed.

Lemma one_not_small : 1 > 1 / 2.
Proof.
  lra.
Qed.
