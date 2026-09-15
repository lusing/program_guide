(* ======================================================================
   01_basics.ml - 程序结构、值与输出
   ======================================================================
   本文件演示 OCaml 的基本程序结构：
     - let 绑定（值定义）
     - print_endline / print_int 等输出函数
     - 单行与多行注释
     - 类型推断与显式类型标注
     - 整数、实数、字符串字面量
     - 求值顺序

   运行方式：
     ocaml 01_basics.ml        # 解释执行
     ocamlopt 01_basics.ml -o 01_basics && ./01_basics   # 编译执行
   ====================================================================== *)

(* ---- 辅助函数：统一的输出方式 ---- *)
(* say 函数：输出一行字符串，类似 print_endline，但语义更直观 *)
let say s = print_endline s

(* ---- 1) let 绑定与基本输出 ---- *)
(* OCaml 中用 let 定义值（不可变绑定）。
   每个顶层 let 后必须跟 ;; 或另一个 let 来分隔。
   在 .ml 文件中，通常不需要 ;; （除非在顶层交互环境）。 *)

let hello = "Hello, OCaml!"

let () =
  say "=== Section 1: let bindings and output ===";
  say hello;
  say "print_endline adds a newline automatically."

(* ---- 2) 注释 ---- *)
(* 这是单行注释（虽然写了多行格式） *)
(* 注释可以 (* 嵌套 (* 很深 *) 的 *) 注释 *)
(* 下面演示一些变量绑定 *)

let language = "OCaml"
let year = 1996
let pi_approx = 3.14

let () =
  say "";
  say "=== Section 2: comments and variables ===";
  say ("Language: " ^ language);
  (* print_int 输出整数但不换行，需要手动加换行 *)
  print_string "Born in year: ";
  print_int year;
  print_newline ();
  print_string "Pi approx: ";
  print_float pi_approx;
  print_newline ()

(* ---- 3) 类型推断与类型标注 ---- *)
(* OCaml 有强大的类型推断系统，通常不需要写类型。
   但也可以显式标注类型，格式是 (value : type) 或 name : type = ... *)

let explicit_int : int = 42
let explicit_float : float = 3.14159
let explicit_string : string = "typed"

(* 函数的类型标注示例 *)
let add (a : int) (b : int) : int = a + b

let () =
  say "";
  say "=== Section 3: type inference and annotations ===";
  print_string "explicit_int = "; print_int explicit_int; print_newline ();
  print_string "explicit_float = "; print_float explicit_float; print_newline ();
  say ("explicit_string = " ^ explicit_string);
  print_string "add 3 4 = "; print_int (add 3 4); print_newline ();
  say "Types are inferred automatically even without annotations."

(* ---- 4) 整数字面量 ---- *)
(* 支持十进制、十六进制、八进制、二进制字面量 *)

let dec_num = 123
let hex_num = 0xFF        (* 十六进制 255 *)
let oct_num = 0o77        (* 八进制 63 *)
let bin_num = 0b1010      (* 二进制 10 *)
let underscore_num = 1_000_000  (* 下划线分隔，提高可读性 *)

let () =
  say "";
  say "=== Section 4: integer literals ===";
  print_string "dec 123 = "; print_int dec_num; print_newline ();
  print_string "hex 0xFF = "; print_int hex_num; print_newline ();
  print_string "oct 0o77 = "; print_int oct_num; print_newline ();
  print_string "bin 0b1010 = "; print_int bin_num; print_newline ();
  print_string "1_000_000 = "; print_int underscore_num; print_newline ()

(* ---- 5) 实数（浮点数）字面量 ---- *)
(* float 是双精度浮点数。注意：整数和浮点数运算符不同！ *)

let float_a = 3.14
let float_b = 2.0
let float_sci = 1.5e3      (* 科学计数法 = 1500.0 *)
let float_neg = -0.5

let () =
  say "";
  say "=== Section 5: float literals ===";
  print_string "float_a = "; print_float float_a; print_newline ();
  print_string "float_b = "; print_float float_b; print_newline ();
  print_string "float_sci = "; print_float float_sci; print_newline ();
  print_string "float_neg = "; print_float float_neg; print_newline ();
  say "Note: float uses +. -. *. /. (dot operators), not + - * /"

(* ---- 6) 字符串字面量 ---- *)
(* 字符串用双引号括起。支持转义字符。 *)

let str_normal = "Hello World"
let str_escape = "line1\nline2\ttabbed"  (* \n 换行, \t 制表符 *)
let str_concat = "abc" ^ "def"            (* 字符串拼接用 ^ *)

let () =
  say "";
  say "=== Section 6: string literals ===";
  say ("str_normal: " ^ str_normal);
  say ("str_concat: " ^ str_concat);
  say "str_escape:";
  say str_escape

(* ---- 7) 求值顺序 ---- *)
(* OCaml 是严格求值（call-by-value）：参数在函数调用前完全求值。
   同一表达式中的求值顺序：一般从左到右，但不保证某些情况。
   let 绑定按顺序求值。 *)

let () =
  say "";
  say "=== Section 7: evaluation order ===";
  (* let 顺序求值：先算 x，再算 y，再算 z *)
  let x = 1 + 2 in
  let y = x * 3 in
  let z = y - 1 in
  print_string "x=3, y=9, z=8 => z = "; print_int z; print_newline ();
  say "let bindings are evaluated in order (strict evaluation)."

(* ---- 8) unit 类型与副作用 ---- *)
(* 输出函数返回 unit 类型（只有一个值：()）。
   用 ; 连接多个副作用表达式，最后一个表达式的值就是整体的值。 *)

let print_pair a b =
  print_string "(";
  print_int a;
  print_string ", ";
  print_int b;
  print_string ")\n"

let () =
  say "";
  say "=== Section 8: unit type and side effects ===";
  say "print_pair 10 20 =>";
  print_pair 10 20;
  say "The semicolon ; sequences side-effect expressions."

(* ======== 01 jieshu ======== *)
(* ==== 01 结束 ==== *)
let () =
  say "";
  say "==== 01 jieshu ===="
