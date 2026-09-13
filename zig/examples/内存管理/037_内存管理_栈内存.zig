pub fn main() void {
    // 栈上分配 (自动释放)
    const x: i32 = 10;
    const arr: [100]i32 = undefined;
    _ = x;
    _ = arr;
}
