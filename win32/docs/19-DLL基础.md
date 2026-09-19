# 第 19 章 DLL 基础：创建、导出与链接

> 本章回答的问题：DLL 和 EXE 到底差在哪？隐式链接和显式链接怎么选？`DllMain` 里为什么不能乱写？Windows 按什么顺序找 DLL？为什么依赖列表里会出现 `api-ms-win-*` 这种怪名字？

## 11.1 DLL 是什么

DLL（Dynamic-Link Library）与 EXE 一样都是 **PE（Portable Executable）格式的模块**，本质区别只有两条：

- EXE 有入口被系统启动为进程；DLL 没有独立生命，必须被加载进某个进程的地址空间；
- DLL 通过**导出表**公布自己的函数，EXE 通过**导入表**声明依赖。

价值在于三件事：**共享代码**（一份系统 DLL 供全部进程映射，物理内存只驻留一份）、**模块化**（功能拆分、按需加载）、**插件机制**（运行时决定加载谁）。整个 Windows 的系统功能就是一大组 DLL：`kernel32.dll`、`user32.dll`、`d3d12.dll`……你调 Win32 API 的每一步都在跨 DLL。

## 11.2 两种链接方式

### 隐式链接（implicit / load-time linking）

链接时挂上导入库，加载器在进程启动时自动加载 DLL 并填好函数地址——你在第 2 章链接命令里写的 `user32.lib` 就是这个机制：

```cpp
// 直接调用，像普通函数一样
MessageBoxW(nullptr, L"hi", L"t", MB_OK);
// 前提：链接了 user32.lib；运行时 user32.dll 必须能被找到，否则进程起不来
```

优点：零样板代码。缺点：**缺 DLL 进程直接起不来**（报错弹窗"无法启动此程序，缺少 xxx.dll"）。

### 显式链接（explicit / run-time linking）

运行时按需加载：

```cpp
HMODULE hMod = LoadLibraryW(L"demo.dll");      // 或 LoadLibraryExW 带更多标志
if (!hMod) { /* GetLastError() */ }

using AddFunc = int (WINAPI*)(int, int);        // ★ 函数指针签名必须与导出完全一致
AddFunc add = (AddFunc)GetProcAddress(hMod, "Add");
// GetProcAddress 返回 FARPROC，必须显式转成正确签名——转错 = 调用约定/参数错乱，诡异崩溃
if (add) {
    int r = add(1, 2);
}

FreeLibrary(hMod);      // 引用计数减一，归零才真正卸载
```

适用场景：**插件系统**（扫描目录逐个加载）、**可选功能**（缺 DLL 只禁用该功能）、**延迟加载**（启动提速）、**绕过版本差异**（新 API 不存在时降级——第 9 章 DPI 的兼容写法就可以这样实现）。

工程惯例：插件接口用纯 C 风格导出（`extern "C"`），避免 C++ 名字修饰（`?Add@@YAXHH@Z` 这种）与编译器版本绑死：

```cpp
// DLL 侧
extern "C" __declspec(dllexport) int Add(int a, int b) { return a + b; }

// 头文件里通常做成宏，一个宏同时服务导出方与导入方：
#ifdef MYLIB_EXPORTS
#  define MYLIB_API __declspec(dllexport)
#else
#  define MYLIB_API __declspec(dllimport)   // 隐式链接的使用方拿到这个
#endif
extern "C" MYLIB_API int Add(int a, int b);
```

`.def` 文件是另一种导出方式（可给符号重命名/定序号），如今主要见于需要稳定序号导出的系统级组件，新代码用 `__declspec(dllexport)` 即可。

## 11.3 `DllMain`：最小化纪律

DLL 可选的初始化入口：

```cpp
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD reason, LPVOID reserved) {
    switch (reason) {
    case DLL_PROCESS_ATTACH:  // 本 DLL 被某进程加载（首次）
        DisableThreadLibraryCalls(hinstDLL);  // 不关心线程事件就关掉，减开销
        break;
    case DLL_PROCESS_DETACH:  // 被卸载
        break;
    case DLL_THREAD_ATTACH:   // 该进程每建一个线程（可用 DisableThreadLibraryCalls 关）
    case DLL_THREAD_DETACH:
        break;
    }
    return TRUE;
}
```

**Loader Lock** 是这里的核心约束：`DllMain` 执行期间加载器持有全局锁。所以 `DllMain` 里**禁止**：

- 调用 `LoadLibrary`/`GetProcAddress` 之外的任何可能再加载 DLL 的操作（COM 初始化、`CreateProcess` 等都在列）；
- 等待同步对象（可能死锁：别的线程可能正等你加载完成）；
- 调用 CRT 的用户回调、创建线程后等它跑。

正确姿势：`DLL_PROCESS_ATTACH` 里只做"记下模块句柄、初始化少量原始状态"这类零风险工作，**复杂的初始化推到显式的导出初始化函数**（如 `MyLib_Initialize()`），由使用方在 `main` 后主动调用。文档《Dynamic-Link Library Best Practices》值得通读，这里的禁令清单只增不减。

## 11.4 DLL 搜索顺序

