theory Sets
  imports "HOL-Analysis.Analysis"
begin

(* 第 02 章 集合论：Isabelle/HOL 通道。HOL 的集合就是特征谓词 'a \<Rightarrow> bool，
   成员级推理大多可被 auto/blast 自动完成。
   源码约定：数学符号一律用 Isabelle 实体写法。 *)

(* 定理 3.7：空集是任何集合的子集。 *)
lemma empty_subset_any: "{} \<subseteq> (A::'a set)"
  by simp

(* 定理 3.12 性质 4/5：分配律。 *)
lemma union_inter_distrib:
  "A \<union> (B \<inter> C) = (A \<union> B) \<inter> (A \<union> C)"
  by auto

lemma inter_union_distrib:
  "A \<inter> (B \<union> C) = (A \<inter> B) \<union> (A \<inter> C)"
  by auto

(* 定理 3.17 德摩根律：两集合版与索引族版。 *)
lemma de_morgan_union: "- (A \<union> B) = -A \<inter> -B"
  by auto

lemma de_morgan_inter: "- (A \<inter> B) = -A \<union> -B"
  by auto

lemma de_morgan_iunion: "- (\<Union>i. E i) = (\<Inter>i. - E i)"
  by auto

lemma de_morgan_iinter: "- (\<Inter>i. E i) = (\<Union>i. - E i)"
  by auto

(* 区间即集合：(1,3) \<inter> (3,5) = 空集，端点 3 不属于任何一个开区间。 *)
lemma open_intervals_disjoint:
  "{1<..<3::real} \<inter> {3<..<5} = {}"
  by auto

(* (1,3) \<union> (3,5) \<noteq> (1,5)：点 3 是漏洞。 *)
lemma open_interval_union_gap:
  "{1<..<3::real} \<union> {3<..<5} \<noteq> {1<..<5}"
proof
  assume h: "{1<..<3::real} \<union> {3<..<5} = {1<..<5::real}"
  have h3: "(3::real) \<in> {1<..<5}" by simp
  then have "(3::real) \<in> {1<..<3} \<union> {3<..<5}" using h by simp
  then show False by auto
qed

(* 反复用到的边界引理：单位分数 1/(n+1) \<le> 1。
   frac_le : 0 \<le> y \<Longrightarrow> x \<le> y \<Longrightarrow> 0 < w \<Longrightarrow> w \<le> z \<Longrightarrow> x / z \<le> y / w。 *)
lemma one_div_succ_le: "1 / (real n + 1) \<le> (1::real)"
proof -
  have "(1::real) / (real n + 1) \<le> 1 / 1"
    by (rule frac_le) simp_all
  then show ?thesis by simp
qed

(* 例 3.14 之一：A n = (-1/(n+1), 1/(n+1))，嵌套递减族的并 = A 0 = (-1,1)。 *)
definition Aseq :: "nat \<Rightarrow> real set" where
  "Aseq n = {- 1/(real n + 1) <..< 1/(real n + 1)}"

lemma union_Aseq: "(\<Union>n. Aseq n) = {-1<..<1::real}"
proof (rule set_eqI, rule iffI)
  fix x
  assume "x \<in> (\<Union>n. Aseq n)"
  then obtain n where hn: "x \<in> Aseq n" by auto
  have hle: "1 / (real n + 1) \<le> 1" by (rule one_div_succ_le)
  from hn have bounds: "- (1/(real n + 1)) < x \<and> x < 1/(real n + 1)"
    unfolding Aseq_def by auto
  have "-1 < x \<and> x < 1" using bounds hle by linarith
  then show "x \<in> {-1<..<1::real}" by auto
next
  fix x
  assume h: "x \<in> {-1<..<1::real}"
  have "x \<in> Aseq 0" unfolding Aseq_def using h by simp
  then show "x \<in> (\<Union>n. Aseq n)" by auto
qed

(* 例 3.14 之三：B n = [0, 2-1/(n+1)]，递增族的交 = B 0 = [0,1]。 *)
definition Bseq :: "nat \<Rightarrow> real set" where
  "Bseq n = {0 .. 2 - 1/(real n + 1)}"

lemma inter_Bseq: "(\<Inter>n. Bseq n) = {0..1::real}"
proof (rule set_eqI, rule iffI)
  fix x
  assume "x \<in> (\<Inter>n. Bseq n)"
  then have "x \<in> Bseq 0" by auto
  then show "x \<in> {0..1::real}" unfolding Bseq_def by simp
next
  fix x
  assume h: "x \<in> {0..1::real}"
  then have hx0: "0 \<le> x" and hx1: "x \<le> 1" by simp_all
  show "x \<in> (\<Inter>n. Bseq n)"
  proof clarify
    fix n
    have hle: "1 / (real n + 1) \<le> 1" by (rule one_div_succ_le)
    have "x \<le> 2 - 1/(real n + 1)" using hx1 hle by linarith
    with hx0 show "x \<in> Bseq n" unfolding Bseq_def by auto
  qed
qed

(* 例 3.14 之二：递增族的并 = [0,2)。点 2 不被任何有限 n 捕获；
   反向包含靠 Archimedean 性质（ex_inverse_of_nat_less）找足够大的 n。 *)
lemma union_Bseq: "(\<Union>n. Bseq n) = {0..<2::real}"
proof (rule set_eqI, rule iffI)
  fix x
  assume "x \<in> (\<Union>n. Bseq n)"
  then obtain n where hn: "x \<in> Bseq n" by auto
  have hfrac: "0 < 1 / (real n + 1)" by simp
  from hn have bounds: "0 \<le> x \<and> x \<le> 2 - 1/(real n + 1)"
    unfolding Bseq_def by auto
  have "x < 2" using bounds hfrac by linarith
  then show "x \<in> {0..<2::real}" using bounds by auto
next
  fix x
  assume h: "x \<in> {0..<2::real}"
  then have hx0: "0 \<le> x" and hx2: "x < 2" by simp_all
  have hpos: "0 < 2 - x" using hx2 by simp
  from ex_inverse_of_nat_less [OF hpos] obtain n
    where npos: "0 < n" and hn: "inverse (real n) < 2 - x" by auto
  have key: "1 / (real n + 1) < 2 - x"
  proof -
    have "1 / (real n + 1) \<le> 1 / real n"
      by (rule frac_le[of 1 1 "real n" "real n + 1"]) (simp_all add: npos)
    also have "1 / real n < 2 - x" using hn by (simp add: inverse_eq_divide)
    finally show ?thesis .
  qed
  have "x \<le> 2 - 1/(real n + 1)" using key by linarith
  with hx0 have "x \<in> Bseq n" unfolding Bseq_def by auto
  then show "x \<in> (\<Union>n. Bseq n)" by auto
qed

end
