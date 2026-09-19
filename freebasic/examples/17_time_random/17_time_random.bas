' 17_time_random.bas —— 时间与随机：Timer 计时、日期全家桶、确定性种子
' 编译：fbc -w all -g -exx 17_time_random.bas -x 17_time_random.exe

#Include Once "vbcompat.bi"          ' 日期函数与 Format 都住在这里

' ---- 1) Timer：Windows 上是开机以来的秒数（实测），做间隔测量 ----
Print "Timer ="; Timer; "（Windows 上 = 开机至今秒数，不是自午夜！）"
Var t0 = Timer
Sleep 60                             ' 睡 60ms
Var dt = Timer - t0
Print "Sleep(60) 实测间隔 ="; dt; " 秒"
Assert(dt >= 0.05)                   ' 下界宽松断言；上界受调度影响不设

' ---- 2) Now 与 Format：分钟占位符是 n，不是 m（m 是月份！）----
Print "Now ="; Now; "（OLE 序数日期，Double）"
Print "Format(Now, ""yyyy-mm-dd hh:nn:ss"") -> "; Format(Now, "yyyy-mm-dd hh:nn:ss")
Print "年月日时分秒: "; Year(Now); " "; Month(Now); " "; Day(Now); " "; Hour(Now); ":"; Minute(Now); ":"; Second(Now)
Assert(Year(Now) >= 2026)

' ---- 3) DateSerial / DateAdd / DateDiff ----
Var fbcBirth = DateSerial(2004, 9, 1)               ' FB 1.0 发布日
Print "DateSerial(2004,9,1) -> "; Format(fbcBirth, "yyyy-mm-dd")
Var threeMonths = DateAdd("m", 3, fbcBirth)
Print "+3 个月 -> "; Format(threeMonths, "yyyy-mm-dd")
Assert(Format(threeMonths, "yyyy-mm-dd") = "2004-12-01")

Var days = DateDiff("d", fbcBirth, Now)
Print "距 2004-09-01 已过 "; days; " 天"
Assert(days > 7000)

' ---- 4) 随机数：Randomize 确定性种子（可测性的关键）----
Randomize 42
Dim As Double a1 = Rnd, a2 = Rnd
Print "种子 42 前两个: "; a1; " "; a2

Randomize 42                         ' 重置同一种子
Dim As Double b1 = Rnd, b2 = Rnd
Print "再次种子 42:   "; b1; " "; b2
Assert(a1 = b1 And a2 = b2)          ' 序列完全复现

' 骰子：Int(Rnd * 6) + 1
Dim inRange As Boolean = True
For i As Integer = 1 To 1000
    Var dice = Int(Rnd * 6) + 1
    If dice < 1 OrElse dice > 6 Then inRange = False
Next
Print "1000 次骰子全部在 [1,6] ->"; inRange
Assert(inRange)

' Rnd 不含 1（[0,1) 开区间上界）
Dim maxSeen As Double = 0
For i As Integer = 1 To 10000
    Var r = Rnd
    If r > maxSeen Then maxSeen = r
Next
Print "10000 次最大 Rnd ="; maxSeen; "（恒 < 1）"
Assert(maxSeen < 1)

Print "[OK] 17_time_random"
End 0
