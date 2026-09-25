# 25 · 线代、图像与 GPU：ublas / odeint / interval / accumulators / histogram / gil / compute

> 对应示例：`examples/25_compute/`（7 个例程）

科学计算的 Boost 全家福：从 BLAS 式线代（ublas，C++26 `std::linalg` 的精神源头）一路到 GPU（compute，本机 RTX 3060 实测）。

## 25.1 Boost.uBLAS（2002）：线代的祖父辈

```cpp
ublas::matrix<double> A(2, 2);
ublas::prod(A, B);                     // 矩阵乘（表达式模板，免临时量）
ublas::lu_factorize(A, pm);            // LU 分解 → 行列式/逆矩阵
```

运行输出（`ublas.cpp`）：

```text
v = [3](1,2,3)
A = [2,2]((4,7),(2,6))
A + B = [2,2]((5,7),(2,7))
A × B = [2,2]((4,7),(2,6))
A × v(前2维) = [2](18,14)
det(A) = 10（4×6-7×2 = 10）
A⁻¹ = [2,2]((0.6,-0.7),(-0.2,0.4))
自检通过
```

**血缘**：C++26 `std::linalg`（P1673）标准化 BLAS 语义——ublas 二十年前的表达。⭐ 中小规模线代（无需 Eigen 那么重）可用；性能敏感的大矩阵请用 Eigen/MKL——ublas 的编译期抽象在激进优化下略逊。

## 25.2 Boost.OdeInt（2011）：微分方程求解器

```cpp
odeint::integrate(Harmonic{}, x, 0.0, pi, 0.01);          // 自适应
odeint::integrate_const(runge_kutta4<>{}, f, y, 0, 1, 0.25, observer);
```

运行输出（`odeint.cpp`）：

```text
半周期后 x = -0.999999（解析解 ≈ -1）
步数 = 14（自适应控制下）
等步长观察次数 = 5
Cash-Karp 自适应: x = -1
自检通过
```

求解器阵容豪华（RK4/Cash-Karp/Dormand-Prince/Rosenbrock/隐式 Euler/Bulirsch-Stoer），状态容器可换——`std::vector`、ublas、甚至 **thrust/GPU 后端**。⭐ std 无对应。

## 25.3 Boost.Interval（2002）：带误差界的算术

```cpp
I width(0.9, 1.1);         // 1.0 ± 0.1
I area = width * height;   // 区间乘法自动传播误差
I(1,1) / I(-0.1, 0.1);     // 跨无穷也不慌
```

运行输出（`interval.cpp`）：

```text
面积区间 = [1.71, 2.31]
三次相加 = [2.7, 3.3]（误差也 ×3）
面积包含 2.0? 1
面积包含 2.5? 0
1/(±0.1) = [-inf, inf]（跨无穷）
自检通过
```

每一步运算的误差自动跟踪——**数值验证**（证明计算结果必在某区间内）与测量误差传播的标准工具。⭐

## 25.4 Boost.Accumulators（2006）：一遍过的流式统计

```cpp
acc::accumulator_set<double, acc::stats<tag::mean, tag::variance, ...>> stats;
for (double x : data) stats(x);
acc::mean(stats);  acc::variance(stats);
```

运行输出（`accumulators.cpp`）：

```text
count = 8
mean = 5（解析 = 5）
variance = 4（样本方差 = 4）
min/max = 2/9
sum = 40
median ≈ 4.16667（解析 = 4.5）
自检通过
```

亿级数据流算均值/方差/分位数只要常数内存（median 用 P² 在线估计算法，4.17 vs 精确 4.5 就是估计误差）。⭐ 日志分析、监控指标、实时统计的利器。

## 25.5 Boost.Histogram（2018）：工业级直方图

```cpp
auto h = bh::make_histogram(bh::axis::regular<>(10, 0, 1), bh::axis::category<std::string>({...}));
h(85.0, "及格");                     // 多维填充
auto hw = bh::make_weighted_histogram(...);
hw(bh::weight(2.5), 0.5);            // 加权（自带方差跟踪）
```

