theory Axioms imports ZF begin

text \<open>Isabelle/ZF 只用六条实公理（src/ZF/ZF_Base.thy 的 axiomatization）。
每条都能用 @{command thm} 打印出原文——集合论的"官方公理表"在机器里的样子。\<close>

thm extension      \<comment> \<open>外延：A = B \<longleftrightarrow> A \<subseteq> B \<and> B \<subseteq> A\<close>
thm Union_iff      \<comment> \<open>并集：A \<in> \<Union>C \<longleftrightarrow> (\<exists>B\<in>C. A \<in> B)\<close>
thm Pow_iff        \<comment> \<open>幂集：A \<in> Pow(B) \<longleftrightarrow> A \<subseteq> B\<close>
thm infinity       \<comment> \<open>无穷：0 \<in> Inf \<and> (\<forall>y\<in>Inf. succ(y) \<in> Inf)，
                        与书 1.3 的无穷公理逐字同形\<close>
thm foundation     \<comment> \<open>基础：A = 0 \<or> (\<exists>x\<in>A. \<forall>y\<in>x. y \<notin> A)\<close>
thm replacement    \<comment> \<open>替换：函数性前提下 PrimReplace 的刻画（模式公理）\<close>

text \<open>对集与分离在 Isabelle/ZF 中不是公理而是定理——由替换导出。
这正是书第二章脚注"对集公理和替换公理模式也只要其中的一个即可"
的机器版。\<close>
thm Upair_iff      \<comment> \<open>c \<in> Upair(a,b) \<longleftrightarrow> c = a \<or> c = b\<close>
thm separation     \<comment> \<open>b \<in> {x\<in>A. P(x)} \<longleftrightarrow> b \<in> A \<and> P(b)\<close>

text \<open>空集常量 0 的空性同样是导出引理而非公理：\<close>
lemma zero_is_empty: "a \<notin> 0" by simp

text \<open>书 1.3.11 定理：任何集合不属于自身——直接从基础公理推。\<close>
lemma x_not_mem_x: "x \<notin> x"
proof
  assume A: "x \<in> x"
  have ne: "{x} \<noteq> 0"
  proof
    assume "{x} = 0"
    then have "x \<in> 0" using singletonI [of x] by simp
    then show False by (rule emptyE)
  qed
  from foundation [of "{x}"] ne
  obtain u where u1: "u \<in> {x}" and u2: "\<forall>y\<in>u. y \<notin> {x}"
    by (auto simp: singleton_iff)
  then have ux: "u = x" by (simp add: singleton_iff)
  from u2 ux A have "x \<notin> {x}" by blast
  then show False using singletonI [of x] by blast
qed

end
