# 15 · 错误处理

> 对应示例：`examples/15_errors/`

## 15.1 FB 错误处理的三层现实

| 层 | 机制 | 状态 |
|---|---|---|
| **返回码** | 函数返回错误码/布尔 + `ByRef` 出参 | **现代正解**，本章主线 |
| `Err` | 运行时错误编号 | 仅在 `-e/-ex/-exx` 检查触发的运行时错误时有值，常规路径恒 0（实测） |
| `On Error Goto` | QB 式错误陷阱 | `-lang fb` 下半残：**捕不到文件打开失败**，`Resume Next` 直接编译错误（仅 `-lang qb/fblite/deprecated`） |

## 15.2 返回码模式（正解）

FB 的 `Open` **本身返回错误码**——0 成功，2 文件不存在（实测）：

```freebasic
Dim As Integer h = FreeFile()
Var rc = Open("data.txt" For Input As #h)
If rc <> 0 Then
    Print "打不开文件，错误码 "; rc
    End rc
End If
```

别等 `Err`——文件打开失败时它还是 0。所有 FB 运行库函数都是这个哲学：**自己检查返回值**。

## 15.3 TryParse 模式

```freebasic
Function tryParseInt(s As String, ByRef outv As Integer) As Boolean
    If Len(s) = 0 Then Return False
    Var start_ = 1
    If s[0] = Asc("-") OrElse s[0] = Asc("+") Then start_ = 2
    If start_ > Len(s) Then Return False
    For i As Integer = start_ To Len(s)
        Var c = s[i - 1]
        If c < Asc("0") OrElse c > Asc("9") Then Return False
    Next
    outv = ValInt(s)
    Return True
End Function
```

"状态 + 出参"是 FB 版的 `(value, err)` 二元组。业务错误用 `Enum` 编码错误码，逐层上报。

## 15.4 Assert：你的防线（由 -g 激活）⭐

```freebasic
Assert(v = 105)
```

**1.10.1 实测：`Assert`/`AssertWarn` 由 `-g` 激活**——`-e`/`-ex`/`-exx` 都不会激活（与多数老文档相反）。激活后断言失败打印 `文件(行): assertion failed` 并以退出码 1 结束；未激活时 `Assert` 整句被编译掉。本教程把 `Assert` 当"可执行的文档"用：示例里每个关键计算后面跟一条，`-g -exx` 层负责真的去撞。

```bash
fbc -w all -g -exx app.bas -x app.exe    # 断言 + 数组边界 + 空指针检查，全开
```

## 15.5 运行时检查（-exx 层）

| 检查 | 触发 | 表现 |
|---|---|---|
| 数组越界 | `a(999)` 越界 | `Aborting due to runtime error 6 (out of bounds array access)`，退出码 = 错误号 |
| 空指针 | `*p` 且 p=0 | 同上机制 |
| 算术溢出 | `255+1` 回绕 | **不查**——静默回绕 |

## 15.6 该选什么

- **可预期的失败**（文件、输入、找不到）：返回码/出参，调用方处理。
- **程序员的错**（不变量被破坏）：`Assert`，`-g` 编译时炸给你看。
- **内存罪行**：`-exx` 运行时捕获。
- QB 式 `On Error`：留给它应有的历史地位——别在新代码里用。

## 15.7 坑位清单（1.10.1 实测）

1. `Open` 失败时 `Err` 仍为 0——查 `Open` 的**返回值**。
2. `Assert` 由 **`-g`** 激活；`-e/-ex/-exx` 不会激活（与老文档相反）。
3. `Resume Next` 在 `-lang fb` 编译错误（仅 qb/fblite/deprecated）。
4. 断言失败退出码 1；`-exx` 越界/空指针退出码 = 错误号（如 6）——脚本判定用退出码非零即可。
5. `Assert(cond)` 只收一个参数，不能像 C 那样带消息字符串。
