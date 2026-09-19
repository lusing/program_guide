# 06 · 数组

> 对应示例：`examples/06_arrays/`

## 6.1 声明：固定数组，下界自己定

```freebasic
Dim v(1 To 5) As Integer = {10, 20, 30, 40, 50}   ' 下界自选 + 初始化器
Dim w(3) As Integer                               ' 省略下界 = 0 To 3
LBound(w) : UBound(w)                             ' 0  3
```

- 下标范围由声明决定，不像 C 永远从 0 开始；跨过程传数组时用 `LBound/UBound` 现场取界。
- 固定数组可以放进 UDT 当字段（编译期尺寸固定）。

## 6.2 动态数组：Redim 与 Preserve ⭐

```freebasic
Redim d(1 To 3) As Integer          ' 动态数组必须用 Redim（或 Dim ...() ）声明
Redim Preserve d(1 To 5)            ' 扩容且保留旧值（缩容同理）
```

**大坑**：`Dim d(1 To 3)` 出来的固定数组不能再 `Redim`——编译器报 "Expected var-len array"。要可变尺寸，一开始就用 `Redim`（或 `Dim d() As Integer` 先声明空动态数组）。

多维动态数组 `Preserve` 时**只能改最后一维**：

```freebasic
Redim m(1 To 2, 1 To 2) As Integer
Redim Preserve m(1 To 2, 1 To 4)    ' 合法：加列
'Redim Preserve m(1 To 4, 1 To 2)   ' 运行时错误：不能改第一维
```

## 6.3 Erase 的双重人格

```freebasic
Erase w        ' 固定数组：全部清零
Erase d        ' 动态数组：释放内存（之后可再 Redim）
```

## 6.4 数组与过程

数组参数传描述符（引用语义），上一章 5.5 已示。函数不能返回数组（用出参）。

## 6.5 初始化器速查

```freebasic
Dim a(1 To 3) As Integer = {1, 2, 3}
Dim m(1 To 2, 1 To 2) As Integer = {{1, 2}, {3, 4}}
Dim pts(1 To 2) As Point2D = { Type(1, 2), Type(3, 4) }   ' UDT 数组
```

多维初始化器按行嵌套花括号。

## 6.6 没有 For Each

FB 1.10 没有 `For Each` 语法（没有迭代器协议）。遍历就是 `For i = LBound(a) To UBound(a)`——顺手把界写对，别硬编码。

## 6.7 坑位清单（1.10.1 实测）

1. 固定数组（`Dim` 带界）不能 `Redim`——动态数组必须 `Redim` 声明起步。
2. `Redim Preserve` 多维时只能扩最后一维。
3. `Erase` 对固定数组是清零、对动态数组是释放——同一关键字两副面孔。
4. 下界不一定是 0：过程内遍历别人传来的数组必须 `LBound/UBound`。
5. `-exx` 会检查数组越界（退出码 = 错误号），但没有 `-exx` 时越界是未定义行为。
