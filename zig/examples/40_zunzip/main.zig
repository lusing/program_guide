//! 40 · 实战：ZIP 解析与 comptime 布局校验 —— EOCD/CD/字节序/CRC32
//! 对应《Systems Programming with Zig》ch3 的二进制格式解析，升级到 0.17。
//! 核心思路：先**构造**一个内存中的最小 ZIP（local header + data + CD + EOCD），
//! 再**反向解析**它——建格式学格式。全部数据在 0.17.0 + x86_64-macos 实测。
const std = @import("std");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 40.2 CRC32（IEEE，多项式 0xEDB88320，表在 comptime 生成） ═══

/// comptime 生成 256 项 CRC32 查表。const 初始化器本身就是 comptime 作用域，
/// 直接写 for 即可（写 inline for 会报 redundant inline keyword）。
const crc_table = blk: {
    @setEvalBranchQuota(100000);
    var t: [256]u32 = undefined;
    for (0..256) |i| {
        var c: u32 = @intCast(i);
        for (0..8) |_| {
            c = if (c & 1 != 0) 0xEDB88320 ^ (c >> 1) else c >> 1;
        }
        t[i] = c;
    }
    break :blk t;
};

/// 标准 CRC32：初值 0xFFFFFFFF，逐字节查表，最终取反
fn crc32(data: []const u8) u32 {
    var c: u32 = 0xFFFFFFFF;
    for (data) |b| {
        c = crc_table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
}

// ═══ 40.5 comptime 布局校验：字段宽度之和必须等于线格式尺寸 ═══
// 注意：这里**故意用普通 struct**（不是 extern）——我们只用它们做 comptime
// 尺寸校验和字段命名，绝不做 @bitCast / bytesToValue 强转（那是坑位清单第一条）。

/// EOCD 固定部分 = 22 字节（不含末尾 comment）
const Eocd = struct {
    sig: u32, // 0x06054b50
    disk_num: u16,
    cd_start_disk: u16,
    entries_this_disk: u16,
    total_entries: u16,
    cd_size: u32,
    cd_offset: u32,
    comment_len: u16,
};

/// Central Directory 条目固定头 = 46 字节（不含 name/extra/comment）
const CdEntry = struct {
    sig: u32, // 0x02014b50
    version_made_by: u16,
    version_needed: u16,
    flags: u16,
    method: u16,
    mod_time: u16,
    mod_date: u16,
    crc: u32,
    comp_size: u32,
    uncomp_size: u32,
    name_len: u16,
    extra_len: u16,
    comment_len: u16,
    disk_start: u16,
    internal_attrs: u16,
    external_attrs: u32,
    local_header_offset: u32,
};

/// 解析后的 CD 条目（name 是零拷贝切片）
const CdInfo = struct {
    method: u16,
    crc: u32,
    comp_size: u32,
    uncomp_size: u32,
    local_header_offset: u32,
    name: []const u8,
};

/// 字段宽度之和（线格式尺寸）。0.17：@typeInfo(T).@"struct".field_types 是
/// 平行数组（与 field_names 等长）。field_types 的元素是 type，普通 for 的
/// 索引是 runtime-known 会报错——必须 inline for 把循环在 comptime 展开。
fn wireSize(comptime T: type) usize {
    var n: usize = 0;
    inline for (@typeInfo(T).@"struct".field_types) |ft| n += @sizeOf(ft);
    return n;
}

comptime {
    if (wireSize(Eocd) != 22) @compileError("EOCD 布局不等于 22 字节");
    if (wireSize(CdEntry) != 46) @compileError("CD 条目布局不等于 46 字节");
}

// ═══ 40.2 构造一个内存中的最小 ZIP ═══

const demo_name = "hello.txt";
const demo_data = "Hello ZIP!";
const demo_crc = crc32(demo_data); // comptime 算出来，运行期零成本

// 各段长度（固定头 + 变长 name）
const lfh_fixed = 30; // local file header 固定部分
const lfh_len = lfh_fixed + demo_name.len;
const cd_fixed = 46; // central directory 条目固定部分
const cd_len = cd_fixed + demo_name.len;
const eocd_len = 22; // EOCD 固定部分（comment_len=0）
const zip_len = lfh_len + demo_data.len + cd_len + eocd_len;

/// comptime 构造完整 ZIP 字节流。布局：
///   [0 .. lfh_len)          local file header + name
///   [lfh_len .. +data)      原始数据（stored，method=0）
///   [.. +cd_len)            central directory 条目 + name
///   [末尾 22)               EOCD
const demo_zip = blk: {
    var z: [zip_len]u8 = @splat(0);
    var o: usize = 0;

    // ── local file header ──
    std.mem.writeInt(u32, z[o..][0..4], 0x04034b50, .little);
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], 20, .little); // version needed
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // flags
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // method = 0 (stored)
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // mod time
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0x21, .little); // mod date (1980-01-01)
    o += 2;
    std.mem.writeInt(u32, z[o..][0..4], demo_crc, .little);
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // comp size
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // uncomp size
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], demo_name.len, .little);
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // extra len
    o += 2;
    @memcpy(z[o..][0..demo_name.len], demo_name);
    o += demo_name.len;

    // ── file data（stored = 原样） ──
    @memcpy(z[o..][0..demo_data.len], demo_data);
    o += demo_data.len;

    // ── central directory entry ──
    const cd_offset = o;
    std.mem.writeInt(u32, z[o..][0..4], 0x02014b50, .little);
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], 20, .little); // version made by
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 20, .little); // version needed
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // flags
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // method
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // mod time
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0x21, .little); // mod date
    o += 2;
    std.mem.writeInt(u32, z[o..][0..4], demo_crc, .little);
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // comp size
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], demo_data.len, .little); // uncomp size
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], demo_name.len, .little);
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // extra len
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // comment len
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // disk start
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // internal attrs
    o += 2;
    std.mem.writeInt(u32, z[o..][0..4], 0, .little); // external attrs
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], 0, .little); // local header offset
    o += 4;
    @memcpy(z[o..][0..demo_name.len], demo_name);
    o += demo_name.len;

    // ── EOCD ──
    std.mem.writeInt(u32, z[o..][0..4], 0x06054b50, .little);
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // disk num
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // cd start disk
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 1, .little); // entries this disk
    o += 2;
    std.mem.writeInt(u16, z[o..][0..2], 1, .little); // total entries
    o += 2;
    std.mem.writeInt(u32, z[o..][0..4], cd_len, .little); // cd size
    o += 4;
    std.mem.writeInt(u32, z[o..][0..4], cd_offset, .little); // cd offset
    o += 4;
    std.mem.writeInt(u16, z[o..][0..2], 0, .little); // comment len
    o += 2;

    break :blk z;
};

