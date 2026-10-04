// examples/05-reduce-sum - reduction, and why the obvious version is silently wrong.
//
// A reduction is the first place a beginner meets the fact that work-items are not
// independent. Summing N numbers with one work-item each does not sum anything; the
// work-items have to COMBINE, and combining needs local memory, barriers, and then a
// second pass over the per-work-group results.
//
// The original tutorial's kernel got three things wrong, and none of them crash:
//
//   1. It halved the stride from localSize/2, which only visits every element when
//      localSize is a power of two. At localSize=100 the strides run 50, 25, 12, 6,
//      3, 1. After those six rounds temp[0] holds 64 of the group's 100 values;
//      32 are stranded in temp[2] and 4 more in temp[24], never folded in. The
//      kernel returns a number that looks entirely plausible.
//
//   2. It wrote output[get_group_id(0)] and presented that as the answer. It is ONE
//      PARTIAL SUM PER WORK-GROUP. With N=1000 and 10 groups you get an array of 10
//      numbers and still owe yourself a second reduction.
//
//   3. It gave no guidance on the local size, so a reader who picked 100 (a natural
//      choice for N=1000) hit defect 1 without any diagnostic.
//
// The corrected path below does the second pass with a separate kernel, and uses
// sequential addressing (index = 2*s*localId) so it is correct at ANY work-group
// size, not just powers of two.
//
// Four cases run below. Case A is EXPECTED TO PRODUCE A WRONG NUMBER, and case D is
// expected to produce the RIGHT number from the SAME buggy kernel - that pairing is
// the whole lesson, because it shows the defect is silent and geometry-dependent
// rather than something a compiler or a driver would ever flag.
//
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

#define N 1000

// Outcome of one two-pass reduction.
typedef struct {
    cl_int launchErr;
    size_t globalSize;    // after rounding up to a multiple of the local size
    int    numGroups;     // how many partials the first pass produced
    int    paddedGroups;  // partials array padded to a power of two for pass two
    double total;         // partials[0] after the second pass
    size_t kernelMaxWG;   // CL_KERNEL_WORK_GROUP_SIZE for the first-pass kernel
} ReduceRun;

static size_t nextPow2(size_t v) {
    size_t p = 1;
    while (p < v) p <<= 1;
    return p;
}

