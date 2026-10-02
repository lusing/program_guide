(* ex06 —— 矢列演算 G（Isabelle/HOL 版） *)
theory ex06_sequent
  imports Main
begin

datatype sform = SVar nat | SAnd sform sform | SOr sform sform
               | SImp sform sform | SNeg sform

inductive gProv :: "sform list \<Rightarrow> sform list \<Rightarrow> bool" where
  gAx: "p \<in> set \<Gamma> \<Longrightarrow> p \<in> set \<Delta> \<Longrightarrow> gProv \<Gamma> \<Delta>"
| gLNeg: "gProv \<Gamma> (p # \<Delta>) \<Longrightarrow> gProv (SNeg p # \<Gamma>) \<Delta>"
| gRNeg: "gProv (p # \<Gamma>) \<Delta> \<Longrightarrow> gProv \<Gamma> (SNeg p # \<Delta>)"
| gLAnd: "gProv (a # b # \<Gamma>) \<Delta> \<Longrightarrow> gProv (SAnd a b # \<Gamma>) \<Delta>"
| gRAnd: "gProv \<Gamma> (a # \<Delta>) \<Longrightarrow> gProv \<Gamma> (b # \<Delta>) \<Longrightarrow> gProv \<Gamma> (SAnd a b # \<Delta>)"
| gLOr: "gProv (a # \<Gamma>) \<Delta> \<Longrightarrow> gProv (b # \<Gamma>) \<Delta> \<Longrightarrow> gProv (SOr a b # \<Gamma>) \<Delta>"
| gROr: "gProv \<Gamma> (a # b # \<Delta>) \<Longrightarrow> gProv \<Gamma> (SOr a b # \<Delta>)"
| gLImp: "gProv \<Gamma> (a # \<Delta>) \<Longrightarrow> gProv (b # \<Gamma>) \<Delta> \<Longrightarrow> gProv (SImp a b # \<Gamma>) \<Delta>"
| gRImp: "gProv (a # \<Gamma>) (b # \<Delta>) \<Longrightarrow> gProv \<Gamma> (SImp a b # \<Delta>)"

lemma g_lem_var: "gProv [] [SOr (SNeg (SVar n)) (SVar n)]"
proof (rule gROr)
  show "gProv [] [SNeg (SVar n), SVar n]"
  proof (rule gRNeg)
    show "gProv [SVar n] [SVar n]"
      by (rule gAx) auto
  qed
qed

lemma g_imp_id: "gProv [] [SImp (SVar n) (SVar n)]"
proof (rule gRImp)
  show "gProv [SVar n] [SVar n]"
    by (rule gAx) auto
qed

(* 可靠性：gProv Γ Δ ⟹ Γ 全真则 Δ 有真——Isabelle 侧留作
   induct+auto 练习；完整机器版见 Coq 通道（九规则归纳）。 *)

(* 坑位速记（Isabelle 侧）：
   - inductive 的双表都是索引（for 钉不了两个都变的东西）；
   - proof (rule gROr) 的实例化由结论 # 模式统一给出。 *)

end
