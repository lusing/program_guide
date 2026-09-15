(* ==========================================================================
   16_numeric.ml - 数值计算
   ==========================================================================
   主题：使用 OCaml 进行数值计算
   内容：
     1. 二分法求根
     2. 牛顿法求根
     3. 梯形积分
     4. 辛普森积分
     5. 克拉默法则解线性方程组
     6. 拉格朗日插值
     7. 浮点数注意事项

   运行方式：
     ocaml 16_numeric.ml
     或
     utop # #use "16_numeric.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-')

(* ========================================================================
   1) 二分法求根
   ========================================================================
   二分法（Bisection Method）：
   - 用于求连续函数 f(x) = 0 的根
   - 前提：在区间 [a, b] 上 f(a) 和 f(b) 符号相反
   - 思路：反复将区间一分为二，选择包含根的子区间
   - 收敛速度：线性（每次迭代精度提高一位）
   - 优点：简单可靠，一定收敛
   - 缺点：收敛较慢，需要初始区间包含根
*)
section 1 "Bisection Method for Root Finding";;

let bisection f a b tol =
  if f a *. f b >= 0.0 then
    failwith "bisection: f(a) and f(b) must have opposite signs"
  else
    let rec loop a b =
      let mid = (a +. b) /. 2.0 in
      if b -. a < tol then mid
      else
        let f_mid = f mid in
        if f_mid = 0.0 then mid
        else if f a *. f_mid < 0.0 then loop a mid
        else loop mid b
    in
    loop a b

(* 测试：求 x^2 - 2 = 0 的根（即 sqrt(2)） *)
let f1 x = x *. x -. 2.0 in
let root1 = bisection f1 1.0 2.0 1e-10 in
Printf.printf "Root of x^2 - 2 = 0 (sqrt 2): %.12f\n" root1;
Printf.printf "  Actual sqrt(2):          %.12f\n" (sqrt 2.0);
Printf.printf "  Error:                   %.12e\n" (abs_float (root1 -. sqrt 2.0));;

(* 测试：求 cos(x) - x = 0 的根（Dottie number） *)
let f2 x = cos x -. x in
let root2 = bisection f2 0.0 1.0 1e-10 in
Printf.printf "Root of cos(x) - x = 0:    %.12f\n" root2;
Printf.printf "  f(root) = %.12e\n" (f2 root2);;

(* 测试：求 x^3 - x - 2 = 0 的根 *)
let f3 x = x *. x *. x -. x -. 2.0 in
let root3 = bisection f3 1.0 2.0 1e-10 in
Printf.printf "Root of x^3 - x - 2 = 0:   %.12f\n" root3;
Printf.printf "  f(root) = %.12e\n" (f3 root3);;

(* 迭代次数统计版本 *)
let bisection_counted f a b tol =
  if f a *. f b >= 0.0 then
    failwith "bisection_counted: signs must differ"
  else
    let rec loop a b count =
      let mid = (a +. b) /. 2.0 in
      if b -. a < tol then (mid, count)
      else
        let f_mid = f mid in
        if f_mid = 0.0 then (mid, count)
        else if f a *. f_mid < 0.0 then loop a mid (count + 1)
        else loop mid b (count + 1)
    in
    loop a b 1

let root, iterations = bisection_counted f1 1.0 2.0 1e-12 in
Printf.printf "Bisection for sqrt(2): %d iterations, root = %.12f\n" iterations root;;

(* ========================================================================
   2) 牛顿法求根
   ========================================================================
   牛顿法（Newton's Method）：
   - 用于求 f(x) = 0 的根
   - 需要函数及其导数
   - 迭代公式：x_{n+1} = x_n - f(x_n) / f'(x_n)
   - 收敛速度：二次（接近根时，每次迭代精度翻倍）
   - 优点：收敛快
   - 缺点：需要导数，可能不收敛，需要好的初始猜测
*)
section 2 "Newton's Method for Root Finding";;