// ═══ 40.3 解析 EOCD：从尾部向前扫 ═══

/// 从尾部向前扫 EOCD 签名 0x06054b50（小端字节序 50 4B 05 06）。
/// 为什么倒着扫：ZIP 允许文件前面有任意前置数据（自解压包 stub），
/// 但 EOCD 一定在文件末尾（最多再拖一个 comment），所以从尾部找是 O(1)。
fn findEocd(data: []const u8) ?usize {
    if (data.len < eocd_len) return null;
    // comment 最长 65535 字节，但我们的 demo 没有 comment，扫最后 22 字节即可
    var i: usize = data.len - eocd_len;
    while (true) {
        if (std.mem.readInt(u32, data[i..][0..4], .little) == 0x06054b50) return i;
        if (i == 0) return null;
        i -= 1;
    }
}

// ═══ 40.4 解析 Central Directory 条目 ═══

/// 从 offset 处解析一个 CD 条目固定头，name 是零拷贝切片。
/// 变长字段（name/extra/comment）靠偏移算术跳过——不能定长读。
fn parseCdEntry(data: []const u8, offset: usize) CdInfo {
    var o = offset;
    std.debug.assert(std.mem.readInt(u32, data[o..][0..4], .little) == 0x02014b50);
    o += 4;
    o += 2; // version made by
    o += 2; // version needed
    o += 2; // flags
    const method = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += 2; // mod time
    o += 2; // mod date
    const crc = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const comp_size = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const uncomp_size = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const name_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const extra_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const comment_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += 2; // disk start
    o += 2; // internal attrs
    o += 4; // external attrs
    const local_header_offset = std.mem.readInt(u32, data[o..][0..4], .little);
    o += 4;
    const name = data[o..][0..name_len];
    // 跳过 name + extra + comment，得到下一条目的偏移（演示用）
    _ = extra_len;
    _ = comment_len;
    return .{
        .method = method,
        .crc = crc,
        .comp_size = comp_size,
        .uncomp_size = uncomp_size,
        .local_header_offset = local_header_offset,
        .name = name,
    };
}

