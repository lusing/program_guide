Require Import List Lia.
Import ListNotations.

(* 第 119 章：有限策略表。done 不是大基数可迭代性定理。 *)
Inductive result : Type := Done | OutOfFuel | Illegal.

Definition c_strategy (k : nat) : nat :=
  match k with 0 => 0 | S q => q end.

Definition bad_strategy (_ : nat) : nat := 6.

Definition legal_target (k p : nat) : bool :=
  Nat.leb p k && Nat.eqb p (c_strategy k).

Fixpoint run_with (strategy : nat -> nat) (fuel k : nat) : result :=
  match fuel with
  | 0 => if Nat.leb 6 k then Done else OutOfFuel
  | S f =>
      if Nat.leb 6 k then Done
      else if legal_target k (strategy k)
           then run_with strategy f (S k)
           else Illegal
  end.

Definition scheduled : list nat := map c_strategy (seq 0 6).

Lemma scheduled_is_alternating_chain :
  scheduled = [0;0;1;2;3;4].
Proof. reflexivity. Qed.

Lemma comparison_terminates : run_with c_strategy 6 0 = Done.
Proof. reflexivity. Qed.

Lemma short_budget_is_detected : run_with c_strategy 5 0 = OutOfFuel.
Proof. reflexivity. Qed.

Lemma bad_target_is_detected : run_with bad_strategy 6 0 = Illegal.
Proof. reflexivity. Qed.

Lemma every_scheduled_target_is_legal :
  forall k, k < 6 -> legal_target k (c_strategy k) = true.
Proof.
  intros k H.
  destruct k as [|[|[|[|[|[|k]]]]]]; try reflexivity; lia.
Qed.
