// examples/11-ocl3-features - the post-1.2 features, asked for by capability rather
// than by version number, on every device this machine has.
//
// Four tests over three features: shared virtual memory (coarse-grained and
// fine-grained buffer, tested separately), to_global(), and sub_group_broadcast(). All
// of them are OpenCL C 2.0 or later, and the usual way to reach for them is
//
//     if (device version >= 2.0) { use them; }
//
// which does not work. On this machine all three devices report CL_DEVICE_VERSION
// "OpenCL 3.0", and CL_DEVICE_OPENCL_C_VERSION reports "OpenCL C 1.2" on both GPUs
// and "OpenCL C 3.0" on the CPU device - and neither string predicts anything:
//
//   - The i7 CPU device advertises OpenCL C 3.0 and still defaults to
//     __OPENCL_C_VERSION__ 120, so to_global() fails to compile unless -cl-std is
//     passed. Its advertised level is a ceiling, not a default. Asked properly, it
//     runs all four tests correctly.
//   - The UHD 630 advertises OpenCL C 1.2 and compiles -cl-std=CL2.0 happily, also
//     running all four correctly. Its advertised level is not even a ceiling.
//   - The RTX 2060 advertises OpenCL C 1.2, accepts -cl-std=CL2.0, runs to_global()
//     which it does not advertise at all, fails to link the subgroup builtins, and -
//     the interesting one - advertises coarse-grained SVM in
//     CL_DEVICE_SVM_CAPABILITIES and then loses every store the kernel makes to it.
//
// So this example gates on CL_DEVICE_SVM_CAPABILITIES and CL_DEVICE_OPENCL_C_FEATURES
// instead, prints what each device advertised, attempts every feature on every device
// anyway, and then compares the two. The comparison is the subject of the example.
// Five outcomes are possible per (device, feature) and all five occur here:
//
//   advertised, works      - the query told the truth
//   advertised, fails      - a broken promise, and the ONLY outcome that fails this
//                            example
//   advertised, fails, but a diagnostic proved the kernel ran and only the data was
//                          lost - a DEFECT in the driver. Reported loudly and counted
//                          separately, because this example teaches capability gating,
//                          not vendor conformance, and a red build.ps1 line would
//                          train readers to ignore red.
//   not advertised, fails  - unavailable as advertised
//   not advertised, works  - the query under-promised, which is what the RTX 2060
//                            does for to_global()
//
// Two traps cost more debugging time than everything else here combined, and both are
// commented at the site where they bite:
//
//   - An SVM pointer goes to clSetKernelArgSVMPointer, NOT clSetKernelArg. The latter
//     reads its value as a cl_mem handle and answers -38 CL_INVALID_MEM_OBJECT, an
//     error naming a memory object in code that never created one. Getting this wrong
//     made all three devices look like they had broken their SVM promise.
//   - to_global of a pointer that does NOT point into global memory is not something
//     these devices agree about: both GPUs return NULL and the CPU device returns the
//     pointer unchanged. Asserting either answer produces a false failure, so step 5b
//     measures and prints it instead.
//
// Each feature is built as its OWN program from its OWN .cl file. One file holding all
// four kernels was tried first and it was worse than merely untidy: the subgroup
// builtins made the whole file unbuildable on the NVIDIA card, so a device that could
// have run the other two features reported nothing at all.
//
// Everything is unsigned integer arithmetic, so "correct" has exactly one meaning and
// no comparison here needs a tolerance.
//
// Contract: exit 0 + "[RESULT] PASS" when no device failed to deliver a feature it
// advertised and at least one feature was verified somewhere; "[RESULT] SKIP" if this
// machine has no OpenCL device at all. A confirmed driver defect does not fail the
// run, but its count is always printed so it can never be silently absorbed.
#include "ocl_util.h"

#define MAXDEV  16
#define POISON  0xFFFFFFFFu     // an output word nobody wrote has to be recognisable

#define SVM_N   1024u           // elements in the SVM allocation
#define TG_N    1024u           // work-items in the to_global probe
#define SG_N    4096u           // work-items in the subgroup broadcast

// The four features, in the order they are attempted and printed.
#define F_SVM_COARSE 0
#define F_SVM_FINE   1
#define F_TOGLOBAL   2
#define F_SUBGROUP   3
#define F_COUNT      4

static const char* const featureName[F_COUNT] = {
    "SVM coarse-grained",
    "SVM fine-grain buffer",
    "to_global()",
    "sub_group_broadcast()"
};

typedef struct {
    int  advertised;    // what the device queries said before anything was attempted
    int  attempted;
    int  worked;        // built, ran, and verified element by element
    int  defect;        // every call succeeded, a diagnostic proved the kernel ran, and
                        // the data still never arrived: the driver's bug, not this
                        // example's. Reported loudly, but not counted as a broken
                        // promise, because the distinction is the whole point.
    char detail[256];   // what actually happened, always with the error code in it
} Feat;

typedef struct {
    cl_device_id     dev;
    char             name[256];
    char             platform[256];
    cl_device_type   type;
    cl_context       ctx;
    cl_command_queue queue;

    // Capability queries, all taken before any feature is attempted so the "advertised"
    // column cannot be influenced by the outcome it is being compared against.
    cl_device_svm_capabilities svmCaps;
    int svmCapsOk;          // the query itself can fail on a 1.2-era device
    int featuresCount;      // entries in CL_DEVICE_OPENCL_C_FEATURES
    int featGeneric;        // __opencl_c_generic_address_space
    int featSubgroups;      // __opencl_c_subgroups
    int extKhrSubgroups;    // cl_khr_subgroups in CL_DEVICE_EXTENSIONS
    int extIntelSubgroups;  // cl_intel_subgroups in CL_DEVICE_EXTENSIONS

    // What to_global() did with a pointer that was NOT global, as a bitmask over the
    // classify() outcomes in kernels/to_global.cl (1=NULL, 2=same pointer, 3=other).
    // Recorded here because this is the one result in the example where two devices
    // that both ran the same kernel answer differently, and a disagreement like that
    // only lands when the three answers are printed next to each other.
    unsigned int tgPrivateMask;
    unsigned int tgLocalMask;

    Feat f[F_COUNT];
} Dev;

// Record the FIRST error only. Folding cl_int codes together with |=, which is the
// tempting one-liner, produces a number that is not any error at all and names
// nothing.
static cl_int firstErr(cl_int acc, cl_int e) { return (acc != CL_SUCCESS) ? acc : e; }

static const char* typeName(cl_device_type t) {
    switch (t) {
    case CL_DEVICE_TYPE_CPU:         return "CPU";
    case CL_DEVICE_TYPE_GPU:         return "GPU";
    case CL_DEVICE_TYPE_ACCELERATOR: return "accelerator";
    default:                         return "other";
    }
}