// ═══ 40.6 端到端：自造 ZIP → 解析 → 提取内容 ═══

/// 从 ZIP 字节流中提取一个 stored（method=0）文件的内容。
/// 路径：CD 条目 → local_header_offset → 跳过 local header → 读数据。
fn extractStoredContent(data: []const u8, entry: CdInfo) ![]const u8 {
    if (entry.method != 0) return error.NotStored;
    var o: usize = entry.local_header_offset;
    // local file header 固定 30 字节，然后跳过 name + extra
    if (std.mem.readInt(u32, data[o..][0..4], .little) != 0x04034b50) return error.BadLocalHeader;
    o += 26; // 直接跳到 name_len 字段（30 - 4 = 26）
    const name_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    const extra_len = std.mem.readInt(u16, data[o..][0..2], .little);
    o += 2;
    o += name_len + extra_len;
    return data[o..][0..entry.comp_size];
}

// ═══ 40.7 字节序演示辅助 ═══

fn hexByte(w: anytype, b: u8) !void {
    try w.print("{X:0>2}", .{b});
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var out_buf: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &out_buf);
    const w = &stdout_impl.interface;
    defer w.flush() catch {};

    // ═══ 40.1 ZIP 格式理论 ═══
    begin("40.1 ZIP 格式理论");
    try w.print("ZIP 文件从尾部倒着读：\n", .{});
    try w.print("  EOCD (End Of Central Directory) 签名 0x06054b50，一定在文件末尾\n", .{});
    try w.print("  Central Directory 条目签名 0x02014b50，目录区在 EOCD 之前\n", .{});
    try w.print("  Local File Header 签名 0x04034b50，每个文件数据的前面\n", .{});
    try w.print("固定字段布局（全部小端）：\n", .{});
    try w.print("  EOCD:  sig(4) disk(2) cd_disk(2) n_disk(2) n_total(2) cd_size(4) cd_off(4) cmt_len(2) = 22B\n", .{});
    try w.print("  CD:    sig(4) vmade(2) vneed(2) flags(2) method(2) time(2) date(2) crc(4)\n", .{});
    try w.print("         csize(4) usize(4) nlen(2) elen(2) clen(2) disk(2) iattr(2) eattr(4) lho(4) = 46B\n", .{});
    try w.print("  LFH:   sig(4) vneed(2) flags(2) method(2) time(2) date(2) crc(4)\n", .{});
    try w.print("         csize(4) usize(4) nlen(2) elen(2) = 30B，后跟 name + extra + data\n", .{});
    try w.print("变长字段（name/extra/comment）紧跟在固定头后面，长度由固定头里的 len 字段给出\n", .{});
    end("40.1 ZIP 格式理论");

    // ═══ 40.2 构造一个内存中的最小 ZIP ═══
    begin("40.2 构造一个内存中的最小 ZIP");
    try w.print("文件: {s}，内容: \"{s}\"（{d} 字节），method=0 (stored)\n", .{ demo_name, demo_data, demo_data.len });
    try w.print("CRC32(\"{s}\") = 0x{X:0>8}（comptime 计算，运行期零成本）\n", .{ demo_data, demo_crc });
    try w.print("内存 ZIP 布局（共 {d} 字节）：\n", .{zip_len});
    try w.print("  [0..{d})     local file header + name\n", .{lfh_len});
    try w.print("  [{d}..{d})  file data \"{s}\"\n", .{ lfh_len, lfh_len + demo_data.len, demo_data });
    try w.print("  [{d}..{d})  central directory entry + name\n", .{ lfh_len + demo_data.len, lfh_len + demo_data.len + cd_len });
    try w.print("  [{d}..{d})  EOCD\n", .{ lfh_len + demo_data.len + cd_len, zip_len });
    try w.print("构造 = 学格式：亲手把每个字段写对，解析时就知道该期待什么\n", .{});
    end("40.2 构造一个内存中的最小 ZIP");

    // ═══ 40.3 解析 EOCD ═══
    begin("40.3 解析 EOCD（从尾部向前扫）");
    const eocd_off = findEocd(&demo_zip) orelse return error.EocdNotFound;
    try w.print("findEocd 在偏移 {d} 处找到签名（文件共 {d} 字节，从尾部扫了 {d} 字节）\n", .{
        eocd_off, zip_len, zip_len - eocd_off,
    });
    var o = eocd_off + 4;
    const disk_num = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
    o += 2;
    const cd_start_disk = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
    o += 2;
    const entries_this_disk = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
    o += 2;
    const total_entries = std.mem.readInt(u16, demo_zip[o..][0..2], .little);
    o += 2;
    const cd_size = std.mem.readInt(u32, demo_zip[o..][0..4], .little);
    o += 4;
    const cd_offset = std.mem.readInt(u32, demo_zip[o..][0..4], .little);
    o += 4;
    try w.print("  disk_num          = {d}\n", .{disk_num});
    try w.print("  cd_start_disk     = {d}\n", .{cd_start_disk});
    try w.print("  entries_this_disk = {d}\n", .{entries_this_disk});
    try w.print("  total_entries     = {d}\n", .{total_entries});
    try w.print("  cd_size           = {d}\n", .{cd_size});
    try w.print("  cd_offset         = {d}\n", .{cd_offset});
    try w.print("从 EOCD 拿到 cd_offset={d}，下一步就去那里解析 Central Directory\n", .{cd_offset});
    end("40.3 解析 EOCD（从尾部向前扫）");

    // ═══ 40.4 解析 Central Directory 条目 ═══
    begin("40.4 解析 Central Directory 条目");
    const entry = parseCdEntry(&demo_zip, cd_offset);
    try w.print("  name                = \"{s}\"\n", .{entry.name});
    try w.print("  method              = {d}（0 = stored，无压缩）\n", .{entry.method});
    try w.print("  crc                 = 0x{X:0>8}\n", .{entry.crc});
    try w.print("  comp_size           = {d}\n", .{entry.comp_size});
    try w.print("  uncomp_size         = {d}\n", .{entry.uncomp_size});
    try w.print("  local_header_offset = {d}\n", .{entry.local_header_offset});
    try w.print("变长 name 通过 name_len 偏移算术取出，零拷贝切片\n", .{});
    end("40.4 解析 Central Directory 条目");

    // ═══ 40.5 comptime 布局校验 ═══
    begin("40.5 comptime 布局校验");
    try w.print("Eocd  字段宽度之和 = {d} 字节（要求 22）\n", .{wireSize(Eocd)});
    try w.print("CdEntry 字段宽度之和 = {d} 字节（要求 46）\n", .{wireSize(CdEntry)});
    try w.print("comptime 校验通过: EOCD=22B CD=46B\n", .{});
    try w.print("写法：for (@typeInfo(T).@\"struct\".field_types) |ft| total += @sizeOf(ft)\n", .{});
    try w.print("0.17 里 .@\"struct\" 的引号是必须的（struct 是关键字）\n", .{});
    try w.print("0.17 里 field_names/field_types 是平行数组；std.meta.fields 已 deprecated\n", .{});
    end("40.5 comptime 布局校验");

    // ═══ 40.6 端到端：自造 ZIP → 解析 → 提取内容 ═══
    begin("40.6 端到端：自造 ZIP → 解析 → 提取内容");
    const extracted = try extractStoredContent(&demo_zip, entry);
    try w.print("提取内容 = \"{s}\"（{d} 字节）\n", .{ extracted, extracted.len });
    const roundtrip = std.mem.eql(u8, extracted, demo_data);
    try w.print("与原始数据一致 = {}（CRC 校验也一致 = {}）\n", .{
        roundtrip, crc32(extracted) == entry.crc,
    });
    try w.print("闭环完成：构造 → 解析 EOCD → 解析 CD → 提取内容 → 验证一致\n", .{});
    end("40.6 端到端：自造 ZIP → 解析 → 提取内容");

    // ═══ 40.7 字节序 ═══
    begin("40.7 字节序");
    const v: u32 = 0x12345678;
    const le = std.mem.nativeToLittle(u32, v);
    const be = std.mem.nativeToBig(u32, v);
    try w.print("u32 = 0x{X:0>8}\n", .{v});
    try w.print("  nativeToLittle 字节序: ", .{});
    for (std.mem.asBytes(&le)) |b| try hexByte(w, b);
    try w.print("（低字节在前 = 小端）\n", .{});
    try w.print("  nativeToBig    字节序: ", .{});
    for (std.mem.asBytes(&be)) |b| try hexByte(w, b);
    try w.print("（高字节在前 = 大端）\n", .{});
    try w.print("readInt(u32, bytes, .little) 按小端解读：0x{X:0>8}\n", .{
        std.mem.readInt(u32, std.mem.asBytes(&le), .little),
    });
    try w.print("ZIP 格式规定全部多字节整数一律小端（与 x86 本机序一致，但与网络序相反）\n", .{});
    end("40.7 字节序");

    // ═══ 40.8 坑位清单 ═══
    begin("40.8 坑位清单");
    try w.print("1. 不要用 extern struct 内联强转网络/文件字节（对齐+填充问题）— 用 readInt 显式解析\n", .{});
    try w.print("2. @typeInfo(T).@\"struct\".field_types 的写法（0.17 引号关键字字段）\n", .{});
    try w.print("3. EOCD 从尾部扫而不是头部顺序读（允许前置数据/自解压包）\n", .{});
    try w.print("4. CRC32 表 comptime 生成，运行期零成本\n", .{});
    try w.print("5. 变长字段（name/extra/comment）靠偏移算术跳过，不能定长读\n", .{});
    end("40.8 坑位清单");

    try w.print("自检通过\n", .{});
}

