theory Wellorder
  imports "ZF.OrderType" "ZF.Nat"
begin

text \<open>
第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）。

ZF 的 Order.thy + OrderType.thy 正是冯琦这一章的官方影子：
well\_ord / ord\_iso / ordermap / ordertype / oadd / omult。
本章抽查刚性定理（定理 1.62）与可比较定理（定理 1.63）的库
锚点、完整证明引理 1.13（单增自映射不下移）与不可交换见证
1++nat = nat < nat++1，再对齐命题 1.25/1.26 的三款递归式。
\<close>

subsection \<open>表示定理与可比较定理的库锚点（定理 1.63/1.64）\<close>

text \<open>秩序集间的同构可比较：同构 / 同构于前段 / 前段同构于它，
三者恰居其一（定理 1.63）。\<close>
thm well_ord_trichotomy

text \<open>表示定理（定理 1.64）：每个秩序集同构于唯一的序数
ordermap 是雪崩映射的化身——x 的名次 = 前段序型。\<close>
thm ordertype_ord_iso
thm Ord_ordertype
thm ordermap_pred_unfold

text \<open>同构唯一性（定理 1.62(2)）与"无秩序集同构于自己的前段"
（定理 1.62(3)）。\<close>
thm well_ord_iso_unique
thm well_ord_iso_predE

subsection \<open>引理 1.13：单增自映射不下移（完整证明）\<close>

text \<open>冯琦的证明：反例集取 \<in>-极小元 z，则 w = f(z) < z 且
f(w) < f(z) = w——w 是更小的反例。这里在一般秩序集上用
well\_ord 的良基性（well\_ord\_is\_wf + wf\_on\_induct）复刻。\<close>

lemma mono_map_le:
  assumes wfA: "well_ord(A,r)" and fA: "f \<in> A->A"
      and mono: "\<forall>x\<in>A. \<forall>y\<in>A. \<langle>x,y\<rangle>\<in>r \<longrightarrow> \<langle>f`x,f`y\<rangle>\<in>r"
  shows "\<forall>a\<in>A. \<langle>f`a,a\<rangle> \<notin> r"
proof -
  from wfA have wfr: "wf[A](r)" by (rule well_ord_is_wf)
  { fix a assume aA: "a\<in>A"
    from wfr aA have "\<langle>f`a,a\<rangle> \<notin> r"
    proof (rule wf_on_induct)
      fix x assume xA: "x\<in>A"
        and IH: "\<And>y. y\<in>A \<Longrightarrow> \<langle>y,x\<rangle>\<in>r \<Longrightarrow> \<langle>f`y,y\<rangle> \<notin> r"
      show "\<langle>f`x,x\<rangle> \<notin> r"
      proof
        assume fxx: "\<langle>f`x,x\<rangle> \<in> r"
        from fA xA have fx: "f`x \<in> A" by (rule apply_type)
        with mono xA fxx have one: "\<langle>f`(f`x),f`x\<rangle> \<in> r" by blast
        from IH fx fxx have two: "\<langle>f`(f`x),f`x\<rangle> \<notin> r" by blast
        from one two show False by blast
      qed
    qed
  } thus ?thesis by blast
qed

subsection \<open>命题 1.25：加法的三款递归式（oadd 库锚点）\<close>

text \<open>i++j 是 ZF 的序数加法（OrderType.thy 按 radd 的序型定义——
正是冯琦定义 1.76 的直和）。三款递归式逐字对齐：\<close>

thm oadd_0        \<comment> \<open>i++0 = i\<close>
thm oadd_succ     \<comment> \<open>i++succ(j) = succ(i++j)：后继款\<close>
thm oadd_Limit    \<comment> \<open>Limit(j) \<Longrightarrow> i++j = (\<Union>k\<in>j. i++k)：极限款\<close>

thm omult_0       \<comment> \<open>i**0 = 0\<close>
thm omult_succ    \<comment> \<open>i**succ(j) = (i**j)++i：乘法后继款\<close>
thm omult_Limit   \<comment> \<open>乘法极限款\<close>

text \<open>运算律锚点（定理 1.75/1.76）：结合律、左消去（第二变元
严格单增）、右弱保序（第一变元只弱单增）、左分配律。\<close>
thm oadd_assoc
thm oadd_lt_mono2
thm oadd_le_mono1
thm oadd_omult_distrib
thm omult_assoc

subsection \<open>不可交换见证：1++nat = nat < nat++1（完整证明）\<close>

text \<open>辅助：有限段上 1++k 仍是自然数——按 nat 归纳，
后继款用 oadd\_succ（simp 规则）+ nat\_succI。\<close>

lemma one_oadd_fin_nat: "n \<in> nat \<Longrightarrow> 1 ++ n \<in> nat"
  apply (erule nat_induct)
   apply (simp add: oadd_0 nat_1I)
  apply (simp add: oadd_succ nat_succI)
  done

text \<open>主见证：1++nat = nat。极限款拆成 (\<Union>k\<in>nat. 1++k)，
一个方向 Union\_least + 辅助引理，另一个方向每个 x 用
x \<le> 1++x 与 oadd\_succ 落进 1++succ(x)。\<close>

lemma one_oadd_nat: "1 ++ nat = nat"
proof -
  have eq: "1 ++ nat = (\<Union>k\<in>nat. 1++k)" using Limit_nat by (rule oadd_Limit)
  have sub: "(\<Union>k\<in>nat. 1++k) \<subseteq> nat"
  proof (rule Union_least)
    fix x assume "x \<in> RepFun(nat, \<lambda>k. 1++k)"
    then obtain k where k: "k \<in> nat" and xk: "x = 1++k" by auto
    from k have "1++k \<in> nat" by (rule one_oadd_fin_nat)
    with xk have xin: "x \<in> nat" by simp
    from Ord_nat have "Transset(nat)" by (rule Ord_is_Transset)
    hence "\<forall>z\<in>nat. z \<subseteq> nat" by (simp only: Transset_def)
    with xin show "x \<subseteq> nat" by blast
  qed
  have sup: "nat \<subseteq> (\<Union>k\<in>nat. 1++k)"
  proof (rule subsetI)
    fix x assume xnat: "x \<in> nat"
    then have ox: "Ord(x)" by (rule nat_into_Ord)
    have sx: "succ(x) \<in> nat" using xnat by (rule nat_succI)
    have e2: "1 ++ succ(x) = succ(1 ++ x)" using ox by (rule oadd_succ)
    have hx: "x < succ(1 ++ x)" using ox by (rule oadd_le_self2)
    then have xin: "x \<in> succ(1 ++ x)" by (rule ltD)
    have xin2: "x \<in> 1++succ(x)" using xin e2 by simp
    from sx xin2 show "x \<in> (\<Union>k\<in>nat. 1++k)" by (rule UN_I)
  qed
  from sub sup have "(\<Union>k\<in>nat. 1++k) = nat" by (rule equalityI)
  with eq show ?thesis by simp
qed

text \<open>右邻不塌缩：nat++1 = succ(nat) > nat（oadd\_1 + ltI），
合起来就是"1+ω = ω < ω+1"的 ZF 版。\<close>

lemma noncomm_add: "1 ++ nat = nat \<and> nat < nat ++ 1"
proof (rule conjI [OF one_oadd_nat])
  have s: "nat ++ 1 = succ(nat)" using Ord_nat by (rule oadd_1)
  have l: "nat < succ(nat)" by (rule ltI [OF succI1 Ord_succ [OF Ord_nat]])
  from s l show "nat < nat ++ 1" by simp
qed

end