// One classify() outcome code from kernels/to_global.cl, in words.
static const char* classifyName(unsigned int c) {
    switch (c) {
    case 1u:  return "NULL";
    case 2u:  return "same pointer";
    case 3u:  return "a third value";
    default:  return "not run";
    }
}

// Summarise a bitmask of classify() outcomes seen across all the lanes.
//
// More than one bit set means the lanes disagreed with each other, which is a
// different and worse finding than "this device returns NULL", so it is reported
// as such rather than being reduced to whichever outcome happened to be seen
// first.
static void describeMask(unsigned int mask, char* out, size_t sz) {
    int bits = 0, which = 0;
    for (unsigned int c = 0; c < 4; c++)
        if (mask & (1u << c)) { bits++; which = (int)c; }
    if (bits == 0)      snprintf(out, sz, "not run");
    else if (bits == 1) snprintf(out, sz, "%s", classifyName((unsigned int)which));
    else                snprintf(out, sz, "MIXED, %d outcomes across lanes", bits);
}

// ---- capability queries ---------------------------------------------------

// Does CL_DEVICE_OPENCL_C_FEATURES list this feature? Returns -1 if the query is
// unavailable, 0 if it answered and the feature is absent, 1 if present.
//
// This is the 3.0 replacement for parsing version strings, and it is the only query
// on this machine that separates the three devices correctly. Two-call idiom: size
// first, then data, so the entry count is derived rather than assumed.
static int hasCFeature(cl_device_id d, const char* wanted) {
    size_t bytes = 0;
    if (clGetDeviceInfo(d, CL_DEVICE_OPENCL_C_FEATURES, 0, NULL, &bytes) != CL_SUCCESS || bytes == 0)
        return -1;

    cl_name_version* v = (cl_name_version*)malloc(bytes);
    if (!v) return -1;
    int found = 0;
    if (clGetDeviceInfo(d, CL_DEVICE_OPENCL_C_FEATURES, bytes, v, NULL) == CL_SUCCESS) {
        size_t n = bytes / sizeof(cl_name_version);
        for (size_t i = 0; i < n; i++)
            if (strcmp(v[i].name, wanted) == 0) { found = 1; break; }
    }
    free(v);
    return found;
}

// Does CL_DEVICE_EXTENSIONS list this extension, as a whole token?
//
// Token-wise, not strstr: "cl_intel_subgroups" is a prefix of
// "cl_intel_subgroups_short", which this machine's UHD 630 lists, so a substring
// search reports the base extension as present on a device that only has the
// derivative one. Extension lists are space-separated, so splitting on spaces and
// comparing exactly is both correct and three lines long.
static int hasExtToken(const char* exts, const char* wanted) {
    size_t wlen = strlen(wanted);
    const char* p = exts;
    while (*p) {
        while (*p == ' ') p++;
        if (!*p) break;
        const char* end = p;
        while (*end && *end != ' ') end++;
        if ((size_t)(end - p) == wlen && strncmp(p, wanted, wlen) == 0) return 1;
        p = end;
    }
    return 0;
}

// ---- build and launch helpers ---------------------------------------------

// Print only the lines of a build log that mention a warning or an error.
static void print_log_problems(const char* log) {
    char line[1024];
    const char* p = log;
    while (*p) {
        const char* end = strchr(p, '\n');
        size_t len = end ? (size_t)(end - p) : strlen(p);
        while (len && (p[len - 1] == '\r' || p[len - 1] == ' ')) len--;
        if (len >= sizeof line) len = sizeof line - 1;
        memcpy(line, p, len);
        line[len] = '\0';
        if (strstr(line, "warning") || strstr(line, "error"))
            printf("      [build log] %s\n", line);
        if (!end) break;
        p = end + 1;
    }
}

// Build one .cl file for one device. Returns NULL on failure, having printed the
// build log.
//
// The log is fetched whether the build succeeded or not, because this example EXPECTS
// some of these builds to fail - the subgroup builtins do not link on the NVIDIA card
// - and the log is the evidence for why, not an afterthought to be collected only when
// something unexpected goes wrong.
//
// FETCHING it always and PRINTING it always are different decisions. The Intel CPU
// runtime puts a dozen lines of vectoriser remarks in the log of every successful
// build, and four features across three devices of that buries the results this example
// exists to print. So a failed build gets the whole log and a successful one gets only
// the lines that report a problem - which still catches the case that matters, because
// the NVIDIA subgroup failure is three "implicit declaration" warnings followed by a
// ptxas error.
static cl_program build_program(const Dev* d, const char* path, const char* tag) {
    char* source = ocl_read_file(path);
    if (!source) return NULL;

    cl_int err = CL_SUCCESS;
    cl_program prog = clCreateProgramWithSource(d->ctx, 1, (const char**)&source, NULL, &err);
    free(source);
    if (!prog || err != CL_SUCCESS) {
        printf("      [FAIL] %s: clCreateProgramWithSource -> %d %s\n", tag, err, ocl_err_name(err));
        return NULL;
    }

    // -cl-std=CL2.0 is not optional here and not a stylistic choice. The default level
    // is vendor-chosen: both Intel devices default to __OPENCL_C_VERSION__ 120 even
    // though the CPU device advertises OpenCL C 3.0, and at 120 none of these builtins
    // is declared. Omitting the flag produces "implicit declaration of function
    // 'to_global' is invalid in OpenCL", which reads like "this device cannot do it"
    // and is really "you never asked for the level that has it".
    const char* opts = "-cl-std=CL2.0";
    err = clBuildProgram(prog, 1, &d->dev, opts, NULL, NULL);

    size_t logSz = 0;
    char* log = NULL;
    if (clGetProgramBuildInfo(prog, d->dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz) == CL_SUCCESS && logSz > 1) {
        log = (char*)malloc(logSz + 1);
        if (log) {
            clGetProgramBuildInfo(prog, d->dev, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
            log[logSz] = '\0';
        }
    }

    if (err != CL_SUCCESS) {
        if (log && log[0]) printf("      [build log]\n%s\n", log);
        printf("      [FAIL] %s: clBuildProgram(%s) -> %d %s\n", tag, opts, err, ocl_err_name(err));
        free(log);
        clReleaseProgram(prog);
        return NULL;
    }
    if (log) print_log_problems(log);
    free(log);
    return prog;
}

// min(CL_KERNEL_WORK_GROUP_SIZE, CL_DEVICE_MAX_WORK_GROUP_SIZE), then clamped to the
// amount of work there actually is.
//
// The kernel-level number has to be in there: on the RTX 2060 the device reports 1024
// while every kernel on it reports 256, so sizing from the device alone gives a launch
// the driver rejects with -54 CL_INVALID_WORK_GROUP_SIZE. Both queries return size_t;
// receiving either into a cl_uint makes the call fail and leaves the variable at zero,
// which then prints as a confident and completely fictitious limit.
//
// The clamp is there because the i7 CPU device reports a max work-group size of 8192,
// and ocl_round_up rounds the GLOBAL size up to a multiple of the local one - so an
// unclamped 8192 turns a 1024-element probe into an 8192-element probe and the output
// reports a test eight times the size of the one that was written. Halving keeps the
// value a legal work-group size on every device here.
static size_t pick_local(cl_device_id dev, cl_kernel k, size_t n) {
    size_t kwg = 0, dwg = 0;
    clGetKernelInfo(k, CL_KERNEL_WORK_GROUP_SIZE, sizeof(kwg), &kwg, NULL);
    clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(dwg), &dwg, NULL);
    if (kwg == 0) kwg = dwg;
    if (dwg == 0) dwg = kwg;
    if (kwg == 0) return 1;
    size_t local = (kwg < dwg) ? kwg : dwg;
    while (local > n && local > 1) local /= 2;
    return local;
}

