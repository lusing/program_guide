(* ==========================================================================
   21_streams_seq.ml - 流与序列
   ==========================================================================
   主题：OCaml 中的序列（Seq）和流（Stream）
   内容：
     1. Seq 序列（惰性序列）
     2. 序列的生成与转换
     3. 无限序列
     4. Stream 流（传统流）
     5. 序列 vs 列表
     6. 管道式数据处理

   运行方式：
     ocaml 21_streams_seq.ml
     或
     utop # #use "21_streams_seq.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-')

(* 辅助函数：打印序列的前 n 个元素 *)
let print_seq label n seq =
  let rec take i s acc =
    if i <= 0 then List.rev acc
    else match s () with
      | Seq.Nil -> List.rev acc
      | Seq.Cons (x, rest) -> take (i - 1) rest (x :: acc)
  in
  let items = take n seq [] in
  Printf.printf "%s (first %d): [%s%s]\n" label n
    (String.concat "; " (List.map string_of_int items))
    (if Seq.is_empty (Seq.drop n seq) then "" else "; ...")

(* ========================================================================
   1) Seq 序列（惰性序列）
   ========================================================================
   Seq 是 OCaml 标准库中的惰性序列（lazy sequence）。
   类型：'a Seq.t （实际上是 unit -> 'a Seq.node）
   Seq.node = Nil | Cons of 'a * 'a Seq.t

   惰性意味着元素按需计算，只有在需要时才生成下一个元素。
   这使得可以表示无限序列，也可以避免不必要的计算。
*)
section 1 "Seq (lazy sequences)";;

(* 从列表创建序列 *)
let s1 = List.to_seq [1; 2; 3; 4; 5]
print_seq "From list" 10 s1;;

(* 空序列 *)
let empty_seq = Seq.empty
Printf.printf "Empty seq is_empty: %b\n" (Seq.is_empty empty_seq);;

(* 单元素序列 *)
let single = Seq.return 42
print_seq "Single element" 5 single;;

(* cons : 在序列前添加元素 *)
let s2 = Seq.cons 0 s1
print_seq "Cons 0 to list seq" 10 s2;;

(* 访问序列的头部 *)
(match s2 () with
 | Seq.Nil -> print_endline "Empty"
 | Seq.Cons (h, _) -> Printf.printf "Head of s2: %d\n" h);;

(* Seq.unfold : 用一个生成函数构造序列 *)
let count_up start =
  Seq.unfold (fun n -> Some (n, n + 1)) start

let s3 = count_up 1
print_seq "Unfold count from 1" 10 s3;;

(* Seq.init : 按索引生成序列 *)
let s4 = Seq.init 10 (fun i -> i * i)
print_seq "Seq.init 10 (i*i)" 15 s4;;

(* Seq.forever : 重复调用函数生成无限序列 *)
let counter = ref 0 in
let s5 = Seq.forever (fun () -> incr counter; !counter) in
print_seq "Seq.forever counter" 8 s5;;

(* ========================================================================
   2) 序列的生成与转换
   ========================================================================
   序列的常用操作：
   - map : 映射
   - filter : 过滤
   - fold_left : 折叠
   - take : 取前 n 个
   - drop : 跳过前 n 个
   - append : 连接
   - flat_map : 扁平化映射
   - zip / unzip : 压缩/解压
   - to_list / of_list : 与列表互转
   - to_array / of_array : 与数组互转
*)
section 2 "Sequence generation and transformation";;

(* map *)
let nums = Seq.ints 0  (* 0, 1, 2, 3, ... *)
let doubled = Seq.map (fun x -> x * 2) nums
print_seq "ints 0" 10 nums;;
print_seq "map (*2)" 10 doubled;;

(* filter *)
let evens = Seq.filter (fun x -> x mod 2 = 0) nums
let odds = Seq.filter (fun x -> x mod 2 <> 0) nums
print_seq "evens (filter)" 10 evens;;
print_seq "odds (filter)" 10 odds;;

(* take / drop *)
let first5 = Seq.take 5 nums
let from5 = Seq.drop 5 nums
print_seq "take 5" 10 first5;;
print_seq "drop 5 (first 5 shown)" 5 from5;;

