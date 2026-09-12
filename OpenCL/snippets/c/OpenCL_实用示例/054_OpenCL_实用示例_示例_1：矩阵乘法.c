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
