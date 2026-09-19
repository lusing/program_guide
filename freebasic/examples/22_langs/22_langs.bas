' 22_langs.bas —— -lang fb 方言的现代特性清单（与 legacy_qb.bas 同场对照）
' 编译：fbc -w all -g -exx 22_langs.bas -x 22_langs.exe
' 对照通道：fbc -lang qb legacy_qb.bas（QB 方言：行号/Gosub/隐式变量）

' ---- 1) 块级作用域：每轮循环变量独立 ----
Dim snapshots(1 To 3) As Integer
For i As Integer = 1 To 3
    Dim blockVar As Integer = i * 10   ' 块内声明，块内生效
    snapshots(i) = blockVar
Next
Print "块作用域快照:"; snapshots(1); snapshots(2); snapshots(3)
Assert(snapshots(3) = 30)

' ---- 2) 短路逻辑是 fb 方言的关键字 ----
Function loud(n As Integer) As Integer
    Print "  loud("; n; ") 被调用"
    Return n
End Function
Print "AndAlso 短路（只应看到一次调用）:"
If (1 = 2) AndAlso (loud(99) > 0) Then
    Print "不可能到这里"
End If
Print "  （上面没有 loud 输出 = 短路生效）"

' ---- 3) 类型推断 Var 与显式 As ----
Var inferred = 3.5                     ' fb：推断 Double
Dim As Integer explicit_ = 42
Print "Var 推断 ="; inferred; "  显式 ="; explicit_
Assert(inferred = 3.5 And explicit_ = 42)

' ---- 4) 字符串比较区分大小写（qb 方言沿袭 QB 不区分）----
Print """A"" = ""a"" ->"; ("A" = "a"); "（fb 方言：false）"
Assert(("A" = "a") = False)

' ---- 5) 后缀变量名是非法的（qb 合法）----
' 以下写法在 -lang fb 编译错误（qb 方言合法）：
'   Dim a% : Dim s$ : Dim f!
' 全部要写 As 类型。

' ---- 6) Gosub/Goto/行号在 fb 方言全部编译错误 ----
'   Gosub label / On x Goto a, b / 10 PRINT "x"
' ——legacy_qb.bas 在 -lang qb 下演示这些。

Print "== 总结 =="
Print "-lang fb：块作用域 + 短路逻辑 + 强制显式类型 + 无行号/Gosub"
Print "老 QB 代码迁移路线：先 -lang qb 编过 → 逐步去掉行号/Gosub → 切 -lang fblite → 最终 -lang fb"

Print "[OK] 22_langs"
End 0
