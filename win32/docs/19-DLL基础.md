# 第 19 章 DLL 基础：创建、导出与链接

> **本章回答的问题**：DLL 和 EXE 到底差在哪？隐式链接和显式链接怎么选？怎么亲手造一个 DLL 并用两种方式调用它？`DllMain` 里为什么不能乱写？Windows 按什么顺序找 DLL？
>
> **前置章节**：第 2 章（链接与导入库——本章把那笔"欠条"彻底讲透）、第 18 章（你已经用过一次 `GetProcAddress`）。
>
> **你将做出什么**：自己的第一个 DLL（`examples/23_dll_math`：mathlib.dll + 隐式链接消费者），并把它的构建链路亲手走一遍。

本章示例：`examples/23_dll_math`（mathlib.h / mathlib.cpp / main.cpp / build.ps1）。

## 19.1 DLL 是什么

DLL（Dynamic-Link Library）与 EXE 一样都是 **PE（Portable Executable）格式的模块**，本质区别只有两条：

- EXE 有入口被系统启动为进程；DLL 没有独立生命，必须被加载进某个进程的地址空间；
- DLL 通过**导出表**公布自己的函数，EXE 通过**导入表**声明依赖。

价值在于三件事：**共享代码**（一份系统 DLL 供全部进程映射，物理内存只驻留一份）、**模块化**（功能拆分、按需加载）、**插件机制**（运行时决定加载谁——下一章的主角）。整个 Windows 的系统功能就是一大组 DLL：`kernel32.dll`、`user32.dll`、`d3d12.dll`……你调 Win32 API 的每一步都在跨 DLL。

## 19.2 隐式链接：加载器替你干活

隐式链接（implicit / load-time linking）= 链接时挂上**导入库**，加载器在**进程启动时**自动加载 DLL 并填好函数地址。第 2 章链接命令里的 `user32.lib` 就是这个机制——现在我们站在另一侧，亲手造一个。

`examples/23_dll_math` 的构建链路（`build.ps1` 四步，建议逐行看）：

```text
① cl /DMATHLIB_EXPORTS /c mathlib.cpp /Fo:build\23_dll_math_mathlib.obj
      定义 MATHLIB_EXPORTS → mathlib.h 里宏展开成 dllexport（编译 DLL 侧）
② link /DLL /OUT:build\mathlib.dll /IMPLIB:build\mathlib.lib ...obj
      产出 DLL 本体 + 导入库（一张"谁住在里面"的欠条清单）
③ cl /c main.cpp /Fo:build\23_dll_math_main.obj
      消费者只 include mathlib.h——宏展开成 dllimport
④ link /SUBSYSTEM:CONSOLE /OUT:build\23_dll_math.exe main.obj mathlib.lib
      ★ 链接命令里出现 mathlib.lib，就是隐式链接的全部
```

消费者代码里**没有任何加载代码**，像调普通函数一样：

```cpp
#include "mathlib.h"

wprintf(L"%d\n", Math_Add(20, 22));   // 进程启动时 mathlib.dll 已被映射进来
```

**亲手验证两件事**：

1. `dumpbin /imports build\23_dll_math.exe`——导入表里出现 `mathlib.dll` 和三个函数名，这就是第 2 章欠条论的实体；
2. 把 `build\mathlib.dll` 临时移走再跑 exe——启动即弹"无法启动此程序，缺少 mathlib.dll"：**缺 DLL 进程直接起不来**，这是隐式链接的代价，也是它的问题定位如此简单的原因。

## 19.3 显式链接：运行时做主

显式链接（explicit / run-time linking）三步曲——`LoadLibraryW` / `GetProcAddress` / `FreeLibrary`：

```cpp
HMODULE hMod = LoadLibraryW(L"plugin.dll");      // 或 LoadLibraryExW 带更多标志
if (!hMod) { /* GetLastError() */ }

using AddFunc = int (WINAPI*)(int, int);        // ★ 函数指针签名必须与导出逐字一致
AddFunc add = (AddFunc)GetProcAddress(hMod, "Add");
// GetProcAddress 返回 FARPROC，必须显式转成正确签名——转错 = 调用约定/参数错乱，诡异崩溃
if (add) {
    int r = add(1, 2);
}

FreeLibrary(hMod);      // 引用计数减一，归零才真正卸载
```

