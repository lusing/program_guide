# 12 · 异常

对应示例：`../examples/10_exceptions.ml`

对应示例：`examples/10_exceptions.ml`

### 12.1 异常是什么

异常（exception）是一种非局部的控制流机制，用于处理错误和特殊情况。当异常被抛出（raise）时，程序会立刻「跳」到最近的捕获（try...with）处。

在 OCaml 中，异常是用 `exception` 关键字定义的：

```ocaml
exception MyError
exception InputOutOfRange of int * int
exception NegativeArgument of string * float
```

异常的定义看起来很像变体类型的构造子——实际上，**异常就是 `exn` 类型的构造子**，而 `exn` 是一个特殊的**可扩展变体**（extensible variant）。你可以随时添加新的异常构造子，这和普通变体类型不同（普通变体一旦定义就不能再加构造子了）。

抛出异常用 `raise` 函数：

```ocaml
let check_positive n =
  if n > 0 then n
  else raise MyError
```

### 12.2 try...with 捕获异常

用 `try ... with ...` 捕获异常：

```ocaml
let safe_div a b =
  try
    Some (a / b)
  with
  | Division_by_zero -> None
```

`try e with pat1 -> e1 | pat2 -> e2 | ...` 的工作方式：
1. 先求值 `e`
2. 如果 `e` 正常返回，就把它的值作为整个 try 表达式的值
3. 如果 `e` 抛出异常，就用异常值去匹配 `with` 后面的模式
4. 第一个匹配的分支的值就是整个 try 表达式的值
5. 如果没有匹配的模式，异常会继续向上传播

`with` 后面的模式就是普通的模式匹配——你可以用通配符、变体构造子模式、`when` 守卫等。

### 12.3 带参数的异常

异常可以携带参数，就像带参数的变体构造子一样：

```ocaml
exception InputOutOfRange of int * int   (* 最小值, 最大值 *)
exception FileError of string * string   (* 文件名, 错误信息 *)

let check_range n min max =
  if n < min || n > max then
    raise (InputOutOfRange (min, max))
  else n
```

捕获时可以解构参数：

```ocaml
try
  check_range 5 10 20
with
| InputOutOfRange (lo, hi) ->
    Printf.printf "Out of range [%d, %d]\n" lo hi;
    0
```

带参数的异常让错误信息可以包含上下文，方便调试和错误恢复。

### 12.4 exn 是可扩展变体类型

`exn` 类型是 OCaml 中一个特殊的类型——它是**可扩展变体**（extensible variant）。这意味着你可以在任何地方给它添加新的构造子（即定义新的异常）。

```ocaml
exception Foo of int    (* 给 exn 添加一个 Foo 构造子 *)
exception Bar of string (* 再添加一个 Bar 构造子 *)
```

这和普通变体类型不同——普通变体类型的构造子在定义时就固定了，不能后续添加。

可扩展变体的优势是灵活：每个库都可以定义自己的异常类型，不需要提前统一声明。劣势是没有穷尽性检查——因为异常类型是开放的，编译器不知道总共有多少种异常，所以 `try...with` 不会检查你是否覆盖了所有可能的异常。

这也是为什么 OCaml 的异常处理是「非类型安全」的——类型系统不会强迫你处理所有可能的异常。

### 12.5 标准库中的常用异常

OCaml 标准库定义了一些常用的异常：

| 异常 | 触发场景 |
|---|---|
| `Failure` | 通用失败，通常带错误信息 |
| `Invalid_argument` | 函数参数非法 |
| `Not_found` | 查找失败（如 `List.find`） |
| `Division_by_zero` | 除以零 |
| `Stack_overflow` | 栈溢出 |
| `Out_of_memory` | 内存不足 |
| `Match_failure` | 模式匹配失败（非穷尽 match 走到了没覆盖的情况） |
| `Sys_error` | 系统调用失败（如文件操作） |
| `End_of_file` | 读到文件末尾 |

`Failure` 和 `Invalid_argument` 都带一个 string 参数，通常是错误描述：

```ocaml
raise (Failure "something went wrong")
raise (Invalid_argument "negative length")
```

