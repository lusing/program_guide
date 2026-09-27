# 09 · 设备内存模型：四级地址空间

> 对应示例 `examples/09_address_spaces/main.c`。参照 HCL 第 5 章（主机端/设备端内存模型）与第 6 章（CPU/GPU 上的内存性能）、OiA 4.5 节。

## 9.1 四级地址空间

| 限定符 | 谁能看见 | 速度/容量（本机 GPU 实测） | 典型用途 |
|---|---|---|---|
| `__global` | 所有 work-item | 12 GB，慢（经 L2） | 输入输出大数组 |
| `__constant` | 所有 work-item 只读 | 64 KB，广播友好 | 卷积核、参数表 |
| `__local` | **同一 work-group 内** | 48 KB（NVIDIA）/256 KB（Intel CPU），极快 | 分块缓存、组内交换 |
| `__private` | 单个 work-item | 寄存器/私有 | 临时变量 |

内核端的四种写法（示例 09 一个内核全用上）：

```c
__constant float4 kW = (float4)(0.1f, 0.2f, 0.3f, 0.4f);   /* ① 程序作用域常量 */

__kernel void mix(__global const float* in,      /* ② 全局（参数） */
                  __global float* out,
                  __local float* stage,          /* ③ local：动态大小（主机传字节数） */
                  const int n) {
    __local float stat[256];                     /* ③' local：静态数组 */
    float priv = 0.0f;                           /* ④ 私有 */
    ...
}
```

动态 local 参数的主机端写法（大小在启动时才决定）：

```c
clSetKernelArg(k, 2, L * sizeof(float), NULL);   /* size=字节数，value=NULL */
```

## 9.2 查询容量与配额

| 查询 | 本机 NVIDIA | 本机 Intel CPU |
|---|---|---|
| `CL_DEVICE_GLOBAL_MEM_SIZE` | 12287 MB | 16171 MB（借系统内存） |
| `CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE` | 64 KB | 64 KB |
| `CL_DEVICE_MAX_CONSTANT_ARGS` | 9 | 9 |
| `CL_DEVICE_LOCAL_MEM_SIZE` | 48 KB | 256 KB |
| `CL_DEVICE_LOCAL_MEM_TYPE` | LOCAL（专用） | GLOBAL（拿全局内存模拟） |

> `__constant` 的 64 KB 是"所有常量参数 + 程序作用域常量"共享的池；`MAX_CONSTANT_ARGS` 是个数上限（本机 9 个，含程序作用域的算不算以驱动实测为准）。

## 9.3 一致性模型：宽松默认，显式同步

OpenCL C 的内存模型是**宽松一致**（relaxed）：没有同步原语时，不同 work-item 看到的写入顺序不保证。三种"保证可见"的手段（12 章逐一实测）：

| 原语 | 作用域 |
|---|---|
| `barrier(CLK_LOCAL_MEM_FENCE)` / `barrier(CLK_GLOBAL_MEM_FENCE)` | work-group 内全部 item 到齐 + 指定内存可见 |
| 原子操作 `atomic_add` 等 | 单个变量的原子性（可见性顺带） |
| 多次内核启动 | 全局同步（队列顺序保证） |

示例 09 的内核用 `barrier` 保证"stage1 写入的 local 数据，stage2 读得到"——没有它就是数据竞争（12 章有对照组实验）。

## 9.4 数据流：主机内存如何映射到地址空间

```
主机 malloc/calloc
   │ clCreateBuffer(CL_MEM_COPY_HOST_PTR / WRITE + clEnqueueWriteBuffer / map)
   ▼
__global / __constant（主机只能经 API 搬运）        __local（内核私有，主机碰不到）        __private（寄存器）
```

设计套路（后面所有算法章反复出现）：

1. global 读入 → 写进 local（合作搬运，含 halo）；
2. `barrier`；
3. 组内从 local 反复读（快）；
4. 结果写回 global。

这正是 19（矩阵分块）、21（卷积 tile）、22（直方图组内攒桶）的公共骨架。

## 9.5 示例验证

示例 09 的计算刻意让四级空间缺一不可（常量权重 × 邻居窗口混合），CPU 参考对拍：

```
constant: max args=9  max buffer=64 KB
mix across global/constant/local/private verified
09 address_spaces PASS
```

> 下一章：[10 数据类型](10-data-types.md)——标量、向量、swizzle、重解释与 fp64。
