From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.
Definition lsum (l : list nat) : nat := fold_right Nat.add 0 l.
Lemma t : forall (a x : nat) (vs : list nat), x = a -> True.
Proof.
  intros a x vs E. subst x. exact I.
Qed.
Lemma t2 : forall (a x : nat) (vs : list nat), (x =? a) = true -> True.
Proof.
  intros a x vs E. apply Nat.eqb_eq in E. subst x. exact I.
Qed.
