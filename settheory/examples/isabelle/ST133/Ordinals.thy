theory Ordinals imports ZF begin

text \<open>序数的官方定义（书 4.2.3）：传递集 + ∈ 是良序。ZF 采用等价
刻画：Transset（元素都是子集）且每个元素也是 Transset——两者等价，
ZF 的写法更适合做证明的归纳启动。\<close>
thm Transset_def
thm Ord_def
thm Ord_0
thm Ord_succ
thm Ord_nat           (* ω 是序数（书 4.2.4(1)） *)

text \<open>序数的比较（书 4.2.8(c) 线性）：三歧的实名。\<close>
thm Ord_linear_lt
thm Ord_linear_le

text \<open>sup = ⋃、inf = ⋂（书 4.2.8(1)(2)）：序数集的并/交仍是序数。\<close>
thm Ord_Union
thm Ord_Inter

text \<open>自己动手：0 < 2 的证明——序数的 < 就是 ∈（书 4.2.3 末尾，
ZF 的 lt_def 逐字给出这一读法）。\<close>
thm lt_def

lemma two_is_ord: "Ord(2)"
  by (rule Ord_succ [OF Ord_succ [OF Ord_0]])

lemma zero_in_two: "0 \<in> 2"
  by (rule succI2 [OF succI1])

lemma zero_lt_two: "0 < 2"
  unfolding lt_def using two_is_ord by (blast intro: zero_in_two)

end
