(* ==========================================================================
   15_algorithms.ml - 排序与经典算法
   ==========================================================================
   主题：使用 OCaml 实现经典算法
   内容：
     1. 插入排序
     2. 归并排序
     3. 快速排序
     4. 二分查找
     5. 埃拉托斯特尼筛法
     6. gcd / lcm
     7. 记忆化斐波那契

   运行方式：
     ocaml 15_algorithms.ml
     或
     utop # #use "15_algorithms.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-')

(* 辅助函数：打印 int list *)
let print_list label lst =
  Printf.printf "%s: [%s]\n" label
    (String.concat "; " (List.map string_of_int lst))

(* ========================================================================
   1) 插入排序
   ========================================================================
   插入排序（Insertion Sort）：
   - 思路：将列表视为已排序和未排序两部分，逐个将未排序元素
     插入到已排序部分的正确位置。
   - 时间复杂度：O(n^2) 平均/最坏，O(n) 最好（已排序）
   - 空间复杂度：O(1)（原地）或 O(n)（函数式版本）
   - 特点：稳定排序，对于小规模或近乎有序的数据效率高。
*)
section 1 "Insertion Sort";;

(* 函数式插入排序：将 x 插入到已排序列表 lst 的正确位置 *)
let rec insert x = function
  | [] -> [x]
  | h :: t as lst ->
      if x <= h then x :: lst
      else h :: insert x t

(* 插入排序主函数 *)
let rec insertion_sort = function
  | [] -> []
  | h :: t -> insert h (insertion_sort t)

(* 测试 *)
let lst1 = [5; 2; 8; 1; 9; 3; 7; 4; 6];;
print_list "Original" lst1;;
print_list "Insertion sorted" (insertion_sort lst1);;

(* 另一种写法：使用 List.fold_left *)
let insertion_sort_fold lst =
  List.fold_left (fun acc x -> insert x acc) [] lst;;

let lst2 = [12; 4; 7; 2; 10; 1; 9; 5; 3; 8; 6; 11];;
print_list "Original" lst2;;
print_list "Insertion sort (fold)" (insertion_sort_fold lst2);;

(* 原地版本（使用数组） *)
let insertion_sort_array arr =
  let n = Array.length arr in
  for i = 1 to n - 1 do
    let key = arr.(i) in
    let j = ref (i - 1) in
    while !j >= 0 && arr.(!j) > key do
      arr.(!j + 1) <- arr.(!j);
      decr j
    done;
    arr.(!j + 1) <- key
  done;
  arr;;

let arr1 = [| 5; 2; 8; 1; 9; 3 |] in
let sorted_arr = insertion_sort_array arr1 in
Printf.printf "Array insertion sort: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list sorted_arr)));;

(* ========================================================================
   2) 归并排序
   ========================================================================
   归并排序（Merge Sort）：
   - 思路：分治法。将列表分成两半，分别排序，然后合并。
   - 时间复杂度：O(n log n) 所有情况
   - 空间复杂度：O(n)（需要额外空间存储合并结果）
   - 特点：稳定排序，适合链表和外部排序，最坏情况仍保持 O(n log n)
*)
section 2 "Merge Sort";;

(* 合并两个已排序的列表 *)
let rec merge left right =
  match left, right with
  | [], _ -> right
  | _, [] -> left
  | x :: xs, y :: ys ->
      if x <= y then x :: merge xs right
      else y :: merge left ys

(* 将列表分成两半 *)
let split lst =
  let rec loop n left right =
    if n = 0 then (List.rev left, right)
    else match right with
      | [] -> (List.rev left, [])
      | h :: t -> loop (n - 1) (h :: left) t
  in
  loop (List.length lst / 2) [] lst

(* 归并排序主函数 *)
let rec merge_sort = function
  | [] -> []
  | [x] -> [x]
  | lst ->
      let left, right = split lst in
      merge (merge_sort left) (merge_sort right)

(* 测试 *)
let lst3 = [38; 27; 43; 3; 9; 82; 10];;
print_list "Original" lst3;;
print_list "Merge sorted" (merge_sort lst3);;

(* 更高效的版本：使用索引而不是拆分列表 *)
let merge_sort_array arr =
  let n = Array.length arr in
  let temp = Array.make n 0 in
  let rec merge_arr left mid right =
    let i = ref left in
    let j = ref (mid + 1) in
    let k = ref left in
    while !i <= mid && !j <= right do
      if arr.(!i) <= arr.(!j) then begin
        temp.(!k) <- arr.(!i);
        incr i
      end else begin
        temp.(!k) <- arr.(!j);
        incr j
      end;
      incr k
    done;
    while !i <= mid do
      temp.(!k) <- arr.(!i);
      incr i; incr k
    done;
    while !j <= right do
      temp.(!k) <- arr.(!j);
      incr j; incr k
    done;
    for idx = left to right do
      arr.(idx) <- temp.(idx)
    done
  in
  let rec sort left right =
    if left < right then begin
      let mid = (left + right) / 2 in
      sort left mid;
      sort (mid + 1) right;
      merge_arr left mid right
    end
  in
  sort 0 (n - 1);
  arr;;