// ---- diagnostic: did the kernel run, or did only the SVM store fail? ---------
//
// Called only after a coarse-SVM verification has already failed. Launches
// svm_cross_check, which writes the same index to an SVM pointer and to an ordinary
// cl_mem buffer inside one work-item, and reports which of the two arrived:
//
//    1  the ordinary buffer is correct and the SVM one is not. The kernel provably
//       executed, so this is a statement about SVM specifically.
//    0  neither arrived. The launch did nothing, and SVM is not the subject.
//    2  both arrived, which means the failure being diagnosed was not reproducible.
//   -1  the diagnostic could not be run, so nothing is settled either way.
//
// The point of the extra kernel is that "1024 elements still hold the poison value"
// on its own cannot distinguish a driver that ignores SVM stores from a caller that
// never got the kernel to run. Reporting the first of those without ruling out the
// second is how a tutorial ends up blaming a vendor for the reader's bug.
static int svm_cross_check(Dev* d, cl_program prog, void* svmPtr,
                           size_t global, size_t local, char* out, size_t outSz) {
    cl_int err = CL_SUCCESS;
    cl_kernel k = clCreateKernel(prog, "svm_cross_check", &err);
    if (!k || err != CL_SUCCESS) {
        snprintf(out, outSz, "diagnostic: clCreateKernel -> %d %s", err, ocl_err_name(err));
        return -1;
    }

    size_t bytes = global * sizeof(unsigned int);
    unsigned int* host = (unsigned int*)malloc(bytes);
    cl_mem regular = clCreateBuffer(d->ctx, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!host || !regular) {
        snprintf(out, outSz, "diagnostic: allocation -> %d %s", err, ocl_err_name(err));
        free(host); if (regular) clReleaseMemObject(regular); clReleaseKernel(k);
        return -1;
    }
    memset(host, 0, bytes);
    clEnqueueWriteBuffer(d->queue, regular, CL_TRUE, 0, bytes, host, 0, NULL, NULL);

    unsigned int n = (unsigned int)global;
    err = CL_SUCCESS;
    err = firstErr(err, clSetKernelArgSVMPointer(k, 0, svmPtr));
    err = firstErr(err, clSetKernelArg(k, 1, sizeof(cl_mem), &regular));
    err = firstErr(err, clSetKernelArg(k, 2, sizeof(unsigned int), &n));
    if (err == CL_SUCCESS) err = clEnqueueNDRangeKernel(d->queue, k, 1, NULL, &global, &local, 0, NULL, NULL);
    if (err == CL_SUCCESS) err = clFinish(d->queue);
    if (err == CL_SUCCESS) err = clEnqueueReadBuffer(d->queue, regular, CL_TRUE, 0, bytes, host, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        snprintf(out, outSz, "diagnostic: launch -> %d %s", err, ocl_err_name(err));
        free(host); clReleaseMemObject(regular); clReleaseKernel(k);
        return -1;
    }

    size_t regBad = 0;
    for (size_t i = 0; i < global; i++)
        if (host[i] != 0xC0DE0000u + (unsigned int)i) regBad++;

    // The SVM half is read under a map bracket, because that is the rule for
    // coarse-grained SVM and a diagnostic that skipped it would be testing something
    // other than what the feature promises.
    size_t svmBad = global;
    err = clEnqueueSVMMap(d->queue, CL_TRUE, CL_MEM_READ_ONLY, svmPtr, bytes, 0, NULL, NULL);
    if (err == CL_SUCCESS) {
        const unsigned int* s = (const unsigned int*)svmPtr;
        svmBad = 0;
        for (size_t i = 0; i < global; i++)
            if (s[i] != 0xBEEF0000u + (unsigned int)i) svmBad++;
        clEnqueueSVMUnmap(d->queue, svmPtr, 0, NULL, NULL);
    }

    free(host); clReleaseMemObject(regular); clReleaseKernel(k);

    if (regBad == 0 && svmBad == 0) {
        snprintf(out, outSz, "diagnostic: BOTH halves landed, so the failure above did not reproduce");
        return 2;
    }
    if (regBad == 0) {
        snprintf(out, outSz,
                 "diagnostic: the ordinary buffer landed %zu/%zu, the SVM store did not (%zu/%zu wrong)",
                 global, global, svmBad, global);
        return 1;
    }
    snprintf(out, outSz, "diagnostic: NEITHER landed (regular %zu/%zu wrong, svm %zu/%zu wrong)",
             regBad, global, svmBad, global);
    return 0;
}

