theory Sup
  imports "HOL-Analysis.Analysis"
begin

(* 第 03 章 上确界：Isabelle/HOL 通道。
   原书定理 4.1 的 q 构造、上确界唯一性、开区间与序列值域的上确界。
   Isabelle 里实数的上确界算子是 Sup（条件完备格）。 *)

(* 原书定理 4.1 核心：p^2 < 2 的正数 p 可以被 q = (2p+2)/(p+2) 超过，
   且 q^2 仍小于 2。恒等式 q-p = (2-p^2)/(p+2)，q^2-2 = 2(p^2-2)/(p+2)^2。 *)
lemma q_trick_gt:
  fixes p :: "'a::linordered_field"
  assumes "0 < p" and "p^2 < 2"
  shows "\<exists>q. p < q \<and> q^2 < 2"
proof (intro exI[of _ "(2*p+2)/(p+2)"] conjI)
  have hpos: "0 < p + 2" using assms by simp
  have eq1: "p * (p + 2) = p*p + 2*p" by (simp add: algebra_simps)
  have pp: "p^2 = p*p" by (simp add: power2_eq_square)
  have lt: "p * (p + 2) < 2*p + 2" using eq1 pp assms(2) by linarith
  show "p < (2*p+2)/(p+2)"
    using lt by (simp add: pos_less_divide_eq[OF hpos])
  have e1: "(2*p+2)^2 = 4*p^2 + 8*p + 4" by (simp add: algebra_simps power2_eq_square)
  have e2: "2*(p+2)^2 = 2*p^2 + 8*p + 8" by (simp add: algebra_simps power2_eq_square)
  have key: "(2*p+2)^2 < 2*(p+2)^2" using e1 e2 assms(2) by linarith
  have hpos2: "0 < (p+2)^2" using hpos by simp
  show "((2*p+2)/(p+2))^2 < 2"
    using key by (simp add: power_divide pos_divide_less_eq[OF hpos2])
qed

(* 对偶：p^2 > 2 的正数 p 可以被更小的正数 q 替代，且 q^2 仍大于 2。
   也就是说 B = {p>0, p^2>2} 没有最小元。 *)
lemma q_trick_lt:
  fixes p :: "'a::linordered_field"
  assumes "0 < p" and "2 < p^2"
  shows "\<exists>q. 0 < q \<and> q < p \<and> 2 < q^2"
proof (intro exI[of _ "(2*p+2)/(p+2)"] conjI)
  have hpos: "0 < p + 2" using assms by simp
  show "0 < (2*p+2)/(p+2)" using assms hpos by simp
  have pp: "p^2 = p*p" by (simp add: power2_eq_square)
  have e3: "p*(p+2) = p^2 + 2*p" by (simp add: algebra_simps power2_eq_square)
  have "2*p + 2 < p*(p+2)" using e3 assms(2) by linarith
  then show "(2*p+2)/(p+2) < p"
    by (simp add: pos_divide_less_eq[OF hpos])
  have e1: "(2*p+2)^2 = 4*p^2 + 8*p + 4" by (simp add: algebra_simps power2_eq_square)
  have e2: "2*(p+2)^2 = 2*p^2 + 8*p + 8" by (simp add: algebra_simps power2_eq_square)
  have key: "2*(p+2)^2 < (2*p+2)^2" using e1 e2 assms(2) by linarith
  have hpos2: "0 < (p+2)^2" using hpos by simp
  show "2 < ((2*p+2)/(p+2))^2"
    using key by (simp add: power_divide pos_less_divide_eq[OF hpos2])
qed

(* 上确界定义（原书定义 4.7）：a 是 S 的上界，且不超过任何上界。
   自包含定义，直接对应书上的两段式。 *)
definition is_lub :: "'a::order set \<Rightarrow> 'a \<Rightarrow> bool" where
  "is_lub S a \<equiv> (\<forall>x \<in> S. x \<le> a) \<and> (\<forall>b. (\<forall>x \<in> S. x \<le> b) \<longrightarrow> a \<le> b)"

definition is_glb :: "'a::order set \<Rightarrow> 'a \<Rightarrow> bool" where
  "is_glb S \<beta> \<equiv> (\<forall>x \<in> S. \<beta> \<le> x) \<and> (\<forall>\<gamma>. (\<forall>x \<in> S. \<gamma> \<le> x) \<longrightarrow> \<gamma> \<le> \<beta>)"

