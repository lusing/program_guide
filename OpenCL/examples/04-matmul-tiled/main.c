// examples/04-matmul-tiled - local memory, barriers, and the two limits that bite.
//
// This example is built around failures on purpose. A tiled matmul looks like it
// should work at any tile size, and the two reasons it does not are among the most
// confusing errors in OpenCL because both report the SAME code,
// -54 CL_INVALID_WORK_GROUP_SIZE, for completely different causes:
//
//   Limit 1 - the work-group is too big.
//     A TILE x TILE work-group has TILE*TILE work-items. At TILE=32 that is 1024.
//     The Intel UHD 630 caps CL_DEVICE_MAX_WORK_GROUP_SIZE at 256, so the launch is
//     rejected. Note that local MEMORY is not the problem: two 32x32 float tiles are
//     8 KB against a 64 KB budget. It is the work-item count.
//
//   Limit 2 - the global size is not a multiple of the local size.
//     On an OpenCL 1.2 device clEnqueueNDRangeKernel requires
//     global_work_size % local_work_size == 0 in every dimension. A 100x100 matrix
//     with a 16x16 local size fails with -54 EVEN THOUGH the kernel guards every one
//     of its loads and stores. The kernel is innocent; the launch geometry is not.
//
// The fix for limit 2 has two halves and neither works alone: the HOST rounds the
// global size up to a multiple of the local size, and the KERNEL bounds-checks before
// reading or writing, because rounding up creates work-items that fall outside the
// matrix. Those extra work-items share local memory with the real ones, so an
// unguarded load does not merely read garbage - it writes garbage into the shared
// tile and corrupts its whole work-group.
//
// Five cases run below. Two are EXPECTED TO FAIL. The example passes only if each
// case does what it is documented to do, so a driver change that silently starts
// accepting TILE=32 would be reported rather than hidden.
//
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

// Outcome of one tiled run, so the caller can distinguish "rejected at launch"
// from "ran but produced wrong numbers".
typedef struct {
    cl_int launchErr;      // CL_SUCCESS if the launch was accepted
    int    compared;       // elements compared
    int    wrong;          // elements outside tolerance
    double maxAbsErr;
    size_t kernelMaxWG;    // CL_KERNEL_WORK_GROUP_SIZE for this build
} TiledRun;

