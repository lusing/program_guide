(* ======================================================================
   06_lists.ml - 列表与 List 模块
   ======================================================================
   本文件演示 OCaml 的列表类型和 List 标准库模块：
     - 列表构造：[] 和 ::
     - 列表拼接 @
     - List.map / List.filter
     - List.fold_left / List.fold_right
     - List.init, List.length, List.rev, List.nth
     - List.find, List.exists, List.for_all, List.partition
     - 自己实现 map

   运行方式：
     ocaml 06_lists.ml
   ====================================================================== *)

let say s = print_endline s

(* 辅助函数：打印整数列表 *)
let print_int_list label lst =
  print_string (label ^ "[");
  List.iteri (fun i x ->
    if i > 0 then print_string "; ";
    print_int x) lst;
  say "]"

(* ---- 1) 列表构造：[] 和 :: ---- *)
(* 列表是同质的（所有元素类型相同）单链表。
   [] 是空列表
   :: (cons) 在列表头部添加一个元素
   [a; b; c] 是 a :: b :: c :: [] 的语法糖 *)

let demo_construction () =
  say "=== Section 1: list construction ===";
  let empty = [] in
  print_int_list "empty = " empty;

  let single = 42 :: [] in
  print_int_list "42 :: [] = " single;

  let nums = 1 :: 2 :: 3 :: [] in
  print_int_list "1::2::3::[] = " nums;

  let nums2 = [1; 2; 3; 4; 5] in
  print_int_list "[1;2;3;4;5] = " nums2;

  say "Lists are homogeneous singly-linked lists.";
  say "Use :: to cons (prepend), and [a;b;c] as literal syntax."

(* ---- 2) 列表拼接 @ ---- *)
(* @ 运算符将两个列表拼接，返回新列表。
   复杂度 O(n)，其中 n 是第一个列表的长度。 *)

let demo_append () =
  say "";
  say "=== Section 2: list append (@) ===";
  let a = [1; 2; 3] in
  let b = [4; 5; 6] in
  let c = a @ b in
  print_int_list "a = " a;
  print_int_list "b = " b;
  print_int_list "a @ b = " c;

  let prepend = 0 :: a in
  print_int_list "0 :: a = " prepend;

  say "@ concatenates two lists; :: is O(1), @ is O(n) on first list."

(* ---- 3) List.map / List.filter ---- *)
(* List.map : ('a -> 'b) -> 'a list -> 'b list
   将函数应用于每个元素，返回结果列表。
   List.filter : ('a -> bool) -> 'a list -> 'a list
   保留满足谓词的元素。 *)

let demo_map_filter () =
  say "";
  say "=== Section 3: List.map and List.filter ===";
  let nums = [1; 2; 3; 4; 5] in

  (* map: 每个元素平方 *)
  let squares = List.map (fun x -> x * x) nums in
  print_int_list "List.map (fun x -> x*x) [1..5] = " squares;

  (* map: 转字符串 *)
  let strs = List.map string_of_int nums in
  say ("List.map string_of_int [1..5] = [" ^ String.concat "; " strs ^ "]");

  (* filter: 保留偶数 *)
  let evens = List.filter (fun x -> x mod 2 = 0) nums in
  print_int_list "List.filter (even) [1..5] = " evens;

  (* filter: 保留大于 3 的 *)
  let bigs = List.filter (fun x -> x > 3) nums in
  print_int_list "List.filter (>3) [1..5] = " bigs;

  say "map transforms elements; filter selects elements."

(* ---- 4) List.fold_left / List.fold_right ---- *)
(* List.fold_left : ('a -> 'b -> 'a) -> 'a -> 'b list -> 'a
   从左到右累积，初始值在左。
   List.fold_right : ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
   从右到左累积，初始值在右。
   fold_left 是尾递归的，fold_right 不是。 *)

let demo_fold () =
  say "";
  say "=== Section 4: fold_left and fold_right ===";
  let nums = [1; 2; 3; 4; 5] in

  (* fold_left 求和 *)
  let sum_left = List.fold_left (fun acc x -> acc + x) 0 nums in
  print_string "List.fold_left (+) 0 [1..5] = "; print_int sum_left; say "";

  (* fold_right 求和 *)
  let sum_right = List.fold_right (fun x acc -> x + acc) nums 0 in
  print_string "List.fold_right (+) [1..5] 0 = "; print_int sum_right; say "";

  (* fold_left 求积 *)
  let product = List.fold_left ( * ) 1 nums in
  print_string "List.fold_left ( * ) 1 [1..5] = "; print_int product; say "";

  (* fold_left 实现 length *)
  let length lst = List.fold_left (fun acc _ -> acc + 1) 0 lst in
  print_string "length [1..5] via fold_left = "; print_int (length nums); say "";

  (* fold_left 和 fold_right 顺序差异的示例 *)
  let left_result = List.fold_left (fun acc x -> "(" ^ acc ^ "+" ^ string_of_int x ^ ")") "0" nums in
  let right_result = List.fold_right (fun x acc -> "(" ^ string_of_int x ^ "+" ^ acc ^ ")") nums "0" in
  say ("fold_left order: " ^ left_result);
  say ("fold_right order: " ^ right_result);
  say "fold_left is tail-recursive; fold_right is not."

(* ---- 5) List.init, List.length, List.rev, List.nth ---- *)
(* List.init n f : 生成长度为 n 的列表，第 i 个元素为 f(i)
   List.length : 列表长度
   List.rev : 反转列表
   List.nth : 取第 n 个元素（从 0 开始），越界抛出 Failure *)

