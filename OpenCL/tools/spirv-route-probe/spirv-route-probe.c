// tools/spirv-route-probe - two SPIR-V routes, one kernel, three devices.
//
// build-spirv.ps1 compiles examples/09-spirv-il/kernels/vector_add.cl twice:
// once with clang's own SPIR-V backend, once by emitting LLVM IR and running it
// through llvm-spirv. Both modules are valid SPIR-V, both pass spirv-val, both
// carry the same kernel name and the same four arguments. On this machine they do
// not behave the same way, and this probe is what measures the difference.
//
// Usage:
//   spirv-route-probe.exe <module.spv> <kernelName> <sourceArity> [-bind-all]
//
// One line is printed per (module, device) pair in a fixed shape so build.ps1 can
// assert on it:
//   [probe] key=<key> create=<e> build=<e> kernel=<e> numargs=<n> launch=<e> verify=<ok>/<N>
//
// <sourceArity> is the number of arguments the C source declares. It is passed in
// rather than read from CL_KERNEL_NUM_ARGS precisely because that query is the thing
// under test: on the Intel iGPU it reports 8 for a 4-argument kernel when the module
// came from llvm-spirv, and 4 when it came from clang's backend.
//
// ---------------------------------------------------------------------------
// -bind-all, and why it is not the default
// ---------------------------------------------------------------------------
// Binding only the four real arguments is what an application does, and it is safe:
// the driver returns -52 CL_INVALID_KERNEL_ARGS from the launch. Binding every
// index CL_KERNEL_NUM_ARGS advertises is NOT safe. On the Intel iGPU driver the
// first clSetKernelArg at an index AT OR PAST the source arity calls abort()
// inside the driver - index 4 for this four-argument kernel, index 3 for a
// three-argument one. Every index below that returns CL_SUCCESS first:
//
//     [setarg] key=uhd index=0 -> 0(CL_SUCCESS)
//     [setarg] key=uhd index=1 -> 0(CL_SUCCESS)
//     [setarg] key=uhd index=2 -> 0(CL_SUCCESS)
//     [setarg] key=uhd index=3 -> 0(CL_SUCCESS)
//     Abort was called at 211 line in file:
//     <process dies, exit 0xC0000409>
//
// No cl_int comes back and nothing upstream can catch it. That is why the default
// path stops at the source arity and why -bind-all has to be asked for explicitly:
// a harness that crashes on its own evidence is worse than one that documents it.
// Reproducing the abort is a deliberate act, not a side effect of running the tests.
// The driver itself survives: examples/01-device-query passes again immediately
// afterwards, with no reset and no reboot.
//
// ---------------------------------------------------------------------------
// What the measurements say
// ---------------------------------------------------------------------------
// The translator module's entry point is a THUNK: a four-parameter function whose
// entire body is OpFunctionCall to %vector_add, which also takes four parameters.
// The backend module's entry point IS %vector_add. The iGPU driver counts the
// parameters of both, which is why the reported arity is exactly twice the real one
// - measured at 2->4, 3->6 and 4->8 across three different kernels.
//
// That is correlation until you intervene, so build.ps1 also runs the intervention:
// disassemble the translator module, repoint OpEntryPoint at %vector_add, delete the
// thunk, reassemble. The edited module reports numargs=4, matching the backend
// route. Removing the thunk - and nothing else - removes the doubling.
//
// Pure ASCII: MSVC's /utf-8 handles the source, but the cp936 console mangles the
// driver's abort text this probe exists to observe.
#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROBE_N 1024
#define PROBE_MAX_DEV 16

static const char* ename(cl_int e) {
    switch (e) {
    case CL_SUCCESS: return "CL_SUCCESS";
    case CL_INVALID_VALUE: return "CL_INVALID_VALUE";
    case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
    case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
    case CL_INVALID_BINARY: return "CL_INVALID_BINARY";
    case CL_INVALID_PROGRAM: return "CL_INVALID_PROGRAM";
    case CL_INVALID_PROGRAM_EXECUTABLE: return "CL_INVALID_PROGRAM_EXECUTABLE";
    case CL_INVALID_KERNEL_NAME: return "CL_INVALID_KERNEL_NAME";
    case CL_INVALID_KERNEL: return "CL_INVALID_KERNEL";
    case CL_INVALID_ARG_INDEX: return "CL_INVALID_ARG_INDEX";
    case CL_INVALID_KERNEL_ARGS: return "CL_INVALID_KERNEL_ARGS";
    case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
    case CL_INVALID_OPERATION: return "CL_INVALID_OPERATION";
    case CL_BUILD_PROGRAM_FAILURE: return "CL_BUILD_PROGRAM_FAILURE";
    case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
    default: return "(other)";
    }
}