`LoadLibraryW(L"foo.dll")` 传**裸文件名**时，Windows 按固定顺序找：

```text
1. 应用程序所在目录（exe 旁边）
2. 系统目录  System32
3. 16 位系统目录（兼容残留）
4. Windows 目录
5. 当前工作目录        ← 安全隐患所在
6. PATH 环境变量目录
```

（启用 SafeDllSearchMode 后 5、6 之间会插入"先查 System32 再查当前目录"的顺序——现代系统默认启用。）要点：

- **exe 旁边的 DLL 优先级最高**——"绿色软件把第三方 DLL 放自己目录"就是靠这条；
- **永远不要依赖"当前目录"**：双击不同快捷方式启动时当前目录不同，行为漂移；
- 需要私有 DLL 集合时用 **application directory + 清单** 或 `SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_APPLICATION_DIR | ...)` 收紧搜索面；
- 传**绝对路径**最稳：`LoadLibraryW(L"C:\\MyApp\\plugins\\demo.dll")`；
- 依赖缺失的典型报错：加载时 `ERROR_MOD_NOT_FOUND`（找不到依赖 DLL 本身）或 `ERROR_PROC_NOT_FOUND`（DLL 在，导出函数不在——版本不匹配）。

## 11.5 API Set：为什么依赖列表里全是 `api-ms-win-*`

用 `dumpbin /dependents some.exe` 或工具查看依赖，常看到：

```text
api-ms-win-crt-runtime-l1-1-0.dll
api-ms-win-core-file-l1-2-1.dll
ext-ms-win-ntuser-window-l1-1-0.dll
```

这些**不是真实文件**，是第 1 章提过的 **API Set 逻辑名**：加载器遇到这类名字时，查进程的 API Set 映射表，把请求转发到真正的实现 DLL（比如上面第一个会落到 `ucrtbase.dll`）。

设计动机：系统 DLL 需要不断重构拆分，如果应用直接依赖物理文件名，每次重构都破坏兼容；引入"逻辑名 → 物理名"的间接层后，**重排内部结构对应用完全透明**。这也解释了 Win8+ 程序的依赖为什么看起来"虚"——虚的是名字，实的是兼容承诺。链接时你仍然只写 `kernel32.lib` 这类导入库，导入库内部负责映射，开发者日常无感；知道机制是为了读得懂工具输出、排查"为什么这台机器缺这个 api-ms 文件"（答案通常是它对应的目标 DLL 或更新缺失）。

## 11.6 PE 格式速览

DLL/EXE 都是 PE 文件，结构从上到下：

```text
DOS 头（MZ 魔数）
NT 头  ── 签名 PE\0\0 + 文件头（机器类型、节数量）+ 可选头（入口点、Subsystem、DataDirectory）
节表   ── .text（代码） .data（可写数据） .rdata（只读数据/导入表） .rsrc（资源） .reloc（重定位）
```

导入表（依赖谁、要哪些函数）、导出表（给别人什么）就在可选头的 DataDirectory 里指向。理解 PE 的回报：读得懂 `dumpbin`/`Dependencies` 工具输出、理解为什么 DLL 能被内存映射加载（第 15 章的映射机制！）、理解签名与防篡改。深入读《Peering Inside the PE》或用工具对照真文件，一天即可入门。

## 11.7 资源段：exe 里还能住什么

`.rsrc` 节存放资源：图标、光标、对话框模板、字符串表、版本信息、自定义二进制。第 10 章的对话框模板就住这里。资源的身份 = 类型 + 名称 + 语言，代码侧统一用 `FindResource`/`LoadResource`/`LockResource` 三步取：

```cpp
HRSRC rc = FindResourceW(hInst, MAKEINTRESOURCEW(IDR_DATA1), L"MYDATA");
HGLOBAL h = LoadResource(hInst, rc);       // 注意：这个"句柄"不需要释放
const void* data = LockResource(h);
DWORD size = SizeofResource(hInst, rc);
```

（`LoadResource` 是少数**不配对释放**的加载 API——资源随模块常驻。）用资源而非单独文件携带数据的理由：单文件分发、完整性、防误删。

## 11.8 易错清单

| 错误 | 后果 |
|------|------|
| 函数指针签名与导出不一致（漏 `__stdcall`/参数错） | 传参错乱、栈损坏，崩溃点飘忽 |
| C++ 类/模板跨 DLL 边界导出 | 各模块 CRT/编译器版本不同则行为未定义；只导出 C 接口或纯虚接口 |
| 在 A.DLL 分配、在 B.EXE 释放内存 | 若两边用不同 CRT 堆，释放崩溃；统一分配释放方，或明确共享堆 |
| `DllMain` 里做复杂初始化 | loader lock 死锁/加载失败 |
| 依赖"当前目录"加载 DLL | 行为随启动方式漂移；DLL 劫持攻击面 |
| `LoadLibrary` 不检查返回值 | 空句柄往下传，`GetProcAddress` 崩溃 |

---

**下一章**：[第 20 章 DLL 进阶与插件系统](20-DLL进阶与插件系统.md)——插件架构实战、资源段、PE 与 API Set 的秘密。
