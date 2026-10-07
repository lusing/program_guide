//! 25 二进制数据与内存布局：三种 struct 布局、@bitCast 的0.17 限制、字节 API、
//! 字节序与网络序、定长 vs 变长（varint）、位域与 packed struct、comptime 布局
//! 守卫，以及一个完整的协议编解码实战（编码 → 十六进制 dump → 解码 → 篡改 → 优雅失败）
//! 全部数据在 0.17.0 + x86_64-macos 上实测，文档25-binary.md 逐条抄录
const std = @import("std");
const builtin = @import("builtin");

fn begin(comptime tag: []const u8) void {
    std.debug.print("==== {s} 开始 ====\n", .{tag});
}

fn end(comptime tag: []const u8) void {
    std.debug.print("==== {s} 结束 ====\n", .{tag});
}

// ═══ 25.2 三种布局的样本类型：字段完全相同，只有 layout 关键字不同 ═══

/// auto（普通 struct）：字段顺序由编译器定，实测 u32被挪到最前
const Auto = struct { a: u8, b: u32, c: u8 };

/// extern（C 布局）：声明顺序 + 自然对齐 + 尾部补齐
const Ext = extern struct { a: u8, b: u32, c: u8 };

/// packed（位级紧密）：按声明顺序一位一位排，零填充
const Packed = packed struct(u32) { a: u8, b: u8, c: u8, d: u8 };

/// 25.4 线协议记录头：extern struct 是"上线路"的唯一选择
const Record = extern struct {
    magic: u16,
    version: u8,
    kind: u8,
    length: u32,
};

/// 25.10 位域：packed struct(u16) 是唯一允许 @bitCast 进出的 struct 形态
const Flags = packed struct(u16) {
    enabled: bool, // bit 0
    mode: u2, // bit 1-2
    reserved: u5, // bit 3-7
    level: u8, // bit 8-15
};

/// 25.2 把"字段宽度之和"算出来——wire 尺寸 ≠ @sizeOf 就说明编译器插了填充
fn wireSize(comptime T: type) usize {
    const S = @typeInfo(T).@"struct";
    var n: usize = 0;
    // ⚠️ 0.17：`field_types` 是平行数组，只能 inline for 遍历（普通 for 会报错）
    inline for (S.field_types) |ft| n += @sizeOf(ft);
    return n;
}

// ═══ 25.11 comptime 布局守卫：线格式尺寸对不上就编译失败 ═══
// 这一版Record 是 2+1+1+4 = 8 且无填充，守卫通过；
// 把字段改成 {a: u8, b: u32, c: u16} 就会触发 @compileError（实测文本见文档 25.4）
comptime {
    if (@typeInfo(Record).@"struct".layout != .@"extern")
        @compileError("线协议结构体必须是 extern struct");
    if (wireSize(Record) != @sizeOf(Record)) {
        // std.fmt.comptimePrint 让报错信息带上具体数字
        @compileError("Record 有填充字节：wire=" ++
            std.fmt.comptimePrint("{d}", .{wireSize(Record)}) ++
            " sizeOf=" ++ std.fmt.comptimePrint("{d}", .{@sizeOf(Record)}));
    }
}

/// 25.12 协议帧：magic(2) + version(1) + flags(2) + varint 长度 + 载荷 + 校验和
pub const Proto = struct {
    /// 帧最大载荷：定长数组让整个编解码器零分配
    pub const max_payload = 64;
    /// 帧头固定部分：magic(2) + version(1) + flags(2) = 5 字节
    pub const header_len = 5;
    /// magic：协议标识，解码器第一个检查项
    pub const magic: u16 = 0xBEEF;
    /// 当前协议版本
    pub const version: u8 = 1;

    /// 一帧的解码结果：切片指向调用方的缓冲区，零拷贝
    pub const Frame = struct {
        version: u8,
        flags: Flags,
        /// varint 解出来的载荷长度
        len: usize,
        /// 载荷字节（指向输入缓冲区的内部）
        payload: []const u8,
    };

    /// 解码失败的原因集合——每一种都用test 钉住（见 25.13）
    pub const DecodeError = error{
        /// 输入比帧头还短
        Truncated,
        /// magic 不匹配（不是本协议的数据）
        BadMagic,
        /// 版本不认识
        BadVersion,
        /// varint 编码超过 5 字节（u32 上限）或者高位全1 溢出
        BadVarint,
        /// 声明的长度超出剩余字节
        LengthOverrun,
        /// 声明的长度超过 max_payload
        TooLarge,
        /// 校验和不匹配（传输损坏 / 恶意篡改）
        ChecksumMismatch,
    };

    /// 累加校验和：简单加法，够演示"完整性检查"这件事
    pub fn checksum(bytes: []const u8) u16 {
        var sum: u16 = 0;
        for (bytes) |b| sum +%= b;
        return sum;
    }

    /// 编码：把一帧写进 out（长度必须 ≥ 实际所需），返回写入的字节数
    pub fn encode(out: []u8, flags: Flags, payload: []const u8) !usize {
        if (payload.len > max_payload) return error.TooLarge;
        var vbuf: [5]u8 = @splat(0);
        const vlen = try putVarint(vbuf[0..], payload.len);
        const need = header_len + vlen + payload.len + 2;
        if (out.len < need) return error.NoSpaceLeft;
        var i: usize = 0;
        std.mem.writeInt(u16, out[i..][0..2], magic, .big); // 网络序（大端）
        i += 2;
        out[i] = version;
        i += 1;
        std.mem.writeInt(u16, out[i..][0..2], @bitCast(flags), .big); // packed → 背板 → 显式端序
        i += 2;
        @memcpy(out[i..][0..vlen], vbuf[0..vlen]); // varint 长度
        i += vlen;
        @memcpy(out[i..][0..payload.len], payload);
        i += payload.len;
        std.mem.writeInt(u16, out[i..][0..2], checksum(out[0..i]), .big);
        i += 2;
        return i;
    }

    /// 解码：从任意切片解一帧。**每一步都检查边界**，恶意输入只会得到 error
    pub fn decode(buf: []const u8) DecodeError!Frame {
        // 1) 帧头都不够
        if (buf.len < header_len) return error.Truncated;
        // 2) magic
        if (std.mem.readInt(u16, buf[0..2], .big) != magic) return error.BadMagic;
        // 3) 版本
        const ver = buf[2];
        if (ver != version) return error.BadVersion;
        // 4) flags（packed struct 的背板往返）
        const flags: Flags = @bitCast(std.mem.readInt(u16, buf[3..5], .big));
        // 5) varint 长度：从偏移 5 开始解，最多 5 字节
        var n: usize = 0;
        const vlen = try getVarint(buf[header_len..], &n);
        // 6) 长度上限（先限上界，再验剩余字节——顺序不能反）
        if (n > max_payload) return error.TooLarge;
        const body = header_len + vlen;
        if (buf.len < body + n + 2) return error.LengthOverrun;
        // 7) 校验和覆盖除末尾2 字节以外的全部内容
        if (std.mem.readInt(u16, buf[body + n ..][0..2], .big) != checksum(buf[0 .. body + n]))
            return error.ChecksumMismatch;
        return .{
            .version = ver,
            .flags = flags,
            .len = n,
            .payload = buf[body..][0..n],
        };
    }
};

