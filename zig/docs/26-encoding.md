# 26 · 编码与流处理

> 对应示例：`examples/26_encoding/main.zig`（1451 行，18 个测试）
>
> hex、Base64、URL 百分号编码、压缩、哈希、SIMD 计数——数据处理工具的六件基本功，
> 外面套一层「流与字节序列的关系」。取材 Systems Programming with Zig ch4：
> z64（Base64 工具）、zwc（高性能字数统计）与 SIMD 词计数。
>
> 本章有三条结论会**推翻你可能听过的说法**，全部是 0.17.0 上实测的（不是文档摘抄，
> 每条都有对应的输出或测试断言）：
>
> 1. **`readSliceShort` 不是"读一点"**。它是"填满缓冲或读到 EOF"语义，
>    源码里就是一个 `while (true) { readVec }`（`lib/std/Io/Reader.zig` 第 696-703 行）。
> 2. **`takeDelimiterExclusive` 在 0.17 会空转**。第一次拿到数据，之后**永远**返回
>    长度为 0 的空片且**不报错**——上层写 `while (true)` 就是死循环刷屏。
>    这不是网络流特有的问题，**文件 Reader 上一样**（实测见 26.3）。
> 3. **`Reader.fixed` 上 `fillMore()` 直接返回 `error.EndOfStream`**，
>    哪怕缓冲里明明有数据。所以"fillMore 三件套"不是万能的正确姿势，
>    它有明确的前置条件（26.2 讲清）。
>
> 另外，本章把 0.17 移除 `**` 运算符这件迁移讲透了（26.12）——它不是"不能用重复"，
> 而是**换了三种替代品**，其中"自己写 comptime 函数"顺带是 comptime 教学的最好例子。

---

## 26.1 流与字节序列：Reader/Writer 为什么是通用抽象

先把概念摆正：**流不是"文件"，流是"一段还没被读走的字节"**。文件、socket、内存切片、
管道、base64 解码器的输出——它们在 `std.Io` 这一层是**同一种东西**：一个可以按顺序取字节的源。
这就是为什么 `Reader`/`Writer` 这对抽象能吃下所有这些场景：处理逻辑只跟"取字节"打交道，
不关心字节从哪来。

`std.Io.Reader` 的全部状态就是四个字段（实测反射出来的，不是猜的）：

```zig
// examples/26_encoding/main.zig 第 313-325 行
    // ═══ 26.1 流与字节序列：Reader/Writer 是这个问题的通用抽象 ═══
    begin("26.1 流与字节序列");
    err.print("流 = 「一段还没被读走的字节」。Reader 把它切成块，Writer 把它接成块。\n", .{});
    err.print("std.Io.Reader 是 { vtable, buffer, seek, end } 四个字段（实测）：\n", .{});
    inline for (@typeInfo(std.Io.Reader).@"struct".field_names) |f| {
        err.print("  .{s}\n", .{f});
    }
    err.print("buffer 是 Reader **自己拥有**的可写缓冲；seek 是已消费位置，end 是已填充位置。\n", .{});
    err.print("buffered() = buffer[seek..end]—— 「已经到手、还没读走」的那一段。\n", .{});
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.1 流与字节序列 开始 ====
流 = 「一段还没被读走的字节」。Reader 把它切成块，Writer 把它接成块。
std.Io.Reader 是 { vtable, buffer, seek, end } 四个字段（实测）：
  .vtable
  .buffer
  .seek
  .end
buffer 是 Reader **自己拥有**的可写缓冲；seek 是已消费位置，end 是已填充位置。
buffered() = buffer[seek..end]—— 「已经到手、还没读走」的那一段。
同一份「按分隔符切分」逻辑可以跑在文件、内存切片、网络流上，这就是通用抽象。
Reader 家族构造：Reader.fixed(切片) / file.reader(io, buf) / stream.reader(io, buf)
Writer 家族构造：Writer.fixed(切片) / Allocating.init(gpa) / file.writer(io, buf)
```

四个字段各管一件事：

| 字段 | 类型 | 作用 |
|---|---|---|
| `.vtable` | `*const VTable` | 后端（文件读/socket 读/内存切片），四个函数指针 |
| `.buffer` | `[]u8` | Reader **自己拥有**的可写缓冲 |
| `.seek` | `usize` | 已消费位置 |
| `.end` | `usize` | 已填充位置 |

`buffer[0..seek]` 是已读走并可被复用的空间，`buffer[seek..end]` 是**已经到手、还没读走**的数据，
`buffer[end..]` 是还能填的空闲空间。所以 `buffered()` 就是 `buffer[seek..end]` 的切片——
**零拷贝**，不复制。

### `Reader.fixed`：把一个切片变成流

```zig
// examples/26_encoding/main.zig 第 326-335 行
        var r = std.Io.Reader.fixed("hello world");
        err.print("\n  Reader.fixed(\"hello world\")：buffer.len={d} end={d} seek={d} bufferedLen={d}\n", .{
            r.buffer.len, r.end, r.seek, r.bufferedLen(),
        });
        err.print("  它把整个切片**直接当已缓冲数据**（.end = buffer.len），所以一次 readSliceAll 就全拿到。\n", .{});
        var buf: [64]u8 = undefined;
        const msg = "hello world";
        try r.readSliceAll(buf[0..msg.len]);
        err.print("  readSliceAll(buf[0..{d}]) -> «{s}》（缓冲必须**正好**是长度；填 64 会报 EndOfStream）\n", .{ msg.len, buf[0..msg.len] });
```

运行输出（`examples/26_encoding/main.zig`）：

```text
  Reader.fixed("hello world")：buffer.len=11 end=11 seek=0 bufferedLen=11
  它把整个切片**直接当已缓冲数据**（.end = buffer.len），所以一次 readSliceAll 就全拿到。
  readSliceAll(buf[0..11]) -> «hello world»（缓冲必须**正好**是长度；填 64 会报 EndOfStream）
```

`Reader.fixed` 的源码（`Io/Reader.zig` 第 152-166 行）里 `buffer` 是 `@constCast(buffer)`、
`end = buffer.len`——**整个切片瞬间变成"已缓冲数据"**。这是测试的万能道具，
但它有个重要副作用，26.2 会实测到：**它不能 `fillMore`**。

⚠️ 顺带一个实测到的点：`readSliceAll` 要求缓冲**正好**是数据长度。传 `buf[0..64]`
而数据只有 11 字节，会报 `error.EndOfStream`（源码第 672 行：`if (n != buffer.len) return error.EndOfStream`）。

`Writer.fixed` 是对称的：落调用方的栈缓冲，写完用 `buffered()` 取，**不需要 flush**。

```zig
// examples/26_encoding/main.zig 第 336-342 行
        var sbuf: [64]u8 = undefined;
        var w = std.Io.Writer.fixed(&sbuf);
        try w.print("Writer.fixed 落到调用方的栈缓冲上：{s}", .{"ok"});
        err.print("  {s}（{d} 字节，无需 flush）\n", .{ w.buffered(), w.buffered().len });
        err.print("  ⚠️ 缓冲写满会报 error.WriteFailed（不是静默截断）\n", .{});
```

运行输出（`examples/26_encoding/main.zig`）：

```text
  Writer.fixed 落到调用方的栈缓冲上：ok（48 字节，无需 flush）
  ⚠️ 缓冲写满会报 error.WriteFailed（不是静默截断）
```

## 26.2 正确的「读一段」姿势：fillMore + buffered + toss

**这是本章最该抄走的一节。** 它同时讲清两件事：`readSliceShort` 为什么不能当单次 read 用，
以及"三件套"该在什么条件下用。

### ⚠️ `readSliceShort` 是"填满或 EOF"，不是单次 read

名字里的 "Short" 指的是**返回值可能小于请求长度**，而不是"读到一点就返回"。
看源码（`Io/Reader.zig` 第 685-704 行）：

```zig
pub fn readSliceShort(r: *Reader, buffer: []u8) ShortError!usize {
    const contents = r.buffer[r.seek..r.end];
    const copy_len = @min(buffer.len, contents.len);
    @memcpy(buffer[0..copy_len], contents[0..copy_len]);
    r.seek += copy_len;
    if (buffer.len - copy_len == 0) {
        @branchHint(.likely);
        return buffer.len;          // ← 填满了立刻返回
    }
    var i: usize = copy_len;
    var data: [1][]u8 = undefined;
    while (true) {                   // ← 否则死循环读到底
        data[0] = buffer[i..];
        i += readVec(r, &data) catch |err| switch (err) {
            error.EndOfStream => return i,
            error.ReadFailed => |e| return e,
        };
        if (buffer.len - i == 0) return buffer.len;
    }
}
```

**它在没有新数据的流上会一直等。** 拿它当"读一点来看看到底还有多少"的探测用，
在 socket 上就是一个挂死的程序。实测（文件 22 字节、请求 16 字节缓冲）：

```zig
// examples/26_encoding/main.zig 第 346-364 行
    // ═══ 26.2 正确的「读一段」姿势：fillMore + buffered + toss ═══
    begin("26.2 读一段：fillMore + buffered + toss");
    err.print("⚠️ readSliceShort 是「**填满缓冲或读到 EOF**」语义，不是单次 read：\n", .{});
    err.print("   它内部是while(true) {{ readVec }} 直到 buffer 满或 EndOfStream（Io/Reader.zig:696-703）。\n", .{});
    err.print("   拿它当「读一点」用，在没有新数据的流上会一直等。\n", .{});
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.2 读一段：fillMore + buffered + toss 开始 ====
⚠️ readSliceShort 是「**填满缓冲或读到 EOF**」语义，不是单次 read：
   它内部是while(true) { readVec } 直到 buffer 满或 EndOfStream（Io/Reader.zig:696-703）。
   拿它当「读一点」用，在没有新数据的流上会一直等。
  文件共 22 字节；readSliceShort(&chunk[16]) = 16
  ⇒ 它果然读满了 16（而不是「有多少读多少」）；剩下 8 字节留在缓冲里。
```

对比 `readSliceAll`：它更严格——**填不满就报错**。所以两者的错误集不同
（`ShortError` 里没有 `EndOfStream`，`Error` 里有）。

实测序列（源 10 字节、缓冲 4 字节）：`4, 4, 2, 0`。只有真的不够了才短读，
这是测试块 `"readSliceShort 是「填满或 EOF」而不是单次 read"` 锁死的行为。

### 三件套：`fillMore()` + `buffered()` + `toss()`

```zig
// examples/26_encoding/main.zig 第 50-67 行
// ═══ 26.4 的正确姿势：手工按分隔符切分（不依赖 takeDelimiter*）═══════════

/// 通用"读一段"：fillMore + buffered + toss 三件套。
/// 返回 false 表示流已结束（fillMore 报 EndOfStream）。
/// ⚠️ 只能在**缓冲区归Reader 所有**的环境用（File.Reader / net.Stream.Reader）；
/// `Reader.fixed` 的 buffer 是只读别名，fillMore 会直接报 EndOfStream。
fn readChunk(r: *std.Io.Reader) !?[]const u8 {
    r.fillMore() catch |err| switch (err) {
        error.EndOfStream => return null,
        error.ReadFailed => |e| return e,
    };
    const avail = r.buffered();
    if (avail.len == 0) return null;
    return avail;
}
```

⚠️ **`fillMore` 返回 `error!void`，不是 `void`**。这是 0.17 的形状——很多教程写 `r.fillMore();`
然后以为"没抛错就是有数据"，那样写会在 EOF 时漏掉。实测逐轮输出：

```text
  三件套逐轮实测：
    第 1 轮 fillMore 后 bufferedLen=22，内容 = «alpha
beta
gamma
delta»
    第 2 轮 fillMore -> EndOfStream← EOF 信号（fillMore **返回错误**，不是 void）
```

`fillMore` 的语义是"**做一次**底层读，尽可能多填"。它可能填进 0 字节而**不是** EOF
（源码注释原文：*"This may result in zero bytes added to the buffer, which is not an end of
stream condition"*）。所以别写"fillMore 返回了就是有数据"的假设——要检查 `bufferedLen()`。

### ⚠️ 但三件套在 `Reader.fixed` 上不成立

这是实测出来的一条硬边界，也是本章最容易被"三件套万能论"漏掉的：

```text
  ⚠️ 但 Reader.fixed 上fillMore 会失败：
    fixed("hello\nworld").fillMore() -> EndOfStream（尽管 bufferedLen=11 明明有数据）
    原因：fillMore 先 rebase(capacity=1)，fixed 的 vtable.rebase = endingRebase → EndOfStream。
    ⇒ fixed 上直接用 buffered() + toss()，别碰 fillMore。
```

机制：`fillMore` 的第一行是 `try rebase(r, r.end - r.seek + 1)`（`Io/Reader.zig` 第 1155 行）。
`Reader.fixed` 的 vtable 里 `.rebase = endingRebase`，而 `endingRebase` 无条件
`return error.EndOfStream`（第 1429 行）。所以**只要数据已经全在缓冲里了，fillMore 反而失败**。

对应的测试直接把这个行为锁死：

```zig
// examples/26_encoding/main.zig 第 1217-1228 行
test "Reader.fixed 上 fillMore 报EndOfStream（buffer 是只读别名）" {
    var r = std.Io.Reader.fixed("hello\nworld");
    // 整个切片就是已缓冲数据
    try std.testing.expectEqual(@as(usize, 11), r.bufferedLen());
    try std.testing.expectEqualStrings("hello\nworld", r.buffered());
    // 但 fillMore 会先 rebase(capacity=1) → fixed 的 endingRebase → EndOfStream
    try std.testing.expectError(error.EndOfStream, r.fillMore());
    // 所以 fixed 上要用 buffered() + toss()
    const idx = std.mem.indexOfScalar(u8, r.buffered(), '\n').?;
    r.toss(idx + 1);
    try std.testing.expectEqualStrings("world", r.buffered());
}
```

**决策表**：

| 环境 | `buffer` 归谁 | 能 `fillMore` 吗 | 按分隔符读取怎么做 |
|---|---|---|---|
| `Reader.fixed(切片)` | 调用方（只读别名） | ❌ 报 EndOfStream | 直接 `buffered()` + `indexOfScalar` + `toss()` |
| `File.Reader` | Reader 自己 | ✅ | 三件套，或 `takeDelimiter` |
| `net.Stream.Reader` | Reader 自己 | ✅（会阻塞到有数据） | 三件套，或 `takeDelimiter` |

### ⚠️ `toss(idx + 1)` 里的 `idx` 是 `?usize`

这是实测撞到的一条，两个错误形态都很值得记住：

