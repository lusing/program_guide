(* ============================================================
   13 - functor：参数化的模块
     functor 是「从 structure 到 structure 的函数」，但它在编译期求值。
     参数必须恰好一个（多参数要靠 spec 形式或元组打包），
     参数用 signature 约束，产出还能再用 signature 约束。

   运行：
     poly -q --script 13-functors.sml
     sml 然后 use "13-functors.sml";
     mlton -output 13-functors 13-functors.sml && ./13-functors
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 最小 functor：匿名签名做参数 ----
   匿名签名直接写在参数位置上，适合「只用一次」的场合。 *)
functor Sqr (X : sig val n : int end) = struct
    val result = X.n * X.n
end

structure Sq7 = Sqr (struct val n = 7 end)
structure Sq9 = Sqr (struct val n = 9 end)

val _ = say ("1) Sqr(n=7).result = " ^ Int.toString Sq7.result)
val _ = say ("   Sqr(n=9).result = " ^ Int.toString Sq9.result)

(* ---- 2) 具名签名：一份 functor 服务多套实现 ----
   这是 functor 最核心的价值。下面 NUM 用抽象类型 num，
   Poly3 全程只通过 NUM 的运算操作 num，于是 int 和 real 都能用。 *)
signature NUM = sig
    type num
    val zero : num
    val one : num
    val add : num * num -> num
    val mul : num * num -> num
    val toString : num -> string
end

structure IntNum : NUM = struct
    type num = int
    val zero = 0
    val one = 1
    fun add (a, b) = a + b
    fun mul (a, b) = a * b
    fun toString n = Int.toString n
end

structure RealNum : NUM = struct
    type num = real
    val zero = 0.0
    val one = 1.0
    (* 注意 a + b 必须显式标注类型！
       参数类型没有被 type num = real 约束到，因为 SML 的重载运算符
       是「逐条绑定」独立解析的，不回头看签名想要什么。
       Poly/ML 会用签名里的期望类型反推（唯一一个能过的），
       SML/NJ 与 MLton 则一律默认成 int，然后在签名匹配时报
       val add: int * int -> int 对不上 real * real -> real。
       所以「重载运算符 + 抽象类型 + 签名约束」这个组合下，务必写死类型。 *)
    fun add (a : real, b : real) = a + b
    fun mul (a : real, b : real) = a * b
    fun toString r = Real.fmt (StringCvt.FIX (SOME 2)) r
end

functor Poly3 (N : NUM) = struct
    (* (1 + 1) * (1 + 1) + 1 = 5，全程不知道 num 到底是 int 还是 real *)
    val demo = N.add (N.mul (N.add (N.one, N.one), N.add (N.one, N.one)), N.one)
    val report = N.toString demo
end

structure PInt = Poly3 (IntNum)
structure PReal = Poly3 (RealNum)

val _ = say ("2) Poly3(IntNum).report  = " ^ PInt.report)
val _ = say ("   Poly3(RealNum).report = " ^ PReal.report)

(* ---- 3) 给产出再加约束：functor ... : SIGNATURE = struct ... end ----
   固定容量的栈：满了就丢弃新元素。 *)
signature STACK = sig
    type t
    val empty : t
    val push : int * t -> t
    val pop : t -> (int * t) option
    val depth : t -> int
end

functor MakeStack (X : sig val capacity : int end) : STACK = struct
    type t = int list
    val empty = []
    fun depth s = List.length s
    fun push (x, s) = if depth s >= X.capacity then s else x :: s
    fun pop [] = NONE
      | pop (x :: rest) = SOME (x, rest)
end

structure Cap3 = MakeStack (struct val capacity = 3 end)

val s3 = Cap3.push (1, Cap3.push (2, Cap3.push (3, Cap3.push (4, Cap3.empty))))
val _ = say ("3) capacity=3, push 1..4 -> depth = " ^ Int.toString (Cap3.depth s3))
val _ =
    case Cap3.pop s3 of
        NONE => say "   pop -> NONE"
      | SOME (top, _) => say ("   pop -> top = " ^ Int.toString top
                              ^ ", depth left = " ^ Int.toString (Cap3.depth s3 - 1))

