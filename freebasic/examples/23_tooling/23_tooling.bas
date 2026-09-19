' 23_tooling.bas —— 工具链与测试：编译期探测、自制测试框架、__FILE__、退出码协议
' 编译：fbc -w all -g -exx 23_tooling.bas -x 23_tooling.exe
' 本示例在两个验证层会打印不同的"形态"行——这正是编译期条件的价值。

' ---- 1) 编译期探测：你的代码知道自己是怎么编的 ----
#if __FB_DEBUG__
    Print "形态：断言层开启（-g，Assert 生效）"
#else
    Print "形态：发布（无断言开销）"
#endif
#ifdef __FB_64BIT__
    Print "目标：64 位"
#endif
Print "fbc 版本 = "; __FB_VER_MAJOR__; "."; __FB_VER_MINOR__; "."; __FB_VER_PATCH__
Print "本文件 = "; __FILE__

' ---- 2) 自制测试框架：30 行内搞定 ----
Dim Shared testCount As Integer = 0
Dim Shared failCount As Integer = 0

Sub check(actual As Integer, expected As Integer, label_ As String)
    testCount += 1
    If actual = expected Then
        Print "  PASS "; label_
    Else
        failCount += 1
        Print "  FAIL "; label_; "（期望 "; expected; " 实际 "; actual; "）"
    End If
End Sub

Sub checkStr(actual As String, expected As String, label_ As String)
    testCount += 1
    If actual = expected Then
        Print "  PASS "; label_
    Else
        failCount += 1
        Print "  FAIL "; label_; "（期望 ["; expected; "] 实际 ["; actual; "]）"
    End If
End Sub

' ---- 3) 被测对象：把前面各章的典型逻辑当靶子 ----
Function fib(n As Integer) As Integer
    If n <= 1 Then Return n
    Return fib(n - 1) + fib(n - 2)
End Function

Function clampi(v As Integer, lo As Integer, hi As Integer) As Integer
    If v < lo Then Return lo
    If v > hi Then Return hi
    Return v
End Function

Function rot13Char(c As Integer) As Integer
    If c >= Asc("a") AndAlso c <= Asc("z") Then Return Asc("a") + (c - Asc("a") + 13) Mod 26
    If c >= Asc("A") AndAlso c <= Asc("Z") Then Return Asc("A") + (c - Asc("A") + 13) Mod 26
    Return c
End Function

Function rot13(s As String) As String
    Var out_ = s
    For i As Integer = 1 To Len(s)
        Mid(out_, i, 1) = Chr(rot13Char(s[i - 1]))
    Next
    Return out_
End Function

Print "== 测试开始 =="
check(fib(10), 55, "fib(10)=55")
check(fib(0), 0, "fib(0)=0")
check(fib(1), 1, "fib(1)=1")
check(clampi(15, 0, 10), 10, "clamp 上界")
check(clampi(-5, 0, 10), 0, "clamp 下界")
check(clampi(5, 0, 10), 5, "clamp 区间内")
checkStr(rot13("hello"), "uryyb", "rot13 小写")
checkStr(rot13(rot13("Attack!")), "Attack!", "rot13 双向")
check(Len("你好"), 6, "UTF-8 字节数")
check(Cast(Integer, 3.5), 4, "Cast 银行家舍入")

' 确定性随机：种子固定 = 序列固定（17 章结论的回归测试）
Randomize 7
Var r1 = Int(Rnd * 100)
Randomize 7
Var r2 = Int(Rnd * 100)
check(r1 = r2, -1, "Randomize 种子确定性（-1 即真）")

Print "== 结果："; testCount; " 项，失败 "; failCount; " 项 =="
If failCount > 0 Then
    Print "存在失败用例，以非零码退出"
    End 1                             ' 退出码协议：失败 = 1
End If

Print "[OK] 23_tooling"
End 0