也有两个辅助函数：

```ocaml
failwith "message"          (* 等价于 raise (Failure "message") *)
invalid_arg "message"       (* 等价于 raise (Invalid_argument "message") *)
```

### 12.6 异常是不被类型系统追踪的副作用

这是一个重要的观点：**异常是一种副作用，而且是类型系统不追踪的副作用。**

一个函数的类型（比如 `int -> int`）只告诉你它接受 int 返回 int，但不会告诉你它可能抛出什么异常。你可以调用这个函数而完全不处理异常，编译器也不会警告你。

这和 `option` 形成对比。如果一个函数返回 `int option`，类型系统会强迫你处理 `None` 的情况（通过模式匹配）。但如果函数可能抛出异常，类型系统什么也不会说。

所以有一条经验法则：

- **预期内的、需要调用者处理的错误**：用 `option` 或 `result` 类型
- **预期外的、真正的异常情况**：用异常

比如 `List.find` 用 `Not_found` 异常，这是一个有争议的设计——很多人认为应该返回 `'a option`。但标准库的设计者认为「找不到」有时候是正常的，有时候是错误的，所以留了两种选择：你可以捕获异常，也可以先用 `List.exists` 检查。

### 12.7 异常与 option 的选择

什么时候用异常，什么时候用 `option`（或 `result`）？

**用 option / result 的情况：**

- 错误是预期内的、常见的
- 调用者几乎总是需要处理这个错误
- 你想让类型系统确保错误被处理
- 错误是「正常业务逻辑」的一部分

**用异常的情况：**

- 错误是罕见的、意外的
- 调用者通常不需要特别处理，让它往上冒就行
- 在深层嵌套中快速「跳出来」
- 错误处理的性能开销不重要（异常抛出/捕获的开销比返回 option 大）

实际项目中的常见模式是：**库的内部用异常，对外的 API 用 option/result 包装**。这样内部代码可以用异常快速跳出，而对外的接口保持类型安全。

### 12.8 异常的性能考虑

抛出和捕获异常的开销比返回一个 `option` 大。因为异常需要展开栈（unwind the stack）、查找匹配的处理程序等。

但如果异常真的是「异常」的（很少发生），那这点开销可以忽略。只有当异常被用作正常控制流（比如在循环中频繁抛出捕获）时，性能才会成为问题。

一个常见的反模式是：用异常来跳出深层循环或递归。这在功能上没问题，但如果发生得很频繁，应该考虑改用其他方式（比如用 `option` 返回、用可变标志位等）。

### 12.9 异常与资源清理

当异常抛出时，栈会展开，中间的函数会提前返回。这时候如果有需要清理的资源（比如打开的文件、分配的内存），就可能泄露。

OCaml 标准库没有 `finally` 或 `try-with-resources` 这样的语法。但你可以用 `Fun.protect`（OCaml 4.08+）来实现类似的功能：

```ocaml
let with_file filename f =
  let chan = open_in filename in
  Fun.protect
    ~finally:(fun () -> close_in chan)
    (fun () -> f chan)
```

`Fun.protect ~finally work` 会执行 `work ()`，无论它正常返回还是抛出异常，都会执行 `finally ()`。如果 `work ()` 抛出了异常，`finally ()` 执行完后异常会继续传播。

### 12.10 本章小结

- 异常用 `exception` 定义，用 `raise` 抛出，用 `try...with` 捕获
- 异常可以带参数，携带错误上下文信息
- `exn` 是可扩展变体类型，可以随时添加新异常
- 标准库定义了 `Failure`、`Invalid_argument`、`Not_found` 等常用异常
- `failwith s` 是 `raise (Failure s)` 的简写
- 异常是不被类型系统追踪的副作用
- 预期内的错误用 option/result，真正的异常情况用异常
- 异常的抛出/捕获有性能开销，但如果很少发生就没关系
- 用 `Fun.protect` 做资源清理


---

---
上一章：[11 · 递归与尾递归](recursion.md) ｜ 下一章：[13 · 高阶函数与闭包](higher-order.md) ｜ 返回：[README](../README.md)
