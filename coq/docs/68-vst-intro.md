# 68 · VST 入门：数组求和的第一个验证

对应示例：`../examples/68_sumarray.v`（Rocq 9.1.1 + stdlib 9.0.0 + VST 2.16 实测编译退出码 0）

前 67 章里我们写的每一个定义、每一条定理，都是 Gallina 世界内部的数学。本章起教程进入 Verified Companions 扩章：对象不再是 Gallina 函数，而是**真实的 C 程序**——经过 CompCert 前端解析、可以被编译成机器码的那种。我们要回答的问题是：一段 C 代码「算得对不对」，能不能像证明 `sort` 正确那样在 Rocq 里证出来？

答案是能，工具就是 VST。本章全程只验证一个 12 行的 C 程序 `sumarray`：把数组元素加起来。它小到我们能在一条引理里看遍整个验证流程的每个零件，又完整到包含本章及后续章节所需的全部基本操作：写函数模型、写 funspec、符号执行、循环不变式、函数调用、全局变量、整程序汇总。学完本章，你将拥有一张「C 程序验证世界地图」，第 69 章的链表反转只是换一张地形图。

## 68.1 三个名字：VST、Verifiable C 与 Floyd

初学者最先混淆的是这三个名字，先划清边界：

- **VST（Verified Software Toolchain）**是总称：一套在 Rocq 里证明 C 程序函数正确性的工具链。它的可靠性（soundness）经过形式化证明——你证出的性质对 C 源语言操作语义的一切执行成立，并且能与 CompCert  verified 编译器的正确性证明**复合**，一直下沉到汇编代码的行为。
- **Verifiable C** 是其中的**程序逻辑**：一个基于分离逻辑（Separation Logic）的霍尔逻辑。它的判断形如 `semax Delta Pre c Post`：在类型上下文 `Delta` 下，命令 `c` 在满足前置断言 `Pre` 的任何状态上执行，若终止则满足后置断言 `Post`。分离逻辑的关键是 **SEP 合取**（`*`）：内存被切成互不相交的若干块，分别由各个 `data_at` 之类的事实描述——这正是处理指针别名问题的利器。
- **Floyd** 是**证明自动化系统**：一个 Rocq tactic 库（`VST.floyd`）。程序逻辑的规则又长又机械（想一想第 20 章决策过程的复杂度），Floyd 的 `forward`、`entailer!` 等 tactic 替你完成规则匹配与化简，你只需在关键节点提供创意（循环不变式、witness）。

三者分工一句话：**Clight AST 描述程序长什么样，Verifiable C 定义「正确」是什么意思，Floyd 帮你把证明推完，VST 的可靠性定理保证这一切不是自娱自乐。** 本章只教使用（写 spec + Floyd 证明），不碰可靠性证明本身。

## 68.2 被验证的 C 程序与 clightgen 工作流

要验证的 C 程序全文如下：

```c
#include <stddef.h>

unsigned sumarray(unsigned a[], int n) {
  int i; unsigned s;
  i=0;
  s=0;
  while (i<n) {
    s+=a[i];
    i++;
  }
  return s;
}

unsigned four[4] = {1,2,3,4};

int main(void) {
  unsigned int s;
  s = sumarray(four,4);
  return (int)s;
}
```

逐行看它在验证视角下的样子：

- `unsigned sumarray(unsigned a[], int n)`：参数 `a` 是 `unsigned` 数组（退化为指针），`n` 是 `int` 长度。返回类型 `unsigned` 决定后置条件里 RETURN 的类型是 `tuint`。
- `int i; unsigned s;`：两个局部变量。注意 C 里 `i` 是**有符号**、`s` 是**无符号**，验证时两者溢出规则完全不同（68.6 详述）。
- `i=0; s=0;`：两个赋值语句，各走一步 `forward`。
- `while (i<n) { s+=a[i]; i++; }`：唯一一个循环。`s+=a[i]` 含数组下标——这是本章第一个技术要点：`forward` 过数组下标前必须证明下标在界内。
- `return s;`：返回语句。
- `unsigned four[4] = {1,2,3,4};`：一个**带初值的全局数组**。全局变量住在内存里，所以它也占用分离逻辑资源，由 `main` 的前置条件带入。
- `main` 只做一件事：以全局数组 `four` 调用 `sumarray`，返回其和（应为 10）。

