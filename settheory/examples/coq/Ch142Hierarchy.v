(* 第 142 章 Coq：层垒谱系的浅嵌入（书 7.2）。 *)

Require Import List Arith Lia.
Import ListNotations.

Inductive pset : Type :=
| PSet : list pset -> pset.

Fixpoint rank (x : pset) : nat :=
  match x with
  | PSet l => fold_right (fun y r => max (rank y + 1) r) 0 l
  end.

Lemma fold_max_lt : forall (l : list pset) (y : pset),
  In y l ->
  rank y < fold_right (fun y0 r => max (rank y0 + 1) r) 0 l.
Proof.
  intros l y.
  induction l as [|z rest IH]; intro Hin.
  - destruct Hin.
  - destruct Hin as [Heq | Hin'].
    + rewrite <- Heq. simpl.
      destruct (le_gt_dec (rank z + 1)
        (fold_right (fun y0 r => max (rank y0 + 1) r) 0 rest)) as [Hle|Hgt].
      * simpl in Hle. lia.
      * simpl in Hgt. lia.
    + assert (Hrec : rank y <
        fold_right (fun y0 r => max (rank y0 + 1) r) 0 rest)
        by (apply IH; exact Hin').
      simpl. lia.
Qed.

Theorem rank_lt_of_mem : forall (y : pset) (l : list pset),
  In y l ->
  rank y < rank (PSet l).
Proof.
  intros y l Hin.
  simpl.
  exact (fold_max_lt l y Hin).
Qed.

Definition V0 : pset := PSet [].
Definition V1 : pset := PSet [V0].

Example rank_V0 : rank V0 = 0. reflexivity. Qed.
Example rank_V1 : rank V1 = 1. reflexivity. Qed.
Example rank_of_V1_member : rank V0 < rank V1. simpl. lia. Qed.
