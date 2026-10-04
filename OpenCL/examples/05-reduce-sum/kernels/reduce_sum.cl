// Sum reduction: three kernels, two of them deliberately kept to show a failure.
//
// A reduction cannot be written as "one work-item per element" - the whole point is
// that work-items must COMBINE their values, and that requires local memory,
// barriers, and then a second pass to combine the per-work-group results.

// ---------------------------------------------------------------------------
// The original tutorial's kernel, reproduced unchanged so the defect is visible.
//
// Two things are wrong with it, and they are independent:
//
//   1. It assumes the work-group size is a power of two. Halving the stride from
//      localSize/2 only visits every element when localSize is 2^k. At
//      localSize=100 the strides run 50, 25, 12, 6, 3, 1 and fold 64 of the 100
//      values into temp[0]; the remaining 36 are stranded - 32 in temp[2] and 4 in
//      temp[24], which the stride=12 round skips because reaching slot 24 needs
//      localId=12 and the guard is localId<12. The kernel returns a plausible
//      looking number that is simply wrong.
//
//   2. It writes output[get_group_id(0)], i.e. ONE PARTIAL SUM PER WORK-GROUP.
//      That is not the total. With N=1000 and 10 work-groups you get an array of
//      10 numbers and still need a second reduction to combine them. The original
//      presented this as the answer.
// ---------------------------------------------------------------------------
__kernel void reduce_partial_naive(__global const float* input,
                                   __global float* output,
                                   __local float* temp,
                                   const int n) {
    int localId   = get_local_id(0);
    int globalId  = get_global_id(0);
    int localSize = get_local_size(0);

    temp[localId] = (globalId < n) ? input[globalId] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    // Power-of-two assumption. Wrong for localSize=100.
    for (int stride = localSize / 2; stride > 0; stride >>= 1) {
        if (localId < stride) {
            temp[localId] += temp[localId + stride];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (localId == 0) {
        output[get_group_id(0)] = temp[0];   // a partial, not the total
    }
}

// ---------------------------------------------------------------------------
// The corrected per-work-group reduction.
//
// Sequential addressing: at step s, work-item t folds element 2*s*t + s into
// element 2*s*t. Doubling s each round means every index is eventually a source
// exactly once, for ANY work-group size, not just powers of two.
//
// The inner guard is what makes non-power-of-two sizes safe. `index < localSize`
// selects the work-items that own a live accumulator; `index + s < localSize`
// stops the last one from reading past the end of the tile on the final rounds.
// Dropping either guard gives a wrong total rather than a crash.
// ---------------------------------------------------------------------------
__kernel void reduce_partial_safe(__global const float* input,
                                  __global float* output,
                                  __local float* temp,
                                  const int n) {
    int localId   = get_local_id(0);
    int globalId  = get_global_id(0);
    int localSize = get_local_size(0);

    temp[localId] = (globalId < n) ? input[globalId] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    for (int s = 1; s < localSize; s <<= 1) {
        int index = 2 * s * localId;
        if (index < localSize) {
            if (index + s < localSize) {
                temp[index] += temp[index + s];
            }
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    if (localId == 0) {
        output[get_group_id(0)] = temp[0];
    }
}

// ---------------------------------------------------------------------------
// Second pass: fold the array of per-work-group partials into one total.
//
// Runs as a SINGLE work-group, so after it partials[0] holds the answer. The host
// pads the partials array up to a power of two and zero-fills the padding, which
// keeps this kernel trivial; reduce_partial_safe would also work unpadded.
// ---------------------------------------------------------------------------
__kernel void reduce_final(__global float* partials,
                           __local float* temp,
                           const int numPartials) {
    int localId   = get_local_id(0);
    int localSize = get_local_size(0);

    temp[localId] = (localId < numPartials) ? partials[localId] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    for (int stride = localSize / 2; stride > 0; stride >>= 1) {
        if (localId < stride) {
            temp[localId] += temp[localId + stride];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    // localSize here is a power of two by construction, so the simple stride loop
    // is correct. That is a deliberate, documented precondition - not luck.
    if (localId == 0) {
        partials[0] = temp[0];
    }
}
