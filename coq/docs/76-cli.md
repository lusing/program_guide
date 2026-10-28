# 76 · quickchick 命令行与变异测试

对应示例：`../examples/76_cli.v`（`Module Ex76Cli`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

属性测试篇的收官章。69 章入门、70 章类型类、71 章生成器、72 章可检查性质、
73 章条件性质、74 章 `QCDerive`、75 章综合案例，一路的工作方式都是：把
`QuickChick` 命令**内嵌**在 .v 文件里，`rocq compile` 编到哪测到哪。这对「边写
边测」是最顺手的姿态，但有两个问题它回答不了：一是**规模**——大文件、多文件、
大量性质时，内嵌执行的代价会失控；二是**反向考核**——`+++ Passed 10000 tests`
究竟是「代码对」还是「没测到」？性质套件本身也是软件，它也需要被测试。

本章把这两件事一次讲完，主角是 QuickChick 自带的命令行工具 `quickChick`：
它扫描 .v 文件里以感叹号开头的特殊注释注解，把散落各处的测试组织成一次批量
执行，并原生支持**变异测试**（mutation testing）——对实现故意种 bug（mutant），
考核性质套件能否把它**杀死**（kill）。案例沿用官方的 stack-compiler：一个高层
表达式语言编译到低层栈机，正确性性质（编译保持语义）配上三个 mutant，逐个
看它们的生死。

### 76.0 为什么需要独立的 runner

先算内嵌执行的成本账。每条 `QuickChick` 命令都会把**到该命令为止的全部内容**
抽取成 OCaml、编译、运行——69 章单文件里几条命令无感，但这个过程
「quickly becomes intractable」：大 Rocq 文件、多文件开发、大量性质都扛不住。
命令行工具的核心卖点正是把所有 `QuickChick` 命令**收集起来，做一次抽取与编
译，汇总报告全部结果**。

对 CI 还有一层意义：69 章强调过，内嵌执行时性质被证伪**不影响退出码**（仍为
0），全绿必须靠人眼盯输出。`quickChick` 补上了这块——任何「意外结果」（base
里有测试失败、mutant 全绿、结果不可判定）都让进程以非零退出码收场，只有全部
符合预期才打印 `All tests produced the expected results` 并以 0 退出，天然可当
CI 门禁。

工作机制四步（据官方文档与工具源码 `quickChickTool.ml`）：

1. 扫描当前目录（含子目录）的全部 .v 文件，解析感叹号注解；把文件复制到一个
   **兄弟目录** `../_qc_<目录名>.tmp`（注意：在父目录下、与当前目录平级）；
2. 生成 `QuickChickTop.v`：把所有被注解登记的测试集中进去，附上抽取指令；
   `_CoqProject` 的副本会追加这个新文件；
3. 用原目录的构建命令（默认 `make`，可用 `-cmd` 换）编译整个临时目录——各 .v
   抽取成**彼此独立的 OCaml 模块**，再由 ocamlbuild 编译；
4. 运行产出的可执行文件，逐段打印结果。

独立的 OCaml 模块是效率关键：工具只重写**内容确实变化**的文件，所以跨 mutant、
跨多次调用可以复用编译产物——三个 mutant 各改一处，其余模块的编译成果全部
复用。

输出按段组织，段头部形如 `Testing base...` 或
`Testing mutant 2 (./Exp.v: line 20): Plus-copy-paste-error`。在 stack-compiler
目录里第一次运行（输出实录，路径与行号对应原项目环境）：

```bash
$ quickChick -color -top Stack
Testing base...
make -f Makefile.coq
make[1]: Entering directory '/home/lemonidas/sfdev/qc/_qc_stack-compiler.tmp'
COQDEP VFILES
COQC Exp.v
COQC Stack.v
COQC QuickChickTop.v
make[1]: Leaving directory '/home/lemonidas/sfdev/qc/_qc_stack-compiler.tmp'
Checking Exp.optimize_correct_prop...
+++ Passed 10000 tests (0 discards)
Checking Stack.compiles_correctly...
+++ Passed 10000 tests (0 discards)
...（随后各段是 mutant 的同构输出，见 76.4）...
All tests produced the expected results
```

