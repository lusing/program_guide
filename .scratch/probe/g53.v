From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.
Definition vdeg (v : nat) (E : list (nat * nat)) : nat :=
  length (filter (fun e => Nat.eqb v (fst e) || Nat.eqb v (snd e)) E).
Lemma vdeg_cons : forall v a b E,
    vdeg v ((a,b) :: E)
    = vdeg v E + (if Nat.eqb v a then 1 else 0) + (if Nat.eqb v b then 1 else 0).
Proof.
  intros v a b E. unfold vdeg. simpl.
  destruct (Nat.eqb v a) eqn:Pa; destruct (Nat.eqb v b) eqn:Pb; simpl; lia.
Qed.