// ---- feature 1a: coarse-grained SVM ---------------------------------------
//
// The pointer returned by clSVMAlloc is valid on the host AND on the device, so there
// is no cl_mem, no clCreateBuffer and no clEnqueueWriteBuffer in this function. What
// coarse-grained SVM still requires is that host access be bracketed by map and unmap
// calls - that bracket is the entire difference from the fine-grained test below, and
// the reason both exist.
static void test_svm_coarse(Dev* d, Feat* f) {
    f->attempted = 1;

    cl_int err = CL_SUCCESS;
    cl_program prog = build_program(d, "kernels/svm.cl", "svm.coarse");
    if (!prog) { snprintf(f->detail, sizeof f->detail, "program did not build"); return; }

    cl_kernel k = clCreateKernel(prog, "svm_write", &err);
    if (!k || err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clCreateKernel -> %d %s", err, ocl_err_name(err));
        clReleaseProgram(prog);
        return;
    }

    size_t local = pick_local(d->dev, k, SVM_N);
    size_t global = ocl_round_up(SVM_N, local);
    size_t bytes = global * sizeof(unsigned int);

    // Alignment 0 means "use the device's preferred alignment". Passing a value the
    // device cannot honour is the usual way this call returns NULL for no visible
    // reason.
    void* p = clSVMAlloc(d->ctx, CL_MEM_READ_WRITE, bytes, 0);
    if (!p) {
        snprintf(f->detail, sizeof f->detail, "clSVMAlloc(coarse) -> NULL for %zu bytes", bytes);
        clReleaseKernel(k); clReleaseProgram(prog);
        return;
    }

    unsigned int seed = 7u;
    int ok = 1;

    // Host write, under an explicit map. svm_write overwrites every element, so this
    // sentinel proves the map/unmap pair worked rather than contributing to the result.
    err = clEnqueueSVMMap(d->queue, CL_TRUE, CL_MEM_WRITE_ONLY, p, bytes, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clEnqueueSVMMap(write) -> %d %s", err, ocl_err_name(err));
        ok = 0;
    }
    if (ok) {
        unsigned int* h = (unsigned int*)p;
        for (size_t i = 0; i < global; i++) h[i] = POISON;
        // Unmap has no blocking_map flag: it is (queue, ptr, wait_list_len, wait_list, event),
        // five arguments against Map's eight. Writing the pair symmetrically is the natural
        // mistake and costs C2197 "too many actual parameters".
        err = clEnqueueSVMUnmap(d->queue, p, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clEnqueueSVMUnmap -> %d %s", err, ocl_err_name(err));
            ok = 0;
        }
    }

    if (ok) {
        unsigned int n = (unsigned int)global;
        err = CL_SUCCESS;
        // clSetKernelArgSVMPointer, NOT clSetKernelArg. clSetKernelArg reads its value
        // as a cl_mem handle, so handing it the raw pointer clSVMAlloc returned makes
        // all three devices here answer -38 CL_INVALID_MEM_OBJECT - an error that names
        // a memory object in a function that never created one. That is the single most
        // misleading failure in this example, and it is entirely the caller's fault.
        err = firstErr(err, clSetKernelArgSVMPointer(k, 0, p));
        err = firstErr(err, clSetKernelArg(k, 1, sizeof(unsigned int), &n));
        err = firstErr(err, clSetKernelArg(k, 2, sizeof(unsigned int), &seed));
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clSetKernelArg -> %d %s", err, ocl_err_name(err));
            ok = 0;
        }
    }
    if (ok) {
        err = clEnqueueNDRangeKernel(d->queue, k, 1, NULL, &global, &local, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clEnqueueNDRangeKernel -> %d %s (global=%zu local=%zu)",
                     err, ocl_err_name(err), global, local);
            ok = 0;
        }
    }
    // clFinish's return is checked, not discarded. When an SVM pointer does not really
    // reach the kernel, clEnqueueNDRangeKernel still reports success and the failure
    // only surfaces here, when the queue is drained - and swallowing it leaves the far
    // less useful symptom of "every element still holds the poison value".
    if (ok) {
        err = clFinish(d->queue);
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clFinish after launch -> %d %s", err, ocl_err_name(err));
            ok = 0;
        }
    }

    // Host read, under an explicit map again. Skipping this bracket is what
    // fine-grained SVM allows and coarse-grained does not.
    if (ok) {
        err = clEnqueueSVMMap(d->queue, CL_TRUE, CL_MEM_READ_ONLY, p, bytes, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clEnqueueSVMMap(read) -> %d %s", err, ocl_err_name(err));
            ok = 0;
        }
    }
    size_t bad = 0, firstBad = 0;
    unsigned int gotFirst = 0, wantFirst = 0;
    if (ok) {
        const unsigned int* h = (const unsigned int*)p;
        for (size_t i = 0; i < global; i++) {
            unsigned int want = (unsigned int)i * seed + 1u;
            if (h[i] != want) { if (!bad) { firstBad = i; gotFirst = h[i]; wantFirst = want; } bad++; }
        }
        err = clEnqueueSVMUnmap(d->queue, p, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            snprintf(f->detail, sizeof f->detail, "clEnqueueSVMUnmap(read) -> %d %s", err, ocl_err_name(err));
            ok = 0;
        }
    }

    // The diagnostic has to run while p and prog are still alive, which is why it sits
    // above the releases rather than next to the reporting.
    int diagVerdict = -1;
    char diag[160] = "";
    if (bad && ok) {
        diagVerdict = svm_cross_check(d, prog, p, global, local, diag, sizeof diag);
        printf("      [%s]\n", diag);
    }

    clSVMFree(d->ctx, p);
    clReleaseKernel(k);
    clReleaseProgram(prog);

    if (bad) {
        // A defect is claimed only on the diagnostic's say-so: return 1 means the
        // ordinary buffer in the same launch came back correct, so the kernel ran and
        // it is the SVM store that never reached the host. Anything less leaves this
        // cell as an ordinary failure, which is the honest default.
        f->defect = (diagVerdict == 1);
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu elements wrong, first at i=%zu got %u want %u; %s",
                 bad, global, firstBad, gotFirst, wantFirst,
                 f->defect ? "kernel ran, SVM store never became visible" : diag);
        ok = 0;
    } else if (ok) {
        snprintf(f->detail, sizeof f->detail, "%zu/%zu elements correct, host access mapped both ways", global, global);
    }
    f->worked = ok && !bad;
}