VST 不直接读 `.c` 文件。工作流的第一步是用 CompCert 自带的 `clightgen` 把 C 解析成 **Clight AST**（CompCert 的 C 子集中间语言）：

```
clightgen -normalize sumarray.c
```

产物是同名的 Rocq 文件 `sumarray.v`——一棵 Gallina 写成的**抽象语法树**。其中三个名字本章会反复用到：`prog`（整个程序的 AST）、`_sumarray`（函数名的 ident，clightgen 给每个 C 标识符加下划线前缀）、`f_sumarray`（`sumarray` 函数体的 AST）。我们的示例通过 `examples/68_sumarray.v.deps` 依赖这棵树（构建系统把它编进 `VC` 逻辑路径下），正文不展示它的内容，把它当成「编译器输出」即可。

从 AST 到定理的完整流水线是：

```
sumarray.c --clightgen--> sumarray.v (Clight AST)
                              |
        函数模型 (纯 Gallina) + funspec (你写)
                              |
                    semax_body 逐函数证明 (Floyd 驱动)
                              |
              semax_prog 汇总 =「整个程序正确」
```

## 68.3 标准样板

每个 VST 验证文件的开头都是同一段样板，唯一随程序变化的是 `Require` 的 AST 文件名：

```coq
(* 68 VST 入门 —— 分离逻辑验证 C 程序：数组求和 *)

(* ---------- 68.1 标准样板：compspecs 与 Vprog ---------- *)

Require Import VST.floyd.proofauto.
Require Import VC.sumarray.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs.  mk_varspecs prog. Defined.
```

四行各管一件事：

1. `Require Import VST.floyd.proofauto.`：导入 Verifiable C 程序逻辑 + Floyd 全套 tactic。本章的 `forward`、`entailer!`、`forward_while` 全来自这里。
2. `Require Import VC.sumarray.`：导入 68.2 说的 Clight AST。之后 `prog`、`_sumarray`、`f_sumarray` 都在作用域里。
3. `#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.`：处理 AST 里的 struct/union 定义，生成类型布局信息。本程序没有结构体，但 `compspecs` 实例是后续一切断言的隐式参数，缺了它所有 `data_at` 都类型检查不过。
4. `Definition Vprog : varspecs. mk_varspecs prog. Defined.`：收集程序里全部**全局变量**的名字与类型（本例中即 `four : tarray tuint 4`），供 `semax_body` 的上下文查询。

## 68.4 函数模型 sum_Z

证明 C 程序正确的第一步，不是看 C 代码，而是写一个**函数模型**（functional model）：用纯 Gallina 数学描述「这个函数本该算什么」：

```coq
(* ---------- 68.2 函数模型 sum_Z ---------- *)

Definition sum_Z : list Z -> Z := fold_right Z.add 0.

Lemma sum_Z_app:
  forall a b, sum_Z (a++b) =  sum_Z a + sum_Z b.
Proof.
  intros. induction a; simpl; lia.
Qed.
```

`sum_Z` 就是第 8 章的 `fold_right` 换名字：把 `Z.add` 右结合地折过整个列表。注意模型里用的是**数学整数 `Z`**，不是 C 的 32 位 `int`——模型只管数学，C 的位宽问题交给规格层处理（68.6）。

`sum_Z_app` 是模型的第一条引理：`sum_Z` 对列表拼接 `++` 的分配律。证明是老朋友：`induction a` 后 `simpl` 把折返展开，`lia` 收尾。这条引理现在看是平凡的，但它正是循环体证明里把「前 i 项和 + 第 i 项」拼成「前 i+1 项和」的那块积木。

