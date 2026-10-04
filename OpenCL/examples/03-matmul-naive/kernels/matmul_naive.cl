// Naive matrix multiply: one work-item computes one element of C.
//
// Every work-item re-reads a whole row of A and a whole column of B, so this does
// width multiplies per output element and is memory-bound. That inefficiency is the
// entire reason examples/04-matmul-tiled exists.
//
// Two details matter here:
//   - pointer arguments carry __global AND const. __global is the address space and
//     is mandatory; const is the ordinary C qualifier. The original tutorial wrote
//     __const, which is neither, and the kernel did not compile on any device.
//   - every access is guarded by (row < width && col < width) because the host
//     rounds the 2D global size up to a multiple of the local size.
__kernel void matmul_naive(__global const float* A,
                           __global const float* B,
                           __global float* C,
                           const int width) {
    int col = get_global_id(0);
    int row = get_global_id(1);

    if (row < width && col < width) {
        float sum = 0.0f;
        for (int k = 0; k < width; k++) {
            sum += A[row * width + k] * B[k * width + col];
        }
        C[row * width + col] = sum;
    }
}
