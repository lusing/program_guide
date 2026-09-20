(* ==========================================================================
   19_testing.ml - 测试与断言
   ==========================================================================
   主题：OCaml 中的测试与断言
   内容：
     1. 简单断言函数
     2. check_int / check_float / check_bool / check_list
     3. 异常断言（检查是否抛出预期异常）
     4. 测试框架雏形
     5. 属性测试（基于固定输入）
     6. 测试报告

   运行方式：
     ocaml 19_testing.ml
     或
     utop # #use "19_testing.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 简单断言函数
   ========================================================================
   断言（assertion）是测试的基础。
   断言检查某个条件是否为真，如果为假则报告失败。
   OCaml 内置了 assert 函数，但它在失败时会抛出 Assert_failure 异常。
   我们可以封装自己的断言函数，提供更好的错误信息。
*)
section 1 "Simple assertion functions";;

(* 基础断言：检查布尔条件 *)
let assert_true ?(msg = "") condition =
  if not condition then
    failwith (Printf.sprintf "Assertion failed: expected true%s%s"
      (if msg = "" then "" else " - ") msg)

let assert_false ?(msg = "") condition =
  if condition then
    failwith (Printf.sprintf "Assertion failed: expected false%s%s"
      (if msg = "" then "" else " - ") msg)

(* 测试断言函数 *)
let test_simple_assertions () =
  print_endline "Testing basic assertions:";
  assert_true (1 + 1 = 2) ~msg:"1+1 should equal 2";
  assert_true (List.length [1; 2; 3] = 3) ~msg:"list length";
  assert_false (1 > 2) ~msg:"1 should not be greater than 2";
  assert_true ("hello" ^ " world" = "hello world") ~msg:"string concat";
  print_endline "  All simple assertions passed!"

let _ = test_simple_assertions ();;

(* 相等性断言：期望值 vs 实际值 *)
let assert_equal ?(msg = "") equal_fn to_str expected actual =
  if not (equal_fn expected actual) then
    failwith (Printf.sprintf "Assertion failed%s%s\n  Expected: %s\n  Actual:   %s"
      (if msg = "" then "" else ": ") msg
      (to_str expected) (to_str actual))

(* 整数断言 *)
let assert_int_equal ?(msg = "") expected actual =
  assert_equal ~msg (=) string_of_int expected actual

(* 测试 *)
let test_int_assertions () =
  print_endline "\nTesting int equality assertions:";
  assert_int_equal 42 (6 * 7) ~msg:"6*7 should be 42";
  assert_int_equal 0 (List.length []) ~msg:"empty list length";
  assert_int_equal 10 (List.fold_left (+) 0 [1; 2; 3; 4]) ~msg:"sum of list";
  print_endline "  All int assertions passed!"

let _ = test_int_assertions ();;

(* 演示失败的断言（捕获异常以继续运行） *)
print_endline "\nDemonstrating a failing assertion (caught):";
try
  assert_int_equal 5 (2 + 2) ~msg:"2+2 should be 4, not 5";
  print_endline "  This should not print"
with Failure msg ->
  Printf.printf "  Caught expected failure:\n    %s\n"
    (String.concat "\n    " (String.split_on_char '\n' msg));;

(* ========================================================================
   2) check_int / check_float / check_bool / check_list
   ========================================================================
   针对不同类型的专用检查函数。
   与 assert 不同，check 函数返回布尔值而不是抛出异常，
   适合用于测试框架中统计通过/失败。
*)
section 2 "check_int / check_float / check_bool / check_list";;

(* 检查结果类型 *)
type test_result = {
  name : string;
  passed : bool;
  message : string;
}

let pass name = { name; passed = true; message = "OK" }
let fail name msg = { name; passed = false; message = msg }

(* 整数检查 *)
let check_int name expected actual =
  if expected = actual then pass name
  else fail name (Printf.sprintf "expected %d, got %d" expected actual)