`-color` 给段头、失败、成功三类文字分别着色；`-top Stack` 指定顶层逻辑模块名，
**必须与 `_CoqProject` 里 `-Q`/`-R` 的绑定一致**。测试名带文件前缀
（`Exp.optimize_correct_prop`）——工具按「文件名.性质名」汇总。

本章示例文件的头几行（与 69–75 章同一套告警屏蔽；导入比 69 章多了 `Tactics`、
`QcDefaultNotation` 与 `qc_scope`）：

```coq
(* 76 quickchick 命令行与变异测试 —— 从编译期内嵌执行到独立 runner：
   感叹号注解三分法（分节 Section、测试 QuickChick、变异 Mutant）、quickChick
   命令行十二选项、变异测试方法论（种 mutant、杀 mutant、幸存者即盲区），
   案例为 QuickChick 官方 stack-compiler（Exp 表达式语言 + Stack 栈机编译器）的内联精简版 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick Tactics.
Import QcDefaultNotation. Open Scope qc_scope.

From Stdlib Require Import Arith List. Import ListNotations.

Module Ex76Cli.
```

### 76.1 Exp：表达式语言与第一份变异注解

官方案例本是 `stack-compiler/` 目录下的两个文件（`Exp.v` 与 `Stack.v`）；本章
把它们内联进同一个 Module，注解写法与真实项目逐字相同：

```coq
(* ---------- 76.1 Exp：表达式语言、eval 与第一个变异注解 ---------- *)

(* 官方案例本是 stack-compiler/ 目录下的 Exp.v 与 Stack.v 两个文件（配 _CoqProject
   与 Makefile）；这里内联进同一 Module 便于单文件编译。以感叹号开头的注释是
   quickChick 命令行工具的注解，对 rocq compile 只是普通注释，编译无碍。 *)

(*! Section arithmetic_expressions *)

Inductive exp : Type :=
| ANum : nat -> exp
| APlus : exp -> exp -> exp
| AMinus : exp -> exp -> exp
| AMult : exp -> exp -> exp.

QCDerive (Arbitrary, Show) for exp.
```

`exp` 是四个构造子的算术表达式语言：字面量、加、减、乘。`QCDerive` 用的是
74 章收尾提过的**组合形式**——一条命令同时派生 `Arbitrary`（生成 + 收缩）与
`Show`（打印），测试四要素就齐了。

分节注解 `(*! Section arithmetic_expressions *)` 宣告从这里开始（直到下一个
分节注解或文件末尾）的测试与 mutant 都归属 `arithmetic_expressions` 节，
真实项目里它位于 `Exp.v` 开头。接着是求值函数——以及本章第一份变异注解：

```coq
Fixpoint eval (e : exp) : nat :=
  match e with
  | ANum n => n
(*! *)
  | APlus e1 e2 => (eval e1) + (eval e2)
(*!! Plus-copy-paste-error *)
(*! | APlus e1 e2 => (eval e1) + (eval e1) *)
  | AMinus e1 e2 => (eval e1) - (eval e2)
  | AMult e1 e2 => (eval e1) * (eval e2)
  end.
```

变异注解由四部分组成（与 QuickChick 参考手册 `QuickChickInterface` 的说法一
致；双感叹号是为了帮解析器把名字与变体区分开）：

1. `(*! *)` —— mutant 块的**开始标记**，永远长这样；
2. 中间是**正确代码**（base），这里是 `APlus` 分支的正常求值；
3. `(*!! Plus-copy-paste-error *)` —— 可选（但推荐）的**mutant 名字**，双感叹
   号帮解析器把它与变体区分开；
4. `(*! | APlus e1 e2 => (eval e1) + (eval e1) *)` —— **变体**：一个复制粘贴
   错误，把加法两个操作数都算成了 `e1`。变体的要求是能**逐字替换** base 代码
   后仍是合法代码。

工具为每个 mutant 生成一份「base 中该处被替换、其余原样」的完整项目副本，跑
同一套测试。注意这些注解行在 .v 里就是普通注释——本章示例文件带着它们照常
`rocq compile`，还保留了激活的内嵌命令，两条通道互不干扰。

### 76.2 optimize：官方教程的填空作业、测试注解与分节

官方 `Exp.v` 在 `optimize` 处留了一道填空作业，只给了一个分支和兜底：

