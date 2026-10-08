From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.
Lemma t1 : forall (L : list nat), S (length L) = length L + 1 + 1.
Proof. intros. lia. Qed.
Lemma t2 : forall x : nat, S x = x + 1 + 1 -> True.
Proof. intros x H. lia. Qed.
