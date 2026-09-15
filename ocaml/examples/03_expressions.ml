(* ======================================================================
   03_expressions.ml - 表达式与运算符
   ======================================================================
   本文件演示 OCaml 的表达式和运算符：
     - 算术运算符：+ - * / mod（float 用 +. -. *. /.）
     - 比较运算符
     - 逻辑运算符：&& || not
     - if 表达式（不是语句）
     - 运算符优先级

   运行方式：
     ocaml 03_expressions.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 整数算术运算符 ---- *)
(* +  -  *  /  mod  都用于 int。
   注意：/ 是整数除法（截断向零），mod 是取模。 *)

let demo_int_arith () =
  say "=== Section 1: integer arithmetic ===";
  let a = 10 in
  let b = 3 in
  print_string "a = "; print_int a; say "";
  print_string "b = "; print_int b; say "";
  print_string "a + b = "; print_int (a + b); say "";
  print_string "a - b = "; print_int (a - b); say "";
  print_string "a * b = "; print_int (a * b); say "";
  print_string "a / b = "; print_int (a / b); say "";
  print_string "a mod b = "; print_int (a mod b); say "";
  print_string "~-a = "; print_int (~-a); say "";  (* 一元负号 *)
  say "Integer division truncates toward zero."

(* ---- 2) 浮点数算术运算符 ---- *)
(* 浮点数运算符都带点号：+.  -.  *.  /.
   还有 ** 表示幂运算（float -> float -> float）。 *)

let demo_float_arith () =
  say "";
  say "=== Section 2: float arithmetic ===";
  let x = 10.0 in
  let y = 3.0 in
  print_string "x = "; print_float x; say "";
  print_string "y = "; print_float y; say "";
  print_string "x +. y = "; print_float (x +. y); say "";
  print_string "x -. y = "; print_float (x -. y); say "";
  print_string "x *. y = "; print_float (x *. y); say "";
  print_string "x /. y = "; print_float (x /. y); say "";
  print_string "x ** y = "; print_float (x ** y); say "";  (* 10^3 *)
  print_string "sqrt x = "; print_float (sqrt x); say "";
  say "Float operators all end with a dot (.) to distinguish from int."

(* ---- 3) 比较运算符 ---- *)
(* =  <>  <  >  <=  >=
   注意：= 是结构相等（类似其他语言的 ==），
         == 是物理相等（指针相等，类似其他语言的 == 对于引用类型）。
   大多数情况下应该用 = 而不是 ==。 *)

let demo_comparison () =
  say "";
  say "=== Section 3: comparison operators ===";
  say ("3 = 3 ? " ^ string_of_bool (3 = 3));
  say ("3 <> 4 ? " ^ string_of_bool (3 <> 4));
  say ("3 < 5 ? " ^ string_of_bool (3 < 5));
  say ("10 > 20 ? " ^ string_of_bool (10 > 20));
  say ("5 <= 5 ? " ^ string_of_bool (5 <= 5));
  say ("5 >= 6 ? " ^ string_of_bool (5 >= 6));
  say ("3.14 = 3.14 ? " ^ string_of_bool (3.14 = 3.14));
  say ("\"abc\" = \"abc\" ? " ^ string_of_bool ("abc" = "abc"));
  say "";
  say "Use = for structural equality (most cases).";
  say "Use == only for physical (pointer) equality."

(* ---- 4) 逻辑运算符 ---- *)
(* && 逻辑与（短路）
   || 逻辑或（短路）
   not 逻辑非 *)

let demo_logic () =
  say "";
  say "=== Section 4: logical operators ===";
  say ("true && true = " ^ string_of_bool (true && true));
  say ("true && false = " ^ string_of_bool (true && false));
  say ("false || true = " ^ string_of_bool (false || true));
  say ("false || false = " ^ string_of_bool (false || false));
  say ("not true = " ^ string_of_bool (not true));
  say ("not false = " ^ string_of_bool (not false));
  say "";
  say "&& and || are short-circuit operators.";
  say "Example: false && (1/0 = 0) does not raise Division_by_zero."

(* ---- 5) if 表达式 ---- *)
(* OCaml 中 if 是表达式，不是语句。它返回一个值。
   if e1 then e2 else e3 中 e2 和 e3 必须有相同类型。
   如果没有 else，默认 else 为 ()（unit 类型）。 *)

let demo_if_expr () =
  say "";
  say "=== Section 5: if expressions ===";
  let abs_int n = if n >= 0 then n else -n in
  print_string "abs_int (-5) = "; print_int (abs_int (-5)); say "";
  print_string "abs_int 10 = "; print_int (abs_int 10); say "";

  let grade score =
    if score >= 90 then "A"
    else if score >= 80 then "B"
    else if score >= 70 then "C"
    else if score >= 60 then "D"
    else "F"
  in
  say ("grade 95 = " ^ grade 95);
  say ("grade 72 = " ^ grade 72);
  say ("grade 50 = " ^ grade 50);
  say "";
  say "if is an expression, not a statement - it returns a value.";
  say "Both branches must have the same type."

(* ---- 6) 运算符优先级 ---- *)
(* 从高到低的大致优先级：
     函数应用（最高）
     *. /.
     +. -.
     * / mod
     + -
     :: @
     = <> < > <= >=
     &&
     ||
     ,
     if then else
     ;  （最低）

   用括号可以改变优先级。 *)

let demo_precedence () =
  say "";
  say "=== Section 6: operator precedence ===";
  (* 算术优先级：先乘除后加减 *)
  let r1 = 2 + 3 * 4 in        (* 14, not 20 *)
  let r2 = (2 + 3) * 4 in      (* 20 *)
  print_string "2 + 3 * 4 = "; print_int r1; say "";
  print_string "(2 + 3) * 4 = "; print_int r2; say "";

  (* 比较与逻辑 *)
  let r3 = 3 < 5 && 5 < 10 in  (* true，比较优先级高于 && *)
  let r4 = (3 < 5) && (5 < 10) in
  say ("3 < 5 && 5 < 10 = " ^ string_of_bool r3);
  say ("(3 < 5) && (5 < 10) = " ^ string_of_bool r4);

  (* cons :: 优先级低于 + * 等 *)
  let r5 = 1 + 2 :: [] in       (* [3], (1+2) :: [] *)
  print_string "length of (1+2 :: []) = "; print_int (List.length r5); say "";

  say "";
  say "When in doubt, use parentheses for clarity."

(* ---- 7) 字符串与列表运算符 ---- *)
(* ^ 字符串拼接
   :: cons 运算符（列表）
   @  列表拼接 *)

let demo_other_ops () =
  say "";
  say "=== Section 7: string and list operators ===";
  let s = "hello" ^ " " ^ "world" in
  say ("\"hello\" ^ \" \" ^ \"world\" = " ^ s);

  let lst = 1 :: 2 :: 3 :: [] in
  print_string "1::2::3::[] = [";
  List.iter (fun x -> print_int x; print_string "; ") lst;
  say "]";

  let lst2 = [4; 5] @ [6; 7] in
  print_string "[4;5] @ [6;7] = [";
  List.iter (fun x -> print_int x; print_string "; ") lst2;
  say "]";
  say "^ for strings, :: and @ for lists."

(* ---- 主程序 ---- *)
let () =
  demo_int_arith ();
  demo_float_arith ();
  demo_comparison ();
  demo_logic ();
  demo_if_expr ();
  demo_precedence ();
  demo_other_ops ();
  say "";
  say "==== 03 jieshu ===="

(* ==== 03 结束 ==== *)
