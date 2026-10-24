theory T73_lcf
  imports "IsaTutLCF.LCF" "IsaTutLCF.Ex1" "IsaTutLCF.Ex3" "IsaTutLCF.Ex4"
begin

section \<open>73.1 LCF：域论与计算的部分正确性逻辑\<close>

text \<open>第 54 章讲过 LCF 的历史：Milner 1972 年的 Edinburgh LCF、
Paulson 1987 年的 Cambridge LCF，以及为它而生的 ML。本章把镜头拉近——
Isabelle 发行版自带的 @{verbatim "LCF"} 理论（Tobias Nipkow 1992 年从 Paulson 的书
Logic and Computation 提炼）就是 Cambridge LCF 的核心逻辑在 Isabelle 里
的再形式化。

它回答一个具体问题：一个程序设计语言的语义、加上证明其部分正确性的
推理规则，怎样装进一阶逻辑？答案是域论（domain theory）：

  - 每个类型都是完全偏序（cpo）：有偏序 @{verbatim "<<"}，
    有最小元 @{verbatim "UU"}（读作 bottom，表示不终止）；
  - 程序的指称是 cpo 的元素，递归定义的指称是函数的最小不动点
    @{verbatim "FIX(f)"}；
  - 等式 @{verbatim "="} 不是原始的——它被定义成两个方向的偏序
    （@{verbatim "eq_def"}），所以 LCF 的等式推理天然是双向小于等于。

与第 69--72 章的 CCL 对比着读最有味道：CCL 用余归纳定义行为等价，
LCF 用不动点归纳证明部分正确性——同一个计算逻辑命题在 1990 年代
初的两条路线。

LCF 会话一共 5 个理论：@{verbatim "LCF"} 本体 + 四个书例（@{verbatim "Ex1"}--
@{verbatim "Ex4"}，全部来自 Paulson 书里的编号：Section 10.4、Example 3.8、
加法、prefixpoint）。本教程把它们原样收进 @{verbatim "examples/lcfbase/"}（会话
@{verbatim "IsaTutLCF"}），T73 建立其上。\<close>

ML \<open>writeln "==== 73 开始 ===="\<close>


subsection \<open>73.2 cpo、UU 与 FIX：六条域论公理\<close>

text \<open>库开篇（源码第 16--28 行）用类型类把 cpo 宣告为万物的
默认排序，然后声明常量（第 30--44 行）：

@{verbatim "class cpo = \"term\""}
@{verbatim "default_sort cpo"}

@{verbatim "typedecl tr"}       三值逻辑：UU / TT / FF
@{verbatim "typedecl void"}     只有一个元素的类型
@{verbatim "typedecl ('a,'b) prod  (infixl \"*\" 6)"}
@{verbatim "typedecl ('a,'b) sum   (infixl \"+\" 5)"}

函数空间、积、和、@{verbatim "tr"}、@{verbatim "void"} 全部是 cpo。

接着是六条域论公理（第 46--59 行）：

@{verbatim "eq_def:    x=y == x << y \<and> y << x"}

@{verbatim "less_trans:   \<lbrakk>x << y; y << z\<rbrakk> \<Longrightarrow> x << z"}
@{verbatim "less_ext:     (\<forall>x. f(x) << g(x)) \<Longrightarrow> f << g"}
@{verbatim "mono:         \<lbrakk>f << g; x << y\<rbrakk> \<Longrightarrow> f(x) << g(y)"}
@{verbatim "minimal:      UU << x"}
@{verbatim "FIX_eq:       \<And>f. f(FIX(f)) = FIX(f)"}

@{verbatim "less_trans"} 是偏序的传递性；@{verbatim "less_ext"} 说函数的序由逐点
序决定（外延性）；@{verbatim "mono"} 把两层序接起来（单调性）；
@{verbatim "minimal"} 说 @{verbatim "UU"} 是万物之底；@{verbatim "FIX_eq"} 是整座大厦的
拱顶石——每个连续函数都有不动点，且 FIX 就是它。