**方法论**：函数模型不 import 任何 VST 库、不依赖 AST，是纯数学。这是刻意的设计——模型的对错与 C 无关，可以独立审查、独立复用。

## 68.5 API 规格：sumarray_spec

模型回答「算什么」，**函数规格（funspec）**回答「在什么样的内存与参数条件下算，算完留下什么」。这是 C 世界的「接口契约」，对应 C 头文件里函数原型的角色：

```coq
(* ---------- 68.3 API 规格：sumarray_spec ---------- *)

Definition sumarray_spec : ident * funspec :=
DECLARE _sumarray
 WITH a: val, sh : share, contents : list Z, size: Z
 PRE [ tptr tuint, tint ]
  PROP  (readable_share sh; 0 <= size <= Int.max_signed;
         Forall (fun x => 0 <= x <= Int.max_unsigned) contents)
  PARAMS (a; Vint (Int.repr size))
  SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)
 POST [ tuint ]
  PROP () RETURN (Vint (Int.repr (sum_Z contents)))
  SEP (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a).
```

逐子句拆解：

- **`DECLARE _sumarray`**：把 ident `_sumarray`（来自 clightgen 的函数名）与一个 funspec 配对，整体类型是 `ident * funspec`。Gprog（68.7）里收集的就是这一对对子。
- **`WITH a: val, sh: share, contents: list Z, size: Z`**：对四个 Rocq 值做存在量化，它们贯穿前、后置条件。`a` 是数组地址（CompCert 的 `val`，即可是 `Vint` 整数、`Vptr` 指针等的联合体），`sh` 是**权限份额**（share，分离逻辑里描述「只读/可写/部分权限」的格元素），`contents` 是用数学整数列出的数组内容，`size` 是长度。
- **`PRE [ tptr tuint, tint ]`**：方括号里是 C 参数类型表——`a` 是 `unsigned int*`（`tptr tuint`），`n` 是 `int`（`tint`）。前置条件本体由三段组成：
  - **`PROP`**：与内存无关、恒真的命题列表。这里三条：`readable_share sh`（份额至少是只读——调用者不必给出写权限）；`0 <= size <= Int.max_signed`（长度装进 32 位**有符号**整数，因为 C 代码里 `n` 和 `i` 都是 `int`）；`Forall (fun x => 0 <= x <= Int.max_unsigned) contents`（每个元素都装进 `unsigned`）。
  - **`PARAMS (a; Vint (Int.repr size))`**：函数形参表（仅前置条件用 PARAMS；后置里对应的是 RETURN）。它断言：形参 `_a` 装着值 `a`、形参 `_n` 装着 `size` 的 32 位表示。
  - **`SEP`**：分离逻辑的空间断言列表。只有一个合取：`data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a`，读作「在地址 `a` 处，存在一个 `unsigned int[size]` 数组，权限 `sh`，内容恰为 `contents` 中各数的 32 位表示」。`data_at` 是 VST 里描述「内存中躺着一个类型完整的值」的核心谓词；它隐含一个事实：**内容表的长度恒等于类型里的长度**——68.11 会靠它取出 `Zlength contents = size`。
- **`POST [ tuint ]`**：方括号是返回类型 `unsigned int`。`PROP ()` 空（没有新产生的恒真事实）；**`RETURN (Vint (Int.repr (sum_Z contents)))`** 断言返回值是「数学和」的 32 位表示；`SEP` 里原样归还整个数组——`sumarray` 只读不写。

整段规格用一句话读：**「对任意满足条件的数组（有只读权限、长度装得下、元素装得下），调用 `sumarray` 必返回元素和的 32 位表示，且数组分毫不动。」**

## 68.6 整数溢出与 Int.repr

为什么规格里到处是 `Int.repr` 和 `Int.max_*`？因为 C 的整数不是数学整数：

