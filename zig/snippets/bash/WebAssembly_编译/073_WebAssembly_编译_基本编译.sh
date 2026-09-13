# 编译成 Wasm
zig build-wasm hello.zig

# 指定输出文件
zig build-wasm hello.zig -o hello.wasm

# 使用发布模式（优化）
zig build-wasm hello.zig --release-small
