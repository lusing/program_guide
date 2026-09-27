/* 18_reduction —— 两级归约：组内树形 + 跨组合并
 *
 * 1M float 求和。单靠一个 kernel 做不完（不同 work-group 之间无法同步），
 * 标准姿势是两级：
 *   级 1: 每个 work-group 在 local 内存里树形归约 -> 写出 1 个部分和
 *   级 2: 部分和数组再归约一次（或数量少时主机直接加）
 * 对照组：
 *   - CPU 串行求和
 *   - atomic_add 版整数直方图式归约（好懂但慢，教学用）
 * 变体实验：组内先 float4 向量化（Scarpino 10.2 思路）观察加速。
 */
#include <math.h>
#include <windows.h>
#include "cl_utils.h"

static const char* K_SRC =
/* 级 1：每工作组一个部分和 */
"__kernel void reduce_stage1(__global const float* in,\n"
"                            __global float* partials,\n"
"                            __local float* scratch,\n"
"                            const int n) {\n"
"    int gid = get_global_id(0);\n"
"    int lid = get_local_id(0);\n"
"    int lsz = get_local_size(0);\n"
"    scratch[lid] = (gid < n) ? in[gid] : 0.0f;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int stride = lsz / 2; stride > 0; stride >>= 1) {\n"
"        if (lid < stride)\n"
"            scratch[lid] += scratch[lid + stride];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (lid == 0)\n"
"        partials[get_group_id(0)] = scratch[0];\n"
"}\n"
/* 向量化变体：每个 work-item 先私有地吃 4 个元素再进树 */
"__kernel void reduce_vec4(__global const float4* in,\n"
"                          __global float* partials,\n"
"                          __local float* scratch,\n"
"                          const int n4) {\n"
"    int gid = get_global_id(0);\n"
"    int lid = get_local_id(0);\n"
"    int lsz = get_local_size(0);\n"
"    float4 v = (gid < n4) ? in[gid] : (float4)(0.0f);\n"
"    float s = v.x + v.y + v.z + v.w;\n"
"    scratch[lid] = s;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"    for (int stride = lsz / 2; stride > 0; stride >>= 1) {\n"
"        if (lid < stride)\n"
"            scratch[lid] += scratch[lid + stride];\n"
"        barrier(CLK_LOCAL_MEM_FENCE);\n"
"    }\n"
"    if (lid == 0)\n"
"        partials[get_group_id(0)] = scratch[0];\n"
"}\n"
/* atomic 版：一个原子计数直出（整数演示） */
"__kernel void reduce_atomic(__global const int* in,\n"
"                            __global int* total, const int n) {\n"
"    int gid = get_global_id(0);\n"
"    if (gid < n) atomic_add(total, in[gid]);\n"
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
    /* 剖析队列拿设备侧时间 */
    const cl_queue_properties props[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE, 0
    };
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
    CL_CHECK(err);
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    const int N = 1 << 20;                     /* 1M */
    const int L = 256;
    const int GROUPS = N / L;
    float* hin = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) hin[i] = (float)((i * 2654435761u) % 1000) / 1000.0f;
    double cpu_ref = 0;
    for (int i = 0; i < N; i++) cpu_ref += hin[i];

    cl_mem bin_ = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                 N * sizeof(float), hin, &err);
    CL_CHECK(err);
    cl_mem bpart = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, GROUPS * sizeof(float), NULL, &err);
    CL_CHECK(err);
    float* hpart = (float*)malloc(GROUPS * sizeof(float));

    double t_kernel = 0;
    double sum = 0;

    /* ---- 两级标量版 ---- */
    {
        cl_kernel k1 = clCreateKernel(prog, "reduce_stage1", &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(k1, 0, sizeof(cl_mem), &bin_));
        CL_CHECK(clSetKernelArg(k1, 1, sizeof(cl_mem), &bpart));
        CL_CHECK(clSetKernelArg(k1, 2, L * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(k1, 3, sizeof(cl_int), &n));
        size_t g = GROUPS * L, l = L;
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, k1, 1, NULL, &g, &l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong t0, t1;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(t0), &t0, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(t1), &t1, NULL);
        t_kernel = (t1 - t0) / 1e6;
        clReleaseEvent(ev);
        CL_CHECK(clEnqueueReadBuffer(q, bpart, CL_TRUE, 0, GROUPS * sizeof(float), hpart, 0, NULL, NULL));
        sum = 0;
        for (int i = 0; i < GROUPS; i++) sum += hpart[i];
        printf("scalar two-stage: sum=%.2f kernel=%.3fms (+host merge of %d partials)\n",
               sum, t_kernel, GROUPS);
        CHECK(fabs(sum - cpu_ref) < 0.5, "scalar reduction accuracy");
        clReleaseKernel(k1);
    }

    /* ---- 向量化版（1/4 的 work-item，各吃 float4） ---- */
    {
        cl_kernel kv = clCreateKernel(prog, "reduce_vec4", &err);
        CL_CHECK(err);
        /* bin_ 已是 N 个 float，可以直接按 float4 视角读（N 是 4 的倍数） */
        cl_int n4 = N / 4;
        int groups4 = n4 / L;
        CL_CHECK(clSetKernelArg(kv, 0, sizeof(cl_mem), &bin_));
        CL_CHECK(clSetKernelArg(kv, 1, sizeof(cl_mem), &bpart));
        CL_CHECK(clSetKernelArg(kv, 2, L * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(kv, 3, sizeof(cl_int), &n4));
        size_t g = groups4 * L, l = L;
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, kv, 1, NULL, &g, &l, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong t0, t1;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(t0), &t0, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(t1), &t1, NULL);
        double t_vec = (t1 - t0) / 1e6;
        clReleaseEvent(ev);
        CL_CHECK(clEnqueueReadBuffer(q, bpart, CL_TRUE, 0, groups4 * sizeof(float), hpart, 0, NULL, NULL));
        double sum4 = 0;
        for (int i = 0; i < groups4; i++) sum4 += hpart[i];
        printf("vectorized      : sum=%.2f kernel=%.3fms (%.1fx vs scalar)\n",
               sum4, t_vec, t_kernel / t_vec);
        CHECK(fabs(sum4 - cpu_ref) < 0.5, "vec4 reduction accuracy");
        clReleaseKernel(kv);
    }

    /* ---- atomic 版（整数） ---- */
    {
        int* hi = (int*)malloc(N * sizeof(int));
        for (int i = 0; i < N; i++) hi[i] = (int)(hin[i] * 1000.0f);
        long long ref = 0;
        for (int i = 0; i < N; i++) ref += hi[i];
        cl_mem bii = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                    N * sizeof(int), hi, &err);
        CL_CHECK(err);
        cl_int zero = 0;
        cl_mem bt = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                   sizeof(cl_int), &zero, &err);
        CL_CHECK(err);
        cl_kernel ka = clCreateKernel(prog, "reduce_atomic", &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(ka, 0, sizeof(cl_mem), &bii));
        CL_CHECK(clSetKernelArg(ka, 1, sizeof(cl_mem), &bt));
        CL_CHECK(clSetKernelArg(ka, 2, sizeof(cl_int), &n));
        size_t g = N;
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, ka, 1, NULL, &g, NULL, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong t0, t1;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(t0), &t0, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(t1), &t1, NULL);
        double t_at = (t1 - t0) / 1e6;
        clReleaseEvent(ev);
        cl_int total = 0;
        CL_CHECK(clEnqueueReadBuffer(q, bt, CL_TRUE, 0, sizeof(cl_int), &total, 0, NULL, NULL));
        printf("atomic int      : total=%lld (expect %lld) kernel=%.3fms\n",
               (long long)total, ref, t_at);
        CHECK((long long)total == ref, "atomic reduction exactness");
        clReleaseKernel(ka); clReleaseMemObject(bii); clReleaseMemObject(bt);
        free(hi);
    }

    printf("CPU reference   : %.2f\n", cpu_ref);
    clReleaseMemObject(bin_); clReleaseMemObject(bpart);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hin); free(hpart);
    printf("18 reduction PASS\n");
    return 0;
}