你其实已经用过这套：第 18 章取 `RtlGetVersion` 就是"拿已加载模块 + 查函数地址"的显式链接形态。适用场景：**插件系统**（运行时扫描决定加载谁，下一章）、**可选功能**（缺 DLL 只禁用该功能而不是起不来）、**延迟加载**（启动提速）、**绕过版本差异**（新 API 不存在时降级——第 9 章 DPI 兼容写法就可以这样做）。

## 19.4 导出怎么写：宏模式与 `extern "C"`

工程惯例是"一个宏服务双方"，23 示例的 `mathlib.h` 就是标准模板：

```cpp
#ifdef MATHLIB_EXPORTS            // DLL 工程定义它 → 我是导出方
#  define MATHLIB_API __declspec(dllexport)
#else                             // 使用方不定义 → 我是导入方
#  define MATHLIB_API __declspec(dllimport)
#endif
extern "C" MATHLIB_API int Math_Add(int a, int b);
```

两个细节：

- **`extern "C"` 关掉 C++ 名字修饰**。不加它，MSVC 导出的名字是 `?Math_Add@@YAHHH@Z`——`GetProcAddress(hMod, "Math_Add")` 找不到人。关掉后导出名就是干净的 `Math_Add`，且与编译器版本解耦；
- `dllimport` 不写通常也能链接上（链接器自动补），但写上让编译器生成更短的跳转桩，并杜绝"跨模块调了个本地副本"类错误——照模板写全。

`.def` 文件是另一种导出方式（可给符号改名/定序号），如今主要见于需要稳定**序号导出**的系统级组件（`Ordinal.1` 那种），新代码用 `__declspec(dllexport)` 即可。

## 19.5 `DllMain`：最小化纪律

DLL 可选的初始化入口：

```cpp
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD reason, LPVOID reserved) {
    switch (reason) {
    case DLL_PROCESS_ATTACH:  // 本 DLL 被某进程加载（首次）
        DisableThreadLibraryCalls(hinstDLL);  // 不关心线程事件就关掉，减开销
        break;
    case DLL_PROCESS_DETACH:  // 被卸载
        break;
    case DLL_THREAD_ATTACH:   // 该进程每建一个线程（可用上面的调用关掉）
    case DLL_THREAD_DETACH:
        break;
    }
    return TRUE;
}
```

**Loader Lock** 是这里的核心约束：`DllMain` 执行期间加载器持有全局锁。所以 `DllMain` 里**禁止**：

- 调用可能再加载 DLL 的操作（COM 初始化、`CreateProcess`、`LoadLibrary` 链式反应都在列）；
- 等待同步对象（可能死锁：别的线程可能正等你加载完成）；
- 调用 CRT 的用户回调、创建线程后等它跑。

正确姿势：`DLL_PROCESS_ATTACH` 里只做"记下模块句柄、初始化少量原始状态"这类零风险工作，**复杂的初始化推到显式的导出初始化函数**（如 `MyLib_Initialize()`），由使用方在 `main` 后主动调用。文档《Dynamic-Link Library Best Practices》值得通读。

## 19.6 DLL 搜索顺序

`LoadLibraryW(L"foo.dll")` 传**裸文件名**时，Windows 按固定顺序找：

```text
1. 应用程序所在目录（exe 旁边）
2. 系统目录  System32
3. 16 位系统目录（兼容残留）
4. Windows 目录
5. 当前工作目录        ← 安全隐患所在
6. PATH 环境变量目录
```

（启用 SafeDllSearchMode 后第 5 步会后移——现代系统默认启用。）要点：