- **`Int.repr : Z -> int`** 把数学整数截断（取模 2^32 后再按有符号解释）成 CompCert 的 32 位 `int`。`Int.max_unsigned = 2^32 - 1`，`Int.max_signed = 2^31 - 1`。
- **无符号算术是模运算**，自然回绕，不定义溢出——所以 `s` 和数组元素的累加无需防溢出，规格只要求元素各自 `<= Int.max_unsigned`。
- **有符号算术溢出是未定义行为**——所以 Verifiable C 要求你证明它不发生：循环变量 `i` 满足 `0 <= i <= size <= Int.max_signed`，`i++` 永不过界。

最后还有一个微妙点：后置条件保证返回 `Int.repr (sum_Z contents)`，可万一和超过 2^32 呢？那时 `Int.repr` 回绕，数学和与机器值脱钩。**规格说的是机器行为，数学结论要靠调用者补证** `0 <= sum_Z contents <= Int.max_unsigned`——好在 `main` 里数组是 `[1;2;3;4]`，易如反掌。

## 68.7 main 的规格与 Gprog

`main` 的规格有一种特殊形态：

```coq
(* ---------- 68.4 main 的规格 ---------- *)

Definition main_spec :=
 DECLARE _main
  WITH gv : globals
  PRE  [] main_pre prog tt gv
  POST [ tint ]
     PROP()
     RETURN (Vint (Int.repr (1+2+3+4)))
     SEP(TT).
```

要点：

- `WITH gv : globals`：全局变量表的句柄。C 的全局变量是内存资源，必须由某人的前置条件「持有」——按惯例全部交给 `main`。
- `PRE [] main_pre prog tt gv`：`main_pre` 是 Floyd 的内置前置条件，它**自动扫描程序的全局声明**，为每个全局变量生成对应的 `data_at`。本例中它会在前置 SEP 里给出 `data_at Ews (tarray tuint 4) (map Vint [Int.repr 1; ...; Int.repr 4]) (gv _four)`：`Ews` 是 extern writable share（全局可写），`gv _four` 是该变量的地址。
- `POST` 的 `RETURN (Vint (Int.repr (1+2+3+4)))` 直白地宣布：程序返回 10。`SEP(TT)` 表示「不再对内存做任何声称」（TT 是恒真，一切资源都可交还）。

```coq
(* ---------- 68.5 汇总 Gprog ---------- *)

Definition Gprog := [sumarray_spec; main_spec].
```

`Gprog` 把全部 funspec 打包成一个列表。它扮演两个角色：作为 `semax_body` 的上下文（函数体里调别的函数时按它查被调函数的规格，68.13 的 `forward_call` 就靠它），以及作为 `semax_prog` 的「验收清单」（68.14 逐个勾销）。多模块程序里还要把 import 的 funspec 一并列入。

## 68.8 semax_body 与 start_function

规格写完，开始证明每个函数体满足自己的规格：

```coq
(* ---------- 68.6 证明 sumarray 的函数体 ---------- *)

Lemma body_sumarray: semax_body Vprog Gprog f_sumarray sumarray_spec.
Proof.
start_function.
```

`semax_body Vprog Gprog f_sumarray sumarray_spec` 读作：在全局变量类型表 `Vprog`、函数规格表 `Gprog` 的上下文中，函数体 AST `f_sumarray` 满足规格 `sumarray_spec`。`semax_body` 是把 `semax` 判断包到「函数声明 + 形参/局部变量类型上下文」上的一层：它自动构造 `Delta`（类型上下文），然后归约成一个 Hoare 三元组目标。

