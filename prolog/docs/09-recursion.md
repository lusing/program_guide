# 09 · 递归、累加器与尾调用

> 对应示例：[`examples/09_recursion/09_recursion.pl`](../examples/09_recursion/09_recursion.pl)

## 9.1 结构性递归：数据长什么样，代码就长什么样

```text
  sum_list_rec([1,2,3,4,5]) = 15
  max_list_rec([3,9,2,7])   = 9
  规律：一个子句处理 []，一个子句处理 [H|T] 并递归 T。
  90% 的列表谓词都是这个骨架（第 08 章已经见过 append/reverse）。
```

```prolog
sum_list_rec([], 0).
sum_list_rec([H | T], S) :-
    sum_list_rec(T, S0),
    S is S0 + H.

max_list_rec([X], X).
max_list_rec([H | T], M) :-
    max_list_rec(T, M0),
    M is max(H, M0).
```

**这个骨架值得刻在脑子里**：一个子句处理空表（基例），一个子句处理 `[H|T]`（拆一个
元素、递归剩下的）。`append/3`、`reverse/2`、`length/2`、`map`、`filter`、`fold` 全是它。

注意 `max_list_rec` 的基例是 `[X]` 而不是 `[]` —— **空表的「最大值」没有意义**，所以干脆
不给空表子句，`max_list_rec([], M)` 直接失败。这是「用失败表达不适用」的范例。

## 9.2 数值递归：怎么把规模缩小

```text
  fact(10)          = 3628800
  fib(10)           = 55
  gcd_rec(1071,462) = 21
  fib/2 有两处递归调用，调用树是二叉的 —— 指数复杂度。
```

```prolog
fact(0, 1).
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F0), F is N * F0.

fib(0, 0).
fib(1, 1).
fib(N, F) :-
    N > 1, N1 is N - 1, N2 is N - 2,
    fib(N1, F1), fib(N2, F2),
    F is F1 + F2.

gcd_rec(X, 0, X) :- X > 0.
gcd_rec(X, Y, G) :- Y > 0, R is X mod Y, gcd_rec(Y, R, G).
```

三点：

- **数值递归必须显式写守卫**（`N > 0`、`Y > 0`）。没有它，`N1 is N - 1` 会一路减到负数
  **永不终止**。列表递归天然有 `[]` 当终点，数值递归没有 —— 所以守卫是必须的。
- **`fib/2` 有两处递归调用，调用树是二叉的**：`fib(30)` 要算 200 多万次。
  **指数复杂度**是这个写法的固有代价，正好用来对照下一节的线性版本。
- **`gcd_rec` 的递归调用在最后一个目标**，它已经是尾递归了 —— 好算法天然是尾递归的。

## 9.3 尾递归与累加器

```text
  fib_acc(10) = 55
  sum_acc    = 15
  尾递归版本里，递归调用是子句的最后一个目标，前面没有任何
  「等它回来还要做」的活儿。引擎于是可以复用栈帧。
  代价：多了一个累加器参数；收益：O(1) 栈深，可以处理很长的列表。
  判定标准很简单：递归调用后面还有别的目标吗？有就不是尾递归。
```

```prolog
% 非尾递归：递归调用之后还要做乘法，栈帧不能扔
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F0), F is N * F0.

% 尾递归：递归调用是最后一步
fib_acc(N, F) :- fib_acc(N, 0, 1, F).
fib_acc(0, A, _B, A).
fib_acc(N, A, B, F) :-
    N > 0, N1 is N - 1, C is A + B,
    fib_acc(N1, B, C, F).

sum_acc(L, S) :- sum_acc(L, 0, S).
sum_acc([], Acc, Acc).
sum_acc([H | T], Acc, S) :- Acc1 is Acc + H, sum_acc(T, Acc1, S).
```

**判定标准一句话：递归调用后面还有别的目标吗？有就不是尾递归。**

尾递归在 Prolog 里的意义比别的语言更大：SWI 与 GNU 都做**尾调用优化（LCO）**，尾递归谓词
的栈占用是**常数**的，能处理几万层的列表；非尾递归版会在几千层时栈溢出。

`sum_acc` 那条只有一个目标的子句体尤其漂亮 —— 它把「加法」这件事在**往下走的时候**就
做掉了，而不是等递归回来再做。

> **包装谓词和递归谓词必须换名字。** 这是本教程最想让你记住的一条工程教训：
>
> ```prolog
> sum_acc(L, S) :- sum_acc(L, 0, S).        % 灾难：sum_acc/2 调用自己，无限递归
> ```
>
> 正确写法是让**元数不同**（`sum_acc/2` 是包装、`sum_acc/3` 是递归），像上面的示例那样。
> 注意「名字相同、元数也不同」在这里恰好安全 —— **因为 `sum_acc/2` 和 `sum_acc/3` 是两个
> 不同的谓词**（04 章）。真正的死循环来自「名字和元数都相同」的自我调用。
>
> 这类错误的表现是「程序不报错但永远不返回」，定位时优先怀疑它。

## 9.4 互递归

```text
  even_odd(7)  = odd
  even_odd(10) = even
  eval(add(2, mul(3,4))) = 14
  互递归在语法分析里是主力：表达式 → 项 → 因子 → 表达式…（第 19 章）。
```

```prolog
even_odd(0, even).
even_odd(N, R) :- N > 0, N1 is N - 1, even_odd(N1, R0), flip(R0, R).

flip(even, odd).
flip(odd, even).
```

互递归（mutual recursion）就是「A 调 B、B 调 A」。这里 `even_odd` 调 `flip`，而真正的
互递归形态是解析器：