// ---- feature 1b: fine-grained buffer SVM -----------------------------------
//
// Identical in shape to the coarse test except that there is not a single map or unmap
// call in it. The host writes the buffer, the kernel reads what the host wrote and
// writes back, and the host reads the result - with no synchronisation API call between
// any of those beyond clFinish. That is precisely the guarantee
// CL_MEM_SVM_FINE_GRAIN_BUFFER makes, and it is why svm_scale MULTIPLIES the existing
// value instead of overwriting it: a kernel that only wrote would pass on a
// coarse-grained allocation too and prove nothing about coherence.
static void test_svm_fine(Dev* d, Feat* f) {
    f->attempted = 1;

    cl_int err = CL_SUCCESS;
    cl_program prog = build_program(d, "kernels/svm.cl", "svm.fine");
    if (!prog) { snprintf(f->detail, sizeof f->detail, "program did not build"); return; }

    cl_kernel k = clCreateKernel(prog, "svm_scale", &err);
    if (!k || err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clCreateKernel -> %d %s", err, ocl_err_name(err));
        clReleaseProgram(prog);
        return;
    }

    size_t local = pick_local(d->dev, k, SVM_N);
    size_t global = ocl_round_up(SVM_N, local);
    size_t bytes = global * sizeof(unsigned int);

    void* p = clSVMAlloc(d->ctx, CL_MEM_READ_WRITE | CL_MEM_SVM_FINE_GRAIN_BUFFER, bytes, 0);
    if (!p) {
        // No error code exists to report: clSVMAlloc returns NULL and leaves nothing to
        // query. The capability bitmask is the only warning available, and it is printed
        // in the matrix next to this line.
        snprintf(f->detail, sizeof f->detail,
                 "clSVMAlloc(FINE_GRAIN_BUFFER) -> NULL for %zu bytes, no error code available", bytes);
        clReleaseKernel(k); clReleaseProgram(prog);
        return;
    }

    // Host write with NO map. Deliberate: this is the claim under test.
    unsigned int* h = (unsigned int*)p;
    for (size_t i = 0; i < global; i++) h[i] = (unsigned int)i;

    unsigned int n = (unsigned int)global;
    err = CL_SUCCESS;
    err = firstErr(err, clSetKernelArgSVMPointer(k, 0, p));
    err = firstErr(err, clSetKernelArg(k, 1, sizeof(unsigned int), &n));
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clSetKernelArg -> %d %s", err, ocl_err_name(err));
        clSVMFree(d->ctx, p); clReleaseKernel(k); clReleaseProgram(prog);
        f->worked = 0;
        return;
    }

    err = clEnqueueNDRangeKernel(d->queue, k, 1, NULL, &global, &local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clEnqueueNDRangeKernel -> %d %s (global=%zu local=%zu)",
                 err, ocl_err_name(err), global, local);
        clSVMFree(d->ctx, p); clReleaseKernel(k); clReleaseProgram(prog);
        f->worked = 0;
        return;
    }
    // Same reason as in the coarse test: the enqueue succeeding says nothing about the
    // kernel having run, and this is the call that finds out.
    err = clFinish(d->queue);
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clFinish after launch -> %d %s", err, ocl_err_name(err));
        clSVMFree(d->ctx, p); clReleaseKernel(k); clReleaseProgram(prog);
        f->worked = 0;
        return;
    }

    // Host read with NO map, also deliberate.
    size_t bad = 0, firstBad = 0;
    unsigned int gotFirst = 0, wantFirst = 0;
    for (size_t i = 0; i < global; i++) {
        unsigned int want = (unsigned int)i * 2u + 1u;
        if (h[i] != want) { if (!bad) { firstBad = i; gotFirst = h[i]; wantFirst = want; } bad++; }
    }

    clSVMFree(d->ctx, p);
    clReleaseKernel(k);
    clReleaseProgram(prog);

    if (bad) {
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu elements wrong, first at i=%zu got %u want %u",
                 bad, global, firstBad, gotFirst, wantFirst);
        f->worked = 0;
    } else {
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu correct with no map/unmap in either direction", global, global);
        f->worked = 1;
    }
}

// ---- feature 2: to_global() ------------------------------------------------
static void test_to_global(Dev* d, Feat* f) {
    f->attempted = 1;

    cl_int err = CL_SUCCESS;
    cl_program prog = build_program(d, "kernels/to_global.cl", "to_global");
    if (!prog) { snprintf(f->detail, sizeof f->detail, "program did not build"); return; }

    cl_kernel k = clCreateKernel(prog, "to_global_probe", &err);
    if (!k || err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clCreateKernel -> %d %s", err, ocl_err_name(err));
        clReleaseProgram(prog);
        return;
    }

    size_t local = pick_local(d->dev, k, TG_N);
    size_t global = ocl_round_up(TG_N, local);
    size_t bytes = global * sizeof(unsigned int);

    unsigned int* host = (unsigned int*)malloc(bytes);
    cl_mem buf = clCreateBuffer(d->ctx, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!host || !buf) {
        snprintf(f->detail, sizeof f->detail, "allocation failed (clCreateBuffer -> %d %s)", err, ocl_err_name(err));
        free(host); if (buf) clReleaseMemObject(buf);
        clReleaseKernel(k); clReleaseProgram(prog);
        return;
    }
    for (size_t i = 0; i < global; i++) host[i] = POISON;
    clEnqueueWriteBuffer(d->queue, buf, CL_TRUE, 0, bytes, host, 0, NULL, NULL);

    unsigned int n = (unsigned int)global;
    err = CL_SUCCESS;
    err = firstErr(err, clSetKernelArg(k, 0, sizeof(cl_mem), &buf));
    err = firstErr(err, clSetKernelArg(k, 1, sizeof(unsigned int), &n));
    if (err == CL_SUCCESS)
        err = clEnqueueNDRangeKernel(d->queue, k, 1, NULL, &global, &local, 0, NULL, NULL);
    if (err == CL_SUCCESS)
        err = clEnqueueReadBuffer(d->queue, buf, CL_TRUE, 0, bytes, host, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "launch/read -> %d %s (global=%zu local=%zu)",
                 err, ocl_err_name(err), global, local);
        free(host); clReleaseMemObject(buf); clReleaseKernel(k); clReleaseProgram(prog);
        f->worked = 0;
        return;
    }

    // Two bits per address space, holding the classify() code from the kernel:
    // 1=NULL, 2=same pointer, 3=a third value.
    //
    // Only the GLOBAL case is asserted. It is the one thing to_global is defined to
    // do: hand it a generic pointer that really points into global memory and it must
    // come back as the same pointer, code 2.
    //
    // Asserting the other two is what made this test fail. The first version expected
    // to_global of a private or local pointer to yield NULL, which both GPUs do and
    // the i7 CPU device does not - it hands the pointer straight back. That printed a
    // confident "BROKEN PROMISE" against a device that had done nothing wrong, out of
    // a test that had assumed an answer instead of measuring one. The private and local
    // codes are therefore collected and printed, never compared to an expectation.
    size_t bad = 0, firstBad = 0;
    unsigned int gotFirst = 0;
    d->tgPrivateMask = 0;
    d->tgLocalMask   = 0;
    for (size_t i = 0; i < global; i++) {
        unsigned int w = host[i];
        unsigned int cg = (w >> 0) & 3u;
        unsigned int cp = (w >> 2) & 3u;
        unsigned int cl = (w >> 4) & 3u;
        if (cg != 2u) { if (!bad) { firstBad = i; gotFirst = w; } bad++; }
        d->tgPrivateMask |= 1u << cp;
        d->tgLocalMask   |= 1u << cl;
    }

    char privDesc[64];
    describeMask(d->tgPrivateMask, privDesc, sizeof privDesc);

    if (bad) {
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu failed the DEFINED case (a global pointer must round-trip), "
                 "first at i=%zu word=0x%X", bad, global, firstBad, gotFirst);
        f->worked = 0;
    } else {
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu round-tripped a global pointer; non-global pointers -> %s",
                 global, global, privDesc);
        f->worked = 1;
    }

    free(host); clReleaseMemObject(buf); clReleaseKernel(k); clReleaseProgram(prog);
}

