# 24 · 数值计算：math / multiprecision / rational / units / qvm / crc / safe_numerics / numeric::conversion

> 对应示例：`examples/24_numeric/`（8 个例程）

Boost 的数值家族覆盖"从精确到安全"的整条光谱：算得更准（multiprecision/rational）、算得对量纲（units）、算得安全（safe_numerics/numeric_conversion）、算得专（math/qvm/crc）。

## 24.1 Boost.Math（2005）：数学全家桶

```cpp
boost::math::tgamma(5.0);                        // Γ 函数 = 24 = 4!
boost::math::normal_distribution<> n170(170, 6); // 统计分布
boost::math::cdf(n170, 180.0);                   // P(X≤180)
boost::math::constants::pi<double>();            // 高精度常量
```

运行输出（`math.cpp`）：

```text
Γ(5) = 24（= 4! = 24）
lgamma(100) = 359.134（防溢出的 log 形式）
B(2,3) = 0.0833333
P(X<=180) = 0.95221
P(X>160) = 0.95221
95% 分位 = 179.869
π = 3.14159（e = 2.71828）
double 机器精度 ε = 2.22045e-16
next(1.0) - 1.0 = 2.22045e-16
自检通过
```

**毕业档案**：`gcd/lcm` 进 std（C++17）——但主体（特殊函数、统计分布全套、插值、多项式求解）std 无对应。⭐ 科学计算与量化分析的 C++ 事实标准。

## 24.2 Boost.Multiprecision（2002）：超精度数值

```cpp
cpp_int fact = 1;
for (int i = 2; i <= 100; ++i) fact *= i;        // 158 位，不溢出
cpp_dec_float_50 pi = boost::math::constants::pi<cpp_dec_float_50>();
```

运行输出（`multiprecision.cpp`）：

```text
100! 有 158 位, 末 10 位 = 0000000000
π(50位) = 3.1415926535897932384626433832795028841971693993751
a+b 前 15 位 = 111111111011111...
a*b 是 57 位? 0
a/3 前 10 位 = 4115226300...
自检通过
```

三种后端可换：`cpp_int`（自带实现，零依赖）、`cpp_dec_float_N`（十进制浮点）、GMP/MPFR 后端（装了就提速）。密码学、大数运算、金融精算的地基。⭐

## 24.3 Boost.Rational（2000）：精确分数

```cpp
rational<int> half(1, 2), third(1, 3);
half + third;               // 5/6（自动约分）
rational<int>(1,10) + rational<int>(2,10) == rational<int>(3,10);   // true！
```

运行输出（`rational.cpp`）：

```text
1/2 + 1/3 = 5/6（自动约分）
1/2 * 1/3 = 1/6
1/2 / 1/3 = 3/2
1/3 的分子 = 1 分母 = 3
1/10 + 2/10 == 3/10 ? 1
1/2 < 2/3 ? 1
1/0 抛 bad_rational（不是 UB）
自检通过
```

**与 decimal（17 章）的分界**：rational 是**精确分数**（分母任意，运算量增长）；decimal 是**十进制浮点**（固定位数，可规模化）。实验数学用 rational，金融工程用 decimal。

## 24.4 Boost.Units（2006）：量纲安全

"米 + 秒"编译期报错——1999 年火星气候探测者号因磅/牛顿混用坠毁，这个库就是这类事故的疫苗：

```cpp
quantity<si::length> d = 100.0 * si::meters;
quantity<si::time> t = 9.58 * si::seconds;
quantity<si::velocity> v = d / t;      // 量纲自动推导
// quantity<si::length> bad = d + t;   // 编译错误！
```

运行输出（`units.cpp`）：

```text
100m / 9.58s = 10.4384 m s^-1（量纲自动推导成速度）
加速度 = 1.09031 m s^-2
1500m 量纲输出 = 1500 m
60J = 60 J
float 能量 = 60 J
自检通过
```

⭐ 科学/工程计算里"单位错误"变编译错误。实测注意：带前缀的量（`kilo * meters`）是异构单位类型，赋给标准量要显式转换。

## 24.5 Boost.QVM（2018）：3D 数学轻量件

```cpp
vec<float,3> v{1,2,3};
dot(v, w);  cross(v, w);  mag(v);
auto rz = rot_mat<3>(axis, angle);     // 旋转矩阵
quat<float> q = rot_quat(axis, angle); // 四元数（无万向锁）
q * v;                                 // 四元数旋转向量
```

运行输出（`qvm.cpp`）：

```text
v = (1,2,3)
点积 = 2
叉积 = (-3,0,1)
|v| = 3.74166
矩阵旋转: (-2,1,3)
四元数旋转: (-2,1,3)
|q| = 1（单位四元数）
q*q 再旋 v: (-1,-2,3)
单位阵 [1][1] = 1
自检通过
```

矩阵旋转与四元数旋转结果一致（-2,1,3）——两条路殊途同归。**与 ublas（25 章）的分界**：QVM 为 3D 图形而生（3x3/4x4、quat、视图零开销）；ublas 为通用线代（任意维、求解器）。

> 实测坑三连：细分头是迷宫（mat×vec 的 operator* 藏在 gen/ 生成头里，直接用总头 `all.hpp`）；`identity_mat`/`rot_quat` 等生成器返回**视图类型**，要落地成实体才能后续运算；1.92 没有 `float3` 快捷别名，自己 `using vec<float,3>`。

## 24.6 Boost.CRC（2001）：校验和

```cpp
boost::crc_32_type crc32;
crc32.process_bytes(data, len);    // 流式喂入
crc32.checksum();                  // 0xca086b9e
```

运行输出（`crc.cpp`）：

```text
CRC-32 = 0xca086b9e
两次一致? 1
改一字节后 0x517b814a（截然不同）
分块喂 = 一次喂? 1
CRC-CCITT = 0xc1b6
自检通过
```

传输完整性、文件指纹的百年老件。std 无对应（C++26 的 `std::checksum` 提案路上）。⭐

## 24.7 + 24.8 安全数值双璧：SafeNumerics 与 NumericConversion

原生 C++ 的算术安全是"两条静默的坑"：**有符号溢出是 UB**、**负数转无符号静默回绕**。两个库分别解毒：

```cpp
// SafeNumerics：溢出变异常/编译错
safe<std::int8_t> s = 100;  s += 100;      // 抛 positive_overflow
// NumericConversion：范围检查的转换
boost::numeric_cast<unsigned int>(-1);      // 抛 negative_overflow
```

运行输出（`safe_numerics.cpp` / `numeric_conversion.cpp`）：

```text
int8 原生 100+100 = -56（UB 现场，碰巧回绕）
safe 溢出被抓住（positive_overflow）
安全范围內: 1000000×2 = 2000000
除零被抓住（divide_by_zero）
---
原生 cast(-1 → unsigned) = 4294967295（静默回绕）
numeric_cast 抓住负溢出
numeric_cast 抓住正溢出
合法转换 100 → int8 = 100
int8 最高 = 127 float 最低 = -3.40282e+38
自检通过
```

对照表里原生 UB 的现场（-56、4294967295）就是两个库存在的全部理由。⭐ 解析外部输入（配置、协议、用户数据）的每一处窄化转换都该有其一在场。

---

下一章：[25 · 线代、图像与 GPU](25-compute.md)——ublas / odeint / interval / accumulators / histogram / gil / compute。
