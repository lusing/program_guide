(* ======================================================================
   05_patterns.ml - 模式匹配
   ======================================================================
   本文件演示 OCaml 的模式匹配（pattern matching）：
     - match 表达式
     - 通配模式、字面量模式
     - 变体构造子模式
     - 列表模式
     - as 模式、嵌套模式
     - 守卫（when）
     - let 模式解构

   运行方式：
     ocaml 05_patterns.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) match 表达式基础 ---- *)
(* match 是模式匹配的基本形式：
   match expr with
   | pattern1 -> expr1
   | pattern2 -> expr2
   | ...

   模式匹配按顺序匹配，第一个匹配的分支被执行。
   编译器会检查是否穷尽（exhaustiveness）和是否有冗余（unused）。 *)

type color = Red | Green | Blue

let demo_match_basics () =
  say "=== Section 1: match expressions ===";
  let string_of_color c =
    match c with
    | Red -> "Red"
    | Green -> "Green"
    | Blue -> "Blue"
  in
  say ("Red -> " ^ string_of_color Red);
  say ("Green -> " ^ string_of_color Green);
  say ("Blue -> " ^ string_of_color Blue);

  (* match 也是表达式，返回值 *)
  let c = Green in
  let result =
    match c with
    | Red -> 1
    | Green -> 2
    | Blue -> 3
  in
  print_string "Green mapped to int: "; print_int result; say "";
  say "match is an expression - it returns a value."

(* ---- 2) 通配模式与字面量模式 ---- *)
(* _ 是通配模式，匹配任何值但不绑定变量。
   字面量模式：直接用常量值（整数、字符串、字符等）作为模式。 *)

let demo_wildcard_literal () =
  say "";
  say "=== Section 2: wildcard and literal patterns ===";
  let describe n =
    match n with
    | 0 -> "zero"
    | 1 -> "one"
    | 2 -> "two"
    | _ -> "something else"   (* 通配模式，兜底 *)
  in
  say ("describe 0 = " ^ describe 0);
  say ("describe 1 = " ^ describe 1);
  say ("describe 2 = " ^ describe 2);
  say ("describe 42 = " ^ describe 42);

  (* 字符串字面量模式 *)
  let greeting lang =
    match lang with
    | "en" -> "Hello"
    | "fr" -> "Bonjour"
    | "es" -> "Hola"
    | "zh" -> "Ni hao"
    | _ -> "Hi"
  in
  say ("greeting \"en\" = " ^ greeting "en");
  say ("greeting \"zh\" = " ^ greeting "zh");
  say ("greeting \"jp\" = " ^ greeting "jp");
  say "_ matches anything and binds no variable."

(* ---- 3) 变体构造子模式 ---- *)
(* 带参数的变体可以在模式中解构其参数。 *)

type shape =
  | Circle of float           (* 半径 *)
  | Rectangle of float * float  (* 宽 * 高 *)
  | Square of float           (* 边长 *)

let demo_variant_patterns () =
  say "";
  say "=== Section 3: variant constructor patterns ===";
  let area s =
    match s with
    | Circle r -> 3.14159 *. r *. r
    | Rectangle (w, h) -> w *. h
    | Square side -> side *. side
  in
  print_string "area (Circle 5.0) = "; print_float (area (Circle 5.0)); say "";
  print_string "area (Rectangle (3.0, 4.0)) = "; print_float (area (Rectangle (3.0, 4.0))); say "";
  print_string "area (Square 5.0) = "; print_float (area (Square 5.0)); say "";

  (* 也可以用 option 类型（标准库已定义） *)
  let opt_value default opt =
    match opt with
    | Some x -> x
    | None -> default
  in
  print_string "opt_value 0 (Some 42) = "; print_int (opt_value 0 (Some 42)); say "";
  print_string "opt_value 0 None = "; print_int (opt_value 0 None); say "";
  say "Variant patterns destructure constructor arguments."

(* ---- 4) 列表模式 ---- *)
(* 列表也可以用模式匹配：
   [] 匹配空列表
   hd::tl 匹配非空列表，hd 是头元素，tl 是尾部
   [x; y; z] 匹配固定长度的列表 *)

let demo_list_patterns () =
  say "";
  say "=== Section 4: list patterns ===";
  let rec sum lst =
    match lst with
    | [] -> 0
    | x :: rest -> x + sum rest
  in
  print_string "sum [1;2;3;4;5] = "; print_int (sum [1;2;3;4;5]); say "";

  let first_element lst =
    match lst with
    | [] -> None
    | x :: _ -> Some x
  in
  (match first_element [10; 20; 30] with
   | Some n -> print_string "first of [10;20;30] = "; print_int n; say ""
   | None -> say "empty");

  (* 固定长度模式 *)
  let describe_pair lst =
    match lst with
    | [] -> "empty list"
    | [_] -> "single element"
    | [_; _] -> "two elements"
    | _ :: _ :: _ -> "three or more elements"
  in
  say ("describe_pair [] = " ^ describe_pair []);
  say ("describe_pair [1] = " ^ describe_pair [1]);
  say ("describe_pair [1;2] = " ^ describe_pair [1;2]);
  say ("describe_pair [1;2;3] = " ^ describe_pair [1;2;3]);
  say "List patterns: [], x::rest, [x;y;...]"

