// examples/09-spirv-il - load a kernel that was compiled BEFORE the program ran.
//
// Every earlier example hands the driver OpenCL C source and lets it compile at
// run time. This one hands the driver a SPIR-V module that OpenCL/build-spirv.ps1
// produced offline, through clCreateProgramWithIL.
//
// The kernel file is byte-identical to examples/02-vector-add/kernels/vector_add.cl
// (md5 89ec17a0b2c75f7dbd8c91bfb4029472). That is deliberate and it is the point:
// nothing on the device side changed, so the verification below is the same
// element-by-element comparison against a CPU reference. If the numbers match, the
// offline route produced the same kernel as the runtime route, and the only thing
// this example adds is where the compilation happened.
//
// What this example demonstrates that the others cannot:
//
//   1. CL_DEVICE_IL_VERSION is a STRING query. There is no boolean form of it, and
//      reading it into a cl_bool - which is what a great deal of sample code does -
//      does not silently return false, it returns an error and leaves the variable
//      untouched. Step 2 below runs all three variants side by side so the
//      difference is measured rather than asserted.
//
//   2. A device that does not support IL fails CLEANLY. clCreateProgramWithIL
//      returns -59 CL_INVALID_OPERATION and nothing crashes. Step 11 looks for such
//      a device on purpose. It also measures the detection idiom that sample code
//      usually recommends: ask for the size and reject the device if it is zero.
//      An empty string still reports room for its terminator, so that device comes
//      back with size=1 and the idiom lets it through.
//
//   3. Build options are ignored for an IL program and mis-checked for a source one.
//      Step 8 sweeps four -cl-std values across both. The IL program accepts all four,
//      including a language level that does not exist, because there is no source left
//      for the option to apply to. The source program accepts CL1.2, CL2.0 and CL3.0 on
//      a device whose compiler is "OpenCL C 1.2", and rejects only CL9.9 - with a build
//      log saying the comparison is against the OpenCL API version (3.0 here), not the
//      OpenCL C version. Asking a 1.2 compiler for OpenCL C 2.0 is therefore not an
//      error, which is the kind of thing that only shows up when you try it.
//
//   4. Argument reflection stops working. Step 10 queries clGetKernelArgInfo on the
//      IL kernel and on a kernel built from source out of the SAME file, in the same
//      run. The source one answers; the IL one does not, and what it returns instead
//      is why the values are printed next to their error codes.
//
// Precondition: run OpenCL/build-spirv.ps1 first. Without it there is no module to
// load, and this example reports SKIP rather than FAIL - a missing toolchain is not
// a broken program, and calling it a failure would train readers to ignore red.
//
// Contract: exit 0 + "[RESULT] PASS", or "[RESULT] SKIP" when spv/vector_add.spv is
// absent.
#include "ocl_util.h"

#define N 1024

// Find a device whose CL_DEVICE_IL_VERSION is EMPTY, i.e. one that cannot take an
// IL program at all. Returns 0 if such a device was found. This is the negative
// control: step 10 uses it to show the failure mode is a clean error code.
//
// Deliberately does not fall back to "any device that is not the target". A machine
// where every device supports IL has no negative control to offer, and inventing one
// would test nothing.
static int ocl_find_device_without_il(cl_device_id* outDev, char* outName, size_t outNameSz) {
    cl_uint numPlat = 0;
    if (clGetPlatformIDs(0, NULL, &numPlat) != CL_SUCCESS || numPlat == 0) return -1;
    cl_platform_id* plats = (cl_platform_id*)malloc(numPlat * sizeof(cl_platform_id));
    if (!plats) return -1;
    clGetPlatformIDs(numPlat, plats, NULL);

    int found = -1;
    for (cl_uint p = 0; p < numPlat && found != 0; p++) {
        cl_uint numDev = 0;
        if (clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, 0, NULL, &numDev) != CL_SUCCESS || !numDev) continue;
        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, numDev, devs, NULL);
        for (cl_uint i = 0; i < numDev; i++) {
            char il[512] = {0};
            size_t got = 0;
            if (clGetDeviceInfo(devs[i], CL_DEVICE_IL_VERSION, sizeof(il), il, &got) != CL_SUCCESS) continue;
            if (got > 1 && il[0] != '\0') continue;          // supports IL, not what we want
            char nm[256] = {0};
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(nm), nm, NULL);
            *outDev = devs[i];
            if (outName && outNameSz) { strncpy(outName, nm, outNameSz - 1); outName[outNameSz - 1] = '\0'; }
            found = 0;
            break;
        }
        free(devs);
    }
    free(plats);
    return found;
}