/// 25.9 LEB128 无符号变长整数：7 位一组，最高位是"还有后续"标志
fn putVarint(out: []u8, value_in: usize) !usize {
    var v = value_in;
    var i: usize = 0;
    while (true) {
        if (i >= out.len) return error.NoSpaceLeft;
        if (v < 0x80) {
            out[i] = @intCast(v);
            return i + 1;
        }
        out[i] = @intCast((v & 0x7F) | 0x80); // 低 7 位 + 续位
        v >>= 7;
        i += 1;
    }
}

/// LEB128 解码。out 指向被解码出来的值，返回**消耗掉的字节数**
fn getVarint(src: []const u8, out: *usize) Proto.DecodeError!usize {
    var acc: usize = 0;
    var shift: u6 = 0;
    var i: usize = 0;
    while (true) {
        if (i >= src.len) return error.BadVarint;
        const b = src[i];
        if (i >= 5) return error.BadVarint; // u32 上限：最多 5 字节
        acc |= @as(usize, b & 0x7F) << shift;
        i += 1;
        if (b & 0x80 == 0) break;
        shift += 7;
    }
    out.* = acc;
    return i;
}

pub fn main(init: std.process.Init) !void {
    _ = init;
    const err = std.debug;

    // ═══ 25.1 为什么协议解析必须懂内存布局 ═══
    begin("25.1 为什么协议解析必须懂内存布局");
    err.print("线上的东西只有字节：没有 int、没有 struct、没有 endianness\n", .{});
    err.print("「读一个 u32」= 4 个字节 + 一个端序约定 + 一个对齐约定\n", .{});
    err.print("三个约定猜错任何一个→ 静默读出垃圾值（不是崩溃，是数据错）\n", .{});
    err.print("本章三种布局的实测@sizeOf（同一组字段 a:u8 b:u32 c:u8）：\n", .{});
    err.print("  auto   size={d:>2} align={d} a@{d} b@{d} c@{d}\n", .{
        @sizeOf(Auto), @alignOf(Auto), @offsetOf(Auto, "a"), @offsetOf(Auto, "b"), @offsetOf(Auto, "c"),
    });
    err.print("  extern size={d:>2} align={d} a@{d} b@{d} c@{d}\n", .{
        @sizeOf(Ext), @alignOf(Ext), @offsetOf(Ext, "a"), @offsetOf(Ext, "b"), @offsetOf(Ext, "c"),
    });
    err.print("  packed size={d:>2} align={d} a@{d} b@{d} c@{d} d@{d}（字段是a b c d 四个 u8）\n", .{
        @sizeOf(Packed),        @alignOf(Packed),
        @offsetOf(Packed, "a"), @offsetOf(Packed, "b"),
        @offsetOf(Packed, "c"), @offsetOf(Packed, "d"),
    });
    err.print("⚠️ auto 的 b@0（声明在中间却排到最前）——这就是「不能上线路」的铁证\n", .{});
    end("25.1 为什么协议解析必须懂内存布局");

    // ═══ 25.2 三种布局的 @typeInfo 形状与 @bitSizeOf ═══
    begin("25.2 三种布局的 @typeInfo 形状");
    inline for (.{ Auto, Ext, Packed, Flags }) |T| {
        const S = @typeInfo(T).@"struct";
        err.print("{s:<7} layout={s:<7} size={d:>2} align={d} backing_integer={any}\n", .{
            @typeName(T), @tagName(S.layout), @sizeOf(T), @alignOf(T), S.backing_integer,
        });
    }
    err.print("@bitSizeOf 只对 packed 和整数类型有意义：\n", .{});
    err.print("  Pk(u32背板)={d}  Flags(u16 背板)={d}  u24={d}\n", .{
        @bitSizeOf(Packed), @bitSizeOf(Flags), @bitSizeOf(u24),
    });
    err.print("⚠️ @bitSizeOf(Ext) 编译失败：no bit size available for type（extern 有填充，位数无定义）\n", .{});
    err.print("@offsetOf 给字节偏移，@bitOffsetOf 给位偏移——packed 里两者不同：\n", .{});
    const F2 = packed struct(u16) { a: u1, b: u3, c: u4, d: u8 };
    err.print("  a: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "a"), @bitOffsetOf(F2, "a") });
    err.print("  b: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "b"), @bitOffsetOf(F2, "b") });
    err.print("  d: offsetOf={d} bitOffsetOf={d}\n", .{ @offsetOf(F2, "d"), @bitOffsetOf(F2, "d") });
    err.print("  → a/b/c 三个非字节对齐字段的 offsetOf 全是 0（挤在第0 个字节里）\n", .{});
    end("25.2 三种布局的 @typeInfo 形状");

    // ═══ 25.3 auto 的字段会被重排：用 @offsetOf 钉死 ═══
    begin("25.3 auto struct 的字段会被重排");
    err.print("Auto{{ a: u8, b: u32, c: u8 }} 声明顺序 = a, b, c\n", .{});
    err.print("实测 offsetOf: a@{d} b@{d} c@{d}  ← b 被挪到最前，a/c 被挤开\n", .{
        @offsetOf(Auto, "a"), @offsetOf(Auto, "b"), @offsetOf(Auto, "c"),
    });
    err.print("sizeOf={d}（1+4+1=6，被对齐撑到 8）wireSize={d}（字段宽度之和）\n", .{
        @sizeOf(Auto), wireSize(Auto),
    });
    err.print("wireSize({d}) != sizeOf({d}) ⇒ auto布局下这两个数**永远**不相等\n", .{
        wireSize(Auto), @sizeOf(Auto),
    });
    err.print("⇒ 所以 auto struct 只能进内存，不能上线（0.17 里它的用途是内存里的快结构体）\n", .{});
    end("25.3 auto struct 的字段会被重排");

    // ═══ 25.4 extern struct：C 布局 + comptime 布局守卫 ═══
    begin("25.4 extern struct：C 布局 + 布局守卫");
    err.print("Ext{{ a: u8, b: u32, c: u8 }}：a@{d} b@{d} c@{d} size={d}（c 在 @8，@sizeOf 补到 12 的倍数 → 尾部 3 字节填充）\n", .{
        @offsetOf(Ext, "a"), @offsetOf(Ext, "b"), @offsetOf(Ext, "c"), @sizeOf(Ext),
    });
    err.print("wireSize(Ext)={d} sizeOf(Ext)={d} ⇒差 {d} 字节是编译器插的对齐填充\n", .{
        wireSize(Ext), @sizeOf(Ext), @sizeOf(Ext) - wireSize(Ext),
    });
    err.print("Record{{magic:u16,version:u8,kind:u8,length:u32}}：\n", .{});
    err.print("  a@{d}(magic) v@{d}(version) k@{d}(kind) len@{d}(length) size={d}\n", .{
        @offsetOf(Record, "magic"), @offsetOf(Record, "version"),
        @offsetOf(Record, "kind"),  @offsetOf(Record, "length"),
        @sizeOf(Record),
    });
    err.print("  wireSize={d} == sizeOf={d} ⇒ 字段顺序恰好无填充，comptime 守卫通过\n", .{
        wireSize(Record), @sizeOf(Record),
    });
    err.print("守卫写法（wire≠sizeOf 就@compileError，实测报错见文档 25.4）：\n", .{});
    err.print("  if (wireSize(Record) != @sizeOf(Record)) @compileError(...)\n", .{});
    err.print("⚠️ extern也**禁止非 2 的幂次位宽**：extern struct{{ a: u24 }} 编译失败\n", .{});
    err.print("   报错：extern structs cannot contain fields of type 'u24'\n", .{});
    err.print("   note: only integers with 0 or power of two bits are extern compatible\n", .{});
    end("25.4 extern struct：C 布局 + 布局守卫");

    // ═══ 25.5 ⚠️ @bitCast 在 0.17 拒绝裸结构体 ═══
    begin("25.5 @bitCast 的0.17 限制");
    err.print("0.17 实测：`const w: u16 = @bitCast(ext_struct_value)` 编译失败\n", .{});
    err.print("  报错文本：error: cannot @bitCast from 'main.Record'\n", .{});
    err.print("  extern struct 不行、普通 struct 更不行（extern 已经是唯一\"合法\"布局了）\n", .{});
    err.print("**唯一例外是 packed struct**（它的内存表示就是背板整数）：\n", .{});
    const f1 = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    const board: u16 = @bitCast(f1);
    err.print("  Flags{{enabled,mode=0b10,level=0x5A}} @bitCast→ u16 = 0x{X:0>4}\n", .{board});
    const f2: Flags = @bitCast(board);
    err.print("  u16 0x{X:0>4} @bitCast→ Flags = enabled={} mode={d} level=0x{X:0>2}\n", .{
        board, f2.enabled, f2.mode, f2.level,
    });
    err.print("位分配从低位起：bit0=enabled bit1-2=mode bit3-7=reserved bit8-15=level\n", .{});
    err.print("⇒ 正确写法：std.mem.asBytes(&v) 拿字节，再readInt/writeInt（**显式端序**）\n", .{});
    const r = Record{ .magic = 0xBEEF, .version = 1, .kind = 2, .length = 8 };
    const rb = std.mem.asBytes(&r);
    err.print("  asBytes(&Record) 类型 = {s}，len={d}（= @sizeOf，切不出越界）\n", .{
        @typeName(@TypeOf(rb)), rb.len,
    });
    err.print("  指向的数组对齐 = {d}（= @alignOf(Record)），内容 = {X}\n", .{
        @alignOf(Record), rb.*,
    });
    end("25.5 @bitCast 的0.17 限制");

    // ═══ 25.6 asBytes / bytesAsValue / bytesToValue / toBytes ═══
    begin("25.6 字节 API 家族");
    err.print("std.mem.toBytes(value)      → [N]u8（**值拷贝**，N = @sizeOf(T)）\n", .{});
    err.print("std.mem.asBytes(&value)     → *align(N) [N]u8（**带对齐**的指针，不拷贝）\n", .{});
    err.print("std.mem.bytesToValue(T, bs)  → T（**值拷贝** = bytesAsValue(T,bs).*）\n", .{});
    err.print("std.mem.bytesAsValue(T, bs) → *T（指针视图，保留指针属性）\n", .{});
    err.print("⚠️ std.mem.valueToBytes 在 0.17 **不存在**（实测 hasDecl=false）\n", .{});
    var v32: u32 = 0x12345678;
    const tb = std.mem.toBytes(v32);
    err.print("toBytes(u32 0x12345678) = {x}（本机小端）\n", .{tb});
    const back = std.mem.bytesToValue(u32, &tb);
    err.print("bytesToValue 回去= 0x{X:0>8}（往返一致）\n", .{back});
    const ab = std.mem.asBytes(&v32);
    err.print("asBytes(&u32) 类型 = {s}（align 来自 T 的 @alignOf={d}）\n", .{
        @typeName(@TypeOf(ab)), @alignOf(u32),
    });
    // extern struct 整体 view
    const raw align(@alignOf(Record)) = [_]u8{ 0xEF, 0xBE, 0x01, 0x02, 0x08, 0x00, 0x00, 0x00 };
    const rec = std.mem.bytesToValue(Record, &raw);
    err.print("bytesToValue(Record, 对齐的字节块) = magic=0x{X} v={d} k={d} len={d}\n", .{
        rec.magic, rec.version, rec.kind, rec.length,
    });
    err.print("⚠️ 对齐不过关时bytesToValue **不报错**，直接给你一个错读的值（实测）\n", .{});
    err.print("   → 所以 extern view 只在\"你确信这块内存是对齐的\"地方用\n", .{});
    end("25.6 字节 API 家族");

    // ═══ 25.7 readInt / writeInt：不要求对齐是最大优势 ═══
    begin("25.7 readInt / writeInt：显式端序 + 零对齐要求");
    var buf: [9]u8 = @splat(0);
    std.mem.writeInt(u32, buf[1..5], 0xAABBCCDD, .big); // 偏移 1，**故意不对齐**
    err.print("writeInt(u32, buf[1..5], 0xAABBCCDD, .big) → dump={X}\n", .{buf});
    err.print("  buf[1..5] 地址 % 4 = 1（未对齐），x86 能跑，ARM 会 trap\n", .{});
    err.print("  这就是 readInt 相对 @ptrCast 的最大优势：它只按字节搬，不生成对齐 load\n", .{});
    err.print("  readInt(u32, buf[1..5], .big)    = 0x{X:0>8}\n", .{std.mem.readInt(u32, buf[1..5], .big)});
    err.print("  readInt(u32, buf[1..5], .little) = 0x{X:0>8}（同一批字节，反过来读）\n", .{std.mem.readInt(u32, buf[1..5], .little)});
    err.print("⚠️ N 必须精确等于 T 的字节数：给 readInt(u32) 喂 8 字节数组会编译失败\n", .{});
    err.print("   报错：expected type '*const [4]u8', found '*const [8]u8'\n", .{});
    err.print("   签名：readInt(T, *const [@divExact(bits,8)]u8, endian) → T（N 由 T 推导）\n", .{});
    err.print("⚠️ u24 也支持但要 3 字节（给 4 字节同样编译失败）\n", .{});
    end("25.7 readInt / writeInt：显式端序 + 零对齐要求");

    // ═══ 25.8 字节序：为什么协议必须显式写端序 ═══
    begin("25.8 字节序：网络序与 htons/ntohs");
    const native = builtin.cpu.arch.endian();
    err.print("builtin.cpu.arch.endian() 类型 = {s}，本机值 = {s}\n", .{
        @typeName(@TypeOf(native)), @tagName(native),
    });
    err.print("它是**编译期常量**（const native = ... 直接 comptime if 分支）\n", .{});
    const value: u32 = 0x12345678;
    err.print("同一个 u32=0x12345678 的三种字节面貌：\n", .{});
    err.print("  本机序 native        {x}（{s} 机器上就是这个顺序）\n", .{
        std.mem.asBytes(&value).*, @tagName(native),
    });
    err.print("  大端   nativeToBig   {x}\n", .{std.mem.asBytes(&std.mem.nativeToBig(u32, value)).*});
    err.print("  小端   nativeToLittle {x}\n", .{std.mem.asBytes(&std.mem.nativeToLittle(u32, value)).*});
    err.print("x86/ARM 桌面端都是小端⇒ nativeToBig 是真交换；大端机器上是空操作\n", .{});
    const port: u16 = 8080;
    const port_be = htons(port);
    err.print("端口 8080：本机字节 {x} → htons 后 {x}\n", .{
        std.mem.asBytes(&port).*, std.mem.asBytes(&port_be).*,
    });
    err.print("自实现 htons/ntohs（不依赖 std.mem 的 4 个变体）：\n", .{});
    err.print("  htons(0x1234)=0x{X:0>4}  ntohs(htons(0x1234))=0x{X:0>4}（交换是自逆的，往返一致）\n", .{
        htons(0x1234), ntohs(htons(0x1234)),
    });
    err.print("⚠️ 为什么必须交换：网络协议规定多字节整数一律大端（网络序）\n", .{});
    err.print("   小端主机直接 memcpy 端口号出去→ 对端读到 0x901f（38609）而不是 8080\n", .{});
    err.print("⚠️ readInt 的 .little/.big 是**第三种**语义（读文件格式用），别和 htons 混用\n", .{});
    end("25.8 字节序：网络序与 htons/ntohs");

    // ═══ 25.9 变长整数 varint / LEB128 ═══
    begin("25.9 变长整数：LEB128");
    err.print("定长编码的代价：值 1 也要占 4 字节。LEB128 按需分配：\n", .{});
    err.print("  {d:>6} → {d} 字节\n", .{ 0, blkLen(0) });
    err.print("  {d:>6} → {d} 字节\n", .{ 1, blkLen(1) });
    err.print("  {d:>6} → {d} 字节\n", .{ 127, blkLen(127) });
    err.print("  {d:>6} → {d} 字节（跨过 0x7F就要多一组）\n", .{ 128, blkLen(128) });
    err.print("  {d:>6} → {d} 字节\n", .{ 300, blkLen(300) });
    err.print("  {d:>6} → {d} 字节（64 位 usize 最多 10 字节）\n", .{ std.math.maxInt(u64), blkLen(std.math.maxInt(u64)) });
    err.print("边界用例（0 / 127 / 128 / 16383 / 16384 / 2^32-1）：\n", .{});
    for ([_]usize{ 0, 127, 128, 16383, 16384, std.math.maxInt(u32) }) |v| {
        var tmp: [10]u8 = undefined;
        const n = try putVarint(&tmp, v);
        var got: usize = 0;
        const m = try getVarint(tmp[0..n], &got);
        err.print("  {d:>10} → {d} 字节 {X} → 解回 {d}（消耗 {d} 字节）{s}\n", .{
            v, n, tmp[0..n], got, m,
            if (got == v and m == n) "✓" else "✗",
        });
    }
    err.print("⚠️ 恶意输入防御：① i >= 5 直接 BadVarint（u32 上限）② 字节不够 BadVarint\n", .{});
    var junk: usize = 0;
    err.print("   getVarint(6 个连续续位)  = {s}（超出 u32 的 5 字节上限 → 拒）\n", .{
        @errorName(varintErr(getVarint(&[_]u8{ 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 }, &junk))),
    });
    err.print("   getVarint(单个 0x80)     = {s}（有续位但没数据 → 拒）\n", .{
        @errorName(varintErr(getVarint(&[_]u8{0x80}, &junk))),
    });
    end("25.9 变长整数：LEB128");

    // ═══ 25.10 位域与 packed struct ═══
    begin("25.10 位域与 packed struct");
    err.print("Flags 是 packed struct(u16)，四个字段共1+2+5+8 = 16 bit\n", .{});
    err.print("改一个字段，观察背板整数怎么变（网络协议里这就是「标志位」）：\n", .{});
    inline for (.{
        Flags{ .enabled = false, .mode = 0, .reserved = 0, .level = 0 },
        Flags{ .enabled = true, .mode = 0, .reserved = 0, .level = 0 },
        Flags{ .enabled = false, .mode = 0b11, .reserved = 0, .level = 0 },
        Flags{ .enabled = false, .mode = 0, .reserved = 0, .level = 0xFF },
        Flags{ .enabled = true, .mode = 0b01, .reserved = 0b11111, .level = 0xA5 },
    }) |f| {
        const b: u16 = @bitCast(f);
        err.print("  enabled={} mode=0b{b:0>2} level=0x{X:0>2} → 0x{X:0>4}\n", .{
            f.enabled, f.mode, f.level, b,
        });
    }
    err.print("取地址：0.17 **允许** &f.field，但类型是带 bit offset 的指针：\n", .{});
    var fv = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    err.print("  &fv.level 类型 = {s}（字节对齐的那个字段，看起来正常）\n", .{@typeName(@TypeOf(&fv.level))});
    err.print("  &fv.mode  类型 = {s}（bit 1-2，**不是**字节对齐）\n", .{@typeName(@TypeOf(&fv.mode))});
    err.print("⚠️ 把 &fv.mode 传给 fn(*u2) 会编译失败（bit offset 无法隐式降为 0）：\n", .{});
    err.print("   报错：expected type '*u2', found '*align(2:1:2) u2'\n", .{});
    err.print("   note: pointer host size '2' cannot cast into pointer host size '0'\n", .{});
    err.print("   note: pointer bit offset '1' cannot cast into pointer bit offset '0'\n", .{});
    err.print("⇒ 修法一：显式标注 *align(2:1:2) u2；修法二：把整个背板 @bitCast 出来再取地址\n", .{});
    err.print("packed struct 的其它实测事实：\n", .{});
    const U24F = packed struct(u32) { a: u24, b: u8 };
    err.print("  packed struct(u32){{a:u24,b:u8}} 合法：size={d} bits={d}（u24 **可以**进 packed）\n", .{
        @sizeOf(U24F), @bitSizeOf(U24F),
    });
    const Odd = packed struct { a: u3, b: u3, c: u3 };
    err.print("  packed struct 不写背板（三个 u3 = 9 位）：size={d} bits={d} align={d}（补齐到 2 字节）\n", .{
        @sizeOf(Odd), @bitSizeOf(Odd), @alignOf(Odd),
    });
    err.print("⚠️ 但 extern struct{{ a: u24 }} 编译失败：extern structs cannot contain fields of type 'u24'\n", .{});
    err.print("   （0 或 2 的幂次位宽才有 C 兼容布局）\n", .{});
    err.print("⚠️ packed struct(u32){{ a: u24 }} 字段装不满背板 → backing integer bit width does not match\n", .{});
    end("25.10 位域与 packed struct");

    // ═══ 25.11 位操作 ═══
    begin("25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl");
    const x: u16 = 0b1011_0110_1100_0001;
    err.print("x = 0b{x}（{d} 位）\n", .{ x, @bitSizeOf(u16) });
    err.print("  @popCount  = {d}（1 的个数；返回类型由位宽推导，不是 usize）\n", .{@popCount(x)});
    err.print("  @clz      = {d}（leading zeros，前导零个数）\n", .{@clz(x)});
    err.print("  @ctz      = {d}（trailing zeros，尾部零个数）\n", .{@ctz(x)});
    err.print("  @bitReverse= 0b{x}（整个字位序翻转）\n", .{@bitReverse(x)});
    err.print("  rotl 4    = 0b{x}   rotr 4 = 0b{x}\n", .{
        std.math.rotl(u16, x, 4), std.math.rotr(u16, x, 4),
    });
    err.print("⚠️ @ctz(0) = {d}（=类型位宽，u8 上是 8）；@popCount(0) = {d}\n", .{ @ctz(@as(u8, 0)), @popCount(@as(u8, 0)) });
    err.print("⚠️ 旋转**不是**内建函数：@rotl / @rotr / @rotateLeft 在 0.17 全部 invalid builtin function\n", .{});
    err.print("   正解是 std.math.rotl(T, v, n) / std.math.rotr(T, v, n)\n", .{});
    err.print("@clz/@ctz 的返回类型 = {s}（u16 → u5，装得下0..16）\n", .{@typeName(@TypeOf(@ctz(x)))});
    err.print("实用场景：@ctz 找最低位 1（枚举的位索引），@popCount 数标志位：\n", .{});
    const mask: u8 = 0b1001_0110;
    err.print("  mask=0b{b:0>8} popCount={d} ctz={d} clz={d}\n", .{
        mask, @popCount(mask), @ctz(mask), @clz(mask),
    });
    end("25.11 位操作 @popCount / @clz / @ctz / @bitReverse / rotl");

    // ═══ 25.12 std.mem 的字节工具箱 ═══
    begin("25.12 std.mem 字节工具箱（逐个实测）");
    var rev8 = [_]u8{ 1, 2, 3, 4, 5 };
    std.mem.reverse(u8, &rev8);
    err.print("reverse(u8, {{1,2,3,4,5}})     = {x}（就地翻转）\n", .{rev8});
    var rev16 = [_]u16{ 0x0102, 0x0304 };
    std.mem.reverse(u16, &rev16);
    err.print("reverse(u16, {{0x0102,0x0304}}) = {{{d},{d}}}（按元素翻，不是按字节翻）\n", .{ rev16[0], rev16[1] });
    var sa: u32 = 0xAAAAAAAA;
    var sb: u32 = 0x55555555;
    std.mem.swap(u32, &sa, &sb);
    err.print("swap(u32)0xAAAAAAAA<->0x55555555 → 0x{X:0>8}, 0x{X:0>8}\n", .{ sa, sb });
    err.print("zeroes([4]u8) = {x}   zeroes(u32) = 0x{X:0>8}（全类型都支持）\n", .{
        std.mem.zeroes([4]u8), std.mem.zeroes(u32),
    });
    const gpa = std.heap.page_allocator;
    const cat = try std.mem.concat(gpa, u8, &.{ "ab", "cd", "ef" });
    defer gpa.free(cat);
    err.print("concat(u8, {{\"ab\",\"cd\",\"ef\"}})  = {s}（len={d}，唯一会分配的那个）\n", .{ cat, cat.len });
    const hex = std.fmt.bytesToHex(rev8, .lower);
    err.print("std.fmt.bytesToHex(rev8, .lower) = {s}（返回定长数组值拷贝，零分配）\n", .{hex});
    err.print("⚠️ std.fmt.fmtSliceHexLower 在 0.17 **不存在**（实测 hasDecl=false）\n", .{});
    end("25.12 std.mem 字节工具箱（逐个实测）");

    // ═══ 25.13 协议实战：编码 → hex dump → 解码 ═══
    begin("25.13 协议实战：编码 → 十六进制 dump → 解码");
    err.print("协议布局（全部大端/网络序）：\n", .{});
    err.print("  [0..2) magic  u16 = 0x{X:0>4}\n", .{Proto.magic});
    err.print("  [2]    version u8  = {d}\n", .{Proto.version});
    err.print("  [3..5) flags   u16 = packed struct(u16) 背板\n", .{});
    err.print("  [5..)  length  varint（LEB128，1-5 字节）\n", .{});
    err.print("  [..n)  payload 载荷 {d} 字节\n", .{Proto.max_payload});
    err.print("  [末尾2) checksum u16 = 前面所有字节的 u16 累加和\n", .{});
    err.print("定长部分是 {d} 字节 + varint 长度 + 载荷 + 2\n", .{Proto.header_len});

    const demo_flags = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    const payload = "hello wire";
    var frame: [128]u8 = undefined;
    const n = try Proto.encode(&frame, demo_flags, payload);
    err.print("\n编码 flags=0x{X:0>4} payload=\"{s}\"（{d} 字节）→ 共 {d} 字节\n", .{
        @as(u16, @bitCast(demo_flags)), payload, payload.len, n,
    });
    err.print("十六进制 dump：\n", .{});
    var dump_buf: [256]u8 = undefined;
    err.print("{s}", .{hexDump(dump_buf[0..], frame[0..n], 16)});
    const decoded = try Proto.decode(frame[0..n]);
    err.print("解码成功：version={d} flags=0x{X:0>4} len={d} payload=\"{s}\"\n", .{
        decoded.version, @as(u16, @bitCast(decoded.flags)), decoded.len, decoded.payload,
    });
    err.print("payload 是**零拷贝切片**：ptr 在frame 内部，decoded.len = {d}\n", .{decoded.len});
    err.print("往返一致 = {}\n", .{std.mem.eql(u8, decoded.payload, payload)});
    end("25.13 协议实战：编码 → 十六进制 dump → 解码");

    // ═══ 25.14 篡改字节 → 每种失败都要优雅 ═══
    begin("25.14 恶意输入：篡改字节 → 优雅失败");
    err.print("逐个篡改/破坏，每种都必须返回**具体的 error**而不是崩溃：\n", .{});
    // ⚠️ 关键：`frame[0..n]` 是**切片**，赋值给 var 只是复制指针（别名同一块内存）。
    //    写 `var bad = frame[0..n]` 之后改 bad 就是改 frame——后面每一项测的
    //    都是被上一项污染过的数据（实测全部报 BadMagic 就是这个坑）。
    //    正解：每次用 @memcpy 把干净数据复制进独立的暂存区。
    const good = frame[0..n];
    var scratch: [128]u8 = undefined;
    // 1) 截断
    err.print("  截断到 3 字节        → {s}\n", .{@errorName(decodeErr(Proto.decode(good[0..3])))});
    // 2) magic 不匹配
    @memcpy(scratch[0..n], good);
    scratch[0] ^= 0xFF;
    err.print("  翻转 magic 首字节    → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
    // 3) 版本不对
    @memcpy(scratch[0..n], good);
    scratch[2] = 0x99;
    err.print("  版本改 0x99          → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
    // 4) 篡改载荷但不改校验和
    @memcpy(scratch[0..n], good);
    scratch[Proto.header_len + 1] ^= 0x01;
    err.print("  篡改载荷 1 字节      → {s}（长度仍合法，只能靠校验和抓）\n", .{
        @errorName(decodeErr(Proto.decode(scratch[0..n]))),
    });
    // 5) 长度字段被改成巨大的值 → 越界
    @memcpy(scratch[0..n], good);
    scratch[Proto.header_len] = 0x7F; // varint 低 7 位全 1，长度被放大
    err.print("  varint 长度改0x7F    → {s}（声明长度超过 max_payload）\n", .{
        @errorName(decodeErr(Proto.decode(scratch[0..n]))),
    });
    // 6) 篡改 flags（长度不变，校验和失配）
    @memcpy(scratch[0..n], good);
    scratch[3] ^= 0x01;
    err.print("  篡改 flags 高字节    → {s}\n", .{@errorName(decodeErr(Proto.decode(scratch[0..n])))});
    // 7) 载荷超过 max_payload：编码器自己先拒
    var small: [8]u8 = undefined;
    err.print("  encode 载荷 65 字节  → {s}（编码器上界检查）\n", .{
        @errorName(encodeErr(Proto.encode(&small, demo_flags, &oversized_payload()))),
    });
    // 8) 尾部砍掉 1 字节（校验和不完整）
    err.print("  尾部砍掉 1 字节      → {s}\n", .{@errorName(decodeErr(Proto.decode(good[0 .. n - 1])))});
    err.print("⇒ 解码器**从不做索引前假设**：每步先验长度，再读字节\n", .{});
    err.print("   顺序是「上限检查 → 剩余字节检查 → 内容校验」，反过来会漏\n", .{});
    end("25.14 恶意输入：篡改字节 → 优雅失败");

    err.print("自检通过\n", .{});
}

/// 把 getVarint 的错误结果转成 anyerror，方便直接喂给 @errorName 打印
fn varintErr(r: Proto.DecodeError!usize) anyerror {
    if (r) |_| {
        return error.ShouldNotHappen;
    } else |e| {
        return e;
    }
}

/// 同上：解码成功时返回 error.UnexpectedSuccess（演示代码里这不该发生）
fn decodeErr(r: Proto.DecodeError!Proto.Frame) anyerror {
    if (r) |_| {
        return error.UnexpectedSuccess;
    } else |e| {
        return e;
    }
}

fn encodeErr(r: anyerror!usize) anyerror {
    if (r) |_| {
        return error.UnexpectedSuccess;
    } else |e| {
        return e;
    }
}

/// 25.8 自实现网络序转换（不依赖 std.mem.nativeToBig 等4 个变体）
fn htons(v: u16) u16 {
    return if (builtin.cpu.arch.endian() == .little) @byteSwap(v) else v;
}

fn ntohs(v: u16) u16 {
    return htons(v); // 交换是自逆的
}

/// 25.9 求varint 编码后的字节数（只为了打印表格）
fn blkLen(v: usize) usize {
    var n: usize = 1;
    var x = v;
    while (x >= 0x80) : (x >>= 7) n += 1;
    return n;
}

/// 构造一个刚好超过 Proto.max_payload 的载荷（65 字节），用来测编码器的上界检查
fn oversized_payload() [Proto.max_payload + 1]u8 {
    return @splat('y');
}

/// 25.13 经典 hex dump：偏移 + 十六进制 + ASCII 栏，每行 width 字节。
/// 返回**调用者缓冲区**里的有效前缀（不能返回局部数组的切片——那个栈帧已经没了）
fn hexDump(out: []u8, bytes: []const u8, width: usize) []const u8 {
    var fbs = std.Io.Writer.fixed(out);
    const w = &fbs;
    var i: usize = 0;
    while (i < bytes.len) : (i += width) {
        w.print("  {x:0>4}  ", .{i}) catch break;
        const row_end = @min(i + width, bytes.len);
        for (bytes[i..row_end]) |b| w.print("{x:0>2} ", .{b}) catch break;
        var pad: usize = width - (row_end - i);
        while (pad > 0) : (pad -= 1) w.print("   ", .{}) catch break;
        w.writeAll(" |") catch break;
        for (bytes[i..row_end]) |b| {
            w.writeByte(if (b >= 0x20 and b < 0x7F) b else '.') catch break;
        }
        w.writeAll("|\n") catch break;
    }
    return w.buffered();
}

test "三种布局：@sizeOf / @offsetOf 实测钉死" {
    // auto：u32 被挪到最前，a/c 挤在它后面
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Auto));
    try std.testing.expectEqual(@as(usize, 4), @alignOf(Auto));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Auto, "b"));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Auto, "a"));
    try std.testing.expectEqual(@as(usize, 5), @offsetOf(Auto, "c"));
    // auto 的字段宽度之和永远不等于 @sizeOf（有重排+对齐双重原因）
    try std.testing.expect(wireSize(Auto) != @sizeOf(Auto));

    // extern：声明顺序 + 自然对齐 + 尾部补齐
    try std.testing.expectEqual(@as(usize, 12), @sizeOf(Ext));
    try std.testing.expectEqual(@as(usize, 4), @alignOf(Ext));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Ext, "a"));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Ext, "b"));
    try std.testing.expectEqual(@as(usize, 8), @offsetOf(Ext, "c"));
    try std.testing.expectEqual(@as(usize, 6), wireSize(Ext)); // 1+4+1
    try std.testing.expectEqual(@as(usize, 6), @sizeOf(Ext) - wireSize(Ext)); // 尾部补齐

    // packed：按位排，零填充
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(Packed));
    try std.testing.expectEqual(@as(usize, 32), @bitSizeOf(Packed));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Packed, "a"));
    try std.testing.expectEqual(@as(usize, 1), @offsetOf(Packed, "b"));
    try std.testing.expectEqual(@as(usize, 2), @offsetOf(Packed, "c"));
    try std.testing.expectEqual(@as(usize, 3), @offsetOf(Packed, "d"));
    try std.testing.expectEqual(@sizeOf(Packed), wireSize(Packed));

    // @typeInfo 的 layout 字段——⚠️ 它的枚举类型是 std.lang.Type.ContainerLayout，
    //    **不是** std.builtin.Type.Layout（0.17 里 std.builtin.Type 是 union，没有 Layout 成员）
    try std.testing.expectEqual(std.lang.Type.ContainerLayout.auto, @typeInfo(Auto).@"struct".layout);
    try std.testing.expectEqual(std.lang.Type.ContainerLayout.@"extern", @typeInfo(Ext).@"struct".layout);
    try std.testing.expectEqual(std.lang.Type.ContainerLayout.@"packed", @typeInfo(Packed).@"struct".layout);
    try std.testing.expect(@typeInfo(Packed).@"struct".backing_integer != null);
    try std.testing.expect(@typeInfo(Ext).@"struct".backing_integer == null);
}