运行输出（`histogram.cpp`）：

```text
一维计数: bin0=1 bin1=2 bin9=1
二维总计数 = 3
10000 样本: 中心 bin=1309 尾部 bin=26（中心 >> 尾部）
加权 bin 值 = 3（方差 = 6.5）
自检通过
```

CERN 高能物理血统：轴可组合（定宽/变宽/类别/圆形）、支持加权与并行填充、可序列化。⭐ std 无对应，数据分析的 C++ 标准件。

## 25.6 Boost.GIL（2005）：泛型图像

```cpp
gil::rgb8_image_t img(8, 4);
gil::at_c<0>(view(x, y)) = r;                    // 通道访问
auto red = gil::nth_channel_view(view, 0);        // 通道视图
gil::copy_and_convert_pixels(view, gray_view);    // 颜色空间转换
```

运行输出（`gil.cpp`）：

```text
尺寸 = 8×4
(7,3) 处 R=224 B=180
红通道总和 = 3584（(0+..+7)×32×4 行）
灰度 (0,0)=0 (7,0)=67
自检通过
```

**像素类型是编译期概念**——"通道数不匹配"的 bug 在类型系统里就死了。图像算法（卷积、重采样、直方图均衡）在视图层泛型展开、零抽象税。⭐ 图像处理流水线的 C++ 底座（OpenCV 之外的轻量选择）。

## 25.7 Boost.Compute（2014）：OpenCL 的 C++ 嫁衣（GPU 实测）

本机实测链路：CUDA 13.3 的 OpenCL 头 + `OpenCL.lib` + RTX 3060（28 个计算单元）：

```cpp
auto device = compute::system::default_device();      // GPU
compute::vector<float> gpu(n, ctx);
compute::copy(host.begin(), host.end(), gpu.begin(), queue);
compute::transform(gpu.begin(), gpu.end(), gpu.begin(), _1 * _1, queue);   // GPU 平方
float sum = compute::accumulate(gpu.begin(), gpu.end(), 0.0f, queue);      // GPU 归约
```

运行输出（`compute.cpp`，**Windows 侧**：RTX 3060 + CUDA OpenCL）：

```text
设备 = NVIDIA GeForce RTX 3060
计算单元 = 28 个
平方和 = 91（1²+2²+…+6² = 91）
GPU 排序首尾 = 1/6
自检通过
```

**macOS 侧**：没有 CUDA 那套，OpenCL 由系统框架提供（`#include <OpenCL/cl.h>`
——Boost.Compute 自己按 `__APPLE__` 分支，不用改代码），链接写
`-framework OpenCL`。本机（Intel Iris Pro）实测输出：

```text
设备 = Iris Pro
计算单元 = 40 个
平方和 = 91（1²+2²+…+6² = 91）
GPU 排序首尾 = 1/6
自检通过
```

设备名与计算单元数随**机器**变（换台机器就不同，所以文档里这是"本机实测"），
但在同一台机器上两条通道必然拿到同一个设备——因此不用登记进"已知漂量"名单。

STL 算法（transform/sort/accumulate/...）的 GPU 版 + lambda 内核（`_1 * _1` 编译成 OpenCL C）。⭐ 数据并行计算的轻量入口（不想拉 CUDA C++ 全家桶时的选择）。

> 实测坑：总头 `boost/compute.hpp` 会拉进 `random_shuffle.hpp`——用了 C++17 已删除的 `std::random_shuffle`，在 `/std:c++latest` 下直接编不过。**用细分头**（system/context/command_queue/container/vector/algorithm/...）绕开。这是"老库 × 新语言档"的又一现场。

---


> 上一章：[24 · 数值计算](24-numeric.md) ｜ 下一章：[26 · 现代元编程](26-modern-tmp.md) ｜ 返回：[README](../README.md)