// Read a whole binary file. ocl_read_file is for text and NUL-terminates, which is
// wrong for a SPIR-V module: a 0x00 byte inside the module would look like the end.
// Returns NULL on failure and sets *outLen.
static unsigned char* read_binary(const char* path, size_t* outLen) {
    FILE* fp = fopen(path, "rb");
    if (!fp) return NULL;
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (sz <= 0) { fclose(fp); return NULL; }
    unsigned char* buf = (unsigned char*)malloc((size_t)sz);
    if (!buf) { fclose(fp); return NULL; }
    if (fread(buf, 1, (size_t)sz, fp) != (size_t)sz) { fclose(fp); free(buf); return NULL; }
    fclose(fp);
    *outLen = (size_t)sz;
    return buf;
}

// Dump clGetKernelArgInfo for the four arguments of vector_add, next to the error
// code of each individual query.
//
// The numbers this prints for an IL kernel look like garbage - 4507, 4515 - and the
// first time they were recorded here they were written up as exactly that. They are
// not. 4507 is 0x119B, CL_KERNEL_ARG_ADDRESS_GLOBAL; 4515 is 0x11A3,
// CL_KERNEL_ARG_ACCESS_NONE (cl.h:769-782). Every one of them comes back with err=0,
// and every one of them is IDENTICAL to what the source-built control kernel in
// step 10 reports. The only thing an IL program loses is CL_KERNEL_ARG_NAME.
//
// That is why the error code rides along with each value rather than being checked
// once at the top: a bare 4507 is not readable without cl.h open, and err=0 is the
// difference between "the driver considers this an answer" and uninitialized memory.
// It is also why the control kernel exists at all - without a column to compare
// against, these numbers cannot be interpreted, only guessed at.
static void dump_arg_info(const char* tag, cl_kernel k) {
    if (!k) { printf("[arginfo] %s: no kernel to query\n", tag); return; }
    for (cl_uint i = 0; i < 4; i++) {
        cl_kernel_arg_address_qualifier aq = 0;
        cl_kernel_arg_access_qualifier  ac = 0;
        char typeName[128] = {0}, argName[128] = {0};
        cl_int e1 = clGetKernelArgInfo(k, i, CL_KERNEL_ARG_ADDRESS_QUALIFIER, sizeof(aq), &aq, NULL);
        cl_int e2 = clGetKernelArgInfo(k, i, CL_KERNEL_ARG_ACCESS_QUALIFIER,  sizeof(ac), &ac, NULL);
        cl_int e3 = clGetKernelArgInfo(k, i, CL_KERNEL_ARG_TYPE_NAME, sizeof(typeName), typeName, NULL);
        cl_int e4 = clGetKernelArgInfo(k, i, CL_KERNEL_ARG_NAME,      sizeof(argName), argName, NULL);
        printf("[arginfo] %s arg%u: addr=%d err=%d | acc=%d err=%d | type='%s' err=%d | name='%s' err=%d\n",
               tag, i, (int)aq, e1, (int)ac, e2, typeName, e3, argName, e4);
    }
}

