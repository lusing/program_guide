/* 27_extensions —— 扩展机制：查询、启用、运行时能力探测
 *
 *  1) 扩展查询三件套：CL_DEVICE_EXTENSIONS（字符串）、
 *     CL_DEVICE_EXTENSIONS_WITH_VERSION（cl_name_version 数组）
 *  2) cl_khr_fp64：#pragma OPENCL EXTENSION ... : enable 实测 double 内核
 *  3) cl_khr_fp16（本机只有 Intel 支持）：条件编译路径演示，没有就 SKIP
 *  4) subgroups：注意查法——扩展字符串里可能没有 "cl_khr_subgroups"
 *     （Intel 只列 subgroup_ballot/shuffle 家族），正路是查设备参数
 *     CL_DEVICE_MAX_NUM_SUB_GROUPS（>0 即支持）。Intel 上实测一个
 *     sub_group_reduce_add 内核；NVIDIA 无此能力 -> SKIP。
 *  5) cl_ext_device_fission 简介（仅文档；本机两家都不支持，跳过实测）
 */
#include "cl_utils.h"

static int has_ext(const char* list, const char* name) {
    return strstr(list, name) != NULL;
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

    /* --- 1) 扩展清单 --- */
    size_t sz = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, 0, NULL, &sz));
    char* exts = (char*)malloc(sz);
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sz, exts, NULL));
    size_t n_ext = 1;
    for (char* p = exts; *p; p++) if (*p == ' ') n_ext++;
    printf("device reports %zu extensions\n", n_ext);

    /* WITH_VERSION 数组形态（OpenCL 3.0） */
    size_t bsz = 0;
    clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS_WITH_VERSION, 0, NULL, &bsz);
    size_t n_nv = bsz / sizeof(cl_name_version);
    CHECK(n_nv == n_ext, "string vs cl_name_version counts must agree");
    printf("EXTENSIONS_WITH_VERSION count = %zu (matches string form)\n", n_nv);

    /* --- 2) fp64 --- */
    if (has_ext(exts, "cl_khr_fp64")) {
        static const char* KD =
            "#pragma OPENCL EXTENSION cl_khr_fp64 : enable\n"
            "__kernel void dbl_dot(__global const double* a, __global double* out) {\n"
            "    int i = get_global_id(0);\n"
            "    out[i] = a[i] * 1.0000000001;\n"
            "}\n";
        cl_program p = clu_build_program(ctx, dev, KD, NULL);
        cl_kernel k = clCreateKernel(p, "dbl_dot", &err);
        CL_CHECK(err);
        double ha[16] = {0}, ho[16] = {0};
        for (int i = 0; i < 16; i++) ha[i] = i * 1e8;
        cl_mem ba = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(ha), ha, &err);
        CL_CHECK(err);
        cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(ho), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &ba));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
        size_t g = 16;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, sizeof(ho), ho, 0, NULL, NULL));
        /* double 精度：乘 1.0000000001 在 float 下不可分辨，double 下可 */
        CHECK(ho[1] != ha[1], "double precision must differ from float");
        printf("fp64   : cl_khr_fp64 enabled, double kernel verified (ho[1]=%.6f)\n", ho[1]);
        clReleaseMemObject(ba); clReleaseMemObject(bo);
        clReleaseKernel(k); clReleaseProgram(p);
    } else {
        printf("fp64   : not supported -> SKIP\n");
    }

    /* --- 3) fp16（Intel 有、NVIDIA 无） --- */
    if (has_ext(exts, "cl_khr_fp16")) {
        printf("fp16   : cl_khr_fp16 present (half kernels possible)\n");
    } else {
        printf("fp16   : cl_khr_fp16 NOT on this device -> half kernels unavailable\n");
    }

    /* --- 4) subgroups：查参数而不是扩展名 --- */
    cl_uint max_sg = 0;
    clGetDeviceInfo(dev, CL_DEVICE_MAX_NUM_SUB_GROUPS, sizeof(max_sg), &max_sg, NULL);
    if (max_sg > 0) {
        printf("subgrp: CL_DEVICE_MAX_NUM_SUB_GROUPS=%u -> supported\n", max_sg);
        /* OpenCL C 2.0/3.0 feature：sub_group_reduce_add。
           3.0 设备须以 -cl-std=CL3.0 + __opencl_c_subgroups 特性启用，
           Intel 的 CL 3.0 编译器默认放开；编不过则打印说明。 */
        static const char* KS =
            "__kernel void sg_sum(__global const float* in, __global float* out) {\n"
            "    int i = get_global_id(0);\n"
            "    float v = sub_group_reduce_add(in[i]);\n"
            "    if (get_sub_group_local_id() == 0)\n"
            "        out[get_sub_group_id(0)] = v;\n"
            "}\n";
        cl_int berr = CL_SUCCESS;
        cl_program p = clCreateProgramWithSource(ctx, 1, &KS, NULL, &err);
        CL_CHECK(err);
        berr = clBuildProgram(p, 1, &dev, "-cl-std=CL3.0", NULL, NULL);
        if (berr == CL_SUCCESS) {
            cl_kernel k = clCreateKernel(p, "sg_sum", &err);
            CL_CHECK(err);
            float hin[64], hout[16] = {0};
            for (int i = 0; i < 64; i++) hin[i] = (float)(i + 1);
            cl_mem bi = clCreateBuffer(ctx, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                       sizeof(hin), hin, &err);
            CL_CHECK(err);
            cl_mem bo = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, sizeof(hout), NULL, &err);
            CL_CHECK(err);
            CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bi));
            CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bo));
            size_t g = 64, l = 64;
            CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, &l, 0, NULL, NULL));
            CL_CHECK(clEnqueueReadBuffer(q, bo, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
            /* 单工作组、一个 sub-group 时 out[0] = 1+2+...+64 = 2080 */
            printf("subgrp : sub_group_reduce_add result = %.1f (>=2080 across sg's)\n", hout[0]);
            CHECK(hout[0] >= 2080.0f - 1.0f, "subgroup reduce");
            clReleaseMemObject(bi); clReleaseMemObject(bo); clReleaseKernel(k);
        } else {
            printf("subgrp : kernel needs OpenCL C 2.0+ (build %d) -> informational\n", berr);
        }
        clReleaseProgram(p);
    } else {
        printf("subgrp : CL_DEVICE_MAX_NUM_SUB_GROUPS=0 -> not supported (NVIDIA 常态)\n");
    }

    /* --- 5) 设备拆分（fission）仅文档化 --- */
    printf("fission: cl_ext_device_fission is CL 1.2-era; modern devices: use "
           "CL_DEVICE_PARTITION_PROPERTIES query instead\n");
    cl_device_partition_property parts[8] = {0};
    size_t psz = 0;
    cl_int prc = clGetDeviceInfo(dev, CL_DEVICE_PARTITION_PROPERTIES,
                                 sizeof(parts), parts, &psz);
    printf("partition properties query -> %s (%zu entries, 0 = none)\n",
           clu_err_str(prc), psz / sizeof(cl_device_partition_property));

    free(exts);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("27 extensions PASS\n");
    return 0;
}