```coq
(* ---------- 76.2 optimize：官方教程的填空作业、测试注解与分节 ---------- *)

(* 官方 Exp.v 在 optimize 处留了填空作业（TODO: FILL ME DURING TUTORIAL!）：
   只给出「APlus e (ANum 0) => optimize e」一个分支和兜底「| _ => ANum 0」。
   完整解答：加 0、减 0 两侧都消去，其余情形对子表达式递归优化。 *)

(*! Section optimizations *)(*! extends arithmetic_expressions *)
```

**作业解答**就是下面这个完整的 `optimize`：`e + 0` 与 `0 + e` 都消去（加法可
交换，两侧等价）；`e - 0` 消去（`nat` 减法下 `e - 0 = e`）；其余情形对子表达式
递归。注意 `0 - e` **不能**消——`0 - e` 一般不等于 `e`，这一处正是下面 mutant
的攻击点：

```coq
Fixpoint optimize (e : exp) : exp :=
  match e with
  | ANum n => ANum n
  | APlus e (ANum 0)  => optimize e
  | APlus (ANum 0) e  => optimize e
  | APlus e1 e2 => APlus (optimize e1) (optimize e2)
(*! *)
  | AMinus e (ANum 0) => optimize e
(*!! Minus-Reverse *)
(*!
  | AMinus (ANum 0) e => optimize e
*)
  | AMinus e1 e2 => AMinus (optimize e1) (optimize e2)
  | AMult e1 e2 => AMult (optimize e1) (optimize e2)
  end.
```

`Minus-Reverse` 是多行变体：把消去条件从 `e - 0` 反转成 `0 - e`——于是
`0 - 1` 被错误地优化成 `1`。多行写法与 76.1 的单行写法完全等价，`(*!` 与
`*)` 可以夹住多行代码。

正确性性质：**优化保持语义**——优化前后求值结果相同。`?` 是把可判定 Prop 压
成 `bool` 的记号（72 章），性质因此可执行：

```coq
Definition optimize_correct_prop (e : exp) := eval (optimize e) = eval e?.

(*! QuickChick optimize_correct_prop. *)
(* 注解把同名性质登记给 quickChick CLI；内嵌的执行版命令统一放在文件
   末尾的执行区（模块外）——每条 QuickChick 命令各自触发一次抽取并
   当场编译运行。内嵌命令允许匿名性质，注解必须具名——执行区最后
   一条内嵌命令合法，却写不成注解。 *)
```

测试注解 `(*! QuickChick optimize_correct_prop. *)` 把这条性质登记给命令行工
具——**只有被注解的性质才会被 CLI 收集**。它与普通 `QuickChick` 命令的关系
是双轨：命令当场执行（每条一次抽取），注解汇总执行（全部测试一次抽取）；两
者可以像上面这样共存。一个硬限制：**注解里必须是具名性质**。内嵌命令可以写
匿名函数（上面第二行命令合法），注解没有对应写法——CLI 按名字收集与汇总，
匿名项无处登记。

分节注解的第二种形态出现在 `optimize` 之前：
`(*! Section optimizations *)(*! extends arithmetic_expressions *)`——
`optimizations` 节**继承** `arithmetic_expressions` 节：跑它时，祖先节里的测试
与 mutant 一并纳入。节的语义（据参考手册与源码）：节是模块内**连续的代码块**，从
分节注解起、到下一个分节注解或文件尾止；`extends` 取传递闭包；没有分节注解
的文件内容属于一个隐式默认节。用 `-s` 指定只跑某个节（一次实测记录）：

```bash
$ quickChick -color -top Stack -s optimizations
Testing base...
make -f Makefile.coq
...
Checking Exp.optimize_correct_prop...
+++ Passed 10000 tests (0 discards)
... etc ...

Testing mutant 0 (./Exp.v: line 35): Minus-Reverse
make -f Makefile.coq
...
AMinus (ANum 0) (ANum 1)
Checking Exp.optimize_correct_prop...
*** Failed after 13 tests and 4 shrinks. (0 discards)

Testing mutant 1 (./Exp.v: line 20): Plus-copy-paste-error
make -f Makefile.coq
...
APlus (ANum 1) (ANum 0)
Checking Exp.optimize_correct_prop...
*** Failed after 5 tests and 3 shrinks. (0 discards)
All tests produced the expected results
```

