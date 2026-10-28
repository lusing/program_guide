(* 第 95 章：有限不可辨别元的封闭律、配对比较引擎与具体样本。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch95.

Section Finite.

Variable A : Type.
Variable ltA : A -> A -> bool.
Variable Phi : Type.
Variable f : Phi -> list A -> bool.

Fixpoint Incb (t : list A) : bool :=
  match t with
  | [] => true
  | a :: l =>
      match l with
      | [] => true
      | b :: _ => ltA a b && Incb l
      end
  end.

Definition indisc (s : list A) : Prop :=
  Incb s = true /\
  forall phi t u, Incb t = true -> Incb u = true ->
    length t = length u -> incl t s -> incl u s ->
    f phi t = f phi u.

(* 封闭律：不可辨别集的递增子集仍不可辨别。 *)
Theorem sub_indisc : forall s t,
  indisc s -> Incb t = true -> incl t s -> indisc t.
Proof.
  intros s t [Hs Hall] Ht Hincl. split; [exact Ht|].
  intros phi u v Hu Hv Hlen H1 H2.
  apply Hall; try assumption.
  - intros x Hx. apply Hincl. now apply H1.
  - intros x Hx. apply Hincl. now apply H2.
Qed.

End Finite.

(* 配对比较引擎（引理 1.15 的核心等式）：若 t1、t2 与公共高块 t3
   同色配对成功，则 t1 与 t2 同色。原书用「H 中取更高的第三块」，
   这是无限部分；有限侧只保留传递内核。 *)
Section Comparison.

Variable C : Type.
Variable ceq : C -> C -> bool.
Hypothesis ceq_ok : forall x y : C, ceq x y = true <-> x = y.
Variable g : list nat -> C.

Definition cmp (t u : list nat) : bool := ceq (g t) (g u).

Theorem comparison_trans : forall t1 t2 t3,
  cmp t1 t3 = true -> cmp t2 t3 = true -> g t1 = g t2.
Proof.
  intros t1 t2 t3 H1 H2.
  apply ceq_ok in H1. apply ceq_ok in H2.
  now rewrite H1, <- H2.
Qed.

End Comparison.

(* 具体样本：奇偶染色下 {0,2,4} 的全部递增二元组取值一致。 *)
Definition g2 (x y : nat) : bool :=
  Nat.even (x + y).

Definition phi_pair (t : list nat) : bool :=
  match t with
  | [x; y] => g2 x y
  | _ => true
  end.

Example pair_02 : phi_pair [0; 2] = true.
Proof. reflexivity. Qed.

Example pair_24 : phi_pair [2; 4] = true.
Proof. reflexivity. Qed.

Example pair_04 : phi_pair [0; 4] = true.
Proof. reflexivity. Qed.

Example counter_pair : phi_pair [1; 2] = false.
Proof. reflexivity. Qed.

(* {0,2,4} 的蓝图：一元恒真、二元恒真（偶+偶）。 *)
Definition blueprint_024 : list bool :=
  [ true; true; true; true ].

Example blueprint_realized :
  phi_pair [0;2] = nth 1 blueprint_024 false /\
  phi_pair [2;4] = nth 2 blueprint_024 false /\
  phi_pair [0;4] = nth 3 blueprint_024 false.
Proof. repeat split; reflexivity. Qed.

End Ch95.
