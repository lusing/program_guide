# 33 · DLL 编程：普通 / MFC 扩展 / 资源专用

> 对应示例：`examples/33_dll`

> **本章你将学会**：DLL 的三种形态（纯 C 接口 / MFC 扩展 / 资源专用）各自的适用场景与构建方法、隐式与显式链接、跨模块边界的内存纪律、“谁分配谁释放”。
> **前置知识**：第 04 章的资源系统、第 15 章的 CRuntimeClass 反射。

《Visual C++ MFC 编程实例》第 15 章用四个例子给全书收尾：例 82/83 静态/动态链接 C/C++ 库、例 84 动态链接 MFC 扩展库、例 85 资源库。这套分类到今天一个字都没过时——DLL 的三种形态依然就是这三种，只是构建工具从 VC6 IDE 换成了命令行。

## 1. 为什么是三种形态

| 形态 | 链接的运行时 | 能导出什么 | 典型场景 |
|---|---|---|---|
| 普通 Win32 DLL | 自选（/MD 或 /MT） | C 函数、POD 数据 | 算法库、硬件接口、跨语言组件 |
| MFC 扩展 DLL | **必须共享 MFC**（_AFXDLL） | MFC 类、CString、CObject* | 大型 MFC 应用的模块化拆分 |
| 资源专用 DLL | 无代码 | 资源（字符串/位图/对话框） | 多语言包、换肤包 |

判据就一条：**要不要把 MFC/CRT 的对象扔过模块边界**。扔，就得扩展 DLL（两边共享同一套运行时）；不扔，普通 DLL 最稳——任何语言、任何运行时的宿主都能加载。

## 2. 普通 Win32 DLL：C 接口是铁律

示例 33 的 `mathlib.dll.cpp` 演示了教科书式写法：

```cpp
extern "C" {

__declspec(dllexport) int Add(int a, int b) { return a + b; }

// 返回字符串：调用方给缓冲区，DLL 只往里写
__declspec(dllexport) void GetGreeting(wchar_t* buf, int cch);

// 用 DLL 自己的堆分配，配套 ExportFree 释放
__declspec(dllexport) wchar_t* AllocReport(int value);
__declspec(dllexport) void ExportFree(void* p);
}
```

四条纪律：

1. **`extern "C"`**：掐灭 C++ 名字修饰。不加它，x64 下导出名是 `?Add@@YAHHH@Z` 这类装饰名，GetProcAddress 按名找不到（得用 Dependency Walker 查真名或用 .def 文件）。
2. **跨边界只传 POD**：`int`、`wchar_t*`、定长结构体。`std::string`、`CString`、`std::vector` 都不行——两边 CRT 版本/堆不一致就是未定义行为。
3. **字符串用“调用方缓冲区”或“配对 free 函数”**：谁分配谁释放（DLL 的堆分配，DLL 的函数释放）。示例里 `AllocReport`/`ExportFree` 配对就是这个协议的显式化。
4. **DllMain 里别干事**：只做 `DisableThreadLibraryCalls`、建私有堆这类轻量初始化。加载器锁（loader lock）里调 COM、加载别的 DLL、同步等待，都是死锁套餐。

## 3. 隐式链接 vs 显式链接

**隐式链接**：链接期把 `mathlib.lib`（导入库）喂给链接器，进程启动时加载器自动映射 DLL，符号像本地函数一样直接调。示例 33 的 exe 侧：

```cpp
extern "C" __declspec(dllimport) int Add(int a, int b);   // dllimport！
```

代价是**启动即依赖**：DLL 不在（或位数不对），弹“找不到 xxx.dll”对话框，程序起不来。

**显式链接**：运行时才决定加载谁——插件、可选功能、按需加载大模块：

```cpp
typedef int (*MultiplyFn)(int, int);
HMODULE h = ::LoadLibraryW(L"mathlib.dll");
MultiplyFn fn = (MultiplyFn)::GetProcAddress(h, "Multiply");
int r = fn(7, 6);
::FreeLibrary(h);
```

三个细节：

- `LoadLibrary` 找不到时 `GetLastError()` = 126（ERROR_MOD_NOT_FOUND）；**位数不匹配**（32 位进程加载 64 位 DLL）错误码 193（ERROR_BAD_EXE_FORMAT）——排查“明明就在同目录”的问题先看这个。
- DLL 搜索顺序：exe 目录 → 系统目录 → PATH……显式加载**最好带全路径**或确保 exe 同目录。
- 引用计数：隐式链接也持有一份；`FreeLibrary` 只减你的那份，归零才真卸载。示例 33 里显式 Load/Free 一次后隐式链接的那份仍在，进程退出时统一卸。

## 4. MFC 扩展 DLL：把类扔过边界

扩展 DLL 的全部秘密在**三件套**（示例 33 的 `shape.dll.cpp`）：

```cpp
// 1. 共享头：DLL 侧编译带 /D_AFXEXT，AFX_EXT_CLASS = dllexport；
//    exe 侧无此宏，同一句展开为 dllimport —— 一份声明两边用
class AFX_EXT_CLASS CShape : public CObject {
public:
    virtual void Draw(CDC* pDC, const CRect& rc) const = 0;
    virtual CString Describe() const = 0;
};

// 2. DllMain 里挂模块
static AFX_EXTENSION_MODULE g_shapeState(FALSE);

extern "C" BOOL APIENTRY DllMain(HINSTANCE hInst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        if (!AfxInitExtensionModule(g_shapeState, hInst))
            return FALSE;
        new CDynLinkLibrary(g_shapeState, TRUE);   // 3. 类表并进应用
    }
    return TRUE;
}
```

