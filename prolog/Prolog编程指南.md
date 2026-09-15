# Prolog 编程指南

一份面向「会写别的语言，但没写过 Prolog」的人的教程。全书 24 章，配 20 个可运行示例，每个示例都在 **SWI-Prolog** 和 **GNU Prolog** 两套引擎上实测通过。

学完你会明白：Prolog 不是「另一种命令式语言」，它的程序是**一组逻辑陈述**，运行方式是**自动定理证明 + 回溯搜索**。所有看起来奇怪的语法（`=` 不是赋值、`is` 才算算术、`!` 是剪枝、DCG 的 `-->`）都是这个前提的推论。

---

## 第 1 章 语言概览：Prolog 到底在干什么

大多数语言你写「怎么做」，Prolog 你写「什么是真的」。

```prolog
parent(tom, bob).
parent(bob, ann).

grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
```

前两行是**事实**，第三行是**规则**，读作「若 X 是 Y 的父/母，且 Y 是 Z 的父/母，则 X 是 Z 的祖父母」。

然后你**提问**：

```prolog
?- grandparent(tom, ann).
true.

?- grandparent(tom, X).
X = ann.
```

三件事和别的语言不一样：

1. **没有赋值，只有合一（unification）**。`X = 5` 不是「把 5 存进 X」，而是「让 X 和 5 变成同一个东西」。如果 X 已经有值了就变成比较。`X = 5, X = 6` 会直接失败。
2. **没有返回值，谓词可以「成功」或「失败」**。失败不是错误，是「这条路径走不通」，系统会回头试别的分支。这就是回溯。
3. **没有循环，只有递归**。所有迭代都写成递归 + 累加器（见第 9 章）。

适用范围：Prolog 擅长的东西在教科书里叫「符号推理」——自然语言解析、专家系统、规划、约束求解、类型检查、数据库查询、程序分析。不擅长的东西也很明确：数值密集型计算、需要原地修改状态的算法、UI。

---

## 第 2 章 工具链与运行方式

本仓库用两套引擎，各有各的用处。

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| `swipl` | `/opt/local/bin/swipl` | SWI-Prolog 10.0.2 | 库最全，日常开发首选 |
| `gprolog` | `/opt/local/bin/gprolog` | GNU Prolog 1.5.0 | 体量小，自带 FD 约束求解器 |
| `gplc` | `/opt/local/bin/gplc` | 随 GNU Prolog | 编成无依赖的本地可执行文件 |

> **Windows 说明**：上表路径是 macOS（MacPorts）环境。Windows 下用
> `scoop install swipl` 装 SWI-Prolog 即可（本仓库在 10.0.2 x64-win64 上验证通过）；
> **GNU Prolog 没有官方 Windows 构建**，`gprolog` / `gplc` 两条通道在 Windows
> 上不可用，`build.ps1` / `run-all.sh` 会自动跳过缺失的工具，无需改动。

### 三条运行通道

**通道 1：SWI 解释执行**

```bash
swipl -q -f examples/01-hello-facts.pl -g main -t halt
```

- `-q`：安静模式，不打 banner
- `-f FILE`：加载文件（不用 `-f` 会去读 `~/.swiplrc`）
- `-g main`：加载完后执行 `main/0`
- `-t halt`：结束时执行 `halt`（哪怕 `main` 失败了也保证退出）

**Windows 下直接跑上面的命令会满屏 `Illegal multibyte Sequence`**：Windows 版
swipl 默认按 ANSI 代码页（中文系统是 GBK）解码源文件、写重定向流，而本仓库
示例是 UTF-8（含中文）。手动运行要补两处（`build.ps1` / `run-all.sh` 已内置）：

```bash
swipl -Dencoding=utf8 -q -f examples/01-hello-facts.pl -g "set_stream(user_output,encoding(utf8)),main" -t halt
```

- `-Dencoding=utf8`：在加载源文件前设好 encoding 标志，修复**源文件解码**
- `set_stream(user_output, encoding(utf8))`：`user_output` 启动时就按本地编码
  打开了，`-D` 管不到它，要在 `-g` 里显式改，否则**重定向输出**仍是 GBK

macOS / Linux 的 locale 本来就是 UTF-8，这两处等价无操作，加不加都一样。

**通道 2：GNU 解释执行**

```bash
gprolog --consult-file examples/01-hello-facts.pl --entry-goal main
```

注意 GNU 会把编译信息（`compiling ... compiled, N lines read`）打到 **stdout**，所以本仓库的判定标准里不检查「stdout 只有程序输出」，而是检查「stdout 里有结束标记」。

**通道 3：gplc 编译成本地可执行文件**

```bash
{ echo ':- initialization(main).'; cat examples/01-hello-facts.pl; } > build/01.pl
cd build && gplc 01.pl -o 01.bin && ./01.bin
```

两个坑：

- `gplc` 只在**当前目录**可靠工作。源文件放子目录（比如 `gplc examples/x.pl`）会因为找不到中间产物而链接失败。本仓库的做法就是把源码拼一份到 `build/` 再编。
- 没有 `:- initialization(main).` 的话，`gplc` 出来的可执行文件不会自动跑 `main`，会掉进交互式 toplevel 等键盘输入 —— 在脚本里就是**永久挂死**。这就是为什么 `run-all.sh` 和 `build.ps1` 都必须重定向 stdin。

### 脚本化的硬性要求

每个示例都是「跑一遍就退出」的脚本，所以固定套路是：

```prolog
main :-
    (   catch(run, E, (nl, format("*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format("*** run/0 失败~n", []), halt(1)
    ).

run :-
    ...
    format("==== NN 结束 ====~n", []).
```

- `halt(0)` 成功 / `halt(1)` 失败，CI 直接读退出码。
- 输出末尾打一个 `==== NN 结束 ====`，验证脚本用它确认「真的跑到了最后一行」，而不是中途失败后被 `halt(0)` 掩盖。
- 没有这个 `halt`，程序跑完会掉进 toplevel 卡住。

### 判定标准

三条通道共用同一套判定，全满足才算通过：

1. 退出码为 0
2. **stderr 为空**（FS 警告都不允许）
3. stdout 里有结束标记 `==== NN 结束 ====`

跑全部：

```bash
./run-all.sh          # 摘要
./run-all.sh -v       # 附完整输出
./run-all.sh 07 15    # 只跑指定编号
```

```powershell
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 04-arithmetic.pl
pwsh ./build.ps1 -Clean
```

---

## 第 3 章 事实、规则与查询（示例 01）

事实库就是若干条断言：

```prolog
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
male(tom).
female(liz).
```

规则用 `:-`，左边是要证明的目标，右边是条件：

```prolog
father(X, Y)      :- parent(X, Y), male(X).
grandparent(X, Z) :- parent(X, Y), parent(Y, Z).
sibling(X, Y)     :- parent(P, X), parent(P, Y), X \== Y.
ancestor(X, Y)    :- parent(X, Y).
ancestor(X, Y)    :- parent(X, Z), ancestor(Z, Y).
```

`ancestor/2` 两条子句是标准写法：一条基例 + 一条递归。系统自上而下试子句，第一条失败就试第二条。

### 变量与匿名变量

- 大写字母或 `_` 开头＝变量。作用域是**单个子句**，跨子句不共享。
- `_` 是匿名变量，每次都算一个新的，用来占位。
- `_X` 是「有名字但不警告未使用」的写法 —— 两套引擎都会对只出现一次的变量报 singleton 警告，而**警告会污染 stderr**，所以本仓库统一用 `_X` 消掉。

### 收集全部解

交互式环境里按 `;` 能一个一个看解，脚本里不行，要用 `findall/3`：

```prolog
?- findall(X, parent(tom, X), L).
L = [bob, liz].
```

`findall(Template, Goal, List)`：对 `Goal` 的每一个解，把 `Template` 实例化后的结果收进 `List`。这是脚本化 Prolog 里最常用的谓词，没有之一。

### 本章的坑

**同一个谓词，不同用法**。`parent(tom, X)` 是查「tom 的孩子」，`parent(X, jim)` 是查「jim 的父母」，`parent(X, Y)` 是枚举所有亲子对。Prolog 没有「输入参数」和「输出参数」的区别 —— 谓词就是一个关系，谁绑定了谁没绑定，它自己会处理。这一点是 Prolog 最强大的地方，也是新手最容易写出「只在某个方向能用」的谓词的原因。

---

## 第 4 章 项与合一（示例 02）

Prolog 里所有数据都是**项（term）**，一共四类：

| 类型 | 例子 | 判断谓词 |
|---|---|---|
| 变量 | `X`, `_` | `var/1` |
| 数字 | `42`, `3.14` | `number/1` |
| 原子 | `tom`, `'hello world'`, `[]` | `atom/1` |
| 复合项 | `f(a,b)`, `[1,2,3]`, `a-b` | `compound/1` |

注意 **`[]` 是原子**，`[1,2,3]` 是复合项（等价于 `'.'(1,'.'(2,'.'(3,[])))`）。列表没什么神奇，就是嵌套的二元项。`[H|T]` 只是 `'.'(H, T)` 的语法糖。

### `=` 与 `==`

这是最容易混的一对：

| 写法 | 名字 | 行为 |
|---|---|---|
| `X = Y` | 合一 | 尝试让两边**变成同一个东西**，会绑定变量 |
| `X == Y` | 同一性 | 检查两边**现在是否已经是同一个东西**，绝不绑定 |
| `X \= Y` | 不能合一 | `= ` 的否定 |
| `X \== Y` | 不同一 | `==` 的否定 |

```prolog
?- X = 1.        % X 绑定成 1
?- X == 1.       % false（X 还是自由变量，不是 1）
?- X = 1, X == 1.% true
?- f(X) = f(a).  % X 绑定成 a —— 合一能穿透复合项的结构
```

**合一能穿透结构**，这是它区别于字符串比较的关键：`f(g(X), b) = f(g(a), Y)` 一次同时绑定 `X=a, Y=b`。

### 发生检查

```prolog
?- X = f(X).
X = f(X).          % 默认不做发生检查，造出一个循环项
```

ISO 提供 `unify_with_occurs_check/2` 防止这件事：

```prolog
?- unify_with_occurs_check(X, f(X)).
false.
```

默认不开是因为检查要遍历整个项，代价高。知道有这回事就行 —— 真造出循环项，`write` 打它会无限循环。

