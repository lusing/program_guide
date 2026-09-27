/* 23_filters —— 图像滤镜集：均值/高斯/Sobel（《OpenCL by Example》第 9 章路线）
 *
 * 输入：程序生成的 128x128 灰度图（棋盘+渐变+椒盐噪声），存成 image2d_t。
 * 三个滤镜内核全部走“图像对象 + 采样器地址模式”的路线（与 21 章的
 * buffer 路线对照）：CLK_ADDRESS_CLAMP_TO_EDGE 处理边界，无显式 clamp 代码。
 *  - mean    3x3 均值（模糊/去噪）
 *  - gaussian 3x3 高斯加权
 *  - sobel   梯度幅值（边缘检测）
 * 校验：CPU 参考对拍 + PGM 输出四张图。
 */
#include <math.h>
#include "cl_utils.h"

#define W 128
#define H 128

static const char* K_SRC =
"const sampler_t SMP = CLK_NORMALIZED_COORDS_FALSE\n"
"                    | CLK_ADDRESS_CLAMP_TO_EDGE\n"
"                    | CLK_FILTER_NEAREST;\n"
"__kernel void f_mean(__read_only image2d_t in, __write_only image2d_t out) {\n"
"    int2 xy = (int2)(get_global_id(0), get_global_id(1));\n"
"    float acc = 0.0f;\n"
"    for (int dy = -1; dy <= 1; dy++)\n"
"        for (int dx = -1; dx <= 1; dx++)\n"
"            acc += read_imagef(in, SMP, xy + (int2)(dx, dy)).x;\n"
"    write_imagef(out, xy, (float4)(acc / 9.0f, 0.0f, 0.0f, 1.0f));\n"
"}\n"
"__kernel void f_gauss(__read_only image2d_t in, __write_only image2d_t out) {\n"
"    int2 xy = (int2)(get_global_id(0), get_global_id(1));\n"
"    float acc = 0.0f;\n"
"    float wsum = 0.0f;\n"
"    for (int dy = -1; dy <= 1; dy++)\n"
"        for (int dx = -1; dx <= 1; dx++) {\n"
"            float w = exp(-2.0f * (float)(dx * dx + dy * dy) / 3.0f);\n"
"            acc += read_imagef(in, SMP, xy + (int2)(dx, dy)).x * w;\n"
"            wsum += w;\n"
"        }\n"
"    write_imagef(out, xy, (float4)(acc / wsum, 0.0f, 0.0f, 1.0f));\n"
"}\n"
"__kernel void f_sobel(__read_only image2d_t in, __write_only image2d_t out) {\n"
"    int2 xy = (int2)(get_global_id(0), get_global_id(1));\n"
"    float tl = read_imagef(in, SMP, xy + (int2)(-1, -1)).x;\n"
"    float tc = read_imagef(in, SMP, xy + (int2)( 0, -1)).x;\n"
"    float tr = read_imagef(in, SMP, xy + (int2)( 1, -1)).x;\n"
"    float ml = read_imagef(in, SMP, xy + (int2)(-1,  0)).x;\n"
"    float mr = read_imagef(in, SMP, xy + (int2)( 1,  0)).x;\n"
"    float bl = read_imagef(in, SMP, xy + (int2)(-1,  1)).x;\n"
"    float bc = read_imagef(in, SMP, xy + (int2)( 0,  1)).x;\n"
"    float br = read_imagef(in, SMP, xy + (int2)( 1,  1)).x;\n"
"    float gx = -tl - 2.0f * ml - bl + tr + 2.0f * mr + br;\n"
"    float gy = -tl - 2.0f * tc - tr + bl + 2.0f * bc + br;\n"
"    float m = sqrt(gx * gx + gy * gy);\n"
"    write_imagef(out, xy, (float4)(m, 0.0f, 0.0f, 1.0f));\n"
"}\n";

