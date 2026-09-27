/* 15_images —— 图像对象与采样器：格式、读写函数、两种插值放大
 *
 * 流程：
 *  1) 查设备图像能力（最大 2D 尺寸、支持的通道顺序/类型数）
 *  2) 生成 64x64 的 RGBA 浮点渐变图（image2d_t，CL_RGBA/CL_FLOAT）
 *  3) kernel A：把输入图逐像素拷到输出图（read_imagef/write_imagef + 整数坐标）
 *  4) kernel B：用采样器放大到 128x128——最近邻 vs 双线性各跑一遍，
 *     采样点选在两个源像素的正中间（最近邻必然跳变、双线性必然取均值）
 *  5) 输出 PPM 灰度图到当前目录（看得到的教学产物），数值上抽查断言
 */
#include <math.h>
#include "cl_utils.h"

static const char* K_SRC =
"const sampler_t SMP_NEAREST = CLK_NORMALIZED_COORDS_FALSE\n"
"                           | CLK_ADDRESS_CLAMP_TO_EDGE\n"
"                           | CLK_FILTER_NEAREST;\n"
"const sampler_t SMP_LINEAR  = CLK_NORMALIZED_COORDS_FALSE\n"
"                           | CLK_ADDRESS_CLAMP_TO_EDGE\n"
"                           | CLK_FILTER_LINEAR;\n"
"__kernel void copy_img(__read_only image2d_t in, __write_only image2d_t out) {\n"
"    int2 xy = (int2)(get_global_id(0), get_global_id(1));\n"
"    float4 c = read_imagef(in, SMP_NEAREST, xy);\n"
"    write_imagef(out, xy, c);\n"
"}\n"
"__kernel void upscale(__read_only image2d_t in, __write_only image2d_t out,\n"
"                      const int sw, const int sh, const int use_linear) {\n"
"    int x = get_global_id(0), y = get_global_id(1);\n"
"    /* 目标像素中心映射回源坐标：((x+0.5)/W*sw - 0.5) */\n"
"    float u = ((float)x + 0.5f) / get_global_size(0) * sw - 0.5f;\n"
"    float v = ((float)y + 0.5f) / get_global_size(1) * sh - 0.5f;\n"
"    float4 c = use_linear ? read_imagef(in, SMP_LINEAR, (float2)(u, v))\n"
"                          : read_imagef(in, SMP_NEAREST, (float2)(u, v));\n"
"    write_imagef(out, (int2)(x, y), c);\n"
"}\n";

