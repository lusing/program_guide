(* ==========================================================================
   28_lazy_eval.ml - 延迟求值：lazy 与 Lazy.force
   ==========================================================================
   主题：OCaml 默认即时求值（eager），但提供 lazy_t 类型按需求值。
        Haskell 默认惰性，OCaml 把惰性做成显式的数据。
   内容：
     1. 即时 vs 延迟：f false (1+2) 的两种求值路径
     2. lazy / Lazy.force / 记忆化（每个 cell 只算一次）
     3. Lazy.is_val / Lazy.from_val / Lazy.map
     4. lazy 模式：match x with lazy p -> ...
     5. 大坑：force 抛出的异常不记忆化，每次 force 都重抛
     6. 延迟流：无穷结构靠 lazy 递归定义，take 若干
     7. lazy 流 vs Seq（thunk 流）：记忆化差异的实测对比
     8. 并发警告：Lazy.force 不是线程安全的

   实测（OCaml 5.4.1）：
     - lazy(print_endline "Computing"; 1+2) 定义时不打印；
       force 时打印并返回 3；再 force 直接返回 3，不再打印。
     - Lazy.map 存在（4.13+）；lazy pattern 自 4.02 起可用。
     - force 一个抛异常的 lazy：每次 force 都重新执行并重抛
       （成功才记忆化，失败不缓存）。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 即时 vs 延迟：先看默认行为
   ======================================================================== *)
section 1 "eager by default";;

(* OCaml 是即时求值：参数 (1+2) 先算，哪怕函数根本用不上它 *)
let use_if_true b n = if b then n + 1 else 0;;

Printf.printf "use_if_true false (1+2) = %d\n" (use_if_true false (1 + 2));;
Printf.printf "use_if_true true (1+2)  = %d\n" (use_if_true true (1 + 2));;

(* 同一个函数，把参数包成 lazy：不用的分支彻底不碰参数 *)
let use_lazy b (n : int Lazy.t) =
  if b then (Lazy.force n) + 1 else 0;;

Printf.printf "use_lazy false (lazy(1+2)) = %d\n" (use_lazy false (lazy (1 + 2)));;
Printf.printf "use_lazy true (lazy(1+2))  = %d\n" (use_lazy true (lazy (1 + 2)));;

(* ========================================================================
   2) lazy / force / 记忆化
   ======================================================================== *)
section 2 "lazy, force, memoization";;

let v = lazy (print_endline "Computing"; 1 + 2);;

print_endline "-- created, not forced yet --";;
Printf.printf "is_val = %b\n" (Lazy.is_val v);;

Printf.printf "first  force = %d\n" (Lazy.force v);;
Printf.printf "second force = %d  (* no Computing above! *)\n" (Lazy.force v);;
Printf.printf "is_val now = %b\n" (Lazy.is_val v);;

(* ========================================================================
   3) Lazy 模块的其他成员
   ======================================================================== *)
section 3 "Lazy.is_val / from_val / map";;

(* from_val：把已经算好的值包装成"已记忆化"的 lazy *)
let w = Lazy.from_val 9;;
Printf.printf "from_val 9: force = %d, is_val = %b\n" (Lazy.force w) (Lazy.is_val w);;

(* map：对延迟值套函数，结果仍是延迟值（链式推迟） *)
let m = Lazy.map (fun x -> x * 10) v;;
Printf.printf "mapped: force = %d (v memoized so no recompute)\n" (Lazy.force m);;

(* ========================================================================
   4) lazy 模式
   ======================================================================== *)
section 4 "lazy patterns";;

let pair = lazy (3, 4);;

(* lazy p 在匹配时 force，再对结果做 p 的结构匹配 *)
let sum = match pair with lazy (a, b) -> a + b;;
Printf.printf "lazy pattern: match pair with lazy (a,b) -> a+b = %d\n" sum;;

(* 与函数配合：解构延迟的树/流时特别顺手 *)
let first = function
  | lazy (x :: _) -> Printf.printf "  first elem = %d\n" x
  | lazy [] -> print_endline "  empty";;
first (lazy [7; 8; 9]);;
first (lazy []);;