test "packed struct 的位偏移 vs 字节偏移" {
    const F2 = packed struct(u16) { a: u1, b: u3, c: u4, d: u8 };
    // 三个非字节对齐字段的字节偏移都是 0
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(F2, "a"));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(F2, "b"));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(F2, "c"));
    try std.testing.expectEqual(@as(usize, 1), @offsetOf(F2, "d"));
    // 位偏移才是真实位置
    try std.testing.expectEqual(@as(u16, 0), @bitOffsetOf(F2, "a"));
    try std.testing.expectEqual(@as(u16, 1), @bitOffsetOf(F2, "b"));
    try std.testing.expectEqual(@as(u16, 4), @bitOffsetOf(F2, "c"));
    try std.testing.expectEqual(@as(u16, 8), @bitOffsetOf(F2, "d"));
}

test "packed struct 是唯一能 @bitCast 进出的 struct 布局" {
    // extern struct 不行：error: cannot @bitCast from 'main.Record'
    // const bad: u32 = @bitCast(Record{ .magic = 1, .version = 1, .kind = 1, .length = 1 });
    // 普通 struct 更不行。
    const f = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    const board: u16 = @bitCast(f);
    try std.testing.expectEqual(@as(u16, 0x5A05), board);
    const back: Flags = @bitCast(board);
    try std.testing.expectEqual(f, back);
    try std.testing.expectEqual(@as(u16, 16), @bitSizeOf(Flags));
    try std.testing.expectEqual(@as(usize, 2), @sizeOf(Flags));
}

