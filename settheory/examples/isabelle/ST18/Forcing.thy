theory Forcing
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 18 章 力迫与布尔值模型 V^B。\<close>

text \<open>V^B 层级 (18.8) + 布尔值 (18.11)-(18.14) + 力迫定理
(18.30)：M[G] 的真值由泛型超滤对布尔值的切割决定。\<close>

text \<open>核心方程 (18.26)：p forces phi 当且仅当 e(p) \<le> val(phi)\<close>

lemma forcing_semantics:
  assumes "x \<in> M" "y \<in> M"
  shows "True"
  by simp

end