(* fold_left *)
let sum_first_10 = Seq.fold_left (+) 0 (Seq.take 10 nums) in
Printf.printf "Sum of first 10 ints: %d\n" sum_first_10;;

(* append *)
let s_a = Seq.init 3 (fun i -> i)  (* 0, 1, 2 *)
let s_b = Seq.init 3 (fun i -> i + 10)  (* 10, 11, 12 *)
let s_appended = Seq.append s_a s_b
print_seq "s_a" 10 s_a;
print_seq "s_b" 10 s_b;
print_seq "append" 10 s_appended;;

(* flat_map : 每个元素展开为一个序列 *)
let pairs = Seq.flat_map (fun x ->
  Seq.map (fun y -> (x, y)) (Seq.take 3 (Seq.ints 1))
) (Seq.take 2 (Seq.ints 1))
(* 生成: (1,1) (1,2) (1,3) (2,1) (2,2) (2,3) *)
print_endline "flat_map pairs (first 6):";
Seq.iteri (fun i (a, b) ->
  if i < 6 then Printf.printf "  (%d, %d)\n" a b
) pairs;;

(* zip : 将两个序列压缩为元组序列 *)
let letters = Seq.init 5 (fun i -> Char.chr (Char.code 'a' + i))
let zipped = Seq.zip (Seq.ints 1) letters
print_endline "zip (int, char):";
Seq.iteri (fun i (n, c) ->
  if i < 5 then Printf.printf "  (%d, %c)\n" n c
) zipped;;

(* 与列表、数组的转换 *)
let lst = List.of_seq (Seq.take 5 (Seq.ints 1)) in
Printf.printf "to_list: [%s]\n" (String.concat "; " (List.map string_of_int lst));
let arr = Array.of_seq (Seq.take 5 (Seq.ints 10)) in
Printf.printf "to_array: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list arr)));;

(* ========================================================================
   3) 无限序列
   ========================================================================
   由于惰性求值，序列可以表示无限长的数据。
   只要不全量求值，只取需要的部分即可。
   常见的无限序列：自然数、斐波那契、素数、迭代生成的序列等。
*)
section 3 "Infinite sequences";;

(* 自然数序列（使用 Seq.ints） *)
let naturals = Seq.ints 0
print_seq "Naturals" 10 naturals;;

(* 斐波那契序列 *)
let fibonacci =
  let rec fib a b () = Seq.Cons (a, fib b (a + b)) in
  fib 0 1
print_seq "Fibonacci" 15 fibonacci;;

(* 素数序列（埃拉托斯特尼筛法的惰性版本） *)
let primes =
  let rec sieve s () =
    match s () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (p, rest) ->
        Seq.Cons (p, sieve (Seq.filter (fun n -> n mod p <> 0) rest))
  in
  sieve (Seq.ints 2)
print_seq "Primes" 15 primes;;

(* 幂序列：2^0, 2^1, 2^2, ... *)
let powers_of_two =
  let rec pow n () = Seq.Cons (n, pow (n * 2)) in
  pow 1
print_seq "Powers of 2" 12 powers_of_two;;

(* 三角数序列：1, 1+2=3, 1+2+3=6, ... *)
let triangular =
  let rec tri n sum () =
    let new_sum = sum + n in
    Seq.Cons (new_sum, tri (n + 1) new_sum)
  in
  tri 1 0
print_seq "Triangular numbers" 10 triangular;;

(* 阶乘序列 *)
let factorials =
  let rec fact n f () =
    let new_f = f * n in
    Seq.Cons (new_f, fact (n + 1) new_f)
  in
  fact 1 1
print_seq "Factorials" 10 factorials;;

(* 使用 unfold 实现 Collatz 序列（冰雹猜想）
   规则：n -> n/2 (偶数), n -> 3n+1 (奇数)，直到 1 *)
let collatz start =
  Seq.unfold (fun n ->
    if n = 0 then None
    else if n = 1 then Some (1, 0)  (* 最后一个元素，然后结束 *)
    else Some (n, if n mod 2 = 0 then n / 2 else 3 * n + 1)
  ) start

