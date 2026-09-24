theory T21_sessions
  imports Main
begin

section \<open>21.1 会话：Isabelle 的工程单位\<close>

ML \<open>writeln "==== 21 开始 ===="\<close>

text \<open>单个 @{verbatim ".thy"} 文件叫理论（theory），一批理论加上构建
配置叫会话（session）。会话用 @{verbatim "ROOT"} 文件描述，本教程
@{verbatim "examples/ROOT"} 的核心内容就是这三行：

@{verbatim "session IsaTut = HOL +"}

@{verbatim "options [document = false]"}

@{verbatim "theories T01_overview ... T24_capstone"}

第一行声明父会话：@{verbatim "HOL"} 决定这份工程从哪个 heap 镜像
起步，也就是 @{verbatim "imports Main"} 背后那套东西从哪来。
第二行是构建选项，@{verbatim "document = false"} 关掉 LaTeX 文档照排
（要出 PDF 就写 @{verbatim "document = true"} 并配 @{verbatim "root.tex"}）。
第三行是理论清单：列表**有序**，但依赖仍然由文件里的
@{verbatim "imports"} 决定，清单只控制加载与错误处理顺序。

构建的入口是 @{verbatim "isabelle build -D examples"}：它先检查依赖，
再按需重新处理理论，最后把会话的 heap 镜像写进用户 heaps 目录。
第二次构建几乎瞬时——前提是没有改过任何被依赖的理论。会话还能
被子会话继承（@{verbatim "session Sub = IsaTut + ..."}），这就是
@{verbatim "HOL-Library"} 这类"父 + 库"套娃的来源。\<close>

subsection \<open>21.2 名字空间：全名、隐藏与开放\<close>

text \<open>每个理论里的声明都有带理论名前缀的完整名字：@{verbatim "helper"} 的
全名是 @{verbatim "T21_sessions.helper"}。平时能用短名，是因为
名字空间把同名条目"开放"了出来。 @{verbatim "hide_const"} 可以把短名
把短名收回去，只留全名——这在"我的定义和库里的撞名"时很有用。\<close>

definition helper :: "nat \<Rightarrow> nat" where
  "helper n = n + 1"

lemma helper_pos: "0 < helper n"
  by (simp add: helper_def)

hide_const (open) helper

text \<open>从这一行往下，短名 @{verbatim "helper"} 不再可用（包括它的
@{verbatim "_def"} 派生事实），必须写全名：\<close>

lemma helper_pos2: "0 < T21_sessions.helper n"
  by (simp add: T21_sessions.helper_def)

subsection \<open>21.3 bundle：可开关的语法与规则包\<close>

text \<open>bundle 把一批 @{verbatim "declare"} / @{verbatim "notation"} 打包，
只在 @{verbatim "context includes B"} 里生效。典型用途是"这段好不容易
既要符号、又要特化 simp 规则，但别污染全局"。\<close>

definition myop :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "myop a b = a + b + 1"

bundle myop_syntax
begin
notation myop  (infixl "\<oplus>" 65)
declare myop_def [simp]
end

context includes myop_syntax
begin

lemma myop_sample: "1 \<oplus> 2 = 4"
  by simp

end

text \<open>出了 @{verbatim "context"}， @{verbatim "\<oplus>"} 消失了， @{verbatim "myop"}
也不再自动展开——同一份定义在不同地方可以有不同"便利度"。\<close>

subsection \<open>21.4 named_theorems：自己开一个规则集合\<close>

text \<open>@{verbatim "named_theorems"} 声明一个动态规则集，之后用属性
@{verbatim "[my_rules]"} 往里塞定理，用 @{verbatim "simp add: my_rules"}
一次性取出。它比手抄 @{verbatim "lemmas"} 列表强在：别人（以及下游理论）
可以往里追加，不必改你的引理。\<close>

named_theorems my_rules

lemma myop_comm [my_rules]: "myop a b = myop b a"
  by (simp add: myop_def add.commute)

lemma myop_comm_use: "myop x y = myop y x"
  by (simp add: my_rules)

subsection \<open>21.5 属性的加与减\<close>

text \<open>属性用 @{verbatim "declare"} 增删：@{verbatim "[simp]"}、@{verbatim "[intro]"}、
@{verbatim "[dest]"}、@{verbatim "[iff]"} 是加，对应的 @{verbatim "[simp del]"}
是减。全局 @{verbatim "declare foo [simp]"} 会影响整条理论后续的所有证明，
能写成局部 @{verbatim "simp add: foo"} 就别写全局。
@{verbatim "lemmas"} 可以把若干条定理一次性命名并打属性。\<close>

lemmas myop_pair = myop_def myop_comm

declare myop_def [simp]
lemma "myop 1 2 = 4" by simp
declare myop_def [simp del]

subsection \<open>21.6 让 theory 输出可验证的结果\<close>

text \<open>本教程的每个示例都用 @{verbatim "ML \<open>writeln ...\<close>"} 打了起止标记，
验证脚本抽标记之间的输出做逐字节比对。这是件小事，但值得写进规范：
命令自身的输出（批注、@{verbatim "value"}、@{verbatim "print_locale"}）
会随版本变化，只有"圈出来的区间"才是稳定可比的。\<close>

ML \<open>writeln "==== 21 结束 ===="\<close>

end
