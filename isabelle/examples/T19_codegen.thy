theory T19_codegen
  imports Main
begin

section \<open>19.1 从定义到可执行程序\<close>

text \<open>Isabelle 里的 @{verbatim "fun"}、@{verbatim "primrec"}、
@{verbatim "definition"} 既是逻辑对象（带生成定理），也能被"编译"：
代码生成器把它们的方程翻译到 ML / OCaml / Haskell / Scala，
于是 @{verbatim "value"} 能算出结果，@{verbatim "eval"} 能当证明方法用。

本章讲三件事：三种求值引擎的区别、代码方程是怎么选的、
以及怎么把定义导出成真正的源码文件。\<close>

ML \<open>writeln "==== 19 开始 ===="\<close>

subsection \<open>19.2 三种求值引擎\<close>

text \<open>先看一个经典的非尾递归定义。@{verbatim "fib 20"} 用 naive 写法
要算上百万次，正好用来体现三种引擎的差别。\<close>

fun fib :: "nat \<Rightarrow> nat" where
  "fib 0 = 0"
| "fib (Suc 0) = 1"
| "fib (Suc (Suc n)) = fib n + fib (Suc n)"

value "fib 10"

text \<open>上面这条 @{verbatim "value"} 的默认引擎是 @{verbatim "code"}：
把 @{verbatim "fib"} 编译进 Poly/ML 再跑。它最快，但要 ML 运行时。

第二种是 @{verbatim "nbe"}（求值即归一化，normalisation by evaluation）：
不生成 ML，而是在内核里把项重写到范式。它对**部分实例化的项**也能算，
这是 ML 引擎做不到的。\<close>

value [nbe] "fib 10"

text \<open>第三种 @{verbatim "code_simp"} 只是把代码方程当 @{verbatim "simp"} 规则
用，纯符号化、不产生数值以外的东西。三者在同一条等式上都能当证明方法：

\begin{itemize}
\item @{verbatim "by eval"} —— 编译执行后比对
\item @{verbatim "by normalization"} —— 归一化为同一范式
\item @{verbatim "by code_simp"} —— 用代码方程做符号化简
\end{itemize}\<close>

lemma "fib 10 = 55" by eval
lemma "fib 10 = 55" by normalization
lemma "fib 10 = 55" by code_simp

text \<open>尾递归版本可以直接看出执行器的"步数感"。\<close>

subsection \<open>19.3 尾递归与辅助引理\<close>

fun trev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "trev [] ys = ys"
| "trev (x # xs) ys = trev xs (x # ys)"

lemma trev_eq: "trev xs ys = rev xs @ ys"
  by (induction xs arbitrary: ys) auto

value "trev [1::nat, 2, 3, 4] []"
lemma "trev [1::nat, 2, 3, 4] [] = [4, 3, 2, 1]" by eval

subsection \<open>19.4 代码方程：code 属性\<close>

text \<open>代码生成器的输入不是源定义本身，而是**一组代码方程**。
每个 @{verbatim "fun"} 的递归方程自动进组；@{verbatim "definition"} 则把它的
定义式整条搬进来。所以用 @{verbatim "foldr"} 写的 @{verbatim "my_len"}，
导出后在目标语言里也仍然是"折叠"，不会被自动改写成递归函数。
这条等式同时还是 @{verbatim "simp"} 能用的重写规则。\<close>

definition my_len :: "'a list \<Rightarrow> nat" where
  "my_len xs = foldr (\<lambda>_ n. Suc n) xs 0"

value "my_len [1::nat, 2, 3, 4, 5]"

text \<open>想换掉默认实现，就给一组标了 @{verbatim "[code]"} 的定理。
它们会以较高优先级覆盖原方程——注意顺序：先给出口条件，再给递归步，
代码生成器按声明顺序从上往下匹配。\<close>

lemma [code]: "my_len [] = 0"
  by (simp add: my_len_def)

lemma [code]: "my_len (x # xs) = Suc (my_len xs)"
  by (simp add: my_len_def)

value "my_len [1::nat, 2, 3, 4, 5]"

text \<open>这条定理要为真，代码生成器不管、但它会**要求**你证明——
所以 @{verbatim "[code]"} 本质上是一条带副作用的普通定理：
既是重写规则，也是代码方程。写错方向会导致导出代码与原定义不等价，
而 Isabelle 不会替你检查这一点，因为它是你自己证明的等式。\<close>

subsection \<open>19.5 导出到目标语言\<close>

definition my_max :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "my_max a b = (if a \<le> b then b else a)"

fun ins :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "ins x [] = [x]"
| "ins x (y # ys) = (if x \<le> y then x # y # ys else y # ins x ys)"

fun isort :: "nat list \<Rightarrow> nat list" where
  "isort [] = []"