(* ---- 4) 参数签名里写 where type ----
   比 : 更精确：直接要求参数必须用 int 实现那个抽象类型。 *)
functor Times10 (X : sig
                         type t
                         val mk : int -> t
                         val out : t -> int
                     end where type t = int) = struct
    val r = X.out (X.mk 7)
end

structure T10 = Times10 (struct
                             type t = int
                             fun mk n = n * 10
                             fun out n = n
                         end)

val _ = say ("4) Times10(mk 7).r = " ^ Int.toString T10.r)

(* ---- 5) 一次传多个 structure：spec 形式的参数 ----
   参数位置不写 strid : sigexp，而是直接写一段 spec，
   里面可以同时声明好几个 structure。 *)
signature SA = sig val a : int end
signature SB = sig val b : int end

functor AddPair (structure A : SA  structure B : SB) = struct
    val sum = A.a + B.b
end

structure Pair12 = AddPair (struct
                                structure A = struct val a = 1 end
                                structure B = struct val b = 2 end
                            end)

val _ = say ("5) AddPair(1, 2).sum = " ^ Int.toString Pair12.sum)

(* ---- 6) sharing type：强制两个参数的抽象类型相同 ----
   下面 RoundTrip 里要写 X.G.peek (X.M.mk n)，也就是把 M 产出的 M.t
   喂给 G。M.t 和 G.t 若被当成两个各自独立的抽象类型，这里就通不过；
   sharing type M.t = G.t 把它们强制「钉」成同一个类型。
   （本例两个结构实际都用 string，所以即使去掉 sharing 也能过；
     一旦两者都是真正的抽象类型，sharing 就是必需的。） *)
signature MAKER = sig type t  val mk : int -> t end
signature GETTER = sig type t  val peek : t -> int end

functor RoundTrip (X : sig
                           structure M : MAKER
                           structure G : GETTER
                           sharing type M.t = G.t
                       end) = struct
    fun run n = X.G.peek (X.M.mk n)
end

structure StrMaker = struct
    type t = string
    fun mk n = Int.toString n
end

structure StrGetter = struct
    type t = string
    fun peek s = String.size s
end

structure RT = RoundTrip (struct structure M = StrMaker  structure G = StrGetter end)

val _ = say ("6) sharing: run 12345 -> size of \"12345\" = " ^ Int.toString (RT.run 12345))

(* ---- 7) 不透明结果签名 :> —— 把内部实现彻底藏起来 ----
   用 :> 之后，签名里没写的成员（比如下面的 secret）外界根本看不到。
   这是 SML 里「抽象数据类型」的标准做法。 *)
signature COUNTER_API = sig
    val next : unit -> int
    val reset : unit -> unit
end

functor MakeCounter (X : sig val start : int end) :> COUNTER_API = struct
    val cell = ref X.start
    val secret = 999
    fun next () = (cell := !cell + 1; !cell)
    fun reset () = cell := X.start
end

structure Maker = MakeCounter (struct val start = 10 end)

val _ = say ("7) start=10")
val _ = say ("   next() = " ^ Int.toString (Maker.next ()))
val _ = say ("   next() = " ^ Int.toString (Maker.next ()))
val _ = (Maker.reset (); say "   reset()")
val _ = say ("   next() = " ^ Int.toString (Maker.next ()))

(* ---- 8) 可移植性：柯里化 functor 只有 SML/NJ 认 ----
   SML/NJ 接受   functor F (A : SA) (B : SB) = ...
   并把它理解成「返回 functor 的 functor」；
   Poly/ML 与 MLton 都在这一行直接报语法错。
   要跨实现，多参数一律用第 5 节的 spec 形式，或者把参数打包成一个结构。 *)

val _ = say "8) curried functor is SML/NJ-only; use the spec form instead"

val _ = say "==== 13 \231\187\147\230\157\159 ===="
