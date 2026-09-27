/* cl_utils.h —— 教程示例共用的 OpenCL C 辅助头（不含 C++ 绑定）
 *
 * 约定：
 *  - 所有示例用 CL_CHECK/CL_CHECK2 包住每个 API 调用，出错即打印可读信息并退出
 *  - clu_init_* 负责最常用的 平台/设备/上下文/队列 搭建
 *  - clu_build_program 负责从源码字符串建程序并打印编译日志
 */
#ifndef CL_UTILS_H
#define CL_UTILS_H

#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

static const char* clu_err_str(cl_int e) {
    switch (e) {
    case CL_SUCCESS: return "CL_SUCCESS";
    case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
    case CL_DEVICE_NOT_AVAILABLE: return "CL_DEVICE_NOT_AVAILABLE";
    case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
    case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
    case CL_OUT_OF_RESOURCES: return "CL_OUT_OF_RESOURCES";
    case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
    case CL_PROFILING_INFO_NOT_AVAILABLE: return "CL_PROFILING_INFO_NOT_AVAILABLE";
    case CL_MEM_COPY_OVERLAP: return "CL_MEM_COPY_OVERLAP";
    case CL_IMAGE_FORMAT_MISMATCH: return "CL_IMAGE_FORMAT_MISMATCH";
    case CL_IMAGE_FORMAT_NOT_SUPPORTED: return "CL_IMAGE_FORMAT_NOT_SUPPORTED";
    case CL_BUILD_PROGRAM_FAILURE: return "CL_BUILD_PROGRAM_FAILURE";
    case CL_MAP_FAILURE: return "MAP_FAILURE";
    case CL_MISALIGNED_SUB_BUFFER_OFFSET: return "CL_MISALIGNED_SUB_BUFFER_OFFSET";
    case CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST: return "CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
    case CL_COMPILE_PROGRAM_FAILURE: return "CL_COMPILE_PROGRAM_FAILURE";
    case CL_LINKER_NOT_AVAILABLE: return "CL_LINKER_NOT_AVAILABLE";
    case CL_LINK_PROGRAM_FAILURE: return "CL_LINK_PROGRAM_FAILURE";
    case CL_DEVICE_PARTITION_FAILED: return "CL_DEVICE_PARTITION_FAILED";
    case CL_KERNEL_ARG_INFO_NOT_AVAILABLE: return "CL_KERNEL_ARG_INFO_NOT_AVAILABLE";
    case CL_INVALID_VALUE: return "CL_INVALID_VALUE";
    case CL_INVALID_DEVICE_TYPE: return "CL_INVALID_DEVICE_TYPE";
    case CL_INVALID_PLATFORM: return "CL_INVALID_PLATFORM";
    case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
    case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
    case CL_INVALID_COMMAND_QUEUE: return "CL_INVALID_COMMAND_QUEUE";
    case CL_INVALID_HOST_PTR: return "CL_INVALID_HOST_PTR";
    case CL_INVALID_MEM_OBJECT: return "CL_INVALID_MEM_OBJECT";
    case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
    case CL_INVALID_IMAGE_SIZE: return "CL_INVALID_IMAGE_SIZE";
    case CL_INVALID_SAMPLER: return "CL_INVALID_SAMPLER";
    case CL_INVALID_BINARY: return "CL_INVALID_BINARY";
    case CL_INVALID_BUILD_OPTIONS: return "CL_INVALID_BUILD_OPTIONS";
    case CL_INVALID_PROGRAM: return "CL_INVALID_PROGRAM";
    case CL_INVALID_PROGRAM_EXECUTABLE: return "CL_INVALID_PROGRAM_EXECUTABLE";
    case CL_INVALID_KERNEL_NAME: return "CL_INVALID_KERNEL_NAME";
    case CL_INVALID_KERNEL_DEFINITION: return "CL_INVALID_KERNEL_DEFINITION";
    case CL_INVALID_KERNEL: return "CL_INVALID_KERNEL";
    case CL_INVALID_ARG_INDEX: return "CL_INVALID_ARG_INDEX";
    case CL_INVALID_ARG_VALUE: return "CL_INVALID_ARG_VALUE";
    case CL_INVALID_ARG_SIZE: return "CL_INVALID_ARG_SIZE";
    case CL_INVALID_KERNEL_ARGS: return "CL_INVALID_KERNEL_ARGS";
    case CL_INVALID_WORK_DIMENSION: return "CL_INVALID_WORK_DIMENSION";
    case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
    case CL_INVALID_WORK_ITEM_SIZE: return "CL_INVALID_WORK_ITEM_SIZE";
    case CL_INVALID_GLOBAL_OFFSET: return "CL_INVALID_GLOBAL_OFFSET";
    case CL_INVALID_EVENT_WAIT_LIST: return "CL_INVALID_EVENT_WAIT_LIST";
    case CL_INVALID_EVENT: return "CL_INVALID_EVENT";
    case CL_INVALID_OPERATION: return "CL_INVALID_OPERATION";
    case CL_INVALID_GL_OBJECT: return "CL_INVALID_GL_OBJECT";
    case CL_INVALID_BUFFER_SIZE: return "CL_INVALID_BUFFER_SIZE";
    case CL_INVALID_MIP_LEVEL: return "CL_INVALID_MIP_LEVEL";
    case CL_INVALID_GLOBAL_WORK_SIZE: return "CL_INVALID_GLOBAL_WORK_SIZE";
    case CL_INVALID_PROPERTY: return "CL_INVALID_PROPERTY";
    case CL_INVALID_IMAGE_DESCRIPTOR: return "CL_INVALID_IMAGE_DESCRIPTOR";
    case CL_INVALID_COMPILER_OPTIONS: return "CL_INVALID_COMPILER_OPTIONS";
    case CL_INVALID_LINKER_OPTIONS: return "CL_INVALID_LINKER_OPTIONS";
    case CL_INVALID_DEVICE_PARTITION_COUNT: return "CL_INVALID_DEVICE_PARTITION_COUNT";
    case CL_INVALID_PIPE_SIZE: return "CL_INVALID_PIPE_SIZE";
    case CL_INVALID_DEVICE_QUEUE: return "CL_INVALID_DEVICE_QUEUE";
    case CL_INVALID_SPEC_ID: return "CL_INVALID_SPEC_ID";
    case CL_MAX_SIZE_RESTRICTION_EXCEEDED: return "CL_MAX_SIZE_RESTRICTION_EXCEEDED";
    default: return "UNKNOWN";
    }
}

