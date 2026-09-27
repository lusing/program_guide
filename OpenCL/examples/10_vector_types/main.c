/* 10_vector_types —— 向量类型：字面量、分量/swizzle、重解释、显式转换、fp64 条件启用
 *
 * 内核三个：
 *  A) swizzle 演练：xyzw 访问、偶奇分量（.even/.odd）、向量字面量广播
 *  B) as_uint4(float4) 按位重解释 + convert_int_sat_rte 饱和舍入
 *  C) double 内核：先查 cl_khr_fp64 再启用（两台实测设备都支持）
 */
#include "cl_utils.h"

static const char* K_A =
"__kernel void swizzle(__global float4* out, __global const float4* in) {\n"
"    int i = get_global_id(0);\n"
"    float4 a = in[i];\n"
"    float4 b = (float4)(0.5f);            /* 标量广播 */\n"
"    float4 r = a.xyxy * b + a.wzyx;       /* swizzle 读写 */\n"
"    float2 lo = a.lo;                     /* 低半/高半 */\n"
"    float2 hi = a.hi;\n"
"    r.x += dot(lo, hi);\n"
"    out[i] = r;\n"
"}\n";

static const char* K_B =
"__kernel void bits(__global const float* f, __global uint* u, __global int* i4) {\n"
"    int g = get_global_id(0);\n"
"    float4 v = (float4)(f[g], f[g] * 2.0f, f[g] * -3.0f, 1e30f);\n"
"    uint4 raw = as_uint4(v);                       /* 按位重解释 */\n"
"    u[g * 4 + 0] = raw.x; u[g * 4 + 1] = raw.y;\n"
"    u[g * 4 + 2] = raw.z; u[g * 4 + 3] = raw.w;\n"
"    int4 ci = convert_int4_sat_rte(v);             /* 饱和 + 就近偶数舍入 */\n"
"    i4[g * 4 + 0] = ci.x; i4[g * 4 + 1] = ci.y;\n"
"    i4[g * 4 + 2] = ci.z; i4[g * 4 + 3] = ci.w;\n"
"}\n";

