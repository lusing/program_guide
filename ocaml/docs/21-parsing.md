# 21 · 解析：词法分析与递归下降

对应示例：`../examples/17_parsing.ml`

对应示例：`examples/17_parsing.ml`

### 21.1 什么是解析

解析（parsing）是把一段文本（源代码、数据文件、配置文件等）转换成结构化数据的过程。它是编译器、解释器、数据处理工具的核心组件。

解析通常分为两个阶段：

1. **词法分析（Lexical Analysis）**：把输入字符串切分成一个个 token（标记）。比如把 `"1 + 2 * 3"` 切分成 `[NUM(1); PLUS; NUM(2); MUL; NUM(3)]`。

2. **语法分析（Syntactic Analysis）**：把 token 流按照语法规则组织成抽象语法树（AST）或直接计算出结果。

为什么要分成两步？因为这样每一步都更简单：
- 词法器只关心单个字符和简单模式（数字、标识符、运算符）
- 语法分析器只关心 token 之间的结构关系，不用管空白、注释、数字怎么解析

### 21.2 定义 Token 类型

我们用变体类型来定义 token。以算术表达式为例：

```ocaml
type token =
  | NUM of float       (* 数字字面量 *)
  | PLUS               (* + *)
  | MINUS              (* - *)
  | MUL                (* * *)
  | DIV                (* / *)
  | LPAREN             (* ( *)
  | RPAREN             (* ) *)
  | EOF                (* 输入结束 *)
```

每个变体构造子对应一种语法单位。`NUM` 携带一个 float 参数，表示具体的数值。`EOF` 标记输入结束，帮助解析器判断何时停止。

用变体类型定义 token 的好处：
- 编译器可以检查模式匹配是否穷尽
- 每个 token 的类型信息一目了然
- 添加新 token 很方便

### 21.3 手写词法器（Lexer）

词法器（也叫 tokenizer）的任务是把输入字符串转换成 token 列表。

基本思路：
- 维护一个当前位置指针
- 跳过空白字符（空格、制表符、换行）
- 根据当前字符判断是什么 token
- 数字：读入连续的数字和小数点，转成 float
- 运算符和括号：单个字符对应一个 token

```ocaml
let lex input =
  let n = String.length input in
  let pos = ref 0 in
  let tokens = ref [] in

  (* 跳过空白字符 *)
  let skip_whitespace () =
    while !pos < n && (input.[!pos] = ' ' || input.[!pos] = '\t' ||
                       input.[!pos] = '\n' || input.[!pos] = '\r') do
      incr pos
    done
  in

  (* 读取数字（整数或小数） *)
  let read_number () =
    let start = !pos in
    while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
      incr pos
    done;
    if !pos < n && input.[!pos] = '.' then begin
      incr pos;
      while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
        incr pos
      done
    end;
    let num_str = String.sub input start (!pos - start) in
    NUM (float_of_string num_str)
  in

  (* 主循环：逐个 token 读取 *)
  let rec tokenize () =
    skip_whitespace ();
    if !pos >= n then
      List.rev (EOF :: !tokens)
    else
      let c = input.[!pos] in
      let token =
        match c with
        | '0'..'9' -> read_number ()
        | '+' -> incr pos; PLUS
        | '-' -> incr pos; MINUS
        | '*' -> incr pos; MUL
        | '/' -> incr pos; DIV
        | '(' -> incr pos; LPAREN
        | ')' -> incr pos; RPAREN
        | _ -> failwith (Printf.sprintf "unexpected character '%c' at position %d" c !pos)
      in
      tokens := token :: !tokens;
      tokenize ()
  in
  tokenize ()
```

测试一下：

```ocaml
let _ =
  let tokens = lex "1 + 2 * 3" in
  (* [NUM 1.0; PLUS; NUM 2.0; MUL; NUM 3.0; EOF] *)
  List.iter (function
    | NUM n -> Printf.printf "NUM(%.1f) " n
    | PLUS -> print_string "PLUS "
    | MINUS -> print_string "MINUS "
    | MUL -> print_string "MUL "
    | DIV -> print_string "DIV "
    | LPAREN -> print_string "LPAREN "
    | RPAREN -> print_string "RPAREN "
    | EOF -> print_string "EOF\n"
  ) tokens
```