三个要点：base 段这次**只跑了** `optimizations` 节里的那一条测试（改优化器时
不必重跑代码生成器的旧测试——这就是分节的动机）；因为 `optimizations`
extends 了 `arithmetic_expressions`，两个节的 mutant（`Minus-Reverse` 与
`Plus-copy-paste-error`）都被纳入；两个 mutant 各自被 `optimize_correct_prop`
用极小反例杀死——`AMinus (ANum 0) (ANum 1)`（优化后得 1，原值 0-1=0）与
`APlus (ANum 1) (ANum 0)`（e1+e1=2，原值 1+0=1）。另注意 mutant 编号**从 0
重新排**，且随 `-s` 的选择而变——后面 `-m`/`-tag` 要按本次输出的编号用。

### 76.3 Stack：栈机、编译器填空作业与新手错误

第二个文件 `Stack.v` 描述低层栈机。它有自己的一节 `stack_instructions`，同样
extends `arithmetic_expressions` 但**不** extends `optimizations`——编译器与优
化器的测试由此可以互不牵连地独立运行（官方案例的设计意图）：

```coq
(* ---------- 76.3 Stack：栈机、编译器填空作业与被抓个正着的新手错误 ---------- *)

(*! Section stack_instructions *)(*! extends arithmetic_expressions *)

Inductive sinstr : Type :=
| SPush : nat -> sinstr
| SPlus : sinstr
| SMinus : sinstr
| SMult : sinstr.

Fixpoint execute (stack : list nat) (prog : list sinstr) : list nat :=
  match (prog, stack) with
  | (nil,             _           ) => stack
  | (SPush n::prog',  _           ) => execute (n::stack) prog'
  | (SPlus::prog',    m::n::stack') => execute ((m+n)::stack') prog'
  | (SMinus::prog',   m::n::stack') => execute ((m-n)::stack') prog'
  | (SMult::prog',    m::n::stack') => execute ((m*n)::stack') prog'
  | (_::prog',        _           ) => execute stack prog'
  end.
```

`execute` 的语义逐条说：程序为空返回当前栈；`SPush n` 把 `n` 压到栈顶继续；
二目指令要求栈顶有两个数 `m`（顶）、`n`（次顶），弹出后压回 `m+n` / `m-n` /
`m*n`；栈不够深时**忽略该指令**继续执行剩下的程序。

第二道填空作业：把表达式编译成指令序列。官方 `Stack.v` 只留了一句
`TODO: WRITE DURING TUTORIAL!`。按直觉写出来的第一版多半是这样——左操作数先
压栈：

```coq
Module StackRookie.

(* 官方 Stack.v 的另一道填空（TODO: WRITE DURING TUTORIAL!）：按直觉
   「左操作数先压栈」写编译器——里面埋着一个新手错误，先让性质说话。 *)

Fixpoint compile (e : exp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
  | APlus  e1 e2 => compile e1 ++ compile e2 ++ [SPlus]
  | AMinus e1 e2 => compile e1 ++ compile e2 ++ [SMinus]
  | AMult  e1 e2 => compile e1 ++ compile e2 ++ [SMult]
  end.

Definition compiles_correctly (e : exp) := (execute [] (compile e)) = [eval e]?.
```

正确性性质是「编译保持语义」：从空栈执行编译结果，应得到恰一个元素的栈，且
该元素就是 `eval e`。执行区的 `QuickChick StackRookie.compiles_correctly`
当场证伪，3 次测试、2 次收缩就拿到最小反例
`AMinus (ANum 0) (ANum 1)`。顺手留一道口头练习：不跑 QuickChick，能看出 bug
吗？答案藏在**减法不交换**里：`APlus`/`AMult` 是可交换的，两个分支怎么压栈
都对；唯独 `AMinus` 会让左右操作数颠倒——所以失败的恰好是减法。

### 76.4 修复并记档：mutant 的生死与变异测试方法论

修复的方向由 `execute` 的弹栈约定倒推：二目指令弹出 `m`（栈顶）、`n` 后算
`m-n`，想让栈顶恰是左操作数，就得**右操作数先压栈**。修好之后，按变异测试的
工程习惯把刚踩过的坑「记档」为 mutant——base 是正确代码，被杀的变体收进注
解，从此每次跑 `quickChick` 都在考核性质套件能不能再次抓住这个错误：

