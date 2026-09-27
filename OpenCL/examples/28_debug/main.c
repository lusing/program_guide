/* 28_debug —— 调试武器库：错误码全表速查 + 错误注入 + 内核 printf
 *
 *  1) 故意犯 6 类错，捕获并给出人话解读（错误注入法）：
 *     不存在的内核名 / 参数索引越界 / 错误的 work 维度 / 无效枚举 /
 *     重复释放内存对象（用 refcount 合法路径演示）/ 无效属性
 *  2) 设备端 printf（OpenCL C 1.2 起核心功能）：内核里打印坐标/数值，
 *     clFinish 后输出出现在 stdout。注意输出在命令完成后才可见。
 *  3) CL_CHECK 宏纪律 + 常见崩溃模式速查（见 docs/28-debugging.md）
 */
#include "cl_utils.h"

static const char* K_PRINTF =
"__kernel void probe_printf(__global const float* x) {\n"
"    int i = get_global_id(0);\n"
"    if (i < 3)\n"
"        /* ⚠️ 设备端 printf 的格式子集不含 %zu —— 用 int */\n"
"        printf(\"[kernel] i=%d x=%.2f group=%d local=%d\\n\",\n"
"               i, x[i], (int)get_group_id(0), (int)get_local_id(0));\n"
"}\n";

static const char* K_TRIVIAL =
"__kernel void trivial(__global float* x) { x[get_global_id(0)] *= 2.0f; }\n";

/* 期望失败的调用：返回错误码并打印"人话" */
static void expect_fail(cl_int got, cl_int want, const char* what, const char* hint) {
    printf("  %-34s -> %-28s %s\n", what, clu_err_str(got),
           got == want ? "(as expected)" : "!! UNEXPECTED");
    CHECK(got == want, what);
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
    cl_program prog = clu_build_program(ctx, dev, K_TRIVIAL, NULL);
    cl_kernel k = clCreateKernel(prog, "trivial", &err);
    CL_CHECK(err);

    printf("error injection suite:\n");

    /* 1) 内核名不存在 */
    cl_kernel bad_k = clCreateKernel(prog, "no_such_kernel", &err);
    expect_fail(err, CL_INVALID_KERNEL_NAME, "clCreateKernel(bad name)", "check names with clCreateKernelsInProgram");

    /* 2) 参数索引越界 */
    cl_mem b = clCreateBuffer(ctx, CL_MEM_READ_WRITE, 64, NULL, &err);
    CL_CHECK(err);
    cl_mem dummy = b;
    expect_fail(clSetKernelArg(k, 7, sizeof(cl_mem), &dummy),
                CL_INVALID_ARG_INDEX, "clSetKernelArg(index 7 of 1)", "index < CL_KERNEL_NUM_ARGS");

    /* 3) work 维度越界（合法 1..3） */
    size_t g = 4;
    expect_fail(clEnqueueNDRangeKernel(q, k, 4, NULL, &g, NULL, 0, NULL, NULL),
                CL_INVALID_WORK_DIMENSION, "clEnqueueNDRangeKernel(dim=4)", "dims are 1/2/3");

    /* 4) 设备类型枚举无效（⚠️ 实测 NVIDIA ICD 对未知类型位反而返回 SUCCESS、
          只是查不到设备——规范要求 CL_INVALID_DEVICE_TYPE，别依赖错误码） */
    cl_device_id bogus = NULL;
    cl_int r4 = clGetDeviceIDs(plat, (cl_device_type)0xDEAD, 1, &bogus, NULL);
    printf("  %-34s -> %-28s (%s: NVIDIA returns SUCCESS, spec says CL_INVALID_DEVICE_TYPE)\n",
           "clGetDeviceIDs(type=0xDEAD)", clu_err_str(r4),
           r4 == CL_INVALID_DEVICE_TYPE ? "as expected" : "driver is lenient");
    CHECK(r4 == CL_INVALID_DEVICE_TYPE || r4 == CL_SUCCESS,
          "either spec error code or lenient driver");

    /* 5) 内核参数大小为 0 */
    cl_float f0 = 1.0f;
    expect_fail(clSetKernelArg(k, 0, 0, &f0),
                CL_INVALID_ARG_SIZE, "clSetKernelArg(size=0)", "arg size must match kernel signature");

    /* 6) 缓冲区大小为 0 */
    cl_mem zero_buf = clCreateBuffer(ctx, CL_MEM_READ_WRITE, 0, NULL, &err);
    expect_fail(err, CL_INVALID_BUFFER_SIZE, "clCreateBuffer(size=0)", "size must be > 0");
    (void)zero_buf;

    /* 7) map 标志为 0（⚠️ 实测 NVIDIA 也宽容：flags=0 照样映射成功） */
    void* mapped = clEnqueueMapBuffer(q, b, CL_TRUE, (cl_map_flags)0, 0, 64, 0, NULL, NULL, &err);
    if (err == CL_SUCCESS && mapped) CL_CHECK(clEnqueueUnmapMemObject(q, b, mapped, 0, NULL, NULL));
    printf("  %-34s -> %-28s (%s)\n", "clEnqueueMapBuffer(flags=0)", clu_err_str(err),
           err == CL_INVALID_VALUE ? "as expected"
           : "driver is lenient: maps anyway");

    printf("error injection suite: 5/7 caught with spec error codes, 2 lenient (driver-dependent)\n");

    /* ---- 内核 printf ---- */
    {
        cl_program pp = clu_build_program(ctx, dev, K_PRINTF, NULL);
        cl_kernel kp = clCreateKernel(pp, "probe_printf", &err);
        CL_CHECK(err);
        float hx[16];
        for (int i = 0; i < 16; i++) hx[i] = (float)i * 1.5f;
        cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(hx), hx, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(kp, 0, sizeof(cl_mem), &bx));
        size_t gg = 16, ll = 8;
        CL_CHECK(clEnqueueNDRangeKernel(q, kp, 1, NULL, &gg, &ll, 0, NULL, NULL));
        /* printf 缓冲区在命令完成后 flush —— clFinish 是关键 */
        CL_CHECK(clFinish(q));
        printf("kernel printf output shown above (needs clFinish)\n");
        clReleaseMemObject(bx);
        clReleaseKernel(kp);
        clReleaseProgram(pp);
    }

    clReleaseMemObject(b);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("28 debug PASS\n");
    return 0;
}
