(* ======================================================================
   09_recursion.ml - 递归与尾递归
   ======================================================================
   本文件演示 OCaml 的递归编程：
     - 基本递归：阶乘、斐波那契
     - 尾递归与累积器
     - 互递归
     - Ackermann函数
     - 汉诺塔
     - 递归 vs 尾递归性能对比

   运行方式：
     ocaml 09_recursion.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 基本递归：阶乘 ---- *)
(* 阶乘 n! = n * (n-1) * ... * 1
   基准情形：0! = 1
   递归情形：n! = n * (n-1)! *)

let demo_factorial () =
  say "=== Section 1: basic recursion - factorial ===";
  let rec factorial n =
    if n <= 0 then 1
    else n * factorial (n - 1)
  in
  print_string "factorial 0 = "; print_int (factorial 0); say "";
  print_string "factorial 1 = "; print_int (factorial 1); say "";
  print_string "factorial 5 = "; print_int (factorial 5); say "";
  print_string "factorial 10 = "; print_int (factorial 10); say "";
  say "factorial n = n * factorial (n-1), with factorial 0 = 1"

(* ---- 2) 基本递归：斐波那契 ---- *)
(* fib(0) = 0, fib(1) = 1
   fib(n) = fib(n-1) + fib(n-2)
   朴素实现有指数级时间复杂度（大量重复计算）。 *)

let demo_fibonacci () =
  say "";
  say "=== Section 2: basic recursion - fibonacci (naive) ===";
  let rec fib n =
    if n = 0 then 0
    else if n = 1 then 1
    else fib (n - 1) + fib (n - 2)
  in
  say "Naive fibonacci (exponential time):";
  for i = 0 to 10 do
    Printf.printf "  fib %d = %d\n" i (fib i)
  done;
  say "Note: naive fib is O(2^n) - very slow for large n."

(* ---- 3) 尾递归与累积器 ---- *)
(* 尾递归：递归调用是函数的最后一个操作。
   编译器可以优化尾递归为循环（尾调用优化 TCO），不会栈溢出。
   通常引入累积器（accumulator）参数来实现尾递归。 *)

let demo_tail_recursion () =
  say "";
  say "=== Section 3: tail recursion with accumulators ===";

  (* 尾递归阶乘 *)
  let factorial_tail n =
    let rec loop acc n =
      if n <= 0 then acc
      else loop (acc * n) (n - 1)   (* 递归调用是最后一个操作 *)
    in
    loop 1 n
  in
  print_string "factorial_tail 10 = "; print_int (factorial_tail 10); say "";
  print_string "factorial_tail 20 = "; print_int (factorial_tail 20); say "";

  (* 尾递归斐波那契（线性时间） *)
  let fib_tail n =
    let rec loop a b n =   (* a = fib(i), b = fib(i+1) *)
      if n = 0 then a
      else loop b (a + b) (n - 1)
    in
    loop 0 1 n
  in
  say "";
  say "Tail-recursive fibonacci (linear time):";
  for i = 0 to 10 do
    Printf.printf "  fib_tail %d = %d\n" i (fib_tail i)
  done;
  print_string "fib_tail 40 = "; print_int (fib_tail 40); say "";
  say "Tail recursion is optimized to loops - no stack overflow."

(* ---- 4) 互递归 ---- *)
(* 两个或多个函数互相递归调用。需要用 let rec ... and ... 语法。 *)

let demo_mutual_recursion () =
  say "";
  say "=== Section 4: mutual recursion ===";

  (* 判断奇偶的互递归实现（仅作演示，实际用 mod 更高效） *)
  let rec is_even n =
    if n = 0 then true
    else is_odd (n - 1)
  and is_odd n =
    if n = 0 then false
    else is_even (n - 1)
  in
  say "is_even / is_odd (mutual recursion):";
  for i = 0 to 10 do
    Printf.printf "  %d: even=%b, odd=%b\n" i (is_even i) (is_odd i)
  done;

  (* 更实际的例子：交替计算两种状态 *)
  let rec sum_even_pos lst =   (* 从索引 0 开始（偶数位置），累加当前元素 *)
    match lst with
    | [] -> 0
    | x :: rest -> x + sum_odd_pos rest
  and sum_odd_pos lst =        (* 跳过当前元素（奇数位置） *)
    match lst with
    | [] -> 0
    | _ :: rest -> sum_even_pos rest
  in
  say "";
  say "sum of elements at even indices (0, 2, 4...):";
  let lst = [10; 20; 30; 40; 50] in
  print_string "  sum_even_pos [10;20;30;40;50] = ";
  print_int (sum_even_pos lst); say "";
  say "  (10 + 30 + 50 = 90)";
  say "Mutual recursion uses let rec f ... and g ... syntax."

