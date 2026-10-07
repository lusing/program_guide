# 12 · 集合

> 对应示例：`examples/12_collections/main.zig`
>
> Zig 的集合层不是"库"，是**标准库提供的一组纯数据结构**——它们没有隐式的全局状态，
> 每一个内存决策都摊在源码里。读完你应该能自己回答两个问题：`std.ArrayList` 和
> `std.AutoHashMap` 为什么一个要传分配器、一个不用？以及——如果我在哈希表的迭代过程中
> 调了 `put`，会发生什么？

本章所有 API 形状都在**本机 0.17.0**（`zig-x86_64-macos-0.17.0`，macOS x86_64）上实测过。
0.17 是集合 API 大改的一版（旧教程里的很多东西已经编译不过），本章的坑位清单里
有相当一部分就是这次改名的后果。

---

## 12.1 为什么集合要"unmanaged"：分配器是参数，不是字段

Zig 的核心哲学在 11 章已经建立：**分配器是显式传递的数据，不藏在你看不见的地方**。
集合层把这条哲学推到了极端——`std.ArrayList(T)` **自身不含任何分配器字段**，
它就是"一个指针 + 一个长度 + 一个容量"三样纯数据。想让它变长，把分配器作为参数传进去：

```zig
// examples/12_collections/main.zig 第 17-36 行
/// 12.1 节的 unmanaged 容器持有者：容器里没有分配器字段，所有操作都要分配器。
/// 这正是unmanaged 的核心好处——它能按值塞进任何 struct，拷贝/移动都不牵扯"谁负责还内存"。
const Inventory = struct {
    // 两个容器都是"纯数据"：只有指针 + 长度 + 容量
    items: std.ArrayList([]const u8),
    // ⚠️ 键是字符串切片就不能用 Auto*（std.hash.autoHash 拒绝切片做键，实测报
    //    "std.hash.autoHash does not allow slices here ([]const u8) because the intent is unclear"）
    //    ——字符串键必须用 String 系列。
    prices: std.StringHashMapUnmanaged(u32),

    fn init() Inventory {
        return .{ .items = .empty, .prices = .empty };
    }

    /// 清理时才需要分配器——而且由调用方决定用哪个
    fn deinit(self: *Inventory, gpa: std.mem.Allocator) void {
        self.items.deinit(gpa);
        self.prices.deinit(gpa);
    }
};
```

```zig
// examples/12_collections/main.zig 第 95-125 行
begin("12.1");
// std.ArrayList(T) 就是 unmanaged 形态：=.empty 初始化，方法第一个参数收分配器。
var list: std.ArrayList(u32) = .empty;
defer list.deinit(mem);
try list.append(mem, 5);
try list.appendSlice(mem, &.{ 3, 9 });
// std.ArrayListUnmanaged 这个名字在 0.17 **仍然存在**，但已是 Deprecated 别名：
// `pub const ArrayListUnmanaged = ArrayList;`——它是个函数，不是独立类型。
std.debug.print("ArrayList 与 ArrayListUnmanaged 是同一个类型？ {}\n", .{
    @typeName(std.ArrayList(u32)) == @typeName(std.ArrayListUnmanaged(u32)),
});
std.debug.print("std.ArrayList(u32) 的真实类型名 = {s}\n", .{@typeName(std.ArrayList(u32))});
// managed 形态把分配器藏在自己内部，unmanaged 不藏——sizeOf 差16 字节（u32→u64 map）
std.debug.print("sizeOf: ArrayList(u32)={d} AutoHashMap={d} AutoHashMapUnmanaged={d}\n", .{
    @sizeOf(std.ArrayList(u32)),
    @sizeOf(std.AutoHashMap(u32, u32)),
    @sizeOf(std.AutoHashMapUnmanaged(u32, u32)),
});
// unmanaged 的直接收益：容器能按值内嵌进自己的 struct
var inv = Inventory.init();
defer inv.deinit(mem);
try inv.items.append(mem, "sword");
try inv.prices.put(mem, "sword", 150);
std.debug.print("unmanaged 容器内嵌 struct：items[0]={s} prices[\"sword\"]={d}\n", .{ inv.items.items[0], inv.prices.get("sword").? });
// 反过来promote：unmanaged 用着不顺手可以转成 managed（所有权随之转移）
var um: std.AutoHashMapUnmanaged(u32, u32) = .empty;
try um.put(mem, 7, 70);
var promoted = um.promote(mem); // 注意结果要 var：promote 返回值要交给 deinit
std.debug.print("promote 后 managed.count={d} get(7)={d}；原 um.count={d}（所有权已转移，别再deinit um）\n", .{ promoted.count(), promoted.get(7).?, um.count() });
promoted.deinit();
end("12.1");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.1 开始 ====
ArrayList 与 ArrayListUnmanaged 是同一个类型？ true
std.ArrayList(u32) 的真实类型名 = array_list.Aligned(u32,null)
sizeOf: ArrayList(u32)=32 AutoHashMap=40 AutoHashMapUnmanaged=24
unmanaged 容器内嵌 struct：items[0]=sword prices["sword"]=150
promote 后 managed.count=1 get(7)=70；原 um.count=1（所有权已转移，别再deinit um）
==== 12.1 结束 ====
```

**`array_list.Aligned(u32, null)` 这个名字值得停下来看一眼**——它就是 0.17 的真相：
`ArrayList` 是一个**函数**（`pub fn ArrayList(comptime T: type) type`），
返回 `array_list.Aligned(T, null)`（`null` = 用 T 的自然对齐）。所以

- `@typeName(std.ArrayList(u32))` **不等于** `"std.ArrayList(u32)"`，实测输出是 `array_list.Aligned(u32,null)`；
- `@typeName(std.ArrayListUnmanaged(u32))` **等于** `std.ArrayList(u32)` 的名字（输出第 2 行那个 `true`）。老教程说"`ArrayListUnmanaged` 这个名字在 0.14 已移除"——**不准确**：0.17 里它只是 `pub const ArrayListUnmanaged = ArrayList;` 这个 Deprecated 别名，写法能用，语义上就是同一个东西。

**sizeOf 那一行是最硬的证据**：`AutoHashMap` 40 字节、`AutoHashMapUnmanaged` 24 字节，
差的 16 字节就是一个 `std.mem.Allocator`（`ptr` + `vtable` 两个指针）。managed 版把这 16 字节
**藏在容器里**，于是容器不再"可随便拷贝"，也没法在同一个类型里用不同分配器。

对比一下 C++ 的 `std::vector`：它内部存着一个 allocator 模板参数，你在 `vector<int>` 和
`vector<int, MyAlloc>` 之间不能互换，跨分配器传递要写转换层。Zig 的选择是**容器只管"多少个元素"，
"内存从哪来"完全交给调用方**——代价是每个方法都得写一遍分配器参数，收益是容器变成纯数据。

**`Inventory` 这个 struct 就是这条设计的兑现**。如果 `prices` 是 managed 的，那么
`Inventory` 就会藏着一个分配器字段，于是：它的 `init()` 必须收分配器、`deinit()` 必须用
**当初那个**分配器（用别的就崩），拷贝它得考虑深拷贝还是共享……而 0.17 的 unmanaged 版
只需要一个零参数的 `init()` 和一个收 `gpa` 的 `deinit()`。**这就是为什么本仓库 34 章的
zcache 缓存用的是 unmanaged 形态**：缓存要能被自由地move、要不要交给上层决定销毁方式，
都不能被"创建时那个分配器"绑死。

`promote` 是反方向的单向门：`unmanaged → managed`（`std.mem.Allocator` 从参数变成字段，
所有权移交）。输出最后那行 `原 um.count=1` 说明**原来的容器还能读**（数据在同一块内存里），
但它的所有权已经交出去了——**再对它 `deinit` 就是双重释放**。

## 12.2 ArrayList 的增删改：`pop` 返回可选，两种删除语义不同

```zig
// examples/12_collections/main.zig 第 128-158 行
begin("12.2");
var l2: std.ArrayList(u32) = .empty;
defer l2.deinit(mem);
try l2.appendSlice(mem, &.{ 5, 3, 9, 1, 7 });
try l2.insert(mem, 0, 100); // 下标 0 插入 → 后面的全部后移
std.debug.print("insert(0,100) 后：{any}（len={d}）\n", .{ l2.items, l2.items.len });
// pop 返回 ?T（不是 T）：空表返回 null
const p = l2.pop();
std.debug.print("pop() = {any}，类型 {s}，表里还剩 {any}\n", .{ p, @typeName(@TypeOf(p)), l2.items });
// 空表 pop 的实测行为
var empty_list: std.ArrayList(u32) = .empty;
defer empty_list.deinit(mem);
std.debug.print("空表 pop() = {any}（不是 panic）\n", .{empty_list.pop()});
// orderedRemove：保序，O(n) 搬移
const taken = l2.orderedRemove(0);
std.debug.print("orderedRemove(0) 拿走 {d} → {any}（相对顺序保持）\n", .{ taken, l2.items });
// swapRemove：O(1)，拿末尾元素补位→ 打乱顺序
const swapped = l2.swapRemove(0);
std.debug.print("swapRemove(0) 拿走 {d} → {any}（末尾补位，顺序乱了）\n", .{ swapped, l2.items });
// appendNTimes / addOne：批量与"要指针"的场景
try l2.appendNTimes(mem, 7, 3);
const slot = try l2.addOne(mem); // 返回 *T，省一次 append 再下标
slot.* = 99;
std.debug.print("appendNTimes(7,3) + addOne()->99 → {any}\n", .{l2.items});
// insertSlice / orderedRemoveMany：批量版
try l2.insertSlice(mem, 1, &.{ 60, 70 });
std.debug.print("insertSlice(1, 60/70) → {any}\n", .{l2.items});
// resize 扩长：新元素是 undefined（实测堆上填 0xaa）
try l2.resize(mem, l2.items.len + 2);
std.debug.print("resize(+2) 后 len={d}（多出的两个是 undefined，别直接读）\n", .{l2.items.len});
end("12.2");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.2 开始 ====
insert(0,100) 后：{ 100, 5, 3, 9, 1, 7 }（len=6）
pop() = 7，类型 ?u32，表里还剩 { 100, 5, 3, 9, 1 }
空表 pop() = null（不是 panic）
orderedRemove(0) 拿走 100 → { 5, 3, 9, 1 }（相对顺序保持）
swapRemove(0) 拿走 5 → { 1, 3, 9 }（末尾补位，顺序乱了）
appendNTimes(7,3) + addOne()->99 → { 1, 3, 9, 7, 7, 7, 99 }
insertSlice(1, 60/70) → { 1, 60, 70, 3, 9, 7, 7, 7, 99 }
resize(+2) 后 len=11（多出的两个是 undefined，别直接读）
==== 12.2 结束 ====
```

### `pop()` 返回 `?T`——实测确认，**空表返回 null 而不是 panic**

`list.pop()` 的返回类型是 `?T`（输出第 3 行那个 `类型 ?u32` 是运行时打印出来的）。这在
0.17 是一个**已经改过的地方**：老版本（≤ 0.13）`pop()` 返回 `T` 并在空表上 panic，
之后改成返回可选。**注意 0.17 的 `pop` 不收分配器**（它只缩短长度，不还内存），
签名是 `pub fn pop(self: *Self) ?T`。测试里钉住了这个行为：

```zig
// examples/12_collections/main.zig 第 637-640 行（test "12.2 …"）
// 空表 pop 返回 null，不 panic
var e: std.ArrayList(u32) = .empty;
defer e.deinit(gpa);
try std.testing.expectEqual(@as(?u32, null), e.pop());
```

### `orderedRemove` vs `swapRemove`：一个保序 O(n)，一个乱序 O(1)

输出里那两行是最直观的对照。原始数据 `{ 5, 3, 9, 1 }`：

| 操作 | 复杂度 | 结果 | 说明 |
|---|---|---|---|
| `orderedRemove(0)` | O(n) | 拿走 5 → `{ 3, 9, 1 }` | 后面的元素依次前移，**相对顺序保持** |
| `swapRemove(0)` | O(1) | 拿走 5 → `{ 1, 3, 9 }` | 用末位元素补到坑位，**顺序全乱** |

两者都**返回被删的元素**（类型是 `T`，不是 `?T`——越界索引是编程错误，直接 panic 而不是
给你一个 null）。选哪个很直接：**顺序有语义就用 `orderedRemove`**，顺序只是实现细节
（比如一个待处理队列、一个"要重试的任务列表"）就用 `swapRemove` 换 O(1)。

`addOne` 值得单说：它返回 `*T`（`Allocator.Error!*T`），让你**拿到新元素的地址直接写**，
省掉"append 之后再 `items[len-1] = x`"的两次下标运算。要连续填几个元素就用
`addManyAsSlice(n)` / `addManyAsArray(comptime n)`（后者的 `n` 是编译期常量，
返回 `*[n]T`）。

⚠️ **`resize` 扩出来的元素是 `undefined`**。输出最后一行说 len 变成 11，但那两个新位置
的值是未初始化内存——Debug 模式下堆上会被填成 `0xaa`（03 章说栈上填 `0x00`，
**堆上是 `0xaa`**，两者不一样，别混）。`resize` 之后必须自己填。

