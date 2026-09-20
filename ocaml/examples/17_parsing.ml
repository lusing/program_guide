(* ==========================================================================
   17_parsing.ml - 解析：词法分析与递归下降
   ==========================================================================
   主题：使用 OCaml 手写解析器
   内容：
     1. 定义 token 类型
     2. 手写词法器（lexer）
     3. 递归下降求值器
     4. 错误捕获与报告
     5. 词频统计
     6. 回文检测

   运行方式：
     ocaml 17_parsing.ml
     或
     utop # #use "17_parsing.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 定义 token 类型
   ========================================================================
   Token（标记）是词法分析的基本单位。
   我们为算术表达式定义以下 token 类型：
   - NUM: 数字
   - PLUS, MINUS, MUL, DIV: 运算符
   - LPAREN, RPAREN: 括号
   - EOF: 输入结束
*)
section 1 "Defining token types";;

type token =
  | NUM of float       (* 数字字面量 *)
  | PLUS               (* + *)
  | MINUS              (* - *)
  | MUL                (* * *)
  | DIV                (* / *)
  | LPAREN             (* ( *)
  | RPAREN             (* ) *)
  | EOF                (* 结束 *)

(* 打印 token 的辅助函数 *)
let string_of_token = function
  | NUM n -> Printf.sprintf "NUM(%.2f)" n
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | MUL -> "MUL"
  | DIV -> "DIV"
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | EOF -> "EOF"

let print_tokens tokens =
  Printf.printf "  Tokens: [%s]\n"
    (String.concat ", " (List.map string_of_token tokens));;

print_endline "Token type defined: NUM, PLUS, MINUS, MUL, DIV, LPAREN, RPAREN, EOF";;
print_endline "Tokens represent the atomic units of a language.";;

(* ========================================================================
   2) 手写词法器（lexer）
   ========================================================================
   词法器（lexer / tokenizer）将输入字符串转换为 token 列表。
   它逐个字符扫描，识别出数字、运算符、括号等。

   实现思路：
   - 跳过空白字符
   - 数字：连续的数字和小数点组成一个 NUM token
   - 运算符：单字符直接对应一个 token
   - 括号：单字符直接对应一个 token
*)
section 2 "Hand-written lexer";;

(* 词法器：将字符串转换为 token 列表 *)
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

  (* 读取数字（可能包含小数点） *)
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

  (* 主循环 *)
  while !pos < n do
    skip_whitespace ();
    if !pos >= n then ()
    else
      let c = input.[!pos] in
      match c with
      | '0'..'9' ->
          let tok = read_number () in
          tokens := tok :: !tokens
      | '+' -> tokens := PLUS :: !tokens; incr pos
      | '-' -> tokens := MINUS :: !tokens; incr pos
      | '*' -> tokens := MUL :: !tokens; incr pos
      | '/' -> tokens := DIV :: !tokens; incr pos
      | '(' -> tokens := LPAREN :: !tokens; incr pos
      | ')' -> tokens := RPAREN :: !tokens; incr pos
      | _ -> failwith (Printf.sprintf "lex: unexpected character '%c' at position %d" c !pos)
  done;

  tokens := EOF :: !tokens;
  List.rev !tokens

(* 测试词法器 *)
let test_lex input =
  Printf.printf "  Input: \"%s\"\n" input;
  try
    let tokens = lex input in
    print_tokens tokens
  with Failure msg ->
    Printf.printf "  Error: %s\n" msg;;

test_lex "3 + 4";;
test_lex "12.5 * (3 - 7) / 2";;
test_lex "1 + 2 * 3 - 4 / 5";;
test_lex "((1 + 2) * (3 + 4))";;

(* ========================================================================
   3) 递归下降求值器
   ========================================================================
   递归下降解析（Recursive Descent Parsing）：
   - 一种自顶向下的解析方法
   - 每个非终结符对应一个函数
   - 函数之间相互调用（可能递归）
   - 适合 LL(1) 文法

   算术表达式文法（考虑优先级）：
     expr   -> term ( ( '+' | '-' ) term )*
     term   -> factor ( ( '*' | '/' ) factor )*
     factor -> NUM | '(' expr ')' | '-' factor
