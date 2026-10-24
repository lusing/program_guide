theory T69_ccl_set
  imports "IsaTutCCL.Set" "IsaTutCCL.Lfp" "IsaTutCCL.Gfp" "IsaTutCCL.Trancl"
begin

section \<open>69.1 CCL 库：Isabelle 自带的"计算逻辑"活化石\<close>

text \<open>1993 年，剑桥大学计算机实验室的 Martin Coen 为 Isabelle 写了一整套
@{verbatim CCL}（Classical Computational Logic，经典可计算逻辑）：
在 FOL 之上造集合论、不动点、传递闭包，最终得到一个**无类型函数语言**
的指称语义，并附带自然数、列表、流、荷兰国旗四个可执行例子。
它不是历史包袱——Isabelle2025-2 发行版仍然带着它，会话索引
@{verbatim "FOL/CCL"} 一共列出 16 个理论：

  - @{verbatim IFOL} / @{verbatim FOL}：直觉主义 / 经典一阶逻辑（第 47 章）；
  - @{verbatim Set} / @{verbatim Lfp} / @{verbatim Gfp} / @{verbatim Trancl}：
    集合论、最小 / 最大不动点、传递闭包——本章；
  - @{verbatim CCL} / @{verbatim Term} / @{verbatim Type} / @{verbatim Hered} /
    @{verbatim Wfd} / @{verbatim Fix}：无类型 λ 演算、类型即项集、
    遗传终止性、良基关系、不动点归纳——第 70/71 章；
  - @{verbatim Nat} / @{verbatim List} / @{verbatim Stream} / @{verbatim Flag}：
    四个计算逻辑实例——第 72 章。

本教程把这 14 个库理论**原样**收进 @{verbatim "examples/cclbase/"}
（会话 @{verbatim IsaTutCCL}，内容即发行版 @{verbatim "src/CCL/"} 的拷贝），
T69–T72 四个示例建立在该会话之上。本章引用的库代码都在正文原样贴出，
读者不需要自己去翻源码。\<close>

ML \<open>writeln "==== 69 开始 ===="\<close>


subsection \<open>69.2 两条公理造出集合论\<close>

text \<open>FOL 本身没有集合。CCL 的 @{verbatim Set} 理论只做两件事：
用 @{verbatim typedecl} 造一个新类型 @{verbatim "'a set"}，
再用两条公理定义 @{verbatim Collect} 与 @{verbatim mem}
（库源码 @{verbatim "src/CCL/Set.thy"} 第 9–18 行）：

@{verbatim "typedecl 'a set"}

@{verbatim "axiomatization Collect :: \"['a \<Rightarrow> o] \<Rightarrow> 'a set\""}
@{verbatim "  and mem :: \"['a, 'a set] \<Rightarrow> o\"  (infixl \":\" 50)"}
@{verbatim "where mem_Collect_iff: \"(a : Collect(P)) \<longleftrightarrow> P(a)\""}
@{verbatim "  and set_extension: \"A = B \<longleftrightarrow> (ALL x. x:A \<longleftrightarrow> x:B)\""}

注意这是**公理**不是定义：在 FOL 里，集合就是谓词的外延化身。
@{verbatim set_extension} 说两个集合相等当且仅当元素逐个相同。\<close>

thm mem_Collect_iff
thm set_extension

text \<open>概括语法 @{verbatim "{x. P(x)}"} 是 @{verbatim Collect} 的语法糖，
靠 @{verbatim translations} 折叠成 λ 抽象（库源码第 20–25 行）。
引入 / 消去是一对规则：\<close>

lemma collect_demo:
  assumes "P(a)"
  shows "a : {x. P(x)}"
  using assms by (rule CollectI)

lemma collectD_demo:
  assumes "a : {x. P(x)}"
  shows "P(a)"
  using assms by (rule CollectD)

text \<open>外延公理的使用形态 @{verbatim set_ext}：证集合相等，
就是逐点证明成员关系双向成立：\<close>

