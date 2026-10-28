theory Levy
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 103 章：Lévy 条件作为（键, 值）对的集合——功能性、相容性
与拼接（后侧去掉已覆盖键）。证明全用确定性规则链（bspec/mp/notE）：
ZF 的 fst/snd 是 THE-定义，blast 对其等式的反向搜索不终止。
Col(ω,<κ) 的 κ-链条件与定理 2.2/2.3 留在正文；其余通道承载
稠密性 D(λ,β) 的书式新鲜槽号。\<close>

text \<open>功能性：同一键至多一个值（部分函数）。\<close>

definition functP :: "i \<Rightarrow> o" where
  "functP(p) \<equiv> \<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"

text \<open>相容：公共键上取值一致。\<close>

definition compatP :: "[i, i] \<Rightarrow> o" where
  "compatP(p, q) \<equiv> \<forall>x\<in>p. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"

text \<open>拼接：q 中去掉已被 p 覆盖的键后取并。\<close>

definition unionP :: "[i, i] \<Rightarrow> i" where
  "unionP(p, q) \<equiv> p \<union> {y \<in> q . \<forall>x \<in> p . fst(x) \<noteq> fst(y)}"

lemma unionP_left: "x \<in> p \<Longrightarrow> x \<in> unionP(p, q)"
  unfolding unionP_def by (rule UnI1)

lemma unionP_memD:
  assumes hx: "x \<in> unionP(p, q)"
  shows "x \<in> p \<or> (x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x)))"
proof -
  from hx have hu: "x \<in> p \<or> x \<in> {y \<in> q . \<forall>z \<in> p . fst(z) \<noteq> fst(y)}"
    unfolding unionP_def by (rule Un_iff [THEN iffD1])
  from hu show ?thesis
  proof
    assume h: "x \<in> p"
    thus ?thesis by (rule disjI1)
  next
    assume h: "x \<in> {y \<in> q . \<forall>z \<in> p . fst(z) \<noteq> fst(y)}"
    hence hs: "x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x))"
      by (rule separation [THEN iffD1])
    thus ?thesis by (rule disjI2)
  qed
qed

lemma unionP_funct:
  assumes "functP(p)" "functP(q)" "compatP(p, q)"
  shows "functP(unionP(p, q))"
proof -
  from assms(1) have hp: "\<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  from assms(2) have hq: "\<forall>x\<in>q. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  from assms(3) have hc: "\<forall>x\<in>p. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding compatP_def .
  show ?thesis
    unfolding functP_def
  proof (intro ballI ballI impI)
    fix x y
    assume hx: "x \<in> unionP(p, q)" and hy: "y \<in> unionP(p, q)"
      and hxy: "fst(x) = fst(y)"
    from unionP_memD hx have dx: "x \<in> p \<or> (x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x)))" .
    from unionP_memD hy have dy: "y \<in> p \<or> (y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y)))" .
    from dx show "snd(x) = snd(y)"
    proof
      assume ax: "x \<in> p"
      from dy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have h1: "\<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hp ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      next
        assume ay: "y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y))"
        have hq1: "\<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hc ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hq1 ay [THEN conjunct1]])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      qed
    next
      assume ax: "x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x))"
      from dy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have hne: "fst(y) \<noteq> fst(x)"
          by (rule ax [THEN conjunct2, rule_format, OF ay])
        from hxy have hyx: "fst(y) = fst(x)" by (rule sym)
        from hne hyx have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      next
        assume ay: "y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y))"
        have h1: "\<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hq ax [THEN conjunct1]])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay [THEN conjunct1]])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      qed
    qed
  qed
qed

text \<open>扩展：新鲜键处加值保持功能性——稠密性 D(λ,β) 的集论核。\<close>

lemma extend_funct:
  assumes "functP(p)" and fresh: "\<forall>x \<in> p . fst(x) \<noteq> fst(t)"
  shows "functP(p \<union> {t})"
proof -
  from assms(1) have hp: "\<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  show ?thesis
    unfolding functP_def
  proof (intro ballI ballI impI)
    fix x y
    assume hx: "x \<in> p \<union> {t}" and hy: "y \<in> p \<union> {t}"
      and hxy: "fst(x) = fst(y)"
    from hx have sx: "x \<in> p \<or> x = t" by auto
    from hy have sy: "y \<in> p \<or> y = t" by auto
    from sx show "snd(x) = snd(y)"
    proof
      assume ax: "x \<in> p"
      from sy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have h1: "\<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hp ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      next
        assume ay: "y = t"
        have hne: "fst(x) \<noteq> fst(t)" by (rule bspec [OF fresh ax])
        from hxy ay have heq: "fst(x) = fst(t)" by simp
        from hne heq have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      qed
    next
      assume ax: "x = t"
      from sy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have hne: "fst(y) \<noteq> fst(t)" by (rule bspec [OF fresh ay])
        from hxy ax have heq: "fst(y) = fst(t)" by simp
        from hne heq have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      next
        assume ay: "y = t"
        from ax ay show "snd(x) = snd(y)" by simp
      qed
    qed
  qed
qed

end
