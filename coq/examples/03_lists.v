From Coq Require Import List.
Import ListNotations.

Module Ex03Lists.

Fixpoint my_length {A : Type} (xs : list A) : nat :=
  match xs with
  | [] => 0
  | _ :: tl => S (my_length tl)
  end.

Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys
  | h :: tl => h :: my_append tl ys
  end.

Example my_length_ex : my_length [1;2;3] = 3.
Proof. reflexivity. Qed.

Example my_append_ex : my_append [1;2] [3;4] = [1;2;3;4].
Proof. reflexivity. Qed.

End Ex03Lists.