*)
section 3 "Recursive descent evaluator";;

(* 解析器状态：token 列表和当前位置 *)
type parser_state = {
  tokens : token list;
  pos : int;
}

let peek state = List.nth state.tokens state.pos
let advance state = { state with pos = state.pos + 1 }

(* 解析 factor: NUM | '(' expr ')' | '-' factor *)
let rec parse_factor state =
  match peek state with
  | NUM n ->
      (n, advance state)
  | LPAREN ->
      let state1 = advance state in
      let (value, state2) = parse_expr state1 in
      (match peek state2 with
       | RPAREN -> (value, advance state2)
       | _ -> failwith "parse_factor: expected ')'")
  | MINUS ->
      let state1 = advance state in
      let (value, state2) = parse_factor state1 in
      (-. value, state2)
  | tok ->
      failwith (Printf.sprintf "parse_factor: unexpected token %s" (string_of_token tok))

(* 解析 term: factor ( ( '*' | '/' ) factor )* *)
and parse_term state =
  let rec loop left_value state =
    match peek state with
    | MUL ->
        let state1 = advance state in
        let (right_value, state2) = parse_factor state1 in
        loop (left_value *. right_value) state2
    | DIV ->
        let state1 = advance state in
        let (right_value, state2) = parse_factor state1 in
        if right_value = 0.0 then failwith "parse_term: division by zero"
        else loop (left_value /. right_value) state2
    | _ -> (left_value, state)
  in
  let (first_value, state1) = parse_factor state in
  loop first_value state1

(* 解析 expr: term ( ( '+' | '-' ) term )* *)
and parse_expr state =
  let rec loop left_value state =
    match peek state with
    | PLUS ->
        let state1 = advance state in
        let (right_value, state2) = parse_term state1 in
        loop (left_value +. right_value) state2
    | MINUS ->
        let state1 = advance state in
        let (right_value, state2) = parse_term state1 in
        loop (left_value -. right_value) state2
    | _ -> (left_value, state)
  in
  let (first_value, state1) = parse_term state in
  loop first_value state1

(* 完整求值函数 *)
let evaluate input =
  let tokens = lex input in
  let state = { tokens = tokens; pos = 0 } in
  let (value, final_state) = parse_expr state in
  (match peek final_state with
   | EOF -> ()
   | tok -> failwith (Printf.sprintf "evaluate: unexpected token after expression: %s"
                        (string_of_token tok)));
  value

(* 测试求值器 *)
let test_eval input =
  try
    let result = evaluate input in
    Printf.printf "  %s = %.4f\n" input result
  with Failure msg ->
    Printf.printf "  %s -> Error: %s\n" input msg;;

test_eval "3 + 4";;
test_eval "10 - 3";;
test_eval "5 * 6";;
test_eval "20 / 4";;
test_eval "2 + 3 * 4";;
test_eval "(2 + 3) * 4";;
test_eval "10 - 3 - 2";;
test_eval "100 / 5 / 2";;
test_eval "-5 + 3";;
test_eval "-(3 + 4) * 2";;
test_eval "2.5 + 3.7 * 2";;
test_eval "((1 + 2) * (3 + 4)) / 5";;

(* ========================================================================
   4) 错误捕获与报告
   ========================================================================
   使用异常机制捕获和报告解析错误。
   自定义异常类型可以携带更丰富的错误信息（位置、期望的 token 等）。
*)
section 4 "Error handling and reporting";;

(* 自定义解析异常 *)
exception Parse_error of string * int  (* 错误消息和位置 *)

