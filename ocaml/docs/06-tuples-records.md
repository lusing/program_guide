# 06 · 元组与记录

对应示例：`../examples/04_tuples.ml`

对应示例：`examples/04_tuples.ml`

### 6.1 元组：把多个值打包在一起

元组（tuple）是把多个值按顺序组合成一个值的方式。元组中的每个元素可以有不同的类型，长度是固定的。

```ocaml
let pair = (42, "answer")          (* int * string *)
let triple = (1, "two", 3.0)       (* int * string * float *)
let point = (3.0, 4.0)             (* float * float *)
```

元组的类型用 `*` 分隔各个元素的类型。`int * string` 的意思是「一个元组，第一个元素是 int，第二个是 string」。

元组用逗号构造。注意一个常见的坑：**逗号不是运算符，它是元组构造语法的一部分**。所以 `1, 2` 就是一个元组，括号不是必须的。但在大多数情况下，加括号会让代码更清晰。

```ocaml
let p = 1, 2            (* 也是元组，等价于 (1, 2) *)
let _ = fst p           (* 1 *)
```

### 6.2 元组的解构

元组最常用的操作是解构（destructuring）——用模式匹配把元组拆开，把各个元素绑到不同的名字上。

```ocaml
let (x, y) = (3.0, 4.0)
(* x = 3.0, y = 4.0 *)
```

这不是特殊语法——`let` 后面跟的是一个模式。元组模式 `(x, y)` 匹配元组值 `(3.0, 4.0)`，然后把 `x` 绑到 `3.0`，`y` 绑到 `4.0`。

解构也可以用在函数参数中：

```ocaml
let distance (x1, y1) (x2, y2) =
  sqrt ((x2 -. x1) ** 2.0 +. (y2 -. y1) ** 2.0)

let d = distance (0.0, 0.0) (3.0, 4.0)   (* 5.0 *)
```

这个函数的类型是 `float * float -> float * float -> float`。它接受两个元组参数，每个元组包含两个 float。

如果你只需要元组的一部分元素，可以用 `_` 通配符忽略不需要的部分：

```ocaml
let (first, _) = (100, "ignored")
(* first = 100 *)
```

对于二元组（pair），标准库还提供了 `fst` 和 `snd` 函数：

```ocaml
let _ = fst (1, "two")     (* 1 *)
let _ = snd (1, "two")     (* "two" *)
```

但 `fst` 和 `snd` 只能用于二元组。三元组及以上没有类似的内置函数，必须用模式匹配提取。

### 6.3 元组的常见用法

元组在 OCaml 中非常常用，典型场景包括：

**1. 函数返回多个值**

不像 C/Java 需要用输出参数或结构体，OCaml 中直接返回元组就行：

```ocaml
let div_rem a b = (a / b, a mod b)

let (q, r) = div_rem 10 3
(* q = 3, r = 1 *)
```

**2. 传递相关联的数据对**

比如键值对、坐标对、名字值对等：

```ocaml
let key_values = [("name", "Alice"); ("age", "30"); ("city", "Beijing")]
```

**3. 模式匹配中的组合**

当你需要同时匹配多个值时，可以把它们打包成元组一起匹配：

```ocaml
let compare_points (x1, y1) (x2, y2) =
  match (x1 = x2, y1 = y2) with
  | (true, true) -> "same point"
  | (true, false) -> "same x"
  | (false, true) -> "same y"
  | (false, false) -> "different"
```

### 6.4 记录：有名字的字段

元组很方便，但它的问题是：你得记住每个位置的含义。当元组的元素很多时，代码的可读性会急剧下降。

记录（record）解决了这个问题。记录是有名字的字段的集合：

```ocaml
type point2d = {
  x : float;
  y : float;
}

type person = {
  name : string;
  age : int;
  email : string;
}
```

创建记录：

```ocaml
let p = { x = 3.0; y = 4.0 }
let alice = { name = "Alice"; age = 30; email = "alice@example.com" }
```

访问字段用 `.` 语法：

```ocaml
let _ = p.x           (* 3.0 *)
let _ = alice.name    (* "Alice" *)
```

记录也可以模式匹配解构：

```ocaml
let { x = px; y = py } = p
(* px = 3.0, py = 4.0 *)
```

还有一个常用的简写：如果变量名和字段名相同，可以只写字段名：

```ocaml
let { x; y } = p
(* x = 3.0, y = 4.0 *)
```

这个简写在创建记录时也能用：

```ocaml
let x = 3.0
let y = 4.0
let p = { x; y }    (* 等价于 { x = x; y = y } *)
```

这叫做「字段名字面量简写」（field punning）。

### 6.5 记录的 with 语法

记录默认是不可变的。如果你想基于已有记录创建一个新记录，只修改部分字段，可以用 `with` 语法：

