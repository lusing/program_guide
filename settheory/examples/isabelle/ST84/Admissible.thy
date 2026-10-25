theory Admissible
  imports "ZF-Constructible.Formula" "ZF.Univ" "ZF.Cardinal" "ZF.ArithSimp"
begin

text \<open>第 84 章 · KP 与可采纳集合：一阶逻辑植入 KP（冯琦第二卷 §1.1）。
Paulson 的 ZF-Constructible 库已把一阶语法做成集合：\<^term>\<open>formula\<close>
是 ZF 归纳数据类型，\<^term>\<open>satisfies\<close> 是以 list(A) 为定义域的 ZF 函数。
本章另设更易读的 Δ₀ 语法，证明传递绝对性；再用 Vset(nat) 实现 HF。\<close>

section \<open>一、语法即集合\<close>

lemma satisfaction_is_set_function:
  "p \<in> formula \<Longrightarrow> satisfies(A,p) \<in> list(A) -> bool"
  by (rule satisfies_type)

text \<open>公式由 Member、Equal、Nand、Forall 四个构造子生成；否定、合取、
存在量词都是定义出来的缩写。满足语义分别由 ‹sats_Member_iff›、
‹sats_Nand_iff›、‹sats_Forall_iff›、‹sats_Exists_iff› 给出。
因此「公式是集合、满足是集合函数」在 ZF 对象逻辑里是字面事实。\<close>

section \<open>二、Δ₀ 公式与传递绝对性\<close>

consts d0f :: i
datatype
  "d0f" = dMem ("i \<in> nat", "j \<in> nat")
        | dEq  ("i \<in> nat", "j \<in> nat")
        | dNeg ("p \<in> d0f")
        | dAnd ("p \<in> d0f", "q \<in> d0f")
        | dAll ("j \<in> nat", "p \<in> d0f")

declare d0f.intros [TC]

text \<open>dAll(j,p) 表示「对所有 v₀\<in>vⱼ，p」；v₀ 压到环境队首。
满足关系仿 Paulson：先定义取 0/1 的集合函数 dsat，再以 dtrue 读成真值。\<close>

consts dsat :: "[i,i] => i"
primrec
  "dsat(A,dMem(i,j)) =
     (\<lambda>env \<in> list(A). bool_of_o (nth(i,env) \<in> nth(j,env)))"
  "dsat(A,dEq(i,j)) =
     (\<lambda>env \<in> list(A). bool_of_o (nth(i,env) = nth(j,env)))"
  "dsat(A,dNeg(p)) =
     (\<lambda>env \<in> list(A). bool_of_o (\<not> dsat(A,p)`env = 1))"
  "dsat(A,dAnd(p,q)) =
     (\<lambda>env \<in> list(A). bool_of_o (dsat(A,p)`env = 1 \<and> dsat(A,q)`env = 1))"
  "dsat(A,dAll(j,p)) =
     (\<lambda>env \<in> list(A). bool_of_o
       (\<forall>x\<in>A. x \<in> nth(j,env) \<longrightarrow> dsat(A,p)`Cons(x,env) = 1))"

lemma dsat_type: "p \<in> d0f \<Longrightarrow> dsat(A,p) \<in> list(A) -> bool"
  by (induct set: d0f) simp_all

abbreviation dtrue :: "[i,i,i] => o" where
  "dtrue(A,p,env) \<equiv> dsat(A,p)`env = 1"

lemma dtrue_Mem_iff [simp]:
  "env \<in> list(A) \<Longrightarrow> dtrue(A,dMem(i,j),env) \<longleftrightarrow> nth(i,env) \<in> nth(j,env)"
  by simp
lemma dtrue_Eq_iff [simp]:
  "env \<in> list(A) \<Longrightarrow> dtrue(A,dEq(i,j),env) \<longleftrightarrow> nth(i,env) = nth(j,env)"
  by simp
lemma dtrue_Neg_iff [simp]:
  "env \<in> list(A) \<Longrightarrow> dtrue(A,dNeg(p),env) \<longleftrightarrow> \<not> dtrue(A,p,env)"
  by simp
lemma dtrue_And_iff [simp]:
  "env \<in> list(A) \<Longrightarrow> dtrue(A,dAnd(p,q),env)
     \<longleftrightarrow> dtrue(A,p,env) \<and> dtrue(A,q,env)"
  by simp
lemma dtrue_All_iff [simp]:
  "env \<in> list(A) \<Longrightarrow> dtrue(A,dAll(j,p),env)
     \<longleftrightarrow> (\<forall>x\<in>A. x \<in> nth(j,env) \<longrightarrow> dtrue(A,p,Cons(x,env)))"
  by simp

declare dsat.simps [simp del]

lemma nth_in_A:
  assumes env: "env \<in> list(A)" and zero: "0 \<in> A" and i: "i \<in> nat"
  shows "nth(i,env) \<in> A"
