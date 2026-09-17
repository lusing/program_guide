# 04 · 模式匹配与卫语句

> 对应示例：`examples/04_patterns/`

## 4.1 匹配即分派

```erlang
area({circle, R})          -> 3.14159 * R * R;
area({rect, W, H}) when W > 0, H > 0 -> W * H;
area({triangle, A, B, C})  -> heron(A, B, C);
area(Other)                -> {error, {unknown_shape, Other}}.   %% 兜底
```

实参从上往下逐子句尝试，第一个匹配的执行。**总是留兜底子句**——漏了就是 `function_clause` 异常。Erlang 没有 switch，这就是分派机制本身。

## 4.2 各种地方都能匹配

```erlang
[X, Y | Rest] = [1,2,3,4].            %% {1,2,[3,4]}：一次剥多个元素
{ok, {user, N}} = {ok, {user, alice}}.%% 嵌套解构
#{name := N} = #{name => a}.          %% map 模式：:= 要求键存在
classify(P = {point, X, Y})           %% 别名模式：整体与部分同时绑定
```

map 模式里只有 `:=` 参与匹配；`#{}`（空模式）匹配**任何 map**。

## 4.3 变量绑定规则

```erlang
same_or_diff({X, X}) -> same;    %% 同一变量出现两次 = 两处必须相等
same_or_diff(_)      -> different.
```

- 变量一次匹配只绑定一次，再次出现即**相等断言**；
- `_` 完全不绑定；`_Foo` 绑定但抑制 unused 警告；
- `{ok, V} = {error, 1}` 抛 `{badmatch, {error, 1}}`——**badmatch 带右边的值**，排查利器；
- 函数体里的 `=` 就是断言：`{ok, Socket} = connect(...)` 失败即崩。

## 4.4 二进制模式（预览）

```erlang
parse_frame(<<Type:8, Len:16, Payload:Len/binary, Rest/binary>>) -> ...
```

段的尺寸可以引用前面绑定的变量（`Len/binary`）——解析自描述协议的常规手段，08 章展开。

## 4.5 卫语句：when

```erlang
clamp(X, Lo, Hi) when Lo =< X, X =< Hi -> X.   %% 逗号 = and
week_day(N) when N =:= 6; N =:= 7 -> weekend.  %% 分号 = or
```

> **注意与多数语言相反**：guard 里 `,` 是"并且"、`;` 是"或者"——Erlang 的标点跟 Prolog 学的是逻辑连接词。

## 4.6 guard 白名单与三条铁律

```erlang
when is_list(L), L =/= [], is_integer(hd(L)) -> ...   %% ✔ 都是 BIF
when lists:member(X, L) -> ...                        %% ✘ 自定义/stdlib 一律不行
```

能用：类型测试（`is_integer` 等）、`hd/length/abs/round/trunc/size/element/map_size/map_get/is_map_key`、比较与位运算。**不能**调自定义函数（编译器直接报 illegal guard expression）。

铁律：① 只有 BIF；② `,`=and、`;`=or；③ **guard 出错静默变 false**——`hd([])` 在 guard 里不抛异常，只是子句不匹配、继续往下试（在函数体里同样写法抛 badarg）。

## 4.7 case 与 if

```erlang
case maps:find(K, M) of
    {ok, V} when is_integer(V) -> {found_int, V};
    {ok, V}                    -> {found, V};
    error                      -> missing
end.

if X > 0 -> positive; X < 0 -> negative; true -> zero end.  %% true 兜底不能省
```

- 对**函数参数**分派 → 多子句；对**中间结果**分派 → `case`；
- `if` 分支只能是 guard 表达式，没兜底抛 `if_clause`（`case` 没兜底抛 `case_clause`，reason 带着没匹配上的值）；
- `case`/`if` 都是表达式，都有值。

## 4.8 坑位清单

1. **变量二次绑定是 badmatch 不是赋值**：`X = 1, X = 2` 直接崩——没有可变变量。
2. **`{X, X}` 是相等断言**：想"两个都取出来"要写 `{X, Y}`；想忽略写 `{X, _}`。
3. **guard 出错静默变 false**：`when hd(L) > 0` 对空列表悄悄不匹配，bug 被掩盖——类型判定（`is_list`）放最前面。
4. **`if` 忘写 `true ->` 兜底**：运行期 `if_clause`；编译器不查。
5. **guard 里调自定义函数是编译错误**：复用逻辑只能在函数体里用 `case`。
6. **map 模式的 `=>` 不参与匹配**：模式里只有 `:=` 有"键必须存在"的语义。

---