(* 上确界唯一性：两个上确界互相不超过对方。 *)
lemma sup_unique:
  fixes a b :: real
  assumes "is_lub S a" and "is_lub S b"
  shows "a = b"
  using assms unfolding is_lub_def by (metis order.antisym)

(* 开区间的上确界是右端点（cSup_greaterThanLessThan 是 simp 规则）。 *)
lemma sup_Ioo:
  fixes a b :: real
  assumes "a < b"
  shows "Sup {a<..<b} = b"
  using assms by simp

(* 序列值域的上确界：Sup {1 - 1/(n+1) | n} = 1。
   最小性靠反证：b < 1 时取 n 使 1/(n+1) < 1-b，则第 n 项超过 b。 *)
lemma range_sup_one: "Sup (range (\<lambda>n. 1 - 1/(real n + 1))) = (1::real)"
proof (rule order.antisym)
  have bd: "bdd_above (range (\<lambda>n. 1 - 1/(real n + 1)))"
    by (auto intro!: bdd_aboveI[of _ 1])
  show "Sup (range (\<lambda>n. 1 - 1/(real n + 1))) \<le> (1::real)"
    by (rule cSup_least) auto
  show "(1::real) \<le> Sup (range (\<lambda>n. 1 - 1/(real n + 1)))"
  proof (rule ccontr)
    assume "\<not> (1::real) \<le> Sup (range (\<lambda>n. 1 - 1/(real n + 1)))"
    then have hs: "Sup (range (\<lambda>n. 1 - 1/(real n + 1))) < 1" by simp
    have hpos: "0 < 1 - Sup (range (\<lambda>n. 1 - 1/(real n + 1)))"
      using hs by simp
    from ex_inverse_of_nat_less [OF hpos] obtain n
      where npos: "0 < n"
        and hn: "inverse (real n) < 1 - Sup (range (\<lambda>n. 1 - 1/(real n + 1)))"
      by auto
    have hle: "1 / (real n + 1) \<le> 1 / real n"
      by (rule frac_le[of 1 1 "real n" "real n + 1"]) (simp_all add: npos)
    define y where "y = 1 - 1/(real n + 1)"
    have hy: "y \<in> range (\<lambda>n. 1 - 1/(real n + 1))" unfolding y_def by auto
    have inv_eq: "inverse (real n) = 1 / real n" by (rule inverse_eq_divide)
    have lt: "Sup (range (\<lambda>n. 1 - 1/(real n + 1))) < y"
      using hn hle inv_eq by (unfold y_def) linarith
    moreover have "y \<le> Sup (range (\<lambda>n. 1 - 1/(real n + 1)))"
      by (rule cSup_upper[OF hy bd])
    ultimately show False by simp
  qed
qed

(* 定理 4.9：属于集合的上界就是上确界。 *)
lemma upper_bound_mem_is_lub:
  fixes a :: "'a::order"
  assumes "a \<in> S" and "\<forall>x \<in> S. x \<le> a"
  shows "is_lub S a"
  using assms unfolding is_lub_def by auto

(* 例 4.8：{1/(n+1)} 的上确界是 1，因为 1 属于值域且是上界。 *)
lemma one_div_sup: "is_lub (range (\<lambda>n::nat. 1 / (real n + 1))) (1::real)"
proof -
  have mem: "1 \<in> range (\<lambda>n::nat. 1 / (real n + 1))"
    by (intro range_eqI[of _ _ 0]) simp
  have ub: "\<forall>x \<in> range (\<lambda>n::nat. 1 / (real n + 1)). x \<le> (1::real)"
    by (auto simp: divide_le_eq_1_pos)
  show ?thesis using upper_bound_mem_is_lub[OF mem ub] .
qed

