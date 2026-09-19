' 02_hello.bas —— 第一个程序：Print 的四种姿势与编码纪律
' 编译：fbc -w all 02_hello.bas -x 02_hello.exe

Print "Hello, FreeBASIC!"              ' 最简单的一行
Print "你好，世界！"                     ' UTF-8 无 BOM 源码，字面量按字节透传

' 分号：不换行继续打印（数字两侧自动补空格，字符串原样）
Print "a ="; 42
Print "b ="; 3.14
Print "拼"; "接"; "中"

' 逗号：跳到下一个打印区（约 14 列一区）
Print 1, 2, 3
Print "left", "right"

' Print 变量与表达式
Dim As String name_ = "fbc"
Dim As Integer year_ = 2004
Print name_ & " 诞生于 " & year_ & " 年"   ' & 是字符串拼接

Print "圆周率 ≈"; 3.14159

Print "[OK] 02_hello"
End 0