### 标准项序

Prolog 里所有项有一个全序，排序谓词（`sort`/`msort`/`keysort`）都基于它：

```
变量 < 数字 < 原子 < 复合项
```

同类之间：数字按值比，原子按字典序，复合项先比参数个数，再比各参数。

```prolog
?- compare(O, 1, 2).        O = (<)
?- compare(O, abc, abd).    O = (<)
?- compare(O, f(1), f(1,2)).O = (<)   % 元数小的在前
?- compare(O, 1, a).        O = (<)   % 数字 < 原子
```

**这个序决定了 `sort` 的顺序，不写自定义比较函数。** 想按自定义键排序，就把键做成 `Key-Value` 再 `keysort/2`（见第 22 章词频统计）。

### `copy_term/2`

```prolog
?- copy_term(f(X, Y), C).
C = f(_A, _B).
```

复制出一份**新鲜变量**，两边不共享。写元解释器、做全排列、生成模板时都要用（模板里的变量必须每次是新的）。

### 本章的坑

**singleton 警告会污染 stderr**。写 `show_unify(f(X), f(b))` 时如果 `X` 只用一次，两套引擎都会警告 `singleton variable X`，而警告进了 stderr 就直接判定失败。修法是把一次性变量写成 `_X`。

---

## 第 5 章 回溯与搜索树（示例 03）

Prolog 求解一个目标时，会维护一棵**搜索树**。每个「有多个子句可匹配」或「有多个成员可选」的地方都是一个**选择点**，失败时回退到最近的选择点，试下一个分支。

```prolog
path(A, B, [A, B])     :- parent(A, B).
path(A, B, [A | Rest]) :- parent(A, C), path(C, B, Rest).
```

`path(X, Y, P)` 同时是「找一条路径」和「验证这条路径是否存在」：

```prolog
?- path(tom, jim, P).
P = [tom, bob, pat, jim]
```

**回溯是双向的**：如果你把路径给全了，它会去验证：

```prolog
?- path(tom, jim, [tom, bob, jim]).
false.          % 这条路径不存在
```

这是 Prolog 独有的爽点 —— 同一个谓词，正着算反着验都能用。写别的语言你得写两个函数。

### 迭代加深

朴素递归搜索在无限分支的图上会永远钻进第一条路径出不来。解决办法是加深度限制：

```prolog
ancestor_d(X, Y, D) :- D > 0, parent(X, Y).
ancestor_d(X, Y, D) :- D > 1, D1 is D - 1, parent(X, Z), ancestor_d(Z, Y, D1).
```

外层用 `between(1, MaxD, D)` 逐渐加大 `D`，就是迭代加深。**用两次搜索的代价换掉无限递归的风险**。

### Generate & Test

Prolog 的经典模式：先用 `between` / `member` 生成候选，再用条件过滤。

```prolog
?- between(1, 100, X), 0 is X mod 7, 0 is X mod 5, X > 50.
X = 70
```

先用约束过滤、后生成（constraint & generate）永远比先生成后过滤快 —— 第 19 章讲约束求解时会看到这个差别的量级。

### 本章的坑

**子句顺序决定搜索顺序，也决定会不会死循环**。`ancestor` 的基例必须写在递归子句**前面**，否则简单查询也要先钻到底。反过来，如果递归子句在无限分支上，先写它就会挂死。

---

## 第 6 章 算术与比较（示例 04）

Prolog 的算术是这套语言里最反直觉的部分，只有一条规则要记住：

> **`=` 不算术，`is` 才算术。**

```prolog
?- X = 1 + 2.
X = 1+2.          % 只是把表达式存起来，没算

?- X is 1 + 2.
X = 3.            % 真算了
```

`1+2` 是**项**，不是数字。`is/2` 才是求值器。

### 比较运算符

| 用途 | 算术（先求值） | 项（不求值） |
|---|---|---|
| 相等 | `=:=` | `==` |
| 不等 | `=\=` | `\==` |
| 小于 | `<` | `@<` |
| 小于等于 | `=<` | `@=<` |
| 大于 | `>` | `@>` |
| 大于等于 | `>=` | `@>=` |

**`=<` 不是 `<=`**，方向反的，这是全世界 Prolog 新手都踩过的坑。

```prolog
?- 1 + 1 =:= 2.     true.
?- 1 + 1 == 2.      false.   % 项 1+1 和项 2 不是一个东西
?- 1 + 1 @< 2.      true.    % 按标准项序，1+1 是复合项，2 是数字 → 数字在前
```

### 整数除法与余数

```prolog
?- X is 7 / 2.      X = 3.5        % 浮点除法
?- X is 7 // 2.     X = 3          % 整数除法
?- X is 7 mod 2.    X = 1          % 取余
?- X is 2 ** 10.    X = 1024.0     % 幂（返回浮点）
?- X is 2 ^ 10.     X = 1024       % 整数幂（有些引擎才有）
```

`//`（截断除）和 `mod`（取余）符合 `(A // B) * B + (A mod B) =:= A`。

### 递归算术：阶乘与斐波那契

```prolog
fact(0, 1).
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

% 尾递归版，用累加器
fact_acc(N, F) :- fact_acc(N, 1, F).
fact_acc(0, Acc, Acc).
fact_acc(N, Acc, F) :- N > 0, Acc1 is Acc * N, N1 is N - 1, fact_acc(N1, Acc1, F).
```

两版的区别见第 9 章。这里先注意 `N > 0` 这个守卫：**没有它，`N1 is N - 1` 会一路减到负数，永不终止。**

### 本章的坑

**算术谓词两头都得是「够具体」的东西**。`X is Y + 1` 里 `Y` 必须是数字，否则直接抛 `error(instantiation_error, ...)`。Prolog 的算术不是符号计算 —— 想解方程得用约束求解（第 19 章）。

---

## 第 7 章 列表（示例 05）

列表就是 `[H|T]` 的嵌套结构，没有特殊支持，全靠递归谓词。

```prolog
my_length([], 0).
my_length([_ | T], N) :- my_length(T, N0), N is N0 + 1.

my_append([], L, L).
my_append([H | T], L, [H | R]) :- my_append(T, L, R).

my_member(X, [X | _]).
my_member(X, [_ | T]) :- my_member(X, T).
```

**`my_append/3` 是理解 Prolog 的试金石。** 三种调用方式：

```prolog
?- my_append([1,2], [3], X).      % 拼接
X = [1,2,3]

?- my_append([1,2], Y, [1,2,3]).  % 求后缀
Y = [3]

?- my_append(X, Y, [1,2]).        % 枚举所有切分方式
X = [],        Y = [1,2] ;
X = [1],       Y = [2] ;
X = [1,2],     Y = [].
```

第三种用法（**枚举所有切分**）是命令式语言里没法直接表达的，而它是很多解析算法的核心。

### 反转与累加器

```prolog
% 朴素版：每次 append，O(n^2)
naive_reverse([], []).
naive_reverse([H | T], R) :- naive_reverse(T, RT), my_append(RT, [H], R).

% 累加器版：O(n)
my_reverse(L, R) :- my_reverse(L, [], R).
my_reverse([], Acc, Acc).
my_reverse([H | T], Acc, R) :- my_reverse(T, [H | Acc], R).
```

第 21 章的基准测试会量化这个差别（800 个元素：1 ms vs 19 ms，差 20 倍）。

### 两套引擎的列表库差异

本仓库遇到过的（见示例 05 和 20 的「双引擎差异」小节）：

| 谓词 | SWI | GNU | 可移植写法 |
|---|---|---|---|
| `numlist/3` | ✅ | ❌ | 自己写 `my_numlist/3` |
| `union/3` `intersection/3` | ✅ | ❌ | 用 `member` 手写 |
| `subtract/3` `flatten/2` | ✅ | ✅ | 直接用 |
| `memberchk/2` `reverse/2` `msort/2` `sort/2` | ✅ | ✅ | 直接用 |
| `min_list/2` `max_list/2` `sum_list/2` | ✅ | ✅ | 直接用 |

### 本章的坑

**`[1,2,3] == '.'(1,'.'(2,'.'(3,[])))` 是 true，但 `'.'` 不能当函子随便用**。SWI 在某些配置下 `'.'` 是保留的，直接写会报错。要演示列表的本质，用 `[a|[b]] == [a,b]` 这种写法更安全。

---

## 第 8 章 高阶谓词与元调用（示例 06）

Prolog 的「函数指针」就是一个**闭包项**，用 `call/N` 调用。

```prolog
double(X, Y) :- Y is X * 2.

?- call(double, 5, R).      R = 10
?- Goal = double, call(Goal, 5, R).   R = 10
```

`call/2..8` 把额外参数追加到闭包后面。`call(double(5), R)` 也是合法的（SWI 和 GNU 都支持这个写法）。

### `maplist`

最常用的高阶谓词，`maplist(Goal, L1, ..., Ln)` 把 `Goal` 逐元素作用上去：

```prolog
?- maplist(double, [1,2,3], R).       R = [2,4,6]
?- maplist(plus, [1,2], [10,20], R).  R = [11,22]    % 两个列表逐元素
?- maplist(=(x), [x,x]).              true          % 检查全是 x
```

`maplist/2..5` 两套引擎都有。

### `include/exclude/foldl`

```prolog
gt3(X) :- X > 3.

?- include(gt3, [1,4,2,5], R).    R = [4,5]
?- exclude(gt3, [1,4,2,5], R).    R = [1,2]
?- foldl(plus, [1,2,3,4], 0, S).  S = 10
```

`foldl(Goal, List, Acc0, Acc)`：`Goal` 是三元谓词 `Goal(Elem, Acc0, Acc1)`。

### `=..`（univ）

在「复合项」和「函子+参数列表」之间来回转换：

```prolog
?- f(a, b) =.. L.        L = [f, a, b]
?- T =.. [g, 1, 2].      T = g(1,2)
```

这是元编程的基础设施 —— 有了它，你可以在运行时拆开、改写、重组任意项：

```prolog
rename_functor(Term, NewF, Out) :-
    Term =.. [_ | Args],
    Out =.. [NewF | Args].
```

### 谓词表（解释器套路）

把「名字 → 实现」放进数据库，运行时查表调用：

