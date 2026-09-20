(* ==========================================================================
   25_domains_effects.ml - OCaml 5 并发：Domain 与 Effect
   ==========================================================================
   主题：OCaml 5 的并行（Domain 多核）与效应（Effect handler）
   内容：
     1. Domain：spawn / join / recommended_domain_count
     2. Atomic：跨 domain 的原子计数
     3. Mutex：互斥访问共享缓冲
     4. 并行数组求和：分块 + Atomic 累加，结果与串行一致
     5. Effect 基础：Xchg 效应与 try...with effect 语法
     6. 状态效应 Get / Set：run_state
     7. 控制反转：invert——把 iter 函数变成 Seq 序列
     8. 一次性续延纪律：Continuation_already_resumed
   本例需要链接 unix 库（用 Unix.gettimeofday 计时）。

   实测要点（OCaml 5.4.1）：
   - Domain 模块没有 cpu_count，只有 recommended_domain_count。
   - Atomic.fetch_and_add 只支持 int（int64 要用锁或其他原子原语）。
   - effect 模式的 GADT 类型标注要写 (Get : a Effect.t)；
     用记录式 Effect.Deep.match_with 时 effc 还必须补显式返回类型，
     否则细化出的类型等式"逃逸"。try...with effect 语法糖则完全免标注。
   - 续延是一次性的（linear）：同一个 k 恢复第二次会抛
     Effect.Continuation_already_resumed——多解回溯不能靠 resume 两次实现。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) Domain：OCaml 5 的并行执行单元
   ======================================================================== *)
section 1 "Domain: OCaml 5 parallel execution units";;

(* Domain.spawn 接一个 unit -> 'a 函数，立刻在另一个域上开始执行，
   返回 'a Domain.t 句柄；Domain.join 等它结束并取回结果
   （被 join 的 domain 里未捕获的异常会在 join 处重新抛出） *)
let () =
  let d = Domain.spawn (fun () -> Domain.recommended_domain_count ()) in
  Printf.printf "spawned domain joined with recommended count = %d\n" (Domain.join d);
  Printf.printf "recommended_domain_count on this machine = %d\n"
    (Domain.recommended_domain_count ());;

(* 多个 domain 同时跑，join 收集全部结果 *)
let () =
  let n = 4 in
  let ds = List.init n (fun i -> Domain.spawn (fun () -> i * i)) in
  let results = List.map Domain.join ds in
  Printf.printf "squares from %d domains: [%s]\n" n
    (String.concat "; " (List.map string_of_int results));;

(* ========================================================================
   2) Atomic：跨 domain 的原子操作
   ======================================================================== *)
section 2 "Atomic: lock-free shared counters";;

(* 普通 ref 在两个 domain 并发 incr 会丢更新（竞态）：
   读取-加一-写回不是原子的，交错时两次 +1 只剩一次 +1。
   Atomic 把读-改-写变成硬件级原子操作，结果确定。
   本教程的验证要求输出可复现，所以只演示确定正确的原子版；
   把 fetch_and_add 换成普通 ref 的三步操作就能观察到丢更新。
   注意：Atomic.fetch_and_add 只支持 int；OCaml 的 int 是 63 位，
   常见计数场景不会溢出。 *)
let atomic_count () =
  let counter = Atomic.make 0 in
  let per_domain = 100_000 in
  let ds = List.init 2 (fun _ ->
    Domain.spawn (fun () ->
      for _ = 1 to per_domain do
        ignore (Atomic.fetch_and_add counter 1)
      done)) in
  List.iter Domain.join ds;
  Atomic.get counter;;

Printf.printf "atomic count after 2 x 100000 increments = %d (expected 200000)\n"
  (atomic_count ());;

(* Atomic.get / set / exchange 也都是原子的（多态，支持任意类型） *)
let () =
  let a = Atomic.make 42 in
  Printf.printf "exchange 42 -> 7 returns old = %d, new = %d\n"
    (Atomic.exchange a 7) (Atomic.get a);;

(* ========================================================================
   3) Mutex：互斥访问更复杂的共享状态
   ======================================================================== *)
section 3 "Mutex: mutual exclusion for complex shared state";;

(* Atomic 只适合单个字的读-改-写；要保护一段复合操作（先读后写、
   多字段一致），用 Mutex 临界区 *)
let mutex_log () =
  let m = Mutex.create () in
  let log = ref [] in
  let ds = List.init 4 (fun i ->
    Domain.spawn (fun () ->
      for k = 1 to 100 do
        Mutex.lock m;
        log := Printf.sprintf "d%d#%d" i k :: !log;
        Mutex.unlock m
      done)) in
  List.iter Domain.join ds;
  !log;;

