// The simplest possible kernel: one work-item per element, no interaction between
// work-items, no local memory, no barriers.
//
// Written against OpenCL C 1.2 on purpose. Every device on this machine accepts
// 1.2, so this kernel is the portable baseline; later examples raise the level only
// where a feature genuinely needs it.
//
// Note the address-space qualifier on every pointer argument: __global. A kernel
// pointer with no address space is a compile error, which is exactly what the
// original tutorial's __const float* arguments were.
__kernel void vector_add(__global const float* a,
                         __global const float* b,
                         __global float* c,
                         const int n) {
    int i = get_global_id(0);
    // Bounds check. The host rounds the global size up to a multiple of the local
    // size, which means some work-items land past n and must not write.
    if (i < n) {
        c[i] = a[i] + b[i];
    }
}
