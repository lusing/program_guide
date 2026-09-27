/* 24_fft —— 1D FFT：迭代 radix-2 蝶形（Scarpino 第 14 章路线）
 *
 * 1024 点复数 FFT。迭代 Cooley-Tukey：log2(N) 个 stage，每 stage 全部蝶形
 * 一次内核启动完成（stage 间靠“多次启动”获得全局同步）。
 * 旋转因子表预生成放进 __constant。
 * 验证：
 *  - 与 O(N^2) 朴素 DFT 对拍（幅度谱，容差）
 *  - 埋一个频率 7 的正弦 + 频率 40 的余弦，检查 |X[7]|、|X[40]| 是双峰
 * 位反转重排也做成一个内核（下标二进制翻转的置换）。
 */
#include <math.h>
#include "cl_utils.h"

#define NFFT 1024

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

    /* 内核源：把 NFFT 注入（fft_stage 用 twiddles 索引步进） */
    char ksrc[4096];
    snprintf(ksrc, sizeof(ksrc),
        "__kernel void bitrev(__global float2* d) {\n"
        "    int i = get_global_id(0);\n"
        "    int r = 0;\n"
        "    for (int v = i, bits = 0; bits < %d; bits++, v >>= 1)\n"
        "        r = (r << 1) | (v & 1);\n"
        "    if (r > i) {\n"
        "        float2 t = d[i]; d[i] = d[r]; d[r] = t;\n"
        "    }\n"
        "}\n"
        "__kernel void fft_stage(__global float2* d, __constant float2* tw,\n"
        "                        const int stage, const int n) {\n"
        "    int i = get_global_id(0);\n"
        "    if (i >= n / 2) return;\n"
        "    int span = 1 << stage;\n"
        "    int base = (i / span) * 2 * span;\n"
        "    int pos  = i %% span;\n"
        "    float2 a = d[base + pos];\n"
        "    float2 b = d[base + pos + span];\n"
        "    float2 w = tw[pos * (n / (2 * span))];\n"
        "    float2 wb = (float2)(w.x * b.x - w.y * b.y, w.x * b.y + w.y * b.x);\n"
        "    d[base + pos]        = a + wb;\n"
        "    d[base + pos + span] = a - wb;\n"
        "}\n",
        10 /* bits */);
    cl_program prog = clu_build_program(ctx, dev, ksrc, NULL);

    /* 输入：0.7*sin(2π·7t) + 0.3*cos(2π·40t) */
    float* hd = (float*)malloc(NFFT * 2 * sizeof(float));
    for (int i = 0; i < NFFT; i++) {
        double t = (double)i / NFFT;
        hd[i * 2 + 0] = (float)(0.7 * sin(2.0 * 3.141592653589793 * 7.0 * t)
                              + 0.3 * cos(2.0 * 3.141592653589793 * 40.0 * t));
        hd[i * 2 + 1] = 0.0f;
    }

    /* 旋转因子：w_k = exp(-2πi k / N)，k = 0..N/2-1 */
    float* htw = (float*)malloc((NFFT / 2) * 2 * sizeof(float));
    for (int k = 0; k < NFFT / 2; k++) {
        double ang = -2.0 * 3.141592653589793 * k / NFFT;
        htw[k * 2 + 0] = (float)cos(ang);
        htw[k * 2 + 1] = (float)sin(ang);
    }

    /* CPU 参考 DFT（幅度） */
    float* refmag = (float*)malloc(NFFT * sizeof(float));
    for (int k = 0; k < NFFT; k++) {
        double re = 0, im = 0;
        for (int i2 = 0; i2 < NFFT; i2++) {
            double ang = -2.0 * 3.141592653589793 * k * i2 / NFFT;
            re += hd[i2 * 2] * cos(ang) - hd[i2 * 2 + 1] * sin(ang);
            im += hd[i2 * 2] * sin(ang) + hd[i2 * 2 + 1] * cos(ang);
        }
        refmag[k] = (float)sqrt(re * re + im * im) / NFFT;
    }

    cl_mem bd = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                               NFFT * 2 * sizeof(float), hd, &err);
    CL_CHECK(err);
    cl_mem btw = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                (NFFT / 2) * 2 * sizeof(float), htw, &err);
    CL_CHECK(err);

    cl_kernel krev = clCreateKernel(prog, "bitrev", &err);
    CL_CHECK(err);
    cl_kernel kstage = clCreateKernel(prog, "fft_stage", &err);
    CL_CHECK(err);
    CL_CHECK(clSetKernelArg(krev, 0, sizeof(cl_mem), &bd));
    CL_CHECK(clSetKernelArg(kstage, 0, sizeof(cl_mem), &bd));
    CL_CHECK(clSetKernelArg(kstage, 1, sizeof(cl_mem), &btw));
    cl_int n = NFFT;
    CL_CHECK(clSetKernelArg(kstage, 3, sizeof(cl_int), &n));

    size_t gfull = NFFT, ghalf = NFFT / 2;
    CL_CHECK(clEnqueueNDRangeKernel(q, krev, 1, NULL, &gfull, NULL, 0, NULL, NULL));
    for (int stage = 0; stage < 10; stage++) {
        CL_CHECK(clSetKernelArg(kstage, 2, sizeof(cl_int), &stage));
        CL_CHECK(clEnqueueNDRangeKernel(q, kstage, 1, NULL, &ghalf, NULL, 0, NULL, NULL));
    }
    float* hout = (float*)malloc(NFFT * 2 * sizeof(float));
    CL_CHECK(clEnqueueReadBuffer(q, bd, CL_TRUE, 0, NFFT * 2 * sizeof(float), hout, 0, NULL, NULL));

    /* 幅度谱对拍 */
    int bad = 0;
    float m7 = 0, m40 = 0;
    for (int k = 0; k < NFFT; k++) {
        float m = sqrtf(hout[k * 2] * hout[k * 2] + hout[k * 2 + 1] * hout[k * 2 + 1]) / NFFT;
        if (fabsf(m - refmag[k]) > 5e-3f) { bad++; break; }
        if (k == 7) m7 = m;
        if (k == 40) m40 = m;
    }
    printf("FFT vs DFT: %s (max err < 5e-3)\n", bad ? "WRONG" : "match");
    CHECK(!bad, "fft matches naive dft");
    printf("|X[7]| = %.3f (expect ~0.35), |X[40]| = %.3f (expect ~0.15)\n",
           m7, m40);
    CHECK(m7 > 0.25f && m7 < 0.45f && m40 > 0.1f && m40 < 0.2f, "spectral peaks");

    /* 泊亚对称断言：|X[k]| == |X[N-k]| */
    float sym_err = 0;
    for (int k = 1; k < NFFT / 2; k++) {
        float m1 = sqrtf(hout[k * 2] * hout[k * 2] + hout[k * 2 + 1] * hout[k * 2 + 1]);
        float m2 = sqrtf(hout[(NFFT - k) * 2] * hout[(NFFT - k) * 2]
                       + hout[(NFFT - k) * 2 + 1] * hout[(NFFT - k) * 2 + 1]);
        float d = fabsf(m1 - m2) / (m1 + 1e-9f);
        if (d > sym_err) sym_err = d;
    }
    printf("conjugate symmetry: max rel err %.2e\n", sym_err);
    CHECK(sym_err < 1e-4f, "real input symmetry");

    clReleaseMemObject(bd); clReleaseMemObject(btw);
    clReleaseKernel(krev); clReleaseKernel(kstage);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hd); free(htw); free(refmag); free(hout);
    printf("24 fft PASS\n");
    return 0;
}
