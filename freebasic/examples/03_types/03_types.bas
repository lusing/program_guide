' 03_types.bas —— 类型系统：尺寸表、Var、Const、Boolean、Cast、溢出回绕
' 编译：fbc -w all -exx 03_types.bas -x 03_types.exe

' ---- 1) 尺寸表（win64 实测） ----
Print "== Sizeof 表（win64：Integer=指针宽 8，Long 恒 4） =="
Print "Byte="; Sizeof(Byte); "  UByte="; Sizeof(UByte)
Print "Short="; Sizeof(Short); "  Integer="; Sizeof(Integer); "  UInteger="; Sizeof(UInteger)
Print "Long="; Sizeof(Long); "  LongInt="; Sizeof(LongInt); "  ULongInt="; Sizeof(ULongInt)
Print "Single="; Sizeof(Single); "  Double="; Sizeof(Double)
Print "Any Ptr="; Sizeof(Any Ptr); "  String(描述符)="; Sizeof(String)

Assert(Sizeof(Integer) = Sizeof(Any Ptr))     ' Integer 跟指针同宽
Assert(Sizeof(Long) = 4)                      ' Long 永远 32 位

' ---- 2) Dim 的多种姿势 ----
Dim a As Integer = 10, b As Double = 2.5      ' 一行多声明（各自带类型）
Var y = 3.14159                              ' Var：类型推断（此处 Double）
Var s = "推断成 String"
Print "y="; y; " s="; s

Const PI As Double = 3.14159265358979        ' 编译期常量
Const GREETING = "hello"
Print "PI="; PI; "  GREETING="; GREETING

' ---- 3) Boolean：底层真是 -1（不是 1），但 Print 显示 true/false ----
Dim flag As Boolean = True
Print "True 打印出来 ="; flag                 ' 显示 true；底层值是 -1（QB 血统）
Assert(flag = -1)
Assert((Not True) = 0)

' ---- 4) 进制字面量与类型后缀 ----
Print "hex=&hFF(255) oct=&o377 bin=&b1010 ->"; &hFF; &o377; &b1010
Dim d1 As Double = 1.5                       ' 小数字面量默认 Double
Dim f1 As Single = 1.5                       ' 赋给 Single 时收窄
Print "d1="; d1; " f1="; f1

' ---- 5) 显式转换 Cast：银行家舍入（2.5→2、3.5→4），截断要用 Fix/Int ----
Dim As Double ratio = 3.7
Dim As Integer rounded = Cast(Integer, ratio)      ' 4：四舍五入（half-to-even）
Dim As Integer chopped = Fix(ratio)                ' 3：向零截断
Print "3.7: Cast="; rounded; " Fix="; chopped
Print "Cast(2.5)="; Cast(Integer, 2.5); " Cast(3.5)="; Cast(Integer, 3.5); "（银行家舍入）"
Assert(rounded = 4)
Assert(chopped = 3)
Assert(Cast(Integer, 2.5) = 2 And Cast(Integer, 3.5) = 4)

' 字符串 <-> 数字
Print "Val(""42"") + 1 ="; Val("42") + 1
Print "Str(-5) = ["; Str(-5); "]"                 ' 负数带负号，正数无前导空格（与 QB 不同）
Assert(Val("3.5") = 3.5)

' ---- 6) 整数回绕（-exx 不查算术溢出，只查数组边界/空指针） ----
Dim ub As UByte = 255
ub += 1                                       ' 回绕成 0（注意 Print 无符号数不补前导空格）
Print "UByte 255 + 1 = "; ub
Assert(ub = 0)

Print "[OK] 03_types"
End 0
