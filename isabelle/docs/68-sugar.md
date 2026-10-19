# 68 · 语法糖与调试：Cancellation、Suc 记号、case 转换、模式别名、Debug、打印糖

对应示例：`../examples/lib/T68_sugar.thy`（IsaTutLib 会话，依赖
`HOL-Library.Cancellation`、`Suc_Notation`、`Simps_Case_Conv`、
`Pattern_Aliases`、`Debug`、`OptionalSugar`）

收官章是八件「不写新数学」的设施：它们不加定义、不加定理，
只让输入更短、输出更美、调试更方便。共同纪律是**逻辑层透明**——
定理的证明不应依赖糖的存在。

## 68.1 Cancellation：加法消去的 simproc

`Cancellation` 给 `cancel_comm_monoid_add` 族注册一组 simproc：
等式两边同项相消、`iterate_add`（同一项的 n 次重复加）归并。
**导入即生效，没有按钮**——化简器悄悄变强：

```isabelle
lemma cancel_demo: "(x::nat) + y + x = y + 2 * x"
  by simp
```

没有它时这类目标要 `ac_simps` 加手工重排；有了它 simproc 把两边
归一成同一范式再消去。扩展点是三个 named_theorems：
`cancelation_simproc_pre`（预处理）、`cancelation_simproc_post`
（消去后回写）、`cancelation_simproc_eq_elim`（矛盾导出）——
注意拼写是 cancelation（美式少一个 l）。

## 68.2 Suc_Notation：Suc 塔的紧凑写法

只做一件事：`Suc²` 到 `Suc⁹` 是嵌套 `Suc` 的缩写
（`Suc2 n = Suc (Suc n)` 等），超过 9 用 `Suc\<^bsup>n\<^esup>`
语法（ML parse_translation 展开）：

```isabelle
value "Suc2 1"          (* 3 *)
value "Suc\<^sup>3 (0::nat)"  (* 3 — 记号立刻展开再求值 *)
```

两个输出都是 3；记号的打印形态只出现在未求值的项里。适用场景是
手工枚举小深度构造子层数；大数字请用正常数字字面量。

## 68.3 Simps_Case_Conv：case 与 simp 规则互转

同一个函数有两种写法：case 表达式（一个方程）与逐构造子 simp
规则（一组方程）。两个命令互转：`simps_of_case` 从 case 定义
展开出规则组，`case_of_simps` 反向收拢：

```isabelle
definition head2 :: "'a list ⇒ 'a option" where
  "head2 xs = (case xs of [] ⇒ None | x # _ ⇒ Some x)"

simps_of_case head2_simps[simp]: head2_def
```

`thm head2_simps` 打印：

```text
head2 [] = None
head2 (?xa # ?x) = Some ?xa
```

case 定义立刻变成化简器可用的两条规则（`[simp]` 属性位由你给的
标注控制）。逆向 `case_of_simps` 在一族 simp 规则太长、想压缩
定义体积时有用。

## 68.4 Pattern_Aliases：Haskell 式 as-模式

bundle `pattern_aliases` 启用 `模式 =: 变量` 语法——解构的同时
给整体起别名：

```isabelle
context includes pattern_aliases begin

fun dup_head :: "nat list ⇒ nat list" where
  "dup_head [] = []" |
  "dup_head ((x # xs) =: l) = x # l"

end

value "dup_head [1, 2]"   (* [1, 1, 2] — l 绑定整个非空列表 *)
```

纪律（库文档原文）：`=` 右侧必须是**自由变量**（别名位不是再
解构的位置）；翻译只处理顶层等式；代码生成器**不会**把别名
翻译成目标语言的 as-模式——它展开成嵌套 `Let`。bundle 会给
simpset 加 `Let_def` 并换一条 `Let` 的 cong 规则（`fun` 的归纳
原则生成需要它）；个别用 let 解构元组的定义会被这条 cong 卡住，
对策是局部 `context includes pattern_aliases`（如上）或把 let
改 case。

## 68.5 Debug：生成代码里的探针

