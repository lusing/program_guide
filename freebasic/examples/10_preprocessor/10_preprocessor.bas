' 10_preprocessor.bas —— 预处理器：#define 函数宏、#macro 多行宏、条件编译、内置宏
' 编译：fbc -w all -g -exx 10_preprocessor.bas -x 10_preprocessor.exe

' ---- 1) 对象式 #define（编译期常量）----
#define MAX_ITEMS 5
#define APP_NAME "demo"
Print "MAX_ITEMS="; MAX_ITEMS; "  APP_NAME="; APP_NAME
Assert(MAX_ITEMS = 5)

' ---- 2) 函数式 #define（注意括号保护）----
#define SQ(x) ((x) * (x))
#define ADD3(a, b, c) ((a) + (b) + (c))
Print "SQ(7)="; SQ(7); "  SQ(1+2)="; SQ(1 + 2)      ' 9：括号保住了
Assert(SQ(7) = 49 And SQ(1 + 2) = 9)
Print "ADD3(1,2,3)="; ADD3(1, 2, 3)

' ---- 3) #macro：多行宏（FB 特色，比 #define 强）----
#macro MAX3(a, b, c, result)
    If (a) >= (b) AndAlso (a) >= (c) Then
        result = (a)
    ElseIf (b) >= (c) Then
        result = (b)
    Else
        result = (c)
    End If
#endmacro

Dim m As Integer
MAX3(3, 9, 5, m)
Print "MAX3(3,9,5)="; m
Assert(m = 9)

' # 宏内字符串化：调试打印神器
#macro SHOW(e)
    Print "  " & #e & " = "; e
#endmacro
SHOW(2 ^ 10)
SHOW(SQ(5))

' ---- 4) 条件编译 ----
#define VERBOSE 1
#If VERBOSE
    Print "VERBOSE 打开"
#else
    Print "VERBOSE 关闭"
#endif

#ifdef __FB_WIN32__
    Print "平台: Windows (__FB_WIN32__)"
#endif
#ifdef __FB_64BIT__
    Print "位数: 64 (__FB_64BIT__)"
#endif
#if __FB_VER_MAJOR__ = 1
    Print "fbc 主版本 1（"; __FB_VER_MAJOR__; "."; __FB_VER_MINOR__; "）"
#endif

' ---- 5) 未定义检查与取反 ----
#ifndef FEATURE_X
    Print "FEATURE_X 未定义（正常）"
#endif

' ---- 6) 续行符 _ 与 __FILE__/__LINE__?（FB 提供 __FILE__ / __FUNCTION__ 宏）----
Print "本文件: "; __FILE__

Print "[OK] 10_preprocessor"
End 0
