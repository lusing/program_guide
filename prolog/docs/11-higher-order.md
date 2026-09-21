# 11 · 高阶谓词与元调用

> 对应示例：[`examples/11_higher_order/11_higher_order.pl`](../examples/11_higher_order/11_higher_order.pl)

## 11.1 `call/1`：目标是项

**谓词就是项，所以可以当参数传** —— 这就是 Prolog 的高阶谓词。整个机制只需要一个谓词：

```text
  G = member(a,[a,b])  call(G)  成立
  call((member(X,[1,2,3]), X>1))  X 的取值 = [2,3]
  换句话：目标不只是「代码」，它同时是「可以运算的数据」。
  这一条让「写一个引擎」变得可行（第 12、24 章）。
```

```prolog
G = member(a, [a, b]),
call(G).                       % 等价于直接写 member(a,[a,b])

G2 = (member(X, [1,2,3]), X > 1),
findall(X, call(G2), L2).      % L2 = [2,3]
```

`call/1` 收一个**目标项**并执行它。注意第二行：**合取（`,`）本身也是一个项**（`','/2`），
所以整个复合条件能装进一个变量。

**Prolog 里「代码」和「数据」是同一套东西** —— 这一条是整门语言最有威力的性质，也是
「用 Prolog 写 Prolog 解释器只要十行」的原因（12 章、24 章）。

## 11.2 `call/N`：闭包

```text
  C = plus(3), call(C, 4) -> 7
  对 5 分别施加 +10/+20/+30：[15,25,35]
  对 10 分别做 scale(2)/scale(3)：[20,30]
  闭包 = 「谓词名 + 部分实参」打包成的项。
```

```prolog
plus(A, B, C) :- C is A + B.
scale(K, X, Y) :- Y is K * X.

C = plus(3),                   % 「还差一个参数的 plus」—— 这就是闭包
call(C, 4, R).                 % R = 7

% 闭包可以放进列表，做成「策略表」
findall(R, ( member(C, [plus(10), plus(20), plus(30)]), call(C, 5, R) ), Rs).
% Rs = [15,25,35]
```

**`call/N` 把额外参数追加到闭包后面。** `call(plus(3), 4, R)` 等价于 `plus(3, 4, R)`。

等价于函数式语言里的 **partial application**，但 **Prolog 不需要 lambda** —— 因为
`plus(3)` 本身就是一个合法的项，直接写就行。

> **只能补「前若干个」参数，不能只补后面的。** `call` 是把新参数**追加到尾部**，所以
> `plus(3)` 补出来的是「第一个参数已定」的 plus。想固定第二个参数得另写一个谓词，或者用
> `=..` 手工组装（11.6）。
>
> **实践含义**：写库时习惯把**「配置参数」放前面、**「数据参数」放最后** —— 这样调用方
> 才能用闭包预置配置。本教程所有高阶谓词都遵守这条约定。

## 11.3 `maplist/2` 与 `maplist/3`

```text
  maplist(sq, [1,2,3,4])    = [1,4,9,16]
  maplist(in_range, [2,3,4]) 全部满足 -> 成立
  maplist(in_range, [1,9])   有元素不满足 -> 失败
  maplist/2 是「全部满足」语义：任何一个元素失败，整体就失败。
  它不产生部分结果，所以别指望它做 filter —— filter 用下面的 partition。
  maplist/3 要求两个列表等长，长度不一致直接失败
```

| 形式 | 语义 |
|---|---|
| `maplist(P, L)` | `P/1` 对每个元素成立；**全部满足才成功**（不是 filter！） |
| `maplist(P, L1, L2)` | `P/2` 逐元素作用，**要求等长** |
| `maplist(P, L1, L2, L3)` | 三元，`maplist/2..5` 两套引擎都有 |

两个容易搞错的地方：

- **`maplist/2` 不是 `filter`。** 它对每个元素调用 `P`，任何一个失败整个就失败，**不产生
  部分结果**。要过滤用 `include/3` / `exclude/3`（SWI 有，GNU 没有 → 自己写 `partition`）。
- **`maplist/3` 要求等长**，长度不一致直接失败（不报错）。

```prolog
sq(X, Y) :- Y is X * X.
in_range(X) :- X >= 2, X =< 4.

?- maplist(sq, [1,2,3,4], L).        L = [1,4,9,16]
?- maplist(in_range, [2,3,4]).       true
?- maplist(in_range, [1,9]).         false
?- maplist(sq, [1,2], [1,4,9]).      false     % 长度不一致
```

`maplist/3` 还有个好用的副产品：**`maplist(=(x), L)` 检查列表是否全是 `x`**
（`=` 也是谓词，`maplist(=(x), L)` 就是「每个元素都等于 x」）。

## 11.4 手写 `foldl` / `partition` / `zip`

```text
  my_foldl(+, [1,2,3,4], 0)  = 10
  my_partition(2=<X=<4, [1..5])  满足 = [2,3,4]，不满足 = [1,5]
  my_zip([a,b,c],[1,2,3])    = [a-1,b-2,c-3]
  my_foldl(+, [1,2,3], 100)  = 106（初值可任意）
  注意三个手写版的共同点：递归骨架完全一样，只有 call(P, ...) 那行不同。
```

