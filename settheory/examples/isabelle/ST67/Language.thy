theory Language
  imports "ZF"
begin

text \<open>第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）。
公理实名制（ZF\_Base.thy 的 axiomatization）、命题 1.1 双包含、
定理 1.2 有序对、例 1.4 万有集不存在、定义 1.23 分离规则。\<close>

subsection \<open>公理实名制（书页 29-32 的公理 1-7）\<close>

text \<open>ZF object-logic 的公理在 ZF\_Base.thy 中逐条声明，可直接引用：
\<^item> extension : A = B \<longleftrightarrow> A \<subseteq> B \<and> B \<subseteq> A（公理 1 同一律）
\<^item> infinity : 0 \<in> Inf \<and> (\<forall>y\<in>Inf. succ(y) \<in> Inf)（公理 7）
\<^item> upair / Union / Pow / replacement（配对、并集、幂集、替换）\<close>

subsection \<open>命题 1.1：同一律即双包含\<close>

lemma prop_1_1: "A = B \<longleftrightarrow> A \<subseteq> B \<and> B \<subseteq> A"
  by (rule extension)

subsection \<open>命题 1.2：幂集唯一性（三步舞：存在→唯一→命名）\<close>

lemma pow_unique:
  assumes H1: "\<forall>z. z \<in> Y1 \<longleftrightarrow> z \<subseteq> X"
      and H2: "\<forall>z. z \<in> Y2 \<longleftrightarrow> z \<subseteq> X"
  shows "Y1 = Y2"
proof (rule equalityI)
  show "Y1 \<subseteq> Y2"
  proof (rule subsetI)
    fix z assume "z \<in> Y1"
    with H1 have "z \<subseteq> X" by blast
    with H2 show "z \<in> Y2" by blast
  qed
next
  show "Y2 \<subseteq> Y1"
  proof (rule subsetI)
    fix z assume "z \<in> Y2"
    with H2 have "z \<subseteq> X" by blast
    with H1 show "z \<in> Y1" by blast
  qed
qed

subsection \<open>定理 1.2：有序对由分量决定（Kuratowski）\<close>

lemma pair_inj: "\<langle>a, b\<rangle> = \<langle>c, d\<rangle> \<longleftrightarrow> a = c \<and> b = d"
  by (rule Pair_iff)

subsection \<open>例 1.4：万有集合不存在（分解原理版罗素）\<close>

theorem no_universal_set: "\<not>(\<exists>a. \<forall>y. y \<in> a)"
proof
  assume "\<exists>a. \<forall>y. y \<in> a"
  then obtain a where A: "\<forall>y. y \<in> a" ..
  let ?R = "{x \<in> a. x \<notin> x}"
  have Ra: "?R \<in> a" using A by blast
  have H: "?R \<in> ?R \<longleftrightarrow> ?R \<notin> ?R"
  proof
    assume "?R \<in> ?R"
    thus "?R \<notin> ?R" by (blast dest: CollectD2)
  next
    assume "?R \<notin> ?R"
    with Ra show "?R \<in> ?R" by (blast intro: CollectI)
  qed
  have em: "?R \<notin> ?R \<or> ?R \<in> ?R" by (rule excluded_middle)
  then show False
  proof
    assume Q: "?R \<notin> ?R"
    have P: "?R \<in> ?R" by (rule iffD2 [OF H Q])
    from Q P show False by (rule notE)
  next
    assume P: "?R \<in> ?R"
    have Q: "?R \<notin> ?R" by (rule iffD1 [OF H P])
    from Q P show False by (rule notE)
  qed
qed

subsection \<open>定义 1.23：分离规则（租借逻辑的唯一推理规则）\<close>

lemma modus_ponens: assumes "P \<longrightarrow> Q" and "P" shows "Q"
  by (rule mp [OF assms(1) assms(2)])

end
