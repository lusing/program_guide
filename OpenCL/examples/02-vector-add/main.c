// examples/02-vector-add - the complete closed loop, end to end.
//
// This is the program the whole tutorial keeps referring back to, because it
// touches every object an ordinary OpenCL application needs, in order:
//
//   platform -> device -> context -> command queue -> program -> kernel
//            -> buffers -> enqueue write -> enqueue kernel -> enqueue read
//            -> wait -> verify
//
// It also does two things that sample code usually omits and that cost beginners
// hours:
//
//   1. It prints the device build log when compilation fails. clBuildProgram
//      returning CL_BUILD_PROGRAM_FAILURE without you fetching
//      CL_PROGRAM_BUILD_LOG is the difference between a five-second fix and an
//      afternoon of guessing.
//
//   2. It uses event profiling to show WHEN the kernel actually ran, and asserts
//      the timestamps are ordered. Profiling is the only way to see that host
//      transfers and kernel execution are separate costs.
//
// Verification: all 1024 results compared element-by-element against a CPU
// reference, plus a monotonicity check on the profiling timestamps.
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

#define N 1024

// Fetch one profiling timestamp from an event. Returns 0 on failure.
static cl_ulong profTime(cl_event ev, cl_profiling_info what) {
    cl_ulong t = 0;
    if (clGetEventProfilingInfo(ev, what, sizeof(t), &t, NULL) != CL_SUCCESS) return 0;
    return t;
}

