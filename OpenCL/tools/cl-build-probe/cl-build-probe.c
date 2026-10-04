// cl-build-probe: compile an OpenCL C source file on a chosen device and print
// the driver's real build log plus the per-kernel work-group resource figures.
//
// This is the "kernel compile" verification channel. It turns "does this kernel
// actually compile on the Intel iGPU" from an opinion into a repeatable artifact.
// It does NOT run the kernel and therefore proves nothing about numerical results
// - that is what examples/ do.
//
//   cl-build-probe.exe <kernel.cl> [kernelName] [deviceHint] [buildOptions]
//
// deviceHint defaults to "UHD" (this machine's Intel iGPU). Pass "NVIDIA", "i7"
// or "CPU" to target a different device. The device is chosen by NAME MATCH across
// every platform, never by taking platforms[0] - on this machine platforms[0] is
// NVIDIA, so blindly using it would silently test the wrong GPU.
//
// Exit code mirrors the build outcome: 0 = built, 1 = build or kernel-creation
// failed, 2 = bad usage / unreadable file / no matching device. Callers that want
// to prove a kernel FAILS (the __const negative case documented in docs/09) assert
// on exit code 1 and on the log text, not on exit code 0.
#define CL_TARGET_OPENCL_VERSION 300
#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char* errName(cl_int e) {
    switch (e) {
        case CL_SUCCESS: return "CL_SUCCESS";
        case CL_INVALID_VALUE: return "CL_INVALID_VALUE";
        case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
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
        case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
        case CL_INVALID_WORK_ITEM_SIZE: return "CL_INVALID_WORK_ITEM_SIZE";
        case CL_INVALID_GLOBAL_WORK_SIZE: return "CL_INVALID_GLOBAL_WORK_SIZE";
        case CL_BUILD_PROGRAM_FAILURE: return "CL_BUILD_PROGRAM_FAILURE";
        case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
        case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
        case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
        case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
        case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
        case CL_INVALID_COMMAND_QUEUE: return "CL_INVALID_COMMAND_QUEUE";
        case CL_INVALID_QUEUE_PROPERTIES: return "CL_INVALID_QUEUE_PROPERTIES";
        case CL_INVALID_BUFFER_SIZE: return "CL_INVALID_BUFFER_SIZE";
        case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
        default: return "(other)";
    }
}

