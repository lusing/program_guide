# 01 · 全景：OpenCL 是什么、三本参考书怎么用、你的机器上有什么

## 1.1 异构计算与 OpenCL 的位置

CPU 擅长控制密集型任务（分支预测、乱序执行、大缓存），GPU 擅长数据密集型任务（几千个线程同时算同样的事）。**异构计算**就是让合适的活干合适的事：主机端 C 程序负责流程与 IO，设备端内核负责大规模并行数值计算。

OpenCL（Open Computing Language）是 Khronos Group 维护的**开放异构并行计算标准**，2008 年 12 月发布 1.0。它一次性定义了四样东西：

| 组成 | 内容 |
|---|---|
| 平台 API | 枚举平台/设备、创建上下文与命令队列（C 函数，`clGetPlatformIDs` 一族） |
| 运行时 API | 提交内核、搬运数据、事件同步（`clEnqueue*` 一族） |
| 内核语言 OpenCL C | C99 子集 + 向量类型 + 地址空间限定符 + 并行内建函数 |
| 数值要求 | IEEE-754 精度边界（`-cl-fast-relaxed-math` 等编译选项定义放宽程度） |

与同类技术对比（见 32 章展开）：

| 技术 | 厂商绑定 | 语言 | 现状（2026） |
|---|---|---|---|
| **OpenCL** | 开放（Khronos） | OpenCL C / SPIR-V | 3.0；NVIDIA/Intel 维护中，AMD 主推 ROCm/HIP |
| CUDA | NVIDIA 专属 | CUDA C++ | 迭代活跃，生态最大 |
| DirectCompute/HLSL | Microsoft | HLSL | 融入 DirectX 12 |
| Metal | Apple | Metal Shading Language | macOS 唯一推荐路线 |
| SYCL | 开放（Khronos） | C++ 单源 | oneAPI/DPC++ 兴起，OpenCL 的现代上层 |

## 1.2 三本参考书与本教程的分工

本教程按三本经典书籍的地图扩充，各有侧重：

| 简称 | 书 | 特长 | 对应章节 |
|---|---|---|---|
| **HCL** | 《OpenCL 异构计算》（Gaster 等，中文版） | 并行思维、执行/内存模型、案例研究（卷积/直方图/粒子模拟）、剖析调试 | 08/09、21–25、14/28 |
| **OiA** | *OpenCL in Action*（Scarpino） | 主机端 API 与内核语言最系统的逐条讲解、算法篇（归约/排序/FFT/矩阵） | 03–13、18/19/20/24 |
| **OPE** | *OpenCL Programming by Example*（Banger & Bhattacharyya） | 缓冲区/图像/程序对象细节、优化案例、图像处理与 JPEG、GL 互操作 | 07/15/16、19/22/23、29 |

读法建议：**本教程为主线（每章都能跑），HCL 补理论直觉，OiA 当 API 手册查，OPE 看工程化细节**。

## 1.3 版本演进：一张表看清 1.0 → 3.0

| 版本 | 年份 | 关键特性 | 现实状态 |
|---|---|---|---|
| 1.0 | 2008 | 平台/上下文/内核/缓冲区/图像 | 历史基线 |
| 1.1 | 2010 | 用户事件、子缓冲区 | 基本无人单独用 |
| **1.2** | 2011 | 设备分区、自定义设备、内建内核、`clCompileProgram`/`clLinkProgram`、DX9 媒体共享 | **最通用的兼容目标** |
| 2.0 | 2013 | SVM、设备端队列、管道、C11 原子 | **NVIDIA 从未实现**（本机实测 NVIDIA 只报 C 1.0/1.1/1.2/3.0） |
| 2.1 | 2015 | SPIR-V 中间语言内核 | 短命 |
| 2.2 | 2017 | OpenCL C++ 内核语言 | 几乎无实现 |
| **3.0** | 2020 | "2.x 特性全部改为可选 + 扩展暴露"，向后兼容 1.2 | 当前版本；NVIDIA/Intel 均已支持 |

