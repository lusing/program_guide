(* ======================================================================
   02_types.ml - 类型系统
   ======================================================================
   本文件演示 OCaml 的类型系统：
     - 基础类型：int, float, bool, char, string, unit
     - 类型别名：type t = ...
     - 类型推断演示
     - 多态类型

   运行方式：
     ocaml 02_types.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 基础类型：int ---- *)
(* int 是有符号整数，在 64 位系统上为 63 位（1 位用于 GC 标记）。
   范围约为 -2^62 到 2^62 - 1。 *)

let demo_int () =
  say "=== Section 1: int type ===";
  let zero = 0 in
  let max_like = 4611686018427387903 in  (* 约 2^62 - 1 *)
  let neg = -100 in
  print_string "zero = "; print_int zero; print_newline ();
  print_string "neg = "; print_int neg; print_newline ();
  print_string "large int = "; print_int max_like; print_newline ();
  say "int is 63-bit signed on 64-bit platforms (1 bit for GC)."

(* ---- 2) 基础类型：float ---- *)
(* float 是双精度浮点数（IEEE 754），与 C 的 double 相同。
   注意：float 和 int 是完全不同的类型，不会自动转换。 *)

let demo_float () =
  say "";
  say "=== Section 2: float type ===";
  let pi = 3.1415926535 in
  let e = 2.71828 in
  let inf = infinity in
  let nan_val = nan in
  print_string "pi = "; print_float pi; print_newline ();
  print_string "e = "; print_float e; print_newline ();
  print_string "infinity = "; print_float inf; print_newline ();
  print_string "nan = "; print_float nan_val; print_newline ();
  say "Note: int and float never convert automatically."

(* ---- 3) 基础类型：bool ---- *)
(* bool 只有两个值：true 和 false。
   if 表达式要求条件必须是 bool 类型。 *)

let demo_bool () =
  say "";
  say "=== Section 3: bool type ===";
  let t = true in
  let f = false in
  say ("t = " ^ string_of_bool t);
  say ("f = " ^ string_of_bool f);
  say ("not true = " ^ string_of_bool (not true));
  say ("true && false = " ^ string_of_bool (true && false));
  say ("true || false = " ^ string_of_bool (true || false))

(* ---- 4) 基础类型：char ---- *)
(* char 是单字节字符（类似 C 的 char），用单引号括起。
   支持转义字符和 Char.code / Char.chr 转换。 *)

let demo_char () =
  say "";
  say "=== Section 4: char type ===";
  let c_a = 'a' in
  let c_z = 'Z' in
  let c_newline = '\n' in
  print_string "c_a = '"; print_char c_a; print_string "' (ASCII ";
  print_int (Char.code c_a); print_string ")\n";
  print_string "c_z = '"; print_char c_z; print_string "' (ASCII ";
  print_int (Char.code c_z); print_string ")\n";
  print_string "Char.chr 65 = '"; print_char (Char.chr 65); print_string "'\n";
  print_string "Char.code '\\n' = "; print_int (Char.code c_newline); print_newline ();
  say "char is 8-bit; use string for Unicode text."

(* ---- 5) 基础类型：string ---- *)
(* string 是不可变的字节序列。
   注意：OCaml string 通常被视为字节串，而非 Unicode 字符串。 *)

let demo_string () =
  say "";
  say "=== Section 5: string type ===";
  let s1 = "hello" in
  let s2 = String.make 5 'x' in
  let s3 = String.capitalize_ascii "world" in
  say ("s1 = " ^ s1);
  say ("s2 = " ^ s2);
  say ("s3 = " ^ s3);
  print_string "String.length s1 = ";
  print_int (String.length s1);
  print_newline ();
  say "Strings are immutable and comparable."

(* ---- 6) 基础类型：unit ---- *)
(* unit 类型只有一个值：()，用于表示"没有有用的返回值"。
   类似 C 的 void，但 unit 是真正的类型，() 是真正的值。 *)

let demo_unit () =
  say "";
  say "=== Section 6: unit type ===";
  let u = () in
  say ("u = () -> " ^ string_of_bool (u = ()));
  say "unit has exactly one value: ()";
  say "Functions with side effects (like print) return unit.";
  (* 忽略一个值的方式：用 _ 或 ignore *)
  let _ = 123 in  (* 忽略 123 *)
  ignore 456;      (* 另一种忽略方式 *)
  say "Use ignore x or let _ = x to discard a value."

(* ---- 7) 类型别名 ---- *)
(* 用 type 给已有类型起新名字，不会创建新类型（只是别名）。
   常用于提高代码可读性。 *)

type name = string
type age = int
type point = float * float   (* 元组类型别名 *)

let demo_type_alias () =
  say "";
  say "=== Section 7: type aliases ===";
  let (n : name) = "Alice" in
  let (a : age) = 30 in
  let (p : point) = (1.5, 2.5) in
  say ("name: " ^ n);
  print_string "age: "; print_int a; print_newline ();
  Printf.printf "point: (%g, %g)\n" (fst p) (snd p);
  say "point is a (float * float) tuple alias";
  say "Type aliases are transparent - name and string are the same type."

(* ---- 8) 类型推断演示 ---- *)
(* OCaml 的类型推断基于 Hindley-Milner 算法。
   编译器能推导出几乎所有表达式的类型，无需手动标注。 *)

let demo_inference () =
  say "";
  say "=== Section 8: type inference ===";
  (* 以下所有类型都是自动推断的 *)
  let x = 42 in           (* int *)
  let y = 3.14 in         (* float *)
  let f a b = a + b in    (* int -> int -> int *)
  let g x = x ^ "!" in    (* string -> string *)
  Printf.printf "x = %d, y = %g\n" x y;
  print_string "f 3 4 = "; print_int (f 3 4); print_newline ();
  say ("g \"hello\" = " ^ g "hello");
  say "Types are inferred automatically - no annotations needed."

(* ---- 9) 多态类型 ---- *)
(* 当函数不依赖具体类型时，其类型参数是多态的（用 'a, 'b 等表示）。
   多态函数可以操作任意类型的数据。 *)

let demo_polymorphism () =
  say "";
  say "=== Section 9: polymorphic types ===";
  (* identity 函数：'a -> 'a，多态 *)
  let id x = x in
  say ("id \"hello\" = " ^ id "hello");
  print_string "id 42 = "; print_int (id 42); print_newline ();

  (* const : 'a -> 'b -> 'a *)
  let const k _ = k in
  say ("const \"a\" 123 = " ^ const "a" 123);

  (* 多态的 pair 操作 *)
  let first (x, _) = x in
  let second (_, y) = y in
  let p = (42, "answer") in
  print_string "first (42, \"answer\") = "; print_int (first p); print_newline ();
  say ("second (42, \"answer\") = " ^ second p);
  say "Polymorphic functions work with any type."

(* ---- 主程序：依次运行所有演示 ---- *)
let () =
  demo_int ();
  demo_float ();
  demo_bool ();
  demo_char ();
  demo_string ();
  demo_unit ();
  demo_type_alias ();
  demo_inference ();
  demo_polymorphism ();
  say "";
  say "==== 02 jieshu ===="

(* ==== 02 结束 ==== *)