注意 @{verbatim "FIX_eq"} 的形态：它是一条等式公理，由 @{verbatim "eq_def"}
展开就是两个方向的 @{verbatim "<<"}。所以 LCF 从第一行起就是
偏序语义、等式语法。

六条公理实测打印：\<close>

thm eq_def less_trans less_ext mono minimal FIX_eq

text \<open>注意打印形态：@{verbatim "x=y"} 打印成 @{verbatim "x = y"}——但读者要
时刻记得它只是 @{verbatim "x << y \<and> y << x"} 的缩写，第 73.6 节
会看到库里的定理一半靠这条展开。\<close>


subsection \<open>73.3 tr 与 COND：三值条件、UU 吞掉一切\<close>

text \<open>布尔值不是两个而是三个（第 61--73 行）：

@{verbatim "tr_cases:      p=UU \<or> p=TT \<or> p=FF"}
@{verbatim "not_TT_less_FF: \<not> TT << FF"}
@{verbatim "not_FF_less_TT: \<not> FF << TT"}
@{verbatim "not_TT_less_UU: \<not> TT << UU"}
@{verbatim "not_FF_less_UU: \<not> FF << UU"}

@{verbatim "COND_UU:       UU \<Rightarrow> x | y  =  UU"}
@{verbatim "COND_TT:       TT \<Rightarrow> x | y  =  x"}
@{verbatim "COND_FF:       FF \<Rightarrow> x | y  =  y"}

@{verbatim "tr_cases"} 是穷举：任何 @{verbatim "tr"} 要么未定义、要么真、要么假。
四条 @{verbatim "not_*_less_*"} 说这三个值互不重叠且 TT/FF 严格在 UU 之上。

条件表达式 @{verbatim "b \<Rightarrow> x | y"} 的三条计算规则是典型的严格性
（strictness）设计：条件未定义，整个表达式就未定义——LCF 是部分
函数语言的语义，不终止会传染。

实测打印（注意记号 @{verbatim "_ \<Rightarrow>/ (_ |/ _)"} 的中缀形态）：\<close>

thm tr_cases not_TT_less_FF not_TT_less_UU
thm COND_UU COND_TT COND_FF

text \<open>第 184--235 行从这几条公理长出第一批工具引理。
最有代表性的是 @{verbatim "tr_induct"}（三情况穷举归纳）与 @{verbatim "COND_cases_iff"}
（COND 的完整刻画）：

@{verbatim "tr_induct: \<lbrakk>P(UU); P(TT); P(FF)\<rbrakk> \<Longrightarrow> \<forall>b. P(b)"}

@{verbatim "COND_cases_iff: \<forall>b. P(b\<Rightarrow>x|y) \<longleftrightarrow>"}
  @{verbatim "(b=UU\<longrightarrow>P(UU)) \<and> (b=TT\<longrightarrow>P(x)) \<and> (b=FF\<longrightarrow>P(y))"}

@{verbatim "COND_cases_iff"} 把对 COND 的行为做推理化归成对三个分支分别
推理——后面 @{verbatim "Ex1"} / @{verbatim "Ex2"} 的证明里
@{verbatim "simp split: COND_cases_iff"} 一把梭就是靠它。\<close>

thm tr_induct COND_cases_iff COND_cases


subsection \<open>73.4 积、严格和与 void：三个数据类型\<close>

text \<open>积类型（第 75--81、248--293 行）：

@{verbatim "surj_pairing:  <FST(z),SND(z)> = z"}
@{verbatim "FST:   FST(<x,y>) = x"}
@{verbatim "SND:   SND(<x,y>) = y"}

关键引理 @{verbatim "UU_is_UU_UU"}：@{verbatim "<UU,UU> = UU"}——积的 bottom
就是 bottom 的积，第 282--293 行推出 @{verbatim "FST(UU) = UU"}、
@{verbatim "SND(UU) = UU"}（投影也严格）。@{verbatim "PROD_less"} 给出积上序的
逐分量刻画：@{verbatim "p << q \<longleftrightarrow> FST(p) << FST(q) \<and> SND(p) << SND(q)"}。

