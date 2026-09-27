/* 09_address_spaces —— 设备端四级地址空间一网打尽
 *
 * 内核 mix() 同时使用四种空间：
 *   __global   ：主机传入的大数组
 *   __constant ：内核作用域常量（编译期固化，查 CL_DEVICE_MAX_CONSTANT_ARGS）
 *   __local    ：静态数组 + 动态分配（clSetKernelArg 传 size、指针 NULL）
 *   __private  ：寄存器/私有变量
 * 计算设计成"四级空间缺一不可"：
 *   out[g] = dot(constant 权重, global 输入经 local 两阶段搬运后的邻居窗口) + 私有计数
 */
#include <math.h>
#include "cl_utils.h"

static const char* K_SRC =
"__constant float4 kW = (float4)(0.1f, 0.2f, 0.3f, 0.4f);\n"   /* constant（程序作用域） */
"\n"
"__kernel void mix(__global const float* in,                     /* global */\n"
"                  __global float* out,\n"
"                  __local float* stage,                         /* local（动态大小） */\n"
"                  const int n) {\n"
"    int gid = get_global_id(0);\n"
"    int lid = get_local_id(0);\n"
"    int lsz = get_local_size(0);\n"
"    __local float stat[256];                                    /* local（静态数组） */\n"
"    float priv = 0.0f;                                          /* private */\n"
"\n"
"    /* 阶段 1：global -> local 动态缓冲 + 静态缓冲（同一数据，两种声明） */\n"
"    stage[lid] = (gid < n) ? in[gid] : 0.0f;\n"
"    stat[lid]  = (gid < n) ? in[gid] : 0.0f;\n"
"    barrier(CLK_LOCAL_MEM_FENCE);\n"
"\n"
"    /* 阶段 2：用 constant 权重混合 local 里的邻居窗口，私有变量做累加 */\n"
"    int nxt = (lid + 1) % lsz;\n"
"    priv = stage[lid]   * kW.x\n"
"         + stage[nxt]   * kW.y\n"
"         + stat[(lid + lsz - 1) % lsz] * kW.z\n"
"         + in[gid]      * kW.w;\n"
"    if (gid < n) out[gid] = priv;\n"
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

    /* 每内核最多多少个 __constant 参数（含程序作用域常量） */
    cl_uint max_const = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_CONSTANT_ARGS, sizeof(max_const), &max_const, NULL));
    cl_ulong const_sz = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE, sizeof(const_sz), &const_sz, NULL));
    printf("constant: max args=%u  max buffer=%llu KB\n", max_const, (unsigned long long)(const_sz >> 10));

    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);
    cl_kernel k = clCreateKernel(prog, "mix", &err);
    CL_CHECK(err);

    const int N = 256, L = 256;                 /* 一个工作组跑满 */
    float* hin = (float*)malloc(N * sizeof(float));
    float* hout = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) hin[i] = (float)(i + 1);

    cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               N * sizeof(float), hin, &err);
    CL_CHECK(err);
    cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
    CL_CHECK(err);
    cl_int n = N;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bi));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
    /* local 动态参数：size = 字节数，value = NULL */
    CL_CHECK(clSetKernelArg(k, 2, L * sizeof(float), NULL));
    CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_int), &n));

    size_t global = N, local = L;
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &global, &local, 0, NULL, NULL));
    CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, N * sizeof(float), hout, 0, NULL, NULL));

    /* CPU 参考计算 */
    int ok = 1;
    for (int i = 0; i < N; i++) {
        int lid = i % L;
        float ref = hin[i] * 0.1f
                  + hin[(i + 1) % N] * 0.2f          /* 组内下一个（N==L 时环绕=组内环绕） */
                  + hin[(lid + L - 1) % L + 0] * 0.3f  /* 组内上一个 */
                  + hin[i] * 0.4f;
        if (fabsf(hout[i] - ref) > 1e-4f) {
            printf("mismatch %d: got %.3f expect %.3f\n", i, hout[i], ref);
            ok = 0;
            break;
        }
    }
    printf("mix across global/constant/local/private %s\n", ok ? "verified" : "WRONG");

    clReleaseMemObject(bi);
    clReleaseMemObject(bo);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hin); free(hout);
    CHECK(ok, "address space mix");
    printf("09 address_spaces PASS\n");
    return 0;
}
