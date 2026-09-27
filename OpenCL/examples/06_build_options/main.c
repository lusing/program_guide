/* 06_build_options —— 程序构建：build 选项、编译日志、程序/内核信息查询
 *
 * 演示：
 *  1) 多段源码组成一个程序（clCreateProgramWithSource 的 count > 1）
 *  2) build 选项（-cl-std / -cl-fast-relaxed-math / -cl-mad-enable 等）与
 *     CL_PROGRAM_* 查询
 *  3) 故意引入语法错误 -> clBuildProgram 返回 CL_BUILD_PROGRAM_FAILURE，
 *     抓出完整 build log（排错第一手段）
 *  4) 内核信息：CL_KERNEL_NUM_ARGS / WORK_GROUP_SIZE（该设备上单工作组上限）
 */
#include "cl_utils.h"

/* 两段源码：先声明再定义，说明"多文件拼接"语义 */
static const char* SRC_DECL =
    "float4 weighted(float4 v, float w);\n";
static const char* SRC_BODY =
    "__kernel void tint(__global const float4* in, __global float4* out, float w) {\n"
    "    int i = get_global_id(0);\n"
    "    out[i] = weighted(in[i], w);\n"
    "}\n"
    "float4 weighted(float4 v, float w) {\n"
    "    return v * w;\n"
    "}\n";

static const char* SRC_BROKEN =
    "__kernel void broken(__global float* x) {\n"
    "    x[get_global_id(0)] = ; /* syntax error */\n"
    "}\n";

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);

    /* --- 1) 多段源码 --- */
    const char* sources[2] = { SRC_DECL, SRC_BODY };
    cl_program prog = clCreateProgramWithSource(ctx, 2, sources, NULL, &err);
    CL_CHECK(err);

    /* --- 2) build 选项 --- */
    const char* opts = "-cl-fast-relaxed-math -cl-mad-enable -cl-std=CL1.2";
    err = clBuildProgram(prog, 1, &dev, opts, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t lsz = 0;
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &lsz);
        char* log = (char*)malloc(lsz + 1);
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, lsz, log, NULL);
        log[lsz] = '\0';
        fprintf(stderr, "unexpected build failure: %s\nlog:\n%s\n", clu_err_str(err), log);
        free(log);
        return 1;
    }

    /* 程序级查询 */
    cl_uint refs = 0;
    CL_CHECK(clGetProgramInfo(prog, CL_PROGRAM_REFERENCE_COUNT, sizeof(refs), &refs, NULL));
    /* 注意：CL_PROGRAM_BINARY_TYPE 是"每设备"的构建信息，走 clGetProgramBuildInfo；
       用 clGetProgramInfo 查它会得到 CL_INVALID_VALUE（实测 NVIDIA 驱动如此） */
    cl_program_binary_type bt = CL_PROGRAM_BINARY_TYPE_NONE;
    CL_CHECK(clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BINARY_TYPE, sizeof(bt), &bt, NULL));
    size_t nsrc = 0;
    CL_CHECK(clGetProgramInfo(prog, CL_PROGRAM_SOURCE, 0, NULL, &nsrc));
    char* joined = (char*)malloc(nsrc);
    CL_CHECK(clGetProgramInfo(prog, CL_PROGRAM_SOURCE, nsrc, joined, NULL));
    CHECK(strstr(joined, "float4 weighted") != NULL,
          "CL_PROGRAM_SOURCE returns the concatenated source");
    printf("program: refs=%u binary_type=%u source_bytes=%zu\n", refs, (unsigned)bt, nsrc);

    /* build 选项回看（部分驱动支持） */
    size_t osz = 0;
    if (clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_OPTIONS, 0, NULL, &osz) == CL_SUCCESS
        && osz > 1) {
        char* o = (char*)malloc(osz);
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_OPTIONS, osz, o, NULL);
        printf("build options echoed: %s\n", o);
        free(o);
    }
    free(joined);

    /* 内核级查询 */
    cl_kernel k = clCreateKernel(prog, "tint", &err);
    CL_CHECK(err);
    cl_uint nargs = 0;
    CL_CHECK(clGetKernelInfo(k, CL_KERNEL_NUM_ARGS, sizeof(nargs), &nargs, NULL));
    size_t wg = 0;
    CL_CHECK(clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_WORK_GROUP_SIZE, sizeof(wg), &wg, NULL));
    size_t pref_mult = 0;
    CL_CHECK(clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE,
                                      sizeof(pref_mult), &pref_mult, NULL));
    cl_ulong lmem = 0;
    CL_CHECK(clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_LOCAL_MEM_SIZE, sizeof(lmem), &lmem, NULL));
    printf("kernel 'tint': num_args=%u max_wg=%zu preferred_multiple=%zu local_mem=%llu\n",
           nargs, wg, pref_mult, (unsigned long long)lmem);
    CHECK(nargs == 3, "tint takes 3 args");

    /* --- 3) 编译错误的日志抓取 --- */
    cl_program bad = clCreateProgramWithSource(ctx, 1, &SRC_BROKEN, NULL, &err);
    CL_CHECK(err);
    err = clBuildProgram(bad, 1, &dev, NULL, NULL, NULL);
    CHECK(err == CL_BUILD_PROGRAM_FAILURE, "broken source must fail to build");
    size_t lsz = 0;
    CL_CHECK(clGetProgramBuildInfo(bad, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &lsz));
    char* log = (char*)malloc(lsz + 1);
    CL_CHECK(clGetProgramBuildInfo(bad, dev, CL_PROGRAM_BUILD_LOG, lsz, log, NULL));
    log[lsz] = '\0';
    printf("broken kernel -> %s; log (%zu bytes) first line: ", clu_err_str(err), lsz);
    const char* nl = strchr(log, '\n');
    if (nl) printf("%.*s\n", (int)(nl - log), log);
    else printf("%s\n", log);
    CHECK(lsz > 1, "build log should not be empty");
    free(log);
    clReleaseProgram(bad);

    /* 跑一下 tint 验证多段源码真的拼起来了 */
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
    CL_CHECK(err);
    float hin[16], hout[16] = {0};
    for (int i = 0; i < 16; i++) hin[i] = (float)i;
    cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                               sizeof(hin), hin, &err);
    CL_CHECK(err);
    cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hout), NULL, &err);
    CL_CHECK(err);
    float w = 2.0f;
    CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bi));
    CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
    CL_CHECK(clSetKernelArg(k, 2, sizeof(float), &w));
    size_t g = 16;
    CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
    CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    int ok = 1;
    for (int i = 0; i < 16; i++) if (hout[i] != hin[i] * 2.0f) { ok = 0; break; }

    clReleaseMemObject(bi);
    clReleaseMemObject(bo);
    clReleaseKernel(k);
    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("%s\n", ok ? "06 build_options PASS" : "06 build_options FAIL");
    return ok ? 0 : 1;
}
