(* 第 13 章 完备集与连通集：Coq/Rocq 通道。
   1/2 落在被删掉的 (1/3, 2/3) 里；1/4 仍在 [0,1]；
   长度 1/2 大于第二步小区间的长度 1/9；0 夹在 -1 和 1 之间。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma half_in_middle_third : 1 / 3 < 1 / 2 /\ 1 / 2 < 2 / 3.
Proof.
  lra.
Qed.

Lemma quarter_in_unit : 0 <= 1 / 4 /\ 1 / 4 <= 1.
Proof.
  lra.
Qed.

(* 第二步每个小闭区间长 1/9，装不下长度为 1/2 的区间。 *)
Lemma half_longer_than_ninth : 1 / 9 < 1 / 2.
Proof.
  lra.
Qed.

(* 0 在 -1 与 1 之间，却不是任何一个开的半边的内点。 *)
Lemma zero_between : -1 < 0 /\ 0 < 1.
Proof.
  lra.
Qed.

Lemma zero_not_strict_side : ~ (0 < 0).
Proof.
  lra.
Qed.
