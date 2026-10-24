theory Nonstat
  imports "ZF.Ordinal" "ZF.Nat"
begin

text \<open>第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）。
ZF 库里没有滤子与 club（那是 HOL 侧的资产），本会话在 ZF 对象逻辑里
从零把 club 理论的骨架搭起来：先给五个定义，再证三件真事实——
κ 自身是无界闭集；两个闭集之交仍闭（定理 2.23 在 μ=2 时的``闭''
一半）；对角线交 \<^term>\<open>DiagInt\<close> 的成员判定。无界一半需要交替取上确界
的乒乓构造，mathlib 的 IsClub.sInter 已经完整承担，ZF 会话只把闭性
这一半做实。\<close>

subsection \<open>五个定义\<close>

text \<open>无界：\<^term>\<open>C\<close> 落在 \<^term>\<open>K\<close> 里，且在 \<^term>\<open>K\<close> 的每个点之上还有 \<^term>\<open>C\<close> 的点。\<close>

definition Unbounded :: "[i,i] \<Rightarrow> o" where
  "Unbounded(K,C) \<equiv> C \<subseteq> K \<and> (\<forall>b\<in>K. \<exists>a\<in>C. b < a)"

text \<open>闭：\<^term>\<open>K\<close> 中每个非零极限点只要等于它与 \<^term>\<open>C\<close> 之交的并，就属于 \<^term>\<open>C\<close>。
条件里 \<^term>\<open>a \<noteq> 0\<close> 不可省——\<^term>\<open>0 = \<Union>(0 \<inter> C)\<close> 恒真，否则会把 \<^term>\<open>0 \<in> C\<close>
强加给每个 club，κ ∖ succ(β) 这类基本例子就全灭。\<close>

definition Closed :: "[i,i] \<Rightarrow> o" where
  "Closed(K,C) \<equiv> \<forall>a\<in>K. a \<noteq> 0 \<and> a = \<Union>(a \<inter> C) \<longrightarrow> a \<in> C"

definition IsClub :: "[i,i] \<Rightarrow> o" where
  "IsClub(K,C) \<equiv> Unbounded(K,C) \<and> Closed(K,C)"

text \<open>荟萃（stationary）：与 \<^term>\<open>K\<close> 上每个 club 都相交。\<close>

definition Stationary :: "[i,i] \<Rightarrow> o" where
  "Stationary(K,S) \<equiv> S \<subseteq> K \<and> (\<forall>C. IsClub(K,C) \<longrightarrow> S \<inter> C \<noteq> 0)"

text \<open>对角线交：\<^term>\<open>x\<close> 属于所有 \<^term>\<open>a \<in> x\<close> 处的 \<^term>\<open>Cf`a\<close>。\<close>

definition DiagInt :: "[i,i] \<Rightarrow> i" where
  "DiagInt(K,Cf) \<equiv> {x \<in> K. \<forall>a \<in> x. x \<in> Cf`a}"

subsection \<open>\<^term>\<open>\<kappa>\<close> 自身是 club\<close>

lemma unbounded_K:
  assumes K: "Limit(K)"
  shows "Unbounded(K,K)"
proof -
  have OK: "Ord(K)" by (rule Limit_is_Ord [OF K])
  have "K \<subseteq> K" by blast
  moreover have "\<forall>b\<in>K. \<exists>a\<in>K. b < a"
  proof
    fix b assume bK: "b \<in> K"
    have sK: "succ(b) \<in> K" by (rule ltD [OF Limit_has_succ [OF K ltI [OF bK OK]]])
    have Ob: "Ord(b)" by (rule lt_Ord [OF ltI [OF bK OK]])
    have "b < succ(b)" by (rule ltI [OF succI1 Ord_succ [OF Ob]])
    with sK show "\<exists>a\<in>K. b < a" by blast
  qed
  ultimately show ?thesis by (auto simp add: Unbounded_def)
qed

lemma closed_K: "Closed(K,K)"
  by (auto simp add: Closed_def)

lemma K_is_club:
  assumes "Limit(K)"
  shows "IsClub(K,K)"
  using assms by (auto simp add: IsClub_def unbounded_K closed_K)

subsection \<open>两个闭集之交仍闭\<close>

