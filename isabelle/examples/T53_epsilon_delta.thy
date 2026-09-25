theory T53_epsilon_delta
  imports Complex_Main
begin

section \<open>53.1 ε-δ：分析的第一性原理\<close>

text \<open>第 46 章用滤子语言一行一个极限定理。本章反其道而行：
**剥掉滤子**，用裸的 ε-δ 定义亲手证极限与连续——这是 Cauchy/
Weierstraß 的原教旨分析，也是 HOL-Analysis 的
@{verbatim "(f <longlongrightarrow> L) F"} 在 @{verbatim "at a"} 情形下展开后
的真实形状。看清"一行滤子 = 十行 ε-δ"，再回看 46 章的抽象
就不玄了。\<close>

ML \<open>writeln "==== 53 开始 ===="\<close>

subsection \<open>53.2 收敛的 ε-定义与滤子定义的等价\<close>

definition converges_to :: "(nat \<Rightarrow> real) \<Rightarrow> real \<Rightarrow> bool" (infixl "\<longlongmapsto>" 50) where
  "s \<longlongmapsto> L \<longleftrightarrow> (\<forall>e > 0. \<exists>N. \<forall>n \<ge> N. \<bar>s n - L\<bar> < e)"

lemma conv_iff_tendsto: "(s \<longlongmapsto> L) \<longleftrightarrow> ((s \<longlongrightarrow> L) sequentially)"
  unfolding converges_to_def
  by (simp add: LIMSEQ_iff)

subsection \<open>53.3 和的极限：ε-N 的手工拼接\<close>

lemma conv_add_eps:
  assumes "s \<longlongmapsto> L" and "t \<longlongmapsto> M"
  shows "(\<lambda>n. s n + t n) \<longlongmapsto> L + M"
  unfolding converges_to_def
proof (intro allI impI)
  fix e :: real
  assume "e > 0"
  then have "e / 2 > 0" by simp
  from assms(1) \<open>e / 2 > 0\<close> obtain N1 where
    N1: "\<And>n. n \<ge> N1 \<Longrightarrow> \<bar>s n - L\<bar> < e / 2"
    unfolding converges_to_def by blast
  from assms(2) \<open>e / 2 > 0\<close> obtain N2 where
    N2: "\<And>n. n \<ge> N2 \<Longrightarrow> \<bar>t n - M\<bar> < e / 2"
    unfolding converges_to_def by blast
  have "\<forall>n \<ge> max N1 N2. \<bar>s n + t n - (L + M)\<bar> < e"
  proof (intro allI impI)
    fix n
    assume "n \<ge> max N1 N2"
    then have n1: "n \<ge> N1" and n2: "n \<ge> N2" by auto
    have "\<bar>s n + t n - (L + M)\<bar> \<le> \<bar>s n - L\<bar> + \<bar>t n - M\<bar>"
      using abs_triangle_ineq [of "s n - L" "t n - M"] by simp
    also have "... < e / 2 + e / 2" using N1 [OF n1] N2 [OF n2] by simp
    finally show "\<bar>s n + t n - (L + M)\<bar> < e" by simp
  qed
  then show "\<exists>N. \<forall>n \<ge> N. \<bar>s n + t n - (L + M)\<bar> < e" ..
qed

subsection \<open>53.4 一点处连续：ε-δ 的裸形\<close>

definition cont_at_eps :: "(real \<Rightarrow> real) \<Rightarrow> real \<Rightarrow> bool" where
  "cont_at_eps f a \<longleftrightarrow>
     (\<forall>e > 0. \<exists>d > 0. \<forall>x. x \<noteq> a \<longrightarrow> \<bar>x - a\<bar> < d \<longrightarrow> \<bar>f x - f a\<bar> < e)"

text \<open>注意 @{verbatim "x \<noteq> a"} 的"去心"：与滤子侧 @{verbatim "eventually_at"}
的形态逐字对齐（x = a 处 |f a - f a| = 0 < e 自动成立，加不加等价；
**但**写非去心版会让等价证明多一个 case-split，实测 auto 关不掉，
要手补 x = a 的平凡分支——对齐官方形态是最省事的路）。\<close>

lemma cont_eps_iff:
  "cont_at_eps f a \<longleftrightarrow> continuous (at a) f"
  unfolding cont_at_eps_def
  by (auto simp: continuous_at tendsto_iff eventually_at dist_real_def imp_conjL)

subsection \<open>53.5 有界闭区间上的一致连续（Bolzano 意义一瞥）\<close>

text \<open>紧性（Heine--Borel）是 46 章 @{verbatim "compact"} 的底座；
一致连续在其上是白给的（@{verbatim "uniformly_continuous_on_compact"}?），
这里只打印官方版作对照：\<close>

thm uniformly_continuous_on_def

subsection \<open>53.6 坑位清单（实测）\<close>

text \<open>1. ε-δ 手工证的体力在**三角不等式拼接**：e/2 + e/2 的
   拆法对每个算子不同（乘法用 min d1 d2 与界估计）。
2. @{verbatim "LIMSEQ_iff"} 是序列版滤子的展开定理——
   名字在不同版本里漂移过（@{verbatim "LIMSEQ_iff"}/
   @{verbatim "tendsto_iff_sequentially"}），报 undefined 先查
   @{verbatim "find_theorems eventually sequentially"}。
3. 连续的 ε-δ 形态与 @{verbatim "continuous (at a)"} 的等价
   在实数上要过 dist = abs 的化简（@{verbatim "real_norm_def"}）。
4. @{verbatim "max N1 N2"} 拼接两个"足够大"是标准动作，
   乘法情形换 @{verbatim "min"}（d 取小）+ 常数界。\<close>

thm conv_add_eps cont_eps_iff

ML \<open>writeln "==== 53 结束 ===="\<close>

end