let test_collatz n =
  let seq = collatz n in
  let len = Seq.length seq in
  let items = List.of_seq seq in
  Printf.printf "  Collatz(%d): [%s] (length: %d)\n" n
    (String.concat " -> " (List.map string_of_int items)) len

print_endline "Collatz sequences:";
test_collatz 6;;
test_collatz 13;;
test_collatz 27;;
test_collatz 1;;

(* ========================================================================
   4) Stream 流（传统流）
   ========================================================================
   Stream 是 OCaml 中另一种流式数据结构，来自 Stream 模块。
   它与 Seq 类似，但更偏向于"按需消费"的流式处理。
   Stream 通常用于解析器和增量数据处理。
   - Stream.from : 从索引函数创建流
   - Stream.of_list : 从列表创建
   - Stream.next : 取下一个元素（可能抛出 Stream.Failure）
   - Stream.peek : 查看下一个元素但不消费
   - Stream.empty : 检查是否为空
   - Stream.iter : 遍历
*)
section 4 "Stream (traditional streams)";;

(* 从列表创建流 *)
let stream1 = Stream.of_list [10; 20; 30; 40; 50]

(* 逐个消费 *)
Printf.printf "Stream next: %d\n" (Stream.next stream1);;
Printf.printf "Stream next: %d\n" (Stream.next stream1);;
Printf.printf "Stream peek: %d\n" (Stream.peek stream1);;
Printf.printf "Stream next: %d\n" (Stream.next stream1);;
Printf.printf "Stream empty? %b\n" (Stream.empty stream1);;

(* 从函数创建流 *)
let counter = ref 0 in
let stream2 = Stream.from (fun _ ->
  incr counter;
  if !counter > 5 then None
  else Some (!counter * !counter)
)

print_endline "Stream.from (squares):";
Stream.iter (fun x -> Printf.printf "  %d\n" x) stream2;;

(* Stream 用于解析（模拟） *)
let char_stream_of_string s =
  Stream.of_string s

let stream3 = char_stream_of_string "hello" in
Printf.printf "Char stream first: %c\n" (Stream.next stream3);
Printf.printf "Second: %c\n" (Stream.next stream3);;

(* 用 Stream 实现简单的整数解析 *)
let parse_int_stream s =
  let chars = Stream.of_string s in
  let buf = Buffer.create 16 in
  let rec parse () =
    match Stream.peek chars with
    | Some ('0'..'9' as c) ->
        Stream.junk chars;
        Buffer.add_char buf c;
        parse ()
    | Some '-' when Buffer.length buf = 0 ->
        Stream.junk chars;
        Buffer.add_char buf '-';
        parse ()
    | _ ->
        if Buffer.length buf = 0 then failwith "parse_int: no digits"
        else int_of_string (Buffer.contents buf)
  in
  parse ()

Printf.printf "parse_int_stream \"42\": %d\n" (parse_int_stream "42");;
Printf.printf "parse_int_stream \"-123\": %d\n" (parse_int_stream "-123");;
Printf.printf "parse_int_stream \"99abc\": %d\n" (parse_int_stream "99abc");;

(* Stream 与 Seq 的互转 *)
let stream_of_seq seq =
  Stream.from (fun _ ->
    match seq () with
    | Seq.Nil -> None
    | Seq.Cons (x, rest) ->
        Obj.set_field (Obj.repr seq) 0 (Obj.repr rest);  (* 不推荐这样用 *)
        Some x
  )

(* 更简单的方式：先转列表再转 Stream *)
let seq_of_first_10_primes = Seq.take 10 primes in
let prime_list = List.of_seq seq_of_first_10_primes in
let prime_stream = Stream.of_list prime_list in
print_endline "Prime stream:";
Stream.iter (fun p -> Printf.printf "  %d\n" p) prime_stream;;

(* ========================================================================
   5) 序列 vs 列表
   ========================================================================
   序列（Seq）和列表（List）的区别：
   - 列表是严格的（所有元素都已计算），序列是惰性的
   - 列表适合小规模数据，序列适合大规模或无限数据
   - 列表随机访问慢（O(n)），序列根本不支持随机访问
   - 列表可以多次遍历，序列也可以（因为是函数式的）
   - 管道式处理时，序列避免了中间数据结构的分配

   什么时候用什么：
   - 数据量小，需要多次访问：用列表
   - 数据量大或无限，只遍历一次：用序列
   - 需要组合多个变换操作：用序列（惰性组合）