int main(void) {
    const char* deviceHint = OCL_DEFAULT_DEVICE;

    // ---- 1. device -------------------------------------------------------
    // Selected by NAME across every platform. platforms[0] on this machine is
    // NVIDIA, so the naive choice would quietly benchmark the wrong GPU.
    cl_device_id device = NULL;
    char deviceName[256] = {0};
    if (ocl_pick_device(deviceHint, CL_DEVICE_TYPE_ALL, &device, deviceName, sizeof(deviceName)) != 0) {
        printf("[FAIL] no device matching \"%s\"\n", deviceHint);
        printf("       Run examples/01-device-query to see what this machine actually has.\n");
        return ocl_report(0);
    }
    ocl_report_device(device);

    // ---- 2. context ------------------------------------------------------
    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context || err != CL_SUCCESS) {
        printf("[FAIL] clCreateContext -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }

    // ---- 3. command queue, with profiling enabled ------------------------
    // CL_QUEUE_PROFILING_ENABLE is what makes clGetEventProfilingInfo return
    // real timestamps instead of CL_PROFILING_INFO_NOT_AVAILABLE.
    cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0 };
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, props, &err);
    if (!queue || err != CL_SUCCESS) {
        printf("[FAIL] clCreateCommandQueueWithProperties -> %d %s\n", err, ocl_err_name(err));
        clReleaseContext(context);
        return ocl_report(0);
    }

    // ---- 4. program, built from a .cl file -------------------------------
    char* source = ocl_read_file("kernels/vector_add.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }

    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, NULL, &err);
    free(source);
    if (!program || err != CL_SUCCESS) {
        printf("[FAIL] clCreateProgramWithSource -> %d %s\n", err, ocl_err_name(err));
        clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }

    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    // Fetch the log whether the build succeeded or not: Intel's driver emits
    // useful warnings even for kernels that compile.
    {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        if (logSz > 1) {
            char* log = (char*)malloc(logSz + 1);
            if (log) {
                clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
                log[logSz] = '\0';
                printf("[build log]\n%s\n", log);
                free(log);
            }
        }
    }
    if (err != CL_SUCCESS) {
        printf("[FAIL] clBuildProgram -> %d %s\n", err, ocl_err_name(err));
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }
    printf("[build] program compiled for %s\n", deviceName);

    cl_kernel kernel = clCreateKernel(program, "vector_add", &err);
    if (!kernel || err != CL_SUCCESS) {
        printf("[FAIL] clCreateKernel -> %d %s\n", err, ocl_err_name(err));
        clReleaseProgram(program); clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report(0);
    }

    // ---- 5. host data ----------------------------------------------------
    float* a = (float*)malloc(N * sizeof(float));
    float* b = (float*)malloc(N * sizeof(float));
    float* c = (float*)malloc(N * sizeof(float));
    if (!a || !b || !c) { printf("[FAIL] host allocation\n"); return ocl_report(0); }
    for (int i = 0; i < N; i++) {
        a[i] = (float)i;
        b[i] = (float)(i * 2);
        c[i] = -1.0f;                       // sentinel, so an unwritten element is obvious
    }

    // ---- 6. device buffers ----------------------------------------------
    cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufB = clCreateBuffer(context, CL_MEM_READ_ONLY,  N * sizeof(float), NULL, &err);
    cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, N * sizeof(float), NULL, &err);
    if (!bufA || !bufB || !bufC) {
        printf("[FAIL] clCreateBuffer -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }

    // ---- 7. enqueue: write, compute, read --------------------------------
    // All three go onto ONE in-order queue, so they execute in submission order
    // without needing explicit event dependencies. examples/07-async-events shows
    // what changes when you want them to overlap instead.
    cl_event evWrite = NULL, evKernel = NULL, evRead = NULL;

    err = clEnqueueWriteBuffer(queue, bufA, CL_FALSE, 0, N * sizeof(float), a, 0, NULL, &evWrite);
    if (err != CL_SUCCESS) printf("[FAIL] write A -> %d %s\n", err, ocl_err_name(err));
    err = clEnqueueWriteBuffer(queue, bufB, CL_FALSE, 0, N * sizeof(float), b, 0, NULL, NULL);
    if (err != CL_SUCCESS) printf("[FAIL] write B -> %d %s\n", err, ocl_err_name(err));

    int n = N;
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufB);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufC);
    clSetKernelArg(kernel, 3, sizeof(int), &n);

    // Global size rounded UP to a multiple of the local size. On an OpenCL 1.2
    // device an unrounded global size is rejected with -54
    // CL_INVALID_WORK_GROUP_SIZE even though the kernel guards its own accesses -
    // so 1024 with local 64 is fine, but 1000 with local 64 would not be.
    size_t localSize = 64;
    size_t globalSize = ocl_round_up((size_t)N, localSize);
    printf("[launch] global=%zu local=%zu (n=%d, rounded up=%s)\n",
           globalSize, localSize, N, globalSize == (size_t)N ? "no change" : "yes");

    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, &evKernel);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clEnqueueNDRangeKernel -> %d %s\n", err, ocl_err_name(err));
        printf("       Check global%%local==0 and local<=CL_DEVICE_MAX_WORK_GROUP_SIZE.\n");
        return ocl_report(0);
    }

    err = clEnqueueReadBuffer(queue, bufC, CL_FALSE, 0, N * sizeof(float), c, 0, NULL, &evRead);
    if (err != CL_SUCCESS) printf("[FAIL] read C -> %d %s\n", err, ocl_err_name(err));

    // Blocking read was CL_FALSE, so nothing is guaranteed until we wait.
    clFinish(queue);

    // ---- 8. verify against a CPU reference -------------------------------
    int bad = 0;
    for (int i = 0; i < N; i++) {
        float ref = (float)i + (float)(i * 2);
        if (c[i] != ref) {
            if (bad < 5) printf("  mismatch i=%d got %f want %f\n", i, c[i], ref);
            bad++;
        }
    }
    printf("[verify] %d/%d elements correct\n", N - bad, N);

    // ---- 9. profiling: when did each stage actually run? -----------------
    // Timestamps are nanoseconds since an unspecified epoch, so only DIFFERENCES
    // and ORDERING are meaningful.
    int profOk = 1;
    if (evKernel) {
        cl_ulong queued  = profTime(evKernel, CL_PROFILING_COMMAND_QUEUED);
        cl_ulong submit  = profTime(evKernel, CL_PROFILING_COMMAND_SUBMIT);
        cl_ulong start   = profTime(evKernel, CL_PROFILING_COMMAND_START);
        cl_ulong end     = profTime(evKernel, CL_PROFILING_COMMAND_END);
        if (!queued || !submit || !start || !end) {
            printf("[profiling] timestamps unavailable\n");
            profOk = 0;
        } else {
            printf("[profiling] kernel queued->submit %llu ns, submit->start %llu ns, execute %llu ns\n",
                   (unsigned long long)(submit - queued),
                   (unsigned long long)(start - submit),
                   (unsigned long long)(end - start));
            // The four stamps must be non-decreasing. A driver that reports them out
            // of order would make every bandwidth number derived from them fiction.
            if (!(queued <= submit && submit <= start && start <= end)) {
                printf("[profiling] timestamps NOT monotonic: %llu %llu %llu %llu\n",
                       (unsigned long long)queued, (unsigned long long)submit,
                       (unsigned long long)start, (unsigned long long)end);
                profOk = 0;
            } else {
                printf("[profiling] timestamps monotonic: OK\n");
            }
        }
    } else {
        profOk = 0;
    }

    // ---- 10. release, newest first ---------------------------------------
    if (evWrite)  clReleaseEvent(evWrite);
    if (evKernel) clReleaseEvent(evKernel);
    if (evRead)   clReleaseEvent(evRead);
    clReleaseMemObject(bufA);
    clReleaseMemObject(bufB);
    clReleaseMemObject(bufC);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);
    free(a); free(b); free(c);

    int pass = (bad == 0) && profOk;
    printf("\nassert all %d elements match CPU reference : %s\n", N, bad == 0 ? "OK" : "FAILED");
    printf("assert profiling timestamps monotonic      : %s\n", profOk ? "OK" : "FAILED");
    return ocl_report(pass);
}