```text
  indexOfScalar 找到 '\n' 于 5（类型 ?usize，**不是** usize）
  ⚠️ 直接写 r.toss(idx + 1) 是**编译错**：invalid operands to binary expression: 'optional' and 'comptime_int'
  ⚠️ 写成 idx.? + 1 则是运行期 panic: attempt to use null value
  ⇒ 正确写法：先 orelse 提前收工，拿到 usize 再 +1。
  实测：toss(6) 后剩余 «world»
```

对应的两条报错文本都是实测复现的：

```text
p6.zig:10:26: error: invalid operands to binary expression: 'optional' and 'comptime_int'
    const n: usize = idx + 1;
                     ~~~~^~~
```

```text
thread 1970879 panic: attempt to use null value
p8.zig:4:23: 0x10bf9eb38 in main (p8)
    const n: usize = x.? + 1;
                      ^
```

正确写法是 `orelse` 提前收工——这不只是为了拿到 `usize`，
**"没找到分隔符"本身就是一个必须处理的分支**（缓冲里还没有完整一行）：

```zig
// examples/26_encoding/main.zig 第 401-412 行
        // ⚠️ toss(idx + 1) 里的 idx 是 ?usize
        {
            var r = std.Io.Reader.fixed("hello\nworld");
            const idx = std.mem.indexOfScalar(u8, r.buffered(), '\n');
            err.print("\n  indexOfScalar 找到 '\\n' 于 {?d}（类型 ?usize，**不是** usize）\n", .{idx});
            err.print("  ⚠️ 直接写 r.toss(idx + 1) 是**编译错**：invalid operands to binary expression: 'optional' and 'comptime_int'\n", .{});
            err.print("  ⚠️ 写成 idx.? + 1 则是运行期 panic: attempt to use null value\n", .{});
            err.print("  ⇒ 正确写法：先 orelse 提前收工，拿到 usize 再 +1。\n", .{});
            if (idx) |i| {
                r.toss(i + 1);
                err.print("  实测：toss({d}) 后剩余 «{s}»\n", .{ i + 1, r.buffered() });
            }
        }
```

### 为什么不能直接指针 cast

有人会想：`buffer` 就是一段内存，`@ptrCast` 成 `[*]const u8` 按下标读不就行了？

不行，两个原因。**第一，逻辑上**：`buffer[end..]` 那部分还没填、是 `undefined`——
你不知道 `end` 在哪，就不知道有效数据的边界在哪。**第二，`end` 会变**：
每轮 `fillMore` 都可能推进它，而一旦发生 rebase，`buffer.ptr` 本身就会移动
（rebase 的作用就是把未消费的残余往前挪腾出空间）。你上一步存下来的指针随时变悬垂。

**唯一正确的做法就是用 `buffered()` 拿当前有效切片**——它每次都从最新的
`ptr/seek/end` 现算，天然免疫 rebase。`std.Io.Reader` 的所有 `peek*`/`take*` 方法
也都是这么实现的。

## 26.3 按分隔符读取：三种写法的实测差异

**本章最关键的一节。** 结论先给：

> **`takeDelimiterExclusive` 在 0.17 会空转**——第一次拿到数据，之后永远返回长度为 0 的
> 空片且不报错。文件 Reader 和网络 Reader 上**行为一致**。

### 根因：源码路径

`takeDelimiterExclusive`（第 894-898 行）委托给 `peekDelimiterExclusive`（第 948-958 行），
后者委托给 `peekDelimiterInclusive`（第 841-873 行）。而 `peekDelimiterInclusive` 的
**开头**（第 842-849 行）是一次纯查找：

```zig
pub fn peekDelimiterInclusive(r: *Reader, delimiter: u8) DelimiterError![]u8 {
    {
        const contents = r.buffer[0..r.end];
        const seek = r.seek;
        if (std.mem.findScalarPos(u8, contents, seek, delimiter)) |end| {
            @branchHint(.likely);
            return contents[seek .. end + 1];      // ← 找到了就返回（含分隔符）
        }
    }
    while (true) { ... }                          // ← 没找到才去 fillMore
    // 缓冲区满了，用 Writer.failing 探测是不是还有更多数据
    var failing_writer = Writer.failing;
    while (r.vtable.stream(r, &failing_writer, .limited(1))) |n| {
        assert(n == 0);
    } else |err| switch (err) {
        error.WriteFailed => return error.StreamTooLong,
        error.ReadFailed => |e| return e,
        error.EndOfStream => |e| return e,
    }
}
```

关键在于 `findScalarPos` 的起点是 `seek`，而 `seek` **不会因为"分隔符已用完"而前移**。
于是：读完 `"l1\n"` 之后，`seek` 指向 `'\n'` 之前的位置，`findScalarPos` 立刻又找到
**同一个** `'\n'`，返回长度为 1 的切片，`peekDelimiterExclusive` 减去分隔符后
返回长度 0 的空片，`toss(0)`——**`seek` 原地不动**。下一轮完全重演。

### 实测 A：文件 Reader 上空转

```zig
// examples/26_encoding/main.zig 第 419-460 行
    // ═══ 26.3 按分隔符读取：三种写法的实测差异 ═══
    begin("26.3 按分隔符读取");
    err.print("⚠️⚠️ 本章最关键的一条：takeDelimiterExclusive 在 0.17 会**空转**。\n", .{});
    err.print("   源码路径：takeDelimiterExclusive → peekDelimiterExclusive → peekDelimiterInclusive\n", .{});
    err.print("   peekDelimiterInclusive 第 866-872 行：缓冲没分隔符时用 Writer.failing 探测，\n", .{});
    err.print("   对**文件**流探测到 EOF → 返回 error.EndOfStream（正常）；\n", .{});
    err.print("   但对已经有数据、只是分隔符用完的情况，它返回**长度为 0 的空片**且**不报错**。\n", .{});
```

运行输出（`examples/26_encoding/main.zig`，8 字节缓冲、10 行文件、只调 8 次）：

```text
==== 26.3 按分隔符读取 开始 ====
⚠️⚠️ 本章最关键的一条：takeDelimiterExclusive 在 0.17 会**空转**。
   源码路径：takeDelimiterExclusive → peekDelimiterExclusive → peekDelimiterInclusive
   peekDelimiterInclusive 第 866-872 行：缓冲没分隔符时用 Writer.failing 探测，
   对**文件**流探测到 EOF → 返回 error.EndOfStream（正常）；
   但对已经有数据、只是分隔符用完的情况，它返回**长度为 0 的空片**且**不报错**。

  A. takeDelimiterExclusive（8 字节缓冲，文件有 10 行）：
     第 1 次 -> 长度 2 «l1»
     第 2 次 -> 长度 0 «»  ← 空转！
     第 3 次 -> 长度 0 «»  ← 空转！
     第 4 次 -> 长度 0 «»  ← 空转！
     第 5 次 -> 长度 0 «»  ← 空转！
     第 6 次 -> 长度 0 «»  ← 空转！
     第 7 次 -> 长度 0 «»  ← 空转！
     第 8 次 -> 长度 0 «»  ← 空转！
     ⇒8 次里有 7 次是空片。上层 while(true) 写下去就是**死循环刷屏**。
```

注意它连 `error.EndOfStream` 都不报——所以 `catch` 分支根本兜不住。
测试块直接断言这个行为（`examples/26_encoding/main.zig` 第 1157-1170 行）：

```zig
    // exclusive：第一次拿到数据，之后永远返回空片（这就是 26.3 的实测结论）
    {
        var f = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer f.close(io);
        var rbuf: [8]u8 = undefined;
        var fr = f.reader(io, &rbuf);
        const first = fr.interface.takeDelimiterExclusive('\n') catch unreachable;
        try std.testing.expectEqualStrings("l1", first);
        // 再调 5 次，全部是长度为 0 的空片，且**不报错**
        for (0..5) |_| {
            const empty = fr.interface.takeDelimiterExclusive('\n') catch unreachable;
            try std.testing.expectEqual(@as(usize, 0), empty.len);
        }
    }
```

### 实测 B：`takeDelimiterInclusive` 是安全的那个

```text
  B. takeDelimiterInclusive（同样 8 字节缓冲）：
     数到 10 行（每行含 '\n'），第 11 次调用返回 EndOfStream 干净收工
```

它**消费掉**分隔符（`toss(result.len)` 里 `result` 含分隔符），所以 `seek` 一定前进。
代价是返回值**含**分隔符，你得自己处理末尾的 `'\n'`。

```zig
// examples/26_encoding/main.zig 第 111-126 行
/// 26.3 的对照：takeDelimiterInclusive 是**唯一不会空转**的 takeDelimiter* 变体。
fn countLinesInclusive(r: *std.Io.Reader) !usize {
    var n: usize = 0;
    while (true) {
        const line = r.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            error.StreamTooLong => return error.StreamTooLong,
            error.ReadFailed => |e| return e,
        };
        if (line.len > 0) n += 1;
    }
    return n;
}
```

### 实测 C：`takeDelimiter` 返回 `?[]u8`，EOF 给 `null`

```text
  C. takeDelimiter（返回 ?[]u8，EOF 给 null 而不是 EndOfStream）：
     第 1 次 -> «l1»（长度 2）
     第 2 次 -> «l2»（长度 2）
     第 11 次 -> null（干净 EOF，不抛错）
     ⇒ takeDelimiter 是**唯一不空转**的 takeDelimiter* 家族成员。
```

它的签名和另外两个不同——**错误集里没有 `EndOfStream`**（第 917 行）：

```zig
pub fn takeDelimiter(r: *Reader, delimiter: u8) error{ ReadFailed, StreamTooLong }!?[]u8
```

因为 EOF 已经用返回值里的 `null` 表达了，错误集就只剩"真出错"。源码（第 918-928 行）
在 EOF 时会把 `buffer[seek..end]` 里剩下的全部返回，然后下次给 `null`。

### 实测 D：通用写法（本章推荐）

```zig
// examples/26_encoding/main.zig 第 66-106 行
/// 26.5 的通用按行读取：循环 fillMore + 手工indexOfScalar + toss(idx+1)。
/// toss 的是`idx + 1`（**含**分隔符），所以不会像 takeDelimiterExclusive 那样空转。
/// 文件与 net.Stream 上行为一致——这是本章最重要的一条。
fn forEachLine(r: *std.Io.Reader, ctx: anytype, comptime cb: fn (@TypeOf(ctx), []const u8) anyerror!void) !usize {
    var lines: usize = 0;
    var carry: usize = 0; //上一轮没切完的字节数
    while (true) {
        _ = try readChunk(r) orelse break;
        const buf = r.buffered();
        var start: usize = 0;
        while (std.mem.indexOfScalarPos(u8, buf, start, '\n')) |idx| {
            try cb(ctx, buf[start..idx]);
            lines += 1;
            start = idx + 1;
        }
        carry = buf.len - start;
        r.toss(start); // 只丢掉已消费的部分，残余留在缓冲里
    }
    if (carry > 0) {
        try cb(ctx, r.buffered()[0..carry]); // 最后一行没有换行符
        lines += 1;
    }
    return lines;
}
```

四个要点：

1. **`toss(start)` 而不是 `toss(all)`**——只丢掉已消费的部分，跨块残留留在缓冲里。
2. **`indexOfScalarPos` 带 `start` 参数**，所以缓冲里有多行时能一次切多条，不用反复 fillMore。
3. **`carry`** 记下本轮没切完的字节数，循环结束后如果非零说明**最后一行没有换行符**，
   要单独回调一次。
4. **回调收到的切片指向 Reader 内部缓冲**，下一次 `fillMore`/`toss` 就失效——必须 `dupe`。
   这不是小事，本章的测试最初就是漏了这个，`acc.lines.items[0]` 读出来是 `"l3"` 而不是 `"l1"`。

运行输出（`examples/26_encoding/main.zig`）：

```text
  D. 通用写法（fillMore + buffered + indexOfScalar + toss(idx+1)）：
     逐行回调命中 10 行，行长 = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 3 }（无空转、末行无换行也正确）
```

最后那个 `3` 就是第 10 行 `"l10"`——末行没有换行符，`carry` 分支把它补上了。

### 实测 E：文件 vs 网络流，差别到底在哪

⚠️ **这里要更正一个常见的说法。** 有人说"`takeDelimiterExclusive` 在文件上阻塞、
在 `net.Stream` 上不阻塞会刷屏"。**实测的结论不一样**：

> **空转这个行为在两种 Reader 上完全一致**（因为 `peekDelimiterExclusive` 是
> `Reader.zig` 里的同一份代码，只有 vtable 不同）。差别不在"空转 vs 不空转"，
> 而在**缓冲里没有分隔符时会发生什么**：
> - **文件**：底层探到 EOF → 返回 `error.EndOfStream`，循环能干净结束。
> - **网络流**：底层 `fillMore` **真的在等**（阻塞在 socket read）——实测挂住不返回。

`net.Stream.Reader` 的 vtable（`Io/net.zig` 第 1337-1345 行）里 `.stream`/`.readVec`
指向 socket 读写，其余全用 `Reader.zig` 的通用实现。所以：

| Reader | 空转行为 | 缓冲无分隔符时 |
|---|---|---|
| `File.Reader` | ✅ 空转（8 次里 7 次空片） | 探到 EOF → `error.EndOfStream` |
| `net.Stream.Reader` | ✅ 空转（实测同样：1 次数据 + 5 次空片） | **阻塞**在 socket read |

所以网络流上用 `takeDelimiterExclusive` 有**两个**风险（空转 + 阻塞），
统一用 `forEachLine` 那种写法把两个风险一起消掉——**同一份代码在两种 Reader 上都对**。

示例里这一段是对称的说明（不跑网络，因为 26 章不该依赖网络环境）：

```zig
// examples/26_encoding/main.zig 第 502-512 行
        err.print("\n  E. 同一份 forEachLine 在 **net.Stream** 上也成立（架构对称）：\n", .{});
        err.print("     net.Stream.Reader 的 vtable 里 .stream/.readVec 是 socket 读写，\n", .{});
        err.print("     但 peekDelimiterInclusive / takeDelimiter* 是**同一份 Reader.zig 代码**，\n", .{});
        err.print("     所以「exclusive 空转」这个行为在两种 Reader 上**完全一致**——\n", .{});
        err.print("     不同之处只在「缓冲里没分隔符时」：文件探到 EOF 报 EndOfStream，\n", .{});
        err.print("     网络流则是**真的在等**（fillMore 阻塞在 socket read，实测挂住不返回）。\n", .{});
        err.print("     ⇒ 结论：网络流上用 takeDelimiterExclusive 有**两个**风险（空转 + 阻塞），\n", .{});
        err.print("     统一用 fillMore 三件套把两个风险一起消掉。\n", .{});
```