lemma set_ext_demo:
  assumes "\<And>x. x:A \<longleftrightarrow> x:B"
  shows "A = B"
  using assms by (rule set_ext)

thm trivial_set


subsection \<open>69.3 有界量词：1993 年的 ASCII 量词还活着\<close>

text \<open>Set 理论定义了两个**有界**量词（库源码第 46–60 行）：

@{verbatim "definition Ball :: \"['a set, 'a \<Rightarrow> o] \<Rightarrow> o\""}
@{verbatim "  where \"Ball(A, P) == ALL x. x:A \<longrightarrow> P(x)\""}

注意写法 @{verbatim "ALL x:A. P(x)"}：这不是新符号，是 FOL 自带的
ASCII 量词形态（@{verbatim "Pure_Thy.old_appl_syntax_setup"} 的遗产），
与 @{verbatim "\<forall>x. P(x)"} 完全等价——CCL 库全文用 ASCII 形态书写。
@{verbatim "EX x:A. P(x)"}、@{verbatim "INT x:A. B(x)"}、
@{verbatim "UN x:A. B(x)"} 同款。\<close>

thm Ball_def
thm Bex_def

lemma ball_demo:
  assumes "\<And>x. x:A \<Longrightarrow> P(x)"
  shows "ALL x:A. P(x)"
  using assms by (rule ballI)

lemma bspec_demo:
  assumes "ALL x:A. P(x)" and "a:A"
  shows "P(a)"
  using assms by (rule bspec)

thm bexI
thm bexE


subsection \<open>69.4 基本运算：I/D/E 三件套与"经典"变体\<close>

text \<open>库源码第 99–119 行定义 @{verbatim subset} / @{verbatim singleton} /
@{verbatim empty} / @{verbatim Un} / @{verbatim Int} / @{verbatim Compl}。
规则命名法三件套：I 引入、D 消去（destruct，Modus Ponens 风格）、
E 消除（elimination，分类讨论风格）；带 C 的是**经典**变体——
前提里出现否定，靠排中律兜底，IFOL 里不可用。\<close>

thm subset_def
thm Un_def
thm Int_def
thm Compl_def

thm subsetI
thm subsetD
thm subsetCE
thm UnI1
thm UnCI
thm IntI
thm ComplD

lemma subset_demo:
  assumes "A <= B" and "a:A"
  shows "a:B"
  using assms by (rule subsetD)

lemma unci_demo:
  assumes "\<not> a:B \<Longrightarrow> a:A"
  shows "a : A Un B"
  using assms by (rule UnCI)

lemma compl_demo:
  assumes "a : Compl(A)"
  shows "\<not> a:A"
  using assms by (rule ComplD)


subsection \<open>69.5 族运算：并交就是上下界\<close>

text \<open>库源码第 123–143 行：@{verbatim INTER} / @{verbatim UNION} 吃函数族，
@{verbatim Inter} / @{verbatim Union} 吃集合族。格论视角：
@{verbatim Union} 是一族集合的**最小上界**，@{verbatim Inter} 是**最大下界**——
这正是库给它们起的规则名（@{verbatim Union_upper} / @{verbatim Union_least}
/ @{verbatim Inter_lower} / @{verbatim Inter_greatest}）。\<close>

thm INTER_def
thm UNION_def
thm Union_upper
thm Union_least
thm Inter_lower
thm Inter_greatest

lemma union_least_demo:
  assumes "\<And>X. X:A \<Longrightarrow> X <= C"
  shows "Union(A) <= C"
  using assms by (rule Union_least)


subsection \<open>69.6 lfp：最小不动点与 Knaster–Tarski\<close>

text \<open>库源码 @{verbatim "src/CCL/Lfp.thy"} 第 12–14 行：

@{verbatim "definition lfp :: \"['a set\<Rightarrow>'a set] \<Rightarrow> 'a set\" where"}
@{verbatim "  \"lfp(f) == Inter({u. f(u) <= u})\""}