(* ---- 5) as 模式与嵌套模式 ---- *)
(* as 模式：给匹配的子模式起一个名字。
   嵌套模式：模式可以嵌套任意深度。 *)

let demo_as_nested () =
  say "";
  say "=== Section 5: as patterns and nested patterns ===";
  (* as 模式：匹配整个值并命名 *)
  let describe_list lst =
    match lst with
    | ([] | [_]) as short ->
        "short list, length = " ^ string_of_int (List.length short)
    | _ :: _ :: _ as long ->
        "long list, length = " ^ string_of_int (List.length long)
  in
  say ("describe_list [] = " ^ describe_list []);
  say ("describe_list [1] = " ^ describe_list [1]);
  say ("describe_list [1;2;3] = " ^ describe_list [1;2;3]);

  (* 嵌套模式：列表中嵌套元组 *)
  let first_point_x lst =
    match lst with
    | ((x, _) :: _) -> x
    | [] -> 0.0
  in
  let points = [(1.0, 2.0); (3.0, 4.0)] in
  print_string "first_point_x [(1,2);(3,4)] = "; print_float (first_point_x points); say "";

  (* 变体中嵌套元组的模式匹配 *)
  let shape_center s =
    match s with
    | Circle r -> (0.0, 0.0)
    | Rectangle (w, h) -> (w /. 2.0, h /. 2.0)
    | Square s -> (s /. 2.0, s /. 2.0)
  in
  let (cx, cy) = shape_center (Rectangle (10.0, 20.0)) in
  print_string "center of Rectangle(10,20) = ("; print_float cx;
  print_string ", "; print_float cy; say ")";
  say "as pattern names the matched value; patterns can be nested."

(* ---- 6) 守卫（when） ---- *)
(* 在模式后加 when 条件，可以在模式匹配基础上增加额外的条件判断。
   只有模式匹配且 when 条件为真时，该分支才被选中。 *)

let demo_when_guard () =
  say "";
  say "=== Section 6: when guards ===";
  let classify n =
    match n with
    | 0 -> "zero"
    | n when n > 0 -> "positive"
    | n when n < 0 -> "negative"
    | _ -> "unreachable"   (* 实际不会走到这里 *)
  in
  say ("classify 0 = " ^ classify 0);
  say ("classify 5 = " ^ classify 5);
  say ("classify (-3) = " ^ classify (-3));

  (* 更复杂的守卫 *)
  let describe_pair (x, y) =
    match (x, y) with
    | (a, b) when a = b -> "equal"
    | (a, b) when a > b -> "first is larger"
    | (_, _) -> "second is larger"
  in
  say ("describe_pair (5, 5) = " ^ describe_pair (5, 5));
  say ("describe_pair (10, 3) = " ^ describe_pair (10, 3));
  say ("describe_pair (2, 7) = " ^ describe_pair (2, 7));
  say "when guards add extra conditions to pattern branches."

(* 记录类型定义（用于 demo_let_patterns 中的记录模式） *)
type point2d = { x : float; y : float }

(* ---- 7) let 模式解构 ---- *)
(* let 本身就是模式匹配的一种形式。
   任何模式都可以用在 let 中（只要模式一定能匹配）。 *)

let demo_let_patterns () =
  say "";
  say "=== Section 7: let pattern destructuring ===";
  (* 元组解构 *)
  let (a, b) = (10, 20) in
  print_string "let (a, b) = (10, 20): a = "; print_int a;
  print_string ", b = "; print_int b; say "";

  (* 记录解构 *)
  let r = { x = 3.5; y = 4.5 } in
  let { x; y } = r in
  print_string "let {x; y} = r: x = "; print_float x;
  print_string ", y = "; print_float y; say "";

  (* 函数参数中的模式 *)
  let add_pair (x, y) = x + y in
  print_string "add_pair (3, 4) = "; print_int (add_pair (3, 4)); say "";

  (* 注意：let 模式必须是穷尽的，否则会有警告。
     对于可能失败的匹配，应该用 match。 *)
  let safe_hd lst =
    match lst with
    | [] -> None
    | x :: _ -> Some x
  in
  (match safe_hd [5; 6] with
   | Some v -> print_string "safe_hd [5;6] = "; print_int v; say ""
   | None -> ());
  say "let patterns must be exhaustive; use match for partial patterns."

(* ---- 主程序 ---- *)
let () =
  demo_match_basics ();
  demo_wildcard_literal ();
  demo_variant_patterns ();
  demo_list_patterns ();
  demo_as_nested ();
  demo_when_guard ();
  demo_let_patterns ();
  say "";
  say "==== 05 jieshu ===="

(* ==== 05 结束 ==== *)