(* 例 4.8 的下确界：0 是下界，任何正数都会被某个 1/n 钻穿。 *)
lemma one_div_inf: "is_glb (range (\<lambda>n::nat. 1 / (real n + 1))) (0::real)"
proof -
  have lb: "\<forall>x \<in> range (\<lambda>n::nat. 1 / (real n + 1)). (0::real) \<le> x"
    by auto
  have greatest: "\<forall>\<gamma>. (\<forall>x \<in> range (\<lambda>n::nat. 1 / (real n + 1)). \<gamma> \<le> x) \<longrightarrow> \<gamma> \<le> (0::real)"
  proof (intro allI impI)
    fix \<gamma> :: real
    assume H: "\<forall>x \<in> range (\<lambda>n::nat. 1 / (real n + 1)). \<gamma> \<le> x"
    show "\<gamma> \<le> 0"
    proof (rule ccontr)
      assume "\<not> \<gamma> \<le> 0"
      then have "0 < \<gamma>" by simp
      from ex_inverse_of_nat_less[OF this] obtain n
        where npos: "0 < n" and hn: "inverse (real n) < \<gamma>" by auto
      have eq: "1 / real n = 1 / (real (n - 1) + 1)" using npos by simp
      have mem: "1 / real n \<in> range (\<lambda>n::nat. 1 / (real n + 1))"
        by (subst eq) (rule range_eqI[of _ _ "n - 1"], simp)
      have "\<gamma> \<le> 1 / real n" using H mem by blast
      moreover have "1 / real n < \<gamma>" using hn by (simp add: inverse_eq_divide)
      ultimately show False by simp
    qed
  qed
  show ?thesis unfolding is_glb_def using lb greatest by blast
qed

(* √2 不是有理数：m/n = √2 推出 m、n 都是偶数，与互素矛盾。 *)
lemma sqrt_2_not_rat: "sqrt 2 \<notin> \<rat>"
proof
  assume "sqrt 2 \<in> \<rat>"
  then obtain m n :: nat
    where n0: "n \<noteq> 0"
      and eq0: "\<bar>sqrt 2\<bar> = m / n"
      and cop: "coprime m n"
    by (rule Rats_abs_nat_div_natE)
  from n0 eq0 have "real m = sqrt 2 * real n"
    by (simp add: abs_of_nonneg field_simps)
  then have "(real m)\<^sup>2 = (sqrt 2)\<^sup>2 * (real n)\<^sup>2"
    by (simp add: power_mult_distrib power2_eq_square)
  also have "(sqrt 2)\<^sup>2 = 2" by simp
  also have "2 * (real n)\<^sup>2 = real (2 * n\<^sup>2)"
    by (simp add: of_nat_mult of_nat_power)
  finally have "real (m\<^sup>2) = real (2 * n\<^sup>2)"
    by (simp add: of_nat_power)
  then have eq: "m\<^sup>2 = 2 * n\<^sup>2" by (simp only: of_nat_eq_iff)
  then have "even (m\<^sup>2)" by simp
  then have "even m" by simp
  then obtain k where mk: "m = 2 * k" using evenE by blast
  with eq have "n\<^sup>2 = 2 * k\<^sup>2"
    by (simp add: power2_eq_square)
  then have "even (n\<^sup>2)" by simp
  then have "even n" by simp
  from \<open>even m\<close> \<open>even n\<close> have "2 dvd gcd m n"
    by (rule gcd_greatest)
  with cop have "(2::nat) dvd 1" by simp
  then show False by simp
qed

lemma rat_sq_ne_two:
  fixes q :: rat
  shows "q\<^sup>2 \<noteq> 2"
proof
  assume hsq: "q\<^sup>2 = 2"
  have "(of_rat q :: real)\<^sup>2 = of_rat (q\<^sup>2)"
    by (simp add: of_rat_power)
  also have "of_rat (q\<^sup>2) = of_rat (2::rat)" by (simp add: hsq)
  also have "of_rat (2::rat) = (2::real)" by simp
  finally have "(of_rat q :: real)\<^sup>2 = 2" .
  then have "sqrt 2 = (of_rat \<bar>q\<bar> :: real)"
    by (metis abs_ge_zero abs_of_rat power2_abs real_sqrt_unique)
  then have "sqrt 2 \<in> \<rat>" by simp
  with sqrt_2_not_rat show False by simp
qed

