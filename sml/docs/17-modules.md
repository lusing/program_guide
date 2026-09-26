# 17 · 模块的组装：open / local / include

> 对应示例：`examples/15-modules.sml`


## 17.1 open 的遮蔽顺序

```sml
structure Red = struct val label = "red"  val code = 1 end
structure Green = struct val label = "green"  val code = 2 end

structure Both = struct
    open Red Green
    val summary = label ^ "/" ^ Int.toString code
end
```

`open Red Green` **等价于先 open Red 再 open Green**，所以后面的赢：

- `Both.label = "green"`
- `Both.code = 2`
- `Both.summary = "green/2"`

`open` 可以用逗号以外的写法吗？不能 —— `open A B` 就是「依次打开」。

## 17.2 open 不报冲突

这是 `open` 最危险的地方。两个结构有同名成员时，`open` **既不报错也不报警告**，只是后面的把前面的盖掉：

```sml
structure A2 = struct val size = 1  val tag = "A" end
structure B2 = struct val size = 2  val tag = "B" end

structure Merged = struct
    open A2 B2
    val both = tag ^ Int.toString size      (* "B2"，静默地赢了 *)
end
```

**没有任何提示。** 所以：

- `open` 只在小作用域（`let ... in ... end`）里用
- 顶层 `open` 大结构是给自己埋雷
- 一定要 open 就用 `open A` 之后立刻用，别隔着几十行再 open 别的

## 17.3 open 一个嵌套路径

```sml
structure Geo = struct
    structure Pt = struct
        val origin = (0, 0)
        fun shift (dx, dy) (x, y) = (x + dx, y + dy)
    end
end

val q =
    let
        open Geo.Pt
    in
        shift (2, 3) origin
    end
```

`open Geo.Pt` 是合法的 —— `open` 接受任意结构路径。

## 17.4 遮蔽规则：内层赢，且只在内层生效

```sml
val limit = 10

structure Cfg = struct
    val limit = 99
    val shown = limit          (* 用的是内层的 99 *)
end

val observed =
    let
        open Cfg              (* open 也是遮蔽：limit 变成 99 *)
    in
        limit
    end
```

结果：

- 顶层 `limit` 仍然是 **10**（`Cfg` 内部和 `let` 内部的遮蔽不外溢）
- `Cfg.limit = 99`、`Cfg.shown = 99`
- `observed = 99`

**遮蔽是词法作用域的，不会泄漏。**

## 17.5 顶层 local

`local` 不只能用在结构里：

```sml
local
    val base = 1000
    fun scale x = x * base
in
    val scaled = scale 3        (* 3000 *)
end
```

`base` 和 `scale` 的作用域到 `end` 为止，外面写 `base` 是 `unbound`。

**`local` 是「不想让辅助绑定污染全局」的标准工具。** 注意 `scaled` 能用到 `scale`，是因为 `scaled` 的求值发生在 `local` 的可见范围内；结果本身只是个 `int`。

## 17.6 include 用在签名里：签名的继承

```sml
signature SHAPE = sig
    val name : string
    val area : real -> real
end

signature CIRCLED = sig
    include SHAPE
    val radius : real
end
```

`include SHAPE` 把 `SHAPE` 的所有条目**原样展开**到 `CIRCLED` 里。所以 `CIRCLED` 等价于：

```sml
signature CIRCLED = sig
    val name : string
    val area : real -> real
    val radius : real
end
```

实现的时候所有条目都要提供：

```sml
structure Circle : CIRCLED = struct
    val name = "circle"
    val radius = 2.0
    fun area r = 3.14159265358979 * r * r
end
```

**多层叠加**：

```sml
signature BASE = sig val id : int end
signature NAMED = sig include BASE  val label : string end
signature VERSIONED = sig include NAMED  val version : int end
```

`VERSIONED` 最终要求提供 `id`、`label`、`version` 三样。这让「接口的逐步扩展」变成几行声明。

## 17.7 include 不能用在 structure 里

这个坑值得单独一节。这样写是**语法错**：

```sml
structure Bad = struct
    include SHAPE            (* 错！*)
    val radius = 1.0
end
```

三家一致拒绝，报错要点都是 `end expected but include was found`。

**根因**：`include` 是 **spec（签名层）的构造**，不是 **strdec（结构层）的构造**。语法上它只能出现在 `sig ... end` 里面。

**想在 structure 内部复用别的 structure，用 `open`**：

```sml
structure Good = struct
    open Shape          (* 把 Shape 的成员引进来 *)
    val radius = 1.0
end
```

注意两者语义不同：`include` 在**签名里**声明「这些条目我也要有」，`open` 在**结构里**把已有的绑定引进作用域。

## 17.8 三种「复用」手段对照

| 手段 | 用在哪 | 语义 |
|---|---|---|
| `open` | 结构层 / 表达式层 | 把绑定的**名字**引进作用域 |
| `include` | 签名层 | 把签名的**声明**复制进来 |
| `where type` | 签名层 | 给签名里的抽象类型定值 |
| `sharing` | 签名层（functor 参数） | 强制两个抽象类型相同（第 15 章） |

---
