(* ex01 —— 全景与 hello-logic（Isabelle/HOL 版）
   经典内核的代表：同样的四条，最后一条不需要任何额外公理。 *)
theory ex01_intro
  imports Main
begin

lemma ml_mp: "\<lbrakk> P \<longrightarrow> Q; P \<rbrakk> \<Longrightarrow> Q"
  by blast

lemma ml_imp_trans: "\<lbrakk> P \<longrightarrow> Q; Q \<longrightarrow> R; P \<rbrakk> \<Longrightarrow> R"
  by blast

lemma ml_nn_intro: "P \<Longrightarrow> \<not> \<not> P"
  by blast

(* 经典哨兵：内核自带经典规则（HOL 的 EFS 体系），blast 直接证 *)
lemma ml_nn_elim: "\<not> \<not> P \<Longrightarrow> P"
  by blast

(* 坑位速记（Isabelle 侧）：
   - Unicode 记号用反斜杠转义写法（\<longrightarrow> 等）最稳，
     直接贴字面 ‹⟧› 记号容易踩词法层的坑（详见 hol/isabelle 教程坑清单）；
   - blast/simp/metis 是自动化三板斧，经典性由内核担保；
   - 对象逻辑是 HOL：P 是 bool 的别名（prop 层与 bool 层的关系见 02 章）。 *)

end