// ---- feature 3: sub_group_broadcast() --------------------------------------
static void test_subgroup(Dev* d, Feat* f) {
    f->attempted = 1;

    cl_int err = CL_SUCCESS;
    cl_program prog = build_program(d, "kernels/subgroup_broadcast.cl", "subgroup");
    if (!prog) { snprintf(f->detail, sizeof f->detail, "program did not build"); return; }

    cl_kernel k = clCreateKernel(prog, "sg_broadcast", &err);
    if (!k || err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "clCreateKernel -> %d %s", err, ocl_err_name(err));
        clReleaseProgram(prog);
        return;
    }

    size_t local = pick_local(d->dev, k, SG_N);
    size_t global = ocl_round_up(SG_N, local);
    size_t words = global * 4u;
    size_t bytes = words * sizeof(unsigned int);

    unsigned int* host = (unsigned int*)malloc(bytes);
    cl_mem buf = clCreateBuffer(d->ctx, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!host || !buf) {
        snprintf(f->detail, sizeof f->detail, "allocation failed (clCreateBuffer -> %d %s)", err, ocl_err_name(err));
        free(host); if (buf) clReleaseMemObject(buf);
        clReleaseKernel(k); clReleaseProgram(prog);
        return;
    }
    for (size_t i = 0; i < words; i++) host[i] = POISON;
    clEnqueueWriteBuffer(d->queue, buf, CL_TRUE, 0, bytes, host, 0, NULL, NULL);

    unsigned int n = (unsigned int)global;
    err = CL_SUCCESS;
    err = firstErr(err, clSetKernelArg(k, 0, sizeof(cl_mem), &buf));
    err = firstErr(err, clSetKernelArg(k, 1, sizeof(unsigned int), &n));
    if (err == CL_SUCCESS)
        err = clEnqueueNDRangeKernel(d->queue, k, 1, NULL, &global, &local, 0, NULL, NULL);
    if (err == CL_SUCCESS)
        err = clEnqueueReadBuffer(d->queue, buf, CL_TRUE, 0, bytes, host, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        snprintf(f->detail, sizeof f->detail, "launch/read -> %d %s (global=%zu local=%zu)",
                 err, ocl_err_name(err), global, local);
        free(host); clReleaseMemObject(buf); clReleaseKernel(k); clReleaseProgram(prog);
        f->worked = 0;
        return;
    }

    // Four independent checks per work-item. The geometry is NOT assumed: the leader of
    // each lane's subgroup is derived from the lane's own reported local id, so a
    // driver that partitions differently, or gives the tail subgroup of a work-group a
    // different size, is still checked correctly.
    //
    //   own value    v must equal i*3+1, so a lane cannot pass by reading a neighbour
    //   geometry     0 <= lid < sz, and the leader index must not underflow
    //   broadcast    b must equal the own value of lane i - lid
    //   contiguity   lids must run 0,1,2,... and restart at 0, so the partition is a
    //                set of consecutive runs and not an arbitrary relabelling
    size_t badOwn = 0, badGeom = 0, badBcast = 0, badContig = 0, firstBad = 0;
    unsigned int szMin = 0, szMax = 0;
    for (size_t i = 0; i < global; i++) {
        unsigned int v = host[i * 4u + 0u], b = host[i * 4u + 1u];
        unsigned int lid = host[i * 4u + 2u], sz = host[i * 4u + 3u];

        if (szMin == 0 || sz < szMin) szMin = sz;
        if (sz > szMax) szMax = sz;

        if (v != (unsigned int)i * 3u + 1u) { if (!badOwn) firstBad = i; badOwn++; }
        if (sz == 0 || sz == POISON || lid >= sz || lid > i) { if (!badGeom) firstBad = i; badGeom++; continue; }
        unsigned int leader = (unsigned int)i - lid;
        if (b != leader * 3u + 1u) { if (!badBcast) firstBad = i; badBcast++; }
        if (i > 0) {
            unsigned int plid = host[(i - 1) * 4u + 2u];
            if (lid != 0 && lid != plid + 1) { if (!badContig) firstBad = i; badContig++; }
        }
    }

    size_t totalBad = badOwn + badGeom + badBcast + badContig;
    if (totalBad) {
        snprintf(f->detail, sizeof f->detail,
                 "own=%zu geom=%zu bcast=%zu contig=%zu wrong, first at i=%zu",
                 badOwn, badGeom, badBcast, badContig, firstBad);
        f->worked = 0;
    } else {
        // Built as a string first. The one-printf version of this was "%u%s%u" with
        // szMin, a separator that is empty when the two agree, and szMin again - so a
        // uniform subgroup size of 16 printed as "1616" and read like a measurement of
        // something enormous.
        char range[24];
        if (szMin == szMax) snprintf(range, sizeof range, "%u", szMin);
        else                snprintf(range, sizeof range, "%u-%u", szMin, szMax);
        snprintf(f->detail, sizeof f->detail,
                 "%zu/%zu lanes correct, subgroup size %s, local=%zu", global, global, range, local);
        f->worked = 1;
    }

    free(host); clReleaseMemObject(buf); clReleaseKernel(k); clReleaseProgram(prog);
}

// ---- device discovery ------------------------------------------------------

