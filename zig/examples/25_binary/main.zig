//! 25 二进制数据与内存布局：extern struct、packed struct、字节序、@bitCast/bytesToValue
//! 取材：Systems Programming with Zig ch3（wire format / endianness / packed struct）
//! + Learning Zig ch8/12（packed struct、C ABI）
const std = @import("std");
const builtin = @import("builtin");

// ═══ 25.1 对齐常量：extern struct 是 C ABI 的"外交护照"
// 普通 struct 字段顺序不保证；extern struct 保证 C 布局（字段按声明顺序、按 C ABI 填充）
const Record = extern struct {
    magic: u16,
    version: u8,
    kind: u8, // 非 exhaustive 语义这里用 u8 演示布局；enum(u8) 也可
    length: u32,
};

// comptime 布局断言：wire 协议的尺寸检查（书上的 EOCD 技巧）
comptime {
    var wire: usize = 0;
    for (std.meta.fields(Record)) |f| wire += @sizeOf(f.type);
    if (wire != @sizeOf(Record)) @compileError("Record 布局被编译器填充了");
}

// ═══ 25.2 packed struct(u16)：位级打包——字段精确到位，@sizeOf 就是背板宽度
const Flags = packed struct(u16) {
    enabled: bool,
    mode: u2,
    reserved: u5,
    level: u8,
};

// ═══ 25.3 WAV(RIFF) 头：真实文件格式的手工解析目标
const WavHead = struct {
    riff_magic: [4]u8, // "RIFF"
    riff_size: u32,
    wave_magic: [4]u8, // "WAVE"
    fmt_magic: [4]u8, // "fmt "
    fmt_size: u32,
    audio_format: u16, // 1 = PCM
    channels: u16,
    sample_rate: u32,
    byte_rate: u32,
    block_align: u16,
    bits_per_sample: u16,
};

pub fn main(init: std.process.Init) !void {
    _ = init;
    const err = std.debug;

    // ═══ 25.4 字节序：同一 u32 的三种字节面貌
    const value: u32 = 0x12345678;
    const native_bytes = std.mem.asBytes(&value);
    err.print("本机（{s}）：{x}\n", .{ @tagName(builtin.cpu.arch.endian()), native_bytes.* });
    const big_val = std.mem.nativeToBig(u32, value);
    err.print("Big 字节序  ：{x}\n", .{std.mem.asBytes(&big_val).*});
    const little_val = std.mem.nativeToLittle(u32, value);
    err.print("Little 字节 ：{x}\n", .{std.mem.asBytes(&little_val).*});
    // 文件格式几乎都是小端（WAV/ELF）或大端（网络序/JPEG 部分）；永远显式指定，不赌本机

    // ═══ 25.5 手工解包：readInt 从任意偏移取数（不要求对齐，最稳）
    const le: [4]u8 = .{ 0x78, 0x56, 0x34, 0x12 };
    const got = std.mem.readInt(u32, &le, .little);
    err.print("LE 解包：0x{X:0>8}\n", .{got});

    // ═══ 25.6 extern struct 整体重解释：bytesToValue（对齐要过关）
    const raw align(@alignOf(Record)) = [_]u8{ 0xEF, 0xBE, 0x01, 0x02, 0x08, 0x00, 0x00, 0x00 };
    const rec = std.mem.bytesToValue(Record, &raw);
    err.print("Record：magic=0x{X} v={d} kind={d} len={d}\n", .{ rec.magic, rec.version, rec.kind, rec.length });

    // ═══ 25.7 packed struct：@bitCast 进出背板整数（写线协议的常用姿势）
    const f1 = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    const board: u16 = @bitCast(f1);
    err.print("Flags→u16：0x{X:0>4}\n", .{board});
    const f2: Flags = @bitCast(board);
    std.debug.assert(f2.level == 0x5A and f2.mode == 0b10 and f2.enabled);

    // ═══ 25.8 综合实战：解析一段 WAV 头字节
    const wav = makeWav(2, 44100, 16, 4);
    const head = parseWavHead(wav[0..44]) catch |e| {
        err.print("解析失败：{s}\n", .{@errorName(e)});
        return e;
    };
    err.print("WAV：{d} 声道 {d} Hz {d} bit，byte_rate={d}\n", .{
        head.channels, head.sample_rate, head.bits_per_sample, head.byte_rate,
    });

    err.print("自检通过\n", .{});
}

