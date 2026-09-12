# 编译到 SPIR-V（64 位）
clang -cl-std=CL2.0 -target spirv64 -c original_kernel.cl -o matrix_multiply.spv

# 查看生成的 SPIR-V 信息
spirv-dis matrix_multiply.spv