```prolog
op_table(add, add3).
op_table(mul, mul3).
op_table(dbl, double).

eval_op(Name, A, B, R) :-
    op_table(Name, Impl),
    ( call(Impl, A, B, R) -> true ; call(Impl, A, R) ).
```

加新操作只要 `assertz` 一条 `op_table`，不用改任何已有代码。这是 Prolog 里实现「插件」最自然的做法。

### 本章的坑

**`call/N` 的第一个参数必须是可调用的项**。`call(X, 5)` 里 `X` 还是自由变量时会抛 `instantiation_error`。想让它「先挂起来，以后再确定」是不行的 —— Prolog 的调用是即刻的。

---

## 第 9 章 递归、累加器与尾调用（示例 07）

### 尾递归

```prolog
% 非尾递归：递归调用之后还要做乘法，栈帧不能扔
fact_naive(N, F) :- N > 0, N1 is N - 1, fact_naive(N1, F1), F is N * F1.

% 尾递归：递归调用是最后一步，栈帧可以复用
fact_tail(N, F) :- fact_tail(N, 1, F).
fact_tail(0, Acc, Acc).
fact_tail(N, Acc, F) :- N > 0, Acc1 is Acc * N, N1 is N - 1, fact_tail(N1, Acc1, F).
```

**尾递归的判定标准**：递归调用是不是子句体的**最后一个目标**，且调用后没有剩余工作。`fact_tail` 里递归调用之后什么都没有，是尾递归；`fact_naive` 里之后还有 `F is N * F1`，不是。

尾递归在 Prolog 里的意义比别的语言更大：SWI 和 GNU 都做**尾调用优化（LCO）**，尾递归谓词的栈占用是常数的，能处理很深的递归；非尾递归版会在几千层时栈溢出。

### 累加器经典三例

```prolog
% 1. 反转——已经从第 7 章见过
reverse_acc(L, R) :- reverse_acc(L, [], R).
reverse_acc([], Acc, Acc).
reverse_acc([H | T], Acc, R) :- reverse_acc(T, [H | Acc], R).

% 2. 计数
count_if([], _, 0).
count_if([X | Xs], Goal, N) :-
    count_if(Xs, Goal, N1),
    ( catch(call(Goal, X), _, fail) -> N is N1 + 1 ; N = N1 ).

% 3. 扁平化——朴素版会 O(n^2)
my_flatten([], []).
my_flatten([H | T], F) :-
    ( is_list(H) -> my_flatten(H, FH) ; FH = [H] ),
    my_flatten(T, FT),
    append(FH, FT, F).
```

### 差异列表

异构列表（difference list）是 Prolog 里避开 `append` 的经典技巧 —— 把一个列表表示成 `列表-尾洞` 的差对：

```prolog
flatten_diff(L, F) :- flatten_dl(L, F-[]).
flatten_dl(X, [X | T]-T) :- \+ is_list(X), !.
flatten_dl([], T-T) :- !.
flatten_dl([H | T], F-T0) :-
    flatten_dl(H, F-T1),
    flatten_dl(T, T1-T0).
```

思想：`[a,b,c|T]-T` 表示「以 T 为尾巴的 a,b,c」。拼接两个差异列表 `A-T1` 和 `T1-B` 结果是 `A-B`，**不用复制任何元素**。整体复杂度从 O(n²) 降到 O(n)。

DCG 的 `-->` 展开成的就是这个东西（第 13 章）。

### 本章的坑

**包装谓词和递归谓词必须换名字。**

```prolog
flatten_dl(L, F) :- flatten_dl(L, F-[]).     % 灾难：flatten_dl/2 会调用自己，无限递归
```

正确写法是把包装谓词叫 `flatten_diff/2`，递归谓词叫 `flatten_dl/2`，**元数不同但名字相同也是坑**（`flatten_dl/2` 调用 `flatten_dl/2` 就是自己）。这类错误的表现是「程序不报错但永远不返回」，定位时优先怀疑这个。

---

## 第 10 章 剪枝与否定（示例 08）

### `!` 是什么

`!`（cut，剪枝）的作用是：**丢掉当前谓词中「这个 `!` 之后的所有子句」和「这个 `!` 之前的所有选择点」**。

最直观的例子 —— 不用 cut：

```prolog
classify_age_naive(Age, child)  :- Age < 13.
classify_age_naive(Age, teen)   :- Age >= 13, Age < 20.
classify_age_naive(Age, adult)  :- Age >= 20.
```

```prolog
?- classify_age_naive(30, X).
X = adult ;
false.          % 还能继续回溯，白费功夫去试前两条
```

用 cut：

```prolog
classify_age(Age, child) :- Age < 13, !.
classify_age(Age, teen)  :- Age >= 13, Age < 20, !.
classify_age(_,   adult).
```

```prolog
?- classify_age(30, X).
X = adult.      % 只有这一个解，没有多余的选择点
```

### 绿切 vs 红切

**绿切（green cut）**：剪掉的都是本来就会失败的分支，程序语义不变，只是更快。

```prolog
grade_green(S, a) :- S >= 90, !.
grade_green(S, b) :- S >= 80, !.
grade_green(S, c) :- S >= 70, !.
grade_green(_,  f).
```

**红切（red cut）**：靠 `!` 来保证正确性，删掉 `!` 程序就错了。

```prolog
grade_red(S, G) :- S >= 90, !, G = a.
grade_red(_,  f).
```

`grade_red` 删掉 `!` 之后，`grade_red(95, G)` 会给出 `G = a` 和 `G = f` 两个解 —— 明显是错的。**红切要特别小心**，因为它让子句顺序变成语义的一部分，重构时会炸。

### if-then-else

`(Cond -> Then ; Else)`：`Cond` 成功走 `Then` **且不回溯进 `Cond`**（隐含一个 cut），失败走 `Else`。

```prolog
max_of(X, Y, M) :- ( X >= Y -> M = X ; M = Y ).
sign_of(N, S) :- ( N > 0 -> S = positive ; N < 0 -> S = negative ; S = zero ).
```

**`->` 本身就带剪枝**。这一点经常被忽略：`(member(X, [1,2,3]) -> true ; true)` 只会产生**一个**解，不是三个。

### `\+`（否定即失败）

`\+ Goal` 读作「`Goal` 不可证明」：

```prolog
?- \+ member(5, [1,2,3]).
true.
```

语义是「`Goal` 失败则 `\+ Goal` 成功」，**并且 `\+` 内部的变量绑定全部丢弃**：

```prolog
?- \+ (X = 1).
false.          % X = 1 能证明，所以 \+ 失败
?- \+ (X = 1, X = 2).
true.           % 不能同时等于 1 和 2，所以不可证明
```

**`\+` 不是逻辑否定**，它是「closed-world assumption」：证明不了就当作假。`\+ likes(mary, X)` 这种带自由变量的写法语义很微妙（意思是「mary 什么都不喜欢」而不是「有某个 mary 不喜欢的东西」），实际代码里尽量别写。

### once/1

`once(Goal)` = `call(Goal), !`。要第一个解、不要多余选择点时用：

```prolog
?- once(member(X, [1,2,3])).   X = 1.
```

### 本章的坑

**`!` 只作用于它所在的谓词**。

```prolog
outer(X)     :- inner(X).
inner(X)     :- member(X, [1,2,3]).

outer_cut(X) :- inner_cut(X).
inner_cut(X) :- member(X, [1,2,3]), !.   % 这个 ! 管不到 outer_cut
```

`outer_cut` 依然只有一个解，但原因不是「cut 传上去了」，而是 `inner_cut` 本身只有一解。**别指望用内层谓词的 `!` 去剪外层的选择点** —— 这是 Prolog 里最反直觉的语义之一。

---

## 第 11 章 定子句文法（示例 09）

DCG（Definite Clause Grammar）用 `-->` 写文法，本质上是**语法糖** —— 每个 `-->` 子句会被展开成带两个额外参数（输入串、剩余串）的普通谓词。

```prolog
sentence --> np, vp.
np(np(D, N)) --> det(D), noun(N).
vp(vp(V, NP)) --> verb(V), np(NP).

det(the) --> [the].
det(a)   --> [a].
noun(cat) --> [cat].
noun(dog) --> [dog].
verb(eats) --> [eats].
```

注意 `np(np(D,N)) --> ...` 里，`np(D,N)` 就是它**造出来的语法树节点**。DCG 不只是识别器，它天然地构造解析树。

### 三种调用方式

```prolog
?- phrase(sentence, [the,cat,eats,a,dog]).        % 识别整句
true.

?- phrase(sentence, [the,cat,eats,a,dog], Rest).  % 识别后还剩什么
Rest = [].

?- phrase(np(T), [the,cat]).                      % 要语法树
T = np(the, cat).
```

`phrase(Goal, List)` = `phrase(Goal, List, [])`。

### 语义动作 `{}`

`{}` 里是普通 Prolog 目标，不消耗输入：

```prolog
count_x(0) --> [].
count_x(N) --> [x], count_x(N0), { N is N0 + 1 }.

digit(D) --> [D], { between(0'0, 0'9, D) }.
```

`digit/1` 这个写法很值得琢磨：它既接受 `[0'5]` 这样的已知字符，也能**生成**一个数字字符 —— 因为 `between` 是可双向用的。整个 DCG 因此也是可双向用的：

```prolog
?- phrase(sentence, S).        % 生成所有合法句子
S = [the, cat, eats, the, cat] ;
S = [the, cat, eats, the, dog] ;
...
```

**生成句子和解析句子是同一份代码**，这在别的语言里得写两套。

### 展开后长什么样

```prolog
det(the) --> [the].
```

展开成：

```prolog
det(the, S0, S) :- S0 = [the | S].
```

`S0` 是输入串，`S` 是消耗掉 `[the]` 之后剩下的。`np --> det, noun` 展开成 `np(S0,S) :- det(S0,S1), noun(S1,S)`，就是把串一路「接力」传下去。**这正是第 9 章讲过的差异列表**。

### 本章的坑

**左递归会死循环。**

```prolog
expr --> expr, [+], term.     % 展开后 expr(S0,S) :- expr(S0,S1), ... 无限递归
```

理由是 DCG 展开后 `expr` 的第一个目标还是 `expr`，而且参数不变，DCG 的自顶向下解析器会立刻钻进无限递归。解决办法是把左递归改写成右递归 + 累加器（示例 10 用的是 `expr_rest` 这种写法），或者用带记忆的解析（SWI 的 `library(tabling)`）。

