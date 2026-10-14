theory Stone
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 48 章 Stone 对偶骨架（谓词式嵌入版）。
       48 章实测教训：基于 Collect 的集合式 stN 让 blast 系统性爆炸
       （Pow(Pow(..)) 成员的见证搜索失控）；谓词式 N(A0,X,G) 配
       intro/dest 规则全家桶后零 blast、秒级通过。\<close>

definition
  ufilter_on :: "[i,i] \<Rightarrow> o" where
  "ufilter_on(A0,G) \<equiv> G \<subseteq> Pow(A0) \<and> A0 \<in> G \<and> 0 \<notin> G \<and>
     (\<forall>X\<in>G. \<forall>Y\<in>G. X \<inter> Y \<in> G) \<and>
     (\<forall>X\<in>G. \<forall>Y\<in>Pow(A0). X \<subseteq> Y \<longrightarrow> Y \<in> G) \<and>
     (\<forall>X\<in>Pow(A0). X \<in> G \<or> (A0 - X) \<in> G)"

text \<open>N_b 的谓词化身：G 是（= N_b 的点）当且仅当 G 超滤且含 b。\<close>

definition
  Nmem :: "[i, i, i] \<Rightarrow> o" where
  "Nmem(A0, X, G) \<equiv> ufilter_on(A0,G) \<and> X \<in> G"

lemma NmemI [intro!]:
  "\<lbrakk> ufilter_on(A0,G); X \<in> G \<rbrakk> \<Longrightarrow> Nmem(A0, X, G)"
  unfolding Nmem_def by simp

lemma NmemD1: "Nmem(A0, X, G) \<Longrightarrow> ufilter_on(A0,G)"
  unfolding Nmem_def by simp

lemma NmemD2: "Nmem(A0, X, G) \<Longrightarrow> X \<in> G"
  unfolding Nmem_def by simp

text \<open>上闭性独立引理（正向爆炸安全区）。\<close>

lemma ufilter_up:
  assumes "ufilter_on(A0,G)" "U \<in> G" "V \<in> Pow(A0)" "U \<subseteq> V"
  shows "V \<in> G"
  using assms unfolding ufilter_on_def by blast

lemma ufilter_inter:
  assumes "ufilter_on(A0,G)" "U \<in> G" "V \<in> G"
  shows "U \<inter> V \<in> G"
  using assms unfolding ufilter_on_def by blast

text \<open>单调：X \<subseteq> Y ⟹ N_X 点必是 N_Y 点。\<close>

lemma Nmono:
  assumes "X \<subseteq> Y" and "Y \<in> Pow(A0)"
  shows "Nmem(A0, X, G) \<Longrightarrow> Nmem(A0, Y, G)"
proof -
  assume h: "Nmem(A0, X, G)"
  from h have huf: "ufilter_on(A0,G)" by (rule NmemD1)
  from h have hX: "X \<in> G" by (rule NmemD2)
  have "Y \<in> G" by (rule ufilter_up [OF huf hX assms(2) assms(1)])
  with huf show "Nmem(A0, Y, G)" by (rule NmemI)
qed

text \<open>N_0 空：超滤子不含空集。\<close>

lemma Nempty:
  assumes "ufilter_on(A0,G)"
  shows "\<not> Nmem(A0, 0, G)"
proof
  assume h: "Nmem(A0, 0, G)"
  from h have "0 \<in> G" by (rule NmemD2)
  moreover from assms have "0 \<notin> G" unfolding ufilter_on_def by simp
  ultimately show False by simp
qed

text \<open>N_{X \<inter> Y} = N_X \<inter> N_Y 的谓词版（双向）。\<close>

lemma NinterI:
  assumes "Nmem(A0, X, G)" and "Nmem(A0, Y, G)"
  shows "Nmem(A0, X \<inter> Y, G)"
proof -
  from assms(1) have huf: "ufilter_on(A0,G)" by (rule NmemD1)
  from assms(1) have hX: "X \<in> G" by (rule NmemD2)
  from assms(2) have hY: "Y \<in> G" by (rule NmemD2)
  have "X \<inter> Y \<in> G" by (rule ufilter_inter [OF huf hX hY])
  with huf show ?thesis by (rule NmemI)
qed

lemma NinterD:
  assumes "Nmem(A0, X \<inter> Y, G)" and "X \<in> Pow(A0)" and "Y \<in> Pow(A0)"
  shows "Nmem(A0, X, G)" and "Nmem(A0, Y, G)"
proof -
  from assms(1) have huf: "ufilter_on(A0,G)" by (rule NmemD1)
  from assms(1) have hXY: "X \<inter> Y \<in> G" by (rule NmemD2)
  have hx: "X \<inter> Y \<subseteq> X" by (rule Int_lower1)
  have "X \<in> G" by (rule ufilter_up [OF huf hXY assms(2) hx])
  with huf show "Nmem(A0, X, G)" by (rule NmemI)
next
  from assms(1) have huf: "ufilter_on(A0,G)" by (rule NmemD1)
  from assms(1) have hXY: "X \<inter> Y \<in> G" by (rule NmemD2)
  have hy: "X \<inter> Y \<subseteq> Y" by (rule Int_lower2)
  have "Y \<in> G" by (rule ufilter_up [OF huf hXY assms(3) hy])
  with huf show "Nmem(A0, Y, G)" by (rule NmemI)
qed

end
