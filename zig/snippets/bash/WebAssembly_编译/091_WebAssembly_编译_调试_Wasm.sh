# 编译时包含调试信息
zig build-wasm program.zig --mode debug

# 使用 wasm-objdump 查看 Wasm 文件
wasm-objdump -x program.wasm

# 使用 wasm-tools
wasm-tools print program.wasm