(* 浮点数检查（带容差） *)
let check_float ?(eps = 1e-6) name expected actual =
  if abs_float (expected -. actual) < eps *. max 1.0 (max (abs_float expected) (abs_float actual))
  then pass name
  else fail name (Printf.sprintf "expected %.6f, got %.6f" expected actual)

(* 布尔检查 *)
let check_bool name expected actual =
  if expected = actual then pass name
  else fail name (Printf.sprintf "expected %b, got %b" expected actual)

(* 列表检查 *)
let check_list name eq_fn to_str expected actual =
  if List.length expected <> List.length actual then
    fail name (Printf.sprintf "length mismatch: expected %d, got %d"
      (List.length expected) (List.length actual))
  else if List.for_all2 eq_fn expected actual then
    pass name
  else
    fail name (Printf.sprintf "lists differ\nexpected: [%s]\ngot:      [%s]"
      (String.concat "; " (List.map to_str expected))
      (String.concat "; " (List.map to_str actual)))

(* 字符串检查 *)
let check_string name expected actual =
  if expected = actual then pass name
  else fail name (Printf.sprintf "expected \"%s\", got \"%s\"" expected actual)

(* 运行检查并打印结果 *)
let run_check check_fn =
  let result = check_fn () in
  let status = if result.passed then "PASS" else "FAIL" in
  Printf.printf "  [%s] %s" status result.name;
  if not result.passed then Printf.printf "\n        %s" result.message;
  print_newline ();
  result

(* 测试各种 check 函数 *)
let () =
  print_endline "Running checks:";

  let r1 = run_check (fun () -> check_int "addition" 5 (2 + 3)) in
  let r2 = run_check (fun () -> check_int "list length" 3 (List.length [1;2;3])) in
  let r3 = run_check (fun () -> check_float "float division" 0.333333 (1.0 /. 3.0)) in
  let r4 = run_check (fun () -> check_bool "list empty" false (List.is_empty [1])) in
  let r5 = run_check (fun () ->
    check_list "map double" (=) string_of_int [2;4;6] (List.map (( * ) 2) [1;2;3])) in
  let r6 = run_check (fun () -> check_string "concat" "hello world" ("hello" ^ " world")) in

  (* 故意失败的测试 *)
  let r7 = run_check (fun () -> check_int "intentional fail" 10 (5 + 5 + 1)) in

  (* run_check 返回 test_result，收集起来就能做汇总统计 *)
  let results = [r1; r2; r3; r4; r5; r6; r7] in
  let npass = List.length (List.filter (fun r -> r.passed) results) in
  Printf.printf "  -> %d checks, %d passed, %d failed\n"
    (List.length results) npass (List.length results - npass)
;;

(* ========================================================================
   3) 异常断言（检查是否抛出预期异常）
   ========================================================================
   测试函数是否在特定条件下抛出预期的异常。
   这对于测试错误处理代码很重要。
*)
section 3 "Exception assertions";;

(* 检查函数是否抛出预期的异常 *)
let check_raises name expected_exn_fn f =
  try
    let _ = f () in
    fail name "expected exception but none was raised"
  with exn ->
    if expected_exn_fn exn then pass name
    else fail name (Printf.sprintf "wrong exception: %s" (Printexc.to_string exn))

(* 检查是否抛出 Failure 异常，且消息匹配 *)
let check_failure name expected_msg f =
  check_raises name
    (function
      | Failure msg when msg = expected_msg -> true
      | _ -> false)
    f

(* 检查是否抛出 Not_found 异常 *)
let check_not_found name f =
  check_raises name
    (function Not_found -> true | _ -> false)
    f

(* 检查是否抛出 Division_by_zero 异常 *)
let check_division_by_zero name f =
  check_raises name
    (function Division_by_zero -> true | _ -> false)
    f