`Debug` 提供三个「逻辑上是恒等、执行时有副作用」的组合子：
`Debug.tracing`（打印消息）、`Debug.flushing`（打印值）、
`Debug.timing`（计时）。逻辑层它们全是恒等（simp 直接消掉），
代码生成到 Eval/PolyML 时才映射成 `Output.tracing` 等：

```isabelle
value "Debug.tracing (STR ''ping'') (1 + 1 :: nat)"   (* 2，执行期打印 ping *)
```

用途：调试导出的程序而不改其逻辑含义——探针在证明里被 simp
消去，在运行时才说话。`STR ''...''` 是 String.literal 的字面量
语法（两对单引号）。

## 68.6 OptionalSugar 与 LaTeXsugar：打印层的糖

这两个理论不改任何逻辑——只改**打印**（面向文档生成，第 44 章）。
`OptionalSugar` 的翻译把 `set` 隐藏（`set xs` 直接打印成 `xs`）、
把 `of_nat` 等嵌入 coercion 隐藏、把多前提 `P ⟹ Q ⟹ R` 打印成
`P ∧ Q ⟹ R`。同一个定理，导入前后打印形态不同——本章实测：

```isabelle
lemma set_print_demo: "x ∈ set [1::nat, 2] ⟹ x = 1 ∨ x = 2"
  by auto

thm set_print_demo   (* 打印为：?x ∈ [1, 2] ⟹ ?x = 1 ∨ ?x = 2 — set 不见了 *)
```

这就是糖的威力与危险：文档好看，但读者看不见的地方多了隐式
转换——写正式文本开它，写教程关它。`LaTeXsugar` 提供
`notation (latex output)` 一族排版定制（如列表追加的 LaTeX 专用
连接符），只在生成 PDF 时露面。

## 68.7 坑位清单（实测）

1. Cancellation 是**隐式**增强：导入后 simp 变强，没有提示；
   复现别人的「这步 simp 能过」前先核对 imports。
2. 三个扩展点 named_theorems 拼写是 cancelation（美式少一个 l）。
3. `Sucⁿ` 只是记号：证明里立刻展开成嵌套 `Suc`；大数字换字面量。
4. `simps_of_case` 生成的规则要自带 `[simp]` 属性位才进化简器；
   `case_of_simps` 收拢时对规则顺序敏感（先到的先匹配）。
5. 模式别名 `=:` 的右侧必须是自由变量；别名在代码生成里展开
   成嵌套 `Let`（目标语言看不到 as）。
6. pattern_aliases bundle 会换 `Let` 的 cong 规则——全局 include
   可能让别的 fun 定义卡壳，尽量局部 include。
7. Debug 三件套在逻辑层是恒等，别让它们出现在定理语句里
   （会被 simp 化掉），只在定义内部使用。
8. `STR ''...''` 是 String.literal 字面量语法（两对单引号）。
9. OptionalSugar 是**单向打印糖**：日志里「项中没有 set」是
   错觉；比对输出或写教程时要意识到（set_print_demo 实证）。
10. 总纲：糖的纪律是逻辑层透明。唯一例外是 Cancellation 的
    simproc 加速——那是化简器内部的合法强化，定理层面无迹。

## 68.8 与其他章的接口

- 第 7 章化简器：Cancellation 是 simproc 机制的库存样本；
  `named_theorems` 扩展点是第 21 章属性管理的应用。
- 第 44 章文档生成：OptionalSugar/LaTeXsugar 是它的印刷车间。
- 第 65 章代码生成：Debug 的 code_printing 目标（Eval/PolyML）
  与 `missing_pattern_match`（Case_Converter，由 Code_Lazy 使用）
  都属于「代码生成周边」。
- 第 5 章递归与终止性：Pattern_Aliases 的 Let-cong 就是给
  `fun` 的归纳原则生成铺路的。

至此第四轮扩充（57–68 章）收官：容器族（57–60）、数学与编程
设施（61–64）、代码生成与糖（65–68）三个批次覆盖了 HOL-Library
的核心货架。后续批次的方向（HOL-Data_Structures、Ramsey、
Landau_Symbols、Reflection 等）见 README 与 PLAN。