严格和（第 83--97 行）：

@{verbatim "INL_DEF: \<not>x=UU \<Longrightarrow> \<not>INL(x)=UU"}
@{verbatim "INR_DEF: \<not>x=UU \<Longrightarrow> \<not>INR(x)=UU"}
@{verbatim "INL_STRICT: INL(UU) = UU"}
@{verbatim "INR_STRICT: INR(UU) = UU"}
@{verbatim "WHEN_UU:  WHEN(f,g,UU) = UU"}
@{verbatim "WHEN_INL: \<not>x=UU \<Longrightarrow> WHEN(f,g,INL(x)) = f(x)"}
@{verbatim "WHEN_INR: \<not>x=UU \<Longrightarrow> WHEN(f,g,INR(x)) = g(x)"}
@{verbatim "SUM_EXHAUSTION: z = UU \<or> (\<exists>x. \<not>x=UU \<and> z = INL(x)) \<or> (\<exists>y. \<not>y=UU \<and> z = INR(y))"}

@{verbatim "WHEN"} 是和类型上的分派子（CCL 的 @{verbatim "case"} 同款角色），
严格性规则与 CCL 完全同构——第 70 章讲过的应用即 case 在这里
换成分派即 WHEN。

@{verbatim "void"} 类型（第 99--102 行）只有一条公理：

@{verbatim "void_cases: (x::void) = UU"}

void 里只有 UU——它是空数据类型的域论化身：一个不产出任何
已定义值的类型。

三组数据公理实测：\<close>

thm surj_pairing FST SND
thm INL_STRICT INR_STRICT WHEN_UU WHEN_INL WHEN_INR SUM_EXHAUSTION
thm void_cases
thm PROD_less PAIR_less PAIR_eq UU_is_UU_UU FST_STRICT SND_STRICT


subsection \<open>73.5 基础引理流水线：从公理到工具\<close>

text \<open>第 125--235 行是一段密集的引理流水线，全部从六条域论
公理 + @{verbatim "eq_def"} 展开出发。几组关键工具：

等式与序的互译（第 125--137 行）：

@{verbatim "eq_imp_less1: x = y \<Longrightarrow> x << y"}
@{verbatim "eq_imp_less2: x = y \<Longrightarrow> y << x"}
@{verbatim "less_refl [simp]: x << x"}
@{verbatim "less_anti_sym: \<lbrakk>x << y; y << x\<rbrakk> \<Longrightarrow> x=y"}

外延与合同（第 139--163 行）：

@{verbatim "ext: (\<And>x. f(x)=g(x)) \<Longrightarrow> (\<lambda>x. f(x)) = (\<lambda>x. g(x))"}
@{verbatim "cong: \<lbrakk>f = g; x = y\<rbrakk> \<Longrightarrow> f(x) = g(y)"}
@{verbatim "less_ap_term: x << y \<Longrightarrow> f(x) << f(y)"}
@{verbatim "less_ap_thm: f << g \<Longrightarrow> f(x) << g(x)"}
@{verbatim "ap_term: x = y \<Longrightarrow> f(x) = f(y)"}
@{verbatim "ap_thm: f = g \<Longrightarrow> f(x) = g(x)"}

UU 的专属事实（第 166--182 行）：

@{verbatim "UU_abs: (\<lambda>x. UU) = UU"}
@{verbatim "UU_app: UU(x) = UU"}
@{verbatim "less_UU: x << UU \<Longrightarrow> x = UU"}

注意名字的来历：@{verbatim "ap_term"} / @{verbatim "ap_thm"} 是 Cambridge LCF 的
老战术 AP_TERM / AP_THM 的直译——函数等于函数（thm）与应用到
项（term）两种合同推理。第 237--245 行把这些全部挂成 simp 规则，
于是 UU 吞掉一切在 simp 里免费。

tr 的六个不相等（第 204--215 行）：三条谁不等于谁由四条
not_less 公理经 @{verbatim "Contrapos"}（逆否）逐一推出：

