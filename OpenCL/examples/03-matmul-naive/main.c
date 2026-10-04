// examples/03-matmul-naive - a 2D NDRange, and how to round it correctly.
//
// Vector addition was one-dimensional, which hides a trap. In two dimensions the
// global size must be rounded up to a multiple of the local size IN EVERY
// DIMENSION, and the kernel must guard every access, because rounding up means
// launching work-items that fall outside the matrix.
//
// On an OpenCL 1.2 device getting this wrong does not produce wrong numbers - it
// produces -54 CL_INVALID_WORK_GROUP_SIZE and no result at all, which is confusing
// because the error name suggests a work-group SIZE problem rather than a
// divisibility problem.
//
// Verification: 256x256 product compared element-by-element against a double
// precision CPU reference.
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

#define WIDTH 256

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

    char* source = ocl_read_file("kernels/matmul_naive.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }
    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, NULL, &err);
    free(source);
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

    cl_kernel kernel = clCreateKernel(program, "matmul_naive", &err);
    if (!kernel) { printf("[FAIL] clCreateKernel -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    const size_t count = (size_t)WIDTH * WIDTH;
    const size_t bytes = count * sizeof(float);
    float* A = (float*)malloc(bytes);
    float* B = (float*)malloc(bytes);
    float* C = (float*)malloc(bytes);
    if (!A || !B || !C) { printf("[FAIL] host allocation\n"); return ocl_report(0); }

    // Deterministic, non-trivial values: a spread of magnitudes and signs so that a
    // transposed index or an off-by-one in the row/column stride shows up loudly.
    for (int r = 0; r < WIDTH; r++) {
        for (int c = 0; c < WIDTH; c++) {
            A[r * WIDTH + c] = (float)((r * 7 + c * 3) % 23) - 11.0f;
            B[r * WIDTH + c] = (float)((r * 5 + c * 11) % 19) - 9.0f;
        }
    }

    cl_mem bufA = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, bytes, A, &err);
    cl_mem bufB = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, bytes, B, &err);
    cl_mem bufC = clCreateBuffer(context, CL_MEM_WRITE_ONLY, bytes, NULL, &err);
    if (!bufA || !bufB || !bufC) { printf("[FAIL] clCreateBuffer -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    int width = WIDTH;
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &bufA);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &bufB);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &bufC);
    clSetKernelArg(kernel, 3, sizeof(int), &width);

    // 2D launch: dimension 0 is the column (fast axis), dimension 1 is the row.
    // Both global sizes are rounded up independently.
    size_t local[2]  = { 16, 16 };              // 256 work-items, exactly the iGPU's max
    size_t global[2] = { ocl_round_up(WIDTH, local[0]), ocl_round_up(WIDTH, local[1]) };
    printf("[launch] global={%zu,%zu} local={%zu,%zu} for a %dx%d matrix\n",
           global[0], global[1], local[0], local[1], WIDTH, WIDTH);

    // CL_KERNEL_WORK_GROUP_SIZE is the per-kernel limit and can be lower than the
    // device limit. Checking it before launching turns a runtime -54 into a message
    // that names the real constraint.
    size_t kernelMax = 0;
    clGetKernelWorkGroupInfo(kernel, device, CL_KERNEL_WORK_GROUP_SIZE, sizeof(kernelMax), &kernelMax, NULL);
    printf("[launch] CL_KERNEL_WORK_GROUP_SIZE=%zu (local product=%zu)\n", kernelMax, local[0] * local[1]);
    if (kernelMax && local[0] * local[1] > kernelMax) {
        printf("[FAIL] local work group %zu exceeds kernel limit %zu\n", local[0] * local[1], kernelMax);
        return ocl_report(0);
    }

    err = clEnqueueNDRangeKernel(queue, kernel, 2, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("[FAIL] clEnqueueNDRangeKernel -> %d %s\n", err, ocl_err_name(err));
        return ocl_report(0);
    }
    err = clEnqueueReadBuffer(queue, bufC, CL_TRUE, 0, bytes, C, 0, NULL, NULL);
    if (err != CL_SUCCESS) { printf("[FAIL] read C -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    // CPU reference in double, so the comparison tests the GPU's arithmetic rather
    // than reproducing its rounding.
    int bad = 0;
    double maxAbsErr = 0.0;
    for (int r = 0; r < WIDTH; r++) {
        for (int c = 0; c < WIDTH; c++) {
            double ref = 0.0;
            for (int k = 0; k < WIDTH; k++)
                ref += (double)A[r * WIDTH + k] * (double)B[k * WIDTH + c];
            double got = (double)C[r * WIDTH + c];
            double diff = got - ref; if (diff < 0) diff = -diff;
            if (diff > maxAbsErr) maxAbsErr = diff;
            // Tolerance scales with the magnitude of the result: 256 products of
            // values up to ~12 accumulate to the thousands, where float spacing is
            // already well above 1e-6.
            double tol = 1e-2 * ((ref < 0 ? -ref : ref) + 1.0);
            if (diff > tol) {
                if (bad < 5) printf("  mismatch [%d,%d] got %f want %f (diff %g)\n", r, c, got, ref, diff);
                bad++;
            }
        }
    }
    printf("[verify] %d/%d elements within tolerance, max abs err %.3e\n",
           (int)count - bad, (int)count, maxAbsErr);

    clReleaseMemObject(bufA); clReleaseMemObject(bufB); clReleaseMemObject(bufC);
    clReleaseKernel(kernel); clReleaseProgram(program);
    clReleaseCommandQueue(queue); clReleaseContext(context);
    free(A); free(B); free(C);

    int pass = (bad == 0);
    printf("\nassert all %d elements match the CPU reference : %s\n", (int)count, pass ? "OK" : "FAILED");
    return ocl_report(pass);
}