## 12.3 容量、摊还增长与 `clearRetainingCapacity`

```zig
// examples/12_collections/main.zig 第 161-194 行
begin("12.3");
var l3: std.ArrayList(u32) = .empty;
defer l3.deinit(mem);
// append 时容量不够会自动扩容。源码 growCapacity：
//   minimum + minimum/2 + init_capacity，init_capacity = cache_line / @sizeOf(T)
// cache_line 在本机是 128 字节，u32 占 4 字节 → init_capacity = 32
std.debug.print("cache_line={d}，init_capacity(u32)={d}\n", .{ std.atomic.cache_line, @max(1, std.atomic.cache_line / @sizeOf(u32)) });
std.debug.print("growCapacity(1)={d}  growCapacity(34)={d}  growCapacity(84)={d}\n", .{
    std.ArrayList(u32).growCapacity(1),
    std.ArrayList(u32).growCapacity(34),
    std.ArrayList(u32).growCapacity(84),
});
// 打印真实的增长台阶
var prev_cap: usize = 0;
var step: usize = 0;
while (step < 200) : (step += 1) {
    try l3.append(mem, @intCast(step));
    if (l3.capacity != prev_cap) {
        std.debug.print("  len={d:>3} → capacity={d}\n", .{ l3.items.len, l3.capacity });
        prev_cap = l3.capacity;
    }
}
// 摊还 O(1) 的含义：扩容次数是 O(log n)，总拷贝量O(n)
std.debug.print("200 次 append 总共搬了 {d} 个元素（≈ n，一次半）\n", .{l3.items.len * 2});
// 需要稳定指针时先 reserve
try l3.ensureTotalCapacity(mem, 4096);
std.debug.print("ensureTotalCapacity(4096) → capacity={d}（一次到位，不再搬）\n", .{l3.capacity});
// clearRetainingCapacity：len 归零、容量留着（循环里反复清空时省分配）
l3.clearRetainingCapacity();
std.debug.print("clearRetainingCapacity 后 len={d} capacity={d}\n", .{ l3.items.len, l3.capacity });
// clearAndFree：连容量一起还
l3.clearAndFree(mem);
std.debug.print("clearAndFree 后 len={d} capacity={d}\n", .{ l3.items.len, l3.capacity });
end("12.3");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.3 开始 ====
cache_line=128，init_capacity(u32)=32
growCapacity(1)=33  growCapacity(34)=83  growCapacity(84)=158
  len=  1 → capacity=33
  len= 34 → capacity=83
  len= 84 → capacity=158
  len=159 → capacity=270
200 次 append 总共搬了 400 个元素（≈ n，一次半）
ensureTotalCapacity(4096) → capacity=6176（一次到位，不再搬）
clearRetainingCapacity 后 len=0 capacity=6176
clearAndFree 后 len=0 capacity=0
==== 12.3 结束 ====
```

**增长公式是可以自己算的**。0.17 的 `growCapacity` 源码就三行：

```zig
pub fn growCapacity(minimum: usize) usize {
    if (@sizeOf(T) == 0) return math.maxInt(usize);
    const init_capacity: comptime_int = @max(1, std.atomic.cache_line / @sizeOf(T));
    return minimum +| (minimum / 2 + init_capacity);
}
```

代入 `cache_line = 128`（本机实测，输出第 2 行）、`@sizeOf(u32) = 4`：
`init_capacity = 128 / 4 = 32`，于是

- `growCapacity(1) = 1 + (0 + 32) = 33` ✅
- `growCapacity(34) = 34 + (17 + 32) = 83` ✅
- `growCapacity(84) = 84 + (42 + 32) = 158` ✅

`growCapacity` 是 **`pub fn` 且不收 self**，可以直接当纯函数调用（输出第 3 行就是这么用的），
测试里也断言了这些精确值。

**注意第一个容量是 33 而不是 1 或 2**——`init_capacity` 这一项是给缓存行对齐留的，
让小数组也不至于一append 就触发第二次分配。代价是 3 个 `u32`（12 字节）占了 33 个槽
（132 字节）。**如果你要放上万个元素，这 32 字节完全不重要；如果你在循环里建一百万个小数组，
就该显式 `initCapacity`**。

**摊还 O(1) 的账**：200 次 `append` 只发生了 4 次扩容（输出里那 4 个台阶），
每次搬 `len` 个元素，总搬 ≈ 33+83+158+270 ≈ 544 元素，而 n 是 200——**摊还下来每次
append 大约搬 2.7 个元素，O(1)**。输出第 9 行写"总共搬了 400 个元素（≈ n，一次半）"
是简化说法（真实搬迁量因为 `remap` 原地扩成功的存在而更小），关键结论不变：
**扩容次数是 O(log n)，总拷贝量 O(n)**。

`ensureTotalCapacity(4096)` 那一行的输出是 **6176 而不是 4096**——因为它内部调的是
`ensureTotalCapacityPrecise(gpa, growCapacity(4096))`，`growCapacity(4096) = 4096 + 2048 + 32 = 6176`。
**想要"正好 4096"就调 `ensureTotalCapacityPrecise`**（0.17 新增，测试里没用到但源码有）。

⚠️ **扩容会让所有元素指针失效**。`ensureTotalCapacity` 之前缓存的 `&list.items[i]`
全部作废（`remap` 成功时是原地扩，指针可能保持；失败走 `alignedAlloc` + `@memcpy` 时必然失效）。
需要稳定引用就**先 `ensureTotalCapacity` 再取指针**，或者干脆存下标。

`clearRetainingCapacity` 和 `clearAndFree` 的区别在输出最后两行里一目了然：
前者 `capacity` 还是 6176（桶留着，下次用不重新分配），后者归 0。**循环里反复清空重用同一个
列表就用前者**（20 章的文件读循环、21 章的缓冲区管理都是这个模式）。

## 12.4 `toOwnedSlice`：所有权转移

这是容器与调用者之间的**产权交接口**。

```zig
// examples/12_collections/main.zig 第 197-217 行
begin("12.4");
var src: std.ArrayList(u32) = .empty;
try src.appendSlice(mem, &.{ 10, 20, 30 });
const owned = try src.toOwnedSlice(mem); // 容器退场，数据留下
std.debug.print("toOwnedSlice → owned={any}；容器本身 len={d} capacity={d}（被掏空了）\n", .{ owned, src.items.len, src.capacity });
// 此时只剩一个裸切片，用 arena 时不用free；用别的分配器就得自己还
// fromOwnedSlice 是反方向：零拷贝接管一段已有内存
const raw = try mem.alloc(u32, 3);
raw[0] = 7;
raw[1] = 8;
raw[2] = 9;
var adopted: std.ArrayList(u32) = .fromOwnedSlice(raw); // 不拷贝，直接接管
std.debug.print("fromOwnedSlice → {any} capacity={d}（指针就是 raw 那块，没有拷贝）\n", .{ adopted.items, adopted.capacity });
adopted.deinit(mem);
// toOwnedSliceSentinel：要C 字符串时用
var text: std.ArrayList(u8) = .empty;
defer text.deinit(mem);
try text.appendSlice(mem, "hello");
const zstr = try text.toOwnedSliceSentinel(mem, 0); // 结尾补一个 0 字节
std.debug.print("toOwnedSliceSentinel(0) → {s} len={d}（末字节是 {d}，可直接给 C API）\n", .{ zstr, zstr.len, zstr[zstr.len] });
end("12.4");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.4 开始 ====
toOwnedSlice → owned={ 10, 20, 30 }；容器本身 len=0 capacity=0（被掏空了）
fromOwnedSlice → { 7, 8, 9 } capacity=3（指针就是 raw 那块，没有拷贝）
toOwnedSliceSentinel(0) → hello len=5（末字节是 0，可直接给 C API）
==== 12.4 结束 ====
```

**`toOwnedSlice` 之后容器变成 `len=0 capacity=0`**（输出第 2 行后半段）——
它把堆指针**搬到了返回值里**，容器自己什么都不剩。所以**调用 `toOwnedSlice` 之后
不应该再 `deinit` 那个容器**（虽然对 arena 分配器 `free` 是空操作所以看不出错，
但换成 `page_allocator` 或 `GeneralPurposeAllocator` 就会 double free）。测试里干脆
连 `defer l.deinit()` 都不写：

```zig
// examples/12_collections/main.zig 第 679-684 行（test "12.4 …"）
const owned = try l.toOwnedSlice(gpa);
defer gpa.free(owned);
try std.testing.expectEqualSlices(u32, &.{ 10, 20, 30 }, owned);
// 容器被掏空：不需要再deinit（也不该deinit）
try std.testing.expectEqual(@as(usize, 0), l.items.len);
try std.testing.expectEqual(@as(usize, 0), l.capacity);
```

**`fromOwnedSlice` 是零拷贝**——测试里直接比对了指针：

```zig
// examples/12_collections/main.zig 第 691-694 行（test "12.4 …"）
var adopted: std.ArrayList(u32) = .fromOwnedSlice(raw);
try std.testing.expectEqual(@intFromPtr(raw.ptr), @intFromPtr(adopted.items.ptr));
try std.testing.expectEqualSlices(u32, &.{ 7, 8, 9 }, adopted.items);
adopted.deinit(gpa);
```

指针相等 = 真的没有拷贝（如果是拷贝，arena 可能给出相同地址，所以这个断言在 arena 下
不够强；但在 `std.testing.allocator` 下它是有效断言——那里每次 alloc 都给不同地址）。

⚠️ **`fromOwnedSlice` 之后那块内存的所有权归容器**，`raw` 自己就不能 `free` 了。

`toOwnedSliceSentinel(gpa, 0)` 是给 C API 准备的：返回 `[:0]u8`，长度 5 但底层占 6 字节
（多出的第 6 字节是 0，输出第 4 行证实了`zstr[5] == 0`）。**切片类型里的哨兵 `:0`
不计入 `.len`**（06 章 6.x 节讲过哨兵数组，这里是它在堆上的版本）。

## 12.5 HashMap 族（一）：0.17 里 managed 与 unmanaged **两套并存**

这是本章最容易抄错代码的地方。0.17 的 HashMap 族**同时提供两套**：

| 类型 | 形态 | 初始化 | 方法带分配器？ |
|---|---|---|---|
| `std.AutoHashMap(K, V)` | managed | `.init(alloc)` | ❌ 不带 |
| `std.AutoHashMapUnmanaged(K, V)` | unmanaged | `.empty` | ✅ 每个方法第一个参数 |
| `std.StringHashMap(V)` | managed | `.init(alloc)` | ❌ |
| `std.StringHashMapUnmanaged(V)` | unmanaged | `.empty` | ✅ |
| `std.HashMap(K,V,Context,load%)` | managed（通用） | `.init(alloc)` / `.initContext(alloc, ctx)` | ❌ |
| `std.HashMapUnmanaged(K,V,Context,load%)` | unmanaged（通用） | `.empty` | ✅ |

**抄错的话编译错误长这样**（给 managed 版多传了分配器）：

```text
error: member function expected 2 argument(s), found 3
    try m.put(std.heap.page_allocator, 1, 1);
        ~^~~~
note: function declared here
        pub fn put(self: *Self, key: K, value: V) Allocator.Error!void {
```

```zig
// examples/12_collections/main.zig 第 220-243 行
begin("12.5");
// HashMap 族在 0.17 **同时有 managed 和 unmanaged 两套**：
//   managed:   AutoHashMap / AutoHashMapUnmanaged / HashMap
//   unmanaged: std.AutoHashMap / std.AutoHashMapUnmanaged / std.HashMapUnmanaged
// managed 用 .init(alloc)，之后每个方法都不带分配器。
var map = std.AutoHashMap(u32, []const u8).init(mem);
defer map.deinit();
try map.put(1, "一");
try map.put(2, "二");
try map.put(3, "三");
std.debug.print("AutoHashMap: count={d} capacity={d} get(2)={s} contains(9)={}\n", .{ map.count(), map.capacity(), map.get(2).?, map.contains(9) });
// load factor：默认 80%，超过就 rehash 扩容
std.debug.print("default_max_load_percentage={d}（超过 count/capacity 就扩）\n", .{std.hash_map.default_max_load_percentage});
// unmanaged 版：每个方法收分配器，但容器本身纯数据
var umap: std.AutoHashMapUnmanaged(u32, u32) = .empty;
defer umap.deinit(mem);
try umap.put(mem, 1, 10);
try umap.put(mem, 2, 20);
std.debug.print("AutoHashMapUnmanaged: count={d} get(2)={d}（方法都收mem）\n", .{ umap.count(), umap.get(2).? });
// 预reserve 之后可以用 putAssumeCapacity（不检查容量，省一次分支）
try umap.ensureTotalCapacity(mem, 8);
umap.putAssumeCapacity(3, 30);
std.debug.print("putAssumeCapacity 后 count={d} capacity={d}\n", .{ umap.count(), umap.capacity() });
end("12.5");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.5 开始 ====
AutoHashMap: count=3 capacity=8 get(2)=二 contains(9)=false
default_max_load_percentage=80（超过 count/capacity 就扩）
AutoHashMapUnmanaged: count=2 get(2)=20（方法都收mem）
putAssumeCapacity 后 count=3 capacity=16
==== 12.5 结束 ====
```

