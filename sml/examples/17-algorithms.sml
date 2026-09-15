(* ============================================================
   17 - 排序与经典算法
     这一节全是「能跑、能对、能比」的算法，重点不是算法本身，
     而是看 SML 怎么写它们：模式匹配分情况、累积器消递归、
     Array 做原地标记、ref 数步数。
     所有结果都是确定性的，三条通道输出必须逐字节一致。

   运行：
     poly -q --script 17-algorithms.sml
     sml 然后 use "17-algorithms.sml";
     mlton -output 17-algorithms 17-algorithms.sml && ./17-algorithms
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 插入排序：模式匹配写「插到哪」 ---- *)
fun insert (x, []) = [x]
  | insert (x, y :: ys) = if x <= y then x :: y :: ys else y :: insert (x, ys)

fun isort [] = []
  | isort (x :: xs) = insert (x, isort xs)

val _ = say ("1) insert (5, [1,3,7]) = " ^ show (insert (5, [1, 3, 7])))
val _ = say ("   isort [4,2,9,1]     = " ^ show (isort [4, 2, 9, 1]))

(* ---- 2) 归并排序：分治，先对半劈开再合并 ----
   split 用「一次取两个」的写法，避免先算 length 再切。 *)
fun split [] = ([], [])
  | split [x] = ([x], [])
  | split (x :: y :: rest) =
        let
            val (a, b) = split rest
        in
            (x :: a, y :: b)
        end

fun merge ([], ys) = ys
  | merge (xs, []) = xs
  | merge (x :: xs, y :: ys) =
        if x <= y then x :: merge (xs, y :: ys)
        else y :: merge (x :: xs, ys)

fun msort [] = []
  | msort [x] = [x]
  | msort xs =
        let
            val (a, b) = split xs
        in
            merge (msort a, msort b)
        end

val (sp1, sp2) = split [1, 2, 3, 4, 5]
val _ = say ("2) split [1,2,3,4,5] = (" ^ show sp1 ^ ", " ^ show sp2 ^ ")")
val _ = say ("   merge ([1,3,5],[2,4]) = " ^ show (merge ([1, 3, 5], [2, 4])))

(* ---- 3) 快速排序：用 List.partition 分区，短到一眼能看完 ---- *)
fun qsort [] = []
  | qsort (pivot :: rest) =
        let
            val (lo, hi) = List.partition (fn x => x < pivot) rest
        in
            qsort lo @ [pivot] @ qsort hi
        end

val _ = say ("3) qsort [3,1,4,1,5,9,2,6] = " ^ show (qsort [3, 1, 4, 1, 5, 9, 2, 6]))

(* ---- 4) 三个排序互相校验：对同一份数据必须给出同一个结果 ---- *)
val data = [37, 12, 91, 5, 44, 12, 78, 3, 60, 25]
val a1 = isort data
val a2 = msort data
val a3 = qsort data

val _ = say ("4) input = " ^ show data)
val _ = say ("   isort = " ^ show a1)
val _ = say ("   msort = " ^ show a2)
val _ = say ("   qsort = " ^ show a3)
val _ = say ("   all agree = " ^ Bool.toString (a1 = a2 andalso a2 = a3))

(* ---- 5) 二分查找 vs 线性查找：用步数把差距量出来 ----
   数组是 0,2,4,...,198 共 100 个元素，找 192（下标 96）。 *)
val tbl = Array.tabulate (100, fn k => k * 2)
val target = 192

fun bsearch (arr : int array, goal : int) =
    let
        fun go (lo, hi, steps) =
            if lo > hi then NONE
            else
                let
                    val mid = (lo + hi) div 2
                    val v = Array.sub (arr, mid)
                in
                    if v = goal then SOME (mid, steps)
                    else if v < goal then go (mid + 1, hi, steps + 1)
                    else go (lo, mid - 1, steps + 1)
                end
    in
        go (0, Array.length arr - 1, 1)
    end

fun lsearch (arr : int array, goal : int) =
    let
        fun go (k, steps) =
            if k >= Array.length arr then NONE
            else if Array.sub (arr, k) = goal then SOME (k, steps)
            else go (k + 1, steps + 1)
    in
        go (0, 1)
    end

fun describe result =
    case result of
        NONE => "not found"
      | SOME (idx, steps) => "index " ^ Int.toString idx ^ " in " ^ Int.toString steps ^ " steps"

val _ = say ("5) binary search 192 -> " ^ describe (bsearch (tbl, target)))
val _ = say ("   linear search 192 -> " ^ describe (lsearch (tbl, target)))
val _ = say ("   binary search 3 (absent) -> " ^ describe (bsearch (tbl, 3)))

(* ---- 6) 埃拉托斯特尼筛法：Array 做标记表 ----
   把 p 的倍数全部划掉，从 p*p 开始即可（更小的倍数已被更小的质数划掉）。 *)
