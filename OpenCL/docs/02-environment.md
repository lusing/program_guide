# 02 · 环境搭建：ICD 架构、三条安装路线、编译配置

## 2.1 Windows 上的 OpenCL 是怎么装起来的

OpenCL 在 Windows 上的运行时由三层组成，理解了这张图，所有安装问题都能自己诊断：

```
你的程序 (opencl_app.exe)
   │ 链接 OpenCL.lib（导入库，只含跳板代码）
   ▼
OpenCL.dll  ──── ICD Loader（Khronos 提供，随驱动/OCL-SDK 分发）
   │ 运行时查注册表：HKLM\SOFTWARE\Khronos\OpenCL\Vendors
   │     "nvopencl64.dll" = "C:\Windows\System32\..."
   │     "intelocl64.dll" = ...
   ▼
各厂商 ICD（真正的实现）
   ├─ nvopencl64.dll   （NVIDIA 驱动自带 → "NVIDIA CUDA" 平台）
   ├─ intelocl64.dll   （Intel CPU/GPU 运行时 → "Intel(R) OpenCL" 平台）
   └─ amdocl64.dll     （AMD 驱动 → "AMD Accelerated Parallel Processing" 平台）
```

三个推论：

1. **装显卡驱动 = 装好 OpenCL 运行时**。NVIDIA/AMD/Intel 的显卡驱动都自带自家 ICD，不需要单独"装 OpenCL"。
2. `OpenCL.dll` / `OpenCL.lib` / 头文件三者只需要一份，与有几个厂商无关——ICD Loader 会枚举注册表里所有厂商。
3. `clGetPlatformIDs` 返回几个平台，取决于装了几个厂商的驱动。本机实测 2 个（NVIDIA CUDA + Intel OpenCL）。

> **CPU 上跑 OpenCL**：Intel CPU 运行时历史上随 oneAPI 分发（"Intel CPU Runtime for OpenCL"）；AMD 的 CPU 设备随驱动。若只有 NVIDIA 显卡，也可以用 PoCL（Portable Computing Language）补一个 CPU 平台。

## 2.2 头文件与库的三条获取路线