let arr2 = [| 38; 27; 43; 3; 9; 82; 10 |] in
let sorted_arr2 = merge_sort_array arr2 in
Printf.printf "Array merge sort: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list sorted_arr2)));;

(* ========================================================================
   3) 快速排序
   ========================================================================
   快速排序（Quick Sort）：
   - 思路：选择一个基准（pivot），将列表分成小于和大于基准的两部分，
     然后递归排序。
   - 时间复杂度：O(n log n) 平均，O(n^2) 最坏
   - 空间复杂度：O(log n) 平均（递归栈）
   - 特点：通常很快，实际中广泛使用。
*)
section 3 "Quick Sort";;

(* 简洁的函数式版本（使用 List.partition）
   注意：这不是原地排序，空间复杂度较高 *)
let rec quick_sort = function
  | [] -> []
  | pivot :: rest ->
      let smaller, larger = List.partition (fun x -> x < pivot) rest in
      quick_sort smaller @ [pivot] @ quick_sort larger

(* 测试 *)
let lst4 = [10; 7; 8; 9; 1; 5; 3; 6; 2; 4];;
print_list "Original" lst4;;
print_list "Quick sorted" (quick_sort lst4);;

(* 原地快速排序（数组版本，更高效） *)
let quick_sort_array arr =
  let n = Array.length arr in
  let swap i j =
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  in
  let partition left right =
    let pivot = arr.(right) in
    let i = ref (left - 1) in
    for j = left to right - 1 do
      if arr.(j) <= pivot then begin
        incr i;
        swap !i j
      end
    done;
    swap (!i + 1) right;
    !i + 1
  in
  let rec sort left right =
    if left < right then begin
      let pi = partition left right in
      sort left (pi - 1);
      sort (pi + 1) right
    end
  in
  sort 0 (n - 1);
  arr;;

let arr3 = [| 10; 7; 8; 9; 1; 5; 3; 6; 2; 4 |] in
let sorted_arr3 = quick_sort_array arr3 in
Printf.printf "Array quick sort: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list sorted_arr3)));;

(* 三数取中优化：选左中右的中位数作为 pivot，减少最坏情况概率 *)
let quick_sort_optimized arr =
  let n = Array.length arr in
  let swap i j =
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  in
  let median_of_three left mid right =
    if arr.(left) > arr.(mid) then swap left mid;
    if arr.(left) > arr.(right) then swap left right;
    if arr.(mid) > arr.(right) then swap mid right;
    swap mid (right - 1);
    arr.(right - 1)
  in
  let rec sort left right =
    if right - left > 1 then begin
      let mid = (left + right) / 2 in
      let pivot = median_of_three left mid right in
      let i = ref left in
      let j = ref (right - 1) in
      while true do
        incr i;
        while arr.(!i) < pivot do incr i done;
        decr j;
        while arr.(!j) > pivot do decr j done;
        if !i < !j then swap !i !j else raise Exit
      done;
      (try () with Exit -> ());
      swap !i (right - 1);
      sort left (!i - 1);
      sort (!i + 1) right
    end else if right - left = 1 then
      if arr.(left) > arr.(right) then swap left right
  in
  if n > 0 then sort 0 (n - 1);
  arr;;

let arr4 = [| 10; 7; 8; 9; 1; 5; 3; 6; 2; 4; 15; 12; 11; 14; 13 |] in
let sorted_arr4 = quick_sort_optimized arr4 in
Printf.printf "Optimized quick sort: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list sorted_arr4)));;

(* ========================================================================
   4) 二分查找
   ========================================================================
   二分查找（Binary Search）：
   - 前提：数组/列表已排序
   - 思路：每次比较中间元素，将搜索范围缩小一半
   - 时间复杂度：O(log n)
   - 空间复杂度：O(1)（迭代）或 O(log n)（递归）
*)
section 4 "Binary Search";;

(* 递归版本（数组） *)
let binary_search_rec arr target =
  let rec search left right =
    if left > right then None
    else
      let mid = (left + right) / 2 in
      if arr.(mid) = target then Some mid
      else if arr.(mid) < target then search (mid + 1) right
      else search left (mid - 1)
  in
  search 0 (Array.length arr - 1)

(* 迭代版本（数组，更高效） *)
let binary_search_iter arr target =
  let left = ref 0 in
  let right = ref (Array.length arr - 1) in
  let found = ref None in
  while !left <= !right && !found = None do
    let mid = (!left + !right) / 2 in
    if arr.(mid) = target then
      found := Some mid
    else if arr.(mid) < target then
      left := mid + 1
    else
      right := mid - 1
  done;
  !found

