' 06_arrays.bas —— 数组：固定/动态、Redim Preserve、多维、Erase、数组传参
' 编译：fbc -w all -exx 06_arrays.bas -x 06_arrays.exe

' ---- 1) 固定数组：可自选下界，初始化器 ----
Dim v(1 To 5) As Integer = {10, 20, 30, 40, 50}
Print "v: LBound="; LBound(v); " UBound="; UBound(v); " v(3)="; v(3)
Assert(LBound(v) = 1 And UBound(v) = 5)

Dim w(3) As Integer                  ' 省略下界 = 0 To 3
Print "w: LBound="; LBound(w); " UBound="; UBound(w)
Assert(LBound(w) = 0 And UBound(w) = 3)

' ---- 2) 动态数组：Redim 声明 + Preserve 扩容 ----
Redim d(1 To 3) As Integer
For i As Integer = 1 To 3 : d(i) = i * i : Next
Redim Preserve d(1 To 5)             ' 保留旧值扩容
d(4) = 16 : d(5) = 25
Print "d 扩容后:"; d(1); d(2); d(3); d(4); d(5)
Assert(d(3) = 9 And d(5) = 25)       ' 旧值在、新值在

Redim Preserve d(1 To 2)             ' 也可以缩
Assert(UBound(d) = 2 And d(1) = 1)

' ---- 3) 多维 + Preserve 只能动最后一维 ----
Redim m(1 To 2, 1 To 2) As Integer
m(1, 1) = 11 : m(1, 2) = 12 : m(2, 1) = 21 : m(2, 2) = 22
Redim Preserve m(1 To 2, 1 To 4)     ' 行数不变，加列
Print "m(1,2)="; m(1, 2); "（保留） m(2,4)="; m(2, 4); "（新增=0）"
Assert(m(1, 2) = 12 And m(2, 4) = 0)

' ---- 4) Erase：固定数组清零；动态数组释放 ----
Erase w
Assert(w(0) = 0 And w(3) = 0)
Erase d
Redim d(1 To 4)                      ' 释放后可重新分配
d(4) = 44
Assert(d(4) = 44)

' ---- 5) 数组作为参数与 UDT 字段 ----
Type Stats
    data_(1 To 3) As Integer         ' 固定数组字段
    total As Integer
End Type
Dim st As Stats
For i As Integer = 1 To 3
    st.data_(i) = i
    st.total += i
Next
Print "st.total="; st.total
Assert(st.total = 6)

Print "[OK] 06_arrays"
End 0
