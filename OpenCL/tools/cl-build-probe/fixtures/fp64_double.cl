// The old tutorial said double "需扩展支持" without naming the extension or the
// pragma. cl_khr_fp64 is the extension; all three devices on this machine list it.
// This fixture uses double WITHOUT the pragma, to measure whether the pragma is
// actually required when the device defaults to OpenCL C 1.2.
__kernel void double_dot(__global const double* a,
                         __global const double* b,
                         __global double* c,
                         const int n) {
    int i = get_global_id(0);
    if (i < n) c[i] = a[i] * b[i];
}
