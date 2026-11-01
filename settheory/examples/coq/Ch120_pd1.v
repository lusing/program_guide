(* 第 120 章：有限开前缀博弈；不冒充无限投影决定性。 *)
Require Import List Bool.
Import ListNotations.

Definition payoff (h : list bool) : bool :=
  match h with
  | _ :: b :: c :: _ => Bool.eqb b c
  | _ => false
  end.

Fixpoint value (fuel : nat) (h : list bool) : bool :=
  match fuel with
  | O => payoff h
  | S f =>
      if Nat.eqb (Nat.modulo (length h) 2) 0
      then orb (value f (h ++ [false])) (value f (h ++ [true]))
      else andb (value f (h ++ [false])) (value f (h ++ [true]))
  end.

Definition certified_move (h : list bool) : bool :=
  match h with
  | [] => false
  | [_ ; b] => b
  | _ => false
  end.

Definition play (b d : bool) : list bool :=
  [certified_move [] ; b ; certified_move [false ; b] ; d].

Theorem root_has_winning_value : value 4 [] = true.
Proof. reflexivity. Qed.

Theorem every_second_round_position_is_winning :
  forall b : bool, value 2 [false ; b] = true.
Proof. intros []; reflexivity. Qed.

Theorem open_strategy_wins :
  forall b d : bool, payoff (play b d) = true.
Proof. intros [] []; reflexivity. Qed.

Theorem losing_reply_is_visible :
  payoff [false ; true ; false ; false] = false.
Proof. reflexivity. Qed.
