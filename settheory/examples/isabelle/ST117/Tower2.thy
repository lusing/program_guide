theory Tower2
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 117 章：荟萃塔 II——三级有限塔的投影提升与表示等式。
载体为 {0,1,2}，层号也是 0、1、2；rep(k,f) 在第 k 个标志坐标取值。
这些引理对应引理 3.54 与定理 3.42 中因子映射 k_λ 的有限图表，
不替代 Q_\<delta> 的 Łoś 定理、临界点计算或 Woodin 定理的无限证明。\<close>

definition
  mark :: "i\<Rightarrow>i" where
    "mark(k) \<equiv> (if k = 0 then 0 else if k = 1 then 1 else 2)"

definition
  proj :: "i\<Rightarrow>i\<Rightarrow>i" where
    "proj(k,x) \<equiv> (if k = 0 then 0 else if k = 1 then (if x = 2 then 1 else x) else x)"

definition
  lift :: "[i, i\<Rightarrow>i, i] \<Rightarrow> i" where
    "lift(k,f,x) \<equiv> f(proj(k,x))"

definition
  rep :: "[i, i\<Rightarrow>i] \<Rightarrow> i" where
    "rep(k,f) \<equiv> f(mark(k))"

definition
  applyId :: "[i\<Rightarrow>i, i] \<Rightarrow> i" where
    "applyId(f,x) \<equiv> f(x)"

lemma applyId_eq: "applyId(f,x) = f(x)"
  unfolding applyId_def by simp

lemma rep_lift_01: "rep(1,lift(0,f)) = rep(0,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma rep_lift_02: "rep(2,lift(0,f)) = rep(0,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma rep_lift_12: "rep(2,lift(1,f)) = rep(1,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma lift_01_restrict: "x = 0 \<or> x = 1 \<Longrightarrow> lift(1,f,x) = f(x)"
  unfolding lift_def proj_def by auto

lemma lift_comp_01: "lift(1,lift(0,f),x) = lift(0,f,x)"
  unfolding lift_def proj_def by simp

lemma lift_comp_12: "lift(2,lift(1,f),x) = lift(1,f,x)"
  unfolding lift_def proj_def by auto

lemma lift_comp_02: "lift(2,lift(0,f),x) = lift(0,f,x)"
  unfolding lift_def proj_def by simp

theorem directed_representations:
  "rep(1,lift(0,f)) = rep(0,f) \<and>
   rep(2,lift(0,f)) = rep(0,f) \<and>
   rep(2,lift(1,f)) = rep(1,f)"
  by (simp add: rep_lift_01 rep_lift_02 rep_lift_12)

end
