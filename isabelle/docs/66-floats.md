# 66 · 浮点、区间、判别式与 sos：实数的可计算面孔

对应示例：`../examples/lib/T66_floats.thy`（IsaTutLib 会话，依赖
`HOL-Library.Interval_Float`（带出 `Interval` 与 `Float`）、
`Quadratic_Discriminant`、`Sum_of_Squares`、`Z2`）

第 46 章的 HOL-Analysis 管实数的**理论**；本章管实数的**计算**：
二进制浮点（精确子集）、定向舍入、保守区间，外加两个代数小品
（二次判别式、sos 决策过程）和最小域 Z2。

## 66.1 Float：二进制浮点的精确定义

`Float` 的 `float` 是**精确**的二进制浮点：`int` 尾数 + `int`
指数，`Float m e` 的值是 `m * 2^e`（typedef 收进 `real` 中所有
这种形状）。它不是 IEEE754——没有 NaN、没有溢出舍入、尾数任意
长——而是「实数的可执行子集」。算术按位精确：乘法指数相加，
加法先对齐指数：

```isabelle
value "Float 3 (-2) + Float 1 0"     (* Float 7 (-2)：3/4 + 1 = 7/4 *)
value "Float 3 (-2) * Float 2 1"     (* Float 6 (-1)：尾数乘、指数加 *)
value "(0::float) < Float 1 (-1)"    (* True *)
value "real_of_float (Float 1 (-1))" (* 1 / 2 :: real *)
```

`real_of_float` 投影回 `real`（注册了 coercion，打印看不到
箭头）。float 上有 `linordered_idom`、`lattice_ab_group_add` 等
实例，比较与 min/max 都精确。打印结果经 `normfloat` 规范化——
尾数的 2 因子被吸进指数，`Float 20 (-2)` 会显示成 `5`。

## 66.2 定向舍入：float_round_up / float_round_down

精度控制是浮点算术的核心：这两个函数把 float 舍到至多 p 位
**有效二进制数字**，方向分别为向下/向上——区间算术的保守性
（结果必含真值）就建立在这一对原语上：

```isabelle
value "float_round_down 2 (Float 21 (-2))"   (* 5   — 5.25 → 5.0 *)
value "float_round_up 2 (Float 21 (-2))"     (* 6   — 5.25 → 6.0 *)
value "float_round_down 2 (Float 21 (-3))"   (* Float 5 (-1) — 2.625 → 2.5 *)
```

5.25 是 101.01b（三位有效）；精度 2 向下舍到 101b = 5，向上进到
110b = 6。配套的方向不等式 `float_round_down`/`float_round_up`
（下舍 ≤ 原值 ≤ 上舍）是「含真值」证明的接口。

## 66.3 Interval_Float：保守的区间算术

`Interval_Float` 把 `Interval`（上下界有序对）与 Float 缝合。
`round_interval p` 对区间两端分别向下/向上舍，保证结果区间
**包住**原区间（`round_ivl_correct`）：

```isabelle
value "lower (round_interval 2 (interval_of (Float 21 (-2))))"  (* 5 *)
value "upper (round_interval 2 (interval_of (Float 21 (-2))))"  (* 6 *)
```

点区间 [5.25] 精度 2 舍入后变 [5, 6]——真值必在其中。`mid`
（中点）、`centered`（中心-半径化）、`split_float_interval`
（对半切分）是区间细化的标准件；guaranteed numerics（保证精度
的数值计算）与区间牛顿法都建在这上面。

## 66.4 Quadratic_Discriminant：配方法与判别式

中学代数的形式化：判别式 `discrim a b c = b² - 4·a·c`，配方法
恒等式

```text
complete_square: a ≠ 0 ⟹ a·x² + b·x + c = 0 ⟷ (2·a·x + b)² = discrim a b c
```

以及判别式为负则无实根：

```isabelle
lemma no_real_root: "∄x::real. 2 * x^2 + 2 * x + 1 = 0"
  using discriminant_negative[of 2 2 1] by (simp add: discrim_def)
```

