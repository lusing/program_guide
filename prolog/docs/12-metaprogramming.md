# 12 · 元编程：把程序当数据处理

> 对应示例：[`examples/12_metaprogramming/12_metaprogramming.pl`](../examples/12_metaprogramming/12_metaprogramming.pl)

## 12.1 为什么 Prolog 的元编程特别顺

别的语言里，「程序」和「数据」是两种东西：想操作代码，得先把它解析成 AST；想执行数据，
得先把它编译成函数。Prolog 没有这道墙 —— **程序本身就是项（term）**，
所以分析、构造、改写、执行程序和处理普通数据用的是同一套工具：

```text
functor(f(a,[1,2],g(x)), N, A)  -> N = f，A = 3
arg(1/2/3, T, X)  -> a / [1,2] / g(x)
T =.. L  ->  L = [f,a,[1,2],g(x)]
L =.. [h,1,2,3]  ->  h(1,2,3)
整数 5 的 univ 结果  ->  [5]
```

三组工具，各管一段：

| 用途 | 谓词 |
|---|---|
| **解剖**一个项 | `functor/3` `arg/3` `=../2`（univ）`copy_term/2` `term_variables/2` |
| **判定**类型 | `var/1` `nonvar/1` `atom/1` `number/1` `compound/1` `atomic/1` `callable/1` `is_list/1` `ground/1` |
| **执行**一个项 | `call/1..N`（11 章）+ 动态数据库 `assert/retract/clause` |

## 12.2 解剖项：名字、元数、参数

```prolog
T = f(a, [1, 2], g(x)),

functor(T, Name, Arity),        % Name = f, Arity = 3
arg(1, T, A1),                  % A1 = a         —— 下标从 1 开始！
arg(2, T, A2),                  % A2 = [1,2]

T =.. Parts,                    % Parts = [f, a, [1,2], g(x)]
Built =.. [h, 1, 2, 3],         % Built = h(1,2,3)
```

`=..`（念作 **univ**）是「项 ↔ 列表」的双向桥：`[F|Args]` 的头上是函子、尾巴是全部实参。
它是**通用**遍历的基础 —— 见 12.4。

两个坑：

- **`arg/3` 的下标从 1 开始**，而列表的 `nth0`/`nth1` 是两套并存。这是 Prolog 里最容易记混的
  一对（08 章提过）。
- **原子与整数的 univ 结果是「只含自己」的单元素列表**：`5 =.. L` 得 `L = [5]`。所以处理 univ
  结果时要先判 `[F]`（零元）还是 `[F|Args]`（有元）。

> **`[]` 的类型判定不可移植。** SWI 里 `atom([])` **为假**，GNU 里 **为真** —— 所以千万别拿
> `atom/1` 判「是不是空列表」。判空请用 `length(L, 0)`，两套引擎一致。

## 12.3 类型判定：没有类型声明，但有类型判定

Prolog 是动态类型语言，但每个项在运行期都有明确的类型，而且**类型判定是谓词**，
可以直接写进条件里：

```prolog
what_cat(Var, Cat) :-
    (   var(Var)       -> Cat = var
    ;   number(Var)    -> Cat = number
    ;   atom(Var)      -> Cat = atom
    ;   compound(Var)  -> Cat = compound
    ;   Cat = other
    ).
```

```text
未绑定变量  -> var
整数 42  -> number
浮点 3.5  -> number
原子 foo  -> atom
列表 [1,2]  -> compound
复合项 f(a)  -> compound
callable(f(a))     成立 —— 这个项可以当目标调用
ground(f(a,1))     成立 —— 不含未绑定变量
ground(f(a,_))     不成立 —— 含未绑定变量
```

注意 **`number/1` 把整数和浮点统称为 `number`**；**列表也是 `compound`**（它是 `'.'/2`）。
`callable/1` 和 `ground/1` 是最常用的两个，分别问「能当目标调吗」和「有未绑定变量吗」。

`ground/1` 是安全性判定的主力：**要 `assert` 一条事实、要写文件、要走网络之前，
先 `ground` 一下**，能挡掉「变量泄漏到全局」这类难查的 bug。

## 12.4 改写程序：手写版 vs 通用版

目标：把算术表达式里每个数字乘 2，结构原封不动。

**手写版** —— 每遇到一个运算符就得补一个子句：

```prolog
double_hand(N, N2) :- number(N), !, N2 is N * 2.
double_hand(A + B, A2 + B2) :- !, double_hand(A, A2), double_hand(B, B2).
double_hand(A * B, A2 * B2) :- !, double_hand(A, A2), double_hand(B, B2).
double_hand(X, X).
```

**通用版** —— 用 `=..` 拆开、递归改参数、再拼回去：

