(* ======================================================================
   11_higher_order.ml - 高阶函数与闭包
   ======================================================================
   本文件演示 OCaml 的高阶函数和闭包：
     - 函数作为参数
     - 函数作为返回值
     - 柯里化与偏应用
     - 闭包与独立计数器
     - 函数组合
     - 函数放进列表

   运行方式：
     ocaml 11_higher_order.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 函数作为参数 ---- *)
(* 高阶函数：接受其他函数作为参数的函数。
   List.map, List.filter, List.fold_left 都是典型的高阶函数。 *)

let demo_function_as_argument () =
  say "=== Section 1: functions as arguments ===";

  (* 自定义高阶函数：对一个数应用两次给定的函数 *)
  let apply_twice f x = f (f x) in
  let double x = x * 2 in
  let square x = x * x in

  print_string "apply_twice double 3 = "; print_int (apply_twice double 3); say "";
  print_string "apply_twice square 3 = "; print_int (apply_twice square 3); say "";

  (* 匿名函数（lambda）作为参数 *)
  print_string "apply_twice (fun x -> x + 1) 10 = ";
  print_int (apply_twice (fun x -> x + 1) 10); say "";

  (* 更实际的例子：多次迭代一个函数 *)
  let rec iterate f n x =
    if n <= 0 then x
    else iterate f (n - 1) (f x)
  in
  print_string "iterate (fun x -> x * 2) 5 1 = ";
  print_int (iterate (fun x -> x * 2) 5 1); say "";  (* 1 * 2^5 = 32 *)

  (* List.map / List.filter 也是高阶函数 *)
  let nums = [1; 2; 3; 4; 5] in
  let doubled = List.map (fun x -> x * 2) nums in
  say ("List.map ( *2 ) [1..5] = [" ^
       String.concat "; " (List.map string_of_int doubled) ^ "]");
  say "Higher-order functions take other functions as arguments."

(* ---- 2) 函数作为返回值 ---- *)
(* 函数也可以作为返回值。这使得"生成函数的函数"成为可能。 *)

let demo_function_as_return () =
  say "";
  say "=== Section 2: functions as return values ===";

  (* 生成一个"加 n"的函数 *)
  let make_adder n =
    fun x -> x + n
  in
  let add5 = make_adder 5 in
  let add10 = make_adder 10 in
  print_string "add5 3 = "; print_int (add5 3); say "";
  print_string "add10 3 = "; print_int (add10 3); say "";

  (* 生成乘法器 *)
  let make_multiplier factor =
    fun x -> x * factor
  in
  let double = make_multiplier 2 in
  let triple = make_multiplier 3 in
  print_string "double 7 = "; print_int (double 7); say "";
  print_string "triple 7 = "; print_int (triple 7); say "";

  (* 更复杂的例子：生成比较器 *)
  let make_comparison threshold =
    fun x ->
      if x > threshold then "above"
      else if x < threshold then "below"
      else "equal"
  in
  let compare_to_10 = make_comparison 10 in
  say ("compare_to_10 15 = " ^ compare_to_10 15);
  say ("compare_to_10 5 = " ^ compare_to_10 5);
  say ("compare_to_10 10 = " ^ compare_to_10 10);
  say "Functions can return other functions - function factories!"

(* ---- 3) 柯里化与偏应用 ---- *)
(* OCaml 中的多参数函数其实都是"一个参数返回函数"的函数（柯里化）。
   let f x y = ...  等价于  let f = fun x -> fun y -> ...
   偏应用（partial application）：只传部分参数，得到一个接受剩余参数的函数。 *)

let demo_currying () =
  say "";
  say "=== Section 3: currying and partial application ===";

  (* 两参数函数的柯里化本质 *)
  let add x y = x + y in
  (* add 3 是一个"加 3"的函数（偏应用） *)
  let add_three = add 3 in
  print_string "add 3 4 = "; print_int (add 3 4); say "";
  print_string "add_three 4 = "; print_int (add_three 4); say "";

  (* 三参数函数的偏应用 *)
  let format_msg prefix suffix name =
    prefix ^ name ^ suffix
  in
  let greet = format_msg "Hello, " "!" in
  let farewell = format_msg "Goodbye, " "." in
  say ("greet \"Alice\" = \"" ^ greet "Alice" ^ "\"");
  say ("greet \"Bob\" = \"" ^ greet "Bob" ^ "\"");
  say ("farewell \"Alice\" = \"" ^ farewell "Alice" ^ "\"");

  (* List.map 的偏应用 *)
  let double_all = List.map (fun x -> x * 2) in
  let doubled = double_all [1; 2; 3; 4; 5] in
  say ("double_all [1..5] = [" ^
       String.concat "; " (List.map string_of_int doubled) ^ "]");

  say "All multi-arg functions are curried; partial application is free."

(* ---- 4) 闭包与独立计数器 ---- *)
(* 闭包（closure）：函数 + 它捕获的环境（自由变量）。
   闭包可以在多次调用之间保持状态。
   每个闭包有独立的状态。 *)

