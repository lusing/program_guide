' 12_oop1.bas —— OOP I：构造/析构、Property、静态成员、访问区
' 编译：fbc -w all -g -exx 12_oop1.bas -x 12_oop1.exe

Type Widget
    Public:
        Declare Constructor(id_ As Integer, w As Double = 1.0)
        Declare Destructor()
        Declare Property width() As Double          ' 读属性
        Declare Property width(w As Double)         ' 写属性（带校验）
        Static count As Integer                     ' 静态成员：声明
        Declare Static Function created() As Integer ' 静态方法
    Private:
        Dim As Integer id
        Dim As Double w_
End Type

' 静态成员：在 Type 外定义（Static 前缀）
Static Widget.count As Integer = 0

Constructor Widget(id_ As Integer, w As Double)
    This.id = id_
    This.w_ = w
    count += 1                       ' 构造计数
End Constructor

Destructor Widget()
    count -= 1                       ' 析构减数
End Destructor

Property Widget.width() As Double
    Return This.w_
End Property

Property Widget.width(w As Double)
    If w < 0 Then w = 0              ' 写属性里做校验：负值钳到 0
    This.w_ = w
End Property

Static Function Widget.created() As Integer
    Return count                     ' 静态方法只碰静态成员
End Function

' ================= 验证 =================
Print "开局 created="; Widget.created()
Assert(Widget.created() = 0)

Scope
    Dim a As Widget = Widget(1, 2.5)
    Dim b As Widget = Widget(2)      ' 默认参数：w = 1.0
    Print "作用域内 created="; Widget.created()
    Assert(Widget.created() = 2)

    Print "a.width="; a.width; "  b.width="; b.width
    Assert(a.width = 2.5 And b.width = 1.0)

    b.width = -5                     ' 经写属性钳位
    Print "b.width=-5 钳位后 ="; b.width
    Assert(b.width = 0)

    b.width = 3.25
    Assert(b.width = 3.25)
End Scope

Print "出作用域后 created="; Widget.created()   ' 析构已把计数减回
Assert(Widget.created() = 0)

Print "[OK] 12_oop1"
End 0
