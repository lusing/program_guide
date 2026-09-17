# 05 · 递归与尾调用

> 对应示例：`examples/05_recursion/`

## 5.1 没有循环，只有递归

Erlang 没有 `for`/`while`。所有重复都靠递归 + 模式匹配：

```erlang
depth_count([])      -> 0;                       %% 基线：空列表
depth_count([_ | T]) -> 1 + depth_count(T).      %% 归纳：头 + 尾的计数
```

写递归先写**基线子句**（什么时候停），再写归纳子句。Erlang 没有"先声明后使用"的限制，相互递归（`is_even` ↔ `is_odd`）直接写。

## 5.2 尾递归：调用即跳转

```erlang
sum(0, Acc)    -> Acc;
sum(N, Acc)    -> sum(N - 1, Acc + N).   %% 最后一步就是调用本身 → 复用栈帧
```

非尾递归（`N + sum(N-1)`）返回前还有加法要做，栈帧只能堆着。实测（OTP 29，深度 20 万）：**非尾递归峰值内存是尾递归的约 970 倍**（2546256 words vs 2624 words）。

> 铁律：**活得久的进程（gen_server 的循环就是）必须尾递归**，否则内存一直涨到 OOM。

## 5.3 累加器模式

```erlang
fib(N)              -> fib(N, 0, 1).      %% 对外接口隐藏累加器
fib(0, A, _)        -> A;
fib(N, A, B)        -> fib(N - 1, B, A + B).   %% 双累加器：O(N)
```

惯用法：导出 `f/1` 做参数检查，内部 `f/2,3` 裸奔递归。fib 的朴素双递归是指数级，双累加器直接线性。

## 5.4 accumulate-then-reverse

尾递归构造列表时 `[X | Acc]` 攒出来是**逆序**的，最后 `lists:reverse` 一次：

```erlang
rev_map(F, L)         -> lists:reverse(rev_map(F, L, [])).
rev_map(_, [], Acc)   -> Acc;
rev_map(F, [H|T], Acc) -> rev_map(F, T, [F(H) | Acc]).
```

`lists:reverse` 是 BIF（C 实现，线性且极快）。stdlib 的 `lists:map` 等就是这么实现的。

## 5.5 递归数据结构：表达式求值器

```erlang
eval({num, N})     -> N;
eval({add, A, B})  -> eval(A) + eval(B);
eval({mul, A, B})  -> eval(A) * eval(B).
```

树的定义是递归的，求值器自然是递归的——每个构造器一个子句，这就是"用模式匹配给代数数据类型写解释器"。

## 5.6 guard 看到的是结构不是值

```erlang
eval({divi, A, B}) -> safe_div(eval(A), eval(B)).   %% 除零判断必须求值后再做
```

想在 `{divi, _, 0}` 上写 guard 拦除零？guard 看到的 `B` 是语法树节点 `{num, 0}` 而不是 `0`——**先求值再判断**。

## 5.7 坑位清单

1. **服务器循环必须尾递归**：`loop(State) -> ... loop(NewState)`；中间夹一个非尾调用就是内存泄漏。
2. **忘写基线子句**：无限递归直到内存耗尽，进程被 OOM killer 杀掉（不是栈溢出——BEAM 没有固定栈大小）。
3. **子句顺序**：`{divi, _, 0}` 特例必须排在通用子句**前面**，从上往下匹配。
4. **尾递归构造列表是逆序**：忘了 `lists:reverse` 结果倒着来。
5. **朴素 fib 是指数级**：`fib(50)` 都会卡住——考试写得出，生产用累加器版。
6. **深递归的中间结果**：非尾递归深度 20 万也能跑（BEAM 堆自适应），但峰值内存差三个数量级——别用"能跑"当借口。

---
