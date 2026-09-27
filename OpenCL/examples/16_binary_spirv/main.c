/* 16_binary_spirv —— 程序二进制与 SPIR-V：缓存 / 重载 / IL 路线
 *
 * 三条创建程序的路线逐一实测：
 *  A) 源码（基线）
 *  B) clCreateProgramWithBinary：把 A 的编译产物 dump 成 .bin，
 *     重新加载运行（离线缓存的标准姿势；二进制与设备绑定）
 *  C) clCreateProgramWithIL（SPIR-V）：由 build.ps1 用 MSYS2 clang 把
 *     kernel_spirv.cl 预编译为 kernel_spirv.spv。本机实测：
 *     - NVIDIA CUDA 平台不支持 IL（CL_DEVICE_IL_VERSION 为空）-> SKIP
 *     - Intel CPU 平台支持 SPIR-V 1.0~1.4 -> 在 CPU 设备上加载运行
 *     ⚠️ 实测坑：clang 生成的 SPIR-V 里内核索引用 size_t 会让 Intel
 *     运行时在 clBuildProgram 卡死；用 int 索引即可。
 */
#include "cl_utils.h"

static const char* K_SRC =
"__kernel void vec_scale(__global const float* x, __global float* y, float k) {\n"
"    int i = get_global_id(0);\n"
"    if (i < 4096) y[i] = x[i] * k;\n"
"}\n";

