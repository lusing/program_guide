From Coq Require Import Arith.

Module Ex02Induction.

Fixpoint sum_to (n : nat) : nat :=
  match n with
  | 0 => 0
  | S k => n + sum_to k
  end.

Theorem plus_n_O : forall n, n + 0 = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
Qed.

Example sum_to_4 : sum_to 4 = 10.
Proof. reflexivity. Qed.

End Ex02Induction.
