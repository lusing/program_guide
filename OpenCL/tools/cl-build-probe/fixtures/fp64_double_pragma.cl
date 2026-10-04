// Same kernel as fp64_double.cl, with the extension pragma the old tutorial
// omitted. Comparing the two build logs shows whether the pragma changes
// anything on this driver.
#pragma OPENCL EXTENSION cl_khr_fp64 : enable

__kernel void double_dot(__global const double* a,
                         __global const double* b,
                         __global double* c,
                         const int n) {
    int i = get_global_id(0);
    if (i < n) c[i] = a[i] * b[i];
}
