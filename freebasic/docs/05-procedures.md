# 05 · 过程：Sub 与 Function

> 对应示例：`examples/05_procedures/`

## 5.1 默认传参规则：按类型分 ⭐

`-lang fb` 里不写 `ByVal`/`ByRef` 时的默认行为**取决于形参类型**（1.10.1 实测）：

| 形参类型 | 默认 | 后果 |
|---|---|---|
| 整数/浮点等**标量** | **ByVal**（传值） | 过程内改不动调用方的变量 |
| **String / UDT / 数组** | **ByRef**（传引用） | 过程内的修改**会**反映到调用方！ |

```freebasic
Sub mutate(x As Integer)          ' 标量默认 ByVal
    x += 100                      ' 只改了副本
End Sub
Sub mutateRef(ByRef x As Integer) ' 显式 ByRef
    x += 100                      ' 真的改了调用方
End Sub
Type Box : v As Integer : End Type
Sub touchBox(b As Box)            ' UDT 默认 ByRef
    b.v += 100                    ' 改得到！
End Sub
```

两个方向的坑都有：C 程序员以为标量会被改（不会）；写惯标量 ByVal 的人在 UDT/String 上顺手就改了调用方。**工程习惯：对会被修改的形参一律显式写 `ByRef`，其余写 `ByVal`**，不依赖默认。

## 5.2 Function、返回值与多返回值

```freebasic
Function divide(a As Double, b As Double, ByRef remainder As Double) As Double
    remainder = a - Fix(a / b) * b
    Return Fix(a / b)
End Function

Dim rem_ As Double
q = divide(17, 5, rem_)            ' 商 3 余 2
```

FB 没有元组，多返回值靠 **ByRef 出参**——这同时也是"返回数组"的标准方式，因为：

> **FB 函数不能返回数组**（1.10.1 实测：`As Integer()` 返回类型不存在，编译报错）。要"返回"数组就传一个数组形参进去 `Redim` 填充。

```freebasic
Sub makeRange(n As Integer, result() As Integer)
    Redim result(1 To n)
    For i As Integer = 1 To n : result(i) = i * i : Next
End Sub
```

## 5.3 默认参数值

```freebasic
Function greet(name_ As String = "world", punct As String = "!") As String
    Return "Hello, " & name_ & punct
End Function
greet()                 ' Hello, world!
greet("fbc", "?")       ' Hello, fbc?
```

默认值从右往左连续生效（跳过中间参数不行）。

## 5.4 递归与 Static 局部

```freebasic
Function fib(n As Integer) As Integer
    If n <= 1 Then Return n
    Return fib(n - 1) + fib(n - 2)
End Function

Function counter() As Integer
    Static calls As Integer = 0     ' 过程级静态：跨调用保值
    calls += 1
    Return calls
End Function
```

`Static` 只在首次执行时初始化；递归深时注意栈（默认 1MB，fib(25) 级别无压力）。

## 5.5 数组参数

```freebasic
Function sumArr(a() As Integer) As Integer
    Dim t As Integer = 0
    For i As Integer = LBound(a) To UBound(a)   ' 现场取界，不猜
        t += a(i)
    Next
    Return t
End Function

Dim nums(1 To 5) As Integer = {1, 2, 3, 4, 5}
sumArr(nums())                     ' 调用时带空括号
```

数组总是传描述符（引用语义）；`Redim` 形参数组对调用方同样生效。

## 5.6 提前退出与调用约定

- `Exit Sub` / `Exit Function` 立即退出。
- FB 默认调用约定是 `StdCall`（Windows API 同款）；对接 C 回调时过程要标 `Cdecl`（19/20 章细讲）。x86_64 Linux 只有单一调用约定，这些标注在 64 位 Linux 上无实际差别——但 `Cdecl` 标注依然保留（32 位平台上是必需的）。

## 5.7 坑位清单（1.10.1 实测）

1. **默认传参按类型分**：标量 ByVal、String/UDT/数组 ByRef——与 QB（一律 ByRef）和 C（一律 ByVal）都不同，别信老教程的"默认 ByRef"。
2. **函数不能返回数组**——用 ByRef 出参（或返回指向堆数组的指针+长度）。
3. 默认参数值只能从右往左连续省略。
4. `Static` 初始化只发生一次；多线程下非原子（19 章）。
5. 递归无尾调用优化，深度自担。