// A short, stable key per device so build.ps1 can assert on "key=uhd" without
// depending on the exact marketing string or on enumeration order.
static void device_key(cl_device_id d, char* out, size_t outSz) {
    char name[256] = {0}, vendor[256] = {0};
    cl_device_type t = 0;
    clGetDeviceInfo(d, CL_DEVICE_NAME, sizeof(name), name, NULL);
    clGetDeviceInfo(d, CL_DEVICE_VENDOR, sizeof(vendor), vendor, NULL);
    clGetDeviceInfo(d, CL_DEVICE_TYPE, sizeof(t), &t, NULL);

    const char* k = "other";
    if (strstr(vendor, "NVIDIA") || strstr(name, "GeForce")) k = "nvidia";
    else if (strstr(name, "UHD") || strstr(name, "HD Graphics") || strstr(name, "Iris")) k = "uhd";
    else if ((t & CL_DEVICE_TYPE_CPU) && strstr(vendor, "Intel")) k = "intelcpu";
    strncpy(out, k, outSz - 1);
    out[outSz - 1] = '\0';
}

static unsigned char* slurp(const char* path, size_t* outLen) {
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0) { fclose(f); return NULL; }
    unsigned char* b = (unsigned char*)malloc((size_t)sz);
    if (!b) { fclose(f); return NULL; }
    if (fread(b, 1, (size_t)sz, f) != (size_t)sz) { fclose(f); free(b); return NULL; }
    fclose(f);
    *outLen = (size_t)sz;
    return b;
}

// One (module, device) trial. Prints exactly one [probe] line.
static void trial(cl_device_id dev, const char* key, const unsigned char* il, size_t ilLen,
                  const char* kname, cl_uint arity, int bindAll) {
    char name[256] = {0};
    clGetDeviceInfo(dev, CL_DEVICE_NAME, sizeof(name), name, NULL);

    // What the device claims about IL, queried the way the spec says: as a STRING.
    // An empty string means no IL support, and there is no boolean form of this
    // query - reading it into a cl_bool is the bug chapter 08 corrects.
    char ilver[512] = {0};
    size_t got = 0;
    cl_int qe = clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, sizeof(ilver), ilver, &got);
    printf("[device] key=%s name=%s IL_VERSION(err=%d)='%s'\n", key, name, qe, qe ? "(query failed)" : ilver);

    cl_int e = 0;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &e);
    if (!ctx) { printf("[probe] key=%s create=- context=%d\n", key, e); return; }

    cl_program prog = clCreateProgramWithIL(ctx, il, ilLen, &e);
    cl_int eCreate = e;
    if (!prog || e != CL_SUCCESS) {
        printf("[probe] key=%s create=%d(%s) build=- kernel=- numargs=- launch=- verify=-\n",
               key, eCreate, ename(eCreate));
        clReleaseContext(ctx);
        return;
    }

    e = clBuildProgram(prog, 1, &dev, NULL, NULL, NULL);
    cl_int eBuild = e;
    if (e != CL_SUCCESS) {
        size_t ln = 0;
        clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &ln);
        if (ln > 1) {
            char* log = (char*)malloc(ln + 1);
            if (log) {
                clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, ln, log, NULL);
                log[ln] = '\0';
                printf("[build log] key=%s\n%s\n", key, log);
                free(log);
            }
        }
        printf("[probe] key=%s create=0 build=%d(%s) kernel=- numargs=- launch=- verify=-\n",
               key, eBuild, ename(eBuild));
        clReleaseProgram(prog); clReleaseContext(ctx);
        return;
    }

    cl_kernel k = clCreateKernel(prog, kname, &e);
    cl_int eKernel = e;
    if (!k || e != CL_SUCCESS) {
        printf("[probe] key=%s create=0 build=0 kernel=%d(%s) numargs=- launch=- verify=-\n",
               key, eKernel, ename(eKernel));
        clReleaseProgram(prog); clReleaseContext(ctx);
        return;
    }

    // The number under test. Reported, never trusted.
    cl_uint numArgs = 0;
    clGetKernelInfo(k, CL_KERNEL_NUM_ARGS, sizeof(numArgs), &numArgs, NULL);

    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &e);
    if (!q) {
        printf("[probe] key=%s create=0 build=0 kernel=0 numargs=%u launch=queue-failed verify=-\n",
               key, numArgs);
        clReleaseKernel(k); clReleaseProgram(prog); clReleaseContext(ctx);
        return;
    }

    float* ha = (float*)malloc(PROBE_N * sizeof(float));
    float* hb = (float*)malloc(PROBE_N * sizeof(float));
    float* hc = (float*)malloc(PROBE_N * sizeof(float));
    for (int i = 0; i < PROBE_N; i++) { ha[i] = (float)i; hb[i] = (float)(i * 2); hc[i] = -1.0f; }

    cl_mem A = clCreateBuffer(ctx, CL_MEM_READ_ONLY,  PROBE_N * sizeof(float), NULL, NULL);
    cl_mem B = clCreateBuffer(ctx, CL_MEM_READ_ONLY,  PROBE_N * sizeof(float), NULL, NULL);
    cl_mem C = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, PROBE_N * sizeof(float), NULL, NULL);
    clEnqueueWriteBuffer(q, A, CL_TRUE, 0, PROBE_N * sizeof(float), ha, 0, NULL, NULL);
    clEnqueueWriteBuffer(q, B, CL_TRUE, 0, PROBE_N * sizeof(float), hb, 0, NULL, NULL);

    // Bind the four arguments the source declares. -bind-all instead binds every
    // index the driver advertised, which on the iGPU aborts the process - see the
    // header comment. The abort is the finding; the flag is how a reader reproduces
    // it without the test suite depending on a crash.
    cl_uint toBind = bindAll ? numArgs : arity;
    if (toBind > 16) toBind = 16;
    for (cl_uint i = 0; i < toBind; i++) {
        void* val; size_t sz;
        int n = PROBE_N;
        switch (i) {
        case 0: val = &A; sz = sizeof(cl_mem); break;
        case 1: val = &B; sz = sizeof(cl_mem); break;
        case 2: val = &C; sz = sizeof(cl_mem); break;
        default: val = &n; sz = sizeof(int); break;
        }
        cl_int se = clSetKernelArg(k, i, sz, val);
        printf("[setarg] key=%s index=%u -> %d(%s)\n", key, i, se, ename(se));
        fflush(stdout);
    }

    size_t gws = PROBE_N, lws = 64;
    cl_int eLaunch = clEnqueueNDRangeKernel(q, k, 1, NULL, &gws, &lws, 0, NULL, NULL);

    int ok = -1;
    if (eLaunch == CL_SUCCESS) {
        clFinish(q);
        clEnqueueReadBuffer(q, C, CL_TRUE, 0, PROBE_N * sizeof(float), hc, 0, NULL, NULL);
        ok = 0;
        for (int i = 0; i < PROBE_N; i++) {
            if (hc[i] == (float)i + (float)(i * 2)) ok++;
        }
    }

    printf("[probe] key=%s create=0 build=0 kernel=0 numargs=%u launch=%d(%s) verify=%d/%d\n",
           key, numArgs, eLaunch, ename(eLaunch), ok, PROBE_N);

    clReleaseMemObject(A); clReleaseMemObject(B); clReleaseMemObject(C);
    free(ha); free(hb); free(hc);
    clReleaseCommandQueue(q); clReleaseKernel(k); clReleaseProgram(prog); clReleaseContext(ctx);
}