@{verbatim "not_UU_eq_TT: UU \<noteq> TT"}
@{verbatim "not_UU_eq_FF: UU \<noteq> FF"}
@{verbatim "not_TT_eq_UU: TT \<noteq> UU"}
@{verbatim "not_TT_eq_FF: TT \<noteq> FF"}
@{verbatim "not_FF_eq_UU: FF \<noteq> UU"}
@{verbatim "not_FF_eq_TT: FF \<noteq> TT"}

全部实测：\<close>

thm eq_imp_less1 less_refl less_anti_sym ext cong
thm less_ap_term less_ap_thm ap_term ap_thm
thm UU_abs UU_app less_UU
thm not_UU_eq_TT not_TT_eq_FF not_FF_eq_UU

text \<open>两条小演示——严格性在 simp 里的样子：\<close>

lemma cond_tt_demo: "TT \<Rightarrow> a | b = (a::'a::cpo)"
  by simp

lemma fst_uu_demo: "FST(UU) = UU"
  by simp


subsection \<open>73.6 可采纳性：不动点归纳的门票\<close>

text \<open>第 106--122 行是全库的方法论核心。不动点归纳公理：

@{verbatim "induct: \<lbrakk>adm(P); P(UU); \<forall>x. P(x) \<longrightarrow> P(f(x))\<rbrakk> \<Longrightarrow> P(FIX(f))"}

读法：要证性质 P 对 @{verbatim "FIX(f)"} 的展开极限成立，需要三样东西：
P 从 UU 起步（@{verbatim "P(UU)"}）、每一步迭代保持
（@{verbatim "P(x) \<longrightarrow> P(f(x))"}）、以及 @{verbatim "adm(P)"}——P 是可采纳的
（admissible）。

可采纳性是域论的拓扑直觉：P 对链的极限封闭——一列越来越定义的
近似若每个都满足 P，极限也满足。没有它，不动点归纳就是错的
（比如 @{verbatim "x = UU"} 对每步迭代成立、对极限不成立）。

八条 adm 公理（第 115--122 行，Paulson 书第 199--200 页的规则表）：

@{verbatim "adm_less:      \<And>t u. adm(\<lambda>x. t(x) << u(x))"}
@{verbatim "adm_not_less:  \<And>t u. adm(\<lambda>x.\<not> t(x) << u)"}
@{verbatim "adm_not_free:  \<And>A. adm(\<lambda>x. A)"}
@{verbatim "adm_subst:     \<And>P t. adm(P) \<Longrightarrow> adm(\<lambda>x. P(t(x)))"}
@{verbatim "adm_conj:      \<And>P Q. \<lbrakk>adm(P); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<and>Q(x))"}
@{verbatim "adm_disj:      \<And>P Q. \<lbrakk>adm(P); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<or>Q(x))"}
@{verbatim "adm_imp:       \<And>P Q. \<lbrakk>adm(\<lambda>x.\<not>P(x)); adm(Q)\<rbrakk> \<Longrightarrow> adm(\<lambda>x. P(x)\<longrightarrow>Q(x))"}
@{verbatim "adm_all:       \<And>P. (\<And>y. adm(P(y))) \<Longrightarrow> adm(\<lambda>x. \<forall>y. P(y,x))"}

结构是一张谓词组合保持可采纳的表：@{verbatim "<<"} 两侧可采纳；否定
那边只能否掉左边（@{verbatim "adm_not_less"}）；命题常量免费；代入、合取、
析取、蕴含（左否定右可采纳）、全称都保持。第 298--319 行再补两条
派生：@{verbatim "adm_eq"}（等式可采纳，按 @{verbatim "eq_def"} 拆成两个
@{verbatim "adm_less"}）与 @{verbatim "adm_not_eq_tr"}（对三值 bool 的不等可采纳）。

库的总结在 @{verbatim "adm_lemmas"}（第 317--319 行）——后面 @{verbatim "induct"}
方法自动拿它当弹药库。

实测打印：\<close>

