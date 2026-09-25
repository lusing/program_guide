theory S01_overview
  imports Main
begin

section \<open>1.1 seL4 是"被证明过的内核"\<close>

text \<open>
  其他语言教程里，示例跑出正确输出就算过。seL4 的出场方式不同：它是一份
  用 Isabelle/HOL 写出来的内核规范，以及一条从规范一路精化到 C 代码与
  机器码的证明链。本教程的示例沿用在 Isabelle/HOL 教程里立下的规矩：
  \emph{每一条 lemma 都必须被机器逐条认可}，整个会话构建通过，示例才算活着。

  本教程引用的"真实代码"分成两个仓库，都放在验证脚本的 @{verbatim "SE4SRC"}
  根目录下（默认 Linux 是 @{verbatim "/home/admin/hol/seL4"}，见 README）：
  \begin{itemize}
    \item @{verbatim "seL4/"}：内核 C 源码、libsel4 头文件、manual；
    \item @{verbatim "l4v/"}：Isabelle/HOL 规范与证明（l4v = L4.verified）。
  \end{itemize}
  教程里出现的每个 @{verbatim "seL4/..."} 与 @{verbatim "l4v/..."} 路径都由
  @{verbatim "tools/check-refs.py"} 对着这个根目录逐条核实，带行号的还要
  在该行上下 8 行内找到离它最近的那个标识名。

  示例文件本身是\emph{自包含的迷你模型}：它们只 imports @{verbatim Main}，
  不依赖 l4v 的会话。原因是 l4v 全量构建需要若干小时与特定的
  Isabelle 版本，而教程要能被反复重跑。每一章的模型都对应
  l4v 里的真实定义，章首会给出文件与行号，读者可以对照阅读。
\<close>

ML \<open>writeln "==== 01 开始 ===="\<close>

subsection \<open>1.2 环境自检\<close>

ML \<open>
  writeln ("Isabelle 版本标识: " ^ getenv "ISABELLE_IDENTIFIER")
\<close>

subsection \<open>1.3 最小的能力模型：权利的集合\<close>

text \<open>
  seL4 里"能不能做一件事"完全由\emph{能力（capability）}决定，能力携带一组
  \emph{权利（rights）}。l4v 的真实定义在
  @{verbatim "l4v/spec/abstract/CapRights_A.thy"} 第 19 行：
  @{verbatim "datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply"}，
  权利集合就是 @{verbatim "cap_rights = rights set"}。本章先用同样的形状建一个模型。
\<close>

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"

definition all_rights :: cap_rights where
  "all_rights \<equiv> UNIV"

definition no_rights :: cap_rights where
  "no_rights \<equiv> {}"

text \<open>掩码（mask）取交集。真实定义见
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 242 行：
  @{verbatim "mask_cap rights cap \<equiv> cap_rights_update (cap_rights cap \<inter> rights) cap"}。\<close>

definition mask :: "cap_rights \<Rightarrow> cap_rights \<Rightarrow> cap_rights" where
  "mask R R' \<equiv> R \<inter> R'"

subsection \<open>1.4 第一条定理：掩码不会让权利变多\<close>

lemma mask_subset: "mask R R' \<subseteq> R"
  by (auto simp: mask_def)

lemma mask_idempotent: "mask (mask R R') R' = mask R R'"
  by (auto simp: mask_def)

lemma mask_all_rights: "mask R all_rights = R"
  by (auto simp: mask_def all_rights_def)

text \<open>这三条就是 seL4 权限模型的全部直觉：派生能力只能\emph{削弱}权利，
  不能创造权利。整本教程后面所有的安全定理，都是这三条的某种放大。\<close>

value "length [AllowRead, AllowWrite, AllowGrant, AllowGrantReply]"
value "rev [AllowRead, AllowGrant]"

text \<open>定理一旦证出就进了当前理论的事实库，可以按名字取出来看——这也是后续
  章节观察规则的通用手段。\<close>

ML \<open>writeln (@{make_string} @{thm mask_subset})\<close>

subsection \<open>1.5 本教程的验证方式\<close>

text \<open>
  根目录的 @{verbatim "run-all.sh"} 做五件事：
  (1) @{verbatim "isabelle build -D examples"} 全量构建；
  (2) @{verbatim "isabelle process_theories -O"} 捕获每个示例的标记区间；
  (3) 同一命令连跑两遍；(4) 标记区间逐字节比对；
  (5) 检查各章文档里引用的真实代码路径确实存在。
  第 5 关是 seL4 教程特有的：正文中出现的每一个文件路径都要能被
  @{verbatim "test -f"} 命中，不写想象中的引用。
\<close>

ML \<open>writeln "==== 01 结束 ===="\<close>

end
