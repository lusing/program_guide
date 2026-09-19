' 08_udt.bas —— 用户定义类型：Type/嵌套/Union/Enum/With/别名/Type() 初始化器
' 编译：fbc -w all -g -exx 08_udt.bas -x 08_udt.exe

' ---- 1) 基本 Type + Type() 初始化器 ----
Type Point2D
    x As Double
    y As Double
End Type

Dim p As Point2D = Type(3, 4)
Print "p = ("; p.x; ", "; p.y; ")"
Assert(p.x = 3 And p.y = 4)

' ---- 2) With 块 ----
With p
    .x = .x * 2
    .y = .y * 2
End With
Print "With 翻倍后 p = ("; p.x; ", "; p.y; ")"
Assert(p.x = 6 And p.y = 8)

' ---- 3) 嵌套 UDT + 嵌套 Type() ----
Type LineSeg
    a As Point2D
    b As Point2D
End Type

Dim seg As LineSeg                    ' Type() 不能嵌套（实测）——分步初始化
seg.a = Type(0, 0)
seg.b = Type(3, 4)
Var dx = seg.b.x - seg.a.x
Var dy = seg.b.y - seg.a.y
Var length_ = Sqr(dx * dx + dy * dy)
Print "线段长度 = "; length_
Assert(length_ = 5)

' ---- 4) Union：同一段内存的多重解读 ----
Union Value32
    i As ULong                       ' 4 字节整数
    bytes(0 To 3) As UByte           ' 同一内存按字节看
End Union

Dim u As Value32
u.i = &h41424344
Print "Union: i=&h"; Hex(u.i); " 字节: ";
For i As Integer = 0 To 3
    Print "0x"; Hex(u.bytes(i), 2); " ";
Next
Print                                   ' 小端：44 43 42 41
Assert(u.bytes(0) = &h44 And u.bytes(3) = &h41)

' ---- 5) Enum：默认 0 起，可显式赋值 ----
Enum Color
    Red                                ' 0
    Green                              ' 1
    Blue                               ' 2
End Enum

Enum Weekday
    Mon = 1
    Tue                                ' 2
    Wed                                ' 3
    Sun = 7
End Enum

Dim c As Color = Green
Print "Green ="; c; "  Tue ="; Tue
Assert(c = 1 And Tue = 2)

' Select Case 配 Enum（08 章传统艺能）
Select Case c
Case Red
    Print "红"
Case Green
    Print "绿（命中）"
Case Blue
    Print "蓝"
End Select

' ---- 6) Type 别名与含数组的 UDT ----
Type Pt As Point2D                     ' 别名
Dim q As Pt = Type(1, 1)
Assert(q.x = 1 And q.y = 1)

Type Histogram
    buckets(0 To 4) As Integer
    total As Integer = 0               ' 字段默认值
End Type

Dim h As Histogram
For i As Integer = 0 To 4
    h.buckets(i) = i * i
    h.total += h.buckets(i)
Next
Print "Histogram total="; h.total; "（字段默认值 total 初值 "; 0; "）"
Assert(h.total = 30)

' ---- 7) UDT 数组 + 初始化器列表 ----
Dim pts(1 To 3) As Point2D = { Type(1, 2), Type(3, 4), Type(5, 6) }
Print "pts(2) = ("; pts(2).x; ", "; pts(2).y; ")"
Assert(pts(2).x = 3 And pts(2).y = 4)

Print "[OK] 08_udt"
End 0
