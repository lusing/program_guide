/* 26_multidevice —— 跨平台/多设备并行：GPU + CPU 分块同算
 *
 * 本机实况：NVIDIA CUDA 平台(RTX 3060) + Intel 平台(12700F CPU)。
 * 同一个 saxpy 内核，各自上下文/队列/缓冲区，主机把 N 个元素切成两半，
 * 分别下发两台设备异步执行，再各自读回、合并校验、分别计时。
 * 这是“多上下文、主机调度”式多设备并行的最小完整样例（无 SVM/无共享上下文，
 * OpenCL 1.2 就能跑）。若机器只有一台设备，则退化为单设备也照常 PASS。
 */
#include <math.h>
#include <windows.h>
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void saxpy(__global const float* x, __global float* y,\n"
"                    const float a, const int n) {\n"
"    int i = get_global_id(0);\n"
"    if (i < n) y[i] = a * x[i] + y[i];\n"
"}\n";

typedef struct {
    cl_platform_id plat;
    cl_device_id dev;
    cl_context ctx;
    cl_command_queue q;
    cl_program prog;
    cl_kernel kern;
    cl_mem bx, by;
    char name[128];
    double kernel_ms;
} devslot_t;

int main(void) {
    cl_uint nplat = 0;
    printf("enumerating platforms...\n");
    CL_CHECK(clGetPlatformIDs(0, NULL, &nplat));
    CHECK(nplat > 0, "no platform");
    cl_platform_id plats[8];
    CL_CHECK(clGetPlatformIDs(nplat > 8 ? 8 : nplat, plats, NULL));

    /* 每个平台挑一台设备（先 GPU 后 CPU），最多两台演示 */
    devslot_t slots[2];
    int nslots = 0;
    for (cl_uint i = 0; i < nplat && i < 8 && nslots < 2; i++) {
        cl_device_id dev = NULL;
        if (clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_GPU, 1, &dev, NULL) != CL_SUCCESS)
            clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_CPU, 1, &dev, NULL);
        if (!dev) continue;
        devslot_t* s = &slots[nslots++];
        s->plat = plats[i];
        s->dev = dev;
        clGetDeviceInfo(dev, CL_DEVICE_NAME, sizeof(s->name), s->name, NULL);
        cl_int err;
        s->ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
        CL_CHECK(err);
        const cl_queue_properties props[] = {
            CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE, 0
        };
        s->q = clCreateCommandQueueWithProperties(s->ctx, dev, props, &err);
        CL_CHECK(err);
        s->prog = clu_build_program(s->ctx, dev, K_SRC, NULL);
        s->kern = clCreateKernel(s->prog, "saxpy", &err);
        CL_CHECK(err);
        printf("slot %d: %s\n", nslots - 1, s->name);
    }
    CHECK(nslots >= 1, "no usable device");
    if (nslots == 1)
        printf("only one device found -> single-device mode\n");

    /* 数据：2M float，前半给 slot0、后半给 slot1（单设备则全给）。
       数据量取小：Intel CPU 运行时的耗时对系统负载非常敏感（实测同一内核
       6ms~50ms 波动），太大在满载机器上会拖垮整体验证。 */
    const int N = 2 << 20;
    float* hx = (float*)malloc(N * sizeof(float));
    float* hy = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) { hx[i] = (float)(i % 512) * 0.25f; hy[i] = 1.0f; }

    int chunk = N / nslots;
    cl_event evs[2];
    LARGE_INTEGER f, t0, t1;
    QueryPerformanceFrequency(&f);

    QueryPerformanceCounter(&t0);
    for (int s = 0; s < nslots; s++) {
        int off = s * chunk;
        int cnt = (s == nslots - 1) ? (N - off) : chunk;
        cl_int n = cnt;
        float a = 3.0f;
        cl_int err;
        slots[s].bx = clCreateBuffer(slots[s].ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     cnt * sizeof(float), hx + off, &err);
        CL_CHECK(err);
        slots[s].by = clCreateBuffer(slots[s].ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                     cnt * sizeof(float), hy + off, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(slots[s].kern, 0, sizeof(cl_mem), &slots[s].bx));
        CL_CHECK(clSetKernelArg(slots[s].kern, 1, sizeof(cl_mem), &slots[s].by));
        CL_CHECK(clSetKernelArg(slots[s].kern, 2, sizeof(float), &a));
        CL_CHECK(clSetKernelArg(slots[s].kern, 3, sizeof(cl_int), &n));
        size_t g = cnt;
        CL_CHECK(clEnqueueNDRangeKernel(slots[s].q, slots[s].kern, 1, NULL, &g, NULL,
                                        0, NULL, &evs[s]));
    }
    /* 主机不等待，两个设备并行跑；现在才分别 join */
    for (int s = 0; s < nslots; s++) {
        CL_CHECK(clWaitForEvents(1, &evs[s]));
        cl_ulong a, b;
        clGetEventProfilingInfo(evs[s], CL_PROFILING_COMMAND_START, sizeof(a), &a, NULL);
        clGetEventProfilingInfo(evs[s], CL_PROFILING_COMMAND_END, sizeof(b), &b, NULL);
        slots[s].kernel_ms = (b - a) / 1e6;
        clReleaseEvent(evs[s]);
    }
    /* 读回各分片 */
    for (int s = 0; s < nslots; s++) {
        int off = s * chunk;
        int cnt = (s == nslots - 1) ? (N - off) : chunk;
        CL_CHECK(clEnqueueReadBuffer(slots[s].q, slots[s].by, CL_TRUE, 0,
                                     cnt * sizeof(float), hy + off, 0, NULL, NULL));
    }
    QueryPerformanceCounter(&t1);
    double wall = (double)(t1.QuadPart - t0.QuadPart) * 1000.0 / f.QuadPart;

    for (int s = 0; s < nslots; s++)
        printf("slot %d (%s): kernel %.2f ms for %d elements\n",
               s, slots[s].name, slots[s].kernel_ms,
               (s == nslots - 1) ? (N - s * chunk) : chunk);
    printf("wall clock (dispatch..merge): %.1f ms\n", wall);

    int bad = 0;
    for (int i = 0; i < N; i += 9973)
        if (fabsf(hy[i] - (3.0f * hx[i] + 1.0f)) > 1e-4f) { bad++; break; }
    printf("merged result: %s\n", bad ? "WRONG" : "verified across all chunks");
    CHECK(!bad, "multi-device merge");

    for (int s = 0; s < nslots; s++) {
        clReleaseMemObject(slots[s].bx);
        clReleaseMemObject(slots[s].by);
        clReleaseKernel(slots[s].kern);
        clReleaseProgram(slots[s].prog);
        clReleaseCommandQueue(slots[s].q);
        clReleaseContext(slots[s].ctx);
    }
    free(hx); free(hy);
    printf("26 multidevice PASS\n");
    return 0;
}
