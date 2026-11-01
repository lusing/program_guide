theory Invariance
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——集合语义的
对称保真、双点不变证书与博雷尔包裹（引理 3.23(3)/定理 3.26-3.27 的
机制核，沿确定性规则链纪律）。子集取 3 = {0,1,2} 的子集；对换
tau = swap(0,1)；群作用取像集 tau``b。数值窗口的公式-布尔值件由
Lean/Coq/Agda 承担（ZF 的函数语义在这件上事倍功半）。\<close>

subsection\<open>对换与像集作用\<close>

definition
  tau :: "i\<Rightarrow>i" where
    "tau(x) \<equiv> (if x = 0 then 1 else if x = 1 then 0 else x)"

definition
  img :: "[i\<Rightarrow>i, i] \<Rightarrow> i" where
    "img(f, b) \<equiv> {f(y) . y \<in> b}"

lemma tau_0 [simp]: "tau(0) = 1"
  unfolding tau_def by simp

lemma tau_1 [simp]: "tau(1) = 0"
  unfolding tau_def by simp

lemma tau_2 [simp]: "tau(2) = 2"
  unfolding tau_def by simp

lemma tau_in_3: "x \<in> {0, 1, 2} \<Longrightarrow> tau(x) \<in> {0, 1, 2}"
  unfolding tau_def by auto

lemma tau_tau: "x \<in> {0, 1, 2} \<Longrightarrow> tau(tau(x)) = x"
  unfolding tau_def by auto

lemma tau_inj: "\<lbrakk>x \<in> {0, 1, 2}; y \<in> {0, 1, 2}; tau(x) = tau(y)\<rbrakk> \<Longrightarrow> x = y"
  unfolding tau_def by auto

subsection\<open>件 E（对称保真的集合版）：像集与成员资格共轭\<close>

lemma mem_conj [rule_format]:
  "\<lbrakk>b \<subseteq> {0, 1, 2}; i \<in> {0, 1, 2}\<rbrakk> \<Longrightarrow> (tau(i) \<in> img(tau, b) \<longleftrightarrow> i \<in> b)"
  unfolding img_def tau_def
  by auto

theorem invariance_01 [rule_format]:
  "\<lbrakk>b \<subseteq> {0, 1, 2}; img(tau, b) = b\<rbrakk> \<Longrightarrow> (0 \<in> b \<longleftrightarrow> 1 \<in> b)"
  unfolding img_def
  apply (rule iffI)
   apply (subgoal_tac "tau(0) \<in> {tau(y) . y \<in> b}")
    apply simp
   apply (rule RepFunI, assumption)
  apply (subgoal_tac "tau(1) \<in> {tau(y) . y \<in> b}")
    apply simp
   apply (rule RepFunI, assumption)
  done

subsection\<open>件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制）\<close>

definition
  Sset :: i  where
    "Sset \<equiv> {0, 2}"

definition
  Xset :: i  where
    "Xset \<equiv> {0, 2, succ(2)}"

definition
  A1set :: i  where
    "A1set \<equiv> Xset \<inter> Sset"

lemma Sset_mem [simp]: "(x \<in> Sset \<longleftrightarrow> x = 0 \<or> x = 2)"
  unfolding Sset_def by auto

lemma Xset_mem [simp]: "(x \<in> Xset \<longleftrightarrow> x = 0 \<or> x = 2 \<or> x = succ(2))"
  unfolding Xset_def by auto

lemma A1set_mem [simp]: "(x \<in> A1set \<longleftrightarrow> x = 0 \<or> x = 2)"
  unfolding A1set_def by auto

text \<open>在 S 上 X 与 A₁ 同真假。\<close>

theorem modI_eq: "x \<in> Sset \<Longrightarrow> (x \<in> Xset \<longleftrightarrow> x \<in> A1set)"
  by auto

text \<open>差集全落理想：X 与 A₁ 真值相异处必在 S 之外。\<close>

theorem modI_ideal:
  "(x \<in> Xset \<and> x \<notin> A1set) \<or> (x \<notin> Xset \<and> x \<in> A1set) \<Longrightarrow> x \<notin> Sset"
  by auto

end
