(* ======================================================================
   04_tuples.ml - 元组与记录
   ======================================================================
   本文件演示 OCaml 的元组与记录类型：
     - 元组构造与解构
     - 记录类型定义与访问
     - 记录的可变字段（mutable）
     - 嵌套解构
     - 记录的 with 语法

   运行方式：
     ocaml 04_tuples.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 元组构造 ---- *)
(* 元组用逗号分隔的值表示，如 (1, 2)。
   元组可以包含不同类型的值，长度固定。
   类型用 * 分隔，如 int * string * float。 *)

let demo_tuple_construct () =
  say "=== Section 1: tuple construction ===";
  (* 二元组 (pair) *)
  let pair = (42, "answer") in
  print_string "pair = ("; print_int (fst pair); print_string ", ";
  say (snd pair ^ ")");

  (* 三元组 *)
  let triple = (1, "two", 3.0) in
  let (a, b, c) = triple in
  print_string "triple = ("; print_int a; print_string ", ";
  print_string b; print_string ", "; print_float c; say ")";

  (* 四元组及以上只能用模式匹配提取 *)
  let quad = (1, 2, 3, 4) in
  let (w, x, y, z) = quad in
  print_string "quad = ("; print_int w; print_string ", "; print_int x;
  print_string ", "; print_int y; print_string ", "; print_int z; say ")";
  say "Tuples can hold values of different types."

(* ---- 2) 元组解构与模式匹配 ---- *)
(* 用 let (p1, p2, ...) = tuple 可以同时解构元组。
   也可以在函数参数中直接解构。 *)

let demo_tuple_destruct () =
  say "";
  say "=== Section 2: tuple destructuring ===";
  let point = (3.0, 4.0) in

  (* let 解构 *)
  let (x, y) = point in
  print_string "x = "; print_float x; say "";
  print_string "y = "; print_float y; say "";

  (* 函数参数解构 *)
  let distance (x1, y1) (x2, y2) =
    sqrt ((x2 -. x1) ** 2.0 +. (y2 -. y1) ** 2.0)
  in
  let d = distance (0.0, 0.0) (3.0, 4.0) in
  print_string "distance from (0,0) to (3,4) = "; print_float d; say "";

  (* 通配符忽略部分元素 *)
  let (first, _) = (100, "ignored") in
  print_string "first element = "; print_int first; say "";
  say "Use _ to ignore tuple elements you don't need."

(* ---- 3) 记录类型定义与访问 ---- *)
(* 记录是命名字段的集合，用 type name = { field1: type1; ... } 定义。
   访问用 record.field 语法。 *)

type point2d = {
  x : float;
  y : float;
}

type person = {
  name : string;
  age : int;
  email : string;
}

let demo_records () =
  say "";
  say "=== Section 3: record types ===";
  (* 创建记录 *)
  let p = { x = 3.0; y = 4.0 } in
  print_string "p.x = "; print_float p.x; say "";
  print_string "p.y = "; print_float p.y; say "";

  let alice = { name = "Alice"; age = 30; email = "alice@example.com" } in
  say ("Name: " ^ alice.name);
  print_string "Age: "; print_int alice.age; say "";
  say ("Email: " ^ alice.email);

  (* 记录也可以模式匹配解构 *)
  let { x = px; y = py } = p in
  print_string "destructured: px = "; print_float px;
  print_string ", py = "; print_float py; say "";

  (* 简写：如果变量名和字段名相同 *)
  let { x; y } = p in
  print_string "shorthand: x = "; print_float x;
  print_string ", y = "; print_float y; say "";
  say "Records have named fields for better readability."

(* ---- 4) 记录的可变字段（mutable） ---- *)
(* 默认记录字段是不可变的。用 mutable 关键字声明可变字段。
   修改可变字段用 record.field <- new_value 语法。 *)

type counter = {
  mutable count : int;
  label : string;           (* 不可变字段 *)
}

let demo_mutable () =
  say "";
  say "=== Section 4: mutable record fields ===";
  let c = { count = 0; label = "clicks" } in
  say ("Initial: " ^ c.label ^ " = " ^ string_of_int c.count);

  c.count <- c.count + 1;   (* 修改可变字段 *)
  say ("After inc: count = " ^ string_of_int c.count);

  c.count <- c.count + 5;
  say ("After +5: count = " ^ string_of_int c.count);

  (* c.label <- "new"  would error - label is immutable *)
  say "Use <- to assign to mutable fields."

(* ---- 5) 嵌套解构 ---- *)
(* 元组和记录可以嵌套，解构也可以嵌套进行。 *)

type rectangle = {
  top_left : point2d;
  bottom_right : point2d;
}

let demo_nested () =
  say "";
  say "=== Section 5: nested destructuring ===";
  let r = {
    top_left = { x = 0.0; y = 10.0 };
    bottom_right = { x = 20.0; y = 0.0 };
  } in

  (* 嵌套记录解构 *)
  let { top_left = { x = x1; y = y1 }; bottom_right = { x = x2; y = y2 } } = r in
  let width = x2 -. x1 in
  let height = y1 -. y2 in
  print_string "width = "; print_float width; say "";
  print_string "height = "; print_float height; say "";

  (* 元组中嵌套记录 *)
  let labeled = ("my rect", r) in
  let (name, { top_left = tl; _ }) = labeled in
  say ("Label: " ^ name);
  print_string "top_left.x = "; print_float tl.x; say "";
  say "Destructuring can be arbitrarily nested."

(* ---- 6) 记录的 with 语法 ---- *)
(* 用 with 语法可以基于已有记录创建新记录，只修改部分字段。
   原记录不会被修改（不可变字段）。 *)

let demo_with_syntax () =
  say "";
  say "=== Section 6: record with syntax ===";
  let p1 = { x = 1.0; y = 2.0 } in
  say "Original p1:";
  print_string "  x = "; print_float p1.x;
  print_string ", y = "; print_float p1.y; say "";

  (* 基于 p1 创建 p2，只修改 x 字段 *)
  let p2 = { p1 with x = 10.0 } in
  say "p2 = { p1 with x = 10.0 }:";
  print_string "  x = "; print_float p2.x;
  print_string ", y = "; print_float p2.y; say "";

  (* p1 保持不变 *)
  say "p1 is unchanged:";
  print_string "  x = "; print_float p1.x;
  print_string ", y = "; print_float p1.y; say "";

  (* with 也可以修改可变字段的记录，但还是创建新记录 *)
  let person1 = { name = "Bob"; age = 25; email = "bob@test.com" } in
  let person2 = { person1 with age = 26; email = "bob2@test.com" } in
  say ("person1: " ^ person1.name ^ ", age " ^ string_of_int person1.age);
  say ("person2: " ^ person2.name ^ ", age " ^ string_of_int person2.age);
  say "with creates a new record; the original is unchanged."

(* ---- 主程序 ---- *)
let () =
  demo_tuple_construct ();
  demo_tuple_destruct ();
  demo_records ();
  demo_mutable ();
  demo_nested ();
  demo_with_syntax ();
  say "";
  say "==== 04 jieshu ===="

(* ==== 04 结束 ==== *)
