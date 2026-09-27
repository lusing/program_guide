# 10 · 字符串与字符

对应示例：`../examples/08_strings.ml`

对应示例：`examples/08_strings.ml`

### 10.1 字符串是不可变的字节序列

在 OCaml 中，`string` 是**不可变的字节序列**。注意是「字节」不是「字符」——历史上 OCaml 的 string 被设计成字节串，不是 Unicode 字符串。每个 `string` 元素是一个 8 位的字节（`char` 类型）。

```ocaml
let s = "Hello, World!"
let len = String.length s     (* 13 *)
let first = s.[0]             (* 'H' *)
```

字符串用 `s.[i]` 语法访问第 i 个字节（从 0 开始）。这是 `String.get s i` 的语法糖。

**字符串是不可变的**——你不能修改字符串中的某个字符。所有「修改」字符串的操作（比如 `String.capitalize_ascii`、`String.sub`）都返回新的字符串，原字符串保持不变。

如果你需要可变的字节缓冲区，用 `Bytes` 模块。`Bytes.t` 是可变的字节序列，和 `string` 之间可以互相转换：

```ocaml
let b = Bytes.of_string "hello"
let () = Bytes.set b 0 'H'     (* 原地修改 *)
let s = Bytes.to_string b      (* "Hello" *)
```

### 10.2 char 类型

`char` 是单字节字符类型，用单引号括起来：

```ocaml
let c1 = 'A'
let c2 = '\n'      (* 换行符 *)
let c3 = '\65'     (* 八进制转义，等于 'A' *)
```

`char` 和 `int` 之间可以互相转换：

```ocaml
let code = Char.code 'A'      (* 65 *)
let ch = Char.chr 97          (* 'a' *)
```

`Char` 模块还有一些常用函数：

- `Char.uppercase_ascii` / `Char.lowercase_ascii`：大小写转换（只处理 ASCII）
- `Char.compare`：比较两个字符

注意这些 `_ascii` 后缀的函数只正确处理 ASCII 范围（0-127）的字符。对于超出 ASCII 范围的字节，它们的行为是未定义的（实际上是按字节值处理的，对于 ISO-8859-1 也能工作）。

判断字符类型的常用方法是直接比较：

```ocaml
let is_digit c = c >= '0' && c <= '9'
let is_lower c = c >= 'a' && c <= 'z'
let is_upper c = c >= 'A' && c <= 'Z'
```

### 10.3 字符串拼接与子串

**拼接**：用 `^` 运算符拼接两个字符串：

```ocaml
let s = "Hello" ^ ", " ^ "World" ^ "!"
```

`^` 是右结合的，而且每次拼接都会创建新字符串。如果要拼接很多字符串，推荐用 `String.concat` 或 `Buffer` 模块，性能更好。

**String.concat**：用分隔符把字符串列表连起来：

```ocaml
val concat : string -> string list -> string

let words = ["apple"; "banana"; "cherry"]
let csv = String.concat ", " words     (* "apple, banana, cherry" *)
```

**String.sub**：取子串，参数是起始位置和长度：

```ocaml
val sub : string -> int -> int -> string

let s = "Hello, World!"
let hello = String.sub s 0 5      (* "Hello" *)
let world = String.sub s 7 5      (* "World" *)
```

如果起始位置或长度不合法（越界），`String.sub` 会抛出 `Invalid_argument` 异常。

### 10.4 字符串分割

`String.split_on_char` 按字符分割字符串：

```ocaml
val split_on_char : char -> string -> string list

let path = "/usr/local/bin/ocaml"
let parts = String.split_on_char '/' path
(* [""; "usr"; "local"; "bin"; "ocaml"] *)
```

注意开头的空字符串——因为第一个字符就是分隔符。

`split_on_char` 是最简单的分割函数。如果你需要更复杂的分割（比如按字符串分割、按正则表达式分割），需要自己实现或用第三方库（比如 `Str` 模块或 `Re` 库）。

### 10.5 字符串与列表互转

有时候你需要用列表操作来处理字符串。可以通过 `Seq`（序列）在字符串和列表之间转换：

```ocaml
(* 字符串 -> 字符列表 *)
let chars = s |> String.to_seq |> List.of_seq

(* 字符列表 -> 字符串 *)
let s = cl |> List.to_seq |> String.of_seq
```

利用这个转换，你可以用 `List.map` 来处理字符串中的每个字符：

```ocaml
let to_uppercase s =
  s |> String.to_seq |> Seq.map Char.uppercase_ascii |> String.of_seq
```

