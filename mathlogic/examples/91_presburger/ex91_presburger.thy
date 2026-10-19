(* ex91 —— 简化版本的自然数模型（郝 ch8）Isabelle 侧账本
   主角是 presburger 战术现场：书的断言在 Isabelle 内建 Cooper 算法
   面前一行清账。另附 8.5.7 加法可定义恒等式（algebra_simps 展开 +
   消去）与鸽笼账（card 版——无有限后继模型）。 *)
theory ex91_presburger
  imports Main
begin

text \<open>---------- 1. 定理 8.3.1 的断言账：L_s = {0,S} ----------\<close>

lemma Scancel: fixes x y k :: nat shows "x + k = y + k \<Longrightarrow> x = y"
  by presburger

lemma no_cycle: fixes x k :: nat shows "x + (k + 1) \<noteq> x"
  by presburger

text \<open>断言 3 的语义核（bump 引理）\<close>
lemma bump_sem: fixes k m t u :: nat shows "(\<exists>x. x + k = t \<and> x + m = u) \<longleftrightarrow> (t + m = u + k \<and> k \<le> t)"
  by presburger

text \<open>---------- 2. 定理 8.4.1 断言 4/5 的语义核 ----------\<close>

lemma min_witness: fixes w u :: nat shows "(\<exists>x. w < x \<and> x < u) \<longleftrightarrow> (w + 1 < u)"
  by presburger

lemma zero_witness: fixes u :: nat shows "(\<exists>x. x < u) \<longleftrightarrow> (1 \<le> u)"
  by presburger

text \<open>---------- 3. D1/D2 奇偶账：Presburger 战术现场 ----------\<close>

lemma even_or_odd: "\<forall>x::nat. \<exists>m. x = 2 * m \<or> x = 2 * m + 1"
  by presburger

lemma not_both: "\<not> (\<exists>x m k::nat. x = 2 * m \<and> x = 2 * k + 1)"
  by presburger

text \<open>Presburger 定理（8.5.1）的一口气现场：带同余的存在消去\<close>
lemma cong_elim: "\<forall>x::nat. \<exists>y. y + y = x \<or> y + y + 1 = x"
  by presburger

lemma cong_elim2: "\<forall>x::nat. \<exists>y. x = 3 * y \<longrightarrow> (\<exists>z. x = z + z + z)"
  by presburger

text \<open>---------- 4. 习题 8.5.7：加法在 (N,S,×) 中可定义 ----------\<close>

lemma id857_core: fixes a b c :: nat shows
  "(a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 \<longleftrightarrow> c * (a + b) = c * c"
proof -
  have "(a * c + 1) * (b * c + 1) = a * b * (c * c) + (a * c + b * c) + 1"
    by (simp add: algebra_simps)
  moreover have "c * c * (a * b + 1) + 1 = a * b * (c * c) + c * c + 1"
    by (simp add: algebra_simps)
  ultimately show ?thesis by (simp add: algebra_simps)
qed

lemma id857: fixes a b c :: nat shows
  "(a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1 \<longleftrightarrow> (c = 0 \<or> a + b = c)"
proof -
  have H: "(a * c + 1) * (b * c + 1) = c * c * (a * b + 1) + 1
             \<longleftrightarrow> c * (a + b) = c * c"
    by (rule id857_core)
  thus ?thesis by (auto simp: mult_cancel_left)
qed

text \<open>样本行：a=1,b=1,c=2（书例网格的一格：9 = 9）\<close>
lemma id857_sample: "(1 * 2 + 1) * (1 * 2 + 1) = (2::nat) * 2 * (1 * 1 + 1) + 1"
  by eval

text \<open>---------- 5. 鸽笼账：(S1)+(S2) 无有限模型 ----------\<close>

text \<open>有限域上「全函数+单射+0 不是后继」不可能：单射像有 n 个元素
  却装进 {1..<n}（n−1 个）——card 一行结账。\<close>
lemma no_finite_successor:
  fixes f :: "nat \<Rightarrow> nat"
  assumes "0 < n" and "\<forall>i<n. f i < n" and "\<forall>i<n. f i \<noteq> 0"
          "\<forall>i<n. \<forall>j<n. f i = f j \<longrightarrow> i = j"
  shows False
proof -
  have inj: "inj_on f {..<n}"
    using assms(4) by (auto simp: inj_on_def)
  have "card (f ` {..<n}) = n"
    using inj by (simp add: card_image)
  moreover have "f ` {..<n} \<subseteq> {Suc 0..<n}"
    using assms(2,3) by auto
  hence "card (f ` {..<n}) \<le> card {Suc 0..<n}"
    using finite_lessThan card_mono by blast
  ultimately have "n \<le> card {Suc 0..<n}" by simp
  moreover have "card {Suc 0..<n} = n - 1"
    by (simp add: card_atLeastLessThan)
  ultimately have "n \<le> n - 1" by simp
  then show False using assms(1) by simp
qed

end
