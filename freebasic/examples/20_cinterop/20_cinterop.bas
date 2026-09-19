' 20_cinterop.bas —— C 互操作：windows.bi 直调 Win32、Extern "C"、qsort 回调、高精度计时
' 编译：fbc -w all -g -exx 20_cinterop.bas -x 20_cinterop.exe

#Include Once "windows.bi"          ' 官方头：数千个 Win32 API 的 Declare 全在这

' ---- 1) 直调 Win32：系统信息 ----
Dim si As SYSTEM_INFO
GetSystemInfo(@si)
Print "处理器数 ="; si.dwNumberOfProcessors
Assert(si.dwNumberOfProcessors > 0)

Dim mi As MEMORYSTATUSEX
mi.dwLength = Sizeof(MEMORYSTATUSEX)     ' 结构体先填尺寸（Win32 惯例）
GlobalMemoryStatusEx(@mi)
Print "物理内存 ="; mi.ullTotalPhys \ (1024 * 1024); " MB"
Assert(mi.ullTotalPhys > 0)

Print "开机毫秒 ="; GetTickCount()

' ---- 2) 高精度计时：QueryPerformanceCounter（17 章承诺的纳秒级）----
Dim As LARGE_INTEGER freq, t0, t1
QueryPerformanceFrequency(@freq)
QueryPerformanceCounter(@t0)
Sleep 50
QueryPerformanceCounter(@t1)
Var elapsedMs = (t1.QuadPart - t0.QuadPart) * 1000.0 / freq.QuadPart
Print Using "QPC 实测 Sleep(50) = ###.## ms"; elapsedMs
Assert(elapsedMs >= 45)

' ---- 3) Extern "C"：直接声明 C 运行库函数 ----
Extern "C"
    Declare Function crand Alias "rand" () As Long
    Declare Sub cqsort Alias "qsort" (ByVal base As Any Ptr, ByVal num As ULong, _
                                      ByVal size As ULong, _
                                      ByVal compar As Function(ByVal As Any Ptr, ByVal As Any Ptr) As Long)
End Extern

Print "C 的 rand() ="; crand()
Assert(crand() >= 0)

' ---- 4) 回调：把 FB 函数递给 C 的 qsort（回调必须 Cdecl！）----
Function cmpInt Cdecl (ByVal a As Any Ptr, ByVal b As Any Ptr) As Long
    Return *CPtr(Integer Ptr, a) - *CPtr(Integer Ptr, b)
End Function

Dim arr(1 To 5) As Integer = {50, 10, 40, 20, 30}
cqsort(@arr(1), 5, Sizeof(Integer), @cmpInt)
Print "qsort 结果:";
For i As Integer = 1 To 5 : Print " "; arr(i); : Next
Print
Assert(arr(1) = 10 And arr(5) = 50 And arr(3) = 30)

' ---- 5) 手写 Declare 调 DLL（不 include 大头文件的单点直调）----
' windows.bi 已声明 GetCurrentProcessId，这里只是示范手写形态（Alias 指导出名）：
Extern "Windows"
    Declare Function fbGetPID Alias "GetCurrentProcessId" () As ULong
End Extern
Print "当前 PID ="; fbGetPID()
Assert(fbGetPID() > 0)

Print "[OK] 20_cinterop"
End 0
