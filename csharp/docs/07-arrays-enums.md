# 07 · 数组与枚举

> 对应示例：`examples/07_arrays_enums`

> **本章你将学会**：数组三种形态、Array 类操作、枚举的底层与还原、[Flags] 位标志。
> **前置章节**：[05 值与引用](05-value-reference.md)、[06 字符串](06-strings.md)。

## 1. 数组：最底层的集合

数组是**引用类型**（注意！变量是栈上的地址，元素在堆上），长度创建即定、不可变。三种形态：

```csharp
int[] one = { 5, 3, 8, 1 };                        // 一维（最常用）
int[,] grid = { { 1, 2 }, { 3, 4 } };              // 多维（矩形：每行同长）
int[][] jagged = { new[] { 1 }, new[] { 1, 2 } };  // 交错（数组的数组，各行可不同长）
```

| | 一维 `T[]` | 多维 `T[,]` | 交错 `T[][]` |
|---|---|---|---|
| 形状 | 直线 | 矩形 | 不规则 |
| 取值 | `a[i]` | `g[i, j]` | `j[i][j]` |
| 长度 | `Length` | `GetLength(0/1)` | 各行 `.Length` |
| 典型 | 列表数据 | 棋盘/矩阵（连续内存） | 稀疏/行不等长 |

多维 `[,]` 是"一整块矩形内存"；交错 `[][]` 是"数组的数组"（每行独立对象）。矩阵运算连续性要求高用 `[,]`；行结构不齐用 `[][]`。日常业务两种都少见——**一维数组 + List/Dictionary 覆盖九成场景**。

## 2. Array 类的静态操作

```csharp
Array.Sort(one);                       // 原地排序（要求元素可比较，第 10 章 IComparable）
Array.Reverse(one);                    // 原地反转
Array.BinarySearch(one, 8);            // 二分查找（必须已排序！）
Array.IndexOf(one, 8);                 // 线性找下标
Array.Copy(src, dst, len);             // 复制
```

注意 `BinarySearch` 的前提：**先 Sort 再查**，乱序数组二分结果是垃圾。找不到返回**负数**（按位取反 ~结果 是插入位置，巧用可做有序插入）。

数组 vs `List<T>`（第 12 章 BCL 集合）的选型：定长、底层互操作、性能极致 → 数组；动态增删、丰富 API → List。**别用 `ArrayList`（非泛型老古董）**——装箱黑洞（第 05 章实测过）。

## 3. 枚举：给整数穿上名字

```csharp
enum Level { Low = 0, Mid = 1, High = 2 }   // 不写值则从 0 自动递增

var lv = Level.High;
(int)lv                    // 2      ← 底层就是 int
(Level)1                   // Mid    ← 数字还原（不校验是否存在！）
Level.High.ToString()      // "High" ← 名字
Enum.TryParse<Level>("High", out var parsed)   // 字符串安全还原
```

枚举的价值：把魔法数字换成**编译器可检查**的名字（`Level.High` 拼错编译不过，`2` 拼错没人知道）。底层类型默认 int，可换：`enum Big : long { ... }`。

两条安全须知：

1. `(Level)99` 编译运行都不报错——**还原外部数据后校验**：`Enum.IsDefined(typeof(Level), value)`
2. 枚举是值类型，可以为 0 且不属于任何名字——switch 表达式的兜底分支别忘了（第 04 章）

## 4. [Flags]：一个值装多个开关

```csharp
[Flags]
enum Perms { None = 0, Read = 1, Write = 2, Exec = 4 }   // 值必须按 2 的幂分配！

var mine = Perms.Read | Perms.Write;     // 组合：0000_0011
mine.HasFlag(Perms.Read)                 // true  ← 查某位
mine & ~Perms.Write                      // 去掉 Write
```

位运算四件套（`|` 加、`&` 查、`& ~` 减、`^` 翻转）作用于二进制位。[Flags] 特性本身只影响 `ToString()` 显示（`mine` 打印成 `Read, Write` 而不是数字）和 API 约定——**真正让位标志成立的是 2 的幂取值**。

设计提醒：组合值可以预定义（`All = Read | Write | Exec`）；命名用复数（`Permissions`/`Options`）；不要给普通枚举乱加 [Flags]——值不是 2 的幂时组合结果无意义。

## 5. 与后续章节的接口

- foreach 遍历数组/枚举 → 第 18 章（IEnumerator 的真面目）
- 数组作 LINQ 数据源 → 第 16 章（`array.Where(...)` 随处可见）
- 枚举配 switch 表达式 → 第 04/19 章（枚举是模式匹配最舒服的伙伴）
- `ReadOnlySpan<T>` 是数组的零拷贝窗口 → 第 26 章

## 常见坑

**越界**：`one[10]` → IndexOutOfRangeException。C# 不做静默环绕（不像溢出），直接崩——好定位但要防：`^1`（倒数第一）、范围 `a[1..3]` 少算下标。

**多维数组用 `.Length`**：`Length` 是**元素总数**（4），不是行数；`GetLength(0)` 才是行数。

**交错数组初始化要 new 每行**：`int[][] j = { {1}, {2} }` 编译错误（内层是数组引用）；要 `new[] {1}`。

**枚举还原不校验**：`(Level)99` 合法地产生无效值——外部输入走 `Enum.IsDefined` 或 `TryParse`。

**[Flags] 忘了 2 的幂**：`A=1, B=2, C=3`（3=A|B 冲突）——位标志直接乱套。

## 实战建议

- API 参数能用枚举就不用 int/字符串——编译期检查是免费的防线
- 数组仅两场景：定长数据 + 性能/互操作；其余 List 起步
- 位标志的 [Flags] + 2 的幂 + 复数命名三件套同时上
- 打印调试枚举直接插值（ToString 自动给名字），别转 int

## 自测

1. **数组是值类型还是引用类型？三种形态各适用什么？** —— 引用类型；一维常用、多维（矩形棋盘）、交错（行不齐）。
2. **BinarySearch 的前提与找不到的返回值？** —— 已排序；负数（~结果为插入点）。
3. **枚举的底层是什么？怎么安全还原外部输入？** —— 默认 int；TryParse/IsDefined 校验。
4. **[Flags] 生效的真正条件？** —— 取值为 2 的幂（特性只管显示）。

---
上一章：[06 字符串深度](06-strings.md) ｜ 下一章：[08 类与封装](08-classes.md) ｜ 返回：[README](../README.md)
