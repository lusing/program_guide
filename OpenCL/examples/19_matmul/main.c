/* 19_matmul —— 矩阵乘法优化之旅：naive -> 本地内存分块(tiled)
 *
 * C = A * B（行主序，方阵 N=512，float）。
 * 两个内核同一结果不同姿势，profiling 计时对比：
 *  K1 naive：每个 work-item 直接扫 A 行 B 列 —— 全局内存延迟裸奔
 *  K2 tiled：16x16 分块搬进 local，barrier 同步后算 —— 全局访问降一个量级
 * 数值用 CPU 参考对拍（容差）。CPU 也计时作参照。
 */
#include <math.h>
#include <windows.h>
#include "cl_utils.h"

#define N 512
#define TS 16          /* tile 边长 */

static const char* K_NAIVE =
"__kernel void matmul_naive(__global const float* A,\n"
"                           __global const float* B,\n"
"                           __global float* C,\n"
"                           const int n) {\n"
"    int col = get_global_id(0);\n"
"    int row = get_global_id(1);\n"
"    if (col >= n || row >= n) return;\n"
"    float acc = 0.0f;\n"
"    for (int k = 0; k < n; k++)\n"
"        acc += A[row * n + k] * B[k * n + col];\n"
"    C[row * n + col] = acc;\n"
"}\n";

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

    /* 把 tile 尺寸编进源码（教学上比内核参数直观） */
    char ksrc[8192];
    snprintf(ksrc, sizeof(ksrc),
        "%s"
        "__kernel void matmul_tiled(__global const float* A,\n"
        "                           __global const float* B,\n"
        "                           __global float* C,\n"
        "                           __local float* tA,\n"
        "                           __local float* tB,\n"
        "                           const int n) {\n"
        "    int col = get_global_id(0);\n"
        "    int row = get_global_id(1);\n"
        "    int lcol = get_local_id(0);\n"
        "    int lrow = get_local_id(1);\n"
        "    int ntiles = n / %d;\n"
        "    float acc = 0.0f;\n"
        "    for (int t = 0; t < ntiles; t++) {\n"
        "        tA[lrow * %d + lcol] = A[row * n + t * %d + lcol];\n"
        "        tB[lrow * %d + lcol] = B[(t * %d + lrow) * n + col];\n"
        "        barrier(CLK_LOCAL_MEM_FENCE);\n"
        "        for (int k = 0; k < %d; k++)\n"
        "            acc += tA[lrow * %d + k] * tB[k * %d + lcol];\n"
        "        barrier(CLK_LOCAL_MEM_FENCE);\n"
        "    }\n"
        "    C[row * n + col] = acc;\n"
        "}\n",
        K_NAIVE, TS, TS, TS, TS, TS, TS, TS, TS);

    cl_program prog = clu_build_program(ctx, dev, ksrc, NULL);

    /* 数据 */
    float* A = (float*)malloc((size_t)N * N * sizeof(float));
    float* B = (float*)malloc((size_t)N * N * sizeof(float));
    float* C = (float*)malloc((size_t)N * N * sizeof(float));
    float* Cref = (float*)malloc((size_t)N * N * sizeof(float));
    for (int i = 0; i < N * N; i++) {
        A[i] = (float)((i * 17 + 3) % 97) / 97.0f;
        B[i] = (float)((i * 29 + 5) % 89) / 89.0f;
    }
    LARGE_INTEGER f, t0, t1;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&t0);
    for (int r = 0; r < N; r++)
        for (int c = 0; c < N; c++) {
            float acc = 0;
            for (int k = 0; k < N; k++) acc += A[(size_t)r * N + k] * B[(size_t)k * N + c];
            Cref[(size_t)r * N + c] = acc;
        }
    QueryPerformanceCounter(&t1);
    double cpu_ms = (double)(t1.QuadPart - t0.QuadPart) * 1000.0 / f.QuadPart;

    cl_mem bA = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               (size_t)N * N * sizeof(float), A, &err);
    CL_CHECK(err);
    cl_mem bB = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               (size_t)N * N * sizeof(float), B, &err);
    CL_CHECK(err);
    cl_mem bC = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY,
                               (size_t)N * N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    cl_int n = N;
    size_t g[2] = {N, N}, l[2] = {TS, TS};

    /* K1 naive */
    double ms1;
    {
        cl_kernel k = clCreateKernel(prog, "matmul_naive", &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bA));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bB));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bC));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &n));
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong s, e;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
        ms1 = (e - s) / 1e6;
        clReleaseEvent(ev);
        clReleaseKernel(k);
        printf("K1 naive  : %8.2f ms  (%.1f GFLOP/s)\n", ms1,
               2.0 * N * N * N / (ms1 / 1000.0) / 1e9);
    }

    /* K2 tiled */
    double ms2;
    {
        cl_kernel k = clCreateKernel(prog, "matmul_tiled", &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bA));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bB));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bC));
        CL_CHECK(clSetKernelArg(k, 3, TS * TS * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(k, 4, TS * TS * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(k, 5, sizeof(cl_int), &n));
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong s, e;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
        ms2 = (e - s) / 1e6;
        clReleaseEvent(ev);
        clReleaseKernel(k);
        printf("K2 tiled  : %8.2f ms  (%.1f GFLOP/s, %.1fx vs naive)\n", ms2,
               2.0 * N * N * N / (ms2 / 1000.0) / 1e9, ms1 / ms2);
    }

    /* 校验（用 tiled 的结果对拍 CPU） */
    CL_CHECK(clEnqueueReadBuffer(q, bC, CL_TRUE, 0, (size_t)N * N * sizeof(float), C, 0, NULL, NULL));
    int bad = 0;
    for (int i = 0; i < N * N; i += 977) {
        if (fabsf(C[i] - Cref[i]) > 1e-2f) { bad++; break; }
    }
    printf("CPU (1 thread) : %8.2f ms\n", cpu_ms);
    printf("accuracy: %s (spot check vs CPU reference)\n", bad ? "WRONG" : "ok");
    CHECK(!bad, "matmul accuracy");

    clReleaseMemObject(bA); clReleaseMemObject(bB); clReleaseMemObject(bC);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(A); free(B); free(C); free(Cref);
    printf("19 matmul PASS\n");
    return 0;
}