```coq
End StackRookie.

(* ---------- 76.4 修复并记档：正确代码做 base，踩过的坑做成 mutant ---------- *)

Module StackFixed.

(* 修复：右操作数先压栈。二目指令弹出 m（栈顶）、n 后计算 m+n / m-n / m*n，
   右者先压则栈顶 m 恰为左操作数。修好后再把刚踩过的坑「记档」为 mutant：
   base 是正确代码，被杀的变体收进单感叹号注解，随时接受套件的考核。 *)

Fixpoint compile (e : exp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
(*! *)
  | APlus  e1 e2 => compile e2 ++ compile e1 ++ [SPlus]
  | AMinus e1 e2 => compile e2 ++ compile e1 ++ [SMinus]
  | AMult  e1 e2 => compile e2 ++ compile e1 ++ [SMult]
(*!! Wrong associativity *)
(*!
  | APlus  e1 e2 => compile e1 ++ compile e2 ++ [SPlus]
  | AMinus e1 e2 => compile e1 ++ compile e2 ++ [SMinus]
  | AMult  e1 e2 => compile e1 ++ compile e2 ++ [SMult]
*)
  end.

Definition compiles_correctly (e : exp) := (execute [] (compile e)) = [eval e]?.

(*! QuickChick compiles_correctly. *)
(* 修复后回归通过（执行区验证）；变异测试的验收标准随之反转——mutant
   「Wrong associativity」在这条性质下必须失败：被杀死才说明性质灵敏；
   quickChick 的 -m 与 -tag 就是逐个验收 mutant 的开关。 *)

End StackFixed.

End Ex76Cli.
```

注意验收标准的**反转**：base 段期望全部 `Passed`；mutant 段期望**至少一条测试
失败**。工具的判定（源码 `confirm_results`）：base 有失败报 `Test failed in
base`；mutant 全绿报 `No tests failed for this mutant`；两者都算「意外结果」，
最终以非零退出码收场。只跑栈机这一节（一次实测记录；其命令写作 `-s stack`，
节名以注解为准）：

```bash
$ quickChick -color -top Stack -s stack
Testing base...
make -f Makefile.coq
...
Checking Stack.compiles_correctly...
+++ Passed 10000 tests (0 discards)

Testing mutant 0 (./Stack.v: line 33): Wrong associativity
make -f Makefile.coq
...
AMinus (ANum 0) (ANum 1)
Checking Stack.compiles_correctly...
*** Failed after 5 tests and 6 shrinks. (0 discards)

Testing mutant 1 (./Exp.v: line 20): Plus-copy-paste-error
make -f Makefile.coq
...
APlus (ANum 0) (ANum 1)
Checking Stack.compiles_correctly...
*** Failed after 5 tests and 2 shrinks. (0 discards)
All tests produced the expected results
```

`stack_instructions` extends `arithmetic_expressions` 而不含 `optimizations`，
所以这次纳入的是 `Wrong associativity`（本节）与 `Plus-copy-paste-error`
（祖先节），`Minus-Reverse` 不参与。三个 mutant 的生死总账：

| mutant（种的 bug） | 所在节 | 被谁杀死 | 最小反例 | 死因 |
|---|---|---|---|---|
| Plus-copy-paste-error（加法算两次 e1） | arithmetic_expressions | optimize_correct_prop、compiles_correctly 都能杀 | `APlus (ANum 1) (ANum 0)` | e1+e1=2 ≠ 1+0=1 |
| Minus-Reverse（0-e 也消成 e） | optimizations | optimize_correct_prop | `AMinus (ANum 0) (ANum 1)` | 优化后 eval=1，原值 0-1=0 |
| Wrong associativity（左操作数先压栈） | stack_instructions | compiles_correctly | `AMinus (ANum 0) (ANum 1)` | 栈机算 1-0=1 ≠ 0-1=0 |

方法论收束成一个根本问题：性质连过 10000 次随机测试，是因为**实现正确**，还
是因为**输入空间没覆盖到**？变异测试给出的考核办法是：对实现（或性质）故意
种 bug，看套件能否检测出来——

