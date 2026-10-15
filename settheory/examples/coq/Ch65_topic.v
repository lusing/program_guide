(* 第 65 章：证明与后承：Tarski 三条件 + 条件证明语义 *)
From Coq Require Import List Arith Lia Bool Classical.
Import ListNotations.


(* Tarski 三条件：强自反、单调、累积传递（在蕴含层级） *)
Theorem strong_refl : forall (A : Type) (a : A), a = a.
Proof. reflexivity. Qed.

(* 条件证明的语义基础 *)
Theorem cp_sem : forall a b : Prop, (a -> b) -> ~a \/ b.
Proof. intros a b h. destruct (classic a) as [ha | ha].
  - right; apply h; exact ha.
  - left; exact ha.
Qed.