```prolog
my_foldl(_, [], Acc, Acc).
my_foldl(P, [H | T], Acc, R) :-
    call(P, H, Acc, Acc1),
    my_foldl(P, T, Acc1, R).

my_partition(_, [], [], []).
my_partition(P, [H | T], Yes, No) :-
    (   call(P, H)
    ->  Yes = [H | YT], No = NT
    ;   Yes = YT, No = [H | NT]
    ),
    my_partition(P, T, YT, NT).

my_zip([], [], []).
my_zip([A | As], [B | Bs], [A - B | Ps]) :- my_zip(As, Bs, Ps).
```

**这三个手写版的递归骨架完全一样，只有 `call(P, ...)` 那一行不同。**
把「怎么遍历」和「对元素做什么」分开，就是高阶谓词的全部价值。

`my_partition` 用 `(C -> T ; E)` 而不是 `\+ C`，是因为前者**能保留 `H` 的绑定**（10 章）——
写 `filter` 类谓词时这是必须的。

`foldl` 的初值可以任意：`my_foldl(+, [1,2,3], 100, R)` 得 `106`。所以同一个 `foldl` 既能
求和（初值 `0`）、也能求积（初值 `1`）、还能拼字符串（初值 `[]`）。

> **内建的 `foldl/4`、`include/3`、`exclude/3` 只有 SWI 有**，GNU Prolog 没有 ——
> 这就是为什么本章三个都要手写。手写版还有个附带好处：**你知道它每一步在干什么**，
> 遇到栈溢出或者非确定性行为时能自己分析。

## 11.5 `forall/2`：全部满足的判定器

```text
  forall(member(X,[2,3,4]), X>1)  成立
  forall(member(X,[2,3,4]), X>3)  不成立
  forall(Cond, Action) 在 ISO 里等价于 \+ (Cond, \+ Action)：
  只要有一个 Cond 解让 Action 不成立，整个 forall 就失败。
  它是「全部」语义的判定器，不产生新解 —— 判定用的首选。
  用 forall 打印一行一个元素：
    1
    2
    3
```

```prolog
forall(Cond, Action)  ≡  \+ ( Cond, \+ Action )
```

只判断真假，**不收集解**，内部绑定也不传出来。它是「判定」场景的首选，因为：

- **不占内存**（`findall` 会把所有解收进列表）；
- **短路**：发现一个反例立刻失败，不用把 `Cond` 全部枚举完。

```prolog
% 打印每个元素 —— forall 最常用的「副作用驱动」写法
forall(member(X, [1,2,3]), format("  ~w~n", [X])).
```

**注意 `forall` 的 `Action` 必须对每个解都成立**，所以如果只想「对满足条件的解做某事」，
必须把条件并进 `Cond`，或者用 `(Cond -> ... ; true)` 兜底（03 章踩过这个坑）。

## 11.6 `=..` 造目标 + `call`：Prolog 版反射

```text
  Goal =.. [plus,3,9]  ->  call(Goal, R)  R = 12
  这是 Prolog 版的「反射」：谓词名来自变量、参数来自列表，
  组合成目标再执行。配置驱动的解释器就靠这一手（第 24 章）。
```

```prolog
Goal =.. [plus, 3, 9],        % 从列表装出一个目标项
call(Goal, R).                % R = 12
```

**谓词名可以来自变量、参数可以来自列表，组合成一个目标再执行。** 这是 Prolog 版的
「反射」，用途很广：

- **派发表**：`op_table(Name, Impl)` 存下「名字 → 实现」，运行时查表调用（12 章）。
- **配置驱动**：把「要跑什么」写成数据，程序只负责解释它。
- **跨引擎调用**：绕过 `gplc` 的静态链接（21 章、22 章）。
- **解释器**：24 章的迷你语言解释器把 AST 变成目标再 `call`。

```prolog
% 抽象一点的通用写法
mcall(Name, Args) :- Goal =.. [Name | Args], call(Goal).
```

> **`call/1` 的第一个参数必须是可调用的项。** `call(X, 5)` 里 `X` 还是自由变量时会抛
> `instantiation_error`。想「先挂起来、以后再确定」是不行的 —— **Prolog 的调用是即刻的**。
>
> 要「以后再说」，就用**闭包项**（`call(Goal, Arg)` 里的 `Goal` 已经是个具体的项）或者
> 退化成「数据 → 目标」的 `=..` 组装。

## 11.7 坑位清单

1. **`call(X)` 里 X 未绑定** → `instantiation_error`。调用是即刻的。
2. **`maplist/2` 当 `filter` 用** → 它只给真假，不给部分结果。用 `include/3` 或手写
   `partition`。
3. **`maplist/3` 两个列表长度不一致** → 直接失败，不报错。
4. **想只预置后面的参数** → `call/N` 只能往后追加。预置靠闭包项（`plus(3)`），只能补前面。
5. **`my_filter` 里用 `\+ call(P,H)`** → 绑定丢了。用 `(C -> T ; E)`。
6. **`forall/2` 的 Action 对部分解失败** → 整句静默失败，看起来像「什么都没做」。
7. **`findall` 求 `Template` 的值** → 它只实例化不求值（06 章）。
8. **`=..` 组装目标后忘了 `call`** → 只是造了个项，什么都没执行。
9. **闭包参数顺序随意** → 配置参数要放前面，否则没法用闭包预置。
10. **忘了 `foldl` 的初值语义** → 求和用 `0`、求积用 `1`、拼列表用 `[]`，初值错了结果全错。

---

上一章：[10 · 剪枝与否定](10-cut.md) · 下一章：[12 · 元编程](12-metaprogramming.md)
