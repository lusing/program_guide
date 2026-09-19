' 14_operators.bas —— 运算符重载：成员/全局 Operator、Cast、复合赋值必须成员、迭代运算符
' 编译：fbc -w all -g -exx 14_operators.bas -x 14_operators.exe

#Include Once "vbcompat.bi"          ' Format()

' ---- Vec：二维向量，配上全套运算符 ----
Type Vec
    Dim As Double x, y
    Declare Constructor(x As Double = 0, y As Double = 0)

    ' Cast：让 Vec 能直接参与字符串拼接/打印
    Declare Operator Cast() As String

    ' 复合赋值运算符（+=、*= 等）必须是成员（实测全局版报 error 152）
    Declare Operator += (ByRef rhs As Vec)
    Declare Operator *= (k As Double)
    Declare Operator -= (ByRef rhs As Vec)
End Type

Constructor Vec(x As Double, y As Double)
    This.x = x : This.y = y
End Constructor

Operator Vec.Cast() As String
    Return "(" & Format(x, "0.0#") & ", " & Format(y, "0.0#") & ")"
End Operator

Operator Vec.+= (ByRef rhs As Vec)
    x += rhs.x : y += rhs.y
End Operator

Operator Vec.-= (ByRef rhs As Vec)
    x -= rhs.x : y -= rhs.y
End Operator

Operator Vec.*= (k As Double)
    x *= k : y *= k
End Operator

' ---- 全局运算符：双目算术与比较 ----
Operator + (ByRef a As Vec, ByRef b As Vec) As Vec
    Return Vec(a.x + b.x, a.y + b.y)
End Operator

Operator - (ByRef a As Vec, ByRef b As Vec) As Vec
    Return Vec(a.x - b.x, a.y - b.y)
End Operator

Operator * (ByRef a As Vec, k As Double) As Vec
    Return Vec(a.x * k, a.y * k)
End Operator

Operator * (k As Double, ByRef a As Vec) As Vec      ' 反向也要单独定义
    Return a * k
End Operator

Operator = (ByRef a As Vec, ByRef b As Vec) As Boolean
    Return (a.x = b.x) And (a.y = b.y)
End Operator

Operator <> (ByRef a As Vec, ByRef b As Vec) As Boolean
    Return Not (a = b)
End Operator

' ---- 长度走函数（没运算符可配，就别硬配）----
Function lengthOf(ByRef v As Vec) As Double
    Return Sqr(v.x * v.x + v.y * v.y)
End Function

' ---- For/Step/Next 迭代运算符：让自定义类型吃 For 语法 ----
Type Range
    Dim As Integer i, limit_
    Declare Constructor(i_ As Integer = 0, limit_ As Integer = 0)
    Declare Operator For ()
    Declare Operator Step ()
    Declare Operator Next(ByRef endCond As Range) As Integer
End Type

Constructor Range(i_ As Integer, limit_ As Integer)
    ' 坑：形参 limit_ 与字段 limit_ 同名，裸写 limit_ = limit_ 是参数自赋值——必须 This.
    This.i = i_
    This.limit_ = limit_
End Constructor

Operator Range.For()
End Operator

Operator Range.Step()
    i += 1
End Operator

Operator Range.Next(ByRef endCond As Range) As Integer
    Return i <= endCond.limit_
End Operator

' ================= 验证 =================
Dim As Vec v1 = Vec(1, 2), v2 = Vec(3, 4)

Dim sum As Vec = v1 + v2
Print "v1 + v2 = "; sum               ' Cast 让打印直接可用
Assert(sum.x = 4 And sum.y = 6)

Dim diff As Vec = v2 - v1
Print "v2 - v1 = "; diff
Assert(diff.x = 2 And diff.y = 2)

Dim scaled As Vec = v1 * 3
Print "v1 * 3 = "; scaled
Assert(scaled.x = 3 And scaled.y = 6)
Dim scaled2 As Vec = 2 * v1           ' 反向乘法
Assert(scaled2.x = 2 And scaled2.y = 4)

sum += Vec(1, 1)                       ' 成员复合赋值
Print "sum += (1,1) 后 = "; sum
Assert(sum.x = 5 And sum.y = 7)
sum -= Vec(5, 7)
Assert(sum.x = 0 And sum.y = 0)
scaled *= 0.5
Assert(scaled.x = 1.5 And scaled.y = 3)

Print "v1 = v1 ->"; (v1 = Vec(1, 2))
Print "v1 <> v2 ->"; (v1 <> v2)
Assert((v1 = Vec(1, 2)) = True)
Assert((v1 <> v2) = True)

Print "lengthOf(v2) ="; lengthOf(v2)
Assert(lengthOf(v2) = 5)

' For 迭代：Range 从 1 走到 4
Dim acc As Integer
For r As Range = Range(1, 0) To Range(0, 4)
    Print "  iter"; r.i
    acc += r.i
Next
Assert(acc = 10)

Print "[OK] 14_operators"
End 0
