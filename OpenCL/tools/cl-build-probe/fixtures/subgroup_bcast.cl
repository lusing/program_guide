// Fixture: subgroup builtins, an OpenCL 2.0 feature (or cl_khr_subgroups).
//
// This is the fixture that shows the vendor line, and it is why generic_addr.cl
// passing on every device must not be generalised into "OpenCL 2.0 works
// everywhere here".
//
// MEASURED RESULT (2026-09-17, -cl-std=CL2.0):
//   - Intel i7-9700 CPU      : builds, runs, 256/256 correct, sub_group_size = 8
//   - Intel UHD Graphics 630 : builds, runs, 256/256 correct, sub_group_size = 16
//   - NVIDIA GeForce RTX 2060: BUILD FAILS
//       <kernel>:33:25: warning: implicit declaration of function
//                       'get_sub_group_local_id' is invalid in OpenCL
//       <kernel>:36:19: warning: implicit declaration of function
//                       'sub_group_broadcast' is invalid in OpenCL
//       ptxas fatal   : Unresolved extern function 'get_sub_group_local_id'
//
// The reason is visible in clinfo-probe's output: both Intel devices list
// cl_khr_subgroups / cl_intel_subgroups among their extensions, NVIDIA lists
// neither. Subgroup support is an extension question, not a version question.
//
// Two more traps this fixture encodes:
//   - sub_group_broadcast needs the TWO-argument form (value, sub_group_local_id);
//     the single-argument form fails with "no matching function".
//   - broadcasting lane 0's value 0 would be a vacuous test that a no-op broadcast
//     also passes, so this kernel writes each lane's own value AND the broadcast
//     result, letting the host prove the broadcast really moved data.
__kernel void subgroup_bcast(__global float* outRaw, __global float* outBcast) {
    int i = get_global_id(0);
    float lane = (float)get_sub_group_local_id();
    float v = lane * 10.0f + 7.0f;              // lane 0 -> 7, non-zero and per-lane distinct
    outRaw[i]   = v;
    outBcast[i] = sub_group_broadcast(v, 0);
}