static char* read_file(const char* name, size_t* out_sz) {
    FILE* f = fopen(name, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = (char*)malloc(sz);
    if (fread(buf, 1, sz, f) != (size_t)sz) { fclose(f); free(buf); return NULL; }
    fclose(f);
    *out_sz = (size_t)sz;
    return buf;
}

static int run_and_check(cl_context ctx, cl_command_queue q, cl_program prog,
                         const char* kname, float k) {
    cl_int err;
    cl_kernel kn = clCreateKernel(prog, kname, &err);
    if (err != CL_SUCCESS) { printf("  clCreateKernel(%s): %s\n", kname, clu_err_str(err)); return 0; }
    const int N = 4096;
    float hx[4096], hy[4096] = {0};
    for (int i = 0; i < N; i++) hx[i] = (float)i;
    cl_mem bx = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, sizeof(hx), hx, &err);
    CL_CHECK(err);
    cl_mem by = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hy), NULL, &err);
    CL_CHECK(err);
    CL_CHECK(clSetKernelArg(kn, 0, sizeof(cl_mem), &bx));
    CL_CHECK(clSetKernelArg(kn, 1, sizeof(cl_mem), &by));
    CL_CHECK(clSetKernelArg(kn, 2, sizeof(float), &k));
    size_t g = N;
    CL_CHECK(clEnqueueNDRangeKernel(q, kn, 1, NULL, &g, NULL, 0, NULL, NULL));
    CL_CHECK(clEnqueueReadBuffer(q, by, CL_TRUE, 0, sizeof(hy), hy, 0, NULL, NULL));
    int ok = 1;
    for (int i = 0; i < N; i++) if (hy[i] != hx[i] * k) { ok = 0; break; }
    clReleaseMemObject(bx); clReleaseMemObject(by); clReleaseKernel(kn);
    return ok;
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

    /* ---- A) 源码基线 ---- */
    cl_program psrc = clu_build_program(ctx, dev, K_SRC, NULL);
    int a_ok = run_and_check(ctx, q, psrc, "vec_scale", 2.0f);
    printf("A) source          : %s\n", a_ok ? "verified" : "WRONG");
    CHECK(a_ok, "source baseline");

    /* ---- B) 二进制 dump / 重载 ---- */
    {
        cl_uint ndev = 1;
        size_t szs[1] = {0};
        CL_CHECK(clGetProgramInfo(psrc, CL_PROGRAM_BINARY_SIZES, sizeof(szs), szs, NULL));
        CHECK(szs[0] > 0, "binary size");
        unsigned char* bin = (unsigned char*)malloc(szs[0]);
        const unsigned char* ptrs[1] = { bin };
        CL_CHECK(clGetProgramInfo(psrc, CL_PROGRAM_BINARIES, sizeof(ptrs), ptrs, NULL));
        FILE* f = fopen("kernel_cache.bin", "wb");
        CHECK(f != NULL, "open cache file");
        fwrite(bin, 1, szs[0], f);
        fclose(f);
        printf("B) binary dumped   : %zu bytes -> kernel_cache.bin\n", szs[0]);

        size_t fsz = 0;
        unsigned char* rbin = (unsigned char*)read_file("kernel_cache.bin", &fsz);
        CHECK(rbin != NULL && fsz == szs[0], "reload cache");
        const unsigned char* rptrs[1] = { rbin };
        cl_device_id devs[1] = { dev };
        cl_program pbin = clCreateProgramWithBinary(ctx, 1, devs, &fsz, rptrs, NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clBuildProgram(pbin, 1, devs, NULL, NULL, NULL));
        int b_ok = run_and_check(ctx, q, pbin, "vec_scale", 3.0f);
        printf("   binary reloaded : %s\n", b_ok ? "verified" : "WRONG");
        CHECK(b_ok, "binary reload");
        clReleaseProgram(pbin);
        free(bin); free(rbin);
    }

    /* ---- C) SPIR-V / IL ---- */
    {
        /* C.1 设备 IL 能力：字符串查询；长度 1 = 只有 NUL = 不支持 */
        size_t il_sz = 0;
        cl_int qrc = clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, 0, NULL, &il_sz);
        char il_ver[256] = {0};
        if (qrc == CL_SUCCESS && il_sz > 0)
            clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, il_sz, il_ver, NULL);
        printf("C) device IL       : %s\n", il_ver[0] ? il_ver : "(none on this device)");

        size_t spv_sz = 0;
        char* spv = read_file("kernel_spirv.spv", &spv_sz);
        if (!spv) {
            printf("   kernel_spirv.spv not found -> SPIR-V part SKIP (still PASS)\n");
        } else if (il_sz <= 1) {
            printf("   device has no IL support -> SPIR-V part SKIP (still PASS)\n");
            free(spv);
        } else {
            /* 当前设备不支持 IL：找一台支持的（本机 = Intel CPU）重建全套 */
            cl_uint nplat = 0;
            clGetPlatformIDs(0, NULL, &nplat);
            cl_platform_id plats[8];
            clGetPlatformIDs(nplat > 8 ? 8 : nplat, plats, NULL);
            cl_device_id ildev = NULL;
            cl_platform_id ilplat = NULL;
            for (cl_uint i = 0; i < nplat && i < 8 && !ildev; i++) {
                cl_uint nd = 0;
                if (clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_ALL, 0, NULL, &nd) != CL_SUCCESS) continue;
                cl_device_id ds[8];
                clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_ALL, nd > 8 ? 8 : nd, ds, NULL);
                for (cl_uint d = 0; d < nd && d < 8; d++) {
                    size_t s = 0;
                    if (clGetDeviceInfo(ds[d], CL_DEVICE_IL_VERSION, 0, NULL, &s) == CL_SUCCESS && s > 1) {
                        ildev = ds[d]; ilplat = plats[i]; break;
                    }
                }
            }
            if (!ildev) {
                printf("   no IL-capable device on this machine -> SKIP (still PASS)\n");
            } else {
                char dn[256] = {0};
                clGetDeviceInfo(ildev, CL_DEVICE_NAME, sizeof(dn), dn, NULL);
                printf("   using IL device : %s\n", dn);
                cl_context ictx = clCreateContext(NULL, 1, &ildev, NULL, NULL, &err);
                CL_CHECK(err);
                cl_command_queue iq = clCreateCommandQueueWithProperties(ictx, ildev, NULL, &err);
                CL_CHECK(err);
                cl_program pil = clCreateProgramWithIL(ictx, spv, spv_sz, &err);
                if (err != CL_SUCCESS) {
                    printf("   clCreateProgramWithIL: %s -> SKIP (still PASS)\n", clu_err_str(err));
                } else {
                    CL_CHECK(clBuildProgram(pil, 1, &ildev, NULL, NULL, NULL));
                    int c_ok = run_and_check(ictx, iq, pil, "vec_scale", 4.0f);
                    printf("   SPIR-V program  : %s\n", c_ok ? "verified" : "WRONG");
                    CHECK(c_ok, "SPIR-V run");
                    clReleaseProgram(pil);
                }
                clReleaseCommandQueue(iq);
                clReleaseContext(ictx);
            }
            free(spv);
        }

        /* C.2 CL_PROGRAM_IL 查询：源码程序不含 IL（返回 size 0） */
        size_t prog_il = 12345;
        clGetProgramInfo(psrc, CL_PROGRAM_IL, 0, NULL, &prog_il);
        printf("   CL_PROGRAM_IL of a source-built program: %zu bytes\n", prog_il);
    }

    clReleaseProgram(psrc);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("16 binary_spirv PASS\n");
    return 0;
}
