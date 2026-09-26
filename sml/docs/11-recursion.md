# 11 · 递归与尾递归

> 对应示例：`examples/09-recursion.sml`


## 11.1 递归是 SML 的主要控制结构

SML 里没有 `for` 循环。要么用递归，要么用 `while`（第 18 章）。绝大多数情况用递归，因为它在列表/树上的表达力更好。

```sml
fun fact 0 = 1
  | fact n = n * fact (n - 1)
```

朴素阶乘：`fact 5 = 5 * 4 * 3 * 2 * 1`。每层递归都要等下一层算完才能做乘法，所以栈深度是 n。

## 11.2 尾递归：把结果攒在参数里

```sml
fun factTail n =
    let
        fun go (0, acc) = acc
          | go (k, acc) = go (k - 1, k * acc)
    in
        go (n, 1)
    end
```

`go` 的递归调用是**最后一个动作**，没有待处理的乘法。这种形式的递归可以被编译器优化成循环，**栈深度 O(1)**。

验证方法很直接：拿一个很大的数字跑。

```sml
fun countDown 0 = ()
  | countDown n = countDown (n - 1)

val _ = countDown 1000000    (* 一百万层递归，尾调用扁平化之后毫无压力 *)
```

如果 `countDown` 不是尾递归，一百万层会直接把栈撑爆。

**注意**：SML 标准**不保证**尾调用优化，但三套实现都做了，而且 `countDown 1000000` 的实测在三家下都通过。不过要真正确认，还是得跑一遍。

## 11.3 累积器模式：列表的两个方向

```sml
(* 正序构造，非尾递归 *)
fun rangeNaive (i, j) = if i > j then [] else i :: rangeNaive (i + 1, j)

(* 倒着攒再 rev，尾递归 *)
fun rangeFast (i, j) =
    let
        fun go (k, acc) = if k > j then rev acc else go (k + 1, k :: acc)
    in
        go (i, [])
    end
```

`rangeNaive (1, 5000)` 会先递归 5000 层再开始构造列表；`rangeFast` 是一路攒一路走，最后 `rev` 一次。

**这是 SML 写法的核心习惯**：先用累积器攒成倒序，需要正序再 `rev` 一次。`rev` 是 O(n) 的尾递归，不亏。

## 11.4 互递归：用 and

```sml
fun isEven 0 = true
  | isEven n = isOdd (n - 1)
and isOdd 0 = false
  | isOdd n = isEven (n - 1)
```

`and` 让两个函数互相可见。用它写状态机特别自然：

```sml
fun inString (cs) = ...
and inComment (cs) = ...
and inCode (cs) = ...
```

**互递归的形式更可读，但语义上不是尾递归的**（互相调用时编译器不一定能扁平化）。要性能就用累积器 + 显式状态参数。

## 11.5 三个经典递归

```sml
(* Ackermann：递归深度增长极快，n=3 就够看 *)
fun ack (0, n) = n + 1
  | ack (m, 0) = ack (m - 1, 1)
  | ack (m, n) = ack (m - 1, ack (m, n - 1))
```

```sml
(* 汉诺塔：数步数，别打印 2^n 行 *)
fun hanoiCount (0, _, _, _) = 0
  | hanoiCount (n, a, b, c) = hanoiCount (n - 1, a, c, b) + 1 + hanoiCount (n - 1, b, a, c)

val _ = hanoiCount (20, "A", "B", "C")    (* 1048575 *)
```

```sml
(* 记忆化斐波那契：朴素递归 O(2^n)，加个 memo 就是 O(n) *)
fun fibMemo n =
    let
        val memo = Array.array (n + 1, ~1)      (* ~1 表示还没算 *)
        fun go k =
            if k <= 1 then k
            else
                let val cached = Array.sub (memo, k)
                in
                    if cached >= 0 then cached
                    else
                        let val r = go (k - 1) + go (k - 2)
                        in (Array.update (memo, k, r); r) end
                end
    in
        go n
    end
```

注意 `fibMemo 40 = 102334155` —— 选这个数字是因为它小于 2³¹，在 MLton 的 32 位 `int` 上不溢出。**挑测试数据时记得 33 章那张表。**

## 11.6 let 里的递归与作用域

```sml
fun gcd (a, b) =
    let
        fun go (x, 0) = x
          | go (x, y) = go (y, x mod y)
    in
        go (a, b)
    end
```

`let ... in ... end` 里可以定义辅助函数，作用域到 `end` 为止。这是把「辅助递归」封在函数内部的常规做法，比在顶层多定义一个只有一处用的函数干净。

## 11.7 递归的替代：foldl

很多递归其实是 fold，写出来更短：

```sml
fun sum xs = foldl (op +) 0 xs
fun len xs = foldl (fn (_, n) => n + 1) 0 xs
fun maxOf (x :: xs) = foldl Int.max x xs
```

**判断标准**：如果递归的结构就是「对列表每个元素做点事然后累积」，那就是 fold。

---