(* 测试 *)
let sorted_arr5 = [| 1; 3; 5; 7; 9; 11; 13; 15; 17; 19; 21 |] in
Printf.printf "Sorted array: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list sorted_arr5)));
let test_binary target =
  match binary_search_iter sorted_arr5 target with
  | Some idx -> Printf.printf "  Found %d at index %d\n" target idx
  | None -> Printf.printf "  %d not found\n" target
in
test_binary 7;
test_binary 21;
test_binary 1;
test_binary 10;
test_binary 0;
test_binary 25;;

(* 二分查找的变体：查找第一个出现的位置 *)
let binary_search_first arr target =
  let left = ref 0 in
  let right = ref (Array.length arr - 1) in
  let result = ref None in
  while !left <= !right do
    let mid = (!left + !right) / 2 in
    if arr.(mid) = target then begin
      result := Some mid;
      right := mid - 1  (* 继续在左半部分找 *)
    end else if arr.(mid) < target then
      left := mid + 1
    else
      right := mid - 1
  done;
  !result

let arr_with_dups = [| 1; 2; 2; 2; 3; 4; 4; 5; 6; 6; 6; 7 |] in
Printf.printf "Array with duplicates: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list arr_with_dups)));
(match binary_search_first arr_with_dups 2 with
 | Some idx -> Printf.printf "  First occurrence of 2 at index %d\n" idx
 | None -> ());
(match binary_search_first arr_with_dups 6 with
 | Some idx -> Printf.printf "  First occurrence of 6 at index %d\n" idx
 | None -> ());;

(* ========================================================================
   5) 埃拉托斯特尼筛法
   ========================================================================
   Sieve of Eratosthenes：
   - 用途：找出 n 以内的所有素数
   - 思路：从 2 开始，将每个素数的倍数标记为非素数
   - 时间复杂度：O(n log log n)
   - 空间复杂度：O(n)
*)
section 5 "Sieve of Eratosthenes";;

let sieve n =
  if n < 2 then [||]
  else begin
    (* is_prime.(i) 表示 i 是否是素数，初始都为 true *)
    let is_prime = Array.make (n + 1) true in
    is_prime.(0) <- false;
    is_prime.(1) <- false;
    let i = ref 2 in
    while !i * !i <= n do
      if is_prime.(!i) then begin
        (* 将 i 的倍数从 i*i 开始标记为非素数 *)
        let j = ref (!i * !i) in
        while !j <= n do
          is_prime.(!j) <- false;
          j := !j + !i
        done
      end;
      incr i
    done;
    (* 收集所有素数 *)
    let primes = ref [] in
    for k = n downto 2 do
      if is_prime.(k) then
        primes := k :: !primes
    done;
    Array.of_list !primes
  end

let primes_100 = sieve 100 in
Printf.printf "Primes up to 100 (%d primes):\n" (Array.length primes_100);
print_endline ("  [" ^ String.concat ", " (List.map string_of_int (Array.to_list primes_100)) ^ "]");;

let primes_1000 = sieve 1000 in
Printf.printf "Primes up to 1000: %d primes\n" (Array.length primes_1000);;

(* 利用筛法判断素数 *)
let is_prime_sieve n =
  if n < 2 then false
  else
    let primes = sieve n in
    let rec binary_search arr left right target =
      if left > right then false
      else
        let mid = (left + right) / 2 in
        if arr.(mid) = target then true
        else if arr.(mid) < target then binary_search arr (mid + 1) right target
        else binary_search arr left (mid - 1) target
    in
    binary_search primes 0 (Array.length primes - 1) n;;

Printf.printf "Is 97 prime? %b\n" (is_prime_sieve 97);
Printf.printf "Is 100 prime? %b\n" (is_prime_sieve 100);
Printf.printf "Is 997 prime? %b\n" (is_prime_sieve 997);;

(* ========================================================================
   6) gcd / lcm
   ========================================================================
   最大公约数（gcd）和最小公倍数（lcm）：
   - gcd(a, b): 能同时整除 a 和 b 的最大正整数
   - lcm(a, b): 能同时被 a 和 b 整除的最小正整数
   - 关系：lcm(a, b) = |a * b| / gcd(a, b)
   - 欧几里得算法：gcd(a, b) = gcd(b, a mod b)
*)
section 6 "gcd and lcm";;

(* 递归版本的欧几里得算法 *)
let rec gcd a b =
  if b = 0 then abs a
  else gcd b (a mod b)

(* 迭代版本 *)
let gcd_iter a b =
  let a = ref (abs a) in
  let b = ref (abs b) in
  while !b <> 0 do
    let tmp = !a mod !b in
    a := !b;
    b := tmp
  done;
  !a

