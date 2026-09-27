/* 30_coalescing —— 合并访问 vs 跨步访问：内存带宽实测
 *
 * 同样的总读取量、同样的计算，唯一区别是访问模式：
 *  A) coalesced：工作组内相邻 work-item 读相邻地址（连续 128B 段）
 *  B) strided  ：相邻 work-item 隔 STRIDE 个元素读（同一 cache line 被
 *     反复丢弃，带宽暴跌）
 *  C) 2D 行主序 vs 列主序遍历（列走 = 每次跨一整行 = 大跨步）
 * 用大数组（64MB）+ 多轮计时取中位数，给出 GB/s 对比。
 */
#include <windows.h>
#include "cl_utils.h"

#define NEL (16 << 20)      /* 16M float = 64MB */
#define STRIDE 32

static const char* K_SRC =
"__kernel void sum_coalesced(__global const float* x, __global float* out,\n"
"                            const int n) {\n"
"    int i = get_global_id(0);\n"
"    float v = (i < n) ? x[i] : 0.0f;\n"          /* 相邻 item 相邻地址 */
"    __local float s[256];\n"
"    s[get_local_id(0)] = v;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int st = 128; st > 0; st >>= 1) {\n"
"        if (get_local_id(0) < st) s[get_local_id(0)] += s[get_local_id(0) + st];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (get_local_id(0) == 0) out[get_group_id(0)] = s[0];\n"
"}\n"
"__kernel void sum_strided(__global const float* x, __global float* out,\n"
"                          const int n, const int stride) {\n"
"    int i = get_global_id(0) * stride;\n"          /* 相邻 item 相隔 stride */
"    float v = (i < n) ? x[i] : 0.0f;\n"
"    __local float s[256];\n"
"    s[get_local_id(0)] = v;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int st = 128; st > 0; st >>= 1) {\n"
"        if (get_local_id(0) < st) s[get_local_id(0)] += s[get_local_id(0) + st];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (get_local_id(0) == 0) out[get_group_id(0)] = s[0];\n"
"}\n"
/* 2D 转置式读取：行序 vs 列序 */
"__kernel void sum_rows(__global const float* x, __global float* out,\n"
"                       const int w, const int h) {\n"
"    int gx = get_global_id(0); int gy = get_global_id(1);\n"
"    float v = (gx < w && gy < h) ? x[gy * w + gx] : 0.0f;\n"
"    __local float s[256];\n"
"    s[get_local_id(1) * 16 + get_local_id(0)] = v;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    if (get_local_id(0) == 0 && get_local_id(1) == 0) {\n"
"        float acc = 0.0f;\n"
"        for (int i = 0; i < 256; i++) acc += s[i];\n"
"        out[get_group_id(1) * get_num_groups(0) + get_group_id(0)] = acc;\n"
"    }\n"
"}\n"
"__kernel void sum_cols(__global const float* x, __global float* out,\n"
"                       const int w, const int h) {\n"
"    int gx = get_global_id(1); int gy = get_global_id(0);\n"   /* 交换 x/y */
"    float v = (gx < w && gy < h) ? x[gy * w + gx] : 0.0f;\n"
"    __local float s[256];\n"
"    s[get_local_id(1) * 16 + get_local_id(0)] = v;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    if (get_local_id(0) == 0 && get_local_id(1) == 0) {\n"
"        float acc = 0.0f;\n"
"        for (int i = 0; i < 256; i++) acc += s[i];\n"
"        out[get_group_id(1) * get_num_groups(0) + get_group_id(0)] = acc;\n"
"    }\n"
"}\n";

