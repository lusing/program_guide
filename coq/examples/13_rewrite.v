(* 13 重写、化简与分情况 —— rewrite 的方向、destruct、discriminate、injection *)

From Stdlib Require Import Arith List.
Import ListNotations.

Module Ex13Rewrite.

(* ---------- rewrite：用等式替换 ---------- *)

Check Nat.add_0_r.
(* Nat.add_0_r : forall n : nat, n + 0 = n
   —— 标准库版的 plus_n_O，方向「复合项 = 简单项」 *)

Theorem plus_0_0 : forall n : nat, (n + 0) + 0 = n.
Proof.
  intros n.
  rewrite Nat.add_0_r.   (* 找到 n + 0，替换为 n，目标变 n + 0 = n *)
  rewrite Nat.add_0_r.   (* 再来一次 *)
  reflexivity.
Qed.

(* 方向与「哪一侧好匹配」：
   rewrite H 把 H 左边换成右边；rewrite <- H 反向。
   经验法则——让「要找的那一侧」是复合模式（如 n + 0），
   匹配就唯一、行为可预期；若一侧是裸变量（如标准库的
   plus_n_O : n = n + 0，左边只有 n），正向 rewrite 行为微妙
   （可能到处塞 n + 0 或原地不动），此时应反向用：
   rewrite <- plus_n_O 去找 n + 0 才是干净的方向。 *)

(* rewrite 还能改进假设（in H）： *)
Theorem rw_in : forall n m : nat, n + 0 = m -> n = m.
Proof.
  intros n m H.
  rewrite Nat.add_0_r in H.   (* 假设 H 里的 n + 0 换成 n *)
  exact H.                    (* H : n = m，正好是目标 *)
Qed.

(* ---------- simpl：按定义展开 ---------- *)

Example simpl_ex : forall n : nat, 0 + n = n.
Proof.
  intros n. simpl.   (* 0 + n 按 Nat.add 定义直接就是 n *)
  reflexivity.
Qed.

(* simpl 只做「按定义能算的」，不做数学推理——
   n + 0 它就动不了（因为 + 在第一个参数上递归），
   这正是 plus_n_O 需要归纳的原因。 *)

(* ---------- destruct：分情况讨论 ---------- *)

Theorem andb_false : forall b : bool, andb b false = false.
Proof.
  intros b. destruct b.
  - reflexivity.
  - reflexivity.
Qed.

Theorem negb_involutive : forall b : bool, negb (negb b) = b.
Proof.
  intros b. destruct b.
  - reflexivity.
  - reflexivity.
Qed.

(* destruct n（nat）裂成 0 / S k 两种情况；不带 IH（不递归）。
   「要枚举不要递归」时用 destruct，要归纳假设时用 induction。 *)

(* ---------- symmetry / transitivity：调整等式的姿态 ---------- *)

Theorem sym_ex : forall n m : nat, n = m -> m = n.
Proof.
  intros n m H. symmetry. exact H.
Qed.

Example chain_ex : 2 + 2 = 4.
Proof.
  transitivity (3 + 1).
  - reflexivity.
  - reflexivity.
Qed.

(* ---------- discriminate：不同构造子永不相等 ---------- *)

Theorem zero_neq_one : 0 <> 1.
Proof.
  intros H.   (* <> 展开是 0 = 1 -> False *)
  discriminate H.
Qed.

Theorem nil_neq_cons : forall (A : Type) (x : A) (xs : list A),
  [] <> x :: xs.
Proof.
  intros A x xs H. discriminate H.
Qed.

(* ---------- injection：同构造子则分量相等 ---------- *)

Theorem inj_ex : forall n m : nat, S n = S m -> n = m.
Proof.
  intros n m H.
  injection H as H2.   (* 从 S n = S m 提取 n = m *)
  exact H2.
Qed.

(* ---------- apply：按结论调用定理 ---------- *)

Theorem apply_ex : forall n : nat, n + 0 = n.
Proof.
  intros n. apply Nat.add_0_r.
Qed.

(* 若目标与定理方向相反，先 symmetry 转身再 apply：
Theorem apply_flip : forall n : nat, n = n + 0.
Proof. intros n. symmetry. apply Nat.add_0_r. Qed. *)

End Ex13Rewrite.