/* CL_CHECK(expr)：expr 是返回 cl_int 的调用 */
#define CL_CHECK(expr)                                                      \
    do {                                                                    \
        cl_int _e = (expr);                                                 \
        if (_e != CL_SUCCESS) {                                             \
            fprintf(stderr, "OpenCL error %d (%s) at %s:%d in %s\n",        \
                    (int)_e, clu_err_str(_e), __FILE__, __LINE__, #expr);   \
            exit(1);                                                        \
        }                                                                   \
    } while (0)

/* CL_CHECK2(var, expr)：带 err 变量返回值的创建型 API */
#define CL_CHECK2(var, expr)                                                \
    do {                                                                    \
        cl_int _e = CL_SUCCESS;                                             \
        (var) = (expr);                                                     \
        if (_e != CL_SUCCESS) {                                             \
            fprintf(stderr, "OpenCL error %d (%s) at %s:%d in %s\n",        \
                    (int)_e, clu_err_str(_e), __FILE__, __LINE__, #expr);   \
            exit(1);                                                        \
        }                                                                   \
    } while (0)

/* 断言辅助：主机端校验 */
#define CHECK(cond, msg)                                                    \
    do {                                                                    \
        if (!(cond)) {                                                      \
            fprintf(stderr, "CHECK failed: %s (%s:%d)\n",                   \
                    (msg), __FILE__, __LINE__);                             \
            exit(1);                                                        \
        }                                                                   \
    } while (0)

/* 选第一个有 GPU 的平台；没有 GPU 就退回第一个平台的第一台设备。
 * 输出 platform/device/num_devices，供 clCreateContext 使用。 */
static void clu_pick_device(cl_platform_id* plat_out, cl_device_id* dev_out,
                            char const** dev_kind_out) {
    cl_uint nplat = 0;
    CL_CHECK(clGetPlatformIDs(0, NULL, &nplat));
    CHECK(nplat > 0, "no OpenCL platform found");
    cl_platform_id plats[8];
    CL_CHECK(clGetPlatformIDs(nplat > 8 ? 8 : nplat, plats, NULL));

    for (cl_uint i = 0; i < nplat && i < 8; i++) {
        cl_device_id dev = NULL;
        if (clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_GPU, 1, &dev, NULL) == CL_SUCCESS) {
            *plat_out = plats[i];
            *dev_out = dev;
            if (dev_kind_out) *dev_kind_out = "GPU";
            return;
        }
    }
    /* 退回任意设备（例如只有 CPU 平台的机器） */
    for (cl_uint i = 0; i < nplat && i < 8; i++) {
        cl_device_id dev = NULL;
        if (clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_DEFAULT, 1, &dev, NULL) == CL_SUCCESS) {
            *plat_out = plats[i];
            *dev_out = dev;
            if (dev_kind_out) *dev_kind_out = "default";
            return;
        }
    }
    CHECK(0, "no OpenCL device found");
}

static void clu_print_device_brief(cl_device_id dev) {
    char name[256] = {0}, ver[64] = {0};
    clGetDeviceInfo(dev, CL_DEVICE_NAME, sizeof(name), name, NULL);
    clGetDeviceInfo(dev, CL_DEVICE_VERSION, sizeof(ver), ver, NULL);
    printf("device : %s (%s)\n", name, ver);
}

/* 从源码构建程序；失败时打印完整 build log 再退出 */
static cl_program clu_build_program(cl_context ctx, cl_device_id dev,
                                    const char* src, const char* options) {
    cl_int err = CL_SUCCESS;
    cl_program prog = clCreateProgramWithSource(ctx, 1, &src, NULL, &err);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "clCreateProgramWithSource: %s\n", clu_err_str(err));
        exit(1);
    }
    err = clBuildProgram(prog, 1, &dev, options, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t log_sz = 0;
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_sz);
        char* log = (char*)malloc(log_sz + 1);
        if (log) {
            clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, log_sz, log, NULL);
            log[log_sz] = '\0';
            fprintf(stderr, "clBuildProgram(%s) failed: %s\nbuild log:\n%s\n",
                    options ? options : "", clu_err_str(err), log);
            free(log);
        }
        exit(1);
    }
    return prog;
}

#ifdef __cplusplus
}
#endif

#endif /* CL_UTILS_H */
