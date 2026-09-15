(* ============================================================
   18 - 数值计算
     二分法 / 牛顿法求根、梯形与辛普森积分、克拉默法则解方程组、
     拉格朗日插值，外加浮点误差与「实数格式化」的三实现差异。
     所有结果打印到小数点后 6 位——这个精度三套实现是一致的，
     更高精度会分叉，见第 10 节。

   运行：
     poly -q --script 18-numeric.sml
     sml 然后 use "18-numeric.sml";
     mlton -output 18-numeric 18-numeric.sml && ./18-numeric
   ============================================================ *)

fun say s = print (s ^ "\n")

(* 统一用 FIX 6 打印实数：n 在 1..16 之间时三套实现逐字节一致 *)
fun fx (r : real) = Real.fmt (StringCvt.FIX (SOME 6)) r

(* ---- 1) 整数除法与实数除法是两回事 ----
   / 永远返回 real，div/mod 只吃 int。 *)
val _ = say ("1) 7 div 2 = " ^ Int.toString (7 div 2)
             ^ ", 7 mod 2 = " ^ Int.toString (7 mod 2))
val _ = say ("   7.0 / 2.0 = " ^ fx (7.0 / 2.0))
val _ = say ("   Math.sqrt 2 = " ^ fx (Math.sqrt 2.0))
val _ = say ("   Math.pow (2.0, 10.0) = " ^ fx (Math.pow (2.0, 10.0)))
val _ = say ("   Math.pi = " ^ fx Math.pi)

(* ---- 2) 取整与绝对值 ----
   注意 Real.floor / ceil / round / trunc 都返回 int，不是 real。
   round 的「平局」行为各家不同，这里刻意避开 x.5。 *)
val _ = say ("2) abs ~3.7 = " ^ fx (abs ~3.7))
val _ = say ("   floor 2.7 = " ^ Int.toString (Real.floor 2.7)
             ^ ", ceil 2.1 = " ^ Int.toString (Real.ceil 2.1))
val _ = say ("   round 2.4 = " ^ Int.toString (Real.round 2.4)
             ^ ", round 2.6 = " ^ Int.toString (Real.round 2.6)
             ^ ", trunc ~2.7 = " ^ Int.toString (Real.trunc ~2.7))

(* ---- 3) 二分法：f (x) = x^3 - 2x - 5 在 [2,3] 上的根 ----
   一直对半折，60 次之后区间宽度只有 2^-60，双精度已经到极限。 *)
fun f (x : real) = x * x * x - 2.0 * x - 5.0

fun bisect (lo, hi, steps) =
    if steps = 0 then (lo + hi) / 2.0
    else
        let
            val mid = (lo + hi) / 2.0
        in
            if f mid > 0.0 then bisect (lo, mid, steps - 1)
            else bisect (mid, hi, steps - 1)
        end

val rootB = bisect (2.0, 3.0, 60)
val _ = say ("3) bisection root on [2,3] = " ^ fx rootB)
val _ = say ("   |f (root)| = " ^ fx (abs (f rootB)))

(* ---- 4) 牛顿法：同一个方程，6 次迭代就到位 ----
   牛顿法是平方收敛的：每步有效位数翻倍，代价是要能写出导数。 *)
fun f' (x : real) = 3.0 * x * x - 2.0

fun newton (x, steps) =
    if steps = 0 then x
    else newton (x - f x / f' x, steps - 1)

val rootN = newton (2.0, 6)
val _ = say ("4) newton from x0 = 2, 6 iterations = " ^ fx rootN)
val _ = say ("   |newton - bisection| = " ^ fx (abs (rootN - rootB)))

(* ---- 5) 梯形法积分：∫ x^2 dx 从 0 到 1，精确值是 1/3 ----
   梯形法对二阶函数有 O(h^2) 误差，100 段还差一点点。 *)
fun trapezoid (a, b, n) =
    let
        val h = (b - a) / Real.fromInt n
        fun term k =
            let
                val x = a + h * Real.fromInt k
            in
                if k = 0 orelse k = n then x * x / 2.0 else x * x
            end
        fun loop (k, acc) = if k > n then acc else loop (k + 1, acc + term k)
    in
        h * loop (0, 0.0)
    end

val trap = trapezoid (0.0, 1.0, 100)
val _ = say ("5) trapezoid, 100 panels = " ^ fx trap)
val _ = say ("   exact 1/3               = " ^ fx (1.0 / 3.0))
val _ = say ("   error                   = " ^ fx (abs (trap - 1.0 / 3.0)))

(* ---- 6) 辛普森法：对二次函数是精确的 ----
   同样 100 段，误差直接归零（在双精度范围内）。 *)
fun simpson (a, b, n) =
    let
        val h = (b - a) / Real.fromInt n
        fun term k =
            let
                val x = a + h * Real.fromInt k
            in
                if k = 0 orelse k = n then x * x
                else if k mod 2 = 0 then 2.0 * x * x
                else 4.0 * x * x
            end
        fun loop (k, acc) = if k > n then acc else loop (k + 1, acc + term k)
    in
        h / 3.0 * loop (0, 0.0)
    end