(* ---- 5) Ackermann 函数 ---- *)
(* Ackermann 函数是经典的递归函数，增长极快。
   A(0, n) = n + 1
   A(m, 0) = A(m-1, 1)
   A(m, n) = A(m-1, A(m, n-1)) *)

let demo_ackermann () =
  say "";
  say "=== Section 5: Ackermann function ===";
  let rec ack m n =
    if m = 0 then n + 1
    else if n = 0 then ack (m - 1) 1
    else ack (m - 1) (ack m (n - 1))
  in
  say "Ackermann function table (small values):";
  for m = 0 to 3 do
    for n = 0 to 4 do
      Printf.printf "  ack %d %d = %d\n" m n (ack m n)
    done
  done;
  say "Note: ack 4 2 is already huge (~ 2^65536).";
  say "Ackermann demonstrates deeply nested recursion."

(* ---- 6) 汉诺塔 ---- *)
(* 汉诺塔问题：将 n 个盘子从 source 移动到 target，用 auxiliary 作辅助。
   规则：每次只能移动一个盘子，大盘子不能放在小盘子上。
   经典递归解法。 *)

let demo_hanoi () =
  say "";
  say "=== Section 6: Tower of Hanoi ===";
  let rec hanoi n source target aux =
    if n = 0 then []
    else
      let step1 = hanoi (n - 1) source aux target in
      let move = Printf.sprintf "Move disk %d from %s to %s" n source target in
      let step3 = hanoi (n - 1) aux target source in
      step1 @ [move] @ step3
  in
  say "Hanoi with 3 disks (source=A, target=C, aux=B):";
  let moves = hanoi 3 "A" "C" "B" in
  List.iteri (fun i m -> Printf.printf "  %d. %s\n" (i + 1) m) moves;
  Printf.printf "  Total moves: %d\n" (List.length moves);
  say "";
  say "Hanoi with 4 disks:";
  let moves4 = hanoi 4 "A" "C" "B" in
  Printf.printf "  Total moves: %d\n" (List.length moves4);
  say "Hanoi: move n-1 to aux, move nth disk, move n-1 to target."

(* ---- 7) 递归 vs 尾递归性能对比 ---- *)
(* 对大输入来说，非尾递归可能栈溢出或更慢。
   这里用一个列表求和的例子来对比（都能完成，但展示原理）。 *)

let demo_perf_comparison () =
  say "";
  say "=== Section 7: recursion vs tail recursion ===";

  let size = 100000 in
  let big_list = List.init size (fun i -> i) in

  (* 普通递归求和（非尾递归，可能栈溢出） *)
  let rec sum_simple lst =
    match lst with
    | [] -> 0
    | x :: rest -> x + sum_simple rest
  in

  (* 尾递归求和 *)
  let sum_tail lst =
    let rec loop acc lst =
      match lst with
      | [] -> acc
      | x :: rest -> loop (acc + x) rest
    in
    loop 0 lst
  in

  say (Printf.sprintf "Summing list of %d elements..." size);

  (* 尾递归版本（安全） *)
  let t1 = Sys.time () in
  let result_tail = sum_tail big_list in
  let t2 = Sys.time () in
  Printf.printf "  Tail-recursive sum: %d (%.4f seconds)\n" result_tail (t2 -. t1);

  (* 普通递归版本（对于非常大的列表可能栈溢出） *)
  (try
    let t3 = Sys.time () in
    let result_simple = sum_simple big_list in
    let t4 = Sys.time () in
    Printf.printf "  Simple recursive sum: %d (%.4f seconds)\n" result_simple (t4 -. t3);
  with Stack_overflow ->
    say "  Simple recursive sum: Stack overflow!");

  say "";
  say "Key takeaway: use tail recursion for large inputs.";
  say "Tail-recursive functions use constant stack space."

(* ---- 主程序 ---- *)
let () =
  demo_factorial ();
  demo_fibonacci ();
  demo_tail_recursion ();
  demo_mutual_recursion ();
  demo_ackermann ();
  demo_hanoi ();
  demo_perf_comparison ();
  say "";
  say "==== 09 jieshu ===="

(* ==== 09 结束 ==== *)
