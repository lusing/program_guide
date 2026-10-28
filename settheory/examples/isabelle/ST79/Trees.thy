theory Trees
  imports "ZF.Nat"
begin

text \<open>第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）。
ZF 通道承担树定义 2.31 在有限序列模型上的全部可靠骨架：节点是函数
f \<in> n→A（域为自然数 n 的有限序列），树序为集合包含（前缀序）。验证
四件事：(1) 每个节点有唯一确定的层 n = domain(f)，不同层互不相交；
(2) 空序列 0 在第 0 层且是根；(3) 第 n+1 层节点的直接前导 f↾n 存在、
落在第 n 层且唯一；(4) 全序列树 Seq(A) 的第 n 层恰为 n→A。
阿朗谢树/苏斯林树的存在性与 MA 的组合后果是不可数命题，由正文证明，
机器不冒充。\<close>

subsection \<open>序列树、前缀闭包与层\<close>

text \<open>A 上全体有限序列：长度 n 是自然数，节点 f 是函数 f \<in> n→A。
这就是例 2.17(2) 的 A^{&lt;ω}。\<close>

definition Seq :: "i => i" where
  "Seq(A) \<equiv> \<Union>n\<in>nat. n -> A"

text \<open>前缀树：含空序列，且每个节点在任何更短长度上的限制都在树中
（定义 2.31(7)「包含全部前导」的函数形态）。\<close>

definition PrefTree :: "[i,i] => o" where
  "PrefTree(T,A) \<equiv>
     T \<subseteq> Seq(A) \<and> 0 \<in> T \<and>
     (\<forall>g\<in>T. \<forall>n\<in>nat. n \<subseteq> domain(g) \<longrightarrow> restrict(g,n) \<in> T)"

text \<open>第 n 层 T_n = T \<inter> (n→A)（定义 2.31(4)）。\<close>

definition lvl :: "[i,i,i] => i" where
  "lvl(A,T,n) \<equiv> {f \<in> T . f \<in> n -> A}"

text \<open>f \<in> n→A 给出 domain(f)=n：Pi_iff 同时给 n\<subseteq>domain(f) 与
f\<subseteq>Sigma(n,const A)，后者把 domain(f) 压回 n。\<close>

lemma fun_domain: "f \<in> n -> A ==> domain(f) = n"
proof -
  assume f: "f \<in> Pi(n, %_. A)"
  from f have tot: "n \<subseteq> domain(f)" and fsub: "f \<subseteq> Sigma(n, %_. A)"
    by (simp_all add: Pi_iff)
  have dsub: "domain(f) \<subseteq> n"
  proof (rule subsetI)
    fix x assume "x \<in> domain(f)"
    then obtain y where xy: "\<langle>x,y\<rangle> \<in> f" by blast
    with fsub have "\<langle>x,y\<rangle> \<in> Sigma(n, %_. A)" by (rule subsetD)
    thus "x \<in> n" by blast
  qed
  show "domain(f) = n" by (rule equalityI [OF dsub tot])
qed

text \<open>主结论一：不同的层互不相交。同时落在两层的节点域既为 n 又为 m。\<close>

lemma levels_disjoint:
  assumes nm: "n \<in> nat" "m \<in> nat" and ne: "n \<noteq> m"
  shows "lvl(A,T,n) \<inter> lvl(A,T,m) = 0"
proof -
  { fix f assume "f \<in> lvl(A,T,n) \<inter> lvl(A,T,m)"
    hence fn: "f \<in> n -> A" and fm: "f \<in> m -> A"
      by (auto simp add: lvl_def)
    have "domain(f) = n" by (rule fun_domain [OF fn])
    moreover have "domain(f) = m" by (rule fun_domain [OF fm])
    ultimately have "n = m" by (rule trans [OF sym])
    with ne have False by blast
  }
  thus ?thesis by blast
qed

text \<open>主结论二：空序列在第 0 层——Pi(0,A)={0}。\<close>

lemma root_level0: "PrefTree(T,A) ==> 0 \<in> lvl(A,T,0)"
  by (simp add: PrefTree_def lvl_def Pi_empty1)

subsection \<open>直接前导的存在与唯一\<close>

text \<open>第 succ(n) 层节点 g 的直接前导是 g↾n：restrict_type2 保证它是
n→A 的函数，前缀闭包保证它在树中。\<close>

lemma predecessor_in_tree:
  assumes pt: "PrefTree(T,A)" and g: "g \<in> lvl(A,T,succ(n))" and nn: "n \<in> nat"
  shows "restrict(g,n) \<in> lvl(A,T,n)"
