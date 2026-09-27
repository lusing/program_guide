# 24 · FFT：迭代 radix-2 蝶形与频谱验证

> 对应示例 `examples/24_fft/main.c`。参照 OiA 第 14 章（信号处理与 FFT，原理推导演算最全）。

## 24.1 从 DFT 到 FFT

N 点 DFT：`X[k] = Σ x[n]·exp(-2πi·nk/N)`，O(N²)。利用旋转因子 `exp(-2πi/N)` 的对称性做分治（Cooley-Tukey），N 为 2 的幂时降到 O(N log N)——1024 点快 100 倍。

迭代 radix-2 的两个阶段：

1. **位反转重排**：把下标二进制翻转（i=001b ↔ 100b）——蝶形网络的输入序；
2. **log2(N) 级蝶形**：级 s 的半跨度 span = 2^s，两两配对做一次复数乘加：

```
a' = a + w·b
b' = a - w·b        w = exp(-2πi·pos/(2·span))  旋转因子
```

## 24.2 内核：位反转 + 每级一次启动

```c
__kernel void bitrev(__global float2* d) {          /* 原位置换 */
    int i = get_global_id(0);
    int r = 0;
    for (int v = i, bits = 0; bits < 10; bits++, v >>= 1)   /* log2(1024) 编进源码 */
        r = (r << 1) | (v & 1);
    if (r > i) { float2 t = d[i]; d[i] = d[r]; d[r] = t; }
}

__kernel void fft_stage(__global float2* d, __constant float2* tw,
                        const int stage, const int n) {
    int i = get_global_id(0);
    if (i >= n / 2) return;                  /* 每级 n/2 只蝴蝶 */
    int span = 1 << stage;
    int base = (i / span) * 2 * span;
    int pos  = i % span;
    float2 a = d[base + pos];
    float2 b = d[base + pos + span];
    float2 w = tw[pos * (n / (2 * span))];   /* 旋转因子查表 */
    float2 wb = (float2)(w.x*b.x - w.y*b.y, w.x*b.y + w.y*b.x);   /* 复乘 */
    d[base + pos]        = a + wb;
    d[base + pos + span] = a - wb;
}
```

设计要点：

- **旋转因子表**预生成放 `__constant`（N/2 个复数），内核只查表——实时 `sincos` 又慢又抖；
- `float2` 承载复数（.x=实 .y=虚），复乘手写四项；
- **级间同步靠多次内核启动**（队列顺序 = 全局屏障，与 20 章双调同款）；
- 主机循环：`bitrev` 一次 + 10 级 `fft_stage`。

## 24.3 验证：三条独立断言

1. **与 O(N²) 朴素 DFT 对拍**（1024 点，容差 5e-3）；
2. **埋已知频率**：信号 = 0.7·sin(2π·7t) + 0.3·cos(2π·40t)，则 |X[7]|/N ≈ 0.35、|X[40]|/N ≈ 0.15；
3. **实输入的共轭对称**：|X[k]| == |X[N-k]|（相对误差 < 1e-4）。

实测全绿：

```
FFT vs DFT: match (max err < 5e-3)
|X[7]| = 0.350 (expect ~0.35), |X[40]| = 0.150 (expect ~0.15)
conjugate symmetry: max rel err 0.00e+00
```

教科书级的 0.350/0.150——谱峰立在对的地方。

## 24.4 性能与进阶

| 方向 | 做法 |
|---|---|
| 每蝴蝶一个 work-item 太浪费 | 一个 item 做整只蝴蝶 + 寄存器缓存（教程写法已是） |
| 共享内存换全局 | 级内数据进 local（19 章套路移植） |
| 库 | clFFT（AMD 系，维护缓）、Vulkan/oneAPI MKL FFT |
| 实信号打包 | 两个实序列塞一个复 FFT（打包技巧，OiA 14 章有习题级讨论） |
| 大 N | Stockham 自排序（免位反转 pass）、多 radix 混合 |

> 至此进阶篇（13–24）完。下一篇起进入实战篇：[25 N 体模拟](25-nbody.md)。
