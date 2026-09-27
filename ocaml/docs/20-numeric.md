# 20 · 数值计算

对应示例：`../examples/16_numeric.ml`

对应示例：`examples/16_numeric.ml`

### 20.1 数值计算中的函数式思维

数值计算通常被认为是「命令式的领地」——到处都是循环、数组、原地修改。但 OCaml 的函数式风格同样可以用来写数值计算代码，而且往往更清晰。

关键在于：把每个计算步骤看作一个从输入到输出的纯函数，然后用函数组合和递归来搭建复杂的计算。

### 20.2 二分法求根

二分法（Bisection Method）是求函数零点的最简单、最可靠的方法。前提是函数在区间 [a, b] 上连续，且 f(a) 和 f(b) 异号（根据中间值定理，区间内至少有一个根）。

算法：
1. 取区间中点 c = (a+b)/2
2. 计算 f(c)
3. 如果 f(c) 和 f(a) 异号，根在 [a, c]，否则根在 [c, b]
4. 重复直到区间足够小

```ocaml
let bisection f a b tolerance =
  let rec loop a b fa fb =
    let c = (a +. b) /. 2.0 in
    let fc = f c in
    if abs_float (b -. a) < tolerance then c
    else if fa *. fc < 0.0 then
      loop a c fa fc
    else
      loop c b fc fb
  in
  loop a b (f a) (f b)
```

这是一个典型的尾递归实现。`loop` 函数维护当前的区间 [a, b] 和两端的函数值 fa、fb，每次迭代缩小区间一半。

```ocaml
(* 求 x^3 - x - 2 = 0 在 [1, 2] 之间的根 *)
let _ =
  let root = bisection (fun x -> x ** 3. -. x -. 2.) 1.0 2.0 1e-6 in
  Printf.printf "Root: %.6f\n" root   (* 约 1.521380 *)
```

### 20.3 牛顿法求根

牛顿法（Newton's Method）是一种更快的求根方法，它利用函数的导数来加速收敛。

迭代公式：x_{n+1} = x_n - f(x_n) / f'(x_n)

```ocaml
let newton_method f f' x0 tolerance max_iter =
  let rec loop x i =
    if i >= max_iter then x
    else
      let fx = f x in
      if abs_float fx < tolerance then x
      else
        let f'x = f' x in
        if abs_float f'x < 1e-12 then failwith "derivative too close to zero"
        else loop (x -. fx /. f'x) (i + 1)
  in
  loop x0 0
```

参数：
- `f`：目标函数
- `f'`：f 的导函数
- `x0`：初始猜测
- `tolerance`：精度要求
- `max_iter`：最大迭代次数（防止发散）

```ocaml
(* 同样求 x^3 - x - 2 = 0 的根 *)
let _ =
  let f x = x ** 3. -. x -. 2. in
  let f' x = 3. *. x ** 2. -. 1. in
  let root = newton_method f f' 2.0 1e-10 50 in
  Printf.printf "Newton root: %.10f\n" root   (* 约 1.5213797068 *)
```

牛顿法的收敛速度是二次的——每次迭代有效位数大约翻倍。但它需要你提供导数，而且初始值不好的话可能不收敛。

**数值微分**：如果你不想手动求导，可以用数值微分来近似：

```ocaml
let numerical_derivative f x h =
  (f (x +. h) -. f (x -. h)) /. (2.0 *. h)

let newton_numerical f x0 tolerance max_iter =
  let f' x = numerical_derivative f x 1e-6 in
  newton_method f f' x0 tolerance max_iter
```

数值微分简单但有精度问题——h 太小会有舍入误差，太大又有截断误差。

### 20.4 梯形积分法

积分的几何意义是函数曲线下的面积。梯形法（Trapezoidal Rule）用小梯形来近似每个区间的面积。

公式：∫_a^b f(x) dx ≈ (h/2) * [f(x_0) + 2f(x_1) + 2f(x_2) + ... + 2f(x_{n-1}) + f(x_n)]

其中 h = (b-a)/n，x_i = a + i*h。

```ocaml
let trapezoidal_integral f a b n =
  let h = (b -. a) /. float_of_int n in
  let rec loop i sum =
    if i >= n then sum
    else
      let x = a +. float_of_int i *. h in
      loop (i + 1) (sum +. f x)
  in
  let sum_middle = loop 1 0.0 in  (* 中间的点（x_1 到 x_{n-1}） *)
  h *. (0.5 *. f a +. sum_middle +. 0.5 *. f b)
```

```ocaml
(* 计算 ∫_0^1 x^2 dx = 1/3 ≈ 0.333333 *)
let _ =
  let result = trapezoidal_integral (fun x -> x *. x) 0.0 1.0 100 in
  Printf.printf "Trapezoidal integral: %.6f\n" result   (* 约 0.333350 *)
```

梯形法的误差是 O(h^2)，即把 n 翻倍，误差大约减少到 1/4。

### 20.5 辛普森积分法

辛普森法（Simpson's Rule）用抛物线近似函数曲线，精度比梯形法更高。