**这张表的实测来源**（探针在 `/tmp`，用回环 TCP，客户端先写数据再让服务端读）：

```text
##### 场景 with-delim #####
takeDelimiterExclusive('\n') 调起（场景 with-delim）……
  第 1 次 -> 长度 3 内容「abc」（共 0 ms）
  第 2 次 -> 长度 0 内容「」（共 0 ms）
  第 3 次 -> 长度 0 内容「」（共 0 ms）
  第 4 次 -> 长度 0 内容「」（共 0 ms）
##### 场景 no-delim #####
takeDelimiterExclusive('\n') 调起（场景 no-delim）……
  >>> 4 秒后进程仍在运行 = 阻塞 <<<
##### 场景 silent #####
takeDelimiterExclusive('\n') 调起（场景 silent）……
  >>> 4 秒后进程仍在运行 = 阻塞 <<<
##### 场景 fillMore-only #####
fillMore() 调起……
  >>> 4 秒后进程仍在运行 = 阻塞 <<<
```

（"有分隔符"场景也是**先拿到数据、然后 3 次空片**，和文件上完全一致。）

### 四个分隔符 API 对照表

| API | 含分隔符 | EOF 时 | 空转？ | 什么时候用 |
|---|---|---|---|---|
| `takeDelimiterInclusive` | ✅ | `error.EndOfStream` | ❌ 不会 | 已知分隔符会消费干净的场合 |
| `takeDelimiterExclusive` | ❌ | `error.EndOfStream` | ✅ **会** | ⚠️ **不要用** |
| `takeDelimiter` | ❌ | 返回 `null` | ❌ 不会 | 想拿 `?[]u8` 的场合 |
| `takeDelimiter(r, d)` 返回 `?` | ❌ | `null` | ❌ 不会 | 同上 |
| `forEachLine`（本文件） | ❌ | 循环正常结束 | ❌ 不会 | **通用首选** |

（`takeSentinel` / `peekSentinel` 是"按哨兵字节切"的一族，`sentinel` 是 `comptime` 参数。
`takeSentinel(0)` 处理 C 字符串，返回 `[:0]const u8` 能直接传给 `{s}`。）

## 26.4 hex 编解码：一对标准库函数

hex 是"给人看的字节"：hexdump、指纹、协议调试日志。两个函数，零分配（定长数组版本）：

```zig
// examples/26_encoding/main.zig 第 514-527 行
    // ═══ 26.4 hex 编解码 ═══
    begin("26.4 hex 编解码");
    {
        const raw = "Zig 0.17 编码";
        const hexed = std.fmt.bytesToHex(raw, .upper);
        err.print("bytesToHex(\"Zig 0.17 编码\", .upper) = {s}\n", .{hexed});
        err.print("  返回类型 = {s}（长度 = input.len * 2，**定长数组**，栈上完成、零分配）\n", .{@typeName(@TypeOf(hexed))});
        var back: [raw.len]u8 = undefined;
        const got = try std.fmt.hexToBytes(&back, &hexed);
        err.print("hexToBytes(&back, &hexed) -> «{s}»（{d} 字节），互逆 = {}\n", .{ got, got.len, std.mem.eql(u8, raw, got) });
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.4 hex 编解码 开始 ====
bytesToHex("Zig 0.17 编码", .upper) = 5A696720302E313720E7BC96E7A081
  返回类型 = [30]u8（长度 = input.len * 2，**定长数组**，栈上完成、零分配）
hexToBytes(&back, &hexed) -> «Zig 0.17 编码»（15 字节），互逆 = true
  ⚠️ bytesToHex 的第二参是 std.fmt.Case（.lower/.upper），**不是端序**——
     hex 没有端序概念（它就是字节的打印形式）。真正的端序参数在
     readSliceEndian / writeInt / bytesToHex 的近亲里，别混淆。
  解码器大小写通吃：bytesToHex("\x00\x01\xfe\xffAB", .lower) = 0001feff4142 -> { 0, 1, 254, 255, 65, 66 }
  ⚠️ hexToBytes 奇数长度 -> InvalidLength（不是崩溃，是错误集成员）
```

**实测签名**（`lib/std/fmt.zig` 第 1140 行 / 第 1156 行）：

```zig
pub fn bytesToHex(input: anytype, case: Case) [input.len * 2]u8
pub fn hexToBytes(out: []u8, input: []const u8) ![]u8
```

三个要点：

1. **第二参是 `Case`（`.lower`/`.upper`），不是端序。** `input: anytype` 但函数体第一行就是
   `comptime assert(@TypeOf(input[0]) == u8)`——只接受字节数组。
2. **返回的是 `[input.len * 2]u8` 定长数组**（上面实测是 `[30]u8`），
   因为输入长度 comptime 已知。这既是零分配的原因，也是它比切片版快的原因。
   要传给 `expectEqualStrings` 得写 `lower[0..]`——数组不自动 coerce 到切片。
3. **错误集有三个成员**：`error.InvalidLength`（奇数长度）、`error.NoSpaceLeft`（输出缓冲不够）、
   `error.InvalidCharacter`（非 hex 字符）。全部可在 `test` 里用 `expectError` 断言。

⚠️ `hexToBytes` 的 `out` 长度检查是 `if (out.len * 2 < input.len) return error.NoSpaceLeft`——
它**允许输出缓冲比需要的大**，返回的是 `out[0..in_i/2]` 子切片。所以解码大串时可以给个宽缓冲。

## 26.5 std.base64：先算长度，再谈读写

```zig
// examples/26_encoding/main.zig 第 541-556 行
    // ═══ 26.5 std.base64 ═══
    begin("26.5 std.base64");
    {
        const msg = "Man is distinguished... 推荐用 calcSize";
        const enc_len = base64_std.Encoder.calcSize(msg.len);
        const enc_buf = try mem.alloc(u8, enc_len);
        const b64 = base64_std.Encoder.encode(enc_buf, msg);
        err.print("calcSize({d}) = {d}（= 4*⌈n/3⌉，纯数学、不出错）\n", .{ msg.len, enc_len });
        err.print("encode -> {s}...\n", .{b64[0..32]});
        const dec_len = try base64_std.Decoder.calcSizeForSlice(b64);
        const dec_buf = try mem.alloc(u8, dec_len);
        try base64_std.Decoder.decode(dec_buf, b64);
        err.print("calcSizeForSlice -> {d}（精确）；calcSizeUpperBound -> {d}（上界，不扣 padding）\n", .{
            dec_len, try base64_std.Decoder.calcSizeUpperBound(b64.len),
        });
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.5 std.base64 开始 ====
calcSize(42) = 56（= 4*⌈n/3⌉，纯数学、不出错）
encode -> TWFuIGlzIGRpc3Rpbmd1aXNoZWQuLi4g...
calcSizeForSlice -> 42（精确）；calcSizeUpperBound -> 42（上界，不扣 padding）
  带 padding 的例子："fo"（2 字节）-> Zm8=
    calcSizeUpperBound(4) = 3；calcSizeForSlice = 2（差 1）
decode后逐字节一致 = true
⇒ 为什么需要 base64：二进制塞进文本通道（邮件头、JSON、URL）要一层 6-bit 重排。
   calcSize 的意义：**编码方向长度是确定的**，所以可以一次分配；
   **解码方向输入可能脏**，所以 calcSizeForSlice 返回错误集。
```

**为什么需要 base64**：早期协议（SMTP、JSON 某些场景）只允许 7 位可打印 ASCII。
二进制数据要进去，得先把每 3 字节（24 bit）重排成 4 个 6-bit 组，
每个 6-bit 映射到 64 个可打印字符之一。代价是**体积膨胀 4/3**——
这个代价在 `calcSize` 的公式 `4*⌈n/3⌉` 里。

### `calcSize` 的意义：编码确定、解码不确定

这是本章最实用的一条 API 设计经验：

| 方向 | 函数 | 返回类型 | 为什么 |
|---|---|---|---|
| 编码 | `Encoder.calcSize(n)` | `usize` | 长度是**纯数学**：`4*⌈n/3⌉`，不可能出错 |
| 解码（上界） | `Decoder.calcSizeUpperBound(n)` | `Error!usize` | 输入可能非法（长度不是 4 的倍数等） |
| 解码（精确） | `Decoder.calcSizeForSlice(s)` | `Error!usize` | 要看 padding 才知道确切长度 |

上面 `"fo"` 那个例子把差别显示出来了：`calcSizeUpperBound(4) = 3`（上界），
`calcSizeForSlice("Zm8=") = 2`（扣掉 padding）。**能用 `calcSizeForSlice` 就别用上界**，
省一次分配。

⚠️ `Encoder.encode` 有一行 `assert(dest.len >= out_len)`——**缓冲不够是 Debug 下的断言失败，
不是错误**。所以必须先 `calcSize`。

### 0.17 的真实名字：`url_safe`，不是 `url_safe_encoder`

这是本章实测出来的一条**迁移要点**：

```text
  0.17 实测存在的编解码器（@hasDecl 逐个探测）：
    std.base64.standard             true
    std.base64.standard_no_pad      true
    std.base64.url_safe             true
    std.base64.url_safe_no_pad      true
    std.base64.url_safe_encoder     false
  ⇒ URL 安全的真名是 **std.base64.url_safe**（Codecs 结构体，不是 encoder 变量）。
     0.16 教程里常写的 url_safe_encoder 在 0.17 **不存在**。
```

0.17 的 `base64.zig` 用一个 `Codecs` 结构体把字母表和编解码器绑在一起（第 20-26 行），
四个实例都是 `Codecs` 类型：`standard`、`standard_no_pad`、`url_safe`、`url_safe_no_pad`。
所以访问路径是 `std.base64.url_safe.Encoder.encode(...)`。

标准 vs URL-safe 的差别实测如下（同一份含 `+/` 需求的字节）：

```text
  同一份二进制 «FBFFBE»（含 +/ 需要的字节）：
    standard.Encoder -> +/++（出现 + 和 /）
    url_safe.Encoder  -> -_--（换成 - 和 _，可放进 URL）
    standard_no_pad  -> Zg（无 = 填充，JWT 用这个）
  Error 集合 = error{InvalidCharacter,InvalidPadding,NoSpaceLeft}
    0. NoSpaceLeft
    1. InvalidCharacter
    2. InvalidPadding
  decode("!!!!") -> InvalidCharacter（生产代码别 catch unreachable）
  decode("AB")-> InvalidPadding（长度不是 4 的倍数）
```

**为什么 URL-safe 表存在**：标准表的第 62/63 个字符是 `+` 和 `/`。
`+` 在 URL 里会被解成空格（表单编码的约定），`/` 是路径分隔符——
两者放 URL 里都会改变语义。RFC 4648 §5 的 URL-safe 表把它们换成 `-` 和 `_`。

**为什么 `no_pad` 变体存在**：JWT（RFC 7519）明确规定 base64url **不带 `=` padding**。
而 `=` 在 cookie 值、某些 header 里也有特殊含义。

### `encodeWriter`：流式场景不用先拼出完整切片

```zig
// examples/26_encoding/main.zig 第 598-601 行
        // encodeWriter：直接写进 Writer，不经中间缓冲
        var aw: std.Io.Writer.Allocating = .init(mem);
        try base64_std.Encoder.encodeWriter(&aw.writer, msg);
        err.print("\n  encodeWriter(&writer, msg) 直接落Writer -> {s}...\n", .{aw.written()[0..32]});
        err.print("  ⇒ 编码器本身也是 Writer 消费者：流式场景不用先拼出完整切片。\n", .{});
```

实测签名（`base64.zig` 第 111 行）：

```zig
pub fn encodeWriter(encoder: *const Base64Encoder, dest: *std.Io.Writer, source: []const u8) !void
```

它内部用 `std.mem.window(u8, source, 3, 3)` 做 3 字节滑窗，每窗编码后 `dest.writeAll`。
**这就是"编码器也是流式消费者"的证据**：你也可以反过来，把 base64 的输出
当成一个 `Reader` 喂给别的解码器。`decode` 没有对应的 `Reader` 版本——
**0.17 的 base64 解码只有切片 API，没有流式 API**。要流式解码得自己分块。

## 26.6 手写一遍 base64：3 字节 → 4 字符

协议本体的理解没有捷径，实现一遍最扎实：

```zig
// examples/26_encoding/main.zig 第 128-159 行
// ═══ 26.6 手写编码器（教学版：3 字节 → 4 字符）════════════════════════════

/// 手写 base64（教学版）：每次吃 3 字节 → 4 个 6-bit 组 → 查表输出，尾部按 RFC 4648 补 '='
fn encodeB64(a: std.mem.Allocator, src: []const u8) ![]u8 {
    const table = std.base64.standard_alphabet_chars;
    const out = try a.alloc(u8, base64_std.Encoder.calcSize(src.len));
    var si: usize = 0;
    var oi: usize = 0;
    while (si + 3 <= src.len) : (si += 3) {
        const n: u32 = (@as(u32, src[si]) << 16) | (@as(u32, src[si + 1]) << 8) | src[si + 2];
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = table[n >> 6 & 0x3F];
        out[oi + 3] = table[n & 0x3F];
        oi += 4;
    }
    const rem = src.len - si;
    if (rem == 1) {
        const n: u32 = @as(u32, src[si]) << 16;
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = '=';
        out[oi + 3] = '=';
    } else if (rem == 2) {
        const n: u32 = (@as(u32, src[si]) << 16) | (@as(u32, src[si + 1]) << 8);
        out[oi] = table[n >> 18 & 0x3F];
        out[oi + 1] = table[n >> 12 & 0x3F];
        out[oi + 2] = table[n >> 6 & 0x3F];
        out[oi + 3] = '=';
    }
    return out;
}
```

算法只有两步：**3 字节拼成 24 bit**（`<<16 | <<8 |`），**切成 4 个 6-bit 查表**
（`>>18 & 0x3F` 等四次）。尾部按 `rem` 分两种情况补 `=`——
`rem == 1` 补两个（只有 1 个有效 6-bit 组），`rem == 2` 补一个。

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.6 手写 base64 开始 ====
手写encodeB64 输出 56 字符，与标准库逐字节一致 = true
  算法：3 字节 → 拼成24 bit → 切成 4 个 6 bit → 查表；尾部按 RFC 4648 补 '='。
  位运算 << >> & | 是这类代码的全部家当；实现一遍最扎实。
