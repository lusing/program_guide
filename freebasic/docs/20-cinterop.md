# 20 · ⭐C 互操作

> 对应示例：`examples/20_cinterop/`

FB 编译产物就是普通 COFF 目标文件、走 MinGW 链接器、符号就是 C ABI——**调用 C 世界不需要任何 FFI 层**：一个 `Declare` 就是全部。这是 FB 对 C 程序员最致命的吸引力。

## 20.1 windows.bi：整个 Win32 一句话进来

```freebasic
#Include Once "windows.bi"          ' fbc 自带，数千 API 的 Declare

Dim si As SYSTEM_INFO
GetSystemInfo(@si)                  ' 传结构体指针（Win32 惯例）
Print si.dwNumberOfProcessors

Dim mi As MEMORYSTATUSEX
mi.dwLength = Sizeof(MEMORYSTATUSEX)
GlobalMemoryStatusEx(@mi)
```

`inc/` 目录还有 `crt/*.bi`（C 运行库）、`SDL2`、`cairo`、`GL`、`curl` 等几百个现成绑定——要什么先翻 `inc/`。

## 20.2 手写 Declare：单点直调

```freebasic
Extern "Windows"                                        ' StdCall + 名字修饰（Win32 API）
    Declare Function fbGetPID Alias "GetCurrentProcessId" () As ULong
End Extern

Extern "C"                                              ' Cdecl + 无修饰（C 运行库/DLL 导出）
    Declare Function crand Alias "rand" () As Long
End Extern
```

- `Extern "Windows"` / `Extern "C"` 块决定调用约定与导出名规则；`Alias` 指定 DLL 里的真实名字。
- 不用块时单条也行：`Declare Function f Lib "mydll" Alias "the_name" (...) As ...`。
- 类型按 C 的真实宽度对表（03 章）：C `int` → `Long`（都是 4 字节），指针 → `Any Ptr`/具体 `Ptr`，`long long` → `LongInt`。

## 20.3 回调：把 FB 函数递给 C ⭐

```freebasic
Extern "C"
    Declare Sub cqsort Alias "qsort" (ByVal base As Any Ptr, ByVal num As ULong, _
                                      ByVal size As ULong, _
                                      ByVal compar As Function(ByVal As Any Ptr, ByVal As Any Ptr) As Long)
End Extern

Function cmpInt Cdecl (ByVal a As Any Ptr, ByVal b As Any Ptr) As Long   ' ⚠ Cdecl！
    Return *CPtr(Integer Ptr, a) - *CPtr(Integer Ptr, b)
End Function

cqsort(@arr(1), 5, Sizeof(Integer), @cmpInt)
```

**回调函数必须标 `Cdecl`**——它是被 C 调用的，栈约定得跟 C 走（对照 19 章：`ThreadCreate` 的入口反而别加 `Cdecl`，因为那是 FB 自己的调用约定）。跨边界的函数指针就是"谁调用，随谁约定"。

## 20.4 高精度计时（17 章的承诺）

```freebasic
Dim As LARGE_INTEGER freq, t0, t1
QueryPerformanceFrequency(@freq)
QueryPerformanceCounter(@t0)
...被测代码...
Var ms = (t1.QuadPart - t0.QuadPart) * 1000.0 / freq.QuadPart
```

`QuadPart` 是 `LongInt`（C `LONGLONG`），乘除前转 Double 防溢出。

## 20.5 绑定自己的 C 库

1. C 侧按 C ABI 导出（`extern "C"`，不 name-mangle）；
2. FB 侧 `Declare ... Lib "mylib"`（`#inclib "mylib"` 或把 `mylib.dll` 放 exe 旁 / `mylib.a` 交链接）；
3. 结构体逐字段按宽度对齐抄一份——**没有自动生成器，手工就是仪式**（这也是 FB 生态绑定多的原因：抄过一次大家共享 `.bi`）。

## 20.6 坑位清单（1.10.1 实测）

1. **回调给 C 的函数要 `Cdecl`**；`ThreadCreate` 入口反而不要——约定看调用方。
2. C `int`/`long` → FB `Long`（4 字节）；别条件反射写 `Integer`（win64 上 8 字节，结构体错位）。
3. Win32 结构体带 `dwLength/cbSize` 尺寸字段的不填 → API 静默失败。
4. `Alias` 拼错导出名 = 链接期才炸（找不到符号），编译期不查。
5. 老教程的 `#Include "windows.bi"`（无 Once）多次包含会重复定义——永远 `Once`。
