(* ex04 —— 经典加成（Isabelle/HOL 版）
   两层：矩阵方向（直觉片段即可）+ 原理本体（内核经典，blast 白送）。 *)
theory ex04_classical
  imports Main
begin

(* ---------- 矩阵方向 ---------- *)

lemma m_lem_imp_dne: "(\<forall>P. P \<or> \<not>P) \<Longrightarrow> (\<forall>P. \<not>\<not>P \<longrightarrow> P)"
  by blast

lemma m_dne_imp_lem: "(\<forall>P. \<not>\<not>P \<longrightarrow> P) \<Longrightarrow> (\<forall>P. P \<or> \<not>P)"
  by blast

lemma m_lem_imp_peirce:
  "(\<forall>P. P \<or> \<not>P) \<Longrightarrow> \<forall>P Q. ((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P"
  by blast

lemma m_peirce_imp_dne:
  "(\<forall>P Q. ((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P) \<Longrightarrow> (\<forall>P. \<not>\<not>P \<longrightarrow> P)"
  by blast

lemma m_clavius: "(\<forall>P. \<not>\<not>P \<longrightarrow> P) \<Longrightarrow> \<forall>P. (\<not>P \<longrightarrow> P) \<longrightarrow> P"
  by blast

(* ---------- 原理本体：经典内核零额外公理 ---------- *)

lemma c_dne: "\<not>\<not>P \<Longrightarrow> P"
  by blast

lemma c_lem: "P \<or> \<not>P"
  by blast

lemma c_peirce: "((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P"
  by blast

lemma c_clavius: "(\<not>P \<longrightarrow> P) \<longrightarrow> P"
  by blast

lemma c_de_morgan_dual: "\<not>(P \<and> Q) \<Longrightarrow> \<not>P \<or> \<not>Q"
  by blast

(* 坑位速记（Isabelle 侧）：
   - 全称量词层级的原理互推 blast 直接吃——矩阵是 SAT 级别的活；
   - 对照 03 章 nd_de_morgan（构造方向）：dual 方向这里白送，
     因为 HOL 内核的 FalseE + 排中定理链在 simp/blast 里随便用。 *)

end
