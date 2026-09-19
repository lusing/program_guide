' 04_control.bas —— 运算符与控制流：短路逻辑、Select Case、循环、Iif 双求值坑
' 编译：fbc -w all -exx 04_control.bas -x 04_control.exe

' ---- 1) AndAlso/OrElse 短路 vs And/Or 非短路 ----
Function check(n As Integer, tag As String) As Boolean
    Print "    check(" ; tag; ") 被调用"
    Return (n > 0)
End Function

Print "== And（两边都算）=="
If check(-1, "左") And check(1, "右") Then Print "真" Else Print "假"
Print "== AndAlso（左边假即短路）=="
If check(-1, "左") AndAlso check(1, "右-不应出现") Then Print "真" Else Print "假"

Print "== 位运算 And/Or/Xor/Shl/Shr =="
Print "12 And 10 ="; 12 And 10; "  12 Or 10 ="; 12 Or 10; "  12 Xor 10 ="; 12 Xor 10
Print "1 Shl 8 ="; 1 Shl 8; "  256 Shr 4 ="; 256 Shr 4
Print "Not 0 ="; Not 0

' ---- 2) If / ElseIf / 单行 If ----
Dim score As Integer = 85
If score >= 90 Then
    Print "优秀"
ElseIf score >= 80 Then
    Print "良好（命中这里）"
Else
    Print "一般"
End If
If score > 0 Then Print "单行 If 也合法"

' ---- 3) Select Case：数值、范围 To、关系 Is、字符串 ----
Dim n As Integer = 7
Select Case n
Case 1, 3, 5, 7, 9
    Print "个位奇数"
Case 2 To 8
    Print "2..8 之间（不会到这，上面先命中）"
Case Is > 100
    Print "很大"
Case Else
    Print "其他"
End Select

Dim fruit As String = "apple"
Select Case fruit
Case "apple", "banana"
    Print "水果命中"
Case Else
    Print "不是目标水果"
End Select

' ---- 4) 循环全家桶 ----
Print "== For Step 负数 =="
For i As Integer = 5 To 1 Step -2
    Print "  i="; i
Next

Print "== Do While / Do Until / While Wend =="
Dim k As Integer = 0
Do While k < 3 : k += 1 : Loop
Print "  Do While 后 k="; k
Do : k -= 1 : Loop Until k = 0
Print "  Do Until 后 k="; k
While k < 2 : k += 1 : Wend
Print "  While Wend 后 k="; k
Assert(k = 2)

Print "== Continue / Exit =="
For i As Integer = 1 To 10
    If (i Mod 2) = 0 Then Continue For       ' 跳过偶数
    If i > 6 Then Exit For                    ' 到 7 就退出
    Print "  奇数:"; i
Next

' ---- 5) Iif：1.10.1 实测只求值选中的分支（老教程说双求值，已过时）----
Function loud(n As Integer) As Integer
    Print "    loud("; n; ") 被调用"
    Return n * 100
End Function
Print "Iif(1=1, loud(1), loud(2)) ="; Iif(1 = 1, loud(1), loud(2))   ' 只会看到 loud(1)

' ---- 6) 整除、取余、乘方 ----
Print "7 \ 2 ="; 7 \ 2; "  -7 \ 2 ="; -7 \ 2; "  7 Mod 3 ="; 7 Mod 3
Print "2 ^ 0.5 ="; 2 ^ 0.5; "  2 ^ 10 ="; 2 ^ 10
Assert((7 \ 2) = 3)
Assert((2 ^ 10) = 1024)

Print "[OK] 04_control"
End 0
