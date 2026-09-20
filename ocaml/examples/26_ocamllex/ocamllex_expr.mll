(* ==========================================================================
   ocamllex_expr.mll - ocamllex 词法器：表达式语言
   ==========================================================================
   ocamllex 从 .mll 规则文件生成 .ml 词法器。
   注意：生成的模块名取自文件名，所以 .mll 不能用数字开头命名
   （本教程因此把它放进 26_ocamllex/ 子目录，模块名 Ocamllex_expr）。

   结构：
     { ... }   header：原样拷贝到生成文件开头（类型、辅助函数）
     rule ... = parse
       | 正则 { 动作 }      每条规则 = 模式 + 生成代码
   匹配规则：最长匹配优先（maximal munch），同长才看声明顺序。
   lexbuf 是隐式参数，token lexbuf 驱动下一次扫描。
   ========================================================================== *)

{
(* ---- header：进入生成的 Ocamllex_expr.ml ---- *)

type token =
  | INT of int
  | FLOAT of float
  | ID of string
  | LET
  | IF
  | THEN
  | ELSE
  | PLUS
  | MINUS
  | STAR
  | SLASH
  | PERCENT
  | CARET
  | LPAREN
  | RPAREN
  | EQUAL
  | SEMI
  | EOF

(* 用 lexbuf 的当前位置信息报词法错误 *)
let error lexbuf msg =
  let p = lexbuf.Lexing.lex_curr_p in
  failwith (Printf.sprintf "line %d, col %d: %s"
              p.Lexing.pos_lnum
              (p.Lexing.pos_cnum - p.Lexing.pos_bol)
              msg)
}

let digit = ['0'-'9']
let int_part = digit+
let frac = '.' digit*
let expo = ('e' | 'E') ('+' | '-')? digit+
let ident_start = ['a'-'z' 'A'-'Z']
let ident_rest = ['a'-'z' 'A'-'Z' '0'-'9' '_']

rule token = parse
  (* 空白：跳过后继续扫描 *)
  | [' ' '\t' '\r']+      { token lexbuf }

  (* 换行：维护行号（错误定位用），继续扫描 *)
  | '\n'                  { Lexing.new_line lexbuf; token lexbuf }

  (* 行注释：// 到行尾 *)
  | "//" [^'\n']*         { token lexbuf }

  (* 浮点字面量：整数部分.小数[指数]。最长匹配保证 3.14 不会被
     下面的整数规则截断成 3 + ".14" *)
  | int_part frac expo? as lx  { FLOAT (float_of_string lx) }
  | int_part frac       as lx  { FLOAT (float_of_string lx) }
  | int_part            as lx  { INT (int_of_string lx) }

  (* 标识符 / 关键字 *)
  | ident_start ident_rest* as lx
      { match lx with
        | "let"  -> LET
        | "if"   -> IF
        | "then" -> THEN
        | "else" -> ELSE
        | _      -> ID lx }

  (* 运算符与标点 *)
  | '+'   { PLUS }
  | '-'   { MINUS }
  | '*'   { STAR }
  | '/'   { SLASH }
  | '%'   { PERCENT }
  | '^'   { CARET }
  | '('   { LPAREN }
  | ')'   { RPAREN }
  | '='   { EQUAL }
  | ';'   { SEMI }

  (* 输入结束 *)
  | eof   { EOF }

  (* 兜底：非法字符，报位置 *)
  | _ as c { error lexbuf (Printf.sprintf "unexpected character %C" c) }