第三步最容易被忽略却最有价值：`CDynLinkLibrary(state, TRUE)` 把本模块的 **CRuntimeClass 类表**并进应用。效果是 exe 里可以**按名字造对象**：

```cpp
CObject* obj = CRuntimeClass::CreateObject(_T("CEllipseShape"));   // 纯字符串耦合！
```

这就是插件系统的原型：宿主只认接口基类 + 类名字符串，实现类躺在 DLL 里。第 15 章的运行时类反射在这里完成了跨模块的合流。

**为什么扩展 DLL 必须共享 MFC**：导出的 `CShape` 带 MFC 的 vtable、RTTI、CString 成员——exe 和 DLL 必须操作**同一套** MFC 代码（mfc140u.dll），否则 `dynamic_cast`、`delete 基类指针` 全是行为未定义。这也解释了为什么扩展 DLL 不能在静态链接 MFC 的 exe 里用。

跨边界分配的内存规矩在扩展 DLL 里依然成立，只是边界变成了“exe 的 CRT 堆”和“DLL 的 CRT 堆”——共享 MFC 时两边都用同一个 msvcp/vcruntime DLL，`new`/`delete` 跨边界通常能工作，但**工程实践上仍建议谁 new 谁 delete**（示例 33 里 exe `unique_ptr<CShape>` 管理全生命周期，就是这个纪律的落地）。

## 5. 资源专用 DLL

只有资源没有代码的 DLL 是**多语言方案**的正解（第 04 章讲过另一半：rc 里多 LANGUAGE 块）：

```cpp
HMODULE hRes = ::LoadLibraryW(L"strings.dll");     // 英文包 / 中文包 / 未来任意语言包
wchar_t buf[256] = {};
::LoadStringW(hRes, 100, buf, 128);                // 注意第一个参数是模块句柄！
```

- 构建：`rc` 编译 `.res` → `link /DLL /NOENTRY`（无入口点）。示例 33 的 `strings.dll.rc` 走的就是 build.ps1 里 `*.dll.rc` 约定的这条路。
- `AfxSetResourceHandle(hRes)` 可以让**整个 MFC 资源加载链**（LoadIcon/LoadMenu/CDialog 全家族）改从资源 DLL 取——应用启动时按用户语言选包，即刻完成界面切换。
- 资源 ID 两边要一致：惯例是把 resource.h 里的 ID 段约定成契约，各语言包的 rc 都 include 同一份。

## 6. 构建脚本视角

示例 33 在 build.ps1 里引入了 DLL 目标约定，值得知道它做了什么（你的真实项目里大概率是 CMake/MSBuild 干同样的事）：

- `xxx.dll.cpp` → 编译时加 `/D_AFXEXT`，`link /DLL /OUT:xxx.dll /IMPLIB:xxx.lib` 产出 DLL + 导入库；
- `xxx.dll.rc` → `rc` 后 `link /DLL /NOENTRY` 产出纯资源 DLL；
- exe 链接时自动 `/LIBPATH:build` + 本目录所有 DLL 的 `.lib`——隐式链接开箱即用；
- 运行时要求 DLL 与 exe 同目录（build\ 下天然满足）。

## 实战建议

- 插件系统：定义**纯虚接口基类**（不依赖 CRT 对象）放共享头，宿主 `LoadLibrary` + `GetProcAddress("CreatePlugin")` 工厂函数，比扩展 DLL 的耦合低得多。扩展 DLL 适合“自家应用模块化”，接口 DLL 适合“给第三方开放”。
- 版本管理：DLL 导出的 C 接口加版本探测函数（`GetAbiVersion()`），宿主加载后先比对再调用——ABI 变更不至于崩得莫名其妙。
- 调试：DllMain 的 `OutputDebugString` 痕迹（示例 33 留了）在 DbgView/VS 输出窗口可见，排查“DLL 到底加载没加载”最直接。
- dumpbin 看 DLL：`dumpbin /exports mathlib.dll` 列导出（第 21 章提过 dumpbin 要写临时 .bat 再跑的坑）。

## 常见坑（实测）

1. **exe 想跑，DLL 得先到**：build\ 里删掉 mathlib.dll 再启动 33_dll.exe，启动即弹“找不到 DLL”。部署时 DLL 是 exe 的一部分（第 23 章打包清单要把它们算进去）。
2. **`__declspec(dllexport)` 与 `dllimport` 用混**：共享头用 `AFX_EXT_CLASS` 一份两用是正解；手写两份声明迟早改漂移。
3. **普通 DLL 导出 C++ 类**（没 extern "C" 没 AFX_EXT）：能编过，但只有同版本 MSVC 的宿主能用——名修饰 + vtable 布局都是实现细节。要跨就出 C 接口，要自家模块就老实扩展 DLL。
4. **扩展 DLL 忘了 `new CDynLinkLibrary`**：类导出了、链接也通了，但 `CRuntimeClass::CreateObject("CEllipseShape")` 返回 null——类表没并上。示例 33 的按钮 4 专门演示这条链的验证方法。
5. **资源 DLL 的 LoadString 传了 nullptr 当模块句柄**：取到的是 exe 自己的字符串——内容“不对”但不出错，极难察觉。

---

上一章：[32 UI 线程深入：自有窗口、线程间消息与竞争](32-ui-threads.md) · 下一章：[34 ODBC 数据库：CDatabase / CRecordset / RFX](34-odbc.md)