let newton_method f f' x0 tol max_iter =
  let rec loop x i =
    if i >= max_iter then
      failwith "newton_method: maximum iterations reached"
    else
      let fx = f x in
      if abs_float fx < tol then x
      else
        let f'x = f' x in
        if f'x = 0.0 then
          failwith "newton_method: derivative is zero"
        else
          let x_next = x -. fx /. f'x in
          loop x_next (i + 1)
  in
  loop x0 0

(* 测试：求 sqrt(2)，f(x) = x^2 - 2, f'(x) = 2x *)
let f x = x *. x -. 2.0 in
let f' x = 2.0 *. x in
let root_newton = newton_method f f' 1.0 1e-12 50 in
Printf.printf "Newton method for sqrt(2): %.15f\n" root_newton;
Printf.printf "  Actual sqrt(2):          %.15f\n" (sqrt 2.0);
Printf.printf "  Error:                   %.15e\n" (abs_float (root_newton -. sqrt 2.0));;

(* 测试：求 e^x - x - 2 = 0 的根 *)
let f_exp x = exp x -. x -. 2.0 in
let f_exp' x = exp x -. 1.0 in
let root_exp = newton_method f_exp f_exp' 1.0 1e-12 50 in
Printf.printf "Root of e^x - x - 2 = 0:   %.12f\n" root_exp;
Printf.printf "  f(root) = %.12e\n" (f_exp root_exp);;

(* 带迭代次数的版本 *)
let newton_counted f f' x0 tol max_iter =
  let rec loop x i =
    if i >= max_iter then (x, i)
    else
      let fx = f x in
      if abs_float fx < tol then (x, i)
      else
        let f'x = f' x in
        if f'x = 0.0 then (x, i)
        else
          let x_next = x -. fx /. f'x in
          loop x_next (i + 1)
  in
  loop x0 0

let r, iters = newton_counted f f' 100.0 1e-12 50 in
Printf.printf "Newton from x0=100: %d iterations, root = %.12f\n" iters r;;

(* 割线法（Secant Method）：不需要导数，用差商近似 *)
let secant_method f x0 x1 tol max_iter =
  let rec loop x0 x1 i =
    if i >= max_iter then failwith "secant: max iterations"
    else
      let fx0 = f x0 in
      let fx1 = f x1 in
      if abs_float fx1 < tol then x1
      else
        let x_next = x1 -. fx1 *. (x1 -. x0) /. (fx1 -. fx0) in
        loop x1 x_next (i + 1)
  in
  loop x0 x1 0

let root_secant = secant_method f 1.0 2.0 1e-12 50 in
Printf.printf "Secant method for sqrt(2): %.12f\n" root_secant;;

(* ========================================================================
   3) 梯形积分
   ========================================================================
   梯形法则（Trapezoidal Rule）：
   - 数值积分方法：用梯形近似曲线下面积
   - 公式：∫f(x)dx ≈ (h/2) * [f(x0) + 2f(x1) + 2f(x2) + ... + 2f(xn-1) + f(xn)]
   - 其中 h = (b-a)/n
   - 收敛阶：O(h^2)
*)
section 3 "Trapezoidal Integration";;

let trapezoidal f a b n =
  let h = (b -. a) /. float_of_int n in
  let sum = ref 0.0 in
  sum := 0.5 *. (f a +. f b);
  for i = 1 to n - 1 do
    let x = a +. float_of_int i *. h in
    sum := !sum +. f x
  done;
  h *. !sum

(* 测试：∫ x^2 dx 从 0 到 1，精确值 = 1/3 *)
let f_x2 x = x *. x in
let integral1 = trapezoidal f_x2 0.0 1.0 10 in
Printf.printf "Integral of x^2 from 0 to 1 (n=10):  %.10f\n" integral1;
Printf.printf "  Exact value: 1/3 = %.10f\n" (1.0 /. 3.0);
Printf.printf "  Error: %.10e\n" (abs_float (integral1 -. 1.0 /. 3.0));;

let integral1_1000 = trapezoidal f_x2 0.0 1.0 1000 in
Printf.printf "Integral of x^2 from 0 to 1 (n=1000): %.10f\n" integral1_1000;
Printf.printf "  Error: %.10e\n" (abs_float (integral1_1000 -. 1.0 /. 3.0));;

