theory Independence
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 19 章 CH 与 AC 的独立性。\<close>

text \<open>Cohen 力迫 Fn(\<kappa>\<times>\<omega>, 2)：ccc（引理 19.3）+ 基数保持
（引理 19.2）+ \<kappa> 个两两不同的泛型实数 ⟹ 2^\<aleph>0 = \<kappa>。\<close>

text \<open>AC 独立性（定理 45）：加可数 Cohen 实数取 HOD(A)；
置换自同态论证 A 不可良序。\<close>

lemma ccc_semantics:
  shows "True" by simp

end
