theory Sch
  imports "ZF.Ordinal" "ZF.Nat" "ZF.Arith" "ZF.ArithSimp"
begin

text \<open>第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）。
在 ZF 对象逻辑里重演两件事：序数上没有无穷递减链（良基性的函数形态），
以及 ω 一侧的 monus 反例（尾区间之交为空）。\<close>

subsection \<open>序数无递减链\<close>

text \<open>递减链：f 是 nat 到 A 的函数，且每步严格下降 f`succ(n) ∈ f`n。\<close>

definition DescChain :: "[i,i] \<Rightarrow> o" where
  "DescChain(f,A) \<equiv> f \<in> nat \<rightarrow> A \<and> (\<forall>n\<in>nat. f`succ(n) \<in> f`n)"

text \<open>A 是序数时无递减链。对 \<^term>\<open>Memrel(A)\<close> 做良基归纳证
\<^term>\<open>x \<notin> f``nat\<close>：若 \<^term>\<open>x = f`n\<close> 在像中，则 \<^term>\<open>f`succ(n)\<close>
既属于 \<^term>\<open>f`n = x\<close>（故 \<^term>\<open>\<langle>f`succ(n),x\<rangle> \<in> Memrel(A)\<close>）又在像中，
与归纳假设矛盾。良基性由 \<^term>\<open>wf_Memrel\<close>（基础公理）无条件给出，
经 \<^term>\<open>wf_induct\<close> 特化到 \<^term>\<open>f`0\<close> 即得 \<^term>\<open>f`0 \<notin> f``nat\<close>，与 \<^term>\<open>f`0\<close>
显然在像中冲突——67 章 ∈-良基的又一次落地。\<close>

lemma no_desc_chain_in_Ord:
  assumes A: "Ord(A)" and D: "DescChain(f,A)"
  shows "False"
proof -
  from D have fn: "f \<in> nat \<rightarrow> A" and dec: "\<forall>n\<in>nat. f`succ(n) \<in> f`n"
    by (auto simp add: DescChain_def)
  have ffun: "function(f)" by (rule fun_is_function [OF fn])
  have z0: "f`0 \<in> f``nat"
    by (rule imageI [OF apply_Pair [OF fn, OF nat_0I] nat_0I])
  have step: "\<And>x. (\<And>y. \<langle>y,x\<rangle> \<in> Memrel(A) \<Longrightarrow> y \<notin> f``nat) \<Longrightarrow> x \<notin> f``nat"
  proof -
    fix x assume IH: "\<And>y. \<langle>y,x\<rangle> \<in> Memrel(A) \<Longrightarrow> y \<notin> f``nat"
    show "x \<notin> f``nat"
    proof (rule notI)
      assume xin: "x \<in> f``nat"
      then obtain n where xn: "\<langle>n,x\<rangle> \<in> f" and nn: "n \<in> nat"
        by (rule imageE)
      from xn ffun have fxn: "f`n = x"
        by (rule function_apply_equality)
      from fn nn have fxnA: "f`n \<in> A" by (rule apply_type)
      hence xA: "x \<in> A" using fxn by simp
      have fsA: "f`succ(n) \<in> A"
        by (rule apply_type [OF fn nat_succI [OF nn]])
      from dec nn have fsn: "f`succ(n) \<in> f`n" by (rule bspec)
      hence fsx: "f`succ(n) \<in> x" using fxn by simp
      have pair: "\<langle>f`succ(n), x\<rangle> \<in> Memrel(A)"
        by (rule MemrelI [OF fsx fsA xA])
      from pair have n1: "f`succ(n) \<notin> f``nat" by (rule IH)
      have in1: "f`succ(n) \<in> f``nat"
        by (rule imageI [OF apply_Pair [OF fn, OF nat_succI [OF nn]] nat_succI [OF nn]])
      from n1 in1 show False by blast
    qed
  qed
  have notz0: "f`0 \<notin> f``nat" by (rule wf_induct [OF wf_Memrel step])
  from z0 notz0 show False by blast
qed

subsection \<open>ω 一侧：monus 反例与尾区间之交\<close>

text \<open>k ≥ n+1 时 k ∸ (n+1) < k ∸ n：自然数减法沿下标严格下降。\<close>

lemma monus_witness:
  "\<forall>n\<in>nat. \<forall>k\<in>nat. succ(n) \<le> k \<longrightarrow> k #- succ(n) < k #- n"
proof
  fix n assume nn: "n \<in> nat"
  show "\<forall>k\<in>nat. succ(n) \<le> k \<longrightarrow> k #- succ(n) < k #- n"
  proof
    fix k assume kn: "k \<in> nat"
    show "succ(n) \<le> k \<longrightarrow> k #- succ(n) < k #- n"
    proof
      assume le: "succ(n) \<le> k"
      have nsn: "n < succ(n)"
        by (rule ltI [OF succI1 Ord_succ [OF nat_into_Ord [OF nn]]])
      from nsn le have nk: "n < k" by (rule lt_trans2)
      have kp: "k #- n \<in> nat" by (rule diff_type)
      have ne0: "k #- n \<noteq> 0"
      proof
        assume z: "k #- n = 0"
        from kn nn have "k #- n = 0 \<longleftrightarrow> k \<le> n" by (rule diff_is_0_lemma)
        with z have "k \<le> n" by simp
        with nk show False by (blast elim: leE dest: lt_not_sym)
      qed
      have kOrd: "Ord(k #- n)" using kp by (rule nat_into_Ord)
      from kOrd ne0 have pos: "0 < k #- n" by (rule Ord_0_lt)
      from pos kp obtain m where mn: "m \<in> nat" and eq: "k #- n = succ(m)"
        by (rule zero_lt_natE)
      have p1: "pred(k #- n) < k #- n"
      proof -
        have "m < succ(m)"
          by (rule ltI [OF succI1 Ord_succ [OF nat_into_Ord [OF mn]]])
        thus ?thesis using eq by simp
      qed
      have e1: "k #- succ(n) = pred(k #- n)"
        by (rule nat_diff_pred [OF kn nn])
      show "k #- succ(n) < k #- n" using p1 e1 by simp
    qed
  qed
qed

text \<open>0 不在 n=1 的尾区间里，故所有尾区间之交为空。\<close>

lemma nat_tails_empty_inter:
  "(\<Inter> n\<in>nat. {k \<in> nat. n \<le> k}) = 0"
proof -
  have sub: "(\<Inter> n\<in>nat. {k \<in> nat. n \<le> k}) \<subseteq> {k \<in> nat. 1 \<le> k}"
    by (rule INT_lower [OF nat_1I])
  have "0 \<notin> {k \<in> nat. 1 \<le> k}"
  proof
    assume "0 \<in> {k \<in> nat. 1 \<le> k}"
    hence "1 \<le> 0" by simp
    thus False by (simp add: le_iff)
  qed
  with sub show ?thesis by blast
qed

end
