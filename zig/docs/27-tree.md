# 27 · 目录遍历与文件树

> 对应示例：`examples/27_tree/`
>
> 递归走查、元数据、通配符过滤、du 汇总、树形输出——文件管理工具的骨架。取材 Tsoukalos ch5（ztree 目录可视化）与 Rios《Learning Zig》ch13（FileGuard 的遍历/过滤设计）。

## 27.1 元数据：statFile 的两种语义

```zig
const st = try cwd.statFile(io, "a.md", .{ .follow_symlinks = false });
st.size; st.kind; st.mtime;                       // 字节、类型、纳秒时间戳（Io.Timestamp）
```

`follow_symlinks = false` 是 **lstat 语义**——链接本身被"看见"（kind 是 `.sym_link`）；默认 true 则穿透到目标（书上的原话：openFile+stat 报告的是目标类型）。判断"这是个链接还是普通文件"必须关穿透。

## 27.2 递归遍历：收集完整路径

```zig
fn walk(io, a, dir, path, depth, out) !void {
    if (depth > 16) return;                        // 套娃防线
    var d = try dir.openDir(io, path, .{ .iterate = true });  // Windows 必须 .iterate
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |entry| {
        const child = try std.fs.path.join(a, &.{ path, entry.name });
        switch (entry.kind) {
            .directory => { try walk(io, a, dir, child, depth + 1, out); a.free(child); },
            .file => try out.append(a, child),
            else => {},                            // 符号链接不跟：防环
        }
    }
}
```

两个所有权决策值得咀嚼：**目录路径是脚手架**（递归返回即释放），**文件路径移交输出列表**。递归工具的内存纪律就是"谁的归谁"。

## 27.3 通配符：30 行的 glob

示例的 `matchGlob` 只支持 `*` 与 `?`，递归回溯实现——零依赖、可单测、够日常用（`*.txt`、`?.log`、`.*`）。复杂需求（字符类、`**`）再上真 glob 库；先把"模式匹配"这件事的原理写明白。

## 27.4 du 汇总与树形输出

`dirSize` 递归累加文件字节数（目录不另计）；`printTree` 排序后按 `├──/└──` 前缀递归下降——`prefix` 每层拼四格或竖线，这是 tree(1) 的全部视觉秘密。

## 27.5 坑位清单

1. **`entry.name` 活不过下一次 `next()`**：迭代器内部缓冲复用——跨 `next` 收集名字必须 `dupe`（示例 printTree 的修正现场：不 dupe 时 c.txt 变 d.log、排序输出错乱、statFile 报 FileNotFound，全是一个根因）。
2. **Windows 开目录不给 `.iterate = true`**：迭代时 AccessDenied（20 章老坑，递归版再踩一次）。
3. **join 用哪个分配器，free 就用哪个**：递归里 `std.heap.page_allocator` 拼路径一时爽，测试分配器逮泄漏时定位到怀疑人生。
4. **符号链接默认不跟**：跟了就可能成环（链接指向上层目录）；要跟就限制深度或记录 (dev, inode) 已访问集合。
5. **示例从仓库根运行**：build.ps1 在 `zig/` 根跑 exe——演示别 stat 相对 cwd 的既有文件（`main.zig` 只在示例目录存在），一律自建沙盒自清理（27 章的修正现场）。

---

上一章：[26 编码与流处理](26-encoding.md) · 下一章：[28 文件监视](28-watch.md)
