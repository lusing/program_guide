# 28 · 文件监视

> 对应示例：`examples/28_watch/`
>
> "目录里发生了什么"——构建工具的热重载、同步工具的触发器都靠它。取材 Tsoukalos ch5（zwatch：Linux inotify / BSD kqueue）与 Rios ch13（FileGuard 的快照比对思想）。

## 28.1 现状盘点：std 没有跨平台 watch

0.16 的 `std.Io` 没有文件系统事件接口；书上的 zwatch 也是按 OS 分叉（inotify/kqueue）。Windows 的对应物是 `ReadDirectoryChangesW`——`std.os.windows` 里连声明都没有，自己 extern。所以本章双路：**轮询核**（跨平台、可测、保底）+ **Windows 原生**（extern 直调，17 章的进阶实战）。

## 28.2 轮询核：快照求差

```zig
const PollWatcher = struct {
    state: std.StringHashMap(Entry),     // path → (size, mtime)
    // baseline() 建基线；poll() 扫描-求差-换血
};
```

事件 = 两次扫描的差集：新键 created、消失 removed、(size, mtime) 变化 modified。诀窍在**什么时候 poll 你说了算**——测试里手动驱动，零计时依赖、完全确定：

```zig
try w.baseline();
try writeFile("n1.txt");
try w.poll(&events);          // 恰好一条 created: n1.txt
```

生产用法套一层定时循环（`std.Io.sleep(io, Duration.fromMilliseconds(200), .awake)`）。粒度与延迟由轮询间隔决定——够不上 inotify 的实时性，但跨平台零惊喜。

## 28.3 所有权：事件与基线不共键

`poll` 里基线 map 每轮换血——事件路径一律 `dupe`，与 map 键严格分家。"借 map 键省一次拷贝"的诱惑在下一轮换血时变成悬空指针。跨 map/列表共享字符串前，先问一句：**谁什么时候释放它**。

## 28.4 Windows 原生：ReadDirectoryChangesW 直调

```zig
const native = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn CreateFileW(...) callconv(.winapi) w.HANDLE;
    extern "kernel32" fn ReadDirectoryChangesW(...) callconv(.winapi) w.BOOL;
    // ...
} else struct { const enabled = false; };
```

要点全在细节里：

- **平台门控用命名空间**：整段 extern 装进 `if (os.tag == .windows) struct {...} else 空壳`——extern 声明和 `callconv(.winapi)` 只在真目标上参与编译。
- **`callconv(.winapi)`**：0.16 里 `.win64` 这个老名字没了；`.winapi` 自动选 x86_64_win / x86_stdcall 等。
- **打开目录必须 `FILE_FLAG_BACKUP_SEMANTICS`**，否则 CreateFileW 拒绝目录句柄。
- **阻塞读 + 写入线程**：RDCW 只报告"调用之后"的变更——写入必须发生在阻塞期间（示例派 writer 线程，100ms 后动一下，RDCW 立刻带事件返回）。
- **事件是不定长记录链表**：`next_offset == 0` 收尾，文件名是 UTF-16、跟在头部之后不齐整对齐——按字节推进。

## 28.5 坑位清单

1. **0.16 的 windows.BOOL 是枚举不是整数**：`ok == 0` 编译不过；比较 `.FALSE`，传参 `.FALSE/.TRUE`。
2. **RDCW 之前写入 = 白写**：调用前落盘的变更不会补报——顺序是"先挂监视，再动文件"。
3. **mtime 是 `Io.Timestamp` 结构**：取纳秒用 `st.mtime.nanoseconds`（`@intCast` 直接怼它会被类型系统打回）。
4. **测试别依赖真实时钟**：轮询核的手动驱动模式就是为此——同步逻辑与时间解耦，想测多快测多快。
5. **CreateFileW 的路径要 UTF-16 + NUL**：ASCII 可以手搬，中文路径老老实实 `utf8ToUtf16LeAlloc` 再补零。

---

上一章：[27 目录遍历与文件树](27-tree.md) · 下一章：[29 TCP 与 UDP](29-networking.md)