// Pick a device by name keyword across ALL platforms and ALL device types.
static int pickDevice(const char* hint, cl_device_id* out, char* outName, size_t outNameSz) {
    cl_uint np = 0;
    if (clGetPlatformIDs(0, NULL, &np) != CL_SUCCESS || np == 0) return -1;
    cl_platform_id* ps = (cl_platform_id*)malloc(np * sizeof(cl_platform_id));
    clGetPlatformIDs(np, ps, NULL);
    int found = 0;
    for (cl_uint p = 0; p < np && !found; p++) {
        cl_uint nd = 0;
        if (clGetDeviceIDs(ps[p], CL_DEVICE_TYPE_ALL, 0, NULL, &nd) != CL_SUCCESS || !nd) continue;
        cl_device_id* ds = (cl_device_id*)malloc(nd * sizeof(cl_device_id));
        clGetDeviceIDs(ps[p], CL_DEVICE_TYPE_ALL, nd, ds, NULL);
        for (cl_uint i = 0; i < nd; i++) {
            char dn[256] = {0};
            clGetDeviceInfo(ds[i], CL_DEVICE_NAME, sizeof(dn), dn, NULL);
            if (!hint || !*hint || strstr(dn, hint)) {
                *out = ds[i];
                if (outName) { strncpy(outName, dn, outNameSz - 1); outName[outNameSz - 1] = '\0'; }
                found = 1; break;
            }
        }
        free(ds);
    }
    free(ps);
    return found ? 0 : -1;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("usage: cl-build-probe <kernel.cl> [kernelName] [deviceHint] [buildOptions]\n");
        printf("       deviceHint defaults to \"UHD\"; try \"NVIDIA\", \"i7\", \"CPU\"\n");
        return 2;
    }
    const char* srcPath   = argv[1];
    const char* kernName  = (argc > 2) ? argv[2] : NULL;
    const char* hint      = (argc > 3) ? argv[3] : "UHD";
    const char* buildOpts = (argc > 4) ? argv[4] : NULL;

    FILE* fp = fopen(srcPath, "rb");
    if (!fp) { printf("[FAIL] cannot open %s\n", srcPath); return 2; }
    fseek(fp, 0, SEEK_END); long sz = ftell(fp); fseek(fp, 0, SEEK_SET);
    if (sz <= 0) { printf("[FAIL] %s is empty\n", srcPath); fclose(fp); return 2; }
    char* src = (char*)malloc((size_t)sz + 1);
    size_t rd = fread(src, 1, (size_t)sz, fp); src[rd] = '\0'; fclose(fp);

    cl_device_id dev;
    char picked[256] = {0};
    if (pickDevice(hint, &dev, picked, sizeof(picked)) != 0) {
        printf("[FAIL] no device matching \"%s\"\n", hint);
        free(src); return 2;
    }

    char cver[128] = {0}, dver[128] = {0};
    clGetDeviceInfo(dev, CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);
    clGetDeviceInfo(dev, CL_DEVICE_VERSION, sizeof(dver), dver, NULL);

    // size_t, not cl_uint: CL_DEVICE_MAX_WORK_GROUP_SIZE returns size_t and a
    // 4-byte receiver makes the driver reject the query, silently leaving 0.
    size_t maxWG = 0;
    clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
    cl_ulong lmem = 0;
    clGetDeviceInfo(dev, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(lmem), &lmem, NULL);
    cl_bool imgSupport = CL_FALSE;
    clGetDeviceInfo(dev, CL_DEVICE_IMAGE_SUPPORT, sizeof(imgSupport), &imgSupport, NULL);

    printf("source       : %s\n", srcPath);
    printf("device       : %s\n", picked);
    printf("device ver   : %s\n", dver);
    printf("opencl C ver : %s\n", cver);
    printf("max workgroup: %zu\n", maxWG);
    printf("local mem    : %llu bytes\n", (unsigned long long)lmem);
    printf("image support: %s\n", imgSupport ? "yes" : "no");
    printf("build options: %s\n", (buildOpts && *buildOpts) ? buildOpts : "(none)");
    printf("---\n");

    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clCreateContext -> %d %s\n", err, errName(err));
        free(src); return 1;
    }

    size_t len = strlen(src);
    cl_program prog = clCreateProgramWithSource(ctx, 1, (const char**)&src, &len, &err);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clCreateProgramWithSource -> %d %s\n", err, errName(err));
        clReleaseContext(ctx); free(src); return 1;
    }

    err = clBuildProgram(prog, 1, &dev, buildOpts, NULL, NULL);

    // Always fetch the log, including on success: Intel's driver emits useful
    // warnings for kernels that still build.
    size_t logSz = 0;
    clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
    char* log = (char*)malloc(logSz + 1);
    clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
    log[logSz] = '\0';
    printf("clBuildProgram -> %d (%s)\n", err, errName(err));
    if (logSz > 1) printf("--- build log ---\n%s\n-----------------\n", log);
    free(log);

    int rc = (err == CL_SUCCESS) ? 0 : 1;

    if (err == CL_SUCCESS && kernName && *kernName) {
        cl_kernel k = clCreateKernel(prog, kernName, &err);
        printf("clCreateKernel(\"%s\") -> %d (%s)\n", kernName, err, errName(err));
        if (err == CL_SUCCESS) {
            // These three are what actually decide whether a launch will be rejected
            // with CL_INVALID_WORK_GROUP_SIZE before you ever run it.
            size_t kwg = 0;
            clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_WORK_GROUP_SIZE, sizeof(kwg), &kwg, NULL);
            cl_ulong klm = 0;
            clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_LOCAL_MEM_SIZE, sizeof(klm), &klm, NULL);
            cl_ulong kpm = 0;
            clGetKernelWorkGroupInfo(k, dev, CL_KERNEL_PRIVATE_MEM_SIZE, sizeof(kpm), &kpm, NULL);
            printf("  CL_KERNEL_WORK_GROUP_SIZE  = %zu\n", kwg);
            printf("  CL_KERNEL_LOCAL_MEM_SIZE   = %llu\n", (unsigned long long)klm);
            printf("  CL_KERNEL_PRIVATE_MEM_SIZE = %llu\n", (unsigned long long)kpm);
            if (maxWG && kwg > maxWG)
                printf("  [WARN] kernel work group %zu exceeds device max %zu\n", kwg, maxWG);
            if (klm > (cl_ulong)lmem)
                printf("  [WARN] kernel local mem %llu exceeds device local mem %llu\n",
                       (unsigned long long)klm, (unsigned long long)lmem);
            clReleaseKernel(k);
        } else {
            rc = 1;
        }
    }

    clReleaseProgram(prog);
    clReleaseContext(ctx);
    free(src);
    printf("[RESULT] %s\n", rc == 0 ? "BUILD OK" : "BUILD FAILED");
    return rc;
}