let demo_utils () =
  say "";
  say "=== Section 5: List.init, length, rev, nth ===";

  (* List.init *)
  let squares = List.init 10 (fun i -> i * i) in
  print_int_list "List.init 10 (fun i -> i*i) = " squares;

  (* List.length *)
  let lst = [1; 2; 3; 4; 5] in
  print_string "List.length [1..5] = "; print_int (List.length lst); say "";

  (* List.rev *)
  let revd = List.rev lst in
  print_int_list "List.rev [1..5] = " revd;

  (* List.nth *)
  print_string "List.nth [1..5] 0 = "; print_int (List.nth lst 0); say "";
  print_string "List.nth [1..5] 2 = "; print_int (List.nth lst 2); say "";
  print_string "List.nth [1..5] 4 = "; print_int (List.nth lst 4); say "";

  say "List.init generates lists; List.nth is O(n) - lists are linked."

(* ---- 6) List.find, List.exists, List.for_all, List.partition ---- *)
(* List.find : ('a -> bool) -> 'a list -> 'a   (找不到抛出 Not_found)
   List.exists : ('a -> bool) -> 'a list -> bool
   List.for_all : ('a -> bool) -> 'a list -> bool
   List.partition : ('a -> bool) -> 'a list -> 'a list * 'a list *)

let demo_query () =
  say "";
  say "=== Section 6: find, exists, for_all, partition ===";
  let nums = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10] in

  (* find *)
  let first_even = List.find (fun x -> x mod 2 = 0) nums in
  print_string "List.find even in [1..10] = "; print_int first_even; say "";

  (* exists *)
  let has_big = List.exists (fun x -> x > 8) nums in
  say ("List.exists (>8) [1..10] = " ^ string_of_bool has_big);
  let has_huge = List.exists (fun x -> x > 100) nums in
  say ("List.exists (>100) [1..10] = " ^ string_of_bool has_huge);

  (* for_all *)
  let all_pos = List.for_all (fun x -> x > 0) nums in
  say ("List.for_all (>0) [1..10] = " ^ string_of_bool all_pos);
  let all_even = List.for_all (fun x -> x mod 2 = 0) nums in
  say ("List.for_all even [1..10] = " ^ string_of_bool all_even);

  (* partition *)
  let (evens, odds) = List.partition (fun x -> x mod 2 = 0) nums in
  print_int_list "evens: " evens;
  print_int_list "odds:  " odds;

  say "find returns first match; partition splits into two lists."

(* ---- 7) 自己实现 map ---- *)
(* 用递归和模式匹配实现 List.map，理解其工作原理。
   同时展示普通递归和尾递归版本。 *)

let demo_implement_map () =
  say "";
  say "=== Section 7: implementing map from scratch ===";

  (* 普通递归版本：简单但可能栈溢出（非尾递归） *)
  let rec my_map f lst =
    match lst with
    | [] -> []
    | x :: rest -> f x :: my_map f rest
  in
  let result1 = my_map (fun x -> x * 2) [1; 2; 3; 4; 5] in
  print_int_list "my_map ( *2 ) [1..5] = " result1;

  (* 尾递归版本：用累积器和 List.rev *)
  let my_map_tail f lst =
    let rec loop acc remaining =
      match remaining with
      | [] -> List.rev acc
      | x :: rest -> loop (f x :: acc) rest
    in
    loop [] lst
  in
  let result2 = my_map_tail (fun x -> x * 2) [1; 2; 3; 4; 5] in
  print_int_list "my_map_tail ( *2 ) [1..5] = " result2;

  say "Simple recursive map is elegant but not tail-recursive.";
  say "Tail-recursive version uses an accumulator + rev at the end."

(* ---- 主程序 ---- *)
let () =
  demo_construction ();
  demo_append ();
  demo_map_filter ();
  demo_fold ();
  demo_utils ();
  demo_query ();
  demo_implement_map ();
  say "";
  say "==== 06 jieshu ===="

(* ==== 06 结束 ==== *)