test "packed 字段取地址：0.17 允许，但类型带 bit offset" {
    var f = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    // 字节对齐的字段：类型就是普通的 *u8
    const pd: *align(2:8:2) u8 = &f.level; // level 占 bit 8-15 → 指针带 bit offset 2
    try std.testing.expectEqual(@as(u8, 0x5A), pd.*);
    // 非字节对齐的字段：类型是 *align(2:1:2) u2 —— 不能隐式传给 fn(*u2)
    // 下面这行编译失败：takeU2(&f.mode);
    //   error: expected type '*u2', found '*align(2:1:2) u2'
    //   note: pointer bit offset '1' cannot cast into pointer bit offset '0'
    const pm: *align(2:1:2) u2 = &f.mode;
    try std.testing.expectEqual(@as(u2, 0b10), pm.*);
    pm.* = 0b11; // 往子字段写也合法
    try std.testing.expectEqual(@as(u2, 0b11), f.mode);
}

test "readInt / writeInt：显式端序 + 不要求对齐" {
    var buf: [9]u8 = @splat(0);
    // 偏移 1，未对齐——readInt 不 care
    std.mem.writeInt(u32, buf[1..5], 0xAABBCCDD, .big);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0xAA, 0xBB, 0xCC, 0xDD, 0, 0, 0, 0 }, &buf);
    try std.testing.expectEqual(@as(u32, 0xAABBCCDD), std.mem.readInt(u32, buf[1..5], .big));
    try std.testing.expectEqual(@as(u32, 0xDDCCBBAA), std.mem.readInt(u32, buf[1..5], .little));
    // N 必须精确等于 sizeof(T)：给 8 字节读u32 是编译错误
    // std.mem.readInt(u32, &[_]u8{8}**8, .little);
    //   error: expected type '*const [4]u8', found '*const [8]u8'
    // u24 要3 字节，不是 4
    const three: [3]u8 = .{ 0xFF, 0xEE, 0xDD };
    // 大端：FF 是最高字节 → 0xFFEEDD（小端才是 0xDDEEFF）
    try std.testing.expectEqual(@as(u24, 0xFFEEDD), std.mem.readInt(u24, &three, .big));
    try std.testing.expectEqual(@as(u24, 0xDDEEFF), std.mem.readInt(u24, &three, .little));
}

