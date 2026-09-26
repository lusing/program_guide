# 14 · 结构与签名

> 对应示例：`examples/12-structures.sml`


## 14.1 structure：把相关的值打包

```sml
structure Math3 = struct
    val pi = 3.14159265358979
    fun square x = x * x
    fun cube x = x * x * x
end

val _ = Math3.square 7      (* 49 *)
```

`structure` 相当于「命名空间 + 编译期打包」。它**没有运行时开销** —— 编译完就是普通函数。

访问用点号：`Math3.square`。嵌套结构用 `A.B.c`。

## 14.2 signature：一份接口契约

```sml
signature COUNTER = sig
    type t
    val zero : t
    val bump : t -> t
    val value : t -> int
end
```

签名里只写**类型**，不写实现。`type t` 这种写法叫**抽象类型声明**：它说「有个类型叫 `t`，具体是什么由实现决定」。

## 14.3 约束：`:`

```sml
structure Counter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 1
    fun value n = n
end
```

`structure Counter : COUNTER = ...` 的意思是「这个结构的公开视图是 `COUNTER`」。

**`:` 是透明约束（transparent ascription）**：签名里虽然只写了 `type t`，但因为约束是透明的，**外界仍然知道 `Counter.t = int`**：

```sml
val asInt : Counter.t = 42          (* 合法！我们直接拿 int 当 Counter.t 用 *)
```

这是 `:` 和 `:>` 的关键区别（第 16 章）。

## 14.4 约束会收窄公开视图

签名里没写的东西，外面用不了：

```sml
signature REALISH = sig
    val pi : real
    val square : int -> int
end

structure Narrow : REALISH = Math3      (* Math3 有 cube，但 REALISH 里没写 *)

val _ = Narrow.square 5      (* 可以 *)
(* Narrow.cube 会报 unbound structure member *)
```

**这个「收窄」是单向的**：可以比实现更窄，不能更宽。签名里写了但实现里没有，直接编译错。

这也是「先定接口再写实现」的落点：接口变窄不影响实现，接口变宽会立刻报错。

## 14.5 open：把成员拉进当前作用域

```sml
structure Point = struct
    val origin = (0, 0)
    fun mk (x, y) = (x, y)
    fun dist2 ((x1, y1), (x2, y2)) = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end

val d =
    let
        open Point
    in
        dist2 (origin, mk (3, 4))
    end
```

`open` 之后 `origin` / `mk` / `dist2` 直接可用。**代价是命名空间污染** —— `open` 不报冲突，只是简单遮蔽（第 17 章）。

**所以 `open` 要限制在小作用域里**，比如上面的 `let ... in ... end`。顶层 `open` 大结构是给自己找麻烦。

## 14.6 嵌套 structure

```sml
structure Geometry = struct
    structure Pt = struct
        fun mid ((x1, y1), (x2, y2)) = ((x1 + x2) div 2, (y1 + y2) div 2)
    end

    structure Seg = struct
        fun len2 ((x1, y1), (x2, y2)) = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
    end
end

val _ = Geometry.Pt.mid ((0, 0), (4, 6))     (* (2, 3) *)
```

结构可以任意嵌套，这是组织大代码库的基础。

## 14.7 local：结构内部的私有绑定

```sml
structure Math4 = struct
    local
        fun helper x = x * 100
    in
        fun boosted x = helper x + 1
    end
end
```

`helper` 在 `Math4` 内部可见，但**不在公开视图里** —— 外面写 `Math4.helper` 会报错。`boosted` 因为被闭包捕获，照样能用它。

**`local` 和签名是两种不同的隐藏手段**：

| | `local` | 签名里不写 |
|---|---|---|
| 隐藏粒度 | 单个绑定 | 成员 |
| 需要签名 | 不需要 | 需要 |
| 适用 | 结构内部的辅助函数 | 对外的接口设计 |

## 14.8 where type：把抽象类型定死

```sml
signature INT_COUNTER = COUNTER where type t = int

structure Counter2 : INT_COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 1
    fun value n = n
end
```

`COUNTER where type t = int` 的意思是「`COUNTER` 这份契约，但把 `t` 明确成 `int`」。

用途：**当一个 functor 需要参数提供某个具体类型时**。第 15 章有实例。

## 14.9 一个签名，多套实现

这是签名最大的价值：

```sml
structure Counter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 1
    fun value n = n
end

structure FastCounter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 2          (* 一次走两步 *)
    fun value n = n div 2       (* 内部当两倍存 *)
end
```

只要接口一样，用它们的地方完全不用改。

## 14.10 「接收一个 structure 的函数」不是函数，是 functor

这是本章最容易撞墙的地方：

```sml
fun runThree (C : COUNTER) = ...      (* 编译错误！*)
```

```
Error: unbound type constructor: COUNTER
```

因为 `(C : COUNTER)` 会被解析成**类型标注**，而 `COUNTER` 是签名不是类型。**SML 里参数位置的 `:` 永远表示「这是个类型」。**

唯一正确的写法是 functor：

```sml
functor RunThree (C : COUNTER) = struct
    val result = C.value (C.bump (C.bump (C.bump C.zero)))
end

structure R1 = RunThree (Counter)
structure R2 = RunThree (FastCounter)
```

这三家里谁都不接受 `fun ... (C : COUNTER)`，所以这不是方言问题，是语言的类型/签名二元划分决定的。下一章展开。

---