val simp = simpson (0.0, 1.0, 100)
val _ = say ("6) simpson, 100 panels = " ^ fx simp)
val _ = say ("   error                = " ^ fx (abs (simp - 1.0 / 3.0)))

(* ---- 7) 克拉默法则解 3x3 方程组 ----
   用行列式求解，比高斯消元短得多，适合系数少、数值条件好的情形。 *)
type mat3 = (real * real * real) * (real * real * real) * (real * real * real)

fun det3 (m : mat3) =
    let
        val ((a, b, c), (d, e, f), (g, h, i)) = m
    in
        a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
    end

fun solve3 (m : mat3, rhs : real * real * real) =
    let
        val (r1, r2, r3) = rhs
        val ((a, b, c), (d, e, f), (g, h, i)) = m
        val det = det3 m
        val dx = det3 ((r1, b, c), (r2, e, f), (r3, h, i))
        val dy = det3 ((a, r1, c), (d, r2, f), (g, r3, i))
        val dz = det3 ((a, b, r1), (d, e, r2), (g, h, r3))
    in
        (dx / det, dy / det, dz / det)
    end

(* 2x +  y -  z = 8
   -3x - y + 2z = -11
   -2x + y + 2z = -3        解是 x=2, y=3, z=-1 *)
val coeff : mat3 = ((2.0, 1.0, ~1.0), (~3.0, ~1.0, 2.0), (~2.0, 1.0, 2.0))
val (sx, sy, sz) = solve3 (coeff, (8.0, ~11.0, ~3.0))
val _ = say ("7) det = " ^ fx (det3 coeff))
val _ = say ("   x = " ^ fx sx ^ ", y = " ^ fx sy ^ ", z = " ^ fx sz)

(* ---- 8) 拉格朗日插值：过 (1,1) (2,4) (3,9)，求 x = 2.5 ----
   三点恰好定出 y = x^2，所以插值结果应当是 6.25。 *)
fun lagrange (pts : (real * real) list, x : real) =
    let
        fun basis (xi, _) =
            let
                fun loop ([], acc) = acc
                  | loop ((xj, _) :: rest, acc) =
                        if Real.== (xj, xi) then loop (rest, acc)
                        else loop (rest, acc * (x - xj) / (xi - xj))
            in
                loop (pts, 1.0)
            end

        fun total ([], acc) = acc
          | total ((xi, yi) :: rest, acc) = total (rest, acc + yi * basis (xi, yi))
    in
        total (pts, 0.0)
    end

val curve = [(1.0, 1.0), (2.0, 4.0), (3.0, 9.0)]
val _ = say ("8) lagrange at x = 2.5 = " ^ fx (lagrange (curve, 2.5)))

(* ---- 9) 浮点不是实数：三个必知的坑 ----
   a) 0.1 和 0.2 都无法用二进制精确表示，加起来不是 0.3
   b) real 不是相等类型，只能用 Real.== / Real.compare
   c) 大数吃小数：1e16 + 1 还是 1e16 *)
val _ = say ("9) 0.1 + 0.2 = " ^ fx (0.1 + 0.2))
val _ = say ("   Real.== (0.1 + 0.2, 0.3) = " ^ Bool.toString (Real.== (0.1 + 0.2, 0.3)))

fun sumTenths (k, acc) = if k = 0 then acc else sumTenths (k - 1, acc + 0.1)
val tenths = sumTenths (100, 0.0)
val _ = say ("   0.1 added 100 times -> " ^ fx tenths
             ^ ", equals 10.0? " ^ Bool.toString (Real.== (tenths, 10.0)))
val _ = say ("   1.0E16 + 1.0 - 1.0E16 = " ^ fx (1.0E16 + 1.0 - 1.0E16))
val _ = say ("   (1/3) * 3 = " ^ fx ((1.0 / 3.0) * 3.0))

(* ---- 10) 实数格式化：三套实现真实分叉的地方 ----
   下面 4 行在三通道下**输出确实不同**，已登记在 run-all.sh 的
   已知差异表里（这是本教程唯一"故意制造差异"的一节，用来证明
   差异检测本身是有效的）：
     Real.toString 1.0            Poly/ML 给 1.0，另两家给 1
     GEN (SOME 6) 1.0             同上：整值实数是否保留 .0
     FIX (SOME 0) 3.5             Poly/ML 与 MLton 给 4（四舍六入五成双），
                                  SML/NJ 给 3
     FIX (SOME 17) 0.3            SML/NJ 末尾几位与另两家不同
   结论：跨实现要打印实数，用 FIX/GEN 且位数 ≤ 16，别用 Real.toString。 *)
val _ = say ("10) Real.toString 1.0            = " ^ Real.toString 1.0)
val _ = say ("    Real.fmt (GEN (SOME 6)) 1.0  = " ^ Real.fmt (StringCvt.GEN (SOME 6)) 1.0)
val _ = say ("    Real.fmt (FIX (SOME 0)) 3.5  = " ^ Real.fmt (StringCvt.FIX (SOME 0)) 3.5)
val _ = say ("    Real.fmt (FIX (SOME 17)) 0.3 = " ^ Real.fmt (StringCvt.FIX (SOME 17)) 0.3)

val _ = say "==== 18 \231\187\147\230\157\159 ===="
