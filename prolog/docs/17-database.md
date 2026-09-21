# 17 · 动态数据库

> 对应示例：[`examples/17_database/17_database.pl`](../examples/17_database/17_database.pl)

## 17.1 增删改查

动态数据库是**子句在运行期可改**的那部分。四个操作：

| 操作 | 语义 | 失败吗 |
|---|---|---|
| `assertz(F)` | 把 `F` 加到**末尾** | 永成功 |
| `asserta(F)` | 把 `F` 加到**开头** | 永成功 |
| `retract(F)` | 删掉**第一条**匹配的 | 没有匹配就**失败** |
| `retractall(F)` | 删掉**所有**匹配的 | **永成功** |

```prolog
assertz(edge2(a,b)), assertz(edge2(b,c)), assertz(edge2(c,d)),
findall(X-Y, edge2(X,Y), E1),        % [a-b, b-c, c-d]

asserta(edge2(z,a)),                 % 插到最前面
findall(X-Y, edge2(X,Y), E2),        % [z-a, a-b, b-c, c-d]

once(retract(edge2(z,_))),           % 删第一条匹配（用 once 只删一条）
retractall(edge2(b,_)).              % 一次删干净
```

```text
assertz 三条后     [a-b,b-c,c-d]
asserta(z,a) 后    [z-a,a-b,b-c,c-d]
retract(edge2(z,_))   成功
retract 不存在的事实  失败（和查库一样，没有就是失败）
retractall(b,_) 后 [a-b,c-d]
```

**`asserta` 与 `assertz` 的顺序差别有语义后果** —— 因为 Prolog 子句是**顺序敏感**的
（第一个匹配的赢，10 章讲过剪枝）。往开头插就是在「抢先」。

> **`retract/1` 会留下选择点**（它还能删下一条）。只想删一条就 `once(retract(...))` 或
> `retract(..), !`。
>
> **`retractall/1` 永远成功**，哪怕一条都没删到 —— **别拿它做「存在性判断」**。
> 要判断存在用 `current_predicate/1` 或先 `findall` 看长度。

## 17.2 副作用不参与回溯：最容易踩的坑

这是本章的核心概念，理解它才算会用动态数据库：

```prolog
(   member(X, [1,2,3]),
    assertz(log_(X)),
    X > 1,              % X = 1 时这里失败
    fail
;   true
),
findall(X2, log_(X2), L).
```

```text
记录到的是 [1,2,3]
```

**`X = 1` 那一轮逻辑上「失败了」，但它 `assertz` 进去的 `log_(1)` 照样留在库里。**

> **Prolog 回溯时会撤销绑定，但不会撤销副作用。**

这条规则有两个方向的重要性：

**正面** —— 「在循环里用 `assert` 累加」能工作，因为它**本来就期望不被撤销**。
动态库是 Prolog 里少数几个能「攒东西」的地方（另一个是 `findall` 的列表参数）。

**负面** —— **一个「失败」的查询可能已经改了数据库。** 这句话的实践含义是：

```prolog
% 危险：这个查询可能失败，但数据库已经被改了
process_all :- forall(item(X), (handle(X), assertz(done(X)))).
```

如果 `handle(X)` 在某个 `X` 上失败，`done(X)` 之前那些**已经写进去了**。
**要做事务性操作，只能自己写「失败时回滚」的逻辑。**

对比：`X = 1`、`member(X, [1,2])` 这类**绑定**在回溯时会被撤销（06 章）。

## 17.3 用动态库写「可变变量」

Prolog 没有可变变量。真要可变，**就用动态库里的一个事实当变量**：

```prolog
bump :-
    retract(counter(N)),        % 读出来
    N1 is N + 1,                % 算新的
    assertz(counter(N1)).       % 写回去

count_up(Target, Final) :-
    retractall(counter(_)),
    assertz(counter(0)),
    repeat,
    counter(C),
    (   C >= Target
    ->  !                       % 到目标就跳出循环，砍掉 repeat 的选择点
    ;   bump,
        fail                    % 否则加点数、回溯再来
    ),
    counter(Final).
```

```text
count_up(5)   -> 5
count_up(100) -> 100
循环结束后库里剩下的计数器 = 3
```

**`repeat` + `retract`/`assert` + `!` 是 Prolog 唯一的「命令式循环」写法：**

> `repeat` 制造一个无限的选择点 → 每轮做一步 → 条件成立就 `!` 砍掉选择点跳出，
> 否则 `fail` 回溯到 `repeat` 重来。

`retract`+`assertz` 这个「读-改-写」三件套就是**可变变量的标准实现**（GNU 的 fd 变量虽然也叫
「变量」，但那是约束变量，不是可变状态）。

