# 06 · 数组、切片与关联数组

> 对应示例：`examples/06_arrays/`

## 6.1 三种"集合"全是内建

| 种类 | 语法 | 语义 |
|---|---|---|
| 静态数组 | `int[3] a;` | 定长、**值语义**（赋值=全量拷贝） |
| 动态数组/切片 | `int[] a;` | 胖指针（ptr+len），**引用语义**（共享内存） |
| 关联数组 | `int[string] aa;` | 内建哈希表 |

不需要引入任何容器库就有这三样——标准库的复杂容器（15 章的 RefCounted、std.container）都建在其上。

## 6.2 切片：D 版"视图"

```d
auto a = [10, 20, 30, 40, 50];
auto head = a[0 .. 2];      // [10, 20]：与 a 共享内存！
head[0] = -1;
writeln(a);                 // [-1, 20, 30, 40, 50]：改切片 = 改原数组

auto copy = head.dup;       // dup：真拷贝（int[]）
auto frozen = "abc".idup;   // idup：拷成不可变（string 用）

auto b = a ~ [60, 70];      // ~ 拼接产新内存
a ~= 80;                    // ~= 原地追加（容量不够时自动扩容搬家）
writeln(a.length, " ", a.capacity);   // capacity：扩容前还能白嫖几个位置
```

对比 Go：语义几乎一致（slice 共享底层、append 可能搬家）；对比 Zig：D 的切片没有 allocator 概念（GC 兜底，15 章逃逸术）。

## 6.3 string 就是 immutable(char)[]

```d
string s = "D 语言";
writeln(s.length);            // 8 —— UTF-8 字节数，不是字符数！
writeln(s.byDchar.walkLength); // 4 —— 按码点数
// s[0] = 'd';                // 编译错：元素不可变
auto m = s.dup;               // char[] 可变副本
```

**UTF-8 三连坑**（新手重灾区）：

1. `.length` 数**字节**：`"第一行".length == 9`（3 字 × 3 字节）。
2. 按下标切：`s[0 .. 1]` 拿到的是**字节**不是字符——中文字符中间下标切出的还是合法 string（D 保证不崩，但语义是乱码）。
3. `foreach (c; s)` 拿到 `char`（码元）；按字符遍历要 `.byDchar`。

## 6.4 关联数组（AA）：内建哈希表

```d
int[string] ages;                 // 声明：值[键]
ages["D"] = 26;                   // 写：不存在则插入
int[string] zh = ["D": "D 语言"]; // 字面量初始化（就是 [k: v] 数组形态）

if (auto p = "Go" in ages)        // in：返回指针；不存在为 null
    writeln(*p);

writeln(ages.get("Java", -1));    // get：带默认值，不存在不抛
ages.remove("D");                 // 删除
foreach (k, v; ages) { ... }      // 遍历（顺序不保证）
auto keys = ages.byKey.array;     // 只拿键 / 值 / 键值对
```

## 6.5 AA 的类型参数

```d
int[string] aa1;        // 键 string → 值 int
string[int] aa2;        // 键 int → 值 string
int[string][string] nest;   // 值本身又是 AA：套娃 OK
```

键类型要能算哈希（内建类型/字符串直接用；自定义 struct 做 08 章的 `toHash`）。

## 6.6 数组即区间

数组满足 range 协议（13 章），所以 std.algorithm/std.array 的全部函数直接可用：

```d
[3, 1, 2].sort;                          // 排序（就地）
[1, 2, 3].map!(x => x * 2).array;        // 变换
[4, 8, 15].filter!(x => x > 5).array;    // 过滤
```

## 6.7 坑位清单

1. **读不存在的 AA 键直接抛 RangeError**（崩溃级别）：`ages["missing"]` 读值就炸——判存在用 `in`，取值带兜底用 `.get`，只有**写**才会自动插入。这是本章头号坑。
2. **`string.length` 是 UTF-8 字节数**：字符数用 `.byDchar.walkLength`；同理 `%2s` 之类宽度格式化按字节算，中文对齐会歪。
3. **切片共享**：函数收到切片改了元素，调用方的数组也变——需要独立副本 `dup`。
4. `dup` vs `idup`：`dup` 出可变（`T[]`），`idup` 出不可变（给 `string`）。
5. AA 字面量语法是 `["k": v]`——**不是** Python 式 `{"k": v}`。
6. `a.capacity` 大于 `a.length` 时 `~=` 不搬家，追加便宜；一旦搬家，旧切片指向旧内存——追加后别再用追加前留下的切片。
7. 多维数组是"数组的数组"：`int[][]` 每行长度可不同（锯齿）；要矩形矩阵自己管理 `int[]` + 手算下标。

---