---

## 第 12 章 用 DCG 写解析器（示例 10）

一个能算 `1+2*(3-1)` 的完整计算器，分三层：

### 第一层：词法分析

```prolog
tokenize([], []).
tokenize([C | Cs], [num(N) | Ts]) :-
    C >= 0'0, C =< 0'9, !,
    take_digits([C | Cs], Ds, Rest),
    number_codes(N, Ds),
    tokenize(Rest, Ts).
tokenize([C | Cs], [C | Ts]) :-       % 其它符号原样保留
    tokenize(Cs, Ts).
```

### 第二层：语法 + 立即求值

```prolog
expr(E)     --> term(T), expr_rest(T, E).
expr_rest(A, E) --> [0'+], term(T), { A1 is A + T }, expr_rest(A1, E).
expr_rest(A, E) --> [0'-], term(T), { A1 is A - T }, expr_rest(A1, E).
expr_rest(A, A) --> [].

term(T)     --> factor(F), term_rest(F, T).
term_rest(A, T) --> [0'*], factor(F), { A1 is A * F }, term_rest(A1, T).
term_rest(A, T) --> [0'/], factor(F), { A1 is A / F }, term_rest(A1, T).
term_rest(A, A) --> [].

factor(N)   --> [num(N)].
factor(E)   --> [0'(], expr(E), [0')].
factor(N)   --> [0'-], factor(V), { N is -V }.       % 一元负号
```

**这就是运算符优先级的标准实现方式**：优先级越低的分层越靠上（`expr` 调 `term` 调 `factor`），每一层用右递归处理同级运算的左结合性。

### 第三层：先造 AST 再求值

```prolog
ast(A)        --> aterm(T), ast_add(T, A).
ast_add(L, R) --> [0'+], aterm(T), ast_add(add(L, T), R).
ast_add(L, A) --> [].

eval(add(A, B), V) :- eval(A, VA), eval(B, VB), V is VA + VB.
```

先造出 `add(num(1), num(2))` 这样的语法树，再单独求值。比直接求值多一个中间结构，但**可以复用**：同一棵树能做常量折叠、能生成代码、能算符号导数。要教程式语言实现，这一步不能省。

### 反向生成

```prolog
?- phrase(expr(E), T), length(T, 5).
```

因为 DCG 可双向，它能**从语法生成表达式**。这是很好的性质测试手段。

### 本章的坑

**`phrase/2` 和 `phrase/3` 的参数顺序容易写反**。

```prolog
phrase(sentence, Rest, [the,cat])     % 错：Rest 和词表位置换了
phrase(sentence, [the,cat], Rest)     % 对
```

参数顺序是 `phrase(文法, 输入串, 剩余串)`。

---

## 第 13 章 动态数据库（示例 11）

Prolog 程序本身就是数据。运行时改自己的子句：

```prolog
:- dynamic(counter/1).

bump_counter(N) :-
    retract(counter(N0)),         % 删掉旧值
    N is N0 + 1,
    assertz(counter(N)),          % 写入新值
    !.
bump_counter(1) :- assertz(counter(1)).
```

- `assertz/1`：加到最后（**z** = 尾部）
- `asserta/1`：加到最前（**a** = 头部），优先匹配
- `retract/1`：删除**第一个**匹配的子句（回溯能删更多）
- `retractall/1`：删除所有匹配的

`:- dynamic(pred/A)` 声明是必需的 —— 不加的话谓词是静态编译的，`assertz` 会报权限错误。

### 全局变量

Prolog 没有可变量，用动态数据库模拟：

```prolog
increment :- retract(counter(N0)), N is N0 + 1, assertz(counter(N)).
```

**注意 `!` 的作用**：没有它，`retract` 失败后会掉到第二条子句，第一次调用会留下两条 `counter` 事实。这是个经典 bug。

### 用动态库做缓存（memoization）

```prolog
fib_memo(N, F) :-
    (   retract(fib_memo(N, F))     % 命中缓存
    ->  assertz(fib_memo(N, F))     % 放回去（retract 会删掉它）
    ;   fib_slow(N, F),             % 真算一遍
        assertz(fib_memo(N, F))
    ).
```

`retract` 是「取出并删除」，所以命中后必须 `assertz` 放回去。这个模式叫 **retract-assert 缓存**。

### 动态图

边可以由 `assertz`/`retract` 在运行时增删，然后直接跑搜索：

```prolog
reachable(X, Y) :- reach(X, Y, [X]).

reach(X, Y, _) :- edge(X, Y).
reach(X, Y, Visited) :-
    edge(X, Z),
    \+ member(Z, Visited),          % 防环
    reach(X, Y, [Z | Visited]).
```

**`\+ member(Z, Visited)` 是必备的**，不然有环的图会无限递归。

### 坑

- **`retract` 是回溯性的**。写 `retract(edge(1, X))` 之后如果继续回溯，它会继续删下一条匹配的子句。要只删一条就在后面加 `!`。
- **动态谓词让调试变难**。逻辑在运行时才确定，`listing` 看到的和源码不一样。生产代码里动态子句一般是「配置」和「缓存」，核心逻辑还是静态的。
- **GNU 上 `clause/2` 读静态谓词需要 `:- public(p/n)` 声明**（见第 20 章）。

---

## 第 14 章 元编程（示例 12）

元编程 = 把程序当数据看。

### `clause/2`：读自己的子句

```prolog
grade(S, a) :- S >= 90.
grade(S, b) :- S >= 80.
grade(_,  f).

?- clause(grade(S, G), Body).
S = _A, G = a, Body = 90>=_A ;
...
```

`clause(Head, Body)` 把谓词的每个子句拆成头和体。用它能做规则检查、文档生成、代码变换。

### 运行时构造调用

```prolog
:- dynamic(getter/2).

make_getter(Field) :-
    atom_concat(get_, Field, Name),     % SWI 有；GNU 用 atom_concat 也行
    Head =.. [Name, Value],
    assertz((Head :- person(_, Value))).   % 注意这里生成了「一条子句」
```

**关键是 `assertz((Head :- Body))` 里那个括号** —— `assertz/1` 接受一个项，这个项必须整体是一条子句。不加括号的话 `,` 会把参数切开。

### 迷你规则引擎

```prolog
rule(animal_is(dog),  [barks, wags_tail]).
rule(animal_is(cat),  [meows, has_fur]).
rule(is_pet,          [animal_is(dog)]).
rule(is_pet,          [animal_is(cat)]).

explain(Goal, Depth) :-
    rule(Goal, Conditions),
    forall(member(C, Conditions), explain(C, Depth1)).
```

规则存在数据库里，推理机去读。加一条规则不用改代码 —— 这就是专家系统的骨架。

### 极简自解释器

```prolog
solve(true) :- !.
solve((A, B)) :- !, solve(A), solve(B).
solve(Goal) :- clause(Goal, Body), solve(Body).
```

不到十行，一个能跑 Prolog 子集的解释器。**Prolog 的自解释器短到可以背下来**，这是它作为「可执行的逻辑」最有力的证明。

### 编译期变换

用 `:- op/3` 定义自己的运算符，就能给自己的 DSL 做语法糖：

```prolog
:- op(700, xfx, ins).
:- op(500, xfx, ..).
```

`ins` 是 SWI clpfd 定义的运算符，`A ins 1..10` 读起来像自然语言。自定义运算符是 Prolog 做 DSL 的第一步。

### 坑

**被 `clause/2` 读的静态谓词，GNU 上要先声明 `:- public`。**

```prolog
:- if(current_prolog_flag(dialect, gprolog)).
:- public(grade/2).
:- endif.
```

不声明会抛 `permission_error(access, private_procedure, ...)`。SWI 没这个限制。

---

## 第 15 章 收集全部解（示例 13）

三个收集谓词的差别是初学者的分水岭。

### `findall/3`

```prolog
?- findall(X, member(X, [1,2,3]), L).
L = [1,2,3].
```

对每个解收集一次，**失败返回空表**：

```prolog
?- findall(X, member(X, []), L).
L = [].
```

### `bagof/3`

```prolog
age(tom, 30).  age(ann, 25).  age(bob, 35).  age(liz, 25).
city(tom, beijing).  city(ann, shanghai).  city(bob, beijing).  city(liz, shenzhen).

?- bagof(N, age(N, A), L).
A = 25, L = [ann, liz] ;
A = 30, L = [tom] ;
A = 35, L = [bob].
```

**`bagof` 会按目标里的自由变量分组**，每个分组返回一个解。上例里 `A` 是自由的，所以按 `A` 的值分了三组。

**没有解时 `bagof` 直接失败**（不是返回 `[]`）—— 这是它和 `findall` 最大的行为差异，写代码时必须注意。

### `V^`：屏蔽分组变量

不想要分组就用 `V^Goal`：

```prolog
?- bagof(N, A^age(N, A), L).
L = [tom, ann, bob, liz].     % 一个解，不再按 A 分组
```

`^` 读作「存在量化」：`A^age(N,A)` 意思是「存在某个 A 使得 age(N,A)」，`A` 不参与分组。

### `setof/3`

`bagof` + 排序去重：

```prolog
?- setof(N, A^age(N, A), L).
L = [ann, bob, liz, tom].     % 排序且去重
```

注意排序用的是**标准项序**（第 4 章）。

### `forall/2`

```prolog
?- forall(member(X, [1,2,3]), X > 0).
true.
```

`forall(Generator, Test)` = 「对所有 `Generator` 的解，`Test` 都成立」。相当于：

```prolog
forall(Cond, Action) :- \+ (Cond, \+ Action).
```

`forall` 只判断真假，**不收集解**。它内部的绑定不会传出来，所以 `forall(age(_, A), A >= 20)` 里的 `_` 要写匿名变量 —— 写 `forall(age(N, A), ...)` 会触发 singleton 警告。

### 聚合

```prolog
?- aggregate_all(count, member(_, [a,b,c]), N).      N = 3
?- aggregate_all(sum(X), member(X, [1,2,3]), S).     S = 6
?- aggregate_all(max(X), member(X, [3,1,2]), M).     M = 3
```

`aggregate_all/3` 是 SWI 的库谓词。**GNU Prolog 没有** —— 可移植的做法是用 `findall` 收成列表再手算：