fun sieve n =
    let
        val mark = Array.array (n + 1, true)
        val _ = if n >= 0 then Array.update (mark, 0, false) else ()
        val _ = if n >= 1 then Array.update (mark, 1, false) else ()

        fun strike p =
            let
                fun go k = if k > n then () else (Array.update (mark, k, false); go (k + p))
            in
                go (p * p)
            end

        fun loop p =
            if p * p > n then ()
            else (if Array.sub (mark, p) then strike p else (); loop (p + 1))

        val _ = loop 2

        fun collect k acc =
            if k > n then rev acc
            else collect (k + 1) (if Array.sub (mark, k) then k :: acc else acc)
    in
        collect 2 []
    end

val _ = say ("6) primes <= 30 = " ^ show (sieve 30))
val _ = say ("   number of primes <= 100 = " ^ Int.toString (length (sieve 100)))

(* ---- 7) 欧几里得算法：gcd 尾递归，lcm 由 gcd 推出 ----
   注意先除后乘，避免 a * b 在 32 位 int 上先溢出。 *)
fun gcd (a, b) = if b = 0 then a else gcd (b, a mod b)
fun lcm (a, b) = a div gcd (a, b) * b

val _ = say ("7) gcd (48, 18)     = " ^ Int.toString (gcd (48, 18)))
val _ = say ("   gcd (1071, 462)  = " ^ Int.toString (gcd (1071, 462)))
val _ = say ("   lcm (4, 6)       = " ^ Int.toString (lcm (4, 6)))

(* ---- 8) 汉诺塔：小规模打印每步，大规模只数步数 ----
   别对 n=20 打印每步——那是 1048575 行。 *)
fun hanoiMoves (0, _, _, _) = []
  | hanoiMoves (n, a, b, c) =
        hanoiMoves (n - 1, a, c, b) @ [(a, c)] @ hanoiMoves (n - 1, b, a, c)

fun hanoiCount (0, _, _, _) = 0
  | hanoiCount (n, a, b, c) =
        hanoiCount (n - 1, a, c, b) + 1 + hanoiCount (n - 1, b, a, c)

val moves3 = hanoiMoves (3, "A", "B", "C")
val _ = say ("8) hanoi 3 -> " ^ Int.toString (length moves3) ^ " moves (2^3 - 1 = 7)")
val _ = say ("   " ^ String.concatWith " " (map (fn (from, to) => from ^ ">" ^ to) moves3))
val _ = say ("   hanoi 10 -> " ^ Int.toString (hanoiCount (10, "A", "B", "C")) ^ " moves")
val _ = say ("   hanoi 20 -> " ^ Int.toString (hanoiCount (20, "A", "B", "C")) ^ " moves")

(* ---- 9) 记忆化斐波那契：用 Array 存已算过的值 ----
   朴素递归算 fib 40 要几十亿次调用，记忆化只要 40 次。 *)
fun fibMemo n =
    let
        val memo = Array.array (n + 1, ~1)      (* ~1 表示「还没算」 *)

        fun go k =
            if k <= 1 then k
            else
                let
                    val cached = Array.sub (memo, k)
                in
                    if cached >= 0 then cached
                    else
                        let
                            val r = go (k - 1) + go (k - 2)
                        in
                            (Array.update (memo, k, r); r)
                        end
                end
    in
        go n
    end

val _ = say ("9) fib 10 (memoized) = " ^ Int.toString (fibMemo 10))
val _ = say ("   fib 40 (memoized) = " ^ Int.toString (fibMemo 40))

(* ---- 10) 有序表的去重与交集：写法和 merge 同构 ---- *)
fun dedup [] = []
  | dedup [x] = [x]
  | dedup (x :: y :: rest) =
        if x = y then dedup (y :: rest) else x :: dedup (y :: rest)

fun inter ([], _) = []
  | inter (_, []) = []
  | inter (x :: xs, y :: ys) =
        if x = y then x :: inter (xs, ys)
        else if x < y then inter (xs, y :: ys)
        else inter (x :: xs, ys)

val _ = say ("10) dedup [1,1,2,3,3,3,4] = " ^ show (dedup [1, 1, 2, 3, 3, 3, 4]))
val _ = say ("    inter [1,3,5,7] [3,4,5,6] = " ^ show (inter ([1, 3, 5, 7], [3, 4, 5, 6])))

(* ---- 11) 一趟折返算出 min / max / sum ----
   foldl 把「累积」这件事写成了模式，不需要显式的递归。 *)
val nums = [37, 12, 91, 5, 44, 12, 78, 3, 60, 25]
val smallest = foldl Int.min (hd nums) nums
val largest = foldl Int.max (hd nums) nums
val total = foldl (op +) 0 nums

val _ = say ("11) min = " ^ Int.toString smallest
             ^ ", max = " ^ Int.toString largest
             ^ ", sum = " ^ Int.toString total
             ^ ", count = " ^ Int.toString (length nums))

val _ = say "==== 17 \231\187\147\230\157\159 ===="
