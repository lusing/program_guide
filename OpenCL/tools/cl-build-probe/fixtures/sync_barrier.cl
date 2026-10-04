// Does the OpenCL C 2.0 spelling of the work-group barrier compile on a device
// whose CL_DEVICE_OPENCL_C_VERSION says "OpenCL C 1.2"? The old tutorial listed
// only barrier(), which is deprecated as of OpenCL C 2.0 in favour of
// work_group_barrier(). Two kernels, one spelling each, so the build log says
// which of the two the device rejected.
__kernel void uses_old_barrier(__global float* out) {
    __local float tile[256];
    int lid = get_local_id(0);
    tile[lid] = (float)lid;
    barrier(CLK_LOCAL_MEM_FENCE);
    out[get_global_id(0)] = tile[255 - lid];
}

__kernel void uses_work_group_barrier(__global float* out) {
    __local float tile[256];
    int lid = get_local_id(0);
    tile[lid] = (float)lid;
    work_group_barrier(CLK_LOCAL_MEM_FENCE);
    out[get_global_id(0)] = tile[255 - lid];
}
