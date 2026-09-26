(* ============================================================
   25 - 持久与易失数据结构：队列、共享与摊还
     Harper《Programming in Standard ML》第 28 章的现场版。
       1) 单列表队列：一边 O(n)，m 个操作 O(m^2)——反例；
       2) 双列表批式队列：front + rear，摊还 O(1)；
       3) 持久性：操作之后旧版本照常可用（结构共享）；
       4) 摊还分析用「数 cons 个数」量化：总功 / 操作数；
       5) 易失队列（ref 就地更新）：快、但旧版本没了，
          别名看得见彼此的修改。
     所有的计数都是纯整数运算，三通道逐字节一致。

   运行：
     poly -q --script 25-queues.sml
     sml 然后 use "25-queues.sml";
     mlton -output 25-queues 25-queues.sml && ./25-queues
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

exception QEmpty

(* ---- 计数器：每分配一个列表格子记 1 个功 ---- *)
val work = ref 0
fun tick () = work := !work + 1

(* ---- 1) 反例：单列表队列 ----
   snoc 用 @ 接尾巴，要把整个旧列表抄一遍：第 m 次入队抄 m-1 格。 *)
fun badSnoc (q : int list, x) =
    let
        fun app ([], ys) = ys
          | app (z :: zs, ys) = (tick (); z :: app (zs, ys))
    in
        app (q, [x])
    end

fun badHead [] = raise QEmpty
  | badHead (x :: _) = x

fun badTail [] = raise QEmpty
  | badTail (_ :: xs) = xs

val _ = work := 0
fun pushBad (q, []) = q
  | pushBad (q, x :: xs) = pushBad (badSnoc (q, x), xs)
val badq = pushBad ([], [1, 2, 3, 4, 5])
val _ = say ("1) bad queue after 5 snocs = " ^ show badq
             ^ ", cells copied = " ^ Int.toString (!work)
             ^ " (0+1+2+3+4 = 10)")

(* ---- 2) 双列表批式队列 ----
   不变式：front 为空时 rear 必须先整个反过来。
   norm 只在这里做翻转，翻转的代价被摊到之前的每次入队上。 *)
datatype 'a queue = Q of 'a list * 'a list

fun norm (Q (f, r)) =
    if null f then Q (revCount r, []) else Q (f, r)
and revCount xs =
    let
        fun go ([], acc) = acc
          | go (x :: rest, acc) = (tick (); go (rest, x :: acc))
    in
        go (xs, [])
    end

val empty : 'a queue = Q ([], [])   (* 无参绑定用 val：fun 后面必须跟参数 *)
fun snoc (Q (f, r), x) = norm (Q (f, x :: r))
fun nullq (Q (f, r)) = null f andalso null r

fun qhead (Q (x :: _, _)) = x
  | qhead (Q ([], _)) = raise QEmpty      (* 空队列 *)

fun qtail (Q (x :: f, r)) = norm (Q (f, r))
  | qtail _ = raise QEmpty

fun qToList (Q (f, r)) = f @ List.rev r

fun qFromList xs = foldl (fn (x, q) => snoc (q, x)) empty xs

(* ---- 3) 持久性：旧版本在操作之后照样能用 ---- *)
val qa = qFromList [1, 2, 3, 4]
val qb = qtail qa                 (* 出队一次 *)
val qc = snoc (qb, 99)            (* 再入队一个 *)

val _ = say ("2) qa = " ^ show (qToList qa))
val _ = say ("   qb = qtail qa = " ^ show (qToList qb))
val _ = say ("   qc = snoc qb 99 = " ^ show (qToList qc))
val _ = say ("   qa untouched: head qa = "
             ^ Int.toString (qhead qa) ^ "  (1 still there)")

(* 出到空，接住 QEmpty *)
fun drain q acc =
    if nullq q then List.rev acc
    else drain (qtail q) (qhead q :: acc)
    handle QEmpty => List.rev acc
val _ = say ("   drain qc = " ^ show (drain qc []))

