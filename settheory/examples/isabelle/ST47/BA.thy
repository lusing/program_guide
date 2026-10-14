theory BA
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 47 章 布尔代数：ZF 无 BA 库，在 𝒫(A) 上做核心事实。
       (1) 𝒫(A) 版 De Morgan（Viale Prop 3.3.1 (iv) 的幂集实例）；
       (2) 主超滤的两个关键引理（PIT 的有限/原子侧）。
       注意：ZF 的 {X \<in> A . P} 是 Collect 折叠，全局 [simp] 展开
       会让 auto 病理性循环——principal_iff 只手动调用。\<close>

lemma ba_de_morgan:
  "A0 - (A \<union> B) = (A0 - A) \<inter> (A0 - B)"
  by blast

definition
  pfilter :: "[i,i] \<Rightarrow> o" where
  "pfilter(A0,F) \<equiv> F \<subseteq> Pow(A0) \<and> A0 \<in> F \<and> (\<forall>X\<in>F. \<forall>Y\<in>F. X \<inter> Y \<in> F)
                   \<and> (\<forall>X\<in>F. \<forall>Y\<in>Pow(A0). X \<subseteq> Y \<longrightarrow> Y \<in> F)"

definition
  ultra :: "[i,i] \<Rightarrow> o" where
  "ultra(A0,F) \<equiv> pfilter(A0,F) \<and>
                   (\<forall>X\<in>Pow(A0). X \<in> F \<longleftrightarrow> (A0 - X) \<notin> F)"

definition
  principal :: "[i,i] \<Rightarrow> i" where
  "principal(A0,a) \<equiv> {X \<in> Pow(A0) . a \<in> X}"

lemma principal_iff:
  "X \<in> principal(A0,a) \<longleftrightarrow> (X \<in> Pow(A0) \<and> a \<in> X)"
  unfolding principal_def Collect_def by blast

lemma principal_inter_closed:
  assumes "a \<in> A0"
  shows "\<forall>X\<in>principal(A0,a). \<forall>Y\<in>principal(A0,a). X \<inter> Y \<in> principal(A0,a)"
proof (intro ballI)
  fix X
  assume "X \<in> principal(A0,a)"
  then have hX: "X \<in> Pow(A0)" and haX: "a \<in> X"
    using principal_iff by blast+
  fix Y
  assume "Y \<in> principal(A0,a)"
  then have hY: "Y \<in> Pow(A0)" and haY: "a \<in> Y"
    using principal_iff by blast+
  have hx: "X \<subseteq> A0" using hX unfolding Pow_iff .
  have hsub: "X \<inter> Y \<subseteq> A0"
    by (rule subset_trans [OF Int_lower1 hx])
  then have hPow: "X \<inter> Y \<in> Pow(A0)" unfolding Pow_iff .
  have hain: "a \<in> X \<inter> Y" using haX haY by simp
  show "X \<inter> Y \<in> principal(A0,a)"
    using hPow hain principal_iff by blast
qed

lemma principal_ultra_dich:
  assumes "a \<in> A0" and "X \<in> Pow(A0)"
  shows "X \<in> principal(A0,a) \<longleftrightarrow> (A0 - X) \<notin> principal(A0,a)"
proof (rule iffI)
  assume h1: "X \<in> principal(A0,a)"
  then have haX: "a \<in> X" using principal_iff by blast
  have hn: "a \<notin> (A0 - X)" using haX assms(1) by simp
  have hP: "A0 - X \<in> Pow(A0)" using Diff_subset unfolding Pow_iff .
  show "(A0 - X) \<notin> principal(A0,a)"
  proof (rule notI)
    assume "A0 - X \<in> principal(A0,a)"
    then have hp2: "A0 - X \<in> Pow(A0) \<and> a \<in> (A0 - X)"
      by (rule iffD1 [OF principal_iff])
    then have ha2: "a \<in> (A0 - X)" by (rule conjunct2)
    with hn show False by simp
  qed
next
  assume h2: "(A0 - X) \<notin> principal(A0,a)"
  have hP: "A0 - X \<in> Pow(A0)" using Diff_subset unfolding Pow_iff .
  have nax: "a \<notin> (A0 - X)"
  proof (rule notI)
    assume "a \<in> (A0 - X)"
    then have "A0 - X \<in> principal(A0,a)" using hP principal_iff by blast
    with h2 show False by simp
  qed
  from nax have "a \<in> X" using assms(1) by simp
  then show "X \<in> principal(A0,a)" using assms(2) principal_iff by blast
qed

text \<open>由 principal_inter_closed 与 principal_ultra_dich 加上平凡的
       上闭性，即得主超滤是超滤（组装为 47 章习题 2）。\<close>

end
