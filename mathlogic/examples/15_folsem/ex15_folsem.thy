(* ex15 —— FOL 语义与一阶理论（Isabelle/HOL 版：locale 演示） *)
theory ex15_folsem
  imports Main
begin

(* locale = 理论的模块化：固定解释 + 假设公理，内部定理自动继承 *)
locale strict_order =
  fixes R :: "nat \<Rightarrow> nat \<Rightarrow> bool"
  assumes irrefl: "\<And>x. \<not> R x x"
  and trans: "\<And>x y z. R x y \<Longrightarrow> R y z \<Longrightarrow> R x z"
begin

(* 理论内推理：传递性 + 自反禁止 \<Longrightarrow> 无 2-环 *)
lemma no_cycle2:
  "\<not> (R x y \<and> R y x)"
  using irrefl[of x] trans[of x y x] by blast

lemma no_cycle3:
  "\<not> (R x y \<and> R y z \<and> R z x)"
  using irrefl[of x] trans[of y z x] trans[of x y x] by blast

(* 「严格小于」是严格偏序的实例化 *)
end

interpretation lt_order: strict_order "(<)"
  by unfold_locales auto

lemma lt_demo: "\<not> ((x::nat) < y \<and> y < x)"
  by (fact lt_order.no_cycle2)

(* 满足一致性（EFT III.5）的一行版 *)
lemma coincidence:
  fixes pe :: "nat \<Rightarrow> bool"
  assumes "\<And>m. m \<in> S \<Longrightarrow> e1 m = e2 m"
  shows "(\<forall>m \<in> S. P (e1 m)) \<longleftrightarrow> (\<forall>m \<in> S. P (e2 m))"
  using assms by auto

(* 坑位速记（Isabelle 侧）：
   - locale 的 fixes/assumes 展开成带前缀的定理（lt_order.no_cycle2）；
   - interpretation ... by unfold_locales auto 一行实例化；
   - coincidence 的 blast 处理「环境一致则量词语义一致」零公理。 *)

end
