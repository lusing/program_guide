# 最小化输出大小
zig build-wasm program.zig --release-small

# 优化执行速度
zig build-wasm program.zig --release-fast

# 关闭边界检查（需要确保代码安全）
zig build-wasm program.zig -O SafeRelease