公式：∫_a^b f(x) dx ≈ (h/3) * [f(x_0) + 4f(x_1) + 2f(x_2) + 4f(x_3) + ... + 4f(x_{n-1}) + f(x_n)]

其中 n 必须是偶数。

```ocaml
let simpson_integral f a b n =
  if n mod 2 <> 0 then failwith "n must be even"
  else
    let h = (b -. a) /. float_of_int n in
    let rec loop i sum =
      if i >= n then sum
      else
        let x = a +. float_of_int i *. h in
        let weight = if i mod 2 = 0 then 2.0 else 4.0 in
        loop (i + 1) (sum +. weight *. f x)
    in
    let sum_middle = loop 1 0.0 in
    h /. 3.0 *. (f a +. sum_middle +. f b)
```

```ocaml
let _ =
  let result = simpson_integral (fun x -> x *. x) 0.0 1.0 100 in
  Printf.printf "Simpson integral: %.6f\n" result   (* 约 0.333333 —— 几乎精确 *)
```

辛普森法的误差是 O(h^4)，收敛快得多。对于光滑函数，辛普森法通常比梯形法高效很多。

### 20.6 克拉默法则解线性方程组

克拉默法则（Cramer's Rule）是解线性方程组的一种方法。对于方程组 Ax = b，解的每个分量是 x_i = det(A_i) / det(A)，其中 A_i 是把 A 的第 i 列换成 b 得到的矩阵。

先实现行列式计算（用递归展开）：

```ocaml
let rec determinant matrix =
  let n = Array.length matrix in
  if n = 0 then 1.0
  else if n = 1 then matrix.(0).(0)
  else if n = 2 then
    matrix.(0).(0) *. matrix.(1).(1) -. matrix.(0).(1) *. matrix.(1).(0)
  else
    let rec sum acc j =
      if j >= n then acc
      else
        (* 构造去掉第 0 行第 j 列的子矩阵 *)
        let sub = Array.make_matrix (n - 1) (n - 1) 0.0 in
        for i' = 1 to n - 1 do
          let col = ref 0 in
          for j' = 0 to n - 1 do
            if j' <> j then (
              sub.(i' - 1).(!col) <- matrix.(i').(j');
              incr col
            )
          done
        done;
        let sign = if j mod 2 = 0 then 1.0 else -1.0 in
        sum (acc +. sign *. matrix.(0).(j) *. determinant sub) (j + 1)
    in
    sum 0.0 0
```

然后用克拉默法则：

```ocaml
let cramer a b =
  let n = Array.length a in
  let det_a = determinant a in
  if abs_float det_a < 1e-12 then failwith "singular matrix"
  else
    let solution = Array.make n 0.0 in
    for i = 0 to n - 1 do
      (* 构造 A_i：把第 i 列换成 b *)
      let a_i = Array.make_matrix n n 0.0 in
      for row = 0 to n - 1 do
        for col = 0 to n - 1 do
          a_i.(row).(col) <-
            if col = i then b.(row) else a.(row).(col)
        done
      done;
      solution.(i) <- determinant a_i /. det_a
    done;
    solution
```

```ocaml
(* 解方程组：
   2x + y - z = 8
   -3x - y + 2z = -11
   -2x + y + 2z = -3
*)
let _ =
  let a = [|
    [| 2.0; 1.0; -1.0 |];
    [| -3.0; -1.0; 2.0 |];
    [| -2.0; 1.0; 2.0 |]
  |] in
  let b = [| 8.0; -11.0; -3.0 |] in
  let x = cramer a b in
  Printf.printf "Solution: x=%.2f, y=%.2f, z=%.2f\n" x.(0) x.(1) x.(2)
  (* 应该是 x=2, y=3, z=-1 *)
```

注意：克拉默法则虽然简洁，但时间复杂度是 O(n!)，只适用于非常小的方程组（n <= 3）。对于大规模方程组，应该用高斯消元法等 O(n^3) 的算法。

### 20.7 拉格朗日插值

拉格朗日插值（Lagrange Interpolation）是一种多项式插值方法：给定 n+1 个点 (x_0,y_0), ..., (x_n, y_n)，构造一个 n 次多项式经过所有这些点。

公式：L(x) = Σ_{i=0}^n y_i * l_i(x)，其中 l_i(x) = Π_{j≠i} (x - x_j) / (x_i - x_j)

```ocaml
let lagrange_interpolate xs ys x =
  let n = Array.length xs in
  let rec lagrange_basis i j prod =
    if j >= n then prod
    else if j = i then lagrange_basis i (j + 1) prod
    else
      let term = (x -. xs.(j)) /. (xs.(i) -. xs.(j)) in
      lagrange_basis i (j + 1) (prod *. term)
  in
  let rec sum i acc =
    if i >= n then acc
    else
      let li = lagrange_basis i 0 1.0 in
      sum (i + 1) (acc +. ys.(i) *. li)
  in
  sum 0 0.0
```