proof (cases "i < length(env)")
  case True
  then show ?thesis using nth_type [OF env] by simp
next
  case False
  have len: "length(env) \<in> nat" using env by simp
  have "length(env) \<le> i"
    by (rule not_lt_iff_le [THEN iffD1, OF nat_into_Ord [OF i]
          nat_into_Ord [OF len] False])
  then have "nth(i,env) = 0"
    by (rule nth_eq_0 [OF env i])
  with zero show ?thesis by simp
qed

text \<open>**Δ₀-绝对性**：A 传递且 A⊆B，环境取自 A，则任何 Δ₀ 公式
在 A、B 中真值相同。关键仅是有界全称：x 属于界 nth(j,env)，
而界在 A 中，传递性自动给出 x∈A。归纳假设用于更新后的环境 Cons(x,env)。\<close>

theorem d0_absoluteness:
  assumes sub: "A \<subseteq> B" and tr: "Transset(A)" and zero: "0 \<in> A"
    and pt: "p \<in> d0f"
  shows "\<forall>env\<in>list(A). dtrue(A,p,env) \<longleftrightarrow> dtrue(B,p,env)"
  using pt
proof (induct p)
  case (dMem i j)
  show ?case
  proof (rule ballI)
    fix env assume envA: "env \<in> list(A)"
    have envB: "env \<in> list(B)"
      by (rule subsetD [OF list_mono [OF sub] envA])
    show "dtrue(A,dMem(i,j),env) \<longleftrightarrow> dtrue(B,dMem(i,j),env)"
      by (simp add: dtrue_Mem_iff [OF envA] dtrue_Mem_iff [OF envB])
  qed
next
  case (dEq i j)
  show ?case
  proof (rule ballI)
    fix env assume envA: "env \<in> list(A)"
    have envB: "env \<in> list(B)"
      by (rule subsetD [OF list_mono [OF sub] envA])
    show "dtrue(A,dEq(i,j),env) \<longleftrightarrow> dtrue(B,dEq(i,j),env)"
      by (simp add: dtrue_Eq_iff [OF envA] dtrue_Eq_iff [OF envB])
  qed
next
  case (dNeg p)
  show ?case
  proof (rule ballI)
    fix env assume envA: "env \<in> list(A)"
    have envB: "env \<in> list(B)"
      by (rule subsetD [OF list_mono [OF sub] envA])
    have "dtrue(A,p,env) \<longleftrightarrow> dtrue(B,p,env)"
      by (rule bspec [OF dNeg(2) envA])
    then show "dtrue(A,dNeg(p),env) \<longleftrightarrow> dtrue(B,dNeg(p),env)"
      by (simp add: dtrue_Neg_iff [OF envA] dtrue_Neg_iff [OF envB])
  qed
next
  case (dAnd p q)
  show ?case
  proof (rule ballI)
    fix env assume envA: "env \<in> list(A)"
    have envB: "env \<in> list(B)"
      by (rule subsetD [OF list_mono [OF sub] envA])
    have "dtrue(A,p,env) \<longleftrightarrow> dtrue(B,p,env)"
      by (rule bspec [OF dAnd(2) envA])
    moreover have "dtrue(A,q,env) \<longleftrightarrow> dtrue(B,q,env)"
      by (rule bspec [OF dAnd(4) envA])
    ultimately show "dtrue(A,dAnd(p,q),env) \<longleftrightarrow> dtrue(B,dAnd(p,q),env)"
      by (simp add: dtrue_And_iff [OF envA] dtrue_And_iff [OF envB])
  qed
next
  case (dAll j p)
  show ?case
  proof (rule ballI)
    fix env assume envA: "env \<in> list(A)"
    have envB: "env \<in> list(B)" using list_mono [OF sub] envA by blast
    have jA: "nth(j,env) \<in> A"
      by (rule nth_in_A [OF envA zero dAll(1)])
    show "dtrue(A,dAll(j,p),env) \<longleftrightarrow> dtrue(B,dAll(j,p),env)"
    proof (simp only: dtrue_All_iff [OF envA] dtrue_All_iff [OF envB],
           rule iffI)
      assume h: "\<forall>x\<in>A. x \<in> nth(j,env) \<longrightarrow> dtrue(A,p,Cons(x,env))"
      show "\<forall>x\<in>B. x \<in> nth(j,env) \<longrightarrow> dtrue(B,p,Cons(x,env))"
      proof (rule ballI, rule impI)
        fix x assume xB: "x \<in> B" and xj: "x \<in> nth(j,env)"
        have xA: "x \<in> A" using tr jA xj unfolding Transset_def by blast
        have cA: "Cons(x,env) \<in> list(A)" using xA envA by simp
        have "dtrue(A,p,Cons(x,env))" using h xA xj by blast
        with bspec [OF dAll(3) cA] show "dtrue(B,p,Cons(x,env))" by blast
      qed
    next
      assume h: "\<forall>x\<in>B. x \<in> nth(j,env) \<longrightarrow> dtrue(B,p,Cons(x,env))"
      show "\<forall>x\<in>A. x \<in> nth(j,env) \<longrightarrow> dtrue(A,p,Cons(x,env))"
      proof (rule ballI, rule impI)
        fix x assume xA: "x \<in> A" and xj: "x \<in> nth(j,env)"
        have xB: "x \<in> B" using sub xA by blast
        have cA: "Cons(x,env) \<in> list(A)" using xA envA by simp
        have "dtrue(B,p,Cons(x,env))" using h xB xj by blast
        with bspec [OF dAll(3) cA] show "dtrue(A,p,Cons(x,env))" by blast
      qed
    qed
  qed