proof -
  from g have gin: "g \<in> T" and gfun: "g \<in> succ(n) -> A"
    by (auto simp add: lvl_def)
  have rfun: "restrict(g,n) \<in> n -> A"
    by (rule restrict_type2 [OF gfun]) (rule subset_succI)
  have rin: "restrict(g,n) \<in> T"
  proof -
    have "n \<subseteq> domain(g)" by (simp add: fun_domain [OF gfun] subset_succI)
    with pt gin nn show ?thesis by (simp add: PrefTree_def)
  qed
  with rfun show ?thesis by (simp add: lvl_def)
qed

text \<open>直接前导唯一：任何域为 n 且含于 g 的函数 h 都等于 g↾n。
两条函数同在 Pi(n,·) 中、逐点值相同，fun_extension 判等；逐点值相同
来自 h\<subseteq>g 与函数性（同一个第一坐标不可能挂两个值）。\<close>

lemma predecessor_unique:
  assumes g: "g \<in> succ(n) -> A" and h: "h \<in> n -> A" and hg: "h \<subseteq> g" and nn: "n \<in> nat"
  shows "h = restrict(g,n)"
proof (rule fun_extension [OF h restrict_type2 [OF g subset_succI]])
  fix x assume xn: "x \<in> n"
  have xsn: "x \<in> succ(n)" by (rule subsetD [OF subset_succI xn])
  have hp: "\<langle>x,h`x\<rangle> \<in> h" by (rule apply_Pair [OF h xn])
  have hp': "\<langle>x,h`x\<rangle> \<in> g" by (rule subsetD [OF hg hp])
  have gp: "\<langle>x,g`x\<rangle> \<in> g" by (rule apply_Pair [OF g xsn])
  have eq: "h`x = g`x" by (rule apply_equality2 [OF hp' gp g])
  then show "h`x = restrict(g,n)`x" by (simp add: restrict xn)
qed

subsection \<open>全序列树\<close>

text \<open>Seq(A) 本身是前缀树（f\<in>k→A 的 n 长度限制仍是 n→A 的函数），
且它的第 n 层恰为 n→A：例 2.17(2) 的层等式 T_α = A^α。\<close>

lemma Seq_pref_tree: "PrefTree(Seq(A),A)"
proof (unfold PrefTree_def Seq_def, intro conjI)
  show "(\<Union>k\<in>nat. k -> A) \<subseteq> (\<Union>k\<in>nat. k -> A)" by (rule subset_refl)
next
  show "0 \<in> (\<Union>n\<in>nat. n -> A)"
    by (rule UN_I [of 0], rule nat_0I, simp add: Pi_empty1)
next
  show "\<forall>g\<in>(\<Union>k\<in>nat. k -> A). \<forall>n\<in>nat.
         n \<subseteq> domain(g) \<longrightarrow> restrict(g,n) \<in> (\<Union>k\<in>nat. k -> A)"
  proof (intro ballI impI)
    fix g n
    assume g: "g \<in> (\<Union>k\<in>nat. k -> A)" and nn: "n \<in> nat" and sub: "n \<subseteq> domain(g)"
    from g obtain k where kn: "k \<in> nat" and gk: "g \<in> k -> A"
      by (force simp add: UN_iff)
    with sub have nk: "n \<subseteq> k" by (simp add: fun_domain [OF gk])
    have "restrict(g,n) \<in> n -> A" by (rule restrict_type2 [OF gk nk])
    thus "restrict(g,n) \<in> (\<Union>k\<in>nat. k -> A)" by (rule UN_I [OF nn])
  qed
qed

lemma full_level: "n \<in> nat ==> lvl(A,Seq(A),n) = n -> A"
proof -
  assume nn: "n \<in> nat"
  show ?thesis
  proof (rule equalityI)
    show "lvl(A,Seq(A),n) \<subseteq> n -> A"
    proof (rule subsetI)
      fix f assume "f \<in> lvl(A,Seq(A),n)"
      then show "f \<in> n -> A" by (auto simp add: lvl_def)
    qed
  next
    show "n -> A \<subseteq> lvl(A,Seq(A),n)"
    proof (rule subsetI)
      fix f assume f: "f \<in> n -> A"
      have fs: "f \<in> Seq(A)"
      proof (simp only: Seq_def, rule UN_I [of n nat f])
        show "n \<in> nat" using nn .
        show "f \<in> n -> A" using f .
      qed
      from f fs show "f \<in> lvl(A,Seq(A),n)" by (simp add: lvl_def)
    qed
  qed
qed

end