- **mutant 被杀死**：套件对这个错误方向灵敏，好信号；
- **mutant 幸存**（工具报 `No tests failed for this mutant`）：套件有盲区。出路
  是补性质、或修生成器分布（73 章的 `collect` 诊断与按规格生成正是排查工具）；
- **等价 mutant 例外**：与 base 语义完全相同的变体（例如给 nat 加法种一个
  「多加一个 0」的变体）永远杀不死——这不是套件的错，需要人工甄别后剔除。

对 75 章那样带类型语言的生成与性质套件，这套反向考核同样适用：生成器与性质
写得越精心，越值得用 mutant 验一验成色。


## 76.5 测试执行区：命令为何在模块外

```coq
(* 内嵌执行命令统一放在模块外：QuickChick 2.2 的抽取管线对模块内
   上下文生成的 OCaml 引用缺少模块限定，会报 Unbound value
   quickchick；命令放到模块外、引用模块内容则一切正常。
   StackRookie 与 StackFixed 里的 compiles_correctly 重名，
   用全限定名区分。 *)

Import Ex76Cli.

QuickChick optimize_correct_prop.
(* +++ Passed 10000 tests (0 discards)。 *)

QuickChick (fun e => eval (optimize e) = eval e?).
(* 同样 +++ Passed 10000 tests (0 discards)。 *)

QuickChick StackRookie.compiles_correctly.
(* 一次实测（随机测试，数字每次会变）：
     AMinus (ANum 0) (ANum 1)
     *** Failed after 3 tests and 2 shrinks. (0 discards)
   反例 e = 0 - 1：Rookie 版编译出 [SPush 0; SPush 1; SMinus]，SMinus 从栈顶
   依次弹出 m=1、n=0，算得 1-0=1；而 eval (0-1) = 0。减法不交换——「左操作数
   先压栈」让它沉入栈底，弹出时左右颠倒。 *)

QuickChick StackFixed.compiles_correctly.
(* +++ Passed 10000 tests (0 discards)：修复后回归通过。 *)
```

与前几章相同的结构约定（69 章 69.5 节详述）：定义住在模块里，内嵌执行命令
统一放模块外。执行区四条命令对应本章三个教学时刻：`optimize_correct_prop`
与它的匿名孪生（说明注解必须具名）、`StackRookie.compiles_correctly`
（新手错误被 3 次测试 2 步收缩揭穿）、`StackFixed.compiles_correctly`
（修复后 10000 次全过）。两个 `compiles_correctly` 重名，用子模块全限定名
区分。注意这四条**只是编译期自检**；真正把注解组织起来批量执行、逐个考核
mutant 的是 `quickChick` 命令行（76.0 与 76.6 节的 shell 演示）。

### 76.5 注解语法速查

QuickChick 参考手册（`QuickChickInterface`）给出的三种注解模板（**以感叹号开头
的注释**才被工具的解析器另眼相看，其余注释一概是普通文本）：

```text
(*! QuickChick prop. *)                          测试注解：登记一条具名性质

(*! *)                                           变异注解开始标记
Normal code                                      正确代码（base）
(*!! mutant-name *)                              可选的 mutant 名字
(*! mutant 1 *)                                  变体 1
(*! mutant 2 *)                                  变体 2
... etc ...                                      （每个变体都是一个独立 mutant）

(*! Section section-name *)                      分节注解
(*! Section section-name *)(*! extends other *)  带继承的分节注解
```

规则清单（据参考手册与工具源码）：

- **测试注解只认具名性质**；匿名 `fun` 写法只在普通命令里合法（76.2 已演示）。
- 变体必须能**逐字替换** base：替换后仍是合法代码。一个块里的多个变体是**多个
  备选 mutant**，每次只启用一个、从不叠加（源码逐个生成副本）；多行变体用
  `(*!` 换行 … `*)` 夹住即可。
- mutant 名字供 `-tag` 选择用，匹配是**前缀匹配**（源码行为）。
- 注解可以压缩成单行内联。官方 mutation-tutorial 里的写法：
  `Definition plus1 (x : nat) := (*!*) x + 1 (*! x *) (*! x + x *) .`
  ——`(*!*)` 是开始标记，`x + 1` 是 base，后面两个注解各是一个变体。
- 节从分节注解起到下一个分节注解或文件尾止；`extends` 取传递闭包；无分节注解
  的文件内容属于隐式默认节。节名打错时工具直接报
  `Didn't find section called ... (available sections: ...)` 并列出全部可用名。
