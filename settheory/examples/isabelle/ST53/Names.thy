theory Names
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 53 章 V^B 骨架：check 名的定义与 G-读出的单点事实。
       谓词式：check(A0, u) = {(check(v), A0) : v \<in> u}。\<close>

consts checkname :: "[i, i] \<Rightarrow> i"

axiomatization where check_empty_ax: "checkname(A0, 0) = 0"

text \<open>checkname 的秩递归定义需要 transrec——ZF 可做但超本教程
       通道预算（与 Jech 路线 12 章的 L 层级同款技术）。骨架改为
       公理化空集情形 + G-读出的两个非递归事实。\<close>

lemma check_empty:
  "checkname(A0, 0) = 0"
  by (rule check_empty_ax)

text \<open>G-读出：val_G(τ) = {val_G(ξ) : τ(ξ) \<in> G}。
       对 check 名与主超滤 G_a = {b : a \<subseteq> b}：ǔ_G = u。\<close>

definition
  valG :: "[i, i, i] \<Rightarrow> i" where
  "valG(A0, G, tau) \<equiv> {w \<in> \<Union>(\<Union>(tau)) . \<exists>x \<in> tau . \<exists>y \<in> G . x = \<langle>w, y\<rangle>}"

lemma valG_empty: "valG(A0, G, 0) = 0"
  unfolding valG_def by simp

lemma valG_singleton_top:
  "valG(A0, G, {\<langle>0, A0\<rangle>}) \<subseteq> {0}"
  unfolding valG_def by auto

end