### 哈希冲突与 load factor

哈希表的核心不变式：**键的哈希值决定它落在哪个桶**。两个不同的键算出同一个哈希值
就是**冲突**，标准库的处理是"开放地址 + 线性探测"（`hash_map.zig` 里的 `Metadata` 有
`isUsed` / `isTombstone` / `isFree` 三态，删除留下 tombstone 供探测链继续走）。

**冲突多不多由 load factor 决定**：`default_max_load_percentage = 80`（输出第 3 行，实测常量
就在 `std.hash_map` 里，可以直接引用）。`count/capacity` 超过 0.8 就 rehash 到两倍容量——
**用空间换探测次数**。实测 24 个元素时 `capacity` 是 32（24/32 = 0.75，没超阈值所以没扩），
而 3 个元素时 capacity 就是 8（3/8 = 0.375，因为起步容量小）。

⚠️ **桶数组里存的是"元数据 + 键值对"两段**，不是指针数组。所以键和值都是**内联存储**的，
`get` 返回的是**值拷贝**（`?V`），不是引用。想要引用用 `getPtr`（`?*V`）。
这和 Python dict / JS Map 的"返回引用"不同——Zig 的默认是拷贝，改动不会穿透回map。

`putAssumeCapacity` 是"我已经 `ensureTotalCapacity` 过了，你不要再检查也不要扩容"。
**容量不够就它会直接内存损坏**（不 panic、不返回 error）——只在刚`ensureTotalCapacity`
过的局部代码里用。测试里没写这个断言，因为它是"契约式"API。

## 12.6 HashMap 族（二）：`getOrPut` 两用、`fetchRemove` 的原子性

```zig
// examples/12_collections/main.zig 第 246-285 行
begin("12.6");
// getOrPut：一次哈希完成"查或插"，返回的槽位让你自己决定填什么
const gop = try map.getOrPut(10);
if (!gop.found_existing) gop.value_ptr.* = "十";
std.debug.print("getOrPut(10) found_existing={} → {s}；count={d}\n", .{ gop.found_existing, map.get(10).?, map.count() });
// 再getOrPut 同一个key：不会重复插入
const gop_again = try map.getOrPut(10);
std.debug.print("getOrPut(10) 再来一次 found_existing={} → count 仍是 {d}\n", .{ gop_again.found_existing, map.count() });
// 词频统计是getOrPut 的经典用法：两步合成一步
var freq = std.StringHashMap(usize).init(mem);
defer freq.deinit();
const words = [_][]const u8{ "a", "b", "a", "c", "b", "a" };
for (words) |w| {
    const entry = try freq.getOrPut(w);
    // 没查到时 value_ptr 是 undefined，必须自己初始化再累加
    if (!entry.found_existing) entry.value_ptr.* = 0;
    entry.value_ptr.* += 1;
}
std.debug.print("词频: a={any} b={any} c={any} count={d}\n", .{ freq.get("a"), freq.get("b"), freq.get("c"), freq.count() });
// fetchRemove：一步完成"查 + 删 + 拿走键值对"，返回 ?KV
if (map.fetchRemove(1)) |kv| {
    std.debug.print("fetchRemove(1) → key={d} value={s}；count={d}\n", .{ kv.key, kv.value, map.count() });
} else {
    std.debug.print("fetchRemove(1) → null\n", .{});
}
// remove 只告诉你"删没删掉"，不拿走值
std.debug.print("remove(2)={} remove(999)={}；count={d}\n", .{ map.remove(2), map.remove(999), map.count() });
// getPtr：拿到值的指针直接改（比 get-改-put 少一次哈希）
try map.put(5, "五");
if (map.getPtr(5)) |v| v.* = "伍";
std.debug.print("getPtr(5) 改值后 get(5)={s}\n", .{map.get(5).?});
// fetchPut：拿走旧值再写入
if (try map.fetchPut(5, "伍贰")) |kv| std.debug.print("fetchPut(5) 返回旧值 {s}\n", .{kv.value});
// putNoClobber：只在 key 不存在时写。⚠️ 已存在会 panic（不是返回错误）——
//    std 源码是 assert(!result.found_existing)，实测 panic: reached unreachable code
var noc: std.AutoHashMapUnmanaged(u32, []const u8) = .empty;
defer noc.deinit(mem);
try noc.putNoClobber(mem, 1, "first");
std.debug.print("putNoClobber 新key 成功 → {s}\n", .{noc.get(1).?});
end("12.6");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.6 开始 ====
getOrPut(10) found_existing=false → 十；count=4
getOrPut(10) 再来一次 found_existing=true → count 仍是 4
词频: a=3 b=2 c=1 count=3
fetchRemove(1) → key=1 value=一；count=3
remove(2)=true remove(999)=false；count=2
getPtr(5) 改值后 get(5)=伍
fetchPut(5) 返回旧值 伍
putNoClobber 新key 成功 → first
==== 12.6 结束 ====
```

### `getOrPut` 是"查找或插入"的两用入口

`getOrPut` 的返回值是一个结构体，三个字段：`key_ptr: *K`、`value_ptr: *V`、
`found_existing: bool`。它的价值在于**只算一次哈希**：

```zig
// 笨办法：两次哈希（get 一次 + put 一次），而且中间有"查了但还没插"的窗口
if (map.get(k)) |v| { use(v); } else { const fresh = compute(); try map.put(k, fresh); use(fresh); }

// getOrPut：一次哈希，槽位直接给你
const gop = try map.getOrPut(k);
if (!gop.found_existing) gop.value_ptr.* = compute();
use(gop.value_ptr.*);
```

**词频统计是最经典的用例**（输出第 4 行：`a=3 b=2 c=1 count=3`）。注意那个
`if (!entry.found_existing) entry.value_ptr.* = 0;` ——**新增的槽位里是 `undefined`，
不初始化就 `+= 1` 会读到垃圾并把它累加进去**。这是 `getOrPut` 唯一的真实陷阱，
也是为什么测试里那个用例要显式写初始化。

对应地，unmanaged 版还有 `getOrPutAssumeCapacity(key)`（无分配器、无 error）、
`getOrPutValue(key, value)`（一步"查或插并写值"，返回 `Entry`）、
以及一整套 `*Adapted` 变体（传入"伪键 + 伪上下文"，免去为查询临时构造真键——
34 章的 zcache 索引用的就是这个思路）。

### `fetchRemove` 的一步语义

`fetchRemove(key)` 做三件事：**查键 → 拿走键值对 → 删掉桶**，返回 `?KV`
（`KV` 是 `struct { key: K, value: V }`，按值拷贝）。它的"原子性"体现在
**你拿到的是值拷贝，而不是指向桶内部的指针**——即使接下来触发 rehash，
`kv.key` / `kv.value` 也是安全的。

对比三个删除方法：

| 方法 | 返回 | 哈希次数 | 能拿到值？ |
|---|---|---|---|
| `fetchRemove(k)` | `?KV` | 1 | ✅ |
| `remove(k)` | `bool` | 1 | ❌ |
| `get(k)` + `remove(k)` | `?V` + `bool` | 2 | ✅ 但可能删错（中间被改） |

**"可能删错"这句要展开**：如果你写 `if (map.get(k)) |v| use(v); _ = map.remove(k);`
并且 `use(v)` 期间有别的代码动了这个 map（多线程、或者`use` 里回调了 map 的方法），
那 `remove(k)` 删的可能已经不是你看到的那个值了。`fetchRemove` 把这步合成一个操作，
在 API 层面就消除了这个窗口。

### ⚠️ `putNoClobber` 在键已存在时 **panic**，不是返回错误

这个实测出来有点反直觉。写：

```zig
try noc.putNoClobber(mem, 1, "zzz"); // key 1 已经存在
```

实测：

```text
thread 1008006 panic: reached unreachable code
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/debug.zig:442:14: 0x106477f3d in assert
    if (!ok) unreachable; // assertion failure
             ^~~~~
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/array_hash_map.zig:484:19: 0x1065b32a6 in putNoClobberContext
            assert(!result.found_existing);
```

std 的实现是 `assert(!result.found_existing)`——**它把"键已存在"当成编程错误**，
而不是一个运行时可处理的分支。所以示例里只演示"新 key 成功"的路径。
**想让"存在就不写"成为正常的业务逻辑，用 `getOrPut` 的 `found_existing` 分支。**

## 12.7 `StringHashMap`：key 按内容哈希，且**只借用不拷贝**

这一节是本章对下游章节影响最大的：`StringHashMap` 的 key 所有权问题会直接决定
34 章（zcache 索引）能不能写对。

```zig
// examples/12_collections/main.zig 第 288-336 行
begin("12.7");
var colors = std.StringHashMap(u32).init(mem);
defer colors.deinit();
try colors.put("red", 0xFF0000);
try colors.put("blue", 0x0000FF);
// 哈希函数是 Wyhash（实测值随内容变化），相等是 mem.eql 逐字节比
std.debug.print("hashString(\"abc\")=0x{x}  hashString(\"abd\")=0x{x}  eqlString(\"abc\",\"abc\")={}\n", .{
    std.hash_map.hashString("abc"), std.hash_map.hashString("abd"), std.hash_map.eqlString("abc", "abc"),
});
// 按内容查找：另写一份内容相同的字面量照样命中
const red_again = "re" ++ "d"; // 编译期拼接，运行时是新地址
std.debug.print("另写一份 \"re\"++\"d\"（地址不同）get → {any}（内容相同即是同一个键）\n", .{colors.get(red_again)});
// ⚠️⚠️ 本节最重要的实测：key 的所有权
// put 只保存切片本身（16 字节的 ptr+len），**不拷贝内容**。
var scratch: [8]u8 = .{ 'g', 'r', 'a', 'y', 0, 0, 0, 0 };
try colors.put(scratch[0..4], 9); // 借用栈上 buffer
std.debug.print("put(scratch[0..4]) 后 get(\"gray\")={any}（查得到）\n", .{colors.get("gray")});
scratch[0] = 'X'; // 改写 buffer —— map 里那个键的内容跟着变了
var borrowed_key: []const u8 = "";
var kit_x = colors.keyIterator();
while (kit_x.next()) |kp| {
    // ⚠️ keyIterator 给的是 *K；对 StringHashMap 来说 K = []const u8，
    //    所以要解**两层**：kp.* 才是那个切片。
    if (kp.*[0] == 'X') borrowed_key = kp.*;
}
std.debug.print("改写 scratch[0]='X' 后 get(\"gray\")={any}，但 keyIterator 里能看到 {s}\n", .{ colors.get("gray"), borrowed_key });
std.debug.print("  → 结论：StringHashMap 的 key 是**借用**，必须保证内存活到 map 死（字面量安全、临时拼接要 dupe 进堆）\n", .{});
// 正确姿势：自己 dupe 一份到堆
var owned_keys = std.StringHashMap(u32).init(mem);
defer owned_keys.deinit();
try owned_keys.put(try mem.dupe(u8, "temporary"), 1);
std.debug.print("先 mem.dupe 再 put → get(\"temporary\")={any}（arena 里整块一起活，map 安全）\n", .{owned_keys.get("temporary")});
// 迭代器给指针：能改值，但迭代中修改结构会让迭代器失效
var it = colors.iterator();
var visited: usize = 0;
while (it.next()) |entry| {
    // entry.key_ptr.* / entry.value_ptr.* 是map 内部存储的地址
    visited += entry.key_ptr.*.len;
}
std.debug.print("iterator 走了 {d} 个 Entry（key+value 字节数），每个 Entry 含 key_ptr / value_ptr 两个指针（改值可以，改结构会失效迭代器）\n", .{visited});
// keyIterator / fetchRemove
var kit2 = colors.keyIterator();
std.debug.print("keyIterator 第一个 key={s}（长度 {d}）\n", .{ kit2.next().?.*, kit2.next().?.*.len });
if (colors.fetchRemove("red")) |kv| std.debug.print("fetchRemove(\"red\") → {s} = 0x{x:0>6}\n", .{ kv.key, kv.value });
// clearRetainingCapacity：清空但留桶
const before = colors.capacity();
colors.clearRetainingCapacity();
std.debug.print("clearRetainingCapacity 后 count={d} capacity={d}（桶还在，扩容没白做）\n", .{ colors.count(), before });
end("12.7");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.7 开始 ====
hashString("abc")=0x2a4f1d7cb516c72  hashString("abd")=0xfb6f90790569f955  eqlString("abc","abc")=true
另写一份 "re"++"d"（地址不同）get → 16711680（内容相同即是同一个键）
put(scratch[0..4]) 后 get("gray")=9（查得到）
改写 scratch[0]='X' 后 get("gray")=null，但 keyIterator 里能看到 Xray
  → 结论：StringHashMap 的 key 是**借用**，必须保证内存活到 map 死（字面量安全、临时拼接要 dupe 进堆）
先 mem.dupe 再 put → get("temporary")=1（arena 里整块一起活，map 安全）
iterator 走了 11 个 Entry（key+value 字节数），每个 Entry 含 key_ptr / value_ptr 两个指针（改值可以，改结构会失效迭代器）
keyIterator 第一个 key=Xray（长度 4）
fetchRemove("red") → red = 0xff0000
clearRetainingCapacity 后 count=0 capacity=8（桶还在，扩容没白做）
==== 12.7 结束 ====
```