判别式 4 − 8 = −4 < 0。配方恒等式把求解化归为平方根存在性
（`plus_or_minus_sqrt`），完整求根公式在库里（`quadratic_eq`
一族）。`a ≠ 0` 前提别省——判别式判据只对二次成立。

## 66.5 Sum_of_Squares：sos 决策过程

`Sum_of_Squares` 提供 `sos` 方法：多元实数算术的全称命题用
「平方和证书」判定（半定规划思想）。离线可用的形态：

```isabelle
lemma "(x::real)^2 + 1 > 0"          by sos
lemma "(a::real)^2 + b^2 ≥ 2 * a * b"  by sos
```

第二行是 AM-GM 的平方和形态（(a−b)² ≥ 0）。复杂证书需要外部
SDP 求解器（csdp 等），本机没有时 `sos` 报的是「证书求不出」，
不是「命题为假」——与 `nitpick` 的失败语义相反，别误读。

## 66.6 Z2：模 2 域

`Z2` 的 `bit` 是 `bool` 的「域化」包装（历史命名）：两元素域
Z/2Z。加是异或、乘是合取、每个元是自己的加法逆元：

```isabelle
value "(1::bit) + 1"                 (* 0 *)

lemma bit_self_add_zero: "(a::bit) + a = 0"
  by (cases a) simp_all
```

源码开头自带提醒：多数场合用 `bool` 就够了，`bit` 只在需要
**域运算**（除法、域论定理，它有 `field` 实例）时才必要。
纠错码（汉明码等）的形式化从它开始。

## 66.7 Code_Real_Approx_By_Float：一个「危险品」标本

`Code_Real_Approx_By_Float` 值得单独警告：它把数学实数 `real`
的代码等式直接映射到机器浮点——**这是不一致的**。源码开头自带
WARNING，结尾还有一个对 `False` 的「伪证」演示（一个实数等式
被浮点实现错误地证伪）。它存在的唯一合法用途是某些代码生成
场景里的近似计算。教学立场：知道它存在、知道为什么危险（实数
的代数性质在浮点上不成立——结合律都丢），**不要**在自己的
理论里导入它；要近似实数就走 66.1–66.3 的 float/interval 显式
通道（那才是有保证的近似）。

## 66.8 坑位清单（实测）

1. `float` 不是 IEEE754：无 NaN/Inf、尾数任意长；它是 `real`
   的可执行子集，不是硬件浮点模拟器。
2. `Float m e` 的指数是**二进制**（值为 m·2^e），别当十进制
   科学计数法读。
3. 打印走 `normfloat` 规范化：`Float 20 (-2)` 显示成 `5`——
   读输出时别误会尾数「丢了」。
4. `float_round_down`/`float_round_up` 的精度参数是**二进制
   有效位数**，不是小数位数。
5. 区间运算必须维持方向纪律（下界下舍、上界上舍），否则保守性
   破产；自定义区间操作时对照 `round_interval` 的写法。
6. `sos` 的失败语义是「证书求不出」而非命题为假；离线只能过
   简单目标，复杂证书要外部 SDP 求解器。
7. `bit` 与 `bool` 是两个类型：域运算用 bit，逻辑用 bool，
   互转走 `Rep_bit`/`Abs_bit`。
8. `discriminant_negative` 的 `a ≠ 0` 前提别省（a = 0 时退化
   为一次方程，判别式判据不适用）。
9. `Code_Real_Approx_By_Float` 是故意不一致的「危险品」：
   导入后 real 的代码等式被机器浮点接管，连 `False` 都能
   「证」；只读勿用。
10. `real_of_float` 是 coercion：float 与 real 混写时打印看不到
    转换箭头，读定理时注意哪一侧在说话。

## 66.9 与其他章的接口

- 第 46 章 HOL-Analysis：float 是 real 的可执行子集，分析定理
  经 `real_of_float` 投影到可计算层。
- 第 28 章 typedef：float（精确子集）与 61 章 ennreal（钳制
  abs）是两种 typedef 模式的对照。
- 第 65 章 Word：同为「数值的表示层」，word 绕回精确可证、
  float 近似需区间保驾——两种工程哲学。
- 第 62 章：Z2 是可数有限域，编码理论与 62 章的基数语言衔接。
