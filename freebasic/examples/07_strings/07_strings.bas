' 07_strings.bas —— String/ZString/WString、内建函数、手写 Split/Replace、编码坑
' 编译：fbc -w all -g -exx 07_strings.bas -x 07_strings.exe

' ---- 1) 变长 String：描述符结构，Len 是字节数（UTF-8 字节直透） ----
Dim s As String = "Hello"
s &= ", FreeBASIC"
Print "s="; s; "  Len(s)="; Len(s); "  Sizeof(String)="; Sizeof(String)
Assert(Len(s) = 16)

Dim zh As String = "你好"          ' 无 BOM UTF-8 源码：字节透传
Print "zh Len="; Len(zh); "（UTF-8 字节数，不是字符数 2）"
Assert(Len(zh) = 6)

' ---- 2) 大小写敏感比较（QB 是不敏感的——迁移坑）----
Print """A"" = ""a"" ->"; ("A" = "a")
Assert(("A" = "a") = False)
Assert(UCase("aBc") = "ABC")

' ---- 3) 内建函数全家桶 ----
Dim t As String = "  FreeBASIC Tutorial  "
Print "Trim=["; Trim(t); "] LTrim=["; LTrim(t); "] RTrim=["; RTrim(t); "]"
Print "Left(4)="; Left(t, 6); "  Right(8)="; RTrim(Right(t, 9))
Print "Mid(11,8)="; Mid(Trim(t), 11, 8)
Print "InStr(Free)="; InStr(t, "Free"); "  InStrRev(a)="; InStrRev(t, "a")
Print "String(5,-)="; String(5, Asc("-")); "  Space(3)=["; Space(3); "]"
Print "Chr/Asc: "; Chr(66); "="; Asc("B")
Print "大小写: "; LCase("MiXeD"); " / "; UCase("MiXeD")
Assert(Trim(t) = "FreeBASIC Tutorial")
Assert(Mid(Trim(t), 11, 8) = "Tutorial")

' ---- 4) 手写 Split（FB 无内建 Split/Replace/Join）----
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

Dim parts() As String
Split("apple,banana,cherry", ",", parts())
Print "Split 得到"; UBound(parts) + 1; " 段: "; parts(0); "/"; parts(1); "/"; parts(2)
Assert(parts(0) = "apple" And parts(2) = "cherry")

Print "ReplaceAll="; ReplaceAll("a-b-c", "-", "+")
Assert(ReplaceAll("a-b-c", "-", "+") = "a+b+c")

' ---- 5) 定长 String 与 ZString（C 字符串）----
Dim fixed_ As String * 10 = "abc"    ' 右侧补空格到 10
Print "定长 Len="; Len(fixed_); "（补齐到声明长度）"
Assert(Len(fixed_) = 10)

Dim z As ZString * 10 = "abc"        ' NUL 结尾的 C 字符串
Print "ZString Len="; Len(z); " Sizeof 缓冲="; Sizeof(z)
Assert(Len(z) = 3 And Sizeof(z) = 10)

' ---- 6) WString：Windows 上是 UTF-16；中文字面量坑见下 ----
Dim ws As WString * 10 = "abc"       ' ASCII 字面量没问题
Print "WString Len(abc)="; Len(ws); "（UTF-16 码元数）"
Assert(Len(ws) = 3)
' 中文宽字符串：无 BOM 源码的字面量会被按 GBK 误解（见下坑位）——用 WChr 拼码位才可靠
Dim zh_w As WString * 10 = WChr(&h4F60) & WChr(&h597D)   ' "你好" 的码位
Print "WChr 拼的中文宽串 Len="; Len(zh_w)
Assert(Len(zh_w) = 2)

Print "[OK] 07_strings"
End 0