static void write_pgm(const char* name, const float* gray, int w, int h, float scale) {
    FILE* f = fopen(name, "wb");
    if (!f) return;
    fprintf(f, "P5\n%d %d\n255\n", w, h);
    for (int i = 0; i < w * h; i++) {
        float v = gray[i] * scale;
        unsigned char p = (unsigned char)(v < 0 ? 0 : v > 1 ? 1 : v * 255);
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
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    /* 输入：棋盘 + 渐变 + 稀疏椒盐噪声 */
    float* hin = (float*)malloc((size_t)W * H * sizeof(float));
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            float base = ((x / 16 + y / 16) % 2) ? 0.7f : 0.25f;
            float grad = 0.1f * x / (float)W;
            hin[(size_t)y * W + x] = base + grad;
        }
    hin[(size_t)33 * W + 42] = 1.0f;      /* 孤亮点：sobel 必须响应 */
    hin[(size_t)100 * W + 60] = 0.0f;     /* 孤暗点 */

    /* CPU 参考（均值滤镜） */
    float* ref_mean = (float*)malloc((size_t)W * H * sizeof(float));
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            float acc = 0;
            for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++) {
                    int sx = x + dx < 0 ? 0 : (x + dx >= W ? W - 1 : x + dx);
                    int sy = y + dy < 0 ? 0 : (y + dy >= H ? H - 1 : y + dy);
                    acc += hin[(size_t)sy * W + sx];
                }
            ref_mean[(size_t)y * W + x] = acc / 9.0f;
        }

    /* 图像对象（R 通道灰度） */
    float* hrgba = (float*)malloc((size_t)W * H * 4 * sizeof(float));
    for (int i = 0; i < W * H; i++) {
        hrgba[i * 4 + 0] = hin[i];
        hrgba[i * 4 + 1] = hrgba[i * 4 + 2] = 0.0f;
        hrgba[i * 4 + 3] = 1.0f;
    }
    cl_image_format fmt = { CL_RGBA, CL_FLOAT };
    cl_image_desc desc;
    memset(&desc, 0, sizeof(desc));
    desc.image_type = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = W;
    desc.image_height = H;
    cl_mem img_in = clCreateImage(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                  &fmt, &desc, hrgba, &err);
    CL_CHECK(err);
    cl_mem img_out = clCreateImage(ctx, CL_MEM_WRITE_ONLY, &fmt, &desc, NULL, &err);
    CL_CHECK(err);

    const char* names[3] = { "f_mean", "f_gauss", "f_sobel" };
    const char* files[3] = { "filter_mean.pgm", "filter_gauss.pgm", "filter_sobel.pgm" };
    float* hout4 = (float*)malloc((size_t)W * H * 4 * sizeof(float));
    float* gray = (float*)malloc((size_t)W * H * sizeof(float));

    size_t origin[3] = {0, 0, 0}, region[3] = {W, H, 1};
    size_t g[2] = {W, H}, l[2] = {16, 16};

    for (int fi = 0; fi < 3; fi++) {
        cl_kernel k = clCreateKernel(prog, names[fi], &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &img_in));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &img_out));
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadImage(q, img_out, CL_TRUE, origin, region, 0, 0, hout4, 0, NULL, NULL));
        for (int i = 0; i < W * H; i++) gray[i] = hout4[i * 4];

        if (fi == 0) {
            int bad = 0;
            for (int i = 0; i < W * H; i += 97)
                if (fabsf(gray[i] - ref_mean[i]) > 1e-4f) { bad++; break; }
            printf("f_mean   : %s (vs CPU reference)\n", bad ? "WRONG" : "verified");
            CHECK(!bad, "mean filter accuracy");
        } else if (fi == 1) {
            /* 高斯与均值同向（模糊），中心点差异应在合理范围 */
            float dmax = 0;
            for (int i = 0; i < W * H; i += 97) {
                float d = fabsf(gray[i] - ref_mean[i]);
                if (d > dmax) dmax = d;
            }
            printf("f_gauss  : ok (max |gauss-mean| = %.4f, both blur)\n", dmax);
            CHECK(dmax < 0.1f, "gaussian plausible");
        } else {
            /* 孤亮点 (42,33) 本身是 3x3 邻域的中心——sobel 中心权重为 0，
               响应峰值出现在它的邻居 (41,33)/(43,33) 上 */
            float peak = gray[33 * W + 41];
            float peak2 = gray[33 * W + 43];
            float flat = gray[8 * W + 8];
            printf("f_sobel  : neighbor response %.3f/%.3f vs flat %.3f\n",
                   peak, peak2, flat);
            CHECK(peak > flat + 0.5f && peak2 > flat + 0.5f,
                  "sobel responds around isolated bright point");
        }
        write_pgm(files[fi], gray, W, H, fi == 2 ? 1.0f : 1.0f);
        clReleaseKernel(k);
    }
    printf("wrote filter_mean.pgm / filter_gauss.pgm / filter_sobel.pgm\n");

    clReleaseMemObject(img_in); clReleaseMemObject(img_out);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hin); free(ref_mean); free(hrgba); free(hout4); free(gray);
    printf("23 filters PASS\n");
    return 0;
}