```ocaml
(* 已知 sin(0)=0, sin(π/6)=0.5, sin(π/2)=1
   用拉格朗日插值估计 sin(π/4) ≈ 0.7071 *)
let _ =
  let pi = 3.14159265358979 in
  let xs = [| 0.0; pi /. 6.0; pi /. 2.0 |] in
  let ys = [| 0.0; 0.5; 1.0 |] in
  let result = lagrange_interpolate xs ys (pi /. 4.0) in
  Printf.printf "Lagrange interpolation of sin(π/4): %.6f\n" result
```

### 20.8 浮点数的三大坑

浮点数看起来简单，但有很多陷阱。了解这些坑可以帮你避免很多难以调试的 bug。

**坑一：精度问题**

浮点数（IEEE 754 双精度）只有大约 15-17 位有效数字。不是所有的十进制小数都能精确表示。

```ocaml
let _ =
  0.1 +. 0.2 = 0.3     (* false！ *)
```

为什么？因为 0.1 和 0.2 在二进制浮点数中都是无限循环小数，存储时有舍入误差。加起来的结果和 0.3 的二进制表示不完全一样。

**坑二：舍入误差累积**

每次浮点运算都可能有一点点误差，这些误差会累积。

```ocaml
let rec sum_loop i acc =
  if i >= 10000 then acc
  else sum_loop (i + 1) (acc +. 0.1)

let _ =
  let result = sum_loop 0 0.0 in
  result = 1000.0    (* false！实际值略小于 1000.0 *)
```

加 10000 次 0.1，结果不是精确的 1000.0，因为每次加法都有一点点误差。

**坑三：比较的陷阱**

因为有精度问题，你几乎不应该用 `=` 直接比较两个浮点数是否相等。你应该用「近似相等」——检查它们的差是否在某个容差范围内。

```ocaml
let (~=.) a b =
  abs_float (a -. b) < 1e-9 *. max 1.0 (max (abs_float a) (abs_float b))
```

这个版本用了相对容差，对于大数和小数都比较合理。

### 20.9 OCaml 中浮点数的特殊值

OCaml 的浮点数遵循 IEEE 754 标准，有几个特殊值：

**nan（Not a Number）**：表示未定义的运算结果，比如 0.0 /. 0.0、sqrt (-1.0)。

```ocaml
let _ =
  0.0 /. 0.0;         (* nan *)
  sqrt (-1.0);        (* nan *)
  nan = nan;          (* false —— nan 不等于任何东西，包括它自己！ *)
  nan <> nan;         (* true  —— 对，nan 不等于自己 *)
```

nan 有一个非常反直觉的性质：**nan 不等于自己**。这是 IEEE 754 标准规定的。判断一个值是不是 nan，可以用 `Float.is_nan`（OCaml 4.07+）或者 `x <> x` 这个技巧。

**infinity 和 neg_infinity**：正无穷和负无穷。

```ocaml
let _ =
  1.0 /. 0.0;          (* infinity *)
  -1.0 /. 0.0;         (* neg_infinity *)
  infinity +. 1.0;     (* infinity *)
  1.0 /. infinity;     (* 0.0 *)
  infinity = infinity  (* true *)
```

### 20.10 浮点数比较的正确姿势

总结一下浮点数比较的最佳实践：

1. **永远不要用 `=` 比较浮点数是否相等**，除非你确切知道你在做什么
2. **用 epsilon 比较**：检查 `abs_float (a -. b) < epsilon`
3. **选择合适的 epsilon**：取决于你的应用场景，通常 1e-9 到 1e-12 对于双精度比较合适
4. **考虑相对误差**：对于很大的数，绝对误差可能不够；可以用 `abs_float (a -. b) < epsilon *. max (abs_float a) (abs_float b)`
5. **注意 nan**：任何和 nan 的比较都会返回 false（除了 `<>` 返回 true）
6. **用 `Float.compare` 而不是 `compare`**：`Float.compare` 对 nan 有明确定义

```ocaml
(* 一个比较完善的浮点数近似相等函数 *)
let approx_equal ?(epsilon = 1e-9) a b =
  if Float.is_nan a || Float.is_nan b then false
  else if a = b then true   (* 处理无穷大和精确相等的情况 *)
  else
    let diff = abs_float (a -. b) in
    if diff < epsilon then true
    else
      let max_val = max (abs_float a) (abs_float b) in
      diff < epsilon *. max_val
```

### 20.11 本章小结

- 二分法求根：简单可靠，需要区间端点异号，收敛速度线性
- 牛顿法求根：收敛速度快（二次），需要导数，初始值不好可能不收敛
- 梯形积分法：O(h^2) 误差，简单直观
- 辛普森积分法：O(h^4) 误差，对于光滑函数效率更高
- 克拉默法则：解线性方程组，简洁但复杂度高（O(n!)），只适合小型方程组
- 拉格朗日插值：构造经过给定点的多项式
- 浮点数三大坑：精度、舍入误差累积、比较
- 浮点数特殊值：nan（不等于自己）、infinity、neg_infinity
- 浮点数比较要用 epsilon，不要直接用 `=`

---

---
上一章：[19 · 排序与经典算法](algorithms.md) ｜ 下一章：[21 · 解析：词法分析与递归下降](parsing.md) ｜ 返回：[README](../README.md)
