(* ============================================================
   26 - option、异常与续延：n 皇后的三种解法
     Harper《Programming in Standard ML》第 29 章的完整复刻。
     同一个回溯搜索，三种「结果如何传出去」的机制：
       1) option：失败返回 NONE，一层层往上渗透；
       2) 异常：解就是转义，从最深处一步弹出；
       3) 续延（CPS）：成功/失败都是传进来的函数，
          「接着搜下一个」是显式的 fc 调用——
          于是既能枚举全部解，也能中途弃赛。
     已知答案当断言用：n=4..8 的解数是 2,10,4,40,92。

   运行：
     poly -q --script 26-queens.sml
     sml 然后 use "26-queens.sml";
     mlton -output 26-queens 26-queens.sml && ./26-queens
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* 棋盘表示：sol 是「第 c 列的皇后放在第几行」的列表。
   放子的顺序是列 0..n-1，所以 qs 的头是最近放的一列。 *)
fun upto (lo, hi) = if lo > hi then [] else lo :: upto (lo + 1, hi)

(* r 行放新皇后与已放的 qs（按列距离 1,2,... 检查）冲突吗 *)
fun conflicts (r : int, qs : int list) =
    let
        fun go ([], _) = false
          | go (q :: rest, d) = r = q orelse Int.abs (r - q) = d
                              orelse go (rest, d + 1)
    in
        go (qs, 1)
    end

val _ = say ("1) conflicts (4, [4,6])  = "
             ^ Bool.toString (conflicts (4, [4, 6])) ^ "  (same row)")
val _ = say ("   conflicts (5, [4,6])  = "
             ^ Bool.toString (conflicts (5, [4, 6])) ^ "  (diagonal)")
val _ = say ("   conflicts (0, [4,6])  = "
             ^ Bool.toString (conflicts (0, [4, 6])) ^ "  (safe)")

(* ---- 2) option 版：失败就是 NONE，向上渗透 ---- *)
fun firstSol ([], _) = NONE
  | firstSol (x :: xs, f) =
        case f x of
            SOME r => SOME r
          | NONE => firstSol (xs, f)

fun solveOpt (n : int, qs : int list) =
    if length qs = n then SOME (rev qs)
    else firstSol (upto (0, n - 1),
                   fn r => if conflicts (r, qs)
                           then NONE
                           else solveOpt (n, r :: qs))

val optSol = solveOpt (8, [])
val _ = say ("2) option  solution = "
             ^ (case optSol of
                    SOME s => show s
                  | NONE => "NONE"))

(* ---- 3) 异常版：解作为转义，一步弹出 ---- *)
exception Solved of int list

fun solveEx (n : int, qs : int list) =
    if length qs = n then raise Solved (rev qs)
    else
        app (fn r =>
                if conflicts (r, qs)
                then ()
                else ignore (solveEx (n, r :: qs)))
            (upto (0, n - 1))

val exSol = (solveEx (8, []); NONE) handle Solved s => SOME s
val _ = say ("3) exception solution = "
             ^ (case exSol of
                    SOME s => show s
                  | NONE => "NONE"))
val _ = say ("   agree with option = "
             ^ Bool.toString (optSol = exSol))

(* ---- 4) CPS 版：成功续延 sc、失败续延 fc ----
   到达目标：先把解交给 sc；sc 正常返回后调 fc 继续搜，
   于是「全部解」也能枚举。想中途弃赛，让 sc 抛异常即可。 *)
fun solveCPS (n : int, qs : int list,
              sc : int list -> unit, fc : unit -> unit) =
    if length qs = n then
        (sc (rev qs); fc ())
    else
        let
            fun try [] = fc ()
              | try (r :: rs) =
                    if conflicts (r, qs) then try rs
                    else solveCPS (n, r :: qs, sc, fn () => try rs)
        in
            try (upto (0, n - 1))
        end

(* 4a) 枚举全部解 *)
fun countSolutions n =
    let
        val count = ref 0
        val sc = fn (_ : int list) => count := !count + 1
        val fc = fn () => ()
    in
        solveCPS (n, [], sc, fc);
        !count
    end

val known = [(4, 2), (5, 10), (6, 4), (7, 40), (8, 92)]
val _ = say "4) CPS enumerate all solutions:"
val _ = app (fn (n, expect) =>
                let
                    val got = countSolutions n
                in
                    say ("   n=" ^ Int.toString n
                         ^ " count=" ^ Int.toString got
                         ^ (if got = expect then " ok" else " MISMATCH"))
                end)
            known

(* 4b) 一发续延：异常就是「只能用一次的 call/cc」 *)
exception Stop of int list
val cpsSol = (solveCPS (8, [], fn s => raise Stop s, fn () => ());
              NONE)
             handle Stop s => SOME s
val _ = say ("   CPS first solution = "
             ^ (case cpsSol of
                    SOME s => show s
                  | NONE => "NONE"))
val _ = say ("   agree with option = " ^ Bool.toString (optSol = cpsSol))

(* ---- 5) 把第一组解画成棋盘 ---- *)
fun drawBoard (sol : int list) =
    let
        val n = length sol
        fun cell (row, col) =
            if List.nth (sol, col) = row then #"Q" else #"."
        fun rowLine row =
            String.implode (map (fn col => cell (row, col)) (upto (0, n - 1)))
    in
        app (fn row => say ("   " ^ rowLine row)) (upto (0, n - 1))
    end

val _ = say "5) board of the first 8-queens solution:"
val _ = case optSol of
            SOME s => drawBoard s
          | NONE => say "   NONE"

val _ = say "==== 26 \231\187\147\230\157\159 ===="