> ⚠️ 3.0 的设计哲学：**核心 = 1.2，其余一切可选**。所以"支持 OpenCL 3.0"不等于支持 SVM/管道/设备端队列——要靠逐项查询（4 章的 `cl_name_version` 数组与特性宏查询就是干这个的）。NVIDIA 跳过整个 2.x 直接到 3.0 是常态而非例外。

## 1.4 本教程的实测环境

所有示例在下列环境编写、编译、运行、断言（每章示例最后打印 `PASS`，由 `build.ps1` 统一验证）：

| 组件 | 实测值 |
|---|---|
| OS | Windows 11（10.0.26200），PowerShell 7 |
| 编译器 | MSVC（VS 2026 / 18.x，`cl.exe` via vcvars64） |
| OpenCL 头/导入库 | CUDA Toolkit 13.3 自带（`G:\cuda\v13.3\include\CL`、`lib\x64\OpenCL.lib`，头文件为 OpenCL 3.0 版） |
| 平台 1 | **NVIDIA CUDA**，OpenCL 3.0 CUDA 13.3.71，RTX 3060（28 CU、48KB local、1024 max WG、C 1.0–1.2 + 3.0，**无 SPIR-V、无 fp16、无 subgroups**） |
| 平台 2 | **Intel(R) OpenCL**，OpenCL 3.0 WINDOWS，i7-12700F CPU（20 CU、256KB local、8192 max WG、C 3.0，**SPIR-V 1.0–1.4、fp16、subgroups 家族齐全**） |
| SPIR-V 编译器 | MSYS2 UCRT64 clang 22.1.8（`-target spirv64`；scoop 版 clang 23 无 SPIRV 后端） |

两台设备能力差异极大，反而成了最好的教具：多平台选择（26 章）、SPIR-V 有无（16 章）、subgroup 可用性（27 章）都有真实对照。

## 1.5 一个 OpenCL 程序长什么样

主机端（C）与设备端（OpenCL C 内核）分工：

```c
/* 主机端：搭台 -> 传数据 -> 收结果（03 章逐行讲解） */
const char* src = "__kernel void vec_add(__global const float* a,        \n"
                  "                     __global const float* b,        \n"
                  "                     __global float* c) {            \n"
                  "    int i = get_global_id(0);  /* 我是第几个工作项 */ \n"
                  "    c[i] = a[i] + b[i];                              \n"
                  "}";
/* clGetPlatformIDs -> clGetDeviceIDs -> clCreateContext
   -> clCreateCommandQueueWithProperties -> clCreateProgramWithSource
   -> clBuildProgram -> clCreateKernel -> clCreateBuffer
   -> clSetKernelArg -> clEnqueueNDRangeKernel -> clEnqueueReadBuffer */
```

关键心智模型（5 章起逐一展开）：

```
Platform（厂商实现，ICD 里一个 DLL）
 └─ Device（GPU/CPU/加速器）
     └─ Context（内存对象的作用域）
         ├─ Command Queue（按序向设备提交命令）
         │    ├─ 数据传输命令（read/write/map/copy）
         │    └─ 内核执行命令（NDRange）
         ├─ Program（内核源码/二进制/SPIR-V 的容器）
         │    └─ Kernel（程序里一个可执行函数 + 参数绑定）
         └─ Memory Objects（buffer / image）
```

## 1.6 目录

- 基础篇（02–12）：环境 → 第一个程序 → 主机端六大对象 → 内核语言
- 进阶篇（13–24）：事件/剖析 → 图像 → 二进制与 SPIR-V → C++ 绑定 → 五大经典算法（归约/矩阵乘法/排序/卷积/直方图/FFT）
- 实战篇（25–32）：粒子模拟 → 多设备 → 扩展 → 调试 → 图形互操作 → 性能模型 → 优化方法论 → 生态

> 下一章：[02 环境搭建](02-environment.md)——ICD 架构与三条安装路线，装完跑 `02_envcheck`。
