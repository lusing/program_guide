# OpenCL Windows 平台开发教程（3.0）

面向**会 C/C++、初学 GPU 异构计算**的读者：从环境搭建教到实战优化——主机端八步、设备端并行思维、事件流水线、五大经典算法（归约/矩阵乘法/双调排序/卷积/直方图/FFT）、多设备并行与图形互操作。每章"读讲解 → 跑示例 → 改代码再跑"，全部 30 个示例在本机双平台实测（编译 + 运行 + 数值断言，末尾必须 `PASS`）。

按三本书的地图扩充（详见 [01 章](docs/01-overview.md)）：《OpenCL 异构计算》（HCL，理论+案例）、*OpenCL in Action*（OiA，API 系统教程）、*OpenCL Programming by Example*（OPE，工程细节）。三篇结构：**基础篇 02–12**（环境→主机端对象→内核语言）+ **进阶篇 13–24**（事件/剖析/图像/SPIR-V/C++/算法）+ **实战篇 25–32**（粒子模拟/多设备/扩展/调试/互操作/性能）。

> 本机实测环境：**NVIDIA CUDA 平台**（RTX 3060，OpenCL 3.0 CUDA 13.3，无 SPIR-V/fp16/subgroups）+ **Intel OpenCL 平台**（i7-12700F CPU，OpenCL 3.0，SPIR-V 1.0–1.4/subgroups 全有）——两台能力互补的设备贯穿全书做活对照。所有坑位清单来自实测（如 BufferRect 的"行单位"静默越界、锁不加 volatile 丢更新、SPIR-V 里 size_t 索引卡死 Intel 运行时、NVIDIA 互操作"幽灵通告"等，详见各章）。

## 目录结构

```text
OpenCL/
├── README.md          本文件
├── docs/              32 章教程（01 → 32 顺序阅读）
├── examples/          30 个示例目录（章号 = 目录号；common/ 放共用头与 vendored opencl.hpp）
├── build.ps1          统一构建验证脚本（须 PowerShell 7 / pwsh）
└── CHEATSheet.md      API 速查 + 坑位索引
```

## 章节索引

**基础篇（02–12）**

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 异构计算、三书地图、版本史、本机实测环境 | — |
| [02 环境搭建](docs/02-environment.md) | ICD 架构、三条安装路线、VS/CMake 配置 | `02_envcheck` |
| [03 第一个程序](docs/03-hello.md) | 向量加法全流程、错误处理纪律 | `03_hello` |
| [04 平台与设备](docs/04-devices.md) | 四类查询形态、cl_name_version 数组 | `04_deviceinfo` |
| [05 上下文与队列](docs/05-context-queue.md) | 引用计数实验、队列属性、同步三板斧 | `05_context_queue` |
| [06 程序与内核](docs/06-programs.md) | build 选项、编译日志、多段源码 | `06_build_options` |
| [07 缓冲区](docs/07-buffers.md) | 标志全家桶、map、子缓冲区、BufferRect 行单位坑 | `07_buffer_ops` |
| [08 执行模型](docs/08-ndrange.md) | NDRange、坐标恒等式、边界守卫 | `08_ndrange` |
| [09 内存模型](docs/09-memory-model.md) | 四级地址空间、一致性 | `09_address_spaces` |
| [10 数据类型](docs/10-data-types.md) | 向量/swizzle、as/convert、fp64 条件启用 | `10_vector_types` |
| [11 内建函数](docs/11-builtins.md) | 数学/整数/shuffle/select/几何 | `11_builtin_funcs` |
| [12 同步](docs/12-synchronization.md) | barrier 实验、原子、volatile 互斥锁坑 | `12_barrier_atomics` |

**进阶篇（13–24）**