每个 `semax_body` 证明的**第一行永远是 `start_function.`**。它完成开题簿记：把 WITH 量化的 `a, sh, contents, size` 引入上下文，把规格 PRE 的 PROP 事实放上横线，建好 `Delta`/`Delta_specs` 两个查询上下文。横线上还会看到两个**缩写**（abbreviation）：`MORE_COMMANDS`（函数体剩余的语句序列）与 `POSTCONDITION`（规格的后置条件）。它们是 Rocq 隐式参数的把戏——`abbreviate` 其实是 `forall A, A -> A` 的恒等函数，两个参数都隐式，作用纯粹是**把冗长的 AST 与断言折叠成一行**，不让目标刷屏。想看被折叠的内容，随时 `unfold abbreviate in MORE_COMMANDS`（之后 `abbreviate_semax` 可重新折起，不折也行，下一个 `forward` 会代劳）。

## 68.9 forward 符号执行

`start_function` 之后的目标是关于「整条函数体」的三元组。Floyd 的默认推进方式是**前向符号执行**：从前往后逐语句应用最强后条件规则，像调试器单步执行，只不过「执行」的是符号值。赋值、自增、`return` 这类语句各一步：

```coq
forward.
forward.
```

两条 `forward.` 分别走过 `i=0;` 和 `s=0;`。每走一步，观察当前前提（`semax` 第二个参数）的 `LOCAL` 部分：第一条执行后新增 `temp _i (Vint (Int.repr 0))`——「C 变量 `_i` 当前装着 32 位整数 0」。这就是前向执行的核心体验：**语句的效果体现为 LOCAL/SEP 断言的机械化更新**，你不需要手写任何中间断言。

## 68.10 循环不变式与 forward_while

遇到 `while`，`forward` 无能为力——前向执行可能进入无穷迭代。必须人工提供一个**循环不变式**（loop invariant），交给 `forward_while`：

```coq
forward_while
 (EX i: Z,
   PROP  (0 <= i <= size)
   LOCAL (temp _a a;
          temp _i (Vint (Int.repr i));
          temp _n (Vint (Int.repr size));
          temp _s (Vint (Int.repr (sum_Z (sublist 0 i contents)))))
   SEP   (data_at sh (tarray tuint size) (map Vint (map Int.repr contents)) a)).
```

不变式的构造是本章第一个真正的「创意点」，套路值得背下来：不变式的形态也是 `PROP/LOCAL/SEP` 断言，但用 `EX i: Z` 存在量化一个**迭代变量**——每次循环对应 `i` 的一个取值。本例里它断言：`i` 始终夹在 `0` 与 `size` 之间；`_i` 装着 `i`、`_n` 装着 `size`；而 `_s` 装着 **`contents` 前 `i` 项的部分和**（`sublist 0 i contents` 是 Floyd 提供的列表区间截取）；SEP 原样保留整个数组（循环只读它）。注意不变式精确到「`i` 与 `size` 的表示是 `Int.repr` 包装」这一层——LOCAL 里装的是 C 值，不是数学值。

`forward_while` 留下**四个子目标**，用 `-` 子弹逐个处理：

**子目标 1：当前断言蕴含不变式**（进循环前的「初始化检查」）。右边被 `EX i` 存在量化，横线上只有 `temp _i (Int.repr 0)`，所以要先用 **`Exists`** tactic 给出 witness——它就是分离逻辑语境下的 `exists`，对应普通证明里的 `exists 0`：

```coq
- Exists 0.
  entailer!.
```

**子目标 2：循环测试表达式类型检查**（`tc_expr`，即「测试能求值不出错」：变量都已初始化、不越界等）。这类目标 `entailer!` 几乎都直接闭掉：

```coq
- entailer!.
```

**子目标 3：循环体保持不变式**——最长的子目标，68.11 专门讲。**子目标 4：循环出口**——68.12 讲。

## 68.11 assert_PROP、entailer! 与 sublist 引理链

进入循环体，第一条 C 语句是 `s += a[i]` 里的数组下标 `a[i]`。`forward` 在这里会**失败**：它必须先证明下标 `i` 落在数组界内，而横线上只有不变式给的 `0 <= i <= size`，没有「数组长度是 `size`」这一环。界内性目标形如 `0 <= i < Zlength (map Int.repr contents)`，无法自动通过。

