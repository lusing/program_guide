# 07 · fun、高阶函数与推导式

> 对应示例：`examples/07_funs/`

## 7.1 fun 的四种写法

```erlang
F1 = fun(X) -> X * 2 end.                    %% ① 匿名
F2 = fun(X) when X > 0 -> positive;          %% ② 多子句（可带 guard）
        (_) -> negative
     end.
F3 = fun erlang:max/2.                       %% ③ 外部引用 M:F/A
F4 = fun local_helper/1.                     %% ④ 本地引用（更快）
```

arity 是 fun 的一部分：`is_function(F1, 1)` 为 true、`is_function(F1, 2)` 为 false。

## 7.2 闭包捕获的是值

```erlang
adder(N) -> fun(X) -> X + N end.     %% 函数工厂 / Erlang 版柯里化
adder(2)(10).                         %% 12
```

变量不可变，所以捕获的就是创建时的值——**闭包陷阱根本不存在**，循环里造一万个 fun 也不怕。

## 7.3 fold 是通用递归模板

```erlang
fold_map(F, L) -> lists:reverse(lists:foldl(fun(X, Acc) -> [F(X) | Acc] end, [], L)).
```

map / filter / reverse / sum 全是 "fold + 一个 fun" 的特例。注意 foldl 的 fun 参数顺序是 **F(元素, 累加器)**；配 `[X|Acc]` 攒出来是逆序（foldr 是正序）。`lists:any/all` 会**短路**（命中即停），map/foreach 不会——示例用"碰到就抛异常"的探针函数证明了这一点。

## 7.4 谓词 / 变换器 / 比较器

```erlang
sort_by(KeyFun, L) -> lists:sort(fun(A,B) -> KeyFun(A) =< KeyFun(B) end, L).
sort_by(fun({_, Age}) -> Age end, People).   %% 把「排序键」参数化
```

把变化点抽成 fun，一段代码到处复用。比较器要给**全序**（返回 `=<` 语义）。

## 7.5 组合、管道与匿名递归

```erlang
compose(F, G)  -> fun(X) -> G(F(X)) end.          %% 先 F 再 G
pipeline(Funs) -> fun(X) -> lists:foldl(fun(F, Acc) -> F(Acc) end, X, Funs) end.

Fact = fun F(0) -> 1; F(N) -> N * F(N - 1) end.   %% fun F(...) end 自递归
```

`fun F(...)` 里的 `F` 只在 fun 体内可见——Erlang 版的 Y 组合子写法；大代码还是具名函数 + `fun name/arity` 清楚。

## 7.6 推导式

```erlang
[X*2 || X <- [1,2,3]].                          %% map
[X || X <- lists:seq(1,10), X rem 2 =:= 0].     %% map + filter
[{A,B,C} || C <- lists:seq(1,20), B <- lists:seq(1,C),   %% 多生成器=嵌套循环
            A <- lists:seq(1,B), A*A+B*B =:= C*C]        %% 勾股数
```

- 生成器 `Pattern <- List`、过滤器就是 guard；
- 右边的生成器在**内层**，范围可用前面绑定的变量；
- 用 `S <- [计算结果]` 把生成器当**局部变量**用（常用技巧）；
- 匿名 fun 递归 + 推导式 = 两行 quicksort（见示例 `quicksort/1`）。

## 7.7 二进制推导式

```erlang
<<<<X>> || <<X>> <= Bin>>.                          %% 原样复制
<<<<Y:16/little>> || <<Y:16/big>> <= Bin>>.         %% 大端→小端
[ C || <<C/utf8>> <= <<"中文"/utf8>> ].             %% 解出码点列表
```

两条硬规则：生成器写 **`<=`**（不是 `<-`）；**输出表达式必须是二进制** `<<...>>`。

## 7.8 惰性序列：fun 即迭代器

```erlang
count_from(N) -> fun() -> {N, count_from(N + 1)} end.
take(5, count_from(1)).    %% [1,2,3,4,5] —— 无限序列取多少算多少
```

调用 fun 得到 `{当前值, 下一个 fun}`——Erlang 版 stream 的全部原理。

## 7.9 坑位清单

1. **生成器模式不匹配静默跳过**：`[X || {X} <- [{1}, not_tuple]]` 得 `[1]`，不是报错——要严格匹配得自己写 `=` 断言。
2. **二进制推导式生成器写 `<-` 直接语法错**；输出不是二进制会运行期 badarg。
3. **foldl 参数顺序是 F(元素, 累加器)**：写反了类型全对、结果全错，编译器不拦。
4. **`~p` 把可打印列表打成字符串**：`[11,12,13]` 打成 `"\v\f\r"`——看数字用 `~w`。
5. **`fun name/arity` 本地引用与热加载**：本地引用绑旧版本代码，外部 `fun M:F/A` 总是最新——23 章实测。
6. **惰性序列每次调用要新的**：`count_from(1)` 每求值一次产生新状态，同一个 fun 调两次结果不同（它是状态机不是纯函数）。

---
