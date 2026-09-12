// opencl_helloworld.c
#include <stdio.h>
#include <stdlib.h>
#include <CL/cl.h>

// 辅助函数：打印错误信息
const char* clErrorString(cl_int error) {
    switch (error) {
        case CL_SUCCESS: return "CL_SUCCESS";
        case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
        case CL_DEVICE_NOT_AVAILABLE: return "CL_DEVICE_NOT_AVAILABLE";
        case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
        case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
        case CL_OUT_OF_RESOURCES: return "CL_OUT_OF_RESOURCES";
        case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
        case CL_INVALID_PLATFORM: return "CL_INVALID_PLATFORM";
        case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
        case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
        case CL_INVALID_QUEUE_PROPERTIES: return "CL_INVALID_QUEUE_PROPERTIES";
        case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
        default: return "Unknown error";
    }
}

int main() {
    cl_int err;

    // 第一步：获取平台 ID
    cl_uint numPlatforms = 0;
    err = clGetPlatformIDs(0, NULL, &numPlatforms);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get number of platforms: %s\n", clErrorString(err));
        return -1;
    }

    printf("Found %d platform(s)\n", numPlatforms);

    if (numPlatforms == 0) {
        printf("Error: No OpenCL platforms found\n");
        return -1;
    }

    cl_platform_id* platforms = (cl_platform_id*)malloc(numPlatforms * sizeof(cl_platform_id));
    err = clGetPlatformIDs(numPlatforms, platforms, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get platform IDs: %s\n", clErrorString(err));
        free(platforms);
        return -1;
    }

    // 第二步：查找第一个可用的设备
    cl_uint numDevices = 0;
    cl_device_id* devices = NULL;
    cl_platform_id platform = platforms[0];

    // 打印平台信息
    char platformName[256];
    err = clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(platformName), platformName, NULL);
    if (err == CL_SUCCESS) {
        printf("Platform: %s\n", platformName);
    }

    // 获取设备数量
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 0, NULL, &numDevices);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get number of devices: %s\n", clErrorString(err));
        free(platforms);
        return -1;
    }

    printf("Found %d device(s)\n", numDevices);

    devices = (cl_device_id*)malloc(numDevices * sizeof(cl_device_id));
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, numDevices, devices, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to get device IDs: %s\n", clErrorString(err));
        free(platforms);
        free(devices);
        return -1;
    }

    // 打印设备信息
    for (cl_uint i = 0; i < numDevices; i++) {
        char deviceName[256];
        char vendorName[256];
        cl_uint maxComputeUnits;
        cl_ulong globalMemSize;
        cl_ulong localMemSize;

        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, sizeof(deviceName), deviceName, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, sizeof(vendorName), vendorName, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(maxComputeUnits), &maxComputeUnits, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(globalMemSize), &globalMemSize, NULL);
        clGetDeviceInfo(devices[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(localMemSize), &localMemSize, NULL);

        printf("\nDevice %d:\n", i + 1);
        printf("  Name: %s\n", deviceName);
        printf("  Vendor: %s\n", vendorName);
        printf("  Max Compute Units: %u\n", maxComputeUnits);
        printf("  Global Memory: %llu MB\n", (unsigned long long)(globalMemSize / (1024 * 1024)));
        printf("  Local Memory: %llu KB\n", (unsigned long long)(localMemSize / 1024));
    }

    // 第三步：创建上下文
    cl_context context = clCreateContext(NULL, numDevices, devices, NULL, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create context: %s\n", clErrorString(err));
        free(platforms);
        free(devices);
        return -1;
    }

    // 第四步：创建命令队列
    // 注意：clCreateCommandQueue 在 OpenCL 2.0 中被弃用，但仍可用于向后兼容
    // OpenCL 2.0+ 推荐使用 clCreateCommandQueueWithProperties
    cl_command_queue cmdQueue = clCreateCommandQueue(context, devices[0], 0, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create command queue: %s\n", clErrorString(err));
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第五步：准备内核代码
    const char* kernelSource =
        "__kernel void vector_add(__global const float* a, "
        "__global const float* b, __global float* c) {"
        "    int idx = get_global_id(0);"
        "    c[idx] = a[idx] + b[idx];"
        "}";

    // 第六步：创建程序对象
    cl_program program = clCreateProgramWithSource(context, 1, &kernelSource, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create program: %s\n", clErrorString(err));
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第七步：编译程序
    err = clBuildProgram(program, numDevices, devices, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to build program: %s\n", clErrorString(err));

        // 打印编译日志
        size_t logSize;
        clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, 0, NULL, &logSize);
        char* log = (char*)malloc(logSize);
        clGetProgramBuildInfo(program, devices[0], CL_PROGRAM_BUILD_LOG, logSize, log, NULL);
        printf("\nBuild Log:\n%s\n", log);
        free(log);

        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第八步：创建内核
    cl_kernel kernel = clCreateKernel(program, "vector_add", &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create kernel: %s\n", clErrorString(err));
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        return -1;
    }

    // 第九步：准备数据
    const int dataCount = 10;
    float* hostA = (float*)malloc(dataCount * sizeof(float));
    float* hostB = (float*)malloc(dataCount * sizeof(float));
    float* hostC = (float*)malloc(dataCount * sizeof(float));

    for (int i = 0; i < dataCount; i++) {
        hostA[i] = (float)i;
        hostB[i] = (float)(i * 2);
    }

    // 第十步：创建缓冲区对象
    cl_mem bufferA = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     dataCount * sizeof(float), hostA, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer A: %s\n", clErrorString(err));
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    cl_mem bufferB = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                     dataCount * sizeof(float), hostB, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer B: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    cl_mem bufferC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, dataCount * sizeof(float), NULL, &err);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to create buffer C: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十一步：设置内核参数
    err = clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufferA);
    err |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufferB);
    err |= clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufferC);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to set kernel arguments: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十二步：执行内核
    size_t globalWorkSize = dataCount;
    err = clEnqueueNDRangeKernel(cmdQueue, kernel, 1, NULL, &globalWorkSize, NULL, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to execute kernel: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十三步：读取结果
    err = clEnqueueReadBuffer(cmdQueue, bufferC, CL_TRUE, 0, dataCount * sizeof(float), hostC, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("Error: Failed to read buffer C: %s\n", clErrorString(err));
        clReleaseMemObject(bufferA);
        clReleaseMemObject(bufferB);
        clReleaseMemObject(bufferC);
        clReleaseKernel(kernel);
        clReleaseProgram(program);
        clReleaseCommandQueue(cmdQueue);
        clReleaseContext(context);
        free(platforms);
        free(devices);
        free(hostA);
        free(hostB);
        free(hostC);
        return -1;
    }

    // 第十四步：输出结果
    printf("\nResults:\n");
    printf("A + B = C\n");
    for (int i = 0; i < dataCount; i++) {
        printf("%f + %f = %f\n", hostA[i], hostB[i], hostC[i]);
    }

    // 验证结果
    int success = 1;
    for (int i = 0; i < dataCount; i++) {
        if (hostC[i] != hostA[i] + hostB[i]) {
            success = 0;
            break;
        }
    }

    printf("\n%s\n", success ? "Test PASSED!" : "Test FAILED!");

    // 清理资源
    clReleaseMemObject(bufferA);
    clReleaseMemObject(bufferB);
    clReleaseMemObject(bufferC);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(cmdQueue);
    clReleaseContext(context);

    free(platforms);
    free(devices);
    free(hostA);
    free(hostB);
    free(hostC);

    return 0;
}
