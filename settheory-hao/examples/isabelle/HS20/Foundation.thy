theory Foundation imports ZF begin

text \<open>良基归纳与递归（书 7.6）：ZF 库的 WF.thy 以 wfrec 为核心。\<close>
thm wf_def             (* wf(r)：每个非空集有 r-极小元 *)
thm wf_induct          (* 良基归纳（书 7.6 的 (7.48) 式） *)
thm wfrec_def          (* 良基递归（书 7.6.6/7.6.51）：wfrec(r,a,H) *)

text \<open>wf_induct 是书 (7.48) 的逐字实现：\<close>
(* wf(r) ⟹ ∀a. P(a) 前提是 ∀y. y r a ⟹ P(y) *)

text \<open>基础公理 = ∈ 是全域良基（书 7.2.15/7.5.3）。\<close>
thm foundation        (* A ≠ 0 ⟹ ∃y∈A. A ∩ y = 0 *)

text \<open>自己动手：空关系是任何集上的良基关系。\<close>
lemma wf_empty_rel: "wf(0)"
  unfolding wf_def by blast

text \<open>∈ 在传递集 X 上的良基性等价于 X ⊆ WF（书 7.2.10/7.2.11）。
ZF 库里相应结果散布于 Cardinal.thy 的 well_ord_Memrel 系列。\<close>
thm Ord_trans

end