let () =
  let log = mutex_log () in
  Printf.printf "mutex log entries: %d (expected 400)\n" (List.length log);
  Printf.printf "all unique: %b\n"
    (List.length log = List.length (List.sort_uniq compare log));;

(* ========================================================================
   4) 并行数组求和：分块 + Atomic 累加
   ======================================================================== *)
section 4 "parallel array sum: chunking + Atomic accumulation";;

let seq_sum arr =
  let acc = ref 0 in
  Array.iter (fun x -> acc := !acc + x) arr;
  !acc;;

(* 把数组切成 ndomain 块，每块在独立 domain 上求和，
   各块的部分和原子地累加到一个 int Atomic 上 *)
let par_sum arr ndomains =
  let total = Atomic.make 0 in
  let n = Array.length arr in
  let chunk = (n + ndomains - 1) / ndomains in
  let ds = List.init ndomains (fun i ->
    Domain.spawn (fun () ->
      let lo = i * chunk in
      let hi = min n (lo + chunk) in
      let part = ref 0 in
      for k = lo to hi - 1 do
        part := !part + arr.(k)
      done;
      ignore (Atomic.fetch_and_add total !part))) in
  List.iter Domain.join ds;
  Atomic.get total;;

let () =
  let n = 10_000_000 in
  let arr = Array.init n (fun i -> i mod 1000) in
  let s1 = seq_sum arr in
  Printf.printf "sequential sum  = %d\n" s1;
  let nd = min 4 (Domain.recommended_domain_count ()) in
  let t0 = Unix.gettimeofday () in
  let sp = par_sum arr nd in
  let t1 = Unix.gettimeofday () in
  Printf.printf "parallel sum (%d domains) = %d, matches: %b\n" nd sp (sp = s1);
  Printf.printf "parallel time: %.3f s (includes domain spawn cost)\n" (t1 -. t0);
  Printf.printf "note: bytecode is interpreted; use ocamlopt for real speedups\n";;

(* ========================================================================
   5) Effect 基础：Xchg 效应与 try...with effect 语法
   ======================================================================== *)
section 5 "effect basics: Xchg and the try...with effect syntax";;

(* 声明效应：往内置可扩展变体 Effect.t 里加构造子。
   Xchg : int -> int t 读作"带一个 int 参数，perform 的结果是 int" *)
type _ Effect.t += Xchg : int -> int Effect.t;;

let comp1 () = Effect.perform (Xchg 0) + Effect.perform (Xchg 1);;

(* OCaml 5.3+ 给深处理器（deep handler）提供了直接的语法糖：
   try 计算 with | effect (模式), k -> continue k 恢复值
   effect 是关键字，表示匹配的是效应不是异常；k 是被挂起的计算
   （delimited continuation），continue k v 让它从 perform 处带着 v 恢复。
   深处理器会处理计算全程 perform 的所有效应。 *)
let demo_xchg () =
  let open Effect.Deep in
  try comp1 () with
  | effect (Xchg n), k -> continue k (n + 1);;

Printf.printf "comp1 under +1 handler = %d\n" (demo_xchg ());;

(* 同一个 comp1，换一个处理器就是换一种语义——这就是"效应的含义
   由处理器赋予"：这里 Xchg 表示"取相反数" *)
let demo_xchg_neg () =
  let open Effect.Deep in
  try comp1 () with
  | effect (Xchg n), k -> continue k (- n);;

Printf.printf "comp1 under neg handler = %d\n" (demo_xchg_neg ());;

(* 效应像异常一样向外层传播；没被任何处理器处理的效应
   会以 Effect.Unhandled 异常的形式在 perform 处爆出 *)
let () =
  match comp1 () with
  | n -> Printf.printf "unhandled? got %d\n" n
  | exception Effect.Unhandled _ ->
      Printf.printf "comp1 without handler raises Effect.Unhandled\n";;

(* ========================================================================
   6) 状态效应 Get / Set：run_state
   ======================================================================== *)
section 6 "state effects: Get / Set";;

type _ Effect.t +=
  | Get : int Effect.t
  | Set : int -> unit Effect.t;;

let get () = Effect.perform Get;;
let put v = Effect.perform (Set v);;

(* 处理器捕获一个 ref 做状态；perform 变成对状态的读写。
   注意深处理器自动重新安装自己，所以循环里的每次 get/put 都被接管。
   实测坑：cell 必须显式标注 int ref——无参效应 Get 的索引精化
   在无标注时会报 "int is ambiguous: escape the scope of its equation"。 *)
