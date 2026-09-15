(* ============================================================
   03 - 表达式与运算符
     优先级、结合性、整数除法的两种口味（div/mod 与 quot/rem）、
     浮点比较、布尔短路、if 是「表达式」而不是语句。

   注意：本文件的字符串字面量全部是 ASCII。中文只出现在注释里 ——
     Poly/ML 报 error: unprintable character \231 found in string，
     MLton   报 Extended text constants disallowed，
     只有 SML/NJ 接受字符串里的原始 UTF-8。这是三者最直观的差异。

   运行：
     poly -q --script 03-expressions.sml
     sml 然后 use "03-expressions.sml";
     mlton -output 03-expressions 03-expressions.sml && ./03-expressions
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 负号写作 ~，不是 - ----
   ~ 既是一元负号，也是二元减号。写成 -7 会被当成
   「缺一个操作数」而报错。 *)
val _ = say ("1) ~7      = " ^ Int.toString (~7))
val _ = say ("   10 - 3  = " ^ Int.toString (10 - 3))
val _ = say ("   ~(2+3)  = " ^ Int.toString (~(2 + 3)))

(* ---- 2) 优先级：算术 > 比较 > 布尔 ----
   SML 没有隐式类型转换，所以 1 + 2.0 是编译错误。 *)
val _ = say ("2) 1 + 2 * 3 < 10     = " ^ Bool.toString (1 + 2 * 3 < 10))
val _ = say ("   (1 + 2) * 3 < 10   = " ^ Bool.toString ((1 + 2) * 3 < 10))

(* ---- 3) 整数除法有两套，负号下的结果不同 ----
   div / mod 是关键字（中缀），向负无穷取整（数论口味）；
   quot / rem 不是关键字，得写成 Int.quot、Int.rem，向零取整（C 口味）。 *)
val _ = say ("3) ~7 div 2  = " ^ Int.toString (~7 div 2) ^ "   (floor style)")
val _ = say ("   ~7 mod 2  = " ^ Int.toString (~7 mod 2))
val _ = say ("   ~7 quot 2 = " ^ Int.toString (Int.quot (~7, 2)) ^ "   (truncate style)")
val _ = say ("   ~7 rem 2  = " ^ Int.toString (Int.rem (~7, 2)))

(* ---- 4) 整除的恒等式：两套都满足 a = (a div b)*b + a mod b ----
   div/mod 让余数永远非负，quot/rem 让余数跟着被除数符号走。 *)
val a = ~7
val b = 2
val _ = say ("4) div/mod  identity = " ^ Int.toString ((a div b) * b + (a mod b)))
val _ = say ("   quot/rem identity = " ^ Int.toString (Int.quot (a, b) * b + Int.rem (a, b)))

(* ---- 5) 浮点不能用 = 比较，要用 Real.== ----
   原因：= 需要「等式类型」，real 不是等式类型。
   更要紧的是：0.1+0.2 在二进制浮点里根本不等于 0.3，
   只是打印成 6 位小数时看着一样。
   注意别用 17 位精度去看真相：SML/NJ 会印成 0.30000000000000000，
   Poly/ML 与 MLton 印成 0.29999999999999999 —— 这是已知差异。
   用 SCI 看差值更清楚，而且三个实现一致。 *)
val r1 = 0.1 + 0.2
val r2 = 0.3
val _ = say "5) comparing reals: '=' would not compile here"
val _ = say ("   Real.== (r1, r2) = " ^ Bool.toString (Real.== (r1, r2)))
val _ = say ("   r1 at 6 digits   = " ^ Real.fmt (StringCvt.FIX (SOME 6)) r1)
val _ = say ("   r2 at 6 digits   = " ^ Real.fmt (StringCvt.FIX (SOME 6)) r2)
val _ = say ("   |r1 - r2|        = " ^ Real.fmt (StringCvt.SCI (SOME 3)) (Real.abs (r1 - r2)))

(* ---- 6) 布尔运算短路求值 ----
   andalso / orelse 是短路运算符；andb / orb 不是（会两边都算）。
   它们是「关键字」，不是普通函数，所以写法是 andalso 而不是 &&。 *)
val _ = say ("6) true  andalso false = " ^ Bool.toString (true andalso false))
val _ = say ("   true  orelse  false = " ^ Bool.toString (true orelse false))
val _ = say ("   not true            = " ^ Bool.toString (not true))

(* ---- 7) if 是表达式，两个分支必须有相同的类型 ----
   SML 没有三元运算符，因为 if 本身就能嵌在表达式里。 *)
val abs3 = if 3 < 0 then ~3 else 3
val _ = say ("7) if 3 < 0 then ~3 else 3 = " ^ Int.toString abs3)
val _ = say ("   if as an expression     = " ^ Int.toString (5 + (if true then 10 else 20)))

(* ---- 8) 比较运算符返回 order，可用于排序 ----
   Int.compare 返回 LESS / EQUAL / GREATER。
   顺带一个坑：参数不能叫 o —— o 是内缀的复合运算符（见第 11 章），
   直接拿它当变量名会报 "infix operator o used without op"。 *)
fun orderName ord = case ord of LESS => "LESS" | EQUAL => "EQUAL" | GREATER => "GREATER"
val _ = say ("8) Int.compare(2,5)    = " ^ orderName (Int.compare (2, 5)))
val _ = say ("   Real.compare(2.0,2.0) = " ^ orderName (Real.compare (2.0, 2.0)))

val _ = say "==== 03 \231\187\147\230\157\159 ===="
