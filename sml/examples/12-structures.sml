(* ============================================================
   12 - 结构、签名与封装
     SML 的模块系统由三样东西组成：
       structure  —— 一组绑定的打包
       signature  —— 一份「接口契约」
       ascription —— 把 structure 按某个 signature 约束（即 : 或 :> ）
     本节讲透明约束、open、local 与 where type；
     最后用 functor 收尾（它是「接收 structure 的函数」唯一写法）。

   运行：
     poly -q --script 12-structures.sml
     sml 然后 use "12-structures.sml";
     mlton -output 12-structures 12-structures.sml && ./12-structures
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) structure：把相关的值打包在一起 ----
   和 C++ 的 namespace、Java 的 class（静态成员那面）类似，
   但 SML 的 structure 完全是编译期的组织手段，没有运行时开销。 *)
structure Math3 = struct
    val pi = 3.14159265358979
    fun square x = x * x
    fun cube x = x * x * x
end

val _ = say ("1) Math3.square 7 = " ^ Int.toString (Math3.square 7))
val _ = say ("   Math3.cube 3   = " ^ Int.toString (Math3.cube 3))
val _ = say ("   Math3.pi       = " ^ Real.fmt (StringCvt.FIX (SOME 5)) Math3.pi)

(* ---- 2) signature：描述「必须有这些成员」 ----
   签名只写类型，不写实现。 *)
signature COUNTER = sig
    type t
    val zero : t
    val bump : t -> t
    val value : t -> int
end

(* ---- 3) 用 : 做「透明约束」----
   透明（transparent）的意思是：类型 t 的具体定义对外仍然可见，
   外界知道 t 就是 int。对比第 14 章的不透明约束 :>。 *)
structure Counter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 1
    fun value n = n
end

val _ = say ("3) Counter.value (Counter.bump Counter.zero) = "
             ^ Int.toString (Counter.value (Counter.bump Counter.zero)))
val _ = say "   (transparent ascription keeps t = int visible)"

(* ---- 4) 透明约束会暴露「签名里没写」的类型细节 ----
   因为 t = int 是公开的，所以可以直接拿 int 当 t 用。 *)
val asInt : Counter.t = 42
val _ = say ("4) since Counter.t = int, 42 can stand for it: "
             ^ Int.toString (Counter.value asInt))

(* ---- 5) open：把 structure 的成员直接引进当前作用域 ----
   方便，但会污染命名空间，一般只在很小的作用域里用。 *)
structure Point = struct
    val origin = (0, 0)
    fun mk (x, y) = (x, y)
    fun dist2 ((x1, y1), (x2, y2)) = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
end

val _ = say ("5) Point.dist2 ((0,0),(3,4)) = "
             ^ Int.toString (Point.dist2 (Point.origin, Point.mk (3, 4))))
val _ =
    let
        open Point
    in
        say ("   after open, dist2 is callable directly = " ^ Int.toString (dist2 (origin, mk (6, 8))))
    end

(* ---- 6) 嵌套 structure：structure 里还能有 structure ----
   外面用 A.B.c 这样的路径访问。 *)
structure Geometry = struct
    structure Pt = struct
        fun mid ((x1, y1), (x2, y2)) = ((x1 + x2) div 2, (y1 + y2) div 2)
    end
    structure Seg = struct
        fun len2 ((x1, y1), (x2, y2)) = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
    end
end

val _ = say ("6) Geometry.Pt.mid ((0,0),(4,6)) = ("
             ^ Int.toString (#1 (Geometry.Pt.mid ((0, 0), (4, 6)))) ^ ","
             ^ Int.toString (#2 (Geometry.Pt.mid ((0, 0), (4, 6)))) ^ ")")
val _ = say ("   Geometry.Seg.len2 ((0,0),(3,4)) = "
             ^ Int.toString (Geometry.Seg.len2 ((0, 0), (3, 4))))

(* ---- 7) local：让辅助函数只在本 structure 内部可见 ----
   local 里声明的 helper 不会被导出，外面写 Math4.helper 会报错。 *)
structure Math4 = struct
    local
        fun helper x = x * 100
    in
        fun boosted x = helper x + 1
    end
end

val _ = say ("7) Math4.boosted 3 = " ^ Int.toString (Math4.boosted 3))
val _ = say "   (Math4.helper stays invisible outside the structure)"

(* ---- 8) 签名的「宽窄」：约束时可以收窄，不能加宽 ----
   REALISH 只声明了 pi 和 square，cube 就被藏起来了。
   想用 Math3.cube 只能通过 Math3，不能通过 Narrow。 *)
signature REALISH = sig
    val pi : real
    val square : int -> int
end

structure Narrow : REALISH = Math3
val _ = say ("8) Narrow.square 5 = " ^ Int.toString (Narrow.square 5))
val _ = say ("   Narrow.pi       = " ^ Real.fmt (StringCvt.FIX (SOME 5)) Narrow.pi)
val _ = say "   (Narrow.cube does not exist: not in the signature)"

(* ---- 9) where type：把签名里的抽象类型定死 ----
   这是比 : 更精确的约束方式：明确要求 t 必须等于 int。 *)
signature INT_COUNTER = COUNTER where type t = int
structure Counter2 : INT_COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 1
    fun value n = n
end
val _ = say ("9) Counter2.value (Counter2.bump 10) = "
             ^ Int.toString (Counter2.value (Counter2.bump 10)))

(* ---- 10) 同一个签名可以有多个实现 ----
   这是签名最大的价值：先把接口定下来，实现可以换。 *)
structure FastCounter : COUNTER = struct
    type t = int
    val zero = 0
    fun bump n = n + 2
    fun value n = n div 2
end

(* 「接收一个 structure 的函数」在 SML 里不是普通函数，而是 functor。
   注意：不能写 fun runThree (C : COUNTER) —— 那会被当成类型标注，
   而 COUNTER 是签名不是类型，三个实现都会报 unbound type constructor。
   唯一的写法就是 functor。第 13 章展开讲。 *)
functor RunThree (C : COUNTER) = struct
    val result = C.value (C.bump (C.bump (C.bump C.zero)))
end

structure R1 = RunThree (Counter)
structure R2 = RunThree (FastCounter)

val _ = say ("10) RunThree(Counter).result     = " ^ Int.toString R1.result)
val _ = say ("    RunThree(FastCounter).result = " ^ Int.toString R2.result)
val _ = say "    (one signature, two implementations, RunThree unchanged)"

val _ = say "==== 12 \231\187\147\230\157\159 ===="
