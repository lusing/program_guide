# 08 · 用户定义类型：Type / Union / Enum

> 对应示例：`examples/08_udt/`

## 8.1 Type：FB 的结构体

```freebasic
Type Point2D
    x As Double
    y As Double
End Type

Dim p As Point2D = Type(3, 4)      ' Type() 初始化器，按字段顺序
```

- `-lang fb` 下 `Dim` 局部变量与 UDT 字段**默认清零**（实测：标量 0、字符串空、UDT 字段全 0，`-lang qb` 下亦然）——与 C 的"局部变量是垃圾值"直觉不同，不必为初始化焦虑。
- 字段可以有**默认值**：`total As Integer = 0`（初始化器未覆盖到的字段使用字段默认值）。

## 8.2 With 块

```freebasic
With p
    .x = .x * 2
    .y = .y * 2
End With
```

连续操作同一 UDT 时少打字；`.字段` 语法强制归属，可读性好。

## 8.3 嵌套与 Type() 的边界

```freebasic
Type LineSeg
    a As Point2D
    b As Point2D
End Type

Dim seg As LineSeg                 ' Type() 不能嵌套 Type()（1.10.1 实测编译错误）
seg.a = Type(0, 0)                 ' 分步初始化
seg.b = Type(3, 4)
```

嵌套初始化器写不了，就分步赋值——一行一个 `Type(...)` 是合法的。

## 8.4 Union：一段内存，多种解读

```freebasic
Union Value32
    i As ULong
    bytes(0 To 3) As UByte
End Union

Dim u As Value32
u.i = &h41424344
Print Hex(u.bytes(0))              ' 44（x86 小端：最低位字节在前）
```

诊断二进制格式、复用缓冲区的老工具。写进去的是哪个成员、读出来的是哪个成员，全靠你自己记账。

## 8.5 Enum

```freebasic
Enum Color
    Red                             ' 0
    Green                           ' 1
    Blue                            ' 2
End Enum

Enum Weekday
    Mon = 1                         ' 显式起点
    Tue                             ' 2（顺延）
    Sun = 7                         ' 可跳跃
End Enum
```

`Enum` 成员本质是 `Integer` 常量，`Select Case` 直接配合使用。FB 不做"枚举类型安全"检查——把 `Tue` 赋给 `Color` 变量照样编译通过。

## 8.6 别名与数组化

```freebasic
Type Pt As Point2D                  ' 类型别名
Dim pts(1 To 3) As Point2D = { Type(1, 2), Type(3, 4), Type(5, 6) }
```

## 8.7 Type 的下一步

Type 还能长出**方法、构造器、属性、继承**——那是 12/13 章 OOP 的地盘。本章只谈"数据载体"用法；两章世界观完全兼容。

## 8.8 坑位清单（1.10.1 实测）

1. **`Type()` 初始化器不能嵌套**：`Type(Type(0,0), ...)` 编译错误——分步赋值。
2. `Dim` 局部变量/UDT 字段**默认清零**（实测，两种方言皆然）——别拿 C 的垃圾值直觉写防御代码。
3. Union 成员共享内存，`Sizeof` 取最大成员；小端序字节序按 x86-64 是低位在前。
4. Enum 无类型安全，成员可显式赋值并可跳跃。
5. UDT 传参默认 **ByRef**（05 章规则）——过程里改字段会动到调用方。