(* 测试异常断言 *)
let () =
  print_endline "Testing exception assertions:";

  let r8 = run_check (fun () ->
    check_division_by_zero "div by zero" (fun () -> 1 / 0)) in

  let r9 = run_check (fun () ->
    check_not_found "List.assoc not found"
      (fun () -> List.assoc "z" [("a", 1); ("b", 2)])) in

  let r10 = run_check (fun () ->
    check_failure "failwith message" "something went wrong"
      (fun () -> failwith "something went wrong")) in

  (* 测试不应该抛出异常的情况 *)
  let r11 = run_check (fun () ->
    check_raises "no exception expected"
      (function _ -> false)  (* 任何异常都算失败 *)
      (fun () -> 1 + 1)) in  (* 这个函数不抛异常，所以测试应该通过 *)

  let rs = [r8; r9; r10; r11] in
  Printf.printf "  -> %d exception checks, %d passed\n"
    (List.length rs) (List.length (List.filter (fun r -> r.passed) rs))
(* 说明：上面的测试会通过，因为 f() 没有抛出异常，
   但 check_raises 的逻辑是：如果没抛异常则返回 fail。
   让我们修正：我们需要一个"不抛出异常"的检查 *)

(* 检查函数不抛出任何异常 *)
let check_no_exception name f =
  try
    let _ = f () in pass name
  with exn ->
    fail name (Printf.sprintf "unexpected exception: %s" (Printexc.to_string exn))

let () =
  let r12 = run_check (fun () ->
    check_no_exception "normal computation" (fun () -> 1 + 2 + 3)) in
  Printf.printf "  -> no-exception check passed: %b\n" r12.passed
;;

(* ========================================================================
   4) 测试框架雏形
   ========================================================================
   构建一个简单的测试框架：
   - 组织测试用例
   - 运行测试套件
   - 统计通过/失败数量
   - 生成测试报告
*)
section 4 "Mini testing framework";;

(* 测试用例类型 *)
type test_case = {
  test_name : string;
  test_fn : unit -> test_result;
}

(* 测试套件类型 *)
type test_suite = {
  suite_name : string;
  cases : test_case list;
}

(* 创建测试用例 *)
let test_case name f = { test_name = name; test_fn = f }

(* 创建测试套件 *)
let test_suite name cases = { suite_name = name; cases }

(* 运行单个测试用例 *)
let run_test_case tc =
  try tc.test_fn ()
  with exn ->
    fail tc.test_name (Printf.sprintf "unexpected exception: %s"
      (Printexc.to_string exn))

(* 运行测试套件 *)
let run_suite suite =
  Printf.printf "\n=== Suite: %s ===\n" suite.suite_name;
  let results = List.map run_test_case suite.cases in
  let passed = List.filter (fun r -> r.passed) results in
  let failed = List.filter (fun r -> not r.passed) results in
  List.iteri (fun i r ->
    let status = if r.passed then "PASS" else "FAIL" in
    Printf.printf "  %2d. [%s] %s" (i + 1) status r.name;
    if not r.passed then Printf.printf "\n      %s" r.message;
    print_newline ()
  ) results;
  Printf.printf "  Results: %d passed, %d failed, %d total\n"
    (List.length passed) (List.length failed) (List.length results);
  (passed, failed, results)

(* === 示例：为列表函数编写测试 === *)

(* 待测试的函数 *)
let rec list_rev acc = function
  | [] -> acc
  | h :: t -> list_rev (h :: acc) t

let my_rev lst = list_rev [] lst

let rec my_map f = function
  | [] -> []
  | h :: t -> f h :: my_map f t

let rec my_filter p = function
  | [] -> []
  | h :: t -> if p h then h :: my_filter p t else my_filter p t

