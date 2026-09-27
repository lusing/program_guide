/* 05_context_queue —— 上下文生命周期与命令队列形态
 *
 * 演示：
 *  1) 带属性上下文（CL_CONTEXT_PLATFORM）与引用计数观测
 *     （clRetainContext/clReleaseContext 如何影响 CL_CONTEXT_REFERENCE_COUNT）
 *  2) 两种队列构造：NULL 属性（顺序）与 CL_QUEUE_PROPERTIES
 *     （profiling / out-of-order 位）——以及 clCreateCommandQueue 已弃用的说明
 *  3) clFinish 与 clEnqueueMarkerWithWaitList 的用法
 */
#include "cl_utils.h"

static cl_uint ref_count(cl_context ctx) {
    cl_uint rc = 0;
    CL_CHECK(clGetContextInfo(ctx, CL_CONTEXT_REFERENCE_COUNT, sizeof(rc), &rc, NULL));
    return rc;
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);

    /* --- 1) 带平台属性的上下文（教学写法：属性数组以 0 结尾） --- */
    cl_context_properties props[] = {
        CL_CONTEXT_PLATFORM, (cl_context_properties)plat,
        0
    };
    cl_int err;
    cl_context ctx = clCreateContext(props, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);

    /* 上下文里能查到设备列表 */
    size_t bytes = 0;
    CL_CHECK(clGetContextInfo(ctx, CL_CONTEXT_DEVICES, 0, NULL, &bytes));
    CHECK(bytes == sizeof(cl_device_id), "context should hold exactly 1 device");
    cl_device_id ctx_dev = NULL;
    CL_CHECK(clGetContextInfo(ctx, CL_CONTEXT_DEVICES, bytes, &ctx_dev, NULL));
    CHECK(ctx_dev == dev, "context device mismatch");

    /* 引用计数：创建=1，Retain+1，Release-1（不能 Release 到 0 再用） */
    cl_uint r0 = ref_count(ctx);
    CL_CHECK(clRetainContext(ctx));
    cl_uint r1 = ref_count(ctx);
    CL_CHECK(clReleaseContext(ctx));
    cl_uint r2 = ref_count(ctx);
    printf("refcount: create=%u retain=%u release=%u\n", r0, r1, r2);
    CHECK(r1 == r0 + 1 && r2 == r0, "refcount tracking");

    /* --- 2) 队列构造 --- */
    /* OpenCL 1.x 的 clCreateCommandQueue 在 2.0 起弃用（3.0 头里默认不声明，
       除非定义 CL_USE_DEPRECATED_OPENCL_1_2_APIS）——现代代码一律用
       clCreateCommandQueueWithProperties。NULL 属性 = 顺序队列、无 profiling。 */
    cl_command_queue q_plain = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
    CL_CHECK(err);

    const cl_queue_properties qprops[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)(CL_QUEUE_PROFILING_ENABLE),
        0
    };
    cl_command_queue q_prof = clCreateCommandQueueWithProperties(ctx, dev, qprops, &err);
    CL_CHECK(err);

    /* 查询队列属性与所属设备 */
    cl_command_queue_properties got = 0;
    CL_CHECK(clGetCommandQueueInfo(q_prof, CL_QUEUE_PROPERTIES, sizeof(got), &got, NULL));
    cl_device_id q_dev = NULL;
    CL_CHECK(clGetCommandQueueInfo(q_prof, CL_QUEUE_DEVICE, sizeof(q_dev), &q_dev, NULL));
    cl_context q_ctx = NULL;
    CL_CHECK(clGetCommandQueueInfo(q_prof, CL_QUEUE_CONTEXT, sizeof(q_ctx), &q_ctx, NULL));
    CHECK(q_dev == dev && q_ctx == ctx, "queue device/context mismatch");
    printf("queue props: plain=%llu prof=%llu (profiling bit=%d)\n",
           (unsigned long long)0, (unsigned long long)got,
           (got & CL_QUEUE_PROFILING_ENABLE) ? 1 : 0);
    CHECK((got & CL_QUEUE_PROFILING_ENABLE) != 0, "profiling queue flag");

    /* --- 3) 在队列上跑一个内核，用 marker+clFinish 做同步点 --- */
    const char* src =
        "__kernel void scale(__global const float* x, __global float* y, float k) {\n"
        "    int i = get_global_id(0);\n"
        "    y[i] = x[i] * k;\n"
        "}\n";
    cl_program prog = clu_build_program(ctx, dev, src, NULL);
    cl_kernel k = clCreateKernel(prog, "scale", &err);
    CL_CHECK(err);

    float hx[64], hy[64] = {0};
    for (int i = 0; i < 64; i++) hx[i] = (float)i;
    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               sizeof(hx), hx, &err);
    CL_CHECK(err);
    cl_mem by = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hy), NULL, &err);
    CL_CHECK(err);
    float kk = 3.0f;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &by));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &kk));

    size_t g = 64;
    CL_CHECK(clEnqueueNDRangeKernel(q_plain, k, 1, NULL, &g, NULL, 0, NULL, NULL));

    /* marker：排进队列一个"等待清单为空"的标记事件；host 上等它 */
    cl_event marker = NULL;
    CL_CHECK(clEnqueueMarkerWithWaitList(q_plain, 0, NULL, &marker));
    CL_CHECK(clWaitForEvents(1, &marker));
    clReleaseEvent(marker);
    CL_CHECK(clFinish(q_plain));   /* 兜底：队列里所有命令全部完成 */

    CL_CHECK(clEnqueueReadBuffer(q_plain, by, CL_TRUE, 0, sizeof(hy), hy, 0, NULL, NULL));
    int ok = 1;
    for (int i = 0; i < 64; i++) if (hy[i] != hx[i] * 3.0f) { ok = 0; break; }
    printf("scale kernel: y[10]=%.1f (expect %.1f)\n", hy[10], hx[10] * 3.0f);

    clReleaseMemObject(bx);
    clReleaseMemObject(by);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q_plain);
    clReleaseCommandQueue(q_prof);
    clReleaseContext(ctx);

    printf("%s\n", ok ? "05 context_queue PASS" : "05 context_queue FAIL");
    return ok ? 0 : 1;
}