int main(void) {
    // ---- 1. device -------------------------------------------------------
    cl_device_id device = NULL;
    char deviceName[256] = {0};
    if (ocl_pick_device(OCL_DEFAULT_DEVICE, CL_DEVICE_TYPE_ALL, &device, deviceName, sizeof(deviceName)) != 0) {
        printf("[FAIL] no device matching \"%s\"\n", OCL_DEFAULT_DEVICE);
        return ocl_report(0);
    }
    ocl_report_device(device);

    // ---- 2. IL support, queried three ways -------------------------------
    // The first is the bug. CL_DEVICE_IL_VERSION is documented as a string; asking
    // for one byte of it is asking for less than the driver needs to write, so the
    // query fails and supportsIL keeps its initial value. Code that tests
    // "if (supportsIL)" then branches on a variable the driver never wrote.
    cl_bool supportsIL = 0;
    cl_int eBool = clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(supportsIL), &supportsIL, NULL);
    printf("[il] wrong way  : cl_bool, sizeof=%zu -> err=%d %s, supportsIL=%d\n",
           sizeof(supportsIL), eBool, ocl_err_name(eBool), (int)supportsIL);

    // The second is the size-only query. Note that on a device WITHOUT IL support
    // this returns 1, not 0: the empty string still has its terminator. So
    // "if (size == 0)" is not the emptiness test either, it is off by one in the
    // direction that makes an unsupported device look supported.
    size_t ilSize = 0;
    cl_int eSize = clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, 0, NULL, &ilSize);
    printf("[il] size query  : err=%d %s, size=%zu\n", eSize, ocl_err_name(eSize), ilSize);

    // The third is the one that works.
    char ilVersion[512] = {0};
    size_t ilGot = 0;
    cl_int eStr = clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(ilVersion), ilVersion, &ilGot);
    printf("[il] string query: err=%d %s, value='%s' (got %zu bytes)\n",
           eStr, ocl_err_name(eStr), ilVersion, ilGot);

    int ilSupported = (eStr == CL_SUCCESS && ilGot > 1 && ilVersion[0] != '\0');
    if (!ilSupported) {
        printf("[skip] %s reports no IL support (CL_DEVICE_IL_VERSION is empty)\n", deviceName);
        printf("       This example needs a device that accepts SPIR-V. On this machine the\n");
        printf("       Intel iGPU advertises SPIR-V_1.2 and the Intel CPU advertises up to 1.4.\n");
        return ocl_report_skip("target device has no CL_DEVICE_IL_VERSION");
    }

    // ---- 3. load the offline-compiled module -----------------------------
    // build.ps1 runs the example from its own directory, so this relative path is
    // the same one the docs tell the reader to expect.
    const char* spvPath = "spv/vector_add.spv";
    size_t ilLen = 0;
    unsigned char* il = read_binary(spvPath, &ilLen);
    if (!il) {
        printf("[skip] %s not found\n", spvPath);
        printf("       Produce it with:  cd OpenCL ; ./build-spirv.ps1\n");
        printf("       That needs a SPIR-V compiler (Intel oneAPI ships clang for this).\n");
        return ocl_report_skip("no SPIR-V module; run build-spirv.ps1 first");
    }

    // Decode the five-word header rather than trusting the build script's report.
    // Word 1 is major<<16 | minor<<8; word 2 is toolVersion<<16 | toolId.
    unsigned magic = 0, verWord = 0, genWord = 0, bound = 0;
    if (ilLen < 20) {
        printf("[FAIL] %s is only %zu bytes, too short for a SPIR-V header\n", spvPath, ilLen);
        free(il);
        return ocl_report(0);
    }
    memcpy(&magic, il + 0, 4); memcpy(&verWord, il + 4, 4);
    memcpy(&genWord, il + 8, 4); memcpy(&bound, il + 12, 4);
    printf("[module] %s : %zu bytes\n", spvPath, ilLen);
    printf("[module] magic=0x%08X (%s)  SPIR-V %u.%u  generator tool %u  bound %u\n",
           magic, magic == 0x07230203u ? "ok" : "BAD",
           (verWord >> 16) & 0xFFFF, (verWord >> 8) & 0xFF,
           genWord & 0xFFFF, bound);
    int headerOk = (magic == 0x07230203u);

    // The device advertises SPIR-V_1.2 and the module says 1.4. That mismatch is
    // printed rather than hidden, because step 6 is what settles whether it matters.
    unsigned modMajor = (verWord >> 16) & 0xFFFF, modMinor = (verWord >> 8) & 0xFF;
    printf("[module] device advertises '%s', module is %u.%u\n", ilVersion, modMajor, modMinor);

    // ---- 4. context and queue -------------------------------------------
    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context || err != CL_SUCCESS) {
        printf("[FAIL] clCreateContext -> %d %s\n", err, ocl_err_name(err));
        free(il);
        return ocl_report(0);
    }
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, NULL, &err);
    if (!queue || err != CL_SUCCESS) {
        printf("[FAIL] clCreateCommandQueueWithProperties -> %d %s\n", err, ocl_err_name(err));
        clReleaseContext(context); free(il);
        return ocl_report(0);
    }

    // ---- 5. clCreateProgramWithIL ---------------------------------------
    // One length, not an array. clCreateProgramWithSource takes a count plus an
    // array of strings plus an array of lengths; clCreateProgramWithIL takes a
    // single contiguous blob and a single size_t. Sample code frequently declares
    // a "size_t lengths[1]" here out of habit and then never uses it.
    cl_program program = clCreateProgramWithIL(context, il, ilLen, &err);
    printf("[il] clCreateProgramWithIL -> %d %s\n", err, ocl_err_name(err));
    if (!program || err != CL_SUCCESS) {
        clReleaseCommandQueue(queue); clReleaseContext(context); free(il);
        return ocl_report(0);
    }

    // ---- 6. build -------------------------------------------------------
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        if (logSz > 1) {
            char* log = (char*)malloc(logSz + 1);
            if (log) {
                clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
                log[logSz] = '\0';
                printf("[build log] (%zu bytes)\n%s\n", logSz, log);
                free(log);
            }
        } else {
            printf("[build log] empty (%zu bytes) - the driver had nothing to say\n", logSz);
        }
    }
    printf("[il] clBuildProgram -> %d %s\n", err, ocl_err_name(err));
    int built = (err == CL_SUCCESS);
    if (!built) {
        printf("[FAIL] the module did not build; see the log above\n");
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context); free(il);
        return ocl_report(0);
    }

    cl_kernel kernel = clCreateKernel(program, "vector_add", &err);
    printf("[il] clCreateKernel(\"vector_add\") -> %d %s\n", err, ocl_err_name(err));
    if (!kernel || err != CL_SUCCESS) {
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context); free(il);
        return ocl_report(0);
    }

    // CL_KERNEL_NUM_ARGS is reported, not assumed. For this module it is 4, matching
    // the source. tools/spirv-route-probe exists because a DIFFERENT offline route
    // produces a module the same driver reads as 8, and an application that trusted
    // this query would then bind four arguments it does not have.
    cl_uint numArgs = 0;
    clGetKernelInfo(kernel, CL_KERNEL_NUM_ARGS, sizeof(numArgs), &numArgs, NULL);
    printf("[il] CL_KERNEL_NUM_ARGS -> %u (the source declares 4)\n", numArgs);
    int arityOk = (numArgs == 4);

    // ---- 7. run and verify ----------------------------------------------
    float* a = (float*)malloc(N * sizeof(float));
    float* b = (float*)malloc(N * sizeof(float));
    float* c = (float*)malloc(N * sizeof(float));
    for (int i = 0; i < N; i++) { a[i] = (float)i; b[i] = (float)(i * 2); c[i] = -1.0f; }

    cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufB = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
    if (!bufA || !bufB || !bufC) {
        printf("[FAIL] clCreateBuffer -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }
    clEnqueueWriteBuffer(queue, bufA, CL_TRUE, 0, N * sizeof(float), a, 0, NULL, NULL);
    clEnqueueWriteBuffer(queue, bufB, CL_TRUE, 0, N * sizeof(float), b, 0, NULL, NULL);

    int n = N;
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufB);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufC);
    clSetKernelArg(kernel, 3, sizeof(int), &n);

    // Local size 64 is under this device's 256 limit. The global size is already a
    // multiple of it, and the kernel bounds-checks anyway - both halves of the rule
    // ocl_round_up documents.
    size_t localSize = 64, globalSize = N;
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, NULL);
    printf("[launch] global=%zu local=%zu -> %d %s\n", globalSize, localSize, err, ocl_err_name(err));
    int launched = (err == CL_SUCCESS);

    int bad = N;
    if (launched) {
        clFinish(queue);
        clEnqueueReadBuffer(queue, bufC, CL_TRUE, 0, N * sizeof(float), c, 0, NULL, NULL);
        bad = 0;
        for (int i = 0; i < N; i++) {
            float ref = (float)i + (float)(i * 2);
            if (c[i] != ref) {
                if (bad < 5) printf("  mismatch i=%d got %f want %f\n", i, c[i], ref);
                bad++;
            }
        }
        printf("[verify] %d/%d elements correct\n", N - bad, N);
    }

    // ---- 8. do build options mean anything for an IL program? -----------
    // There is no source left to set a language level for - the module recorded
    // OpenCL C 1.2 when it was compiled, offline. So the same four -cl-std values are
    // swept across an IL program and a source program built from the same kernel, and
    // the two columns are compared instead of either one being assumed.
    //
    // This device reports "OpenCL 3.0 NEO" as its API version and "OpenCL C 1.2" as
    // its language version, and those are two different numbers. The expectation
    // written before running the sweep was that CL2.0 would be REJECTED against real
    // source, since the device only implements OpenCL C 1.2. It is accepted, and CL9.9
    // is the value that fails - with a build log that names the comparison actually
    // being made:
    //
    //     -cl-std OpenCLC version greater than OpenCL (API) version
    //
    // NEO checks the option against CL_DEVICE_VERSION (3.0), not against
    // CL_DEVICE_OPENCL_C_VERSION (1.2). CL3.0 is the boundary test that follows from
    // the log's wording, and it passes - "greater than", not "greater than or equal".
    // The IL column answers the question in the heading: all four values are accepted
    // there, CL9.9 included, because with no source to compile the option has nothing
    // to be checked against and nothing to act on.
    //
    // The practical consequence for source programs is the sharp edge worth knowing:
    // on a 3.0-API device whose compiler is 1.2, you can ask for OpenCL C 2.0, get
    // CL_SUCCESS back from clBuildProgram, and only discover the language level was
    // never honoured when a 2.0-only construct fails to compile or quietly does
    // nothing.
    {
        static const char* opts[] = {
            "-cl-std=CL1.2", "-cl-std=CL2.0", "-cl-std=CL3.0", "-cl-std=CL9.9"
        };
        const size_t nOpts = sizeof(opts) / sizeof(opts[0]);

        cl_program p2 = clCreateProgramWithIL(context, il, ilLen, &err);
        if (p2) {
            for (size_t s = 0; s < nOpts; s++) {
                cl_int e = clBuildProgram(p2, 1, &device, opts[s], NULL, NULL);
                printf("[options] IL program,     \"%s\" -> %d %s\n", opts[s], e, ocl_err_name(e));
            }
            clReleaseProgram(p2);
        } else {
            printf("[options] could not create a second IL program -> %d %s\n", err, ocl_err_name(err));
        }

        char* src = ocl_read_file("kernels/vector_add.cl");
        if (src) {
            cl_int e4 = 0;
            cl_program p3 = clCreateProgramWithSource(context, 1, (const char**)&src, NULL, &e4);
            if (p3) {
                for (size_t s = 0; s < nOpts; s++) {
                    cl_int e = clBuildProgram(p3, 1, &device, opts[s], NULL, NULL);
                    printf("[options] source program, \"%s\" -> %d %s\n", opts[s], e, ocl_err_name(e));
                    if (e != CL_SUCCESS) {
                        // -11 says the front-end compiler ran and complained, but not
                        // what it said. Quote the first line so the rejection is
                        // evidence rather than an inference from an error code.
                        size_t logSz = 0;
                        clGetProgramBuildInfo(p3, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
                        if (logSz > 1) {
                            char* log = (char*)malloc(logSz);
                            clGetProgramBuildInfo(p3, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
                            char* nl = strpbrk(log, "\r\n");
                            if (nl) *nl = '\0';
                            printf("[build log] %s\n", log);
                            free(log);
                        }
                    }
                }
                clReleaseProgram(p3);
            } else {
                printf("[options] clCreateProgramWithSource -> %d %s\n", e4, ocl_err_name(e4));
            }
            free(src);
        }
    }

    // ---- 9. can the IL be read back out? --------------------------------
    {
        size_t back = 0;
        cl_int e4 = clGetProgramInfo(program, CL_PROGRAM_IL, 0, NULL, &back);
        printf("[readback] CL_PROGRAM_IL size query -> %d %s, size=%zu\n", e4, ocl_err_name(e4), back);
        if (e4 == CL_SUCCESS && back > 0) {
            unsigned char* buf = (unsigned char*)malloc(back);
            if (buf) {
                cl_int e5 = clGetProgramInfo(program, CL_PROGRAM_IL, back, buf, NULL);
                int same = (e5 == CL_SUCCESS && back == ilLen && memcmp(buf, il, ilLen) == 0);
                printf("[readback] -> %d %s, %zu bytes, identical to the file: %s\n",
                       e5, ocl_err_name(e5), back, same ? "yes" : "no");
                free(buf);
            }
        }
        // CL_PROGRAM_NUM_KERNELS is queried too, and its error is checked, because
        // on this driver it returns CL_INVALID_VALUE for an IL program while
        // CL_PROGRAM_KERNEL_NAMES succeeds. Printing the value without the error
        // code is how that inconsistency gets read as a zero.
        cl_uint nk = 0;
        cl_int e6 = clGetProgramInfo(program, CL_PROGRAM_NUM_KERNELS, sizeof(nk), &nk, NULL);
        printf("[readback] CL_PROGRAM_NUM_KERNELS -> %d %s, value=%u\n", e6, ocl_err_name(e6), nk);
        size_t need = 0;
        cl_int e7 = clGetProgramInfo(program, CL_PROGRAM_KERNEL_NAMES, 0, NULL, &need);
        if (e7 == CL_SUCCESS && need > 0) {
            char* names = (char*)calloc(1, need + 1);
            if (names) {
                clGetProgramInfo(program, CL_PROGRAM_KERNEL_NAMES, need, names, NULL);
                printf("[readback] CL_PROGRAM_KERNEL_NAMES -> '%s'\n", names);
                free(names);
            }
        } else {
            printf("[readback] CL_PROGRAM_KERNEL_NAMES -> %d %s\n", e7, ocl_err_name(e7));
        }
    }

    // ---- 10. is argument reflection usable for an IL program? -----------
    // clGetKernelArgInfo needs metadata a SPIR-V module is not required to carry -
    // argument names in particular are optional debug information, and the modules
    // build-spirv.ps1 emits name the functions but not their parameters.
    //
    // What makes this a measurement rather than a complaint is the contrast: a
    // kernel built from SOURCE out of the very same file, on the same device, in
    // the same run. If reflection answers for that one and returns nonsense for
    // the IL one, the cause is the IL path and not this driver in general.
    //
    // Deliberately carries NO assert. "The values are junk" is a property of this
    // driver and this toolchain, not a contract this example should enforce: a
    // driver that preserved argument metadata would make an assert here fail while
    // behaving strictly better. The numbers are printed with their error codes and
    // docs/08-spirv.md section 8.10.4 reports what they were.
    {
        dump_arg_info("il    ", kernel);

        cl_kernel srcKernel = NULL;
        cl_program sp = NULL;
        char* src = ocl_read_file("kernels/vector_add.cl");
        if (src) {
            cl_int e = 0;
            sp = clCreateProgramWithSource(context, 1, (const char**)&src, NULL, &e);
            if (sp && clBuildProgram(sp, 1, &device, NULL, NULL, NULL) == CL_SUCCESS) {
                srcKernel = clCreateKernel(sp, "vector_add", &e);
            }
            free(src);
        }
        dump_arg_info("source", srcKernel);

        if (srcKernel) clReleaseKernel(srcKernel);
        if (sp) clReleaseProgram(sp);
    }

    // ---- 11. what a device WITHOUT IL support does ----------------------
    // The negative control. This must be an error code, not a crash: an application
    // that enumerates devices has to be able to ask and be told "no".
    {
        cl_device_id noIL = NULL;
        char noILName[256] = {0};
        if (ocl_find_device_without_il(&noIL, noILName, sizeof(noILName)) == 0) {
            // The size-only query, on the one device where its answer matters. Sample
            // code detects "no IL support" with "if (ilVersionSize == 0)". An empty
            // string is still a string, and still reports room for its terminator, so
            // this is expected to come back non-zero and let an unsupported device
            // through. Measured, not assumed - the verdict is printed.
            size_t noILSize = 0;
            cl_int eSz = clGetDeviceInfo(noIL, CL_DEVICE_IL_VERSION, 0, NULL, &noILSize);
            printf("[no-il] %s : CL_DEVICE_IL_VERSION size query -> %d %s, size=%zu\n",
                   noILName, eSz, ocl_err_name(eSz), noILSize);
            printf("[no-il] \"if (size == 0)\" would %s this device\n",
                   noILSize == 0 ? "correctly reject" : "WRONGLY ACCEPT");

            cl_int e8 = 0;
            cl_context c2 = clCreateContext(NULL, 1, &noIL, NULL, NULL, &e8);
            if (c2) {
                cl_int e9 = 0;
                cl_program p3 = clCreateProgramWithIL(c2, il, ilLen, &e9);
                printf("[no-il] %s : clCreateProgramWithIL -> %d %s\n", noILName, e9, ocl_err_name(e9));
                printf("[no-il] a clean error code is the correct behaviour; a crash would not be\n");
                if (p3) clReleaseProgram(p3);
                clReleaseContext(c2);
            } else {
                printf("[no-il] %s : could not create a context -> %d %s\n", noILName, e8, ocl_err_name(e8));
            }
        } else {
            printf("[no-il] every device on this machine supports IL; no negative control available\n");
        }
    }

    // ---- 12. release ----------------------------------------------------
    clReleaseMemObject(bufA); clReleaseMemObject(bufB); clReleaseMemObject(bufC);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);
    free(a); free(b); free(c);
    free(il);

    int pass = headerOk && built && launched && (bad == 0) && arityOk;
    printf("\nassert SPIR-V magic 0x07230203          : %s\n", headerOk ? "OK" : "FAILED");
    printf("assert module built and launched        : %s\n", (built && launched) ? "OK" : "FAILED");
    printf("assert CL_KERNEL_NUM_ARGS == 4          : %s\n", arityOk ? "OK" : "FAILED");
    printf("assert all %d elements match CPU ref    : %s\n", N, bad == 0 ? "OK" : "FAILED");
    return ocl_report(pass);
}