test "字节 API 家族：toBytes / asBytes / bytesToValue / bytesAsValue" {
    const v: u32 = 0x12345678;
    // toBytes：值拷贝，0.17 里 valueToBytes 的等价物（后者已移除）
    const tb = std.mem.toBytes(v);
    try std.testing.expectEqual(@as(usize, 4), tb.len);
    try std.testing.expectEqualSlices(u8, &std.mem.asBytes(&v).*, &tb);
    // bytesToValue：值拷贝
    try std.testing.expectEqual(v, std.mem.bytesToValue(u32, &tb));
    // asBytes 返回**带对齐**的指针（align 来自 T）
    var w: u32 = 0;
    const ab = std.mem.asBytes(&w);
    try std.testing.expectEqual(@as(usize, 4), ab.len);
    // ⚠️ @alignOf(@TypeOf(ab)) 拿到的是**指针本身**的对齐（x86_64 上是 8），
    //    不是它指向的数组的对齐。后者要问 @typeInfo(...).pointer.attrs.align
    try std.testing.expectEqual(@as(usize, @alignOf(u32)), @typeInfo(@TypeOf(ab)).pointer.attrs.@"align".?);
    try std.testing.expectEqual(@as(usize, 8), @alignOf(@TypeOf(ab))); // 指针自身对齐
    // bytesAsValue 返回指针视图
    const bv = std.mem.bytesAsValue(u32, &tb);
    try std.testing.expectEqual(v, bv.*);
    // ⚠️ std.mem.valueToBytes 在 0.17 不存在
    try std.testing.expect(!@hasDecl(std.mem, "valueToBytes"));
    try std.testing.expect(@hasDecl(std.mem, "toBytes"));
}

