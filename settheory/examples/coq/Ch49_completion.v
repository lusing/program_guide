(** 第 49 章：3 元链的 RO 补全（决定性验证）

    链 {0 < 1 < 2}：任何两条件相容（链无分叉）——补全坍缩为
    2 元布尔代数。这是稠密像唯一性定理的边界现场：链太"细"，
    正则化把一切非空下闭集缝成全集；j 非单射（非分离偏序）。 *)

Require Import List Arith Lia.
Import ListNotations.

Definition P3 : list nat := [0; 1; 2].

(* ---- 基础工具（独立定义，无 mutual） ---- *)
Fixpoint inb (x : nat) (l : list nat) : bool :=
  match l with
  | nil => false
  | y :: t => if Nat.eq_dec x y then true else inb x t
  end.

Fixpoint dedup (l : list nat) : list nat :=
  match l with
  | nil => nil
  | x :: t => if inb x t then dedup t else x :: dedup t
  end.

Fixpoint inserts (x : nat) (l : list nat) : list nat :=
  match l with
  | nil => [x]
  | y :: t => if Nat.leb x y then x :: y :: t else y :: inserts x t
  end.

Fixpoint isort (l : list nat) : list nat :=
  match l with
  | nil => nil
  | y :: t => inserts y (isort t)
  end.

Definition norm (l : list nat) : list nat := isort (dedup l).

Definition interl (A B : list nat) : list nat :=
  norm (filter (fun x => inb x A) B).

Definition unionl (A B : list nat) : list nat :=
  norm (filter (fun x => negb (inb x A)) B ++ A).

Definition compl3 (S : list nat) : list nat :=
  norm (filter (fun x => negb (inb x S)) P3).

Definition inclb (A B : list nat) : bool :=
  forallb (fun x => inb x B) A.

(* ---- 序与序拓扑 ---- *)
Definition le3 (x y : nat) : bool :=
  if Nat.eq_dec x 0 then true else Nat.leb x y.

Definition down3 (p : nat) : list nat :=
  filter (fun q => le3 q p) P3.

Definition downclosed (S : list nat) : bool :=
  forallb (fun p => inclb (down3 p) S) S.

Definition subsets3 : list (list nat) :=
  [ nil; [0]; [1]; [2]; [0;1]; [0;2]; [1;2]; [0;1;2] ].

Definition opens3 : list (list nat) :=
  filter downclosed subsets3.

(* ---- 闭包 / 内部 / 正则化 ---- *)
Definition closedsets3 : list (list nat) :=
  map compl3 opens3.

Definition big_inter (L : list (list nat)) : list nat :=
  fold_right interl P3 L.

Definition big_union (L : list (list nat)) : list nat :=
  fold_right unionl nil L.

Definition cl3 (U : list nat) : list nat :=
  big_inter (filter (fun C => inclb U C) closedsets3).

Definition int3 (U : list nat) : list nat :=
  big_union (filter (fun O => inclb O U) opens3).

Definition reg3 (U : list nat) : list nat := int3 (cl3 U).

Definition j3 (p : nat) : list nat := reg3 (down3 p).

(* ---- 决定性断言 ---- *)

(* 开集恰为 4 个下闭集：∅ {0} {0,1} {0,1,2} *)
Lemma opens3_val : length opens3 = 4.
Proof. vm_compute. reflexivity. Qed.

Lemma opens3_list : opens3 = [nil;[0];[0;1];[0;1;2]].
Proof. vm_compute. reflexivity. Qed.

(* j(0) = j(1) = j(2) = 全集——补全坍缩，j 非单射 *)
Lemma j3_collapse :
  j3 0 = [0;1;2] /\ j3 1 = [0;1;2] /\ j3 2 = [0;1;2].
Proof. repeat split; vm_compute; reflexivity. Qed.

(* RO 全体 = {∅, 全集}：2 元布尔代数 *)
Lemma ro3_two : forall O, In O opens3 -> reg3 O = nil \/ reg3 O = [0;1;2].
Proof.
  intros O HO.
  rewrite opens3_list in HO.
  destruct HO as [H|[H|[H|[H|[]]]]]; subst O;
  unfold reg3, int3, cl3, big_inter, big_union, closedsets3, compl3,
         downclosed, inclb, down3, le3, interl, unionl, norm, isort,
         inserts, dedup, inb;
  vm_compute; auto.
Qed.

(* 稠密像：每个开集的正则化非空时 = j(0)——平凡稠密 *)
Lemma dense3 : forall O, In O opens3 -> reg3 O = nil \/ j3 0 = reg3 O.
Proof.
  intros O HO.
  destruct (ro3_two O HO) as [H | H].
  - left. exact H.
  - right. rewrite (proj1 j3_collapse). symmetry. exact H.
Qed.