thm induct
thm adm_less adm_not_less adm_not_free adm_subst
thm adm_conj adm_disj adm_imp adm_all
thm adm_eq adm_not_eq_tr


subsection \<open>73.7 induct 方法与不动点三件套\<close>

text \<open>第 321--326 行把不动点归纳包成一个方法：先实例化函数
@{verbatim "f"}，再自动尝试用 @{verbatim "adm_lemmas"} 关掉可采纳性子目标。
用法：@{verbatim "apply (induct f)"}。谓词是公理表里没有的组合时（比如
任意的 @{verbatim "Q"}），adm 义务关不掉，必须自己作为前提提供。实测
一条——注意 @{verbatim "induct"} 留下三个子目标的顺序（adm / P(UU) /
逐步保持），示例证明里逐个用前提关：\<close>

lemma fix_induct_demo:
  fixes Q :: "'a::cpo \<Rightarrow> o" and s :: "'a::cpo \<Rightarrow> 'a::cpo"
  assumes admQ: "adm(Q)" and base: "Q(UU)"
    and step: "\<And>x. Q(x) \<Longrightarrow> Q(s(x))"
  shows "Q(FIX(s))"
  apply (induct s)
    apply (rule admQ)
   apply (rule base)
  apply (intro strip)
  apply (rule step)
  apply assumption
  done

text \<open>不动点理论的定理（第 328--379 行）：

@{verbatim "least_FIX: f(p) = p \<Longrightarrow> FIX(f) << p"}
@{verbatim "lfp_is_FIX: \<lbrakk>f(p) = p; \<forall>q. f(q)=q \<longrightarrow> p << q\<rbrakk> \<Longrightarrow> p = FIX(f)"}
@{verbatim "FIX_pair: <FIX(f),FIX(g)> = FIX(\<lambda>p.<f(FST(p)),g(SND(p))>))"}
@{verbatim "FIX1: FIX(f) = FST(FIX(\<lambda>p. <f(FST(p)),g(SND(p))>))"}
@{verbatim "FIX2: FIX(g) = SND(FIX(\<lambda>p. <f(FST(p)),g(SND(p))>))"}
@{verbatim "induct2: \<lbrakk>adm(\<lambda>p. P(FST(p),SND(p))); P(UU,UU);"}
  @{verbatim "\<forall>x y. P(x,y) \<longrightarrow> P(f(x),g(y))\<rbrakk> \<Longrightarrow> P(FIX(f),FIX(g))"}

@{verbatim "least_FIX"} 说 FIX 是最小不动点（任何不动点 p 都在它之上）；
@{verbatim "lfp_is_FIX"} 是刻画：既是不动点又最小，就是 FIX。
@{verbatim "FIX_pair"} 把两个不动点打包成一个——并行不动点，然后
@{verbatim "FIX1"} / @{verbatim "FIX2"} 拆回来。@{verbatim "induct2"} 是双函数版不动点
归纳：证两个递归定义相互合作满足 P 的利器。

实测：\<close>

thm least_FIX lfp_is_FIX FIX_pair FIX1 FIX2 induct2


subsection \<open>73.8 Ex1：幂等函数（Paulson 书 Section 10.4）\<close>

text \<open>四个书例登场。@{verbatim "Ex1"}（源码 @{verbatim "ex/Ex1.thy"}）
形式化 Paulson 书第 10.4 节的例子：一个重复直到谓词满足的
循环函数是幂等的。先公理化语法（第 8--20 行）：

@{verbatim "axiomatization P :: \"'a \<Rightarrow> tr\" and"}
  @{verbatim "G :: \"'a \<Rightarrow> 'a\" and H :: \"'a \<Rightarrow> 'a\" and"}
  @{verbatim "K :: \"('a \<Rightarrow> 'a) \<Rightarrow> ('a \<Rightarrow> 'a)\""}
@{verbatim "where"}
  @{verbatim "P_strict: P(UU) = UU and"}
  @{verbatim "K: K = (\<lambda>h x. P(x) \<Rightarrow> x | h(h(G(x)))) and"}
  @{verbatim "H: H = FIX(K)"}

