__kernel void reduce(__global const float* input,
                     __global float* output,
                     __local float* temp,
                     const int n) {
    int localId = get_local_id(0);
    int globalId = get_global_id(0);
    int groupSize = get_local_size(0);

    // 加载数据到本地内存
    temp[localId] = (globalId < n) ? input[globalId] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    // 树形归约
    for (int stride = groupSize / 2; stride > 0; stride >>= 1) {
        if (localId < stride) {
            temp[localId] += temp[localId + stride];
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }

    // 写入结果
    if (localId == 0) {
        output[get_group_id(0)] = temp[0];
    }
}
