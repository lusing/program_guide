From Coq Require Import List.
Import ListNotations.

Module Ex06Option.

Definition head_nat (xs : list nat) : option nat :=
  match xs with
  | [] => None
  | h :: _ => Some h
  end.

Example head_nat_some : head_nat [10;20] = Some 10.
Proof. reflexivity. Qed.

Example head_nat_none : head_nat [] = None.
Proof. reflexivity. Qed.

End Ex06Option.