```prolog
stats(L, Count-Sum-Min-Max) :-
    findall(V, member(V, L), Vs),
    length(Vs, Count),
    sumlist(Vs, Sum),          % 或者自己写递归
    min_list(Vs, Min),
    max_list(Vs, Max).
```

`min_list` / `max_list` / `sum_list` 两套引擎都有，可以放心用。

### 坑

**`findall` 和 `bagof` 在「无解」时的行为不同**：`findall` 返回 `[]` 且成功，`bagof` 失败。包在 `\+` 或 if-then-else 里时这个差别会改变程序流程。

---

## 第 16 章 输入输出与文件（示例 14）

### 三种输出

```prolog
write(term).              % 不引号的形式，abc 打 abc，'a b' 打 a b
writeq(term).             % 可读回的形式，'a b' 打 'a b'
format("~w ~q ~d ~s~n", [abc, f(x), 42, "str"]).
```

`format/2` 常用指令：

| 指令 | 含义 |
|---|---|
| `~w` | write 形式 |
| `~q` | writeq 形式（带引号，可读回） |
| `~d` | 整数 |
| `~f` / `~2f` | 浮点 / 保留 2 位 |
| `~s` | 字符码列表按字符串打印 |
| `~n` | 换行 |
| `~a` | 原子 |
| `~i` | 忽略对应参数 |

**要打印字面量 `~` 就写 `~~`。** 这是 `format` 字符串里最常见的错。

### 写文件

```prolog
open('/tmp/demo.txt', write, S),
format(S, "line1~n", []),
format(S, "line2~n", []),
close(S).
```

`open(File, Mode, Stream)` 的 Mode 是 `read` / `write` / `append`。**写完必须 `close`**，否则缓冲没落盘。

Windows 下还有个坑：**没有通用的 `/tmp`**。`'/tmp/x.txt'` 会被解析成
`<当前盘>:\tmp\x.txt`，该目录通常不存在，`open/3` 直接抛
`existence_error(source_sink, ...)`。跨平台写法见示例 14：用
`:- if(current_prolog_flag(windows, true))` 条件编译，Windows 分支改用
`%TEMP%`（SWI 下 `getenv('TEMP', T)` 可取到）。

### 读文件

读固定长度：

```prolog
read_n_chars(_, 0, []) :- !.
read_n_chars(S, N, [C | Cs]) :-
    get_code(S, C),
    N1 is N - 1,
    read_n_chars(S, N1, Cs).
```

逐行读：

```prolog
read_lines2(S, Lines) :-
    read_one_line(S, Cs, Last),
    (   Last == eof
    ->  Lines = []                       % 处理掉最后那个空行
    ;   Lines = [Cs | Rest],
        read_lines2(S, Rest)
    ).

read_one_line(S, Cs, Last) :-
    get_code(S, C),
    (   C =:= -1     -> Cs = [], Last = eof       % EOF
    ;   C =:= 0'\n   -> Cs = [], Last = newline   % 行尾
    ;   Cs = [C | Rest], read_one_line(S, Rest, Last)
    ).
```

**EOF 的判断要用 `get_code` 返回 `-1`**，别只靠 `at_end_of_stream/1` —— 后者在缓冲区边界上的行为两个引擎不完全一致，而且它不消耗字符，容易写成死循环。

### 用项做序列化

Prolog 的 `read/2` 和 `writeq/2` 天生就是序列化格式：

```prolog
open(F, write, S), writeq(S, point(1, 2)), write(S, '.\n'), close(S),
open(F, read, S2), read(S2, T), close(S2).
% T = point(1,2)
```

每个项后面**必须有一个 `.` 加空白**，`read` 才知道项在哪结束。这是 Prolog 源文件的格式，也是它的数据交换格式 —— 省掉了写 parser 的功夫。

### 流与别名

`user_output` / `user_error` / `user_input` 是标准流的别名：

```prolog
format(user_error, "警告：~w~n", [X]).
```

**把调试信息写到 `user_error` 而不是默认输出**，这样 `2>err.txt` 就能单独捞出来 —— 本仓库的判定标准要求 stderr 为空，所以正式示例里不能随便往 stderr 写东西。

### 坑

**文件路径用原子，且要引号**。`open('/tmp/x.txt', ...)` 里带特殊字符的路径必须用单引号包成原子，`open(/tmp/x.txt, ...)` 是语法错误。

---

## 第 17 章 原子与字符串（示例 15）

Prolog 里「字符串」有三层表示，这是新手最困惑的地方：

| 表示 | 例子 | 类型 | SWI 默认 | GNU 默认 |
|---|---|---|---|---|
| 原子 | `hello` | `atom` | ✅ | ✅ |
| 字符码列表 | `[104,101,108,108,111]` | `list` | `"hello"` 的备选 | `"hello"` 的默认 |
| 字符串 | `"hello"` | `string` | **默认** | 不存在这个类型 |

**SWI 里 `"hello"` 默认是 string 类型，GNU 里默认是字符码列表。** 这一个差异会让同一份代码在两套系统上行为完全不同。解决办法是在文件头统一声明：

```prolog
:- set_prolog_flag(double_quotes, codes).
```

这样 `"hello"` 在两套系统里都是字符码列表。**本仓库每个示例都有这一行。**

### 互转

```prolog
atom_codes(hello, Cs).          Cs = [104,101,108,108,111]
atom_chars(hello, Chs).         Chs = [h,e,l,l,o]
number_codes(42, Cs).           Cs = [52,50]
number_chars(42, Chs).          Chs = ['4','2']
atom_length(hello, N).          N = 5
atom_concat(hel, lo, hello).    true
char_code(a, C).                C = 97
```

反向也能用（这是 Prolog 的一贯风格）：

```prolog
?- atom_codes(A, [104,105]).    A = hi
?- number_codes(N, [0'4,0'2]).  N = 42
```

### `sub_atom/5`

```prolog
?- sub_atom('hello world', B, L, A, world).
B = 6, L = 5, A = 0.

?- sub_atom(abcd, 1, 2, _, S).      % 位置 1 起取 2 个
S = bc.
```

参数是 `sub_atom(原子, 起始, 长度, 尾部长度, 子原子)`。

### 切分与拼接

`atomic_list_concat/2,3`、`atomics_to_string/3`、`split_string/4` **都是 SWI 专有**。GNU 上没有，只能自己写：

```prolog
split_atom(Atom, Sep, Parts) :-
    atom_codes(Atom, Codes),
    split_codes(Codes, Sep, Groups),
    findall(P, (member(G, Groups), atom_codes(P, G)), Parts).

split_codes([], _, [[]]).
split_codes([C | Cs], Sep, [G | Gs]) :-
    (   C =:= Sep
    ->  G = [], split_codes(Cs, Sep, Gs)
    ;   G = [C | G1], split_codes(Cs, Sep, [G1 | Gs])
    ).
```

拼接同理：

```prolog
join_atoms([], _, '').            % 注意：'' 和 "" 都是空字符码列表
join_atoms([A], _Sep, A).
join_atoms([A | As], Sep, Out) :-
    join_atoms(As, Sep, Rest),
    atom_concat(A, Sep, Tmp),
    atom_concat(Tmp, Rest, Out).
```

### 格式化到原子

SWI 有 `format(atom(A), ...)`；GNU 没有 `with_output_to/2`，也没有 `format/3` 的 atom 目标。可移植的笨办法是**写临时文件再读回**：

```prolog
atom_format(Atom, Fmt, Args) :-
    (   catch(format(atom(Atom), Fmt, Args), _, fail)
    ->  true
    ;   Tmp = '/tmp/prolog-fmt.tmp',
        open(Tmp, write, S), format(S, Fmt, Args), close(S),
        open(Tmp, read, S2), read_all_codes(S2, Cs), close(S2),
        atom_codes(Atom, Cs)
    ).
```

笨，但百分之百可靠，而且额外教一遍「怎么用 catch 探测功能」。

### 本章的坑

**`format/1` 不存在**。`format("hello~n")` 在 SWI 上能跑（有重载），在 GNU 上直接 `existence_error`。**永远写 `format(Fmt, [])` 两参数形式**，哪怕没有参数。

---

## 第 18 章 异常与清理（示例 16）

```prolog
safe_div(A, B, R) :-
    (   B =:= 0
    ->  throw(division_by_zero)
    ;   R is A / B
    ).

?- catch(safe_div(1, 0, R), E, (write(E), nl, fail)).
division_by_zero
```

`catch(Goal, Catcher, Recovery)`：`Goal` 抛出的异常如果和 `Catcher` **合一成功**，就执行 `Recovery`。

### ISO 标准错误项

两套引擎都用这套结构化错误：

```prolog
error(instantiation_error, Context)                % 参数还是自由变量
error(type_error(ExpectedType, Culprit), Context)  % 类型不对
error(domain_error(Domain, Culprit), Context)      % 超出定义域
error(existence_error(procedure, Name/Arity), Context)   % 没这个谓词
error(existence_error(source_sink, File), Context)       % 没这个文件
error(permission_error(Operation, Type, Culprit), Context)
error(evaluation_error(Error), Context)            % 算术错误
```

```prolog
?- X is _ + 1.
ERROR: error(instantiation_error, ...)

?- atom_length(f(a), N).
ERROR: error(type_error(atom, f(a)), ...)

?- open('no-such-file', read, S).
ERROR: error(existence_error(source_sink, 'no-such-file'), ...)
```

**按错误项的函子匹配，比按原子名字匹配可靠得多**：

```prolog
catch(Goal, error(existence_error(_, _), _), fallback)   % 只捕这一类
```

### 主动抛错做参数校验

```prolog
:- dynamic(person/2).

set_age(Name, Age) :-
    (   \+ atom(Name)  -> throw(error(type_error(atom, Name), set_age/2))
    ;   \+ integer(Age) -> throw(error(type_error(integer, Age), set_age/2))
    ;   Age < 0 -> throw(error(domain_error(age, Age), set_age/2))
    ;   retractall(person(Name, _)),
        assertz(person(Name, Age))
    ).
```

这是 Prolog 里的「防御式编程」。**抛出结构化错误比直接失败好得多** —— 调用方能区分「参数错了」和「查不到结果」。

### 资源清理

```prolog
with_open(File, Mode, Goal) :-
    open(File, Mode, S),
    (   catch(call(Goal, S), E, (close(S), throw(E)))
    ->  close(S)
    ;   close(S), fail
    ).
```

