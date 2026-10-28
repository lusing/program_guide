(* 第 96 章：覆盖引理的有限骨架——结构覆盖构造与链式并封闭。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch96.

Section Family.

Variable A : Type.
Variable Fam : list A -> Prop.

Hypothesis H0 : Fam [].
Hypothesis H1 : forall a, Fam [a].
Hypothesis H2 : forall X Y, Fam X -> Fam Y -> Fam (X ++ Y).

(* 结构覆盖构造：单点 + 二元并封闭的族覆盖一切有限集。
   这是「在 slack 内总能覆盖」的结构性内核；覆盖引理本体是
   关于 L 层级的超穷归纳，此处不模拟。 *)
Theorem cover_all : forall X : list A, exists Y, Fam Y /\ incl X Y.
Proof.
  induction X as [|a t [Y [HF HInc]]].
  - exists []. split; [exact H0 | intros x []].
  - exists (a :: Y). split.
    + exact (H2 [a] Y (H1 a) HF).
    + intros x [<- | Hx]; [left; reflexivity | right; apply HInc; exact Hx].
Qed.

(* 链式并封闭（推论 1.8(4) 的骨架）：族的成员之任意有限列表，
   其串联仍在族中——沿链的并在族内。 *)
Theorem chain_union : forall Xs : list (list A),
  (forall X, In X Xs -> Fam X) -> Fam (concat Xs).
Proof.
  induction Xs as [|X Xs IH]; simpl; intros H.
  - exact H0.
  - apply H2.
    + apply H. left; reflexivity.
    + apply IH. intros X' HX'. apply H. right; exact HX'.
Qed.

End Family.

(* 具体样本：在 nat 上的包含判定。 *)
Definition inclB (X Y : list nat) : bool :=
  forallb (fun x => existsb (fun y => Nat.eqb x y) Y) X.

Example cov23 : inclB [2; 3] [1; 2; 3] = true.
Proof. reflexivity. Qed.

Example not_cov34 : inclB [3; 4] [2; 4] = false.
Proof. reflexivity. Qed.

End Ch96.
