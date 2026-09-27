# 21 · 图像卷积：边界策略与 local tile（halo）

> 对应示例 `examples/21_convolution/main.c`。参照 HCL 第 7 章（OpenCL 案例学习 1：卷积——本主题的最佳叙述）、OPE 第 9 章。

## 21.1 卷积：图像处理的母题

输出像素 = 邻域窗口与卷积核的加权和：

```
out(x,y) = Σ_{dy,dx} in(x+dx, y+dy) · K(dx,dy)      （3×3 核，dx,dy ∈ {-1,0,1}）
```

锐化/模糊/边缘检测全是换核不换结构（23 章）。两个工程问题：**边界怎么办**、**邻居数据怎么高效拿**。

## 21.2 边界策略

| 策略 | 公式 | 适用 |
|---|---|---|
| clamp-to-edge（教程） | 越界坐标钳回 [0, n-1] | 通用 |
| 常量填充 | 越界返回固定值 | 信号处理 |
| 镜像 | 反射 | 图像压缩 |
| padding 输入 | 缓冲区外圈加 R 圈 | 计算换简单 |

buffer 路线要手写 clamp（`clamp(x, 0, w-1)`）；image 对象路线直接交给采样器 `CLK_ADDRESS_CLAMP_TO_EDGE`（23 章对照）。

## 21.3 K1 直接卷积：每像素 9 次全局读

```c
__kernel void conv_direct(__global const float* in, __global float* out,
                          const int w, const int h) {
    int x = get_global_id(0), y = get_global_id(1);
    if (x >= w || y >= h) return;
    float acc = 0.0f;
    for (int dy = -1; dy <= 1; dy++)
        for (int dx = -1; dx <= 1; dx++) {
            int sx = clamp(x + dx, 0, w - 1), sy = clamp(y + dy, 0, h - 1);
            acc += in[sy * w + sx] * kK[(dy + 1) * 3 + (dx + 1)];
        }
    out[y * w + x] = acc;
}
```

卷积核放 `__constant`（9 个 float，全设备广播）。

## 21.4 K2 local tile + halo：HCL 第 7 章的招牌套路

16×16 的 work-group 计算输出需要 18×18 的输入窗口（外圈 1 圈 = **halo**）。把 18×18 搬进 local 全组共享：

```c
__kernel void conv_local(... __local float* tile, const int w, const int h) {
    int lx = get_local_id(0), ly = get_local_id(1);
    int gx = get_group_id(0) * TW, gy = get_group_id(1) * TH;
    int lw = TW + 2;                       /* tile 实宽 16+2 */
    /* 合作搬运：256 个 item 搬 18×18=324 个元素（有人多搬一个） */
    for (int i = ly; i < TH + 2; i += TH)
        for (int j = lx; j < TW + 2; j += TW)
            tile[i * lw + j] = in[clamp(gy+i-1,0,h-1) * w + clamp(gx+j-1,0,w-1)];
    barrier(CLK_LOCAL_MEM_FENCE);
    /* 窗口内积，全部命中 local */
    acc += tile[(ly + 1 + dy) * lw + (lx + 1 + dx)] * kK[...];
}
```

搬运循环的步进写法（`i += TH`）让"256 人搬 324 个坑"均匀分摊；`barrier` 后卷积的 9 次读全部打在 local 上。

## 21.5 实测（256×256，3×3 锐化核，RTX 3060）

```
conv_direct : 0.009 ms  accuracy ok
conv_local  : 0.006 ms  accuracy ok
speedup local/direct: 1.47x
wrote sharpened.pgm
```

3×3 核太小、256×256 太小（全图 256KB 在 L2 里），local 优势只 1.5 倍；核半径越大（5×5/7×7）、图越大，差距越大（HCL 第 7 章的分析：work-group 大小要按"halo 摊销比"选——16×16 的 tile 摊销 1 圈 halo 是 324/256 ≈ 1.27 倍搬运，8×8 则是 100/64 ≈ 1.56 倍）。

两个内核都对拍 CPU 参考（同 clamp 边界，容差 1e-4）并输出 `sharpened.pgm` 肉眼可验。

## 21.6 要点回顾

- 常量核进 `__constant`；
- tile 维度 = 工作组维度 + 2R（R = 核半径）；
- 搬运用步进循环（`+= local_size`），不是一人一个；
- barrier 夹住搬运与使用；
- work-group 大小是 halo 摊销与占用率的折中（HCL 第 7 章的选择方法论）。

> 下一章：[22 直方图](22-histogram.md)——全局原子 vs 本地内存+合并的 7 倍差。
