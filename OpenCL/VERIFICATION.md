# 多机验证台账

本教程的每一条能力声明都要落在一台真实的机器上。这个文件是**验证台账**：每台机器一节，
记录硬件档案、当日全量运行结果、该机特有的实测发现。换机器验证时**追加新节，不改历史节**——
历史节是当时的记录，机器和驱动都会变，台账的价值恰恰在于保留差异。

`build/logs/` 是生成物不入库，所以每次全量运行的关键读数摘录进本文件；完整日志在运行
那台机器的 `build/logs/` 下。设备能力基线（平台/设备表）由 `tools/clinfo-probe` 产出，
正文引用的那张表在 [docs/01-opencl-overview.md 1.5 节](./docs/01-opencl-overview.md#15-本机实测基线)。

## 1. 复现方法（所有机器相同）

```powershell
cd tools\clinfo-probe; .\build.ps1     # 设备基线探针（编译 + 运行）
cd ..\..
pwsh build.ps1                         # 全部示例：增量编译 + 运行 + 判定
pwsh build.ps1 -Rebuild                # 强制全量重编
pwsh build.ps1 -Examples 02-vector-add # 单个示例
pwsh build-spirv.ps1                   # SPIR-V 三路由（无工具链自动降级说明）
```

判定规则（`build.ps1` 头注释为准）：退出码 0、输出含 `PASS`、无显式 `[RESULT] FAIL`。
逐设备的 `[FAIL] ...` **诊断行不算失败**——`11-ocl3-features` 按设计打印它们，
末尾仍是 `[RESULT] PASS`。`[RESULT] SKIP` 按绿处理（与 `build-spirv.ps1` 的独立性设计一致）。

Windows PowerShell 5.1 与 pwsh 7 都必须能跑通 `build.ps1` 全链路（脚本因此纯 ASCII，
见 [docs/02-environment-setup.md 2.10](./docs/02-environment-setup.md#210-windows-命令行陷阱)）。

## 2. 机器 #1 —— 本机（2026-10-04 全量验证）

### 2.1 硬件与系统

| 项 | 值 |
|---|---|
| 整机 | HASEE Computer N9x0TD_TF |
| OS | Windows 11 Home 10.0.26200 |
| CPU | Intel Core i7-9700 @ 3.00 GHz（8 核 8 线程） |
| 内存 | 16 GB |
| 独显 | NVIDIA GeForce RTX 2060 6 GB（驱动 610.88） |
| 核显 | Intel UHD Graphics 630（驱动 31.0.101.2140，NEO） |

### 2.2 OpenCL 平台/设备（clinfo-probe 实测，3 平台 3 设备）

| 设备 | 平台 | 设备版本 | OpenCL C | IL/SPIR-V | CU | local mem | 子组 | SVM |
|---|---|---|---|---|---|---|---|---|
| RTX 2060 | NVIDIA CUDA | 3.0 CUDA 13.3.80 | 1.2 | **无** | 30 | 48 KiB（CL_LOCAL） | 无 | 仅 coarse |
| **UHD 630**（教程主目标） | Intel OpenCL HD Graphics | 3.0 NEO | 1.2 | SPIR-V 1.2 | 24 | 64 KiB（CL_LOCAL） | 有 | coarse+fine+atomics（0xB） |
| i7-9700 | Intel OpenCL | 3.0 | **3.0** | SPIR-V 1.0–1.4 | 8 | 256 KiB（**CL_GLOBAL**） | 有 | 全部（0xF，含 system） |

完整表（max_work_item_sizes、max_mem_alloc、扩展计数等）见
[docs/01 1.5 节](./docs/01-opencl-overview.md#15-本机实测基线)（2026-09-17 实测，与本次一致）。

### 2.3 工具链（构建脚本自动发现，实际解析结果）

| 组件 | 解析结果 |
|---|---|
| vcvars64 | VS 2026（18）Community，vswhere → `d:\Program Files\...\18\Community`（`G:\` 有同版本并存） |
| OpenCL SDK | `D:\cuda\13.3`（CUDA 13.3.1；与 `CUDA_PATH=D:\scoop\apps\cuda\current` 的 `cl.h` MD5 相同） |
| SPIR-V clang | oneAPI DPC++/C++ 2025.3.2（`D:\oneAPI\compiler\latest\bin\compiler\clang.exe` + `llvm-spirv.exe`） |
| spirv-val / spirv-dis | Vulkan SDK 1.4.335.0（PATH） |
| CMake | 4.4.4（`find_package(OpenCL)` 闭环通过） |
| ICD 加载器 | Khronos `C:\Windows\System32\OpenCL.dll` 3.0.6.0 |
| Shell | pwsh 7.6.6；Windows PowerShell 5.1 全链路亦实测通过 |

注册表只登记一个 ICD（`intelocl64.dll`），NVIDIA 的在 DriverStore——细节与教训见
[docs/02 2.2 节](./docs/02-environment-setup.md#22-本机运行时实况注册表说的和设备列表说的不一致)。

### 2.4 `build.ps1` 全量结果：41/41 通过（2026-10-04）

统一脚本覆盖两代示例：`01-`…`11-`（现教程，11 个，目标设备 UHD 630）+ `02_`…`31_`
（历史章，30 个，默认设备 RTX 2060）。退出码 0，无 FAIL。

**现教程（11 个）**

| 示例 | 判定 | 本机关键读数 |
|---|---|---|
| 01-device-query | OK | 3 平台枚举；按名选设备 vs `platforms[0]` 反例注记 |
| 02-vector-add | OK | 数值断言通过 |
| 03-matmul-naive | OK | 256×256，65536/65536 与 CPU 参考一致，最大误差 0 |
| 04-matmul-tiled | OK | 反例 TILE=32（1024 工作项 > 上限 256）被 -54 拒；正例 TILE=16 通过 |
| 05-reduce-sum | OK | 非二次幂 local=100 静默丢值演示（2559 ≠ 3997）+ 正确两级归约 |
| 06-image-brightness | OK | 60 种 2D 读格式枚举；RGBA/CL_FLOAT 可用、CL_ARGB 不可 |
| 07-async-events | OK | 队列属性 0x3（乱序+剖析）；阻塞/非阻塞/事件 DAG 三案例 |
| 08-cpp-bindings | OK | cl.hpp 三种构造、RAII 引用计数往返、跨示例加载 IL 模块 |
| 09-spirv-il | OK | SPIR-V **1.4** 模块在标称 1.2 的 UHD 上加载+运行，1024/1024 正确；NVIDIA 拒绝 IL（-59，正确行为）；IL 读回与文件逐字节一致 |
| 10-multi-device | OK | 3 设备各建上下文；2 Mi 元素 × 32 轮哈希分块合并 |
| 11-ocl3-features | OK | 4 特性 × 3 设备门控矩阵，9 项数值验证；发现见 2.6 |

**历史章（30 个）**

| 示例 | 判定 | 本机关键读数（默认设备 RTX 2060） |
|---|---|---|
| 02_envcheck | OK | 3 平台/3 设备能力矩阵 |
| 03_hello | OK | 向量加法数值校验 |
| 04_deviceinfo | OK | OPENCL_C_ALL_VERSIONS 4 项、FEATURES 4 项、扩展 26 个 |
| 05_context_queue | OK | 引用计数 create=1/retain=2/release=1；profiling 队列位 |
| 06_build_options | OK | 选项回显；坏内核 CL_BUILD_PROGRAM_FAILURE + 日志 |
| 07_buffer_ops | OK | 子缓冲 offset=512/size=1024；BufferRect 行读取 |
| 08_ndrange | OK | 坐标恒等式、global offset、边界守卫 |
| 09_address_spaces | OK | constant：max_args=9、64 KiB |
| 10_vector_types | OK | swizzle、位重释、sat 转换、fp64 全验证 |
| 11_builtin_funcs | OK | math/int/vec 三组 0 mismatch |
| 12_barrier_atomics | OK | atomic_add 4096 精确；互斥锁和正确；xchg 初值恰现一次 |
| 13_events | OK | wait list 流水线、用户事件闸门（NVIDIA 报 3）、回调触发 |
| 14_profiling | OK | write ~7.7 GB/s、read ~7.3 GB/s（32 MB） |
| 15_images | OK | 32768² 上限、75 读写格式、copy 像素精确、插值语义 |
| 16_binary_spirv | OK | binary 1117 B 落盘重载验证；SPIR-V 段走 SKIP 分支（NVIDIA 无 IL） |
| 17_cpp_vecadd | OK | kernel 0.012 ms；map 32768 值一致 |
| 18_reduction | OK | 标量两级 / 向量化 3.3x / 原子 int 总数精确 |
| 19_matmul | OK | naive 280.1 → tiled 440.8 GFLOP/s（1.6x）；CPU 单线程 433.6 ms |
| 20_bitonic | OK | 升序有序且与 qsort 结果一致 |
| 21_convolution | OK | direct 0.016 ms / local 0.013 ms（1.28x） |
| 22_histogram | OK | global 2.556 ms / local 0.359 ms（**7.12x**） |
| 23_filters | OK | mean/gauss/sobel 数值验证 + PGM 输出 |
| 24_fft | OK | FFT vs DFT 误差 < 5e-3；共轭对称 0 |
| 25_nbody | OK | 4096 体 × 20 步 0.49 ms/步，~33.9 G 交互/s；动量守恒抽查 |
| 26_multidevice | OK | NVIDIA 0.05 ms + UHD 0.36 ms 分块同算合并 |
| 27_extensions | OK | 扩展字符串与 WITH_VERSION 计数一致（26=26）；fp16/子组如实缺席 |
| 28_debug | OK | 错误注入 5/7 返回规范错误码、2 处驱动宽松（如实记录） |
| 29_d3d11 | OK | 互操作幽灵通告（-59）→ staging 桥接数值验证 |
| 30_coalescing | OK | 合并 1D 55.3 GB/s；行和 47.3；列和 31.8 |
| 31_autotune | OK | 最优 local=128（0.352 ms / 190.6 GB/s） |

### 2.5 `build-spirv.ps1`（2026-10-04）：三路由全 OK

| 路由 | 模块 | 结果 |
|---|---|---|
| backend（clang SPIR-V 后端） | 1416 B，SPIR-V **1.4**，tool 21 | spirv-val 通过 |
| translator（-emit-llvm \| llvm-spirv --max-version=1.2） | 1864 B，SPIR-V **1.0**，tool 14 | spirv-val 通过 |
| cpp（-cl-std=CLC++） | 1416 B，SPIR-V 1.4 | spirv-val 通过；与 C 路由反汇编**仅差 1 条 OpSource** |

### 2.6 本机特有发现（其他机器对照重点）

1. **NVIDIA SVM coarse-grained 名不副实**（11 章 diagnostic 证实）：通告 yes、内核确实执行
   （普通 buffer 半边 1024/1024 正确）、SVM store 对主机不可见。教训：按查询门控**并且**
   验证第一个结果。
2. **NVIDIA D3D11 互操作幽灵通告**（29 章）：`cl_khr_d3d11_sharing` 在列、入口点可取，
   `CL_D3D11_DEVICE_KHR` 枚举返回 -59。staging 桥接兜底通过。
3. **NVIDIA 无 IL**：09/16 章的 SKIP 分支在这台机器是真实走到的分支。
4. **UHD 标称 SPIR-V 1.2，实际接受 1.4 模块**（09 章实测：加载、构建、运行、读回全通过）。
   规范允许拒绝，驱动选择宽容——依赖这一点是不可移植的。
5. **to_global() 在 NVIDIA 未通告但可用**（11 章 NOTE：设备可以做得比承诺多）。
6. 注册表单 ICD vs 三平台（docs/02 2.2）、PowerShell 5.1 参数点号切分（docs/02 2.10）等
   环境级坑在本机全部复现过。

### 2.7 CMake 路线（docs/02 2.7 复验，2026-10-04）

CMake 4.4.4 + VS 2026 生成器：configure（`Found OpenCL: D:/scoop/apps/cuda/current`，
version 3.0）→ build → run：`clGetPlatformIDs -> 0, numPlatforms = 3`，exit 0。

## 3. 机器 #0 —— 历史机（旧篇性能数字来源，未在本轮复验）

README 早期版本记载的环境：**RTX 3060 + i7-12700F，双平台**（NVIDIA CUDA 13.3 +
Intel CPU OpenCL 3.0，**无核显**）。旧篇（`02_`…`31_` 配套的 32 章文档）中的性能数字
（如 matmul 755→970 GFLOP/s）在该机测得；机器 #1 复测为 280→441（RTX 2060），
**量级结论（tiled 优于 naive）不变，绝对值以机器为准**。该机已不在手边，本节仅作数字溯源。

## 4. 新机器模板

验证一台新机器时复制 2.x 的结构追加为"机器 #N"，至少包含：

1. **硬件与系统**：机型、OS 版本、CPU、内存、GPU（独显/核显，驱动版本）。
2. **平台基线**：`tools/clinfo-probe` 输出的平台/设备表（照抄关键列：OpenCL C 版本、
   IL/SPIR-V、CU、local mem、子组、SVM）。
3. **工具链解析**：`build.ps1` 开头打印的 vcvars64 / OpenCL SDK / clang 三行，
   以及是否走了 `OPENCL_ROOT` 覆盖。
4. **全量结果**：`pwsh build.ps1` 的判定数（N/N 通过）+ 每示例一行关键读数；
   有 SPIR-V 工具链则附 `build-spirv.ps1` 汇总。
5. **特有发现**：这台机器与已有机器行为不同的地方（幽灵通告、名不副实的能力、
   SKIP 分支是否走到、性能倒挂等）。日期一律用绝对日期。

若新机设备名不含 `UHD`：改 `examples/common/ocl_util.h` 的 `OCL_DEFAULT_DEVICE`
或给 `cl-build-probe` 传 deviceHint（docs/02 2.11），**不要**改成取 `platforms[0]`。