let run_state init (f : unit -> 'a) : int * 'a =
  let cell : int ref = ref init in
  let open Effect.Deep in
  let v = try f () with
    | effect Get, k -> continue k !cell
    | effect (Set v), k -> cell := v; continue k ()
  in
  (!cell, v);;

(* 在"纯函数语法"里写状态化算法：阶乘的累加器藏在处理器后面 *)
let factorial_stateful n =
  run_state 1 (fun () ->
    for i = 1 to n do
      put (get () * i)
    done;
    get ());;

let () =
  let final, v = factorial_stateful 10 in
  Printf.printf "factorial_stateful 10: final state = %d, result = %d\n" final v;
  let final, v = run_state 100 (fun () -> get () + get ()) in
  Printf.printf "run_state 100 (get+get): final = %d, result = %d\n" final v;
  Printf.printf "same computation, different state = %d\n"
    (fst (run_state 7 (fun () -> get () + get ())));;

(* ========================================================================
   7) 控制反转：invert——把 iter 函数变成 Seq 序列
   ======================================================================== *)
section 7 "control inversion: turning iter into Seq";;

(* 生产者（List.iter 式推模式）好写，消费者（Seq 拉模式）好用。
   invert 用效应把前者变成后者：每次 yield 挂起计算，
   把元素和"剩余计算"包成一个 Cons 节点交回消费者。
   这是 effect handler 的招牌应用（官方手册示例）。 *)
let invert (type a) ~(iter : (a -> unit) -> unit) : a Seq.t =
  let module M = struct
    type _ Effect.t += Yield : a -> unit Effect.t
  end in
  let yield v = Effect.perform (M.Yield v) in
  fun () ->
    let open Effect.Deep in
    match iter yield with
    | () -> Seq.Nil
    | effect (M.Yield v), k -> Seq.Cons (v, continue k);;

let () =
  (* 一个推模式的生产者 *)
  let lst_iter f = List.iter f [1; 2; 3] in
  let s = invert ~iter:lst_iter in
  let next = Seq.to_dispenser s in
  Printf.printf "inverted list iter yields:";
  let rec drain () =
    match next () with
    | Some v -> Printf.printf " %d" v; drain ()
    | None -> print_newline ()
  in
  drain ();
  (* 同一个 invert 适配任何 iter：字符串逐字符 *)
  let str_iter f = String.iter f "OCaml" in
  let s2 = invert ~iter:str_iter in
  let chars = List.of_seq s2 in
  Printf.printf "inverted string iter yields: [%s]\n"
    (String.concat "; " (List.map (Printf.sprintf "%C") chars));;

(* ========================================================================
   8) 一次性续延纪律：Continuation_already_resumed
   ======================================================================== *)
section 8 "the linear continuation discipline";;

(* OCaml 5 的续延是一次性的（linear）：每个捕获的 k 必须恰好被
   continue 或 discontinue 一次。恢复第二次会抛
   Effect.Continuation_already_resumed。 *)
let () =
  let open Effect.Deep in
  let outcome = ref "no exception?!" in
  try ignore (Effect.perform (Xchg 0))
  with
  | effect (Xchg n), k ->
      ignore (continue k (n + 1));   (* 第一次恢复：剩余计算跑完并返回 *)
      (try ignore (continue k (n + 1))   (* 第二次恢复同一个 k：必炸 *)
       with Effect.Continuation_already_resumed ->
         outcome := "Effect.Continuation_already_resumed");
      Printf.printf "second resume of same continuation: %s\n" !outcome;
      print_endline "implication: multi-answer backtracking cannot just resume k twice;";
      print_endline "  enumerate solutions by re-running the computation instead,";
      print_endline "  or use a search library built on these primitives.";;

(* ========================================================================
   9) 要点与注意事项
   ======================================================================== *)
section 9 "notes and caveats";;

let () =
  print_endline "domains:";
  print_endline "  - spawn returns a handle; join to wait & collect (exceptions propagate)";
  print_endline "  - shared mutable state needs Atomic (counters) or Mutex (sections)";
  print_endline "  - domain spawn has cost; chunk work coarse-grained";
  print_endline "effects:";
  print_endline "  - deep handler sugar: try ... with effect (Pat), k -> continue k v (5.3+)";
  print_endline "  - still marked experimental in the manual; APIs may change";
  print_endline "  - continuations are one-shot: continue/discontinue exactly once";
  print_endline "  - effects are synchronous; no perform from C callbacks or signal handlers";
  print_endline "  - libraries: Eio/Lwt/Async build async IO on these primitives";;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 25 jieshu ===="  (* 第二十五个文件结束 *)
