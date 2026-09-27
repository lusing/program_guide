# 32 · 生态与迁移：工具、库、CUDA/SYCL 映射与学习路线

> 本章无示例。参照 OPE 第 1 章（CUDA or OpenCL? 的选择讨论）与 HCL 第 13 章（WebCL——历史注记）。

## 32.1 工具箱

| 工具 | 用途 | 获取 |
|---|---|---|
| [clinfo](https://github.com/Oblomov/clinfo) | 环境/设备全量报告（比 02 章示例细） | scoop/源码 |
| CLU / CLBlast 自带 bench | 带宽/算力基线 | — |
| NVIDIA Nsight Systems / Compute | 时间线 / 内核级调试与剖析 | NVIDIA 免费工具链 |
| Intel VTune | Intel GPU/CPU 混合剖析 | Intel oneAPI 组件 |
| AMD uProf / RGP | AMD 侧 | AMD 驱动套件 |
| [clspy](https://github.com/aconz2/clspy) 类 REPL | 快速试内核 | 源码 |

## 32.2 库：别手写生产内核

| 库 | 领域 |
|---|---|
| **clBlast** | BLAS（GEMM/向量）——19 章的工业版 |
| clFFT | FFT（AMD 系，维护趋缓）——24 章的工业版 |
| Eigen GPU 后代 / ViennaCL | 线性代数 C++ 封装 |
| OpenCV `UMat`/T-API | 图像处理（内部 OpenCL） |
| oneMKL（Intel） | 数学内核库 |

判断标准：计算模式是"教科书算法"（BLAS/FFT/图像滤波）→ 用库；是领域内核（物理模拟、光线求交）→ 手写。

## 32.3 CUDA ↔ OpenCL 概念映射

很多资料以 CUDA 讲 GPU 编程，对照表帮你双语阅读：

| OpenCL | CUDA C++ | 注 |
|---|---|---|
| work-item | thread | |
| work-group | block | |
| NDRange + local size | grid + block dim | |
| sub-group | warp | 32（NVIDIA）|
| `__global` memory | global memory | |
| `__local` memory | `__shared__` | |
| `__constant` | `__constant__` | |
| barrier(CLK_LOCAL_MEM_FENCE) | `__syncthreads()` | |
| sub_group_shuffle | `__shfl_sync` | NVIDIA 有 CUDA 版无 OpenCL 版（27 章实测） |
| kernel printf | printf | 设备 printf 双方都支持 |
| cl_event | cudaEvent / stream 语义 | |
| clCreateProgramWithSource | nvcc 离线编译 | CUDA 无运行时源码编译（NVRTC 除外） |
| SPIR-V | PTX/cubin | 中间层哲学不同 |

核心差异：CUDA 单厂商生态（工具链/库/文档全面优）、离线编译模型；OpenCL 运行时编译、跨厂商但各厂商投入不均（本机实测的 NVIDIA"幽灵扩展"即一例）。

## 32.4 SYCL：OpenCL 的现代上层

SYCL（Khronos）：**单源 C++**（主机/设备代码同一文件同一模板）、免字符串内核、自动依赖图。主流实现：

| 实现 | 背景 |
|---|---|
| Intel oneAPI DPC++ | 最活跃（Intel 主推），底层走 OpenCL L0 |
| AdaptiveCpp（原 hipSYCL） | 多后端（OpenCL/CUDA/HIP） |
| ComputeCpp | Codeplay（商用为主） |

什么时候从 OpenCL C 迁到 SYCL：C++ 工程想要模板化内核与自动内存管理；跨 NVIDIA+AMD+Intel 的单源代码。OpenCL C 本身仍是理解一切底层（本教程的收获）的最佳入口。

## 32.5 历史注记与近况（2026 视角）

- **WebCL**（HCL 第 13 章）：浏览器里的 OpenCL，Firefox 实验扩展随 NPAPI 之死消亡——路线由 WebGPU 接棒；
- **OpenCL 3.0**（2020）之后标准本身进入维护节奏，活力转移到 SYCL/Vulkan compute；
- NVIDIA：支持到 3.0 但无 2.x 特性（无 SVM/subgroups），互操作实测不可用（29 章）；
- Intel：CPU 运行时 3.0 全特性（本机 SPIR-V/subgroups 实测可用）；
- AMD：重心在 ROCm/HIP（OpenCL 支持随版本波动）。

**务实结论**：OpenCL 仍是"一段 C 代码跑在任何厂商硬件上"的唯一开放标准路线，学习它 = 同时学会 CUDA/SYCL 的心智模型（映射表 32.3）。

## 32.6 学习路线图

```
本教程 01-12（基础） ──► 手头项目直接用（图像/信号/模拟任选）
       │
       ├─ 13-17（进阶 API）──► C++ 工程化（opencl.hpp + 事件流水线）
       │
       ├─ 18-25（算法实战）──► clBlast/clFFT 对读，理解库为什么快
       │
       └─ 26-31（深水区）──► 按设备调优 / 多设备调度 / autotune
                │
                └──► SYCL（DPC++）或 CUDA（若锁定 NVIDIA）
```

三本书的续读建议：HCL 补第 3/6 章架构直觉；OiA 补 12–13 章（QR 分解、稀疏矩阵、共轭梯度——数值线代深水区）；OPE 补第 9 章 JPEG 与第 11 章（回归/KNN——数据科学向案例）。

## 32.7 结语

本教程 32 章、30 个实测示例、三本书的地图，全部代码在 NVIDIA CUDA 3.0（RTX 3060）+ Intel OpenCL 3.0（12700F）双平台验证通过。带走三样东西：

1. **主机端八步 + 设备端并行思维**的心智模型；
2. **先探测再使用**的习惯（设备能力、扩展、互操作，处处有"幽灵通告"）；
3. **对拍 + 剖析 + autotune** 的优化循环纪律。

Happy heterogenous computing!