所需的等式 `Zlength contents = size` 其实**藏在前提的 SEP 里**：`data_at sh (tarray tuint size) (...) a` 按定义强制内容表长度等于 `size`。但 SEP 合取是空间资源，不是可以随手 `apply` 的命题——需要 **`assert_PROP`** 把它**提升为 PROP 事实**放到横线上：

```coq
- assert_PROP (Zlength contents = size). {
    entailer!.
    do 2 rewrite Zlength_map. reflexivity.
  }
```

`assert_PROP P` 生成一个子目标：`当前前提 |- P`（前提在左边，目标命题在右边）。证明它靠 **`entailer!`**——Floyd 证蕴含式的主力 tactic。它做三档化简：先把 `ENTAIL Delta, P |-- Q` 分解、再做 `go_lower`（压低 PROP/LOCAL 层，把所有 `temp`/`lvar` 等局部事实翻译成横线上的等式与范围假设）、再做 `saturate_local`（从左边各 SEP 合取里**榨出**全部可用命题，比如正是从 `data_at` 里榨出 `Zlength (...) = size` 放到横线）。做完这些，剩下的尾巴由 `do 2 rewrite Zlength_map. reflexivity.` 收掉（两层 `map` 不改变长度）。（Floyd 的 `list_solve` 也能一步解决这类列表长度目标，本教程用手写法让读者看清结构。）至此横线上有了 `Zlength contents = size`，三条 `forward.` 顺畅走过 `x = a[i];`、`s += x;`、`i++;`：

```coq
  forward.
  forward.
  forward.
```

走到循环体末尾，当前断言（即循环体的最强后条件）必须重新蕴含不变式——这就是不变式的「保持」方向。迭代变量取 `i+1`：先 `Exists (i+1)`，再 `entailer!` 把一切能自动化推掉（界内性、`Int.repr` 的环同态等），剩下唯一的纯数学目标：

```
sum_Z (sublist 0 (i+1) contents) = sum_Z (sublist 0 i contents) + Znth i contents
```

「前 i+1 项和 = 前 i 项和 + 第 i 项」，证明分三步拆：

```coq
  Exists (i+1).
  entailer!.
  f_equal. f_equal.
  rewrite (sublist_split 0 i (i+1)) by lia.
  rewrite sum_Z_app. rewrite (sublist_one i) by lia.
  simpl. lia.
```

- `sublist_split 0 i (i+1)`：把 `sublist 0 (i+1)` 在 `i` 处撕开成 `sublist 0 i contents ++ sublist i (i+1) contents`（`by lia` 提供撕口合法的条件 `0 <= i <= i+1 <= length`）；
- `sum_Z_app`：68.4 的模型引理，把和分配到拼接两段；
- `sublist_one i`：单元素区间 `sublist i (i+1) contents` 就是 `[Znth i contents]`；
- `simpl. lia.`：把 `sum_Z [x]` 算成 `x`，线性算术收尾。

三条 `by lia` 与本行 `lia` 里用的界内性假设 `0 <= i <= size` 与 `Zlength contents = size` 都来自横线——这正是前面 `assert_PROP` 投资的红利。

## 68.12 循环之后与 return

第四个子目标：循环正常出口。此时前提自动合成了「不变式 ∧ 循环测试为假」，即 `i = size`（由 `0 <= i <= size` 与 `¬(i < size)` 得）。`return s;` 同样一步 `forward`：

```coq
- forward.
  entailer!.
  autorewrite with sublist in *|-.
  autorewrite with sublist.
  reflexivity.
Qed.
```

`forward` 过 `return` 后，目标是「当前前提蕴含函数的 POSTCONDITION」。`entailer!` 化简后核心等式是 `sum_Z (sublist 0 size contents) = sum_Z contents`（配合 `i = size`）。`autorewrite with sublist` 是 Floyd 的 `sublist` 重写库：`sublist 0 (Zlength l) l = l` 之类的引理自动归约，归约完两边相同，`reflexivity` 收官，`Qed`。

