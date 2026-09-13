From Coq Require Import Arith.
From Coq Require Import Bool.

Module Ex04BoolNat.

Definition is_zero (n : nat) : bool :=
  match n with
  | 0 => true
  | _ => false
  end.

Theorem is_zero_0 : is_zero 0 = true.
Proof. reflexivity. Qed.

Theorem is_zero_S : forall n, is_zero (S n) = false.
Proof.
  intros n.
  reflexivity.
Qed.

Theorem plus_comm_2_3 : 2 + 3 = 3 + 2.
Proof. reflexivity. Qed.

End Ex04BoolNat.