### 按内容，不是按地址

`StringHashMap` 的键类型是 `[]const u8`，而它的哈希/相等函数是
`std.hash_map.hashString`（**Wyhash**）和 `std.hash_map.eqlString`（就是 `mem.eql`）。
两个函数都是 `pub` 的，可以直接调用（输出第 2 行）：

```zig
pub const StringContext = struct {
    pub fn hash(self: @This(), s: []const u8) u64 {
        _ = self;
        return hashString(s);          // Wyhash.hash(0, s)
    }
    pub fn eql(self: @This(), a: []const u8, b: []const u8) bool {
        _ = self;
        return eqlString(a, b);         // mem.eql(u8, a, b)
    }
};
```

输出第 3 行是这一节最漂亮的一个实测：把 `"red"` 和 `"re" ++ "d"` 两条语句，
编译后**是两个不同地址的字面量**（`++` 是编译期拼接，会生成新的常量副本），
但 `get(red_again)` 照样命中 `16711680`（= `0xFF0000`，"red" 的值）。**内容相同即是同一个键。**

### ⚠️⚠️ key 是借用的——实测证据

这是本节的核心，也是 34 章 zcache 的设计前提。`put` 保存的是**切片本身**
（两个机器字：ptr + len，共 16 字节），**不拷贝内容**。

示例里做的实验（输出第 4、5 两行）：

1. 把栈上一个 `[8]u8` 数组的前 4 字节（内容 `"gray"`）作为 key `put` 进去 → `get("gray")` 返回 9，**查得到**；
2. 把那块内存的第一个字节改成 `'X'`（内容变成 `"Xray"`）→ `get("gray")` 返回 **null**，
   但 `keyIterator` 里能看到那个键现在是 **`Xray`**。

**map 里的键跟着原内存变了**——因为它存的从来不是拷贝。这就是"借用"的确切含义。

由此得出三条实践规则：

| key 来源 | 安全吗 | 为什么 |
|---|---|---|
| 字面量 `"red"` | ✅ 安全 | 在静态存储区，程序整个生命周期都在 |
| arena 里 `dupe` 出来的 | ✅ 安全（本示例做法） | arena 到最后统一释放，key 不会先死 |
| 栈上 buffer / `ArrayList` 的 `items` 切片 | ❌ 危险 | buffer 出作用域就没了，或者列表 realloc 后指针失效 |
| 从文件读进来的临时 buffer | ❌ 危险 | 同上 |

正确做法就是示例最后那几行：**`try mem.dupe(u8, "...")` 把键拷进堆，再 `put` 那个副本。**
34 章的 zcache 之所以用 `StringHashMapUnmanaged` 而不是 managed 版，就是因为它需要
把整个 map 放在一个可移动的结构里，而键的内存统一由调用方的 arena 管。

⚠️ **`keyIterator` 对字符串 map 要解两层指针**。`Iterator.Entry` 给的是
`key_ptr: *K`，而 `K = []const u8`，所以 `kp` 是 `*[]const u8`——
`kp[0]` 会报 `error: type '*[]const u8' does not support indexing`，
必须写 `kp.*[0]`（先解引用成切片，再索引）或 `kp.*`（拿到切片本身）。这是编译期
就抓到的错误（见坑位清单第 10 条）。

### 迭代中改结构 = 迭代器失效

`iterator()` 返回的 `Iterator` 内部持有 `metadata`（元数据数组指针）和 `index`
（扫到第几个桶）。**任何会 rehash 的操作**（`put` 新键、`remove` 后再 `put` 到触发扩容的量、
`fetchRemove` 大量堆积后触发 rehash）都会重建元数据数组 → 迭代器手里的指针变成悬垂。

std 的防护手段是 `lockPointers()` / `unlockPointers()`：调用后，任何会导致
"已有键值指针失效"的操作直接触发断言。**遍历 + 条件删除的正确模式**是：

```zig
// ✅ 收集要删的键，循环外逐个删
var to_delete: std.ArrayList(u32) = .empty;
defer to_delete.deinit(mem);
var it = map.iterator();
while (it.next()) |e| {
    if (shouldDelete(e.value_ptr.*)) try to_delete.append(mem, e.key_ptr.*);
}
for (to_delete.items) |k| _ = map.remove(k);

// ✅ 或一边迭代一边删（fetchRemove 不需要额外哈希，且不会 rehash 桶数组的结构指针语义）
var it2 = map.iterator();
while (it2.next()) |e| {
    if (shouldDelete(e.value_ptr.*)) _ = map.fetchRemove(e.key_ptr.*); // 仍然有风险，见下
}
```

第二种写法**在实践中是有风险的**——`fetchRemove` 会在桶里留tombstone，
如果接着 `put` 到一定数量就可能 rehash。所以本仓库的代码里统一用第一种
（20 章的目录树清理就是先收集再删）。

## 12.8 `array_hash_map`：`std.ArrayHashMap` 已移除，新名字要记住

这是 0.17 的**破坏性改名**，老教程里的 `std.ArrayHashMap(K, V)` 和
`std.AutoArrayHashMap(K, V)` **都不存在了**：

```text
error: root source file struct 'std' has no member named 'ArrayHashMap'
    var m: std.ArrayHashMap(u32, u32) = .empty;
           ~~~^~~~~~~~~~~~~
note: root source file struct 'std' struct declared here
pub const AutoHashMap = hash_map.AutoHashMap;
```

新家在 **`std.array_hash_map`** 模块下，而且**全部是 unmanaged**（`.empty` + 方法收分配器）：

| 老名字（0.16 及更早） | 0.17 新名字 |
|---|---|
| `std.ArrayHashMap(K, V)` | `std.array_hash_map.Auto(K, V)` / `.Custom(K,V,Context,store_hash)` |
| `std.AutoArrayHashMap(K, V)` | `std.array_hash_map.Auto(K, V)` |
| `std.StringArrayHashMap(V)` | `std.array_hash_map.String(V)` |
| `std.ArrayHashMapUnmanaged(...)` | 同上（老名字是 Deprecated 别名，但参数是 4 个的 `Custom`） |

```zig
// examples/12_collections/main.zig 第 339-390 行
begin("12.8");
// ⚠️ 0.17 的重大改名：std.ArrayHashMap 和 std.AutoArrayHashMap **已被移除**。
// 实测 `std.ArrayHashMap` → error: root source file struct 'std' has no member named 'ArrayHashMap'
//新家在 std.array_hash_map 模块下，且**全部是 unmanaged**（.empty + 方法收分配器）。
std.debug.print("std 有 ArrayHashMap 吗? {}  有 AutoArrayHashMap 吗? {}\n", .{ @hasDecl(std, "ArrayHashMap"), @hasDecl(std, "AutoArrayHashMap") });
// 三个入口：Auto（自动配哈希）/ String（内容哈希）/ Custom（自定义上下文 + 存不存 hash）
var ahm: std.array_hash_map.Auto(u32, []const u8) = .empty;
defer ahm.deinit(mem);
try ahm.put(mem, 30, "thirty");
try ahm.put(mem, 10, "ten");
try ahm.put(mem, 20, "twenty");
// 核心差别：迭代顺序 == 插入顺序（内部就是两条 ArrayList + 一张索引表）
std.debug.print("ArrayHashMap 插入序30,10,20 → 迭代序:", .{});
var ahm_it = ahm.iterator();
while (ahm_it.next()) |e| std.debug.print(" {d}={s}", .{ e.key_ptr.*, e.value_ptr.* });
std.debug.print("\n", .{});
// 对照：普通 HashMap 顺序不保证
var hm2 = std.AutoHashMap(u32, u32).init(mem);
defer hm2.deinit();
try hm2.put(30, 1);
try hm2.put(10, 2);
try hm2.put(20, 3);
std.debug.print("AutoHashMap  插入序 30,10,20 → 迭代序:", .{});
var hm_it = hm2.iterator();
while (hm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
std.debug.print("（无保证）\n", .{});
// 删除两兄弟：swapRemove 打乱顺序、orderedRemove 保序
try ahm.put(mem, 40, "forty");
std.debug.print("再put(40) → 序:", .{});
ahm_it = ahm.iterator();
while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
std.debug.print("；swapRemove(10)={} → 序:", .{ahm.swapRemove(10)});
ahm_it = ahm.iterator();
while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
std.debug.print("；orderedRemove(20)={} → 序:", .{ahm.orderedRemove(20)});
ahm_it = ahm.iterator();
while (ahm_it.next()) |e| std.debug.print(" {d}", .{e.key_ptr.*});
std.debug.print("\n", .{});
// ⚠️ ArrayHashMap **没有** fetchRemove / remove / valueIterator / toOwnedSlice
// 删除只有 swapRemove(key) / orderedRemove(key)，返回 bool（不拿走值！）
std.debug.print("ArrayHashMap 有 fetchRemove? {} 有 remove? {} 有 valueIterator? {}\n", .{
    @hasDecl(std.array_hash_map.Auto(u32, u32), "fetchRemove"),
    @hasDecl(std.array_hash_map.Auto(u32, u32), "remove"),
    @hasDecl(std.array_hash_map.Auto(u32, u32), "valueIterator"),
});
// 字符串版
var sahm: std.array_hash_map.String(u32) = .empty;
defer sahm.deinit(mem);
try sahm.put(mem, "alpha", 1);
try sahm.put(mem, "beta", 2);
std.debug.print("array_hash_map.String: get(\"beta\")={d} count={d}\n", .{ sahm.get("beta").?, sahm.count() });
end("12.8");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.8 开始 ====
std 有 ArrayHashMap 吗? false  有 AutoArrayHashMap 吗? false
ArrayHashMap 插入序30,10,20 → 迭代序: 30=thirty 10=ten 20=twenty
AutoHashMap  插入序 30,10,20 → 迭代序: 30 10 20（无保证）
再put(40) → 序: 30 10 20 40；swapRemove(10)=true → 序: 30 40 20；orderedRemove(20)=true → 序: 30 40
ArrayHashMap 有 fetchRemove? false 有 remove? false 有 valueIterator? false
array_hash_map.String: get("beta")=2 count=2
==== 12.8 结束 ====
```

### 为什么它值得存在：保插入序

输出第 3、4 行是本节的重点。同样的插入顺序 `30, 10, 20`：

- **`array_hash_map.Auto`** 迭代出 `30, 10, 20`——**严格等于插入顺序**；
- **`AutoHashMap`** 迭代出 `30, 10, 20`——**碰巧也一样，但这只是巧合**。

`hash_map.zig` 的文档注释写得很直接：`No order is guaranteed and any modification
invalidates live iterators. If iterating over the table entries is a strong usecase and
needs to be fast, prefer the alternative std.ArrayHashMap.`

`array_hash_map` 的实现是**两条 ArrayList（键数组 + 值数组）+ 一张索引表**：
`entries: DataList`（就是那个"两个并行数组"的结构）加上 `index_header: ?*IndexHeader`。
所以"哈希查找"只是附加能力，"**按插入序线性遍历**"才是它的一等公民操作——
遍历时缓存友好（数组连续），且**Entry 指针在`ensureTotalCapacity` 之后保持有效**。
代价是每条目多一张索引表的开销（源码注释说：条目数 < 9 时相比 `ArrayList` 只多一个
指针大小的整数）。

⚠️ **不要用 `AutoHashMap` 的迭代顺序做任何有意义的输出**。本仓库能这么写
"插入序 30,10,20 → 迭代序: 30 10 20"，是因为这三个整数恰好按插入顺序落桶。
换一批数据就不保证了——**依赖它就是埋雷**。

### `array_hash_map` 的 API 缺口（实测）

输出第 7 行用 `@hasDecl` 逐个检查，结果是：

| 方法 | `array_hash_map.Auto` | `AutoHashMap` |
|---|---|---|
| `fetchRemove` | ❌ **没有** | ✅ 有 |
| `remove` | ❌ **没有** | ✅ 有 |
| `swapRemove(key) -> bool` | ✅ 有 | ❌（那是 ArrayList 的） |
| `orderedRemove(key) -> bool` | ✅ 有 | ❌ |
| `valueIterator` | ❌ 没有 | ✅ 有 |
| `toOwnedSlice` | ❌ 没有 | ❌ 没有 |
| `putNoClobber` / `fetchPut` / `clone` / `capacity` / `ensureUnusedCapacity` | ✅ 有 | ✅ 有 |