*)
section 5 "Seq vs List";;

(* 比较：列表 vs 序列的管道处理 *)

(* 列表版本：每一步都创建一个新列表 *)
let list_pipeline n =
  let lst = List.init n (fun i -> i) in
  let mapped = List.map (fun x -> x * 2) lst in
  let filtered = List.filter (fun x -> x mod 3 = 0) mapped in
  let doubled = List.map (fun x -> x * x) filtered in
  List.fold_left (+) 0 (List.take 10 doubled)  (* List.take 可能不存在 *)

(* 由于 List.take 不是标准函数，我们用 Seq 来比较 *)

(* 序列版本：惰性计算，没有中间列表 *)
let seq_pipeline n =
  let s = Seq.ints 0 in
  let s1 = Seq.map (fun x -> x * 2) s in
  let s2 = Seq.filter (fun x -> x mod 3 = 0) s1 in
  let s3 = Seq.map (fun x -> x * x) s2 in
  let s4 = Seq.take 10 s3 in
  Seq.fold_left (+) 0 s4

(* 计时比较 *)
let time_it label f =
  let start = Unix.gettimeofday () in
  let result = f () in
  let elapsed = Unix.gettimeofday () -. start in
  Printf.printf "  %s: result = %d, time = %.6f seconds\n" label result elapsed;
  result

print_endline "Performance comparison (large data):";
let n = 1000000 in
let _ = time_it "Seq pipeline" (fun () -> seq_pipeline n) in

(* 对应的列表版本（近似） *)
let list_pipeline_full n =
  let rec init i acc =
    if i < 0 then acc
    else init (i - 1) (i :: acc)
  in
  let lst = init (n - 1) [] in
  let mapped = List.map (fun x -> x * 2) lst in
  let filtered = List.filter (fun x -> x mod 3 = 0) mapped in
  let doubled = List.map (fun x -> x * x) filtered in
  let rec take n lst = match n, lst with
    | 0, _ -> []
    | _, [] -> []
    | _, h :: t -> h :: take (n - 1) t
  in
  let taken = take 10 doubled in
  List.fold_left (+) 0 taken

let _ = time_it "List pipeline" (fun () -> list_pipeline_full n);;

(* 说明：序列的优势在于不需要分配中间数据结构，
   尤其是在大数量级下，可以节省大量内存。
   对于小数据量，列表可能更快，因为没有惰性计算的开销。 *)

(* 内存使用对比的直观演示 *)
print_endline "\nMemory characteristics:";
print_endline "  List: all elements exist in memory at once";
print_endline "  Seq: only one element computed at a time during traversal";
print_endline "  Seq can represent infinite sequences";
print_endline "  List length is O(1); Seq length is O(n)";
print_endline "  List can be accessed multiple times efficiently";
print_endline "  Seq is recomputed each time (unless converted to list)";

(* 序列的重复计算问题演示 *)
let side_effect_counter = ref 0 in
let seq_with_side_effect =
  Seq.init 5 (fun i ->
    incr side_effect_counter;
    i * 10
  ) in

side_effect_counter := 0;
let _ = Seq.nth seq_with_side_effect 2 in
Printf.printf "\nAfter Seq.nth 2: counter = %d (computed up to index 2)\n"
  !side_effect_counter;

side_effect_counter := 0;
let _ = List.of_seq seq_with_side_effect in
Printf.printf "After List.of_seq: counter = %d (computed all)\n"
  !side_effect_counter;

side_effect_counter := 0;
let _ = Seq.nth seq_with_side_effect 2 in
Printf.printf "After second Seq.nth 2: counter = %d (recomputed!)\n"
  !side_effect_counter;;

(* ========================================================================
   6) 管道式数据处理
   ========================================================================
   序列非常适合管道式（pipeline）数据处理。
   多个操作（map, filter, flat_map 等）可以链式组合，
   惰性求值确保数据在管道中"流动"时被逐步处理。
   这是函数式编程中处理数据的优雅方式。