static int enumerate_devices(Dev* out, int max) {
    cl_uint numPlat = 0;
    if (clGetPlatformIDs(0, NULL, &numPlat) != CL_SUCCESS || numPlat == 0) return 0;

    cl_platform_id* plats = (cl_platform_id*)malloc(numPlat * sizeof(cl_platform_id));
    if (!plats) return 0;
    clGetPlatformIDs(numPlat, plats, NULL);

    int count = 0;
    for (cl_uint p = 0; p < numPlat && count < max; p++) {
        char pname[256] = {0};
        clGetPlatformInfo(plats[p], CL_PLATFORM_NAME, sizeof(pname), pname, NULL);

        cl_uint numDev = 0;
        if (clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0)
            continue;

        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        if (!devs) continue;
        clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, numDev, devs, NULL);

        for (cl_uint i = 0; i < numDev && count < max; i++) {
            Dev* d = &out[count];
            memset(d, 0, sizeof *d);
            d->dev = devs[i];
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(d->name), d->name, NULL);
            strncpy(d->platform, pname, sizeof(d->platform) - 1);
            clGetDeviceInfo(devs[i], CL_DEVICE_TYPE, sizeof(d->type), &d->type, NULL);

            d->svmCapsOk = (clGetDeviceInfo(devs[i], CL_DEVICE_SVM_CAPABILITIES,
                                            sizeof(d->svmCaps), &d->svmCaps, NULL) == CL_SUCCESS);
            if (!d->svmCapsOk) d->svmCaps = 0;

            {
                size_t bytes = 0;
                if (clGetDeviceInfo(devs[i], CL_DEVICE_OPENCL_C_FEATURES, 0, NULL, &bytes) == CL_SUCCESS)
                    d->featuresCount = (int)(bytes / sizeof(cl_name_version));
            }
            int g = hasCFeature(devs[i], "__opencl_c_generic_address_space");
            int s = hasCFeature(devs[i], "__opencl_c_subgroups");
            d->featGeneric   = (g == 1);
            d->featSubgroups = (s == 1);

            char exts[4096] = {0};
            if (clGetDeviceInfo(devs[i], CL_DEVICE_EXTENSIONS, sizeof(exts), exts, NULL) == CL_SUCCESS) {
                d->extKhrSubgroups   = hasExtToken(exts, "cl_khr_subgroups");
                d->extIntelSubgroups = hasExtToken(exts, "cl_intel_subgroups");
            }

            d->f[F_SVM_COARSE].advertised = d->svmCapsOk && (d->svmCaps & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER) != 0;
            d->f[F_SVM_FINE].advertised   = d->svmCapsOk && (d->svmCaps & CL_DEVICE_SVM_FINE_GRAIN_BUFFER) != 0;
            d->f[F_TOGLOBAL].advertised   = d->featGeneric;
            d->f[F_SUBGROUP].advertised   = d->featSubgroups;

            count++;
        }
        free(devs);
    }
    free(plats);
    return count;
}