最小不动点 = 所有**前不动点**（@{verbatim "f(u) <= u"}）的交。
两条刻画不需要单调性；单调性才保证它真是不动点（Knaster–Tarski）。
第 51 章在 HOL 里证过同样的定理，这里是 FOL 版。\<close>

thm lfp_def
thm lfp_lowerbound
thm lfp_greatest
thm lfp_lemma2
thm lfp_Tarski

text \<open>库用 apply 脚本证 @{verbatim lfp_lemma2}（源码第 24–25 行）。
改写成 Isar，看两向夹逼怎么走：要证 @{verbatim "f(lfp(f)) <= lfp(f)"}，
用 @{verbatim lfp_greatest} 把目标转成"对任意前不动点 u 都是下界"，
再用 @{verbatim lfp_lowerbound} 拿到 @{verbatim "lfp(f) <= u"}，
单调性传过去：\<close>

lemma lfp_lemma2_demo:
  assumes mono: "mono(f)"
  shows "f(lfp(f)) <= lfp(f)"
proof (rule lfp_greatest)
  fix u
  assume hu: "f(u) <= u"
  from hu have lub: "lfp(f) <= u" by (rule lfp_lowerbound)
  from mono lub have step: "f(lfp(f)) <= f(u)" by (rule monoD)
  from step hu show "f(lfp(f)) <= u" by (rule subset_trans)
qed

text \<open>配套的 @{verbatim lfp_lemma3}（源码第 27–28 行）是对偶方向，
两条一夹就是 @{verbatim lfp_Tarski}。库还给出通用**归纳规则**
@{verbatim induct}（源码第 36–45 行）——第 71 章讲 Nat/List 归纳时用它。\<close>

thm lfp_lemma3
thm induct


subsection \<open>69.7 gfp：最大不动点与三级余归纳\<close>

text \<open>库源码 @{verbatim "src/CCL/Gfp.thy"} 第 12–14 行，与 lfp 完全对偶：

@{verbatim "definition gfp :: \"['a set\<Rightarrow>'a set] \<Rightarrow> 'a set\" where"}
@{verbatim "  \"gfp(f) == Union({u. u <= f(u)})\""}

最大不动点 = 所有**后不动点**（@{verbatim "u <= f(u)"}）的并。
先看一个两理论联合作战的小证明——单调函数的 lfp 永远装在 gfp 里：\<close>

thm gfp_def
thm gfp_upperbound
thm gfp_least
thm gfp_Tarski

lemma lfp_subset_gfp_demo:
  assumes mono: "mono(f)"
  shows "lfp(f) <= gfp(f)"
proof (rule lfp_lowerbound)
  show "f(gfp(f)) <= gfp(f)" by (rule gfp_lemma3[OF mono])
qed

text \<open>gfp 的真正威力在**余归纳**：要证 @{verbatim "a : gfp(f)"}，
找一个集合 A 把 a 装进去，再证 @{verbatim "A <= f(A)"} 就行
（@{verbatim coinduct}，源码第 38–39 行）。Martin Coen 把它强化成三级
（源码第 41–90 行），条件是 @{verbatim "A <= f(A) Un gfp(f)"}——
允许把"已经知道在 gfp 里的东西"提前用上：\<close>

thm coinduct
thm coinduct2
thm coinduct3

text \<open>三级余归纳是第 70 章证 λ 演算行为等价、第 72 章证无限列表
等式的主力武器，届时回头看这三条规则。\<close>


subsection \<open>69.8 传递闭包：lfp 的第一个用户\<close>

text \<open>库源码 @{verbatim "src/CCL/Trancl.thy"} 第 21–25 行：

@{verbatim "definition rtrancl :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"r^* == lfp(\<lambda>s. id Un (r O s))\""}
@{verbatim "definition trancl :: \"i set \<Rightarrow> i set\""}
@{verbatim "  where \"r^+ == r O rtrancl(r)\""}

