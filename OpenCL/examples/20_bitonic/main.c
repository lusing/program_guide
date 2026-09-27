/* 20_bitonic —— 双调排序（bitonic sort）：GPU 友好的经典并行排序
 *
 * 原理（Scarpino 11.2 / Banger 11 章）：
 *  n 步阶段(stage) k=1..log2(N)，每阶段内部 j=k-1..0 做“比较距离 2^j 的
 *  比较交换”，方向由 (i & 2^k) 决定升/降——整个网络确定性、无数据依赖分支。
 * 主机循环 log2(N) 个 stage、每 stage 内 (k) 次内核启动（每步一次栅栏级全局同步）。
 * 数据：1024 个 float，与 CPU qsort 对拍 + 有序性断言。
 */
#include <math.h>
#include <stdlib.h>
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void bitonic_step(__global float* data, const int j,\n"
"                          const int stage, const int n) {\n"
"    int i = get_global_id(0);\n"
"    int partner = i ^ (1 << j);                 /* 比较距离 2^j 的伙伴 */\n"
"    if (partner > i && partner < n) {\n"
"        /* ⚠️ 方向必须绑定 stage（块大小 2^stage），不能随 j 变：\n"
"           up = (i 的第 stage 位 == 0)。最后一个 stage 时所有 i 该位都是 0，\n"
"           于是整体升序 —— 这正是双调网络收尾的方式 */\n"
"        bool up = ((i >> stage) & 1) == 0;\n"
"        if ((data[i] > data[partner]) == up) {\n"
"            float t = data[i]; data[i] = data[partner]; data[partner] = t;\n"
"        }\n"
"    }\n"
"}\n";

static int is_sorted(const float* a, int n) {
    for (int i = 1; i < n; i++) if (a[i - 1] > a[i]) return 0;
    return 1;
}

static int cmp_float(const void* a, const void* b) {
    float x = *(const float*)a, y = *(const float*)b;
    return (x > y) - (x < y);
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
    cl_kernel k = clCreateKernel(prog, "bitonic_step", &err);
    CL_CHECK(err);

    const int N = 1024;                          /* 必须是 2 的幂 */
    float* h = (float*)malloc(N * sizeof(float));
    float* href = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) {
        h[i] = (float)(((i * 1103515245u + 12345u) >> 16) % 10000) - 5000.0f;
        href[i] = h[i];
    }
    qsort(href, N, sizeof(float), cmp_float);

    cl_mem bd = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                               N * sizeof(float), h, &err);
    CL_CHECK(err);
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bd));
    cl_int n = N;
    CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &n));

    size_t g = N;
    for (int kk = 1; (1 << kk) <= N; kk++)
        for (int j = kk - 1; j >= 0; j--) {
            CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &j));
            CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &kk));
            CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        }
    CL_CHECK(clEnqueueReadBuffer(q, bd, CL_TRUE, 0, N * sizeof(float), h, 0, NULL, NULL));

    printf("sorted: %s (first %.0f %.0f %.0f ... last %.0f)\n",
           is_sorted(h, N) ? "ascending" : "NO",
           h[0], h[1], h[2], h[N - 1]);
    CHECK(is_sorted(h, N), "ascending order");

    /* 与 CPU 排序逐元素对拍 */
    int bad = 0;
    for (int i = 0; i < N; i++) if (h[i] != href[i]) { bad++; break; }
    printf("matches qsort: %s\n", bad ? "NO" : "yes");
    CHECK(!bad, "same order as CPU qsort");

    clReleaseMemObject(bd);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(h); free(href);
    printf("20 bitonic PASS\n");
    return 0;
}
