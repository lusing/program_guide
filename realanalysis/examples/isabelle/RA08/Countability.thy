theory Countability
  imports "HOL-Analysis.Analysis"
begin

(* 第 08 章 可数性：Isabelle 通道。
   双射的三条性质、ℤ 的交错枚举、布尔序列对角线、
   ℝ 与 (0,1) 不可数、ℚ 可数、可数并。
   源码约定：数学符号用 Isabelle 实体写法。 *)

(* ---------------- 8.1 势：双射的三条性质 ---------------- *)

lemma id_bij: "bij (id :: 'a \<Rightarrow> 'a)"
  by simp

lemma bij_converse:
  assumes "bij (f :: 'a \<Rightarrow> 'b)"
  shows "bij (inv f)"
  using assms by (simp add: bij_imp_bij_inv)

lemma bij_comp_trans:
  assumes "bij (f :: 'a \<Rightarrow> 'b)" "bij (g :: 'b \<Rightarrow> 'c)"
  shows "bij (g \<circ> f)"
  using assms by (rule bij_comp)

(* ---------------- 8.3 ℤ 的交错枚举 ---------------- *)

(* 偶数 n ↦ n/2，奇数 n ↦ -(n+1)/2。
   0↦0，1↦-1，2↦1，3↦-2，4↦2。
   与原书“从 1 起：1↦0，2↦1，3↦-1”只差下标平移。 *)
definition zig :: "nat \<Rightarrow> int" where
  "zig n = (if even n then int (n div 2) else - int ((n + 1) div 2))"

lemma zig_even: "zig (2 * k) = int k"
  by (simp add: zig_def)

lemma zig_odd: "zig (2 * k + 1) = - int (k + 1)"
  by (simp add: zig_def)

lemma zig_values:
  "zig 0 = 0" "zig 1 = -1" "zig 2 = 1" "zig 3 = -2" "zig 4 = 2" "zig 5 = -3"
  by (simp_all add: zig_def)

definition unzig :: "int \<Rightarrow> nat" where
  "unzig z = (if 0 \<le> z then nat (2 * z) else nat (- (2 * z) - 1))"

lemma zig_unzig: "zig (unzig z) = z"
proof (cases "0 \<le> z")
  case True
  have "unzig z = nat (2 * z)" by (simp add: unzig_def True)
  moreover have "nat (2 * z) = 2 * nat z"
    using True by (simp add: nat_mult_distrib)
  moreover have "zig (2 * nat z) = z"
    using True by (simp add: zig_even)
  ultimately show ?thesis by simp
next
  case False
  then have nz: "z < 0" by simp
  define k where "k = nat (- z - 1)"
  have zeq: "z = - int (k + 1)"
    using nz unfolding k_def by simp
  have "unzig z = 2 * k + 1"
    using nz zeq by (simp add: unzig_def)
  moreover have "zig (2 * k + 1) = - int (k + 1)"
    by (rule zig_odd)
  ultimately show ?thesis using zeq by simp
qed

lemma unzig_zig: "unzig (zig n) = n"
proof (cases "even n")
  case True
  then obtain k where nk: "n = 2 * k" by (metis evenE)
  have "zig n = int k"
    by (simp add: nk zig_even)
  moreover have "unzig (int k) = 2 * k"
    by (simp add: unzig_def)
  ultimately show ?thesis using nk by simp
next
  case False
  then obtain k where nk: "n = 2 * k + 1" by (metis oddE)
  have "zig n = zig (2 * k + 1)" by (simp add: nk)
  also have "zig (2 * k + 1) = - int (k + 1)" by (rule zig_odd)
  finally have zeq: "zig n = - int (k + 1)" .
  have "unzig (- int (k + 1)) = nat (2 * int (k + 1) - 1)"
    by (simp add: unzig_def)
  also have "nat (2 * int (k + 1) - 1) = 2 * k + 1"
    by simp
  finally have "unzig (zig n) = 2 * k + 1" using zeq by simp
  then show ?thesis using nk by simp
qed

lemma zig_bij: "bij zig"
  by (rule bij_betw_byWitness[where f'=unzig])
     (auto simp: zig_unzig unzig_zig)

(* ---------------- 8.4 对角线 ---------------- *)

lemma cantor_bool:
  "\<not> surj (f :: nat \<Rightarrow> nat \<Rightarrow> bool)"
proof
  assume s: "surj f"
  from s[unfolded surj_def, rule_format, of "\<lambda>n. \<not> f n n"]
  obtain n where eq: "(\<lambda>n. \<not> f n n) = f n" by blast
  from eq have "(\<lambda>n. \<not> f n n) n = f n n" by (rule fun_cong)
  then show False by simp
qed

lemma uncountable_reals: "uncountable (UNIV :: real set)"
  by (rule uncountable_UNIV_real)

lemma uncountable_unit_interval: "uncountable {0::real <..< 1}"
  by (simp add: uncountable_open_interval)

(* ---------------- 8.5 ℚ 可数、可数并 ---------------- *)

lemma countable_integers: "countable (UNIV :: int set)"
  by simp

lemma countable_rationals: "countable (UNIV :: rat set)"
  by simp

lemma countable_union_nat:
  assumes "\<And>n::nat. countable (E n)"
  shows "countable (\<Union>n. E n)"
  using assms by (simp add: countable_UN)

end