自反传递闭包是 @{verbatim "λs. id Un (r O s)"} 的最小不动点；
传递闭包再复合一步 r。注意类型：关系是 @{verbatim "i set"}——
@{verbatim i} 是 CCL 的项类型（第 70 章主角），因为 1993 年造传递闭包
就是为了服务 λ 演算的归约关系，不是任意类型的通用库。
不动点方程 @{verbatim rtrancl_unfold} 是全库的钥匙：\<close>

thm rtrancl_def
thm rtrancl_unfold
thm rtrancl_refl
thm r_into_rtrancl

text \<open>库用 unfold + blast 证明"走一步仍在中"（源码第 91–95 行）。
这里改用显式规则链重证一遍——注意 @{verbatim subst} 是**展开**
（把目标里的 @{verbatim "r^*"} 换成不动点方程的右边）：\<close>

lemma rtrancl_into_rtrancl_demo:
  assumes h1: "<a,b> : r^*" and h2: "<b,c> : r"
  shows "<a,c> : r^*"
proof (subst rtrancl_unfold)
  show "<a,c> : id Un (r O r^*)"
  proof (rule UnI2)
    show "<a,c> : r O r^*" by (rule compI[OF h1 h2])
  qed
qed

text \<open>从 unfold 方程还能长出**归纳规则**（源码第 106–130 行）：
前向归纳 @{verbatim rtrancl_full_induct} 与更好用的
@{verbatim rtrancl_induct}；传递性 @{verbatim trans_rtrancl}
就是用它证的。@ {verbatim "r^+"} 与 @{verbatim "r^*"} 的互转规则
（@{verbatim trancl_into_rtrancl} 等，源码第 155–205 行）配套齐全。\<close>

thm rtrancl_full_induct
thm rtrancl_induct
thm trans_rtrancl
thm trancl_into_rtrancl
thm tranclE


subsection \<open>69.9 库怎么喂自动证明器\<close>

text \<open>Set 理论的最后一段（源码第 376–391 行）把整库规则按用途挂到
blast / simp 的规则集上：

@{verbatim "lemmas [intro!] = ballI subsetI InterI INT_I CollectI ComplI IntI UnCI singletonI"}
@{verbatim "  and [intro] = bexI UnionI UN_I"}
@{verbatim "  and [elim!] = bexE UnionE UN_E CollectE ComplE IntE UnE emptyE singletonE"}
@{verbatim "  and [elim] = ballE InterD InterE INT_D INT_E subsetD subsetCE"}

@{verbatim "lemmas [simp] = trivial_set empty_eq mem_rews"}
@{verbatim "  and [cong] = ball_cong bex_cong INT_cong UN_cong"}

感叹号是优先级：@{verbatim "intro!"} 盖过上下文里可能冲突的引入规则。
@{verbatim mem_rews} 是一族成员关系重写规则——挂上 @{verbatim "[simp]"}
之后，blast 证集合等式基本一步过：\<close>

thm mem_rews

lemma blast_set_demo:
  "a : (A Un B) Int C \<longleftrightarrow> (a:A | a:B) \<and> a:C"
  by blast

text \<open>库自身也吃这套配置：整部 @{verbatim Set} 理论的等式定律
（交换律、结合律、分配律、De Morgan，源码第 394–516 行）
几乎全是 @{verbatim "by (blast intro: equalityI)"} 一行流。\<close>

lemma Int_Un_distrib_demo: "A Int (B Un C) = (A Int B) Un (A Int C)"
  by (blast intro: equalityI)

lemma Compl_Un_demo: "Compl(A Un B) = Compl(A) Int Compl(B)"
  by (blast intro: equalityI)


subsection \<open>69.10 坑位清单（实测）\<close>

