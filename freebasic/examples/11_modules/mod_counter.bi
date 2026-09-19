' mod_counter.bi —— 计数器模块的接口（.bi = 头文件惯例：只放声明）
' 实现见 mod_counter.bas；使用方 #Include 本文件即可。

#Include Once "mod_counter.bi"   ' 防重复包含守卫（自引用无害）

Namespace Counter
    ' ---- 接口：类型 + 过程声明，不带实现 ----
    Type Stats
        total As Integer
        calls As Integer
    End Type

    Declare Function add(v As Integer) As Integer      ' 累加并返回当前总值
    Declare Function getvalue() As Integer             ' 只读当前总值
    Declare Function stats() As Stats                  ' 取统计
    Declare Sub reset()                                ' 清零
End Namespace
