' 15_errors.bas —— 错误处理：返回码模式、TryParse、Err、Assert 防线
' 编译：fbc -w all -g -exx 15_errors.bas -x 15_errors.exe

' ---- 1) 文件打开的返回码检查（FB 现代正解）----
' Open 本身返回错误码：0 = 成功，2 = 文件不存在（实测）
Function openOrCreate(path As String, mode_ As String, ByRef h As Integer) As Integer
    h = FreeFile()
    If mode_ = "input" Then
        Return Open(path For Input As #h)
    Else
        Return Open(path For Output As #h)
    End If
End Function

' ---- 2) TryParse 模式：状态 + ByRef 出参 ----
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

' ---- 3) 业务错误码：枚举 + 分层上报 ----
Enum ParseStatus
    PARSE_OK = 0
    PARSE_EMPTY = 100
    PARSE_BADCHAR = 101
End Enum

Function classify(s As String) As ParseStatus
    If Len(s) = 0 Then Return PARSE_EMPTY
    For i As Integer = 1 To Len(s)
        Var c = s[i - 1]
        If c < Asc("0") OrElse c > Asc("9") Then Return PARSE_BADCHAR
    Next
    Return PARSE_OK
End Function

' ================= 验证 =================
Print "== 文件错误码 =="
Dim As Integer h
Var rc = openOrCreate("nonexistent_zzz.txt", "input", h)
Print "打开不存在的文件 -> 返回码 "; rc
Assert(rc = 2)                       ' 实测：2 = File not found

rc = openOrCreate("err_demo_tmp.txt", "output", h)
Print "打开可写文件 -> 返回码 "; rc
Assert(rc = 0)
Print #h, "临时内容"
Close #h
Kill "err_demo_tmp.txt"              ' 自清场

Print "== TryParse =="
Dim outv As Integer
Print """42"" ->"; tryParseInt("42", outv); " 值="; outv
Assert(tryParseInt("42", outv) And outv = 42)
Print """-17"" ->"; tryParseInt("-17", outv); " 值="; outv
Assert(outv = -17)
Print """4x2"" ->"; tryParseInt("4x2", outv)
Assert(tryParseInt("4x2", outv) = False)
Print """"" ->"; tryParseInt("", outv)
Assert(tryParseInt("", outv) = False)
Print """+9"" ->"; tryParseInt("+9", outv); " 值="; outv
Assert(outv = 9)

Print "== 错误码分类 =="
Print "classify(""123"") ="; classify("123")
Print "classify(""a1"") ="; classify("a1")
Print "classify("""") = "; classify("")
Assert(classify("123") = PARSE_OK)
Assert(classify("a1") = PARSE_BADCHAR)
Assert(classify("") = PARSE_EMPTY)

' Err：仅在 -e/-ex/-exx 运行时检查触发时才有值；常规路径恒 0（实测）
Print "Err ="; Err
Assert(Err = 0)

Print "[OK] 15_errors"
End 0