/// 用小端手工打包一个最小 WAV 头（不依赖结构体内存布局——线格式自己写才是可移植的）
fn makeWav(channels: u16, sample_rate: u32, bits: u16, data_len: u32) [44]u8 {
    var b: [44]u8 = undefined;
    @memcpy(b[0..4], "RIFF");
    std.mem.writeInt(u32, b[4..8], 36 + data_len, .little);
    @memcpy(b[8..12], "WAVE");
    @memcpy(b[12..16], "fmt ");
    std.mem.writeInt(u32, b[16..20], 16, .little);
    std.mem.writeInt(u16, b[20..22], 1, .little); // PCM
    std.mem.writeInt(u16, b[22..24], channels, .little);
    std.mem.writeInt(u32, b[24..28], sample_rate, .little);
    std.mem.writeInt(u32, b[28..32], sample_rate * channels * bits / 8, .little);
    std.mem.writeInt(u16, b[32..34], channels * bits / 8, .little);
    std.mem.writeInt(u16, b[34..36], bits, .little);
    @memcpy(b[36..40], "data");
    std.mem.writeInt(u32, b[40..44], data_len, .little);
    return b;
}

fn parseWavHead(b: *const [44]u8) !WavHead {
    if (!std.mem.eql(u8, b[0..4], "RIFF") or !std.mem.eql(u8, b[8..12], "WAVE"))
        return error.BadMagic;
    if (!std.mem.eql(u8, b[12..16], "fmt ") or std.mem.readInt(u32, b[16..20], .little) != 16)
        return error.BadFmtChunk;
    return .{
        .riff_magic = b[0..4].*,
        .riff_size = std.mem.readInt(u32, b[4..8], .little),
        .wave_magic = b[8..12].*,
        .fmt_magic = b[12..16].*,
        .fmt_size = std.mem.readInt(u32, b[16..20], .little),
        .audio_format = std.mem.readInt(u16, b[20..22], .little),
        .channels = std.mem.readInt(u16, b[22..24], .little),
        .sample_rate = std.mem.readInt(u32, b[24..28], .little),
        .byte_rate = std.mem.readInt(u32, b[28..32], .little),
        .block_align = std.mem.readInt(u16, b[32..34], .little),
        .bits_per_sample = std.mem.readInt(u16, b[34..36], .little),
    };
}

// ═══ 25.9 测试：布局、位域、roundtrip
test "extern struct 布局可预测" {
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Record)); // 2+1+1+4 无填充
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(Flags)); // packed 背板 u16
    try std.testing.expectEqual(@as(usize, 16), @bitSizeOf(Flags));
}

test "packed struct 位域往返" {
    const f = Flags{ .enabled = false, .mode = 0b11, .reserved = 0, .level = 0xFF };
    const back: Flags = @bitCast(@as(u16, @bitCast(f)));
    try std.testing.expectEqual(f, back);
    try std.testing.expectEqual(false, back.enabled);
}

test "WAV 打包与解析互逆" {
    const w = makeWav(1, 8000, 8, 100);
    const h = try parseWavHead(&w);
    try std.testing.expectEqual(@as(u16, 1), h.channels);
    try std.testing.expectEqual(@as(u32, 8000), h.sample_rate);
    try std.testing.expectEqual(@as(u32, 8000), h.byte_rate); // 8bit 单声道：字节率=采样率
    try std.testing.expectEqual(@as(u16, 8), h.bits_per_sample);
    // 坏魔数必须报错而不是读出垃圾
    var bad = w;
    bad[0] = 'X';
    try std.testing.expectError(error.BadMagic, parseWavHead(&bad));
}

test "readInt/writeInt 互逆" {
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, 0xDEADBEEF, .little);
    try std.testing.expectEqualSlices(u8, &.{ 0xEF, 0xBE, 0xAD, 0xDE }, &buf);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), std.mem.readInt(u32, &buf, .little));
    try std.testing.expectEqual(@as(u32, 0xEFBEADDE), std.mem.readInt(u32, &buf, .big));
}
