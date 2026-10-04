// Fixture: the corrected matrix-multiply kernel.
//
// The only change from matmul_bad.cl is the address-space qualifier on the two
// input pointers: __const float* becomes __global const float*. "const" is the
// ordinary C qualifier and stays; what was missing is the address space, which
// OpenCL C requires on every kernel pointer argument.
__kernel void matrix_mul(__global const float* A,
                         __global const float* B,
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
