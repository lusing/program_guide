# 19 · 矩阵乘法优化之旅：naive → 本地内存分块

> 对应示例 `examples/19_matmul/main.c`。参照 OPE 第 8 章案例研究（Case study – matrix multiplication）、OiA 12.2、HCL 第 4 章（简单的矩阵相乘）。行主序 C = A×B，N=512。

## 19.1 K1 naive：每元素扫一行一列

```c
__kernel void matmul_naive(__global const float* A, __global const float* B,
                           __global float* C, const int n) {
    int col = get_global_id(0), row = get_global_id(1);
    if (col >= n || row >= n) return;
    float acc = 0.0f;
    for (int k = 0; k < n; k++)
        acc += A[row * n + k] * B[k * n + col];
    C[row * n + col] = acc;
}
```

2D NDRange：`(col, row)` 一一映射输出矩阵，每 item 干 N 次乘加。问题在访存：B 按列走 = 每步跨 n×4 字节 = **2D 跨步访问**（30 章实测这种模式带宽塌方）。

## 19.2 K2 tiled：16×16 分块进 local

思路：把 A、B 各搬 16×16 的 tile 进 `__local`，全组共享复用——每个元素从全局内存读 N 次 ×2 降到 N/16 次 ×2：

```c
__kernel void matmul_tiled(... __local float* tA, __local float* tB, const int n) {
    int col = get_global_id(0), row = get_global_id(1);
    int lcol = get_local_id(0), lrow = get_local_id(1);
    float acc = 0.0f;
    for (int t = 0; t < n / TS; t++) {
        tA[lrow * TS + lcol] = A[row * n + t * TS + lcol];     /* 合作搬运 */
        tB[lrow * TS + lcol] = B[(t * TS + lrow) * n + col];
        barrier(CLK_LOCAL_MEM_FENCE);
        for (int k = 0; k < TS; k++)
            acc += tA[lrow * TS + k] * tB[k * TS + lcol];      /* 从 local 吃 */
        barrier(CLK_LOCAL_MEM_FENCE);
    }
    C[row * n + col] = acc;
}
```

两个 barrier 夹住"搬运→使用"（12 章）；tile 尺寸 TS=16 编进源码（`snprintf` 注入，教学上比内核参数直观）。

## 19.3 实测（RTX 3060，512×512，profiling 计时）

```
K1 naive  :     0.36 ms  (755.5 GFLOP/s)
K2 tiled  :     0.28 ms  (970.9 GFLOP/s, 1.3x vs naive)
CPU (1 thread) :   259.94 ms
accuracy: ok (spot check vs CPU reference)
```

- GPU naive 就比单线程 CPU 快 ~700 倍；
- tiling 再拿 1.3 倍——512 规模下 A、B（各 1MB）已能塞进 L2，local 红利有限；**规模越大（A、B 超 L2）tiling 越值钱**（1024+ 时通常 2–3 倍）；
- RTX 3060 理论 FP32 ~13 TFLOP/s，离极限还远——继续压榨要向量化装载 + 寄存器分块 + 双缓冲（OPE 第 8 章的"Kernel optimization techniques"清单、31 章方法论）。

## 19.4 验证方法

CPU 三重循环生成参考解（512³ ≈ 1.3 亿次乘加，~260ms，可接受），设备结果抽样对拍，容差 1e-2（浮点累加序不同）。**先对拍再优化**——所有优化章的铁律。

## 19.5 变体路线图（超出教程实测范围，留给读者）

| 优化 | 思路 | 预期 |
|---|---|---|
| float4 向量装载 | tile 搬运用 `float4`，一 item 算 4×4 输出块 | 借满 SIMD 宽度，~2x |
| 寄存器分块 | 每 item 累加 8×8 个输出（寄存器数组） | 减 local 压力 |
| 双缓冲 | async_work_group_copy 预取下一 tile（12.6） | 计算与搬运重叠 |
| B 转置预处理 | 先转置 B，乘法全变行序访问 | 对 naive 版立竿见影 |
| 直接用 clBlast | 32 章生态 | SGEMM 已调到极限 |

> 下一章：[20 双调排序](20-sorting.md)——GPU 友好的比较网络。
