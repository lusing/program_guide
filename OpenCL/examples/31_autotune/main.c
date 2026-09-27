/* 31_autotune —— 自动调参：扫 local size 找最优
 *
 * 同一个“每元素乘加”内核，local size 从 32 扫到 1024（含非 2 幂的 96），
 * 每个 candidate 跑多轮取最优，输出排行。要点：
 *  - 必须预热（首轮包含程序加载/页表建立等一次性开销）
 *  - candidate 必须能整除 global size（否则 CL_INVALID_WORK_GROUP_SIZE）
 *  - CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE 是厂商建议的“波次”倍数
 *    （NVIDIA=32 warp，Intel CPU 通常 128），实测最优通常在它的倍数附近
 */
#include <windows.h>
#include "cl_utils.h"

#define N 8 << 20

static const char* K_SRC =
"__kernel void fma_all(__global const float* x, __global float* y, float k) {\n"
"    int i = get_global_id(0);\n"
"    if (i < 8388608) y[i] = fma(x[i], k, y[i]);\n"
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
    cl_kernel k = clCreateKernel(prog, "fma_all", &err);
    CL_CHECK(err);

    size_t pref_mult = 0;
    CL_CHECK(clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE,
                                      sizeof(pref_mult), &pref_mult, NULL));
    size_t max_wg = 0;
    CL_CHECK(clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_WORK_GROUP_SIZE,
                                      sizeof(max_wg), &max_wg, NULL));
    printf("preferred multiple = %zu, max work-group = %zu\n", pref_mult, max_wg);

    const size_t NEL = 8388608;
    float* hx = (float*)malloc(NEL * sizeof(float));
    float* hy = (float*)malloc(NEL * sizeof(float));
    for (size_t i = 0; i < NEL; i++) { hx[i] = 1.0f; hy[i] = 2.0f; }
    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               NEL * sizeof(float), hx, &err);
    CL_CHECK(err);
    cl_mem by = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                               NEL * sizeof(float), hy, &err);
    CL_CHECK(err);
    float kk = 3.0f;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &by));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &kk));

    const size_t cands[] = {32, 64, 96, 128, 192, 256, 384, 512, 768, 1024};
    const int NC = (int)(sizeof(cands) / sizeof(cands[0]));
    printf("%8s %12s %10s\n", "local", "best ms", "GB/s");
    double best_ms = 1e9;
    size_t best_l = 0;
    int runs_done = 0;   /* 校验用：每次 launch 都把 y 累加一次 x*k */
    for (int c = 0; c < NC; c++) {
        size_t l = cands[c];
        if (l > max_wg) { printf("%8zu %12s (exceeds max)\n", l, "-"); continue; }
        if (NEL % l != 0) { printf("%8zu %12s (not divisible)\n", l, "-"); continue; }
        size_t g = NEL;
        /* 预热 */
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, NULL));
        runs_done++;
        clFinish(q);
        double ms = 1e9;
        for (int r = 0; r < 5; r++) {
            cl_event ev;
            CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, &ev));
            runs_done++;
            CL_CHECK(clWaitForEvents(1, &ev));
            cl_ulong s, e;
            clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(s), &s, NULL);
            clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(e), &e, NULL);
            clReleaseEvent(ev);
            double m = (e - s) / 1e6;
            if (m < ms) ms = m;
        }
        double gbps = 2.0 * NEL * 4 / (ms / 1000.0) / 1e9;
        printf("%8zu %12.3f %10.1f\n", l, ms, gbps);
        if (ms < best_ms) { best_ms = ms; best_l = l; }
    }
    printf("winner: local=%zu (%.3f ms)\n", best_l, best_ms);
    CHECK(best_l > 0, "some candidate ran");
    CHECK(best_l % pref_mult == 0 || best_l % (pref_mult / 2) == 0,
          "winner aligns with preferred multiple (heuristic)");

    /* 正确性：y 初值 2，每次 launch 加 3 -> 2 + 3*runs_done（整数，float 精确） */
    CL_CHECK(clEnqueueReadBuffer(q, by, CL_TRUE, 0, NEL * sizeof(float), hy, 0, NULL, NULL));
    float expect = 2.0f + 3.0f * (float)runs_done;
    CHECK(hy[0] == expect && hy[NEL - 1] == expect, "fma result");
    printf("y[0] = %.1f after %d launches (expect %.1f)\n", hy[0], runs_done, expect);

    clReleaseMemObject(bx); clReleaseMemObject(by);
    clReleaseKernel(k); clReleaseProgram(prog);
    clReleaseCommandQueue(q); clReleaseContext(ctx);
    free(hx); free(hy);
    printf("31 autotune PASS\n");
    return 0;
}