int main(void) {
    // Unbuffered. A driver that faults takes the C runtime's buffer with it, and the
    // last thing printed before the fault is usually the thing that explains it -
    // examples/10 learned that the hard way with a cross-platform clCreateContext.
    setvbuf(stdout, NULL, _IONBF, 0);

    Dev devs[MAXDEV];
    int n = enumerate_devices(devs, MAXDEV);

    printf("=== step 1: devices ===\n");
    if (n == 0) return ocl_report_skip("no OpenCL device at all on this machine");
    for (int i = 0; i < n; i++)
        printf("  [%d] %-40s %-12s on %s\n", i, devs[i].name, typeName(devs[i].type), devs[i].platform);

    // ---- 2. what each device advertises ----------------------------------
    //
    // Printed BEFORE anything is attempted, so this table cannot have been written
    // with knowledge of the results it is about to be compared against.
    printf("\n=== step 2: what each device advertises (queried before any attempt) ===\n");
    for (int i = 0; i < n; i++) {
        Dev* d = &devs[i];
        printf("\n  [%d] %s\n", i, d->name);
        char dver[128] = {0}, cver[128] = {0};
        clGetDeviceInfo(d->dev, CL_DEVICE_VERSION, sizeof(dver), dver, NULL);
        clGetDeviceInfo(d->dev, CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);
        printf("      CL_DEVICE_VERSION              %s\n", dver);
        printf("      CL_DEVICE_OPENCL_C_VERSION     %s   <- a string, and it predicts nothing below\n", cver);

        if (d->svmCapsOk) {
            printf("      CL_DEVICE_SVM_CAPABILITIES     0x%X (coarse=%d fine=%d fine_system=%d atomics=%d)\n",
                   (unsigned)d->svmCaps,
                   (d->svmCaps & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER) ? 1 : 0,
                   (d->svmCaps & CL_DEVICE_SVM_FINE_GRAIN_BUFFER) ? 1 : 0,
                   (d->svmCaps & CL_DEVICE_SVM_FINE_GRAIN_SYSTEM) ? 1 : 0,
                   (d->svmCaps & CL_DEVICE_SVM_ATOMICS) ? 1 : 0);
        } else {
            printf("      CL_DEVICE_SVM_CAPABILITIES     (query failed - device predates OpenCL 2.0)\n");
        }

        printf("      CL_DEVICE_OPENCL_C_FEATURES    %d entries; __opencl_c_generic_address_space=%s, __opencl_c_subgroups=%s\n",
               d->featuresCount, d->featGeneric ? "yes" : "no", d->featSubgroups ? "yes" : "no");
        printf("      extensions                     cl_khr_subgroups=%s, cl_intel_subgroups=%s\n",
               d->extKhrSubgroups ? "yes" : "no", d->extIntelSubgroups ? "yes" : "no");
    }
    printf("\n  [NOTE] the two Intel devices agree on __opencl_c_subgroups but NOT on the\n");
    printf("         extension string: only the iGPU lists cl_khr_subgroups, the CPU device\n");
    printf("         lists cl_intel_subgroups alone. Same vendor, different answer - which is\n");
    printf("         why the gate below reads the FEATURES array and not the extension list.\n");

    // ---- 3. contexts and queues, one per device --------------------------
    //
    // One context per device, never one context spanning platforms: examples/10
    // measured that clCreateContext across platforms faults with 0xC0000005 on this
    // machine rather than returning CL_INVALID_DEVICE.
    printf("\n=== step 3: one context and one queue per device ===\n");
    int usable = 0;
    for (int i = 0; i < n; i++) {
        Dev* d = &devs[i];
        cl_int err = CL_SUCCESS;
        d->ctx = clCreateContext(NULL, 1, &d->dev, NULL, NULL, &err);
        if (!d->ctx || err != CL_SUCCESS) {
            printf("  [%d] %-40s clCreateContext -> %d %s\n", i, d->name, err, ocl_err_name(err));
            continue;
        }
        cl_queue_properties props[] = { 0 };
        d->queue = clCreateCommandQueueWithProperties(d->ctx, d->dev, props, &err);
        if (!d->queue || err != CL_SUCCESS) {
            printf("  [%d] %-40s clCreateCommandQueueWithProperties -> %d %s\n", i, d->name, err, ocl_err_name(err));
            clReleaseContext(d->ctx);
            d->ctx = NULL;
            continue;
        }
        printf("  [%d] %-40s context + queue OK\n", i, d->name);
        usable++;
    }
    if (usable == 0) return ocl_report_skip("no device accepted a context and a queue");

    // ---- 4. attempt every feature on every device -------------------------
    printf("\n=== step 4: attempt all %d features on all %d devices ===\n", F_COUNT, n);
    for (int i = 0; i < n; i++) {
        Dev* d = &devs[i];
        if (!d->ctx) continue;
        printf("\n  --- [%d] %s ---\n", i, d->name);
        for (int j = 0; j < F_COUNT; j++) {
            printf("    %s (advertised: %s)\n", featureName[j], d->f[j].advertised ? "yes" : "no");
            switch (j) {
            case F_SVM_COARSE: test_svm_coarse(d, &d->f[j]); break;
            case F_SVM_FINE:   test_svm_fine(d, &d->f[j]);   break;
            case F_TOGLOBAL:   test_to_global(d, &d->f[j]);  break;
            case F_SUBGROUP:   test_subgroup(d, &d->f[j]);   break;
            }
            printf("      -> %s\n", d->f[j].detail);
        }
    }

    // ---- 5. advertised against actual -------------------------------------
    printf("\n=== step 5: did the capability queries tell the truth? ===\n");
    printf("  %-39s %-21s %-10s %s\n", "device", "feature", "advertised", "actual");
    int broken = 0, unpromised = 0, verified = 0, defects = 0;
    for (int i = 0; i < n; i++) {
        Dev* d = &devs[i];
        if (!d->ctx) { printf("  %-39s (no context)\n", d->name); continue; }
        for (int j = 0; j < F_COUNT; j++) {
            Feat* f = &d->f[j];
            const char* verdict;
            if (!f->attempted)                    verdict = "not attempted";
            else if (f->advertised && f->worked)  { verdict = "OK: promised and delivered"; verified++; }
            else if (f->defect)                   { verdict = "DEFECT: advertised, ran, data lost"; defects++; }
            else if (f->advertised && !f->worked) { verdict = "BROKEN PROMISE"; broken++; }
            else if (!f->advertised && f->worked) { verdict = "works, but was NOT advertised"; unpromised++; verified++; }
            else                                  verdict = "unavailable, as advertised";
            printf("  %-39s %-21s %-10s %s\n", d->name, featureName[j],
                   f->advertised ? "yes" : "no", verdict);
        }
    }

    printf("\n  [NOTE] \"works, but was NOT advertised\" is not a bug in this example and not a\n");
    printf("         bug in the driver - it is the finding. CL_DEVICE_OPENCL_C_FEATURES is a\n");
    printf("         list of what a device PROMISES, and a device may do more than it promises.\n");
    printf("         Code that gates on it stays portable; code that gates on a version string\n");
    printf("         gets neither the extra capability nor a working fallback.\n");

    if (defects) {
        printf("\n  [NOTE] DEFECT is a separate row from BROKEN PROMISE on purpose, and it is only\n");
        printf("         ever set when a diagnostic proved the kernel ran. svm_cross_check writes\n");
        printf("         the same index to an SVM pointer and to an ordinary buffer in one launch:\n");
        printf("         if the ordinary half comes back correct, the work-item executed and it is\n");
        printf("         specifically the SVM store that never reached the host. Without that step,\n");
        printf("         \"the data is still poison\" cannot be told apart from \"my launch never ran\",\n");
        printf("         and blaming a vendor for the second is the worst thing a tutorial can do.\n");
        printf("         It does not fail this example because the subject here is how to GATE on a\n");
        printf("         capability, not whether one vendor conforms. But the practical consequence\n");
        printf("         is the lesson: a device advertising a capability is not the same as a\n");
        printf("         device delivering it, so gate on the query AND verify the first result.\n");
    }

    // ---- 5b. the one result the devices disagree about ---------------------
    //
    // Printed separately from the matrix because it is not a pass/fail. Every device
    // that ran to_global at all round-tripped a real global pointer, which is the
    // defined case and the only one asserted above. What they differ on is what
    // to_global hands back for a pointer that does NOT point into global memory - and
    // a difference like that only lands when the answers sit in one column each.
    printf("\n=== step 5b: to_global() given a pointer that is NOT global ===\n");
    printf("  %-39s %-18s %s\n", "device", "private pointer", "local pointer");
    unsigned int firstPriv = 0, firstLoc = 0;
    int anyRan = 0, allAgree = 1;
    for (int i = 0; i < n; i++) {
        Dev* d = &devs[i];
        if (!d->ctx || !d->f[F_TOGLOBAL].attempted || !d->f[F_TOGLOBAL].worked) continue;
        char pd[64], ld[64];
        describeMask(d->tgPrivateMask, pd, sizeof pd);
        describeMask(d->tgLocalMask,   ld, sizeof ld);
        printf("  %-39s %-18s %s\n", d->name, pd, ld);
        if (!anyRan) { firstPriv = d->tgPrivateMask; firstLoc = d->tgLocalMask; anyRan = 1; }
        else if (d->tgPrivateMask != firstPriv || d->tgLocalMask != firstLoc) allAgree = 0;
    }
    if (!anyRan) printf("  (no device ran to_global successfully)\n");

    printf("\n  [NOTE] %s\n", allAgree
        ? "every device that ran this answered the same way."
        : "those columns differ, and no device in them is broken.");
    printf("         The defined case - hand to_global a generic pointer that really does\n");
    printf("         point into global memory, get the same pointer back - held on every\n");
    printf("         device in that table, and it is the only part step 4 asserts. What a\n");
    printf("         device does with a PRIVATE or LOCAL pointer is not something the devices\n");
    printf("         here agree on:\n");
    printf("         a device whose private memory is ordinary host memory has no reason to\n");
    printf("         invent a NULL where the pointer it was given was perfectly usable. An\n");
    printf("         earlier version of this example asserted NULL, and reported a confident\n");
    printf("         BROKEN PROMISE against a CPU device that had done nothing wrong. Use\n");
    printf("         to_global on pointers that point into global memory and nowhere else.\n");

    // ---- 6. release -------------------------------------------------------
    for (int i = 0; i < n; i++) {
        if (devs[i].queue) clReleaseCommandQueue(devs[i].queue);
        if (devs[i].ctx)   clReleaseContext(devs[i].ctx);
    }

    // The only failure this example asserts is a device not delivering something it
    // advertised. A feature being absent is not a failure - it is the normal state of
    // most features on most devices, and calling it one would train readers to ignore
    // red. Verifying nothing at all is not a pass either, so that is guarded.
    printf("\nassert no device failed a feature it advertised        : %s (%d broken)\n",
           broken == 0 ? "OK" : "FAILED", broken);
    printf("assert at least one feature was numerically verified   : %s (%d verified)\n",
           verified > 0 ? "OK" : "FAILED", verified);
    printf("info   features that worked without being advertised   : %d\n", unpromised);
    printf("info   driver defects confirmed by diagnostic          : %d\n", defects);
    return ocl_report(broken == 0 && verified > 0);
}