- 工具的扫描器**不懂 Coq 注释嵌套**：不要把感叹号注解样例抄进普通注释里（对
  rocq compile 而言嵌套注释合法，但工具会误读）。C 风格 `/*! ... */` 注解也
  被支持（可用于 .c/.h 文件的变异测试）。
- 普通命令与注解的关系：命令**当场**执行、各自触发一次抽取；注解**汇总**执行、
  全部测试共享一次抽取。两者可在同一文件共存——本章示例即如此。

### 76.6 命令行选项表

以下语义以 QuickChick 参考手册（`QuickChickInterface`）为准、并经 2.2 源码
（`quickChickTool.ml` 的选项表）逐项核对：

| 选项 | 语义 |
|---|---|
| `-s <节名>` | 只测指定节（含其 `extends` 的传递闭包）里的性质与 mutant |
| `-v` | 冗余模式，用于调试工具自身的行为 |
| `-failfast` | 一发现意外结果立即以非零退出码终止 |
| `-color` | 在 ANSI 终端上给输出着色（段头 / 失败 / 成功三类） |
| `-cmd <命令>` | 整个目录的编译命令，默认 `make`（用其他构建系统时换） |
| `-top <名字>` | 顶层逻辑模块名，须与 `_CoqProject` 的 `-Q`/`-R` 绑定一致 |
| `-ocamlbuild <参数>` | 传给 ocamlbuild 的附加参数（例如要链接的库） |
| `-nobase` | 跳过对 base（未变异代码）的测试 |
| `-m <编号>` | 只测编号为 N 的那一个 mutant |
| `-tag <名字>` | 只测名字（前缀）匹配的 mutant |
| `-include <文件>` | 指定一个清单文件，列出参与编译的 .v（`#` 起行注释） |
| `-exclude <名字...>` | （已弃用）排除若干文件；必须作为最后一个参数 |

逐个补充说明：

- **`-s`**：选择性测试的主力。改优化器时 `-s optimizations`，改编译器时
  `-s stack_instructions`，把无关的成功测试挡在门外，省时也省读输出的注意力。
- **`-v`**：打印工具内部的解析与决策过程（处理了哪些节、写了哪些文件），排查
  「为什么我的测试没被收集到」时打开。
- **`-failfast`**：默认行为是跑完所有段再汇总退出码；加它则第一个意外结果就让
  整个运行立即失败——CI 里想要「快速红」时用。
- **`-color`**：纯输出美化，不影响判定。
- **`-cmd`**：工具靠「编译整个目录」来产出 `.vo` 与抽取物，默认调 `make`；目录
  用 dune 等其他构建时用它替换。
- **`-top`**：生成的 `QuickChickTop.v` 以 `Require <top>.<文件>` 引入各模块，
  前缀对不上就直接 Require 失败。stack-compiler 的 `_CoqProject` 是
  `-Q . Stack`，所以命令里必须 `-top Stack`。（源码默认空串、手册称默认
  `Top`——实践中以显式传对为准。）
- **`-ocamlbuild`**：抽取产物由 ocamlbuild 编译（工具自动带 `-use-ocamlfind
  -pkg zarith`），有额外链接需求时从这里传。
- **`-nobase`** / **`-m`** / **`-tag`**：三个「缩小范围」开关。注意细节：一旦
  用了 `-m` 或 `-tag`，base 段自动跳过（源码行为）；编号以**本次运行**输出头
  部的 `Testing mutant N` 为准——它随 `-s` 的选择重排：对比 76.0 首跑实录里
  的 `mutant 2` 与 76.2 运行里的 `mutant 1`，同一个 `Plus-copy-paste-error`
  编号变了。
- **`-include`**：默认收集目录下全部 .v；项目里有不想参与测试的文件时，用清
  单圈定范围（清单里 `#` 之后是注释）。
- **`-exclude`**：源码已打印弃用警告，语义由 `-include` 取代；因为用的是
  「其余参数」式解析，必须放最后。

2.2 源码的选项表里还有两个手册未收录的：`-N <次数>`（改每条性质的最大成功测
试数）与 `-analysis`（把输出改成 JSON 便于程序处理）。

