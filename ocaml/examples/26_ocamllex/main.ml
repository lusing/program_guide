(* ==========================================================================
   26_ocamllex/main.ml - ocamllex 实战：token 流、错误定位、递归下降求值
   ==========================================================================
   与 17_parsing 的手写词法器对比：正则交给 ocamllex，
   我们只写"动作"和文法。main.ml 与生成的 Ocamllex_expr 模块链接。
   构建链：ocamllex ocamllex_expr.mll  →  ocamllex_expr.ml
           ocamlc ocamllex_expr.ml main.ml -o 26_ocamllex
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

open Ocamllex_expr;;

let token_name = function
  | INT _ -> "INT" | FLOAT _ -> "FLOAT" | ID _ -> "ID"
  | LET -> "LET" | IF -> "IF" | THEN -> "THEN" | ELSE -> "ELSE"
  | PLUS -> "PLUS" | MINUS -> "MINUS" | STAR -> "STAR" | SLASH -> "SLASH"
  | PERCENT -> "PERCENT" | CARET -> "CARET"
  | LPAREN -> "LPAREN" | RPAREN -> "RPAREN"
  | EQUAL -> "EQUAL" | SEMI -> "SEMI"
  | EOF -> "EOF";;

let token_detail = function
  | INT n -> Printf.sprintf "INT %d" n
  | FLOAT f -> Printf.sprintf "FLOAT %g" f
  | ID s -> Printf.sprintf "ID %s" s
  | t -> token_name t;;

(* ========================================================================
   1) token 流：把字符串词法化并打印
   ======================================================================== *)
section 1 "tokenizing a string with the generated lexer";;

let tokenize_string s =
  let lb = Lexing.from_string s in
  let rec loop acc =
    let t = token lb in
    if t = EOF then List.rev acc else loop (t :: acc)
  in
  loop [];;

let () =
  let src = "let x = 3.14 * 2;\n// a comment line\nx ^ 2 + (y - 1) % 5" in
  let ts = tokenize_string src in
  Printf.printf "source:\n%s\ntokens (%d):\n" src (List.length ts);
  List.iter (fun t -> Printf.printf "  %s\n" (token_detail t)) ts;;

(* ========================================================================
   2) 最长匹配与行号：ocamllex 的核心语义
   ======================================================================== *)
section 2 "maximal munch and line tracking";;

let () =
  (* 3.14 不会被切成 3 / . / 14：规则集合里能匹配的最长者胜出 *)
  let ts = tokenize_string "3.14 42 1e-3" in
  List.iter (fun t -> Printf.printf "  %s\n" (token_detail t)) ts;;

(* 换行规则里调用了 Lexing.new_line，pos_lnum 一直是准的 *)
let () =
  let bad = "1 + 2\n3 + $oops" in
  Printf.printf "source with bad char on line 2:\n%s\n" bad;
  (try
     ignore (tokenize_string bad);
     print_endline "no error?!"
   with Failure msg ->
     Printf.printf "lex error: %s\n" msg);;

(* ========================================================================
   3) 递归下降求值器：站在生成的 lexer 上
   ======================================================================== *)
section 3 "a recursive-descent evaluator on top of the lexer";;

(* 文法（无二义性）：
     program := stmt*
     stmt    := 'let' ID '=' expr ';'
              | expr
     expr    := term (('+'|'-') term)*
     term    := factor (('*'|'/'|'%') factor)*
     factor  := unary ('^' factor)?              右结合
     unary   := '-' unary | atom
     atom    := INT | FLOAT | ID | '(' expr ')'
              | 'if' expr 'then' expr 'else' expr *)

type env = (string, float) Hashtbl.t;;

(* 一格 lookahead 的解析器状态：缓存下一个 token *)
type parser = { lb : Lexing.lexbuf; mutable peeked : token option; env : env };;

let next_tok p =
  match p.peeked with
  | Some t -> p.peeked <- None; t
  | None -> token p.lb;;

let peek_tok p =
  match p.peeked with
  | Some t -> t
  | None ->
      let t = token p.lb in
      p.peeked <- Some t;
      t;;

let parse_error p msg =
  let pos = p.lb.Lexing.lex_curr_p in
  failwith (Printf.sprintf "line %d: %s" pos.Lexing.pos_lnum msg);;

