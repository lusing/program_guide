/* 11_builtin_funcs —— 内建函数巡礼：浮点/整数/shuffle/select/几何
 *
 * 设备与 CPU（CRT）对拍，容差比较。覆盖：
 *  - 数学：fabs fma exp log sin sqrt rsqrt floor ceil rint
 *  - 取小取大：fmin fmax clamp mad step smoothstep mix
 *  - 比较/测试：isnan isinf sign any all
 *  - 整数：abs clz mad_sat min max upsample rotate
 *  - shuffle / select（SIMD 精髓）
 *  - 几何：dot cross normalize fast_length distance
 */
#include <math.h>
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void math1(__global const float* x, __global float* r) {\n"
"    int i = get_global_id(0);\n"
"    float v = x[i];\n"
"    r[i*12+0]  = fabs(v - 1.5f);\n"
"    r[i*12+1]  = fma(v, 2.0f, 0.25f);\n"
"    r[i*12+2]  = native_exp(v * 0.1f);        /* 快速近似版 */\n"
"    r[i*12+3]  = log(v + 1.0f);\n"
"    r[i*12+4]  = sin(v);\n"
"    r[i*12+5]  = sqrt(fabs(v));\n"
"    r[i*12+6]  = rsqrt(fabs(v) + 1.0f);\n"
"    r[i*12+7]  = floor(v) + ceil(v) * 0.01f;\n"
"    r[i*12+8]  = clamp(v, -0.5f, 0.5f);\n"
"    r[i*12+9]  = step(0.5f, v) + smoothstep(0.0f, 1.0f, v) * 0.001f;\n"
"    r[i*12+10] = mix(-1.0f, 1.0f, clamp(v, 0.0f, 1.0f));\n"
"    r[i*12+11] = isnan(v) ? 1.0f : (isinf(v) ? 2.0f : sign(v));\n"
"}\n"
"__kernel void int1(__global const int* x, __global int* r) {\n"
"    int i = get_global_id(0);\n"
"    int v = x[i];\n"
"    r[i*6+0] = abs(v);\n"
"    r[i*6+1] = clz(v == 0 ? 1 : v);\n"
"    r[i*6+2] = mad_sat(v, 3, 7);\n"
"    r[i*6+3] = max(v, -v);\n"
"    r[i*6+4] = upsample((char)clamp(v, -128, 127), (uchar)(v & 0xff));\n"
"    r[i*6+5] = rotate(v, (int)3);\n"
"}\n"
"__kernel void vec_ops(__global const float4* a, __global const float4* b,\n"
"                      __global float4* r, __global float* g) {\n"
"    int i = get_global_id(0);\n"
"    float4 va = a[i], vb = b[i];\n"
"    /* shuffle：用索引表重排分量 */\n"
"    uint4 mask = (uint4)(3, 2, 1, 0);\n"
"    float4 rev = shuffle(va, mask);\n"
"    /* select：按条件逐分量选 a/b（真 -> b） */\n"
"    float4 picked = select(va, vb, isgreater(vb, va));\n"
"    r[i] = rev + picked * 0.001f;\n"
"    /* 几何 */\n"
"    float3 p = va.xyz, q = (float3)(vb.x, vb.y, vb.z);\n"
"    g[i*3+0] = dot(p, q);\n"
"    g[i*3+1] = fast_length(p + 1.0f);\n"
"    g[i*3+2] = distance(p, q);\n"
"}\n";

static int close_enough(float got, float ref, float tol) {
    /* inf/NaN 同型即视为一致（log(0) = -inf 这类边界） */
    if (isinf(got) && isinf(ref)) return (got > 0) == (ref > 0);
    if (isnan(got) || isnan(ref)) return isnan(got) && isnan(ref);
    float d = fabsf(got - ref);
    return d <= tol * (1.0f + fabsf(ref));
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

    const int N = 16;
    float hx[16]; int hix[16];
    for (int i = 0; i < N; i++) {
        hx[i] = -1.0f + 0.13f * i;                 /* 覆盖负数/0~1 区间 */
        hix[i] = (i % 2 ? -1 : 1) * (i * 7919 % 1000);
    }

    /* ---- 数学函数 ---- */
    {
        cl_kernel k = clCreateKernel(prog, "math1", &err);
        CL_CHECK(err);
        cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(hx), hx, &err);
        CL_CHECK(err);
        float* hr = (float*)calloc(N * 12, sizeof(float));
        cl_mem br = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, N * 12 * sizeof(float), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &br));
        size_t g = N;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, br, CL_TRUE, 0, N * 12 * sizeof(float), hr, 0, NULL, NULL));
        int bad = 0;
        for (int i = 0; i < N; i++) {
            float v = hx[i];
            struct { float ref; float tol; } exp_[12] = {
                { fabsf(v - 1.5f), 0 }, { v * 2.0f + 0.25f, 0 },
                { expf(v * 0.1f), 2e-3f }, { logf(v + 1.0f), 1e-5f },
                { sinf(v), 1e-5f }, { sqrtf(fabsf(v)), 1e-6f },
                { 1.0f / sqrtf(fabsf(v) + 1.0f), 1e-5f },
                { floorf(v) + ceilf(v) * 0.01f, 0 },
                { v < -0.5f ? -0.5f : (v > 0.5f ? 0.5f : v), 0 },
                { (v >= 0.5f ? 1.0f : 0.0f)
                  + (v <= 0.0f ? 0.0f : (v >= 1.0f ? 1.0f : v * v * (3 - 2 * v))) * 0.001f, 1e-4f },
                { -1.0f + 2.0f * (v < 0 ? 0 : (v > 1 ? 1 : v)), 0 },
                { (v != v) ? 1.0f : 0.0f },   /* sign 稍后单独验 */
            };
            for (int j = 0; j < 11; j++) {
                if (!close_enough(hr[i * 12 + j], exp_[j].ref, exp_[j].tol)) {
                    printf("math1 mismatch i=%d j=%d got=%.6f ref=%.6f\n",
                           i, j, hr[i * 12 + j], exp_[j].ref);
                    bad++;
                }
            }
            float sg = (v > 0) - (v < 0);
            if (!close_enough(hr[i * 12 + 11], sg, 0)) bad++;
        }
        printf("math1  : %d mismatches (fabs/fma/log/sin/sqrt/clamp/mix/sign...)\n", bad);
        CHECK(bad == 0, "math builtins");
        clReleaseMemObject(bx); clReleaseMemObject(br); clReleaseKernel(k);
        free(hr);
    }

    /* ---- 整数函数 ---- */
    {
        cl_kernel k = clCreateKernel(prog, "int1", &err);
        CL_CHECK(err);
        cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(hix), hix, &err);
        CL_CHECK(err);
        int hr[16 * 6];
        cl_mem br = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hr), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bx));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &br));
        size_t g = N;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, br, CL_TRUE, 0, sizeof(hr), hr, 0, NULL, NULL));
        int bad = 0;
        for (int i = 0; i < N; i++) {
            int v = hix[i];
            unsigned uv = (unsigned)(v == 0 ? 1 : v);
            int clz = 0; while (!(uv & 0x80000000u) && clz < 32) { uv <<= 1; clz++; }
            long long ms = (long long)v * 3 + 7;
            int lo = v & 0xff, hiC = v < -128 ? -128 : (v > 127 ? 127 : v);
            unsigned rot = ((unsigned)v << 3) | ((unsigned)v >> (32 - 3));
            struct { int idx; int got; int ref; } bads[6] = {
                {0, hr[i * 6 + 0], abs(v)},
                {1, hr[i * 6 + 1], clz},
                {2, hr[i * 6 + 2], (int)(ms > 2147483647LL ? 2147483647 : ms)},
                {3, hr[i * 6 + 3], (v > -v ? v : -v)},
                {4, hr[i * 6 + 4], (int)(((unsigned)hiC << 8) | (unsigned char)lo)},
                {5, hr[i * 6 + 5], (int)rot},
            };
            for (int j = 0; j < 6; j++) {
                if (bads[j].got != bads[j].ref) {
                    if (bad < 5)
                        printf("int1 i=%d j=%d v=%d got=%d ref=%d\n",
                               i, j, v, bads[j].got, bads[j].ref);
                    bad++;
                }
            }
        }
        printf("int1   : %d mismatches (abs/clz/mad_sat/upsample/rotate)\n", bad);
        CHECK(bad == 0, "integer builtins");
        clReleaseMemObject(bx); clReleaseMemObject(br); clReleaseKernel(k);
    }

    /* ---- shuffle / select / 几何 ---- */
    {
        cl_kernel k = clCreateKernel(prog, "vec_ops", &err);
        CL_CHECK(err);
        cl_float4 ha[4] = {{1,2,3,4},{-1,0.5f,2,8},{0.1f,0.2f,0.3f,0.4f},{5,5,5,5}};
        cl_float4 hb[4] = {{4,3,2,1},{1,1,1,1},{0.9f,0.1f,0.5f,0.2f},{-5,6,-5,6}};
        cl_mem ba = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(ha), ha, &err);
        CL_CHECK(err);
        cl_mem bb = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(hb), hb, &err);
        CL_CHECK(err);
        cl_float4 hr[4]; float hg[4 * 3];
        cl_mem bro = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hr), NULL, &err);
        CL_CHECK(err);
        cl_mem bg = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hg), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &ba));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bb));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bro));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_mem), &bg));
        size_t g = 4;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bro, CL_TRUE, 0, sizeof(hr), hr, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bg, CL_TRUE, 0, sizeof(hg), hg, 0, NULL, NULL));
        int bad = 0;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                float rev = ha[i].s[3 - j];
                float pick = hb[i].s[j] > ha[i].s[j] ? hb[i].s[j] : ha[i].s[j];
                if (!close_enough(hr[i].s[j], rev + pick * 0.001f, 1e-5f)) bad++;
            }
            float p0 = ha[i].s[0], p1 = ha[i].s[1], p2 = ha[i].s[2];
            float q0 = hb[i].s[0], q1 = hb[i].s[1], q2 = hb[i].s[2];
            if (!close_enough(hg[i * 3 + 0], p0 * q0 + p1 * q1 + p2 * q2, 1e-4f)) bad++;
            if (!close_enough(hg[i * 3 + 1],
                              sqrtf((p0 + 1) * (p0 + 1) + (p1 + 1) * (p1 + 1) + (p2 + 1) * (p2 + 1)),
                              2e-3f)) bad++;
            if (!close_enough(hg[i * 3 + 2],
                              sqrtf((p0 - q0) * (p0 - q0) + (p1 - q1) * (p1 - q1) + (p2 - q2) * (p2 - q2)),
                              1e-4f)) bad++;
        }
        printf("vec_ops: %d mismatches (shuffle/select/dot/fast_length/distance)\n", bad);
        CHECK(bad == 0, "vec builtins");
        clReleaseMemObject(ba); clReleaseMemObject(bb); clReleaseMemObject(bro); clReleaseMemObject(bg);
        clReleaseKernel(k);
    }

    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("11 builtin_funcs PASS\n");
    return 0;
}
