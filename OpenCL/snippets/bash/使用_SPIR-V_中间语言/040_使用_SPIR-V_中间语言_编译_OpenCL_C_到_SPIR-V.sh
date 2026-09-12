# 优化 SPIR-V
spirv-opt -O kernel.spv -o kernel_optimized.spv

# 验证 SPIR-V
spirv-val kernel.spv

# 生成 SPIR-V 信息
spirv-cfg kernel.spv -o cfg.dot
