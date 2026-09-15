(* ============================================================
   14 - 不透明约束：把实现藏起来
     第 12 章用的是冒号 : ，那是「透明约束」——签名里写的 type t
     对外仍然等于实现里的那个类型。
     本节用冒号加大于号 :> ，也就是「不透明约束」：
     类型 t 对外彻底抽象，外界只能通过签名里列出的函数操作它。
     这是 SML 里做抽象数据类型（ADT）的标准手段。

   运行：
     poly -q --script 14-abstraction.sml
     sml 然后 use "14-abstraction.sml";
     mlton -output 14-abstraction 14-abstraction.sml && ./14-abstraction
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 透明与不透明并排对比 ----
   两个 structure 的实现逐字相同，只有约束方式不同：
     TransBox  : BOX   ->  t 就是 int，外界看得见
     OpaqueBox :> BOX  ->  t 是个抽象类型，外界看不见 *)
signature BOX = sig
    type t
    val wrap : int -> t
    val unwrap : t -> int
end

structure TransBox : BOX = struct
    type t = int
    fun wrap n = n
    fun unwrap n = n
end

structure OpaqueBox :> BOX = struct
    type t = int
    fun wrap n = n
    fun unwrap n = n
end

(* 透明：既然知道 t = int，就可以直接拿 int 当 t 用 *)
val nTrans : TransBox.t = 42
val _ = say ("1) transparent: t is int, so 42 : TransBox.t = " ^ Int.toString nTrans)

(* 不透明：下面这行通不过，OpaqueBox.t 与 int 是两个不同的类型
     val nOpaque : OpaqueBox.t = 42      <- Error: 类型不匹配
   唯一的造值途径是签名里导出的 wrap *)
val nOpaque = OpaqueBox.unwrap (OpaqueBox.wrap 42)
val _ = say ("   opaque: only wrap can build a value, got " ^ Int.toString nOpaque)

(* ---- 2) 不透明约束保护不变量 ----
   自然数类型：fromInt 会把负数夹成 0。
   因为 t 是抽象的、构造子不导出，外界**没法**绕过 fromInt 造出负数。 *)
signature NAT = sig
    type t
    val fromInt : int -> t
    val toInt : t -> int
    val add : t * t -> t
end

structure Nat :> NAT = struct
    type t = int
    fun fromInt n = if n < 0 then 0 else n
    fun toInt n = n
    fun add (a : t, b : t) = a + b
end

val _ = say ("2) Nat.fromInt 5    -> " ^ Int.toString (Nat.toInt (Nat.fromInt 5)))
val _ = say ("   Nat.fromInt (~9) -> " ^ Int.toString (Nat.toInt (Nat.fromInt ~9)))
val _ = say ("   Nat.add (5, 0)   -> "
             ^ Int.toString (Nat.toInt (Nat.add (Nat.fromInt 5, Nat.fromInt ~9))))

(* 如果第 2 行写成透明约束   structure Nat : NAT = ...
   外界就能写   val bad : Nat.t = ~9   ，不变量当场破产。
   所以「要保护不变量」时，:> 不是风格问题，是正确性问题。 *)

(* ---- 3) 不透明会把内部辅助函数一并藏掉 ----
   Stats 里 total / toReal 都只是内部工具，签名里没写，外面就不存在。 *)
signature STATS = sig
    val mean : int list -> real
    val count : int list -> int
end

structure Stats :> STATS = struct
    fun total [] = 0
      | total (x :: xs) = x + total xs
    fun toReal n = Real.fromInt n
    fun mean xs =
        if null xs then 0.0
        else toReal (total xs) / toReal (length xs)
    fun count xs = length xs
end

val _ = say ("3) mean [1,2,3,4] = "
             ^ Real.fmt (StringCvt.FIX (SOME 3)) (Stats.mean [1, 2, 3, 4]))
val _ = say ("   count [1,2,3,4] = " ^ Int.toString (Stats.count [1, 2, 3, 4]))
(*   外面写 Stats.total [1,2] 会报 unbound structure member *)

(* ---- 4) eqtype：把「相等性」显式保留下来 ----
   签名里写 type t 时，抽象类型默认**不是**相等类型，
   于是 = 用不了。写 eqtype t 才是「抽象，但允许 = 」。 *)
signature KEYEQ = sig
    eqtype key
    val mkKey : int -> key
end

structure IntKey :> KEYEQ = struct
    type key = int
    fun mkKey n = n
end

val _ = say ("4) eqtype keeps = usable -> "
             ^ Bool.toString (IntKey.mkKey 3 = IntKey.mkKey 3))

(* 只写 type key，不写 eqtype： *)
signature KEYBARE = sig
    type key
    val mkKey : int -> key
end

structure BareKey :> KEYBARE = struct
    type key = int
    fun mkKey n = n
end

(* 下面这行会被三个实现一致拒绝，因为 BareKey.key 不是相等类型：
     val _ = BareKey.mkKey 3 = BareKey.mkKey 3
   三种报错措辞几乎一样：
     SML/NJ  : operator and operand do not agree [equality type required]
     Poly/ML : Can't unify ''a to BareKey.key (Requires equality type)
     MLton   : expects: [<equality>] * [<equality>] but got: [BareKey.key] * ...
   补救办法：把比较函数自己导出。 *)
