# 16 · 不透明约束与抽象数据类型

> 对应示例：`examples/14-abstraction.sml`


## 16.1 `:` 与 `:>` 的区别

```sml
signature BOX = sig
    type t
    val wrap : int -> t
    val unwrap : t -> int
end

structure TransBox : BOX = struct        (* 透明约束 *)
    type t = int
    fun wrap n = n
    fun unwrap n = n
end

structure OpaqueBox :> BOX = struct      (* 不透明约束 *)
    type t = int
    fun wrap n = n
    fun unwrap n = n
end
```

两者的实现**逐字相同**，但对外表现完全不同：

```sml
val a : TransBox.t = 42        (* 合法：我们知道 TransBox.t = int *)
val b : OpaqueBox.t = 42       (* 类型错：OpaqueBox.t 和 int 是两个类型 *)
```

不透明约束下，**唯一的造值途径是签名里导出的 `wrap`**。

## 16.2 不透明约束保护不变量

```sml
signature NAT = sig
    type t
    val fromInt : int -> t
    val toInt : t -> int
    val add : t * t -> t
end

structure Nat :> NAT = struct
    type t = int
    fun fromInt n = if n < 0 then 0 else n
    fun toInt n = n
    fun add (a : t, b : t) = a + b
end
```

`fromInt` 会把负数夹成 0，所以 `Nat` 里的值保证非负。因为 `t` 是抽象类型、构造子不导出，**外界没法绕过 `fromInt` 造出负数**。

如果第 4 行写成透明约束：

```sml
structure Nat : NAT = struct ...
val bad : Nat.t = ~9        (* 不变量当场破产 *)
```

**所以「要保护不变量」时，`:>` 不是风格问题，是正确性问题。**

## 16.3 不透明会连内部辅助函数一起藏

```sml
structure Stats :> STATS = struct
    fun total [] = 0
      | total (x :: xs) = x + total xs
    fun toReal n = Real.fromInt n
    fun mean xs = if null xs then 0.0 else toReal (total xs) / toReal (length xs)
    fun count xs = length xs
end
```

`total` 和 `toReal` 只在内部用，签名里没写，外面就 `Stats.total` 用不了。这正是我们要的。

## 16.4 eqtype：把相等性显式保留

签名里写 `type t` 时，抽象类型**默认不是相等类型**：

```sml
signature KEYBARE = sig
    type key
    val mkKey : int -> key
end

structure BareKey :> KEYBARE = struct
    type key = int
    fun mkKey n = n
end

(* 下面这行会被三家一致拒绝 *)
(* val _ = BareKey.mkKey 3 = BareKey.mkKey 3 *)
```

三种报错的措辞几乎一样：

| 实现 | 报错 |
|---|---|
| SML/NJ | `operator and operand do not agree [equality type required]` |
| Poly/ML | `Can't unify ''a to BareKey.key (Requires equality type)` |
| MLton | `expects: [<equality>] * [<equality>] but got: [BareKey.key] * ...` |

这是**刻意设计的**：`key` 的实现是 `int`，但那不关外界的事。既然接口没说可以比较，就不能比较。

要保留相等性，写 `eqtype`：

```sml
signature KEYEQ = sig
    eqtype key
    val mkKey : int -> key
end

structure IntKey :> KEYEQ = struct
    type key = int
    fun mkKey n = n
end

val _ = IntKey.mkKey 3 = IntKey.mkKey 3     (* 现在合法了 *)
```

或者自己导出比较函数：

```sml
signature KEYNOEQ = sig
    type key
    val mkKey : int -> key
    val eqKey : key * key -> bool
end
```

**`eqtype t` 和 `type t` + 导出 `eq` 函数的区别**：前者让 `=` 可用（包括在别人的泛型代码里），后者只给你一个函数。要「当 map 的 key」就用 `eqtype`。

## 16.5 抽象类型的 option 也不能比较

一个容易被忽略的推论：

```sml
val isEmpty =
    case Queue.deq (Queue.empty : int Queue.queue) of
        NONE => true
      | SOME _ => false
```

**不能写成 `Queue.deq ... = NONE`** —— `option` 的相等性依赖成员类型的相等性，而 `Queue.queue` 是抽象的、不是相等类型。得老老实实 `case`。

## 16.6 多态抽象类型

`type 'a queue` 也可以抽象：

```sml
signature QUEUE = sig
    type 'a queue
    val empty : 'a queue
    val enq : 'a * 'a queue -> 'a queue
    val deq : 'a queue -> ('a * 'a queue) option
    val size : 'a queue -> int
end

structure Queue :> QUEUE = struct
    type 'a queue = 'a list * 'a list      (* 前段 + 倒序后段 *)
    val empty = ([], [])
    fun size (f, b) = length f + length b
    fun enq (x, (f, b)) = (f, x :: b)
    fun deq ([], []) = NONE
      | deq ([], b) = (case rev b of [] => NONE | x :: f' => SOME (x, (f', [])))
      | deq (x :: f, b) = SOME (x, (f, b))
end
```

外界完全不知道内部是「两个列表」。以后想换成 `Array` 实现，调用方一行都不用改。

## 16.7 不透明之后就「开不了箱」

不透明约束下，类型是抽象的、**没有任何强制转换手段**（SML 不像 C++ 有 `reinterpret_cast`）。要取回内容只能在签名里**导出受控的出口**：

```sml
signature SHOWNAT = sig
    type t
    val fromInt : int -> t
    val show : t -> string          (* 出口之一：字符串形式 *)
end
```

```sml
structure SNat :> SHOWNAT = struct
    type t = int
    fun fromInt n = if n < 0 then 0 else n
    fun show n = "Nat(" ^ Int.toString n ^ ")"
end
```

这是「闭包式的受控出口」：虽然 `toInt` 不在签名里，外界仍然能拿到能用的东西。

## 16.8 functor + `:>`：抽象数据类型工厂

最实用的组合：

```sml
signature STORE = sig
    type t
    val empty : t
    val put : string * int -> t -> t
    val get : string -> t -> int option
    val keys : t -> string list
end

functor MakeStore (X : sig val fallback : int end) :> STORE = struct
    type t = (string * int) list
    val empty = []
    fun put (k, v) s = (k, v) :: s
    fun get k s = (case List.find (fn (k', _) => k' = k) s of
                       NONE => SOME X.fallback
                     | SOME (_, v) => SOME v)
    fun keys s = map (fn (k, _) => k) s
end

structure Store = MakeStore (struct val fallback = 0 end)
val st = Store.put ("x", 1) (Store.put ("y", 2) Store.empty)
```

`st` 的真实类型是 `(string * int) list`，但**外界既写不出这个类型，也拆不开它**。想换实现（比如换 `Array`、加 LRU 淘汰）完全不影响调用方。

## 16.9 本章两个「顺手记下」的坑

**① `map #1 s` 会撞 flex record。** 本章写 `keys` 时最初写成 `fun keys s = map #1 s`，三家都报 `unresolved flex record (can't tell what fields there are besides #1)`。改成显式 lambda 就好：

```sml
fun keys s = map (fn (k, _) => k) s
```

**② 柯里化函数调用别写成三元组。** `Store.put ("x", 1, Store.empty)` 是错的 —— `put` 是柯里化的，要写 `Store.put ("x", 1) Store.empty`。报错信息是 `operator and operand do not agree`，容易误以为是类型问题。

---
