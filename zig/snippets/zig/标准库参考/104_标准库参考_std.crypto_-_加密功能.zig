const std = @import("std");

pub fn main() void {
    // 随机数生成
    var rng = std.crypto.random.DefaultPrng.init(42);
    const rand = rng.random().int(u64);
    std.debug.print("Random: {}\n", .{rand});

    // SHA256 哈希
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash("Hello", &hash, .{});
    std.debug.print("SHA256: {any}\n", .{hash});

    // HMAC
    const key = "secret";
    const message = "hello";
    var hmac_result: [32]u8 = undefined;
    std.crypto.auth.hmac.sha2.HmacSha256.create(&hmac_result, message, key);
}
