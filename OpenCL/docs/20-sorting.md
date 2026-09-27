# 20 · 双调排序：GPU 友好的比较网络

> 对应示例 `examples/20_bitonic/main.c`。参照 OiA 11.2 节、OPE 第 11 章（Bitonic sort）。

## 20.1 为什么 GPU 排序不用快排

快排/归并排序是**分治 + 数据依赖分支**——GPU 最恨的两样。双调排序（bitonic sort）是**比较网络**：

- 输入长度必须是 2 的幂；
- 比较模式与数据无关（定死的网络）→ 无分支、无内存依赖、天然并行；
- 复杂度 O(n log²n)（CPU 上不如快排，GPU 上反而是王者）。

## 20.2 网络：stage 与 step 两层循环

对 n 个元素，外层 stage `k = 1..log2(n)`（块大小 2^k 翻倍），内层 step `j = k-1..0`（比较距离 2^j 折半）。每一步是**全并行**的比较交换：

```c
__kernel void bitonic_step(__global float* data, const int j,
                           const int stage, const int n) {
    int i = get_global_id(0);
    int partner = i ^ (1 << j);                 /* 比较距离 2^j 的伙伴 */
    if (partner > i && partner < n) {
        /* ⚠️ 方向必须绑定 stage（块大小 2^stage），不能随 j 变 */
        bool up = ((i >> stage) & 1) == 0;
        if ((data[i] > data[partner]) == up) {
            float t = data[i]; data[i] = data[partner]; data[partner] = t;
        }
    }
}
```

主机按网络顺序逐步启动（每步一次内核 = 一次全局同步）：

```c
for (int kk = 1; (1 << kk) <= N; kk++)
    for (int j = kk - 1; j >= 0; j--) {
        clSetKernelArg(k, 1, sizeof(cl_int), &j);
        clSetKernelArg(k, 2, sizeof(cl_int), &kk);
        clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL);
    }
```

log2(1024)=10 个 stage 共 55 次内核启动。

## 20.3 实测坑：方向位绑定谁

教程第一版把方向写成 `((i >> (j+1)) & 1) == 0`（随步距 j 变）——结果**部分有序**（首段对、尾段错）。正确语义（Wikipedia 网络伪码与实测一致）：

> 方向 = `(i & 2^stage) == 0` 时升序——**同一 stage 内所有 step 的方向一致**，由块大小的那一位决定；最后一个 stage 的该位对所有 i 都是 0，于是整体升序，网络收尾。

实测修正后：

```
sorted: ascending (first -5000 -4991 -4981 ... last 4998)
matches qsort: yes
20 bitonic PASS
```

与 CPU `qsort` 逐元素一致（无重复键时双调网络产出唯一排序）。

## 20.4 实现注记

- `partner > i` 的判断让一对只被低编号的那个 item 处理（避免双写）；
- 非 2 幂长度：补 ±∞ 哨兵到 2 幂，排完裁掉；
- 每步全量 item 启动（`if (partner < n)` 冗余但无害；严格版可算活跃区间）；
- 交换用显式三行（`swap` 不是 OpenCL C 标准函数）。

## 20.5 排序家族选型

| 算法 | GPU 友好度 | 复杂度 | 备注 |
|---|---|---|---|
| 双调（本章） | ★★★ | O(n log²n) | 教学主力，网络固定 |
| 基数排序（OiA 11.3） | ★★★ | O(n·k) | 整数键最快，向量位拆箱 |
| 归并（并行版） | ★★ | O(n log n) | 多轮 kernel 间归并 |
| 桶 + 原子计数（OPE 第 11 章 KNN 用到） | ★★ | 数据依赖 | 直方图式分桶 |

> 下一章：[21 卷积](21-convolution.md)——图像处理的母题，local tile + halo。
