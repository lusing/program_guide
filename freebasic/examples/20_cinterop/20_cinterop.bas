' 20_cinterop.bas —— C 互操作：Win32/glibc 直调、Extern "C"、qsort 回调、高精度计时
' 编译：fbc -w all -g -exx 20_cinterop.bas -x 20_cinterop.exe
' 双平台：Windows 走 windows.bi 直调 Win32；Linux 走官方 crt 头直调 glibc（sysconf/clock_gettime/getpid）。

#ifdef __FB_WIN32__
    #Include Once "windows.bi"          ' 官方头：数千个 Win32 API 的 Declare 全在这
#endif
#ifdef __FB_LINUX__
    #Include Once "crt/unistd.bi"       ' 官方 crt 头：sysconf / getpid（glibc 的 Declare）
    #Include Once "crt/time.bi"         ' timespec 布局（linux-x86_64：__time_t 8 字节 + clong 8 字节）
    #define _SC_NPROCESSORS_ONLN 84     ' glibc bits/confname.h 的 ABI 值（头文件未导出，需手写）
    #define _SC_PHYS_PAGES     85
    #define _SC_PAGESIZE       30
#endif

' ---- 1) 直调系统 API：系统信息 ----
#ifdef __FB_WIN32__
Dim si As SYSTEM_INFO
GetSystemInfo(@si)
Print "处理器数 ="; si.dwNumberOfProcessors
Assert(si.dwNumberOfProcessors > 0)

Dim mi As MEMORYSTATUSEX
mi.dwLength = Sizeof(MEMORYSTATUSEX)     ' 结构体先填尺寸（Win32 惯例）
GlobalMemoryStatusEx(@mi)
Print "物理内存 ="; mi.ullTotalPhys \ (1024 * 1024); " MB"
Assert(mi.ullTotalPhys > 0)
#endif
#ifdef __FB_LINUX__
Var ncpu = sysconf(_SC_NPROCESSORS_ONLN)                 ' 在线 CPU 数
Print "处理器数 ="; ncpu
Assert(ncpu > 0)

Var physKB = sysconf(_SC_PHYS_PAGES) * sysconf(_SC_PAGESIZE) \ 1024
Print "物理内存 ="; physKB \ 1024; " MB"                 ' 物理页数 × 页大小
Assert(physKB > 0)
#endif

' ---- 2) 高精度计时：QPC / clock_gettime（17 章承诺的纳秒级）----
#ifdef __FB_WIN32__
Print "开机毫秒 ="; GetTickCount()

Dim As LARGE_INTEGER freq, t0, t1
QueryPerformanceFrequency(@freq)
QueryPerformanceCounter(@t0)
Sleep 50
QueryPerformanceCounter(@t1)
Var elapsedMs = (t1.QuadPart - t0.QuadPart) * 1000.0 / freq.QuadPart
Print Using "QPC 实测 Sleep(50) = ###.## ms"; elapsedMs
Assert(elapsedMs >= 45)
#endif
#ifdef __FB_LINUX__
#define CLOCK_MONOTONIC 1             ' time.h 枚举值（Linux ABI 恒为 1）
Extern "C"
    Declare Function clock_gettime Alias "clock_gettime" (ByVal clk_id As Long, ByRef tp As timespec) As Long
End Extern

Dim As timespec mt0, mt1
clock_gettime(CLOCK_MONOTONIC, mt0)
Print "开机毫秒 ="; mt0.tv_sec * 1000 + mt0.tv_nsec \ 1000000    ' MONOTONIC 自系统启动起算
Sleep 50
clock_gettime(CLOCK_MONOTONIC, mt1)
Var elapsedMs = (mt1.tv_sec - mt0.tv_sec) * 1000.0 + (mt1.tv_nsec - mt0.tv_nsec) / 1000000.0
Print Using "MONOTONIC 实测 Sleep(50) = ###.## ms"; elapsedMs
Assert(elapsedMs >= 45)
#endif

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

' ---- 5) 手写 Declare 单点直调（不 include 大头文件的单点直调）----
#ifdef __FB_WIN32__
' windows.bi 已声明 GetCurrentProcessId，这里只是示范手写形态（Alias 指导出名）：
Extern "Windows"
    Declare Function fbGetPID Alias "GetCurrentProcessId" () As ULong
End Extern
#endif
#ifdef __FB_LINUX__
' unistd.bi 已声明 getpid，这里同样示范手写形态（Linux 无 stdcall，Extern "C" 即可）：
Extern "C"
    Declare Function fbGetPID Alias "getpid" () As Long
End Extern
#endif
Print "当前 PID ="; fbGetPID()
Assert(fbGetPID() > 0)

Print "[OK] 20_cinterop"
End 0
