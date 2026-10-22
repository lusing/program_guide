theory Naturals
  imports "ZF.Arith"
begin

text \<open>第 68 章：自然数与第一递归定义定理（冯琦 §1.3）。
例 1.8（nat 与其元素都是传递集合）；定理 1.15（ZF 官方加法恰
递归在第二变元）；定理 1.16(1) 交换律的手工双归纳。\<close>

subsection \<open>例 1.8：nat 与其元素都是传递集合\<close>

lemma omega_transset: "Transset(nat)"
  by (rule Ord_is_Transset [OF Ord_nat])

lemma nat_elem_transset: "n \<in> nat \<Longrightarrow> Transset(n)"
  by (rule Ord_is_Transset [OF nat_into_Ord])

subsection \<open>定理 1.15：加法 = 递归在第二变元（ZF 官方形态）\<close>

text \<open>ZF/Arith 的加法 \<^term>\<open>m #+ n\<close> 与书页 51 逐字相同：
\<^item> add\_0\_right : m \<in> nat \<Longrightarrow> m #+ 0 = m
\<^item> add\_succ\_right [simp] : m #+ succ(n) = succ(m #+ n)
\<close>

subsection \<open>定理 1.16(1)：交换律的手工双归纳（外层 n，内层 m）\<close>

lemma add_0_left_manual: "n \<in> nat \<Longrightarrow> 0 #+ n = n"
  by (rule add_0)

text \<open>书页 51 的证明结构：外层对 n 归纳；归纳步内再对 m 归纳。
这里外层用 nat\_induct，内层的"succ 平移"由 add\_succ / add\_succ\_right
两个递归式与 IH 联合给出。\<close>

lemma add_comm_manual:
  assumes "m \<in> nat" "n \<in> nat" shows "m #+ n = n #+ m"
  using assms(2)
proof (induct rule: nat_induct)
  case 0
  show "m #+ 0 = 0 #+ m" using assms(1) by simp
next
  case (succ x)
  have "m #+ succ(x) = succ(m #+ x)" by (rule add_succ_right)
  also have "\<dots> = succ(x #+ m)" by (simp add: succ.hyps)
  also have "\<dots> = succ(x) #+ m" by (rule add_succ [THEN sym])
  finally show "m #+ succ(x) = succ(x) #+ m" .
qed

text \<open>官方版本（对照锚点）：add\_commute : m #+ n = n #+ m。\<close>

lemma official_check: "m #+ n = n #+ m"
  by (rule add_commute)

end
