# 15 · functor

> 对应示例：`examples/13-functors.sml`


## 15.1 functor 是什么

functor 是「从 structure 到 structure 的**编译期**函数」。参数必须恰好一个，用签名约束；产出可以再用签名约束。

```sml
functor Sqr (X : sig val n : int end) = struct
    val result = X.n * X.n
end

structure Sq7 = Sqr (struct val n = 7 end)      (* Sq7.result = 49 *)
structure Sq9 = Sqr (struct val n = 9 end)      (* Sq9.result = 81 *)
```

参数位置的 `sig ... end` 是**匿名签名**，适合只用一次的场合。

## 15.2 一份 functor 服务多套实现

这才是 functor 的核心价值。用抽象类型做参数：

```sml
signature NUM = sig
    type num
    val zero : num
    val one : num
    val add : num * num -> num
    val mul : num * num -> num
    val toString : num -> string
end

structure IntNum : NUM = struct
    type num = int
    val zero = 0
    val one = 1
    fun add (a, b) = a + b
    fun mul (a, b) = a * b
    fun toString n = Int.toString n
end
```

**注意 `RealNum` 这里必须加类型标注**，否则会撞上一个实现差异：

```sml
structure RealNum : NUM = struct
    type num = real
    val zero = 0.0
    val one = 1.0
    (* 下面两个标注是必须的！见 15.6 *)
    fun add (a : real, b : real) = a + b
    fun mul (a : real, b : real) = a * b
    fun toString r = Real.fmt (StringCvt.FIX (SOME 2)) r
end

functor Poly3 (N : NUM) = struct
    val demo = N.add (N.mul (N.add (N.one, N.one), N.add (N.one, N.one)), N.one)
    val report = N.toString demo
end

structure PInt = Poly3 (IntNum)      (* "5" *)
structure PReal = Poly3 (RealNum)    (* "5.00" *)
```

`Poly3` 全程只用 `NUM` 的操作，所以 int 和 real 都能用。**这就是 SML 的泛型。**

## 15.3 给产出加约束

```sml
signature STACK = sig
    type t
    val empty : t
    val push : int * t -> t
    val pop : t -> (int * t) option
    val depth : t -> int
end

functor MakeStack (X : sig val capacity : int end) : STACK = struct
    type t = int list
    val empty = []
    fun depth s = List.length s
    fun push (x, s) = if depth s >= X.capacity then s else x :: s
    fun pop [] = NONE
      | pop (x :: rest) = SOME (x, rest)
end

structure Cap3 = MakeStack (struct val capacity = 3 end)
```

`functor F (...) : SIG = ...` 让封装后的产出也满足 `SIG`。

## 15.4 参数签名里的 where type

```sml
functor Times10 (X : sig
                         type t
                         val mk : int -> t
                         val out : t -> int
                     end where type t = int) = struct
    val r = X.out (X.mk 7)
end
```

`where type t = int` 要求参数必须用 `int` 实现 `t`。这比 `:` 更精确 —— 第 14 章的 `INT_COUNTER` 就是这个模式。

## 15.5 一次传多个 structure：spec 形式的参数

SML 的 functor 只吃一个参数。要传多个，用 **spec 形式**：参数位置不写 `strid : sigexp`，而是直接写一段 spec，里面可以声明好几个 structure：

```sml
signature SA = sig val a : int end
signature SB = sig val b : int end

functor AddPair (structure A : SA  structure B : SB) = struct
    val sum = A.a + B.b
end

structure Pair12 = AddPair (struct
                                structure A = struct val a = 1 end
                                structure B = struct val b = 2 end
                            end)
```

注意实际的参数是**一个 struct**，里面装了两个子结构。

**另一种（可移植的）做法是把参数打包成一个签名**：

```sml
signature PAIR = sig structure A : SA  structure B : SB end
functor AddPair2 (P : PAIR) = struct val sum = P.A.a + P.B.b end
```

两者都可以，spec 形式更短，打包形式更显式。

## 15.6 柯里化 functor 只有 SML/NJ 认

SML/NJ 接受：

```sml
functor F2 (A : SA) (B : SB) = struct val r = A.a + B.b end
structure R = F2 (PA) (PB)
```

它把 `F2` 理解成「返回 functor 的 functor」。但实测：

| 实现 | `functor F (A:S1) (B:S2)` |
|---|---|
| SML/NJ | 接受 |
| Poly/ML | **`error: = expected but ( was found`** |
| MLton | **`Syntax error: replacing FUNCTOR with DO`** |

**这是 SML/NJ 的扩展，不是标准 SML'97。** 要跨实现，多参数一律用 15.5 的两种写法。

## 15.7 sharing type：把两个抽象类型「钉」成同一个

如果 functor 要把一个参数产出的值喂给另一个参数：

```sml
signature MAKER = sig type t  val mk : int -> t end
signature GETTER = sig type t  val peek : t -> int end

functor RoundTrip (X : sig
                           structure M : MAKER
                           structure G : GETTER
                           sharing type M.t = G.t
                       end) = struct
    fun run n = X.G.peek (X.M.mk n)
end
```

`X.M.mk n` 的类型是 `M.t`，`X.G.peek` 要 `G.t`。**如果 `M.t` 和 `G.t` 被当成两个各自独立的抽象类型，这里就通不过。** `sharing type M.t = G.t` 把它们强制成同一个类型。

本章示例里两个结构实际都用 `string`（具体类型），所以去掉 `sharing` 也能过 —— 但一旦两者都是真正的抽象类型，`sharing` 就成了**必需**的。这是 functor 类型系统里最微妙的一点。

## 15.8 不透明的结果签名

```sml
functor MakeCounter (X : sig val start : int end) :> COUNTER_API = struct
    val cell = ref X.start
    val secret = 999                (* 不导出 *)
    fun next () = (cell := !cell + 1; !cell)
    fun reset () = cell := X.start
end
```

`:>` 让产出变得不透明 —— 签名里没写的 `secret` 外面根本看不到。**functor + `:>` 是 SML 里做「抽象数据类型工厂」的标准组合**，下一章展开。

## 15.9 重载运算符 + 抽象类型 + 签名约束：必须标注

回到 15.2 那个 `RealNum`。如果写成：

```sml
structure RealNum : NUM = struct
    type num = real
    val zero = 0.0
    val one = 1.0
    fun add (a, b) = a + b          (* 没有标注 *)
    fun mul (a, b) = a * b
    fun toString r = Real.fmt (StringCvt.FIX (SOME 2)) r
end
```

实测结果：

| 实现 | 结果 |
|---|---|
| SML/NJ | **`val add: int * int -> int` 对不上 `real * real -> real`** |
| Poly/ML | 通过（用签名期望的类型反推） |
| MLton | **同上报错** |

**根因**：SML 的重载运算符是「逐条绑定独立解析」的，`fun add (a, b) = a + b` 这条绑定**不会回头去看签名想要什么类型**。`type num = real` 这个声明也不构成对 `add` 的约束（`type` 只是别名！）。所以没有上下文时 `+` 就默认成 `int`。

**结论：在「重载运算符 + 抽象类型 + 签名约束」这个组合下，参数类型必须写死。** 这个坑在写 `NUM` 这类「数值抽象」时几乎必然遇到。

---