(* 测试：∫ sin(x) dx 从 0 到 pi，精确值 = 2 *)
let integral2 = trapezoidal sin 0.0 3.14159265358979 100 in
Printf.printf "Integral of sin(x) from 0 to pi (n=100): %.10f\n" integral2;
Printf.printf "  Exact value: 2.0\n";
Printf.printf "  Error: %.10e\n" (abs_float (integral2 -. 2.0));;

(* 测试：∫ e^x dx 从 0 到 1，精确值 = e - 1 *)
let integral3 = trapezoidal exp 0.0 1.0 100 in
Printf.printf "Integral of e^x from 0 to 1 (n=100): %.10f\n" integral3;
Printf.printf "  Exact value: e - 1 = %.10f\n" (exp 1.0 -. 1.0);
Printf.printf "  Error: %.10e\n" (abs_float (integral3 -. (exp 1.0 -. 1.0)));;

(* 自适应梯形法：递归细分区间直到误差足够小 *)
let rec adaptive_trapezoidal f a b fa fb tol whole =
  let mid = (a +. b) /. 2.0 in
  let fmid = f mid in
  let left = (mid -. a) *. (fa +. fmid) /. 2.0 in
  let right = (b -. mid) *. (fmid +. fb) /. 2.0 in
  let approx = left +. right in
  if abs_float (approx -. whole) <= 3.0 *. tol then
    approx +. (approx -. whole) /. 15.0
  else
    adaptive_trapezoidal f a mid fa fmid (tol /. 2.0) left +.
    adaptive_trapezoidal f mid b fmid fb (tol /. 2.0) right

let adaptive_trap f a b tol =
  let fa = f a in
  let fb = f b in
  let whole = (b -. a) *. (fa +. fb) /. 2.0 in
  adaptive_trapezoidal f a b fa fb tol whole

let integral_adaptive = adaptive_trap f_x2 0.0 1.0 1e-10 in
Printf.printf "Adaptive trapezoidal (tol=1e-10): %.12f\n" integral_adaptive;
Printf.printf "  Error: %.12e\n" (abs_float (integral_adaptive -. 1.0 /. 3.0));;

(* ========================================================================
   4) 辛普森积分
   ========================================================================
   辛普森法则（Simpson's Rule）：
   - 用二次多项式近似被积函数
   - 公式：∫f(x)dx ≈ (h/3) * [f(x0) + 4f(x1) + 2f(x2) + 4f(x3) + ... + f(xn)]
   - n 必须为偶数
   - 收敛阶：O(h^4)（比梯形法快得多）
*)
section 4 "Simpson's Integration";;

let simpson f a b n =
  if n mod 2 <> 0 then
    failwith "simpson: n must be even"
  else
    let h = (b -. a) /. float_of_int n in
    let sum = ref (f a +. f b) in
    for i = 1 to n - 1 do
      let x = a +. float_of_int i *. h in
      let coeff = if i mod 2 = 0 then 2.0 else 4.0 in
      sum := !sum +. coeff *. f x
    done;
    h /. 3.0 *. !sum

(* 测试：∫ x^2 dx 从 0 到 1 *)
let simp1 = simpson f_x2 0.0 1.0 10 in
Printf.printf "Simpson x^2 from 0 to 1 (n=10):  %.12f\n" simp1;
Printf.printf "  Error: %.12e\n" (abs_float (simp1 -. 1.0 /. 3.0));;

(* 对于二次函数，辛普森法则是精确的（n=2 就够了） *)
let simp2 = simpson f_x2 0.0 1.0 2 in
Printf.printf "Simpson x^2 from 0 to 1 (n=2):   %.12f\n" simp2;
Printf.printf "  Error: %.12e\n" (abs_float (simp2 -. 1.0 /. 3.0));;

(* 测试：∫ sin(x) dx 从 0 到 pi *)
let pi = 4.0 *. atan 1.0 in
let simp3 = simpson sin 0.0 pi 10 in
Printf.printf "Simpson sin(x) from 0 to pi (n=10): %.12f\n" simp3;
Printf.printf "  Exact: 2.0, Error: %.12e\n" (abs_float (simp3 -. 2.0));;