```prolog
double_gen(N, N2) :- number(N), !, N2 is N * 2.
double_gen(T, T2) :-
    compound(T),
    !,
    T =.. [F | Args],
    double_list(Args, Args2),
    T2 =.. [F | Args2].
double_gen(X, X).
```

```text
手写版 1+2*3 -> 2+4*6（值 26）
通用版 1+2*3 -> 2+4*6（值 26）
通用版 f(g(1),2,[3,x]) -> f(g(2),4,[6,x])
```

**通用版加运算符不用改代码。** 这也正是它的适用范围远大于手写版的原因：写解释器、编译器、
代码生成器全靠它。代价是**每次都要 `=..` 拆装，慢一点**；性能敏感的路径上，手写版反而更好。
所以两者都常用，别迷信「通用」。

## 12.5 动态数据库：把事实当成可变状态

普通子句是编译期固定的，`assert`/`retract` 让它在运行期可变：

```prolog
:- dynamic(item/2).

assertz(item(apple, 3)),
assertz(item(pear, 5)),
assertz(item(plum, 2)),
findall(N-Q, item(N,Q), All),          % [apple-3, pear-5, plum-2]

once(retract(item(pear, _))),          % 删一条
retractall(item(plum, _)),             % 一次删干净
```

一条极其重要的不对称：

- **`retract/1` 会留下选择点** —— 它「成功地删掉了第一条，但还可以回溯再删下一条」。
  只想删一条必须加 `once/1` 或 `!`，否则后续回溯会把剩下的同名事实也删掉。
- **`retractall/1` 一次删干净，永远成功**（哪怕一条都没有），不留选择点。

**`clause/2` 看子句的头与体** —— 这是运行期反射：

```prolog
assertz((cheap(X) :- item(X, Q), Q < 4)),
clause(cheap(X), Body),                % Body = item(A, B), B < 4
```

注意 `Body` 打印出来是 `item(A,B),B<4`，其中的变量是**未绑定的新变量**（`clause/2` 给的是
一个「可用的副本」而不是原来那个子句）。要打印得好看就配 `numbervars/3`。

> **`:- dynamic(p/2).` 是「标记」，不是「执行」。** 不加这句也能 `assertz`（SWI 默认允许），
> 但引擎会**警告**，而且 SWI 无法为它做 JIT 优化。**GNU Prolog 的写法必须带括号**
> （`:- dynamic(item/2).`），因为 GNU 不把 `dynamic` 定义成前缀运算符 —— 写成
> `:- dynamic item/2.` 是**语法错误**（22 章）。
>
> **`assert`/`retract` 有副作用、不可回溯**（17 章细讲）。它们和 Prolog 的「逻辑」性格是冲突的，
> 所以能不用就不用：优先 `findall` 收集 + 纯递归处理。

## 12.6 `copy_term/2` 做模板

`copy_term/2` 把一个项**原样复制**一份，两份的变量**互不共享**：

```prolog
Template = rule(_Who, _Action),
copy_term(Template, I1),
I1 = rule(tom, run).
```

```text
模板照旧          rule(A,B)
实例化后的副本    rule(tom,run)
```

**为什么需要它**：`Template` 里的 `_Who`/`_Action` 如果直接拿去实例化，绑定会**反向污染**
模板本身 —— 下一次用就变成「已经填过的」了。`copy_term` 拿一份干净副本，模板永远保持
「空槽」状态。

这是第 24 章前向推理引擎的关键：**规则要被反复套用到不同的已知事实上**，如果规则变量被
上一次的匹配绑死，推理就错了。

## 12.7 坑位清单

1. **`atom([])` 拿来做类型判断** → SWI 假、GNU 真。判空用 `length(L, 0)`。
2. **`arg/3` 下标当 0 基** → 它是 **1 基**，和 `nth0` 不一样。
3. **`=..` 结果按 `[F|Args]` 硬拆** → 原子/整数的结果是**单元素列表** `[5]`，尾是 `[]`。
4. **`retract/1` 不加 `once`** → 回溯时把同名事实全删了。
5. **以为 `retractall` 会失败** → 它**永远成功**（哪怕没删到东西），别拿它做「存在性判断」。
6. **`clause/2` 拿到的 `Body` 变量当作原变量** → 它是副本，绑定不回传。
7. **`assertz` 一个含自由变量的子句** → 变成「万能匹配」的坑，先 `ground/1` 检查。
8. **`:- dynamic item/2.` 不带括号** → GNU 语法错误。
9. **通用改写版用在热点路径** → `=..` 有开销，性能敏感处手写版更合适。
10. **`format` 里直接塞 `%`** → GNU 把 `%` 当格式说明符（22 章），内容要用 `~s` 参数传。

---

上一章：[11 · 高阶谓词与元调用](11-higher-order.md) · 下一章：[13 · 解集收集](13-all-solutions.md)