| 章 | 主题 | 示例 |
|---|---|---|
| [13 事件](docs/13-events.md) | wait list 流水线、用户事件闸门、回调 | `13_events` |
| [14 剖析](docs/14-profiling.md) | 四时间戳、传输 vs 计算时间线 | `14_profiling` |
| [15 图像](docs/15-images.md) | 格式/采样器、插值语义两大实测坑 | `15_images` |
| [16 二进制与 SPIR-V](docs/16-binary-spirv.md) | binary 缓存、SPIR-V（含 size_t 卡死坑） | `16_binary_spirv` |
| [17 C++ 绑定](docs/17-cpp-bindings.md) | opencl.hpp RAII/异常/惯用法 | `17_cpp_vecadd` |
| [18 归约](docs/18-reduction.md) | 两级树形、float4 向量化（2.3x） | `18_reduction` |
| [19 矩阵乘法](docs/19-matmul.md) | naive → tiled（755→970 GFLOP/s） | `19_matmul` |
| [20 双调排序](docs/20-sorting.md) | 比较网络、方向位绑定 stage 的坑 | `20_bitonic` |
| [21 卷积](docs/21-convolution.md) | 边界策略、local tile + halo | `21_convolution` |
| [22 直方图](docs/22-histogram.md) | 全局原子 vs 本地攒桶（7.15x） | `22_histogram` |
| [23 图像滤镜](docs/23-image-filters.md) | 均值/高斯/Sobel（image 路线） | `23_filters` |
| [24 FFT](docs/24-fft.md) | 迭代 radix-2 蝶形、频谱验证 | `24_fft` |

**实战篇（25–32）**

| 章 | 主题 | 示例 |
|---|---|---|
| [25 N 体模拟](docs/25-nbody.md) | 双缓冲、守恒律验证（63G 交互/s） | `25_nbody` |
| [26 多设备并行](docs/26-multi-device.md) | GPU+CPU 分块同算 | `26_multidevice` |
| [27 扩展机制](docs/27-extensions.md) | 查询/启用、subgroup 正确查法 | `27_extensions` |
| [28 调试](docs/28-debugging.md) | 错误注入、内核 printf、坑位总表 | `28_debug` |
| [29 D3D11 互操作](docs/29-d3d-interop.md) | 完整路线 + 幽灵扩展实测 + staging 桥接 | `29_d3d11` |
| [30 性能模型](docs/30-perf-model.md) | SIMT、合并访问（106 GB/s 实测） | `30_coalescing` |
| [31 优化方法论](docs/31-optimization.md) | autotune 实验台、基准纪律 | `31_autotune` |
| [32 生态与迁移](docs/32-ecosystem.md) | 工具/库、CUDA↔OpenCL 映射、SYCL | — |

## 构建工具链

要求：**PowerShell 7（pwsh）**、MSVC（VS 2022+ 的 vcvars64）、OpenCL 头与导入库（默认按 CUDA Toolkit 路径配置，可在 `build.ps1` 顶部改三行变量）。C++ 绑定头已 vendor（`examples/common/CL/opencl.hpp`，Khronos OpenCL-CLHPP）；16 章 SPIR-V 预编译需要 MSYS2 clang（找不到自动走 SKIP 分支）。

```powershell
pwsh build.ps1 -All          # 编译并运行全部示例（PASS 判定）
pwsh build.ps1 -Chapter 03   # 单章
pwsh build.ps1 -List         # 列出全部示例
pwsh build.ps1 -Clean        # 清理
```

验证标准：退出码 0、输出含 `PASS`、无 `FAIL` 行；日志落 `build/logs/`。

## 参考书目

- 《OpenCL 异构计算》（B. Gaster 等，中文版）——并行思维与案例研究（教程简称 HCL）
- Matthew Scarpino, *OpenCL in Action*（Manning）——API 与算法系统教程（OiA）
- R. Banger & K. Bhattacharyya, *OpenCL Programming by Example*（Packt）——工程细节（OPE）
- Khronos 规范：<https://registry.khronos.org/OpenCL/>（clGetDeviceInfo 参考页等）
