(* 第 10 章 闭集和开集：Coq/Rocq 通道。
   德摩根律是“开集的补是闭集”在命题层的样子；
   有限交要取最小半径；无限族用具体数值看它为什么会坏。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Classical_Prop.
Open Scope R_scope.

(* 并的补是补的交：不需要排中律。 *)
Lemma demorgan_or (P Q : Prop) : ~ (P \/ Q) <-> ~ P /\ ~ Q.
Proof.
  split.
  - intros H. split; intro HPQ; apply H; [left | right]; exact HPQ.
  - intros [HnP HnQ] [HP | HQ]; [apply HnP | apply HnQ]; assumption.
Qed.

(* 交的补是补的并：从左到右用一次排中律，对应“闭集的补是开集”那一侧。 *)
Lemma demorgan_and (P Q : Prop) : ~ (P /\ Q) <-> ~ P \/ ~ Q.
Proof.
  split.
  - intros H.
    destruct (classic P) as [HP | HnP].
    + right. intro HQ. apply H. split; assumption.
    + left. exact HnP.
  - intros [HnP | HnQ] [HP HQ]; [apply HnP | apply HnQ]; assumption.
Qed.

(* 补集做两次回到原命题。 *)
Lemma compl_involutive (P : Prop) : ~ ~ P <-> P.
Proof.
  split.
  - apply NNPP.
  - intros HP HnP. apply HnP. exact HP.
Qed.

(* 定理 10.4 的半径：比最小半径还近，就同时落进两个邻域。 *)
Lemma min_radius (r1 r2 x : R) :
  Rabs x < Rmin r1 r2 -> Rabs x < r1 /\ Rabs x < r2.
Proof.
  intro H.
  split.
  - apply Rlt_le_trans with (Rmin r1 r2); [exact H | apply Rmin_l].
  - apply Rlt_le_trans with (Rmin r1 r2); [exact H | apply Rmin_r].
Qed.

(* 0 在 (-1, 1) 里，1 不在。单点会被无限交留下来，端点不会。 *)
Lemma zero_inside : -1 < 0 /\ 0 < 1.
Proof. split; lra. Qed.

Lemma one_not_inside : ~ (1 < 1).
Proof. apply Rlt_irrefl. Qed.

(* 2 不在 [0, 1] 里，所以不在任何 [0, 2-1] 这种更短的闭区间里。 *)
Lemma two_not_in_short : ~ (2 <= 1).
Proof. lra. Qed.

(* 1 在 [0, 2-1] 里，说明并集吃得进 2 左边的点。 *)
Lemma one_in_short : 0 <= 1 /\ 1 <= 2 - 1.
Proof. split; lra. Qed.

(* 闭包的数值影子：2 在 (-3, 3) 里，并且离缺掉的端点 3 的距离是 1。 *)
Lemma approach_endpoint : -3 < 2 /\ 2 < 3 /\ Rabs (3 - 2) = 1.
Proof.
  split; [lra | split; [lra |]].
  replace (3 - 2) with 1 by lra.
  rewrite Rabs_pos_eq; lra.
Qed.
