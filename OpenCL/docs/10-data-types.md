# 10 · 数据类型：标量、向量、swizzle、重解释、转换、fp64

> 对应示例 `examples/10_vector_types/main.c`。参照 OiA 第 4 章、OPE 第 7 章（Built-in data types / Vector data types / Vector components）。

## 10.1 标量类型与主机端对应

| 内核类型 | 主机类型 | 字节（本机实测） |
|---|---|---|
| `char/uchar`、`short/ushort`、`int/uint`、`long/ulong` | `cl_char`…`cl_ulong` | 1/2/4/8 |
| `float` | `cl_float` | 4 |
| `double`（需 fp64） | `cl_double` | 8 |
| `bool`、`size_t`、`ptrdiff_t`、`intptr_t` | — | 与地址宽度一致 |

**永远用 `cl_` 前缀类型在主机端对拍**——它们保证与设备端宽度一致。

`half`（fp16）：存储格式核心支持，运算要 `cl_khr_fp16`（本机 Intel 有、NVIDIA 无，27 章条件启用演示）。`double` 要 `cl_khr_fp64`（本机两家都有；OpenCL C 3.0 下也可以查 `__opencl_c_fp64` 特性宏）。

## 10.2 向量类型：长度 2/3/4/8/16

```c
float4 v = (float4)(1.0f, 2.0f, 3.0f, 4.0f);   /* 向量字面量 */
float4 z = (float4)(0.5f);                     /* 标量广播 */
float4 r = a.xyxy * z + a.wzyx;                /* swizzle + 向量运算 */
```

- 所有算术/比较/位运算对向量**逐分量**执行；
- `float3` 占 16 字节对齐（向量字面量里可用 `float2+float1` 拼）；
- **向量宽度 ≠ 硬件 SIMD**：NVIDIA GPU 的 preferred/native width 全是 1（SIMT 执行模型）；Intel CPU native=8（AVX 向量吃得到）。查询 `CL_DEVICE_{PREFERRED,NATIVE}_VECTOR_WIDTH_*` 只是提示，编译器自己决定展开。本机实测：`vector width float: preferred=1 native=1`（GPU）vs `native=8`（CPU）。

## 10.3 分量访问：xyzw / hi.lo / odd.even / 数字编号

```c
v.x v.y v.z v.w           /* 1..4 分量 */
v.xy v.xyzw v.wzyx        /* swizzle：重组（读），重复分量不能当左值 */
v.lo v.hi                 /* 低半/高半：float4 -> 两个 float2 */
v.odd v.even              /* 奇/偶分量 */
v.s0..v.s7 v.sf           /* 数字编号，长向量主力 */
```

示例 10A 实测四条访问路径并与 CPU 复算对拍（注意 `xyxy = (x,y,x,y)`、`wzyx = (w,z,y,x)`——逐分量对齐别想岔，教程作者本人就在这里翻过车）：

```
swizzle : out[0]=(15.5,4.0,2.5,2.0) verified
```

## 10.4 重解释与显式转换：as_typ 与 convert_

```c
uint4 raw = as_uint4(float4_val);            /* 按位重解释：不改比特 */
int4  ci  = convert_int4_sat_rte(float4_val);/* 显式转换：可选饱和与舍入模式 */
```

两者区别是**位 vs 值**。`convert_*` 的修饰符：

- 饱和：`_sat`（越界钳到类型极值）；
- 舍入：`_rte`（就近偶数，默认）`_rtz`（向零）`_rtp`/`_rtn`（向正/负）。

示例 10B 实测三个断言（位精确 + 溢出 + 舍入）：

```
bits   : as_uint4 bit-exact ok, convert_sat_rte 1e30->INT_MAX=2147483647, 2.5->2
```

`1e30f` 转 int 溢出被 `_sat` 钳到 `INT_MAX`；`2.5` 按 `_rte` 落到 `2`（偶数）。**隐式窄化在内核里同样发生**（C 规则），要精确控制就显式 convert。

## 10.5 fp64：条件启用三步走

```c
/* 主机：先查 */
strstr(exts, "cl_khr_fp64")  /* 或 3.0 特性宏 __opencl_c_fp64 */

/* 内核源：再启用（1.2 语法；3.0 下 pragma 变成可选提示） */
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
__kernel void dbl(...) { double2 v = ...; dot(v, (double2)(3.0, 5.0)); ... }

/* 验证：double 精度确实区别于 float */
out[g] = in[g] * 1.0000000001;   /* float 下不可分辨，double 下可 */
```

示例实测：`fp64 : cl_khr_fp64 present, double kernel verified (out[3]=31.00)`。

## 10.6 坑位清单（实测）

1. swizzle 左值限制：`v.xy = w.yx` 合法，`v.xx = ...` 非法（重复分量）；
2. `as_typ4` 要求源/目的总位宽相等（`as_int4(float4)` 恰好 32=32×4）；
3. `half` 只保证存储；运算需扩展，先查再启用；
4. 主机端对拍别用 `float`/`int`——用 `cl_float`/`cl_int`；
5. 向量常量的逗号列表项数必须等于向量长度（`float4` 四项或一项广播）。

> 下一章：[11 运算符与内建函数](11-builtins.md)——数学/整数/shuffle/select/几何全家桶。
