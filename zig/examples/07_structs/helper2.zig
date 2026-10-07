//! 07 结构的第二个文件：演示"每个 .zig 文件本身就是一个 struct"
pub const Answer = 42;

pub fn twice(x: u32) u32 {
    return x * 2;
}

/// 文件 struct 里也能再放 struct
pub const Table = struct {
    keys: usize = 0,
};
