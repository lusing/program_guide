theory T46_analysis_intro
  imports Complex_Main
begin

section \<open>46.1 分析库开门：滤子语言\<close>

text \<open>HOL 会话镜像里的 @{verbatim "Complex_Main"} 是分析世界的正门：
@{verbatim "Complex + MacLaurin + Binomial_Plus"}——滤子、极限、连续、
导数全在。通用语是**滤子**（filter）——"邻域"的抽象：
@{verbatim "at x"}（x 处邻域）、@{verbatim "at_right a"}、
@{verbatim "at_infinity"}、@{verbatim "sequentially"}（自然数滤子）。
极限、连续、导数全部用 @{verbatim "(f <longlongrightarrow> L) F"} 一个动词表达。
本理论在主会话里就能跑（Complex_Main 已在 HOL 镜像，实测零额外
构建成本——这是当初把它放主会话的依据）。\<close>

ML \<open>writeln "==== 46 开始 ===="\<close>

subsection \<open>46.2 极限：tendsTo 的入门双例\<close>

text \<open>常函数与多项式——两块垫脚石。常函数 @{verbatim "tendsto_const"}
无条件成立；多项式用 @{verbatim "tendsto_intros"} 规则组逐步拼：\<close>

lemma const_lim: "((\<lambda>n. (5::real)) \<longlongrightarrow> 5) sequentially"
  by (rule tendsto_const)

lemma poly_lim: "((\<lambda>x. x * x) \<longlongrightarrow> a * a) (at a)"
  for a :: real
  by (intro tendsto_intros)

subsection \<open>46.3 连续：continuous_on 与 at\<close>

definition sq :: "real \<Rightarrow> real" where "sq x = x * x"

lemma sq_cont: "continuous_on UNIV sq"
  unfolding sq_def by (intro continuous_intros)

lemma sq_cont_at: "continuous (at a) sq"
  unfolding sq_def by (intro continuous_intros)

subsection \<open>46.4 导数：DERIV 的两种说法\<close>

text \<open>@{verbatim "DERIV f x :> d"} 是教科书句式（实值函数）；
更一般的 @{verbatim "(f has_derivative f') F"} 里导数是**线性映射**，
支撑欧氏空间。@{verbatim "x * x"} 求导用两条 identity 乘积
（@{verbatim "DERIV_mult"}），或者直接调 @{verbatim "derivative_intros"}
规则组：\<close>

lemma sq_deriv: "DERIV sq x :> 2 * x"
  unfolding sq_def
  by (intro derivative_eq_intros)
     (auto intro: derivative_intros)

subsection \<open>46.5 一条 IVT：连续函数穿零必有点\<close>

lemma crosses_zero:
  fixes f :: "real \<Rightarrow> real"
  assumes cont: "continuous_on {0..1} f" and f0: "f 0 \<le> 0" and f1: "0 \<le> f 1"
  shows "\<exists>x\<in>{0..1}. f x = 0"
proof -
  have "\<exists>x\<ge>0. x \<le> 1 \<and> f x = 0"
    by (rule IVT' [where f = f and a = 0 and b = 1 and y = 0];
        simp_all add: cont f0 f1)
  then show ?thesis by auto
qed

subsection \<open>46.6 边界：Complex_Main 不是全量 Analysis\<close>

text \<open>实测边界（容易想错）：@{verbatim "Complex_Main"} 里
@{verbatim "find_theorems has_integral"} **零结果**——Henstock--Kurzweil
积分住在 **HOL-Analysis 会话**（@{verbatim "Analysis/Henstock_Kurzweil_Integration.thy"}
里的 @{verbatim "ident_has_integral"}、@{verbatim "integral_unique"}），
不在 Complex_Main 的导入宇宙里。要用积分，要么把理论放进
HOL-Analysis 父会话（多一次堆构建），要么像本教程这样在
Complex_Main 内完成极限/连续/导数主线。滤子/拓扑/连续的全部
基础设施两边共享。\<close>

subsection \<open>46.7 坑位清单（实测）\<close>

text \<open>1. 类型不写 @{verbatim "real"} 就没有分析：@{verbatim "1 / n"}
   在 @{verbatim "nat"} 上是整除，极限定理全不适用。
2. @{verbatim "continuous_on A f"}（集合上）与 @{verbatim "continuous (at x) f"}
   （一点处）是两个谓词，混用点 @{verbatim "at_within"} 桥接。
3. @{verbatim "DERIV"} 的 @{verbatim ":>"} 三件套是一个语法单元；
   @{verbatim "derivative_intros"} 对**多层复合**好用，裸乘积
   x * x 一类 auto intro! 有时推不动——@{verbatim "metis"}
   配 @{verbatim "DERIV_mult"}/@{verbatim "DERIV_ident"} 是稳兜底。
4. IVT 系列引理名带撇号分方向：@{verbatim "IVT'"} 要求
   @{verbatim "f a <le> 0 \<le> f b"}；拿 @{verbatim "IVT"} 硬套
   方向反了证不出。
5. **积分不在 Complex_Main**（46.6）：以为
   @{verbatim "has_integral"} 随手就有，实测 undefined fact。
6. 极限记号 @{verbatim "(f <longlongrightarrow> L) F"} 的长箭头是语法；
   ASCII 环境写长箭头转义。\<close>

thm const_lim poly_lim sq_cont sq_deriv crosses_zero

ML \<open>writeln "==== 46 结束 ===="\<close>

end
