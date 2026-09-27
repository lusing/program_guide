# 27 · 扩展机制：查询、启用、subgroups 的正确查法

> 对应示例 `examples/27_extensions/main.c`。参照 HCL 第 11 章（OpenCL 扩展：设备拆分与双精度）。

## 27.1 扩展的存在形态

扩展 = 厂商在标准之外加的能力，三种载体：

1. **字符串通告**：`CL_DEVICE_EXTENSIONS`（空格分隔）或 3.0 的 `CL_DEVICE_EXTENSIONS_WITH_VERSION`（`cl_name_version` 数组，4 章）；
2. **宏启用**（内核语言）：`#pragma OPENCL EXTENSION cl_khr_fp64 : enable`（1.x 语法；3.0 里 pragma 降级为提示，能力由特性宏/查询决定）；
3. **函数入口**：扩展 API（如 d3d11 互操作）必须 `clGetExtensionFunctionAddressForPlatform` 动态拿指针（29 章）。

实测对照（同一台机器）：

```
device reports 26 extensions
EXTENSIONS_WITH_VERSION count = 26 (matches string form)
```

## 27.2 fp64：最经典的"查了再用"

```c
if (strstr(exts, "cl_khr_fp64")) {
    /* 内核源：#pragma OPENCL EXTENSION cl_khr_fp64 : enable */
    /* 用 double 计算 */
}
```

示例的验证设计很讲究：`out[i] = a[i] * 1.0000000001`——float 下这个系数不可分辨（乘完还是原值），double 下可分辨。**用只有 double 才能通过的断言证明 double 真的在跑**：

```
fp64   : cl_khr_fp64 present, double kernel verified (ho[1]=100000000.010000)
fp16   : cl_khr_fp16 NOT on this device -> half kernels unavailable
```

fp16（`cl_khr_fp16`）本机只有 Intel 支持——同一个内核源，一家能编一家不能，运行时探测是唯一正路。

## 27.3 subgroups：扩展名查不到，查参数

本机 Intel CPU 的扩展字符串里**没有** `cl_khr_subgroups`（只有 subgroup_ballot/shuffle 家族），但 subgroups 能力实际存在（OpenCL C 2.0+ 内建 + C 3.0 特性宏 `__opencl_c_subgroups`）。正确查法是**设备参数**：

```c
cl_uint max_sg = 0;
clGetDeviceInfo(dev, CL_DEVICE_MAX_NUM_SUB_GROUPS, sizeof(max_sg), &max_sg, NULL);
/* > 0 即支持 */
```

subgroups（warp/wave 级编程）能做的事：组内 shuffle 换数据、`sub_group_reduce_add` 一条指令归约（比 18 章的 barrier 树更直接）：

```c
__kernel void sg_sum(__global const float* in, __global float* out) {
    float v = sub_group_reduce_add(in[get_global_id(0)]);
    if (get_sub_group_local_id() == 0)
        out[get_sub_group_id(0)] = v;
}
```

（需 `-cl-std=CL3.0`（或 2.0）构建；NVIDIA `MAX_NUM_SUB_GROUPS=0` → 示例自动跳过。）

## 27.4 设备分区（fission 后继）

HCL 第 11 章的 `cl_ext_device_fission`（CL 1.2 时代拆 CPU）现代等价物是核心 API：

```c
const cl_device_partition_property props[] = {
    CL_DEVICE_PARTITION_EQUALLY, 4, 0
};
cl_device_id subs[8];
clCreateSubDevices(cpu_dev, props, 8, subs, &n);
```

本机实测 `CL_DEVICE_PARTITION_PROPERTIES` 查询返回 1 项（0 = 不支持任何分区）——两家都没开放分区，示例只走查询演示。

## 27.5 常用扩展速查（本机标注）

| 扩展 | 用途 | NVIDIA | Intel CPU |
|---|---|---|---|
| `cl_khr_fp64` | double | ✓ | ✓ |
| `cl_khr_fp16` | half 运算 | ✗ | ✓ |
| `cl_khr_il_program` | SPIR-V（16 章） | ✗ | ✓ |
| `cl_khr_subgroups`（按参数查） | warp 级编程 | ✗ | ✓ |
| `cl_khr_gl_sharing` / `cl_khr_d3d11_sharing` | 图形互操作（29 章） | 通告有、实测不可用 | ✗ |
| `cl_khr_int64_base/extended_atomics` | 64 位原子 | ✓ | ✓ |
| `cl_khr_image2d_from_buffer` | buffer 当图像 | ✓ | ✓ |
| `cl_khr_command_buffer` | 命令缓冲重放 | ✗ | ✓ |
| `cl_intel_*` / `cl_nv_*` | 厂商私有 | — | — |

## 27.6 使用扩展的模板

```c
/* 1) 主机探测 */
char exts[8192]; clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sizeof(exts), exts, NULL);
int has = strstr(exts, "cl_khr_fp64") != NULL;
/* 2) 备好两条内核源（或用宏拼装） */
/* 3) 能力不同给不同提示，绝不假设 */
```

> 下一章：[28 调试](28-debugging.md)——错误注入、内核 printf 与坑位总表。
