// Fixture: the matrix-multiply kernel EXACTLY as the original
// OpenCL_Windows_Tutorial.md presented it (its "示例 1").
//
// __const is not an OpenCL C keyword. The compiler therefore sees the pointer as
// having no address space and rejects it. Measured log on the Intel UHD 630:
//   error: pointer arguments to kernel functions must reside in '__global',
//          '__constant' or '__local' address space
//
// This file exists so the failure is reproducible on demand rather than being a
// claim in prose. See matmul_good.cl for the corrected version.
__kernel void matrix_mul(__const float* A,
                         __const float* B,
                         __global float* C,
                         const int width) {
    int row = get_global_id(1);
    int col = get_global_id(0);

    if (row < width && col < width) {
        float sum = 0.0f;
        for (int i = 0; i < width; i++) {
            sum += A[row * width + i] * B[i * width + col];
        }
        C[row * width + col] = sum;
    }
}
