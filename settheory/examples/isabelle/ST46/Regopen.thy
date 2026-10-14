theory Regopen
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 46 章 预序字典：稠密性与原子的两个基本事实
       （Viale Fact 2.2.13 / 2.2.14）。
       ZF 无拓扑库，46 章的拓扑部分由 Lean/Coq/Julia/Python 通道承载，
       这里做纯序论核心：原子必入一切稠密集、稠密的传递性。\<close>

definition
  denseOn :: "[i,i,i] \<Rightarrow> o" where
  "denseOn(P,rel,D) \<equiv> \<forall>p\<in>P. \<exists>q\<in>D. \<langle>q,p\<rangle> \<in> rel"

definition
  atomOn :: "[i,i,i] \<Rightarrow> o" where
  "atomOn(P,rel,a) \<equiv> a \<in> P \<and> (\<forall>q\<in>P. \<langle>q,a\<rangle> \<in> rel \<longrightarrow> q = a)"

text \<open>Fact 2.2.13：原子属于每个稠密集——含原子的偏序上泛型性平凡。\<close>

lemma atom_in_dense:
  assumes "D \<subseteq> P" and "atomOn(P,rel,a)" and "denseOn(P,rel,D)"
  shows "a \<in> D"
proof -
  from assms(2) have aP: "a \<in> P" unfolding atomOn_def by simp
  with assms(3)[unfolded denseOn_def]
  obtain q where "q \<in> D" and qa: "\<langle>q,a\<rangle> \<in> rel" by blast
  from assms(1) \<open>q \<in> D\<close> have qP: "q \<in> P" by auto
  with assms(2)[unfolded atomOn_def] qa have "q = a" by blast
  with \<open>q \<in> D\<close> show ?thesis by simp
qed

text \<open>Fact 2.2.14：稠密的传递性（D 在 E 中稠密、E 在 F 中稠密
       且 rel 在 F 上传递，则 D 在 F 中稠密）。\<close>

lemma dense_dense_trans:
  assumes "D \<subseteq> E" "E \<subseteq> F"
    and "denseOn(E,rel,D)" and "denseOn(F,rel,E)" and "trans[F](rel)"
  shows "denseOn(F,rel,D)"
proof (unfold denseOn_def, rule ballI)
  fix p
  assume "p \<in> F"
  with assms(4) obtain r where "r \<in> E" and rp: "\<langle>r,p\<rangle> \<in> rel"
    unfolding denseOn_def by auto
  with assms(3) obtain q where "q \<in> D" and qr: "\<langle>q,r\<rangle> \<in> rel"
    unfolding denseOn_def by auto
  from assms(5)[unfolded trans_on_def] assms(1,2)
    \<open>q \<in> D\<close> \<open>r \<in> E\<close> \<open>p \<in> F\<close> qr rp
  have qp: "\<langle>q,p\<rangle> \<in> rel" by blast
  with \<open>q \<in> D\<close> show "\<exists>q\<in>D. \<langle>q,p\<rangle> \<in> rel" by auto
qed

text \<open>滤子的两条公理（Viale Def 2.2.19 的骨架）：
       上闭 + 两两在滤子内有公共精化。\<close>

definition
  filterOn :: "[i,i,i] \<Rightarrow> o" where
  "filterOn(P,rel,G) \<equiv> G \<subseteq> P \<and>
     (\<forall>p\<in>G. \<forall>q\<in>P. \<langle>p,q\<rangle> \<in> rel \<longrightarrow> q \<in> G) \<and>
     (\<forall>p\<in>G. \<forall>q\<in>G. \<exists>r\<in>G. \<langle>r,p\<rangle> \<in> rel \<and> \<langle>r,q\<rangle> \<in> rel)"

end