套路是「**先把句柄关掉，再把异常原样抛回去**」：

```prolog
catch(Goal, E, (close(S), throw(E)))
```

注意 `throw(E)` 放在 `close(S)` 之后 —— 顺序反了文件就漏关了。

**SWI 有 `setup_call_cleanup/3`** 一次性解决这个问题：

```prolog
setup_call_cleanup(open(File, read, S), process(S), close(S))
```

它保证第三个参数无论在成功、失败还是异常时都会执行。**GNU 没有这个谓词**，手写版更保险。

### `catch` 与回溯

`catch` 只管异常，不影响回溯。但如果 `Recovery` 里有 `fail`，回溯会回到 `catch` 外面 —— 可以用这个特性跳过出错的元素：

```prolog
?- catch((member(X, [1,2,3]), picky(X), write(X)), bad_two, fail).
1
3
```

`X = 2` 时 `picky` 抛出 `bad_two`，`catch` 捕获后 `fail`，回溯继续找下一个 `X`。**这是「跳过坏数据继续处理」的惯用写法。**

### 退出码

```prolog
main :-
    (   catch(run, E, (format(user_error, "ERR ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "FAILED~n", []), halt(1)
    ).
```

- `halt/1` 带参数设置退出码：`halt(0)` 成功，`halt(1)` 失败
- 异常路径和失败路径分开处理，都能给出非零退出码
- `format(user_error, ...)` 让错误信息进 stderr，`stdout` 保持干净

**这套模板本仓库 20 个示例每个都在用。**

### 坑

**`catch` 的 `Catcher` 写裸变量会吞掉所有异常**。

```prolog
catch(Goal, _, fail)      % 危险：连 instantiation_error 这种真 bug 也吞了
```

只在确实想「不管什么错都当成失败」时这么写（比如做特性探测，见第 22 章）。正常代码里应该匹配具体的错误项。

---

## 第 19 章 约束求解（示例 17）

### 前言：为什么需要约束

朴素做法是「生成 + 测试」：

```prolog
queens_naive(N, Qs) :-
    numlist2(1, N, Qs),            % 生成 N 个数的所有排列
    safe_diagonals(Qs).            % 再检查对角线
```

N=8 时生成 8! = 40320 个排列，每个都要全文检查。约束求解的做法是**先声明值域和约束，让求解器主动剪枝，最后才枚举**：

```prolog
queens(N, Qs) :-
    length(Qs, N),
    domain_vars(Qs, 1, N),            % 1) 声明值域
    all_diff(Qs),                     % 2) 所有列不同
    safe_diagonals(Qs),               % 3) 对角线约束
    label_vars(Qs).                   % 4) 最后才枚举
```

差别在量级上：N=8 时朴素版要遍历 4 万种可能，约束版剪枝后基本是直接落解。

### 两套引擎的 API 完全不同

**SWI（clpfd 库）：**

```prolog
:- use_module(library(clpfd)).

domain_vars(Vars, Lo, Hi) :- Vars ins Lo..Hi.
all_diff(Vars)            :- all_different(Vars).
label_vars(Vars)          :- labeling([], Vars).
label_ff(Vars)            :- labeling([ff], Vars).
```

**GNU（内置 FD 求解器）：**

```prolog
domain_vars(Vars, Lo, Hi) :- fd_domain(Vars, Lo, Hi).
all_diff(Vars)            :- fd_all_different(Vars).
label_vars(Vars)          :- fd_labeling(Vars).
label_ff(Vars)            :- fd_labeling(Vars).
```

**用 `:- if(current_prolog_flag(dialect, ...))` 各写一份，是对付这个差异的唯一办法。**

```prolog
:- op(700, xfx, ins).
:- op(500, xfx, ..).

:- if(current_prolog_flag(dialect, swi)).
domain_vars(Vars, Lo, Hi) :- Vars ins Lo..Hi.
:- elif(current_prolog_flag(dialect, gprolog)).
domain_vars(Vars, Lo, Hi) :- fd_domain(Vars, Lo, Hi).
:- endif.
```

**注意那两个 `op/3` 声明必须放在 `:- if` 外面。** GNU 只是「跳过执行」这段代码，读文件时照样要能**解析**它。`Vars ins Lo..Hi` 里的 `ins` 和 `..` 如果不先声明成运算符，GNU 在读文件阶段就报语法错误，`:- if` 也救不了。

### 约束运算符对照

| 含义 | SWI (clpfd) | GNU (FD) |
|---|---|---|
| 相等 | `#=` | `#=` |
| 不等 | `#\=` | `#\=` |
| 小于 | `#<` | `#<` |
| 小于等于 | `#=<` | `#=<` |
| 大于 | `#> ` | `#>` |
| 大于等于 | `#>=` | `#>=` |
| 加法 | `+` | `+` |
| 元素约束 | `element(I, L, V)` | `fd_element(I, L, V)` |

基础的关系运算符两套是同名的（都是 ISO FD 提案的写法），分叉主要在**声明值域**和**枚举**这两个环节。

### 顺序很重要

```prolog
% 好：先加完所有约束，最后枚举
domain_vars(Qs, 1, N), all_diff(Qs), safe_diagonals(Qs), label_vars(Qs).

% 差：一边枚举一边加约束，等于退化成朴素版
label_vars(Qs), all_diff(Qs).
```

**每加一条约束都会剪掉一批候选，越早剪越省事。** 这是约束求解和普通回溯最本质的区别：约束是**主动收缩值域**的，不是被动等失败。

### 坑

- **`labeling` 的选项两套不一样**。SWI 用 `labeling([ff], Vars)`，GNU 的 `fd_labeling/2` 也接受选项但名字不同。想同时兼容就只用 `labeling([], Vars)` / `fd_labeling(Vars)` 的默认策略。
- **clpfd 的变量不是普通整数**。约束变量在 `labeling` 之前不能做 `is` 算术，`X is Y + 1` 会抛 `instantiation_error`。必须先 `labeling` 具体化。
- **GNU 上 `fd_domain/3` 是 `fd_domain(L, Lo, Hi)`，`L` 可以是单个变量也可以是列表**，这一点比 SWI 宽松（SWI 要用 `ins`）。

---

## 第 20 章 代码组织与条件编译（示例 18）

### GNU 没有模块系统

SWI 有 `:- module/2`，GNU 没有。想让一份代码在两套系统上都能跑，唯一零成本的办法是**命名前缀**：

```prolog
geo_area(circle(R), A)  :- A is 3.141592653589793 * R * R.
geo_area(rect(W, H), A) :- A is W * H.

geo_perimeter(circle(R), P) :- P is 2 * 3.141592653589793 * R.
```

用 `geo_` 前缀隔离，靠命名而不是靠系统。**这是可移植 Prolog 代码的通用做法。**

### 动态派发表

比硬编码 if-then-else 好得多的扩展方式：

```prolog
handler(circle, geo_area).
handler(rect,   geo_area).

demo :-
    handler(Name, Impl),
    call(Impl, circle(2), V).
```

加一个新形状 = `assertz` 一条 `handler` 事实，不碰任何已有谓词。

### 条件编译的关键字

```prolog
:- if(current_prolog_flag(dialect, swi)).
:- elif(current_prolog_flag(dialect, gprolog)).
:- else.
:- endif.
```

两套引擎都支持 `:- if` / `:- elif` / `:- else` / `:- endif`。**但有个大坑**：

> `:- if` 只控制「跳不跳过执行」，**被跳过的代码在读文件阶段仍然必须语法合法**。

所以 SWI 专有的运算符（比如 clpfd 的 `ins`）必须先 `:- op` 声明，否则 GNU 在 read 阶段就报语法错误（见第 19 章）。

### 运行时方言检测

```prolog
dialect_name(D) :-
    (   catch(current_prolog_flag(dialect, X), _, fail)
    ->  D = X
    ;   D = unknown
    ).
```

比编译期 `:- if` 更灵活，可以影响运行时行为。**注意要包 `catch`** —— 万一某个实现没有 `dialect` 标志，裸调用会抛异常。

### `:- initialization`

```prolog
:- initialization(main).        % 加载完后跑 main/0
```

这是把 Prolog 文件变成可执行脚本的关键。**`gplc` 编译出来的可执行文件没有 `:- initialization(main).` 就不会自动执行**，会掉进交互式 toplevel —— 在 CI 里就是永久挂死。

`build.ps1` 和 `run-all.sh` 的 gplc 通道就是靠拼一行 `:- initialization(main).` 到源码头部来实现的。

### `:- public`

**GNU 专有需求**：

```prolog
:- if(current_prolog_flag(dialect, gprolog)).
:- public(grade/2).
:- endif.
```

GNU 上静态谓词默认是 private 的，`clause/2` 读它会抛 `permission_error(access, private_procedure, ...)`。SWI 没这个限制。

### 其它有用的指令

```prolog
:- dynamic(p/1).             % 允许运行时增删子句
:- discontiguous(p/1).       % 允许把子句拆到文件的不同位置（消掉警告）
:- multifile(p/1).           % 允许跨文件累积子句
:- op(700, xfx, ===).        % 自定义运算符
```

`discontiguous` 在本仓库的几个示例里都要用 —— 为了照顾可读性，同一个谓词的子句会分散在不同小节。

### 坑

**条件编译的代码路径要真的都测过**。`:- if(dialect, swi)` 里的分支在 GNU 上永远不会执行 —— 意味着**写错了也不会被发现**。本仓库的做法是每条通道都跑一遍全量，任何一条挂了都会暴露。

---

## 第 21 章 测试与基准（示例 19）

SWI 自带 `plunit`：

```prolog
:- begin_tests(arith).
test(add) :- X is 1 + 1, X =:= 2.
test(fail_case, [fail]) :- 1 =:= 2.
:- end_tests(arith).
```

**GNU 没有 plunit。** 想两边都能跑，就自己写一个最小框架。

### 最小测试框架

核心是把「结局」归一成三种，避免异常把整轮测试带走：

```prolog
outcome(Goal, R) :-
    (   catch((Goal -> R = true ; R = false), E, R = exc(E))
    ->  true
    ;   R = false
    ).
```

四种断言：