(* 改进的词法器：抛出更精确的异常 *)
let lex_with_error input =
  let n = String.length input in
  let pos = ref 0 in
  let tokens = ref [] in

  let skip_whitespace () =
    while !pos < n && (input.[!pos] = ' ' || input.[!pos] = '\t' ||
                       input.[!pos] = '\n' || input.[!pos] = '\r') do
      incr pos
    done
  in

  let read_number () =
    let start = !pos in
    let has_dot = ref false in
    while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
      incr pos
    done;
    if !pos < n && input.[!pos] = '.' then begin
      has_dot := true;
      incr pos;
      while !pos < n && (input.[!pos] >= '0' && input.[!pos] <= '9') do
        incr pos
      done
    end;
    if !has_dot && input.[!pos - 1] = '.' then
      raise (Parse_error ("invalid number format", start));
    let num_str = String.sub input start (!pos - start) in
    NUM (float_of_string num_str)
  in

  while !pos < n do
    skip_whitespace ();
    if !pos >= n then ()
    else
      let c = input.[!pos] in
      match c with
      | '0'..'9' ->
          let tok = read_number () in
          tokens := tok :: !tokens
      | '+' -> tokens := PLUS :: !tokens; incr pos
      | '-' -> tokens := MINUS :: !tokens; incr pos
      | '*' -> tokens := MUL :: !tokens; incr pos
      | '/' -> tokens := DIV :: !tokens; incr pos
      | '(' -> tokens := LPAREN :: !tokens; incr pos
      | ')' -> tokens := RPAREN :: !tokens; incr pos
      | _ -> raise (Parse_error (Printf.sprintf "unexpected character '%c'" c, !pos))
  done;

  tokens := EOF :: !tokens;
  List.rev !tokens

(* 错误报告函数 *)
let report_error input msg pos =
  Printf.printf "  Parse error at position %d: %s\n" pos msg;
  Printf.printf "  Input: %s\n" input;
  Printf.printf "         %s^\n" (String.make pos ' ')

(* 安全求值：捕获异常并报告 *)
let safe_evaluate input =
  try
    let tokens = lex_with_error input in
    let state = { tokens = tokens; pos = 0 } in
    let (value, final_state) = parse_expr state in
    (match peek final_state with
     | EOF -> ()
     | _ -> raise (Parse_error ("unexpected token after expression", final_state.pos)));
    Printf.printf "  %s = %.4f\n" input value
  with
  | Parse_error (msg, pos) -> report_error input msg pos
  | Failure msg -> Printf.printf "  Error: %s\n" msg;;

print_endline "Testing error handling:";
safe_evaluate "3 + 4";;
safe_evaluate "3 + + 4";;
safe_evaluate "(3 + 4";;
safe_evaluate "3 + 4)";;
safe_evaluate "10 / 0";;
safe_evaluate "3 @ 4";;
safe_evaluate "1.2.3 + 4";;

(* ========================================================================
   5) 词频统计
   ========================================================================
   词频统计（Word Frequency Count）：
   - 将文本分割成单词
   - 统计每个单词出现的次数
   - 按频率排序输出

   这是文本处理中常见的任务，结合了字符串处理和哈希表的使用。
*)
section 5 "Word frequency count";;

(* 将文本分割成单词（简单版本：按空白和标点分割） *)
let split_words text =
  let n = String.length text in
  let words = ref [] in
  let current = Buffer.create 16 in
  for i = 0 to n - 1 do
    let c = text.[i] in
    match c with
    | 'a'..'z' | 'A'..'Z' | '0'..'9' | '\'' | '-' ->
        Buffer.add_char current c
    | _ ->
        if Buffer.length current > 0 then begin
          words := Buffer.contents current :: !words;
          Buffer.clear current
        end
  done;
  if Buffer.length current > 0 then
    words := Buffer.contents current :: !words;
  List.rev !words

(* 转小写（简单实现） *)
let to_lower s =
  String.map (fun c ->
    if c >= 'A' && c <= 'Z' then
      Char.chr (Char.code c + 32)
    else c
  ) s

(* 词频统计 *)
let word_frequency text =
  let words = split_words text in
  let freq = Hashtbl.create 100 in
  List.iter (fun w ->
    let w' = to_lower w in
    let count = try Hashtbl.find freq w' with Not_found -> 0 in
    Hashtbl.replace freq w' (count + 1)
  ) words;
  freq

(* 按频率排序输出 *)
let print_frequencies freq =
  let entries = Hashtbl.fold (fun w c acc -> (w, c) :: acc) freq [] in
  let sorted = List.sort (fun (_, c1) (_, c2) -> compare c2 c1) entries in
  List.iteri (fun i (w, c) ->
    Printf.printf "  %2d. %-15s %d\n" (i + 1) w c
  ) sorted

(* 测试文本 *)
let sample_text = "
The quick brown fox jumps over the lazy dog.
The dog barks, the fox runs.
Quick brown fox, lazy dog.
Over and over, the fox jumps.
";;

