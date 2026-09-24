theory S19_cspec
  imports Main
begin

section \<open>19.1 把 C 代码搬进 Isabelle\<close>

text \<open>
  设计规范之下还有一层：C 代码本身。l4v 的做法是把 C
  \emph{自动翻译}进 Isabelle，入口是
  @{verbatim "l4v/spec/cspec/"}（@{verbatim "KernelState_C.thy"}、
  @{verbatim "KernelInc_C.thy"}），翻译用的源是经过预处理的
  @{verbatim "spec/cspec/c/"}（由 @{verbatim "seL4/"} 仓库生成，
  两者由 CI 的 Proof Sync 流水线保持一致）。

  翻译分两步：
  \begin{enumerate}
    \item \emph{C → Simpl}：由 C 解析器（@{verbatim "c-parser"}）把每个函数
          翻译成一个 Simpl 语言的语句；
    \item \emph{Simpl → 可读的规范}：由 @{verbatim "autocorres"} 把指针、
          结构体字段访问包装成抽象类型，产生形如
          @{verbatim "get_cap'_proc"} 的定义。
  \end{enumerate}

  本章建一个最小的"C 风格堆"，说明翻译之后要证明的东西长什么样。
\<close>

ML \<open>writeln "==== 19 开始 ===="\<close>

type_synonym addr = nat
type_synonym word = nat
type_synonym heap = "addr \<Rightarrow> word option"

definition empty_heap :: heap where "empty_heap \<equiv> \<lambda>_. None"

definition load :: "addr \<Rightarrow> heap \<Rightarrow> word option" where
  "load a h \<equiv> h a"

definition store :: "addr \<Rightarrow> word \<Rightarrow> heap \<Rightarrow> heap" where
  "store a v h \<equiv> h(a \<mapsto> v)"

subsection \<open>19.2 最基础的三条堆定律\<close>

lemma load_after_store: "load a (store a v h) = Some v"
  by (simp add: load_def store_def)

lemma load_other_after_store:
  "b \<noteq> a \<Longrightarrow> load b (store a v h) = load b h"
  by (simp add: load_def store_def)

lemma store_twice: "store a v2 (store a v1 h) = store a v2 h"
  by (rule ext) (simp add: store_def)

text \<open>
  这三条是 autocorres 里 @{verbatim "heap_wp"} 战术自动做的事：
  把连续的 load/store 化简成"最后一次写入"。
  真实内核的 C 代码里有成千上万次结构体字段访问，
  全靠这类定律压下去。
\<close>

subsection \<open>19.3 一个 C 函数的翻译形态\<close>

text \<open>
  下面这段模拟 seL4 里读取能力权利字段的 C 函数。
  C 里它是一次结构体字段访问，翻译成 Isabelle 之后变成
  "读某个地址上的某个偏移"，并且带上一个
  \emph{该地址确实被映射}的前提条件。
\<close>

record cap_struct =
  cap_word0 :: word
  cap_word1 :: word

type_synonym c_heap = "addr \<Rightarrow> cap_struct option"

definition cap_get_rights :: "addr \<Rightarrow> c_heap \<Rightarrow> word option" where
  "cap_get_rights p h \<equiv> case h p of None \<Rightarrow> None | Some c \<Rightarrow> Some (cap_word1 c)"

definition cap_set_rights :: "addr \<Rightarrow> word \<Rightarrow> c_heap \<Rightarrow> c_heap" where
  "cap_set_rights p v h \<equiv> case h p of
      None \<Rightarrow> h
    | Some c \<Rightarrow> h(p \<mapsto> c\<lparr> cap_word1 := v \<rparr>)"

lemma get_after_set:
  "h p \<noteq> None \<Longrightarrow> cap_get_rights p (cap_set_rights p v h) = Some v"
  by (auto simp: cap_get_rights_def cap_set_rights_def split: option.splits)

lemma get_unmapped_is_none:
  "h p = None \<Longrightarrow> cap_get_rights p h = None"
  by (simp add: cap_get_rights_def)

lemma set_preserves_other_field:
  "h p = Some c \<Longrightarrow> cap_word0 (the (cap_set_rights p v h p)) = cap_word0 c"
  by (auto simp: cap_set_rights_def)

text \<open>
  @{thm get_unmapped_is_none} 对应 C 里"空指针解引用"：
  在 Isabelle 里它不会崩，而是返回一个 @{verbatim "None"}，
  于是"这段 C 代码合法"变成了"证明这个 @{verbatim "None"} 分支不会出现"。
  这是把 C 翻译进逻辑之后最本质的一个转变：
  \emph{未定义行为变成了必须被排除的分支}。
\<close>

subsection \<open>19.4 从 C 回到设计规范：c_corres\<close>

text \<open>
  C 层与设计层之间的对应叫 @{verbatim "c_corres"}，
  与第 18 章的 @{verbatim "corres"} 同形，只是关系 R 变成了
  "C 堆里的字节 ↔ 设计规范里的记录"。

  真实定理在 @{verbatim "l4v/proof/crefine/"} 下，形状大致是

  @{verbatim "c_corres ... (dcap_get_rights ...) (cap_get_rights ...)"}

  模型里用一个"字段投影"关系演示同一件事。
\<close>

record dcap =
  d_rights :: word
  d_badge  :: word

definition dcap_of :: "cap_struct \<Rightarrow> dcap" where
  "dcap_of c \<equiv> \<lparr> d_rights = cap_word1 c, d_badge = cap_word0 c \<rparr>"

definition d_get_rights :: "dcap \<Rightarrow> word" where
  "d_get_rights c \<equiv> d_rights c"

lemma c_matches_d:
  "h p = Some c \<Longrightarrow> cap_get_rights p h = Some (d_get_rights (dcap_of c))"
  by (simp add: cap_get_rights_def dcap_of_def d_get_rights_def)

text \<open>
  @{thm c_matches_d} 就是一次 @{verbatim "c_corres"} 证明的极小形态：
  C 侧读出来的字 == 设计侧记录里的字段。
  真实内核里这样的定理有上千条，覆盖每一个 C 函数。
\<close>

subsection \<open>19.5 翻译不是"信它没错"\<close>

text \<open>
  最后要说明一件事：C 解析器本身\emph{不在}被证明的范围里。
  l4v 的可信基础（@{verbatim "CAVEATS"} 文档里有明确说明）包括
  \begin{itemize}
    \item C 解析器与 autocorres 的正确性（工具，未被形式验证）；
    \item 编译器与汇编器的正确性（seL4 用的是经过验证的编译路径与
          @{verbatim "proof/asmrefine"} 里的二进制级证明来缩小这一块）；
    \item 硬件模型（@{verbatim "spec/machine/"}）。
  \end{itemize}

  @{verbatim "seL4/CAVEATS.md"} 是这份清单的官方版本，读证明之前应该先看它。
\<close>

ML \<open>
  writeln (@{make_string} @{thm load_after_store});
  writeln (@{make_string} @{thm c_matches_d})
\<close>

ML \<open>writeln "==== 19 结束 ===="\<close>

end