let demo_closures_counters () =
  say "";
  say "=== Section 4: closures and independent counters ===";

  (* 创建计数器的工厂函数 *)
  let make_counter () =
    let count = ref 0 in   (* 可变引用，被闭包捕获 *)
    fun () ->
      count := !count + 1;
      !count
  in

  let c1 = make_counter () in
  let c2 = make_counter () in

  say "Counter c1:";
  Printf.printf "  c1 () = %d\n" (c1 ());
  Printf.printf "  c1 () = %d\n" (c1 ());
  Printf.printf "  c1 () = %d\n" (c1 ());

  say "Counter c2 (independent):";
  Printf.printf "  c2 () = %d\n" (c2 ());
  Printf.printf "  c2 () = %d\n" (c2 ());

  say "c1 continues from where it left off:";
  Printf.printf "  c1 () = %d\n" (c1 ());
  Printf.printf "  c1 () = %d\n" (c1 ());

  say "";
  say "Each closure has its own captured state - they are independent.";
  say "Closures = function + captured environment (lexical scoping)."

(* ---- 5) 函数组合 ---- *)
(* 函数组合：将两个函数组合成一个新函数。
   (f << g) x = f (g x)    数学中的 f o g
   也可以定义反向组合 (>>)。 *)

let demo_function_composition () =
  say "";
  say "=== Section 5: function composition ===";

  (* 函数组合运算符：(f >> g) x = g (f x) *)
  let (>>) f g x = g (f x) in

  (* 数学组合：(f << g) x = f (g x) *)
  let (<<) f g x = f (g x) in

  let double x = x * 2 in
  let square x = x * x in
  let inc x = x + 1 in

  (* double then square: square (double x) = (2x)^2 = 4x^2 *)
  let double_square = double >> square in
  print_string "double >> square applied to 3 = ";
  print_int (double_square 3); say "";  (* square(double(3)) = square(6) = 36 *)

  (* square then double: double (square x) = 2 * x^2 *)
  let square_double = square >> double in
  print_string "square >> double applied to 3 = ";
  print_int (square_double 3); say "";  (* double(square(3)) = double(9) = 18 *)

  (* 多个函数组合 *)
  let pipeline = inc >> double >> square in   (* (x+1)*2 然后平方 *)
  print_string "inc >> double >> square applied to 3 = ";
  print_int (pipeline 3); say "";  (* square(double(inc(3))) = square(double(4)) = square(8) = 64 *)

  (* 用 << 组合（数学顺序） *)
  let math_compose = square << double << inc in   (* square(double(inc(x))) *)
  print_string "square << double << inc applied to 3 = ";
  print_int (math_compose 3); say "";  (* 64, same as pipeline *)

  (* 实际例子：字符串处理流水线 *)
  let trim s = String.trim s in
  let upper s = String.uppercase_ascii s in
  let add_exclaim s = s ^ "!" in
  let process = trim >> upper >> add_exclaim in
  say ("process \"  hello  \" = \"" ^ process "  hello  " ^ "\"");
  say "Function composition builds pipelines: (f >> g) x = g(f(x))."

(* ---- 6) 函数放进列表 ---- *)
(* 函数是一等公民，可以像其他值一样放进列表、元组等数据结构中。
   这使得"策略模式"等设计模式非常自然。 *)

let demo_functions_in_lists () =
  say "";
  say "=== Section 6: functions in lists (first-class) ===";

  (* 整数变换函数的列表 *)
  let transforms = [
    (fun x -> x * 2);        (* 翻倍 *)
    (fun x -> x * x);        (* 平方 *)
    (fun x -> x + 1);        (* 加一 *)
    (fun x -> 0 - x);        (* 取反 *)
  ] in

  (* 对同一个数依次应用所有变换 *)
  let apply_all x fns = List.map (fun f -> f x) fns in
  let results = apply_all 5 transforms in
  say "Applying all transforms to 5:";
  List.iter (fun r -> Printf.printf "  result: %d\n" r) results;

  (* 用 pipeline 方式依次应用所有函数 *)
  let rec apply_in_order x fns =
    match fns with
    | [] -> x
    | f :: rest -> apply_in_order (f x) rest
  in
  let pipeline_result = apply_in_order 5 transforms in
  print_string "Applying transforms in sequence to 5: ";
  print_int pipeline_result; say "";
  say "  ((((5*2)^2)+1)*(-1) = -101)";

  (* 实际例子：一组过滤条件 *)
  let filters = [
    (fun x -> x > 0);        (* 正数 *)
    (fun x -> x mod 2 = 0);  (* 偶数 *)
    (fun x -> x < 20);       (* 小于 20 *)
  ] in
  let passes_all x = List.for_all (fun f -> f x) filters in
  say "";
  say "Numbers passing all filters (positive, even, <20):";
  let nums = List.init 30 (fun i -> i - 5) in
  let passing = List.filter passes_all nums in
  say ("  [" ^ String.concat "; " (List.map string_of_int passing) ^ "]");

  say "";
  say "Functions are first-class: store in lists, pass around, compose freely."

(* ---- 主程序 ---- *)
let () =
  demo_function_as_argument ();
  demo_function_as_return ();
  demo_currying ();
  demo_closures_counters ();
  demo_function_composition ();
  demo_functions_in_lists ();
  say "";
  say "==== 11 jieshu ===="

(* ==== 11 结束 ==== *)