字符串反转也可以通过列表实现：

```ocaml
let reverse_string s =
  s |> String.to_seq |> List.of_seq |> List.rev |> List.to_seq |> String.of_seq
```

当然，对于大字符串，通过列表中转效率不高。实际项目中推荐用 `Buffer` 模块直接构建。

### 10.6 Printf 格式化输出

`Printf` 模块提供了类似 C 语言 `printf` 的格式化功能，但类型安全。

常用的格式说明符：

| 说明符 | 类型 | 说明 |
|---|---|---|
| `%d` | `int` | 十进制整数 |
| `%f` | `float` | 浮点数 |
| `%s` | `string` | 字符串 |
| `%c` | `char` | 字符 |
| `%b` | `bool` | 布尔值 |
| `%x` | `int` | 十六进制（小写） |
| `%X` | `int` | 十六进制（大写） |
| `%o` | `int` | 八进制 |
| `%Ld` | `int64` | 64 位整数 |
| `%.2f` | `float` | 保留两位小数 |
| `%10s` | `string` | 宽度 10，右对齐 |
| `%-10s` | `string` | 宽度 10，左对齐 |
| `%!` | - | 刷新缓冲区 |

```ocaml
Printf.printf "Name: %s, Age: %d, Height: %.2f\n" "Alice" 30 1.65
```

`Printf.sprintf` 返回格式化后的字符串，而不是打印出来：

```ocaml
let msg = Printf.sprintf "Result: %d + %d = %d" 3 4 (3 + 4)
(* "Result: 3 + 4 = 7" *)
```

`Printf` 的格式化函数是类型安全的。如果你用 `%d` 但传了一个 `string`，编译器会在编译期报错，而不是等到运行时才崩。这得益于 OCaml 的类型系统——格式化字符串不是普通的字符串，它有特殊的类型（格式标记类型）。

### 10.7 关于 Unicode

需要特别提醒：OCaml 标准库的 `string` 和 `char` 是面向字节的，不是面向 Unicode 字符的。

- `String.length "中文"` 返回的是字节数（6，因为每个汉字占 3 个 UTF-8 字节），不是字符数（2）
- `s.[0]` 返回的是第一个字节，不是第一个字符
- `Char.uppercase_ascii 'a'` 只处理 ASCII 字符，对中文无效

如果你需要正确处理 Unicode 文本，应该用第三方库：

- **`uutf` / `uunf` / `uucp`**：Unicode 字符处理的基础库
- **`sedlex`**：Unicode 词法分析器生成器
- **`Camomile`**：功能完整的 Unicode 库

在实际项目中，最常见的做法是：把字符串当 UTF-8 编码的字节串处理，需要字符级操作时用第三方库。

### 10.8 字符串的常用操作速查

| 操作 | 函数 / 运算符 | 复杂度 |
|---|---|---|
| 取长度 | `String.length s` | O(1) |
| 取第 i 个字节 | `s.[i]` / `String.get s i` | O(1) |
| 拼接两个字符串 | `s1 ^ s2` | O(n+m) |
| 用分隔符连接列表 | `String.concat sep lst` | O(总长度) |
| 取子串 | `String.sub s start len` | O(len) |
| 按字符分割 | `String.split_on_char c s` | O(n) |
| 转大写（ASCII） | `String.uppercase_ascii s` | O(n) |
| 转小写（ASCII） | `String.lowercase_ascii s` | O(n) |
| 首字母大写（ASCII） | `String.capitalize_ascii s` | O(n) |
| 比较 | `String.compare s1 s2` | O(min(n,m)) |
| 包含 | `String.contains s c` | O(n) |

### 10.9 本章小结

- OCaml 的 `string` 是不可变的字节序列，不是 Unicode 字符串
- `char` 是单字节类型，用 `Char.code` / `Char.chr` 和 int 互转
- 字符串拼接用 `^`，大量拼接用 `String.concat` 或 `Buffer`
- `String.sub` 取子串，`String.split_on_char` 按字符分割
- 字符串和列表可以通过 `Seq` 互转
- `Printf.printf` / `Printf.sprintf` 提供类型安全的格式化输出
- 需要 Unicode 处理时用第三方库（uutf、Camomile 等）
- `Bytes` 是可变的字节缓冲区

---

---
上一章：[09 · 变体类型（代数数据类型）](variants.md) ｜ 下一章：[11 · 递归与尾递归](recursion.md) ｜ 返回：[README](../README.md)
