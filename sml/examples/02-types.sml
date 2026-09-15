(* ============================================================
   02 - 类型与字面量
     SML 是强类型、编译期全推断的语言：几乎不用写类型，
     但类型错了在「编译期」就过不去。本节把基本类型过一遍。

   运行：
     poly -q --script 02-types.sml
     sml 然后 use "02-types.sml";
     mlton -output 02-types 02-types.sml && ./02-types
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 六种基本类型各来一个 ----
   注意：这里都没写类型标注，类型是推断出来的。 *)
val i = 42                 (* int    机器字长整数，64 位平台上就是 63 位有符号 *)
val r = 3.5                (* real   双精度浮点 *)
val b = true               (* bool   只有 true / false *)
val c = #"A"               (* char   单个字符 *)
val s = "Standard ML"      (* string 字符串 *)
val u = ()                 (* unit   只有一个值，用作"没有返回值" *)
val w = 0wxFF              (* word   无符号整数 *)

val _ = say ("1) int    i = " ^ Int.toString i)
val _ = say ("   real   r = " ^ Real.fmt (StringCvt.FIX (SOME 2)) r)
val _ = say ("   bool   b = " ^ Bool.toString b)
val _ = say ("   char   c = " ^ Char.toString c)
val _ = say ("   string s = " ^ s)
val _ = say ("   unit   u = ()")
val _ = say ("   word   w = " ^ Word.toString w)

(* ---- 2) 类型标注：用括号或冒号，写错就编译报错 ----
   把下面的 int 改成 real，两个实现都会拒绝这一行。 *)
val n1 : int = 7
val n2 = 7 : int
val n3 = (7 : int)
val _ = say ("2) three ways to annotate = " ^ Int.toString (n1 + n2 + n3))

(* ---- 3) 重载字面量：同一个 42，可以当 int 也可以当 real 系列 ----
   1.0、2.0 这种带小数点的默认是 real；
   但 Int.toString 逼着编译器把它当 int。 *)
val _ = say ("3) 42 as int     = " ^ Int.toString 42)
val _ = say ("   42 as real    = " ^ Real.fmt (StringCvt.FIX (SOME 1)) 42.0)

(* ---- 4) 等式类型：不是所有类型都能用 = 比较 ----
   int / string / bool / char / 列表 都能比；
   但 real 和函数不能，写了会编译报错。 *)
val _ = say ("4) 1 = 1          : " ^ Bool.toString (1 = 1))
val _ = say ("   \"a\" = \"b\"      : " ^ Bool.toString ("a" = "b"))
val _ = say ("   [1,2] = [1,2]  : " ^ Bool.toString ([1,2] = [1,2]))

(* ---- 5) type 只是别名，不产生新类型 ----
   这和 datatype 完全不同：下面 point 和 int*int 是同一个类型。 *)
type point = int * int
val p : point = (3, 4)
val q : int * int = p                 (* 直接赋值，不需要转换 *)
val _ = say ("5) type alias: p = (" ^ Int.toString (#1 q) ^ "," ^ Int.toString (#2 q) ^ ")")

(* ---- 6) 整数字长是实现相关的，别假设 int 一定是 64 位 ----
   实测：SML/NJ 与 Poly/ML 的 int 是 63 位有效，
         而 MLton 默认的 int 只有 32 位（要 64 位得显式用 Int64）。
   所以这一节三个实现输出不同，属于「已知差异」。
   Int.maxInt 的类型是 int option，这是 Basis 的规定，必须 valOf。 *)
val _ = say ("6) int size (implementation dependent)")
val _ = say ("   Int.precision = " ^ Int.toString (valOf Int.precision) ^ " bits")
val _ = say ("   Int.maxInt    = " ^ Int.toString (valOf Int.maxInt))

(* 结束标记：\231\187\147\230\157\159 是「结束」二字的 UTF-8 字节十进制写法，
   Poly/ML 不接受字符串里的原始中文，所以必须写转义。 *)
val _ = say "==== 02 \231\187\147\230\157\159 ===="
