theory Wellorders imports ZF begin

text \<open>良序、序同构与三歧性构造（书 4.1）的 ZF 官方件。\<close>

text \<open>良序 = 良基 + 传递 + 线性（书 3.1.8 的定义在关系上的版本）。\<close>
thm well_ord_def
thm well_ordI
thm well_ord_is_wf
thm well_ord_is_linear
thm well_ord_subset
thm well_ord_0

text \<open>保序映射与序同构（书 4.1.3 的增函数 = mono_map）。\<close>
thm mono_map_def
thm mono_map_is_inj
thm ord_iso_def

text \<open>书 4.1.6 三歧性定理的构造
  f = {(x,y) | W1[x] 同构于 W2[y]}
在 ZF 中的逐字实现就叫 ord_iso_map——"Construction for linearity
theorem"。它的定义域、值域分别含于 W1、W2（正式的"是前段"由
后续引理补足）。\<close>
thm ord_iso_map_def
thm domain_ord_iso_map
thm range_ord_iso_map

text \<open>自己动手：单点集上的空关系是良序——线序由 x = y 支起，
良基来自 wf[A](0)。\<close>
lemma well_ord_singleton: "well_ord({a}, 0)"
  apply (rule well_ordI)
   apply (rule wf_on_any_0)
  by (simp add: linear_def)

end