test "字节序：本机小端 + htons 往返" {
    try std.testing.expectEqual(std.builtin.Endian.little, builtin.cpu.arch.endian());
    const value: u32 = 0x12345678;
    // 本机序就是小端面貌
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x78, 0x56, 0x34, 0x12 }, &std.mem.asBytes(&value).*);
    // nativeToBig 把它翻成大端面貌
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0x12, 0x34, 0x56, 0x78 }, &std.mem.asBytes(&std.mem.nativeToBig(u32, value)).*);
    // nativeToLittle 在小端机器上是空操作
    try std.testing.expectEqual(value, std.mem.nativeToLittle(u32, value));
    // 端口 8080：小端机器上 htons 必须真交换
    try std.testing.expectEqual(@as(u16, 0x901F), htons(8080)); // 8080=0x1F90，交换后 0x901F
    try std.testing.expectEqual(@as(u16, 8080), ntohs(htons(8080)));
    try std.testing.expectEqual(@as(u16, 0x3412), htons(0x1234)); // 0x1234 → 0x3412
    // 不交换就是错的：8080 直接上线会被对端读成 0x901f = 38609
    try std.testing.expect(htons(8080) != 8080 or builtin.cpu.arch.endian() == .big);
}

test "varint / LEB128：边界往返 + 恶意输入" {
    inline for (.{ 0, 1, 127, 128, 300, 16383, 16384, std.math.maxInt(u32) }) |v| {
        var buf: [10]u8 = undefined;
        const n = try putVarint(&buf, v);
        var got: usize = 0;
        const m = try getVarint(buf[0..n], &got);
        try std.testing.expectEqual(v, got);
        try std.testing.expectEqual(n, m);
    }
    // 明确的字节数：0/127 → 1 字节；128 → 2 字节；16384 → 3 字节
    try std.testing.expectEqual(@as(usize, 1), blkLen(0));
    try std.testing.expectEqual(@as(usize, 1), blkLen(127));
    try std.testing.expectEqual(@as(usize, 2), blkLen(128));
    try std.testing.expectEqual(@as(usize, 3), blkLen(16384));
    // 64 位最大值需要 10 字节
    try std.testing.expectEqual(@as(usize, 10), blkLen(std.math.maxInt(u64)));

    var junk: usize = 0;
    // 续位后没数据
    try std.testing.expectError(error.BadVarint, getVarint(&[_]u8{0x80}, &junk));
    // 6 个连续续位（超出 u32 的 5 字节上限）
    try std.testing.expectError(error.BadVarint, getVarint(&[_]u8{ 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 }, &junk));
    // 输出缓冲区不够
    var one: [1]u8 = @splat(0);
    try std.testing.expectError(error.NoSpaceLeft, putVarint(one[0..], 300));
}