@{verbatim "K"} 是循环体：谓词 @{verbatim "P"} 满足就返回 @{verbatim "x"}，否则做两次
@{verbatim "G"} 再递归。@{verbatim "H"} 是它的不动点。要证的最终目标：
@{verbatim "\<forall>x. H(H(x)) = H(x)"}——跑两遍等于跑一遍（幂等）。

库的证明分四步（第 24--40 行）。

第一步，展开：@{verbatim "H_unfold: H = K(H)"}——这就是 @{verbatim "FIX_eq"}
换个名字。

第二步，严格性：@{verbatim "H_strict [simp]: H(UU) = UU"}——展开 +
@{verbatim "P(UU) = UU"} 即得。

第三步是全证明的心脏：
@{verbatim "H_idemp_lemma: \<forall>x. H(FIX(K,x)) = FIX(K,x)"}

注意目标里 @{verbatim "FIX(K,x)"} 是把 FIX 应用到双参数函数的部分应用
——不动点归纳的对象不再是 @{verbatim "H"} 而是 @{verbatim "FIX(K)"} 的一般
展开。证明是标准三段式：@{verbatim "apply (induct K)"} 自动关 adm、
UU 起步靠 simp、归纳步用 @{verbatim "simp split: COND_cases_iff"} 把 COND
拆成三分支 + @{verbatim "H_unfold"} 改写内层调用。

第四步收口：@{verbatim "H_idemp: \<forall>x. H(H(x)) = H(x)"}，由引理按
@{verbatim "H"} 的定义折叠（@{verbatim "[folded H]"}）。

全部四条实测：\<close>

thm H_unfold H_strict H_idemp_lemma H_idemp


subsection \<open>73.9 Ex3 与 Ex4：加法与前缀点\<close>

text \<open>@{verbatim "Ex3"}（源码 @{verbatim "ex/Ex3.thy"}）是书上
后继的不动点是无穷大的例子：

@{verbatim "axiomatization s :: \"'a \<Rightarrow> 'a\" and p :: \"'a \<Rightarrow> 'a \<Rightarrow> 'a\""}
@{verbatim "where p_strict: p(UU) = UU and p_s: p(s(x),y) = s(p(x,y))"}

@{verbatim "s"} 是后继，@{verbatim "p"} 是加法（对第一参数递归）。定理：

@{verbatim "p(FIX(s),y) = FIX(s)"}

无穷大加任何数还是无穷大。证明只有两行：@{verbatim "apply (induct s)"}
对第一参数做不动点归纳，simp 用两条公理化规则直接收——adm 由
@{verbatim "adm_lemmas"} 自动关。

@{verbatim "Ex4"}（源码 @{verbatim "ex/Ex4.thy"}）是 @{verbatim "Ex4.example"}，
前缀点（prefixpoint）刻画：

@{verbatim "assumes asms: f(p) << p  \<And>q. f(q) << q \<Longrightarrow> p << q"}
@{verbatim "shows FIX(f) = p"}

p 是所有前缀点里最大的那个，当且仅当 p 就是 @{verbatim "FIX(f)"}。
这是 @{verbatim "lfp_is_FIX"} 的偏序版：不动点条件弱化成前缀点，
最小性条件相应变成比一切前缀点都大。证明把 @{verbatim "eq_def"}
展开成两个 @{verbatim "<<"}，一个方向不动点归纳、一个方向用
@{verbatim "FIX_eq"} 的等式一半。

两个例子实测：\<close>

thm Ex3.example
thm Ex4.example

text \<open>一个小复刻——@{verbatim "Ex3"} 型的推理直接上手做一遍。
先公理化自己的后继与加法：\<close>

axiomatization
  my_s :: "'a::cpo \<Rightarrow> 'a" and
  my_p :: "'a::cpo \<Rightarrow> 'a::cpo \<Rightarrow> 'a"
where
  my_p_strict: "my_p(UU) = UU" and
  my_p_s: "my_p(my_s(x),y) = my_s(my_p(x,y))"

