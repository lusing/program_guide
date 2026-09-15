(* ============================================================
   11 - 高阶函数与柯里化
     在 SML 里函数是「一等公民」：能当参数、当返回值、存进数据结构。
     本节讲柯里化、部分应用、闭包、以及 o 与 op。

   运行：
     poly -q --script 11-higher-order.sml
     sml 然后 use "11-higher-order.sml";
     mlton -output 11-higher-order 11-higher-order.sml && ./11-higher-order
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 柯里化：把 f(a,b) 写成 f a b ----
   类型上看得最清楚：
     add1 : int * int -> int      （收一个元组）
     add2 : int -> int -> int     （收一个，返回一个函数）
   -> 是右结合的，所以 int -> int -> int 读作 int -> (int -> int)。 *)
fun add1 (a, b) = a + b
fun add2 a b = a + b

val _ = say ("1) add1 (3,4) = " ^ Int.toString (add1 (3, 4)))
val _ = say ("   add2 3 4   = " ^ Int.toString (add2 3 4))

(* ---- 2) 部分应用：只给一部分参数，得到一个新函数 ----
   add2 3 就是「加 3」这个函数本身。这是柯里化最大的好处。 *)
val add3 = add2 3
val _ = say ("2) add3 = add2 3; add3 10 = " ^ Int.toString (add3 10))
val _ = say ("   map add3 [1,2,3]     = " ^ show (map add3 [1,2,3]))

(* ---- 3) 用柯里化写可复用的比较器 ----
   比较器先固定基准值，再拿去 filter。 *)
fun greaterThan base x = x > base
val _ = say ("3) filter (greaterThan 3) [1..6] = "
             ^ show (List.filter (greaterThan 3) [1,2,3,4,5,6]))

(* ---- 4) 多参柯里化：乘数 -> 列表 -> 结果 ----
   scaleBy 10 的意思是「把列表里每个元素乘 10」。
   注意 map (scaleBy 10) 与 map scaleBy 10 完全不同：
   前者是对的，后者会把 10 当成列表用，类型不对。 *)
fun scaleBy k xs = map (fn x => x * k) xs
val _ = say ("4) scaleBy 3 [1,2,3] = " ^ show (scaleBy 3 [1,2,3]))
val _ = say ("   scaleBy 10 same     = " ^ show (scaleBy 10 [1,2,3]))

(* ---- 5) 闭包：函数记住了它诞生时的环境 ----
   makeCounter 返回的函数抓住了自己的 n，
   每次调用都会读到更新后的 n —— 这就是闭包。 *)
fun makeCounter start =
    let
        val n = ref start
    in
        fn () => (n := !n + 1; !n)
    end

val c1 = makeCounter 0
val c2 = makeCounter 100
val _ = say ("5) c1() c1() c2() = "
             ^ Int.toString (c1 ()) ^ " " ^ Int.toString (c1 ()) ^ " " ^ Int.toString (c2 ()))
val _ = say "   (two counters, independent state)"

(* ---- 6) o 是函数复合（中缀），op o 才能当值传递 ----
   (f o g) x = f (g x)，即先 g 后 f。
   单独写 o 当参数时要用 op o，因为它是中缀运算符。 *)
fun inc x = x + 1
fun dbl x = x * 2
val _ = say ("6) (inc o dbl) 5 = " ^ Int.toString ((inc o dbl) 5) ^ "   (5*2+1)")
val _ = say ("   (dbl o inc) 5 = " ^ Int.toString ((dbl o inc) 5) ^ "   ((5+1)*2)")
val _ = say ("   foldl (op o) compose three = "
             ^ Int.toString (List.foldl (op o) (fn x => x) [inc, dbl, inc] 1))

(* ---- 7) op：把中缀运算符变成普通函数 ----
   不能直接写 foldl + 0 xs，因为 + 是中缀；
   写成 op + 就得到类型 (int*int) -> int 的普通函数。 *)
val _ = say ("7) foldl (op +)       = " ^ Int.toString (List.foldl (op +) 0 [1,2,3,4]))
val _ = say ("   foldl (op * )      = " ^ Int.toString (List.foldl (op * ) 1 [1,2,3,4]))
val _ = say ("   foldl (op ^) on strings    = " ^ List.foldl (op ^) "" ["a","b","c"])
val _ = say ("   (op -) is a plain function = " ^ Int.toString ((op -) (10, 4)))

(* ---- 8) 函数作为数据：存进列表再统一调用 ----
   注意列表元素必须同类型，所以这些函数都是 int -> int。 *)
val pipeline = [inc, dbl, add3, fn x => x * x]
val applied = map (fn f => f 5) pipeline
val _ = say ("8) map (f 5) [inc,dbl,add3,square] = " ^ show applied)
val _ = say ("   folded = "
             ^ Int.toString (List.foldl (fn (f, acc) => f acc) 5 pipeline))

(* ---- 9) 写一个自己的高阶函数：twice / compose ----
   twice f 把 f 应用两次；compose 就是柯里化版的 o。 *)
fun twice f x = f (f x)
fun compose f g x = f (g x)
val _ = say ("9) twice inc 0        = " ^ Int.toString (twice inc 0))
val _ = say ("   twice dbl 1        = " ^ Int.toString (twice dbl 1))
val _ = say ("   compose inc dbl 5  = " ^ Int.toString (compose inc dbl 5))

(* ---- 10) 用高阶函数替换显式递归 ----
   下面三种写法等价；习惯之后你会优先写第一种。 *)
val xs = [1,2,3,4,5,6]
val _ = say ("10) map/filter combo   = " ^ show (map inc (List.filter (fn x => x mod 2 = 0) xs)))
val _ = say ("    equivalent recursion = " ^ show (let
                                                  fun go [] = []
                                                    | go (x :: r) =
                                                        if x mod 2 = 0 then inc x :: go r else go r
                                                in go xs end))

val _ = say "==== 11 \231\187\147\230\157\159 ===="
