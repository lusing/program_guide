(* ex16 —— FOL 自然演绎（Isabelle/HOL 版）：量词与 Drinker *)
theory ex16_folnd
  imports Main
begin

(* (1) 量词 de Morgan 构造方向 *)
lemma all_not_ex: "(\<forall>x. P x) \<Longrightarrow> \<not> (\<exists>x. \<not> P x)"
  by blast

lemma ex_not_all: "(\<exists>x. \<not> P x) \<Longrightarrow> \<not> (\<forall>x. P x)"
  by blast

(* (2) Drinker 悖论：经典内核一行 *)
lemma drinker: "\<exists>x. P x \<longrightarrow> (\<forall>y. P y)"
  by blast

(* (3) 量词 de Morgan 完整版 *)
lemma de_morgan_exists: "(\<exists>x. \<not> P x) = (\<not> (\<forall>x. P x))"
  by blast

(* 侧条件纪律：Isabelle 的 fix/assume 即 ∀I/∃E，
   obtain 是 witness 的受控获取 *)
lemma witness_demo:
  assumes "\<exists>x. P x"
  obtains x where "P x"
  using assms by blast

(* 坑位速记（Isabelle 侧）：
   - blast 直接处理量词与经典步骤（内核担保）；
   - obtains x 是 ∃E 的 Isar 表述——witness 只在当前块有效；
   - =（而非性 iff）在 bool 上即等价。 *)

end
