theory S20_refine_chain
  imports Main
begin

section \<open>20.1 一条链，四个层次\<close>

text \<open>
  把前面几章拼起来，seL4 的正确性是一条\emph{精化链}：

  \begin{enumerate}
    \item \textbf{抽象规范 A}：@{verbatim "spec/abstract/"}，写"内核做什么"；
    \item \textbf{设计规范 D}：@{verbatim "spec/design/"}，由 Haskell 模型生成，
          数据结构与 C 同形（第 18 章的 @{verbatim "corres"}）；
    \item \textbf{C 规范}：@{verbatim "spec/cspec/"}，由 C 代码自动翻译而来
          （第 19 章的 @{verbatim "c_corres"}）；
    \item \textbf{机器码}：@{verbatim "proof/asmrefine/"}，
          把编译后的二进制与 C 语义对应起来。
  \end{enumerate}

  链上每一环都给出"上一层做的事，下一层也做了"的定理，
  于是"抽象规范满足的性质"可以被搬到"真实二进制"上。
\<close>

ML \<open>writeln "==== 20 开始 ===="\<close>

subsection \<open>20.2 精化的传递性\<close>

text \<open>
  模型把"层"抽象成三元关系：@{verbatim "refines R m1 m2"} 表示
  m2 是 m1 的一个实现（在关系 R 下）。链能成立，
  靠的就是这条关系的传递性。
\<close>

text \<open>
  模型里的定义是"结果相关"：从相关的两个状态出发，
  跑完各自的程序之后仍然相关。
\<close>

definition refines' :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> 'a) \<Rightarrow> ('b \<Rightarrow> 'b) \<Rightarrow> bool" where
  "refines' R f g \<equiv> \<forall>a b. R a b \<longrightarrow> R (f a) (g b)"

lemma refines'_reflexive: "refines' (\<lambda>a b. a = b) f f"
  by (simp add: refines'_def)

lemma refines'_transitive:
  "refines' R1 f g \<Longrightarrow> refines' R2 g h \<Longrightarrow>
   refines' (R1 OO R2) f h"
  by (auto simp: refines'_def relcompp.simps) blast

text \<open>
  @{thm refines'_transitive} 就是整条精化链的代数依据：
  两环各自成立 ⟹ 合成关系下首尾也成立。
  @{verbatim "OO"} 是关系的复合（@{verbatim "relcompp"}）。
\<close>

subsection \<open>20.3 一个简单的三层链\<close>

text \<open>
  下面用三个具体的"层"把传递性跑一遍：
  \begin{itemize}
    \item 抽象层：一个自然数计数；
    \item 设计层：一个布尔"是否非零"；
    \item C 层：一个列表长度。
  \end{itemize}
\<close>

definition a_inc :: "nat \<Rightarrow> nat" where "a_inc n \<equiv> n + 1"

definition d_inc :: "bool \<Rightarrow> bool" where "d_inc b \<equiv> True"

definition rel_ad :: "nat \<Rightarrow> bool \<Rightarrow> bool" where
  "rel_ad n b \<equiv> b = (n \<noteq> 0)"

lemma a_to_d: "refines' rel_ad a_inc d_inc"
  by (auto simp: refines'_def rel_ad_def a_inc_def d_inc_def)

type_synonym clayer = "nat list"

definition c_inc :: "clayer \<Rightarrow> clayer" where "c_inc xs \<equiv> xs @ [0]"

definition rel_dc :: "bool \<Rightarrow> clayer \<Rightarrow> bool" where
  "rel_dc b xs \<equiv> b = (xs \<noteq> [])"

lemma d_to_c: "refines' rel_dc d_inc c_inc"
  by (auto simp: refines'_def rel_dc_def d_inc_def c_inc_def)

lemma a_to_c: "refines' (rel_ad OO rel_dc) a_inc c_inc"
  using a_to_d d_to_c by (rule refines'_transitive)

text \<open>
  @{thm a_to_c} 就是把两环合成一环后的样子。真实链里
  @{verbatim "refines'"} 换成 @{verbatim "corres_underlying"}，
  "层"换成 A / D / C / 汇编，形状完全一样。
\<close>

subsection \<open>20.4 链的两端：性质怎么搬过去\<close>

text \<open>
  仅有"行为一致"还不够，还要把\emph{性质}从抽象层搬到代码层。
  这需要精化关系是"满的"（每个抽象状态都有具体实现）。
\<close>

definition rel_total :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> bool" where
  "rel_total R \<equiv> \<forall>a. \<exists>b. R a b"

lemma abstract_property_transfers:
  "rel_total R \<Longrightarrow> refines' R f g \<Longrightarrow> R a b \<Longrightarrow> R (f a) (g b)"
  by (simp add: refines'_def)

text \<open>
  @{thm abstract_property_transfers} 看似只是把定义展开，
  但它说明了一件重要的事：\emph{抽象层的性质为什么对代码成立}——
  因为代码层的每个行为都能在抽象层找到一个对应行为，
  而抽象层那边已经证明了性质。
\<close>

subsection \<open>20.5 假设清单：读证明之前先看它\<close>

text \<open>
  l4v 的每一条定理都带着假设。真正读完整个仓库的人会告诉你：
  最有价值的不是定理本身，而是这份假设清单。典型的成员有
  \begin{itemize}
    \item 硬件模型：@{verbatim "spec/machine/"} 里对 MMU、中断控制器、
          定时器的建模是否与真芯片一致；
    \item 编译器与链接器（@{verbatim "proof/asmrefine/"} 覆盖了一部分，
          但不是全部优化）；
    \item 启动代码与内核初始化：@{verbatim "KernelInit_A.thy"} 之后
          才是被证明的状态；
    \item 配置：只有 *_verified.cmake 里那一批配置组合是经过验证的
          （见 @{verbatim "seL4/configs/"}）。
  \end{itemize}

  模型里把这件事写成一条"审计"清单：
\<close>

datatype assumption = HardwareModel | Compiler | BootCode | ConfigSet | CParser

definition verified_assumptions :: "assumption set" where
  "verified_assumptions \<equiv> {ConfigSet}"

definition unverified_assumptions :: "assumption set" where
  "unverified_assumptions \<equiv> {HardwareModel, Compiler, BootCode, CParser}"

lemma parser_is_not_verified: "CParser \<in> unverified_assumptions"
  by (simp add: unverified_assumptions_def)

lemma config_is_checked: "ConfigSet \<in> verified_assumptions"
  by (simp add: verified_assumptions_def)

lemma assumptions_partition:
  "verified_assumptions \<inter> unverified_assumptions = {}"
  by (auto simp: verified_assumptions_def unverified_assumptions_def)

ML \<open>
  writeln (@{make_string} @{thm a_to_c});
  writeln (@{make_string} @{thm refines'_transitive})
\<close>

ML \<open>writeln "==== 20 结束 ===="\<close>

end