signature KEYNOEQ = sig
    type key
    val mkKey : int -> key
    val eqKey : key * key -> bool
end

structure PostKey :> KEYNOEQ = struct
    type key = int
    fun mkKey n = n
    fun eqKey (a, b) = a = b
end

val _ = say ("   without eqtype, export eqKey yourself -> "
             ^ Bool.toString (PostKey.eqKey (PostKey.mkKey 3, PostKey.mkKey 3)))

(* ---- 5) 不透明是单向的：结构内部照样能看自己的实现 ----
   有序表：fromList 保证结果永远升序，而 insert 这个辅助函数不导出。 *)
signature SORTED = sig
    type t
    val fromList : int list -> t
    val toList : t -> int list
end

structure Sorted :> SORTED = struct
    type t = int list
    fun insert (x, []) = [x]
      | insert (x, y :: ys) = if x <= y then x :: y :: ys else y :: insert (x, ys)
    fun fromList xs = foldl (fn (x, acc) => insert (x, acc)) [] xs
    fun toList xs = xs
end

val _ = say ("5) Sorted.fromList [3,1,4,1,5] -> "
             ^ String.concatWith "," (map Int.toString (Sorted.toList (Sorted.fromList [3, 1, 4, 1, 5]))))

(* ---- 6) 不透明 + 多态类型参数：不可变队列 ----
   type 'a queue 也是可以抽象的。内部用「前段 + 倒序后段」实现，
   外界只看到 enq / deq / size，换实现不影响调用方。 *)
signature QUEUE = sig
    type 'a queue
    val empty : 'a queue
    val enq : 'a * 'a queue -> 'a queue
    val deq : 'a queue -> ('a * 'a queue) option
    val size : 'a queue -> int
end

structure Queue :> QUEUE = struct
    type 'a queue = 'a list * 'a list
    val empty = ([], [])
    fun size (f, b) = length f + length b
    fun enq (x, (f, b)) = (f, x :: b)
    fun deq ([], []) = NONE
      | deq ([], b) =
            (case rev b of
                 [] => NONE
               | x :: f' => SOME (x, (f', [])))
      | deq (x :: f, b) = SOME (x, (f, b))
end

val q0 = Queue.enq (1, Queue.enq (2, Queue.enq (3, Queue.empty)))
val _ = say ("6) enq 1,2,3 -> size = " ^ Int.toString (Queue.size q0))

val (t1, q1) = valOf (Queue.deq q0)
val _ = say ("   deq -> top = " ^ Int.toString t1 ^ ", size = " ^ Int.toString (Queue.size q1))

val (t2, q2) = valOf (Queue.deq q1)
val _ = say ("   deq -> top = " ^ Int.toString t2 ^ ", size = " ^ Int.toString (Queue.size q2))

val isEmpty = (case Queue.deq (Queue.empty : int Queue.queue) of
                   NONE => true
                 | SOME _ => false)
val _ = say ("   deq on empty is NONE -> " ^ Bool.toString isEmpty)
(*   注意这里不能用 Queue.deq ... = NONE 来判空：
     抽象类型 queue 不是相等类型，option 的比较同样过不了类型检查。 *)

(* ---- 7) 不透明之后就「开不了箱」，要取回内容只能靠导出的函数 ----
   下面这个 Nat 把 show 一起导出，于是虽然 toInt 不在签名里，
   外界仍然能拿到字符串形式——这是闭包式的「受控出口」。 *)
signature SHOWNAT = sig
    type t
    val fromInt : int -> t
    val show : t -> string
end

structure SNat :> SHOWNAT = struct
    type t = int
    fun fromInt n = if n < 0 then 0 else n
    fun show n = "Nat(" ^ Int.toString n ^ ")"
end

val _ = say ("7) opaque Nat without toInt, but with show -> " ^ SNat.show (SNat.fromInt 7))

(* ---- 8) 不透明 + functor：最实用的组合 ----
   functor 的产出也做不透明约束，内部表结构就彻底对外不可见。 *)
signature STORE = sig
    type t
    val empty : t
    val put : string * int -> t -> t
    val get : string -> t -> int option
    val keys : t -> string list
end

functor MakeStore (X : sig val fallback : int end) :> STORE = struct
    type t = (string * int) list
    val empty = []
    fun put (k, v) s = (k, v) :: s
    fun get k s =
        (case List.find (fn (k', _) => k' = k) s of
             NONE => SOME X.fallback
           | SOME (_, v) => SOME v)
    fun keys s = map (fn (k, _) => k) s
end

structure Store = MakeStore (struct val fallback = 0 end)
val st = Store.put ("x", 1) (Store.put ("y", 2) Store.empty)

val _ = say ("8) get \"x\" -> " ^ Int.toString (valOf (Store.get "x" st)))
val _ = say ("   get \"z\" (absent) -> " ^ Int.toString (valOf (Store.get "z" st)))
val _ = say ("   keys -> " ^ String.concatWith "," (Store.keys st))
(*   st 的真实类型是 (string * int) list，但外界写不出来，也拆不开。 *)

val _ = say "==== 14 \231\187\147\230\157\159 ===="
