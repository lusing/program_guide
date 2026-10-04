// examples/01-device-query - what OpenCL hardware is actually on this machine?
//
// Every later example picks its device by name, so the first thing to do is find
// out what names exist. This program enumerates every platform and every device,
// prints the capabilities that decide what you may and may not write, and ends with
// a compact comparison table.
//
// The single most useful thing it prints is the pair CL_DEVICE_VERSION and
// CL_DEVICE_OPENCL_C_VERSION. On this machine both GPUs say "OpenCL 3.0" for the
// former and "OpenCL C 1.2" for the latter. Those are different questions: the
// first is the runtime API level, the second is the kernel LANGUAGE level, and it
// is the language level that decides whether to_global() or sub_group_broadcast()
// compiles by default. Reading only the first one is how people end up believing a
// device cannot do something it can.
//
// Build and run via OpenCL/build.ps1. Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

static const char* device_type_name(cl_device_type t) {
    switch (t) {
    case CL_DEVICE_TYPE_CPU:         return "CPU";
    case CL_DEVICE_TYPE_GPU:         return "GPU";
    case CL_DEVICE_TYPE_ACCELERATOR: return "ACCELERATOR";
    case CL_DEVICE_TYPE_DEFAULT:     return "DEFAULT";
    default:                         return "OTHER";
    }
}

// CL_DEVICE_IL_VERSION is a STRING listing the supported intermediate languages,
// not a boolean. The empty string means "no SPIR-V, so clCreateProgramWithIL is
// unusable here". Query it by asking for the size first, then allocating.
static void print_il_version(cl_device_id dev) {
    size_t sz = 0;
    if (clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, 0, NULL, &sz) == CL_SUCCESS && sz > 1) {
        char* il = (char*)malloc(sz);
        if (!il) return;
        clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, sz, il, NULL);
        printf("      IL version       : %s\n", il);
        free(il);
    } else {
        printf("      IL version       : (empty => no SPIR-V support)\n");
    }
}

// SVM capabilities are a bitmask, and OpenCL 3.0 made every one of these bits
// optional. Decode all four so the reader can see exactly which flavour of shared
// virtual memory a device offers.
static void print_svm(cl_device_id dev) {
    cl_device_svm_capabilities svm = 0;
    if (clGetDeviceInfo(dev, CL_DEVICE_SVM_CAPABILITIES, sizeof(svm), &svm, NULL) != CL_SUCCESS) {
        printf("      SVM capabilities : (query unsupported)\n");
        return;
    }
    printf("      SVM capabilities : 0x%X (coarse=%d fine=%d fine_system=%d atomics=%d)\n",
           (unsigned)svm,
           (int)((svm & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER) != 0),
           (int)((svm & CL_DEVICE_SVM_FINE_GRAIN_BUFFER) != 0),
           (int)((svm & CL_DEVICE_SVM_FINE_GRAIN_SYSTEM) != 0),
           (int)((svm & CL_DEVICE_SVM_ATOMICS) != 0));
}

