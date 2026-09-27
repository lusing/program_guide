/* 14_profiling —— 事件剖析：write / kernel / read 的时间线
 *
 * 前提：队列要带 CL_QUEUE_PROFILING_ENABLE 创建，
 * 否则 clGetEventProfilingInfo 返回 CL_PROFILING_INFO_NOT_AVAILABLE。
 * 四个时间点（纳秒，设备时钟）：QUEUED -> SUBMIT -> START -> END
 *  - 排队等待 = SUBMIT - QUEUED，提交等待 = START - SUBMIT
 *  - 纯执行 = END - START
 * 顺便演示：内核时间随数据量翻倍的 scaling、
 * 以及“读回前后用事件而非 clFinish 才能拿到时间线”的正确姿势。
 */
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void saxpy(__global const float* x, __global float* y, float a) {\n"
"    int i = get_global_id(0);\n"
"    y[i] = a * x[i] + y[i];\n"
"}\n";

static double prof_ms(cl_event ev, cl_profiling_info from, cl_profiling_info to) {
    cl_ulong t0 = 0, t1 = 0;
    size_t r = 0;
    CL_CHECK(clGetEventProfilingInfo(ev, from, sizeof(t0), &t0, &r));
    CL_CHECK(clGetEventProfilingInfo(ev, to, sizeof(t1), &t1, &r));
    return (double)(t1 - t0) / 1e6;   /* ns -> ms */
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;

    /* 剖析必须在队列属性里开启 */
    const cl_queue_properties props[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE,
        0
    };
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
    CL_CHECK(err);
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);
    cl_kernel k = clCreateKernel(prog, "saxpy", &err);
    CL_CHECK(err);

    const size_t N = 8u << 20;                 /* 8M floats = 32MB */
    float* hx = (float*)malloc(N * sizeof(float));
    float* hy = (float*)malloc(N * sizeof(float));
    for (size_t i = 0; i < N; i++) { hx[i] = 1.0f; hy[i] = 2.0f; }

    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY, N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    cl_mem by = clCreateBuffer(ctx, CL_MEM_READ_WRITE, N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    float a = 3.0f;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &by));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &a));

    cl_event evW = NULL, evK = NULL, evR = NULL;
    size_t g = N;

    printf("stage      queued->submit  submit->start  run(end-start)  total\n");
    printf("-------------------------------------------------------------\n");

    CL_CHECK(clEnqueueWriteBuffer(q, bx, CL_FALSE, 0, N * sizeof(float), hx, 0, NULL, &evW));
    CL_CHECK(clEnqueueWriteBuffer(q, by, CL_FALSE, 0, N * sizeof(float), hy, 0, NULL, NULL));
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, &evK));
    CL_CHECK(clEnqueueReadBuffer(q, by, CL_FALSE, 0, N * sizeof(float), hy, 0, NULL, &evR));
    CL_CHECK(clWaitForEvents(1, &evR));

    double wq = prof_ms(evW, CL_PROFILING_COMMAND_QUEUED, CL_PROFILING_COMMAND_SUBMIT);
    double ws = prof_ms(evW, CL_PROFILING_COMMAND_SUBMIT, CL_PROFILING_COMMAND_START);
    double wr = prof_ms(evW, CL_PROFILING_COMMAND_START, CL_PROFILING_COMMAND_END);
    printf("%-10s %12.3fms %13.3fms %13.3fms %8.1fms\n", "write", wq, ws, wr, wq + ws + wr);

    double kq = prof_ms(evK, CL_PROFILING_COMMAND_QUEUED, CL_PROFILING_COMMAND_SUBMIT);
    double ks = prof_ms(evK, CL_PROFILING_COMMAND_SUBMIT, CL_PROFILING_COMMAND_START);
    double kr = prof_ms(evK, CL_PROFILING_COMMAND_START, CL_PROFILING_COMMAND_END);
    printf("%-10s %12.3fms %13.3fms %13.3fms %8.1fms\n", "kernel", kq, ks, kr, kq + ks + kr);

    double rq = prof_ms(evR, CL_PROFILING_COMMAND_QUEUED, CL_PROFILING_COMMAND_SUBMIT);
    double rs = prof_ms(evR, CL_PROFILING_COMMAND_SUBMIT, CL_PROFILING_COMMAND_START);
    double rr = prof_ms(evR, CL_PROFILING_COMMAND_START, CL_PROFILING_COMMAND_END);
    printf("%-10s %12.3fms %13.3fms %13.3fms %8.1fms\n", "read", rq, rs, rr, rq + rs + rr);

    /* 带宽：write/read 按 32MB 数据量估算 GB/s */
    double gb = (double)(N * sizeof(float)) / (1024.0 * 1024.0 * 1024.0);
    printf("write bandwidth ~ %.1f GB/s, read ~ %.1f GB/s (32MB each)\n",
           gb / (wr / 1000.0), gb / (rr / 1000.0));

    /* 校验：3*1+2 = 5 */
    int ok = 1;
    for (size_t i = 0; i < N; i += 1048573) if (hy[i] != 5.0f) { ok = 0; break; }
    CHECK(ok, "saxpy result");
    CHECK(wr > 0 && kr > 0 && rr > 0, "positive run times");

    /* 反面教材：无 profiling 的队列查询事件剖析 -> CL_PROFILING_INFO_NOT_AVAILABLE */
    {
        cl_command_queue qp = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
        CL_CHECK(err);
        cl_event e = NULL;
        CL_CHECK(clEnqueueNDRangeKernel(qp, k, 1, NULL, &g, NULL, 0, NULL, &e));
        clFinish(qp);
        cl_ulong t = 0;
        cl_int rc = clGetEventProfilingInfo(e, CL_PROFILING_COMMAND_START, sizeof(t), &t, NULL);
        printf("profiling on plain queue -> %s (%d)\n", clu_err_str(rc), rc);
        CHECK(rc == CL_PROFILING_INFO_NOT_AVAILABLE, "plain queue must reject profiling");
        clReleaseEvent(e);
        clReleaseCommandQueue(qp);
    }

    clReleaseEvent(evW); clReleaseEvent(evK); clReleaseEvent(evR);
    clReleaseMemObject(bx); clReleaseMemObject(by);
    clReleaseKernel(k); clReleaseProgram(prog);
    clReleaseCommandQueue(q); clReleaseContext(ctx);
    free(hx); free(hy);
    printf("14 profiling PASS\n");
    return 0;
}
