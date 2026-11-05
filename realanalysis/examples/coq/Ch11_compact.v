(* 第 11 章 紧集：Coq/Rocq 通道。
   开区间没有有限子覆盖的那一步：1/8 在 (0,1) 里，却在 (1/4, 3/4) 的左边。
   N = 4 时，有限并的最右一项是 (1/4, 3/4)，端点附近的 1/8 漏在外面。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
Open Scope R_scope.

Lemma four_lt_eight : 4 < 8.
Proof. lra. Qed.

Lemma inv_pos_four : 0 < / 4.
Proof.
  apply Rinv_0_lt_compat. lra.
Qed.

Lemma inv_pos_eight : 0 < / 8.
Proof.
  apply Rinv_0_lt_compat. lra.
Qed.

(* 0 < 4 * 8，所以倒数反号：8 > 4 推出 1/8 < 1/4。 *)
Lemma eighth_lt_fourth : / 8 < / 4.
Proof.
  apply Rinv_lt_contravar.
  - assert (H4 : 0 < 4) by lra.
    assert (H8 : 0 < 8) by lra.
    apply Rmult_lt_0_compat; assumption.
  - exact four_lt_eight.
Qed.

(* 1/8 在 (0, 1) 里。1 = 1/1，所以仍是倒数的比较。 *)
Lemma eighth_in_unit : 0 < / 8 /\ / 8 < 1.
Proof.
  split.
  - exact inv_pos_eight.
  - rewrite <- Rinv_1.
    apply Rinv_lt_contravar.
    + assert (H1 : 0 < 1) by lra.
      assert (H8 : 0 < 8) by lra.
      apply Rmult_lt_0_compat; assumption.
    + lra.
Qed.

(* 1/8 不在 (1/4, 3/4) 里：它没有跨过左端点。 *)
Lemma eighth_not_in_inner : ~ (/ 4 < / 8).
Proof.
  intro H.
  apply (Rlt_asym (/ 8) (/ 4)).
  - exact eighth_lt_fourth.
  - exact H.
Qed.