```prolog
case(Name, Goal) :-                 % 期望成功
    outcome(Goal, R),
    (   R == true  -> record(Name, pass)
    ;   R == false -> record(Name, fail(goal_failed))
    ;   record(Name, fail(R))
    ).

case_fail(Name, Goal) :-            % 期望失败
    outcome(Goal, R),
    (   R == false -> record(Name, pass)
    ;   record(Name, fail(should_have_failed_but(R)))
    ).

case_eq(Name, Got, Want) :-         % 期望相等（用 ==，不是 =）
    (   Got == Want -> record(Name, pass)
    ;   record(Name, fail(neq(Got, Want)))
    ).

case_throws(Name, Goal) :-          % 期望抛异常
    outcome(Goal, R),
    (   R == true -> record(Name, fail(no_exception))
    ;   R == false -> record(Name, fail(no_exception))
    ;   record(Name, pass)
    ).
```

结果记进动态数据库，最后统一汇总：

```prolog
record(Name, R) :- assertz(case_result(Name, R)).
clear_cases :- retractall(case_result(_, _)).

report :-
    findall(N, case_result(N, pass), Ps),
    findall(N-D, case_result(N, fail(D)), Fs),
    length(Ps, NP), length(Fs, NF),
    format("  通过 ~w，失败 ~w~n", [NP, NF]),
    forall(member(Nm-D2, Fs), format("    [FAIL] ~w —— ~q~n", [Nm, D2])).
```

### 本章的坑（一个真踩过的）

**失败详情必须是「单参数」项。**

```prolog
record(Name, fail(got(Got), want(Want))).    % 错！这是 fail/2
```

而汇总里匹配的是 `findall(N-D, case_result(N, fail(D)), Fs)` —— `fail/1`。`fail/2` 和 `fail/1` 是两个不同的函子，匹配不上，**结果是失败数永远是 0**，测试全绿但其实没测到东西。

正确写法是把详情包成单参数项：

```prolog
record(Name, fail(neq(Got, Want))).
```

**教训：用动态数据库存结构化结果时，函子名和元数必须严格对应**，这类 bug 不会报错，只会静默地丢掉数据。

### 性质测试

不写具体输入输出，写「对所有输入都成立的性质」：

```prolog
rev_twice_is_id(L) :- my_rev(L, R), my_rev(R, L2), L2 == L.
sum_of_range(N)    :- my_numlist(1, N, L), my_sum(L, S), S2 is N * (N + 1) // 2, S =:= S2.

run_property :-
    (   forall(between(0, 40, N),
               ( my_numlist(1, N, L), rev_twice_is_id(L) ))
    ->  format("  [OK] reverse 两次 = 原列表~n", [])
    ;   format("  [FAIL]~n", [])
    ).
```

一次覆盖 N = 0..40 共 41 个输入，比手写十条断言更能抓到边界 bug（N=0、N=1 这类）。

### 基准

**`statistics(runtime, [Ms, _])` 两套引擎都有**，返回整数毫秒：

```prolog
ms(Goal, Delta) :-
    statistics(runtime, [T0, _]),
    ( catch(Goal, _, fail) -> true ; true ),
    statistics(runtime, [T1, _]),
    Delta is T1 - T0.
```

实测结果（800 个元素）：

| 实现 | 耗时 |
|---|---|
| 累加器版 reverse | 1 ms |
| append 拼接版 reverse | 19 ms |

同一件事，差别全在「用不用 `append` 拼接」上。**毫秒数受负载影响，看数量级，别看绝对值。**

### 调试

1. **打点**：在子句里插一句写往 `user_error` 的 `format`，把变量打出来。走 `user_error` 而不是默认输出，方便 `2>err.txt` 单独捞。
2. **`listing/1`**：把谓词的所有子句打出来，看 `clause/2` 视角的程序。**GNU 上要先 `:- public(p/n)`。**
3. **交互式单步**：SWI 的 `gtrace.` / GNU 的 `trace.` 都能单步，但**脚本化运行用不了**，只能靠打点和断言代替。
4. **最小复现**：先把问题缩到一个五秒能跑完的 goal，再查。

---

## 第 22 章 可移植性与综合实战（示例 20）

### 特性探测：`catch` 是最可靠的检测法

```prolog
probe(Name, Goal) :-
    (   catch(once(Goal), _, fail)
    ->  format("  ~w  ->  有~n", [Name])
    ;   format("  ~w  ->  没有~n", [Name])
    ).

?- probe("numlist/3", numlist(1, 3, _)).
  numlist/3  ->  没有          % GNU 上
```

为什么用 `catch` 而不是写死版本号：**谓词存不存在是运行时事实，探测出来的结果永远是真的。**

### 实测出来的差异清单

| 谓词 / 功能 | SWI 10.0.2 | GNU 1.5.0 | 替代方案 |
|---|---|---|---|
| `get_time/1` | ✅ | ❌ | `statistics(runtime, [Ms,_])` |
| `numlist/3` | ✅ | ❌ | 自己写 `my_numlist/3` |
| `writeln/1` | ✅ | ❌ | `format("~q~n", [T])` |
| `atom_number/2` | ✅ | ❌ | `atom_codes` + `number_codes` |
| `term_to_atom/2` | ✅ | ❌ | 手写转换 |
| `gensym/2` | ✅ | ❌ | 自己维护计数器 |
| `atomics_to_string/3`、`atomic_list_concat/2` | ✅ | ❌ | 自己写 `join_atoms/3` |
| `exists_file/1` | ✅ | ❌ | 试着 `open` 一下 |
| `expand_file_name/2` | ✅ | ❌ | — |
| `union/3`、`intersection/3` | ✅ | ❌ | 用 `member` 手写 |
| `aggregate_all/3` | ✅ | ❌ | `findall` + `min_list`/`sum_list` |
| `setup_call_cleanup/3` | ✅ | ❌ | 手写 `with_open/3` |
| `with_output_to/2` | ✅ | ❌ | 写临时文件再读回 |
| `format/1`（单参数） | ⚠️ 重载 | ❌ | 永远写 `format(Fmt, [])` |
| `string` 类型 / dict | ✅ | ❌ | 别用 |
| `module` / `use_module` | ✅ | ❌ | 命名前缀 |
| `plunit` | ✅ | ❌ | 自写测试框架 |
| `clpfd` 的 `ins`/`labeling` | ✅ | ❌ | `fd_domain`/`fd_labeling` |
| `read_term_from_atom/3` | ✅ | ✅ | 直接用 |
| `statistics/2` | ✅ | ✅ | 直接用 |
| `msort/sort/keysort/min_list/max_list/sum_list` | ✅ | ✅ | 直接用 |
| `maplist/include/exclude/foldl` | ✅ | ✅ | 直接用 |
| `findall/bagof/setof/forall` | ✅ | ✅ | 直接用 |
| `reverse/2`、`subtract/3`、`flatten/2`、`prefix/2` | ✅ | ✅ | 直接用 |
| `number_codes/2`、`atom_codes/2`、`char_code/2` | ✅ | ✅ | 直接用 |
| `:- if / :- elif / :- endif` | ✅ | ✅ | 直接用 |

### 封装层（shim）

原则：**有就用、没有就退，不追求功能完整。**

```prolog
% writeln/1：SWI 有，GNU 没有
my_writeln(T) :- format("~q~n", [T]).

% 原子 -> 整数：SWI 有 atom_number/2，GNU 退回 number_codes/2
atom_to_int(A, N) :-
    (   catch(atom_number(A, N), _, fail)
    ->  true
    ;   atom_codes(A, Cs),
        all_digits(Cs), Cs \= [],
        number_codes(N, Cs)
    ).

all_digits([]).
all_digits([C | Cs]) :- C >= 0'0, C =< 0'9, all_digits(Cs).

% 文件是否存在：GNU 没有 exists_file/1，退回「试着打开」
my_file_exists(F) :-
    (   catch(exists_file(F), _, fail)
    ->  true
    ;   catch((open(F, read, S), close(S)), _, fail)
    ).
```

**注意 `my_file_exists` 的坑**：GNU Prolog 里 `file_exists/1` 是个内置谓词（`gplc` 会报 `redefining built-in predicate`），所以封装必须**换一个名字**。这个错误只有走 gplc 通道才会暴露 —— 又一次说明三条通道都要跑。

### 综合实战：词频统计

一个完整的小项目，全程只用公共子集：

```prolog
% 1) 分词：按「非字母」切开
tokenize(Codes, Words) :-
    split_words(Codes, [], RevGroups),
    reverse(RevGroups, Groups),
    % split_words 是头插攒缓冲的，每个分组自己是倒着的，要再翻一次
    findall(W,
            ( member(Cs, Groups), Cs \= [],
              reverse(Cs, CsR),
              downcase_codes(CsR, Lc), atom_codes(W, Lc) ),
            Words).

% 2) 游程压缩：排序后的列表 -> [元素-次数]
rle([], []).
rle([X | Xs], [X-N | Rest]) :-
    take_same(X, Xs, 1, N, Tail),
    rle(Tail, Rest).

% 3) 按频次降序：把计数取负当 key
freq_sorted(Freqs, Sorted) :-
    findall(K-W, (member(W-C, Freqs), K is 0 - C), Pairs),
    keysort(Pairs, Sorted).
```

跑出来：

```
总词数：49
不同词数：36
Top 8：
    prolog  x7
    is  x4
    logic  x2
    not  x2
    programming  x2
    you  x2
```

两个设计点值得记：

1. **`keysort` 只能升序，按频次降序就把计数取负当键。** 这是 Prolog 里的标准技巧。
2. **分词时的 `Cur` 缓冲是头插攒的**，所以每个分组自己是倒着的 —— 忘记 `reverse(Cs, CsR)` 会得到 `golorp` 这种反写的词。**这个 bug 不会报错，只会让你看到一堆乱码**，非常难查。

### 部署

```bash
# 1) 解释执行（开发）
swipl -q -f prog.pl -g main -t halt
gprolog --consult-file prog.pl --entry-goal main

# 2) SWI 编译成字节码可执行文件（prog.pl 需有 :- initialization(main, main).）
swipl -q -o prog -c prog.pl

# 3) GNU 编译成真正的本地可执行文件（无运行时依赖）
{ echo ':- initialization(main).'; cat prog.pl; } > build/entry.pl
cd build && gplc entry.pl -o prog && ./prog
```

`gplc` 出来的二进制**不依赖任何 Prolog 运行时**，可以直接扔到没装 GNU Prolog 的机器上跑。这是 GNU Prolog 相对 SWI 最实际的优势。

