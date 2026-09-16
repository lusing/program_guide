# 11 · 分配器与内存 ⭐

> 对应示例：`examples/11_allocators/`
>
> Zig 最与众不同的设计：**内存策略是显式参数**。本章是全书核心章之一。

## 11.1 分配器哲学：从哪来，你说了算

C 的 `malloc` 是个全局函数——内存从"那个堆"来，测试没法换、嵌入式没有堆、多线程全局锁。C++ 的 `new` 藏在表达式里，分配行为看不见。Rust 有全局分配器可替换，但 API 层面还是"隐式拿内存"。

Zig 的答案：`std.mem.Allocator` 是个**接口**（约 40 字节的结构体，几个函数指针），所有要堆内存的函数都把它当**第一个参数**：

```zig
fn dupString(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    return allocator.dupe(u8, s);       // 用谁给的分配器，就用谁
}
```

收益直接落在工程上：**测试**注入会失败的分配器试错误路径（15 章）；**解析器**挂 arena 一把回收（11.4）；**嵌入式**给一块静态缓冲当堆（11.5）；**性能**热路径换无锁分配器——同一段代码，五种内存策略零改动。

## 11.2 Allocator 接口解剖

```zig
const a: std.mem.Allocator = ...;
const slice = try a.alloc(u32, 100);     // 分配 100 个 u32（失败返回 error.OutOfMemory）
defer a.free(slice);                     // 释放（长度要一致）
const one = try a.create(Point);         // 分配单个（返回 *Point）
defer a.destroy(one);
const copy = try a.dupe(u8, "hello");    // 复制一块
const own  = try a.realloc(slice, 200);  // 重定大小
```

| 方法 | 语义 | 备注 |
|---|---|---|
| `alloc(T, n)` | n 个 T | 返回 `[]T`，**长度信息在切片里** |
| `free(slice)` | 释放 | 传完整切片（ptr+len 都要对上） |
| `create(T)` / `destroy(p)` | 单个对象 | `*T` 版本的 alloc/free |
| `dupe(T, s)` / `dupeZ` | 拷贝（后者加哨兵 0） | 字符串处理常客 |
| `resize` / `realloc` | 原地扩 / 搬家扩 | resize 可能失败返回 null |

注意 `free` 需要**原来那个切片**（起点+长度），不是裸指针——分配器靠它记账。**混用分配器的 free 是大错**（坑位 2）。

## 11.3 六个分配器选型表

| 分配器 | 0.16 写法 | 适用 | 注意 |
|---|---|---|---|
| 栈数组 | `var buf: [N]T` | 长度已知的全部场景 | **默认选择，不碰堆** |
| `page_allocator` | `std.heap.page_allocator` | 底层/超大块 | 按页向 OS 要，小分配浪费 |
| `DebugAllocator` | `var da = std.heap.DebugAllocator(.{}){};` | **开发期默认** | 泄漏检测（见下） |
| `ArenaAllocator` | `var ar = ArenaAllocator.init(backing);` | 批量同生命周期 | 解析/请求处理，一次 deinit 全收 |
| `FixedBufferAllocator` | `var fba = FixedBufferAllocator.init(&buf);` | 无堆/热路径/测试 | 用完 `reset()` 复用 |
| `smp_allocator` | `std.heap.smp_allocator` | 多线程发布版 | 0.16 起 main 不接 Init 时的默认堆 |

### DebugAllocator（旧名 GPA）：泄漏检测实测

```zig
var da = std.heap.DebugAllocator(.{}){};
defer {
    const st = da.deinit();     // 收尾检查：有泄漏返回 .leak
    std.debug.print("收尾：{s}\n", .{@tagName(st)});   // ok / leak
}
```

`deinit()` 返回 `.ok` 或 `.leak`，泄漏时还会把**每个泄漏块的分配点**打印到 stderr（文件:行号）。开发期拿它当默认堆，`defer` 里看一眼 `ok`——泄漏当场抓获。配置项 `.{ .thread_safe = true }` 等，详见 `lib/std/heap/debug_allocator.zig` 头注释。

### Arena：一批分配一次释放

```zig
var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena_state.deinit();          // ← 下面所有分配在这里一次性归还
const arena = arena_state.allocator();
const words = try parseLine(arena, "the quick brown fox");
// parseLine 里每次 dupe 都挂 arena——中间产物零清理成本
```

解析一批数据（配置文件、HTTP 请求、AST）的内存形状天然是"树"——整个批一起活、一起死。Arena 把"每个节点单独 free"的复杂度变成 **O(1)**：只要不清盘，中间想怎么分配就怎么分配。规则：**arena 里不做单个 free**（`arena.free(x)` 合法但是 no-op 语义，别依赖）。

### FixedBuffer：一块缓冲当堆

```zig
var backing: [128]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&backing);
const f = fba.allocator();
_ = try f.alloc(u8, 50);
if (f.alloc(u8, 50)) |_| unreachable else |err| { }   // OutOfMemory：只剩 28
fba.reset();                                            // 归零复用
```

无堆环境（内核、wasm、中断上下文）或热路径（每请求一块栈缓冲）用它。用尽返回 `error.OutOfMemory`——**优雅的失败**而不是崩。`reset()` 后整块重来。

## 11.4 传参惯例：谁调用，谁负责

```zig
// 库函数：永远不自带分配器，永远第一个参数收
pub fn parseLine(arena: std.mem.Allocator, line: []const u8) ![]const []const u8 { ... }

// 应用代码：根据场景挑分配器传进去
parseLine(arena, line)       // 批处理：arena
parseLine(gpa, line)         // 长生命周期：DebugAllocator + 手动 free
parseLine(fba, line)         // 嵌入式：固定缓冲
```

**所有权约定**写进文档注释：返回的切片谁释放、用哪个分配器释放、`toOwnedSlice` 后原容器归零（12 章）。std 源码是最好的范本——每个 pub fn 的 doc comment 都交代了内存归属。

## 11.5 内存布局基本功

```zig
@sizeOf(T)       // T 占几字节（含对齐）
@alignOf(T)      // T 的对齐要求
comptime { std.debug.assert(@sizeOf(u64) == 8); }
```

**栈优先**是第一原则：长度编译期已知的 `[N]T`、小缓冲 `[64]u8`，都不该碰堆。堆是给"长度运行期才知道"的东西准备的。`undefined` 表示"我不初始化，马上要整个覆写"——读 undefined 是 UB（Debug 抓得住），写了再读就没事。

## 11.6 坑位清单

1. **跨分配器 free**：A 分的内存给 B 释放——DebugAllocator 会直接报错，其他分配器可能是 UB。**分配和释放必须是同一个分配器实例**。
2. **arena 里 free 单个对象**：合法但是 no-op（内存不还）——别把"看起来能 free"当成 arena 里做细粒度管理的理由。
3. **忘 deinit DebugAllocator**：泄漏就白检测了——`defer { _ = da.deinit(); }` 是模板的一部分。main 返回前执行的 defer 若进程直接退出，stderr 也能看到泄漏报告但退出码不变。
4. **page_allocator 做小分配**：每笔按页（4KB）对齐——100 字节也要一页。它是别的分配器的底座，不是业务代码的直接工具。
5. **`c_allocator` 要 `-lc`**：链接 libc 才存在（17 章）；拿它对比性能时别忘了编译参数。
6. **切片 free 要原切片**：`a.free(s[0..3])` 只释放一半？——不行，free 需要当初 `alloc` 返回的起点+长度，改过的切片还回去是 UB。

---