```prolog
eval(add(A, B), V, []) :- !, eval_expr(A, VA, []), eval_expr(B, VB, []), V is VA + VB.
eval(mul(A, B), V, []) :- !, eval_expr(A, VA, []), eval_expr(B, VB, []), V is VA * VB.
```

`eval_expr` 遇到 `add` 时又去调 `eval_expr` —— 这就是「表达式 → 子表达式 → 表达式」的
互递归。**19 章的 DCG 版本会把这个结构写得非常清楚**（`expr → term → factor → expr`），
那里也是运算符优先级的实现方式。

## 9.5 树递归

```text
  中序遍历（应有序） = [1,3,4,5,8,9]
  求和               = 30
  深度               = 3
  树就不是「一个子句配一个元素」了，而是「每棵子树各递归一次」。
```

二叉树用 `nil | t(Left, Value, Right)` 表示 —— **没有类，没有指针，就是一个普通项**：

```prolog
tree_insert(nil, X, t(nil, X, nil)).
tree_insert(t(L, V, R), X, t(L2, V, R)) :- X @<  V, tree_insert(L, X, L2).
tree_insert(t(L, V, R), X, t(L, V, R2)) :- X @>= V, tree_insert(R, X, R2).

tree_inorder(nil, []).
tree_inorder(t(L, V, R), Ls) :-
    tree_inorder(L, LL),
    tree_inorder(R, RL),
    append(LL, [V | RL], Ls).          % 左 + 根 + 右
```

注意 `tree_insert/3` **不是「原地插入」**，它是「插入并返回一棵新树」：

```prolog
tree_from_list(L, T) :- tree_from_list(L, nil, T).      % 累加器式建树
tree_from_list([], T, T).
tree_from_list([H | T], Acc, R) :-
    tree_insert(Acc, H, Acc1),
    tree_from_list(T, Acc1, R).
```

**Prolog 里没有「修改」，只有「算出新值」**（05 章）—— 这和 Elixir/Haskell 一样，和 C 系
语言完全不同。所以数据结构都写成「传入旧结构、传出新结构」的形式。

`X @< V` / `X @>= V` 用的是**标准项序**（04 章），不是算术比较 —— 这样这棵树能装任意项
（字符串、复合项），不只是数字。

## 9.6 递归 + 回溯 = 搜索

```text
  图里有环，直接 path(a,e,L) 会无限绕下去（L 一直变长），
  所以必须先限定路径长度 —— 这是 Prolog 搜索的常见护栏：
  顶点数恰好为 3 的路径：[[a,d,e]]
  递归负责「往前走」，回溯负责「走不通就退回来换一条」——
  这两件事加起来就是搜索算法，不需要显式维护栈。
  工程上还要加 visited 集合去环（第 24 章会给一个完整版）。
```

```prolog
edge(a, b). edge(b, c). edge(c, d). edge(a, d).
edge(d, e). edge(e, a).                 % 注意 e → a 形成环

path(X, X, [X]).
path(X, Z, [X | T]) :-
    edge(X, Y),                          % 生成器：选择下一条边
    path(Y, Z, T).                       % 递归 + 回溯
```

**递归负责「往前走」，回溯负责「走不通就退回来换一条」—— 这两件事加起来就是深度优先
搜索，不需要显式维护栈。** 这是 Prolog 相对于命令式语言最核心的表达力优势。

但代价是：**有环的图会无限绕下去**（`L` 一直变长，`path(a,e,L)` 永不返回）。两种护栏：

```prolog
% 护栏 1：限定路径长度
findall(L, ( length(L, 3), path(a, e, L) ), Ls).

% 护栏 2：维护 visited，防重复访问
reach(X, Y) :- reach(X, Y, [X]).
reach(X, Y, _) :- edge(X, Y).
reach(X, Y, Visited) :-
    edge(X, Z),
    \+ member(Z, Visited),               % 关键：不能省
    reach(X, Y, [Z | Visited]).
```

**`length/2` 限长是更通用的护栏**：它把「无限搜索」变成「有限搜索」，代价是你得先知道
答案的形状。**「生成器 + 限长」是 Prolog 里避免无限搜索的常规手段**（08 章、23 章都用到）。

## 9.7 坑位清单

1. **数值递归忘守卫** → 减到负数永不终止。列表递归有 `[]` 兜底，数值递归要自己写。
2. **包装谓词与递归谓词同名同元数** → 自我调用，不报错也不返回。换名字或换元数。
3. **子句顺序随意** → 影响搜索顺序与性能；基例一般写前面（`even_odd(0, even)` 在
   `N > 0` 的子句之前）。
4. **`fib/2` 当高效实现** → 指数复杂度。要快就上累加器版或记忆化（17 章）。
5. **以为 `tree_insert` 会改原树** → 它返回新树。这里正是「不可变」最容易被误用的地方。
6. **图搜索不加护栏** → 有环就无限递归。`length/2` 限长或 visited 集合二选一。
7. **`\+ member(Z, Visited)` 忘了** → 有环图无限递归。
8. **用 `@<` 和 `<` 混着写** → 前者是项序（能装任意项），后者是算术（只对数字）。树里
   用 `@<` 才能装非数字。
9. **`tree_inorder` 里用 `append` 拼接** → 每个节点一次 `append`，整体 O(n²)。大树上改用
   差异列表（09.5 的累加器思路的推广）。

---

上一章：[08 · 列表](08-lists.md) · 下一章：[10 · 剪枝与否定](10-cut.md)