(* 测试套件 *)
let list_suite = test_suite "List functions" [
  test_case "rev empty list" (fun () ->
    check_list "rev []" (=) string_of_int [] (my_rev []));

  test_case "rev single element" (fun () ->
    check_list "rev [1]" (=) string_of_int [1] (my_rev [1]));

  test_case "rev multiple elements" (fun () ->
    check_list "rev [1;2;3]" (=) string_of_int [3;2;1] (my_rev [1;2;3]));

  test_case "rev preserves length" (fun () ->
    check_int "length (rev lst)" 5 (List.length (my_rev [1;2;3;4;5])));

  test_case "rev twice = original" (fun () ->
    check_list "rev (rev lst)" (=) string_of_int [1;2;3;4;5]
      (my_rev (my_rev [1;2;3;4;5])));

  test_case "map empty list" (fun () ->
    check_list "map f []" (=) string_of_int [] (my_map (( * ) 2) []));

  test_case "map double" (fun () ->
    check_list "map double" (=) string_of_int [2;4;6;8;10]
      (my_map (( * ) 2) [1;2;3;4;5]));

  test_case "filter even" (fun () ->
    check_list "filter even" (=) string_of_int [2;4]
      (my_filter (fun x -> x mod 2 = 0) [1;2;3;4;5]));

  test_case "filter all pass" (fun () ->
    check_list "filter all pass" (=) string_of_int [1;2;3]
      (my_filter (fun _ -> true) [1;2;3]));

  test_case "filter none pass" (fun () ->
    check_list "filter none pass" (=) string_of_int []
      (my_filter (fun _ -> false) [1;2;3]));

  test_case "map composition" (fun () ->
    let lst = [1;2;3] in
    let f = (fun x -> x * 2) in
    let g = (fun x -> x + 1) in
    check_list "map (f o g)" (=) string_of_int
      (my_map (fun x -> f (g x)) lst)
      (my_map f (my_map g lst)));
]

let list_passed, list_failed, _ = run_suite list_suite;;

(* ========================================================================
   5) 属性测试（基于固定输入）
   ========================================================================
   属性测试（Property-based Testing）：
   - 不是测试具体的输入输出对，而是测试函数的属性（性质）
   - 例如：排序后列表长度不变、rev(rev(x)) = x、排序后元素不变
   - 这里我们用固定的测试输入来演示属性测试的思想
   - 真正的属性测试框架（如 QCheck）会随机生成大量测试用例
*)
section 5 "Property-based testing (fixed inputs)";;

(* 插入排序函数（来自 15_algorithms.ml） *)
let rec insert x = function
  | [] -> [x]
  | h :: t as lst -> if x <= h then x :: lst else h :: insert x t

let insertion_sort lst =
  List.fold_left (fun acc x -> insert x acc) [] lst

(* 属性 1：排序后列表长度不变 *)
let prop_sort_preserves_length lst =
  let sorted = insertion_sort lst in
  List.length sorted = List.length lst

(* 属性 2：排序后列表是有序的（非递减） *)
let prop_sort_is_sorted lst =
  let sorted = insertion_sort lst in
  let rec is_sorted = function
    | [] | [_] -> true
    | a :: b :: rest -> a <= b && is_sorted (b :: rest)
  in
  is_sorted sorted

(* 属性 3：排序后元素集合不变（排列） *)
let prop_sort_permutation lst =
  let sorted = insertion_sort lst in
  let rec same_elements l1 l2 =
    match l1 with
    | [] -> l2 = []
    | h :: t ->
        (* 从 l2 中移除一个 h；找不到说明不是排列 *)
        try
          let rec remove_one x = function
            | [] -> raise Not_found
            | h :: t -> if h = x then t else h :: remove_one x t
          in
          same_elements t (remove_one h l2)
        with Not_found -> false
  in
  same_elements lst sorted

(* 属性 4：对已排序的列表再次排序结果不变（幂等性） *)
let prop_sort_idempotent lst =
  let sorted1 = insertion_sort lst in
  let sorted2 = insertion_sort sorted1 in
  sorted1 = sorted2

(* 运行属性测试 *)
let test_property name prop test_inputs =
  let all_pass = ref true in
  let failures = ref 0 in
  List.iter (fun input ->
    if not (prop input) then begin
      all_pass := false;
      incr failures
    end
  ) test_inputs;
  if !all_pass then
    pass (Printf.sprintf "%s (%d test cases)" name (List.length test_inputs))
  else
    fail name (Printf.sprintf "%d of %d cases failed" !failures (List.length test_inputs))