### 76.7 与本教程 build.sh 工作流的衔接

本教程的定位是**单文件自包含**：每章一个 .v、`Module` 包裹、`build.sh` 复制到
build/ 后逐个 `rocq compile`。QuickChick 命令内嵌执行、输出看 `Passed`/
`Failed`——这套流程适合边写边测，本章示例也照此编译（注解全是注释，不影响
`build.sh -File 76_cli.v`）。

`quickChick` 面向的是**目录即项目**的形态：`_CoqProject` + 构建命令。想在本教
程里实操，搭一个 stack-compiler 式的最小目录即可，两个配置文件（官方原样）：

```text
-Q . Stack
Tutorial.v
Exp.v
Stack.v
```

```makefile
all: Makefile.coq
	$(MAKE) -f Makefile.coq

Makefile.coq:
	coq_makefile -f _CoqProject -o Makefile.coq

clean: Makefile.coq
	$(MAKE) -f Makefile.coq clean
	rm -rf ../_qc_$(shell basename $(CURDIR)).tmp *.bak Makefile.coq*

test: clean
	quickChick -color -top Stack
```

（第一个是 `_CoqProject`：`-Q . Stack` 绑定逻辑前缀，下面列出参与编译的文
件——`Tutorial.v` 是官方 POPL 教程现场文件，与变异测试无关，自建时可删去。
第二个是 `Makefile`：`make test` 即清理后跑一轮完整变异测试。）

把本章 `Ex76Cli` 的内容拆回两个文件就能跑：76.1–76.2 的 exp/eval/optimize 及
注解放 `Exp.v`，76.3–76.4 的 sinstr/execute/compile 及注解放 `Stack.v`，去掉
`Module` 包裹与激活的内嵌 `QuickChick` 行（保留注解），再执行：

```bash
$ make test          # 或直接：quickChick -color -top Stack
$ quickChick -color -top Stack -s optimizations     # 只测优化器
$ quickChick -color -top Stack -m 0                  # 只验收 0 号 mutant
```

对本教程主线，建议保持双轨：日常开发与逐章学习用 `build.sh`（快、反馈直接）；
当一个验证项目长到多文件、或想在 CI 上既跑证明又跑属性测试时，再引入
`quickChick`——它的非零退出码语义正好补上 `rocq compile` 全绿不代表全通过
（69 章）的缺口。最后记得把 `_qc_*.tmp` 与 `*.bak` 加进 .gitignore（官方
Makefile 的 clean 目标会清理它们）。

### 76.8 坑与要点

- **两套退出码语义别混**：内嵌 `QuickChick` 证伪不改 `rocq compile` 退出码；
  `quickChick` 对任何意外结果（base 失败、mutant 全绿、结果不可判定）非零退出。
- **注解必须具名**：`(*! QuickChick (fun e => ...). *)` 没有这种写法；先把性质
  `Definition` 成名字。
- **变体必须逐字可替换 base**：替换后不合法的变体会在对应 mutant 段直接编译
  失败，整个运行以非零退出码收场。
- **mutant 编号是相对本次运行的**：`-s` 换节、增删 mutant 都会重排；用 `-m`
  前先跑一遍看头部编号。
- **`-m`/`-tag` 会连带跳过 base 段**；只想跳 base 用 `-nobase`。
- **`-top` 对不上 `_CoqProject`**：`QuickChickTop.v` 的 `Require` 直接报错，
  这是新手上手最常见的失败。
- **临时目录在父目录**：`../_qc_<目录名>.tmp` 是当前目录的兄弟目录，父目录不可
  写时会失败；清理靠项目 Makefile 的 clean 目标。
- **幸存 mutant 的两读法**：盲区（要补性质、调生成器——回 73 章的 `collect`
  与按规格生成）或等价 mutant（语义本就相同，永远杀不死，人工剔除）。
- **别在普通注释里抄注解样例**：rocq 认嵌套注释，工具的扫描器不认，会误读出
  假的 mutant。

至此属性测试篇（69–76）完结：四要素、生成器、可检查性质、条件性质、自动派
生、综合案例，最后落到工具链与反向考核。下一步要么把稳定下来的性质升级成
`Theorem`（各证明篇的老本行），要么给自己 75 章式的性质套件种几个 mutant，
看看它到底有多灵。
