(* ======================================================================
   10_exceptions.ml - 异常
   ======================================================================
   本文件演示 OCaml 的异常处理机制：
     - 定义异常：exception MyExn
     - 带参数的异常
     - raise 抛出异常
     - try ... with 捕获异常
     - 异常的多分支处理
     - 标准异常：Failure, Invalid_argument, Not_found
     - 异常 vs option

   运行方式：
     ocaml 10_exceptions.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 定义异常与抛出异常 ---- *)
(* 用 exception 关键字定义异常。
   用 raise 函数抛出异常。
   异常是一种特殊的变体类型（extensible variant）。 *)

exception MyError
exception InputOutOfRange of int * int   (* 带参数的异常：最小值和最大值 *)
exception DivisionByZero
exception NegativeArgument of string * float   (* 函数名 + 非法值 *)

let demo_define_and_raise () =
  say "=== Section 1: defining and raising exceptions ===";

  (* 一个可能抛出异常的函数 *)
  let check_positive n =
    if n > 0 then n
    else raise MyError
  in

  (* 安全调用：用 try ... with 捕获 *)
  let safe_check n =
    try
      let result = check_positive n in
      Printf.sprintf "check_positive %d = %d (OK)" n result
    with
    | MyError -> Printf.sprintf "check_positive %d = Error (not positive)" n
  in
  say (safe_check 42);
  say (safe_check (-5));
  say (safe_check 0);
  say "Exceptions are defined with 'exception' and raised with 'raise'."

(* ---- 2) 带参数的异常 ---- *)
(* 异常可以携带参数，类似变体构造子。
   在 with 分支中可以解构这些参数。 *)

let demo_param_exceptions () =
  say "";
  say "=== Section 2: exceptions with parameters ===";

  let safe_sqrt x =
    if x < 0.0 then raise (NegativeArgument ("sqrt", x))
    else sqrt x
  in

  let safe_div a b =
    if b = 0 then raise DivisionByZero
    else a / b
  in

  (* 捕获并读取异常参数 *)
  let test_sqrt x =
    try
      let r = safe_sqrt x in
      Printf.sprintf "sqrt %g = %g" x r
    with
    | NegativeArgument (func, value) ->
        Printf.sprintf "Error in %s: negative argument %g" func value
    | DivisionByZero -> "Division by zero"
  in
  say (test_sqrt 16.0);
  say (test_sqrt (-4.0));
  say (test_sqrt 2.0);

  let test_div a b =
    try
      let r = safe_div a b in
      Printf.sprintf "%d / %d = %d" a b r
    with
    | DivisionByZero -> Printf.sprintf "%d / 0 = DivisionByZero" a
    | NegativeArgument (f, v) -> Printf.sprintf "Error in %s: %g" f v
  in
  say "";
  say (test_div 10 2);
  say (test_div 10 0);
  say "Exceptions can carry data, like variant constructors."

(* ---- 3) try ... with 捕获异常 ---- *)
(* try expr with pattern -> handler
   异常会向上传播，直到被捕获。
   如果异常未被捕获，程序终止并打印异常信息。 *)

let demo_try_with () =
  say "";
  say "=== Section 3: try ... with exception handling ===";

  (* 异常传播的例子 *)
  let inner n =
    if n < 0 then raise (Failure "inner: negative")
    else n * 2
  in
  let middle n =
    if n = 0 then raise (Invalid_argument "middle: zero")
    else inner (n - 1)
  in
  let outer n =
    try
      middle n
    with
    | Failure msg ->
        say ("Caught Failure: " ^ msg);
        -1
    | Invalid_argument msg ->
        say ("Caught Invalid_argument: " ^ msg);
        -2
  in

  Printf.printf "outer 5 = %d\n" (outer 5);
  Printf.printf "outer 1 = %d\n" (outer 1);
  Printf.printf "outer 0 = %d\n" (outer 0);
  say "";
  say "Exceptions propagate up the call stack until caught."

(* ---- 4) 异常的多分支处理 ---- *)
(* try ... with 可以有多个分支，类似 match。
   还可以用 | _ 作为兜底，捕获所有异常。 *)

