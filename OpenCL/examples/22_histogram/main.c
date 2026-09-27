/* 22_histogram —— 直方图两路：全局原子 vs 本地内存+合并（《OpenCL 异构计算》第 9 章）
 *
 * 256 桶、4M 字节输入：
 *  A) global_only：每个 work-item 直接 atomic_add 到全局直方图 —— 简单但全局
 *     原子竞争激烈
 *  B) local_first：每工作组在 local 内存攒私有直方图（组内原子），最后由
 *     lid==0 把 256 桶原子合并进全局 —— 竞争减少 num_groups 倍
 * 两路结果必须一致，并与 CPU 参考对拍；profiling 计时对比。
 */
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void hist_global(__global const uchar* data, __global uint* hist,\n"
"                          const int n) {\n"
"    int i = get_global_id(0);\n"
"    if (i < n) atomic_add(hist + data[i], 1u);\n"
"}\n"
"__kernel void hist_local(__global const uchar* data, __global uint* hist,\n"
"                         __local uint* local_hist,\n"
"                         const int n) {\n"
"    int lid = get_local_id(0);\n"
"    int lsz = get_local_size(0);\n"
"    /* 组内先清零（合作） */\n"
"    for (int b = lid; b < 256; b += lsz)\n"
"        local_hist[b] = 0;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    int i = get_global_id(0);\n"
"    if (i < n) atomic_add(local_hist + data[i], 1u);\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    /* 组级合并进全局 */\n"
"    for (int b = lid; b < 256; b += lsz)\n"
"        atomic_add(hist + b, local_hist[b]);\n"
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
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    const int N = 1 << 22;                     /* 4M 字节 */
    const int L = 256;
    unsigned char* hd = (unsigned char*)malloc(N);
    unsigned int href[256] = {0};
    for (int i = 0; i < N; i++) {
        hd[i] = (unsigned char)((i * 2654435761u) >> 24);
        href[hd[i]]++;
    }

    cl_mem bd = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               N, hd, &err);
    CL_CHECK(err);
    cl_mem bh = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_HOST_READ_ONLY,
                               256 * sizeof(cl_uint), NULL, &err);
    CL_CHECK(err);

    const char* names[2] = { "hist_global", "hist_local" };
    double times[2];
    unsigned int results[2][256];

    for (int variant = 0; variant < 2; variant++) {
        /* 清零直方图（fill 用 pattern） */
        cl_uint zero = 0;
        CL_CHECK(clEnqueueFillBuffer(q, bh, &zero, sizeof(zero),
                                     0, 256 * sizeof(cl_uint), 0, NULL, NULL));
        cl_kernel k = clCreateKernel(prog, names[variant], &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bd));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bh));
        if (variant == 1)
            CL_CHECK(clSetKernelArg(k, 2, 256 * sizeof(cl_uint), NULL));
        CL_CHECK(clSetKernelArg(k, variant == 1 ? 3 : 2, sizeof(cl_int), &n));
        size_t g = N, l = L;
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong s, e;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
        times[variant] = (e - s) / 1e6;
        clReleaseEvent(ev);
        clReleaseKernel(k);
        CL_CHECK(clEnqueueReadBuffer(q, bh, CL_TRUE, 0, 256 * sizeof(cl_uint),
                                     results[variant], 0, NULL, NULL));
        int bad = 0;
        for (int b = 0; b < 256; b++)
            if (results[variant][b] != href[b]) { bad++; break; }
        printf("%-12s: %.3f ms  %s\n", names[variant], times[variant],
               bad ? "WRONG" : "matches CPU");
        CHECK(!bad, names[variant]);
    }
    printf("local-vs-global speedup: %.2fx\n", times[0] / times[1]);

    clReleaseMemObject(bd); clReleaseMemObject(bh);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hd);
    printf("22 histogram PASS\n");
    return 0;
}
