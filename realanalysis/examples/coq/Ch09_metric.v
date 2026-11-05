(* 第 09 章 拓扑定义：Coq/Rocq 通道。
   实数距离 |x-y| 的三公理、开球成员、[-3,3] 有界的具体估计。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Ring.
Open Scope R_scope.

Definition d (p q : R) : R := Rabs (p - q).

Lemma d_self (p : R) : d p p = 0.
Proof. unfold d. replace (p - p) with 0 by lra. apply Rabs_R0. Qed.

Lemma d_sym (p q : R) : d p q = d q p.
Proof. unfold d. replace (p - q) with (- (q - p)) by lra. apply Rabs_Ropp. Qed.

Lemma d_triangle (p q r : R) : d p q <= d p r + d r q.
Proof.
  unfold d.
  assert (EQ : (p - r) + (r - q) = p - q).
  { unfold Rminus.
    rewrite Rplus_assoc.
    rewrite <- (Rplus_assoc (- r) r (- q)).
    rewrite Rplus_opp_l.
    rewrite Rplus_0_l.
    reflexivity. }
  rewrite <- EQ.
  apply Rabs_triang.
Qed.

(* 邻域：|x| < 3 当且仅当 -3 < x < 3。端点 3 不在里面。 *)
Lemma in_ball_sample : d 0 2 < 3.
Proof.
  unfold d, Rminus.
  rewrite Rplus_0_l.
  rewrite Rabs_Ropp.
  rewrite Rabs_pos_eq; lra.
Qed.

Lemma endpoint_out : ~ d 0 3 < 3.
Proof.
  unfold d, Rminus.
  rewrite Rplus_0_l.
  rewrite Rabs_Ropp.
  rewrite Rabs_pos_eq.
  - apply Rlt_irrefl.
  - lra.
Qed.

Lemma bounded_sample (p : R) : -3 <= p -> p <= 3 -> d p 0 <= 3.
Proof.
  intros H1 H2.
  unfold d.
  rewrite Rminus_0_r.
  apply Rabs_le.
  split; assumption.
Qed.
