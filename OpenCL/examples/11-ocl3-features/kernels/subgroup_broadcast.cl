// sub_group_broadcast(), written so that a builtin doing nothing at all would fail.
//
// The obvious version of this test broadcasts lane 0's value when lane 0's value is
// 0, and then checks that every lane got 0. A no-op passes that: the output buffer is
// already zeroed, every lane reads 0, and the assertion succeeds while proving
// nothing. So each lane here starts from a value that is distinct and non-zero, and
// the kernel emits the subgroup geometry alongside the result, letting the host check
// the broadcast against the lane that actually led the subgroup instead of against a
// subgroup size it guessed.
//
// Four words per work-item:
//   [0] v    - this lane's own value, i*3+1
//   [1] b    - sub_group_broadcast(v, 0): what lane 0 of THIS lane's subgroup held
//   [2] lid  - get_sub_group_local_id()
//   [3] sz   - get_sub_group_size()
//
// The host never assumes how the device partitions work-items into subgroups. It
// derives the leader of each lane's subgroup as i - lid and checks b against the
// value that lane reported, then checks that the lids form contiguous 0,1,2,... runs.
// A driver that used a different partition, or a different size for the tail subgroup
// of a work-group, still passes - and a broadcast that silently did nothing fails on
// the first lane that is not its own leader.
//
// Built with -cl-std=CL2.0. Without it the sub_group builtins are not declared at
// all on the Intel devices, whose default level is 1.2 even when the device advertises
// OpenCL C 3.0 - see docs/09.

__kernel void sg_broadcast(__global unsigned int* out, unsigned int n)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;

    unsigned int v = i * 3u + 1u;

    out[i * 4u + 0u] = v;
    out[i * 4u + 1u] = sub_group_broadcast(v, 0);
    out[i * 4u + 2u] = get_sub_group_local_id();
    out[i * 4u + 3u] = get_sub_group_size();
}
