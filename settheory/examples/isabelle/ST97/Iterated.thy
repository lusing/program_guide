theory Iterated
  imports "ZF.Nat"
begin

text \<open>第 97 章：线性迭代超幂的有限影子。临界点轨迹表（后继映射的
迭代）与阶段系统交换图。迭代超幂本体与 Gaifman 良基性留在正文。\<close>

consts kappa0 :: "i"
consts traj :: "i => i"

axiomatization where
  traj_0: "traj(0) = kappa0" and
  traj_Suc: "ALL n. n : nat \<longrightarrow> traj(succ(n)) = succ(traj(n))"

lemma traj_1: "traj(succ(0)) = succ(kappa0)"
  by (simp add: traj_0 traj_Suc)

lemma traj_3: "traj(succ(succ(succ(0)))) = succ(succ(succ(kappa0)))"
  by (simp add: traj_0 traj_Suc)

(* 轨迹严格递增：traj(n) ∈ traj(succ(n))（推论 1.10 的影子）。 *)
lemma traj_step: "n : nat \<Longrightarrow> traj(n) : traj(succ(n))"
  by (simp add: traj_Suc)

consts e01 :: "i => i"
consts e12 :: "i => i"

axiomatization where
  e01_def_ax: "ALL x. e01(x) = succ(succ(x))" and
  e12_def_ax: "ALL x. e12(x) = succ(x)"

definition e02 :: "i => i" where
  "e02(x) == e12(e01(x))"

lemma commute: "e02(x) = e12(e01(x))"
  by (simp add: e02_def)

lemma e02_explicit: "e02(x) = succ(succ(succ(x)))"
  by (simp add: e02_def e01_def_ax e12_def_ax)

end