qed

section \<open>三、有限累积层次与 HF = V_\<omega>\<close>

lemma HF_transset: "Transset(Vset(nat))"
  by (rule Transset_0 [THEN Transset_Vfrom])

lemma HF_elem_iff:
  "x \<in> Vset(nat) \<longleftrightarrow> (\<exists>j\<in>nat. x \<subseteq> Vset(j))"
  apply (subst Vset [of nat])
  apply (simp add: Pow_iff)
  done

lemma Vset_mono_nat:
  assumes h: "j \<le> k" shows "Vset(j) \<subseteq> Vset(k)"
  by (rule Vfrom_mono [OF subset_refl le_imp_subset [OF h]])

text \<open>nat 是极限序数，库定理 doubleton_in_VLimit 直接给出弱配对。\<close>

lemma HF_pair:
  assumes ha: "a \<in> Vset(nat)" and hb: "b \<in> Vset(nat)"
  shows "{a,b} \<in> Vset(nat)"
  by (rule doubleton_in_VLimit [OF ha hb Limit_nat])

lemma HF_Union:
  assumes ha: "a \<in> Vset(nat)" shows "\<Union>(a) \<in> Vset(nat)"
proof -
  from ha obtain j where jn: "j\<in>nat" and aj: "a \<subseteq> Vset(j)"
    using HF_elem_iff by auto
  have tr: "Transset(Vset(j))" by (rule Transset_Vset)
  have "\<Union>(a) \<subseteq> Vset(j)"
  proof (rule Union_least)
    fix x assume xa: "x \<in> a"
    then have xj: "x \<in> Vset(j)" using aj by blast
    with tr show "x \<subseteq> Vset(j)" unfolding Transset_def by blast
  qed
  then have "\<Union>(a) \<in> Pow(Vset(j))" by (rule PowI)
  then have "\<Union>(a) \<in> (\<Union>i\<in>nat. Pow(Vset(i)))" by (rule UN_I [OF jn])
  then show ?thesis by (simp only: Vset [symmetric])
qed

text \<open>分离：x 的任意子集 y 与 x 同层。Δ₀ 限定真正的工作在上一节：
它保证「在 HF 内切出的子集」与「在 V 内切出的子集」是同一个。\<close>

lemma HF_separation:
  assumes ys: "y \<subseteq> x" and hx: "x \<in> Vset(nat)"
  shows "y \<in> Vset(nat)"
proof -
  from hx obtain j where jn: "j\<in>nat" and xj: "x \<subseteq> Vset(j)"
    using HF_elem_iff by auto
  have "y \<subseteq> Vset(j)" by (rule subset_trans [OF ys xj])
  then have "y \<in> Pow(Vset(j))" by (rule PowI)
  then have "y \<in> (\<Union>i\<in>nat. Pow(Vset(i)))" by (rule UN_I [OF jn])
  then show ?thesis by (simp only: Vset [symmetric])
qed

lemma HF_zero: "0 \<in> Vset(nat)"
proof -
  have "0 \<subseteq> Vset(0)" by simp
  then have "0 \<in> Pow(Vset(0))" by (rule PowI)
  then have "0 \<in> (\<Union>i\<in>nat. Pow(Vset(i)))" by (rule UN_I [OF nat_0I])
  then show ?thesis by (simp only: Vset [symmetric])
qed

text \<open>V_\<omega> 满足 KP⁻ 的传递、配对、并集、分离条件，却不含 \<omega>：
若 nat 落在某有限层 V_j，则它是有限集 V_j 的子集，与 nat_not_Finite 矛盾。
这正是 KP = KP⁻ + 无穷公理（定义 1.6、1.7）的分界。\<close>

theorem nat_not_in_HF: "nat \<notin> Vset(nat)"
proof
  assume "nat \<in> Vset(nat)"
  then obtain j where jn: "j\<in>nat" and sub: "nat \<subseteq> Vset(j)"
    using HF_elem_iff by auto
  have fin: "Finite(Vset(j))" by (rule Finite_Vset [OF jn])
  have "Finite(nat)" by (rule subset_Finite [OF sub fin])
  with nat_not_Finite show False by contradiction
qed

end
