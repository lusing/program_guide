theory Naturals imports ZF begin

text \<open>ω 的官方定义：含 0 且对 succ 封闭的最小集合——最小归纳集
（书 3.1.2 的 N = "属于一切归纳集的元素"）。在 Isabelle/ZF 中 nat
定义为相应算子的最小不动点 lfp。\<close>
thm nat_def
thm nat_unfold       (* lfp 的展开：归纳集两条件的合取 *)

text \<open>归纳原理（书 (3.4)/(3.5)）与第二归纳原理（书 3.1.9）的实名。\<close>
thm nat_induct       (* case_names 0 succ：两条前提，结论对一切 n *)
thm complete_induct  (* case_names less：强归纳形态 *)

text \<open>nat 是序数（第 133 章的预告：最小的无穷序数）。\<close>
thm Ord_nat

text \<open>递归定理的实例：ZF 的加法/乘法定义（书 3.2.4/3.2.5）。
注意 ZF 的加法对**第一**参数递归（succ(m) #+ n = succ(m #+ n)），
与书对第二参数递归互为镜像——同一运算的两种合法递归式。\<close>
thm add_def
thm add_0_right
thm add_succ
thm mult_def
thm mult_0_right
thm mult_succ

text \<open>自己动手用 nat_induct 重演书 3.2.7 的证明骨架：
succ 的加法按定义展开、归纳假设代入——基例与步例都落在库引理上。\<close>
lemma one_add: "n \<in> nat \<Longrightarrow> succ(0) #+ n = succ(n)"
proof (erule nat_induct)
  show "succ(0) #+ 0 = succ(0)" by simp
next
  fix x assume IH: "succ(0) #+ x = succ(x)"
  show "succ(0) #+ succ(x) = succ(succ(x))" using IH by simp
qed

end
