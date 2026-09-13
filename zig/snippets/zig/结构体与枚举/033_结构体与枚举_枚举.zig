const Color = enum {
    red,
    green,
    blue,
};

const Status = enum(u8) {
    pending = 0,
    running = 1,
    completed = 2,
};

pub fn main() void {
    var color = Color.blue;
    std.debug.print("Color: {}\n", .{color});
}
