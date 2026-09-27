# 18 · 归约：两阶段树形、向量化、原子对照

> 对应示例 `examples/18_reduction/main.c`。参照 OiA 10.2 节（Numerical reduction）、HCL 第 9 章（直方图的"局部规约 + 全局规约"同款两级思想）。

## 18.1 为什么归约必须分两级

1M 个 float 求和。单个内核做不到全局同步（work-group 之间没有 OpenCL C 级屏障），所以：

```
级 1：每个 work-group 在 __local 里树形归约 -> 写出 1 个部分和
级 2：部分和数组（N/L 个）再归约（数量小时主机直接加；大时再来一轮内核）
```

级 1 内核（教程标准形态）：

```c
__kernel void reduce_stage1(__global const float* in,
                            __global float* partials,
                            __local float* scratch,
                            const int n) {
    int gid = get_global_id(0), lid = get_local_id(0), lsz = get_local_size(0);
    scratch[lid] = (gid < n) ? in[gid] : 0.0f;      /* 越界补 0 */
    barrier(CLK_LOCAL_MEM_FENCE);
    for (int stride = lsz / 2; stride > 0; stride >>= 1) {
        if (lid < stride)
            scratch[lid] += scratch[lid + stride];
        barrier(CLK_LOCAL_MEM_FENCE);               /* 每轮都要栅栏 */
    }
    if (lid == 0)
        partials[get_group_id(0)] = scratch[0];
}
```

要点：树形归约的活跃 item 每轮减半（`stride` 折半）；**每轮 barrier 不能省**（下轮读上轮写）；`lid == 0` 收口。

实测（1M float，RTX 3060）：

```
scalar two-stage: sum=523768.07 kernel=0.047ms (+host merge of 4096 partials)
CPU reference   : 523768.07
```

## 18.2 向量化变体：一个 item 吃 float4

```c
float4 v = (gid < n4) ? in4[gid] : (float4)(0.0f);
float s = v.x + v.y + v.z + v.w;      /* 先私有横加，再进树 */
scratch[lid] = s;
```

设备内存按 128B 事务取数——`float4` 让一个 item 一条指令吃 4 个数，树深减 2 级：

```
vectorized      : sum=523768.07 kernel=0.020ms (2.3x vs scalar)
```

OiA 10.2 的"reduction with vectors"思路实测有效，本机 **2.3 倍**。

## 18.3 原子版：好懂但慢

```c
if (gid < n) atomic_add(total, in[gid]);   /* int 版 */
```

实测（4M int）：`atomic int: total=523762833 kernel=0.027ms`——小数据量下也不差，但竞争随数据量线性涨（22 章直方图实测全局原子 vs 本地内存差 7 倍）。**float 没有原子加**（12 章的锁或 22 章的整数定点是替代）。

## 18.4 数值精度注意

树形归约的对数深度把误差从 O(n) 降到 O(log n)，但 float 累加序不同结果不同——对拍用容差（教程 0.5 绝对容差过 1M 随机数据）；要精确可整数化（先乘大数转 int）或 Kahan 求和的并行变体。

## 18.5 生产级归约的下一步

教程两级已够教学；工业实现还会：

- 级 2 也上 GPU（部分和 < 某阈值才回主机）；
- 组内先 warp 级归约（NVIDIA `__shfl` 式；OpenCL 用 subgroups，27 章）；
- 多 kernel 流水（18→31 章的思想叠加）；
- 直接用库：clBlast/Reduction kernels（32 章）。

> 下一章：[19 矩阵乘法](19-matmul.md)——naive → 分块 → 实测 970 GFLOP/s。