let demo_multi_branch () =
  say "";
  say "=== Section 4: multi-branch exception handling ===";

  let list_ops op lst =
    try
      match op with
      | "hd" -> List.hd lst
      | "nth2" -> List.nth lst 2
      | "find5" -> List.find (fun x -> x = 5) lst
      | _ -> raise (Failure "unknown op")
    with
    | Failure s ->
        say ("  Failure: " ^ s); -1
    | Not_found ->
        say "  Not_found: element 5 not in list"; -2
    | Invalid_argument _ ->
        say "  Invalid_argument: bad argument"; -3
    | _ ->
        say "  Some other exception"; -99
  in

  say "Testing list_ops on [1; 2; 3; 4]:";
  Printf.printf "  list_ops \"hd\" = %d\n" (list_ops "hd" [1;2;3;4]);
  Printf.printf "  list_ops \"nth2\" = %d\n" (list_ops "nth2" [1;2;3;4]);
  Printf.printf "  list_ops \"find5\" = %d\n" (list_ops "find5" [1;2;3;4]);
  Printf.printf "  list_ops \"hd\" [] = %d\n" (list_ops "hd" []);
  Printf.printf "  list_ops \"badop\" [1] = %d\n" (list_ops "badop" [1]);
  say "Multiple with branches handle different exception types."

(* ---- 5) 标准异常 ---- *)
(* OCaml 标准库中常用的异常：
   - Failure : string -> exn    通用失败
   - Invalid_argument : string -> exn   参数非法
   - Not_found : exn            未找到元素
   - Stack_overflow : exn       栈溢出
   - Out_of_memory : exn        内存不足
   - Sys_error : string -> exn  系统调用错误
   - Division_by_zero : exn     除零错误 *)

let demo_standard_exceptions () =
  say "";
  say "=== Section 5: standard library exceptions ===";

  (* Failure *)
  say "Failure example (List.nth out of bounds):";
  (try
    let _ = List.nth [1; 2; 3] 10 in
    ()
  with
  | Failure s -> say ("  Caught Failure: " ^ s));

  (* Invalid_argument *)
  say "";
  say "Invalid_argument example (String.sub with negative len):";
  (try
    let _ = String.sub "hello" 0 (-1) in
    ()
  with
  | Invalid_argument s -> say ("  Caught Invalid_argument: " ^ s));

  (* Not_found *)
  say "";
  say "Not_found example (List.find with no match):";
  (try
    let _ = List.find (fun x -> x > 100) [1; 2; 3] in
    ()
  with
  | Not_found -> say "  Caught Not_found");

  (* Division_by_zero *)
  say "";
  say "Division_by_zero example:";
  (try
    let _ = 10 / 0 in
    ()
  with
  | Division_by_zero -> say "  Caught Division_by_zero");

  say "Common standard exceptions: Failure, Invalid_argument, Not_found, Division_by_zero."

(* ---- 6) 异常 vs option ---- *)
(* 异常适合"意外情况"或快速失败，option 适合"预期可能失败"。
   现代 OCaml 更倾向于用 option / result 类型（更函数式）。
   但异常在某些场景（如回溯、跳出深层递归）仍然很有用。 *)

let demo_exception_vs_option () =
  say "";
  say "=== Section 6: exceptions vs option types ===";

  (* 基于异常的版本 *)
  let rec find_index_exn pred lst =
    match lst with
    | [] -> raise Not_found
    | x :: _ when pred x -> 0
    | _ :: rest -> 1 + find_index_exn pred rest
  in

  (* 基于 option 的版本 *)
  let rec find_index_opt pred lst =
    match lst with
    | [] -> None
    | x :: _ when pred x -> Some 0
    | _ :: rest ->
        match find_index_opt pred rest with
        | None -> None
        | Some i -> Some (i + 1)
  in

  let nums = [3; 7; 1; 9; 5] in
  let pred = fun x -> x = 9 in

  say "Finding index of 9 in [3;7;1;9;5]:";

  (* 异常版本的使用 *)
  let exn_result =
    try
      Some (find_index_exn pred nums)
    with
    | Not_found -> None
  in
  (match exn_result with
   | Some i -> Printf.printf "  Exception style: found at index %d\n" i
   | None -> say "  Exception style: not found");

  (* option 版本的使用 *)
  let opt_result = find_index_opt pred nums in
  (match opt_result with
   | Some i -> Printf.printf "  Option style: found at index %d\n" i
   | None -> say "  Option style: not found");

  (* 查找不存在的元素 *)
  say "";
  say "Finding index of 100 (not present):";
  let opt_notfound = find_index_opt (fun x -> x = 100) nums in
  (match opt_notfound with
   | Some _ -> say "  Option: found (unexpected)"
   | None -> say "  Option: returns None (clean)");

  say "";
  say "Option is more explicit and composable with other functional patterns.";
  say "Exceptions are useful for non-local control flow and unexpected errors."

(* ---- 主程序 ---- *)
let () =
  demo_define_and_raise ();
  demo_param_exceptions ();
  demo_try_with ();
  demo_multi_branch ();
  demo_standard_exceptions ();
  demo_exception_vs_option ();
  say "";
  say "==== 10 jieshu ===="

(* ==== 10 结束 ==== *)
