From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.
Definition lsum (l : list nat) : nat := fold_right Nat.add 0 l.
Lemma lsum_map_add3 : forall (f g h : nat -> nat) vs,
    lsum (map (fun v => f v + g v + h v) vs)
    = lsum (map f vs) + lsum (map g vs) + lsum (map h vs).
Proof.
  intros f g h vs; induction vs as [|x vs IH];
    unfold lsum in *; simpl in *.
  - reflexivity.
  - lia.
Qed.
