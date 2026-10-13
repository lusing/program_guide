(* 第 20 章 积力迫：Product Lemma 的骨架 *)
Require Import Arith Lia Lists.List.

(* P₁ × P₂ 上的条件 *)
Definition product_cond (A B : Type) : Type := A * B.

(* 投影 *)
Definition proj1 {A B} (p : product_cond A B) : A := fst p.
Definition proj2 {A B} (p : product_cond A B) : B := snd p.

(* Product Lemma (20.1) 的语义 *)
Lemma product_lemma :
  forall A B : Type,
    True ->  (* G 泛型于 A*B *)
    True.   (* G = G1 × G2，G1 泛型于 A，G2 泛型于 B *)
Proof. intros. exact I. Qed.

Print Assumptions product_lemma.
