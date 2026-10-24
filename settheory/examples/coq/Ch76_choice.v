(* 第 76 章：选择公理与无穷和积不等式（冯琦 §2.1–2.2）——Coq 通道 *)
(* 有限良序给出可计算选择函数；König 对角线在两坐标布尔乘积中完整证明。 *)
From Coq Require Import Bool List Arith.
Import ListNotations.

Module Ch76.

(* ---------- 定理 2.2：秩序 ⇒ 选择函数的有限构造 ---------- *)
(* order 把全集合按良序列出；对任意子集 A，沿 order 找到首个仍属于 A
   的元素。这就是“取 A 的最小元”，而不是含糊地取某个极小元。 *)
Fixpoint choose_by_order (order A : list nat) : option nat :=
  match order with
  | [] => None
  | x :: xs => if existsb (Nat.eqb x) A
               then Some x else choose_by_order xs A
  end.

Lemma choose_by_order_sound : forall order A x,
  choose_by_order order A = Some x -> In x A.
Proof.
  induction order as [|a order IH]; intros A x H; simpl in H.
  - discriminate.
  - destruct (existsb (Nat.eqb a) A) eqn:E.
    + inversion H; subst a. apply existsb_exists in E.
      destruct E as [y [Hy E]]. apply Nat.eqb_eq in E. now subst y.
    + now apply IH with (1 := H).
Qed.

Lemma choose_by_order_complete : forall order A x,
  In x order -> In x A -> exists y, choose_by_order order A = Some y.
Proof.
  induction order as [|a order IH]; intros A x Hx HA; simpl in *.
  - contradiction.
  - destruct (existsb (Nat.eqb a) A) eqn:E.
    + now exists a.
    + destruct Hx as [->|Hx].
      * assert (Etrue : existsb (Nat.eqb x) A = true).
        { apply existsb_exists. exists x. split; [exact HA|apply Nat.eqb_refl]. }
        rewrite E in Etrue. discriminate.
      * now apply IH with (x := x).
Qed.

Example choice_demo :
  choose_by_order [0;1;2;3;4] [4;2;3] = Some 2.
Proof. reflexivity. Qed.

(* ---------- 问题 2.1：两个 ∈-极小元，无法唯一指定 ---------- *)
Definition two_minimals : list (list nat) := [[0];[1]].

Example minimal_not_unique :
  map (fun a => match a with x::_ => x | [] => 0 end) two_minimals = [0;1].
Proof. reflexivity. Qed.

(* ---------- 定理 2.10：König 对角构造的二坐标原型 ---------- *)
(* X₀={h₀}、X₁={h₁}。第 0 坐标避开 h₀(0)，第 1 坐标避开 h₁(1)；
   所得 f 同时不属于 X₀ 与 X₁。证明只取等式的相应坐标投影。 *)
Definition diagonal2 (h0 h1 : bool * bool) : bool * bool :=
  (negb (fst h0), negb (snd h1)).

Theorem diagonal2_escape : forall h0 h1,
  diagonal2 h0 h1 <> h0 /\ diagonal2 h0 h1 <> h1.
Proof.
  intros h0 h1. split; intro H.
  - pose proof (f_equal fst H) as E. simpl in E.
    destruct (fst h0); discriminate.
  - pose proof (f_equal snd H) as E. simpl in E.
    destruct (snd h1); discriminate.
Qed.

Example diagonal2_demo :
  diagonal2 (false,false) (true,true) = (true,false).
Proof. reflexivity. Qed.

End Ch76.
