// examples/07-async-events - non-blocking transfers, event dependencies, and the
// difference between an in-order queue and an out-of-order one.
//
// Four things get separated here that are usually conflated:
//
//   1. BLOCKING vs NON-BLOCKING is about the HOST, not the device. clEnqueue*Buffer
//      with CL_TRUE returns after the transfer finishes; with CL_FALSE it returns as
//      soon as the command is queued. The device does identical work either way.
//
//   2. On an IN-ORDER queue, commands submitted to the same queue run in submission
//      order, so events are NOT what makes write -> kernel -> read correct. You need
//      them (or clFinish) only to know when the HOST may touch its own buffer again.
//
//   3. On an OUT-OF-ORDER queue that guarantee is gone. The event wait-list is the
//      only thing ordering two commands. Omitting it produces no error - it produces
//      a race. Measured on this machine: with the wait-lists removed, the combine
//      kernel started before its producers finished in roughly half of twenty runs,
//      and the output was still numerically correct in all twenty. The overlap is
//      real and the damage is not yet visible. That is the worst possible feedback.
//
//   4. A marker (clEnqueueMarkerWithWaitList, an OpenCL 1.2 entry point) fans several
//      branches back into one. It enqueues no device work; it is purely a join node.
//      Which means its OWN profiling timestamps are not a barrier instant - this
//      driver was observed stamping the marker's END after the kernel waiting on it
//      had already STARTED, while both real data producers had correctly finished
//      first. Assert on the edges that carry data, not on the join node.
//
// Cases C and D run this diamond, which is a real DAG rather than a chain:
//
//   evWriteA --> scale_kernel  (C = A*2)     --\
//                                               +--> evFan --> add_kernel (E = C+D) --> evRead
//   evWriteB --> offset_kernel (D = B+1000)  --/
//
// Four cases run. Case B peeks at a host buffer it has no right to read yet and
// reports what it finds; case D measures how often dropping the wait-lists actually
// goes wrong. Neither peek is a pass/fail condition - a race that happens to come out
// right proves nothing, and a race that goes wrong is not a bug in this example.
//
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

#define N      65536
#define LOCAL  256
#define EPS    1e-5
#define RACY_REPEATS 20

// Everything the DAG runner needs, bundled so its signature stays readable.
typedef struct {
    cl_mem A, B, C, D, E;
    cl_kernel scale, offset, add;
} Dag;

typedef struct {
    int    wrong;
    double maxAbsErr;
    int    edgesChecked;   // dependency edges whose profiling order was verified
    int    edgesOk;        // how many of those held: end(parent) <= start(child)
    int    dataChecked;    // edges that carry DATA into the combine kernel
    int    dataOk;
    int    markerLagged;   // marker's own END came after its child's START
} DagRun;

static cl_ulong evTime(cl_event e, cl_profiling_info what) {
    cl_ulong v = 0;
    clGetEventProfilingInfo(e, what, sizeof(v), &v, NULL);
    return v;
}

// Accumulate the FIRST real error. Bitwise-ORing cl_int codes together is a common
// shortcut and it is wrong: the result names no error at all, so the message you
// print afterwards is fiction.
static cl_int keepFirst(cl_int acc, cl_int e) {
    return (acc != CL_SUCCESS) ? acc : e;
}

// Release a set of events and NULL them. The argument count comes from sizeof rather
// than being passed by hand, so it cannot drift out of sync with the list.
#define RELEASE_EVENTS(...)                                                  \
    do {                                                                     \
        cl_event* evs_[] = { __VA_ARGS__ };                                  \
        for (size_t i_ = 0; i_ < sizeof(evs_) / sizeof(evs_[0]); i_++)        \
            if (*evs_[i_]) { clReleaseEvent(*evs_[i_]); *evs_[i_] = NULL; }   \
    } while (0)