static const char* K_C =
"#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
"__kernel void dbl(__global const double* in, __global double* out) {\n"
"    int g = get_global_id(0);\n"
"    double2 v = (double2)(in[g], in[g] + 1.0);\n"
"    out[g] = dot(v, (double2)(3.0, 5.0));\n"
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

    /* 主机端类型宽度（cl_ 前缀类型保证跨平台） */
    printf("host sizes: cl_char=%zu cl_short=%zu cl_int=%zu cl_long=%zu "
           "cl_float=%zu cl_double=%zu cl_float4=%zu\n",
           sizeof(cl_char), sizeof(cl_short), sizeof(cl_int), sizeof(cl_long),
           sizeof(cl_float), sizeof(cl_double), sizeof(cl_float4));

    /* 设备端向量宽度偏好（NVIDIA GPU 通常全 1；Intel CPU native=8 揭示 SSE/AVX） */
    cl_uint pref = 0, nat = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT, sizeof(pref), &pref, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT, sizeof(nat), &nat, NULL));
    printf("vector width float: preferred=%u native=%u\n", pref, nat);

    /* ---- A: swizzle ---- */
    {
        cl_program p = clu_build_program(ctx, dev, K_A, NULL);
        cl_kernel k = clCreateKernel(p, "swizzle", &err);
        CL_CHECK(err);
        cl_float4 hin[4] = {
            {1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}, {13, 14, 15, 16}
        };
        cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(hin), hin, &err);
        CL_CHECK(err);
        cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hin), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bo));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bi));
        size_t g = 4;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        cl_float4 hout[4];
        CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
        /* CPU 复算：r = a.xyxy*0.5 + a.wzyx; r.x += dot(a.xy, a.zw)
           xyxy = (x,y,x,y)，wzyx = (w,z,y,x) —— 逐分量对齐别想岔 */
        int ok = 1;
        for (int i = 0; i < 4; i++) {
            cl_float4 a = hin[i];
            float r0 = a.s[0] * 0.5f + a.s[3] + (a.s[0] * a.s[2] + a.s[1] * a.s[3]);
            float r1 = a.s[1] * 0.5f + a.s[2];
            float r2 = a.s[0] * 0.5f + a.s[1];
            float r3 = a.s[1] * 0.5f + a.s[0];
            if (hout[i].s[0] != r0 || hout[i].s[1] != r1 ||
                hout[i].s[2] != r2 || hout[i].s[3] != r3) ok = 0;
        }
        printf("swizzle : out[0]=(%.1f,%.1f,%.1f,%.1f) %s\n",
               hout[0].s[0], hout[0].s[1], hout[0].s[2], hout[0].s[3],
               ok ? "verified" : "WRONG");
        CHECK(ok, "swizzle semantics");
        clReleaseMemObject(bi); clReleaseMemObject(bo); clReleaseKernel(k); clReleaseProgram(p);
    }

    /* ---- B: 重解释 + 饱和转换 ---- */
    {
        cl_program p = clu_build_program(ctx, dev, K_B, NULL);
        cl_kernel k = clCreateKernel(p, "bits", &err);
        CL_CHECK(err);
        float hf[8] = {1.5f, 2.5f, 3.5f, 4.5f, -1.5f, 100.25f, 7.0f, 0.125f};
        cl_uint hu[32]; cl_int hi[32];
        cl_mem bf = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(hf), hf, &err);
        CL_CHECK(err);
        cl_mem bu = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hu), NULL, &err);
        CL_CHECK(err);
        cl_mem bii = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hi), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bf));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bu));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bii));
        size_t g = 8;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bu, CL_TRUE, 0, sizeof(hu), hu, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bii, CL_TRUE, 0, sizeof(hi), hi, 0, NULL, NULL));
        int ok = 1;
        for (int i = 0; i < 8; i++) {
            float vals[4] = {hf[i], hf[i] * 2.0f, hf[i] * -3.0f, 1e30f};
            for (int j = 0; j < 4; j++) {
                cl_uint bits;
                memcpy(&bits, &vals[j], 4);
                if (hu[i * 4 + j] != bits) ok = 0;
            }
            /* 1e30 -> int 溢出：sat 应钳到 INT_MAX */
            if (hi[i * 4 + 3] != 2147483647) ok = 0;
            /* 2.5 舍入到偶数=2；-1.5 舍入到偶数=-2 */
            if (hf[i] == 1.5f && hi[i * 4 + 0] != 2) ok = 0;
        }
        if (hf[1] == 2.5f && hi[1 * 4 + 0] != 2) ok = 0;
        printf("bits   : as_uint4 bit-exact %s, convert_sat_rte 1e30->INT_MAX=%d, 2.5->%d\n",
               ok ? "ok" : "BAD", hi[0 * 4 + 3], hi[1 * 4 + 0]);
        CHECK(ok, "as/convert semantics");
        clReleaseMemObject(bf); clReleaseMemObject(bu); clReleaseMemObject(bii);
        clReleaseKernel(k); clReleaseProgram(p);
    }

    /* ---- C: fp64 条件启用 ---- */
    {
        char exts[8192] = {0};
        clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sizeof(exts), exts, NULL);
        if (strstr(exts, "cl_khr_fp64")) {
            cl_program p = clu_build_program(ctx, dev, K_C, NULL);
            cl_kernel k = clCreateKernel(p, "dbl", &err);
            CL_CHECK(err);
            double hin[16], hout[16];
            for (int i = 0; i < 16; i++) hin[i] = i + 0.25;
            cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                       sizeof(hin), hin, &err);
            CL_CHECK(err);
            cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hout), NULL, &err);
            CL_CHECK(err);
            CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bi));
            CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
            size_t g = 16;
            CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
            CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
            int ok = 1;
            for (int i = 0; i < 16; i++)
                if (hout[i] != (hin[i] * 3.0 + (hin[i] + 1.0) * 5.0)) ok = 0;
            printf("fp64   : cl_khr_fp64 present, double kernel %s (out[3]=%.2f)\n",
                   ok ? "verified" : "WRONG", hout[3]);
            CHECK(ok, "fp64 kernel");
            clReleaseMemObject(bi); clReleaseMemObject(bo);
            clReleaseKernel(k); clReleaseProgram(p);
        } else {
            printf("fp64   : cl_khr_fp64 NOT present -> double kernels unavailable\n");
        }
    }

    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("10 vector_types PASS\n");
    return 0;
}