```ocaml
let p1 = { x = 1.0; y = 2.0 }
let p2 = { p1 with x = 10.0 }
(* p2 = { x = 10.0; y = 2.0 } *)
(* p1 保持不变 *)
```

`with` 语法不会修改原记录——它创建一个新记录。原记录的所有未在 `with` 中列出的字段都会被复制过来。

也可以同时修改多个字段：

```ocaml
let p3 = { p1 with x = 10.0; y = 20.0 }
```

对于嵌套记录，`with` 可以嵌套使用：

```ocaml
type rectangle = {
  top_left : point2d;
  bottom_right : point2d;
}

let move_rect dx dy rect =
  { rect with
    top_left = { rect.top_left with
      x = rect.top_left.x +. dx;
      y = rect.top_left.y +. dy
    }
  }
```

这看起来有点啰嗦，但它明确地表达了「函数式更新」的语义——原数据不被修改，总是创建新的。

### 6.6 可变字段（mutable）

记录的字段默认是不可变的。如果你需要可变的字段，用 `mutable` 关键字声明：

```ocaml
type counter = {
  mutable count : int;
  label : string;           (* 不可变字段 *)
}
```

修改可变字段用 `<-` 运算符：

```ocaml
let c = { count = 0; label = "clicks" }
let () =
  c.count <- c.count + 1;   (* count 变成 1 *)
  c.count <- c.count + 5    (* count 变成 6 *)
```

注意 `<-` 是赋值运算符，不是 `=`。`c.count <- c.count + 1` 的意思是「把 c.count 的值改成 c.count + 1」。

不可变字段不能被修改：
```ocaml
(* 错误：The field label is not mutable *)
(* c.label <- "new label" *)
```

什么时候用可变记录？当你需要封装一个有状态的对象时，可变记录非常方便。比如计数器、缓存、游戏中的玩家状态等。

一个完整的计数器例子：

```ocaml
type counter = {
  mutable count : int;
  mutable step : int;
}

let make_counter ?(step = 1) start =
  { count = start; step }

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current

let reset c =
  c.count <- 0

let set_step c s =
  c.step <- s
```

注意 `make_counter` 用了可选参数（`?step`），这在第 13 章会详细讲。

### 6.7 记录的多态（参数化记录）

记录类型可以有类型参数，就像参数化变体一样：

```ocaml
type 'a labeled = {
  label : string;
  value : 'a;
}

let int_labeled = { label = "count"; value = 42 }
let str_labeled = { label = "name"; value = "Alice" }
let float_labeled = { label = "pi"; value = 3.14159 }
```

`'a labeled` 是一个参数化的记录类型，`value` 字段可以是任意类型。

### 6.8 嵌套解构

元组和记录可以任意嵌套，解构也可以嵌套进行：

```ocaml
type rectangle = {
  top_left : point2d;
  bottom_right : point2d;
}

let r = {
  top_left = { x = 0.0; y = 10.0 };
  bottom_right = { x = 20.0; y = 0.0 };
}

(* 嵌套记录解构 *)
let { top_left = { x = x1; y = y1 }; bottom_right = { x = x2; y = y2 } } = r
let width = x2 -. x1    (* 20.0 *)
let height = y1 -. y2   (* 10.0 *)
```

元组中也可以嵌套记录，记录中也可以嵌套元组：

```ocaml
let labeled = ("my rect", r)
let (name, { top_left = tl; _ }) = labeled
(* name = "my rect" *)
(* tl = { x = 0.0; y = 10.0 } *)
```

解构的嵌套深度没有限制。但如果嵌套太深，代码可读性会下降，这时候考虑写辅助函数来提取字段。

### 6.9 记录与元组的选择

什么时候用元组，什么时候用记录？简单的判断标准：

- **元素个数 ≤ 2，且含义明显**：用元组。比如 `(key, value)` 对、坐标对、返回两个值的函数。
- **元素个数 ≥ 3，或含义不明显**：用记录。给字段起名字能大大提高可读性。
- **可能会扩展字段**：用记录。给记录加字段比给元组加元素容易得多（不需要修改所有使用的地方）。

一个经验法则：**如果同一个类型的元组在代码中出现超过两次，就应该考虑把它改成记录。**

### 6.10 本章小结

- 元组用逗号构造，把多个不同类型的值打包在一起
- 元组解构用 `let (x, y) = tuple` 或函数参数模式
- `fst` 和 `snd` 只能用于二元组
- 记录有命名字段，用 `type name = { field : type; ... }` 定义
- 记录字段用 `.` 访问，也可以模式匹配解构
- `with` 语法基于已有记录创建新记录（函数式更新）
- `mutable` 字段用 `<-` 赋值
- 记录可以是参数化（多态）的
- 解构可以任意嵌套
- 简单场景用元组，复杂场景用记录

---

---
上一章：[05 · 表达式与运算符](expressions.md) ｜ 下一章：[07 · 模式匹配](patterns.md) ｜ 返回：[README](../README.md)