/* 跑一次并返回带宽 GB/s：bytes 为本次实际读取的字节数 */
static double run_bw(cl_command_queue q, cl_kernel k, size_t* g, size_t* l,
                     int dims, double bytes) {
    cl_event ev;
    cl_int err = clEnqueueNDRangeKernel(q, k, dims, NULL, g, l, 0, NULL, &ev);
    CL_CHECK(err);
    CL_CHECK(clWaitForEvents(1, &ev));
    cl_ulong s, e;
    clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
    clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
    clReleaseEvent(ev);
    return bytes / (double)(e - s);   /* 1 byte/ns 恰好 = 1 GB/s */
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
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    float* hx = (float*)malloc(NEL * sizeof(float));
    for (int i = 0; i < NEL; i++) hx[i] = 1.0f;
    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY, NEL * sizeof(float), NULL, &err);
    CL_CHECK(err);
    CL_CHECK(clEnqueueWriteBuffer(q, bx, CL_TRUE, 0, NEL * sizeof(float), hx, 0, NULL, NULL));
    cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY,
                               (NEL / 256 + 16) * sizeof(float), NULL, &err);
    CL_CHECK(err);

    double bytes = (double)NEL * sizeof(float);
    double gb = bytes / (1024.0 * 1024.0 * 1024.0);

    /* A) coalesced */
    {
        cl_kernel k = clCreateKernel(prog, "sum_coalesced", &err);
        CL_CHECK(err);
        cl_int n = NEL;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &n));
        size_t g = NEL, l = 256;
        run_bw(q, k, &g, &l, 1, 1.0);          /* warmup */
        double best = 0;
        for (int r = 0; r < 5; r++) {
            double bw = run_bw(q, k, &g, &l, 1, bytes);
            if (bw > best) best = bw;
        }
        printf("coalesced 1D : %6.1f GB/s (%.0f MB read)\n", best, bytes / 1048576.0);
        CHECK(best > 1.0, "coalesced bandwidth positive");
        clReleaseKernel(k);
    }

    /* B) strided（只读 1/STRIDE 的元素，但按“触碰带宽”算下界） */
    {
        cl_kernel k = clCreateKernel(prog, "sum_strided", &err);
        CL_CHECK(err);
        cl_int n = NEL, st = STRIDE;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &n));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &st));
        size_t g = NEL / STRIDE, l = 256;
        double t_us = 0;
        for (int r = 0; r < 3; r++) {
            cl_event ev;
            CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, &ev));
            CL_CHECK(clWaitForEvents(1, &ev));
            cl_ulong s, e;
            clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
            clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
            clReleaseEvent(ev);
            t_us = (e - s) / 1000.0;
        }
        /* 有效读 2MB，但触碰的 cache line 分布在 64MB 上 */
        printf("strided x%-3d: %6.3f ms for 2MB effective (%.1f MB touched)"
               " -- same lines evicted and re-fetched\n",
               STRIDE, t_us / 1000.0, bytes / 1048576.0);
        clReleaseKernel(k);
    }

    /* C) rows vs cols（4096x4096 子块） */
    {
        const int W2 = 4096, H2 = 4096;
        const char* names[2] = { "sum_rows", "sum_cols" };
        for (int v = 0; v < 2; v++) {
            cl_kernel k = clCreateKernel(prog, names[v], &err);
            CL_CHECK(err);
            cl_int w = W2, h = H2;
            CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
            CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
            CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &w));
            CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &h));
            size_t g[2] = {W2, H2}, l[2] = {16, 16};
            double best = 0;
            for (int r = 0; r < 3; r++) {
                cl_event ev;
                CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, g, l, 0, NULL, &ev));
                CL_CHECK(clWaitForEvents(1, &ev));
                cl_ulong s, e;
                clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
                clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
                clReleaseEvent(ev);
                double bw = ((double)W2 * H2 * 4) / (double)(e - s); /* byte/ns = GB/s */
                if (bw > best) best = bw;
            }
            printf("%-11s  : %6.1f GB/s (2D traversal)\n", names[v], best);
            clReleaseKernel(k);
        }
    }

    /* 数值正确性：全 1.0 求和 */
    {
        cl_kernel k = clCreateKernel(prog, "sum_coalesced", &err);
        CL_CHECK(err);
        cl_int n = NEL;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_int), &n));
        size_t g = NEL, l = 256;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, NULL));
        size_t po = NEL / 256;
        float* hp = (float*)malloc(po * sizeof(float));
        CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, po * sizeof(float), hp, 0, NULL, NULL));
        double total = 0;
        for (size_t i = 0; i < po; i++) total += hp[i];
        printf("sum sanity  : %.0f (expect %d)\n", total, NEL);
        CHECK(total == (double)NEL, "sum correctness");
        free(hp);
        clReleaseKernel(k);
    }

    clReleaseMemObject(bx); clReleaseMemObject(bo);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hx);
    printf("30 coalescing PASS\n");
    return 0;
}