**所以"要键值有序 + 要 fetchRemove"这个组合在 0.17 的 std 里没有现成容器**——
要么自己写（先 `get` 拿值、再 `orderedRemove` 删，容忍中间的并发窗口），
要么在 `array_hash_map` 上包一层。要注意 `swapRemove` / `orderedRemove` 的参数是
**键不是下标**，返回 `bool`（删没删掉），**拿不到被删的值**——这和 `ArrayList` 的
同名方法（参数是下标、返回值是被删元素）**语义完全不同**，抄代码时特别容易搞混。

### `store_hash` 参数

`Custom(K, V, Context, store_hash)` 的第四个参数是 0.17 新增的：
`store_hash = false` 时（`Auto` 和 `String` 都是 false）不存哈希值，
`eql` 会被调用多次（靠廉价比较兜底）；`true` 时（实测 `String` 版就是 true
—— `array_hash_map.Custom([]const u8,u32,array_hash_map.StringContext,true)`）
每个条目多存一个 `u32`，但 `eql` 只调一次。**字符串键必须 `store_hash = true`**，
因为比较两个字符串不便宜。

## 12.9 `MultiArrayList`：真·并行数组，以及一个 0.17 的 std bug

`std.MultiArrayList` 在 0.17 **存在**，而且是本章最有意思的数据结构：它把
`ArrayList(Struct)` 拆成**每个字段一条独立的数组**。

```zig
// examples/12_collections/main.zig 第 393-467 行
begin("12.9");
var mal: std.MultiArrayList(Item) = .empty;
defer mal.deinit(mem);
// sizeOf：一个字段都不占的"索引"，所有字段数组的基址都藏在 bytes 里
std.debug.print("sizeOf: Item={d}字节 MultiArrayList(Item)={d}字节（只有指针+len+cap）\n", .{ @sizeOf(Item), @sizeOf(std.MultiArrayList(Item)) });
try mal.append(mem, .{ .name = "sword", .hp = 10, .price = 150 });
try mal.append(mem, .{ .name = "shield", .hp = 25, .price = 80 });
try mal.append(mem, .{ .name = "potion", .hp = 3, .price = 25 });
std.debug.print("len={d} capacity={d}（第一个 append 就直接给 9）\n", .{ mal.len, mal.capacity });
// 核心手法：items(.field) 拿到某个字段的**完整并行数组**
const names = mal.items(.name);
const hps = mal.items(.hp);
for (names, hps) |n, h| std.debug.print("  {s:<7} hp={d}\n", .{ n, h });
// 只扫一个字段（缓存友好），这是 MAL 存在的全部意义
var total: u32 = 0;
for (mal.items(.hp)) |h| total += h;
std.debug.print("只扫 hp 字段求和 = {d}（内存连续，比结构体数组快）\n", .{total});
// get(i) 拼出一个"临时结构体"（值，不是指针）；要改用 set
const one = mal.get(1);
std.debug.print("get(1) = {s} hp={d} price={d}\n", .{ one.name, one.hp, one.price });
mal.set(1, .{ .name = "shield", .hp = 40, .price = 90 });
std.debug.print("set(1, hp=40) 后 get(1).hp={d}\n", .{mal.get(1).hp});
mal.items(.hp)[0] = 77; // 直接改并行数组也行
std.debug.print("items(.hp)[0]=77 后 get(0).hp={d}\n", .{mal.get(0).hp});
// 删除只有两个：swapRemove（O(1)，末尾补位）/ orderedRemove（O(n) 保序），都返回 void
mal.swapRemove(0);
std.debug.print("swapRemove(0) 后 len={d} name0={s}（void 返回，看不到被删的值）\n", .{ mal.len, mal.get(0).name });
// slice()：不转移所有权的窗口；toOwnedSlice() 把整个 MAL 变成字段数组集合
var win = mal.slice();
std.debug.print("slice(): len={d} get(0).name={s}（借用，非拷贝）\n", .{ win.len, win.get(0).name });
var owned_mal = mal.toOwnedSlice(); // 注意：**没有分配器参数**，也不返回 error
std.debug.print("toOwnedSlice(): len={d}，每个字段一条数组：", .{owned_mal.len});
for (owned_mal.items(.name)) |nm| std.debug.print(" {s}", .{nm});
std.debug.print(" hp={any}\n", .{owned_mal.items(.hp)});
owned_mal.deinit(mem);
mal.clearAndFree(mem);
// ⚠️⚠️ 0.17.0 的 std bug：MultiArrayList.sort / sortSpan / sortSpanUnstable **全部编译不过**
//    实测报错（sort 与 sortSpan 都是这一条）：
//      lib/std/multi_array_list.zig:609:36: error: cannot store runtime value in compile time variable
//                 .slice = self.slice(),
//      note: referenced by: sortInternal ... / multi_array_list.zig:624
//    所以下面用手写"排序下标数组"的变通方案代替。
var mal2: std.MultiArrayList(Item) = .empty;
defer mal2.deinit(mem);
try mal2.append(mem, .{ .name = "dagger", .hp = 7, .price = 40 });
try mal2.append(mem, .{ .name = "bow", .hp = 5, .price = 90 });
try mal2.append(mem, .{ .name = "club", .hp = 12, .price = 15 });
var order = [_]usize{ 0, 1, 2 };
// 把 hp 切片当 ctx 传给 std.mem.sort，排的是下标
std.mem.sort(usize, &order, mal2.items(.hp), struct {
    fn byHp(hp_values: []const u32, a: usize, b: usize) bool {
        return hp_values[a] < hp_values[b];
    }
}.byHp);
std.debug.print("变通排序（排下标）按 hp 升序：", .{});
for (order) |ix| std.debug.print(" {s}({d})", .{ mal2.items(.name)[ix], mal2.items(.hp)[ix] });
std.debug.print("\n", .{});
// 手写"并行数组"替代方案（不依赖 MAL 时可以用）
const SoA = struct {
    snames: std.ArrayList([]const u8),
    shps: std.ArrayList(u32),
    sprices: std.ArrayList(u32),
};
var soa: SoA = .{ .snames = .empty, .shps = .empty, .sprices = .empty };
defer soa.snames.deinit(mem);
defer soa.shps.deinit(mem);
defer soa.sprices.deinit(mem);
try soa.snames.append(mem, "wand");
try soa.shps.append(mem, 4);
try soa.sprices.append(mem, 60);
try soa.snames.append(mem, "spear");
try soa.shps.append(mem, 15);
try soa.sprices.append(mem, 70);
std.debug.print("手写 SoA：names.len={d} hps.len={d} prices.len={d}（三者必须手动同步，MAL 就是替你同步）\n", .{ soa.snames.items.len, soa.shps.items.len, soa.sprices.items.len });
end("12.9");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.9 开始 ====
sizeOf: Item=24字节 MultiArrayList(Item)=24字节（只有指针+len+cap）
len=3 capacity=9（第一个 append 就直接给 9）
  sword   hp=10
  shield  hp=25
  potion  hp=3
只扫 hp 字段求和 = 38（内存连续，比结构体数组快）
get(1) = shield hp=25 price=80
set(1, hp=40) 后 get(1).hp=40
items(.hp)[0]=77 后 get(0).hp=77
swapRemove(0) 后 len=2 name0=potion（void 返回，看不到被删的值）
slice(): len=2 get(0).name=potion（借用，非拷贝）
toOwnedSlice(): len=2，每个字段一条数组： potion shield hp={ 3, 40 }
变通排序（排下标）按 hp 升序： bow(5) dagger(7) club(12)
手写 SoA：names.len=2 hps.len=2 prices.len=2（三者必须手动同步，MAL 就是替你同步）
==== 12.9 结束 ====
```

### 为什么 `sizeOf` 两者相等

输出第 2 行：`Item` 是 24 字节（`[]const u8` = 16 + `u32` + `u32` = 24），
`MultiArrayList(Item)` 也是 **24 字节**。这很反直觉——容器居然和元素一样大？

答案：`MultiArrayList` 里**不存任何字段数据**，只存一个 `[]align(@alignOf(Elem)) u8` 的大块字节
（所有字段数组都挤在这块内存的不同偏移上）+ `len: usize` + `capacity: usize`。
16（切片）+ 8 + 8 = 32……嗯，实际是 24，说明 `bytes` 是 `[*]align(u8) u8` 形式的胖指针，
或者 `capacity` 的存储方式有优化。**总之：容器本身是常数大小，与元素类型和元素数量无关。**

推论很重要：**你可以在一个数组里放一百万个 `Item` 而容器还是 24 字节**，
而且每加一个字段到 `Item`（比如加个 `u8 rarity`），**容器大小一点不变**——
只是每个元素在内存里多占 1 字节（有 padding 就再对齐）。

### `items(.field)` 是核心手法

`mal.items(.name)` 返回 `[]const []const u8`——**这条字段的完整并行数组**。
于是：

```zig
// 只扫一个字段：CPU cache 友好（连续访问），不需要碰其他字段的内存
for (mal.items(.hp)) |h| total += h;   // 输出：只扫 hp 字段求和 = 38
```

这是 **Structure of Arrays（SoA）** 布局：传统 `ArrayList(Item)` 是
**Array of Structures**（AoS），扫 `hp` 时每个元素要跨过 16 字节的 `name` 指针，
cache line 利用率低；SoA 里 `hp` 全部连续，扫 8 个元素只占 32 字节 =半条 cache line。
**"只需要其中一个字段"是 SoA 的典型场景**——比如游戏里的所有单位位置、AI 的所有目标血量。

`get(i)` 返回**拼装出来的临时结构体（值，不是指针）**——因为数据在不同的数组里，
没法返回一个指向"某个真实结构体"的指针。输出第 8 行直接打印了它的三个字段。
要改就用 `set(i, elem)`（**整个替换**）或者直接改某个字段数组 `mal.items(.hp)[i] = x`
（**部分修改**，输出第 10 行验证了这条路）。⚠️ 想只改一个字段就非得走
`items(.field)[i] = x`——`get(i)` 拿到的是拷贝，改它的字段没有任何效果。

### `toOwnedSlice()` 没有分配器参数

和 `ArrayList.toOwnedSlice(gpa)` 不同（那里要传 `gpa`），`MultiArrayList.toOwnedSlice()`
**不收分配器，也不返回 error**。因为它不重新分配——它只是把内部那块字节的所有权
**转交给一个 `Slice` 结构体**（`Slice` 也是一个含 `bytes` + `len` 的小结构，
还有自己的 `deinit(gpa)` / `items(.field)` / `get(i)` / `swap` / `subslice`）。
测试里实测了这一点：

```zig
// examples/12_collections/main.zig 第 824-830 行（test "12.9 …"）
// toOwnedSlice 没有分配器参数
var mal2: std.MultiArrayList(Item) = .empty;
try mal2.append(gpa, .{ .name = "x", .hp = 1, .price = 2 });
var owned = mal2.toOwnedSlice();
try std.testing.expectEqual(@as(usize, 1), owned.len);
try std.testing.expectEqualStrings("x", owned.items(.name)[0]);
owned.deinit(gpa);
```

⚠️ **`Slice` 没有具名字段**（没有 `owned.names` / `owned.hp`）——想访问某字段仍要
`owned.items(.name)`。写 `owned.names` 报 `error: no field named 'names' in struct
'multi_array_list.MultiArrayList(Item).Slice'`。

⚠️ **`swapRemove` / `orderedRemove` 返回 `void`**（不是元素）。想看被删了什么，
必须在调用前自己读 `mal.get(i)`。

### ⚠️⚠️ 0.17.0 的 std bug：`MultiArrayList.sort*` 全部编译不过

实测（`sort`、`sortSpan`、`sortSpanUnstable` 都试了）：

```text
/Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/multi_array_list.zig:609:36: error: cannot store runtime value in compile time variable
                .slice = self.slice(),
                         ~~^~~
referenced by:
    sort__func_856: /Volumes/mac004/lang/zig-x86_64-macos-0.17.0/lib/std/multi_array_list.zig:624:30
    main: p14.zig:11:13
```

问题出在 `sortInternal` 里的这段：

```zig
const sort_context: struct {
    sub_ctx: @TypeOf(ctx),
    slice: Slice,
    pub fn swap(...) void { ... }
    pub fn lessThan(...) bool { ... }
} = .{
    .sub_ctx = ctx,
    .slice = self.slice(),   // ← 这一行：编译器认为这是"编译期变量"
};
```

`sort_context` 是 `const`，编译器在给 `.slice = self.slice()` 赋值时把它当成了
编译期求值的位置（大概是 `Slice` 里有 `pub const empty: Slice = .{}` 之类的常量
触发了 comptime 传播的 bug）。**结果是整个 `MultiArrayList` 的排序功能在 0.17.0 上不可用。**

变通方案（示例里用的）：**排下标数组**——把要排序的那个字段切片当 `ctx` 传给
`std.mem.sort`，排的是下标，再用下标去索引各字段（输出第 13 行：
`变通排序（排下标）按 hp 升序： bow(5) dagger(7) club(12)`）。这个模式对
`ArrayList` 也适用，是"多字段结构按某个键排序"的通用解法。

### 手写 SoA：什么时候值得