(* 想拿到异常本身再打 exnName：handle 的体必须与被包表达式同类型，
   所以用 option ref 中转——直接写 handle e => e 是类型错。 *)
val caught : exn option ref = ref NONE
val _ = ((qhead (empty : int queue); ()) handle e => (caught := SOME e))
val _ = say ("   exn (QEmpty) = "
             ^ (case !caught of
                    SOME e => exnName e
                  | NONE => "none"))

(* ---- 4) 摊还：200 入队 + 100 出队，数格子 ---- *)
val _ = work := 0
fun churn 0 q = q
  | churn k q =
        let
            val q1 = snoc (q, k)
            val q2 = if k mod 2 = 0 then qtail q1 else q1
        in
            churn (k - 1) q2
        end
val churned = churn 200 empty
val ops = 300
val _ = say ("3) 200 snocs + ~100 qtails: cells allocated = "
             ^ Int.toString (!work))
val _ = say ("   amortized work per op = "
             ^ Real.fmt (StringCvt.FIX (SOME 2))
                     (real (!work) / real ops))
val _ = say ("   survivors = " ^ show (qToList churned))

(* 对比：同样的事单列表队列要抄多少格子 *)
val _ = work := 0
fun churnBad (0, q) = q
  | churnBad (k, q) =
        let
            val q1 = badSnoc (q, k)
            val q2 = if k mod 2 = 0 then badTail q1 else q1
        in
            churnBad (k - 1, q2)
        end
val _ = churnBad (200, [])
val _ = say ("   bad queue same workload: cells copied = "
             ^ Int.toString (!work))

(* ---- 5) 易失队列：两个 ref，就地更新 ---- *)
type 'a equeue = {front : 'a list ref, rear : 'a list ref}

fun emk () : 'a equeue = {front = ref [], rear = ref []}
fun elenq ({front, rear} : 'a equeue, x) =
    rear := x :: !rear
fun enorm ({front, rear} : 'a equeue) =
    if null (!front) then (front := List.rev (!rear); rear := []) else ()
fun ehead (eq as {front, ...} : 'a equeue) =
    (enorm eq;
     case !front of
         x :: _ => x
       | [] => raise QEmpty)
fun etail (eq as {front, rear} : 'a equeue) =
    (enorm eq;
     case !front of
         _ :: f => front := f
       | [] => raise QEmpty)

val eq1 = emk () : int equeue
val _ = elenq (eq1, 10)
val _ = elenq (eq1, 20)
val _ = elenq (eq1, 30)

(* 别名：eq2 和 eq1 是同一个队列（同一个记录） *)
val eq2 = eq1
val _ = say ("4) ehead eq1 = " ^ Int.toString (ehead eq1))
val _ = etail eq2                                   (* 通过别名出队 *)
val _ = say ("   after etail via eq2, ehead eq1 = "
             ^ Int.toString (ehead eq1) ^ "  (10 gone, alias sees it)")

(* 持久版对照：同样「先看头、再从另一个名字出队」 *)
val pq = qFromList [10, 20, 30]
val pq2 = pq
val _ = say ("   persistent: head pq = " ^ Int.toString (qhead pq2))
val pq3 = qtail pq2
val _ = say ("   after qtail, head pq = " ^ Int.toString (qhead pq)
             ^ "  (10 still there)")

(* ---- 6) 结构共享的可移植证明：元素放 ref，改一处两边都看得见 ---- *)
val marker = ref 10
val sq1 = snoc (snoc (empty : int ref queue, marker), ref 20)
val sq2 = snoc (sq1, ref 30)
val _ = marker := 99
val _ = say ("5) mutate shared element, head sq1 = "
             ^ Int.toString (!(qhead sq1)))
val _ = say ("   mutate shared element, head sq2 = "
             ^ Int.toString (!(qhead sq2))
             ^ "  (both versions share the cell)")

val _ = say "==== 25 \231\187\147\230\157\159 ===="