==== 26.6 手写 base64 结束 ====
```

`main` 里只对比"我的 == 标准的"，真正的对拍在 test 块里，
用 RFC 4648 的全部尾部情形（`""` / `"f"` / `"fo"` / `"foo"` / `"foob"` / `"fooba"` / `"foobar"`）：

```zig
// examples/26_encoding/main.zig 第 977-997 行
test "base64：手写与标准库逐字节一致（含 RFC 4648 全部尾部情形）" {
    const a = std.testing.allocator;
    const cases = [_][]const u8{
        "",       "f",      "fo",    "foo",   "foob",
        "fooba",  "foobar", "Man is distinguished",
        "\xfb\xff\xbe", // 会产生 +/ 的字节，测标准 vs URL-safe差异
    };
    for (cases) |c| {
        const mine = try encodeB64(a, c);
        defer a.free(mine);
        const want = try a.alloc(u8, base64_std.Encoder.calcSize(c.len));
        defer a.free(want);
        try std.testing.expectEqualStrings(base64_std.Encoder.encode(want, c), mine);
        // 往返
        const dl = try base64_std.Decoder.calcSizeForSlice(want);
        const db = try a.alloc(u8, dl);
        defer a.free(db);
        try base64_std.Decoder.decode(db, want);
        try std.testing.expectEqualSlices(u8, c, db);
    }
}
```

⚠️ **手写一遍的价值在于它对拍的是全部尾部情形**。
只测 `"foobar"`（长度能被 3 整除）的实现，`rem == 1` 和 `rem == 2` 两条分支就是死代码。

⚠️ 顺带记一个 0.17 的库细节：`base64_std.Encoder.encode` 的快路径用了
`std.mem.readInt(u128, source[idx..][0..16], .big)`——**一次读 16 字节算 16 个输出字符**
（第 128 行）。所以手写版比标准库慢是正常的，标准库为性能牺牲了可读性。

## 26.7 URL 百分号编码：0.17 只有解码，编码得手写

⚠️ **实测结论：0.17 的标准库没有 URL 百分号编码器。** `std.Uri` 上只有解码：

```text
==== 26.7 URL 百分号编码 开始 ====
0.17 实测：**没有内建编码器**。std.Uri 上只有解码：
  @hasDecl(std.Uri, "escape") = false
  @hasDecl(std.Uri, "unescape") = false
  @hasDecl(std.Uri, "percentEncode") = false
  @hasDecl(std.Uri, "percentDecode") = false
  @hasDecl(std.Uri, "percentDecodeInPlace") = true
  @hasDecl(std.Uri, "percentDecodeBackwards") = true
  ⇒ percentEncode 得手写（本节那个30 行的函数）。
```

（全库 grep `percent` / `uriEscape` / `escapeUri` 都是零命中，`std.Uri` 上确实没有。）

### 手写编码器

```zig
// examples/26_encoding/main.zig 第 161-209 行
// ═══ 26.8 URL 百分号编码（0.17 只有解码，编码得手写）══════════════════════

/// RFC 3986 unreserved：A-Z a-z 0-9 - . _ ~
fn isUnreserved(c: u8) bool {
    return (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or
        (c >= '0' and c <= '9') or c == '-' or c == '.' or c == '_' or c == '~';
}

/// 百分号编码：未保留字符原样输出，其余写成 %XX（大写十六进制）。
/// 最坏情况 3 倍长度，调用方按 `s.len * 3` 给缓冲。
fn percentEncode(buf: []u8, s: []const u8) error{NoSpaceLeft}![]u8 {
    const hex = "0123456789ABCDEF";
    var n: usize = 0;
    for (s) |c| {
        if (isUnreserved(c)) {
            if (n >= buf.len) return error.NoSpaceLeft;
            buf[n] = c;
            n += 1;
        } else {
            if (n + 3 > buf.len) return error.NoSpaceLeft;
            buf[n] = '%';
            buf[n + 1] = hex[c >> 4];
            buf[n + 2] = hex[c & 15];
            n += 3;
        }
    }
    return buf[0..n];
}

/// 百分号解码：非法转义序列返回错误（**不**像 std.Uri 那样静默透传）。
fn percentDecode(buf: []u8, s: []const u8) error{ NoSpaceLeft, InvalidEscape, InvalidDigit }![]u8 {
    var n: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        if (n >= buf.len) return error.NoSpaceLeft;
        if (s[i] == '%') {
            if (i + 2 >= s.len) return error.InvalidEscape;
            const hi = std.fmt.charToDigit(s[i + 1], 16) catch return error.InvalidDigit;
            const lo = std.fmt.charToDigit(s[i + 2], 16) catch return error.InvalidDigit;
            buf[n] = (hi << 4) | lo;
            i += 3;
        } else {
            buf[n] = s[i];
            i += 1;
        }
        n += 1;
    }
    return buf[0..n];
}
```

运行输出（`examples/26_encoding/main.zig`）：

```text
  «hello world» -> hello%20world -> «hello world》（往返 = true）
  «a+b/c?d=e&f» -> a%2Bb%2Fc%3Fd%3De%26f -> «a+b/c?d=e&f」（往返 = true）
  «safe-._~chars» -> safe-._~chars -> «safe-._~chars》（往返 = true）
  «» -> %00%01%FF -> «»（往返 = true）
  unreserved集合 = A-Z a-z 0-9 - . _ ~（RFC 3986）；其余一律 %XX。
  ⚠️ 注意 `+` 不在unreserved 里：查询串里的空格是 %20 还是 + 取决于你编哪一层。
```

**最坏情况 3 倍长度**：每个字节变成 3 个字符（`%` + 2 位十六进制）。
所以调用方按 `s.len * 3` 给缓冲——这也是为什么 `percentEncode` 的参数是
`(buf, s)` 而不是返回分配的结果：**编码方向的长度上界是确定的**（和 base64 的 `calcSize` 同理）。

### ⚠️ `std.Uri.percentDecodeInPlace` 的两个坑

```text
  对照 std.Uri.percentDecodeInPlace("hello%20world%21") -> «hello world!》（12 字节）
  ⚠️ 它返回**裸 []u8**（不是错误联合），且对 "100%z" 这种非法转义**静默透传**：
     percentDecodeInPlace("100%z") = «100%z» ← 原样返回，不报错
     而本节手写的 percentDecode 遇到 '%z' 返回 error.InvalidDigit（见 test 块断言）。
```

**坑 1：返回裸 `[]u8`，不是错误联合。** 签名（`Uri.zig` 第 171 行）：

```zig
pub fn percentDecodeInPlace(buffer: []u8) []u8
```

写 `try` 会报 `expected error union type, found '[]u8'`。

**坑 2：非法转义静默透传。** 看 `percentDecodeBackwards` 的实现（`Uri.zig` 第 147-165 行）：
`std.fmt.parseInt(u8, ..., 16)` 失败时走 `else |_| {}`——**不报错的空catch**，
然后把这个字节原样拷进输出。所以 `"100%z"` 解出来还是 `"100%z"`。

这个设计对"尽力解析"是对的（真实世界的 URL 确实有非法转义），
但**它无法告诉调用者"这个 URL 是脏的"**。如果你需要严格校验（比如处理不可信输入），
就得用手写版 + 错误集。两个行为都在 test 块里断言了：

```zig
// examples/26_encoding/main.zig 第 1025-1056 行
test "URL 百分号编码：手写往返 + 非法转义报错（对照 std.Uri 静默透传）" {
    const a = std.testing.allocator;
    const cases = [_][]const u8{
        "hello world", "a+b/c?d=e&f", "safe-._~chars", "\x00\x01\xff", "中文.txt",
    };
    for (cases) |c| {
        const ebuf = try a.alloc(u8, c.len * 3);
        defer a.free(ebuf);
        const enc = try percentEncode(ebuf, c);
        const dbuf = try a.alloc(u8, enc.len);
        defer a.free(dbuf);
        const dec = try percentDecode(dbuf, enc);
        try std.testing.expectEqualSlices(u8, c, dec);
    }
    // 具体编码值
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("hello%20world", try percentEncode(&buf, "hello world"));
    try std.testing.expectEqualStrings("safe-._~", try percentEncode(&buf, "safe-._~"));
    // 缓冲不够
    var tiny: [2]u8 = undefined;
    try std.testing.expectError(error.NoSpaceLeft, percentEncode(&tiny, "hello"));
    // 非法转义：手写版报错
    try std.testing.expectError(error.InvalidEscape, percentDecode(&buf, "abc%"));
    try std.testing.expectError(error.InvalidDigit, percentDecode(&buf, "abc%z1"));
    // std.Uri 只有解码，且对非法输入静默透传（这就是手写版的理由）
    try std.testing.expect(!@hasDecl(std.Uri, "percentEncode"));
    try std.testing.expect(@hasDecl(std.Uri, "percentDecodeInPlace"));
    var inplace: [8]u8 = undefined;
    @memcpy(inplace[0..5], "100%z");
    try std.testing.expectEqualStrings("100%z", std.Uri.percentDecodeInPlace(inplace[0..5]));
}
```

⚠️ **编码器必须有 `NoSpaceLeft`**：上面用 2 字节缓冲编码 `"hello"` 就撞上了。
这是纯栈分配写法的代价——你得自己算长度上界。

⚠️ **多层编码要当心**：如果字符串已经是 base64 或已经百分号编码过了，
再编码一遍会把 `%` 编成 `%25`（实测输出里 `a+b/c?d=e&f` → `a%2Bb%2Fc%3Fd%3De%26f`
就编了 7 个字符）。**先解码再编码，不要叠加**。

## 26.8 压缩：0.17 的 std.compress 现状

**先说结论：0.17 的标准库只能压 flate（gzip/zlib/raw），其他格式只能解压。**

```text
==== 26.8 压缩 std.compress 开始 ====
  std.compress.flate    true
  std.compress.zstd     true
  std.compress.lzma     true
  std.compress.lzma2    true
  std.compress.xz       true
  flate.Container 的三个成员 = .raw / .gzip / .zlib（实测）：
    .raw
    .gzip
    .zlib
  ⚠️ zstd / lzma 在 0.17 **只有 Decompress，没有 Compress**（实测 @hasDecl = false）。
     也就是说标准库能解压 zstd/lzma，但压不出来——压缩只有 flate 一条路。
