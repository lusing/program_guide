# 23 · 图像滤镜集：均值 / 高斯 / Sobel（image 对象路线）

> 对应示例 `examples/23_filters/main.c`。参照 OPE 第 9 章（Image Processing and OpenCL：Mean/Median/Gaussian/Sobel + JPEG 压缩）。

## 23.1 与 21 章的分工

| | 21 卷积 | 23 滤镜 |
|---|---|---|
| 数据容器 | buffer（`__global float*`） | **image 对象**（`image2d_t`） |
| 边界处理 | 手写 `clamp` | **采样器** `CLK_ADDRESS_CLAMP_TO_EDGE` |
| 邻居访问 | local tile + halo | `read_imagef` 直接采样 |

image 路线代码短、纹理缓存友好；buffer 路线（+local）是数值计算通用解。两条腿都要会。

## 23.2 三个滤镜内核（共用一个采样器）

```c
const sampler_t SMP = CLK_NORMALIZED_COORDS_FALSE
                    | CLK_ADDRESS_CLAMP_TO_EDGE
                    | CLK_FILTER_NEAREST;

/* 均值：9 邻域平均（模糊/去椒盐） */
acc += read_imagef(in, SMP, xy + (int2)(dx, dy)).x;   ... out = acc / 9;

/* 高斯：距离加权（中心重、边缘轻） */
float w = exp(-2.0f * (dx*dx + dy*dy) / 3.0f);
acc += read_imagef(...).x * w;    wsum += w;          ... out = acc / wsum;

/* Sobel：3×3 的两个方向差分卷积核，输出梯度幅值（边缘检测） */
float gx = -tl - 2*ml - bl + tr + 2*mr + br;
float gy = -tl - 2*tc - tr + bl + 2*bc + br;
float m = sqrt(gx*gx + gy*gy);
```

均值与高斯是同一形状（可分离核还能再拆成水平/垂直两 pass，复杂度 9→6）；Sobel 是"卷积核取差分模板"的标准示范。OPE 第 9 章还有 median（中值排序网络，抗椒盐最强）与 JPEG 的 DCT 路线。

## 23.3 验证设计

1. **均值**与 CPU 参考（同 clamp 边界）逐点对拍（1e-4）；
2. **高斯**与均值定性对照（同为模糊，逐点差 < 0.1）；
3. **Sobel** 用可预言的探针：孤亮点 (42,33)——

> ⚠️ 实测教学点：**亮点的响应峰值在它的邻居，不在它自己**。Sobel 核中心权重为 0，孤立点自身是 3×3 窗口的对称中心 → 梯度 ≈ 0；左右邻居才看到陡变。教程第一版在亮点本身断言，实测 0.006 对 0.006（与平坦区无差），改查邻居 (41,33)/(43,33) 后 1.441/1.428 对平坦 0.006——鲜明成立。

```
f_mean   : verified (vs CPU reference)
f_gauss  : ok (max |gauss-mean| = 0.0360, both blur)
f_sobel  : neighbor response 1.441/1.428 vs flat 0.006
wrote filter_mean.pgm / filter_gauss.pgm / filter_sobel.pgm
```

## 23.4 通道布局与灰度

示例用 `CL_RGBA/CL_FLOAT` 存灰度（R 通道有值），`read_imagef` 返回 float4 取 `.x`。真实图像直接 `CL_RGBA/CL_UNORM_INT8`（8bit/通道，硬件自动归一化到 [0,1]）。

## 23.5 从滤镜到应用

- **锐化** = 原图 + λ×(原图 − 模糊)（21 章锐化核的等价形式）；
- **USM、模糊半径分级**：高斯核加大（5×5/7×7）或两次 3×3 级联；
- **实时预览**：与 29 章 D3D11 桥接（纹理往返）；
- **JPEG（OPE 第 9 章）**：8×8 DCT + 量化 + 熵编码——DCT 内核与 24 章 FFT 同宗。

> 下一章：[24 FFT](24-fft.md)——迭代 radix-2 蝶形与频谱验证。