- **exe 旁边的 DLL 优先级最高**——"绿色软件把第三方 DLL 放自己目录"就是靠这条；23/24 示例的 DLL 全部输出到 `build\`（与 exe 同目录）正是利用它；
- **永远不要依赖"当前目录"**：双击不同快捷方式启动时当前目录不同，行为漂移；它还是 DLL 劫持（DLL hijacking）攻击面的来源——攻击者在可写目录放一个同名恶意 DLL 等你加载；
- 需要收紧搜索面时用 `SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_APPLICATION_DIR | ...)` 或 `LoadLibraryExW` 的搜索标志；
- 传**绝对路径**最稳：`LoadLibraryW(L"C:\\MyApp\\plugins\\demo.dll")`；
- 依赖缺失的典型报错：加载时 `ERROR_MOD_NOT_FOUND`（找不到 DLL 本身或它的依赖）或 `ERROR_PROC_NOT_FOUND`（DLL 在，导出函数不在——版本不匹配）。

## 19.7 完整示例解剖

`examples/23_dll_math` 的文件分工：`mathlib.h`（契约 + 双面宏）、`mathlib.cpp`（实现 + 最小 `DllMain`）、`main.cpp`（隐式消费者）、`build.ps1`（四步构建 + 运行验证）。运行输出：

```text
Math_Add(20, 22) = 42
Math_Mul(6, 7)   = 42
Math_Version()   = mathlib 1.0 (MSVC x64)
（没有 LoadLibrary——加载发生在进程启动，这就是隐式链接）
```

## 19.8 易错清单

| 错误 | 后果 |
|------|------|
| 函数指针签名与导出不一致（漏 `WINAPI`/参数错） | 传参错乱、栈损坏，崩溃点飘忽 |
| C++ 类/模板跨 DLL 边界导出 | 各模块 CRT/编译器版本不同则行为未定义；只导出 C 接口或纯虚接口（COM 路线，第 22 章） |
| 在 A.DLL 分配、在 B.EXE 释放内存 | 两边用不同 CRT 堆，释放崩溃；统一"谁分配谁释放"（下一章插件三原则） |
| `DllMain` 里做复杂初始化 | loader lock 死锁/加载失败 |
| 依赖"当前目录"加载 DLL | 行为随启动方式漂移 + 劫持攻击面 |
| `LoadLibrary` 不检查返回值 | 空句柄往下传，`GetProcAddress` 崩溃 |
| 导出忘 `extern "C"` | `GetProcAddress` 按名找不到（被修饰成 `?xxx@...`） |

## 19.9 小结

1. DLL = PE 模块 + 导出表；EXE 用导入表声明欠账，加载器启动时结清（隐式）或你运行时结清（显式）。
2. 隐式：`.lib` 上链接命令即完事；缺 DLL 启动即死——代价换来零样板。
3. 显式：`LoadLibrary/GetProcAddress/FreeLibrary` 三步；签名逐字核对是生死线。
4. 导出宏一个头两副面孔（`dllexport`/`dllimport`）；`extern "C"` 断开名字修饰。
5. `DllMain` 最小化纪律：loader lock 在场，复杂初始化推给显式导出函数。
6. 搜索顺序六步，exe 目录优先、当前目录勿依赖。

## 19.10 动手练习

1. 给 mathlib 加 `Math_Div(int a, int b, int* out)`：除零返回 `HRESULT` 风格错误码（`E_INVALIDARG`），正常返回 `S_OK`——DLL 边界上传错误的正确姿势预习。
2. 把 23 的消费者改成显式链接版（`LoadLibraryW(L"mathlib.dll")` + `GetProcAddress` 取三个函数），对比两种版本代码量与启动行为。
3. 实验：把 `mathlib.dll` 改名再跑 exe，观察错误弹窗；再把它放回但删掉 `build\` 里其他无关 DLL 复现"部分依赖缺失"（用 `dumpbin /dependents` 先看依赖清单）。

---

**下一章**：[第 20 章 DLL 进阶与插件系统](20-DLL进阶与插件系统.md)——插件架构实战、资源段、PE 与 API Set 的秘密。
