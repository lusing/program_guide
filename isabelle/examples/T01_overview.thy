theory T01_overview
  imports Main
begin

section \<open>1.1 这是一本"机器当裁判"的教程\<close>

text \<open>其他语言教程里，示例跑出正确输出就算过；
在 Isabelle/HOL 里，示例中的每一条 lemma 都必须被机器逐条认可，
整个会话构建通过，示例才算活着。验证命令是
@{verbatim "isabelle build"}，观察输出用 @{verbatim "isabelle process_theories -O"}。
本文件的 ML 块会打印一对标记行，验证脚本只比对标记之间的字节。\<close>

ML \<open>writeln "==== 01 开始 ===="\<close>

subsection \<open>1.2 环境自检\<close>

text \<open>先确认自己在哪个 Isabelle 里跑。字符串直接来自 ML 端的
@{verbatim "getenv"}，教程不引用任何想象中的输出。\<close>

ML \<open>
  writeln ("Isabelle 版本标识: " ^ getenv "ISABELLE_IDENTIFIER")
\<close>

subsection \<open>1.3 计算：先看看求值器长什么样\<close>

text \<open>@{verbatim "value"} 用代码生成器求值并打印结果与类型——
注意 nat 的字面量与打印格式，第 11 章会专门讲算术。\<close>

value "(1::nat) + 2 * 3"
value "rev [1::nat, 2, 3]"
value "map (\<lambda>n. n * n) [1::int, 2, 3]"

subsection \<open>1.4 证明：第一条被机器认可的定理\<close>

lemma first_proof: "1 + 1 = (2::nat)"
  by simp

text \<open>@{verbatim "by simp"} 的意思是"交给化简器，证完为止"。
@{verbatim "simp"} 不是万灵药——第 6 章会展示它失败的样子与解法。\<close>

lemma and_swap: "A \<and> B \<longleftrightarrow> B \<and> A"
  by blast

text \<open>定理一旦证出，就存进当前理论的"事实库"，可以按名字取用。
下面用 ML 把它拿出来打印——这也是后续章节观察规则的通用手段。\<close>

ML \<open>writeln (@{make_string} @{thm and_swap})\<close>

subsection \<open>1.5 本教程的验证方式\<close>

text \<open>仓库根目录的 @{verbatim "run-all.sh"} 做四件事：
(1) @{verbatim "isabelle build -D examples"} 全量构建，证明错误在此暴露；
(2) @{verbatim "isabelle process_theories -O"} 捕获每个示例的标记区间；
(3) 同一命令连跑两遍；(4) 逐字节比对两遍输出。
单引擎没有"多通道"可比，就用运行间确定性替代跨通道一致性。\<close>

ML \<open>writeln "==== 01 结束 ===="\<close>

end