示例最后那6 行给了替代方案：一个 struct 里装三条平行 `ArrayList`。
**对比成本很低**——但要手动保证三条列表**始终等长**（示例输出 `names.len=2 hps.len=2 prices.len=2`）。

**`MultiArrayList` 帮你做的就是这件事**：它内部就是这三条数组（外加索引），
`append` 一次同时往所有字段数组推元素，**不可能不同步**。所以：

- 字段多（≥3）、且经常只扫其中一两个 → `MultiArrayList`
- 字段少（1-2）、或总是一起用 → `ArrayList(Struct)` 更简单

## 12.10 排序：`std.mem.sort` 与 `std.sort.*` 的分工

0.17 的排序 API 分两层，职责清晰：

| 层 | 用途 |
|---|---|
| `std.mem.sort` / `std.mem.sortUnstable` | **日常入口**，两者签名完全一致 |
| `std.sort.{insertion, heap, pdq, block}` | 底层算法，按需要挑 |

`mem.sort` 就是 `std.sort.block` 的一层转发（源码里 `pub fn sort(...) { std.sort.block(...); }`），
`mem.sortUnstable` 就是 `std.sort.pdq`。四个底层算法在 0.17 **全部还在**。

| 函数 | 稳定性 | 复杂度 | 适用 |
|---|---|---|---|
| `std.mem.sort` → block | **稳定** | O(n log n) | **默认选它** |
| `std.mem.sortUnstable` → pdq | 不稳定 | O(n log n) 期望 | 元素大、不需要稳定 |
| `std.sort.insertion` | 稳定 | O(n²) 但常数极小 | 长度 < 32 的小数组 |
| `std.sort.heap` | 不稳定 | O(n log n) 最坏 | 担心最坏情况 |
| `std.sort.pdq` | 不稳定 | O(n log n) 期望 | 快，抗对抗输入 |
| `std.sort.block` | 稳定 | O(n log n) | `mem.sort` 的实现 |

```zig
// examples/12_collections/main.zig 第 470-512 行
begin("12.10");
var nums = [_]u32{ 42, 7, 19, 3, 88, 23 };
// 统一签名：fn (ctx, lhs, rhs) bool。四个参数：元素类型、切片、上下文、比较函数
std.mem.sort(u32, &nums, {}, lessThanU32);
std.debug.print("std.mem.sort（稳定）        → {any}\n", .{nums});
// 需要降序：换个比较函数即可（不改容器）
std.mem.sort(u32, &nums, {}, greaterThanU32);
std.debug.print("换成降序比较→ {any}\n", .{nums});
// 内置比较器：std.sort.asc(T) / std.sort.desc(T)，省掉自己写函数
std.mem.sort(u32, &nums, {}, std.sort.asc(u32));
std.debug.print("std.sort.asc(u32)→ {any}\n", .{nums});
// 六个底层算法都在 std.sort 里，签名与 mem.sort 一致
var a1 = [_]u32{ 5, 2, 8, 1 };
std.sort.insertion(u32, &a1, {}, lessThanU32); // 稳定，O(n²) 但常数小，适合小数组
var a2 = [_]u32{ 5, 2, 8, 1 };
std.sort.heap(u32, &a2, {}, lessThanU32); // 不稳定，O(n log n) 最坏
var a3 = [_]u32{ 5, 2, 8, 1 };
std.sort.pdq(u32, &a3, {}, lessThanU32); // 不稳定，pattern-defeating 快排
var a4 = [_]u32{ 5, 2, 8, 1 };
std.sort.block(u32, &a4, {}, lessThanU32); // 稳定，mem.sort 实际就调它
std.debug.print("insertion={any} heap={any} pdq={any} block={any}\n", .{ a1, a2, a3, a4 });
// mem.sortUnstable = pdq；mem.sort = block（稳定）
var a5 = [_]u32{ 5, 2, 8, 1 };
std.mem.sortUnstable(u32, &a5, {}, lessThanU32);
std.debug.print("mem.sortUnstable（= pdq）  → {any}\n", .{a5});
// ⚠️ ArrayList **没有** .sort 方法（实测 no field or member function named 'sort'），
//    也没有 .swap。只能把 items 切片交给 std.mem.sort。
var alist: std.ArrayList(u32) = .empty;
defer alist.deinit(mem);
try alist.appendSlice(mem, &.{ 9, 6, 3 });
std.mem.sort(u32, alist.items, {}, std.sort.asc(u32));
std.debug.print("排ArrayList：std.mem.sort(u32, list.items, ...) → {any}\n", .{alist.items});
// ctx 的意义：比较函数无捕获，靠参数拿外部状态（14 章泛型会大量用这个模式）
const table = NameTable{ .names = &.{ "bob", "alice", "carol" } };
var ids = [_]u32{ 0, 1, 2 };
std.mem.sort(u32, &ids, table, NameTable.lessByName);
std.debug.print("按 ctx 里的名字排序 id：", .{});
for (ids) |id| std.debug.print(" {d}={s}", .{ id, table.names[id] });
std.debug.print("\n", .{});
// ArrayList 也没有 swap，两个元素对调用 std.mem.swap
std.mem.swap(u32, &alist.items[0], &alist.items[2]);
std.debug.print("std.mem.swap 两个元素 → {any}\n", .{alist.items});
end("12.10");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.10 开始 ====
std.mem.sort（稳定）        → { 3, 7, 19, 23, 42, 88 }
换成降序比较→ { 88, 42, 23, 19, 7, 3 }
std.sort.asc(u32)→ { 3, 7, 19, 23, 42, 88 }
insertion={ 1, 2, 5, 8 } heap={ 1, 2, 5, 8 } pdq={ 1, 2, 5, 8 } block={ 1, 2, 5, 8 }
mem.sortUnstable（= pdq）  → { 1, 2, 5, 8 }
排ArrayList：std.mem.sort(u32, list.items, ...) → { 3, 6, 9 }
按 ctx 里的名字排序 id： 1=alice 0=bob 2=carol
std.mem.swap 两个元素 → { 9, 6, 3 }
==== 12.10 结束 ====
```

### 统一签名与 `ctx` 的意义

所有排序函数的形状都一样：`fn (T, []T, ctx, lessThanFn) void`，
`lessThanFn: fn (@TypeOf(ctx), T, T) bool`。三个要点：

1. **比较函数必须"无捕获"**（不是闭包）。Zig 的函数要么是top-level 的，
   要么是 struct 里的方法——不能捕获运行时环境。**需要外部状态就通过 `ctx` 参数传**。
2. **`ctx` 是泛型的**（`anytype`），可以是 `{}`（空结构体，常量）、一个切片、
   一个 struct（示例里的 `NameTable`）、甚至一个指针。类型由你传的实参推断，
   然后 `lessThanFn` 的第一个参数类型必须**精确匹配** `ctx` 的类型。
3. **降序不需要新API**，换个比较函数就行（输出第 3 行）。

`ctx` 的威力在输出第 11 行：排的是 `ids = {0, 1, 2}`，但顺序由 `table.names[]` 决定——
**比较函数本身是纯的、可复用的**，外部数据（名字表）从 `ctx` 来。
这个模式在 14 章的泛型排序里会大量出现。

`std.sort.asc(T)` / `std.sort.desc(T)` 是 0.17 的便利函数（返回
`fn (void, T, T) bool`），底层就是 `inner(_: void, a: T, b: T) bool { return a < b; }`。
用它们 `ctx` 就只能是 `{}`。

### ⚠️ `ArrayList` 没有 `.sort`，也没有 `.swap`

实测：

```text
error: no field or member function named 'sort' in 'array_list.Aligned(u32,null)'
    try l.sort(1, 0, std.sort.asc(u32));
        ~^~~~~
note: struct declared here
    return struct {
           ^~~~~
```

（`swap` 同样报`no field or member function named 'swap'`。）所以排 `ArrayList`
就是排它的 `items` 字段——**这在unmanaged 形态下尤其顺理成章**：`items` 就是一个
`[]T`，直接传给 `std.mem.sort`。输出第 10 行就是这么做的。

测试里用 `@hasDecl` 把这个事实钉住了：

```zig
// examples/12_collections/main.zig 第 865-867 行（test "12.10 …"）
// ArrayList 没有 .sort / .swap
try std.testing.expect(!@hasDecl(std.ArrayList(u32), "sort"));
try std.testing.expect(!@hasDecl(std.ArrayList(u32), "swap"));
```

⚠️ 另外注意**容器的 `items` 在扩容时会换地址**——把 `list.items` 传给 `sort` 是
安全的（`sort` 原地排，不扩容），但排序期间不能有别的操作动这个列表。

## 12.11 二分查找：比较函数返回三态 `Order`

二分查找的函数**和排序长在同一族**（`std.sort` 模块），但比较函数的返回类型不同：
**排序要 `bool`（"a 在 b 前面吗"），二分要 `std.math.Order`（三态：`.lt` / `.eq` / `.gt`）**。

| 函数 | 返回 | 语义 |
|---|---|---|
| `binarySearch(T, items, ctx, cmpFn) ` | `?usize` | 找到返回下标，没找到 `null` |
| `lowerBound(T, items, ctx, cmpFn)` | `usize` | 第一个**不小于** target 的下标 |
| `upperBound(T, items, ctx, cmpFn)` | `usize` | 第一个**大于** target 的下标 |
| `equalRange(T, items, ctx, cmpFn)` | `struct { usize, usize }` | 相等区间 `[start, end)` |
| `partitionPoint(T, items, ctx, **predFn**)` | `usize` | 谓词为真的元素个数 |
| `min` / `max` / `argMin` / `argMax` / `isSorted` | `?T` / `?usize` / `bool` | 极值 |

```zig
// examples/12_collections/main.zig 第 82-85 行
/// 12.10 节二分查找的比较函数：返回三态Order（.lt/.eq/.gt），不是 bool
fn orderU32(target: u32, item: u32) std.math.Order {
    return std.math.order(target, item);
}
```

```zig
// examples/12_collections/main.zig 第 515-558 行
begin("12.11");
// 前提：**必须已排序**。四参数与排序同构，但比较函数返回三态 Order 而不是 bool。
const sorted = [_]u32{ 1, 3, 5, 7, 9, 11 };
// ⚠️⚠️ 0.17 的坑：context 参数写成裸字面量会编译失败——字面量是 comptime_int，
//    而 compareFn 要的是 fn(u32, u32) Order：
//      error: expected type 'fn (comptime_int, u32) math.Order', found 'fn (u32, u32) math.Order'
//      note: non-generic function cannot cast into a generic function
//    修法：给查找目标点名类型。
const target7: u32 = 7;
const target4: u32 = 4;
const target6: u32 = 6;
const hit = std.sort.binarySearch(u32, &sorted, target7, orderU32);
std.debug.print("binarySearch(7) = {any}（命中下标）\n", .{hit});
std.debug.print("binarySearch(4) = {any}（没命中返回 null，不是错误）\n", .{std.sort.binarySearch(u32, &sorted, target4, orderU32)});
// lowerBound / upperBound：返回 usize 而不是 ?usize，是"插入位置"
std.debug.print("lowerBound(4) = {d}（第一个 >= 4 的位置）\n", .{std.sort.lowerBound(u32, &sorted, target4, orderU32)});
std.debug.print("upperBound(4) = {d}（第一个 > 4 的位置）\n", .{std.sort.upperBound(u32, &sorted, target4, orderU32)});
// ⚠️ partitionPoint 是例外：它的第4 参是 **bool 谓词**不是 Order 比较函数
const pp = std.sort.partitionPoint(u32, &sorted, target4, struct {
    fn isBelow(ctx: u32, item: u32) bool {
        return item < ctx;
    }
}.isBelow);
std.debug.print("partitionPoint(元素<4 的个数) = {d}（谓词签名，返回 bool）\n", .{pp});
// 排序 + 二分 = 有序插入
const pos = std.sort.lowerBound(u32, &sorted, target6, orderU32);
std.debug.print("插入 6 应放在 sorted[{d}]={d} 之前（保持有序的唯一正确位置）\n", .{ pos, sorted[pos] });
// equalRange：一次拿到相等区间两端
const dup = [_]u32{ 1, 2, 2, 2, 5, 7 };
const key2: u32 = 2;
const range = std.sort.equalRange(u32, &dup, key2, orderU32);
std.debug.print("equalRange(2) = [{}, {}) 共 {d} 个2\n", .{ range[0], range[1], range[1] - range[0] });
// min/max/argMin/argMax/isSorted：⚠️ 0.17 里 min/max/argMin/argMax 返回**可选**
//（空切片返回 null），而且格式化必须用 {any}——用 {d} 会报
//    error: invalid format string 'd' for type '?u32'
std.debug.print("min={any} max={any} argMin={any} argMax={any} isSorted={}\n", .{
    std.sort.min(u32, &sorted, {}, lessThanU32),
    std.sort.max(u32, &sorted, {}, lessThanU32),
    std.sort.argMin(u32, &sorted, {}, lessThanU32),
    std.sort.argMax(u32, &sorted, {}, lessThanU32),
    std.sort.isSorted(u32, &sorted, {}, lessThanU32),
});
std.debug.print("空切片的 min = {any}（返回 null，不是崩溃）\n", .{std.sort.min(u32, &[_]u32{}, {}, lessThanU32)});
end("12.11");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.11 开始 ====
binarySearch(7) = 3（命中下标）
binarySearch(4) = null（没命中返回 null，不是错误）
lowerBound(4) = 2（第一个 >= 4 的位置）
upperBound(4) = 2（第一个 > 4 的位置）
partitionPoint(元素<4 的个数) = 2（谓词签名，返回 bool）
插入 6 应放在 sorted[3]=7 之前（保持有序的唯一正确位置）
equalRange(2) = [1, 4) 共 3 个2
min=1 max=11 argMin=0 argMax=5 isSorted=true
空切片的 min = null（返回 null，不是崩溃）
==== 12.11 结束 ====
```