```

`compress.zig` 一共只有 5 个 re-export（整个文件 17 行）：

```zig
/// gzip and zlib are here.
pub const flate = @import("compress/flate.zig");
pub const lzma = @import("compress/lzma.zig");
pub const lzma2 = @import("compress/lzma2.zig");
pub const xz = @import("compress/xz.zig");
pub const zstd = @import("compress/zstd.zig");
```

`zstd/` 目录下**只有 `Decompress.zig`**，没有 `Compress.zig`。所以
`std.compress.zstd` 只能解压。**这也意味着 0.17 没有内置的 zstd 压缩能力**——
需要压 zstd 得引第三方库。

### flate 的形状：`Compress` 自己就是一个 Writer

这是 flate API 最反直觉的地方——**它不是"调一个函数处理整个缓冲区"，
而是"给你一个 Writer，你往里写"**：

```zig
// examples/26_encoding/main.zig 第 654-672 行
    // ═══ 26.8 压缩：0.17 的 std.compress 现状 ═══
    begin("26.8 压缩 std.compress");
    {
        inline for (.{ "flate", "zstd", "lzma", "lzma2", "xz" }) |nm| {
            err.print("  std.compress.{s:<8} {}\n", .{ nm, @hasDecl(std.compress, nm) });
        }
        err.print("  flate.Container 的三个成员 = .raw / .gzip / .zlib（实测）：\n", .{});
        inline for (@typeInfo(std.compress.flate.Container).@"enum".field_names) |nm| {
            err.print("    .{s}\n", .{nm});
        }
        err.print("  ⚠️ zstd / lzma 在 0.17 **只有 Decompress，没有 Compress**（实测 @hasDecl = false）。\n", .{});
        err.print("     也就是说标准库能解压 zstd/lzma，但压不出来——压缩只有 flate 一条路。\n", .{});

        var big: [4096]u8 = undefined;
        for (&big, 0..) |*p, i| p.* = @intCast('a' + @as(u8, @intCast(i % 26)));
        // 压缩：Compress 自己就是个 Writer
        var out: std.Io.Writer.Allocating = try .initCapacity(mem, 256);
        var scratch: [std.compress.flate.max_window_len]u8 = undefined;
        var comp = try std.compress.flate.Compress.init(&out.writer, &scratch, .gzip, .default);
        try comp.writer.writeAll(&big);
        try comp.finish();
```

运行输出（`examples/26_encoding/main.zig`）：

```text
  4096 字节原文（周期 26 的可压缩数据）-> gzip 70 字节
  gzip 头 4 字节 = 1F 8B 08 00（1f 8b = gzip 魔数，实测）
  解压回 4096 字节，逐字节一致 = true
  ⇒ Decompress.init **不返回错误**（无 try），Compress.init 返回 Writer.Error!。
  ⚠️ 两个 init 的 buffer 大小要求不同：Compress 要 max_window_len，
     Decompress 也要 max_window_len（**不是** history_len，实测写成 history_len 会 assert 失败）。
  ⚠️ 输出端必须用 Allocating.initCapacity(gpa, n)：Allocating.init 的 buffer 初始长度是 0，
     而 flate.Compress.init 里 assert(output.buffer.len > 8) —— 实测直接 panic。
```

**实测签名**：

```zig
// Compress.zig 第 303-310 行
pub fn init(output: *Writer, buffer: []u8, container: flate.Container, opts: Options) Writer.Error!Compress

// Decompress.zig 第 85 行
pub fn init(input: *Reader, container: Container, buffer: []u8) Decompress
```

三个必须知道的差异：

| | `Compress.init` | `Decompress.init` |
|---|---|---|
| 返回 | `Writer.Error!Compress`（**要 `try`**） | `Decompress`（**不要 `try`**） |
| scratch 大小 | `max_window_len`（= 65536） | `max_window_len`（**不是 `history_len`=32768**） |
| 输出/输入端 | `*Io.Writer` | `*Io.Reader` |

⚠️ **`Decompress` 的 buffer 必须是 `max_window_len`**。源码第 86 行：
`if (buffer.len != 0) assert(buffer.len >= flate.max_window_len);`
——写 `history_len`（32768）会 assert 失败，因为 `max_window_len = history_len * 2`（第 5 行）。

⚠️ **输出端必须用 `Allocating.initCapacity(gpa, n)`**，不能用 `Allocating.init(gpa)`。
后者初始 `.buffer = &.{}`（长度 0），而 `Compress.init` 第 309 行有
`assert(output.buffer.len > 8)`——**直接 panic**。这是实测撞出来的两条 panic 路径。

⚠️ `Compress` 结构体很大：源码第 27 行注释写着
*"Allocates statically ~224K (128K lookup, 96K tokens)"*——
`lookup` 字段里有 `[1 << lookup_hash_bits]PackedOptionalU15` 和 `[32768]PackedOptionalU15`。
**所以它必须放栈上或堆上，不能按值传递**（`init` 返回值直接 `var comp = try ...` 即可，
编译器会给你在栈上开空间）。

⚠️ `Options` 有 10 个预设（`level_1` 到 `level_9`，加 `fastest`/`default`/`best` 别名）。
`default = level_6`、`fastest = level_1`、`best = level_9`。

## 26.9 std.hash：做完整性校验

哈希在数据处理里的角色是**完整性校验**和**分桶**：不是加密（那用 `std.crypto`），
而是"这段数据在传输/存储过程中有没有变"。

### Wyhash：流式 == 一次性

```zig
// examples/26_encoding/main.zig 第 693-700 行
    // ═══ 26.9 哈希：完整性校验 ═══
    begin("26.9 std.hash 完整性校验");
    {
        const Wy = std.hash.Wyhash;
        const h1 = Wy.hash(0, "hello");
        err.print("std.hash.Wyhash.hash(0, \"hello\") = 0x{x}\n", .{h1});
        var inc: Wy = .init(0);
        inc.update("he");
        inc.update("llo");
        err.print("流式 update(\"he\")+update(\"llo\") = 0x{x}（== 一次性 hash）\n", .{inc.final()});
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.9 std.hash 完整性校验 开始 ====
std.hash.Wyhash.hash(0, "hello") = 0xe24bbd9f93f532d
流式 update("he")+update("llo") = 0xe24bbd9f93f532d（== 一次性 hash）
  ⇒ Wyhash 的 update 语义就是**拼接**，所以流式与一次性必然相等。
  ⚠️ 0.17 没有 smallHash / largeHash（实测 has no member named 'smallHash'）。
std.hash.Crc32.hash("hello") = 0x3610a686（= crc.@"CRC-32/ISO-HDLC"）
  ⚠️ 0.17 里没有 std.hash.crc.Crc32 —— 真名是带引号的 @"CRC-32/ISO-HDLC"。
std.hash.int(@as(u32, 7)) = 1327878809（把整数打散成哈希，给 HashMap 用）
autoHash(&hasher, u8 1) + autoHash(&hasher, u32 3) -> final = 0x5d2de479d53c74ea
  ⚠️⚠️ 0.17 的 autoHash 签名是 **(hasher, key) void**（流式），
     不是旧版的 autoHash(...) 返回 u64。写错了报 expected 2 argument(s), found 3。
  ⚠️ 且 f64 **不可哈希**：@compileError("unable to hash type f64")。
```

**实测签名**（`hash/wyhash.zig`）：

```zig
pub fn init(seed: u64) Wyhash
pub fn update(self: *Wyhash, input: []const u8) void
pub fn final(self: *Wyhash) u64
pub fn hash(seed: u64, input: []const u8) u64
```

⚠️ **`final` 要用 `var` 收**：它的接收者是 `*Wyhash`（**不是** `*const Wyhash`），
因为它会改内部状态。而 `smallHash` / `largeHash` 在 0.17 **不存在**
（老教程里的写法报 `struct 'hash.wyhash.Wyhash' has no member named 'smallHash'`）——
统一用 `hash`（它内部按长度选路径）。

⚠️ `update` 的注释里有一条**重要的算法细节**
（`wyhash.zig` 第 35-36 行）：

```zig
// This is subtly different from other hash function update calls. Wyhash requires the last
// full 48-byte block to be run through final1 if is exactly aligned to 48-bytes.
```

意思是"正好在 48 字节边界收尾"和"最后一块不足 48 字节"走的路径不同。
所以**分块大小会影响结果吗？** 不会——测试块 `"流式哈希 == 一次性哈希（流式的核心不变式）"`
用 6 种块大小（1/7/64/1000/4096/total）全部断言等于一次性结果：

```zig
// examples/26_encoding/main.zig 第 1393-1415 行
test "流式哈希 == 一次性哈希（流式的核心不变式）" {
    const Wy = std.hash.Wyhash;
    const a = std.testing.allocator;
    const total = 8192;
    const data = try a.alloc(u8, total);
    defer a.free(data);
    for (data, 0..) |*p, i| p.* = @intCast(i & 0xff);

    var whole = Wy.init(0);
    whole.update(data);

    // 分块，且块大小刻意不等于 total（模拟真实的流式读取）
    for ([_]usize{ 1, 7, 64, 1000, 4096, total }) |chunk_len| {
        var streamed = Wy.init(0);
        var i: usize = 0;
        while (i < total) {
            const stop = @min(i + chunk_len, total);
            streamed.update(data[i..stop]);
            i = stop;
        }
        try std.testing.expectEqual(whole.final(), streamed.final());
    }
}
```

⚠️ **`final()` 会改状态，所以它只能调一次**（不是幂等的）。
上面 `var whole` 之后没再调 `whole.final()` 之外的逻辑，就是这个原因。

### crc：真名带引号

```zig
// examples/26_encoding/main.zig 第 705-706 行
        err.print("std.hash.Crc32.hash(\"hello\") = 0x{x}（= crc.@\"CRC-32/ISO-HDLC\"）\n", .{std.hash.Crc32.hash("hello")});
        err.print("  ⚠️ 0.17 里没有 std.hash.crc.Crc32 —— 真名是带引号的 @\"CRC-32/ISO-HDLC\"。\n", .{});
```

`hash/crc.zig` 有 **90 多个 CRC 变体**，全部按 IANA 名字命名：
`@"CRC-3/GSM"`、`@"CRC-16/CCITT"`、`@"CRC-32/ISO-HDLC"`、`@"CRC-64/XZ"`……
必须用 `@"..."` 带引号语法（名字里有 `/`）。`std.hash.Crc32` 是 `crc.@"CRC-32/ISO-HDLC"` 的别名，
它是 `hash.zig` 第 9 行 `pub const Crc32 = crc.@"CRC-32/ISO-HDLC";` 给的。

每个变体的 API（`crc.zig` 第 951-991 行）：

```zig
pub fn init() Self                                    // 注意：无参数
pub fn update(self: *Self, bytes: []const u8) void
pub fn final(self: Self) W
pub fn hash(bytes: []const u8) W
```

⚠️ **`final` 的接收者是 `*Self`？** 不是——是 `self: Self`（**按值**）。
和 `Wyhash.final(self: *Wyhash)` 不同。这是实测确认的，两个都写了测试。

⚠️ crc 的 `final` 返回类型是**位宽 W**（`u32` / `u64` / `u16`…），不是固定 `u64`。
`CRC-8/MAXIM-DOW` 的 `final()` 返回 `u8`——写 `const x: u64 = crc8.final()` 要 `@intCast`。

测试里锁死了 CRC-32 的实测值，防止标准库改行为：

```zig
// examples/26_encoding/main.zig 第 1283-1285 行
    // CRC-32 是确定性的：实测值锁死，防止标准库改行为
    try std.testing.expectEqual(@as(u32, 0x3610A686), std.hash.Crc32.hash("hello"));
```

（`0x3610A686` 就是 `"hello"` 的 CRC-32/ISO-HDLC，和 `echo hello | cksum` 的输出一致。）

### ⚠️ `autoHash` 在 0.17 变成了流式签名

这是 0.17 的一条**大改动**，很多人会踩：

```text
  ⚠️⚠️ 0.17 的 autoHash 签名是 **(hasher, key) void**（流式），
     不是旧版的 autoHash(...) 返回 u64。写错了报 expected 2 argument(s), found 3。
  ⚠️ 且 f64 **不可哈希**：@compileError("unable to hash type f64")。
```

实测报错（按旧写法 `std.hash.autoHash(3.5, "x", @as(u8, 1))`）：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/hash/auto_hash.zig:185:5: note: function declared here
pub fn autoHash(hasher: anytype, key: anytype) void {
~~~^~~~~~~~~~~~~~~
main.zig:110:70: error: expected 2 argument(s), found 3
```

**旧写法 → 新写法的迁移**：

```zig
// 旧（0.16 及之前）：一次算完
const h = std.hash.autoHash(a, b, c);

// 新（0.17）：喂给 hasher
var h: std.hash.Wyhash = .init(0);
std.hash.autoHash(&h, a);
std.hash.autoHash(&h, b);
std.hash.autoHash(&h, c);
const result = h.final();
```

⚠️ **`f64` 不可哈希**（`auto_hash.zig` 第 88 行 `@compileError("unable to hash type " ++ @typeName(Key))`）。
所以浮点数要么先转成位模式（`@bitCast` 成 `u64`）再哈希，要么用专门的浮点哈希函数。

⚠️ **`autoHash` 不接受切片**（第 187-190 行）：含切片的 struct/union 会被
`@compileError` 拒绝，理由是"意图不明"。要哈希切片就手写 `h.update(slice)`。

⚠️ 还有 `std.hash.autoHashStrat(hasher, key, comptime strat)`——`strat` 是
`HashStrategy` 枚举（`.Shallow` / `.Deep` / `.DeepRecursive`）。`autoHash` 等价于
`autoHashStrat(h, k, .Shallow)`。

### 实际用法：边读边算，不把文件读进内存

```zig
// examples/26_encoding/main.zig 第 715-733 行
        // 流式哈希的实际用法：校验大文件
        err.print("\n  实际用法——边读边算，全程不把文件读进内存：\n", .{});
        {
            var f = try std.Io.Dir.cwd().createFile(init.io, probe_path, .{});
            {
                var b: [64]u8 = undefined;
                var fw = f.writer(init.io, &b);
                try fw.interface.writeAll("the quick brown fox jumps over the lazy dog");
                try fw.interface.flush();
            }
            f.close(init.io);
            var f2 = try std.Io.Dir.cwd().openFile(init.io, probe_path, .{});
            defer f2.close(init.io);
            var rbuf: [16]u8 = undefined; //故意用小缓冲，逼出多次 fillMore
            var fr = f2.reader(init.io, &rbuf);
            var h = Wy.init(0);
            var total: usize = 0;
            while (true) {
                const avail = (try readChunk(&fr.interface)) orelse break;
                h.update(avail);
                total += avail.len;
                fr.interface.toss(avail.len);
            }
            err.print("    16 字节缓冲、逐块 update：{d} 字节 -> Wyhash 0x{x}\n", .{ total, h.final() });
            err.print("    一次性算同一个字符串：             Wyhash 0x{x}\n", .{Wy.hash(0, "the quick brown fox jumps over the lazy dog")});
            err.print("    ⇒ 相同 ⇒ 内存占用从O(文件大小) 降到 O(缓冲大小)。\n", .{});
        }
```

运行输出（`examples/26_encoding/main.zig`）：

```text
  实际用法——边读边算，全程不把文件读进内存：
    16 字节缓冲、逐块 update：43 字节 -> Wyhash 0x5326b3568cf2e35
    一次性算同一个字符串：             Wyhash 0x5326b3568cf2e35
    ⇒ 相同 ⇒ 内存占用从O(文件大小) 降到 O(缓冲大小)。
```

⚠️ 注意这个循环用的是 `readChunk`（三件套），所以**不能**在 `Reader.fixed` 上跑
——但这里传的是 `File.Reader`，缓冲区归 Reader 自己，`fillMore` 正常。

## 26.10 SIMD 加速：@Vector、位掩码 + @popCount

### ⚠️ `@Vector` 没有"默认宽度"

```text
==== 26.10 SIMD @Vector 开始 ====
@Vector 是**语言级固定宽度**，与目标 CPU 特性无关：
  @Vector(32, u8) = 32 字节 / 256 位
  @Vector(3, u8)  = 24 位（不是2 的幂，硬件要拆成多次）
  @Vector(128, u8) = 1024 位（x86 AVX2 一次只256 位，要拆成 4 条 ymm）
  本机：arch=x86_64 model=haswell avx2=true sse2=true avx=true
  ⇒ 「AVX2 是 256 位但@Vector 默认多少」这个问题的答案是：
     @Vector **没有默认宽度**，你写几就是几；编译器负责拆成硬件指令。
  实测 @Vector(32, u8) 在 wasm32-freestanding / riscv64 / aarch64 上都能编译
     （编译器自动降级成标量循环），所以**不是**「不支持的目标上编译失败」。
```

**实测的目标特性探测**（本机 `haswell`）：

```zig
// examples/26_encoding/main.zig 第 753-758 行
        err.print("  本机：arch={s} model={s} avx2={} sse2={} avx={}\n", .{
            @tagName(builtin.cpu.arch),
            builtin.cpu.model.name,
            std.Target.x86.featureSetHas(builtin.cpu.features, .avx2),
            std.Target.x86.featureSetHas(builtin.cpu.features, .sse2),
            std.Target.x86.featureSetHas(builtin.cpu.features, .avx),
        });
```

⚠️ **探测 CPU 特性的正确写法是 `std.Target.x86.featureSetHas`**，
不是 `builtin.cpu.arch.x86.featureSetHas`——`Arch` 是枚举，
实测报 `type 'Target.Cpu.Arch' does not support field access`。

**关于"在不支持的目标上编译会失败"**——实测**不成立**：

```bash
$ for t in wasm32-freestanding riscv64-linux aarch64-linux x86_64-linux-none; do
    zig build-obj p5.zig -target $t -fno-emit-bin && echo "$t 编译通过"
  done
wasm32-freestanding 编译通过
riscv64-linux 编译通过
aarch64-linux 编译通过
x86_64-linux-none 编译通过
```

`@Vector` 是**语言特性**，LLVM 后端负责降级（拆成多条标量指令或更小的向量）。
所以**同一份 SIMD 代码可以跨架构编译**，只是没有硬件加速。
这和 `@import("std").simd` 之类需要按目标条件编译的东西不同。

### 真实例子：统计 32 字节里有几个字节等于目标值

```zig
// examples/26_encoding/main.zig 第 211-239 行
// ═══ 26.10 SIMD ══════════════════════════════════════════════════════════

/// SIMD 版：统计 32 字节窗口里有几个字节等于 target。
/// 尾数不足 32 字节退回标量。
fn countByteSimd(data: []const u8, target: u8) usize {
    const V = @Vector(32, u8);
    const tv: V = @splat(target);
    var n: usize = 0;
    var i: usize = 0;
    while (i + 32 <= data.len) : (i += 32) {
        const v: V = data[i..][0..32].*; // 切片 →向量：一次装 32 字节
        const bits: u32 = @bitCast(v == tv); // 比较 → 位掩码
        n += @popCount(bits); // popCount 数位
    }
    for (data[i..]) |c| {
        if (c == target) n += 1;
    }
    return n;
}

fn countByteScalar(data: []const u8, target: u8) usize {
    var n: usize = 0;
    for (data) |c| {
        if (c == target) n += 1;
    }
    return n;
}
```

三个动作，缺一不可：

| 动作 | 语法 | 说明 |
|---|---|---|
| 切片 → 向量 | `data[i..][0..32].*` | `.*` 解引用数组值，一次装 32 字节 |
| 比较 → 位掩码 | `@bitCast(v == tv)` | `==` 产生 `@Vector(32, bool)`，`@bitCast` 压成 `u32` |
| 数位 | `@popCount(bits)` | 数 `u32` 里有多少个 1 |

运行输出（`examples/26_encoding/main.zig`）：

```text
  真实例子：96 字节里数 'x' —— SIMD 24 个 == 标量 24 个（3 个 32 字节窗口）
  三个动作：切片→向量 text[i..][0..32].*、比较 → 位掩码 @bitCast、@popCount 数位
  ⚠️ 掩码类型是 @Vector(N, bool)，位宽只有 N：@bitCast 到 u32 **要求 N == 32**，
     否则报 @bitCast size mismatch（实测 N=3 时 destination 'u8' has 8 bits but source
     '@Vector(3, bool)' has 3 bits）。N != 32 时用 @select 转 u32 再 @reduce(.Add)。
```

### ⚠️ `@bitCast` 的位宽必须严格相等

这是实测撞到的精确报错：

```text
p4.zig:56:26: error: @bitCast size mismatch: destination type 'u8' has 8 bits but source type '@Vector(3, bool)' has 3 bits
        const bits: u8 = @bitCast(eq);
                         ^~~~~~~~~~~~
```

比较结果的类型是 `@Vector(N, bool)`，**位宽恰好是 N**（一个 `bool` 只占 1 位，
因为它是 mask 的元素类型）。所以：

- `N == 32` → `@bitCast` 到 `u32` ✅
- `N == 8` → 只能 `@bitCast` 到 `u8`
- `N == 3` → **任何整数都不行**（没有 3 位整数类型）

`N != 32` 时的绕法是用 `@select` 转成整数向量再 `@reduce`：

```zig
// examples/26_encoding/main.zig 第 773-777 行
        err.print("  ⚠️ 掩码类型是 @Vector(N, bool)，位宽只有 N：@bitCast 到 u32 **要求 N == 32**，\n", .{});
        err.print("     否则报 @bitCast size mismatch（实测 N=3 时 destination 'u8' has 8 bits but source\n", .{});
        err.print("     '@Vector(3, bool)' has 3 bits）。N != 32 时用 @select 转 u32 再 @reduce(.Add)。\n", .{});
```

实测：

```text
@Vector(3,u8) 比较结果的类型 = @Vector(3, bool)
⚠️ @bitCast(@Vector(N,bool)) -> u32 要求 N == 32，否则报 size mismatch（实测）
  绕法：@select 到 u32 再 @reduce(.Add, ...) = 3
```

⚠️ **注意区分 `@Vector(N, bool)` 和 `@Vector(N, u1)`**。前者是布尔向量（`==` 的结果），
后者是位向量。`@bitCast` 只接受**位宽严格相等**的目标类型，
所以 `@Vector(32, bool)` → `u32` ✅，`@Vector(32, u1)` → `u32` ❌（32 vs 32 看着一样，但
`@Vector(32, u1)` 的 `==` 结果仍是 `@Vector(32, bool)`）。

**`@select` 的正确用法**（实测很容易写错参数顺序）：

```zig
@select(T, 条件向量, 为真时的值, 为假时的值)
```

实测（条件为真时选 ones）：

```text
  @reduce(.Add, @splat(3) x32) = 96（32*3=96）
  @select(u8, v==3, ones, twos)[0] = 1（逐元素选，不是全有全无）
```

⚠️ **第一个参数是元素类型 `T`，不是 `@as(T, ...)`**。写 `@select(@as(u8, ...))` 会报错。

### `@reduce`：五种归约操作

```text
  @reduce 在 4x u32 上：.Add=28 .Max=7 .And=7 .Or=7 .Xor=0
```

实测的五个 tag 和结果（`@splat(7)` 作用在 `@Vector(4, u32)` 上）：

| tag | 结果 | 含义 |
|---|---|---|
| `.Add` | 28 | 求和 |
| `.Max` | 7 | 最大值 |
| `.And` | 7 | 按位与 |
| `.Or` | 7 | 按位或 |
| `.Xor` | 0 | 按位异或（4 个 7 异或偶数次 = 0） |

⚠️ `.And`/`.Or`/`.Xor` **只能作用在整数向量上**，作用在 `f32` 上是编译错。
浮点只有 `.Add`/`.Mul`/`.Max`/`.Min`/`.And`（布尔语义）等。

⚠️ `@reduce` 的 tag 不能当运行时变量传——它是 `comptime` 参数，
所以想动态选归约操作得用 `switch` 分派（`inline for` 展开）。

### 词计数：位技巧的综合用例

```zig
// examples/26_encoding/main.zig 第 241-290 行
/// SIMD 词计数（书上 zwc 的核心）：32 字节一批，比较产生位掩码，popCount 数词首。
/// 块间用 prev_was_space 把上一块的末位接进来，跨块单词不丢。
fn countWordsSimd(text: []const u8) WordCounts {
    const V = @Vector(32, u8);
    const B = @Vector(32, u1);
    const ones: B = @splat(1);
    const zeros: B = @splat(0);
    const sp: V = @splat(' ');
    const tab: V = @splat('\t');
    const cr: V = @splat('\r');
    const nl: V = @splat('\n');
    var lines: usize = 0;
    var words: usize = 0;
    var prev_was_space: u32 = 1; // 开头视作"空白"，首词即词首
    var i: usize = 0;
    while (i + 32 <= text.len) : (i += 32) {
        const v: V = text[i..][0..32].*;
        const is_nl = v == nl;
        lines += @popCount(@as(u32, @bitCast(@select(u1, is_nl, ones, zeros))));
        const is_white = (v == sp) | ((v >= tab) & (v <= cr)); // 空格或 \t..\r
        const curr: u32 = @bitCast(@select(u1, is_white, ones, zeros));
        const prev = (curr << 1) | prev_was_space; // 把上一块的末位接进来
        words += @popCount(~curr & prev); // 词首 = 当前非空白 且 前一字符空白
        prev_was_space = curr >> 31;
    }
    var was_space = prev_was_space == 1; // 尾巴不足 32 字节：退回标量
    while (i < text.len) : (i += 1) {
        const c = text[i];
        const ws = c == ' ' or (c >= '\t' and c <= '\r');
        if (c == '\n') lines += 1;
        if (!ws and was_space) words += 1;
        was_space = ws;
    }
    return .{ .lines = lines, .words = words };
}
```

**词首检测的位技巧**：词首 = 当前非空白 **且** 前一字符空白。
用位运算表达就是 `~curr & (curr << 1 | prev_was_space)`：
- `curr` 是"当前是空白"的位图，`~curr` 是"当前非空白"。
- `curr << 1` 把"当前是空白"右移一位（对齐成"前一位是空白"）。
- `| prev_was_space` 把**上一块的最后一位**接进来——这是跨块不丢单词的关键。
- 开头 `prev_was_space = 1`，这样第一个字符如果是字母就被算成词首。

⚠️ **`prev_was_space = curr >> 31`**：`curr` 是 `u32`（32 位），
`curr >> 31` 就是取最高位（最后一个字节的空白标记），
留给下一轮当 `prev`。这是"块间状态传递"的唯一一处。

运行输出（`examples/26_encoding/main.zig`）：

```text
  词计数：SIMD .{ .lines = 2, .words = 10 } == 标量 .{ .lines = 2, .words = 10 }（one two  three	four
five  six seven	eight
nine ten）
  位技巧：词首 = 当前非空白 且 前一字符空白。块间用 prev_was_space 把上一块末位接进来。
```

⚠️ **验证 SIMD 正确性只有一个办法：对拍**。标量实现是参照系，
两个实现对拍一组刁钻输入（空串、全空白、跨界单词、满 32 倍数）比单看 SIMD 代码可信得多：

```zig
// examples/26_encoding/main.zig 第 1074-1090 行
test "SIMD 词计数 == 标量（含块边界切开单词、满32 倍数、空串）" {
    // 0.17 起 `**` 已移除，构造长字符串用文件顶部的 Rep()
    const texts = [_][]const u8{
        "one two  three\tfour",
        Rep("a", 31).bytes ++ " b",
        Rep("ab", 16).bytes ++ " cd " ++ Rep("ef", 20).bytes,
        "\n\n\n",
        "   leading and trailing   ",
        "",
        "single",
        Rep("word ", 40).bytes,
        Rep("a", 32).bytes, // 正好 32 字节，无尾块
    };
    for (texts) |t| {
        try std.testing.expectEqual(countWordsScalar(t), countWordsSimd(t));
    }
}
```

第一个字节计数测试更狠——**遍历长度 0 到 199 的每一个长度**：

```zig
// examples/26_encoding/main.zig 第 1058-1072 行
test "SIMD 计数 == 标量计数（跨窗口 + 任意尾巴长度）" {
    const a = std.testing.allocator;
    for (0..200) |len| {
        const buf = try a.alloc(u8, len);
        defer a.free(buf);
        for (buf, 0..) |*p, i| p.* = if (i % 4 == 2) 'x' else @intCast('a' + @as(u8, @intCast(i % 26)));
        try std.testing.expectEqual(countByteScalar(buf, 'x'), countByteSimd(buf, 'x'));
    }
    // 全 0 长度
    try std.testing.expectEqual(@as(usize, 0), countByteSimd("", 'x'));
    // 正好 32 的倍数
    var exact: [64]u8 = undefined;
    for (&exact, 0..) |*p, i| p.* = if (i % 2 == 0) 'x' else 'y';
    try std.testing.expectEqual(countByteScalar(&exact, 'x'), countByteSimd(&exact, 'x'));
}
```

**200 个长度 × 每次一个断言**——这是 SIMD 测试该有的样子。

## 26.11 流式处理 vs 一次性读入：取舍

这是本章唯一一个**设计决策**话题，其余都是 API。实测对比：

```zig
// examples/26_encoding/main.zig 第 795-828 行
    // ═══ 26.11 流式 vs 一次性：取舍 ═══
    begin("26.11 流式 vs 一次性");
    {
        const total = 1024 * 1024; // 1 MiB
        const Wy = std.hash.Wyhash;
        const t0 = std.Io.Clock.now(.awake, init.io);
        var whole: [total]u8 = undefined;
        for (&whole, 0..) |*p, i| p.* = @intCast(i & 0xff);
        var h_whole = Wy.init(0);
        h_whole.update(&whole);
        const sum_whole = h_whole.final();
        const ns_whole = t0.durationTo(std.Io.Clock.now(.awake, init.io)).nanoseconds;

        const t1 = std.Io.Clock.now(.awake, init.io);
        var chunk: [4096]u8 = undefined;
        var h_stream = Wy.init(0);
        var i: usize = 0;
        while (i < total) : (i += chunk.len) {
            for (&chunk, 0..) |*p, j| p.* = @intCast((i + j) & 0xff);
            h_stream.update(&chunk);
        }
        const sum_stream = h_stream.final();
        const ns_stream = t1.durationTo(std.Io.Clock.now(.awake, init.io)).nanoseconds;
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.11 流式 vs 一次性 开始 ====
同样 1048576 字节、同样一个 Wyhash：
  一次性读入：栈上 1048576 字节常驻，哈希 0xc3c6dcf50d8950b3，耗时 12074593 ns
  4 KiB 分块：  栈上 4096 字节常驻，哈希 0xc3c6dcf50d8950b3，耗时 16540550 ns
  哈希相同 = true（流式 update 就是拼接）
  ⇒ 取舍：内存**有界**换内存**无界**。处理大小未知的输入（文件、socket、管道），
     流式是唯一能保证不 OOM 的写法；输入大小已知且很小，一次性更简单更快。
  ⚠️ 上面两个 ns 数字每次运行都不同（Debug 模式），只说明「同一量级」，不当性能数据。
  栈上1 MiB 数组只在 Debug 下能跑过；ReleaseFast 下会爆栈——真实代码用分配器。
==== 26.11 流式 vs 一次性 结束 ====
```

⚠️ **那两行 ns 的具体数字每次运行都不一样，而且相对大小会翻转**。
本机实测过三次：`12074593 / 16540550`（流式慢 45%）、`10900322 / 10343869`（流式反而快）。
**唯一稳定的是那个哈希值**（`0xc3c6dcf50d8950b3`，两边永远相同）。

这个"快慢会翻转"本身就是结论：**在 Debug 模式下测不出流式的真实代价**。
真要比较性能得用 `-OReleaseFast`，而且要注意 Debug 下的循环开销被放大得离谱
（每次迭代都带边界检查），这会系统性地偏向"一次大块处理"的写法。
上面抄的这一组数字来自某一次运行，**只说明"同一量级"**。

**唯一的不变式是哈希值相同**（`0xc3c6dcf50d8950b3` 两边一样）。
这是 26.9 那条性质在规模上的体现——所以**流式化不会改变结果，只改变内存占用**。

⚠️ **不要把上面两个 ns 当性能数据**。这是 Debug 模式（溢出检查、越界检查全开），
性能大概是 ReleaseFast 的 1/10 到 1/30。15.13 节说过同样的话。
这里的数字只说明"同一量级"。

⚠️ **栈上 1 MiB 数组只在 Debug 下能跑过**。macOS 默认栈 8 MiB，ReleaseFast 下
同样的代码可能爆栈。**真实代码用分配器**——示例用栈数组是为了让"内存占用"
这个对比一眼可见，不是推荐写法。

### 决策表

| 场景 | 选择 | 理由 |
|---|---|---|
| 文件大小已知且 < 几百 MB | 一次性 `readFileAlloc` | 简单，能随机访问（`seek` 后再读） |
| 文件大小未知 / 无穷大（如 `/dev/zero`） | **必须流式** | 一次性会 OOM |
| socket / 管道 | **必须流式** | 数据到达时间不确定 |
| 只需要一个汇总值（哈希/校验和/行数） | **必须流式** | 中间数据没用，别存 |
| 需要随机访问（数据库索引、压缩包目录） | 一次性 + `mmap` | 流式做不到回退 |
| 数据已在内存里 | 一次性 | 别为了"流式"而流式 |

⚠️ **"流式"不等于"慢"**。上面那组数字里流式慢了 45%，但换个运行它又快 5%
（见 26.11 的说明）——**在 Debug 模式下这个比较毫无意义**，因为每次循环迭代
的边界检查开销被放大了几十倍，真要比较必须用 `-OReleaseFast`。
流式换来的是**内存有界**，这个代价通常值。

⚠️ **流式真正的代价是"不能随机访问"**。一次性读入之后你可以 `seek` 到任何偏移再读；
流式只能顺序向前。这是本质取舍，不是实现问题——所以"需要随机访问"（数据库页、
压缩包中央目录、索引文件）就必须走一次性 + `mmap`，别硬套流式。

⚠️ **流式的另一个好处：可以提前终止**。一行式处理里遇到哨兵行就 `break`，
剩下的数据根本不用读。一次性读入做不到这一点（你已经付了全部 I/O 的钱）。

## 26.12 0.17 迁移：`**` 运算符已移除

这是本章要专门讲的一块，因为它是**上一版教程就已经踩到**的坑。

```text
==== 26.12 0.17 迁移：** 运算符已移除 开始 ====
0.17 起 `**`（编译期重复）运算符已从语言里移除。实测：
  "ab" ** 3-> error: binary operator '*' has whitespace on one side, but not the other
  [_]u8{7} ** 4     -> 同上（**连数组重复也没了**）
  它被词法分析成两个 '*' 指针解引用，所以报的是空白错误而不是「找不到运算符」。

  0.17 的三种替代：
  1. 向量/数组同一值重复：@splat  -> { 7, 7, 7, 7 }
  2. 常量字符串重复：自己写 comptime 函数（本文件的 Rep）：
       Rep("ab", 3).bytes = «ababab»（长度 6，[:0]const u8）
  3. 编译期拼字符串用 comptimePrint 或 `++`（**`++` 仍在**）：
       "foo" ++ "bar" = «foobar»（长度 6）
       comptimePrint("{d}-{d}", .{7,9}) = «7-9»（类型 *const [N:0]u8）
  Rep 顺带演示了 comptime 的两种典型用法：comptime 参数 + **类型**作返回值。
  （写成返回 []const u8 就不行——编译期循环必须有确定类型才能定长分配。）
==== 26.12 0.17 迁移：** 运算符已移除 结束 ====
```

**实测的报错文本**（这就是为什么它难懂——报错完全不提 `**`）：

```text
pow.zig:3:20: error: binary operator '*' has whitespace on one side, but not the other
    const a = "ab" ** 3;
                   ^
```

⚠️ 报错指向**第二个 `*`**。因为词法分析器把 `**` 拆成了两个独立的 `*` 记号，
语义分析走到第二个 `*` 时发现"左操作数 `*` 的结果不能解引用"，于是抱怨空白规则
（Zig 要求一元 `*` 解引用和二元 `*` 不能有歧义，所以 `a * *p` 要写成 `a * *p`）。
**它完全不告诉你"这个运算符曾经存在过"**——这是迁移时最费时间的地方。

⚠️ **数组重复也没了**。实测 `[_]u8{7} ** 4` 报同一个错：

```text
pow2.zig:3:26: error: binary operator '*' has whitespace on one side, but not the other
    const arr = [_]u8{7} ** 4;
                         ^
```

### 三种替代品

**替代 1：`@splat`（数组/向量同一值）**

```zig
// examples/26_encoding/main.zig 第 836-837 行
    const v4: @Vector(4, u8) = @splat(7);
    err.print("  1. 向量/数组同一值重复：@splat  -> {any}\n", .{v4});
```

实测输出 `{ 7, 7, 7, 7 }`。⚠️ `@splat` 的参数类型从**目标类型**推导，
所以 `@splat(7)` 在 `@Vector(4, u8)` 上下文里得到 `{7,7,7,7}`，
在 `@Vector(4, u32)` 上下文里得到 `{7,7,7,7}` 但元素是 `u32`。

**替代 2：comptime 函数（字符串重复）**

```zig
// examples/26_encoding/main.zig 第 30-48 行
/// 0.17 起 `**`（编译期重复）运算符已从语言里移除：`"ab" ** 3` 现在会被
/// 词法分析成两个 `*`，直接报 "binary operator '*' has whitespace on one side"。
/// 替代品是一个**返回类型的 comptime 函数**——它顺带把 comptime 的两种典型用法
/// （comptime 参数 + 类型作返回值）都演示了一遍。
/// 数组/向量用 `@splat`，字符串只能自己写（`++` 拼接仍在）。
fn Rep(comptime s: []const u8, comptime n: usize) type {
    return struct {
        //⚠️ 哨兵数组 `[N:0]u8` 的结尾 0 由**编译器自动放置**，不要手动写。
        //   手动写 `b[b.len - 1] = 0` 会把**最后一个真实字节**覆盖成0（实测：
        //   Rep("ab", 4) 得到 "abababa "而不是 "abababab"）。b.len 是 N 不含哨兵，
        //   而 @sizeOf([8:0]u8) = 9——所以 b[b.len] 才是哨兵位。
        const data: [s.len * n:0]u8 = blk: {
            var b: [s.len * n:0]u8 = undefined;
            for (0..n) |i| @memcpy(b[i * s.len ..][0..s.len], s);
            break :blk b;
        };
        pub const bytes: [:0]const u8 = &data;
    };
}
```

⚠️ **返回类型必须是 `type`，不能是 `[]const u8`**。原因是编译期的 `for` 循环
必须能求值出一个**确定长度**的分配，而切片长度在编译期是运行期值。
返回匿名 struct（它的字段 `data` 是定长数组）才能拿到栈上/只读段的零分配常量。

⚠️ **哨兵数组的 0 不要手动写**——这是一个连本教程自己都写错的坑（第一版 `Rep` 里有
`b[b.len - 1] = 0`，结果 `Rep("ab", 4)` 得到 `"abababa\x00"`）。原因是：

| | 值 |
|---|---|
| `b.len`（`[8:0]u8`） | 8（**不含**哨兵） |
| `@sizeOf([8:0]u8)` | 9（含哨兵） |
| `b[b.len - 1]` | 第 7 个字节 = **真实数据** |
| `b[b.len]` | 第 8 个字节 = 哨兵位（编译器自动置 0） |

哨兵数组的结尾 0 由编译器自动放置，手写反而覆盖数据。这个 bug 是被 test 块
的 `expectEqualStrings("abababab", r.bytes)` 抓出来的——**测试断言字面量是发现这类问题的最短路径**。

**替代 3：`++` 拼接（仍在）和 `comptimePrint`**

```zig
// examples/26_encoding/main.zig 第 839-844 行
    err.print("  3. 编译期拼字符串用 comptimePrint 或 `++`（**`++` 仍在**）：\n", .{});
    err.print("       \"foo\" ++ \"bar\" = «{s}」（长度 {d}）\n", .{ "foo" ++ "bar", ("foo" ++ "bar").len });
    err.print("       comptimePrint(\"{{d}}-{{d}}\", .{{7,9}}) = «{s}»（类型 *const [N:0]u8）\n", .{
        std.fmt.comptimePrint("{d}-{d}", .{ 7, 9 }),
    });
```

⚠️ **`++` 只在编译期操作数上工作**。`++` 的两侧必须都是 comptime 已知长度的
切片（或数组）。`runtime_slice ++ "x"` 是编译错。

⚠️ **`comptimePrint` 的返回类型是 `*const [count(fmt, args):0]u8`**——
一个**指针**，不是切片。传给 `{s}` 可以（会自动解引用），但
`comptimePrint(...).len` 是错的（指针没有 `len`）。要长度得写
`std.fmt.count(fmt, args)`。

### 什么时候还需要 `Rep` 这种写法

三个场景：

1. **构造长的常量测试数据**（本文件的主要用途，见 26.10 的 test 块）。
2. **编译期生成查找表**（比如 256 项的 hex 表、base64 反查表）。
3. **编译期字符串常量折叠**（比如把所有错误信息拼成一张表）。

如果只是"重复几次"而不是"生成常量"，**运行期循环 + `ArrayList` 就够**：

```zig
// 运行期版本（不需要 comptime）
var buf: [12]u8 = undefined;
for (0..3) |i| @memcpy(buf[i * 4 ..][0..4], "abcd");
// buf = "abcdabcdabcd"
```

实测两者输出：

```text
运行时 @memcpy 循环: abcdabcdabcd
```

⚠️ **选 `Rep`（comptime）的判据**：结果需要是 `comptime` 已知长度的**常量**
（能作为数组长度、类型的一部分、`++` 的操作数）。否则运行期循环更简单。

## 26.13 流与编码 API 的实测签名速查

这一节是全章的**速查表**，所有签名都来自 `lib/std/` 源码 + 本机实测。

```zig
// examples/26_encoding/main.zig 第 850-860 行
    // ═══ 26.13 流与编码 API 的实测签名速查 ═══
    begin("26.13 实测签名速查");
    err.print("std.Io.Reader 的关键方法（签名摘自 lib/std/Io/Reader.zig，本机 0.17.0）：\n", .{});
    err.print("  fillMore(r) Error!void——**返回错误**，EOF 时是 error.EndOfStream\n", .{});
    err.print("  buffered(r) []u8 / bufferedLen(r) usize\n", .{});
    err.print("  toss(r, n: usize) void —— n 是 usize，传 ?usize 会编译错\n", .{});
    err.print("  take(r, n) Error![]u8 / peek(r, n) Error![]u8 / takeArray(r, comptime n)\n", .{});
    err.print("  takeByte(r) Error!u8 / peekByte(r) Error!u8\n", .{});
    err.print("  readSliceShort(r, buf) ShortError!usize——**填满或 EOF**，不是单次 read\n", .{});
    err.print("  readSliceAll(r, buf) Error!void——填不满报 error.EndOfStream\n", .{});
    err.print("  takeSentinel(r, comptime sentinel) [:{{sentinel}}]u8\n", .{});
    err.print("  takeDelimiterInclusive(r, d) / takeDelimiterExclusive(r, d) DelimiterError![]u8\n", .{});
    err.print("  takeDelimiter(r, d) error{{ReadFailed,StreamTooLong}}!?[]u8——EOF 给 null\n", .{});
    err.print("  stream(r, w, limit) StreamError!usize / streamRemaining(r, w) StreamRemainingError!usize\n", .{});
    err.print("  allocRemaining(r, gpa, limit) / readAllocAll(r, gpa, len)\n", .{});
```

运行输出（`examples/26_encoding/main.zig`）：

```text
==== 26.13 实测签名速查 开始 ====
std.Io.Reader 的关键方法（签名摘自 lib/std/Io/Reader.zig，本机 0.17.0）：
  fillMore(r) Error!void——**返回错误**，EOF 时是 error.EndOfStream
  buffered(r) []u8 / bufferedLen(r) usize
  toss(r, n: usize) void —— n 是 usize，传 ?usize 会编译错
  take(r, n) Error![]u8 / peek(r, n) Error![]u8 / takeArray(r, comptime n)
  takeByte(r) Error!u8 / peekByte(r) Error!u8
  readSliceShort(r, buf) ShortError!usize——**填满或 EOF**，不是单次 read
  readSliceAll(r, buf) Error!void——填不满报 error.EndOfStream
  takeSentinel(r, comptime sentinel) [:{sentinel}]u8
  takeDelimiterInclusive(r, d) / takeDelimiterExclusive(r, d) DelimiterError![]u8
  takeDelimiter(r, d) error{ReadFailed,StreamTooLong}!?[]u8——EOF 给 null
  stream(r, w, limit) StreamError!usize / streamRemaining(r, w) StreamRemainingError!usize
  allocRemaining(r, gpa, limit) / readAllocAll(r, gpa, len)

  四个错误集（互不相同，别混）：
    Reader.Error            = { ReadFailed, EndOfStream }
    Reader.ShortError        = { ReadFailed }（短读永远不报 EndOfStream）
    Reader.StreamError= { ReadFailed, WriteFailed, EndOfStream }
    Reader.DelimiterError= { ReadFailed, EndOfStream, StreamTooLong }
```

### ⚠️ `File.readAll` / `readAllAlloc` / `writeAll` 在 0.17 不存在

这是文件级 API 的一条硬迁移：

```text
  ⚠️ File.readAll / readAllAlloc / writeAll 在 0.17 **不存在**（文件级 API），
     对应物是 readStreaming / writeStreaming / writeStreamingAll / readPositional。
  实测签名（第一个参数是**切片数组**，不是单个 buffer）：
    File.readStreaming(io, buffer: []const []u8) ReadStreamingError!usize
    File.readPositional(io, buffer: []const []u8, offset: u64) !usize
    File.writeStreaming(io, header, data: []const []u8, splat: usize) Writer.Error!usize
    File.writeStreamingAll(io, bytes: []const u8) Writer.Error!void
  ⚠️ readStreaming 的切片必须**已初始化为真实 buffer**：填 {undefined} 会 EINVAL panic
     （实测：thread panic: programmer bug caused syscall error: INVAL）。
  实测 readStreaming(io, &[_][]u8{buf}) -> 21 字节 «hello streaming world»
```

**签名要点**（`Io/File.zig` 第 471 行 / 第 503 行 / 第 610 行 / 第 620 行）：

```zig
pub fn readStreaming(file: File, io: Io, buffer: []const []u8) ReadStreamingError!usize
pub fn readPositional(file: File, io: Io, buffer: []const []u8, offset: u64) ReadPositionalError!usize
pub fn writeStreaming(file: File, io: Io, header: []const u8, data: []const []u8, splat: usize) Writer.Error!usize
pub fn writeStreamingAll(file: File, io: Io, bytes: []const u8) Writer.Error!void
```

⚠️ **`buffer` 是 `[]const []u8`（切片数组），不是单个 `[]u8`**。这是 scatter/gather 接口：
可以一次读/写多个不连续的目标（对应 `readv`/`writev`）。单缓冲也要写成
`&[_][]u8{buf}`。

⚠️ **`ReadStreamingError = error{EndOfStream} || Reader.Error`**（第 464 行）——
它比 `Reader.Error` 多一个 `EndOfStream`，因为"可能返回 0 字节"是 streaming 模式的正常情况。

⚠️ **`readStreaming` 的切片必须已初始化**。填 `.{undefined}` 会 EINVAL panic：

```text
thread 1960306 panic: programmer bug caused syscall error: INVAL
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:14443:34: 0x10f35b61b in errnoBug (p3)
    if (is_debug) std.debug.panic("programmer bug caused syscall error: {t}", .{err});
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/Io/Threaded.zig:9975:52: 0x10f3aa39d in fileReadStreamingPosix (p3)
            .INVAL => |err| return syscall.errnoBug(err),
```

原因是 `undefined` 的切片长度是垃圾值，`writev` 拿一个荒谬的 `iovcnt`/长度去调系统调用。
**正确写法**是 `var raw: [64]u8 = undefined; var one = [_][]u8{raw[0..]};`——
`raw[0..]` 的长度是 64（编译期确定），指针指向真实内存。

### Writer 家族与 `print` 的两参规则

```text
  Writer 家族：
    Writer.fixed(buf) Writer——落调用方的栈缓冲，无需 flush
    Writer.Allocating.init(gpa) / initCapacity(gpa, n) / deinit() / written()
    Writer.Discarding.init(buf) Writer——丢弃但计数（.writer.end 是长度）
    File.writer(io, buf) / writerStreaming(io, buf) / writer(io, undefined)= 无缓冲
  格式串：Writer.print(comptime fmt, args) Error!void（**固定两参**，无占位符也要 .{}）
```

⚠️ **`Writer.Discarding.init` 收的是 `[]u8` 不是 Allocator**
（`Writer.zig` 第 2350 行）——写 `.init(mem)` 报
`expected type '[]u8', found 'mem.Allocator'`。

⚠️ **想干算格式化长度用 `std.fmt.count(fmt, args)`**（实测 `count("{d}", .{12345}) = 5`）。
`Discarding` 的 `.count` 字段实测是 **0**（那是别的东西），真正的长度在
**`.writer.end`**。这和直觉相反，容易看漏。

⚠️ **`File.writer(io, undefined)` 是合法的**——`undefined` 表示"不要缓冲"，
每次 `write` 直接进系统调用。慢但省内存。

⚠️ **`print` 固定两个参数**，即使格式串里没有占位符：

```text
r5.zig:128:9: error: expected 2 argument(s), found 1
    d.print("  takeSentinel: ");
        ~~~~~~~~~~~~~
```

所以 `print("纯文字\n")` 是编译错，必须写 `print("纯文字\n", .{})`。

### `std.fmt` 的 0.17 实测存在性

```text
  std.fmt 的 0.17 实测存在性：
    std.fmt.bytesToHex         true
    std.fmt.hexToBytes         true
    std.fmt.allocPrint         true
    std.fmt.bufPrint           true
    std.fmt.parseInt           true
    std.fmt.parseFloat         true
    std.fmt.comptimePrint      true
    std.fmt.count              true
    std.fmt.parseChar          false
    std.fmt.fmtInt             false
    std.fmt.formatInt          false
    std.fmt.format             false
    std.fmt.alignIntoBuffer    false
  ⇒ parseChar 和 fmtInt 在 0.17 **都不存在**；alignIntoBuffer 也没了。
  ⚠️ allocPrint / bufPrint 已标注 Deprecated（源码注释：Deprecated in favor of
     mem.PrintError / mem.print），新代码用 gpa.print(fmt, args) 和 mem.print(buf, ...)。
  bytesToHex(input: anytype, case: Case) [input.len*2]u8——第二参是 Case 不是端序
  hexToBytes(out: []u8, input: []const u8) ![]u8——奇数长度报 error.InvalidLength
```

**`std.fmt` 的 0.17 签名表**：

| 名字 | 0.17 签名 | 备注 |
|---|---|---|
| `bytesToHex` | `(input: anytype, case: Case) [input.len*2]u8` | 第二参是**大小写**不是端序 |
| `hexToBytes` | `(out: []u8, input: []const u8) ![]u8` | 错误：`InvalidLength`/`NoSpaceLeft`/`InvalidCharacter` |
| `parseInt` | `(comptime T, buf, base: u8) ParseIntError!T` | base 是 `u8` |
| `parseFloat` | `(comptime T, s: []const u8) ParseFloatError!T` | 在 `fmt/parse_float.zig` |
| `comptimePrint` | `(comptime fmt, args) *const [count(fmt,args):0]u8` | 返回**指针** |
| `count` | `(comptime fmt, args) usize` | 干算格式化后长度 |
| `allocPrint` | `(gpa, comptime fmt, args) Allocator.Error![]u8` | ⚠️ 已 Deprecated |
| `bufPrint` | `(buf, comptime fmt, args) BufPrintError![]u8` | ⚠️ 已 Deprecated |
| `parseChar` | — | **不存在** |
| `fmtInt` | — | **不存在** |

⚠️ **`allocPrint` / `bufPrint` 已标注 Deprecated**。源码注释（`fmt.zig` 第 623 行 / 第 599 行）：

```zig
/// Deprecated in favor of `mem.PrintError`.
pub const BufPrintError = mem.PrintError;

/// Deprecated in favor of `mem.PrintError`.
pub fn bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype) BufPrintError![]u8 {
```

```zig
/// Deprecated in favor of `Allocator.print`.
pub fn allocPrint(gpa: Allocator, comptime fmt: []const u8, args: anytype) Allocator.Error![]u8 {
    return gpa.print(fmt, args);
}
```

**新写法**：`gpa.print(fmt, args)` 和 `mem.print(buf, fmt, args)`。
⚠️ 但它们**还能用**（Deprecated 不是 Removed），本文件的 test 块
`"0.17 的 API 存在性：确实被移除的那些名字"` 里实测断言了它们仍工作——
**Deprecated 会给警告，Removed 才报编译错，两者要分清**。

⚠️ `parseChar` 和 `fmtInt` 是**真删了**（0.17 完全不存在这两个名字）。
想格式化单个字符用 `{c}`（`d.print("{c}", .{ch})`），
想在编译期格式化整数用 `comptimePrint("{d}", .{n})`。

### std.json：两个 0.17 变化

```text
  std.json（20 章已深入，本章只做流式搭档）：
    parseFromSlice(std.json.Value, ...) -> .object，3 个字段，name=zig
    Stringify.value(value, options, writer) 回写 -> {"name":"zig","tags":[1,2,3],"ok":true}
    ⚠️ 两个 0.17 变化：std.json.Value 是 **union(enum)** 不是纯 enum；
       Stringify.value 的 writer 参数在**最后**（value, options, writer）。
```

```zig
// examples/26_encoding/main.zig 第 911-923 行
    err.print("\n  std.json（20 章已深入，本章只做流式搭档）：\n", .{});
        {
            const jtext = "{\"name\":\"zig\",\"tags\":[1,2,3],\"ok\":true}";
            const parsed = try std.json.parseFromSlice(std.json.Value, mem, jtext, .{});
            switch (parsed.value) {
                .object => |o| {
                    err.print("    parseFromSlice(std.json.Value, ...) -> .object，{d} 个字段，name={s}\n", .{ o.count(), o.get("name").?.string });
                },
                else => {},
            }
            var al: std.Io.Writer.Allocating = .init(mem);
            try std.json.Stringify.value(parsed.value, .{}, &al.writer);
            err.print("    Stringify.value(value, options, writer) 回写-> {s}\n", .{al.written()});
            err.print("    ⚠️ 两个 0.17 变化：std.json.Value 是 **union(enum)** 不是纯 enum；\n", .{});
            err.print("       Stringify.value 的 writer 参数在**最后**（value, options, writer）。\n", .{});
        }
```

⚠️ **`std.json.Value` 在 0.17 是 `union(enum)`**（`json/dynamic.zig` 第 20 行），
不是纯 `enum`。实测字段名：

```text
    . null
    . bool
    . integer
    . float
    . number_string
    . string
    . array
    . object
```

反射写法要改成 `@typeInfo(std.json.Value).@"union".field_names`——
写 `.@"enum"` 报 `access of union field 'enum' while field 'struct' is active`。

⚠️ **`Stringify.value` 的参数顺序是 `(value, options, writer)`**——
`writer` 在**最后**。这是从 0.16 的 `(writer, value, options)` 改过来的，
很容易写反（实测报 `expected 'json.Stringify.Options', found 'json.dynamic.Value'`）。

⚠️ `Stringify.value` 要传一个 `*Io.Writer`，所以配合 `Allocating` 时写
`&al.writer`（`.writer` 字段），不是 `&al`。

## 26.14 坑位清单

本章实测踩到的坑，按"踩到时的迷惑程度"排序。

1. ⚠️⚠️ **`takeDelimiterExclusive` 会空转**。第一次返回数据，之后**永远**返回长度 0 的空片
   且**不报错**（文件 Reader 和网络 Reader 都一样）。上层写 `while (true)` 就是死循环刷屏，
   `catch` 也兜不住。根因是 `peekDelimiterInclusive` 的 `findScalarPos(u8, contents, seek, d)`
   起点是 `seek`，而 `seek` 不前进。**用 `forEachLine`（26.3）或者 `takeDelimiter`（返回 `?[]u8`）**。

2. ⚠️⚠️ **`readSliceShort` 是"填满或 EOF"，不是单次 read**。源码 `Io/Reader.zig` 第 696-703 行
   就是一个 `while (true) { readVec }`。拿它探测"还有多少数据"会挂死。
   实测序列（源 10 字节、缓冲 4 字节）是 `4, 4, 2, 0`——只有真不够了才短读。

3. ⚠️⚠️ **`Reader.fixed` 上 `fillMore()` 返回 `error.EndOfStream`**，哪怕缓冲里明明有数据。
   机制：`fillMore` 第一行 `rebase(capacity=1)`，而 `fixed` 的 `vtable.rebase = endingRebase`
   无条件返回 `EndOfStream`。**fixed 上只用 `buffered()` + `toss()`**。

4. ⚠️ **`toss(idx + 1)` 的 `idx` 是 `?usize`**。直接 `idx + 1` 报
   `invalid operands to binary expression: 'optional' and 'comptime_int'`；
   写成 `idx.? + 1` 则是运行期 `panic: attempt to use null value`。
   正确写法是 `orelse` 提前收工——"没找到分隔符"本身就是一个必须处理的分支。

5. ⚠️ **`fillMore` 返回 `Error!void`，不是 `void`**。EOF 时是 `error.EndOfStream`。
   而且它**可能填进 0 字节而这不是 EOF**（源码注释明说），所以还要检查 `bufferedLen()`。

6. ⚠️ **`**` 运算符在 0.17 已移除**（数组重复也一样）。报错是
   `binary operator '*' has whitespace on one side, but not the other`——
   **完全不提 `**`**，因为词法分析把它拆成了两个 `*`。替代品：`@splat`（数组/向量）、
   自己写 comptime 函数（字符串）、`++`（仍在）。

7. ⚠️ **哨兵数组 `[N:0]u8` 的结尾 0 由编译器自动放置，不要手动写**。
   手动写 `b[b.len - 1] = 0` 会覆盖**最后一个真实字节**——本教程第一版的 `Rep` 就这么写错了，
   `Rep("ab", 4)` 得到 `"abababa\x00"`。`b.len` 是 N 不含哨兵，`@sizeOf([8:0]u8)` 才是 N+1。

8. ⚠️ **回调收到的切片指向 Reader 内部缓冲，下一次 `fillMore`/`toss` 就失效**。
   `forEachLine` 的回调必须 `dupe` 一份。不 dupe 的话 test 会读到 `"l3"` 而不是 `"l1"`
   （本章测试最初就是这样红的）。

9. ⚠️ **`std.hash.autoHash` 在 0.17 是 `(hasher, key) void`（流式）**，
   不是旧版的 `autoHash(...)` 返回 `u64`。写错报 `expected 2 argument(s), found 3`。
   而且 **`f64` 不可哈希**（`@compileError("unable to hash type f64")`）。

10. ⚠️ **`std.hash.crc.Crc32` 不存在**，真名是 `crc.@"CRC-32/ISO-HDLC"`（带引号）。
    `std.hash.Crc32` 是 `hash.zig` 第 9 行给的别名。`crc` 家族有 90+ 个变体，
    `final()` 返回**位宽类型**（`CRC-8` 的 `final()` 返回 `u8`）。

11. ⚠️ **`std.base64.url_safe_encoder` 不存在**，真名是 `std.base64.url_safe`
    （`Codecs` 结构体）。四个实例：`standard` / `standard_no_pad` / `url_safe` / `url_safe_no_pad`。

12. ⚠️ **`flate.Compress` 自己就是一个 Writer**（没有 `update` 方法），
    往 `comp.writer` 写然后 `comp.finish()`。而且：
    `Decompress.init` **不返回错误**（不要 `try`），两个 init 的 scratch 都必须
    `max_window_len`（**不是** `history_len`）。zstd/lzma **只有 Decompress 没有 Compress**。

13. ⚠️ **`Writer.Allocating.init(gpa)` 的 buffer 初始长度是 0**，
    而 `flate.Compress.init` 里有 `assert(output.buffer.len > 8)` → 直接 panic。
    压缩场景必须用 `Allocating.initCapacity(gpa, n)`。

14. ⚠️ **`File.readStreaming(io, &[_][]u8{undefined})` 会 EINVAL panic**
    （`programmer bug caused syscall error: INVAL`）。切片必须初始化为**真实 buffer**：
    `var raw: [64]u8 = undefined; var one = [_][]u8{raw[0..]};`。
    它的参数是 `[]const []u8`（scatter/gather），不是单个 `[]u8`。

15. ⚠️ **`@bitCast(@Vector(N, bool))` 到整数类型要求 `N` 严格等于整数位宽**。
    `N = 3` 报 `@bitCast size mismatch: destination type 'u8' has 8 bits but source type
    '@Vector(3, bool)' has 3 bits`。`N != 32` 时用 `@select` 转 u32 再 `@reduce(.Add)`。

16. ⚠️ **0.17 里这些名字已消失**：`std.fmt.parseChar`、`std.fmt.fmtInt`、
    `std.fmt.alignIntoBuffer`、`File.readAll`、`File.readAllAlloc`、`File.writeAll`、
    `std.hash.Wyhash.smallHash`、`std.hash.Wyhash.largeHash`、`std.hash.crc.Crc32`、
    `std.base64.url_safe_encoder`。而 `allocPrint` / `bufPrint` 只是 **Deprecated**
    （还能用，有警告）——**Deprecated 和 Removed 要分清**。

---

上一章：[25 二进制数据与内存布局](25-binary.md) · 下一章：[27 目录遍历与文件树](27-tree.md)
