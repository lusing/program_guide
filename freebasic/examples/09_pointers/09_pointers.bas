' 09_pointers.bas —— 指针与内存：@/*、Allocate 家族、Peek/Poke、指针运算、Byref
' 编译：fbc -w all -g -exx 09_pointers.bas -x 09_pointers.exe

' ---- 1) 取址与解引用 ----
Dim x As Integer = 42
Dim p As Integer Ptr = @x            ' @ 取地址
Print "*p ="; *p                     ' * 解引用
*p = 100                             ' 通过指针改 x
Print "改后 x ="; x
Assert(x = 100)

' ---- 2) 指针下标语法：p[i] 是 *(p+i) 的糖 ----
Dim p2 As Integer Ptr = @x
Print "p2[0] ="; p2[0]
Assert(p2[0] = 100)

' ---- 3) 堆内存：Allocate / Callocate / Reallocate / Deallocate ----
Dim a As Integer Ptr = Allocate(5 * Sizeof(Integer))   ' 不清零
For i As Integer = 0 To 4
    a[i] = i * i
Next
Print "Allocate 填充后:"; a[0]; a[1]; a[2]; a[3]; a[4]
Assert(a[4] = 16)
Dim b As Integer Ptr = Reallocate(a, 8 * Sizeof(Integer))  ' 扩容（内容保留）
If b <> 0 Then a = b
a[7] = 49
Print "Reallocate 后 a[2]="; a[2]; " a[7]="; a[7]
Assert(a[2] = 4 And a[7] = 49)
Deallocate(a)

Dim c As Double Ptr = Callocate(3, Sizeof(Double))     ' 分配并清零
Print "Callocate 清零: c[0]="; c[0]; " c[2]="; c[2]
Assert(c[0] = 0 And c[2] = 0)
Deallocate(c)

' ---- 4) 指针运算按元素大小走 ----
Dim arr(0 To 4) As Integer = {10, 20, 30, 40, 50}
Dim q As Integer Ptr = @arr(0)
Print "q+2 指向:"; *(q + 2)          ' +2 = 前进 2 个 Integer（16 字节）
Assert(*(q + 2) = 30)

' ---- 5) Peek / Poke：按地址直接读写 ----
Poke Integer, @x, 777
Print "Poke 后 x="; x
Assert(x = 777)
Print "Peek:"; Peek(Integer, @x)
Assert(Peek(Integer, @x) = 777)

' ---- 6) 指针与 UDT：-> 访问字段 ----
Type Point3D
    x As Double
    y As Double
    z As Double
End Type
Dim pt As Point3D = Type(1, 2, 3)
Dim pp As Point3D Ptr = @pt
Print "pp->y ="; pp->y
pp->z = 99
Assert(pt.z = 99)

' ---- 7) Byref 局部变量：引用的语法糖 ----
Dim ByRef r As Integer = x
r += 1
Print "Byref 后 x="; x
Assert(x = 778)

' ---- 8) 空指针：-exx 下解引用即捕获 ----
Dim nullp As Integer Ptr = 0
Dim guard As Boolean = (nullp = 0)   ' 只比较不解引用
Print "空指针判断 guard="; guard
Assert(guard)

Print "[OK] 09_pointers"
End 0