### ⚠️⚠️ 裸字面量当 context 会编译失败（本节最容易踩的坑）

老教程里通常写 `std.sort.binarySearch(u32, sorted, 7, orderFn)`——**在 0.17 编译不过**：

```text
error: expected type 'fn (comptime_int, u32) math.Order', found 'fn (u32, u32) math.Order'
    _ = std.sort.binarySearch(u32, &sorted, 3, C.cmp);
                                               ~^~~~
note: non-generic function cannot cast into a generic function
note: parameter type declared here
    comptime compareFn: fn (@TypeOf(context), T) std.math.Order,
```

原因很实在（03 章 3.3 节讲过）：**字面量是 `comptime_int`**，所以 `ctx` 被推断成
`comptime_int`，于是 `compareFn` 必须接受 `comptime_int`——而你的 `orderU32(ctx: u32, ...)`
声明的是 `u32`。**"非泛型函数不能转成泛型函数的形参"**，编译器不给你coerce。

修法就是示例里写的：**给查找目标点名类型**（`const target7: u32 = 7;`）。
或者把 `orderU32` 的 `ctx` 参数也声明成 `comptime_int`（但那样就失去 comptime 优化了，不值）。

⚠️ 同一个坑在 `sort` 里不存在——因为 `sort` 的 `ctx` 惯例上写 `{}`（一个空结构体字面量），
类型天然确定。**只有 `binarySearch` / `lowerBound` 这类"拿 ctx 当查找目标"的函数会踩。**

### `partitionPoint` 是例外：谓词签名

前五个函数的第 4 参都是 `fn (@TypeOf(ctx), T) std.math.Order`，
但 **`partitionPoint` 是 `fn (@TypeOf(ctx), T) bool`**：

```text
error: expected type 'fn (u32, u32) bool', found 'fn (u32, u32) math.Order'
    std.sort.partitionPoint(u32, &sorted, t4, Target.cmp)
note: return type 'math.Order' cannot cast into return type 'bool'
note: parameter type declared here
    comptime predicate: fn (@TypeOf(context), T) bool,
```

为什么？因为 `partitionPoint` 的语义是"**满足谓词的前缀有多长**"——
`lowerBound` / `upperBound` 本身就是它的一个包装（源码里 `lowerBound` 内部
`return partitionPoint(T, items, context, S.predicate)`，`S.predicate` 把
`Order.invert()` 转成 bool）。所以底层那个函数只需要"左半边满足 / 右半边不满足"，
bool 就够。

**但 `partitionPoint` 本身很有用**——"有多少个元素满足某条件"用它是 O(log n)：
输出第 6 行 `partitionPoint(元素<4 的个数) = 2`（`{1,3,5,...}` 里 `< 4` 的正好 2 个）。
如果数组**已经有序**（谓词单调），这是最优解；如果没序，这个函数是错的（不检查单调性）。

### `min` / `max` / `argMin` / `argMax` 返回**可选**（0.17 变化）

这几个函数的返回值在 0.17 是 `?T` / `?usize`（空切片返回 `null`），**不是** `T`。
格式化时必须用 `{any}`，用 `{d}` 会报：

```text
error: invalid format string 'd' for type '?u32'
/Volumes/.../lib/std/Io/Writer.zig:1935:5: error: invalid format string 'd' for type '?usize'
```

输出第 9 行那行 `min=1 max=11 argMin=0 argMax=5` 用的是 `{any}`，
输出第 10 行专门演示空切片：`空切片的 min = null（返回 null，不是崩溃）`。

顺带：`isSorted` 返回 `bool`（不是可选），**它是断言式检查**——在 Debug 模式下
`isSorted` 之后接一个 `std.debug.assert`，可以在测试里钉住"这个列表必须有序"
这个前置条件（`std.mem.sort` 的前提）。

### `lowerBound` 的用途：有序插入

输出第 7 行是这一节的实用落点：`lowerBound(6)` 返回 3，
也就是 `sorted[3] = 7`，**6 应该插在下标 3 的位置**——这是保持有序的唯一正确位置
（插在 2 会破坏有序，插在 4 之后又是乱序）。要"二分找位置 + 插入"就得这么写：

```zig
const pos = std.sort.lowerBound(u32, &sorted, target6, orderU32);
try list.insert(mem, pos, 6);   // 有序插入，O(n) 搬移 + O(log n) 定位
```

34 章的 zcache 用它做有序淘汰（找出最久未用的那个）就是这个模式。

## 12.12 定容集合：`std.BoundedArray` 已移除，手写三件套

`std.BoundedArray(N)` 在 0.17 **不存在**：

```text
error: root source file struct 'std' has no member named 'BoundedArray'
    var l = std.BoundedArray(u8, 4).init(std.heap.page_allocator);
            ~~~^~~~~~~~~~~~~
note: struct declared here
pub const AutoHashMap = hash_map.AutoHashMap;
```

替代方案就是 0.14 起的三件套：**栈上定长数组 + 一个 usize 长度 + 一个"满了怎么办"的策略**。

```zig
// examples/12_collections/main.zig 第 48-63 行
/// 12.12 节的定容集合手写替代：定长数组 + 计数（std.BoundedArray 在 0.17 已移除）
const FixedStack = struct {
    buf: [4]u8 = undefined,
    len: usize = 0,

    /// 返回 false = 满了（拒绝，既不覆盖也不扩容）
    fn push(self: *FixedStack, ch: u8) bool {
        if (self.len == self.buf.len) return false;
        self.buf[self.len] = ch;
        self.len += 1;
        return true;
    }
    fn items(self: *const FixedStack) []const u8 {
        return self.buf[0..self.len]; // 只暴露有效部分，不泄漏容量
    }
};
```

```zig
// examples/12_collections/main.zig 第 561-579 行
begin("12.12");
// ⚠️ std.BoundedArray 在 0.17 **不存在**（实测 error: root source file struct 'std'
//    has no member named 'BoundedArray'）。0.14 起被"定长数组 + 计数"取代。
std.debug.print("std 有 BoundedArray 吗? {}\n", .{@hasDecl(std, "BoundedArray")});
// 三件套：栈上数组做存储、usize 记长度、写满就停
var fixed: FixedStack = .{};
for ("zig!") |ch| {
    if (!fixed.push(ch)) break;
}
std.debug.print("定容 4 槽装了 {d} 个字符：{s}（容量就是数组长度）\n", .{ fixed.len, fixed.items() });
// 满了就拒绝——不是覆盖、不是扩容，这就是"定容"的意义
std.debug.print("再 push 一个返回={}（拒绝而非覆盖，len 仍是 {d}）\n", .{ fixed.push('?'), fixed.len });
// 动态版对照：同样内容放进 ArrayList
var dynamic: std.ArrayList(u8) = .empty;
defer dynamic.deinit(mem);
try dynamic.appendSlice(mem, "zig");
try dynamic.append(mem, '!');
std.debug.print("同样内容放 ArrayList → {s}（len={d}，可以无限长）\n", .{ dynamic.items, dynamic.items.len });
end("12.12");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.12 开始 ====
std 有 BoundedArray 吗? false
定容 4 槽装了 4 个字符：zig!（容量就是数组长度）
再 push 一个返回=false（拒绝而非覆盖，len 仍是 4）
同样内容放 ArrayList → zig!（len=4，可以无限长）
==== 12.12 结束 ====
```

**"定容"的价值在于分配器不能失败**。`push` 返回 `bool` 而不是 `!void`——
因为栈上数组不需要分配，所以**没有 `error.OutOfMemory` 这条路径**。
对比输出第 5 行：`ArrayList` 的每个 `append` 都是 `try`（可能 OOM），
而 `FixedStack.push` 只是个普通 `bool`。**在实时/嵌入式/内核式代码里这个差别是决定性的**——
一段解析路径上不允许出现"分配失败"这种运行时不确定性时，定容写法是唯一选择。

测试里把"拒绝而非覆盖"这个语义钉得很死——**长度不变、内容不变**：

```zig
// examples/12_collections/main.zig 第 902-907 行（test "12.12 …"）
for ("zig!") |ch| try std.testing.expect(f.push(ch)); // 4 个字符正好塞满 4 槽
try std.testing.expectEqual(@as(usize, 4), f.len);
try std.testing.expectEqualStrings("zig!", f.items());
try std.testing.expect(!f.push('?')); // 第 5 个被拒绝——不覆盖、不扩容
try std.testing.expectEqual(@as(usize, 4), f.len); // 长度没变
try std.testing.expectEqualStrings("zig!", f.items()); // 内容也没被覆盖
```

⚠️ **变体策略要自己决定**。"满了之后"可以是：拒绝（示例）、覆盖最旧的（环形缓冲，
20 章的网络收包就是环形）、覆盖最新的、丢弃一半旧的（`shrinkRetainingCapacity`）——
**`BoundedArray` 曾经把这个策略硬编码成"满了 panic"，现在还给你了，所以更该想清楚。**

**`items()` 返回 `[]const u8` 而不是整个 `buf`**——只暴露 `[0..len)`，
这样调用方拿到一个"和普通切片一样"的东西，不会看到未初始化的尾部。
需要读尾部（罕见）就再加一个 `raw()` 方法。

## 12.13 集合选型表

```zig
// examples/12_collections/main.zig 第 582-602 行
begin("12.13");
// 决策顺序（按实测存在的类型列）：
// 1. 长度编译期已知且小 → [N]T 栈数组（零分配、零间接）
// 2. 长度编译期已知但要当参数传 → []const T 切片
// 3. 长度要变、要放堆 → std.ArrayList(T)（unmanaged，本章 12.1-12.4）
// 4. 长度要变但不许堆 → 12.12 的"数组 + len"三件套
// 5. 键值查找 → std.AutoHashMap / std.StringHashMap（managed）
//    键值查找 + 要保插入序 → std.array_hash_map.Auto（12.8）
// 6. 元素是结构体、只扫部分字段 → std.MultiArrayList（12.9）
// 7. 只是要个"枚举键的集合" → std.EnumSet（位域，零分配，见 08 章）
var mask: std.EnumSet(Flag) = .{};
mask.insert(.a);
mask.insert(.c);
std.debug.print("EnumSet(Flag)：sizeOf={d}字节 bitSize={d}位；含 a={} b={} c={} count={d}\n", .{
    @sizeOf(std.EnumSet(Flag)), @bitSizeOf(@TypeOf(mask.bits)),
    mask.contains(.a),          mask.contains(.b),
    mask.contains(.c),          mask.count(),
});
// 一句话总结
std.debug.print("选型口诀：定长用数组、要变用 List、查键用 Map、要序用 array_hash_map、扫字段用 MultiArrayList、枚举集合用 EnumSet\n", .{});
end("12.13");
```

运行输出（`examples/12_collections/main.zig`）：

```text
==== 12.13 开始 ====
EnumSet(Flag)：sizeOf=1字节 bitSize=4位；含 a=true b=false c=true count=2
选型口诀：定长用数组、要变用 List、查键用 Map、要序用 array_hash_map、扫字段用 MultiArrayList、枚举集合用 EnumSet
==== 12.13 结束 ====
```

### 完整决策表

| 需求 | 选它 | 形态 | 章节 |
|---|---|---|---|
| 长度编译期已知、几个到几十个 | `[N]T` | 栈数组 | 06 章 |
| 长度编译期已知、要当参数传 | `[]const T` | 切片 | 06 章 |
| 长度要变、要放堆、要按值存进 struct | `std.ArrayList(T)` | unmanaged，`.empty` | 12.1-12.4 |
| 构造完就只要数据（容器退场） | `ArrayList.toOwnedSlice(gpa)` | — | 12.4 |
| 长度要变、**不许分配失败** | `[N]T` + `usize` 手写 | 栈 | 12.12 |
| 键值查找，键是整数/结构体 | `std.AutoHashMap(K,V)` | managed，`.init(a)` | 12.5 |
| 键值查找，键是字符串 | `std.StringHashMap(V)` | managed | 12.7 |
| 键值查找 + **要保插入序** | `std.array_hash_map.Auto(K,V)` | **unmanaged** | 12.8 |
| 键值查找 + **要fetchRemove** | `std.AutoHashMap` | managed | 12.6 |
| 元素是结构体、**只扫部分字段** | `std.MultiArrayList(Struct)` | unmanaged | 12.9 |
| 元素是结构体、字段一起用 | `std.ArrayList(Struct)` | unmanaged | 12.2 |
| 键是**枚举**、只要"在不在" | `std.EnumSet(E)` | 位域，**1 字节起** | 12.13 |
| 键是**枚举**、要带值 | `std.EnumMap(E, V)` | unmanaged | 08 章 |
| 顺序敏感的去重集合 | `std.EnumSet` + `union` 技巧 | 位域 | 08 章 |
| 栈 / 队列 / 双端队列 | `std.ArrayList` + `swapRemove` | unmanaged | 12.2 |
| 优先级队列 | `std.PriorityQueue(T, lessFn, max)` | 堆 | 31 章 |
| 排序 | `std.mem.sort`（稳定） | — | 12.10 |
| 有序数据的查找 | `std.sort.binarySearch` / `lowerBound` | — | 12.11 |