> **能用递归就别用这种写法** —— 它慢、难读、还会污染全局状态。
>
> **真正需要它的场景**：**状态要在多个谓词之间共享，递归参数传不动。** 比如
> 「解析过程中累积符号表」这种横跨好几层递归的需求。
>
> 顺带注意：`count_up/2` **不是可重入的** —— 它依赖那个全局的 `counter/1` 事实，
> 嵌套调用会互相踩。这是全局状态的通病。

## 17.4 记忆化：动态库最漂亮的应用

朴素 `fib` 是 O(2ⁿ)；把算过的结果缓存进动态库，立刻降到 O(n)：

```prolog
memo_fib(N, F) :-
    (   fib_cache(N, Cached)        % 缓存命中？
    ->  F = Cached
    ;   fib_compute(N, F),          % 没命中：真算
        assertz(fib_cache(N, F))    % 存起来
    ).

fib_compute(0, 0) :- !.
fib_compute(1, 1) :- !.
fib_compute(N, F) :-
    N > 1,
    N1 is N - 1, N2 is N - 2,
    memo_fib(N1, F1),
    memo_fib(N2, F2),
    F is F1 + F2.
```

```text
memo_fib(10)  = 55
memo_fib(40)  = 102334155
缓存里现在有 41 条记录
朴素的 fib(40) 要算约 3 亿次调用；带记忆化只要 40 次。
```

**这是动态库最正当的用法**，因为：

> **缓存是「幂等的派生物」** —— 删了只会重算，**不会破坏正确性**。
> 所以 17.2 那个「副作用不回溯」的坑在这里**无害**。

对比 17.3 的计数器：那个**不能重入、不能失败**；而缓存**随便你怎么回溯、怎么删**，
结果永远一样。这就是「什么是好副作用、什么是坏副作用」的判据。

> **生产代码里记得给缓存加个清理入口**（`retractall(fib_cache(_,_))`）。
> 否则缓存会跟着进程生命周期无限增长 —— 这就是最朴素的「内存泄漏」。

## 17.5 反射：`clause/2` 与 `abolish/1`

```prolog
assertz(fact2(0)),
assertz((fact2(X) :- X > 1)),
findall(H-B, clause(fact2(H), B), Clauses).
```

```text
clause/2 看到 (头-体)：[0-true,A-(A>1)]
事实的体显示为 true；带规则的子句体就是它的右侧。
```

**`clause(Head, Body)` 是运行期反射的入口**：看到的事实，`Body` 是 `true`；看到规则，
`Body` 是它的右侧。所有「解释器、调试器、规则检查器」都建立在这上面（12 章、24 章）。

**`current_predicate/1` 问「这个谓词还存不存在」**：

```prolog
current_predicate(fact2/1)      % abolish 之前 → 成立
abolish(fact2/1),               % 删掉整个谓词
current_predicate(fact2/1)      % abolish 之后 → 不成立（调用报 existence_error）
```

```text
current_predicate/1 可以问「这个谓词还存不存在」：
  abolish 之前 current_predicate(fact2/1) 成立
  abolish 之后已不存在（调用会报 existence_error）
对照：静态谓词 price/2 一直都在
```

> **`abolish/1` 删掉的是整个谓词（所有子句），不只是事实。**
> **它不看参数** —— `abolish(price/2)` 不管 `price` 里有什么，全清空。
> **一个手滑就清空整个谓词，慎用。**
>
> **可移植性警告**：对**静态**谓词 `abolish` 的行为两套引擎不一致 ——
> 一个报权限错误，一个**照删不误**（静态代码被删掉，后果不可预测）。
> **所以可移植代码只对 `dynamic` 谓词用 `abolish`。**
>
> 补充：**GNU 的 `current_predicate/1` 看不到内建谓词**（21、22 章会再遇到）。
> 所以拿它判「内建谓词是否存在」是不可移植的。

## 17.6 坑位清单

1. **以为回溯会撤销 `assertz`** → 不会。失败的查询可能已经改了库。
2. **`retract/1` 不加 `once`/`!`** → 回溯把同名事实全删了。
3. **拿 `retractall/1` 的成功当「删到了」** → 它永远成功，一条没删也成功。
4. **`:- dynamic item/2.` 不带括号** → GNU 语法错误（12 章）。
5. **`abolish/1` 用在静态谓词上** → 两套引擎行为不同，可能把代码删了。
6. **`abolish/1` 忘记参数是「名字/元数」** → 写 `abolish(fact2)` 是错的，要 `fact2/1`。
7. **`clause/2` 期望看到静态谓词的子句** → 标准规定只看动态谓词。
8. **`clause/2` 拿到的 `Body` 变量当原变量** → 是副本，绑定不回传（配 `numbervars/3` 打印）。
9. **缓存不设清理入口** → 无界增长，等于内存泄漏。
10. **用动态库做跨谓词共享状态** → 不可重入、不可嵌套，能传参就传参。

---

上一章：[16 · 运算符](16-operators.md) · 下一章：[18 · 定子句文法](18-dcg.md)
