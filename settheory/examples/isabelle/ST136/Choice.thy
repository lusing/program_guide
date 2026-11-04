theory Choice imports ZF "ZF-AC.AC_Equiv" "ZF-AC.WO1_AC" "ZF-AC.HH" begin

text \<open>书 4.6.1 的等价网络在 Isabelle/ZF 的 AC 库中是官方件。
AC1 = 选择函数形式（书的 (3)）；WO1 = 良序定理（书的 (4））。\<close>
thm AC1_def
thm WO1_def

text \<open>(4) \<Longrightarrow> (3)：良序给出选择函数——"取最小元"就是选择。
这正是书 4.6.1 证明的最后一环。\<close>
thm ex_choice_fun

text \<open>(3)（乃至更弱的 AC1）\<Longrightarrow> (4)：选择函数造良序——
书证明的核心（Hartogs 上界内的超穷递归）。\<close>
thm AC1_WO2
thm WO1_AC1

text \<open>良序集的商集映射（书证明中 (2)\<rightarrow>(3) 的不交化技巧
在 ZF 里有现成的陪集工具）。\<close>
thm lam_sing_bij

end