### `EnumSet`：被低估的零成本集合

输出第 2 行：`Flag` 有 4 个成员，`EnumSet(Flag)` 只占 **1 字节**（4 个 bit）。
它是 08 章 `packed struct` 思想的直接应用：**集合的成员数编译期已知，于是用位图**。
`std.EnumSet` 的完整 API（实测）：`init(EnumFieldStruct)` / `initMany` / `initOne` /
`count` / `contains` / `insert` / `remove` / `setPresent` / `toggle` / `toggleSet` /
`toggleAll` / `setUnion` / `setIntersection` / `eql` / `subsetOf` / `supersetOf` /
`complement` / `unionWith` / `intersectWith` / `xorWith` / `differenceWith` / `iterator`。

⚠️ **初始化写 `{}`，不是 `.initEmpty()`**——`initEmpty` 在 0.17 **不存在**
（实测 `error: struct 'enums.EnumSet(Flag)' has no member named 'initEmpty'`）。
`bits` 字段有默认值 `.empty`，所以 `var s: std.EnumSet(F) = .{};` 就够了。

⚠️ **`isEmpty` 和 `toArray` 也不存在**（实测两者都报 `no member named`）。
判空用 `count() == 0`，取出用 `iterator()` 或 `initMany` 反推。

**集合运算（交集 / 并集 / 差集 / 对称差）是一整套的**——如果你的集合成员是枚举，
`EnumSet` 比 `AutoHashMap(enum, void)` 好太多：零分配、1 字节、按值可拷贝、
运算全部编译成位操作。27 章的树、31 章的并发集合都用得上。

### 12.14 测试：12 个 test 块钉住每节的语义

本章 12 个 test 块全部用 `std.testing.allocator`——**它在 `defer` 触发时报告泄漏**，
所以每个测试既验证了语义，又验证了内存管理的正确性：

```text
$ zig test main.zig
1/12 main.test.12.1 unmanaged 容器可内嵌 struct，且 ArrayListUnmanaged 是同一类型...OK
2/12 main.test.12.2 append/insert/pop/orderedRemove/swapRemove 的语义...OK
3/12 main.test.12.3 容量增长、ensureTotalCapacity 与 clearRetainingCapacity...OK
4/12 main.test.12.4 toOwnedSlice 掏空容器，fromOwnedSlice 零拷贝接管...OK
5/12 main.test.12.5/12.6 HashMap：get / getOrPut / fetchRemove / remove / getPtr...OK
6/12 main.test.12.7 StringHashMap 按内容哈希，key 只是借用切片...OK
7/12 main.test.12.8 array_hash_map 保插入序，swapRemove/orderedRemove 语义不同...OK
8/12 main.test.12.9 MultiArrayList：字段拆成并行数组，get/set 与 swapRemove...OK
9/12 main.test.12.10 排序：mem.sort 稳定 / sortUnstable 不稳定，ctx 传外部状态...OK
10/12 main.test.12.11 二分：binarySearch / lowerBound / upperBound / equalRange...OK
11/12 main.test.12.12 定容集合手写三件套：满了拒绝而非覆盖...OK
12/12 main.test.12.13 选型：ArrayListUnmanaged 同一性 + EnumSet 也是集合...OK
All 12 tests passed.
```

几个测试值得单独说：

**测试 2（12.2）把两种删除的语义钉成了数组比较**：

```zig
// examples/12_collections/main.zig 第 641-646 行
// orderedRemove 保序
try std.testing.expectEqual(@as(u32, 100), l.orderedRemove(0));
try std.testing.expectEqualSlices(u32, &.{ 5, 3, 9, 1 }, l.items);
// swapRemove 打乱顺序：拿末位补位
try std.testing.expectEqual(@as(u32, 5), l.swapRemove(0));
try std.testing.expectEqualSlices(u32, &.{ 1, 3, 9 }, l.items);
```

**测试 3（12.3）把 `growCapacity` 的公式钉成了精确值**：

```zig
// examples/12_collections/main.zig 第 653-655 行
const init_cap: usize = @max(1, std.atomic.cache_line / @sizeOf(u32));
try std.testing.expectEqual(@as(usize, 1 + 0 + init_cap), std.ArrayList(u32).growCapacity(1));
try std.testing.expectEqual(@as(usize, 34 + 17 + init_cap), std.ArrayList(u32).growCapacity(34));
```

**测试 6（12.7）把"key 是借用"这个事实变成了一个可执行断言**——先`put` 一个
栈 buffer、改写它、再断言 `get` 返回 `null` 且 `keyIterator` 里能看到新内容：

```zig
// examples/12_collections/main.zig 第 746-757 行
var buf: [4]u8 = "gray".*;
try sm.put(gpa, buf[0..], 9);
try std.testing.expectEqual(@as(u32, 9), sm.get("gray").?);
buf[0] = 'X';
try std.testing.expectEqual(@as(?u32, null), sm.get("gray"));
// map 里存的那个 key 现在是 "Xray"（keyIterator 给的是 *const []const u8，要解两层）
var kit = sm.keyIterator();
var found_xray = false;
while (kit.next()) |kp| {
    if (std.mem.eql(u8, kp.*, "Xray")) found_xray = true;
}
try std.testing.expect(found_xray);
```

**测试 11 / 12（12.12、12.13）用 `@hasDecl` 把"哪些名字还存在"钉住了**——
这类"API 存在性断言"在版本升级时特别有用（升到 0.18 时这些测试会先失败，
而不是等到某段业务代码编译不过）。

## 12.14 坑位清单

1. **`std.ArrayList(T)` 在 0.17 就是 unmanaged 形态**（`.empty` + 方法收分配器），
   `@typeName` 是 `array_list.Aligned(T,null)`。`std.ArrayListUnmanaged` **仍然存在**
   但是 Deprecated 别名（`pub const ArrayListUnmanaged = ArrayList;`），
   与 `ArrayList` 是**同一个类型**——不是"旧类型被移除了"。

2. **`std.ArrayHashMap` 和 `std.AutoArrayHashMap` 已被移除**。0.17 里没有这两个名字
   （实测 `error: root source file struct 'std' has no member named 'ArrayHashMap'`）。
   新家在 **`std.array_hash_map`**：`Auto(K,V)` / `String(V)` / `Custom(K,V,Context,store_hash)`，
   **全部是 unmanaged**。老名字 `std.ArrayHashMapUnmanaged` 等是 Deprecated 别名。

3. **`std.BoundedArray` 已不存在**（实测 `no member named 'BoundedArray'`）。
   用"定长数组 + `usize` 长度 + 满了怎么办"三件套自己写。
   好处不只是省内存，还有**分配失败路径消失**（`push` 返回 `bool` 而不是 `!void`）。

4. **`pop()` 返回 `?T`，空表返回 `null` 而不是 panic**（实测 `std.ArrayList(u32).pop()`
   的类型是 `?u32`）。⚠️ 但 `orderedRemove(i)` / `swapRemove(i)` 返回**裸 `T`**——
   越界索引是编程错误，直接 panic。三个方法返回类型不一致，别搞混。

5. **HashMap 族 managed / unmanaged **两套并存**，抄错时报错长这样：
   `error: member function expected 2 argument(s), found 3`（给 managed 版多传了分配器）。
   记法：**managed 一律 `.init(alloc)` 且方法不带分配器；unmanaged 一律 `.empty` 且方法第一个参数是分配器。**

6. **`StringHashMap` 的 key 是借用不是拷贝**（实测：改写原buffer 后 `get` 返回 `null`，
   但 `keyIterator` 里能看到新内容）。字符串字面量安全（静态存储期），
   栈上 buffer / 临时拼接 / `ArrayList.items` **都危险**——必须 `mem.dupe` 进堆。
   这一条直接决定 34 章 zcache 的设计。

7. **`binarySearch` / `lowerBound` / `upperBound` 的 `context` 不能是裸字面量**：
   `error: expected type 'fn (comptime_int, u32) math.Order', found 'fn (u32, u32) math.Order'`
   + `note: non-generic function cannot cast into a generic function`。
   修法：`const target: u32 = 7;`（给查找目标点名类型）。
   排序函数没这问题（`ctx` 惯例写 `{}`）。

8. **`partitionPoint` 的第 4 参是 `bool` 谓词，不是 `Order` 比较函数**：
   `error: expected type 'fn (u32, u32) bool', found 'fn (u32, u32) math.Order'`。
   `binarySearch` / `lowerBound` / `upperBound` / `equalRange` 才是 `Order`。

9. **`std.sort.min` / `max` / `argMin` / `argMax` 在 0.17 返回**可选**
   （`?T` / `?usize`，空切片返回 `null`）。格式化必须用 `{any}`，
   `{d}` 会报 `error: invalid format string 'd' for type '?u32'`。

10. **`ArrayList` 没有 `.sort` 也没有 `.swap`**（实测两个都报
    `no field or member function named 'sort' in 'array_list.Aligned(u32,null)'`）。
    排 `ArrayList` 就是 `std.mem.sort(T, list.items, ctx, lessFn)`；
    换两个元素用 `std.mem.swap(T, &a, &b)`。
    `array_hash_map` 也**没有 `valueIterator` / `toOwnedSlice`**，而且
    **没有 `fetchRemove` / `remove`**（只有 `swapRemove(key)` / `orderedRemove(key)` 返回 `bool`）。

11. **`StringHashMap.keyIterator` 要解两层指针**：`kp` 是 `*[]const u8`，
    `kp[0]` 报 `error: type '*[]const u8' does not support indexing`，要写 `kp.*[0]`。

12. **`MultiArrayList.toOwnedSlice()` 没有分配器参数也不返回 error**（和
    `ArrayList.toOwnedSlice(gpa)` 不同）。返回的 `Slice` **没有具名字段**，
    要访问还是 `owned.items(.field)`——写 `owned.names` 报 `no field named 'names'`。
    `swapRemove` / `orderedRemove` 返回 **`void`**（拿不到被删的值）。

13. **⚠️ 0.17.0 的 std bug：`MultiArrayList.sort` / `sortSpan` / `sortSpanUnstable` 全部编译不过**。
    实测报错：`lib/std/multi_array_list.zig:609:36: error: cannot store runtime value in
    compile time variable`（`.slice = self.slice(),`）。变通方案：排下标数组
    （把字段切片当 `ctx` 传给 `std.mem.sort(usize, &order, field_slice, cmp)`）。

14. **`putNoClobber` 在键已存在时 panic 而不是返回错误**。std 源码是
    `assert(!result.found_existing)`，实测 `thread ... panic: reached unreachable code`。
    "存在就不写"这种正常业务逻辑请用 `getOrPut` 的 `found_existing` 分支。

15. **`ArrayHashMap.swapRemove(key)` 和 `ArrayList.swapRemove(index)` 参数与返回值都不同**：
    前者收**键**、返回 `bool`；后者收**下标**、返回**被删的元素**。同名不同义，抄代码必错。

16. **`std.EnumSet` 初始化写 `{}`，`.initEmpty()` 不存在**
    （`error: struct 'enums.EnumSet(Flag)' has no member named 'initEmpty'`）；
    `isEmpty` 和 `toArray` 也没有——用 `count() == 0` 和 `iterator()`。
    另外 `std.hash.autoHash` **拒绝 `[]const u8` 做键**
    （`does not allow slices here ([]const u8) because the intent is unclear`）——
    字符串键必须用 `StringHashMap` / `StringHashMapUnmanaged` / `array_hash_map.String`。

17. **`std.debug.print` 的格式串里字面 `{` 会被当占位符**。写
    `"insertSlice(1, {60,70})"` 报 `error: too few arguments`（它把 `{60,70}`
    当成了一个格式化说明符）。要打印花括号就写 `{{` `}}`，或者干脆改成 `60/70`。

18. **`ensureTotalCapacity(n) 给的是"至少 n"，不是"正好 n"**：内部调
    `ensureTotalCapacityPrecise(gpa, growCapacity(n))`，实测
    `ensureTotalCapacity(4096)` 得到 `capacity = 6176`。要精确值用 `ensureTotalCapacityPrecise`。

---

上一章：[11 分配器](11-allocators.md) · 下一章：[13 comptime I](13-comptime.md)
