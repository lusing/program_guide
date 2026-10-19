theory T65_codegen
  imports "HOL-Library.Code_Target_Numeral" "HOL-Library.Code_Lazy"
    "HOL-Library.Code_Test" "HOL-Library.Word" "HOL-Library.IArray"
begin

section \<open>65.1 Code_Target_Numeral：目标语言整数\<close>

text \<open>默认情况下，@{typ nat}/@{typ int} 在生成代码里是一元结构的
代数类型（0/Suc 风格），算术是链表级别。@{theory "HOL-Library.Code_Target_Nat"}
与 @{theory "HOL-Library.Code_Target_Int"}（合称
@{theory "HOL-Library.Code_Target_Numeral"}）把代码实现换成目标语言的
机器整数（SML 的 @{verbatim IntInf}、Haskell 的 @{verbatim Integer} 等），
逻辑层不变——值的**语义**完全透明，@{verbatim value} 输出不变，
变的是导出代码的速度（线性 → 常数）。\<close>

ML \<open>writeln "==== 65 开始 ===="\<close>

value "2 ^ 10 :: nat"
value "(21 :: int) * 17 - 400"

text \<open>输出与未导入时逐字节相同：这是「表示层优化、逻辑层不变」的
标准范式。内部机制是 @{verbatim "integer"} 抽象类型 + Lifting
（@{verbatim "integer_of_nat"}/@{verbatim "nat_of_integer"} 往返），
证明层不需要知道它存在。注意截断语义：@{term "nat_of_integer (-1) = 0"}，
负数进不了 nat。\<close>

section \<open>65.2 Code_Lazy：把严格语言变成惰性\<close>

text \<open>@{theory "HOL-Library.Code_Lazy"} 解决第 64 章埋下的问题：
SML/OCaml 是严格求值，共归纳类型（流）的构造子会直接撑爆栈。
 @{verbatim "code_lazy_type t"} 把代数类型 @{verbatim t} 的生成代码
包一层「惰性盒子」——构造子推迟求值、case 强制求值，语义不变。
第 64 章 @{verbatim "code_lazy_type stream"} 之后 @{verbatim "stake"}
才能安全求值，就是它的功劳。底层类型 @{typ "'a lazy"} 与两个原语：\<close>

value "Code_Lazy.force (Code_Lazy.delay (%_. [1::nat, 2, 3]))"

text \<open>@{const Code_Lazy.delay} 把「单位到值的函数」包成惰性值，
@{const Code_Lazy.force} 取回；生成的目标语言代码里盒子还自带
「求值一次即缓存」。@{verbatim print_lazy_types} 查看当前惰性化的
类型清单，@{verbatim deactivate_lazy_type} 回滚。\<close>

section \<open>65.3 Code_Test：拿目标语言当测试机\<close>

text \<open>@{theory "HOL-Library.Code_Test"} 提供 @{verbatim test_code}
诊断命令：把一个**可执行的命题**生成代码、在真实编译器里跑、
断言为真——「证明之外再跑一遍」的烟测通道：\<close>

definition sq_even :: "nat \<Rightarrow> bool" where
  "sq_even n = even (n * n)"

test_code "sq_even 4 = True" in PolyML

text \<open>目标是 @{verbatim PolyML}（Isabelle 自带的 ML 进程，离线可用）；
换成 @{verbatim SML}/@{verbatim Haskell}/@{verbatim OCaml}/
@{verbatim Scala} 则调本机对应编译器（不在则无）。它检查的是
「代码等式算出真」，与逻辑层的 @{method eval} 证明互补：
一个验证实现，一个验证定理。\<close>

section \<open>65.4 Word：固定位宽的字\<close>

text \<open>@{theory "HOL-Library.Word"} 定义 @{typ "'a word"}——
@{typ int} 模去「低 @{verbatim "LENGTH('a)"} 位相同」的商类型
（第 29 章流水线的又一实例）。位宽写在**类型参数**里：
@{typ "8 word"} 是字节。算术是绕回的（环定律照常成立，
这正是硬件语义）：\<close>