text \<open>定理 2.23 在 μ=2 时的``闭''一半：闭性对有限交封闭。关键是
\<^term>\<open>a = \<Union>(a \<inter> (C0 \<inter> C1))\<close> 夹逼出 \<^term>\<open>a = \<Union>(a \<inter> C0)\<close>——因为
\<^term>\<open>a \<inter> (C0 \<inter> C1) \<subseteq> a \<inter> C0\<close> 且 \<^term>\<open>a \<inter> C0 \<subseteq> a\<close>，取并后有
a ⊆ ⋃(a ∩ C0) ⊆ ⋃(a) ⊆ a（末一步用 \<^term>\<open>a\<close> 是序数），三段夹逼即得等号。\<close>

lemma closed_inter_closed:
  assumes OK: "Ord(K)" and C0: "Closed(K,C0)" and C1: "Closed(K,C1)"
  shows "Closed(K, C0 \<inter> C1)"
proof -
  { fix a assume aK: "a \<in> K" and an0: "a \<noteq> 0"
      and aeq: "a = \<Union>(a \<inter> (C0 \<inter> C1))"
    have Oa: "Ord(a)" by (rule lt_Ord [OF ltI [OF aK OK]])
    have Ua: "\<Union>(a) \<subseteq> a" by (rule Ord_Union_subset [OF Oa])
    have e0: "a = \<Union>(a \<inter> C0)"
    proof (rule equalityI)
      show "a \<subseteq> \<Union>(a \<inter> C0)"
      proof -
        have "a = \<Union>(a \<inter> (C0 \<inter> C1))" using aeq .
        also have "\<Union>(a \<inter> (C0 \<inter> C1)) \<subseteq> \<Union>(a \<inter> C0)" by (rule Union_mono) blast
        finally show ?thesis .
      qed
      show "\<Union>(a \<inter> C0) \<subseteq> a"
      proof -
        have "\<Union>(a \<inter> C0) \<subseteq> \<Union>(a)" by (rule Union_mono) blast
        also have "\<Union>(a) \<subseteq> a" by (rule Ua)
        finally show ?thesis .
      qed
    qed
    hence aC0: "a \<in> C0" using aK an0 C0 by (auto simp add: Closed_def)
    have e1: "a = \<Union>(a \<inter> C1)"
    proof (rule equalityI)
      show "a \<subseteq> \<Union>(a \<inter> C1)"
      proof -
        have "a = \<Union>(a \<inter> (C0 \<inter> C1))" using aeq .
        also have "\<Union>(a \<inter> (C0 \<inter> C1)) \<subseteq> \<Union>(a \<inter> C1)" by (rule Union_mono) blast
        finally show ?thesis .
      qed
      show "\<Union>(a \<inter> C1) \<subseteq> a"
      proof -
        have "\<Union>(a \<inter> C1) \<subseteq> \<Union>(a)" by (rule Union_mono) blast
        also have "\<Union>(a) \<subseteq> a" by (rule Ua)
        finally show ?thesis .
      qed
    qed
    hence aC1: "a \<in> C1" using aK an0 C1 by (auto simp add: Closed_def)
    with aC0 have "a \<in> C0 \<inter> C1" by blast }
  thus ?thesis by (auto simp add: Closed_def)
qed

text \<open>两个 club 之交的闭性（无界性由乒乓构造给出，见 mathlib 的 IsClub.sInter）。\<close>

lemma club_inter_closed:
  assumes OK: "Ord(K)" and c0: "IsClub(K,C0)" and c1: "IsClub(K,C1)"
  shows "Closed(K, C0 \<inter> C1)"
proof -
  from c0 have d0: "Closed(K,C0)" by (auto simp add: IsClub_def)
  from c1 have d1: "Closed(K,C1)" by (auto simp add: IsClub_def)
  show ?thesis by (rule closed_inter_closed [OF OK d0 d1])
qed

subsection \<open>对角线交的成员判定\<close>

lemma DiagInt_subset: "DiagInt(K,Cf) \<subseteq> K"
  by (auto simp add: DiagInt_def)

lemma DiagInt_mem_iff:
  "x \<in> DiagInt(K,Cf) \<longleftrightarrow> x \<in> K \<and> (\<forall>a \<in> x. x \<in> Cf`a)"
  by (auto simp add: DiagInt_def)

end
