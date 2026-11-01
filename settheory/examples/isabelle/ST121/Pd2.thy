theory Pd2 imports "ZF.List" "ZF.equalities" begin

text \<open>第 121 章：两步原博弈与三步隐藏坐标辅助博弈。
0/1 表示动作；只验证有限策略提升、拉回和保赢等式。\<close>

definition AuxPayoff where
  "AuxPayoff(a,b,h) \<equiv> (if (a=1 | b=0) & h=b then 1 else 0)"

definition ProjectedPayoff where
  "ProjectedPayoff(a,b) \<equiv>
    (if AuxPayoff(a,b,0)=1 | AuxPayoff(a,b,1)=1 then 1 else 0)"

definition BaseStrategyWins where
  "BaseStrategyWins(a) \<equiv>
    (if ProjectedPayoff(a,0)=1 & ProjectedPayoff(a,1)=1 then 1 else 0)"

definition BaseValue where
  "BaseValue \<equiv>
    (if BaseStrategyWins(0)=1 | BaseStrategyWins(1)=1 then 1 else 0)"

definition AuxValueFor where
  "AuxValueFor(a) \<equiv>
    (if (AuxPayoff(a,0,0)=1 | AuxPayoff(a,0,1)=1) &
        (AuxPayoff(a,1,0)=1 | AuxPayoff(a,1,1)=1) then 1 else 0)"

definition AuxValue where
  "AuxValue \<equiv> (if AuxValueFor(0)=1 | AuxValueFor(1)=1 then 1 else 0)"

definition LiftedHiddenMove where "LiftedHiddenMove(b) \<equiv> b"

definition LiftedPlay where
  "LiftedPlay(b) \<equiv> [1,b,LiftedHiddenMove(b)]"

lemma base_value_is_true: "BaseValue = 1"
  by (simp add: BaseValue_def BaseStrategyWins_def
                ProjectedPayoff_def AuxPayoff_def)

lemma auxiliary_value_is_true: "AuxValue = 1"
  by (simp add: AuxValue_def AuxValueFor_def AuxPayoff_def)

lemma values_agree: "BaseValue = AuxValue"
  by (simp add: base_value_is_true auxiliary_value_is_true)

lemma winning_first_move_lifts:
  "b=0 | b=1 \<Longrightarrow> AuxPayoff(hd(LiftedPlay(b)),hd(tl(LiftedPlay(b))),
      hd(tl(tl(LiftedPlay(b))))) = 1"
  by (erule disjE;
      simp add: LiftedPlay_def LiftedHiddenMove_def AuxPayoff_def)

lemma winning_auxiliary_strategy_pulls_back:
  "b=0 | b=1 \<Longrightarrow> ProjectedPayoff(1,b) = 1"
  by (erule disjE; simp add: ProjectedPayoff_def AuxPayoff_def)

lemma losing_first_move_has_no_hidden_rescue:
  "h=0 | h=1 \<Longrightarrow> AuxPayoff(0,1,h) = 0"
  by (erule disjE; simp add: AuxPayoff_def)

lemma projected_payoff_is_not_uniformly_won: "BaseStrategyWins(0) = 0"
  by (simp add: BaseStrategyWins_def ProjectedPayoff_def AuxPayoff_def)

end
