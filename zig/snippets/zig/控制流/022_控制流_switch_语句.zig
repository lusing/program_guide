pub fn main() void {
    var score: i32 = 85;

    const grade = switch (score) {
        90...100 => "A",
        80...89 => "B",
        70...79 => "C",
        60...69 => "D",
        0...59 => "F",
        else => "invalid",
    };

    std.debug.print("Grade: {}\n", .{grade});
}
