# 04 · 平台与设备：查询 API 的四类形态

> 对应示例 `examples/04_deviceinfo/main.c`。参照 OiA 第 2 章（平台/设备/上下文/程序）、OPE 第 2 章（Query Platforms / Query devices）。

## 4.1 为什么查询是第一课

OpenCL 程序要在**你无法预知的硬件**上跑：GPU 还是 CPU？支持 fp64 吗？local 内存多大？工作组上限多少？答案全靠运行时查询。本机两台设备的差异就是活教材：

| 查询 | NVIDIA RTX 3060 | Intel i7-12700F (CPU) |
|---|---|---|
| compute units | 28 | 20 |
| max work-group size | 1024 | 8192 |
| max work-item sizes | 1024 × 1024 × **64** | 8192 × 8192 × 8192 |
| local memory | 48 KB | 256 KB |
| preferred/native vector width (float) | 1 / 1 | 1 / **8** |
| OpenCL C 版本 | 1.0, 1.1, 1.2, 3.0（无 2.x） | 3.0（含全部特性宏） |

注意第三行：NVIDIA 第三维上限只有 64——2D/3D NDRange 里把 `local[1]` 设成 128 会直接 `CL_INVALID_WORK_ITEM_SIZE`。

## 4.2 形态一：标量查询（一次值）

```c
cl_uint cu;
CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(cu), &cu, NULL));
size_t max_wg;
CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(max_wg), &max_wg, NULL));
```

规则：**缓冲区大小必须与查询类型等宽**（`cl_uint` 4 字节、`size_t` 8 字节……），传小了驱动可能只写一半。常用速查：

| 查询 | 类型 | 说明 |
|---|---|---|
| `CL_DEVICE_TYPE` | cl_device_type | 位掩码 GPU/CPU/ACCELERATOR |
| `CL_DEVICE_MAX_COMPUTE_UNITS` | cl_uint | 并行单元数（NVIDIA SM / Intel 核心） |
| `CL_DEVICE_MAX_WORK_GROUP_SIZE` | size_t | 单工作组 item 数上限 |
| `CL_DEVICE_MAX_WORK_ITEM_SIZES` | size_t[3] | 每维上限 |
| `CL_DEVICE_GLOBAL_MEM_SIZE` / `CL_DEVICE_LOCAL_MEM_SIZE` | cl_ulong | 字节 |
| `CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE` | cl_ulong | `__constant` 总量 |
| `CL_DEVICE_MEM_BASE_ADDR_ALIGN` | cl_uint | **位**为单位！子缓冲区对齐用（7 章） |
| `CL_DEVICE_AVAILABLE` / `CL_DEVICE_COMPILER_AVAILABLE` | cl_bool | 恒查不亏 |

## 4.3 形态二：字符串查询（两遍法）

先问长度再取内容——**永远别猜缓冲区大小**：

```c
size_t sz = 0;
clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, 0, NULL, &sz);   /* 第一遍：sz 含 NUL */
char* exts = malloc(sz);
clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sz, exts, NULL); /* 第二遍：取内容 */
```

扩展字符串是空格分隔的名字表，判断支持用子串搜索（注意 `cl_khr_fp16` 会误匹配 `cl_khr_fp16_...` 之类前缀扩展时先按空格分词更稳）：

```c
int has_fp64 = strstr(exts, "cl_khr_fp64") != NULL;
```

## 4.4 形态三：cl_name_version 数组（OpenCL 3.0 新姿势）

3.0 给"带版本的结构化清单"设计了一组查询，**返回的是 `cl_name_version` 结构数组**（`cl.h` 中定义：4 字节版本 + 64 字节名字）：

```c
typedef struct cl_name_version {
    cl_version version;   /* CL_MAKE_VERSION(major, minor, patch) 打包的 32 位 */
    char name[64];
} cl_name_version;
```

三个成员查询（示例 04 全部实测）：

