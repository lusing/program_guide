// Shared helpers for every example in this tutorial.
//
// These exist so that the eleven examples do not each re-implement device
// selection and end up with eleven slightly different versions of the same bug.
// The two things this header is really about:
//
//   1. Choosing a device BY NAME across all platforms. Taking platforms[0] or
//      devices[0] is the single most common mistake in OpenCL sample code, and on
//      this machine it silently selects the NVIDIA GPU instead of the Intel iGPU
//      the tutorial is written for. Every example here names its target.
//
//   2. Reporting a verdict in one fixed shape - exit code 0 plus a final
//      "[RESULT] PASS" line - so OpenCL/build.ps1 can judge all eleven examples
//      with a single rule instead of parsing eleven bespoke output formats.
//
// Everything is static so each example stays a single translation unit.
#ifndef OCL_UTIL_H
#define OCL_UTIL_H

// 300, not 120: at 120 the headers hide every 2.x entry point, so
// clCreateCommandQueueWithProperties and clCreateProgramWithIL do not even
// compile. See docs/02-environment-setup.md.
#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif

#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// The device this tutorial targets: the Intel integrated GPU. Matched by name so
// the example still works if the platform enumeration order changes.
#define OCL_DEFAULT_DEVICE "UHD"

// Print an error and abort the example with a FAIL verdict. Used for
// infrastructure failures (no device, no context) where continuing is meaningless.
#define OCL_DIE(fmt, ...)                                                    \
    do {                                                                     \
        printf("[FAIL] " fmt "\n", ##__VA_ARGS__);                           \
        printf("[RESULT] FAIL\n");                                           \
        exit(1);                                                             \
    } while (0)

// Translate a cl_int into a readable name. Examples print this instead of a bare
// number because "-54" tells a reader nothing while
// "-54 CL_INVALID_WORK_GROUP_SIZE" tells them exactly which limit they hit.
static const char* ocl_err_name(cl_int e) {
    switch (e) {
    case CL_SUCCESS: return "CL_SUCCESS";
    case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
    case CL_DEVICE_NOT_AVAILABLE: return "CL_DEVICE_NOT_AVAILABLE";
    case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
    case CL_BUILD_PROGRAM_FAILURE: return "CL_BUILD_PROGRAM_FAILURE";
    case CL_INVALID_VALUE: return "CL_INVALID_VALUE";
    case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
    case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
    case CL_INVALID_QUEUE_PROPERTIES: return "CL_INVALID_QUEUE_PROPERTIES";
    case CL_INVALID_COMMAND_QUEUE: return "CL_INVALID_COMMAND_QUEUE";
    case CL_INVALID_HOST_PTR: return "CL_INVALID_HOST_PTR";
    case CL_INVALID_KERNEL: return "CL_INVALID_KERNEL";
    case CL_INVALID_KERNEL_NAME: return "CL_INVALID_KERNEL_NAME";
    case CL_INVALID_KERNEL_DEFINITION: return "CL_INVALID_KERNEL_DEFINITION";
    case CL_INVALID_KERNEL_ARGS: return "CL_INVALID_KERNEL_ARGS";
    case CL_INVALID_ARG_INDEX: return "CL_INVALID_ARG_INDEX";
    case CL_INVALID_ARG_SIZE: return "CL_INVALID_ARG_SIZE";
    case CL_INVALID_ARG_VALUE: return "CL_INVALID_ARG_VALUE";
    case CL_INVALID_WORK_DIMENSION: return "CL_INVALID_WORK_DIMENSION";
    case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
    case CL_INVALID_WORK_ITEM_SIZE: return "CL_INVALID_WORK_ITEM_SIZE";
    case CL_INVALID_GLOBAL_WORK_SIZE: return "CL_INVALID_GLOBAL_WORK_SIZE";
    case CL_INVALID_GLOBAL_OFFSET: return "CL_INVALID_GLOBAL_OFFSET";
    case CL_INVALID_EVENT_WAIT_LIST: return "CL_INVALID_EVENT_WAIT_LIST";
    case CL_INVALID_OPERATION: return "CL_INVALID_OPERATION";
    case CL_INVALID_PROGRAM: return "CL_INVALID_PROGRAM";
    case CL_INVALID_PROGRAM_EXECUTABLE: return "CL_INVALID_PROGRAM_EXECUTABLE";
    case CL_INVALID_BINARY: return "CL_INVALID_BINARY";
    case CL_INVALID_BUILD_OPTIONS: return "CL_INVALID_BUILD_OPTIONS";
    case CL_INVALID_BUFFER_SIZE: return "CL_INVALID_BUFFER_SIZE";
    case CL_INVALID_MEM_OBJECT: return "CL_INVALID_MEM_OBJECT";
    case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
    case CL_INVALID_IMAGE_SIZE: return "CL_INVALID_IMAGE_SIZE";
    case CL_INVALID_SAMPLER: return "CL_INVALID_SAMPLER";
    case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
    case CL_OUT_OF_RESOURCES: return "CL_OUT_OF_RESOURCES";
    case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
    default: return "(other)";
    }
}

// Select a device by matching a substring of CL_DEVICE_NAME, scanning EVERY
// platform and (optionally) every device type.
//
// Returns 0 on success. On failure the caller should OCL_DIE: an example that
// cannot find its target device has proven nothing and must not quietly fall back
// to whatever device happens to be first.
static int ocl_pick_device(const char* nameHint, cl_device_type type,
                           cl_device_id* outDev, char* outName, size_t outNameSz) {
    cl_uint numPlat = 0;
    if (clGetPlatformIDs(0, NULL, &numPlat) != CL_SUCCESS || numPlat == 0) return -1;

    cl_platform_id* plats = (cl_platform_id*)malloc(numPlat * sizeof(cl_platform_id));
    if (!plats) return -1;
    clGetPlatformIDs(numPlat, plats, NULL);

    int found = 0;
    for (cl_uint p = 0; p < numPlat && !found; p++) {
        cl_uint numDev = 0;
        if (clGetDeviceIDs(plats[p], type, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0) continue;

        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(plats[p], type, numDev, devs, NULL);

        for (cl_uint i = 0; i < numDev; i++) {
            char dname[256] = {0};
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(dname), dname, NULL);
            if (!nameHint || !*nameHint || strstr(dname, nameHint)) {
                *outDev = devs[i];
                if (outName && outNameSz > 0) {
                    strncpy(outName, dname, outNameSz - 1);
                    outName[outNameSz - 1] = '\0';
                }
                found = 1;
                break;
            }
        }
        free(devs);
    }
    free(plats);
    return found ? 0 : -1;
}

// Print which device an example actually landed on. Every example calls this so
// its output is self-documenting: a reader can tell from the log alone whether the
// numbers came from the iGPU, the CPU or the NVIDIA card.
static void ocl_report_device(cl_device_id dev) {
    char name[256] = {0}, dver[128] = {0}, cver[128] = {0};
    clGetDeviceInfo(dev, CL_DEVICE_NAME, sizeof(name), name, NULL);
    clGetDeviceInfo(dev, CL_DEVICE_VERSION, sizeof(dver), dver, NULL);
    clGetDeviceInfo(dev, CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);

    // size_t, NOT cl_uint. CL_DEVICE_MAX_WORK_GROUP_SIZE returns size_t; receiving
    // it into a 4-byte cl_uint makes the driver reject the query with
    // CL_INVALID_VALUE and leave the variable at 0, which then prints as a
    // confident and completely fictitious "max work group size: 0".
    size_t maxWG = 0;
    clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
    cl_ulong localMem = 0;
    clGetDeviceInfo(dev, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(localMem), &localMem, NULL);

    printf("[device] %s\n", name);
    printf("[device] %s | %s | max_work_group_size=%zu | local_mem=%llu B\n",
           dver, cver, maxWG, (unsigned long long)localMem);
}

// Read a whole text file into a malloc'd NUL-terminated buffer. Returns NULL on
// failure. Used to load kernels/*.cl so the examples show the realistic
// "kernel lives in its own file" layout rather than embedding source in a string.
static char* ocl_read_file(const char* path) {
    FILE* fp = fopen(path, "rb");
    if (!fp) { printf("[FAIL] cannot open %s\n", path); return NULL; }
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (sz <= 0) { fclose(fp); printf("[FAIL] %s is empty\n", path); return NULL; }
    char* buf = (char*)malloc((size_t)sz + 1);
    if (!buf) { fclose(fp); return NULL; }
    size_t rd = fread(buf, 1, (size_t)sz, fp);
    buf[rd] = '\0';
    fclose(fp);
    return buf;
}

// Round a global size UP to a multiple of the local size.
//
// On an OpenCL 1.2 device clEnqueueNDRangeKernel requires global_work_size to be
// an exact multiple of local_work_size; otherwise it returns
// -54 CL_INVALID_WORK_GROUP_SIZE even when the kernel guards every one of its
// accesses. This trips people up because it looks like a resource error.
//
// Rounding up launches extra work-items past the useful range, so the KERNEL must
// also bounds-check before reading or writing. Host rounding and kernel guarding
// are two halves of one fix and neither works alone.
static size_t ocl_round_up(size_t n, size_t multiple) {
    if (multiple == 0) return n;
    return ((n + multiple - 1) / multiple) * multiple;
}

// Print the single verdict line that OpenCL/build.ps1 keys on, and return the
// matching process exit code so main can "return ocl_report(pass);".
static int ocl_report(int pass) {
    printf("[RESULT] %s\n", pass ? "PASS" : "FAIL");
    return pass ? 0 : 1;
}

// Report a SKIP rather than a FAIL when a precondition is genuinely absent on this
// machine. A skip that is clearly labelled is honest; the same situation reported
// as a pass would be a lie, and reported as a fail would be noise.
static int ocl_report_skip(const char* reason) {
    printf("[skip] %s\n", reason);
    printf("[RESULT] SKIP\n");
    return 0;
}

#endif // OCL_UTIL_H