词法器用了可变状态（`pos` 引用、`tokens` 引用）来跟踪进度。这是一个典型的「用命令式风格实现更自然」的场景——词法分析本质上就是逐字符扫描、维护状态。

### 21.4 递归下降解析器的原理

递归下降（Recursive Descent）是手写解析器最常用的方法。它的思路很简单：

1. 为每个语法规则写一个函数
2. 函数之间可以互相调用（对应语法规则中的非终结符引用）
3. 函数自己调用自己（对应递归的语法规则）

算术表达式的语法规则（BNF 范式）：
```
expr   ::= term (('+' | '-') term)*
term   ::= factor (('*' | '/') factor)*
factor ::= NUM | '(' expr ')'
```

这个语法表达了运算符优先级：
- 乘除（`*`、`/`）的优先级高于加减（`+`、`-`）
- 括号可以改变优先级
- 同优先级从左到右结合

对应的递归下降解析器就有三个函数：`parse_expr`、`parse_term`、`parse_factor`，它们互相调用、自己调用自己。

### 21.5 手写递归下降求值器

我们来实现一个算术表达式求值器——它不构造 AST，而是边解析边计算结果。

首先，我们需要一个「当前 token 指针」的概念。解析器维护一个 token 列表和当前位置。

```ocaml
type parser_state = {
  tokens : token array;
  mutable pos : int;
}

let peek state = state.tokens.(state.pos)
let advance state = state.pos <- state.pos + 1
let expect state token msg =
  if peek state <> token then
    failwith (Printf.sprintf "expected %s, got %s at position %d"
                msg "?" state.pos)
  else advance state
```

然后按照语法规则写三个解析函数：

```ocaml
let rec parse_expr state =
  let left = parse_term state in
  parse_expr_rest state left

and parse_expr_rest state acc =
  match peek state with
  | PLUS ->
      advance state;
      let right = parse_term state in
      parse_expr_rest state (acc +. right)
  | MINUS ->
      advance state;
      let right = parse_term state in
      parse_expr_rest state (acc -. right)
  | _ -> acc

and parse_term state =
  let left = parse_factor state in
  parse_term_rest state left

and parse_term_rest state acc =
  match peek state with
  | MUL ->
      advance state;
      let right = parse_factor state in
      parse_term_rest state (acc *. right)
  | DIV ->
      advance state;
      let right = parse_factor state in
      if right = 0.0 then failwith "division by zero"
      else parse_term_rest state (acc /. right)
  | _ -> acc

and parse_factor state =
  match peek state with
  | NUM n ->
      advance state;
      n
  | LPAREN ->
      advance state;
      let result = parse_expr state in
      expect state RPAREN "')'";
      result
  | _ -> failwith "unexpected token in factor"
```

注意这个结构：
- `parse_expr` 先解析一个 term，然后循环解析后续的 `+ term` 或 `- term`
- `parse_term` 先解析一个 factor，然后循环解析后续的 `* factor` 或 `/ factor`
- `parse_factor` 处理最基本的单位：数字或括号表达式

这种「先解析一个左操作数，再循环处理右操作数」的模式叫做**尾递归消除左递归**。直接写左递归的语法（`expr ::= expr '+' term`）会导致无限递归，所以我们把它改成了右递归 + 累加的形式。

最后，一个入口函数：

```ocaml
let eval input =
  let tokens = lex input in
  let state = { tokens = Array.of_list tokens; pos = 0 } in
  let result = parse_expr state in
  if peek state <> EOF then
    failwith "unexpected tokens after expression"
  else result
```

测试：

```ocaml
let _ =
  Printf.printf "1 + 2 * 3 = %.2f\n" (eval "1 + 2 * 3");   (* 7.00 *)
  Printf.printf "(1 + 2) * 3 = %.2f\n" (eval "(1 + 2) * 3"); (* 9.00 *)
  Printf.printf "10 - 2 * 3 + 4 / 2 = %.2f\n" (eval "10 - 2 * 3 + 4 / 2") (* 6.00 *)
```

### 21.6 错误的捕获与报告

解析器需要处理各种错误情况：非法字符、语法错误、括号不匹配等等。

上面的实现用了 `failwith` 来抛出异常，这是最简单的做法。但错误信息不够友好——用户只知道「出错了」，但不知道具体在哪里、为什么。

