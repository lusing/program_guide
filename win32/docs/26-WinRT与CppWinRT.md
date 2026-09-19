# 第 26 章 WinRT 与 C++/WinRT

> **本章回答的问题**：WinRT 和 COM、和 .NET 是什么关系？`IInspectable` 是什么？C++/WinRT 投影怎么用、工具链要配什么？`co_await` 怎么消费 WinRT 异步？无打包的 Win32 程序调 WinRT 有什么边界？
>
> **前置章节**：第 22~24 章（COM 全家桶——WinRT 就是它们的直系后代）、第 12 章（`hstring` 是宽字符串的近亲）。
>
> **你将做出什么**：一个从 Win32 控制台调用 WinRT 的完整演示（`examples/29_winrt_modern`）：现代日期格式化 + C++20 协程消费线程池异步。

本章示例：`examples/29_winrt_modern/main.cpp`。

## 26.1 WinRT 是什么：COM 的现代进化

第 1 章说过 Win8 时代微软想用 WinRT（Windows Runtime）"取代"Win32，结果证明 UI 层可换、系统层不可换。WinRT 最终的形态非常有意思：**它成了"新版系统 API 的专属发布渠道"**——通知、后台任务、现代传感器、蓝牙、应用生命周期，这些新能力只通过 WinRT 暴露。想用它们？就从 Win32 世界伸手动一动 WinRT。

血统上，**WinRT 是 COM 的直系后代**：

```text
IUnknown                     （COM，1993）
 └─ IInspectable             （WinRT，2012）
     └─ 各投影类型的默认接口
```

`IInspectable` 在 `QueryInterface/AddRef/Release` 之上只加了三个方法（`GetIids/GetRuntimeClassName/GetTrustLevel`）——**本质还是那套 vtable 二进制契约**。你 24 章手写的组件与 WinRT 组件在 ABI 层是同一物种。

三处进化值得点名：

1. **元数据（.winmd）**：每个 WinRT 组件自带完整类型信息（类/方法/事件/参数），机器可读——语言投影由此自动生成绑定，不再需要 IDL 手工分发头文件；
2. **命名空间化的类库**：`Windows.Foundation`、`Windows.Storage`……真正的面向对象 API（类、属性、事件），告别 32 年的扁平函数表；
3. **异步优先**：任何可能超 50ms 的操作都以 `IAsyncAction`/`IAsyncOperation<T>` 返回——从协议层杜绝卡 UI。

## 26.2 激活机制：`RoGetActivationFactory`

COM 的创建是"CLSID 查注册表 → DLL → 类厂"；WinRT 换成"**类全名字符串 → 激活工厂**"：

```text
COM:   CoCreateInstance(CLSID_Calc, ...)          按 GUID 找
WinRT: RoGetActivationFactory(L"Windows.Globalization.DateTimeFormatting
                                 .DateTimeFormatter", ...)
                                             按 "命名空间.类名" 找
```

`RoGetActivationFactory`（在 api-ms-win-core-winrt 里，导入库 `WindowsApp.lib`）内部同样是注册表/清单查找 + DLL 加载 + 工厂获取——**机制是 COM 的，命名是现代的**。理解这一点你就明白：用 C++/WinRT 不等于抛弃了 COM，而是 COM 被包装得看不见了。

## 26.3 C++/WinRT 投影：头文件即绑定

**C++/WinRT** 是微软官方的 C++ 语言投影（现代版，取代了 WRL 和 C++/CX）。"投影"= 把 .winmd 元数据生成的 ABI 调用，包装成自然的现代 C++ 类型：

```cpp
#include <winrt/Windows.Globalization.DateTimeFormatting.h>   // 每命名空间一个头

winrt::Windows::Globalization::DateTimeFormatting::DateTimeFormatter fmt(
    L"{year.full}年{month.integer(2)}月{day.integer(2)}日");
auto s = fmt.Format(winrt::clock::now());      // 投影方法：像普通 C++ 类
```

使用侧三件套（28/29 示例的构建差异全在这）：

| 件 | 内容 |
|----|------|
| 头文件 | SDK 自带：`Include\<ver>\cppwinrt\winrt\*.h`（编译加 `/I` 指向 cppwinrt 目录） |
| 链接库 | `WindowsApp.lib`（一个伞库，含 RoGetActivationFactory 等） |
| 语言标准 | `/std:c++20`（协程等语言特性要求） |

投影的价值主张，29 示例里那句"没有手工引用计数"就是注脚：**工厂、接口、引用计数、HSTRING 全部被 RAII 化**——`winrt::hstring` 是字符串、智能指针管生命周期、异常转 C++ 异常。你在 23 章写的样板，投影全包了。

## 26.4 `init_apartment`：老朋友换新衣

```cpp
winrt::init_apartment(winrt::apartment_type::single_threaded);   // = CoInitializeEx(STA)
```

内部就是 `CoInitializeEx`（22.7 的套间规则原封不动）。GUI 线程用 `single_threaded`（STA），后台线程按需 `multi_threaded`。忘了初始化？和 COM 一样给你 `CO_E_NOTINITIALIZED`。

## 26.5 实战：全球化格式化（29 示例第一段）

```cpp
DateTimeFormatter date{ L"{year.full} 年 {month.integer(2)} 月 {day.integer(2)} 日" };
DateTimeFormatter time{ L"{hour.integer(2)}:{minute.integer(2)}:{second.integer(2)}" };
auto now = winrt::clock::now();
wprintf(L"%s\n", date.Format(now).c_str());    // hstring 的 .c_str() 互操作
```

