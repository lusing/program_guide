// Tiled matrix multiply using __local memory and barriers.
//
// The idea: instead of every work-item re-reading a whole row and column from
// global memory, a work-group cooperatively loads a TILE x TILE block of A and of B
// into on-chip local memory once, then every work-item in the group reuses those
// blocks TILE times. Global traffic drops by roughly a factor of TILE.
//
// TILE is a compile-time macro so the host can build the same source at several
// sizes and show what happens at each. examples/04 does exactly that: 32 fails,
// 16 and 8 succeed.
#ifndef TILE
#define TILE 16
#endif

__kernel void matmul_tiled(__global const float* A,
                           __global const float* B,
                           __global float* C,
                           const int width) {
    // Two tiles live in local memory for the whole work-group. At TILE=16 that is
    // 2 * 16 * 16 * 4 = 2048 bytes; at TILE=32 it is 8192 bytes. Both fit the iGPU's
    // 64 KB, so local memory SIZE is not what breaks TILE=32 - the work-item count
    // is. See the comment in the host program.
    __local float tileA[TILE][TILE];
    __local float tileB[TILE][TILE];

    int col = get_global_id(0);
    int row = get_global_id(1);
    int localCol = get_local_id(0);
    int localRow = get_local_id(1);

    float sum = 0.0f;
    int numTiles = (width + TILE - 1) / TILE;

    for (int t = 0; t < numTiles; t++) {
        int aCol = t * TILE + localCol;
        int bRow = t * TILE + localRow;

        // Boundary guard, and it is load-bearing. The host rounds the global size up
        // to a multiple of TILE, so some work-items have row or col past the matrix.
        // Without this guard those work-items read out of bounds and write garbage
        // INTO THE SHARED TILE - which then corrupts every other work-item in the
        // group, not just themselves. A missing guard here produces wrong numbers
        // across a whole tile, which is much harder to diagnose than a crash.
        tileA[localRow][localCol] = (row < width && aCol < width) ? A[row * width + aCol] : 0.0f;
        tileB[localRow][localCol] = (bRow < width && col < width) ? B[bRow * width + col] : 0.0f;

        // Every work-item must finish filling the tile before any of them reads it.
        barrier(CLK_LOCAL_MEM_FENCE);

        for (int i = 0; i < TILE; i++) {
            sum += tileA[localRow][i] * tileB[i][localCol];
        }

        // And nobody may start overwriting the tile with the next block until every
        // work-item has finished reading the current one. Omitting this second
        // barrier is a classic race that fails intermittently.
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    // Guard the store too: work-items created only to pad the global size up to a
    // multiple of the local size must not write.
    if (row < width && col < width) {
        C[row * width + col] = sum;
    }
}