(* 测试：∫ 1/(1+x^2) dx 从 0 到 1，精确值 = pi/4 *)
let f_atan x = 1.0 /. (1.0 +. x *. x) in
let simp4 = simpson f_atan 0.0 1.0 100 in
Printf.printf "Simpson 1/(1+x^2) from 0 to 1 (n=100): %.12f\n" simp4;
Printf.printf "  Exact: pi/4 = %.12f\n" (pi /. 4.0);
Printf.printf "  Error: %.12e\n" (abs_float (simp4 -. pi /. 4.0));;

(* 自适应辛普森法 *)
let rec adaptive_simpson f a b fa fb fmid tol whole =
  let mid = (a +. b) /. 2.0 in
  let left_mid = (a +. mid) /. 2.0 in
  let right_mid = (mid +. b) /. 2.0 in
  let flm = f left_mid in
  let frm = f right_mid in
  let h = b -. a in
  let left = h /. 12.0 *. (fa +. 4.0 *. flm +. fmid) in
  let right = h /. 12.0 *. (fmid +. 4.0 *. frm +. fb) in
  let approx = left +. right in
  if abs_float (approx -. whole) <= 15.0 *. tol then
    approx +. (approx -. whole) /. 15.0
  else
    adaptive_simpson f a mid fa fmid flm (tol /. 2.0) left +.
    adaptive_simpson f mid b fmid fb frm (tol /. 2.0) right

let adaptive_simp f a b tol =
  let fa = f a in
  let fb = f b in
  let mid = (a +. b) /. 2.0 in
  let fmid = f mid in
  let whole = (b -. a) /. 6.0 *. (fa +. 4.0 *. fmid +. fb) in
  adaptive_simpson f a b fa fb fmid tol whole

let asimp = adaptive_simp f_atan 0.0 1.0 1e-12 in
Printf.printf "Adaptive Simpson (tol=1e-12): %.15f\n" asimp;
Printf.printf "  Error: %.15e\n" (abs_float (asimp -. pi /. 4.0));;

(* ========================================================================
   5) 克拉默法则解线性方程组
   ========================================================================
   克拉默法则（Cramer's Rule）：
   - 用于求解形如 Ax = b 的线性方程组
   - 利用行列式求解：xi = det(Ai) / det(A)
   - 其中 Ai 是将 A 的第 i 列替换为 b 得到的矩阵
   - 只适用于方阵且 det(A) != 0 的情况
   - 计算量：O(n * n!)（非常大，只适合小规模问题）
*)
section 5 "Cramer's Rule for Linear Systems";;

(* 计算 2x2 矩阵的行列式 *)
let det2 a b c d = a *. d -. b *. c

(* 解 2x2 线性方程组：
   a1*x + b1*y = c1
   a2*x + b2*y = c2 *)
let solve_2x2 a1 b1 c1 a2 b2 c2 =
  let d = det2 a1 b1 a2 b2 in
  if d = 0.0 then failwith "solve_2x2: singular matrix"
  else
    let dx = det2 c1 b1 c2 b2 in
    let dy = det2 a1 c1 a2 c2 in
    (dx /. d, dy /. d)

(* 测试：
   2x + y = 5
   x - y = 1
   解：x = 2, y = 1
*)
let x1, y1 = solve_2x2 2.0 1.0 5.0 1.0 (-1.0) 1.0 in
Printf.printf "2x2 system:\n";
Printf.printf "  2x + y = 5\n";
Printf.printf "  x - y = 1\n";
Printf.printf "  Solution: x = %.2f, y = %.2f\n" x1 y1;;

(* 3x3 行列式（按第一行展开） *)
let det3 m =
  let a = m.(0).(0) and b = m.(0).(1) and c = m.(0).(2) in
  let d = m.(1).(0) and e = m.(1).(1) and f = m.(1).(2) in
  let g = m.(2).(0) and h = m.(2).(1) and i = m.(2).(2) in
  a *. (e *. i -. f *. h) -.
  b *. (d *. i -. f *. g) +.
  c *. (d *. h -. e *. g)

