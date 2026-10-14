theory Completion
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 49 章 布尔补全：谓词式骨架。
       j(p) = Reg(\<down>p) 的两条核心引理（Lemma 4.2.5 的保序与稠密半边）。
       沿用 47/48 章教训：谓词式定义 + 正向提取 blast + 显式规则链。\<close>

text \<open>下闭集（序拓扑的开集）。\<close>

definition
  dclosed :: "[i, i, i] \<Rightarrow> o" where
  "dclosed(P, rel, A) \<equiv> A \<subseteq> P \<and>
     (\<forall>x\<in>A. {y \<in> P . \<langle>y,x\<rangle> \<in> rel} \<subseteq> A)"

text \<open>保序的集合半边（Lemma 4.2.5 (1)）：
       rel 传递且 p \<le> q，则 \<down>p \<subseteq> \<down>q（精化者的下锥更小）。\<close>

lemma downset_incl:
  assumes "trans[P](rel)" and "\<langle>p,q\<rangle> \<in> rel"
    and "p \<in> P" and "q \<in> P"
  shows "{x \<in> P . \<langle>x,p\<rangle> \<in> rel} \<subseteq> {x \<in> P . \<langle>x,q\<rangle> \<in> rel}"
proof (rule subsetI)
  fix x
  assume "x \<in> {x \<in> P . \<langle>x,p\<rangle> \<in> rel}"
  then have h1: "x \<in> P" and h2: "\<langle>x,p\<rangle> \<in> rel"
    unfolding Collect_def by blast+
  have hpq: "\<langle>x,q\<rangle> \<in> rel"
    by (rule trans_onD [OF assms(1) h2 assms(2) h1 assms(3) assms(4)])
  with h1 show "x \<in> {x \<in> P . \<langle>x,q\<rangle> \<in> rel}"
    unfolding Collect_def by blast
qed

text \<open>稠密半边（Lemma 4.2.5 (2) 的骨架）：
       非空下闭集 A 包含其任一点 p 的整条下锥。\<close>

lemma dclosed_down_dense:
  assumes "dclosed(P, rel, A)" and "p \<in> A"
  shows "{y \<in> P . \<langle>y,p\<rangle> \<in> rel} \<subseteq> A"
proof -
  from assms have "A \<subseteq> P" and "\<forall>x\<in>A. {y \<in> P . \<langle>y,x\<rangle> \<in> rel} \<subseteq> A"
    unfolding dclosed_def by simp+
  from this(2) assms(2) show ?thesis by simp
qed

text \<open>补全坍缩的反例骨架（Cor 4.2.7 的"非分离 ⟹ j 非单射"）：
       若 p 与 q 相容且有公共精化链，则 \<down>p 与 \<down>q 的正则化重合。
       完整证明需要 Reg 机器；此处证它的一阶近似：底元素的锥是全空间。\<close>

lemma bottom_cone_all:
  assumes "\<forall>x\<in>P. \<langle>x,b\<rangle> \<in> rel" and "b \<in> P"
  shows "{y \<in> P . \<langle>y,b\<rangle> \<in> rel} = P"
proof (rule equalityI)
  show "{y \<in> P . \<langle>y,b\<rangle> \<in> rel} \<subseteq> P" by auto
next
  show "P \<subseteq> {y \<in> P . \<langle>y,b\<rangle> \<in> rel}"
  proof (rule subsetI)
    fix x
    assume "x \<in> P"
    with assms(1) have "\<langle>x,b\<rangle> \<in> rel" by simp
    with \<open>x \<in> P\<close> show "x \<in> {y \<in> P . \<langle>y,b\<rangle> \<in> rel}"
      unfolding Collect_def by blast
  qed
qed

end
