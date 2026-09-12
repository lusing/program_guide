#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>

cl_program createProgramFromSPIRV(cl_context context, cl_device_id device,
                                   const char* spvFile) {
    FILE* fp = fopen(spvFile, "rb");
    if (!fp) {
        printf("Failed to open SPIR-V file: %s\n", spvFile);
        return NULL;
    }

    // 获取文件大小
    fseek(fp, 0, SEEK_END);
    size_t size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    // 读取 SPIR-V 二进制
    unsigned char* spvBinary = (unsigned char*)malloc(size);
    fread(spvBinary, 1, size, fp);
    fclose(fp);

    // 检查 IL 支持
    size_t ilVersionSize;
    clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, 0, NULL, &ilVersionSize);
    if (ilVersionSize == 0) {
        printf("Device does not support IL programs\n");
        free(spvBinary);
        return NULL;
    }

    // 创建程序
    cl_int err;
    size_t lengths[1] = { size };
    cl_program program = clCreateProgramWithIL(context, spvBinary, size, &err);

    free(spvBinary);

    if (err != CL_SUCCESS) {
        printf("Failed to create program from IL: %d\n", err);
        return NULL;
    }

    // 构建程序
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t logSize;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSize);
        char* log = (char*)malloc(logSize);
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSize, log, NULL);
        printf("Build error: %s\n", log);
        free(log);
        clReleaseProgram(program);
        return NULL;
    }

    return program;
}
