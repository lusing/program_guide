(* 第 146 章 Coq：可构成集 L 的浅嵌入（书 8.1-8.2）。

   哥德尔运算 G4/G5/G7 的可计算实现 + Def(X) 的有限演示。 *)

Require Import List Arith Lia.
Require Import PeanoNat.
Import ListNotations.

Definition rel := list (nat * nat).

Definition g4 (X Y : rel) : rel :=
  filter (fun p => negb (existsb (fun q =>
    andb (Nat.eqb (fst p) (fst q)) (Nat.eqb (snd p) (snd q))) Y)) X.

Definition g5 (X Y : rel) : rel :=
  filter (fun p => existsb (fun q =>
    andb (Nat.eqb (fst p) (fst q)) (Nat.eqb (snd p) (snd q))) Y) X.

Fixpoint dedup (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: rest =>
      let r := dedup rest in
      if existsb (Nat.eqb x) r then r else x :: r
  end.

Definition g7 (X : rel) : list nat := dedup (map fst X).

Example g4_sample :
  g4 [(1,2); (3,4); (5,6)] [(3,4); (7,8)] = [(1,2); (5,6)].
Proof. reflexivity. Qed.

Example g5_sample :
  g5 [(1,2); (3,4); (5,6)] [(3,4); (7,8)] = [(3,4)].
Proof. reflexivity. Qed.

Example g7_sample :
  g7 [(1,2); (1,3); (2,4)] = [1; 2].
Proof. reflexivity. Qed.

Example g7_dedup :
  g7 [(1,2); (3,4)] = [1; 3].
Proof. reflexivity. Qed.

(* ---------- Def(X) 的有限演示（书 8.1.1/8.1.8） ---------- *)

Definition def_subsets (X : list nat) (bound : nat) : list (list nat) :=
  map (fun mask => filter (fun i => Nat.testbit mask i) X)
      (seq 0 (2 ^ bound)).

Example def_count : forall n, n <= 10 ->
  length (def_subsets (seq 0 n) n) = 2 ^ n.
Proof.
  intros n Hn.
  unfold def_subsets.
  rewrite map_length, seq_length.
  reflexivity.
Qed.

Example finite_def_is_full :
  length (def_subsets (seq 0 2) 2) = 4.
Proof. reflexivity. Qed.
