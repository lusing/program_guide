(* ============================================================
   24 - 记忆化与递归挂起
     Harper《Programming in Standard ML》第 31 章的三个要点，
     全部用计数器量出来：
       1) 朴素 fib 是指数级；
       2) 把 fib 包一层 memoize 没用——递归调用不走表
          （这是本章头号大坑）；
       3) 正解是「开递归」：函数把「怎么递归」参数化，
          memoRec 负责查表回填，递归全走表，线性；
       4) 递归挂起：循环流（fibs 自己加自己的尾巴）没有
          共享会指数级重算，挂起缓存一格就治好。
     MLton 默认 int 是 32 位：fib 最大取到 46 不溢出，本章取 40。

   运行：
     poly -q --script 24-memo.sml
     sml 然后 use "24-memo.sml";
     mlton -output 24-memo 24-memo.sml && ./24-memo
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 朴素 fib：数一数调用了多少次 ---- *)
val calls1 = ref 0
fun fibNaive (n : int) =
    (calls1 := !calls1 + 1;
     if n < 2 then n else fibNaive (n - 1) + fibNaive (n - 2))

val _ = calls1 := 0
val f25 = fibNaive 25
val _ = say ("1) naive fib 25 = " ^ Int.toString f25
             ^ ", calls = " ^ Int.toString (!calls1))

(* ---- 2) 数组当表：命令式记忆化，一遍填表 ---- *)
val fills = ref 0
fun fibArray (n : int) =
    let
        val tbl = Array.array (n + 1, ~1)
        fun go k =
            if Array.sub (tbl, k) >= 0 then Array.sub (tbl, k)
            else
                let
                    val v = if k < 2 then k else go (k - 1) + go (k - 2)
                    val _ = fills := !fills + 1
                    val _ = Array.update (tbl, k, v)
                in
                    v
                end
    in
        go n
    end

val _ = fills := 0
val f40 = fibArray 40
val _ = say ("2) array memo fib 40 = " ^ Int.toString f40
             ^ ", table fills = " ^ Int.toString (!fills))

(* ---- 3) 大坑：memoize 包不住递归 ----
   memoize 返回的包装函数自己会查表，但 fibNaive 内部的
   递归调用仍然直连原函数，一步也不走表——调用数纹丝不动。 *)
fun memoize (f : int -> int) : int -> int =
    let
        val tbl = ref ([] : (int * int) list)
    in
        fn k =>
           case List.find (fn (k', _) => k' = k) (!tbl) of
               SOME (_, v) => v
             | NONE =>
                   let
                       val v = f k
                       val _ = tbl := (k, v) :: !tbl
                   in
                       v
                   end
    end

val _ = calls1 := 0
val fibWrapped = memoize fibNaive
val w25 = fibWrapped 25
val _ = say ("3) memoize(fibNaive) 25 = " ^ Int.toString w25
             ^ ", calls = " ^ Int.toString (!calls1) ^ "  <-- still exponential!")

(* ---- 4) 正解：开递归 + memoRec ----
   fibBody 把「递归点」做成参数 rec，自己不再自呼；
   memoRec 提供 rec = 查表版的自己，miss 时算完回填。 *)
val bodyRuns = ref 0

fun fibBody (recf : int -> int) (n : int) =
    (bodyRuns := !bodyRuns + 1;
     if n < 2 then n else recf (n - 1) + recf (n - 2))

fun memoRec (body : (int -> int) -> int -> int) : int -> int =
    let
        val tbl = ref ([] : (int * int) list)
        fun self k =
            case List.find (fn (k', _) => k' = k) (!tbl) of
                SOME (_, v) => v
              | NONE =>
                    let
                        val v = body self k
                        val _ = tbl := (k, v) :: !tbl
                    in
                        v
                    end
    in
        self
    end

val _ = bodyRuns := 0
val fibFast = memoRec fibBody
val r25 = fibFast 25
val r40 = fibFast 40
val _ = say ("4) memoRec fib 25 = " ^ Int.toString r25
             ^ ", fib 40 = " ^ Int.toString r40
             ^ ", body runs = " ^ Int.toString (!bodyRuns))

(* ---- 5) 惰性流版的 fib：表就是流自己 ----
   第 25 章（惰性）已经见过 fib 流；这里配上计数器，
   看它同样是「每个元素只算一次」。 *)