三个观察点：模板语法（`{...}` 占位）是 WinRT 的**全球化格式标准**，用户地区变化自动适配——这比手工 `swprintf` 拼 "2026-09-19" 专业一个量级；`winrt::clock::now()` 返回 WinRT 的 `DateTime`（就是 FILETIME 的语义）；`hstring.c_str()` 返回 `wchar_t const*`，与 `wprintf` 零成本互操作。

## 26.6 异步模型与 C++20 协程

WinRT 一切耗时操作返回 `IAsyncAction`（无结果）或 `IAsyncOperation<T>`（有结果）。**C++/WinRT 把它们做成了协程友好的 awaiter**——用 `/std:c++20` 的 `co_await` 直译"等它完成"：

```cpp
// 29 示例：协程函数提交线程池工作并等待
static wf::IAsyncAction WorkAsync() {
    co_await winrt::Windows::System::Threading::ThreadPool::RunAsync(
        [](auto&&) { /* 线程池上执行 */ });
    // co_await 之后继续——写法是同步的，执行是异步的
}

int wmain() {
    auto action = WorkAsync();
    action.get();    // 控制台场景：阻塞等完成
}
```

规则两条：

1. **`.get()` 阻塞**只配控制台/初始化路径——**UI 线程禁用**（等于 STA 里死等，28 章讲过的死锁配方）；
2. UI 里正确的姿势是"一路协程到底"：事件处理器里 `co_await SomethingAsync(); UpdateUI();`——`co_await` 恢复时自动回到原套间，线程安全免费附送。

对照记忆：第 14 章的 `PostMessage` 回传模式解决的是同一个问题（后台结果回 UI）；协程是它的现代语法糖（编译器替你生成状态机与恢复调度）。

## 26.7 无打包 Win32 的能力边界

从 Win32 程序（未走 MSIX 打包、无 Store 身份）调 WinRT，绝大多数 API 直接可用（29 示例就是明证），但两类能力有边界：

- **需要身份的**：Toast 通知要求应用有 AUMID（AppUserModelID）+ 开始菜单快捷方式的配合，否则系统不知道"通知是谁发的"；解决法是 `SetCurrentProcessExplicitAppUserModelID` + 安装期建快捷方式（文档《Toast notifications from desktop apps》），或干脆 MSIX 打包；
- **需要能力的**：位置、摄像头、麦克风等在打包世界由 manifest 声明能力；无打包程序走系统级隐私设置（用户首次使用弹同意框）。

工程结论：**工具类程序直接调；要通知/商店分发，再研究打包**。第 30 章学习地图的 MSIX 一支由此展开。

## 26.8 WinRT 地图：哪些现代能力只在这里

| 领域 | 命名空间 | 一句话 |
|------|---------|--------|
| 通知 | `Windows.UI.Notifications` | Toast/磁贴（注意 26.7 的身份要求） |
| 文件/存储 | `Windows.Storage` | 现代文件 API（异步优先、`StorageFolder`） |
| 设备 | `Windows.Devices.*` | 蓝牙/串口/传感器 |
| 后台 | `Windows.ApplicationModel.Background` | 后台任务 |
| 全球化 | `Windows.Globalization` | 26.5 实战 |
| 线程 | `Windows.System.Threading` | 26.6 实战 |

选型法则一条：**老能力（文件/进程/内存）留在 Win32——它们更直接；新能力只在 WinRT——只能来这调**。

## 26.9 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| `CO_E_NOTINITIALIZED` | 忘 `init_apartment` | 26.4 开场白 |
| 大量"未声明的标识符" | 没包含对应 `winrt/Windows.X.h` | 每命名空间一个头（26.3） |
| 链接错误 `RoGetActivationFactory` | 忘链 `WindowsApp.lib` | 26.3 三件套 |
| UI 线程 `get()` 卡死 | STA 里阻塞等自己 | 一路协程（26.6） |
| 编译报协程头错误 | 语言标准低于 C++20 | `/std:c++20` |
| Toast 发不出 | 无 AUMID/快捷方式 | 26.7 身份要求 |
| 找不到 cppwinrt 头 | SDK 没装 UWP 桌面组件 | 装齐 SDK（29 的 build.ps1 有自动探测） |

## 26.10 小结

1. WinRT = COM 直系后代（IInspectable）+ 元数据 + 类库化 + 异步优先；新系统能力的唯一入口。
2. 激活按"命名空间.类名"找工厂，机制仍是 COM 那套——投影是包装不是替换。
3. C++/WinRT 三件套：cppwinrt 头 + WindowsApp.lib + C++20；样板全消失（RAII 化）。
4. 异步 `co_await` 直译；`.get()` 只配控制台；UI 里协程到底。
5. 无打包边界在"身份/能力"两处，工具程序基本无感。

## 26.11 动手练习

1. 把 29 示例换成 `Windows.Storage`：`co_await KnownFolders::GetFolderAsync(KnownFolderId::Documents)` 后列前 5 个条目名（`GetItemsAsync()`）——异步文件枚举初体验。
2. 写一个"开机到现在的毫秒数"小工具：`GetSystemTimeAsFileTime`（18 章）与 `winrt::clock` 双算对照，验证相等。
3. 概念题：为什么 `hstring` 不直接用 `std::wstring`？（提示：HSTRING 的 ABI 与引用计数；投影在边界做转换。）

---

**下一章**：[第 27 章 Windows 服务与事件日志](27-Windows服务与事件日志.md)——后台服务的完整生命。
