theory Proper
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 107 章：主条件证书的集论核（确定性规则链，沿 103-106 章纪律）。
本体（命题 2.1、引理 2.22-2.24、定理 2.13/2.14）留在正文。\<close>

text \<open>相容：两条件有公共延展（以延展集给出的偏序数据）。\<close>

definition CompatP :: "[i, i] \<Rightarrow> o" where
  "CompatP(r, p) \<equiv> r \<inter> p \<noteq> 0"

text \<open>A 在 q 之下准稠密：一切 r 延展 q 与 A 中某元素相容。\<close>

definition PredenseBelowP :: "[i, i] \<Rightarrow> o" where
  "PredenseBelowP(A, q) \<equiv> \<forall>r\<in>q. \<exists>p\<in>A. CompatP(r, p)"

text \<open>(M,P)-泛型条件证书（定义 2.21 的集论核）。\<close>

definition GenericCondP :: "[i, i] \<Rightarrow> o" where
  "GenericCondP(AA, q) \<equiv> \<forall>A\<in>AA. PredenseBelowP(A, q)"

lemma predenseI:
  assumes h: "\<And>r. r \<in> q \<Longrightarrow> \<exists>p\<in>A. CompatP(r, p)"
  shows "PredenseBelowP(A, q)"
  unfolding PredenseBelowP_def
proof (rule ballI)
  fix r
  assume hr: "r \<in> q"
  from h [OF hr] show "\<exists>p\<in>A. CompatP(r, p)" .
qed

lemma genericI:
  assumes h: "\<And>A. A \<in> AA \<Longrightarrow> PredenseBelowP(A, q)"
  shows "GenericCondP(AA, q)"
  unfolding GenericCondP_def
proof (rule ballI)
  fix A
  assume hA: "A \<in> AA"
  from h [OF hA] show "PredenseBelowP(A, q)" .
qed

text \<open>更强的条件保持证书：q' 延展 q（延展集含于）⟹ 证书下放
（Task 22 Step 2：条件复合保持证书）。\<close>

lemma generic_strengthen:
  assumes hsub: "q' \<subseteq> q"
    and h: "GenericCondP(AA, q)"
  shows "GenericCondP(AA, q')"
proof (rule genericI)
  fix A
  assume hA: "A \<in> AA"
  from h hA have hP: "PredenseBelowP(A, q)" unfolding GenericCondP_def by (rule bspec)
  show "PredenseBelowP(A, q')"
  proof (rule predenseI)
    fix r
    assume hr: "r \<in> q'"
    from hsub hr have hrq: "r \<in> q" by (rule subsetD)
    from hP [unfolded PredenseBelowP_def] hrq show "\<exists>p\<in>A. CompatP(r, p)"
      by (rule bspec)
  qed
qed

text \<open>链样本（确定性链）：q 的每个延展都含 p（链）
\<Longrightarrow> {p} 在 q 之下准稠密。\<close>

lemma chain_predense:
  assumes hchain: "\<forall>r\<in>q. p \<subseteq> r" and hp0: "p \<noteq> 0"
  shows "PredenseBelowP({p}, q)"
proof (rule predenseI)
  fix r
  assume hr: "r \<in> q"
  from hchain hr have hpr: "p \<subseteq> r" by (rule bspec)
  show "\<exists>p'\<in>{p}. CompatP(r, p')"
  proof (rule bexI [where x = p])
    show "CompatP(r, p)" unfolding CompatP_def
    proof (rule notI)
      assume hempty: "r \<inter> p = 0"
      have hsub1: "p \<subseteq> r \<inter> p"
        by (rule Int_greatest [OF hpr subset_refl])
      from hempty hsub1 have hsub2: "p \<subseteq> 0" by (rule subst)
      then have "p = 0" by (rule subset_empty_iff [THEN iffD1])
      from hp0 this show False by (rule notE)
    qed
  next
    show "p \<in> {p}" by (rule singletonI)
  qed
qed

end