(* 解 3x3 线性方程组 *)
let solve_3x3 a b =
  let det = det3 a in
  if det = 0.0 then failwith "solve_3x3: singular matrix"
  else
    let replace_col col =
      let m = Array.map Array.copy a in
      for i = 0 to 2 do
        m.(i).(col) <- b.(i)
      done;
      m
    in
    let d1 = det3 (replace_col 0) in
    let d2 = det3 (replace_col 1) in
    let d3 = det3 (replace_col 2) in
    [| d1 /. det; d2 /. det; d3 /. det |]

(* 测试：
   x + y + z = 6
   2x + y - z = 1
   x - y + 2z = 5
   解：x = 1, y = 2, z = 3
*)
let a3 = [|
  [| 1.0; 1.0; 1.0 |];
  [| 2.0; 1.0; -1.0 |];
  [| 1.0; -1.0; 2.0 |]
|] in
let b3 = [| 6.0; 1.0; 5.0 |] in
let sol = solve_3x3 a3 b3 in
Printf.printf "\n3x3 system:\n";
Printf.printf "  x + y + z = 6\n";
Printf.printf "  2x + y - z = 1\n";
Printf.printf "  x - y + 2z = 5\n";
Printf.printf "  Solution: x = %.2f, y = %.2f, z = %.2f\n"
  sol.(0) sol.(1) sol.(2);;

(* ========================================================================
   6) 拉格朗日插值
   ========================================================================
   拉格朗日插值（Lagrange Interpolation）：
   - 给定 n 个点 (xi, yi)，构造一个 n-1 次多项式经过所有点
   - 公式：P(x) = Σ yi * Li(x)
   - 其中 Li(x) = Π (x - xj) / (xi - xj), j ≠ i
   - 用途：从离散数据点估计中间值
*)
section 6 "Lagrange Interpolation";;

(* 计算拉格朗日基函数 Li(x) *)
let lagrange_basis xs i x =
  let n = Array.length xs in
  let result = ref 1.0 in
  for j = 0 to n - 1 do
    if j <> i then
      result := !result *. (x -. xs.(j)) /. (xs.(i) -. xs.(j))
  done;
  !result

(* 拉格朗日插值多项式 *)
let lagrange_interpolate xs ys x =
  let n = Array.length xs in
  let result = ref 0.0 in
  for i = 0 to n - 1 do
    result := !result +. ys.(i) *. lagrange_basis xs i x
  done;
  !result

(* 测试：用 sin(x) 的几个点做插值 *)
let xs = [| 0.0; 0.5; 1.0; 1.5; 2.0 |] in
let ys = Array.map sin xs in
print_endline "Lagrange interpolation of sin(x):";
Printf.printf "  Data points:\n";
Array.iteri (fun i x -> Printf.printf "    x=%.1f, sin(x)=%.6f\n" x ys.(i)) xs;
print_endline "  Interpolated values:";
let test_points = [| 0.25; 0.75; 1.25; 1.75 |] in
Array.iter (fun x ->
  let approx = lagrange_interpolate xs ys x in
  let exact = sin x in
  Printf.printf "    x=%.2f: approx=%.6f, exact=%.6f, error=%.2e\n"
    x approx exact (abs_float (approx -. exact))
) test_points;;

(* 测试：用二次函数的三个点，插值应该精确还原 *)
print_endline "\nLagrange interpolation of x^2 (should be exact for degree 2):";
let xs_quad = [| 0.0; 1.0; 2.0 |] in
let ys_quad = [| 0.0; 1.0; 4.0 |] in
let test_x = [| 0.5; 1.5; (-0.5); 3.0 |] in
Array.iter (fun x ->
  let approx = lagrange_interpolate xs_quad ys_quad x in
  let exact = x *. x in
  Printf.printf "  x=%.1f: approx=%.4f, exact=%.4f, error=%.2e\n"
    x approx exact (abs_float (approx -. exact))
) test_x;;

