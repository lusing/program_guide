# 12 · 集合类型 ⭐

> 对应示例：`examples/12_collections/`

## 12.1 ArrayList：unmanaged 形态

```zig
var list: std.ArrayList(u32) = .empty;      // 0.14+ 唯一形态：值 + .empty
defer list.deinit(mem);                     // 清理也带分配器
try list.appendSlice(mem, &.{ 5, 3, 9 });   // 每个操作都传分配器
try list.append(mem, 2);
try list.insert(mem, 0, 100);
const popped = list.pop().?;                // 0.16：pop 返回 ?T（空表 null）
_ = list.orderedRemove(0);                  // 保序删除
```

**`.empty` 值 + 方法收分配器**——这就是 0.14 起 ArrayList 的（唯一）形态，旧教程的 `ArrayList(T).init(alloc)` 已成历史。为什么这么改：容器变成**纯数据**（可以放 struct 里、可以拷贝、没有藏着的分配器状态），分配器跟着操作走（和 11 章哲学一脉相承）。`items` 字段就是底层 `[]T`，直接当切片用。

| 操作 | 方法 | 复杂度 |
|---|---|---|
| 尾部加 | `append(mem, v)` | 均摊 O(1) |
| 批量加 | `appendSlice(mem, s)` | O(n) |
| 弹尾 | `pop() ?T` | O(1) |
| 插入 | `insert(mem, i, v)` | O(n) 搬移 |
| 保序删 | `orderedRemove(i)` | O(n) 搬移 |
| 换位删 | `swapRemove(i)` | O(1)，**打乱顺序** |
| 预留 | `ensureTotalCapacity(mem, n)` | — |

## 12.2 容量与所有权转移

```zig
try list.ensureTotalCapacity(mem, 32);   // 一次到位（循环里反复 append 前先做）
list.capacity                            // 当前容量（> len 的部分是预留）
const owned = try list.toOwnedSlice(mem); // list 变空；owned 由调用者 free
```

增长策略：容量不够时按约 1.5 倍扩——**中途会出现"搬新家"**，旧的 `&list.items` 指针会失效（坑位 2）。`toOwnedSlice` 把堆缓冲的管理权交给调用者（容器退场、数据留下），是"构造完就只要结果"场景的收尾动作（`defer mem.free(owned)` 接力）。

## 12.3 AutoHashMap：按键自动配策略

```zig
var map = std.AutoHashMap(u32, []const u8).init(mem);   // managed：init 收分配器
defer map.deinit();
try map.put(1, "一");
if (map.get(2)) |v| { ... }        // ?V
const gop = try map.getOrPut(3);    // 拿到槽位引用，自己决定插不插
if (!gop.found_existing) gop.value_ptr.* = "三";
_ = map.remove(1);
```

HashMap 族**保留了 managed 形态**（`init(alloc)` 一次、之后不用再传）——和 ArrayList 不同，注意别写混。`Auto` 表示键的哈希/相等函数按 K 自动选（整数用位混合，struct 用字段哈希）。`getOrPut` 是"查到就用、没查到就插"的原子一步（先 `get` 再 `put` 是两步、两次哈希）。

| 变体 | 键 | 特点 |
|---|---|---|
| `AutoHashMap(K, V)` | 任意（自动） | 默认选择 |
| `StringHashMap(V)` | `[]const u8` | **按内容**哈希 |
| `ArrayHashMap(K, V)` | 任意 | 保插入顺序，迭代快 |

## 12.4 StringHashMap：内容即键

```zig
var colors = std.StringHashMap(u32).init(mem);
try colors.put("red", 0xFF0000);
colors.get("red")          // 找得到——"red" 字面量内容相同
```

字符串键按**字节内容**哈希和比较，不是指针地址——两个不同的 `"red"` 是同一个键。代价见坑位 4：**放进去的键内存必须活到 map 死**（map 只存了切片）。

## 12.5 迭代与删除

```zig
var it = colors.iterator();               // 顺序不保证！
while (it.next()) |e| { e.key_ptr.*; e.value_ptr.*; }
if (colors.fetchRemove("red")) |rm| {     // 删除并取走键值对
    rm.key; rm.value;
}
```

迭代器给指针（`key_ptr/value_ptr`），遍历时能改值别动结构。**迭代中 put 是悬空隐患**（触发 rehash 后迭代器全废）——迭代时收集要删的键，循环外逐个 `remove`，或直接用 `fetchRemove` 边删边拿。

## 12.6 排序：std.mem.sort

```zig
fn lessThan(_: void, a: u32, b: u32) bool { return a < b; }
var nums = [_]u32{ 42, 7, 19, 3 };
std.mem.sort(u32, &nums, {}, lessThan);        // 升序，原地
// ctx 参数：比较函数需要的上下文（按结构体字段排序时传出去）
fn byAge(_: void, a: User, b: User) bool { return a.age < b.age; }
```

`std.mem.sort(T, slice, context, lessThan)`——pdq 家族（混台快排），不稳定排序。**context 参数**让比较函数无捕获也能比较"外部状态"（比如按配置的键排序）。要稳定排序用 `std.sort.block`。

## 12.7 选型速查

| 需求 | 选择 |
|---|---|
| 长度编译期已知 | 数组 `[N]T`（栈，免费） |
| 动态增长的主力 | `ArrayList(T)` |
| 定容、避免堆 | 数组 + len 手管（0.16 已移除 `BoundedArray`） |
| 键值查找 | `AutoHashMap` / `StringHashMap` |
| 键值 + 插入序 | `ArrayHashMap` |
| 排序 | `std.mem.sort`（不稳定）/ `std.sort.block`（稳定） |

## 12.8 坑位清单

1. **`pop()` 返回 `?T`**：0.16 的 pop 对空表返回 null——直接当值用编译错，`.?` 或 if 捕获。
2. **append 后旧指针失效**：扩容搬新家，迭代/缓存过的 `&list.items[i]` 全部作废——需要稳定引用先 `ensureTotalCapacity`，或改存下标。
3. **HashMap 仍要 `.init(alloc)`**：和 ArrayList 的 `.empty` 不同族——0.16 里 ArrayList unmanaged、HashMap managed，抄代码看清是哪个。
4. **StringHashMap 的键生命周期**：键切片被 map 保存，放进 map 的字符串若是临时拼接（栈上 buffer），map 一 rehash 就悬空——键要 `dupe` 进堆。
5. **swapRemove 不保序**：O(1) 删除的代价是拿末尾补位——顺序有意义的场景用 `orderedRemove`。
6. **`{d}` 打不出切片**：ArrayList 的 items、数组都要 `{any}`（02 章格式规则）。

---
