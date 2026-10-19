theory T68_sugar
  imports "HOL-Library.Cancellation" "HOL-Library.Suc_Notation"
    "HOL-Library.Simps_Case_Conv" "HOL-Library.Pattern_Aliases"
    "HOL-Library.Debug" "HOL-Library.OptionalSugar"
begin

section \<open>68.1 Cancellation：加法消去的 simproc\<close>

text \<open>@{theory "HOL-Library.Cancellation"} 给
@{class cancel_comm_monoid_add} 族注册一组 simproc：等式两边
同项相消、@{const iterate_add}（同一个项的 n 次重复加）归并。
导入即生效，无按钮——化简器悄悄变强：\<close>

ML \<open>writeln "==== 68 开始 ===="\<close>

lemma cancel_demo: "(x::nat) + y + x = y + 2 * x"
  by simp

text \<open>没有 Cancellation 时这类目标需要 @{verbatim ac_simps} 加
手工重排；有了它 simproc 直接把两边归一成同一范式再消去。
扩展点是三个 named_theorems：@{verbatim "cancelation_simproc_pre"}
（预处理）、@{verbatim "cancelation_simproc_post"}（消去后回写）、
@{verbatim "cancelation_simproc_eq_elim"}（矛盾导出）。\<close>

section \<open>68.2 Suc_Notation：Suc 塔的紧凑写法\<close>

text \<open>@{theory "HOL-Library.Suc_Notation"} 只做一件事：
@{verbatim "Suc\<^sup>2"} 到 @{verbatim "Suc\<^sup>9"} 是嵌套 Suc 的
缩写（@{verbatim "Suc2 n = Suc (Suc n)"} 等），超过 9 用
@{verbatim "Suc\<^bsup>n\<^esup>"} 语法（ML parse_translation 展开）。
纯记号，无新内容：\<close>

value "Suc2 1"
value "Suc\<^sup>3 (0::nat)"

text \<open>两个输出都是 3（@{const Suc2}/@{verbatim "Suc\<^sup>3"} 立刻展开成嵌套
@{const Suc} 再求值）；记号形态只出现在未求值项的打印里。
适用场景是手工枚举小深度归纳（比如 peek 第 3 层构造子），
大数字请用正常数字字面量。\<close>

section \<open>68.3 Simps_Case_Conv：case 与 simp 规则互转\<close>

text \<open>同一个函数有两种写法：case 表达式（一个方程）与逐构造子
 simp 规则（一组方程）。@{theory "HOL-Library.Simps_Case_Conv"}
的两个命令互转：@{command simps_of_case} 从 case 定义展开出
规则组，@{command case_of_simps} 反向收拢。后者生成的方程
自动带 [@{verbatim simp}] 属性（由你给的属性位控制）：\<close>

definition head2 :: "'a list \<Rightarrow> 'a option" where
  "head2 xs = (case xs of [] \<Rightarrow> None | x # _ \<Rightarrow> Some x)"

simps_of_case head2_simps[simp]: head2_def

text \<open>生成结果（thm 打印可见）：

@{verbatim "head2 [] = None / head2 (x # xs) = Some x"}

——case 定义立刻变成化简器可用的两条规则。逆向
@{command case_of_simps} 在一族 simp 规则太长想压缩定义时有用。\<close>

section \<open>68.4 Pattern_Aliases：Haskell 式 as-模式\<close>

text \<open>@{theory "HOL-Library.Pattern_Aliases"} 的 bundle
@{verbatim pattern_aliases} 启用 @{verbatim "模式 =: 变量"}
语法——解构的同时给整体起别名：\<close>

context includes pattern_aliases begin

fun dup_head :: "nat list \<Rightarrow> nat list" where
  "dup_head [] = []" |
  "dup_head ((x # xs) =: l) = x # l"

end

value "dup_head [1, 2]"

text \<open>@{verbatim "((x # xs) =: l)"} 里 @{verbatim l} 绑定整个
非空列表，@{verbatim "dup_head [1, 2]"} 得 @{verbatim "[1, 1, 2]"}。
纪律（库文档原文）：= : 右侧必须是**自由变量**（别名不是再
解构的位置）；翻译只处理顶层等式；代码生成器**不会**把别名
模式翻译成目标语言的 as-模式——它展开成嵌套 @{const Let}。
bundle 会给 simpset 加 @{thm Let_def} 并换一条 @{const Let} 的
cong 规则（@{verbatim fun} 的终止性归纳需要它），个别
let 解构元组的定义会被这条 cong 卡住——对策是局部
@{verbatim "context includes pattern_aliases"} 或把 let 改 case。\<close>

