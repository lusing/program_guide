/* 21_convolution —— 图像卷积：边界策略 + 本地内存 tile（带 halo）
 *
 * 灰度 256x256 图 x 3x3 卷积核（锐化核）。两个内核：
 *  A) 直接卷积：每个像素 9 次全局读，边界用 clamp
 *  B) 本地缓存版：tile (16x16) + halo(1)，合作搬运到 local 后算——
 *     《OpenCL 异构计算》第 7 章的核心套路（选 workgroup 大小、缓存到 local）
 * 对拍 CPU 参考实现 + 计时对比。输出 PGM 看效果。
 */
#include <math.h>
#include <windows.h>
#include "cl_utils.h"

#define W 256
#define H 256
#define TW 16
#define TH 16
#define R 1            /* 卷积核半径 */

static const char* K_DIRECT =
"__constant float kK[9] = { 0.0f, -1.0f, 0.0f,\n"
"                          -1.0f, 5.0f, -1.0f,\n"
"                           0.0f, -1.0f, 0.0f };\n"
"__kernel void conv_direct(__global const float* in, __global float* out,\n"
"                          const int w, const int h) {\n"
"    int x = get_global_id(0);\n"
"    int y = get_global_id(1);\n"
"    if (x >= w || y >= h) return;\n"
"    float acc = 0.0f;\n"
"    for (int dy = -1; dy <= 1; dy++)\n"
"        for (int dx = -1; dx <= 1; dx++) {\n"
"            int sx = clamp(x + dx, 0, w - 1);\n"
"            int sy = clamp(y + dy, 0, h - 1);\n"
"            acc += in[sy * w + sx] * kK[(dy + 1) * 3 + (dx + 1)];\n"
"        }\n"
"    out[y * w + x] = acc;\n"
"}\n";

static double now_ms(void) {
    LARGE_INTEGER f, t;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&t);
    return (double)t.QuadPart * 1000.0 / (double)f.QuadPart;
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);
    const cl_queue_properties props[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE, 0
    };
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
    CL_CHECK(err);

    /* tile 尺寸编进源码（snprintf 版，比字符串拼接直观） */
    char ksrc[8192];
    snprintf(ksrc, sizeof(ksrc),
        "%s"
        "__kernel void conv_local(__global const float* in, __global float* out,\n"
        "                         __local float* tile,\n"
        "                         const int w, const int h) {\n"
        "    int lx = get_local_id(0), ly = get_local_id(1);\n"
        "    int gx = get_group_id(0) * %d, gy = get_group_id(1) * %d;\n"
        "    int x = gx + lx, y = gy + ly;\n"
        "    /* tile 是 (%d+2)x(%d+2)：合作搬运，含 1 圈 halo */\n"
        "    int lw = %d + 2;\n"
        "    for (int i = ly; i < %d + 2; i += %d) {\n"
        "        for (int j = lx; j < %d + 2; j += %d) {\n"
        "            int sx = clamp(gx + j - 1, 0, w - 1);\n"
        "            int sy = clamp(gy + i - 1, 0, h - 1);\n"
        "            tile[i * lw + j] = in[sy * w + sx];\n"
        "        }\n"
        "    }\n"
        "    barrier(CLK_LOCAL_MEM_FENCE);\n"
        "    if (x < w && y < h) {\n"
        "        float acc = 0.0f;\n"
        "        for (int dy = -1; dy <= 1; dy++)\n"
        "            for (int dx = -1; dx <= 1; dx++)\n"
        "                acc += tile[(ly + 1 + dy) * lw + (lx + 1 + dx)]\n"
        "                     * kK[(dy + 1) * 3 + (dx + 1)];\n"
        "        out[y * w + x] = acc;\n"
        "    }\n"
        "}\n",
        K_DIRECT, TW, TH, TW, TH, TW, TH, TH, TW, TH);
    cl_program prog = clu_build_program(ctx, dev, ksrc, NULL);

    /* 输入图：径向渐变 + 圆环（有结构，卷积效果可见） */
    float* hin = (float*)malloc((size_t)W * H * sizeof(float));
    float* href = (float*)malloc((size_t)W * H * sizeof(float));
    float* hout = (float*)malloc((size_t)W * H * sizeof(float));
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            float dx = x - W / 2.0f, dy = y - H / 2.0f;
            float r = sqrtf(dx * dx + dy * dy);
            hin[(size_t)y * W + x] =
                0.5f + 0.5f * sinf(r / 8.0f) * expf(-r / 128.0f);
        }

    /* CPU 参考：同 clamp 边界 */
    static const float K[9] = { 0, -1, 0, -1, 5, -1, 0, -1, 0 };
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            float acc = 0;
            for (int dy = -1; dy <= 1; dy++)
                for (int dx = -1; dx <= 1; dx++) {
                    int sx = x + dx < 0 ? 0 : (x + dx >= W ? W - 1 : x + dx);
                    int sy = y + dy < 0 ? 0 : (y + dy >= H ? H - 1 : y + dy);
                    acc += hin[(size_t)sy * W + sx] * K[(dy + 1) * 3 + dx + 1];
                }
            href[(size_t)y * W + x] = acc;
        }

    cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               (size_t)W * H * sizeof(float), hin, &err);
    CL_CHECK(err);
    cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY,
                               (size_t)W * H * sizeof(float), NULL, &err);
    CL_CHECK(err);
    cl_int w = W, h = H;
    size_t g[2] = {W, H}, l[2] = {TW, TH};

    const char* names[2] = { "conv_direct", "conv_local" };
    double times[2] = {0, 0};
    for (int ki = 0; ki < 2; ki++) {
        cl_kernel k = clCreateKernel(prog, names[ki], &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bi));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
        if (ki == 1)
            CL_CHECK(clSetKernelArg(k, 2, (TW + 2) * (TH + 2) * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(k, ki == 1 ? 3 : 2, sizeof(cl_int), &w));
        CL_CHECK(clSetKernelArg(k, ki == 1 ? 4 : 3, sizeof(cl_int), &h));
        cl_event ev;
        /* 预热一次再计时 */
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, NULL));
        clFinish(q);
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong s, e;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
        times[ki] = (e - s) / 1e6;
        clReleaseEvent(ev);
        clReleaseKernel(k);
        CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, (size_t)W * H * sizeof(float), hout, 0, NULL, NULL));
        int bad = 0;
        for (int i = 0; i < W * H; i += 251)
            if (fabsf(hout[i] - href[i]) > 1e-4f) { bad++; break; }
        printf("%-12s: %.3f ms  accuracy %s\n", names[ki], times[ki], bad ? "WRONG" : "ok");
        CHECK(!bad, names[ki]);
    }
    printf("speedup local/direct: %.2fx\n", times[0] / times[1]);

    /* PGM 输出（锐化结果，0/1 clamp） */
    FILE* f = fopen("sharpened.pgm", "wb");
    if (f) {
        fprintf(f, "P5\n%d %d\n255\n", W, H);
        for (int i = 0; i < W * H; i++) {
            float v = hout[i] < 0 ? 0 : hout[i] > 1 ? 1 : hout[i];
            fputc((unsigned char)(v * 255), f);
        }
        fclose(f);
        printf("wrote sharpened.pgm\n");
    }

    clReleaseMemObject(bi); clReleaseMemObject(bo);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hin); free(href); free(hout);
    printf("21 convolution PASS\n");
    return 0;
}