(* 例 4.11：A = {p ∈ ℚ | p > 0 ∧ p² < 2} 在 ℚ 中没有上确界。 *)
lemma hole_no_lub: "\<nexists>a::rat. is_lub {p. 0 < p \<and> p\<^sup>2 < 2} a"
proof
  assume "\<exists>a::rat. is_lub {p. 0 < p \<and> p\<^sup>2 < 2} a"
  then obtain a where ha: "is_lub {p::rat. 0 < p \<and> p\<^sup>2 < 2} a" by blast
  have one_in: "(1::rat) \<in> {p. 0 < p \<and> p\<^sup>2 < 2}" by simp
  from ha one_in have "1 \<le> a" unfolding is_lub_def by blast
  then have apos: "0 < a" by simp
  show False
  proof (cases rule: linorder_cases[of "a\<^sup>2" 2])
    case less
    from q_trick_gt[OF apos less] obtain q where q: "a < q" "q\<^sup>2 < 2" by blast
    then have "q \<in> {p::rat. 0 < p \<and> p\<^sup>2 < 2}" using apos by simp
    with ha q(1) show False unfolding is_lub_def
      by (meson dual_order.strict_iff_not)
  next
    case equal
    then show False using rat_sq_ne_two[of a] by simp
  next
    case greater
    from q_trick_lt[OF apos greater] obtain q
      where q: "0 < q" "q < a" "2 < q\<^sup>2" by blast
    have qub: "\<forall>p. 0 < p \<and> p\<^sup>2 < 2 \<longrightarrow> p \<le> q"
    proof (intro allI impI)
      fix p :: rat
      assume "0 < p \<and> p\<^sup>2 < 2"
      then have plt: "p\<^sup>2 < q\<^sup>2" using q(3) by simp
      have "0 \<le> q" using q(1) by simp
      with plt have "p < q" by (rule power2_less_imp_less)
      then show "p \<le> q" by simp
    qed
    with ha have "a \<le> q" unfolding is_lub_def by auto
    with q(2) show False by simp
  qed
qed

(* 定理 4.12：最小上界性推出最大下界性，且 inf B = sup (下界集)。 *)
lemma glb_from_lub:
  fixes B :: "real set"
  assumes complete: "\<And>S::real set. S \<noteq> {} \<Longrightarrow> bdd_above S \<Longrightarrow> \<exists>a. is_lub S a"
    and ne: "B \<noteq> {}" and bb: "bdd_below B"
  shows "\<exists>\<beta>. is_lub {x. \<forall>y\<in>B. x \<le> y} \<beta> \<and> is_glb B \<beta>"
proof -
  let ?L = "{x. \<forall>y\<in>B. x \<le> y}"
  from bb obtain m where "\<forall>y\<in>B. m \<le> y" unfolding bdd_below_def by blast
  then have Lne: "?L \<noteq> {}" by auto
  from ne obtain b0 where b0: "b0 \<in> B" by blast
  have Lba: "bdd_above ?L"
  proof -
    have "\<forall>x\<in>?L. x \<le> b0" using b0 by auto
    then show ?thesis unfolding bdd_above_def by blast
  qed
  from complete[of ?L, OF Lne Lba] obtain \<beta> where \<beta>: "is_lub ?L \<beta>" by blast
  have low: "\<forall>y\<in>B. \<beta> \<le> y"
  proof
    fix y assume "y \<in> B"
    then have "\<forall>x\<in>?L. x \<le> y" by auto
    with \<beta> show "\<beta> \<le> y" unfolding is_lub_def by blast
  qed
  have great: "\<forall>\<gamma>. (\<forall>y\<in>B. \<gamma> \<le> y) \<longrightarrow> \<gamma> \<le> \<beta>"
  proof (intro allI impI)
    fix \<gamma> assume "\<forall>y\<in>B. \<gamma> \<le> y"
    then have "\<gamma> \<in> ?L" by simp
    with \<beta> show "\<gamma> \<le> \<beta>" unfolding is_lub_def by blast
  qed
  show ?thesis
  proof (intro exI conjI)
    show "is_lub ?L \<beta>" by (rule \<beta>)
    show "is_glb B \<beta>" unfolding is_glb_def using low great by blast
  qed
qed

(* ℝ 的条件完备性填上定理 4.12 的假设，于是每个非空有下界集都有下确界。 *)
lemma real_glb_exists:
  fixes B :: "real set"
  assumes "B \<noteq> {}" "bdd_below B"
  shows "\<exists>\<beta>. is_glb B \<beta>"
proof -
  have complete: "\<And>S::real set. S \<noteq> {} \<Longrightarrow> bdd_above S \<Longrightarrow> \<exists>a. is_lub S a"
  proof -
    fix S :: "real set"
    assume neS: "S \<noteq> {}" and ba: "bdd_above S"
    show "\<exists>a. is_lub S a"
    proof (intro exI)
      show "is_lub S (Sup S)"
        unfolding is_lub_def
      proof
        show "\<forall>x\<in>S. x \<le> Sup S"
          using cSup_upper ba by blast
        show "\<forall>b. (\<forall>x\<in>S. x \<le> b) \<longrightarrow> Sup S \<le> b"
          using cSup_least neS by blast
      qed
    qed
  qed
  from glb_from_lub[OF complete assms] show ?thesis by blast
qed

end