let () =
  print_endline "Word frequency analysis:";
  let freq = word_frequency sample_text in
  print_frequencies freq;

  (* 更多统计 *)
  let total_words = Hashtbl.fold (fun _ c acc -> acc + c) freq 0 in
  let unique_words = Hashtbl.length freq in
  Printf.printf "\n  Total words: %d\n" total_words;
  Printf.printf "  Unique words: %d\n" unique_words;

  (* 查找最常见的单词 *)
  let most_common freq =
    Hashtbl.fold (fun w c (mw, mc) ->
      if c > mc then (w, c) else (mw, mc)
    ) freq ("", 0) in
  let top_word, top_count = most_common freq in
  Printf.printf "  Most common: \"%s\" (%d times)\n" top_word top_count;;

(* ========================================================================
   6) 回文检测
   ========================================================================
   回文（Palindrome）：正读和反读都一样的字符串。
   例如："level", "racecar", "A man a plan a canal Panama"

   实现思路：
   - 预处理：转小写，移除非字母数字字符
   - 检查：比较首尾对应字符
*)
section 6 "Palindrome detection";;

(* 检查字符是否是字母数字 *)
let is_alnum c =
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9')

(* 预处理字符串：保留字母数字并转小写 *)
let preprocess s =
  let buf = Buffer.create (String.length s) in
  String.iter (fun c ->
    if is_alnum c then
      Buffer.add_char buf (
        if c >= 'A' && c <= 'Z' then
          Char.chr (Char.code c + 32)
        else c
      )
  ) s;
  Buffer.contents buf

(* 简单的回文检测：反转后比较 *)
let is_palindrome_simple s =
  let clean = preprocess s in
  let reversed =
    let n = String.length clean in
    String.init n (fun i -> clean.[n - 1 - i])
  in
  clean = reversed

(* 更高效的版本：双指针法 *)
let is_palindrome s =
  let clean = preprocess s in
  let n = String.length clean in
  let rec check left right =
    if left >= right then true
    else if clean.[left] <> clean.[right] then false
    else check (left + 1) (right - 1)
  in
  check 0 (n - 1)

(* 测试回文检测 *)
let test_palindrome s =
  let result = is_palindrome s in
  Printf.printf "  \"%s\" -> %b\n" s result;;

print_endline "Palindrome tests:";
test_palindrome "level";;
test_palindrome "racecar";;
test_palindrome "hello";;
test_palindrome "A man a plan a canal Panama";;
test_palindrome "Was it a car or a cat I saw";;
test_palindrome "No lemon no melon";;
test_palindrome "12321";;
test_palindrome "12345";;
test_palindrome "";;
test_palindrome "a";;

(* 找出最长回文子串（中心扩展法） *)
let longest_palindromic_substring s =
  let clean = preprocess s in
  let n = String.length clean in
  if n = 0 then ""
  else
    let expand left right =
      let l = ref left and r = ref right in
      while !l >= 0 && !r < n && clean.[!l] = clean.[!r] do
        decr l; incr r
      done;
      (!l + 1, !r - 1)
    in
    let best_start = ref 0 in
    let best_end = ref 0 in
    for i = 0 to n - 1 do
      (* 奇数长度回文 *)
      let s1, e1 = expand i i in
      if e1 - s1 > !best_end - !best_start then begin
        best_start := s1;
        best_end := e1
      end;
      (* 偶数长度回文 *)
      if i + 1 < n then begin
        let s2, e2 = expand i (i + 1) in
        if e2 - s2 > !best_end - !best_start then begin
          best_start := s2;
          best_end := e2
        end
      end
    done;
    String.sub clean !best_start (!best_end - !best_start + 1);;

print_endline "\nLongest palindromic substring:";;
let test_lps s =
  let lps = longest_palindromic_substring s in
  Printf.printf "  \"%s\" -> \"%s\" (length %d)\n" s lps (String.length lps);;

test_lps "babad";;
test_lps "cbbd";;
test_lps "abcba12321";;
test_lps "a";;
test_lps "forgeeksskeegfor";;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 17 jieshu ===="  (* 第十七个文件结束 *)