declare my_p_strict [simp] my_p_s [simp]

lemma my_ex3: "my_p(FIX(my_s),y) = FIX(my_s)"
  apply (induct my_s)
  apply simp
  apply simp
  done


subsection \<open>73.10 Ex2：双不动点（Example 3.8）\<close>

text \<open>@{verbatim "Ex2"}（源码 @{verbatim "ex/Ex2.thy"}，书
Example 3.8）是四个例子里唯一用双参数不动点归纳的。它的公理化
与 @{verbatim "Ex1"} 共享名字 @{verbatim "P"}（都声明 @{verbatim "P :: 'a \<Rightarrow> tr"}），
所以不能与 @{verbatim "Ex1"} 同 imports（类型冲突实测：报
@{verbatim "Clash of types"} 的近亲错误）——本教程的 @{verbatim "imports"} 行
因此只带 Ex1/Ex3/Ex4。要看它的定理打印，单独开一个只导
@{verbatim "IsaTutLCF.Ex2"} 的会话即可；这里把源码全文贴出讲解（很短，
第 1--28 行）：

@{verbatim "theory Ex2"}
@{verbatim "imports \"../LCF\""}
@{verbatim "begin"}

@{verbatim "axiomatization"}
  @{verbatim "P     :: \"'a \<Rightarrow> tr\" and"}
  @{verbatim "F     :: \"'b \<Rightarrow> 'b\" and"}
  @{verbatim "G     :: \"'a \<Rightarrow> 'a\" and"}
  @{verbatim "H     :: \"'a \<Rightarrow> 'b \<Rightarrow> 'b\" and"}
  @{verbatim "K     :: \"('a \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b \<Rightarrow> 'b)\""}
@{verbatim "where"}
  @{verbatim "F_strict:     F(UU) = UU and"}
  @{verbatim "K:            K = (\<lambda>h x y. P(x) \<Rightarrow> y | F(h(G(x),y))) and"}
  @{verbatim "H:            H = FIX(K)"}

@{verbatim "declare F_strict [simp] K [simp]"}

@{verbatim "lemma example: \<forall>x. F(H(x::'a,y::'b)) = H(x,F(y))"}
  @{verbatim "apply (simplesubst H)"}
  @{verbatim "apply (induct \"K:: ('a\<Rightarrow>'b\<Rightarrow>'b) \<Rightarrow> ('a\<Rightarrow>'b\<Rightarrow>'b)\")"}
  @{verbatim "apply simp"}
  @{verbatim "apply (simp split: COND_cases_iff)"}
  @{verbatim "done"}

@{verbatim "end"}

设定：@{verbatim "H"} 是双参数递归函数（对 @{verbatim "x"} 递归），
@{verbatim "F"} 是另一个对第二参数位置严格单调的操作。定理
@{verbatim "\<forall>x. F(H(x,y)) = H(x,F(y))"} 说 F 穿过 H——把 F
塞进循环体等于把 F 套在结果外面。

证明三行：先把 @{verbatim "H"} 展开成 @{verbatim "FIX(K)"} 的迭代形态
（@{verbatim "simplesubst"}），然后对 @{verbatim "K"} 做不动点归纳。UU 步 simp
收（@{verbatim "F(UU) = UU"} 两头都是 UU）；归纳步
@{verbatim "simp split: COND_cases_iff"} 把 @{verbatim "P(x) \<Rightarrow> ... | ..."}
拆三支，TT/FF 支直接对上归纳假设。adm 义务由 @{verbatim "induct"}
方法从 @{verbatim "adm_lemmas"} 自动关闭——@{verbatim "adm_less"} 管
@{verbatim "F(..) << H(..)"} 形状的子公式（经 @{verbatim "eq_def"} 拆开）。

@{verbatim "induct2"}（第 73.7 节）在这里没用上——目标只有一个 FIX；
但当两个递归定义互相依赖时（@{verbatim "FIX_pair"} 的场景），
@{verbatim "induct2"} 就是唯一入口。它是并行递归正确性的标准武器，
Paulson 书里 WHILE 规则的证明就是它的变体。\<close>