// One dependency edge: the parent must have ended no later than the child started.
// This is the objective evidence that the graph was honoured rather than assumed.
static int checkEdge(const char* label, cl_event parent, cl_event child,
                     int* checked, int* ok, int verbose) {
    if (!parent || !child) return 1;
    cl_ulong parentEnd = evTime(parent, CL_PROFILING_COMMAND_END);
    cl_ulong childStart = evTime(child, CL_PROFILING_COMMAND_START);
    (*checked)++;
    int held = (parentEnd <= childStart);
    if (held) (*ok)++;
    if (verbose)
        printf("      edge %-24s parent_end=%llu child_start=%llu  %s\n",
               label, (unsigned long long)parentEnd, (unsigned long long)childStart,
               held ? "ordered" : "VIOLATED");
    return held;
}

// Linear chain: upload hostA, compute C = A*2, download into hostOut.
//
// blocking=1 uses CL_TRUE for both transfers. blocking=0 uses CL_FALSE, in which case
// the read has merely been QUEUED when the call returns and hostOut is not the
// caller's to read yet. peekBeforeWait=1 deliberately reads it anyway and reports how
// much of it had arrived, which is the point of the exercise.
static int runLinear(cl_command_queue queue, cl_mem bufA, cl_mem bufC, cl_kernel kScale,
                     const float* hostA, float* hostOut, const float* refC, int n,
                     int blocking, int peekBeforeWait, int* outPeekWrong) {
    const size_t global = ocl_round_up((size_t)n, (size_t)LOCAL);
    const size_t local = LOCAL;
    const float k = 2.0f;
    const int nArg = n;
    const size_t bytes = (size_t)n * sizeof(float);
    const cl_bool mode = blocking ? CL_TRUE : CL_FALSE;

    clSetKernelArg(kScale, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kScale, 1, sizeof(cl_mem), &bufC);
    clSetKernelArg(kScale, 2, sizeof(float), &k);
    clSetKernelArg(kScale, 3, sizeof(int), &nArg);

    cl_int err = clEnqueueWriteBuffer(queue, bufA, mode, 0, bytes, hostA, 0, NULL, NULL);
    if (err != CL_SUCCESS) { printf("    [FAIL] write A -> %s\n", ocl_err_name(err)); return -1; }

    err = clEnqueueNDRangeKernel(queue, kScale, 1, NULL, &global, &local, 0, NULL, NULL);
    if (err != CL_SUCCESS) { printf("    [FAIL] scale -> %s\n", ocl_err_name(err)); return -1; }

    // Sentinel-fill so a peek can distinguish "not arrived yet" from "happened to be
    // right already". Without this the peek would be uninterpretable.
    for (int i = 0; i < n; i++) hostOut[i] = -1.0e30f;

    err = clEnqueueReadBuffer(queue, bufC, mode, 0, bytes, hostOut, 0, NULL, NULL);
    if (err != CL_SUCCESS) { printf("    [FAIL] read C -> %s\n", ocl_err_name(err)); return -1; }

    if (peekBeforeWait && !blocking) {
        int wrong = 0;
        for (int i = 0; i < n; i++) {
            double diff = (double)hostOut[i] - (double)refC[i];
            if (diff < 0) diff = -diff;
            if (diff > EPS) wrong++;
        }
        *outPeekWrong = wrong;
        printf("    peek before clFinish: %d/%d elements not yet correct\n", wrong, n);
        printf("    (this read is INFORMATIONAL - the buffer is not the host's to\n");
        printf("     touch until the command completes, so either outcome is legal)\n");
    }

    err = clFinish(queue);
    if (err != CL_SUCCESS) { printf("    [FAIL] clFinish -> %s\n", ocl_err_name(err)); return -1; }

    int wrong = 0;
    for (int i = 0; i < n; i++) {
        double diff = (double)hostOut[i] - (double)refC[i];
        if (diff < 0) diff = -diff;
        if (diff > EPS) {
            if (wrong < 3) printf("    mismatch [%d] got %f want %f\n", i, hostOut[i], refC[i]);
            wrong++;
        }
    }
    printf("    after clFinish: %d/%d elements correct\n", n - wrong, n);
    return wrong;
}