let expect p want =
  let got = next_tok p in
  if got <> want then
    parse_error p (Printf.sprintf "expected %s, got %s"
                     (token_name want) (token_detail got));;

(* 值统一用 float 计算；INT 在叶子处提升。
   左结合的二元运算层级用累积器循环；^ 右结合则自然递归 *)
let rec parse_expr p env =
  let rec loop acc =
    match peek_tok p with
    | PLUS -> ignore (next_tok p); loop (acc +. parse_term p env)
    | MINUS -> ignore (next_tok p); loop (acc -. parse_term p env)
    | _ -> acc
  in
  loop (parse_term p env)

and parse_term p env =
  let rec loop acc =
    match peek_tok p with
    | STAR -> ignore (next_tok p); loop (acc *. parse_factor p env)
    | SLASH ->
        ignore (next_tok p);
        let r = parse_factor p env in
        if r = 0.0 then parse_error p "division by zero"
        else loop (acc /. r)
    | PERCENT ->
        ignore (next_tok p);
        (* 取余按整数语义处理 *)
        let r = parse_factor p env in
        loop (Float.of_int (Int.rem (int_of_float acc) (int_of_float r)))
    | _ -> acc
  in
  loop (parse_factor p env)

and parse_factor p env =
  let base = parse_unary p env in
  match peek_tok p with
  | CARET -> ignore (next_tok p); Float.pow base (parse_factor p env)
  | _ -> base

and parse_unary p env =
  match peek_tok p with
  | MINUS -> ignore (next_tok p); -. (parse_unary p env)
  | _ -> parse_atom p env

and parse_atom p env =
  match next_tok p with
  | INT n -> Float.of_int n
  | FLOAT f -> f
  | ID name ->
      (match Hashtbl.find_opt env name with
       | Some v -> v
       | None -> parse_error p (Printf.sprintf "unbound variable %s" name))
  | LPAREN ->
      let v = parse_expr p env in
      expect p RPAREN;
      v
  | IF ->
      let c = parse_expr p env in
      expect p THEN;
      let t = parse_expr p env in
      expect p ELSE;
      let e = parse_expr p env in
      if c <> 0.0 then t else e
  | t -> parse_error p (Printf.sprintf "unexpected %s" (token_detail t))

let run_program src =
  let env : env = Hashtbl.create 16 in
  let p = { lb = Lexing.from_string src; peeked = None; env } in
  let rec loop last =
    match peek_tok p with
    | EOF -> last
    | SEMI -> ignore (next_tok p); loop last
    | LET ->
        ignore (next_tok p);
        (match next_tok p with
         | ID name ->
             expect p EQUAL;
             let v = parse_expr p env in
             Hashtbl.replace env name v;
             Printf.printf "  let %s = %g\n" name v;
             loop v
         | t -> parse_error p (Printf.sprintf "expected ID after let, got %s"
                                 (token_detail t)))
    | _ ->
        let v = parse_expr p env in
        Printf.printf "  = %g\n" v;
        loop v
  in
  loop nan;;

let () =
  print_endline "program 1:";
  ignore (run_program "1 + 2 * 3");
  print_endline "program 2 (let-bindings):";
  ignore (run_program "let x = 3.14 * 2; x ^ 2 + (x - 1) % 5");
  print_endline "program 3 (if-then-else):";
  ignore (run_program "let a = 10; if a - 10 then 1 + 1 else 2 ^ 3");
  print_endline "program 4 (division by zero is caught):";
  (try ignore (run_program "1 / 0")
   with Failure msg -> Printf.printf "  caught: %s\n" msg);;

(* ========================================================================
   4) 从文件词法化：Lexing.from_channel
   ======================================================================== *)
section 4 "lexing from a channel";;

let () =
  (* 把一段源码写进临时文件，再从 channel 词法化 *)
  let path = Filename.temp_file "ocamllex_demo" ".ml" in
  let oc = open_out path in
  output_string oc "42 * (10 - 4)\n";
  close_out oc;
  let ic = open_in path in
  let lb = Lexing.from_channel ic in
  let rec loop () =
    let t = token lb in
    if t <> EOF then (Printf.printf "  %s\n" (token_detail t); loop ())
  in
  loop ();
  close_in ic;
  Sys.remove path;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 26 jieshu ===="  (* 第二十六个文件结束 *)