(* ========================================================================
   7) 浮点数注意事项
   ========================================================================
   浮点数（float）使用 IEEE 754 双精度表示，
   存在精度限制和舍入误差，使用时需要注意。
*)
section 7 "Floating Point Caveats";;

(* 1) 不要用 = 比较浮点数是否相等 *)
print_endline "1) Equality comparison is unreliable:";
let a = 0.1 +. 0.2 in
let b = 0.3 in
Printf.printf "   0.1 + 0.2 = %.20f\n" a;
Printf.printf "   0.3       = %.20f\n" b;
Printf.printf "   (0.1 + 0.2) = 0.3 ? %b\n" (a = b);;

(* 正确做法：用近似相等（容差比较） *)
let approx_equal ?(eps = 1e-10) x y =
  abs_float (x -. y) < eps *. max 1.0 (max (abs_float x) (abs_float y))
;;
Printf.printf "   approx_equal (0.1+0.2) 0.3: %b\n" (approx_equal a b);;

(* 2) 浮点数的精度：大约 15-17 位有效数字 *)
print_endline "\n2) Floating point precision (~15-17 significant digits):";
let big = 1e16 in
Printf.printf "   1e16 + 1 = %.0f\n" (big +. 1.0);
Printf.printf "   (1e16 + 1) - 1e16 = %.0f\n" ((big +. 1.0) -. big);;

(* 3) 特殊值：nan, infinity, neg_infinity *)
print_endline "\n3) Special values:";
Printf.printf "   0.0 /. 0.0 = %f (nan)\n" (0.0 /. 0.0);
Printf.printf "   1.0 /. 0.0 = %f (infinity)\n" (1.0 /. 0.0);
Printf.printf "   -1.0 /. 0.0 = %f (neg_infinity)\n" (-1.0 /. 0.0);
Printf.printf "   nan = nan ? %b\n" (nan = nan);  (* nan 不等于任何东西，包括自己 *)
Printf.printf "   is_nan nan = %b\n" (classify_float nan = FP_nan);;

(* 4) 求和的精度问题：大数加小数可能丢失精度 *)
print_endline "\n4) Summation precision (large + small):";
let sum_large_first =
  let s = ref 1e10 in
  for _ = 1 to 1000 do
    s := !s +. 0.1
  done;
  !s -. 1e10
in
let sum_small_first =
  let s = ref 0.0 in
  for _ = 1 to 1000 do
    s := !s +. 0.1
  done;
  !s
in
Printf.printf "   Sum 0.1*1000, large first: %.10f\n" sum_large_first;
Printf.printf "   Sum 0.1*1000, small first: %.10f\n" sum_small_first;
Printf.printf "   Exact: 100.0\n";;

(* 5) Kahan 求和算法：减少求和误差 *)
let kahan_sum arr =
  let sum = ref 0.0 in
  let c = ref 0.0 in  (* 误差补偿 *)
  for i = 0 to Array.length arr - 1 do
    let y = arr.(i) -. !c in
    let t = !sum +. y in
    c := (t -. !sum) -. y;
    sum := t
  done;
  !sum
;;

(* 构造一个有精度问题的数组 *)
let test_arr = Array.init 100000 (fun _ -> 0.1) in
let naive_sum = Array.fold_left (+.) 0.0 test_arr in
let k_sum = kahan_sum test_arr in
let exact = 10000.0 in
Printf.printf "\n   Naive sum of 0.1*100000: %.10f (error: %.2e)\n"
  naive_sum (abs_float (naive_sum -. exact));
Printf.printf "   Kahan sum of 0.1*100000: %.10f (error: %.2e)\n"
  k_sum (abs_float (k_sum -. exact));;

(* 6) 浮点数的范围 *)
print_endline "\n6) Float range:";
Printf.printf "   max_float = %g\n" max_float;
Printf.printf "   min_float = %g\n" min_float;
Printf.printf "   epsilon_float = %g (最小的 x 使得 1.0 +. x <> 1.0)\n" epsilon_float;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 16 jieshu ===="  (* 第十六个文件结束 *)