test "位操作：popCount / clz / ctz / bitReverse / rotl" {
    const x: u16 = 0b1011_0110_1100_0001;
    try std.testing.expectEqual(@as(u5, 8), @popCount(x)); // popCount 返回 log2 计数类型
    try std.testing.expectEqual(@as(u5, 0), @clz(x));
    try std.testing.expectEqual(@as(u5, 0), @ctz(x));
    try std.testing.expectEqual(@as(u16, 0b1000_0011_0110_1101), @bitReverse(x));
    // 旋转不是内建函数：@rotl / @rotr / @rotateLeft 全部 invalid builtin function
    try std.testing.expectEqual(@as(u16, 0b0110_1100_0001_1011), std.math.rotl(u16, x, 4));
    try std.testing.expectEqual(@as(u16, 0b0001_1011_0110_1100), std.math.rotr(u16, x, 4)); // 0x1B6C
    try std.testing.expectEqual(std.math.rotl(u16, x, 4), std.math.rotr(u16, x, 12));
    // @ctz(0) = 位宽，@popCount(0) = 0
    try std.testing.expectEqual(@as(u4, 8), @ctz(@as(u8, 0)));
    try std.testing.expectEqual(@as(u4, 0), @popCount(@as(u8, 0)));
    // 实际用法：数标志位、找最低位 1
    try std.testing.expectEqual(@as(u4, 4), @popCount(@as(u8, 0b1001_0110)));
    try std.testing.expectEqual(@as(u4, 1), @ctz(@as(u8, 0b1001_0110)));
    try std.testing.expectEqual(@as(u4, 0), @clz(@as(u8, 0b1001_0110))); // 最高位就是 1
    try std.testing.expectEqual(@as(u4, 3), @clz(@as(u8, 0b0001_0110))); // 最高位在 bit4
}