// ═══ Tests ═══

test "CRC32 标准测试向量" {
    // "123456789" 的 CRC32 = 0xCBF43926（RFC 3720 附录标准向量）
    try std.testing.expectEqual(@as(u32, 0xCBF43926), crc32("123456789"));
    // 空串 = 0
    try std.testing.expectEqual(@as(u32, 0), crc32(""));
    // 我们的 demo 数据
    try std.testing.expectEqual(demo_crc, crc32(demo_data));
}

test "findEocd 在内存 ZIP 上工作" {
    const off = findEocd(&demo_zip);
    try std.testing.expect(off != null);
    try std.testing.expectEqual(@as(usize, zip_len - eocd_len), off.?);
    // 签名字节是 50 4B 05 06（小端）
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x50, 0x4B, 0x05, 0x06 }, demo_zip[off.?..][0..4]);
    // 空输入 / 太短都返回 null
    try std.testing.expect(findEocd("") == null);
    const ten_zeros: [10]u8 = @splat(0);
    try std.testing.expect(findEocd(&ten_zeros) == null);
}

test "parseCdEntry 字段正确" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    const entry = parseCdEntry(&demo_zip, cd_offset);
    try std.testing.expectEqualStrings("hello.txt", entry.name);
    try std.testing.expectEqual(@as(u16, 0), entry.method);
    try std.testing.expectEqual(@as(u32, 10), entry.comp_size);
    try std.testing.expectEqual(@as(u32, 10), entry.uncomp_size);
    try std.testing.expectEqual(demo_crc, entry.crc);
    try std.testing.expectEqual(@as(u32, 0), entry.local_header_offset);
}

