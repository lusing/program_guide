// kernel.clcpp - OpenCL C++ 内核
kernel void vector_add(global const float* a,
                       global const float* b,
                       global float* c,
                       const int n) {
    int idx = get_global_id(0);
    if (idx < n) {
        c[idx] = a[idx] + b[idx];
    }
}
