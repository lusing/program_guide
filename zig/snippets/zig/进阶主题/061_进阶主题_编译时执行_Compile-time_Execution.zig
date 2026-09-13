fn fibonacci(comptime n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

pub fn main() void {
    const fib_10 = fibonacci(10);
    std.debug.print("F(10) = {}\n", .{fib_10});
}
