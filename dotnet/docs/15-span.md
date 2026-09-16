# 15 · Span 与 Memory：少分配的高性能之道

> 对应示例：`examples/15_span`

## 1. 分配是性能的隐形税

`"10,20,30".Split(',')` 干了什么：分配一个 `string[]`（3 个元素）+ 3 个新 string（每个数字一份拷贝）——**为了看一眼三个数字，制造了四个堆对象**。每个对象都要 GC 出生、存活、回收；分配速度越快、GC 越频繁，停顿越密。高吞吐路径（解析器、网络缓冲、序列化）上，"减少分配"就是"减少 GC"就是"稳定的低延迟"。

`Span<T>` 的答案：**不拷贝数据，只递一扇指向数据的窗口**。

## 2. ReadOnlySpan：示例的 CSV 解析

示例全文（21 行）拆两段看，先看第一段：

```csharp
var text = "10,20,30,40";
ReadOnlySpan<char> span = text.AsSpan();
var sum = 0;
var start = 0;

for (var i = 0; i <= span.Length; i++)
{
    if (i == span.Length || span[i] == ',')
    {
        var part = span[start..i];
        sum += int.Parse(part);
        start = i + 1;
    }
}
```

逐块解读：

- `text.AsSpan()`：把 string 变成 `ReadOnlySpan<char>`——**不拷贝**，span 内部只是"指向原 string 字符数据的起点 + 长度"。
- `span[start..i]`：**切片**（范围语法，见 §3）——同样不拷贝，只是另一扇更窄的窗口。循环扫到逗号就切出一个"数字窗口"。
- `int.Parse(part)`：BCL 为 span 准备的无分配重载——直接从窗口读出数值，全程没有产生任何新 string。

对比 Split 版：堆分配从 5 个对象（数组 + 4 个数字串）降到 **0**。语义完全一致，代码只多了一个游标变量 `start`。

`ReadOnlySpan<T>` vs `Span<T>`：只读窗口 vs 可读可写窗口。字符串不可变（第 03 章），所以 `AsSpan()` 给的是 ReadOnly 版；要原地改数据用 `Span<T>`。

## 3. 索引与范围：切片语法

切片能写，靠的是 C# 8 的 Index/Range 语法，示例两处都在用：

```csharp
span[start..i]     // Range：从 start 到 i（不含 i）
span[^1]           // Index：倒数第一个（^1 = 从末尾数 1）
span[..n]          // 从头到 n
span[n..]          // 从 n 到末尾
```

这些语法同样适用于数组和 string（`text[^1]`、`arr[1..3]`），span 只是让它们**零拷贝**。

## 4. Span + stackalloc：栈上缓冲

示例第二段：

```csharp
Span<int> data = stackalloc int[3];
data[0] = 7;
data[1] = 8;
data[2] = 9;
Console.WriteLine($"sum={sum}, last={data[^1]}");
```

`stackalloc` 在**栈**上开一块 3 个 int 的缓冲（`Span<int>` 指向它）——方法返回时自动消失，GC 全程不知情。这曾是 unsafe 代码的专利，配合 Span 变成了安全语法。**纪律**：栈空间有限（通常 1MB 级），stackalloc 只开小缓冲（几十~几百字节量级）；大小不定或较大用 `ArrayPool<T>.Shared.Rent` 租借。

## 5. Span 的纪律：为什么它有那么多限制

Span 是"栈专用窗口"——指向的内存可能随栈帧销毁而失效，所以语言层面禁止：

- **不能存成字段**（方法返回后窗口悬空）；
- **不能跨 `await`**（异步恢复时栈早换了）；
- **不能装箱**、不能进泛型 `T`、不能用在 lambda 捕获里。

这些限制不是缺陷而是保护。确需跨边界传递（字段、异步流）时用 **`Memory<T>`**：可以存字段、可以异步，用时 `.Span` 取窗口（多一步显式转换，换来安全）。

## 6. 何时用：先写对，再写快

Span 让代码更"底层"（游标、窗口、手动边界），可读性有代价。正确姿势：**先用 LINQ/Split 写出正确的版本；剖析（`dotnet-counters` 看 GC 率、BenchmarkDotNet 计时）证明某段是热点，再换 Span**。90% 的代码永远不会是热点——本章工具是给那 10% 准备的。

## 7. 坑位清单

1. **span 指向的数据变了**：span 是窗口不是快照——底层 string/数组被修改后，窗口内容跟着变；靠 span 缓存"旧值"是错觉。
2. **stackalloc 过大**：栈溢出（StackOverflowException 直接杀进程、无法 catch）；超过百字节量级改用 ArrayPool。
3. **async 方法里声明 Span**：直接编译错 CS4011/CS8175——用 `Memory<T>` 替代。
4. **Span 逃逸出方法**：返回类型用 Span 且指向栈缓冲会编译错；返回窗口的前提是底层内存是堆的或调用者提供的。
5. **为了快牺牲对**：先 Profile 后优化——没证据的热点优化，换来的复杂度大概率白付（第 20 章的 StringBuilder 段落是同样心法的另一案例）。
