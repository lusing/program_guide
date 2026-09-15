(* ============================================================
   01 - 程序结构、值与输出
     SML 没有「主程序」：一个源文件就是一串顶层声明。
     本节演示 val 绑定、print 输出、注释、类型推断与类型标注、
     整数/实数/字符串字面量、以及求值顺序。

   运行（两个实现都行）：
     poly -q --script 01-basics.sml
     sml 然后输入  use "01-basics.sml";

   关于中文：本教程的字符串字面量里只写 ASCII，中文全部放注释。
     原因是 Poly/ML 的词法分析器会拒绝字符串里的原始高位字节
     （error: unprintable character \231），而 SML/NJ 却接受 ——
     这是两个实现最直观的一处差异，详见 README 的差异清单。
   ============================================================ *)

(* 小工具：每次输出一行。后面每个示例都会重新定义一次，
   这样每个 .sml 文件都能独立运行，不依赖外部文件。 *)
fun say s = print (s ^ "\n")

(* ---- 1) val 绑定：一次绑定，之后不可变 ----
   SML 没有赋值语句（除了 ref，见第 16 章）。
   写 x = 43 不是赋值，而是「用新值遮蔽旧名字」。 *)
val x = 42
val pi = 3.14159
val name = "Standard ML"
val flag = true

(* ---- 2) 类型推断：不用写类型，编译器自己算出来 ----
   x 是 int，pi 是 real，name 是 string，flag 是 bool。
   重载的字面量（如 42、3.14159）靠上下文定类型。 *)
val _ = say ("1) x      = " ^ Int.toString x)
val _ = say ("   name   = " ^ name)
val _ = say ("   flag   = " ^ Bool.toString flag)

(* ---- 3) 类型标注：用 : 显式声明，写错会编译报错 ----
   把下面的 7 改成 7.0 试试，SML/NJ 与 Poly/ML 都会拒绝。 *)
val y : int = 7 * 6
val _ = say ("2) y      = " ^ Int.toString y)

(* ---- 4) 实数必须用 Real.fmt 打出确定的小数位 ----
   注意不要用 Real.toString：两个实现对整数值实数的输出不同
   （Poly/ML 印 1.0，SML/NJ 印 1）。用 FIX 描述符就一致。 *)
val _ = say ("3) pi     = " ^ Real.fmt (StringCvt.FIX (SOME 5)) pi)
val _ = say ("   pi*2   = " ^ Real.fmt (StringCvt.FIX (SOME 5)) (pi * 2.0))
val _ = say ("   1.0/3  = " ^ Real.fmt (StringCvt.FIX (SOME 6)) (1.0 / 3.0))

(* ---- 5) 注释可以嵌套，这是 SML 的特色 ----
   下面这整块都被注释掉了；其中的 (* 里层注释 *) 是配对的里层注释：
   (*
      val hidden = 1
      (* 里层注释：C/Java 不支持这样写 *)
      val alsoHidden = 2
   *)
   正因为能嵌套，才可以放心地把「本身就带注释的一段代码」整体注释掉。 *)
val _ = say "4) nested comments: ok"

(* ---- 6) say 本身就是 val 绑定：函数也是值 ----
   say 的类型是 string -> string -> unit 吗？不是。
   它的类型是 fn : string -> unit，是一个「值」。 *)
val _ = say "5) functions are values"

(* ---- 7) 求值顺序：顶层声明按书写顺序依次求值 ----
   这也是为什么结束标记放在最后一行就能证明"跑到头了"。 *)
val _ = say "6) top-level declarations evaluate in order"

(* 结束标记：\231\187\147\230\157\159 是「结束」二字的 UTF-8 字节十进制写法。
   Poly/ML 不接受字符串里的原始中文，所以这里必须写转义。 *)
val _ = say "==== 01 \231\187\147\230\157\159 ===="
