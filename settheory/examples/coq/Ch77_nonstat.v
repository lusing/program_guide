(* 第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）——Coq 通道 *)
(* 三个真定理：对角线交/并的德摩根对偶、有限正规性（顶点模型）、
   例 2.11 尾集族之交为空。都不是模拟，而是 nat 上可机器检验的命题。 *)
From Coq Require Import Bool List Arith Lia.
Import ListNotations.

Module Ch77.

(* ---------- 对角线交 / 并的成员判定 ---------- *)
(* inDiagInt C i：位置 i 落在对角线交 ΔC 里，即 ∀j<i, i∈C_j（成员用 C j i = true）。
   inDiagUn X i：位置 i 落在对角线并 ∇X 里，即 ∃j<i, i∈X_j。 *)
Definition inDiagInt (C : nat -> nat -> bool) (i : nat) : Prop :=
  forall j, j < i -> C j i = true.

Definition inDiagUn (X : nat -> nat -> bool) (i : nat) : Prop :=
  exists j, j < i /\ X j i = true.

(* 德摩根对偶（推论 2.3 的补集恒等式）：κ∖ΔC = ∇(κ∖C)。逐位置读作
   i ∈ ΔC ⟺ ¬(∃j<i, i ∉ C_j)。补集用 fun j k => negb (C j k) 表达。 *)
Theorem diag_demorgan : forall C i,
  inDiagInt C i <-> ~ inDiagUn (fun j k => negb (C j k)) i.
Proof.
  intros C i. split.
  - intros H [j [Hj Hneg]].
    specialize (H j Hj). simpl in Hneg. rewrite H in Hneg. discriminate.
  - intros H j Hj.
    destruct (C j i) eqn:E; [reflexivity|].
    exfalso. apply H. exists j. split; [exact Hj|].
    simpl. rewrite E. reflexivity.
Qed.

(* ---------- 有限正规性（定理 2.24 在有限截断上的缩影） ---------- *)
(* 有限序数模型 n 里，「club = 含顶点 n−1」；若每个 C_j 都含顶点，则对角线交
   也含顶点——因为顶点 n−1 的成员条件恰是 ∀j<n−1, C j (n−1) = true。 *)
Theorem diag_top : forall n C,
  0 < n -> (forall j, j < n - 1 -> C j (n - 1) = true) ->
  inDiagInt C (n - 1).
Proof.
  intros n C Hpos Htop. exact Htop.
Qed.

(* ---------- 例 2.11：ω 上尾集族 C_k={i>k} 之交为空 ---------- *)
(* inTail k i 表 i∈C_k，即 i>k（用 ¬(i≤k) 表达）。全体之交为空 = 每个 i 都被
   某个 C_k 甩掉，逃逸点取 k=i（因 ¬(i>i)）。 *)
Definition inTail (k i : nat) : bool := negb (leb i k).

Theorem tail_clubs_empty_inter : forall i, exists k, inTail k i = false.
Proof.
  intros i. exists i. unfold inTail. rewrite Nat.leb_refl. reflexivity.
Qed.

(* 每个尾集在窗口内确无界：i>k 对足够大的 i 成立（取 i=k+1）。 *)
Theorem tail_unbounded : forall k, exists i, inTail k i = true.
Proof.
  intros k. exists (S k). unfold inTail.
  apply negb_true_iff. rewrite Nat.leb_gt. lia.
Qed.

End Ch77.