一个更好的做法是定义专门的解析异常，携带位置信息：

```ocaml
exception Parse_error of int * string   (* 位置, 错误信息 *)

let parse_error state msg =
  raise (Parse_error (state.pos, msg))
```

然后在顶层捕获异常，给出友好的错误信息：

```ocaml
let eval_safe input =
  try
    let tokens = lex input in
    let state = { tokens = Array.of_list tokens; pos = 0 } in
    let result = parse_expr state in
    if peek state <> EOF then
      Error "unexpected tokens after expression"
    else Ok result
  with
  | Failure msg -> Error msg
  | Parse_error (pos, msg) ->
      Error (Printf.sprintf "parse error at position %d: %s" pos msg)
```

这里我们用 `result` 类型（`Ok` 或 `Error`）来表示成功或失败，而不是让异常向上传播——这是一种更函数式的错误处理方式。

### 21.7 实战：词频统计

我们来写一个更实用的解析任务：统计一段文本中每个单词出现的次数。

```ocaml
let word_frequency text =
  let table = Hashtbl.create 100 in
  let n = String.length text in
  let i = ref 0 in

  while !i < n do
    (* 跳过非字母字符 *)
    while !i < n && not (text.[!i] |> function
      | 'a'..'z' | 'A'..'Z' | '0'..'9' | '\'' -> true
      | _ -> false) do
      incr i
    done;
    if !i < n then begin
      let start = !i in
      (* 读取一个单词 *)
      while !i < n && (match text.[!i] with
        | 'a'..'z' | 'A'..'Z' | '0'..'9' | '\'' -> true
        | _ -> false) do
        incr i
      done;
      let word = String.sub text start (!i - start)
                 |> String.lowercase_ascii in
      (* 更新计数 *)
      let count = match Hashtbl.find_opt table word with
        | Some c -> c + 1
        | None -> 1
      in
      Hashtbl.replace table word count
    end
  done;
  table
```

```ocaml
let _ =
  let text = "The quick brown fox jumps over the lazy dog. The dog barks." in
  let freq = word_frequency text in
  Hashtbl.iter (fun word count ->
    Printf.printf "%s: %d\n" word count
  ) freq
```

词频统计是自然语言处理中最基础的任务之一，也是解析思维的应用——你需要识别「单词」这个单位，然后统计它们的分布。

### 21.8 实战：回文检测

回文（palindrome）是指正着读和倒着读一样的字符串，比如 "level"、"racecar"。

一个更复杂的版本：忽略大小写和非字母数字字符。

```ocaml
let is_palindrome s =
  let n = String.length s in
  let left = ref 0 in
  let right = ref (n - 1) in
  let is_alnum c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
  in
  let result = ref true in
  while !left < !right && !result do
    (* 左边跳过非字母数字 *)
    while !left < !right && not (is_alnum s.[!left]) do
      incr left
    done;
    (* 右边跳过非字母数字 *)
    while !left < !right && not (is_alnum s.[!right]) do
      decr right
    done;
    if !left < !right then begin
      if Char.lowercase_ascii s.[!left] <> Char.lowercase_ascii s.[!right] then
        result := false
      else begin
        incr left;
        decr right
      end
    end
  done;
  !result
```

```ocaml
let _ =
  print_bool (is_palindrome "racecar");            (* true *)
  print_bool (is_palindrome "hello");              (* false *)
  print_bool (is_palindrome "A man, a plan, a canal: Panama")   (* true *)
```

这个例子展示了双指针技术——同时从两端向中间扫描，跳过不需要的字符，比较有效字符。

### 21.9 本章小结

- 解析分为词法分析和语法分析两个阶段
- Token 用变体类型定义，每个构造子对应一种语法单位
- 词法器逐字符扫描输入，生成 token 列表
- 递归下降解析器：每个语法规则对应一个函数，函数间互相调用
- 语法规则的层次结构自然表达了运算符优先级
- 左递归需要转换成尾递归 + 累加的形式，防止无限递归
- 解析错误应该携带位置信息，方便定位问题
- 词频统计、回文检测是解析思维的常见应用

---

---
上一章：[20 · 数值计算](numeric.md) ｜ 下一章：[22 · 输入输出与文件](io.md) ｜ 返回：[README](../README.md)