(* 测试输入集 *)
let int_lists = [
  [];
  [1];
  [1; 2; 3];
  [3; 2; 1];
  [5; 2; 8; 1; 9; 3; 7; 4; 6];
  [1; 1; 1; 1];
  [2; 1; 4; 3; 6; 5];
  [10; 9; 8; 7; 6; 5; 4; 3; 2; 1];
  [1; 3; 2; 5; 4; 7; 6; 9; 8];
  [5; 5; 3; 3; 1; 1];
]

(* 运行属性测试套件 *)
let prop_suite = test_suite "Sort properties" [
  test_case "preserves length" (fun () ->
    test_property "sort preserves length" prop_sort_preserves_length int_lists);

  test_case "result is sorted" (fun () ->
    test_property "sort result is sorted" prop_sort_is_sorted int_lists);

  test_case "permutation of input" (fun () ->
    test_property "sort is permutation" prop_sort_permutation int_lists);

  test_case "idempotent (sort twice = once)" (fun () ->
    test_property "sort is idempotent" prop_sort_idempotent int_lists);
]

let prop_passed, prop_failed, _ = run_suite prop_suite;;

(* 更多属性：列表反转的属性 *)
let prop_rev_involutive lst = my_rev (my_rev lst) = lst
let prop_rev_length lst = List.length (my_rev lst) = List.length lst
let prop_rev_append lst1 lst2 =
  my_rev (lst1 @ lst2) = my_rev lst2 @ my_rev lst1

let list_prop_suite = test_suite "List rev properties" [
  test_case "rev (rev lst) = lst" (fun () ->
    test_property "rev involutive" prop_rev_involutive int_lists);

  test_case "rev preserves length" (fun () ->
    test_property "rev preserves length" prop_rev_length int_lists);

  test_case "rev (a@b) = rev(b)@rev(a)" (fun () ->
    let pairs = [
      ([], []);
      ([1], [2; 3]);
      ([1; 2], [3; 4; 5]);
      ([1; 2; 3], []);
    ] in
    test_property "rev append"
      (fun (a, b) -> prop_rev_append a b)
      pairs);
]

let lp_passed, lp_failed, _ = run_suite list_prop_suite;;

(* ========================================================================
   6) 测试报告
   ========================================================================
   汇总所有测试结果，生成完整的测试报告。
   包括：通过数、失败数、通过率、失败详情等。
*)
section 6 "Test report";;

(* 收集所有测试结果 *)
let all_suites = [
  ("List functions", list_passed, list_failed);
  ("Sort properties", prop_passed, prop_failed);
  ("List rev properties", lp_passed, lp_failed);
]

(* 生成报告 *)
let print_report suites =
  print_endline "\n";
  print_endline (String.make 60 '=');
  print_endline "  TEST REPORT";
  print_endline (String.make 60 '=');

  let total_pass = ref 0 in
  let total_fail = ref 0 in

  List.iter (fun (name, passed, failed) ->
    let total = List.length passed + List.length failed in
    let pct = if total = 0 then 100.0 else
      float_of_int (List.length passed) /. float_of_int total *. 100.0 in
    Printf.printf "\n  %-30s  %3d passed, %3d failed, %3d total  (%5.1f%%)\n"
      name (List.length passed) (List.length failed) total pct;
    total_pass := !total_pass + List.length passed;
    total_fail := !total_fail + List.length failed;
  ) suites;

  let total = !total_pass + !total_fail in
  let pct = if total = 0 then 100.0 else
    float_of_int !total_pass /. float_of_int total *. 100.0 in

  print_endline (String.make 60 '-');
  Printf.printf "  %-30s  %3d passed, %3d failed, %3d total  (%5.1f%%)\n"
    "TOTAL" !total_pass !total_fail total pct;
  print_endline (String.make 60 '=');

  if !total_fail = 0 then
    print_endline "\n  All tests passed!"
  else
    Printf.printf "\n  %d test(s) FAILED!\n" !total_fail;
  print_newline ()

let _ = print_report all_suites;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 19 jieshu ===="  (* 第十九个文件结束 *)