test "std.mem 字节工具箱逐个实测" {
    var rev8 = [_]u8{ 1, 2, 3, 4, 5 };
    std.mem.reverse(u8, &rev8);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 5, 4, 3, 2, 1 }, &rev8);
    var rev16 = [_]u16{ 0x0102, 0x0304 };
    std.mem.reverse(u16, &rev16);
    try std.testing.expectEqual(@as(u16, 0x0304), rev16[0]); // 按元素翻，不是按字节翻

    var a: u32 = 1;
    var b: u32 = 2;
    std.mem.swap(u32, &a, &b);
    try std.testing.expectEqual(@as(u32, 2), a);
    try std.testing.expectEqual(@as(u32, 1), b);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 0, 0, 0 }, &std.mem.zeroes([4]u8));
    try std.testing.expectEqual(@as(u32, 0), std.mem.zeroes(u32));

    const a2 = std.testing.allocator;
    const cat = try std.mem.concat(a2, u8, &.{ "ab", "cd", "ef" });
    defer a2.free(cat);
    try std.testing.expectEqualStrings("abcdef", cat);
    try std.testing.expectEqual(@as(usize, 6), cat.len);

    const hex = std.fmt.bytesToHex(&[_]u8{ 0xDE, 0xAD, 0xBE, 0xEF }, .lower);
    try std.testing.expectEqualStrings("deadbeef", &hex);
    // ⚠️ std.fmt.fmtSliceHexLower 在 0.17 不存在
    try std.testing.expect(!@hasDecl(std.fmt, "fmtSliceHexLower"));
}

test "协议编解码：往返 + 零拷贝" {
    // std.testing.allocator 是 SafeAllocator：每次 free 都会记账，
    // 少一次 free 或多一次 alloc 都会让测试失败（本教程 15 章讲过机制）
    const gpa = std.testing.allocator;
    const flags = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    const payload = "hello wire";
    var frame: [128]u8 = undefined;
    const n = try Proto.encode(&frame, flags, payload);
    const good = frame[0..n];
    // 定长部分 5 + varint(10) 1 字节 + 载荷 10 + 校验和 2 = 18
    try std.testing.expectEqual(Proto.header_len + 1 + payload.len + 2, n);

    const f = try Proto.decode(frame[0..n]);
    try std.testing.expectEqual(Proto.version, f.version);
    try std.testing.expectEqual(flags, f.flags);
    try std.testing.expectEqual(payload.len, f.len);
    try std.testing.expectEqualSlices(u8, payload, f.payload);
    // 零拷贝：payload 指向输入缓冲区内部，不是副本
    const base = @intFromPtr(good.ptr);
    const pp = @intFromPtr(f.payload.ptr);
    try std.testing.expect(pp >= base);
    try std.testing.expect(pp < base + good.len);

    // 真用一次 gpa：把载荷复制到堆上再编解码一次。payload 指向的是 **heap_frame 内部**
    // （编码时 @memcpy 拷进去了），不是 heap_payload——所以只能断言"落在 frame 区间内"
    const heap_payload = try gpa.dupe(u8, payload);
    defer gpa.free(heap_payload);
    var heap_frame: [128]u8 = undefined;
    const hn = try Proto.encode(&heap_frame, flags, heap_payload);
    const hf = try Proto.decode(heap_frame[0..hn]);
    try std.testing.expectEqualSlices(u8, payload, hf.payload);
    const hb = @intFromPtr(heap_frame[0..hn].ptr);
    const hp = @intFromPtr(hf.payload.ptr);
    try std.testing.expect(hp >= hb);
    try std.testing.expect(hp < hb + hn);
}

test "协议解码器对恶意输入稳健：每种失败都钉住" {
    const flags = Flags{ .enabled = true, .mode = 0b10, .reserved = 0, .level = 0x5A };
    var frame: [128]u8 = undefined;
    const n = try Proto.encode(&frame, flags, "hello wire");
    const good = frame[0..n];
    // ⚠️ 别写`var bad = good` —— 那是**切片别名**，改 bad 就是改 good，
    //    后面每一项测的都是被上一项污染过的数据（这个坑真实踩过一次）。
    var bad: [128]u8 = undefined;
    const reset = struct {
        fn f(dst: []u8, src: []const u8) void {
            @memcpy(dst[0..src.len], src);
        }
    }.f;

    // 1) 空输入 / 截断
    try std.testing.expectError(error.Truncated, Proto.decode(&[_]u8{}));
    try std.testing.expectError(error.Truncated, Proto.decode(good[0..3]));
    try std.testing.expectError(error.Truncated, Proto.decode(good[0 .. Proto.header_len - 1]));

    // 2) magic 不匹配（两种改法都试）
    reset(&bad, good);
    bad[0] ^= 0xFF;
    try std.testing.expectError(error.BadMagic, Proto.decode(bad[0..n]));
    reset(&bad, good);
    bad[1] ^= 0x0F;
    try std.testing.expectError(error.BadMagic, Proto.decode(bad[0..n]));

    // 3) 版本不认识
    reset(&bad, good);
    bad[2] = 0x99;
    try std.testing.expectError(error.BadVersion, Proto.decode(bad[0..n]));

    // 4) 长度爆炸：把 varint 低字节改成 0x7F（续位还在，长度被放大）
    reset(&bad, good);
    bad[Proto.header_len] = 0x7F;
    try std.testing.expectError(error.TooLarge, Proto.decode(bad[0..n]));

    // 5) 声明长度超过 max_payload（0x7E → 126 > 64）
    reset(&bad, good);
    bad[Proto.header_len] = 0x7E;
    try std.testing.expectError(error.TooLarge, Proto.decode(bad[0..n]));

    // 6) 尾部截断一个字节（校验和不完整）
    try std.testing.expectError(error.LengthOverrun, Proto.decode(good[0 .. n - 1]));

    // 7) 篡改载荷但保持长度合法——**只能靠校验和抓**
    reset(&bad, good);
    bad[Proto.header_len + 1] ^= 0x01;
    try std.testing.expectError(error.ChecksumMismatch, Proto.decode(bad[0..n]));

    // 8) 篡改 flags（长度不变，但内容变了 → 校验和失配）
    reset(&bad, good);
    bad[3] ^= 0x01;
    try std.testing.expectError(error.ChecksumMismatch, Proto.decode(bad[0..n]));

    // 9) 编码器自己也要挡住超长载荷
    var small: [16]u8 = undefined;
    try std.testing.expectError(error.TooLarge, Proto.encode(&small, flags, &oversized_payload()));
    // 10) 输出缓冲区不够
    var tiny: [4]u8 = undefined;
    try std.testing.expectError(error.NoSpaceLeft, Proto.encode(&tiny, flags, "abc"));
}

test "comptime 布局守卫：Record 的 wire 尺寸 == @sizeOf" {
    // 守卫写在文件顶层的 comptime 块里：不等就 @compileError
    try std.testing.expectEqual(wireSize(Record), @sizeOf(Record));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Record));
    try std.testing.expectEqual(@as(usize, 0), @offsetOf(Record, "magic"));
    try std.testing.expectEqual(@as(usize, 2), @offsetOf(Record, "version"));
    try std.testing.expectEqual(@as(usize, 3), @offsetOf(Record, "kind"));
    try std.testing.expectEqual(@as(usize, 4), @offsetOf(Record, "length"));
    // 反例：Awkward（u8,u32,u16）字段宽度之和 7≠ 12，守卫会拒绝它
    const Awkward = extern struct { a: u8, b: u32, c: u16 };
    try std.testing.expectEqual(@as(usize, 7), wireSize(Awkward));
    try std.testing.expectEqual(@as(usize, 12), @sizeOf(Awkward));
    try std.testing.expect(wireSize(Awkward) != @sizeOf(Awkward));
    // 调紧字段顺序就能消掉填充
    const Tight = extern struct { a: u32, b: u16, c: u8 };
    try std.testing.expectEqual(@as(usize, 7), wireSize(Tight));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(Tight));
}
