/* 13_events —— 事件系统：命令事件 / wait list / 用户事件 / 回调
 *
 * 时序演示：
 *  1) 异步写（事件 evW） -> 内核等 evW（事件 evK） -> 读等 evK（事件 evR）
 *     全程不阻塞主机，最后只等 evR —— 三段流水线的标准骨架
 *  2) 用户事件：主机 setStatus 前内核不放行（gate 语义）
 *  3) 回调：命令完成时主机收到通知（注意回调线程不是主线程）
 *  4) clGetEventInfo 的状态查询
 */
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void shift(__global const float* x, __global float* y, float d) {\n"
"    int i = get_global_id(0);\n"
"    y[i] = x[i] + d;\n"
"}\n";

static volatile int g_callback_fired = 0;

static void CL_CALLBACK on_kernel_done(cl_event ev, cl_int status, void* user) {
    (void)ev;
    const char* tag = (const char*)user;
    printf("  [callback thread] kernel event status=%d tag=%s\n", status, tag);
    g_callback_fired = 1;
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
    cl_kernel k = clCreateKernel(prog, "shift", &err);
    CL_CHECK(err);

    const int N = 1024;
    float* hx = (float*)malloc(N * sizeof(float));
    float* hy = (float*)calloc(N, sizeof(float));
    for (int i = 0; i < N; i++) hx[i] = (float)i;
    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY, N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    cl_mem by = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    float delta = 100.0f;
    cl_int n = N;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &by));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &delta));
    (void)n;

    /* ---- 1) 事件串联的三段流水线 ---- */
    cl_event evW = NULL, evK = NULL, evR = NULL;
    printf("pipeline: async write -> kernel waits write -> read waits kernel\n");
    CL_CHECK(clEnqueueWriteBuffer(q, bx, CL_FALSE, 0, N * sizeof(float), hx, 0, NULL, &evW));
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, (size_t[]){(size_t)N}, NULL, 1, &evW, &evK));
    CL_CHECK(clEnqueueReadBuffer(q, by, CL_FALSE, 0, N * sizeof(float), hy, 1, &evK, &evR));

    /* 状态观测：提交后立刻查，可能已完成（0=complete/-2=queued/-1=submitted/1=running） */
    cl_int st = -1;
    clGetEventInfo(evK, CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(st), &st, NULL);
    printf("kernel event status right after enqueue: %d (0 = already complete)\n", st);

    CL_CHECK(clWaitForEvents(1, &evR));
    clGetEventInfo(evK, CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(st), &st, NULL);
    printf("kernel event status after wait: %d (0 = CL_COMPLETE)\n", st);
    CHECK(st == CL_COMPLETE, "kernel event complete");
    int ok = 1;
    for (int i = 0; i < N; i++) if (hy[i] != hx[i] + 100.0f) { ok = 0; break; }
    CHECK(ok, "pipeline result");

    /* 事件携带的命令类型信息 */
    cl_command_type ctype = 0;
    CL_CHECK(clGetEventInfo(evK, CL_EVENT_COMMAND_TYPE, sizeof(ctype), &ctype, NULL));
    printf("kernel event command type: %u (CL_COMMAND_NDRANGE_KERNEL = 0x11F0 = 4592)\n",
           (unsigned)ctype);
    CHECK(ctype == CL_COMMAND_NDRANGE_KERNEL, "event command type");

    /* ---- 2) 用户事件 gate ---- */
    cl_event user = clCreateUserEvent(ctx, &err);
    CL_CHECK(err);
    float delta2 = -50.0f;
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &delta2));
    cl_event evK2 = NULL;
    /* 内核只等用户事件：主机不 setStatus 它就永远不开跑 */
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, (size_t[]){(size_t)N}, NULL, 1, &user, &evK2));
    CL_CHECK(clEnqueueReadBuffer(q, by, CL_FALSE, 0, N * sizeof(float), hy, 1, &evK2, NULL));
    cl_int st2 = -100;
    clGetEventInfo(evK2, CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(st2), &st2, NULL);
    printf("kernel gated on user event, status now: %d (not 0 = CL_COMPLETE; NVIDIA 报 3)\n", st2);
    CHECK(st2 != CL_COMPLETE, "user event gates execution");
    CL_CHECK(clSetUserEventStatus(user, CL_COMPLETE));   /* 放行 */
    clFinish(q);
    ok = 1;
    for (int i = 0; i < N; i++) if (hy[i] != hx[i] - 50.0f) { ok = 0; break; }
    CHECK(ok, "gated kernel result");

    /* ---- 3) 回调 ---- */
    static const char tag[] = "kernel-done";
    cl_event evK3 = NULL;
    float delta3 = 7.0f;
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &delta3));
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, (size_t[]){(size_t)N}, NULL, 0, NULL, &evK3));
    CL_CHECK(clSetEventCallback(evK3, CL_COMPLETE, on_kernel_done, (void*)tag));
    clFinish(q);
    /* 回调由驱动线程异步触发，给一点时间 */
    for (int spin = 0; spin < 100 && !g_callback_fired; spin++) Sleep(10);
    printf("callback fired: %s\n", g_callback_fired ? "yes" : "no");
    CHECK(g_callback_fired, "event callback");
    clReleaseEvent(evK3);

    clReleaseEvent(evW); clReleaseEvent(evK); clReleaseEvent(evR);
    clReleaseEvent(user); clReleaseEvent(evK2);
    clReleaseMemObject(bx); clReleaseMemObject(by);
    clReleaseKernel(k); clReleaseProgram(prog);
    clReleaseCommandQueue(q); clReleaseContext(ctx);
    free(hx); free(hy);
    printf("13 events PASS\n");
    return 0;
}
