# 03 · 类型与变量

> 对应示例：`examples/03_types/`

## 3.1 内建类型尺寸表（win64 / linux-x86_64 双平台实测）⭐

| 类型 | 字节 | 范围/说明 |
|---|---|---|
| `Byte` / `UByte` | 1 | 有符号/无符号 8 位 |
| `Short` / `UShort` | 2 | 16 位 |
| **`Integer` / `UInteger`** | **8** | **指针宽度**——win64/linux-x86_64 都是 8，win32/x86 上是 4！ |
| `Long` / `ULong` | 4 | 恒 32 位（两平台实测一致；⚠ 但 C 的 `long` 在 linux-x86_64 是 8，见下） |
| `LongInt` / `ULongInt` | 8 | 恒 64 位 |
| `Single` | 4 | 单精度浮点 |
| `Double` | 8 | 双精度浮点 |
| `Any Ptr` | 8 | 指针 |
| `String` | 24 | 变长字符串**描述符**的尺寸（数据另算，07 章） |
| `Boolean` | 1 | 真 = **-1**（QB 血统），假 = 0 |

**最大的坑**：`Integer` 是"指针宽"类型，跨平台变化；`Long` 在 FB 里恒 4 字节（与 C 的 `long` 在 Windows 上一致，但和很多人"long = 64 位"的直觉相反）。要恒定宽度用 `LongInt`；对接 C API 时按 `windows.bi`/`crt` 头里的类型映射抄（20 章）。**⚠ Linux 例外**：linux-x86_64 上 C 的 `long` 是 8 字节，FB `Long`（4）对不上——C 接口里的 `long` 要映射 `LongInt` 或 `crt` 头的 `clong`（该类型随平台伸缩：win64=4、linux-x86_64=8，1.10.2 实测）。

## 3.2 声明：Dim、Var、Const

```freebasic
Dim a As Integer = 10, b As Double = 2.5   ' 一行多声明
Var y = 3.14159                            ' 类型推断：Double
Var s = "推断成 String"
Const PI As Double = 3.14159265358979      ' 编译期常量
Const GREETING = "hello"                   ' Const 可省略 As（自动推断）
```

- **`Dim x = 7`（无 `As`）在 `-lang fb` 是编译错误**——默认类型只属于 `-lang qb/fblite`。要推断用 `Var`。
- `Var` 必须带初始化式，类型在编译期定死，不是动态类型。
- `Static` 局部变量跨调用保值；`Dim Shared` 声明模块级全局（过程内可见）。

## 3.3 Boolean 的两面

```freebasic
Dim flag As Boolean = True
Print flag          ' 输出 true（Print 对 Boolean 特殊格式化）
Assert(flag = -1)   ' 底层值确实是 -1，不是 1！
```

位运算 `And/Or/Xor/Not` 直接作用其上（`Not True = 0`）。习惯 C 的 `1` 当真值会踩坑：`If 2 Then` 合法（非零即真），但 `True = 1` 是**假**。

## 3.4 字面量

```freebasic
&hFF        ' 十六进制 255
&o377       ' 八进制 255
&b1010      ' 二进制 10
1.5         ' 小数字面量默认 Double
```

QB 时代的变量后缀（`x%`、`s$`）在 `-lang fb` 禁用（22 章）。字符串内的引号用**双写**转义：`"He said ""hi"""`——没有反斜杠转义。

## 3.5 数值转换：Cast 是舍入不是截断 ⭐

```freebasic
Cast(Integer, 2.5)   ' = 2   银行家舍入（half-to-even）
Cast(Integer, 3.5)   ' = 4
Cast(Integer, -3.5)  ' = -4
Fix(3.7)             ' = 3   向零截断
Int(-3.7)            ' = -4  向下取整（地板）
```

从 C 过来的几乎必踩：`Cast(Integer, x)` 默认四舍五入，想截断用 `Fix()`（向零）/`Int()`（向下）。字符串数字互转：

```freebasic
Val("3.5")       ' = 3.5   字符串转数（还有 ValInt/ValLng/ValUInt 变体）
Str(-5)          ' = "-5"  数转字符串；正数无前导空格（与 QB 的 Str 不同！）
```

## 3.6 溢出：编译器不管你

```freebasic
Dim ub As UByte = 255
ub += 1          ' 回绕成 0，无警告无运行时错误
```

`-exx` 只检查**数组边界和空指针**，不查算术溢出——unsigned 回绕、有符号溢出都是静默的。要安全就自己在关键处断言。

## 3.7 坑位清单（1.10.1 实测）

1. `Integer` win64 = 8 字节；`Long` 恒 4。从 C 抄类型映射时逐个核对。
2. `Cast` 转整数是**银行家舍入**；截断用 `Fix`/`Int`。
3. `True` = -1；`Print` 布尔显示 `true/false` 但底层是 -1/0。
4. `Dim x = 7` 无 `As` 在 `-lang fb` 编译不过——用 `Var` 或写全类型。
5. `Str()` 正数**无**前导空格（QB 有）；`Print` 打印非负有符号数会补一个前导空格（符号位），**无符号类型不补**——`Print "="; ubyte值` 出来是 `=0`。
6. 字符串引号转义是 `""` 双写，反斜杠 `\` 无特殊含义。
7. `Const` 可省 `As` 自动推断，`Dim` 不行。