int main(void) {
    cl_uint numPlatforms = 0;
    cl_int err = clGetPlatformIDs(0, NULL, &numPlatforms);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clGetPlatformIDs(count) -> %d %s\n", err, ocl_err_name(err));
        printf("       No OpenCL platform means no ICD loader, or no vendor driver registered.\n");
        return ocl_report(0);
    }
    printf("platforms found: %u\n", numPlatforms);

    cl_platform_id* platforms = (cl_platform_id*)malloc(numPlatforms * sizeof(cl_platform_id));
    if (!platforms) return ocl_report(0);
    clGetPlatformIDs(numPlatforms, platforms, NULL);

    int totalDevices = 0;
    int foundTarget = 0;
    char targetName[256] = {0};

    for (cl_uint p = 0; p < numPlatforms; p++) {
        char pname[256] = {0}, pvend[256] = {0}, pver[256] = {0};
        clGetPlatformInfo(platforms[p], CL_PLATFORM_NAME, sizeof(pname), pname, NULL);
        clGetPlatformInfo(platforms[p], CL_PLATFORM_VENDOR, sizeof(pvend), pvend, NULL);
        clGetPlatformInfo(platforms[p], CL_PLATFORM_VERSION, sizeof(pver), pver, NULL);

        printf("\n=== Platform %u: %s ===\n", p, pname);
        printf("    vendor  : %s\n", pvend);
        printf("    version : %s\n", pver);
        // Only true when p == 0. An earlier revision printed this inside the loop,
        // so the output claimed three times over that platforms[0] was three
        // different things - undercutting the exact lesson the note is there to
        // teach.
        if (p == 0) {
            printf("    NOTE    : platforms[0] here is \"%s\". Sample code that blindly takes\n"
                   "              platforms[0] would run on this vendor, not necessarily the one\n"
                   "              you meant. That is why every example selects by device name.\n", pname);
        }

        cl_uint numDev = 0;
        if (clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0) {
            printf("    (no devices)\n");
            continue;
        }
        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, numDev, devs, NULL);

        for (cl_uint i = 0; i < numDev; i++) {
            cl_device_type type = 0;
            char dname[256] = {0}, dver[128] = {0}, cver[128] = {0}, driver[128] = {0};
            clGetDeviceInfo(devs[i], CL_DEVICE_TYPE, sizeof(type), &type, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(dname), dname, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_VERSION, sizeof(dver), dver, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);
            clGetDeviceInfo(devs[i], CL_DRIVER_VERSION, sizeof(driver), driver, NULL);

            // size_t, not cl_uint - see the note in ocl_util.h.
            size_t maxWG = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
            cl_ulong localMem = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(localMem), &localMem, NULL);
            cl_ulong globalMem = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(globalMem), &globalMem, NULL);
            cl_uint units = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(units), &units, NULL);
            cl_bool img = CL_FALSE;
            clGetDeviceInfo(devs[i], CL_DEVICE_IMAGE_SUPPORT, sizeof(img), &img, NULL);
            cl_device_local_mem_type lmt = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_LOCAL_MEM_TYPE, sizeof(lmt), &lmt, NULL);

            printf("  --- Device %u: %s [%s] ---\n", i, dname, device_type_name(type));
            printf("      runtime version  : %s\n", dver);
            printf("      LANGUAGE version : %s   <-- this one decides what kernels you may write\n", cver);
            printf("      driver version   : %s\n", driver);
            printf("      compute units    : %u\n", units);
            printf("      max work group   : %zu\n", maxWG);
            printf("      local mem        : %llu B (%s)\n", (unsigned long long)localMem,
                   lmt == CL_LOCAL ? "CL_LOCAL, dedicated on-chip" :
                   lmt == CL_GLOBAL ? "CL_GLOBAL, backed by global memory - tiling buys nothing here" : "none");
            printf("      global mem       : %llu B\n", (unsigned long long)globalMem);
            printf("      image support    : %s\n", img ? "yes" : "no");
            print_il_version(devs[i]);
            print_svm(devs[i]);

            size_t extSz = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_EXTENSIONS, 0, NULL, &extSz);
            if (extSz > 1) {
                char* ext = (char*)malloc(extSz);
                if (ext) {
                    clGetDeviceInfo(devs[i], CL_DEVICE_EXTENSIONS, extSz, ext, NULL);
                    // Subgroups are an EXTENSION question, not a version question:
                    // both Intel devices expose these, NVIDIA exposes neither, and
                    // that - not the version string - predicts whether
                    // sub_group_broadcast() compiles.
                    //
                    // Test BEFORE tokenising. strtok overwrites each separator with
                    // a NUL, so after the counting loop `ext` is only the first
                    // extension name and searching it finds nothing - which prints a
                    // confident and wrong "subgroups=no" for devices that have them.
                    int hasSubgroups = (strstr(ext, "cl_khr_subgroups") != NULL) ||
                                       (strstr(ext, "cl_intel_subgroups") != NULL);
                    int cnt = 0;
                    for (char* tok = strtok(ext, " "); tok; tok = strtok(NULL, " ")) cnt++;
                    printf("      extensions       : %d total, subgroups=%s\n", cnt,
                           hasSubgroups ? "yes" : "no");
                    free(ext);
                }
            }

            totalDevices++;
            if (strstr(dname, OCL_DEFAULT_DEVICE)) {
                foundTarget = 1;
                strncpy(targetName, dname, sizeof(targetName) - 1);
            }
        }
        free(devs);
    }

    printf("\n=== comparison table ===\n");
    // 40, not 38: the longest device name on this machine ("Intel(R) Core(TM)
    // i7-9700 CPU @ 3.00GHz") is 39 characters and overflowed into the next column.
    printf("%-40s %-14s %-8s %-10s %s\n", "device", "OpenCL C", "max WG", "local mem", "SPIR-V");
    for (cl_uint p = 0; p < numPlatforms; p++) {
        cl_uint numDev = 0;
        if (clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0) continue;
        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, numDev, devs, NULL);
        for (cl_uint i = 0; i < numDev; i++) {
            char dname[256] = {0}, cver[128] = {0};
            size_t maxWG = 0;
            cl_ulong localMem = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(dname), dname, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(maxWG), &maxWG, NULL);
            clGetDeviceInfo(devs[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(localMem), &localMem, NULL);
            size_t ilSz = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_IL_VERSION, 0, NULL, &ilSz);
            printf("%-40s %-14s %-8zu %-10llu %s\n", dname, cver, maxWG,
                   (unsigned long long)localMem, (ilSz > 1) ? "yes" : "no");
        }
        free(devs);
    }

    free(platforms);

    // Assertions. Deliberately modest: this example must pass on any machine that
    // has OpenCL at all, not only on this one. The presence of the tutorial's
    // target iGPU is reported but not required, so the example stays useful to a
    // reader with different hardware.
    int pass = (numPlatforms >= 1) && (totalDevices >= 1);
    printf("\nassert platforms >= 1        : %u %s\n", numPlatforms, numPlatforms >= 1 ? "OK" : "FAILED");
    printf("assert devices >= 1          : %d %s\n", totalDevices, totalDevices >= 1 ? "OK" : "FAILED");
    if (foundTarget)
        printf("tutorial target device found : %s\n", targetName);
    else
        printf("tutorial target device found : NO - later examples default to \"%s\" and will\n"
               "                               fail to find it; pass your own device name instead\n",
               OCL_DEFAULT_DEVICE);

    return ocl_report(pass);
}
