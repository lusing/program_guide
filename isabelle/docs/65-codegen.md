# 65 · 代码生成周边：数值表示、惰性化、测试机、Word 与 IArray

对应示例：`../examples/lib/T65_codegen.thy`（IsaTutLib 会话，依赖
`HOL-Library.Code_Target_Numeral`、`Code_Lazy`、`Code_Test`、
`Word`、`IArray`）

第 19/37 章讲了代码生成的机制（`value` 三引擎、`[code]` 等式、
`export_code`）。本章讲五个「周边」设施：它们不动逻辑层一根
手指，全部作用在**表示与执行**上。

## 65.1 Code_Target_Numeral：目标语言整数

默认情况下，`nat`/`int` 在生成代码里是一元代数结构（0/Suc 风格），
算术是链表级别。`Code_Target_Nat` 与 `Code_Target_Int`（合称
`Code_Target_Numeral`）把代码实现换成目标语言的机器整数
（SML 的 `IntInf`、Haskell 的 `Integer` 等）。逻辑层完全透明——
`value` 输出逐字节不变，变的是导出代码的速度：

```isabelle
value "2 ^ 10 :: nat"              (* 1024，与未导入时相同 *)
value "(21 :: int) * 17 - 400"     (* -43 *)
```

内部机制是 `integer` 抽象类型 + Lifting（`integer_of_nat`/
`nat_of_integer` 往返），证明层不需要知道它存在。一个语义注记：
`nat_of_integer (-1) = 0`——负数进不了 nat，截断是设计不是 bug。

## 65.2 Code_Lazy：把严格语言变成惰性

`Code_Lazy` 解决第 64 章埋下的问题：SML/OCaml 严格求值，共归纳
类型（流）的构造子会无限构造尾部而撑爆栈。`code_lazy_type t`
把代数类型 `t`（datatype 或 codatatype 都行，只要「构造子 + case
可分解」）的生成代码包一层惰性盒子：构造推迟、case 强制。
第 64 章 `code_lazy_type stream` 之后 `stake` 才能安全求值，就是
它的功劳。底层是类型 `'a lazy` 与两个原语：

```isabelle
value "Code_Lazy.force (Code_Lazy.delay (λ_. [1::nat, 2, 3]))"
  (* [1, 2, 3] *)
```

`delay` 把「单位到值的函数」包成惰性值，`force` 取回；目标语言
里的盒子还带「求值一次即缓存」。`print_lazy_types` 查看当前惰性
化的类型清单，`deactivate_lazy_type` 回滚。

## 65.3 Code_Test：拿目标语言当测试机

`Code_Test` 提供 `test_code` 诊断命令：把一个**可执行命题**生成
代码、在真实编译器里跑、断言为真——「证明之外再跑一遍」的烟测
通道：

```isabelle
definition sq_even :: "nat ⇒ bool" where
  "sq_even n = even (n * n)"

test_code "sq_even 4 = True" in PolyML
```

目标 `PolyML` 是 Isabelle 自带的 ML 进程，离线可用；换成
`SML`/`Haskell`/`OCaml`/`Scala` 则调本机编译器（不在则跳过）。
它与 `by eval` 互补：一个验证**实现**（代码等式），一个验证
**定理**。命题必须可执行——常量缺代码等式时得到的是代码生成
错误，而不是「假」。

## 65.4 Word：固定位宽的字

`Word` 定义 `'a word`——`int` 模去「低 `LENGTH('a)` 位相同」
的商类型（第 29 章流水线的又一实例）。位宽写在**类型参数**里：
`8 word` 是字节。算术绕回（环定律照常成立，这正是硬件语义）：

```isabelle
value "(255 :: 8 word) + 1"    (* 0 — 绕回 *)
value "(255 :: 8 word) + 2"    (* 1 *)
value "(7 :: 4 word) * 3"      (* 5 — 21 mod 16 *)
value "unat (255 :: 8 word)"   (* 255 *)

lemma "(255 :: 8 word) + 1 = 0"
  by eval
```

`unat`（即 `unsigned`）取无符号值，`signed` 取补码解释；
判等式走 `take_bit`（`word_of_nat_eq_iff`），环绕总闸是
`2 ^ n = (0 :: 'a word) ⟷ n ≥ LENGTH('a)`。注意 `-1` 是环绕的
最大值（`(-1 :: 8 word) = 255`），别再当数学负数。

## 65.5 IArray：不可变数组

`IArray` 是「逻辑层是列表、实现层是数组」的最小包装：

```isabelle
datatype 'a iarray = IArray "'a list"
```

**没有更新操作**——不可变才能安全映射到目标语言数组（目前只
接了 SML）。操作面：构造 `IArray`/`IArray.of_fun`，读取
`as !! n`（`IArray.sub`），`IArray.length`，量词
`IArray.all`/`IArray.exists`，回转 `IArray.list_of`：

```isabelle
definition arr :: "nat iarray" where
  "arr = IArray [5, 7, 9]"

value "arr !! 1"                                  (* 7 *)
value "IArray.length arr"                         (* 3 *)
value "IArray.list_of (IArray.of_fun (λi. i * i) 4)"  (* [0, 1, 4, 9] *)
value "IArray.exists (λx. x > 8) arr"             (* True *)
```

`value` 走的是通用列表实现（证明层语义）；导出到 SML 后换成真
数组，索引从线性变常数。证明规则全部是「剥壳到列表」，
`IArray.of_fun_nth`（`i < n ⟹ of_fun f n !! i = f i`）是代表。

## 65.6 坑位清单（实测）

1. `Code_Target_Numeral` 是**全局**代码设置：导入即生效，
   `value` 输出不变但导出代码变脸；与手写的 nat/int 自定义
   `code` 规则同堂会撞。
2. `nat_of_integer` 截断负数到 0——设计如此。
3. `code_lazy_type` 只接受**代数类型**（构造子+case 可分解）；
   typedef 不行。
4. 惰性化是全局状态：`print_lazy_types` 可查；同一类型在一个
   理论里只能 `code_lazy_type` 一次。
5. `test_code` 的命题必须可执行（全部常量有代码等式），否则
   报代码生成错误而非「假」。
6. `'a word` 的位宽参数要 `len` 类；数字宽度（`8 word`）来自
   `Numeral_Type` 的类型级数字（bit0/bit1 链）。
7. word 的 `-1` 是环绕最大值，不是数学负数；写负字面值前
   想清楚。
8. IArray 的 `!!`（`IArray.sub`）与列表 `List.nth`、流的
   `snth` 同记号不同常量——看类型分辨。
9. IArray 没有更新操作是**故意的**；要就地更新请用别的结构
   （如第 59 章红黑树）。
10. 本章五件的共性：**逻辑层什么都不变**，变的是表示与性能。
    写证明时当它们不存在，导出代码时它们才露面。

## 65.7 与其他章的接口

- 第 19/37 章代码生成：本章五件全部挂在那一套
  `[code]`/`code_printing`/导出机制上。
- 第 64 章流：`code_lazy_type` 的动机案例。
- 第 28/29 章 typedef 与商类型：`integer`、`'a word`、
  `'a iarray` 三种包装方式的对照样本（typedef / 商 / datatype）。
- 第 46 章分析：Word 的 `len` 类与类型级数字在硬件验证
  库（如 AFP 的 Word_Lib）里是地基。
