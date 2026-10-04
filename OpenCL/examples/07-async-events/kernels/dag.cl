// Kernels for the event-dependency DAG in examples/07-async-events.
//
// Three trivially different operations, so that the interesting part of the example
// stays where it belongs - on the host, in the event graph. Each kernel takes an
// explicit n and guards, because the host rounds the global size up to a multiple of
// the local size.

__kernel void scale_kernel(__global const float* in,
                           __global float* out,
                           const float k,
                           const int n) {
    int i = get_global_id(0);
    if (i >= n) return;
    out[i] = in[i] * k;
}

__kernel void offset_kernel(__global const float* in,
                            __global float* out,
                            const float k,
                            const int n) {
    int i = get_global_id(0);
    if (i >= n) return;
    out[i] = in[i] + k;
}

__kernel void add_kernel(__global const float* a,
                         __global const float* b,
                         __global float* out,
                         const int n) {
    int i = get_global_id(0);
    if (i >= n) return;
    out[i] = a[i] + b[i];
}
