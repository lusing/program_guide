__kernel void matrix_mul_optimized(__const float* A,
                                   __const float* B,
                                   __global float* C,
                                   const int width) {
    // 本地内存用于缓存
    __local float tileA[32][32];
    __local float tileB[32][32];

    int row = get_global_id(1);
    int col = get_global_id(0);
    int localRow = get_local_id(1);
    int localCol = get_local_id(0);

    float sum = 0.0f;

    // 分块处理
    int numTiles = (width + 31) / 32;

    for (int t = 0; t < numTiles; t++) {
        // 加载 tile 到本地内存
        tileA[localRow][localCol] = A[row * width + t * 32 + localCol];
        tileB[localRow][localCol] = B[(t * 32 + localRow) * width + col];

        barrier(CLK_LOCAL_MEM_FENCE);

        // 计算部分乘积
        for (int i = 0; i < 32; i++) {
            sum += tileA[localRow][i] * tileB[i][localCol];
        }

        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (row < width && col < width) {
        C[row * width + col] = sum;
    }
}