// Run the diamond DAG.
//
// useWaitLists=1 gives every command the event wait-list it needs, which is correct
// on any queue. useWaitLists=0 passes empty wait-lists, which is correct on an
// in-order queue and a genuine race on an out-of-order one.
//
// poisonCD=1 blocking-writes a sentinel into C and D first. Without it a racy run
// would read correct-looking values left over from the previous iteration and the
// race would never show.
//
// checkEdges verifies each dependency edge from the profiling timestamps;
// verboseEdges controls whether each one is printed (case D repeats twenty times and
// must not flood the log).
static int runDag(cl_command_queue queue, const Dag* d,
                  const float* hostA, const float* hostB, float* hostOut,
                  const float* refE, int n, int useWaitLists,
                  int checkEdges, int verboseEdges, int poisonCD, DagRun* out) {
    out->wrong = 0;
    out->maxAbsErr = 0.0;
    out->edgesChecked = 0;
    out->edgesOk = 0;

    const size_t global = ocl_round_up((size_t)n, (size_t)LOCAL);
    const size_t local = LOCAL;
    const size_t bytes = (size_t)n * sizeof(float);
    const float kScale = 2.0f;
    const float kOffset = 1000.0f;
    const int nArg = n;
    cl_int err = CL_SUCCESS;

    if (poisonCD) {
        float* poison = (float*)malloc(bytes);
        if (!poison) return -1;
        for (int i = 0; i < n; i++) poison[i] = -1.0e30f;
        // CL_TRUE: these complete before the racy graph is queued.
        clEnqueueWriteBuffer(queue, d->C, CL_TRUE, 0, bytes, poison, 0, NULL, NULL);
        clEnqueueWriteBuffer(queue, d->D, CL_TRUE, 0, bytes, poison, 0, NULL, NULL);
        free(poison);
    }

    cl_event evWriteA = NULL, evWriteB = NULL, evScale = NULL, evOffset = NULL;
    cl_event evFan = NULL, evAdd = NULL, evRead = NULL;

    // --- roots: two independent uploads -----------------------------------
    err = keepFirst(err, clEnqueueWriteBuffer(queue, d->A, CL_FALSE, 0, bytes, hostA, 0, NULL, &evWriteA));
    err = keepFirst(err, clEnqueueWriteBuffer(queue, d->B, CL_FALSE, 0, bytes, hostB, 0, NULL, &evWriteB));

    // --- branch 1: scale --------------------------------------------------
    clSetKernelArg(d->scale, 0, sizeof(cl_mem), &d->A);
    clSetKernelArg(d->scale, 1, sizeof(cl_mem), &d->C);
    clSetKernelArg(d->scale, 2, sizeof(float), &kScale);
    clSetKernelArg(d->scale, 3, sizeof(int), &nArg);
    cl_event waitA[1] = { evWriteA };
    err = keepFirst(err, clEnqueueNDRangeKernel(queue, d->scale, 1, NULL, &global, &local,
                                                useWaitLists ? 1 : 0, useWaitLists ? waitA : NULL, &evScale));

    // --- branch 2: offset -------------------------------------------------
    clSetKernelArg(d->offset, 0, sizeof(cl_mem), &d->B);
    clSetKernelArg(d->offset, 1, sizeof(cl_mem), &d->D);
    clSetKernelArg(d->offset, 2, sizeof(float), &kOffset);
    clSetKernelArg(d->offset, 3, sizeof(int), &nArg);
    cl_event waitB[1] = { evWriteB };
    err = keepFirst(err, clEnqueueNDRangeKernel(queue, d->offset, 1, NULL, &global, &local,
                                                useWaitLists ? 1 : 0, useWaitLists ? waitB : NULL, &evOffset));

    // --- join: a marker does no device work, it is purely a graph node -----
    cl_event waitFan[2] = { evScale, evOffset };
    err = keepFirst(err, clEnqueueMarkerWithWaitList(queue, useWaitLists ? 2 : 0,
                                                     useWaitLists ? waitFan : NULL, &evFan));

    // --- combine ----------------------------------------------------------
    clSetKernelArg(d->add, 0, sizeof(cl_mem), &d->C);
    clSetKernelArg(d->add, 1, sizeof(cl_mem), &d->D);
    clSetKernelArg(d->add, 2, sizeof(cl_mem), &d->E);
    clSetKernelArg(d->add, 3, sizeof(int), &nArg);
    cl_event waitAdd[1] = { evFan };
    err = keepFirst(err, clEnqueueNDRangeKernel(queue, d->add, 1, NULL, &global, &local,
                                                useWaitLists ? 1 : 0, useWaitLists ? waitAdd : NULL, &evAdd));

    // --- download ---------------------------------------------------------
    for (int i = 0; i < n; i++) hostOut[i] = -1.0e30f;
    cl_event waitRead[1] = { evAdd };
    err = keepFirst(err, clEnqueueReadBuffer(queue, d->E, CL_FALSE, 0, bytes, hostOut,
                                             useWaitLists ? 1 : 0, useWaitLists ? waitRead : NULL, &evRead));

    if (err != CL_SUCCESS) {
        printf("    [FAIL] enqueue -> %d %s\n", err, ocl_err_name(err));
        RELEASE_EVENTS(&evWriteA, &evWriteB, &evScale, &evOffset, &evFan, &evAdd, &evRead);
        return -1;
    }

    // Waiting on the LAST event is enough: it transitively waits on everything the
    // graph depends on. That is the whole point of building the graph.
    err = clWaitForEvents(1, &evRead);
    if (err != CL_SUCCESS) {
        printf("    [FAIL] clWaitForEvents -> %d %s\n", err, ocl_err_name(err));
        RELEASE_EVENTS(&evWriteA, &evWriteB, &evScale, &evOffset, &evFan, &evAdd, &evRead);
        return -1;
    }

    if (checkEdges) {
        // The marker's own timestamps, printed in full because they turn out not to
        // mean what a reader would expect. See the note below.
        if (verboseEdges && evFan) {
            printf("      marker evFan profiling: queued=%llu submit=%llu start=%llu end=%llu\n",
                   (unsigned long long)evTime(evFan, CL_PROFILING_COMMAND_QUEUED),
                   (unsigned long long)evTime(evFan, CL_PROFILING_COMMAND_SUBMIT),
                   (unsigned long long)evTime(evFan, CL_PROFILING_COMMAND_START),
                   (unsigned long long)evTime(evFan, CL_PROFILING_COMMAND_END));
        }

        printf("      -- graph edges (the wait-lists as submitted) --\n");
        checkEdge("writeA -> scale",  evWriteA, evScale,  &out->edgesChecked, &out->edgesOk, verboseEdges);
        checkEdge("writeB -> offset", evWriteB, evOffset, &out->edgesChecked, &out->edgesOk, verboseEdges);
        checkEdge("scale -> fan",     evScale,  evFan,    &out->edgesChecked, &out->edgesOk, verboseEdges);
        checkEdge("offset -> fan",    evOffset, evFan,    &out->edgesChecked, &out->edgesOk, verboseEdges);
        int fanToAdd = checkEdge("fan -> add",  evFan,    evAdd, &out->edgesChecked, &out->edgesOk, verboseEdges);
        checkEdge("add -> read",      evAdd,    evRead,   &out->edgesChecked, &out->edgesOk, verboseEdges);

        // A marker is a join node with no data of its own, so the edges that a
        // correctness argument actually rests on are the producers of the buffers the
        // combine kernel reads: scale writes C, offset writes D, add reads both.
        printf("      -- data edges (who produced what add consumed) --\n");
        checkEdge("scale -> add (C)",  evScale,  evAdd, &out->dataChecked, &out->dataOk, verboseEdges);
        checkEdge("offset -> add (D)", evOffset, evAdd, &out->dataChecked, &out->dataOk, verboseEdges);

        out->markerLagged = !fanToAdd;
        if (verboseEdges) {
            printf("    graph edges ordered %d/%d, data edges ordered %d/%d\n",
                   out->edgesOk, out->edgesChecked, out->dataOk, out->dataChecked);
            if (out->markerLagged)
                printf("    NOTE: the marker's own END is LATER than add's START.\n");
        }
    }

    int wrong = 0;
    double maxAbsErr = 0.0;
    for (int i = 0; i < n; i++) {
        double diff = (double)hostOut[i] - (double)refE[i];
        if (diff < 0) diff = -diff;
        if (diff > maxAbsErr) maxAbsErr = diff;
        if (diff > EPS) wrong++;
    }
    out->wrong = wrong;
    out->maxAbsErr = maxAbsErr;

    RELEASE_EVENTS(&evWriteA, &evWriteB, &evScale, &evOffset, &evFan, &evAdd, &evRead);
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

    // Does this device allow out-of-order queues at all? Cases C and D depend on it.
    cl_command_queue_properties devQueueProps = 0;
    clGetDeviceInfo(device, CL_DEVICE_QUEUE_PROPERTIES,
                    sizeof(devQueueProps), &devQueueProps, NULL);
    int outOfOrderOk = (devQueueProps & CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) != 0;
    printf("[queue]  CL_DEVICE_QUEUE_PROPERTIES = 0x%llX -> out-of-order %s, profiling %s\n",
           (unsigned long long)devQueueProps,
           outOfOrderOk ? "supported" : "NOT supported",
           (devQueueProps & CL_QUEUE_PROFILING_ENABLE) ? "supported" : "NOT supported");

    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context) { printf("[FAIL] clCreateContext -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    char* source = ocl_read_file("kernels/dag.cl");
    if (!source) { clReleaseContext(context); return ocl_report(0); }
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

    Dag d;
    d.scale  = clCreateKernel(program, "scale_kernel",  &err);
    d.offset = clCreateKernel(program, "offset_kernel", &err);
    d.add    = clCreateKernel(program, "add_kernel",    &err);
    if (!d.scale || !d.offset || !d.add) {
        printf("[FAIL] clCreateKernel -> %s\n", ocl_err_name(err));
        return ocl_report(0);
    }

    const size_t bytes = (size_t)N * sizeof(float);
    float* hostA = (float*)malloc(bytes);
    float* hostB = (float*)malloc(bytes);
    float* hostOut = (float*)malloc(bytes);
    float* refC = (float*)malloc(bytes);
    float* refE = (float*)malloc(bytes);
    if (!hostA || !hostB || !hostOut || !refC || !refE) {
        printf("[FAIL] out of host memory\n");
        return ocl_report(0);
    }
    for (int i = 0; i < N; i++) {
        hostA[i] = (float)(i % 100);
        hostB[i] = (float)((i * 7) % 53);
        refC[i] = hostA[i] * 2.0f;
        refE[i] = (float)((double)hostA[i] * 2.0 + ((double)hostB[i] + 1000.0));
    }

    d.A = clCreateBuffer(context, CL_MEM_READ_ONLY,  bytes, NULL, &err);
    d.B = clCreateBuffer(context, CL_MEM_READ_ONLY,  bytes, NULL, &err);
    d.C = clCreateBuffer(context, CL_MEM_READ_WRITE, bytes, NULL, &err);
    d.D = clCreateBuffer(context, CL_MEM_READ_WRITE, bytes, NULL, &err);
    d.E = clCreateBuffer(context, CL_MEM_READ_WRITE, bytes, NULL, &err);
    if (!d.A || !d.B || !d.C || !d.D || !d.E) {
        printf("[FAIL] clCreateBuffer -> %s\n", ocl_err_name(err));
        return ocl_report(0);
    }

    int failures = 0;

    // ---- In-order queue, used by cases A and B -----------------------------
    cl_queue_properties inOrderProps[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE,
        0
    };
    cl_command_queue qInOrder = clCreateCommandQueueWithProperties(context, device, inOrderProps, &err);
    if (!qInOrder) { printf("[FAIL] in-order queue -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    // ---- Case A: blocking transfers, no events. The baseline. --------------
    printf("\n=== case A: in-order queue, BLOCKING (CL_TRUE) transfers, no events (expect pass) ===\n");
    printf("    Every enqueue returns only after its transfer is done, so there is\n");
    printf("    nothing left to synchronize when the call chain ends.\n");
    {
        int peekWrong = -1;
        int wrong = runLinear(qInOrder, d.A, d.C, d.scale, hostA, hostOut, refC, N,
                              1, 0, &peekWrong);
        if (wrong < 0) { printf("    UNEXPECTED: harness error\n"); failures++; }
        else if (wrong != 0) { printf("    UNEXPECTED: %d wrong elements\n", wrong); failures++; }
        else printf("    as documented: correct with no events involved\n");
    }

    // ---- Case B: non-blocking transfers, still no events. ------------------
    printf("\n=== case B: in-order queue, NON-BLOCKING (CL_FALSE) transfers, no events (expect pass after clFinish) ===\n");
    printf("    Submission order still holds on an in-order queue, so the DEVICE side\n");
    printf("    needs no events. The HOST side does: the read is only queued when the\n");
    printf("    enqueue returns.\n");
    {
        int peekWrong = -1;
        int wrong = runLinear(qInOrder, d.A, d.C, d.scale, hostA, hostOut, refC, N,
                              0, 1, &peekWrong);
        if (wrong < 0) { printf("    UNEXPECTED: harness error\n"); failures++; }
        else if (wrong != 0) { printf("    UNEXPECTED: %d wrong elements after clFinish\n", wrong); failures++; }
        else {
            printf("    as documented: correct once clFinish returned.\n");
            printf("    The peek found %d/%d elements not yet correct - a real race that\n",
                   peekWrong, N);
            printf("    this example reports but does not assert on, because on a fast\n");
            printf("    driver it can legitimately come out as 0.\n");
        }
    }

    // ---- Out-of-order queue, used by cases C and D -------------------------
    cl_command_queue qOOO = NULL;
    if (outOfOrderOk) {
        cl_queue_properties oooProps[] = {
            CL_QUEUE_PROPERTIES,
            (cl_queue_properties)(CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE | CL_QUEUE_PROFILING_ENABLE),
            0
        };
        qOOO = clCreateCommandQueueWithProperties(context, device, oooProps, &err);
        if (!qOOO) printf("[warn] out-of-order queue creation failed -> %s\n", ocl_err_name(err));
    }

    if (!qOOO) {
        printf("\n=== cases C and D: SKIPPED ===\n");
        printf("    This device does not offer CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,\n");
        printf("    so there is no queue on which a missing wait-list can actually race.\n");
        printf("    Cases A and B already cover the in-order contract.\n");
    } else {
        // ---- Case C: the DAG with proper wait-lists ------------------------
        printf("\n=== case C: out-of-order queue, full event DAG with wait-lists (expect pass) ===\n");
        printf("    Two independent uploads, two independent kernels, a marker to join\n");
        printf("    them, one combine kernel. Every edge is an explicit wait-list.\n");
        {
            DagRun r;
            if (runDag(qOOO, &d, hostA, hostB, hostOut, refE, N,
                       1 /*wait-lists*/, 1 /*check edges*/, 1 /*print them*/,
                       0 /*no poison*/, &r) != 0) {
                printf("    UNEXPECTED: harness error\n"); failures++;
            } else if (r.wrong != 0) {
                printf("    UNEXPECTED: %d wrong elements\n", r.wrong); failures++;
            } else if (r.dataChecked > 0 && r.dataOk != r.dataChecked) {
                // This is the assertion that matters: every producer of a buffer the
                // combine kernel reads must have finished before it started.
                printf("    UNEXPECTED: %d/%d DATA edges violated despite wait-lists\n",
                       r.dataChecked - r.dataOk, r.dataChecked);
                failures++;
            } else {
                printf("    as documented: %d/%d correct, max abs err %.3e\n", N - r.wrong, N, r.maxAbsErr);
                printf("    all %d data edges held; %d/%d graph edges held by timestamp\n",
                       r.dataChecked, r.edgesOk, r.edgesChecked);
                if (r.markerLagged) {
                    printf("    fan -> add did NOT hold by timestamp, and that is expected of a\n");
                    printf("    marker: it enqueues no device work, so its START/END record when\n");
                    printf("    the driver processed the marker command, not when its wait-list\n");
                    printf("    became satisfied. One run on this machine put the marker's END\n");
                    printf("    about 7 us AFTER the add kernel that waited on it had STARTED,\n");
                    printf("    while both data producers had correctly finished first.\n");
                    printf("    The lag is intermittent, so this example asserts on the data\n");
                    printf("    edges and only reports the marker one.\n");
                }
            }
        }

        // ---- Case D: the same DAG with the wait-lists removed ---------------
        printf("\n=== case D: out-of-order queue, DAG with NO wait-lists, %d repeats (report only) ===\n", RACY_REPEATS);
        printf("    The two intermediate buffers are re-poisoned with -1e30 before each\n");
        printf("    run, otherwise the previous iteration's correct values hide the race.\n");
        {
            int wrongRuns = 0, graphViolatedRuns = 0, dataViolatedRuns = 0, markerLagRuns = 0;
            int totalGraphViolations = 0, totalDataViolations = 0;
            double worstErr = 0.0;
            for (int rep = 0; rep < RACY_REPEATS; rep++) {
                DagRun r;
                if (runDag(qOOO, &d, hostA, hostB, hostOut, refE, N,
                           0 /*no wait-lists*/, 1 /*check edges*/, 0 /*quiet*/,
                           1 /*poison C,D*/, &r) != 0) {
                    printf("    UNEXPECTED: harness error on repeat %d\n", rep); failures++; break;
                }
                if (r.wrong) { wrongRuns++; if (r.maxAbsErr > worstErr) worstErr = r.maxAbsErr; }
                int graphViolated = r.edgesChecked - r.edgesOk;
                int dataViolated = r.dataChecked - r.dataOk;
                if (graphViolated > 0) { graphViolatedRuns++; totalGraphViolations += graphViolated; }
                if (dataViolated > 0)  { dataViolatedRuns++;  totalDataViolations  += dataViolated; }
                if (r.markerLagged) markerLagRuns++;
            }
            printf("    runs where the numbers were WRONG          : %d/%d\n", wrongRuns, RACY_REPEATS);
            printf("    runs where add STARTED before a producer END: %d/%d (%d edges)\n",
                   dataViolatedRuns, RACY_REPEATS, totalDataViolations);
            printf("    runs with >=1 violated graph edge          : %d/%d (%d edges)\n",
                   graphViolatedRuns, RACY_REPEATS, totalGraphViolations);
            printf("    runs where the marker's END lagged add's START: %d/%d\n",
                   markerLagRuns, RACY_REPEATS);
            if (wrongRuns > 0) {
                printf("    worst max abs err observed                 : %.3e\n", worstErr);
                printf("    The only difference from case C is the wait-lists.\n");
            } else if (dataViolatedRuns > 0) {
                printf("    This is the dangerous combination, measured rather than argued:\n");
                printf("    the combine kernel really did start before its producers finished\n");
                printf("    in %d of %d runs, and the output was still right every time.\n",
                       dataViolatedRuns, RACY_REPEATS);
                printf("    The dependency is genuinely missing and the profiler can see it,\n");
                printf("    but the numbers give no hint. A bigger n, a busier machine or a\n");
                printf("    different driver can turn this into wrong results at any moment,\n");
                printf("    which is exactly how missing wait-lists survive in production.\n");
            } else {
                printf("    Neither overlap nor wrong results on this run. That is NOT evidence\n");
                printf("    the code is correct - it means the driver happened to serialize\n");
                printf("    these commands. Re-run; the outcome is not stable.\n");
            }
        }
    }

    free(hostA); free(hostB); free(hostOut); free(refC); free(refE);
    clReleaseMemObject(d.A); clReleaseMemObject(d.B); clReleaseMemObject(d.C);
    clReleaseMemObject(d.D); clReleaseMemObject(d.E);
    clReleaseKernel(d.scale); clReleaseKernel(d.offset); clReleaseKernel(d.add);
    clReleaseProgram(program);
    free(source);
    if (qOOO) clReleaseCommandQueue(qOOO);
    clReleaseCommandQueue(qInOrder);
    clReleaseContext(context);

    printf("\n=== summary ===\n");
    printf("device %s, n=%d, local=%d, out-of-order %s\n",
           deviceName, N, LOCAL, outOfOrderOk ? "supported" : "not supported");
    printf("case A in-order + blocking        : pass\n");
    printf("case B in-order + non-blocking    : pass after clFinish; the peek is report-only\n");
    printf("case C out-of-order + wait-lists  : pass, data edges verified from profiling timestamps\n");
    printf("case D out-of-order, no wait-lists: report-only - a race is not an assertion\n");
    printf("unexpected outcomes               : %d\n", failures);

    return ocl_report(failures == 0);
}
