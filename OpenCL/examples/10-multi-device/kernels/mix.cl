// examples/10-multi-device/kernels/mix.cl
//
// A deliberately INTEGER-ONLY workload, and the reason is the point of this
// example rather than an avoidance of the interesting case.
//
// This kernel is compiled three separate times by three separate vendor
// compilers - NVIDIA's, Intel NEO's and Intel's CPU runtime - and the host then
// compares all three outputs against ONE C reference, bit for bit. Floating
// point would make that comparison a statement about the vendors rather than
// about the sharding: contraction into an FMA, a different division sequence or
// a transcendentals implementation would each move the last bit, and the example
// would fail for a reason that has nothing to do with whether the shards were
// reassembled correctly.
//
// Unsigned integer arithmetic has exactly one conforming answer, so a mismatch
// here can only mean the sharding is wrong. That is the property this example
// needs, because "did the pieces go back together in the right order" is the
// thing it is actually testing.
//
// The work is a 32-round integer hash (lowbias32). It is compute-bound rather
// than memory-bound on purpose: a memory-bound kernel would measure three memory
// buses and tell us nothing about three compute engines.
//
// OpenCL C 1.2. No 2.x features, so all three devices compile it unchanged.

__kernel void mix(__global const unsigned int* in,
                  __global unsigned int* out,
                  unsigned int base,
                  unsigned int n)
{
    unsigned int i = get_global_id(0);

    // Rounding the global size up to a multiple of the local size launches
    // work-items past the end of this shard. They must not read in[] or write
    // out[], and the guard has to be here rather than on the host: the host
    // cannot round up without also over-launching. See docs/06 section 6.5.
    if (i >= n) return;

    // Folding the global base index in is what makes a mis-sharded result
    // detectable. If the host assigned the wrong base to a shard, every element
    // of that shard comes out different, not merely some of them.
    unsigned int x = in[i] ^ (base + i);

    for (int r = 0; r < 32; r++) {
        x ^= x >> 16;
        x *= 0x7feb352du;
        x ^= x >> 15;
        x *= 0x846ca68bu;
        x ^= x >> 16;

        // The round counter has to enter the value. Without it the loop body is
        // idempotent after the first pass in the sense that a compiler is free to
        // look for a shortcut, and the measurement stops being about work done.
        x += (unsigned int)r;
    }

    out[i] = x;
}