(* 最小公倍数 *)
let lcm a b =
  if a = 0 || b = 0 then 0
  else abs (a * b) / gcd a b

(* 测试 *)
let test_gcd a b =
  Printf.printf "  gcd(%d, %d) = %d, lcm(%d, %d) = %d\n"
    a b (gcd a b) a b (lcm a b);;

print_endline "GCD and LCM tests:";
test_gcd 48 18;
test_gcd 1071 462;
test_gcd 100 25;
test_gcd 7 13;
test_gcd 0 5;
test_gcd (-24) 36;;

(* 多个数的 gcd / lcm *)
let gcd_list = List.fold_left gcd 0
let lcm_list = List.fold_left lcm 1

let nums = [12; 18; 24; 30] in
Printf.printf "gcd of [%s] = %d\n"
  (String.concat "; " (List.map string_of_int nums)) (gcd_list nums);
Printf.printf "lcm of [%s] = %d\n"
  (String.concat "; " (List.map string_of_int nums)) (lcm_list nums);;

(* ========================================================================
   7) 记忆化斐波那契
   ========================================================================
   斐波那契数列：F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2)
   朴素递归的时间复杂度是 O(2^n)，非常慢。
   使用记忆化（memoization）可以降到 O(n)。
*)
section 7 "Memoized Fibonacci";;

(* 朴素递归（慢，O(2^n)） *)
let rec naive_fib n =
  if n <= 1 then n
  else naive_fib (n - 1) + naive_fib (n - 2)

(* 迭代版本（O(n) 时间，O(1) 空间） *)
let iter_fib n =
  if n <= 1 then n
  else begin
    let a = ref 0 in
    let b = ref 1 in
    for _ = 2 to n do
      let tmp = !a + !b in
      a := !b;
      b := tmp
    done;
    !b
  end

(* 使用 Hashtbl 记忆化 *)
let memo_fib =
  let cache = Hashtbl.create 100 in
  let rec fib n =
    try Hashtbl.find cache n
    with Not_found ->
      let result =
        if n <= 1 then n
        else fib (n - 1) + fib (n - 2)
      in
      Hashtbl.add cache n result;
      result
  in
  fib

(* 使用数组预计算（动态规划） *)
let dp_fib n =
  if n <= 1 then n
  else begin
    let dp = Array.make (n + 1) 0 in
    dp.(0) <- 0;
    dp.(1) <- 1;
    for i = 2 to n do
      dp.(i) <- dp.(i - 1) + dp.(i - 2)
    done;
    dp.(n)
  end

(* 矩阵快速幂（O(log n)） *)
let matrix_mult a b =
  [| [| a.(0).(0) * b.(0).(0) + a.(0).(1) * b.(1).(0);
        a.(0).(0) * b.(0).(1) + a.(0).(1) * b.(1).(1) |];
     [| a.(1).(0) * b.(0).(0) + a.(1).(1) * b.(1).(0);
        a.(1).(0) * b.(0).(1) + a.(1).(1) * b.(1).(1) |] |]

let fast_fib n =
  if n <= 1 then n
  else
    let rec matrix_pow m e =
      if e = 1 then m
      else if e mod 2 = 0 then
        let half = matrix_pow m (e / 2) in
        matrix_mult half half
      else
        let half = matrix_pow m (e / 2) in
        matrix_mult m (matrix_mult half half)
    in
    let base = [| [| 1; 1 |]; [| 1; 0 |] |] in
    let result = matrix_pow base n in
    result.(0).(1)

(* 测试各种方法 *)
let test_fib n =
  Printf.printf "Fibonacci(%d):\n" n;
  if n <= 30 then
    Printf.printf "  Naive:     %d\n" (naive_fib n);
  Printf.printf "  Iterative: %d\n" (iter_fib n);
  Printf.printf "  Memoized:  %d\n" (memo_fib n);
  Printf.printf "  DP:        %d\n" (dp_fib n);
  Printf.printf "  Fast pow:  %d\n" (fast_fib n);;

test_fib 10;
test_fib 20;
test_fib 30;
test_fib 40;
test_fib 50;;

(* 展示记忆化的速度优势：计算多个 fib 值时缓存复用 *)
print_endline "\nMemoization benefit (cached values reused):";
let start = Unix.gettimeofday () in
for i = 0 to 30 do
  ignore (memo_fib i)
done;
let elapsed = Unix.gettimeofday () -. start in
Printf.printf "  Compute fib(0..30) with memo: %.6f seconds\n" elapsed;

let start2 = Unix.gettimeofday () in
for i = 0 to 30 do
  ignore (memo_fib i)  (* 第二次调用直接从缓存取 *)
done;
let elapsed2 = Unix.gettimeofday () -. start2 in
Printf.printf "  Second call (all cached):     %.6f seconds\n" elapsed2;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 15 jieshu ===="  (* 第十五个文件结束 *)
