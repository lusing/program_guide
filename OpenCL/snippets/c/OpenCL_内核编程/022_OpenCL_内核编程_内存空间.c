__kernel void example(__global float* input, __global float* output) {
    __local float sharedData[256];  // 本地内存
    int idx = get_global_id(0);

    // 从全局内存读取
    float data = input[idx];

    // 写入本地内存
    sharedData[get_local_id(0)] = data;

    // 同步
    barrier(CLK_LOCAL_MEM_FENCE);

    // 计算
    float result = sharedData[get_local_id(0)] * 2.0f;

    // 写入全局内存
    output[idx] = result;
}
