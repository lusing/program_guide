# 07 · 字符串

> 对应示例：`examples/07_strings/`

## 7.1 三种字符串

| 类型 | 形态 | `Len` 返回 | 典型用途 |
|---|---|---|---|
| **`String`** | 变长，24 字节描述符 + 堆数据 | **字节数** | 日常 99% 的场景 |
| `String * N` | 定长 N 字节，右侧补空格 | 恒 N | 随机文件记录（16 章） |
| **`ZString * N`** | NUL 结尾（C 字符串），缓冲 N 字节 | 有效字符数 | 对接 C API（20 章） |
| **`WString * N`** | 宽字符，Windows 上 = **UTF-16** | 码元数 | 对接 Win32 W 系列 API |

```freebasic
Dim s As String = "你好"        ' Len = 6：UTF-8 字节数，不是字符数！
Dim z As ZString * 10 = "abc"   ' Len = 3，Sizeof(z) = 10（缓冲尺寸）
Dim ws As WString * 10 = "abc"  ' Len = 3（UTF-16 码元）
```

## 7.2 编码坑位（本机实测，重要）⭐

教程全线 **UTF-8 无 BOM 源码 + `chcp 65001` 控制台**。在此纪律下：

1. `String` 字面量**按字节透传**：中文 `Print` 输出正确，`Len` 是 UTF-8 字节数。想按"字符数"统计得自己按 UTF-8 解码（或保持 ASCII 假设）。
2. **`WString` 中文字面量不可用**：无 BOM 源码会被 fbc 按系统 GBK 解释——`"你好"` 变成 3 个乱码码元。宽串用 **`WChr`** 拼码位：
   ```freebasic
   Dim zh As WString * 10 = WChr(&h4F60) & WChr(&h597D)   ' "你好"，Len = 2
   ```
   （VB 的 `ChrW` 在 FB 里叫 `WChr`。）
3. 若源码**带 BOM**，fbc 走另一条路：`String` 字面量被转成系统 GBK、输出走宽字符 API——管道验证全乱（02 章实测）。别带 BOM。

## 7.3 内建函数全家桶

```freebasic
Left(s, n) / Right(s, n) / Mid(s, start, len)     ' 注意下标从 1 起
InStr(s, "sub") / InStrRev(s, "sub")              ' 查找，找不到 0
Trim / LTrim / RTrim                              ' 去空白
UCase / LCase                                     ' 大小写
String(n, Asc("-"))                               ' 重复字符（第二参是字符码）
Space(n) / Chr(code) / Asc(ch)
```

## 7.4 比较是大小写敏感的

```freebasic
("A" = "a")        ' 假（0）
```

QB 老玩家注意：QBasic 的字符串比较**不区分大小写**，FB 是区分的。要模糊比较先 `UCase` 两边。

## 7.5 没有内建 Split/Replace/Join ⭐

FB 标准库没有这三个现代标配（1.10.1 实测：未声明符号）。手写并不难，也是练 `InStr/Mid/Redim Preserve` 的好题目：

```freebasic
Sub Split(text_ As String, delim As String, result() As String)
    Dim count As Integer = -1
    Dim start_ As Integer = 1
    Do
        Var p = InStr(start_, text_, delim)
        If p = 0 Then Exit Do
        count += 1
        Redim Preserve result(0 To count)
        result(count) = Mid(text_, start_, p - start_)
        start_ = p + Len(delim)
    Loop
    count += 1
    Redim Preserve result(0 To count)
    result(count) = Mid(text_, start_)
End Sub

Function ReplaceAll(s As String, find_ As String, repl As String) As String
    Dim out_ As String = ""
    Dim last As Integer = 1
    Do
        Var p = InStr(last, s, find_)
        If p = 0 Then Exit Do
        out_ &= Mid(s, last, p - last) & repl
        last = p + Len(find_)
    Loop
    Return out_ & Mid(s, last)
End Function
```

复杂文本处理别在 FB 里硬写——正则可以经 C 互操作挂 PCRE（20 章思路），或干脆换宿主语言。

## 7.6 拼接与性能

`&` 与 `+` 都能拼接字符串（`+` 两边必须都是字符串）。循环里大量 `s &= x` 会反复重分配——FB 运行时对 `&=` 有一定优化，但巨量拼接时先算总长、`String(total, 0)` 预分配再 `Mid(s, pos, n) = ...` 填充更稳。

## 7.7 坑位清单（1.10.1 实测）

1. `Len(String)` = **UTF-8 字节数**（无 BOM 纪律下），不是字符数。
2. `WString` 中文字面量在无 BOM 源码里按 GBK 误解——用 `WChr` 拼码位。
3. `ChrW` 不存在，叫 `WChr`；`Chr` 收字符码。
4. 字符串比较**区分大小写**（QB 不区分——迁移注意）。
5. 无内建 `Split/Replace/Join`——手写（本章有现成实现）。
6. `Mid/InStr` 下标**从 1 起**，不是 0。
7. `String * N` 定长串的 `Len` 恒等于 N（右侧空格补齐），要"有效长度"自己 RTrim。
