/* 由 build.ps1 调 MSYS2 clang 预编译为 SPIR-V：
   clang -cl-std=CL1.2 -target spirv64 -c kernel_spirv.cl -o kernel_spirv.spv
   注意索引用 int 而不是 size_t（size_t 会让 Intel 运行时在 clBuildProgram 卡死，实测） */
kernel void vec_scale(global const float* x, global float* y, float k) {
    int i = get_global_id(0);
    if (i < 4096) y[i] = x[i] * k;
}
