From Coq Require Import Arith.
From Coq Require Import Bool.

Module Ex01Basics.

Definition square (n : nat) : nat := n * n.

Example plus_1_2 : 1 + 2 = 3.
Proof. reflexivity. Qed.

Example square_3 : square 3 = 9.
Proof. reflexivity. Qed.

Example andb_true_false : andb true false = false.
Proof. reflexivity. Qed.

End Ex01Basics.
