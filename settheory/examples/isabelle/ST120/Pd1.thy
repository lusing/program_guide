theory Pd1 imports "ZF.List" "ZF.equalities" begin

text \<open>第 120 章：四步有限开博弈。0/1 表示动作，张三在偶数长度位置行动。
这里不形式化无限投影博弈、测度塔或 Martin--Steel 定理。\<close>

definition Payoff where
  "Payoff(h) \<equiv> (if hd(tl(h)) = hd(tl(tl(h))) then 1 else 0)"

definition Value0 where "Value0(h) \<equiv> Payoff(h)"

definition Value1 where
  "Value1(h) \<equiv> (if Value0(h @ [0]) = 1 then Value0(h @ [1]) else 0)"

definition Value2 where
  "Value2(h) \<equiv> (if Value1(h @ [0]) = 1 then 1 else Value1(h @ [1]))"

definition Value3 where
  "Value3(h) \<equiv> (if Value2(h @ [0]) = 1 then Value2(h @ [1]) else 0)"

definition Value4 where
  "Value4(h) \<equiv> (if Value3(h @ [0]) = 1 then 1 else Value3(h @ [1]))"

definition CertifiedMove where
  "CertifiedMove(h) \<equiv>
    (if h = [] then 0 else if h = [0,0] then 0 else
       if h = [0,1] then 1 else 0)"

definition Play where
  "Play(b,d) \<equiv> [CertifiedMove([]),b,CertifiedMove([0,b]),d]"

lemma root_has_winning_value: "Value4([]) = 1"
  by (simp add: Value4_def Value3_def Value2_def Value1_def Value0_def Payoff_def)

lemma second_round_false: "Value2([0,0]) = 1"
  by (simp add: Value2_def Value1_def Value0_def Payoff_def)

lemma second_round_true: "Value2([0,1]) = 1"
  by (simp add: Value2_def Value1_def Value0_def Payoff_def)

lemma open_strategy_wins: "b=0 | b=1 \<Longrightarrow> Payoff(Play(b,d)) = 1"
  by (erule disjE; simp add: Play_def CertifiedMove_def Payoff_def)

lemma losing_reply_is_visible: "Payoff([0,1,0,0]) = 0"
  by (simp add: Payoff_def)

end