至此 `body_sumarray` 完成。回顾整条证明的形状：`start_function` 开题 → 两条 `forward` 走到循环 → `forward_while` 配一个人工不变式 → 四个子目标各用一个模式（Exists+entailer! / entailer! / assert_PROP+forward+ Exists+引理链 / forward+entailer!）→ `Qed`。这套模式将原封不动地复用于第 69 章的链表反转。

## 68.13 全局变量与 main 的函数体

现在验证 `main`。先定义全局数组的内容表，然后照例 `start_function`——此时前提的 SEP 里就能看到 `main_pre` 自动生成的 `data_at Ews (tarray tuint 4) (...) (gv _four)`：

```coq
(* ---------- 68.7 全局变量与 main 的函数体证明 ---------- *)

Definition four_contents := [1; 2; 3; 4].

Lemma body_main:  semax_body Vprog Gprog f_main main_spec.
Proof.
  start_function.
  forward_call (gv _four, Ews, four_contents, 4).
```

`forward_call` 走函数调用语句 `s = sumarray(four, 4);`。它的参数是**被调函数 WITH 子句的 witness 元组**：`sumarray_spec` 声明 `WITH a: val, sh: share, contents: list Z, size: Z`，四元顺序给出——地址 `gv _four`、权限 `Ews`、内容 `four_contents`、长度 `4`。Floyd 拿这个 witness 去 Gprog 里查 `_sumarray` 的规格，实例化其前/后置，把调用前状态与规格前提对齐。

`forward_call` 会留下一个子目标：**被调函数 PRE 的 PROP 部分必须在调用点成立**——本例即「`four` 可读、`0 <= 4 <= Int.max_signed`、每个元素 `<= Int.max_unsigned`」：

```coq
  repeat constructor; computable.
```

`repeat constructor` 拆掉 `Forall` 的两个构造子与三条前提的合取，`computable` 是 Floyd 的决策过程，把 `0 <= 4 <= 2147483647` 这类纯数值比较算掉。最后 `forward.` 走过 `return s;`：

```coq
  forward.
Qed.
```

## 68.14 semax_prog 与 prog_correct

两个函数体都证完了，最后把整程序打成一张证书。先看一行样板：`semax_prog` 还需要一个**外部规格 Espec**——描述程序与外部世界（I/O、系统调用）交互的抽象接口。`sumarray` 不与世界交互，用**平凡实例** `NullExtension.Espec` 即可：

```coq
(* ---------- 68.8 整个程序的正确性 ---------- *)

#[export] Existing Instance NullExtension.Espec.

Lemma prog_correct: semax_prog prog tt Vprog Gprog.
Proof.
prove_semax_prog.

semax_func_cons body_sumarray.
semax_func_cons body_main.
Qed.
```

`semax_prog prog tt Vprog Gprog` 读作：「在程序 `prog` 中，Vprog/Gprog 里登记的每个函数都满足其规格」。`prove_semax_prog` 把这条大定理拆成函数清单上的逐个义务；`semax_func_cons body_sumarray.` 用 68.8–68.12 的引理勾销 `_sumarray` 那一项，再同理勾销 `_main`。（对照第 61 章的 `cofix` 显式构造：这里每一步都是普通引理应用，没有 guardedness 检查——C 函数的递归由类型系统与 Gprog 的依赖顺序保证良构。）

证书铸成，惯例是用 `Print Assumptions` 审计它到底依赖哪些公理：

