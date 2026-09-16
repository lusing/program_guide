# 20 · 文件与 IO

> 对应示例：`examples/20_files/`
>
> 0.16 大迁移：`std.fs.File/Dir` 并入 `std.Io`，**几乎全部方法带 io 参数**——本章全是新世界写法。

## 20.1 std.Io.Dir：文件系统的心智模型

```zig
const cwd = std.Io.Dir.cwd();          // 当前目录（旧 std.fs.cwd() 已移走）
try cwd.writeFile(io, .{
    .sub_path = "build_demo.txt",
    .data = "第一行：Zig 写文件\n第二行：fin",
});
```

所有文件操作挂在 `Dir` 上：`cwd()` 起、相对路径走（相对路径天然线程安全——没有全局 cwd 竞态）、`openDir` 进子目录再操作（比拼长路径高效）。`writeFile` 一行落地整个文件，是"写小文件"的默认选择。

## 20.2 读文件：readFileAlloc

```zig
const text = try cwd.readFileAlloc(io, "build_demo.txt", mem, .limited(1024 * 1024));
```

一次读全文件：`io`、路径、分配器、**上限**（`Io.Limit.limited(n)` / `.unlimited`）——上限参数防"一个巨大文件把你内存抽干"，崩溃变成 `error.StreamTooLong`。大文件流式读用 `file.reader(io, &buf)` 的 Reader 接口（和写侧对称）。

## 20.3 元数据

```zig
const st = try cwd.statFile(io, "build_demo.txt", .{});
st.size       // 字节数（还有 mtime/kind 等）
```

## 20.4 目录：建、开、遍历

```zig
try cwd.createDirPath(io, "build_demo_dir/sub");        // 递归建（旧名 makePath）
var dir = try cwd.openDir(io, "build_demo_dir", .{ .iterate = true });  // ← Windows 必须开 iterate
defer dir.close(io);
var it = dir.iterate();
while (try it.next(io)) |entry| {       // next 也要 io
    std.debug.print("  [{s}] {s}\n", .{ @tagName(entry.kind), entry.name });
    // entry.kind: .file / .directory / .sym_link ...
}
```

`.iterate = true` 在 Windows 上**必须显式开**（底层打开标志不同）——不开的话迭代时直接 `error.AccessDenied`（实测踩中）。`entry.kind` 分派是递归遍历的骨架（24 章实战用）。

## 20.5 缓冲 Writer 写文件

```zig
const f = try cwd.createFile(io, "demo.txt", .{ .truncate = true, .read = false });
defer f.close(io);                      // close 也带 io
var fbuf: [128]u8 = undefined;
var fw = f.writer(io, &fbuf);
const w = &fw.interface;
try w.print("缓冲写入 {s}\n", .{"OK"});
try w.flush();
```

`createFile` 拿 File（选项控制 truncate/read/write/append），`f.writer(io, &buf)` 挂缓冲——和 02 章 stdout 完全同一套四步。**flush 是契约的一部分**。02 章说过：缓冲所有权在你，忘 flush 丢尾部。

## 20.6 路径：std.fs.path

```zig
const joined = try std.fs.path.join(mem, &.{ "dir", "sub", "a.txt" });   // Windows 出反斜杠
std.fs.path.basename(joined);    // "a.txt"
std.fs.path.dirname(joined);     // "dir\\sub"
```

`std.fs.path` 还在老位置（没搬）——`join/basename/dirname/resolve/isAbsolute` 跨平台处理分隔符。**join 出来的内存是分配的**（记得 free 或挂 arena）。

## 20.7 std.json：结构 ↔ JSON

```zig
const Score = struct { name: []const u8, points: u32 };
const s1 = Score{ .name = "阿 Z", .points = 99 };

// 序列化：往 Writer 打
var jbuf: [256]u8 = undefined;
var jw = std.Io.Writer.fixed(&jbuf);            // 内存缓冲当 Writer（拼接利器）
try std.json.Stringify.value(s1, .{}, &jw);
// jw.buffered() → {"name":"阿 Z","points":99}

// 反序列化：Parsed(T) 包装（托管内存）
const back = try std.json.parseFromSlice(Score, mem, jw.buffered(), .{});
defer back.deinit();                            // 字符串还借用着这块内存！
back.value.name
```

`Stringify.value(v, options, writer)` 序列化（20 章的 Writer 接口直接接入）；`parseFromSlice(T, alloc, bytes, options)` 返回 **Parsed(T)**——堆上解析结果 + 析构，**`back.value` 里的切片指向 Parsed 内部缓冲，deinit 后全部悬空**（坑位 4）。动态 JSON（不知道结构）用 `std.json.Value` 树。

## 20.8 临时目录与清理

```zig
var tmp = std.testing.tmpDir(.{});    // 测试专用（15 章）
defer tmp.cleanup();
try tmp.dir.writeFile(io, .{ .sub_path = "x.txt", .data = "abc" });
```

`deleteFile(io, path)` / `deleteTree(io, dir_path)`（递归删）负责打扫——示例的演示文件用完就清，build.ps1 重复跑不残留。

## 20.9 坑位清单

1. **`std.fs.cwd()` 没了**：0.16 用 `std.Io.Dir.cwd()`；File/Dir 及全部方法搬家带 io——抄旧代码逐个补参数。
2. **Windows 开目录不开 `.iterate` = AccessDenied**：错误出现在**迭代时**而非打开时，极具迷惑性（实测踩中）。
3. **忘 flush 丢尾部**：文件和 stdout 同一个坑（02 章），缓冲 Writer 统一规则。
4. **Parsed(T) 的字符串借用**：`parseFromSlice` 的结果切片指向内部缓冲，`deinit()` 后使用 = 悬空——要长期持有就 `dupe`。
5. **readFileAlloc 上限传太小**：正常文件报 StreamTooLong——上限该是"业务上合理的最大值"不是随手小数。
6. **迭代时删条目**：`it.next()` 期间 `deleteFile` 同目录条目——行为未定义；先收集路径，迭代完再删。

---