datatype 'a status = Delayed of unit -> 'a | Value of 'a
type 'a susp = 'a status ref
fun delay (f : unit -> 'a) : 'a susp = ref (Delayed f)
fun force (s : 'a susp) : 'a =
    case !s of
        Value v => v
      | Delayed f => let val v = f () in s := Value v; v end

datatype 'a stream = Nil | Cons of 'a * 'a stream susp

fun fibStream () : int stream =
    let
        fun go (a, b) = Cons (a, delay (fn () => go (b, a + b)))
    in
        go (0, 1)
    end

fun stake (n : int, s : 'a stream) =
    if n <= 0 then []
    else case s of
             Nil => []
           | Cons (x, rest) =>
                 x :: (if n - 1 <= 0 then [] else stake (n - 1, force rest))

val _ = say ("5) fib stream take 15 = " ^ show (stake (15, fibStream ())))

(* ---- 6) 递归挂起：循环流不打结就是指数级 ----
   Harper 31.4 的 recursive suspensions。
   fibs = 0 :: 1 :: (fibs + tail fibs)。写法上「打结」只能用
   fun（SML 没有 val rec 除 fn 外的递归值）；每次调用 fibsGen ()
   都会重新生成一条新流，于是 sadds 里两次调用各自引出独立的
   计算——重算量随取的元素数指数增长。
   解法：根上放一个记忆化挂起，force 一次之后所有引用共享同一条流。 *)
fun sadds (Cons (a, ra), Cons (b, rb)) =
        Cons (a + b, delay (fn () => sadds (force ra, force rb)))
  | sadds _ = Nil

fun stail (Cons (_, r)) = force r
  | stail Nil = Nil

val regen = ref 0
fun fibsGen () : int stream =
    (regen := !regen + 1;
     Cons (0, delay (fn () =>
       Cons (1, delay (fn () =>
         sadds (fibsGen (), stail (fibsGen ())))))))

fun stakeAny (n : int, s : 'a stream) =
    if n <= 0 then []
    else case s of
             Nil => []
           | Cons (x, rest) =>
                 x :: (if n - 1 <= 0 then [] else stakeAny (n - 1, force rest))

val _ = regen := 0
val _ = stakeAny (20, fibsGen ())
val _ = say ("6) knot NOT shared, take 20: regenerations = "
             ^ Int.toString (!regen))

(* 打结版。「让 val 递归」在 SML 里没有直接写法（val rec 只收 fn），
   想让流的根挂起指向「引用它自己的生成器」，标准做法是先占位再回填：
   rootCell 先放一个会炸的占位挂起，定义完 fibsKnotted 之后再把
   Delayed fibsKnotted 写回去——这一步就是「打结」。 *)
val regen2 = ref 0
val rootCell : int stream susp = delay (fn () => raise Fail "unfilled")
fun fibsKnotted () : int stream =
    (regen2 := !regen2 + 1;
     Cons (0, delay (fn () =>
       Cons (1, delay (fn () =>
         sadds (force rootCell, stail (force rootCell)))))))
val _ = rootCell := Delayed fibsKnotted    (* 回填：现在根指向真正的生成器 *)

val _ = regen2 := 0
val first20 = stakeAny (20, fibsKnotted ())
val _ = say ("   knot shared,    take 20: regenerations = "
             ^ Int.toString (!regen2))
val _ = say ("   fibsKnotted take 20 = " ^ show first20)

val _ = say "==== 24 \231\187\147\230\157\159 ===="
