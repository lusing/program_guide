Require Import Bool.

(* 第 121 章：三步辅助博弈与两步投影博弈；只验证有限策略变换。 *)

Definition auxiliary_payoff (a b h : bool) : bool :=
  (a || negb b) && Bool.eqb h b.

Definition projected_payoff (a b : bool) : bool :=
  auxiliary_payoff a b false || auxiliary_payoff a b true.

Definition base_strategy_wins (a : bool) : bool :=
  projected_payoff a false && projected_payoff a true.

Definition base_value : bool :=
  base_strategy_wins false || base_strategy_wins true.

Definition auxiliary_value_for (a : bool) : bool :=
  (auxiliary_payoff a false false || auxiliary_payoff a false true) &&
  (auxiliary_payoff a true false || auxiliary_payoff a true true).

Definition auxiliary_value : bool :=
  auxiliary_value_for false || auxiliary_value_for true.

Definition lifted_hidden_move (b : bool) : bool := b.

Definition lifted_strategy_wins (b : bool) : bool :=
  auxiliary_payoff true b (lifted_hidden_move b).

Definition pulled_back_strategy_wins (b : bool) : bool :=
  projected_payoff true b.

Theorem projection_rule :
  forall a b : bool,
    projected_payoff a b =
    (auxiliary_payoff a b false || auxiliary_payoff a b true).
Proof. intros [] []; reflexivity. Qed.

Theorem base_value_is_true : base_value = true.
Proof. reflexivity. Qed.

Theorem auxiliary_value_is_true : auxiliary_value = true.
Proof. reflexivity. Qed.

Theorem values_agree : base_value = auxiliary_value.
Proof. reflexivity. Qed.

Theorem winning_first_move_lifts :
  forall b : bool, lifted_strategy_wins b = true.
Proof. intros []; reflexivity. Qed.

Theorem winning_auxiliary_strategy_pulls_back :
  forall b : bool, pulled_back_strategy_wins b = true.
Proof. intros []; reflexivity. Qed.

Theorem losing_first_move_has_no_hidden_rescue :
  forall h : bool, auxiliary_payoff false true h = false.
Proof. intros []; reflexivity. Qed.

Theorem projected_payoff_is_not_uniformly_won :
  base_strategy_wins false = false.
Proof. reflexivity. Qed.
