theory Collapse
  imports "ZF.Epsilon" "ZF.OrderType" "ZF.Nat"
begin

text \<open>
第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）。

库锚点全家桶：Transset_induct（∈-归纳法，定理 1.94 的官方化身）、
transrec（∈-递归定义，定理 1.96）、rank 一族（命题 1.21：
rank_lt 是 b∈a → RK(b)<RK(a)，rank_succ 是 S∘RK = RK∘S，
rank_of_Ord 是 RK(α)=α）。本章的完整证明件：刚性定理（定理
1.95）的最小非平凡实例——2 = {0,1} 上的 ∈-同构只有恒等，证明
全程复刻冯琦的"双围"论证；坍缩方程 π(a) = {π(z) | z R a} 在
二元链上的逐点验收（定理 1.100 的机制样板）。一般坍缩器与四个
现场由 Coq/Agda/Julia/Python/Prolog 五通道承载。
\<close>

subsection \<open>库锚点：∈-归纳、∈-递归与秩\<close>

thm Transset_induct   \<comment> \<open>定理 1.94（∈-归纳法）\<close>
thm transrec          \<comment> \<open>定理 1.96（∈-递归定义）\<close>
thm rank_lt           \<comment> \<open>命题 1.21(1)：a∈b → rank(a)<rank(b)\<close>
thm rank_succ         \<comment> \<open>命题 1.21(2)：rank(succ(x)) = succ(rank(x))\<close>
thm rank_of_Ord       \<comment> \<open>序数的秩是自己：Ord(i) ⟹ rank(i) = i\<close>

text \<open>秩计算现形：rank(0) = 0、rank(2) = 2（冯诺伊曼数字在秩轴上
排成斜率为 1 的直线）。\<close>

lemma rank_2: "rank(2) = 2"
  apply (rule rank_of_Ord)
  apply (rule Ord_succ [OF Ord_succ [OF Ord_0]])
  done

subsection \<open>刚性定理的最小实例（定理 1.95 at 2）\<close>

text \<open>2 = {0,1} 上的 ∈-同构只有恒等。证明是冯琦"双围"的逐字
复刻：f`0 没有前驱（保关系反向 + 满射），故 f`0 = 0；f`1 有
前驱 f`0 = 0（保关系正向），故 f`1 = 1。\<close>

lemma elem2E: "x \<in> 2 \<Longrightarrow> (x = 0 \<Longrightarrow> P) \<Longrightarrow> (x = 1 \<Longrightarrow> P) \<Longrightarrow> P"
  apply (erule succE)   \<comment> \<open>2 = succ(1)：x = 1 或 x ∈ 1\<close>
   apply blast+         \<comment> \<open>succE/emptyE 都是 elim!，两枝皆命题级\<close>
  done

lemma rigid_2:
  assumes f: "f \<in> 2 \<rightarrow> 2"
      and pres: "\<forall>x\<in>2. \<forall>y\<in>2. x\<in>y \<longleftrightarrow> f`x \<in> f`y"
      and surj: "\<forall>y\<in>2. \<exists>x\<in>2. f`x = y"
  shows "\<forall>x\<in>2. f`x = x"
proof -
  have z2: "0 \<in> 2" by (rule succI2 [OF succI1])
  have o2: "1 \<in> 2" by (rule succI1)
  have z1: "0 \<in> 1" by (rule succI1)
  have f0: "f`0 = 0"
  proof (rule ccontr)
    assume nz: "f`0 \<noteq> 0"
    have f02: "f`0 \<in> 2" using f z2 by (rule apply_type)
    from f02 have disj0: "f`0 = 0 \<or> f`0 = 1" by blast
    from disj0 nz have f01: "f`0 = 1" by blast
    from surj z2 have s0: "\<exists>x\<in>2. f`x = 0" by (rule bspec)
    from s0 obtain z where z: "z \<in> 2" "f`z = 0" by blast
    from pres z(1) have "\<forall>y\<in>2. z\<in>y \<longleftrightarrow> f`z \<in> f`y" by (rule bspec)
    from this z2 have iff0: "z\<in>0 \<longleftrightarrow> f`z \<in> f`0" by (rule bspec)
    have inf0: "f`z \<in> f`0" using z(2) f01 z1 by simp
    from iff0 inf0 have "z \<in> 0" by blast
    thus False by (rule emptyE)
  qed
  have f1: "f`1 = 1"
  proof -
    have f12: "f`1 \<in> 2" using f o2 by (rule apply_type)
    have f1ne0: "f`1 \<noteq> 0"
    proof
      assume f10: "f`1 = 0"
      from pres z2 have "\<forall>y\<in>2. 0\<in>y \<longleftrightarrow> f`0 \<in> f`y" by (rule bspec)
      from this o2 have iff1: "0\<in>1 \<longleftrightarrow> f`0 \<in> f`1" by (rule bspec)
      have "f`0 \<in> f`1" using z1 iff1 by blast
      hence "0 \<in> 0" using f0 f10 by simp
      thus False by (rule emptyE)
    qed
    from f12 have "f`1 = 0 \<or> f`1 = 1" by blast
    with f1ne0 show ?thesis by blast
  qed
  show ?thesis
  proof
    fix x assume x2: "x \<in> 2"
    from x2 have "x = 0 \<or> x = 1" by blast
    then show "f`x = x" using f0 f1 by blast
  qed
qed

subsection \<open>坍缩方程的逐点验收（定理 1.100 的机制样板）\<close>

text \<open>二元链：节点 {0,1}，关系 E2 = {⟨0,1⟩}（0 是 1 的唯一前驱）。
恒等映射 π = λx∈2. x 满足坍缩方程 π(1) = {π(z) | ⟨z,1⟩ ∈ E2}：
右端前驱集恰为 {0}，π 作用后仍是 {0} = 1。\<close>

definition E2 :: i where
  "E2 \<equiv> {\<langle>0,1\<rangle>}"

definition pi2 :: i where
  "pi2 \<equiv> \<lambda>x\<in>2. x"

lemma zero_mem_2: "0 \<in> 2" by (rule succI2 [OF succI1])
lemma one_mem_2: "1 \<in> 2" by (rule succI1)

lemma ext_E2_1: "{z \<in> 2. \<langle>z,1\<rangle> \<in> E2} = {0}"
  unfolding E2_def by blast

lemma collapse_eq_1: "{pi2`z. z \<in> {z \<in> 2. \<langle>z,1\<rangle> \<in> E2}} = pi2`1"
  apply (simp add: ext_E2_1)
  apply (simp add: pi2_def beta zero_mem_2 one_mem_2 succ_def)
  done

text \<open>rank 给坍缩定层：二元链的秩分层正是 rank(0)=0、rank(1)=1
——定理 1.98 的 ρ(a) = sup{ρ(y)+1} 在库里即 rank 的递归方程。\<close>

thm rank             \<comment> \<open>rank(a) = (⋃y\<in>a. succ(rank(y)))：定理 1.98 的官方\<close>

end
