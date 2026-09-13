From Coq Require Import List.
Import ListNotations.

Module Ex07HigherOrder.

Definition inc_all (xs : list nat) : list nat :=
  map (fun n => S n) xs.

Definition sum_all (xs : list nat) : nat :=
  fold_right Nat.add 0 xs.

Example inc_all_ex : inc_all [1;2;3] = [2;3;4].
Proof. reflexivity. Qed.

Example sum_all_ex : sum_all [1;2;3;4] = 10.
Proof. reflexivity. Qed.

End Ex07HigherOrder.
