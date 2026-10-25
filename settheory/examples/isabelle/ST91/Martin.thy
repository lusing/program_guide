theory Martin
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）。
本章机器化两件：一步迭代的相容分解与典型嵌入的完备性半边
（定理 3.14 与引理 3.54 的抽象形态，以配对相容的记账承载）；
马丁公理小偏序化归（引理 3.58 中 MA* 到 MA 的一步）。有限支撑
迭代（定义 3.36）、链条件保持（定理 3.16/3.17）、迭代分配律
（定理 3.15）与 Solovay-Tennenbaum 定理（定理 3.18）由讲义承载。\<close>

section \<open>一步迭代的相容分解与典型嵌入（定理 3.14 / 引理 3.54）\<close>

text \<open>comp 是第一步 P 上的相容谓词，compQ 是第二步的；topQ 是
第二步的最大元，与一切相容。迭代条件取有序对，迭代相容按定义
分解为两个分量的相容。\<close>

locale iter_pair =
  fixes P :: i
  fixes Q :: i
  fixes comp :: "i \<Rightarrow> i \<Rightarrow> o"
  fixes compQ :: "i \<Rightarrow> i \<Rightarrow> o"
  fixes topQ :: i
  assumes topQ_Q: "topQ \<in> Q"
  assumes compQ_top: "\<lbrakk>q \<in> Q\<rbrakk> \<Longrightarrow> compQ(topQ, q)"

context iter_pair
begin

definition icomp :: "i \<Rightarrow> i \<Rightarrow> o" where
  "icomp(x, y) \<equiv> comp(fst(x), fst(y)) \<and> compQ(snd(x), snd(y))"

text \<open>迭代相容按定义分解为分量相容（定理 3.14 的组合核心）。\<close>

lemma icomp_split:
  shows "icomp(\<langle>p, q\<rangle>, \<langle>p', q'\<rangle>) \<longleftrightarrow>
         (comp(p, p') \<and> compQ(q, q'))"
  unfolding icomp_def by simp

text \<open>典型嵌入 i(p) = (p, 1_Q)：相容完全由第一步决定
（引理 3.54(6) 完备嵌入的冲突换算）。\<close>

lemma canon_compat:
  assumes pP: "p \<in> P" and pP': "p' \<in> P"
  shows "icomp(\<langle>p, topQ\<rangle>, \<langle>p', topQ\<rangle>) \<longleftrightarrow> comp(p, p')"
proof -
  have h1: "icomp(\<langle>p, topQ\<rangle>, \<langle>p', topQ\<rangle>) \<longleftrightarrow>
            (comp(p, p') \<and> compQ(topQ, topQ))"
    unfolding icomp_def by simp
  moreover have "compQ(topQ, topQ)" using compQ_top topQ_Q by simp
  ultimately show ?thesis by simp
qed

end

section \<open>马丁公理的化归一步（引理 3.58 的 MA* 到 MA）\<close>

text \<open>MA(κ)：任意 ccc 偏序与至多 κ 个稠密集有相遇滤子；
MA*(κ)：同上但偏序本身限制势至多 κ。化归的关键是闭包引理：
任何 ccc 偏序 P 与 κ 个稠密集 D_α，取每个 D_α 上的选择函数与
相容见证函数 g 在 κ 步内生成的闭包 Q（势至多 κ），则
D_α 交 Q 在 Q 中稠密且 Q 保持 ccc。此处将闭包存在性公理化，
化归便是一步逻辑。\<close>

locale ma_abstract =
  fixes kappa :: i
  fixes ccc :: "i \<Rightarrow> o"
  fixes maStar :: "i \<Rightarrow> o"
  fixes filter_meets :: "i \<Rightarrow> i \<Rightarrow> i \<Rightarrow> o"
  fixes closure_exists :: "i \<Rightarrow> i \<Rightarrow> i \<Rightarrow> o"
  assumes maStar_meets: "\<lbrakk>maStar(Q); D \<subseteq> kappa\<rbrakk> \<Longrightarrow>
    \<exists>F. filter_meets(Q, F, D)"
  assumes closure_ex: "\<lbrakk>D \<subseteq> kappa\<rbrakk> \<Longrightarrow> \<exists>Q. closure_exists(P, D, Q)"
  assumes closure_small: "\<lbrakk>closure_exists(P, D, Q)\<rbrakk> \<Longrightarrow> maStar(Q)"
  assumes closure_meet_transfer: "\<lbrakk>closure_exists(P, D, Q);
    filter_meets(Q, F, D)\<rbrakk> \<Longrightarrow> filter_meets(P, F, D)"

context ma_abstract
begin

text \<open>MA* 加上闭包引理给出 MA：小偏序上的相遇滤子原样是大偏序
上的相遇滤子。这一步是引理 3.58 中 (2) 蕴含 (1) 的全部逻辑内容；
闭包构造（选择函数加相容见证的迭代）由讲义承载。\<close>

lemma MA_from_MAStar:
  assumes hD: "D \<subseteq> kappa"
  shows "\<exists>F. filter_meets(P, F, D)"
proof -
  from closure_ex [OF hD] obtain Q where Qc: "closure_exists(P, D, Q)"
    by auto
  then have small: "maStar(Q)" using closure_small by simp
  from maStar_meets [OF small hD] obtain F
    where hf: "filter_meets(Q, F, D)" by auto
  have hres: "filter_meets(P, F, D)"
    using closure_meet_transfer [OF Qc hf] by simp
  then show ?thesis by (rule exI)
qed

end

section \<open>§3.4 讲义锚点\<close>

text \<open>一步迭代（定义 3.31/3.32：P-偏序集名字与 P*Q）、典型嵌入与
完备嵌入引理（定义 3.33、引理 3.54）、迭代泛型滤子 G*H 与一步迭代
引理（定义 3.34、定理 3.14：G*H 是 P*Q-泛型且分解唯一）、迭代与
乘积的关系（引理 3.53：乘积稠密嵌入进迭代）、迭代分配律（引理 3.55、
定理 3.15）由讲义与 Lean/Coq/Agda/计算通道的配对分解样品承载。
有限支撑迭代（定义 3.36/3.37）、迭代完备嵌入（引理 3.57）、
链条件保持（性质(K)、定理 3.16/3.17）与 Solovay-Tennenbaum 定理
（定理 3.18：ZFC+GCH 的可数传递模型上，长度 κ 的有限支撑迭代
给出 MA + 2^ω = κ 的模型；记录函数用 Cantor 配对实现，其编号
不小于第一分量——Lean/Coq 的 cantor_selfLE 验证了这一公理），
以及 MA 的三重等价（引理 3.58）与推论（连续统可停在任意正则
κ > ω₁）亦由讲义承载。\<close>

end
