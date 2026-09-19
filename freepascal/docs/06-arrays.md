# 06 · 数组与集合

## 1. 静态数组：下标范围自己定

```pascal
type
  TWeek = array[1..7] of string;          // 下标 1..7，不必从 0 开始
  TGrid = array[0..2, 0..2] of Integer;   // 静态二维
var
  week: TWeek;
begin
  week[1] := '周一';
  Assert(Low(week) = 1);                  // 下标范围用 Low/High 取，别写死数字
  Assert(High(week) = 7);
```

- **长度编译期定死**，越界靠检查通道（`-Cr`）在运行期抓。
- 静态数组是**值类型**：整体赋值 = 逐元素深拷贝，传参（不带 `var`）也是拷贝。
- 下标从几开始是你说了算——这是 Pascal 的传统艺能，`array['a'..'z']` 都合法（字符序数）。

## 2. 动态数组：SetLength 分配，赋值却是共享

```pascal
type
  TInts = array of Integer;
var
  a, b: TInts;
begin
  SetLength(a, 5);              // 长度 0 出身，SetLength 分配/调整
  for i := 0 to High(a) do a[i] := i * i;    // 下标恒 0..High

  b := a;                       // ⚠️ 共享同一块内存！
  b[0] := 999;
  Assert(a[0] = 999);           // a 也"变"了——它们是同一个数组的两个名字

  SetLength(b, 3);              // SetLength 才触发"脱离共享"（重新分配）
  Assert(Length(a) = 5);        // 此后各过各的
```

**动态数组与静态数组的赋值语义完全相反**（实测断言）：

| | 静态数组 | 动态数组 |
|---|---|---|
| 本体 | 值（栈/嵌入） | 引用计数指针（堆） |
| `b := a` | 深拷贝 | 共享（引用计数 +1） |
| 修改 `b` 的元素 | 不影响 `a` | **影响 `a`** |
| 何时分离 | 天生独立 | `SetLength` 或写操作触发重分配 |

要独立副本：`SetLength(b, Length(a)); Move(a[0], b[0], ...)`（示例 6.2 实测）。
动态数组字面量 `a := [10, 20, 30]`（FPC 3.x 支持）；但记住 05 章的坑：`[1..5]` 是集合不是数组。

## 3. 多维动态数组：数组的数组

```pascal
SetLength(m, 3);                       // 先定行数
for r := 0 to 2 do SetLength(m[r], 4); // 每行各自定长——锯齿数组天然支持
m[2][3] := 23;                          // m[2][3] 与 m[2,3] 等价
```

内存不保证连续（每行一块），要连续大矩阵用一维数组手动算下标。

## 4. 数组作参数：开放数组最通用

```pascal
function Total(const values: array of Integer): Integer;  // 任意数组都能进
procedure DoubleAll(var arr: TInts);                      // var 动态数组：改长度可回传
```

- 开放数组参数（05 章讲过）接纳静态/动态/字面量，`Low` 恒 0。
- **动态数组 + `var`**：过程内 `SetLength` 的结果回传给调用者（示例实测：翻倍 + 追加一个元素）。
- 大数组传参一律 `const`（零拷贝）或 `var`（就地改），裸传会整块拷贝。

## 5. 集合 set：编译器级的位图开关

```pascal
type
  TDigits = set of 0..15;
var
  prime, odd: TDigits;
begin
  prime := [2, 3, 5, 7];
  odd := [1, 3, 5, 7, 9];

  both := prime * odd;          // 交集
  either := prime + odd;        // 并集
  diff := prime - odd;          // 差集
  Assert(either = [1..3, 5, 7, 9]);        // 字面量可混用子界
  Assert([3, 5] <= prime);      // 子集判断
  Assert(7 in prime);           // 成员判断——集合最高频用法
  Include(prime, 11);           // 比 prime := prime + [11] 高效
  Exclude(prime, 2);
end;
```

- 基类型必须**序数类型**且值域 ≤ 256 个值（`set of Byte` 是上限，`set of Integer` 非法）。
- `in` 的天然战场：`if ch in ['a'..'z', '_'] then ...`、`if key in [vkLeft..vkDown] then ...`。
- for-in 只迭代**存在的元素**（`[1,3,5]` 迭代 3 次）。
- 实现是位图：**SizeOf 按值域算**——实测 `set of 0..15` = 4 字节、`set of Byte` = 32 字节、
  FPC 对小值域按 32 位粒度向上取整（16 个值占 16 位但分配 4 字节）。

> 坑（实测）：`Include(s, 11)` 在 `set of 0..9` 上是**编译期**错误——
> `range check error while evaluating constants (11 must be between 0 and 9)`。
> 常量越界根本活不过编译。这不是刁难：越界常量百分百是 bug，编译器替你挡了。

## 6. 示例与验证

本章示例 `examples/06_arrays`：静态/动态数组语义对照、二维锯齿、参数回传、
集合全家桶 + 位图尺寸实测。

```powershell
pwsh -File build.ps1 -Example 06_arrays
```

## 7. 坑位清单（实测）

1. **动态数组赋值是共享不是拷贝**——改副本元素本体跟着变；要独立副本显式 `Move` 或 `SetLength` 后逐个拷。
2. `SetLength` 之外的"修改"（`b[i] := x`）不触发分离，直接改共享内存。
3. `[1..5]` 是集合构造器，不能传给开放数组参数（05 章坑的数组侧回响）。
4. 集合 SizeOf 按值域 32 位粒度分配：`set of 0..15` 是 4 字节不是 2。
5. 常量下标/元素越界在**编译期**报错（Include/set 字面量/静态数组常量初始化）。

---
上一章：[05 过程与函数](05-procedures.md) ｜ 下一章：[07 字符串与编码](07-strings.md) ｜ 返回：[README](../README.md)
