// Fixture: the generic address space via to_global(), an OpenCL 2.0 language feature.
//
// MEASURED RESULT (2026-09-17, -cl-std=CL2.0): this builds AND runs correctly
// (256/256 values) on ALL THREE devices on this machine, including both GPUs that
// advertise only "OpenCL C 1.2".
//
// That is the real lesson, and it is the opposite of what the advertised version
// string suggests: CL_DEVICE_OPENCL_C_VERSION reports the language level the
// compiler uses BY DEFAULT when you pass no -cl-std, not a hard ceiling. Compiled
// without -cl-std, this file fails on the iGPU with
//   error: implicit declaration of function 'to_global' is invalid in OpenCL
// which is easy to misread as "the device cannot do this". It can - you have to ask.
//
// Relying on that is still non-portable, because the vendor decides how much of the
// unadvertised level it honours. See subgroup_bcast.cl for a feature where NVIDIA
// draws the line and Intel does not.
//
// Also note the variable is named gp, not generic: "generic" is a reserved keyword
// in OpenCL C and using it as an identifier fails to parse.
__kernel void generic_addr(__global float* out) {
    int i = get_global_id(0);
    void* gp = (__global void*)&out[i];
    __global float* p = to_global(gp);
    *p = (float)(i * 3);
}