(* ========================================================================
   5) 坑：异常不记忆化
   ======================================================================== *)
section 5 "pitfall: exceptions are NOT memoized";;

let bad = lazy (print_endline "attempting"; failwith "boom");;

let try_force () =
  try
    ignore (Lazy.force bad);
    "ok"
  with e -> Printexc.to_string e;;

Printf.printf "1st force -> %s\n" (try_force ());;
Printf.printf "2nd force -> %s\n" (try_force ());;
print_endline "(* 'attempting' printed twice: failure is recomputed every time *)";;

(* ========================================================================
   6) 延迟流：无穷结构
   ======================================================================== *)
section 6 "lazy streams: infinite structures";;

(* 头是现成值，尾是"以后再算"的延迟流 *)
type 'a cell = Nil | Cons of 'a * 'a lstream
and 'a lstream = 'a cell Lazy.t;;

(* 无穷自然数流： Cons 的尾又是同类型的 lazy —— 递归定义合法，
   因为 lazy 把"下一步"推迟到 force 时 *)
let rec naturals_from n : int lstream =
  lazy (Cons (n, naturals_from (n + 1)));;

let naturals = naturals_from 0;;

let rec take n (s : 'a lstream) : 'a list =
  if n = 0 then []
  else match Lazy.force s with
    | Nil -> []
    | Cons (x, tl) -> x :: take (n - 1) tl;;

Printf.printf "take 5 naturals = [%s]\n"
  (String.concat ";" (List.map string_of_int (take 5 naturals)));;

(* 流上的 map / filter：同样递归 + lazy *)
let rec smap f (s : 'a lstream) : 'b lstream =
  lazy (match Lazy.force s with
        | Nil -> Nil
        | Cons (x, tl) -> Cons (f x, smap f tl));;

let rec sfilter p (s : 'a lstream) : 'a lstream =
  lazy (match Lazy.force s with
        | Nil -> Nil
        | Cons (x, tl) ->
          if p x then Cons (x, sfilter p tl)
          else Lazy.force (sfilter p tl));;

let evens = sfilter (fun x -> x mod 2 = 0) (smap (fun x -> x * 3) naturals);;
Printf.printf "first 5 of filter even (map (*3) naturals) = [%s]\n"
  (String.concat ";" (List.map string_of_int (take 5 evens)));;

(* ========================================================================
   7) lazy 流 vs Seq：记忆化差异
   ======================================================================== *)
section 7 "lazy stream vs Seq (thunk)";;

(* 计数器：记录"真正计算"发生了几次 *)
let computations = ref 0;;

let count_expr () = incr computations; !computations * 10;;

(* lazy 版：计算一次，之后白拿 *)
let lz = lazy (count_expr ());;
let a1 = Lazy.force lz;;
let a2 = Lazy.force lz;;
Printf.printf "lazy: two forces -> %d, %d, computations = %d\n" a1 a2 !computations;;

(* Seq 版：每次遍历都重算（thunk 不记忆化） *)
computations := 0;;
let sq = Seq.unfold (fun i -> if i > 3 then None else Some (count_expr (), i + 1)) 1;;
let b1 = List.of_seq sq;;
let b2 = List.of_seq sq;;
Printf.printf "seq: two walks -> [%s], [%s], computations = %d\n"
  (String.concat ";" (List.map string_of_int b1))
  (String.concat ";" (List.map string_of_int b2))
  !computations;;

(* 结论：要"算一次反复用"选 lazy；要"便宜地重新扫一遍"选 Seq。
   21 号示例的 Seq 管道就是无记忆版本的设计。 *)

(* ========================================================================
   8) 并发警告（不实测，避免真崩）
   ======================================================================== *)
section 8 "thread-safety warning";;

print_endline "Lazy.force is NOT thread-safe.";;

(* OCaml 手册原意：两个 Domain 同时 force 同一个 lazy 可能崩
   （内部状态机没有同步）。Domain 场景下要么每个 Domain 用自己的
   lazy，要么 Mutex 包住 force。29 号示例的 Domain 并行里，
   各 Domain 各自持有延迟值就没这个问题。 *)

print_endline "==== 28 jieshu ====";;
