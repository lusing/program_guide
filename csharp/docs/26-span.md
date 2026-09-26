# 26 · Span 与高性能内存

> 对应示例：`examples/26_span`

> **本章你将学会**：Span 的窗口语义、ReadOnlySpan<char> 零分配解析、stackalloc、Memory<T> 与跨 await、ArrayPool、分配量观测。
> **前置章节**：[05 值与引用](05-value-reference.md)、[25 GC](25-gc.md)。

## 1. Span 是什么：窗口，不是拷贝

数组切片的传统做法 `arr[1..4]` 会**新造一个数组**（分配 + 拷贝）。`Span<T>` 是**指向原内存的窗口**：

```csharp
var array = new[] { 10, 20, 30, 40, 50 };
Span<int> all = array;                 // 整段窗口（零拷贝）
Span<int> middle = all.Slice(1, 3);    // [20,30,40] 的窗口（零拷贝）
middle[0] = 99;                        // 通过窗口改——原数组跟着变
// array = [10, 99, 30, 40, 50]
```

Span 内部是"起点指针 + 长度"（的值类型包装）——创建/切分零分配。它可以窗口数组、栈内存（stackalloc）、非托管内存、string（ReadOnlySpan<char>）。**BCL 大量 API 有 Span 重载**（int.Parse、string 构造、流写入）——传 Span 版本免拷贝。

代价与限制（ref struct 的身份决定的）：

- **只能活在栈上**：不能做字段、不能进异步方法、不能装箱、不能进泛型 T
- 生命周期限制在当前方法帧——**窗口不能活得比被窗的内存久**

## 2. ReadOnlySpan<char>：解析器的省账利器

热路径字符串处理的传统账单：每次 Substring/IndexOf 后切片都分配新串：

```csharp
var line = "编号=1024;名称=张三";
foreach (var token in line.Split(';'))            // Split 本身分配数组+子串
{
    var eq = token.IndexOf('=');
    var key = token.AsSpan(0, eq);                // 窗口：零分配
    var value = token.AsSpan(eq + 1);
    // key.Length/value 都能用；要真正 string 时再 .ToString()（单次分配）
}
```

`AsSpan` 把 string 当窗口看。模式：**处理全程用 Span，最终结果才物化成 string**——中间千百次切片零分配。日志解析、协议解码、CSV/JSON 高性能路径的标准写法（BCL 自己就是这么优化的）。

## 3. stackalloc：栈上的小临时缓冲

```csharp
Span<byte> buffer = stackalloc byte[8];    // 栈上分配：方法返回自动回收，GC 无感
```

**栈分配 vs 堆分配**：零 GC 压力、极快分配（挪个栈指针）。适用三条全满足：**小（经验值 ≤1KB）、本方法内用完、长度已知或小上限**。超线（大了）会栈溢出（栈默认 1MB）——大缓冲走 ArrayPool。`Span<int> s = stackalloc int[n]` 配合 C# 的集合表达式（`[1, 2, 3]`）也常见。

## 4. Memory<T>：能跨 await 的窗口

Span 不能进异步方法（栈语义 vs 方法可能挂起重入）。**Memory<T> 是"可存活的窗口句柄"**：

```csharp
async Task<int> SumLaterAsync()
{
    Memory<int> mem = new[] { 1, 2, 3, 4 };
    await Task.Yield();               // 挂起——Span 在这就编译错误
    var s = 0;
    foreach (var v in mem.Span) s += v;   // 用时再换 Span
    return s;
}
```

规则：**方法内同步路径用 Span，需要存放（字段/异步/队列）用 Memory**。BCL 的异步 API（Stream.ReadAsync(Memory<byte>)）收的就是 Memory——第 32 章文件 IO 的现代签名。

## 5. ArrayPool：大缓冲的租还

高频创建大数组的场景（网络缓冲、序列化中间区）：

```csharp
var pool = System.Buffers.ArrayPool<int>.Shared;   // 进程级共享池
var rented = pool.Rent(1024);                      // 租（容量可能 ≥ 请求值！）
try { /* 用 rented.AsSpan(0, 实际长度) */ }
finally { pool.Return(rented); }                   // 还——复用而非 GC
```

两个纪律：**容量 ≥ 请求**（按请求长度切 Span 用，别信 Length）；**try/finally 归还**（丢还 = 池变漏）。适合"尺寸大 + 分配频繁 + 用完即弃"的模式；中小对象直接 new（gen0 免费，25 章结论）。

## 6. 分配量观测：用数字说话

```csharp
var before = GC.GetAllocatedBytesForCurrentThread();
// ... 被测代码 ...
var after = GC.GetAllocatedBytesForCurrentThread();
Console.WriteLine($"{after - before:N0} 字节");
```

当前线程的累计分配字节数——**优化前后各测一次，省下的分配一目了然**。配合 BenchmarkDotNet（社区标准基准库）做严格对比；快速验证用它够了。示例实测 1000 次字符串拼接的分配量——Span 方案的同类操作分配为零。

## 7. 什么时候上 Span：判断清单

先问三个问题，全"是"再上：

1. 这是**热路径**吗（每秒万次级/大文件逐段）？
2. 有**分配证据**吗（GC 计数高/GetAllocatedBytes 显示大量临时）？
3. 常规手段（StringBuilder、复用 buffer、改算法）没用了吗？

普通业务代码（每请求几百次分配）**不需要 Span**——gen0 回收免费（25 章）。Span 是协议解析、序列化引擎、计算内核这一层的武器。过早 Span 化 = 可读性换不存在的性能。

## 常见坑

**Span 存进字段/闭包/异步**：编译错误（ref struct 限制）——要跨生命周期换 Memory<T>。

**ArrayPool.Rent 的 Length 陷阱**：返回数组容量 ≥ 请求——遍历到 rented.Length 会多跑垃圾数据；记录请求长度或用 Span 截取。

**窗口比被窗内存活得久**：Span 指向的局部数组方法返回后窗口悬空——限制在方法内用是硬保护（编译器管着）。

**string 的 Span 不是 string**：`span.ToString()` 每次都分配——要 string 就一次转好存起来，别在循环里反复 ToString。

**到处 Span 化冷代码**：可读性暴跌、性能无感——按第 7 节清单判断，90% 的代码不需要。

## 实战建议

- 解析热路径的固定套路：**ReadOnlySpan<char> 全程 + 结果处单次物化**
- 缓冲区三档：小临时 stackalloc、中大临时 new（gen0）、大且频繁 ArrayPool
- 异步管道（流式读写）统一 Memory<byte> + 用时 .Span
- 学习路径：先读 BCL 源码里的 Span 用法（如 int.Parse(ReadOnlySpan<char>)），再在自己的解析器里小范围试验 + 分配量前后对比
- 第 27 章 unsafe 的很多场景，今天用 Span 就够了——**先 Span 后指针**

## 自测

1. **Span 与切片数组的本质区别？** —— 窗口（零拷贝，改动穿透）vs 新数组（拷贝独立）。
2. **Span 为什么不能进异步方法？Memory 怎么补位？** —— ref struct 栈语义限制；Memory 可存放、用时取 .Span。
3. **stackalloc 的三条适用线？** —— 小（≤1KB 级）、方法内用完、长度已知/小上限。
4. **ArrayPool.Rent 的两个纪律？** —— 容量 ≥ 请求（按实际长度用）；try/finally 归还。

---
上一章：[25 GC 与内存管理](25-gc.md) ｜ 下一章：[27 unsafe 与互操作](27-unsafe-interop.md) ｜ 返回：[README](../README.md)
