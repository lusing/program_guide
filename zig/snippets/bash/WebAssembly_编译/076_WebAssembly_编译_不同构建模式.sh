# 开发模式（包含调试信息）
zig build-wasm program.zig --mode debug

# 发布模式（优化大小）
zig build-wasm program.zig --release-small

# 发布模式（优化速度）
zig build-wasm program.zig --release-fast
