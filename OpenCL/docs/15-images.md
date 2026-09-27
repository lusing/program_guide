# 15 · 图像对象与采样器：格式、读写、插值语义

> 对应示例 `examples/15_images/main.c`。参照 OiA 第 6 章、OPE 第 4 章（OpenCL Images，含 cl_image_desc 细节）。

## 15.1 为什么图像对象不等于 buffer

图像对象（`cl_mem` of type `CL_MEM_OBJECT_IMAGE2D/3D/1D/2D_ARRAY...`）给内核暴露的是**带硬件采样器**的随机访问：

- 坐标越界自动处理（clamp/mirror/repeat，不用写 if）；
- 硬件双线性插值一条指令；
- 格式转换自动完成（unorm 8-bit 存、float 读）；
- 纹理缓存对 2D 局部性友好。

图像滤波/采样类负载用它；规则网格数值计算用 buffer（+手动 local 缓存，21 章）。

## 15.2 创建：format + desc（1.2 起的统一入口）

```c
cl_image_format fmt = { CL_RGBA, CL_FLOAT };     /* 通道顺序 + 通道类型 */
cl_image_desc desc;
memset(&desc, 0, sizeof(desc));
desc.image_type = CL_MEM_OBJECT_IMAGE2D;
desc.image_width  = SW;
desc.image_height = SH;
cl_mem img = clCreateImage(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           &fmt, &desc, host_data, &err);
```

通道顺序/类型组合不是任意的——**先问上下文**（设备级没有"支持多少种格式"的查询，这是新手常见误区；示例 15 实测）：

```c
cl_image_format fmts[64];
cl_uint n = 0;
clGetSupportedImageFormats(ctx, CL_MEM_READ_WRITE, CL_MEM_OBJECT_IMAGE2D, 64, fmts, &n);
/* 本机 NVIDIA：75 种（READ_WRITE 通道） */
```

常用组合：`CL_RGBA/CL_FLOAT`（计算）、`CL_RGBA/CL_UNORM_INT8`（对应 8bit 纹理）、`CL_R/CL_FLOAT`（单通道灰度）。`cl_image_desc` 还能表达行距（`image_row_pitch`）、从 buffer 派生（`mem_object`，需 `cl_khr_image2d_from_buffer`）、数组/3D。

容量查询：`CL_DEVICE_IMAGE2D_MAX_WIDTH/HEIGHT`（本机 32768×32768）、`CL_DEVICE_IMAGE_MAX_BUFFER_SIZE`、`CL_DEVICE_IMAGE_SUPPORT`（某些嵌入式设备没有图像）。

## 15.3 主机端搬运

```c
size_t origin[3] = {0, 0, 0}, region[3] = {W, H, 1};
clEnqueueWriteImage(q, img, CL_TRUE, origin, region,
                    0 /*input_row_pitch*/, 0 /*slice_pitch*/, host, 0, NULL, NULL);
clEnqueueReadImage(q, img, CL_TRUE, origin, region, 0, 0, host, 0, NULL, NULL);
```

紧凑布局 pitch 传 0。同族：`clEnqueueCopyImage`、`clEnqueueFillImage`、`clEnqueueCopyImageToBuffer`。

## 15.4 内核端：image2d_t + sampler

```c
__kernel void copy_img(__read_only image2d_t in, __write_only image2d_t out) {
    int2 xy = (int2)(get_global_id(0), get_global_id(1));
    float4 c = read_imagef(in, SMP_NEAREST, xy);    /* 整数坐标 = 免滤波 */
    write_imagef(out, xy, c);
}
```

访问限定符 `__read_only`/`__write_only` 必须与创建标志一致。读函数族按数据类型选：`read_imagef`（float/unorm/half 结果）、`read_imagei/ui`（整数格式）。写只有 `write_imagef/i/ui`（**写不支持滤波**，坐标是整数）。`get_image_width/height/dim/channel_data_type` 运行时自描述。

## 15.5 采样器：三种声明方式与全部参数

```c
/* A. 内核常量（教程默认，编译期确定） */
const sampler_t SMP = CLK_NORMALIZED_COORDS_FALSE
                    | CLK_ADDRESS_CLAMP_TO_EDGE
                    | CLK_FILTER_NEAREST;

/* B. 主机对象，作为内核参数传入（15 章示例 C 段演示） */
const cl_sampler_properties sprops[] = {
    CL_SAMPLER_NORMALIZED_COORDS, CL_TRUE,
    CL_SAMPLER_ADDRESSING_MODE,   CL_ADDRESS_CLAMP_TO_EDGE,
    CL_SAMPLER_FILTER_MODE,       CL_FILTER_LINEAR,
    0
};
cl_sampler smp = clCreateSamplerWithProperties(ctx, sprops, &err);
```

参数表：

| 参数 | 取值 | 说明 |
|---|---|---|
| 坐标归一化 | `CLK_NORMALIZED_COORDS_{TRUE,FALSE}` | TRUE 时坐标 ∈ [0,1) |
| 寻址模式 | `CLK_ADDRESS_{CLAMP,CLAMP_TO_EDGE,REPEAT,MIRRORED_REPEAT,NONE}` | NONE 时越界未定义（须保证在界内） |
| 滤波 | `CLK_FILTER_{NEAREST,LINEAR}` | LINEAR 只对 read |

## 15.6 插值语义的两个实测坑（本章精华）

教程作者实测全部中招，规范原文印证——**OpenCL 的采样语义与直觉不同**：

**坑 1：线性滤波的 texel 中心在 i+0.5，不在整数**。规范公式：

```
i0 = floor(u - 0.5);  a = frac(u - 0.5);
结果 = (1-a) * texel[i0] + a * texel[i0+1]
```

即采样 `u=0.5` 才是"正好 texel 0"，`u=1.5` 是"正好 texel 1"（D3D/GL 同款约定）。实测扫点（2×1 图，值 0/1）：

```
u=0.25 -> 0.0000   u=0.50 -> 0.0000   u=0.75 -> 0.2500
u=1.00 -> 0.5000   u=1.25 -> 0.7500   u=1.50 -> 1.0000
```

**坑 2：最近邻是截断取整 `(int)u`，不是四舍五入**。实测 `u=0.75 -> texel 0`（值 0），不是 texel 1。

示例 15B 的放大内核（64→128）正好让两种滤波分道扬镳（dst(2,2) 映射回源 u=0.75）：

```
nearest(2,2).r = 0.00000 (expect 0.00000), linear(2,2).r = 0.00397 (expect 0.00397)
```

（0.00397 = 0.75×src[0].r + 0.25×src[1].r，源是 0→1/63 渐变。）

## 15.7 PPM/PGM：零依赖的看图产物

示例把结果写成 P5/P6 裸图（无头文件依赖，任何看图软件能开）：

```
wrote upscale_linear.ppm (128x128, R channel)
```

教学友好：跑完就能肉眼看插值差异。

> 下一章：[16 二进制与 SPIR-V](16-binary-spirv.md)——程序缓存、IL 路线与本机两家平台的有无对照。