*)
section 6 "Pipeline data processing";;

(* 示例 1：处理数字序列 *)
print_endline "Pipeline 1: number crunching";
let result1 =
  Seq.ints 1
  |> Seq.map (fun x -> x * x)        (* 平方 *)
  |> Seq.filter (fun x -> x mod 2 = 0)  (* 只保留偶数 *)
  |> Seq.take 10                      (* 取前10个 *)
  |> Seq.fold_left (+) 0              (* 求和 *)
in
Printf.printf "  Sum of first 10 even squares: %d\n" result1;;

(* 示例 2：文本处理管道 *)
print_endline "\nPipeline 2: text processing";
let text = "The quick brown fox jumps over the lazy dog" in
let words =
  String.split_on_char ' ' text
  |> List.to_seq
  |> Seq.map (fun w ->
    String.map (fun c ->
      if c >= 'A' && c <= 'Z' then Char.chr (Char.code c + 32) else c
    ) w)
  |> Seq.filter (fun w -> String.length w > 3)
  |> Seq.map String.capitalize_ascii
  |> Seq.sort String.compare
  |> List.of_seq
in
Printf.printf "  Words >3 chars, capitalized, sorted: [%s]\n"
  (String.concat ", " words);;

(* 示例 3：生成并筛选素数的管道 *)
print_endline "\nPipeline 3: prime number processing";
let prime_pipeline n =
  Seq.ints 2
  |> Seq.filter (fun p ->
    Seq.ints 2
    |> Seq.take_while (fun d -> d * d <= p)
    |> Seq.for_all (fun d -> p mod d <> 0)
  )
  |> Seq.take n
  |> List.of_seq

let first_15_primes = prime_pipeline 15 in
Printf.printf "  First 15 primes: [%s]\n"
  (String.concat ", " (List.map string_of_int first_15_primes));;

(* 示例 4：数据统计管道 *)
print_endline "\nPipeline 4: data statistics";
type record = { name : string; age : int; score : float }

let data = [
  { name = "Alice"; age = 20; score = 95.5 };
  { name = "Bob"; age = 21; score = 87.3 };
  { name = "Charlie"; age = 19; score = 92.0 };
  { name = "Diana"; age = 22; score = 78.6 };
  { name = "Eve"; age = 20; score = 88.8 };
  { name = "Frank"; age = 21; score = 91.5 };
  { name = "Grace"; age = 19; score = 97.0 };
  { name = "Henry"; age = 22; score = 75.2 };
]

let stats =
  List.to_seq data
  |> Seq.filter (fun r -> r.score >= 80.0)
  |> Seq.map (fun r -> r.score)
  |> Seq.fold_left
       (fun (count, sum, min_s, max_s) s ->
         (count + 1, sum +. s, min min_s s, max max_s s))
       (0, 0.0, max_float, neg_infinity)

let count, sum, min_s, max_s = stats in
let avg = sum /. float_of_int count in
Printf.printf "  Students with score >= 80: %d\n" count;
Printf.printf "  Average score: %.2f\n" avg;
Printf.printf "  Min score: %.2f\n" min_s;
Printf.printf "  Max score: %.2f\n" max_s;;

(* 示例 5：分组聚合管道 *)
print_endline "\nPipeline 5: group by age";
module IntMap = Map.Make(Int)

let group_by_age records =
  List.to_seq records
  |> Seq.fold_left (fun map r ->
    let current = try IntMap.find r.age map with Not_found -> (0, 0.0) in
    let count, sum = current in
    IntMap.add r.age (count + 1, sum +. r.score) map
  ) IntMap.empty
  |> IntMap.to_seq
  |> Seq.map (fun (age, (count, sum)) ->
       (age, count, sum /. float_of_int count))
  |> List.of_seq

let age_groups = group_by_age data in
Printf.printf "  %-5s %-8s %-10s\n" "Age" "Count" "Avg Score";
Printf.printf "  %s\n" (String.make 25 '-');
List.iter (fun (age, count, avg) ->
  Printf.printf "  %-5d %-8d %-10.2f\n" age count avg
) age_groups;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 21 jieshu ===="  (* 第二十一个文件结束 *)
