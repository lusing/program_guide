# 22 · 直方图：全局原子 vs 本地内存 + 合并

> 对应示例 `examples/22_histogram/main.c`。参照 HCL 第 9 章（OpenCL 案例学习 3：直方图——本主题最深入的剖析）、OPE 第 3/8 章（Histogram calculation 案例研究）。

## 22.1 问题：高竞争的原子计数

256 桶直方图，4M 字节输入。最直觉的内核：

```c
__kernel void hist_global(__global const uchar* data, __global uint* hist,
                          const int n) {
    int i = get_global_id(0);
    if (i < n) atomic_add(hist + data[i], 1u);
}
```

百万级 work-item 对 256 个全局计数槽 `atomic_add`——同一槽的原子操作在硬件上**串行化**，竞争激烈（30 章会看到原子单元是稀缺资源）。

## 22.2 解法：组内攒桶，组级合并

```c
__kernel void hist_local(__global const uchar* data, __global uint* hist,
                         __local uint* local_hist, const int n) {
    int lid = get_local_id(0), lsz = get_local_size(0);
    for (int b = lid; b < 256; b += lsz)       /* 1) 组内清零（合作） */
        local_hist[b] = 0;
    barrier(CLK_LOCAL_MEM_FENCE);
    int i = get_global_id(0);
    if (i < n) atomic_add(local_hist + data[i], 1u);   /* 2) 打在 local 上 */
    barrier(CLK_LOCAL_MEM_FENCE);
    for (int b = lid; b < 256; b += lsz)       /* 3) 每组 256 次全局原子 */
        atomic_add(hist + b, local_hist[b]);
}
```

把账算清楚（N = 4M 元素、L = 256 item/组、B = 256 桶 → 组数 = 16384）：

| 版本 | 每元素主力原子 | 落点 | 合并开销 |
|---|---|---|---|
| 全局原子 | 4M 次 `atomic_add` | **全局内存**（跨组共享 256 槽，热点串行化，每次 L2 往返） | 无 |
| 本地攒桶 | 4M 次 `atomic_add` | **local 内存**（组私有、片上、银行并行，无跨组竞争） | 组数 × B = 16384×256 ≈ 4M 次**整桶突发**全局原子 |

注意本例 B = L 恰好让"合并的原子次数"与"每元素次数"同量级——赢面不在次数，而在**落点**：每元素的主力原子从全局内存搬到片上 local（快一个量级），剩下的合并原子是低竞争的整桶加法。若选 L > B（比如 512），合并次数还能减半。实测：

```
hist_global : 1.433 ms  matches CPU
hist_local  : 0.200 ms  matches CPU
local-vs-global speedup: 7.15x
```

**7.15 倍**——这就是 HCL 第 9 章的核心结论：**直方图的原子竞争要用"私有副本 + 合并"消解**。

## 22.3 组内清零的写法

`local_hist` 不能 memset——用步进循环全组合作清零（`for (b = lid; b < 256; b += lsz)`，256 桶 / 256 item = 每人一桶），然后 barrier。桶数不是 L 倍数时同一写法自然覆盖。

## 22.4 桶数超大时

256 桶 × 4B = 1KB/组，local 装得下（48KB）。桶数到 65536（图像 16bit 直方图）时 256KB 超 NVIDIA local 上限——变体：

- 减组内覆盖桶段（多轮内核）；
- 用 global 内存分片（每 CU 一片）；
- 两遍扫描（先统计范围再分桶）。

HCL 第 9 章还有"选择适量的 work-group"的 occupancy 分析（组太多合并开销涨、太少占不满）。

## 22.5 验证

两路结果与 CPU 参考逐桶一致（直方图是精确整数，可全等断言）；`clEnqueueFillBuffer` 用 0 模式清零全局直方图（比读回再写干净）。

> 下一章：[23 图像滤镜](23-image-filters.md)——均值/高斯/Sobel 与 image 对象路线。