// Run the named first-pass kernel plus reduce_final, and report the scalar total.
//
// The partials buffer is created zero-filled and padded up to a power of two, so
// reduce_final - which uses the simple stride-halving loop - has an honest
// precondition rather than a lucky one.
static int runReduce(cl_context context, cl_command_queue queue, cl_device_id device,
                     cl_program program, const char* kernelName, cl_mem bufIn,
                     int n, size_t localSize, int showPartials, ReduceRun* out) {
    out->launchErr = CL_SUCCESS;
    out->globalSize = 0;
    out->numGroups = 0;
    out->paddedGroups = 0;
    out->total = 0.0;
    out->kernelMaxWG = 0;

    cl_int err = CL_SUCCESS;
    cl_kernel kPartial = clCreateKernel(program, kernelName, &err);
    if (!kPartial) {
        printf("    [FAIL] clCreateKernel(%s) -> %s\n", kernelName, ocl_err_name(err));
        return -1;
    }
    cl_kernel kFinal = clCreateKernel(program, "reduce_final", &err);
    if (!kFinal) {
        printf("    [FAIL] clCreateKernel(reduce_final) -> %s\n", ocl_err_name(err));
        clReleaseKernel(kPartial);
        return -1;
    }

    // Query the kernel's own limit, not just the device's: register pressure and
    // local memory use can pull CL_KERNEL_WORK_GROUP_SIZE below the device maximum.
    clGetKernelWorkGroupInfo(kPartial, device, CL_KERNEL_WORK_GROUP_SIZE,
                             sizeof(out->kernelMaxWG), &out->kernelMaxWG, NULL);
    if (localSize > out->kernelMaxWG) {
        printf("    [FAIL] local size %zu exceeds CL_KERNEL_WORK_GROUP_SIZE %zu\n",
               localSize, out->kernelMaxWG);
        clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    size_t globalSize = ocl_round_up((size_t)n, localSize);
    int numGroups = (int)(globalSize / localSize);
    size_t padded = nextPow2((size_t)numGroups);

    size_t deviceMaxWG = 0;
    clGetDeviceInfo(device, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(deviceMaxWG), &deviceMaxWG, NULL);
    if (padded > deviceMaxWG) {
        // Honest limitation rather than a silent wrong answer: this two-pass scheme
        // needs a third pass once the partial count exceeds one work-group.
        printf("    [FAIL] %d partials padded to %zu exceeds max work-group %zu; needs a third pass\n",
               numGroups, padded, deviceMaxWG);
        clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    out->globalSize = globalSize;
    out->numGroups = numGroups;
    out->paddedGroups = (int)padded;

    float* zeros = (float*)calloc(padded, sizeof(float));
    if (!zeros) { clReleaseKernel(kPartial); clReleaseKernel(kFinal); return -1; }
    cl_mem bufPartials = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                        padded * sizeof(float), zeros, &err);
    free(zeros);
    if (!bufPartials) {
        printf("    [FAIL] clCreateBuffer(partials) -> %s\n", ocl_err_name(err));
        clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    int nArg = n;
    int numPartialsArg = numGroups;

    clSetKernelArg(kPartial, 0, sizeof(cl_mem), &bufIn);
    clSetKernelArg(kPartial, 1, sizeof(cl_mem), &bufPartials);
    clSetKernelArg(kPartial, 2, localSize * sizeof(float), NULL);   // __local float* temp
    clSetKernelArg(kPartial, 3, sizeof(int), &nArg);

    clSetKernelArg(kFinal, 0, sizeof(cl_mem), &bufPartials);
    clSetKernelArg(kFinal, 1, padded * sizeof(float), NULL);
    clSetKernelArg(kFinal, 2, sizeof(int), &numPartialsArg);

    printf("    %s: n=%d global=%zu local=%zu -> %d partials (padded to %zu)\n",
           kernelName, n, globalSize, localSize, numGroups, padded);

    err = clEnqueueNDRangeKernel(queue, kPartial, 1, NULL, &globalSize, &localSize, 0, NULL, NULL);
    out->launchErr = err;
    if (err != CL_SUCCESS) {
        printf("    [FAIL] pass 1 launch -> %d %s\n", err, ocl_err_name(err));
        clReleaseMemObject(bufPartials); clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    // Snapshot the partials BETWEEN the two passes. reduce_final writes its answer
    // into partials[0], so reading after pass 2 would print the total in slot 0 and
    // call it a partial.
    if (showPartials) {
        float* snapshot = (float*)calloc(padded, sizeof(float));
        if (!snapshot) { clReleaseMemObject(bufPartials); clReleaseKernel(kPartial); clReleaseKernel(kFinal); return -1; }
        err = clEnqueueReadBuffer(queue, bufPartials, CL_TRUE, 0, padded * sizeof(float), snapshot, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            printf("    [FAIL] read partials -> %s\n", ocl_err_name(err));
            free(snapshot); clReleaseMemObject(bufPartials);
            clReleaseKernel(kPartial); clReleaseKernel(kFinal);
            return -1;
        }
        printf("    pass 1 produced %d partials:\n      ", numGroups);
        for (int i = 0; i < numGroups; i++) printf("%.0f ", snapshot[i]);
        double snapshotSum = 0.0;
        for (int i = 0; i < numGroups; i++) snapshotSum += (double)snapshot[i];
        printf("\n    sum of partials = %.1f\n", snapshotSum);
        printf("    A reader who stopped here would have %d numbers, not one - that is\n", numGroups);
        printf("    what pass 2 is for.\n");
        free(snapshot);
    }

    size_t finalGlobal = padded, finalLocal = padded;
    err = clEnqueueNDRangeKernel(queue, kFinal, 1, NULL, &finalGlobal, &finalLocal, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("    [FAIL] pass 2 launch -> %d %s\n", err, ocl_err_name(err));
        clReleaseMemObject(bufPartials); clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    float total = 0.0f;
    err = clEnqueueReadBuffer(queue, bufPartials, CL_TRUE, 0, sizeof(float), &total, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("    [FAIL] read partials[0] -> %s\n", ocl_err_name(err));
        clReleaseMemObject(bufPartials); clReleaseKernel(kPartial); clReleaseKernel(kFinal);
        return -1;
    }

    out->total = (double)total;
    printf("    pass 2 total = %.1f (CL_KERNEL_WORK_GROUP_SIZE=%zu)\n", out->total, out->kernelMaxWG);

    clReleaseMemObject(bufPartials);
    clReleaseKernel(kPartial);
    clReleaseKernel(kFinal);
    return 0;
}

// Compare a measured total against the reference and classify it against the outcome
// the case documents. Returns 1 if the case behaved as documented, 0 if not.
static int checkCase(const char* label, const ReduceRun* r, double reference, int expectMatch) {
    double diff = r->total - reference;
    if (diff < 0) diff = -diff;
    double tol = 1e-4 * ((reference < 0 ? -reference : reference) + 1.0);
    int matched = (diff <= tol);

    printf("    case %s: reference = %.1f, got = %.1f, abs diff = %.1f -> %s\n",
           label, reference, r->total, diff, matched ? "MATCHES" : "DIFFERS");

    if (matched == expectMatch) {
        if (expectMatch) printf("    as documented: correct.\n");
        else             printf("    as documented: wrong, and nothing reported an error.\n");
        return 1;
    }
    printf("    UNEXPECTED: case %s %s but documents %s\n",
           label, matched ? "matched" : "differed", expectMatch ? "a match" : "a mismatch");
    return 0;
}

int main(void) {
    cl_device_id device = NULL;
    char deviceName[256] = {0};
    if (ocl_pick_device(OCL_DEFAULT_DEVICE, CL_DEVICE_TYPE_ALL, &device, deviceName, sizeof(deviceName)) != 0) {
        printf("[FAIL] no device matching \"%s\"; run 01-device-query first\n", OCL_DEFAULT_DEVICE);
        return ocl_report(0);
    }
    ocl_report_device(device);

    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context) { printf("[FAIL] clCreateContext -> %s\n", ocl_err_name(err)); return ocl_report(0); }
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, NULL, &err);
    if (!queue) { printf("[FAIL] clCreateCommandQueue -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    char* source = ocl_read_file("kernels/reduce_sum.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }

    size_t srcLen = strlen(source);
    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, &srcLen, &err);
    if (!program) { printf("[FAIL] clCreateProgramWithSource -> %s\n", ocl_err_name(err)); return ocl_report(0); }
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        char* log = (char*)malloc(logSz + 1);
        if (log) {
            clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
            log[logSz] = '\0';
            printf("[build log]\n%s\n", log);
            free(log);
        }
        printf("[FAIL] clBuildProgram -> %s\n", ocl_err_name(err));
        return ocl_report(0);
    }

    // All-positive small integers: the exact total (3997) is representable in float,
    // so any difference from the reference is dropped data, not rounding. A
    // zero-mean pattern would let a wrong reduction land near the right answer.
    float* input = (float*)malloc(N * sizeof(float));
    if (!input) { printf("[FAIL] out of host memory\n"); return ocl_report(0); }
    double reference = 0.0;
    for (int i = 0; i < N; i++) {
        input[i] = (float)(i % 7) + 1.0f;
        reference += (double)input[i];
    }

    cl_mem bufIn = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                  N * sizeof(float), input, &err);
    if (!bufIn) {
        printf("[FAIL] clCreateBuffer(input) -> %s\n", ocl_err_name(err));
        free(input);
        return ocl_report(0);
    }

    printf("\nn = %d, exact reference sum = %.1f\n", N, reference);

    int failures = 0;

    // ---- Case A: the original kernel at a non-power-of-two local size. ----
    printf("\n=== case A: reduce_partial_naive, local=100 (expect a WRONG total) ===\n");
    printf("    100 is not a power of two, so stride halving 50,25,12,6,3,1 strands\n");
    printf("    36 of each group's 100 values. No API call reports any of this.\n");
    {
        ReduceRun r;
        if (runReduce(context, queue, device, program, "reduce_partial_naive",
                      bufIn, N, 100, 1, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (!checkCase("A", &r, reference, 0)) {
            failures++;
        }
    }

    // ---- Case B: the corrected kernel at the same geometry. ---------------
    printf("\n=== case B: reduce_partial_safe, local=100 (expect a correct total) ===\n");
    printf("    Same n, same local size, same data - only the fold pattern changed.\n");
    {
        ReduceRun r;
        if (runReduce(context, queue, device, program, "reduce_partial_safe",
                      bufIn, N, 100, 1, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (!checkCase("B", &r, reference, 1)) {
            failures++;
        }
    }

    // ---- Case C: the corrected kernel at a power-of-two local size. -------
    printf("\n=== case C: reduce_partial_safe, local=64 (expect a correct total) ===\n");
    printf("    n=1000 rounds up to global=1024, so 16 groups and 24 padding\n");
    printf("    work-items. The kernel's bounds check is what makes that safe.\n");
    {
        ReduceRun r;
        if (runReduce(context, queue, device, program, "reduce_partial_safe",
                      bufIn, N, 64, 0, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (!checkCase("C", &r, reference, 1)) {
            failures++;
        }
    }

    // ---- Case D: the original kernel at a power-of-two local size. --------
    printf("\n=== case D: reduce_partial_naive, local=64 (expect a CORRECT total) ===\n");
    printf("    The same buggy kernel from case A, now right. This is why the defect\n");
    printf("    survives code review: it only shows at geometries nobody tested.\n");
    {
        ReduceRun r;
        if (runReduce(context, queue, device, program, "reduce_partial_naive",
                      bufIn, N, 64, 0, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (!checkCase("D", &r, reference, 1)) {
            failures++;
        }
    }

    free(input);
    clReleaseMemObject(bufIn);
    clReleaseProgram(program);
    free(source);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    printf("\n=== summary ===\n");
    printf("device %s, n=%d, reference %.1f\n", deviceName, N, reference);
    printf("case A naive local=100 : a wrong total is the documented outcome\n");
    printf("case B safe  local=100 : correct\n");
    printf("case C safe  local=64  : correct\n");
    printf("case D naive local=64  : correct - the bug is geometry-dependent\n");
    printf("unexpected outcomes    : %d\n", failures);

    return ocl_report(failures == 0);
}