static void write_ppm(const char* name, const float* gray, int w, int h) {
    FILE* f = fopen(name, "wb");
    if (!f) return;
    fprintf(f, "P5\n%d %d\n255\n", w, h);
    for (int i = 0; i < w * h; i++) {
        unsigned char p = (unsigned char)(gray[i] < 0 ? 0 : gray[i] > 1 ? 255 : gray[i] * 255);
        fputc(p, f);
    }
    fclose(f);
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
    CL_CHECK(err);

    /* 设备图像能力 + 上下文支持的图像格式（clGetSupportedImageFormats 才是正路，
       设备级没有“格式数量”这种查询） */
    size_t max2d_w = 0, max2d_h = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_IMAGE2D_MAX_WIDTH, sizeof(max2d_w), &max2d_w, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_IMAGE2D_MAX_HEIGHT, sizeof(max2d_h), &max2d_h, NULL));
    cl_image_format fmts[64];
    cl_uint fmt_cnt = 0;
    CL_CHECK(clGetSupportedImageFormats(ctx, CL_MEM_READ_WRITE, CL_MEM_OBJECT_IMAGE2D,
                                        64, fmts, &fmt_cnt));
    printf("image2d max: %zux%zu, context supports %u read-write formats\n",
           max2d_w, max2d_h, fmt_cnt);
    CHECK(fmt_cnt > 0, "image formats");

    const int SW = 64, SH = 64, DW = 128, DH = 128;
    /* 左红右蓝的棋盘渐变，颜色即坐标——放大后一眼可辨插值效果 */
    float* src = (float*)malloc((size_t)SW * SH * 4 * sizeof(float));
    for (int y = 0; y < SH; y++)
        for (int x = 0; x < SW; x++) {
            float* p = src + ((size_t)y * SW + x) * 4;
            p[0] = x / (float)(SW - 1);
            p[1] = y / (float)(SH - 1);
            p[2] = 1.0f - x / (float)(SW - 1);
            p[3] = 1.0f;
        }

    cl_image_format fmt = { CL_RGBA, CL_FLOAT };
    cl_image_desc desc;
    memset(&desc, 0, sizeof(desc));
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = SW;
    desc.image_height = SH;

    cl_mem img_in = clCreateImage(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                  &fmt, &desc, src, &err);
    CL_CHECK(err);

    cl_image_desc desc_d = desc;
    desc_d.image_width = DW; desc_d.image_height = DH;
    float* dst = (float*)calloc((size_t)DW * DH * 4, sizeof(float));

    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    /* ---- A: 同尺寸拷贝 ---- */
    {
        cl_mem img_out = clCreateImage(ctx, CL_MEM_WRITE_ONLY, &fmt, &desc, NULL, &err);
        CL_CHECK(err);
        cl_kernel k = clCreateKernel(prog, "copy_img", &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &img_in));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &img_out));
        size_t g[2] = {SW, SH}, l[2] = {16, 16};
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, NULL));
        size_t origin[3] = {0, 0, 0}, region[3] = {SW, SH, 1};
        CL_CHECK(clEnqueueReadImage(q, img_out, CL_TRUE, origin, region, 0, 0, dst, 0, NULL, NULL));
        int ok = 1;
        for (int i = 0; i < SW * SH * 4; i++) if (dst[i] != src[i]) { ok = 0; break; }
        printf("copy_img : pixel-exact %s\n", ok ? "verified" : "WRONG");
        CHECK(ok, "image copy");
        clReleaseKernel(k); clReleaseMemObject(img_out);
    }

    /* ---- B: 放大（最近邻 vs 双线性） ---- */
    {
        cl_mem img_big = clCreateImage(ctx, CL_MEM_WRITE_ONLY, &fmt, &desc_d, NULL, &err);
        CL_CHECK(err);
        cl_kernel k = clCreateKernel(prog, "upscale", &err);
        CL_CHECK(err);
        cl_int sw = SW, sh = SH;
        size_t origin[3] = {0, 0, 0}, region[3] = {DW, DH, 1};
        size_t g[2] = {DW, DH}, l[2] = {16, 16};

        float* near = (float*)calloc((size_t)DW * DH * 4, sizeof(float));
        float* lin  = (float*)calloc((size_t)DW * DH * 4, sizeof(float));

        cl_int use_linear = 0;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &img_in));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &img_big));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &sw));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &sh));
        CL_CHECK(clSetKernelArg(k, 4, sizeof(cl_int), &use_linear));
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadImage(q, img_big, CL_TRUE, origin, region, 0, 0, near, 0, NULL, NULL));

        use_linear = 1;
        CL_CHECK(clSetKernelArg(k, 4, sizeof(cl_int), &use_linear));
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadImage(q, img_big, CL_TRUE, origin, region, 0, 0, lin, 0, NULL, NULL));

        /* 关键断言：dst(2,2) 中心映射回源坐标 u = 2.5*(64/128) - 0.5 = 0.75。
           ⚠️ 两个实测语义（与直觉相反）：
           - 线性采样 texel 中心在 i+0.5（规范公式 i0=floor(u-0.5)、a=frac(u-0.5)）：
             u=0.75 -> i0=0, a=0.25 -> linear.r = 0.75*src[0].r + 0.25*src[1].r
           - 最近邻是截断取整（i=(int)u），不是四舍五入：u=0.75 -> texel 0
           两者因此可区分 */
        float* n22 = near + (2 * (size_t)DW + 2) * 4;
        float* l22 = lin + (2 * (size_t)DW + 2) * 4;
        int ok = 1;
        float exp_n = 0.0f;                                         /* src[0].r */
        float exp_l = 0.75f * 0.0f + 0.25f * (1.0f / (SW - 1));     /* 混合 */
        if (fabsf(n22[0] - exp_n) > 1e-5f) ok = 0;
        if (fabsf(l22[0] - exp_l) > 1e-4f) ok = 0;
        printf("nearest(2,2).r = %.5f (expect %.5f), linear(2,2).r = %.5f (expect %.5f)\n",
               n22[0], exp_n, l22[0], exp_l);
        CHECK(ok, "interpolation semantics");

        /* 输出灰度（取 R 通道）PPM 看效果 */
        float* gray = (float*)malloc((size_t)DW * DH * sizeof(float));
        for (int i = 0; i < DW * DH; i++) gray[i] = lin[i * 4];
        write_ppm("upscale_linear.ppm", gray, DW, DH);
        printf("wrote upscale_linear.ppm (128x128, R channel)\n");

        clReleaseKernel(k); clReleaseMemObject(img_big);
        free(near); free(lin); free(gray);
    }

    /* ---- C: sampler 对象（主机侧 clCreateSamplerWithProperties + 传参） ---- */
    {
        const cl_sampler_properties sprops[] = {
            CL_SAMPLER_NORMALIZED_COORDS, CL_TRUE,
            CL_SAMPLER_ADDRESSING_MODE, CL_ADDRESS_CLAMP_TO_EDGE,
            CL_SAMPLER_FILTER_MODE, CL_FILTER_NEAREST,
            0
        };
        cl_sampler smp = clCreateSamplerWithProperties(ctx, sprops, &err);
        CL_CHECK(err);
        cl_sampler_info si = 0;
        CL_CHECK(clGetSamplerInfo(smp, CL_SAMPLER_FILTER_MODE, sizeof(si), &si, NULL));
        CHECK(si == CL_FILTER_NEAREST, "sampler info");
        /* 归一化坐标下的读法演示：另一个 kernel 直接把 sampler 当参数
           （本例不另写 kernel，仅验证对象创建/查询/释放路径） */
        clReleaseSampler(smp);
        printf("sampler object: created/queried/released\n");
    }

    clReleaseMemObject(img_in);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(src); free(dst);
    printf("15 images PASS\n");
    return 0;
}