| 路线 | 头文件 | OpenCL.lib | 适合 |
|---|---|---|---|
| **A. CUDA Toolkit**（本教程主线） | `<CUDA>\include\CL\cl.h`（3.0 版全套，含 `cl_gl.h`/`cl_d3d11.h` 等） | `<CUDA>\lib\x64\OpenCL.lib` | 已装 CUDA 的机器，零额外操作 |
| **B. Khronos 官方** | [OpenCL-Headers](https://github.com/KhronosGroup/OpenCL-Headers) + [OpenCL-ICD-Loader](https://github.com/KhronosGroup/OpenCL-ICD-Loader)（或 [OpenCL-SDK](https://github.com/KhronosGroup/OpenCL-SDK)） | 自己编译 icd loader 得到 | 干净、版本最新（3.0+） |
| **C. 厂商 SDK**（OCL-SDK / oneAPI） | 老式 OCL-SDK 1.2 头 | 附带 | 不推荐，版本陈旧 |

> ⚠️ **C++ 绑定头要单独拿**：CUDA 只带旧式 `CL/cl.hpp`（CL_HPP 目标 2.0）；现代的 `CL/opencl.hpp`（即 `cl2.hpp` 后继）来自 [OpenCL-CLHPP](https://github.com/KhronosGroup/OpenCL-CLHPP)，单头文件、header-only。本教程把它 vendor 在 `examples/common/CL/opencl.hpp`（main 分支），17 章直接可用。

验证安装的顺序：

```powershell
# 1) 有没有 OpenCL.dll
Test-Path C:\Windows\System32\OpenCL.dll

# 2) 平台枚举（本教程 02 示例就是迷你 clinfo）
pwsh build.ps1 -Chapter 02

# 3) 全量报告可用第三方 clinfo（scoop install clinfo-mc 或 GitHub Oblomov/clinfo）
```

## 2.3 Visual Studio 工程配置

空项目（C++）→ 项目属性（x64！）：

1. **C/C++ → 常规 → 附加包含目录**：`G:\cuda\v13.3\include`（或你的头文件路线）
2. **链接器 → 常规 → 附加库目录**：`G:\cuda\v13.3\lib\x64`
3. **链接器 → 输入 → 附加依赖项**：`OpenCL.lib`
4. 想吃 C++ 绑定：再加 `examples\common` 到包含目录，源码里 `#include <CL/opencl.hpp>`

坑位：

- 平台必须选 **x64**——装的是 64 位驱动，链接 32 位库会得到 `LNK2019`。
- `CL_TARGET_OPENCL_VERSION` 不定义时头文件默认 300（OpenCL 3.0），旧教程默认 120。显式定义最稳：`/DCL_TARGET_OPENCL_VERSION=300`。
- 用了 `CL/cl2.hpp` 或老代码里的 `clCreateCommandQueue`（1.x API）需要 `CL_USE_DEPRECATED_OPENCL_1_2_APIS`，新代码别走回头路（5 章）。

## 2.4 命令行编译与 CMake

命令行（本教程 `build.ps1` 的实际姿势，`vcvars64.bat` 先进环境）：

```bat
cl /nologo /utf-8 /DCL_TARGET_OPENCL_VERSION=300 /W3 main.c ^
   /I"G:\cuda\v13.3\include" ^
   /link /LIBPATH:"G:\cuda\v13.3\lib\x64" OpenCL.lib
```

CMake（跨平台写法，Windows 上 `OpenCL_ROOT` 指到驱动/SDK 目录）：

```cmake
cmake_minimum_required(VERSION 3.10)
project(opencl_demo C)
find_package(OpenCL REQUIRED)
add_executable(demo main.c)
target_link_libraries(demo PRIVATE OpenCL::OpenCL)
```

> CMake 的 `FindOpenCL` 找的是 `OpenCL_ROOT`、`OCL_ROOT` 等环境变量或注册表；CUDA 装的 OpenCL 头不在默认搜索路径时，`set(OpenCL_ROOT "G:/cuda/v13.3")` 显式给。

## 2.5 示例：02_envcheck（迷你 clinfo）

`examples/02_envcheck/main.c` 打印装机判定所需的全部信息：

```
found 2 platform(s)
[platform 0] NVIDIA CUDA
  vendor=NVIDIA Corporation version=OpenCL 3.0 CUDA 13.3.71 profile=FULL_PROFILE
  <device 0> NVIDIA GeForce RTX 3060  [GPU]
    version=OpenCL 3.0 CUDA driver=610.60
    OpenCL C : OpenCL C 1.2
    IL/SPIR-V: (none)
    compute units=28  global mem=12287 MB  local mem=48 KB
    fp64=1 fp16=0 il_program=0 subgroups=0 d3d11=0 gl=1
[platform 1] Intel(R) OpenCL
  ...
    OpenCL C : OpenCL C 3.0
    IL/SPIR-V: SPIR-V_1.0 SPIR-V_1.1 SPIR-V_1.2 SPIR-V_1.3 SPIR-V_1.4
    compute units=20  global mem=16171 MB  local mem=256 KB
    fp64=1 fp16=1 il_program=1 subgroups=0 d3d11=0 gl=0
02 envcheck PASS
```

读表要点：

- **`CL_DEVICE_IL_VERSION` 是字符串**；长度为 1（只剩 NUL）就是"不支持 IL/SPIR-V"——NVIDIA 平台即如此，16 章 SPIR-V 只能在 Intel CPU 平台演示。
- `fp16`（cl_khr_fp16）、`subgroups` 家族：同一台机器两家一个有一个没有，27 章的处理套路是**运行时逐项探测**。
- `FULL_PROFILE` vs `EMBEDDED_PROFILE`：桌面实现都是 FULL。

## 2.6 本教程的构建入口

```powershell
pwsh build.ps1 -All        # 编译并运行全部 30 个示例（每个末尾必须 PASS）
pwsh build.ps1 -Chapter 03 # 只跑某一章
pwsh build.ps1 -List       # 列出全部示例
pwsh build.ps1 -Clean      # 清理 build/
```

约定：

- 示例目录 = 章号（`03_hello`、`16_binary_spirv`…），`main.c` 或 `main.cpp`；
- **示例内文件读写一律相对路径**（工作目录即示例目录）——中文路径 + C 运行时 `fopen` 的坑见 16 章坑位清单；
- 16 章会在构建时自动调 MSYS2 clang 预编译 SPIR-V（找不到则示例走 SKIP 分支，仍然 PASS）。

> 下一章：[03 第一个程序](03-hello.md)——向量加法从平台到读回的完整 14 步。
