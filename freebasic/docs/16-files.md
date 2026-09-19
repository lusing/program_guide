# 16 · 文件 IO

> 对应示例：`examples/16_files/`

## 16.1 文件号与 FreeFile

```freebasic
Dim As Integer h = FreeFile()      ' 拿一个空闲文件号
Open "a.txt" For Output As #h
...
Close #h
```

`FreeFile()` 从 1 起找空闲号；小脚本直接 `Open ... As #1` 也行，但函数里一律 `FreeFile`。

## 16.2 顺序文本：Output / Input / Append

```freebasic
Open "notes.txt" For Output As #h      ' 覆盖写
Print #h, "第一行"                      ' Print # 语法：写一行带换行
Print #h, "数字也行:"; 42
Print #h, Using "pi=##.##"; 3.14159    ' Using 模板原样可用
Close #h

Open "notes.txt" For Input As #h
Do Until Eof(h)
    Line Input #h, line_               ' 整行读（含空格）
Loop
Close #h

Open "notes.txt" For Append As #h      ' 追加写
```

`Input #h, a, b` 按逗号分段读（QB 风格，老 CSV）；现代文本处理用 `Line Input` + 07 章的手写 `Split`。

## 16.3 二进制：Put / Get 任意类型

```freebasic
Type PointRec : x As Double : y As Double : End Type

Open "pts.bin" For Binary As #h
Put #h, , Type<PointRec>(1, 1)         ' 省略位置 = 顺序写
Put #h, , Type<PointRec>(2, 4)
Close #h

Open "pts.bin" For Binary As #h
Print LOF(h)                           ' 文件字节数（LOF 收文件号！）
Seek #h, Sizeof(PointRec) + 1          ' 跳到第 2 条：字节偏移从 1 计
Get #h, , pr                           ' 顺序读当前位置
Close #h
```

`Type<PointRec>(...)` 是 `Type()` 初始化器的尖括号显式类型写法（嵌套/歧义时用）。

## 16.4 随机文件：按记录号直存直取

```freebasic
Type Employee
    id As Integer
    name_ As String * 12               ' 定长字段是随机记录的关键
    score As Double
End Type

Open "emp.dat" For Random As #h Len = Sizeof(Employee)
Put #h, 2, Type<Employee>(8, "bob", 75.25)    ' 直接写 2 号记录
Get #h, 2, emp                                  ' 按号读
Print RTrim(emp.name_)                          ' 定长串右边补的空格要 Trim
Close #h
```

记录号从 **1** 计（QB 传统）。这是 FB 的"内置数据库"——定长记录 + 记录号寻址，做小型数据文件极顺手。

## 16.5 特殊设备：Open Cons / Open Err / Open Scr

```freebasic
Open Cons For Output As #h     ' 标准输出
Print #h, "..."                ' gfx 模式下 Print 进图形窗，Open Cons 才到控制台（18 章）
Close #h
' Open Err  → 标准错误（调试信息）
' Open Scr  → 屏幕
```

## 16.6 文件系统杂项

| 函数 | 作用 |
|---|---|
| `Kill "x.txt"` | 删文件 |
| `Dir("*.txt")` / `Dir()` | 匹配遍历（21 章） |
| `LOF(h)` / `Lof` | 文件长度（收**文件号**） |
| `Eof(h)` / `Seek #h, n` | 尾判定 / 定位 |
| `FileAttr` / `FileDateTime` / `FileLen("路径")` | 属性（后者收文件名） |

## 16.7 坑位清单（1.10.1 实测）

1. **`LOF(h)` 收文件号**，`FileLen("路径")` 才收文件名——混用直接 type mismatch。
2. 二进制 `Seek` 字节偏移**从 1 计**；随机模式记录号也从 1 计。
3. `Put/Get` 里的 `String * N` 定长字段：读出来右边带补位空格，用前 `RTrim`。
4. 常量名撞内建函数：`Const BIN = ...` 撞 `Bin()`（二进制串函数）直接"Duplicated definition"——`HEX/OCT/VAL/STR` 同理小心。
5. `Print Using` 的 `_` 是"下一字符字面量"转义，不是空格（QB 语义）。
6. 示例跑完要 `Kill` 自产文件——仓库干净，验证可重复。