int main(int argc, char** argv) {
    // Unbuffered. This probe can be made to crash the driver with -bind-all, and a
    // buffered stdout would lose every line printed before the abort.
    setvbuf(stdout, NULL, _IONBF, 0);

    if (argc < 4) {
        printf("usage: spirv-route-probe <module.spv> <kernelName> <sourceArity> [-bind-all]\n");
        return 2;
    }
    const char* path = argv[1];
    const char* kname = argv[2];
    cl_uint arity = (cl_uint)atoi(argv[3]);
    int bindAll = 0;
    for (int i = 4; i < argc; i++) if (strcmp(argv[i], "-bind-all") == 0) bindAll = 1;

    size_t ilLen = 0;
    unsigned char* il = slurp(path, &ilLen);
    if (!il) { printf("[FAIL] cannot read %s\n", path); return 2; }

    // Decode the header here too, so the module's own claim about its version sits
    // next to the device's claim about which versions it supports.
    unsigned magic = 0, ver = 0, gen = 0, bound = 0;
    memcpy(&magic, il + 0, 4); memcpy(&ver, il + 4, 4);
    memcpy(&gen, il + 8, 4); memcpy(&bound, il + 12, 4);
    printf("[module] %s\n", path);
    printf("[module] %zu bytes magic=0x%08X(%s) SPIR-V %u.%u generator=%u bound=%u\n",
           ilLen, magic, magic == 0x07230203u ? "ok" : "BAD",
           (ver >> 16) & 0xFFFF, (ver >> 8) & 0xFF, gen & 0xFFFF, bound);
    printf("[module] kernel='%s' sourceArity=%u bindAll=%d\n", kname, arity, bindAll);

    cl_uint np = 0;
    if (clGetPlatformIDs(0, NULL, &np) != CL_SUCCESS || np == 0) {
        printf("[FAIL] no OpenCL platforms\n");
        return 2;
    }
    cl_platform_id* ps = (cl_platform_id*)malloc(np * sizeof(*ps));
    clGetPlatformIDs(np, ps, NULL);

    int trials = 0;
    for (cl_uint i = 0; i < np; i++) {
        cl_uint nd = 0;
        if (clGetDeviceIDs(ps[i], CL_DEVICE_TYPE_ALL, 0, NULL, &nd) != CL_SUCCESS || nd == 0) continue;
        cl_device_id* ds = (cl_device_id*)malloc(nd * sizeof(*ds));
        clGetDeviceIDs(ps[i], CL_DEVICE_TYPE_ALL, nd, ds, NULL);
        for (cl_uint j = 0; j < nd && trials < PROBE_MAX_DEV; j++) {
            char key[32] = {0};
            device_key(ds[j], key, sizeof(key));
            // The tutorial's subject is the iGPU; the others are here as controls.
            // "other" devices are skipped so an unexpected USB accelerator cannot
            // change the probe's output shape between runs.
            if (strcmp(key, "other") == 0) continue;
            trial(ds[j], key, il, ilLen, kname, arity, bindAll);
            trials++;
        }
        free(ds);
    }
    free(ps);
    free(il);
    printf("[probe] %d trial(s)\n", trials);
    return 0;
}
