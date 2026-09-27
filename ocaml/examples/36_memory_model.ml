(* ==========================================================================
   36_memory_model.ml - OCaml 5 内存模型：数据竞争与 DRF-SC
   ==========================================================================
   主题：官方手册「Memory model: the hard promises」章。
        relaxed 模型下哪些顺序有保证、什么是数据竞争、
        为什么「无竞争即顺序一致」（DRF-SC）。
   内容：
     1. happens-before 的四个来源（程序序 / 原子连贯 / spawn / join /
        mutex 解锁）
     2. 非原子竞争实测：丢失更新（每次运行结果都不同）
     3. Atomic 修复：结果精确
     4. spawn/join 建立的 happens-before：非原子写也能安全传递
     5. Mutex 同样建立 happens-before
     6. atomic record fields（5.4+，[@atomic] 与 [%atomic.loc]）

   实测（OCaml 5.4.1，byte + native 都真并行）：
     - 两个 domain 各 300_000 次 r := !r + 1：最终计数几乎必然
       小于 600_000（读-改-写交错丢失更新）。
     - 换 Atomic.fetch_and_add：精确 600_000。
     - spawn 前的非原子写 + join 后读：安全（join 建立 happens-before，
       不构成数据竞争）。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

let n_incr = 300_000;;

(* ========================================================================
   1) happens-before 速览
   ======================================================================== *)
section 1 "the happens-before relation";;

print_endline "happens-before sources (manual, memorymodel chapter):";
print_endline "  1. program order within a domain";
print_endline "  2. atomic coherence on the same location";
print_endline "  3. Domain.spawn: spawn precedes first action of child";
print_endline "  4. Domain.join: last action of d precedes join";
print_endline "  5. mutex unlock precedes subsequent ops on the mutex";;

(* 数据竞争 = 两个冲突动作（同位置非原子、至少一个写、非初始化写）
   之间没有 happens-before 关系。
   DRF-SC：没有数据竞争的程序只会表现出顺序一致的行为。 *)

(* ========================================================================
   2) 非原子竞争：丢失更新
   ======================================================================== *)
section 2 "non-atomic race: lost updates";;

let counter = ref 0;;
let d1 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do counter := !counter + 1 done);;
let d2 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do counter := !counter + 1 done);;
Domain.join d1;
Domain.join d2;;
Printf.printf "expected %d, got %d -> %d lost updates\n"
  (2 * n_incr) !counter (2 * n_incr - !counter);;
print_endline "(races are non-deterministic: this number varies per run)";;

(* 注意：结果不固定，但「几乎必然丢」——两个读-改-写交错时
   后写覆盖先写。这是数据竞争的典型症状：不是崩溃，而是
   「静悄悄地算错」 *)

(* ========================================================================
   3) Atomic 修复
   ======================================================================== *)
section 3 "atomic fix: exact result";;

let acounter = Atomic.make 0;;
let d1 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do ignore (Atomic.fetch_and_add acounter 1) done);;
let d2 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do ignore (Atomic.fetch_and_add acounter 1) done);;
Domain.join d1;
Domain.join d2;;
Printf.printf "atomic: expected %d, got %d\n" (2 * n_incr) (Atomic.get acounter);;

(* fetch_and_add / compare_and_set / exchange / incr / deccr 对同一
   原子位置的访问保持原子连贯 -> 每个 happens-before 都成立 -> 无竞争 *)

(* ========================================================================
   4) spawn / join 建立的 happens-before
   ======================================================================== *)
section 4 "message passing via spawn/join";;

(* 非原子写 + 非原子读，但读写之间有 join 相连 -> 有 happens-before
   -> 不构成数据竞争 -> 顺序一致，读到的一定是写过的值 *)
let mailbox = ref 0 and payload = ref 0;;
payload := 42;;
let d = Domain.spawn (fun () ->
  (* spawn 先于子域首动作：这里读到的 payload 一定是 42 *)
  mailbox := !payload * 2);;
Domain.join d;;
Printf.printf "via join: mailbox = %d (non-atomic but race-free)\n" !mailbox;;

(* 对照：如果读发生在 join 之前、且另一域同时在写 —— 那才是竞争 *)

(* ========================================================================
   5) Mutex 建立顺序
   ======================================================================== *)
section 5 "mutex also orders";;

(* Mutex 在 OCaml 5 属于标准库（4.x 时代在 threads 库）。
   解锁 happens-before 后续加锁 -> 临界区之间全序 -> 非原子
   计数也精确 *)
let m = Mutex.create ();;
let mc = ref 0;;
let d1 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do
    Mutex.lock m;
    mc := !mc + 1;
    Mutex.unlock m
  done);;
let d2 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do
    Mutex.lock m;
    mc := !mc + 1;
    Mutex.unlock m
  done);;
Domain.join d1;
Domain.join d2;;
Printf.printf "mutex-guarded: expected %d, got %d\n" (2 * n_incr) !mc;;

(* ========================================================================
   6) atomic record fields（OCaml 5.4+）
   ======================================================================== *)
section 6 "atomic record fields [@atomic] (5.4+)";;

type service = {
  name : string;
  mutable hits : int [@atomic];        (* 该字段的读写都是原子的 *)
};;

let svc = { name = "svc"; hits = 0 };;
let d1 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do
    ignore (Atomic.Loc.fetch_and_add [%atomic.loc svc.hits] 1)
  done);;
let d2 = Domain.spawn (fun () ->
  for _ = 1 to n_incr do
    ignore (Atomic.Loc.fetch_and_add [%atomic.loc svc.hits] 1)
  done);;
Domain.join d1;
Domain.join d2;;
Printf.printf "atomic field: expected %d, got %d\n" (2 * n_incr) svc.hits;;

(* [%atomic.loc f] 把 [@atomic] 字段变成 Atomic.Loc.t 视图，
   支持 fetch_and_add 等全套原子操作——免掉单独建 Atomic.t 的盒子 *)

(* ========================================================================
   7) 结论
   ======================================================================== *)
section 7 "takeaway";;

print_endline "DRF-SC: no data race => only sequentially-consistent behavior.";
print_endline "Build happens-before with: atomics, spawn/join, mutex.";
print_endline "Plain refs across domains without those = silent corruption.";;

print_endline "==== 36 jieshu ====";;