| "isort (x # xs) = ins x (isort xs)"

value "isort [3::nat, 1, 4, 1, 5]"

text \<open>导出时要列出**全部要导出的常量**，代码生成器会自动带上它们的依赖。
不带 @{verbatim "file"} 参数时，产物进 Isabelle 自己的导出区
（在 jEdit 的 Export 面板里能看到），不会污染源码目录——这是现在推荐的写法。\<close>

export_code my_max in SML module_name T19_Code
export_code my_max ins isort in SML module_name T19_List
export_code my_max ins isort in OCaml module_name T19_List
export_code my_max ins isort in Haskell module_name T19_List
export_code my_max ins isort in Scala module_name T19_List

text \<open>导出不需要本机装对应编译器：写代码是一回事，编译是另一回事。
真要编译验证，是 shell 里 @{verbatim "mlton"} / @{verbatim "ocamlfind"} 的事，
不在证明助手的职责范围内。\<close>

subsection \<open>19.6 什么不能生成代码\<close>

text \<open>以下几类东西没有可执行方程，遇到 @{verbatim "value"} 或
@{verbatim "export_code"} 会报@{verbatim "no code equation"}：

\begin{enumerate}
\item 用了选择算子 @{verbatim "SOME"} / @{verbatim "THE"} 的定义
      （@{verbatim "Hilbert_Choice"} 里的东西基本上都不可执行）；
\item 以集合、关系、谓词形式写出来的"说明式"定义，
      比如用 @{verbatim "Least"} 描述最小值；
\item @{verbatim "inductive"} 定义的谓词（可以额外部署 @{verbatim "code_pred"}，
      让它们变成可枚举的生成器，属于另一套设施）；
\item 类型层面没有对应表示的东西，比如真函数类型。
\end{enumerate}

对应的办法通常是：先用常规手段证明一个**可计算的**实现与说明式定义等价，
再用 @{verbatim "[code]"} 把实现装进去——上一节的 @{verbatim "my_len"}
就是这个套路的最小样本。\<close>

subsection \<open>19.7 用 @{verbatim "code_datatype"} 定制后端表示\<close>

text \<open>逻辑里 @{verbatim "Set"} 是抽象类型，代码生成器把它实现为
@{verbatim "List.coset"}（补集表示，见报错里的 @{verbatim "List.coset"}）。
@{verbatim "code_datatype"} 用于**把某个类型映射到指定的构造器集合**——
最有代表性的场景是自己定义了一个抽象类型，然后用另一份具体的表示来导出代码。
下面造一个小 @{verbatim "wrapper"} 类型演示。\<close>

datatype 'a wrapped = Wrap "'a list"

primrec unwrap :: "'a wrapped \<Rightarrow> 'a list" where
  "unwrap (Wrap xs) = xs"

code_datatype Wrap  \<comment> \<open>把 @{verbatim "Wrap"} 声明为 @{verbatim "wrapped"} 的代码构造器\<close>

value "unwrap (Wrap [1::nat, 2, 3])"

text \<open>这条 @{verbatim "code_datatype Wrap"} 在 @{verbatim "wrapped"} 上把
@{verbatim "Wrap"} 从 @{verbatim "datatype"} 生成的默认表示中"提"出来，
让后端**直接**把它当作构造器；不加这条也能导出，只是加之后端表现更贴近
@{verbatim "list"}。 @{verbatim "Set"} 的类型同理，只是它的构造器叫
@{verbatim "List.coset"} 且**必须**配 @{verbatim "code_datatype"} 才可用。\<close>

subsection \<open>19.8 @{verbatim "code_module"} / 目标限定\<close>

text \<open>导出时可以在常量、类型、构造器后加 @{verbatim "(Haskell)"}
这样的**目标限定**，只影响指定后端。@{verbatim "code_module"} 更进一步，
把一堆常量绑成一个可复用模块；@{verbatim "code_module_attribute"} 给
生成的模块头加一段固定文本。这类"目标限定"的语法与 @{verbatim "export_code"}
同族，具体形式见 @{verbatim "codegen.pdf"} §4；本教程只演示 @{verbatim "export_code ... in Haskell"}
这种**基础形式**（上一节 19.5），高级形式留给读者。\<close>

subsection \<open>19.9 让导出保持稳定的两条纪律\<close>

text \<open>本教程的 @{verbatim "export_code"} 不带 @{verbatim "file"} 参数，产物
进 Isabelle 的 export 区，不进工作树；因此**不会**污染两遍输出比对。
如果加了 @{verbatim "file"} 就必须注意：**导出路径的绝对化**会
让 macOS/Linux 两端的输出不一致，逐字节比对直接崩。\<close>

ML \<open>writeln "==== 19 结束 ===="\<close>

end
