' 13_oop2.bas —— OOP II：Extends 继承、Virtual/Abstract 多态、Base 调用、堆对象
' 编译：fbc -w all -g -exx 13_oop2.bas -x 13_oop2.exe

#Include Once "vbcompat.bi"          ' Format() 需要它

' ---- 基类：抽象面积 + 虚描述 ----
Type Shape Extends Object            ' 要虚方法，必须显式继承 Object
    Protected:
        Dim As String label          ' Protected：派生类可见，外界不可见
    Public:
        Declare Constructor()                          ' 默认构造器：派生类隐式拷贝构造的前提（坑）
        Declare Constructor(label_ As String)
        Declare Abstract Function area() As Double     ' 抽象：子类必须实现
        Declare Virtual Function describe() As String  ' 虚方法：子类可改写
End Type

Constructor Shape()
    This.label = "?"
End Constructor

Constructor Shape(label_ As String)
    This.label = label_
End Constructor

Virtual Function Shape.describe() As String
    Return label & " 面积=" & Format(area(), "0.00")
End Function

' ---- 派生类 1：矩形 ----
Type Rect Extends Shape
    Protected:
        Dim As Double w, h
    Public:
        Declare Constructor(w As Double, h As Double)
        Declare Function area() As Double Override     ' Override 只写在 Declare 行
End Type

Constructor Rect(w As Double, h As Double)
    Base("矩形")                      ' 调基类构造器
    This.w = w
    This.h = h
End Constructor

Function Rect.area() As Double
    Return w * h
End Function

' ---- 派生类 2：圆（还改写 describe）----
Type Circle Extends Shape
    Protected:
        Dim As Double r
    Public:
        Declare Constructor(r As Double)
        Declare Function area() As Double Override
        Declare Virtual Function describe() As String Override
End Type

Constructor Circle(r As Double)
    Base("圆")
    This.r = r
End Constructor

Function Circle.area() As Double
    Return 3.14159265358979 * r * r
End Function

Virtual Function Circle.describe() As String
    Return "【" & Base.describe() & "】"    ' Base. 调基类实现再加工
End Function

' ---- 抽象类不能实例化（实测报"UDT has unimplemented abstract methods"）----

' ================= 验证 =================
Dim r As Rect = Rect(3, 4)
Dim c As Circle = Circle(1)
Print r.describe()
Print c.describe()
Assert(r.area() = 12)
Assert(Abs(c.area() - 3.14159265358979) < 0.000001)

' ---- 多态：基类指针数组，动态派发 ----
Dim As Shape Ptr shapes(1 To 3)
shapes(1) = @r
shapes(2) = @c
shapes(3) = New Rect(2, 5)           ' 堆对象走 New

Var total = 0.0
For i As Integer = 1 To 3
    Print "shapes("; i; "): "; shapes(i)->describe()
    total += shapes(i)->area()       ' 按实际类型调 area
Next
Print "总面积="; total
Assert(Abs(total - (12 + 3.14159265358979 + 10)) < 0.000001)

Delete shapes(3)                     ' New 的必须 Delete（析构器会跑）

' Protected 验证：label 在外界不可见（下一行若取消注释即编译错误）
' Print r.label

Print "[OK] 13_oop2"
End 0
