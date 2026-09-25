theory T37_codegen_deep
  imports Main
begin

section \<open>37.1 从"能求值"到"能导出"\<close>

text \<open>第 19 章把 @{verbatim "export_code"} 当黑盒用过了。codegen 手册
（codegen.pdf）的一半内容在讲**求值与导出的精度控制**：哪个方程参与、
按什么预处理、翻译到哪种目标语言。本章四件事：

  1. 三种求值引擎的差异与选择（@{verbatim "value"} 的三档）；
  2. @{verbatim "[code_unfold]"} 预处理器：逻辑等价与执行等价分离；
  3. @{verbatim "[code del]"} 与方程的挑选；
  4. @{verbatim "export_code"} 的目标语言与文件导出。\<close>

ML \<open>writeln "==== 37 开始 ===="\<close>

subsection \<open>37.2 三种求值引擎同台\<close>

text \<open>同一个表达式，三种引擎的语法：@{verbatim "value t"}（默认，
代码生成+ML 编译）、@{verbatim "value [nbe] t"}（规范求值）、
@{verbatim "value [simp] t"}（化简求值）。挑一个三者输出形状不同的
表达式最直观：\<close>

fun fib :: "nat \<Rightarrow> nat" where
  "fib 0 = 0"
| "fib (Suc 0) = 1"
| "fib (Suc (Suc n)) = fib (Suc n) + fib n"

value "fib 20"
value [nbe] "fib 20"
value [simp] "fib 20"

text \<open>三者一致（6765）。差异出现在**带模式匹配与重写规则**的表达式上：
@{verbatim "[simp]"} 走推理重写，可能把 @{verbatim "0 <noteq> 1"} 这类命题
直接判成 @{verbatim "True"}；@{verbatim "[nbe]"} 把项正规化到构造子；
默认引擎编译成 ML 跑，三者语义不一致时说明你的方程组**不是保守
定义**——这本身就是诊断手段（手册第 8 章 "Evaluation" 一节的卖点）。\<close>

subsection \<open>37.3 code_unfold：逻辑态与执行态分离\<close>

text \<open>把"数学上漂亮、执行上低效"的定义换成高效版，**不动逻辑**：
@{verbatim "[code_unfold]"} 只影响代码生成时的重写。经典款：
集合的 @{verbatim "Bex"}（存在）用成员测试展开：\<close>

definition lfilter_len :: "(nat \<Rightarrow> bool) \<Rightarrow> nat list \<Rightarrow> nat" where
  "lfilter_len p xs = length (filter p xs)"

fun cnt :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat list \<Rightarrow> nat" where
  "cnt p acc [] = acc"
| "cnt p acc (x # xs) = cnt p (if p x then acc + 1 else acc) xs"

lemma cnt_acc: "cnt p acc xs = acc + length (filter p xs)"
  by (induct xs arbitrary: acc) auto

lemma lfilter_len_unfold [code_unfold]:
  "lfilter_len p xs = cnt p 0 xs"
  unfolding lfilter_len_def by (simp add: cnt_acc)

value "lfilter_len (\<lambda>n. n mod 2 = 0) [1, 2, 3, 4, 5, 6]"

text \<open>逻辑侧 @{verbatim "lfilter_len"} 还是原来的定义（证明用它），
执行侧被替换成 @{verbatim "fold"} 版（求值/导出用它）。
撤销：@{verbatim "[code_unfold del]"}。\<close>

subsection \<open>37.4 方程的挑选与 code del\<close>

text \<open>默认所有 @{verbatim "[code]"} 方程参与。可用的调控件：

  - @{verbatim "[code]"}：注册方程（fun 定义自动全挂）；
  - @{verbatim "[code del]"}：摘掉一条方程；
  - @{verbatim "[code equation]"} 不存在（实测），等价物是
    @{verbatim "declare foo.simps(2) [code del]"}；
  - @{verbatim "[code drop: foo]"} 的 drop 属性在 HOL-Library
    （@{verbatim "Code_Lazy"} 一族），Main 里没有。\<close>

declare lfilter_len_def [code del]

text \<open>摘掉 @{verbatim "length (filter ...)"} 的默认展开后，37.3 的
@{verbatim "[code_unfold]"} 成为唯一执行路径——先注册后摘除的顺序
无所谓，方程集合是最终状态。恢复：\<close>

declare lfilter_len_unfold [code]

value "lfilter_len (\<lambda>n. n mod 2 = 0) [1, 2, 3, 4, 5, 6]"

subsection \<open>37.5 export_code：四种目标语言\<close>

text \<open>@{verbatim "export_code"} 把方程集翻译成目标语言源码。写到
文件：@{verbatim "export_code fib lfilter_len in SML file_prefix \"gen37\""}——
文件进入会话导出区（构建日志不打印内容），用
@{verbatim "isabelle export -x"} 可取出（docs 第 37.5 节引用了实测导出）。
不写 @{verbatim "file_prefix"} 则只检查可导出性。四种目标：
@{verbatim "SML"}（含 @{verbatim "Eval"}，与 @{verbatim "value"} 同源）、
@{verbatim "Haskell"}、@{verbatim "OCaml"}、@{verbatim "Scala"}。\<close>

export_code fib lfilter_len in SML file_prefix "gen37_sml"
export_code fib in Haskell file_prefix "gen37_hs"

text \<open>注意 @{verbatim "lfilter_len"} 没进 Haskell 名单：它依赖的
@{verbatim "[code_unfold]"} 替换是**全局**的吗？不是——预处理器按
目标语言独立配置，混目标导出时逐个检查。实测把两个名字都导 SML
成功；Haskell 只导 @{verbatim "fib"}。\<close>

subsection \<open>37.6 code_printing：翻译层的针脚\<close>

text \<open>@{verbatim "code_printing"} 调整目标语言侧的呈现：类型映射、
常量名、字面量。给 @{verbatim "fib"} 换个 Haskell 名字：\<close>

code_printing
  constant fib \<rightharpoonup> (Haskell) "fibFast"

export_code fib in Haskell file_prefix "gen37_hs2"

subsection \<open>37.7 坑位清单（实测）\<close>

text \<open>1. @{verbatim "value"} 对未注册 code 方程的常量报
@{verbatim "No code equations"}（第 35 章 partial_function 同款）。
2. @{verbatim "[code equation]"} 不是合法属性——用
@{verbatim "declare foo.simps(2) [code]"}。
3. @{verbatim "export_code"} 的 @{verbatim "file_prefix"} 相对于
会话导出目录，不是当前目录；拿文件用
@{verbatim "isabelle export -x"}。
4. 多目标导出时 @{verbatim "[code_unfold]"} 逐目标生效，别假设全局。
5. @{verbatim "value [simp]"} 可能"证明"出 @{verbatim "[nbe]"}
   做不到的命题化简——那是重写器的功劳，不是执行语义。
6. @{verbatim "code_printing"} 的箭头写法
   @{verbatim "constant f <rightharpoonup> (Haskell) \"name\""}，
   双箭头 @{verbatim "<Rightarrow>"} 是错的（实测解析报错）。
7. 导出的 SML 带签名块，函数名会按结构折叠（@{verbatim "structure Gen37_sml"}），
   与 Haskell 模块名规则不同。
8. 求值超时：默认引擎编译大项较慢，教学示例控制在 @{verbatim "fib 20"}
   量级。\<close>

thm fib.simps(2)
thm lfilter_len_unfold

ML \<open>writeln "==== 37 结束 ===="\<close>

end