```coq
Print Assumptions prog_correct.
(* Axioms:
ClassicalDedekindReals.sig_not_dec : forall P : Prop, {~ ~ P} + {~ P}
ClassicalDedekindReals.sig_forall_dec :
  forall P : nat -> Prop,
  (forall n : nat, {P n} + {~ P n}) ->
  {n : nat | ~ P n} + {forall n : nat, ~ P n}
prop_ext : ClassicalFacts.prop_extensionality
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
  f = g -> forall x : A, f x = g x
Eqdep.Eq_rect_eq.eq_rect_eq :
  forall (U : Type) (p : U) (Q : U -> Type) (x : Q p) (h : p = p),
  x = eq_rect p Q x p h
Classical_Prop.classic : forall P : Prop, P \/ ~ P
Ensembles.Extensionality_Ensembles :
  forall (U : Type) (A B : Ensembles.Ensemble U),
  Ensembles.Same_set U A B -> A = B *)
```

输出**不是** `Closed under the global context`——七条公理来自 stdlib 的经典逻辑、命题/函数外延与带类型等性的基础设施（`Classical_Prop.classic`、`prop_ext`、`functional_extensionality_dep` 等），是 VST 及其底层库的标准假设集：全部是关于 **Prop 世界**的经典性断言，不涉及任何关于 C 语义或内存的临时公理。这是 VST 证书的标准「成色」。

## 68.15 本章坑位

以下每个坑都是编写本章时**实际复现过**的报错（Rocq 9.1.1 + VST 2.16），报错文本为编译器原样输出。

**坑 1：对数组下标直接用 `forward`，界内性没到位。** 删掉 68.11 的 `assert_PROP` 块、让 `forward` 直接碰 `a[i]`：

```text
File "./bad1.v", line 67, characters 2-9:
Error: Tactic failure: Make sure Zlength_solve or auto can prove
(0 <= i < Zlength (map Int.repr contents))

The usual way to do that is to use assert or assert_PROP before forward. (level 1).
```

报错本身已给出药方：先用 `assert` 或 `assert_PROP` 把界内性（或其原料 `Zlength contents = size`）放到横线上。新手容易在横线已经有 `0 <= i <= size` 时误以为足够——差的就是 SEP 里 `data_at` 藏着的那条长度等式。

**坑 2：`forward_call` 不给 witness。** 把 `forward_call (gv _four, Ews, four_contents, 4).` 写成裸的 `forward_call.`：

```text
File "./bad2.v", line 94, characters 2-14:
Error: Tactic failure: Failed to infer some parts of witness.
```

Floyd 不会替你猜 WITH 实例化（尤其是 `contents` 这种从内存内容反推不出来的量）。witness 元组的**顺序和分量必须与 WITH 子句一一对应**，写错类型还会报 unification 错误。

**坑 3：`forward_call` 之后忘了先证 PROP 子目标。** 删掉 `repeat constructor; computable.` 直接 `forward.`，报错落在下一行，且信息极具误导性：

```text
File "./bad5.v", line 95, characters 2-9:
Error:
Tactic failure: simplify_Delta did not put Delta_specs and Delta into canonical form.
```

真实原因是 `forward_call` 留下的 PROP 义务没清、当前子目标根本不是 `semax` 目标，`forward` 的预处理当然失败。同类症状：循环不变式子目标没解完就写下一条 `-` 子弹，报 `[Focus] Wrong bullet -: Current bullet - is not finished.`。**看到这两类「风马牛不相及」的错误，先检查上一个 tactic 是否留下了未关闭的子目标。**

**坑 4：漏写 `start_function.`。** 证明体直接以 `forward.` 开头：

```text
File "./bad7.v", line 53, characters 0-7:
Error:
Tactic failure: simplify_Delta did not put Delta_specs and Delta into canonical form.
```

`semax_body` 目标还没展开成三元组形状，Floyd 的全部 tactic 都找不到它们期望的前提结构。与坑 3 同一条错误文本、两种病因——这条文本基本等于「当前目标不是规范的 semax 断言，先想少了哪步开题」。

---

上一章：[67 · 引用与副作用](67-references.md) ｜ 下一章：[69 · 链表反转](69-list-reverse.md) ｜ 返回：[README](../README.md)