subsection \<open>73.11 坑位清单（实测）\<close>

text \<open>1. @{verbatim "imports \"IsaTutLCF.ex.Ex1\""} 解析不到：理论注册名是
   @{verbatim "IsaTutLCF.Ex1"}（@{verbatim "directories \"ex\""} 不进限定名）。写带
   ex. 的全名反而报 @{verbatim "need to include sessions IsaTutLCF.ex"}。
2. Ex1 与 Ex2 不能同 imports：两者都公理化 @{verbatim "P :: 'a \<Rightarrow> tr"}，
   合并即类型冲突（@{verbatim "Clash of types"}）。要同时讲，只能串场或
   贴源码。
3. @{verbatim "induct"} 方法的 adm 不是万能关：谓词是 @{verbatim "adm_lemmas"}
   表内形状（@{verbatim "<<"} 组合、等、tr 不等）才自动；任意谓词
   @{verbatim "Q"} 必须把 @{verbatim "adm(Q)"} 当前提给。
4. @{verbatim "apply (induct f)"} 出三个子目标、顺序固定：adm / P(UU) /
   @{verbatim "\<forall>x. P(x) \<longrightarrow> P(f(x))"}。第三个是 strip 形态，直接
   assumption 关不掉，先 @{verbatim "intro strip"}。
5. @{verbatim "eq_def"} 是定义不是公理：证等式最常用的开局是
   @{verbatim "apply (unfold eq_def)"} 拆成两个 @{verbatim "<<"}（@{verbatim "Ex4"} 的
   证明就是）。反过来 @{verbatim "simp add: eq_def"} 也能把等式重写成序。
6. @{verbatim "ap_term"} / @{verbatim "ap_thm"} 的方向：term 是项相同函数作用
   （x=y 推 f(x)=f(y)），thm 是函数相同作用到项（f=g 推
   f(x)=g(x)）。与老 LCF 战术名对应，别记反。
7. @{verbatim "simp split: COND_cases_iff"} 是处理 COND 的标准姿势：直接
   simp 只会按 COND_TT/FF/UU 三条重写头部，要对条件分情况推理
   必须 split。
8. @{verbatim "FIX_eq"} 给的是等式、@{verbatim "least_FIX"} 给的是序：证
   @{verbatim "FIX(f) = p"} 要两个方向（@{verbatim "lfp_is_FIX"} 模板），只证一边
   会卡在另一半。
9. @{verbatim "UU_abs"}：@{verbatim "(\<lambda>x. UU) = UU"}——常函数 UU 就是
   UU 本身（函数空间的 bottom）。simp 已挂；手写证明时别绕路。
10. LCF 没有 @{verbatim "induct_tac"} 也没有结构归纳：唯一的归纳就是
    不动点归纳（@{verbatim "induct"} / @{verbatim "induct2"}）；数据上的推理靠穷举
    公理（@{verbatim "tr_cases"} / @{verbatim "SUM_EXHAUSTION"} / @{verbatim "void_cases"}）。\<close>


subsection \<open>73.12 与其他章的接口\<close>

text \<open>第 54 章讲 LCF 的历史（Milner/Paulson/ML 的诞生），本章是
它的逻辑本体；第 47 章 FOL 是本章的逻辑底座（LCF = FOL + 域论
公理）；第 69 章 lfp/gfp 是同一套不动点思想的集合论化身，
第 71 章 CCL 的 Wfd/Fix 则是另一个计算逻辑家族的对照。
@{verbatim "Ex1"} / @{verbatim "Ex3"} / @{verbatim "Ex4"} 的证明模式（induct + simp
split）与第 70 章 CCL 的余归纳模式（eq_coinduct3 + EQgen）恰成
镜像：一边自底向上逼近，一边自顶向下兜底。\<close>

thm eq_def less_trans FIX_eq induct induct2
  H_unfold H_idemp my_ex3 Ex3.example Ex4.example

ML \<open>writeln "==== 73 结束 ===="\<close>

end