---

## 第 23 章 速查表

### 语法

```prolog
% 注释
/* 块注释 */

fact(a, b).                          % 事实
rule(X) :- cond1(X), cond2(X).       % 规则（:- 读作「如果」）
head :- A, B ; C.                    % ; 是「或」，也是 if-then-else 的分隔符

?- goal.                             % 查询（只在交互式里）

[1, 2, 3]                            % 列表
[H | T]                              % 头尾拆分
[]                                   % 空列表（原子！）
'(a)'                                % 带引号的原子
0'a                                  % 字符 a 的码（97）
0'\n                                 % 换行符
'hello world'                        % 含空格的原子
X  _  _X                             % 变量 / 匿名 / 命名但不警告
```

### 一元类型测试

| 谓词 | 说明 |
|---|---|
| `var/1` `nonvar/1` | 是不是自由变量 |
| `atom/1` `number/1` `integer/1` `float/1` | 基本类型 |
| `atomic/1` `compound/1` `callable/1` | 原子或数 / 复合项 / 可调用 |
| `is_list/1` | 是不是合法列表 |
| `ground/1` | 有没有自由变量 |

### 合一与比较

| 写法 | 说明 |
|---|---|
| `X = Y` | 合一（会绑定） |
| `X \= Y` | 不能合一 |
| `X == Y` | 同一性（不绑定） |
| `X \== Y` | 不同一 |
| `X =@= Y` | 结构等价（忽略变量名） |
| `unify_with_occurs_check/2` | 合一 + 发生检查 |
| `X @< Y` 等 | 按标准项序比较 |
| `compare(O, X, Y)` | `O` 得到 `<` / `=` / `>` |

### 算术

| 写法 | 结果 |
|---|---|
| `X is Expr` | 求值并绑定 |
| `1 + 1 =:= 2` | 算术相等 |
| `1 + 1 =\= 2` | 算术不等 |
| `7 / 2` | 3.5 |
| `7 // 2` | 3 |
| `7 mod 2` | 1 |
| `2 ** 10` | 1024.0 |
| `abs/1` `sign/1` `min/2` `max/2` `sqrt/1` `truncate/1` `round/1` `float_integer_part/1` | 常用函数 |

### 控制

| 写法 | 说明 |
|---|---|
| `,` | 合取（与） |
| `;` | 析取（或） |
| `!` | 剪枝，丢弃选择点 |
| `(C -> T ; E)` | if-then-else，`->` 隐含剪枝 |
| `\+ G` | 否定即失败 |
| `once(G)` | 只要第一个解 |
| `call(G, A1, ...)` | 元调用 |
| `forall(G, T)` | 对所有解 `T` 都成立 |
| `repeat` | 无限成功（配合 `!` 用） |

### 常用内置谓词

```prolog
% 列表
length/2  member/2  memberchk/2  append/3  reverse/2  nth0/3  nth1/3
last/2  select/3  permutation/2  subtract/3  flatten/2  prefix/2
sort/2  msort/2  keysort/2  min_list/2  max_list/2  sum_list/2

% 高阶
maplist/2..5  include/3  exclude/3  foldl/4

% 收集
findall/3  bagof/3  setof/3

% 项构造与拆解
functor/3  arg/3  =../2  copy_term/2  term_variables/2  numbervars/3

% 原子与文本
atom_length/2  atom_concat/3  sub_atom/5  atom_codes/2  atom_chars/2
number_codes/2  number_chars/2  char_code/2

% 流
open/3  close/1  read/2  read_term/3  write/2  writeq/2  write_term/3
format/2  format/3  get_code/2  put_code/2  nl/0  nl/1  flush_output/1
at_end_of_stream/1

% 数据库
assertz/1  asserta/1  retract/1  retractall/1  clause/2  listing/1

% 系统
halt/0  halt/1  statistics/2  current_prolog_flag/2  set_prolog_flag/2
catch/3  throw/1
```

### 指令

```prolog
:- set_prolog_flag(double_quotes, codes).    % 跨引擎必写
:- dynamic(p/A).
:- discontiguous(p/A).
:- multifile(p/A).
:- public(p/A).                              % GNU 专用：允许 clause/2 访问静态谓词
:- op(Priority, Type, Name).
:- initialization(Goal).
:- if(Cond). :- elif(Cond). :- else. :- endif.
:- use_module(library(...)).                 % SWI
```

---

## 第 24 章 双引擎坑清单

本仓库写 20 个示例、跑 60 条通道踩出来的坑，按「会不会报错」分类。

### A. 会报错的坑（好查）

| # | 现象 | 原因 | 修法 |
|---|---|---|---|
| 1 | GNU: `syntax error: . or operator expected after expression` | 用了 SWI 专有运算符（如 `ins`），GNU 读文件阶段就炸 | 在 `:- if` **外面**先 `:- op` 声明 |
| 2 | GNU: `exists` 某谓词 / gplc: `Undefined symbols: predicate(numlist/3)` | 用了 SWI 专有谓词 | 自己写，或用 `catch` 探测后退回 |
| 3 | gplc: `fatal error: redefining built-in predicate file_exists/1` | 自定义谓词撞了 GNU 内置名 | 换名字（`my_file_exists`） |
| 4 | GNU: `permission_error(access, private_procedure, ...)` | 用 `clause/2` 读静态谓词 | 加 `:- public(p/n)` |
| 5 | `format/1` 在 GNU 上 `existence_error` | 只写了格式串没给参数 | 永远写 `format(Fmt, [])` |
| 6 | GNU: `quote character expected here` | 用 `\` 续行写长字符串 | 写成一行 |
| 7 | GNU: `syntax error` 在长字符串那一行 | 结尾漏了 `.` | 检查句末 |
| 8 | `fail(got(X), want(Y))` 统计不到 | 函子元数不匹配（`fail/2` vs `fail/1`） | 包成单参数项 |
| 9 | `0''`（撇号字符）在两套上解析不同 | 引号嵌套歧义 | 直接写 `39` |
| 10 | 脚本挂死，输出停在 `| ?-` | 没有 `halt`，或 gplc 出的二进制没有 `:- initialization` | 入口一定 `halt(0/1)` |
| 11 | 判定失败：stderr 非空 | singleton 变量警告 | 一次性变量写 `_X` |
| 12 | `No permission to modify static procedure` | `assertz` 前没声明 `:- dynamic(p/A).` | 加声明 |

### B. 不报错的坑（难查，最要命）

| # | 现象 | 原因 |
|---|---|---|
| 13 | 程序不返回也不报错 | 谓词调用自己（包装谓词和递归谓词重名/同元数） |
| 14 | 字都是反的（`golorp`） | 头插攒缓冲忘了 `reverse` |
| 15 | 测试全绿但没测到东西 | 结果存进动态库时函子元数不匹配 |
| 16 | 无限递归 | 图上搜索忘了 `\+ member(Z, Visited)` |
| 17 | 第一次调用留下两条事实 | 改计数器时忘了 `!` |
| 18 | 搜索顺序乱、慢十倍 | 子句顺序不对，基例写在递归之后 |
| 19 | `bagof` 分支静默消失 | 无解时 `bagof` 失败而不是返回 `[]` |
| 20 | 明明有解却返回 false | 用了 `==` 而不是 `=`，或用了 `=\=` 而不是 `=:=` |

### C. 环境相关的坑

| # | 现象 | 原因 |
|---|---|---|
| 21 | `which pwsh` 找不到 | `/opt/local/bin` 不在默认 PATH，要用绝对路径 `/opt/local/bin/pwsh` |
| 22 | 示例在子目录跑失败 | 相对路径的文件操作（如 `open('xxx.tmp')`）会写到**当前工作目录** |
| 23 | gplc 链接失败 | `gplc` 只在当前目录可靠工作，源文件要先拷到 cwd |
| 24 | Windows 上 `build.ps1` 报「stdout 和 stderr 不能重定向到同一文件」 | `Start-Process` 的限制，要分两个文件 |
| 25 | PowerShell 里 gprolog 通道挂死 | 没重定向 stdin，gprolog 停在 toplevel 等键盘 |

### 一条经验

**每次改动后跑全量三条通道。** 上面 25 条里，第 3、4、5、17 条都只有在特定通道上才会出现 —— 只跑 SWI 或者只跑解释执行，这些坑会一直藏着，直到有人拿 GNU 编译。

---

## 阅读路线

**第一次接触逻辑编程**：第 1–2 章 → 示例 01 → 第 3 章 → 示例 02 → 第 4 章 → 示例 03。到这里你会对「合一 + 回溯」有体感。

**已经会别的语言**：直接第 4 章（项与合一）和第 6 章（算术），这两章是思维转换的关键。

**想快速用起来**：第 7 章（列表）、第 10 章（剪枝）、第 15 章（收集解）—— 覆盖日常 80% 的写法。

**做解析**：第 11–12 章（DCG 两章），从识别器做到完整计算器。

**做规则/推理系统**：第 13 章（动态库）、第 14 章（元编程）。

**写可移植代码**：第 20 章 + 第 22 章 + 第 24 章。这三章是全仓库所有坑的沉淀。

**想验证自己的理解**：拿第 21 章的测试框架，给示例里的谓词补测试。

---

## 附：本仓库的运行方式

```bash
cd /Users/xulun/code/programming/prolog

# 跑全部（20 个示例 × 3 条通道 = 60 项）
./run-all.sh
./run-all.sh -v          # 附完整输出
./run-all.sh 07 15       # 只跑指定编号

# 单跑某个示例
swipl -q -f examples/04-arithmetic.pl -g main -t halt
gprolog --consult-file examples/04-arithmetic.pl --entry-goal main

# 编成本地可执行文件
{ echo ':- initialization(main).'; cat examples/04-arithmetic.pl; } > build/e.pl
cd build && gplc e.pl -o e && ./e
# Windows：gprolog / gplc 命令不适用（无官方 Windows 版）；
# swipl 命令要加 -Dencoding=utf8 和 set_stream 前缀，见第 2 章（脚本已内置）
```

```powershell
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 04-arithmetic.pl
pwsh ./build.ps1 -All -Verbose
pwsh ./build.ps1 -Clean
```

判定标准（三条通道共用）：退出码 0、stderr 为空、stdout 含 `==== NN 结束 ====`。