// Build the tiled kernel at a given TILE, launch it over a width x width matrix,
// and compare against a double-precision CPU reference.
//
// roundGws=1 rounds the global size up to a multiple of TILE (the correct thing to
// do). roundGws=0 passes the raw width, which demonstrates limit 2.
static int runTiled(cl_context context, cl_command_queue queue, cl_device_id device,
                    const char* source, int width, int tile, int roundGws, TiledRun* out) {
    out->launchErr = CL_SUCCESS;
    out->compared = 0;
    out->wrong = 0;
    out->maxAbsErr = 0.0;
    out->kernelMaxWG = 0;

    cl_int err = CL_SUCCESS;
    char opts[64];
    sprintf(opts, "-DTILE=%d", tile);

    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, NULL, &err);
    if (!program) { printf("    [FAIL] clCreateProgramWithSource -> %s\n", ocl_err_name(err)); return -1; }

    err = clBuildProgram(program, 1, &device, opts, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        char* log = (char*)malloc(logSz + 1);
        if (log) {
            clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
            log[logSz] = '\0';
            printf("    [build log]\n%s\n", log);
            free(log);
        }
        printf("    [FAIL] clBuildProgram(%s) -> %s\n", opts, ocl_err_name(err));
        clReleaseProgram(program);
        return -1;
    }

    cl_kernel kernel = clCreateKernel(program, "matmul_tiled", &err);
    if (!kernel) { printf("    [FAIL] clCreateKernel -> %s\n", ocl_err_name(err)); clReleaseProgram(program); return -1; }

    clGetKernelWorkGroupInfo(kernel, device, CL_KERNEL_WORK_GROUP_SIZE,
                             sizeof(out->kernelMaxWG), &out->kernelMaxWG, NULL);

    const size_t count = (size_t)width * width;
    const size_t bytes = count * sizeof(float);
    float* A = (float*)malloc(bytes);
    float* B = (float*)malloc(bytes);
    float* C = (float*)malloc(bytes);
    if (!A || !B || !C) { free(A); free(B); free(C); clReleaseKernel(kernel); clReleaseProgram(program); return -1; }

    for (int r = 0; r < width; r++)
        for (int c = 0; c < width; c++) {
            A[r * width + c] = (float)((r * 7 + c * 3) % 23) - 11.0f;
            B[r * width + c] = (float)((r * 5 + c * 11) % 19) - 9.0f;
        }

    cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, bytes, A, &err);
    cl_mem bufB = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, bytes, B, &err);
    cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, bytes, NULL, &err);
    if (!bufA || !bufB || !bufC) {
        printf("    [FAIL] clCreateBuffer -> %s\n", ocl_err_name(err));
        free(A); free(B); free(C); clReleaseKernel(kernel); clReleaseProgram(program);
        return -1;
    }

    clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufB);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufC);
    clSetKernelArg(kernel, 3, sizeof(int), &width);

    size_t local[2] = { (size_t)tile, (size_t)tile };
    size_t global[2];
    if (roundGws) {
        global[0] = ocl_round_up((size_t)width, local[0]);
        global[1] = ocl_round_up((size_t)width, local[1]);
    } else {
        global[0] = (size_t)width;
        global[1] = (size_t)width;
    }
    printf("    %s global={%zu,%zu} local={%zu,%zu}=%zu work-items, CL_KERNEL_WORK_GROUP_SIZE=%zu\n",
           opts, global[0], global[1], local[0], local[1], local[0] * local[1], out->kernelMaxWG);

    err = clEnqueueNDRangeKernel(queue, kernel, 2, NULL, global, local, 0, NULL, NULL);
    out->launchErr = err;
    if (err != CL_SUCCESS) {
        printf("    launch rejected -> %d %s\n", err, ocl_err_name(err));
        clReleaseMemObject(bufA); clReleaseMemObject(bufB); clReleaseMemObject(bufC);
        free(A); free(B); free(C);
        clReleaseKernel(kernel); clReleaseProgram(program);
        return 0;   // a rejected launch is a legitimate, informative outcome
    }

    err = clEnqueueReadBuffer(queue, bufC, CL_TRUE, 0, bytes, C, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("    [FAIL] read C -> %s\n", ocl_err_name(err));
        clReleaseMemObject(bufA); clReleaseMemObject(bufB); clReleaseMemObject(bufC);
        free(A); free(B); free(C);
        clReleaseKernel(kernel); clReleaseProgram(program);
        return -1;
    }

    out->compared = (int)count;
    for (int r = 0; r < width; r++) {
        for (int c = 0; c < width; c++) {
            double ref = 0.0;
            for (int k = 0; k < width; k++)
                ref += (double)A[r * width + k] * (double)B[k * width + c];
            double got = (double)C[r * width + c];
            double diff = got - ref; if (diff < 0) diff = -diff;
            if (diff > out->maxAbsErr) out->maxAbsErr = diff;
            double tol = 1e-2 * ((ref < 0 ? -ref : ref) + 1.0);
            if (diff > tol) {
                if (out->wrong < 3) printf("    mismatch [%d,%d] got %f want %f\n", r, c, got, ref);
                out->wrong++;
            }
        }
    }
    printf("    ran: %d/%d within tolerance, max abs err %.3e\n",
           out->compared - out->wrong, out->compared, out->maxAbsErr);

    clReleaseMemObject(bufA); clReleaseMemObject(bufB); clReleaseMemObject(bufC);
    free(A); free(B); free(C);
    clReleaseKernel(kernel); clReleaseProgram(program);
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

    size_t deviceMaxWG = 0;
    clGetDeviceInfo(device, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(deviceMaxWG), &deviceMaxWG, NULL);

    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context) { printf("[FAIL] clCreateContext -> %s\n", ocl_err_name(err)); return ocl_report(0); }
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, NULL, &err);
    if (!queue) { printf("[FAIL] clCreateCommandQueue -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    char* source = ocl_read_file("kernels/matmul_tiled.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }

    int failures = 0;

    // ---- Case A: TILE=32 on a 256x256 matrix. EXPECTED TO FAIL. -----------
    printf("\n=== case A: width=256 TILE=32, global size rounded (expect launch rejection) ===\n");
    printf("    32*32 = 1024 work-items per group; this device caps groups at %zu.\n", deviceMaxWG);
    printf("    Local memory is NOT the constraint: two 32x32 float tiles are 8192 B.\n");
    {
        TiledRun r;
        if (runTiled(context, queue, device, source, 256, 32, 1, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (r.launchErr == CL_INVALID_WORK_GROUP_SIZE) {
            printf("    as documented: rejected with -54 CL_INVALID_WORK_GROUP_SIZE\n");
        } else if (r.launchErr == CL_SUCCESS) {
            // Not a bug in the example - it means this device allows 1024-wide groups
            // (the CPU device does, at 8192). Report it rather than pretending.
            printf("    NOTE: this device accepted the launch (limit is %zu, not 256), %d/%d correct\n",
                   deviceMaxWG, r.compared - r.wrong, r.compared);
            if (r.wrong) { printf("    but the values were wrong\n"); failures++; }
        } else {
            printf("    UNEXPECTED error code %d %s\n", r.launchErr, ocl_err_name(r.launchErr));
            failures++;
        }
    }

    // ---- Case B: TILE=16. 16*16 = 256, exactly the iGPU's cap. -----------
    printf("\n=== case B: width=256 TILE=16, global size rounded (expect pass) ===\n");
    {
        TiledRun r;
        if (runTiled(context, queue, device, source, 256, 16, 1, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong values\n", r.wrong); failures++;
        } else {
            printf("    as documented: accepted and numerically correct\n");
        }
    }

    // ---- Case C: TILE=8. 64 work-items, well under any cap. --------------
    printf("\n=== case C: width=256 TILE=8, global size rounded (expect pass) ===\n");
    {
        TiledRun r;
        if (runTiled(context, queue, device, source, 256, 8, 1, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong values\n", r.wrong); failures++;
        } else {
            printf("    as documented: accepted and numerically correct\n");
        }
    }

    // ---- Case D: width=100, TILE=16, global size NOT rounded. EXPECTED TO FAIL.
    printf("\n=== case D: width=100 TILE=16, global size NOT rounded (expect launch rejection) ===\n");
    printf("    100 %% 16 = %d, so the geometry is not divisible even though the kernel\n", 100 % 16);
    printf("    guards every load and store. The kernel is not the problem.\n");
    {
        TiledRun r;
        if (runTiled(context, queue, device, source, 100, 16, 0, &r) != 0) {
            printf("    UNEXPECTED: harness error\n"); failures++;
        } else if (r.launchErr == CL_INVALID_WORK_GROUP_SIZE) {
            printf("    as documented: rejected with -54 for a divisibility reason\n");
        } else if (r.launchErr == CL_SUCCESS) {
            // OpenCL 2.0+ devices may accept a non-divisible global size. Say so.
            printf("    NOTE: this device accepted a non-divisible global size, %d/%d correct\n",
                   r.compared - r.wrong, r.compared);
            if (r.wrong) { printf("    but the values were wrong\n"); failures++; }
        } else {
            printf("    UNEXPECTED error code %d %s\n", r.launchErr, ocl_err_name(r.launchErr));
            failures++;
        }
    }

    // ---- Case E: width=100, TILE=16, global size rounded. The fix. -------
    printf("\n=== case E: width=100 TILE=16, global size rounded up to 112 (expect pass) ===\n");
    printf("    This is case D with the host-side fix applied. It only works because the\n");
    printf("    kernel also guards its loads and stores - the padding work-items share\n");
    printf("    local memory with real ones.\n");
    {
        TiledRun r;
        if (runTiled(context, queue, device, source, 100, 16, 1, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong values - the boundary guard is not working\n", r.wrong);
            failures++;
        } else {
            printf("    as documented: accepted and numerically correct\n");
        }
    }

    free(source);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    printf("\n=== summary ===\n");
    printf("device %s, CL_DEVICE_MAX_WORK_GROUP_SIZE=%zu\n", deviceName, deviceMaxWG);
    printf("case A TILE=32            : launch rejection is the documented outcome\n");
    printf("case B TILE=16            : pass\n");
    printf("case C TILE=8             : pass\n");
    printf("case D width=100 unrounded: launch rejection is the documented outcome\n");
    printf("case E width=100 rounded  : pass\n");
    printf("unexpected outcomes       : %d\n", failures);

    return ocl_report(failures == 0);
}
