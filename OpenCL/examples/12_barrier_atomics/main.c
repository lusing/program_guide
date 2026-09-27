/* 12_barrier_atomics —— 工作组内同步：barrier 的必要性 + 原子操作
 *
 *  A) 两阶段内核：stage1 每个 item 写 local[lid]，barrier 后 stage2 读"组内
 *     下一个邻居"。barrier 保证读到的是全组写完的值——host 用环形移位校验。
 *     对照组：去掉 barrier 的内核在同一数据上跑出脏读概率（演示用，不判定）。
 *  B) 原子加：所有 item 对同一个 global int 做 atomic_add，结果必须 == item 总数
 *  C) 互斥锁求 float 和：atomic_cmpxchg 自旋拿锁 -> 临界区加一个 float -> 放锁。
 *     （float 没有原子加，这就是经典替代方案；Scarpino 7.4.3）
 *  D) atomic_xchg 交换
 */
#include <math.h>
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void rotate_barrier(__global const float* in, __global float* out,\n"
"                             __local float* s, const int n) {\n"
"    int gid = get_global_id(0), lid = get_local_id(0), lsz = get_local_size(0);\n"
"    s[lid] = (gid < n) ? in[gid] : 0.0f;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);            /* 没有它，下面这行可能读到没写完的槽 */\n"
"    if (gid < n) out[gid] = s[(lid + 1) % lsz];\n"
"}\n"
"__kernel void rotate_nobarrier(__global const float* in, __global float* out,\n"
"                               __local float* s, const int n) {\n"
"    int gid = get_global_id(0), lid = get_local_id(0), lsz = get_local_size(0);\n"
"    s[lid] = (gid < n) ? in[gid] : 0.0f;\n"
"    /* 故意不加 barrier */\n"
"    if (gid < n) out[gid] = s[(lid + 1) % lsz];\n"
"}\n"
"__kernel void atomic_count(__global int* counter, const int n) {\n"
"    int gid = get_global_id(0);\n"
"    if (gid < n) atomic_add(counter, 1);\n"
"}\n"
"__kernel void mutex_sum(__global const float* x, volatile __global float* sum,\n"
"                        volatile __global int* lock, const int n) {\n"
"    int gid = get_global_id(0);\n"
"    if (gid >= n) return;\n"
"    int acquired;\n"
"    do {\n"
"        int expected = 0;\n"
"        acquired = atomic_cmpxchg(lock, expected, 1);   /* CAS 抢锁 */\n"
"    } while (acquired != 0);\n"
"    /* 临界区：float 没有原子加，锁保护的普通读改写。\n"
"       ⚠️ sum/lock 必须 volatile：否则编译器/缓存会把 *sum 的读提升到锁外，\n"
"       实测丢更新（只累加到第一个 wave 共 512 项为止）。 */\n"
"    float s = *sum;\n"
"    s = s + x[gid];\n"
"    *sum = s;\n"
"    atomic_xchg(lock, 0);                               /* 放锁 */\n"
"}\n"
"__kernel void atomic_xchg_demo(__global int* v, __global int* got) {\n"
"    int g = get_global_id(0);\n"
"    got[g] = atomic_xchg(v, g);                         /* 全体和同一个槽交换 */\n"
"}\n";

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

    /* ---- A: barrier 环形移位 ---- */
    const int N = 4096, L = 256;
    float* hin = (float*)malloc(N * sizeof(float));
    float* hout = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) hin[i] = (float)i;
    {
        cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   N * sizeof(float), hin, &err);
        CL_CHECK(err);
        cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
        CL_CHECK(err);
        cl_kernel kb = clCreateKernel(prog, "rotate_barrier", &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(kb, 0, sizeof(cl_mem), &bi));
        CL_CHECK(clSetKernelArg(kb, 1, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(kb, 2, L * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(kb, 3, sizeof(cl_int), &n));
        size_t g = N, l = L;
        CL_CHECK(clEnqueueNDRangeKernel(q, kb, 1, NULL, &g, &l, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, N * sizeof(float), hout, 0, NULL, NULL));
        int ok = 1;
        for (int i = 0; i < N; i++) {
            int nxt = (i % L + 1) % L + (i / L) * L;
            if (hout[i] != hin[nxt]) { ok = 0; break; }
        }
        printf("barrier : rotated-in-group %s\n", ok ? "verified" : "WRONG");
        CHECK(ok, "barrier rotation");

        /* 无 barrier 版本：跑几次统计出错次数（多数情况下小网格也可能碰对） */
        cl_kernel kn = clCreateKernel(prog, "rotate_nobarrier", &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(kn, 0, sizeof(cl_mem), &bi));
        CL_CHECK(clSetKernelArg(kn, 1, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(kn, 2, L * sizeof(float), NULL));
        CL_CHECK(clSetKernelArg(kn, 3, sizeof(cl_int), &n));
        int dirty_runs = 0;
        for (int r = 0; r < 5; r++) {
            CL_CHECK(clEnqueueNDRangeKernel(q, kn, 1, NULL, &g, &l, 0, NULL, NULL));
            CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, N * sizeof(float), hout, 0, NULL, NULL));
            int bad = 0;
            for (int i = 0; i < N; i++) {
                int nxt = (i % L + 1) % L + (i / L) * L;
                if (hout[i] != hin[nxt]) bad++;
            }
            if (bad) dirty_runs++;
        }
        printf("no-barrier: %d/5 runs produced races (illustrative)\n", dirty_runs);
        clReleaseKernel(kb); clReleaseKernel(kn);
        clReleaseMemObject(bi); clReleaseMemObject(bo);
    }

    /* ---- B: 原子计数 ---- */
    {
        cl_int zero = 0;
        cl_mem bc = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                   sizeof(cl_int), &zero, &err);
        CL_CHECK(err);
        cl_kernel k = clCreateKernel(prog, "atomic_count", &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bc));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &n));
        size_t g = N;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        cl_int count = 0;
        CL_CHECK(clEnqueueReadBuffer(q, bc, CL_TRUE, 0, sizeof(cl_int), &count, 0, NULL, NULL));
        printf("atomic_add counter = %d (expect %d) %s\n", count, N,
               count == N ? "verified" : "WRONG");
        CHECK(count == N, "atomic add");
        clReleaseKernel(k); clReleaseMemObject(bc);
    }

    /* ---- C: 互斥锁 float 求和 ---- */
    {
        cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   N * sizeof(float), hin, &err);
        CL_CHECK(err);
        float zero_f = 0.0f; cl_int zero_i = 0;
        cl_mem bs = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                   sizeof(float), &zero_f, &err);
        CL_CHECK(err);
        cl_mem bl = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                   sizeof(cl_int), &zero_i, &err);
        CL_CHECK(err);
        cl_kernel k = clCreateKernel(prog, "mutex_sum", &err);
        CL_CHECK(err);
        cl_int n = N;
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bs));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bl));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &n));
        size_t g = 16384;   /* 故意多派 item，guard 保护 */
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        float sum = 0.0f;
        CL_CHECK(clEnqueueReadBuffer(q, bs, CL_TRUE, 0, sizeof(float), &sum, 0, NULL, NULL));
        float ref = 0;
        for (int i = 0; i < N; i++) ref += hin[i];
        printf("mutex float sum = %.1f (expect %.1f) %s\n", sum, ref,
               fabsf(sum - ref) < 0.5f ? "verified" : "WRONG");
        CHECK(fabsf(sum - ref) < 0.5f, "mutex sum");
        clReleaseKernel(k);
        clReleaseMemObject(bx); clReleaseMemObject(bs); clReleaseMemObject(bl);
    }

    /* ---- D: atomic_xchg ---- */
    {
        const int M = 1024;
        cl_int init = -777;
        cl_mem bv = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                   sizeof(cl_int), &init, &err);
        CL_CHECK(err);
        cl_mem bg = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, M * sizeof(cl_int), NULL, &err);
        CL_CHECK(err);
        cl_kernel k = clCreateKernel(prog, "atomic_xchg_demo", &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bv));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bg));
        size_t g = M;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        int* hg = (int*)malloc(M * sizeof(int));
        cl_int final_v = 0;
        CL_CHECK(clEnqueueReadBuffer(q, bg, CL_TRUE, 0, M * sizeof(int), hg, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bv, CL_TRUE, 0, sizeof(cl_int), &final_v, 0, NULL, NULL));
        /* 每个拿到的旧值要么是 -777（第一个抢到的），要么是某个 <M 的 item 编号；
           全部旧值里 -777 恰好出现一次 */
        int sevens = 0, ok = 1;
        for (int i = 0; i < M; i++) {
            if (hg[i] == -777) sevens++;
            else if (hg[i] < 0 || hg[i] >= M) ok = 0;
        }
        if (sevens != 1 || final_v < 0 || final_v >= M) ok = 0;
        printf("atomic_xchg: old values valid, init seen exactly once %s\n",
               ok ? "verified" : "WRONG");
        CHECK(ok, "atomic xchg");
        free(hg);
        clReleaseKernel(k); clReleaseMemObject(bv); clReleaseMemObject(bg);
    }

    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hin); free(hout);
    printf("12 barrier_atomics PASS\n");
    return 0;
}