text \<open>1. **Isabelle2025-2 的 CCL 会话只剩 5 个理论**——发行版
   @{verbatim "src/CCL/ROOT"} 只列 @{verbatim Wfd} / @{verbatim Fix} /
   @{verbatim "ex/Nat"} / @{verbatim "ex/List"} / @{verbatim "ex/Stream"} /
   @{verbatim "ex/Flag"}；@{verbatim Set} / @{verbatim Lfp} / @{verbatim Gfp} /
   @{verbatim CCL} / @{verbatim Trancl} / @{verbatim Term} / @{verbatim Type} /
   @{verbatim Hered} 是留在树里的遗留文件。要用得自建会话
   （本教程的 @{verbatim IsaTutCCL}）。
2. **Draft 会话里 @{verbatim "imports Set"} 解析不到**——
   @{verbatim process_theories} 的 Draft 会话只在自己的 @{verbatim "-D"}
   目录里找理论文件。正解是限定导入 @{verbatim "\"IsaTutCCL.Set\""}
   （同第 45 章的 @{verbatim "\"HOL-Library.Multiset\""} 套路）。
3. **库理论绝不能标 @{verbatim "(global)"}**——会把 @{verbatim Set} /
   @{verbatim Nat} / @{verbatim List} / @{verbatim Stream} 污染成全局名，
   与 HOL / ZF / HOL-Library 里的同名理论相撞，整个构建报
   @{verbatim "Bad import of theory ... need to include sessions"}。
4. **ASCII 量词 @{verbatim ALL} / @{verbatim EX} / @{verbatim INT} /
   @{verbatim UN} 在 FOL 里可用**，但常量名不能叫它们（词法层整词替换，
   第 18 章同款）；@{verbatim SUM} / @{verbatim PROD} / @{verbatim INF} /
   @{verbatim SUP} 在 CCL 里根本不存在。
5. **应用必须写括号**：@{verbatim "P(a)"} 不是 @{verbatim "P a"}
   （FOL 旧应用语法，第 47 章同款坑）。
6. **Trancl 的关系是 @{verbatim "i set"}**（CCL 项类型），
   不是任意 @{verbatim "'a set"}——照搬 HOL 的 @{verbatim trancl}
   经验会类型不匹配。
7. **@{verbatim "subst rtrancl_unfold"} 是展开不是收拢**：
   等式左边是 @{verbatim "r^*"}，subst 把目标里的闭包换成方程右边；
   想反向走要用 @{verbatim "subst (asm) ..."} 或对称改写。
8. **@{verbatim lfp_lowerbound} 不需要 @{verbatim mono}**；
   @{verbatim lfp_Tarski} 才需要（与 HOL 的 @{verbatim lfp_unfold}
   区别，见第 51 章）。
9. **blast 的证明力来自 @{verbatim "[intro!]"} / @{verbatim "[elim!]"}
   分组**——自己写证明时 @{verbatim "intro:"} / @{verbatim "elim:"}
   要显式给，别指望默认集。
10. **库源码是 1993 年 apply 风格**（@{verbatim "apply ... done"}），
    读的时候先还原每条规则的朝向；本章示例一律改写成 Isar。\<close>

thm collect_demo collectD_demo set_ext_demo
  ball_demo bspec_demo
  subset_demo unci_demo compl_demo
  union_least_demo
  lfp_lemma2_demo lfp_subset_gfp_demo
  rtrancl_into_rtrancl_demo
  blast_set_demo Int_Un_distrib_demo Compl_Un_demo

subsection \<open>69.11 与其他章的接口\<close>

text \<open>第 47 章 FOL 是本章的父逻辑；第 70 章把 @{verbatim ":"}
改造成类型判断、把 @{verbatim gfp} 的余归纳升级成
@{verbatim eq_coinduct3}；第 71 章把 @{verbatim lfp} 的
@{verbatim induct} 规则变成 @{verbatim Nat_ind} / @{verbatim List_ind}；
第 72 章的四个例子理论把本章全部机制跑一遍。\<close>

ML \<open>writeln "==== 69 结束 ===="\<close>

end
