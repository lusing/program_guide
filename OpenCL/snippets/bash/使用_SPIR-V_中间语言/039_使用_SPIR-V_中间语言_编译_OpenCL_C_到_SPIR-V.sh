# 从 SPIR-V 反汇编
spirv-dis kernel.spv -o kernel.asm

# 从汇编生成 SPIR-V
spirv-as kernel.asm -o kernel.spv
