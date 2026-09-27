# 27 · 错误处理：option / result 与绑定运算符

对应示例：`../examples/23_error_handling.ml`

对应示例：`examples/23_error_handling.ml`

### 27.1 三种失败通道

OCaml 处理失败有三个层次：异常（不可见、易忘）、`option`
（失败无细节）、`result`（失败带原因、类型逼你处理）。第 12 章
讲过异常；本章讲后两者以及把它们写顺的语法——绑定运算符。

```ocaml
let safe_div a b = if b = 0 then None else Some (a / b)

let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not an int: %S" s)
```

### 27.2 嵌套 match 的痛苦与组合子

三层可能失败的操作套起来，手写 match 是三层缩进；用
`Option.bind` / `Option.map`（或 `Result.bind` / `Result.map`）
可以拉平一层。`Stdlib` 里两者都齐全，还有
`Result.product`（两个独立计算任一失败即失败）、
`Result.map_error`（只改错误信息）、
`Option.to_result ~none:...`（给 None 补上原因）。

### 27.3 绑定运算符的真相：let\* 是算子值，要自己接线

OCaml 4.08 引入了 `let*` / `and*` / `let+` / `and+` 绑定运算符，
让失败链可以“直着写”：

```ocaml
let word_len_times2 s =
  let open Option_syntax in
  let* parts = safe_head (String.split_on_char ' ' s) in
  let* n = int_of_string_opt parts in
  Some (n * 2)
```

**关键事实（很多人第一反应都错）**：`let*` 不是“脱糖后去查找
名为 `bind` 的函数”，而是脱糖为一个**字面名为 `( let* )` 的算子值**：

```ocaml
let* x = e in body    ≡    ( let* ) e (fun x -> body)
```

`Stdlib.Option` / `Stdlib.Result` 只提供了 `bind` / `map` /
`product` 函数，**并没有定义这些算子**——所以直接
`let open Result in let* ...` 会报：

```
Error: Unbound value ( let* )
```

想用绑定运算符，必须自己接线（算子名遵循普通作用域规则，
可以定义在顶层，也可以收进模块再 open）：

```ocaml
module Result_syntax = struct
  let ( let* ) = Result.bind
  let ( and* ) = Result.product
  let ( let+ ) r f = match r with Ok x -> Ok (f x) | Error e -> Error e
end
```

两个实测细节：

1. **`( let+ )` 的参数序是“值在前、函数在后”**，恰好与
   `Option.map` / `Result.map`（函数在前）相反，不能直接把
   `map` 赋给 `( let+ )`。
2. `Stdlib.Option` 连 `product` 都没有，`and*` 也要自己写。

### 27.4 and\* 的语义由实现说了算：fail-fast vs 累积

`and*` 脱糖到 `( and* )`——同一个写法，换个实现就是换种语义：

- `Result.product`：任一失败即失败（fail-fast）；
- 自制 `Validation` 模块：把两边错误列表 `@` 拼起来，**所有
  错误一起报**——表单校验最想要的形态。

示例 23 的第 6 节完整实现了 60 行不到的 `Validation`，
同一个 `validate_user`，错误全量列出：

```
all bad  : Error [name is empty; age too large (max 150); email missing '@']
```

### 27.5 选型法则

- 异常：编程错误、真正异常的路径（不出现在类型里）；
- option：失败没什么可说的（查找、除零、解析）；
- result：失败要带原因、调用方必须处理。

`try ... with Sys_error msg -> Error msg` 是把异常世界接进
result 世界的标准桥。

### 27.6 本章小结

- `let*`/`and*`/`let+` 是算子值，Stdlib 不自带，需自己接线；
- 接线时注意 `( let+ )` 值在前的参数序；
- `and*` 语义看实现：product 是 fail-fast，自制 Validation 可累积；
- 负数字面量作实参要加括号：`f "bob" (-1) "x"`。

---

---
上一章：[26 · 综合实战：成绩 CSV 分析与报告](project.md) ｜ 下一章：[28 · GADT：广义代数数据类型](gadts.md) ｜ 返回：[README](../README.md)
