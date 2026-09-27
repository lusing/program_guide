# 16 · 程序二进制与 SPIR-V：缓存、离线编译、IL 路线

> 对应示例 `examples/16_binary_spirv/main.c` + `kernel_spirv.cl`。参照 OPE 第 5 章（Creating binary files / SPIR）。

## 16.1 三条路线回顾与本机的有无

| 路线 | 入口 | NVIDIA RTX 3060（本机） | Intel 12700F CPU（本机） |
|---|---|---|---|
| 源码 | `clCreateProgramWithSource` | ✓ | ✓ |
| 设备二进制 | `clCreateProgramWithBinary` | ✓（dump 实测 1117 字节轻量产物） | ✓ |
| IL / SPIR-V | `clCreateProgramWithIL` | **✗**（`CL_DEVICE_IL_VERSION` 为空） | ✓ SPIR-V 1.0–1.4 |

示例 16 依次实测三条，SPIR-V 段自动探测能力并换设备——**同一台机器"一有一无"是最好的教学对照**。

## 16.2 设备二进制：dump 与重载

```c
/* 1) 问大小（每设备一个） */
size_t szs[1];
clGetProgramInfo(prog, CL_PROGRAM_BINARY_SIZES, sizeof(szs), szs, NULL);
/* 2) 取内容（指针数组） */
unsigned char* bin = malloc(szs[0]);
const unsigned char* ptrs[1] = { bin };
clGetProgramInfo(prog, CL_PROGRAM_BINARIES, sizeof(ptrs), ptrs, NULL);
/* 3) 存盘；下次启动直接 */
cl_program pbin = clCreateProgramWithBinary(ctx, 1, devs, &sz, rptrs, NULL /*binary_status*/, &err);
clBuildProgram(pbin, 1, devs, NULL, NULL, NULL);
```

实测输出：

```
A) source          : verified
B) binary dumped   : 1117 bytes -> kernel_cache.bin
   binary reloaded : verified
```

缓存策略要点：

- **二进制与设备（甚至驱动版本）绑定**——加载时驱动校验，不认识就 `CL_INVALID_BINARY`；发布软件要按设备分桶存缓存；
- `CL_PROGRAM_BINARY_SIZES/BINARIES` 是"每设备"数组（多设备程序会得到多个二进制）；
- NVIDIA 的 1117 字节说明它存的是句柄式轻量表示（真编译在驱动侧），Intel CPU 平台的二进制则大得多——**别对二进制大小做假设**。

## 16.3 SPIR-V：语言无关的中间层

SPIR-V 是 Khronos 的标准中间语言（OpenCL 2.1 起核心，1.2 走 `cl_khr_il_program` 扩展）。价值：

- 源码不随发行版暴露（知识产权）；
- 前端（clang 等）与驱动解耦，可以离线深度优化；
- 同一份 IL 可喂给支持它的任何后端。

### 16.3.1 探测能力（务必先做）

```c
size_t il_sz = 0;
clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, 0, NULL, &il_sz);
/* il_sz == 1（只有 NUL）=> 不支持；否则返回 "SPIR-V_1.0 SPIR-V_1.2 ..." 字符串 */
```

### 16.3.2 离线编译 .cl → .spv

本机工具链实测：**scoop 的 LLVM 23 没有 SPIRV 后端**（`-print-targets` 无 spirv），**MSYS2 UCRT64 clang 22.1.8 有**：

```powershell
& G:\scoop\apps\msys2\current\ucrt64\bin\clang.exe `
    '-cl-std=CL1.2' -target spirv64 -c kernel_spirv.cl -o kernel_spirv.spv
```

（PowerShell 注意引号：`-cl-std=CL1.2` 不加引号会被拆成 `-cl-std=CL1` 和 `.2`。）`build.ps1` 在构建 16 章时自动做这一步；`spirv-dis/spirv-val` 等工具随 SPIRV-Tools 分发。

### 16.3.3 加载运行

```c
size_t spv_sz; char* spv = read_file("kernel_spirv.spv", &spv_sz);
cl_program pil = clCreateProgramWithIL(ctx, spv, spv_sz, &err);
clBuildProgram(pil, 1, &ildev, NULL, NULL, NULL);
```

> ⚠️ **本教程最离谱的实测坑**：clang 生成的 SPIR-V 里，内核索引用 `size_t` 会让 **Intel CPU 运行时在 `clBuildProgram` 无限卡死**（不是报错，是挂起）。改成 `int i = get_global_id(0);` 后秒过。排查过程（独立探针逐变量隔离）记录在教程仓库历史。教学内核的 SPIR-V 一律用 int 索引。

### 16.3.4 实测输出

```
C) device IL       : (none on this device)
   using IL device : 12th Gen Intel(R) Core(TM) i7-12700F
   SPIR-V program  : verified
   CL_PROGRAM_IL of a source-built program: 0 bytes
16 binary_spirv PASS
```

## 16.4 相关查询

| 查询 | 含义 |
|---|---|
| `CL_PROGRAM_IL` | 程序的 IL 字节（源码程序为 0 字节，实测） |
| `CL_PROGRAM_BINARIES` / `CL_PROGRAM_BINARY_SIZES` | 设备二进制 |
| `CL_PROGRAM_SOURCE` | 源码回显 |
| `CL_DEVICE_IL_VERSION` / `CL_DEVICE_ILS_WITH_VERSION` | 设备 IL 能力（3.0 数组形态） |

## 16.5 选型建议

| 场景 | 建议 |
|---|---|
| 应用/教学 | 源码 + `clCreateProgramWithBinary` 缓存（启动提速） |
| 发行内核不泄源码 | SPIR-V（目标设备支持 IL 时） |
| NVIDIA-only 生产 | CUDA C++ / PTX 生态更顺 |
| 跨 NVIDIA+Intel | 源码路线最稳（IL 两家有无不一，本机即例） |

> 下一章：[17 C++ 绑定](17-cpp-bindings.md)——opencl.hpp 的 RAII 与异常。