test "extractStoredContent 往返一致" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    const entry = parseCdEntry(&demo_zip, cd_offset);
    const content = try extractStoredContent(&demo_zip, entry);
    try std.testing.expectEqualStrings(demo_data, content);
    try std.testing.expectEqual(demo_crc, crc32(content));
}

test "comptime 布局校验：EOCD=22 CD=46" {
    // 顶层 comptime 块已经 @compileError 守住了；这里再钉一次具体数字
    try std.testing.expectEqual(@as(usize, 22), wireSize(Eocd));
    try std.testing.expectEqual(@as(usize, 46), wireSize(CdEntry));
    // 0.17：field_names 和 field_types 是平行数组（std.meta.fields 已 deprecated）
    const S = @typeInfo(Eocd).@"struct";
    try std.testing.expectEqual(@as(usize, 8), S.field_names.len);
    try std.testing.expectEqual(@as(usize, 8), S.field_types.len);
    try std.testing.expectEqualStrings("sig", S.field_names[0]);
    try std.testing.expectEqual(u32, S.field_types[0]);
}

test "内存 ZIP 结构自洽：EOCD 指向的 CD 偏移 + 大小 = EOCD 偏移" {
    const eocd_off = findEocd(&demo_zip).?;
    const cd_size = std.mem.readInt(u32, demo_zip[eocd_off + 12 ..][0..4], .little);
    const cd_offset = std.mem.readInt(u32, demo_zip[eocd_off + 16 ..][0..4], .little);
    try std.testing.expectEqual(@as(usize, cd_len), cd_size);
    try std.testing.expectEqual(@as(usize, lfh_len + demo_data.len), cd_offset);
    // CD 条目 + EOCD 正好填满到文件末尾
    try std.testing.expectEqual(cd_offset + cd_size, eocd_off);
}