value "(255 :: 8 word) + 1"
value "(255 :: 8 word) + 2"
value "(7 :: 4 word) * 3"
value "unat (255 :: 8 word)"

lemma "(255 :: 8 word) + 1 = 0"
  by eval

text \<open>第一行 @{verbatim 0}（255+1 绕回），第三行 @{verbatim 5}
（21 mod 16）。@{const unat} 取无符号值（@{const unsigned}），
@{const signed} 取补码解释；判等式有 @{verbatim take_bit} 形态
（@{thm word_of_nat_eq_iff [no_vars]}），「幂等环绕」定理
@{verbatim "2 ^ n = (0 :: 'a word)"} 当且仅当 @{verbatim "n >= LENGTH('a)"} 是绕回
算术的总闸。\<close>

section \<open>65.5 IArray：不可变数组\<close>

text \<open>@{theory "HOL-Library.IArray"} 是「逻辑层是列表、实现层是
数组」的最小包装：@{verbatim "datatype 'a iarray = IArray ('a list)"}，
没有更新操作，所以代码生成可以安全地把 @{typ "'a iarray"} 映射到
目标语言的数组（目前只接了 SML）。操作面：构造 @{const IArray}/
@{const IArray.of_fun}，读取 @{term "as !! n"}（@{const IArray.sub}），
@{const IArray.length}，量词 @{const IArray.all}/@{const IArray.exists}，
回转 @{const IArray.list_of}：\<close>

definition arr :: "nat iarray" where
  "arr = IArray [5, 7, 9]"

value "arr !! 1"
value "IArray.length arr"
value "IArray.list_of (IArray.of_fun (%i. i * i) 4)"
value "IArray.exists (%x. x > 8) arr"

text \<open>@{verbatim value} 走的是通用列表实现（证明层语义）；
导出到 SML 后才换成真数组——索引从线性变常数。证明规则全部
是「剥壳到列表」：@{thm IArray.of_fun_nth [no_vars]} 是代表。\<close>

section \<open>65.6 坑位清单（实测）\<close>

text \<open>
1. Code_Target_Numeral 是**全局**代码设置：导入即生效、
   @{verbatim value} 输出不变但导出代码变脸；与不兼容的
   数字代码规则（自己手写过 nat 的 @{verbatim code}）同堂会撞。
2. @{verbatim nat_of_integer} 截断负数到 0——从 @{verbatim integer}
   回转时这不是错误而是设计。
3. @{verbatim "code_lazy_type"} 只接受**代数类型**（构造子+case
   可分解的类型：datatype/codatatype 都行）；typedef 不行。
4. 惰性化是全局状态：@{verbatim print_lazy_types} 可查，
   同一类型重复 @{verbatim code_lazy_type} 会报错（一个理论
   一次；64 章与 65 章是不同理论所以各写各的）。
5. @{verbatim test_code} 的命题必须**可执行**（全部常量有代码
   等式）；不可执行时给出的是代码生成错误而非「假」。
6. @{typ "'a word"} 的位宽参数要 @{class len} 类；数字宽度
   （@{verbatim "8 word"}）来自 @{verbatim Numeral_Type} 的
   类型级数字——写法是类型位置直接放数字。
7. word 的 0/1 字面量照常；但 @{term "-1"} 是环绕的最大值
   （@{verbatim "(-1 :: 8 word) = 255"}），别再当数学负数。
8. IArray 的 @{verbatim "!!"} 与列表 @{const List.nth} 同记号
   不同常量（@{const IArray.sub}）；与 64 章流的 @{verbatim "!!"}
   又不同——看类型分辨。
9. IArray 没有更新操作是**故意的**（不可变才能安全映射到数组）；
   需要就地更新的场景用别的结构（如第 59 章红黑树）。
10. 本章五件都是「代码生成周边」：逻辑层什么都不变，变的是
    表示与性能。证明里当它们不存在，导出代码时才露面。
\<close>

ML \<open>writeln "==== 65 结束 ===="\<close>

end
