/* 03_hello —— 第一个 OpenCL 程序：向量加法
 *
 * 完整走一遍主机端八步：选平台设备 -> 上下文 -> 队列 -> 程序 -> 内核
 *                      -> 缓冲区 -> 执行 -> 读回校验
 * 全部 API 用 CL_CHECK 包裹（common/cl_utils.h）。
 */
#include "cl_utils.h"

static const char* K_SRC = "\
__kernel void vec_add(__global const float* a,                 \n\
                      __global const float* b,                 \n\
                      __global float* c,                       \n\
                      const unsigned int n)                    \n\
{                                                               \n\
    unsigned int i = get_global_id(0);                          \n\
    if (i < n)                                                  \n\
        c[i] = a[i] + b[i];                                     \n\
}                                                               \n\
";

int main(void) {
    const size_t N = 1024;
    float* ha = (float*)malloc(N * sizeof(float));
    float* hb = (float*)malloc(N * sizeof(float));
    float* hc = (float*)calloc(N, sizeof(float));
    CHECK(ha && hb && hc, "host alloc");

    for (size_t i = 0; i < N; i++) {
        ha[i] = (float)(i % 97) * 0.5f;
        hb[i] = (float)((i * 7) % 13) * -1.0f;
    }

    /* 1. 平台与设备（优先 GPU） */
    cl_platform_id platform;
    cl_device_id device;
    clu_pick_device(&platform, &device, NULL);
    clu_print_device_brief(device);

    /* 2. 上下文 */
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    CL_CHECK(err);

    /* 3. 命令队列（OpenCL 2.0+ 用 WithProperties；NULL 属性 = 顺序队列） */
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, device, NULL, &err);
    CL_CHECK(err);

    /* 4. 程序（源码 -> 编译） */
    cl_program prog = clu_build_program(ctx, device, K_SRC, NULL);

    /* 5. 内核 */
    cl_kernel k = clCreateKernel(prog, "vec_add", &err);
    CL_CHECK(err);

    /* 6. 缓冲区（a/b 只读并带初始数据，c 只写） */
    cl_mem ba = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               N * sizeof(float), ha, &err);
    CL_CHECK(err);
    cl_mem bb = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               N * sizeof(float), hb, &err);
    CL_CHECK(err);
    cl_mem bc = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY,
                               N * sizeof(float), NULL, &err);
    CL_CHECK(err);

    cl_uint un = (cl_uint)N;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &ba));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bb));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bc));
    CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_uint), &un));

    /* 7. 执行（一维 NDRange，local size 交给运行时选择） */
    size_t global = N;
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &global, NULL, 0, NULL, NULL));

    /* 8. 读回并校验 */
    CL_CHECK(clEnqueueReadBuffer(q, bc, CL_TRUE, 0, N * sizeof(float), hc, 0, NULL, NULL));

    int ok = 1;
    for (size_t i = 0; i < N; i++) {
        if (hc[i] != ha[i] + hb[i]) { ok = 0; printf("mismatch at %zu\n", i); break; }
    }
    printf("c[0]=%.2f c[1]=%.2f c[1023]=%.2f\n", hc[0], hc[1], hc[1023]);
    printf("%s\n", ok ? "03 hello PASS" : "03 hello FAIL");

    clReleaseMemObject(ba);
    clReleaseMemObject(bb);
    clReleaseMemObject(bc);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(ha); free(hb); free(hc);
    return ok ? 0 : 1;
}
