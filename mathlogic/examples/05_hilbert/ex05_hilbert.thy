(* ex05 —— Hilbert 系统 L 与演绎定理（Isabelle/HOL 版） *)
theory ex05_hilbert
  imports Main
begin

datatype hform = HVar nat | HImp hform hform | HNeg hform

(* 三公理模式：definition + \<exists> 展开（fun 的模式匹配写不了结构等式） *)
definition isAxiom :: "hform \<Rightarrow> bool" where
  "isAxiom A \<equiv> (\<exists>p q. A = HImp p (HImp q p))
             \<or> (\<exists>p q r. A = HImp (HImp p (HImp q r)) (HImp (HImp p q) (HImp p r)))
             \<or> (\<exists>p q. A = HImp (HImp (HNeg q) (HNeg p)) (HImp p q))"

inductive derives :: "hform list \<Rightarrow> hform \<Rightarrow> bool" for \<Gamma> where
  dHyp: "A \<in> set \<Gamma> \<Longrightarrow> derives \<Gamma> A"
| dAx: "isAxiom A \<Longrightarrow> derives \<Gamma> A"
| dMP: "derives \<Gamma> (HImp p A) \<Longrightarrow> derives \<Gamma> p \<Longrightarrow> derives \<Gamma> A"

lemma weakK: "derives \<Gamma> A \<Longrightarrow> derives \<Gamma> (HImp B A)"
proof -
  assume H: "derives \<Gamma> A"
  have ax: "derives \<Gamma> (HImp A (HImp B A))"
    by (rule dAx) (auto simp: isAxiom_def)
  from dMP[OF ax H] show "derives \<Gamma> (HImp B A)" .
qed

lemma identity: "derives \<Gamma> (HImp p p)"
proof -
  have a1: "derives \<Gamma> (HImp p (HImp (HImp p p) p))"
    by (rule dAx) (auto simp: isAxiom_def)
  have a2: "derives \<Gamma> (HImp (HImp p (HImp (HImp p p) p))
                        (HImp (HImp p (HImp p p)) (HImp p p)))"
    by (rule dAx) (auto simp: isAxiom_def)
  have s3: "derives \<Gamma> (HImp (HImp p (HImp p p)) (HImp p p))"
    using dMP[OF a2 a1] .
  have s4: "derives \<Gamma> (HImp p (HImp p p))"
    by (rule dAx) (auto simp: isAxiom_def)
  from dMP[OF s3 s4] show "derives \<Gamma> (HImp p p)" .
qed

theorem deduction: "derives (p # \<Gamma>) q \<Longrightarrow> derives \<Gamma> (HImp p q)"
proof (induction rule: derives.induct)
  case (dHyp A)
  then show ?case
  proof (cases "A = p")
    case True
    then show ?thesis using identity by auto
  next
    case False
    then have "A \<in> set \<Gamma>" using dHyp by auto
    then have "derives \<Gamma> A" by (rule derives.dHyp)
    then show ?thesis using weakK by auto
  qed
next
  case (dAx A)
  then have "derives \<Gamma> A" by (rule derives.dAx)
  then show ?case using weakK by auto
next
  case (dMP pp A)
  have s2: "derives \<Gamma> (HImp (HImp p (HImp pp A))
                        (HImp (HImp p pp) (HImp p A)))"
    by (rule dAx) (auto simp: isAxiom_def)
  with dMP show ?case by (metis derives.dMP)
qed

(* 坑位速记（Isabelle 侧）：
   - inductive ... for Γ 把上下文钉成参数——演绎定理的归纳
     在 (p # Γ) 上做，IH 里上下文原样；
   - 公理模式用 definition + ∃ 展开；
   - dMP 分支交给 metis 装配 A2 实例（等式逻辑，无方向性风险）。 *)

end
