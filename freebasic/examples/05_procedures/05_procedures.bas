' 05_procedures.bas —— Sub/Function：ByRef 默认（大坑）、Optional、递归、Static、数组参数
' 编译：fbc -w all -exx 05_procedures.bas -x 05_procedures.exe

' ---- 1) 默认传参规则（-lang fb 实测）：标量 ByVal，String/UDT/数组 ByRef ----
Sub mutate(x As Integer)            ' 标量默认 ByVal：改不到调用方
    x += 100
End Sub
Sub mutateRef(ByRef x As Integer)   ' 显式 ByRef 才是引用
    x += 100
End Sub
Type Box
    v As Integer
End Type
Sub touchBox(b As Box)              ' UDT 默认 ByRef：改得到！
    b.v += 100
End Sub
Sub touchStr(s As String)           ' String 默认 ByRef：改得到！
    s &= "!"
End Sub

' ---- 2) Function 与多返回值（ByRef 出参）----
Function divide(a As Double, b As Double, ByRef remainder As Double) As Double
    remainder = a - Fix(a / b) * b
    Return Fix(a / b)
End Function

' ---- 3) 默认参数值与 Optional ----
Function greet(name_ As String = "world", punct As String = "!") As String
    Return "Hello, " & name_ & punct
End Function

' ---- 4) 递归 ----
Function fib(n As Integer) As Integer
    If n <= 1 Then Return n
    Return fib(n - 1) + fib(n - 2)
End Function

' ---- 5) Static 局部变量：跨调用保值 ----
Function counter() As Integer
    Static calls As Integer = 0
    calls += 1
    Return calls
End Function

' ---- 6) 数组参数：传描述符，LBound/UBound 现场取 ----
Function sumArr(a() As Integer) As Integer
    Dim t As Integer = 0
    For i As Integer = LBound(a) To UBound(a)
        t += a(i)
    Next
    Return t
End Function

' ---- 7) FB 函数不能返回数组（1.10.1 实测）：用 ByRef 出参 ----
Sub makeRange(n As Integer, result() As Integer)
    Redim result(1 To n)
    For i As Integer = 1 To n
        result(i) = i * i
    Next
End Sub

' ================= 验证 =================
Dim v As Integer = 5
mutate v
Print "mutate 后 v="; v
Assert(v = 5)                       ' 标量默认 ByVal：没被改
mutateRef v
Print "mutateRef 后 v="; v
Assert(v = 105)                     ' 显式 ByRef：被改了

Dim box As Box : box.v = 1
touchBox box
Print "touchBox 后 box.v="; box.v
Assert(box.v = 101)                 ' UDT 默认 ByRef
Dim msg As String = "hi"
touchStr msg
Print "touchStr 后 msg="; msg
Assert(msg = "hi!")                 ' String 默认 ByRef

Dim rem_ As Double
Dim q As Double = divide(17, 5, rem_)
Print "17/5 -> 商"; q; " 余 "; rem_
Assert(q = 3 And rem_ = 2)

Print greet()                        ' 默认参数
Print greet("fbc", "?")
Assert(greet() = "Hello, world!")

Print "fib(10)="; fib(10)
Assert(fib(10) = 55)

counter() : counter()
Print "counter 第三次调用="; counter()
Assert(counter() = 4)                ' 上行已算第四次

Dim nums(1 To 5) As Integer = {1, 2, 3, 4, 5}
Print "sumArr="; sumArr(nums())
Assert(sumArr(nums()) = 15)

Dim squares() As Integer
makeRange 4, squares()
Print "squares:"; squares(1); squares(2); squares(3); squares(4)
Assert(squares(4) = 16)

Print "[OK] 05_procedures"
End 0
