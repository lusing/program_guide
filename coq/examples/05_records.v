Module Ex05Records.

Record Point : Type := {
  px : nat;
  py : nat
}.

Definition move_x (p : Point) (dx : nat) : Point :=
  {| px := px p + dx; py := py p |}.

Example point_move_ex :
  move_x {| px := 2; py := 5 |} 3 = {| px := 5; py := 5 |}.
Proof. reflexivity. Qed.

End Ex05Records.
