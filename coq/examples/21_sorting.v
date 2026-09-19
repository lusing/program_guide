(* 21 插入排序与正确性证明 —— 函数、有序性、重排性三合一 *)

From Coq Require Import List Arith Sorting.Permutation.
Import ListNotations.

Module Ex21Sorting.

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: ys => if Nat.leb x y then x :: y :: ys else y :: insert x ys
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (sort xs)
  end.

Compute (sort [3; 1; 4; 1; 5; 9; 2; 6]).
(* = [1; 1; 2; 3; 4; 5; 6; 9] —— 能跑；本章要证它对 *)

(* ---------- 什么是「排好序」——自己定义，自己证明 ---------- *)

(* le_all x l ：x <= l 中的每个元素 *)

Fixpoint le_all (x : nat) (l : list nat) : Prop :=
  match l with
  | [] => True
  | y :: tl => x <= y /\ le_all x tl
  end.

Fixpoint sorted (l : list nat) : Prop :=
  match l with
  | [] => True
  | x :: tl => le_all x tl /\ sorted tl
  end.

(* 引理 1：<= 的传递性可以穿透 le_all *)
Lemma le_all_le : forall (x y : nat) (l : list nat),
  x <= y -> le_all y l -> le_all x l.
Proof.
  intros x y l Hxy H. induction l as [| z zs IH].
  - simpl. exact I.
  - simpl in *. destruct H as [Hyz Hrest]. split.
    + apply (Nat.le_trans x y z Hxy Hyz).
    + apply IH. exact Hrest.
Qed.

(* 引理 2：比 y 大的元素插进列表，不破坏 y 对全表的优势 *)
Lemma le_all_insert_lt : forall (x y : nat) (l : list nat),
  y < x -> le_all y l -> le_all y (insert x l).
Proof.
  intros x y l Hyx H. induction l as [| z zs IH].
  - simpl. simpl in H. split. apply Nat.lt_le_incl. exact Hyx. exact I.
  - simpl in *. simpl. destruct (Nat.leb x z) eqn:E.
    + apply Nat.leb_le in E. simpl in H. destruct H as [Hyz Hrest].
      split. apply Nat.lt_le_incl. exact Hyx. split. exact Hyz. exact Hrest.
    + simpl in H. destruct H as [Hyz Hrest]. split.
      * exact Hyz.
      * apply IH. exact Hrest.
Qed.

(* ---------- 正确性之一：插入保序 ---------- *)

Theorem insert_sorted : forall (x : nat) (l : list nat),
  sorted l -> sorted (insert x l).
Proof.
  intros x l H. induction l as [| y ys IH].
  - simpl in *. simpl. split. exact I. exact I.
  - simpl in *. destruct H as [Hle Hsorted]. simpl.
    destruct (Nat.leb x y) eqn:E.
    + apply Nat.leb_le in E. split.
      * split. exact E. apply le_all_le with y. exact E. exact Hle.
      * split. exact Hle. exact Hsorted.
    + apply Nat.leb_gt in E. split.
      * apply le_all_insert_lt. exact E. exact Hle.
      * apply IH. exact Hsorted.
Qed.

(* ---------- 正确性之二：插入是重排 ---------- *)

Theorem insert_perm : forall (x : nat) (l : list nat),
  Permutation (x :: l) (insert x l).
Proof.
  intros x l. induction l as [| y ys IH].
  - simpl. apply Permutation_refl.
  - simpl. destruct (Nat.leb x y) eqn:E.
    + apply Permutation_refl.
    + apply Permutation_trans with (y :: x :: ys).
      * apply perm_swap.
      * apply perm_skip. exact IH.
Qed.

(* ---------- 合成：sort 的双重正确性 ---------- *)

Theorem sort_sorted : forall l : list nat, sorted (sort l).
Proof.
  induction l as [| x xs IH].
  - simpl. exact I.
  - simpl. apply insert_sorted. exact IH.
Qed.

Theorem sort_perm : forall l : list nat, Permutation l (sort l).
Proof.
  induction l as [| x xs IH].
  - apply Permutation_refl.
  - simpl. apply Permutation_trans with (x :: sort xs).
    + apply perm_skip. exact IH.
    + apply insert_perm.
Qed.

(* 「排序正确」= 结果有序 + 结果是输入的重排。
   两者合体，机器盖章。*)

Theorem sort_correct : forall l : list nat,
  sorted (sort l) /\ Permutation l (sort l).
Proof.
  intros l. split.
  - apply sort_sorted.
  - apply sort_perm.
Qed.

(* Permutation 来自标准库 Sorting.Permutation，它自带
   perm_skip / perm_swap / Permutation_trans 等装配零件。 *)

End Ex21Sorting.