section \<open>68.5 Debug：生成代码里的探针\<close>

text \<open>@{theory "HOL-Library.Debug"} 提供三个「逻辑上是恒等、
执行时有副作用」的组合子：@{const Debug.tracing}
（打印消息）、@{const Debug.flushing}（打印值）、
@{const Debug.timing}（计时）。逻辑层它们全是恒等
（simp 直接消掉），代码生成到 Eval/PolyML 时才映射成
 @{verbatim Output.tracing} 等：\<close>

value "Debug.tracing (STR ''ping'') (1 + 1 :: nat)"

text \<open>输出是 2，副作用（打印 ping）发生在执行期。用途：
调试导出的程序而不改其逻辑含义——探针在证明里被 simp 消去，
在运行时才说话。\<close>

section \<open>68.6 OptionalSugar 与 LaTeXsugar：打印层的糖\<close>

text \<open>这两个理论不改任何逻辑——它们只改**打印**（面向
文档生成，第 44 章）。@{theory "HOL-Library.OptionalSugar"}
的翻译把 @{const set} 隐藏（@{term "set xs"} 直接打印成
@{verbatim xs}）、把 @{const of_nat} 等嵌入 coercion 隐藏、
把多前提 @{verbatim "P ⟹ Q ⟹ R"} 打印成 @{verbatim "P ∧ Q ⟹ R"}。
实测同一个定理在导入前后打印形态不同：\<close>

lemma set_print_demo: "x \<in> set [1::nat, 2] \<Longrightarrow> x = 1 \<or> x = 2"
  by auto

thm set_print_demo

text \<open>提取的输出里 @{const set} 不见了（@{verbatim "x ∈ [1, 2] ⟹ ..."}）
——这就是糖的威力与危险：文档好看，但读者看不见的地方多了
隐式转换。写正式文本时开它，写教程时关它。
@{theory "HOL-Library.LaTeXsugar"} 则提供 @{verbatim "notation (latex output)"}
一族排版定制（如列表追加的 LaTeX 专用连接符），只在生成
PDF 时露面。\<close>

section \<open>68.7 坑位清单（实测）\<close>

text \<open>
1. Cancellation 是**隐式**增强：导入后 simp 变强，没有提示；
   复现别人的「这步 simp 能过」前先核对 imports。
2. @{verbatim "cancelation_simproc_pre"}/@{verbatim "_post"}/@{verbatim "_eq_elim"} 三个
   named_theorems 是扩展点（注意拼写是 cancelation，美式
   少一个 l）。
3. @{verbatim "Suc\<^sup>n"} 只是输入/输出记号，证明里它们立刻
   展开成嵌套 @{const Suc}；数字大就换字面量。
4. @{command simps_of_case} 生成的规则名要自带
   @{verbatim "[simp]"} 属性位才进化简器；@{command case_of_simps}
   收拢时对规则顺序敏感（先到的先匹配）。
5. 模式别名 @{verbatim "=:"} 的右侧必须是自由变量；别名在
   代码生成里展开成嵌套 @{const Let}（目标语言看不到 as）。
6. pattern_aliases bundle 会换 @{const Let} 的 cong 规则——
   全局 include 可能让别的 fun 定义卡壳，尽量局部
   @{verbatim "context includes pattern_aliases"}。
7. Debug 三件套在逻辑层是恒等（simp 消掉）；别让它们出现在
   定理语句里（会被化简掉），只在定义内部使用。
8. @{verbatim "STR ''...''"} 是 String.literal 的字面量语法
   （两对单引号），不是普通字符串。
9. OptionalSugar 的糖是**单向打印**：隐藏 set/of_nat 的输出
   在读日志时会造成「项里没有 set」的错觉；比对输出或
   写教程时意识到这点（本章 set_print_demo 即实证）。
10. 收官总纲：本章八件全是「不写新数学」的设施——语法糖、
    转换器、调试探针。它们的共同纪律是「逻辑层透明」：
    任何定理的证明都不应依赖糖的存在（除了 Cancellation 的
    simproc 加速，那是化简器内部的合法强化）。
\<close>

ML \<open>writeln "==== 68 结束 ===="\<close>

end