| 查询 | 内容 | 本机 NVIDIA 实测 |
|---|---|---|
| `CL_DEVICE_OPENCL_C_ALL_VERSIONS` | 支持的 OpenCL C 语言版本 | `OpenCL C@1.0/1.1/1.2/3.0` |
| `CL_DEVICE_OPENCL_C_FEATURES` | 支持的 C 特性宏 | `__opencl_c_fp64、__opencl_c_images、__opencl_c_int64、__opencl_c_3d_image_writes`（均 @3.0.0） |
| `CL_DEVICE_EXTENSIONS_WITH_VERSION` | 扩展清单 | 26 项，与字符串形态数量一致 |

> ⚠️ **头号坑**：`CL_DEVICE_OPENCL_C_FEATURES` 按 3.0 规范返回的就是 `cl_name_version` 数组，**不是**像 `CL_DEVICE_EXTENSIONS` 那样的空格分隔字符串。拿它当字符串 `%s` 打印只会得到空串（首 4 字节是版本整数，常以 0 开头）。正确解法：`bytes / sizeof(cl_name_version)` 得条目数，逐条读 `.name` 与 `.version >> 22`（major）、`(version >> 12) & 0x3FF`（minor）。

平台级也有同族（`CL_PLATFORM_EXTENSIONS_WITH_VERSION` 等），还有函数入口版本查询 `clGetPlatformInfo(CL_PLATFORM_NUMERIC_VERSION)`。

## 4.5 形态四：以设备为条件的查询

同一查询在不同对象上问法不同，别搞混（06 章还有一例）：

- `clGetPlatformInfo(platform, CL_PLATFORM_*)`：问平台（名字/厂商/版本/Profile/扩展）。
- `clGetDeviceInfo(device, CL_DEVICE_*)`：问设备。
- `clGetCommandQueueInfo` / `clGetContextInfo` / `clGetMemObjectInfo` / `clGetKernelWorkGroupInfo`：问运行对象（后续章节各自出现）。

`clGetKernelWorkGroupInfo` 特别重要——**同一内核的 max work-group 会小于设备上限**（寄存器压力），本机 `tint` 内核实测 256 < 设备 1024；`CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE` 给出厂商建议的波次倍数（NVIDIA 32 = warp，31 章自动调参直接用）。

## 4.6 设备类型与选择策略

```c
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &dev, NULL);   /* 只要 GPU */
```

| 类型位 | 含义 |
|---|---|
| `CL_DEVICE_TYPE_CPU` / `_GPU` / `_ACCELERATOR` | 按类要 |
| `CL_DEVICE_TYPE_DEFAULT` | 平台默认设备 |
| `CL_DEVICE_TYPE_ALL` | 平台内全部 |

选择策略（教程 `clu_pick_device` 的实现）：**遍历平台找第一个有 GPU 的**；没有再退回 DEFAULT。跨平台时同一物理 GPU 不会出现在两个平台里（ICD 各管各家）。

> ⚠️ 宽容驱动坑（实测）：NVIDIA 对**未知的** device type 位（如 `0xDEAD`）返回 `CL_SUCCESS` 而不是规范的 `CL_INVALID_DEVICE_TYPE`，只是查不到设备。别把"没报错"当成"参数合法"。

## 4.7 示例输出节选

```
device : NVIDIA GeForce RTX 3060 (OpenCL 3.0 CUDA)
  scalar queries:
    compute units               : 28
    max work-group size          : 1024
    global memory                : 12287 MB
    max work-item sizes (3 dims) : 1024 x 1024 x 64
  string query:
    extensions (26 names, 623 bytes incl. NUL)
  cl_name_version arrays:
  OPENCL_C_ALL_VERSIONS           : OpenCL C@1.0.0 OpenCL C@1.1.0 OpenCL C@1.2.0 OpenCL C@3.0.0
  OPENCL_C_FEATURES               : __opencl_c_fp64@3.0.0 __opencl_c_images@3.0.0 __opencl_c_int64@3.0.0 __opencl_c_3d_image_writes@3.0.0
04 deviceinfo PASS (C versions=4, features=4)
```

> 下一章：[05 上下文与命令队列](05-context-queue.md)——引用计数实验与队列属性。
