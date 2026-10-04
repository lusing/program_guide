// to_global() applied to a pointer from each of the three address spaces.
//
// The defined behaviour is one line: given a generic pointer that points into
// global memory, to_global returns the same pointer typed __global. That is the
// only case this kernel asserts anything about.
//
// The other two cases are NOT asserted, and the reason is a measurement rather
// than a guess about the spec. Handing to_global a pointer to PRIVATE or LOCAL
// memory is not something the three devices on this machine agree about: the two
// GPUs return NULL and the i7 CPU device returns the pointer unchanged. So the
// kernel records which of three outcomes happened and lets the host print it.
// Encoding the outcome instead of a pass/fail bit is what makes the disagreement
// visible rather than turning it into a mysterious wrong number.
//
//   1 -> returned NULL
//   2 -> returned the same pointer, i.e. an identity conversion
//   3 -> returned something else entirely
//
// Requires -cl-std=CL2.0. Without it, both Intel devices default to
// __OPENCL_C_VERSION__ 120 and to_global is not declared at all - the error reads
// "implicit declaration of function 'to_global' is invalid in OpenCL", which
// sounds like "this device cannot do it" and is really "you never asked for the
// level that has it".
//
// One word out per work-item: bits 0-1 classify the global pointer, bits 2-3 the
// private one, bits 4-5 the local one.

static unsigned int classify(unsigned int* p)
{
    __global unsigned int* g = to_global(p);
    if (g == (__global unsigned int*)0) return 1u;
    // Compared in the GENERIC address space. Converting the result back to a
    // generic pointer is an implicit conversion and is allowed; comparing a
    // __global pointer to a generic one directly is not.
    if ((unsigned int*)g == p)          return 2u;
    return 3u;
}

__kernel void to_global_probe(__global unsigned int* out, unsigned int n)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;

    // All three source pointers, one per address space.
    __global unsigned int* g = out + i;

    unsigned int privateVal = i + 1u;

    __local unsigned int loc;
    if (get_local_id(0) == 0) loc = 0xABCDu;
    barrier(CLK_LOCAL_MEM_FENCE);

    unsigned int word = 0u;
    word |= classify(g)           << 0;
    word |= classify(&privateVal) << 2;
    word |= classify(&loc)        << 4;

    // Written last: classify(&loc) forced the work-group to wait for lane 0's
    // store, and out[i] is itself in global memory that g points into.
    out[i] = word;
}
