# 34. OS 集成：进程、线程、文件与配置

WinUI 3 不是"逃离系统编程"。一个 WinUI 3 应用就是一个 Windows 进程：有线程、有句柄、能用全部 Win32/WinRT 能力。这一篇讲清 UI 工程里最常遇到的系统集成点：线程边界、文件访问、配置存储、子进程，以及对象生命周期。

> 原教程此章包含大量通用 OS 编程内容（纤程、自写线程池、Fork-Join、Future），已移除——那些属于系统编程教程的主题。这里只保留与 WinUI 3 工程直接相关、且容易踩坑的部分。

## 34.1 线程边界：UI 线程与 DispatcherQueue

WinUI 3 应用的线程模型：

- **UI 线程**：单线程 apartment（STA），拥有全部 UI 对象，跑消息循环
- **后台线程**：线程池或自建，做耗时工作，**不能触碰任何 UI 对象**

跨线程调度的枢纽是 `DispatcherQueue`——UI 线程的任务队列：

```cpp
#include <winrt/Microsoft.UI.Dispatching.h>

using namespace winrt::Microsoft::UI::Dispatching;

// 在 UI 线程上抓取（通常存在成员里）
m_dispatcherQueue = DispatcherQueue::GetForCurrentThread();

// UI → 后台（线程池）：这个方向照常用协程
co_await winrt::resume_background();

// 后台 → UI：不要 co_await resume_foreground(m_dispatcherQueue)！
// WinUI 3 的 Microsoft.UI.Dispatching.DispatcherQueue 没有 resume_foreground 重载
// （换 Windows.System 的同名类型能编过，但运行时永不恢复）。正确做法是 TryEnqueue：
m_dispatcherQueue.TryEnqueue([strong = get_strong()] { strong->UpdateUi(); });
// 完整说明见 08 篇 8.7.1；下面 34.1 的手工线程模式也是走 TryEnqueue
```

自建线程往 UI 线程投递工作，用 `TryEnqueue`。**优先用 [32 篇](./32-binding-mvvm.md) 32.7 的协程写法**；只有"要长期跑的独立线程"（轮询、监听、串口读取）才需要下面这种手工模式：

```cpp
// 头文件里持为成员：std::jthread m_worker;
// jthread 析构时自动请求停止并 join，不会像 detach() 那样线程失控
winrt::weak_ref<winrt::MyApp::TasksViewModel> weakVm{ m_viewModel };
auto queue = m_dispatcherQueue;

m_worker = std::jthread([weakVm, queue](std::stop_token st)
{
    winrt::init_apartment(winrt::apartment_type::multi_threaded);  // 后台线程要碰 WinRT 对象就必须先加入 MTA

    while (!st.stop_requested())
    {
        auto result = PollOnce();                 // 后台：只产生纯数据

        // TryEnqueue 返回 false 说明 UI 队列已关闭（进程正在退出）
        if (!queue.TryEnqueue([weakVm, result]
        {
            if (auto vm = weakVm.get())           // 升级失败 = 页面已销毁，直接放弃
            {
                vm.LoadFrom(result);
            }
        }))
        {
            break;
        }
    }
});
```

三个必须做对的点：

- **不要用 `detach()`**。线程生命周期要有主人，否则它会在页面销毁后继续访问 `this` —— 这正是 34.5 讲的循环引用之外的第二类悬空访问
- **回调里只持弱引用**（`winrt::weak_ref`）+ `DispatcherQueue`，不持 UI 对象强引用；`TryEnqueue` 的 lambda 里再 `get()` 升级
- **后台线程调用任何 WinRT API 前要先 `init_apartment`**（一般是 MTA）。漏了这行，报出来的错和真实原因差得很远

工程纪律（完整异步模式见 [32 篇](./32-binding-mvvm.md) 32.7）：

```text
后台线程：只产生数据、只持有纯数据对象
      ↓ 结果通过 DispatcherQueue 回流
UI 线程：更新 ViewModel 状态 → 绑定刷界面
```

## 34.2 文件访问

### 34.2.1 WinRT 文件 API

WinUI 3 应用首选 WinRT 的 `StorageFile` 异步 API：

```cpp
using namespace winrt::Windows::Storage;

winrt::Windows::Foundation::IAsyncAction SaveTasksAsync(winrt::hstring const& content)
{
    auto folder = ApplicationData::Current().LocalFolder();   // 应用数据目录
    auto file = co_await folder.CreateFileAsync(
        L"tasks.json", CreationCollisionOption::ReplaceExisting);
    co_await FileIO::WriteTextAsync(file, content);
}
```

这些 API 本身就是异步的，在 UI 线程 `co_await` 不会卡界面。常用成员：

- `StorageFile::GetFileFromPathAsync(path)`：按路径打开
- `FileIO::ReadTextAsync / WriteTextAsync`：文本读写
- `ApplicationData::Current().LocalFolder()`：应用专属可写目录（打包应用的用户数据归系统管理，卸载即清）

#### 非打包应用拿不到 `ApplicationData`（两个类型都不行——实测）

`Windows.Storage.ApplicationData::Current()` 的语义建立在**包身份**上：非打包（unpackaged）进程没有包身份，这行代码运行时会直接抛异常（[33 篇](./33-theming-packaging.md) 33.6.2 的两种形态在这里就分岔了）。Windows App SDK 提供了一个同名但不同命名空间的类型 `Microsoft.Windows.Storage.ApplicationData`，静态入口是 `GetDefault()`——**很多资料说它是"非打包也能用"的回退，这是错的**。

> **实测（WASDK 1.8，`examples/34-os-integration/` 非打包运行）**：`Microsoft.Windows.Storage.ApplicationData::GetDefault().LocalPath()` 同样抛 `hresult_error`，消息是 **"该进程没有程序包标识符"**（no package identity）。也就是说 **`GetDefault()` 和 `Current()` 一样依赖包身份**，不是非打包的救命稻草。（类型成员集本身是元数据实测：`Microsoft.Windows.Storage.winmd` 里确有 `LocalPath` / `LocalFolder` / `LocalCachePath` / `TemporaryPath` / `LocalSettings` / `ClearAsync` 及 `GetForUser` / `GetForPackageFamily`——但它们在非打包进程里都在 `GetDefault()` 这一步就抛了。）

非打包进程要一个"每用户可写目录"，可靠做法是**回到 Win32**：`%LOCALAPPDATA%` 拼上你的应用名。`examples/34-os-integration/` 里就是这样兜底的：

```cpp
#include <winrt/Microsoft.Windows.Storage.h>

winrt::hstring ResolveLocalDir()
{
    // 先试 WASDK 类型：打包进程（或已给身份）会成功
    try
    {
        return winrt::Microsoft::Windows::Storage::ApplicationData::GetDefault().LocalPath();
    }
    catch (winrt::hresult_error const&)
    {
        // 非打包：GetDefault() 抛 "该进程没有程序包标识符"，退回 %LOCALAPPDATA%
        wchar_t buf[MAX_PATH]{};
        DWORD n = GetEnvironmentVariableW(L"LOCALAPPDATA", buf, MAX_PATH);
        if (n == 0 || n >= MAX_PATH) { return L"."; }
        return winrt::hstring{ std::wstring(buf) + L"\\OsIntApp" };
    }
}
```

实测这条兜底在非打包下解析出 `C:\Users\<you>\AppData\Local\OsIntApp`。

两条路二选一，取决于你的部署形态：

- **就是非打包**（绿色 exe、开发期直接跑）→ 用上面的 `%LOCALAPPDATA%` / `SHGetKnownFolderPath(FOLDERID_LocalAppData)` 兜底，别指望 `ApplicationData`
- **想要 `ApplicationData` 的托管语义**（自动清理、按用户/包族隔离）→ 给应用**包身份**：打完整 MSIX，或挂一个稀疏包（sparse package，见 [33 篇](./33-theming-packaging.md)）。有了身份，`GetDefault()` 就不抛了

一个会浪费你半小时的坑：两个类型都叫 `ApplicationData`，如果同一个 `.cpp` 里同时写了 `using namespace winrt::Windows::Storage;` 和 `using namespace winrt::Microsoft::Windows::Storage;`，编译器会报歧义——像上面那样显式写全 `winrt::Microsoft::Windows::Storage::ApplicationData::GetDefault()` 即可。

### 34.2.2 文件选择器：Windows App SDK picker

桌面应用里的文件选择器必须和"哪个窗口"绑定，否则弹不出来。Windows App SDK 提供了专门为桌面设计的 picker——`Microsoft.Windows.Storage.Pickers`（本机 1.8 元数据实测，见文末版本说明），**窗口归属通过构造函数的 `WindowId` 传入**，不再需要手写 HWND 互操作：

```cpp
#include <winrt/Microsoft.Windows.Storage.Pickers.h>

using namespace winrt::Microsoft::Windows::Storage::Pickers;

winrt::Windows::Foundation::IAsyncAction MainWindow::PickFileAsync()
{
    // AppWindow().Id() 就是这个窗口的 WindowId
    FileOpenPicker picker{ AppWindow().Id() };
    picker.FileTypeFilter().Append(L".json");

    auto result = co_await picker.PickSingleFileAsync();
    if (!result) { co_return; }               // 用户取消

    // 新 picker 只给字符串路径，不再返回 StorageFile
    winrt::hstring path = result.Path();
    m_viewModel.LoadFrom(path);
}
```

三个和 UWP picker 的本质差别，都会影响你怎么写后续代码：

| | `Windows.Storage.Pickers`（UWP） | `Microsoft.Windows.Storage.Pickers`（WASDK） |
|---|---|---|
| 窗口归属 | 需手动 `IInitializeWithWindow` + HWND | 构造函数收 `Microsoft.UI.WindowId` |
| 返回类型 | `StorageFile` / `StorageFolder` | `PickFileResult` / `PickFolderResult`，只有 `Path()` 字符串 |
| 文件类型过滤 | `FileTypeFilter()`；UWP 侧不往里面加扩展名，调用选择器就抛异常 | 同样是 `FileTypeFilter()`（`winrt::IVector<winrt::hstring>`），照样显式 `Append` 最省事 |

拿到路径之后要读内容，就自己接上一步：`co_await FileIO::ReadTextAsync(co_await StorageFile::GetFileFromPathAsync(path))`，或者直接用 `std::filesystem` / 文件流（见 34.2.3）。`FileSavePicker`（`SuggestedFileName`、`SuggestedFolder`、`FileTypeChoices`）与 `FolderPicker`（`PickSingleFolderAsync`）同一套模式。

**旧写法仍然有效**，在必须拿到 HWND 做传统互操作、或工程里的 Windows App SDK 还没有这个命名空间时要用到：

```cpp
#include <shobjidl_core.h>
#include <microsoft.ui.xaml.window.h>

using namespace winrt::Windows::Storage::Pickers;

FileOpenPicker picker;
picker.FileTypeFilter().Append(L".json");

// 桌面进程里必须把 picker 绑到本窗口的 HWND，否则运行时抛异常
auto windowNative{ this->try_as<::IWindowNative>() };
HWND hWnd{ nullptr };
windowNative->get_WindowHandle(&hWnd);
picker.as<::IInitializeWithWindow>()->Initialize(hWnd);

auto file = co_await picker.PickSingleFileAsync();
```

这是 WinUI 3 桌面化后的真实适配点：UWP 的 picker 挂在应用窗口模型下，桌面进程里要么走 HWND 互操作（旧路径），要么走 WASDK 的 `WindowId`（新路径）。

> **版本说明**：本节签名对照本机 NuGet 缓存的 `Microsoft.WindowsAppSDK.Foundation` 1.8.260222000（`Microsoft.Windows.Storage.Pickers.winmd`）逐个方法核对：三个 picker 的构造参数都是 `Microsoft.UI.WindowId`，`PickSingleFileAsync` 返回 `PickFileResult`、`PickSaveFileAsync` 同、`PickSingleFolderAsync` 返回 `PickFolderResult`，两个结果类型都只有 `Path` 一个属性。想确认自己那版 SDK 有没有这些成员，直接在 `%USERPROFILE%\.nuget\packages\microsoft.windowsappsdk.foundation\<版本>\metadata\` 下用 [.NET 的 `MetadataReader` 或 `ILDASM`](https://learn.microsoft.com/dotnet/api/system.reflection.metadata) 打开同名 `.winmd`；这个命名空间是较近的版本才加进来的，老版本里搜不到属正常。


### 34.2.3 文件操作放 Service 层

无论用哪套 API，读写的职责在 Service，页面只发起和展示（分层依据见 [05 篇](./05-project-structure.md) 5.7）：

```text
Page：用户点"打开" → 调 ViewModel.OpenAsync()
ViewModel：更新 IsLoading 状态 → 调 Service → 结果写入可观察状态
Service：真实 IO（StorageFile / std::filesystem / 第三方库）
```

## 34.3 配置存储：注册表、JSON、XML 怎么选

| 存储 | 适合 | 注意 |
|------|------|------|
| 注册表（Win32 API） | 少量应用偏好、开关型配置 | 不是数据库；键值少而平 |
| JSON（文件） | 用户数据、任务列表、应用设置 | 首选的通用格式 |
| XML（文件） | 结构化文档、导入导出、旧格式兼容 | 需要解析库（pugixml、tinyxml2） |

注册表走 Win32 API（`RegCreateKeyExW` / `RegSetValueExW` / `RegQueryValueExW`），在 Service 层包成业务语义的方法，页面和 ViewModel 不感知实现。JSON 用 nlohmann/json 等库解析，解析完转成 Model 对象再进 ViewModel。

原则一句话：**格式是 Service 的实现细节，上层只看"保存设置 / 加载任务"**。

## 34.4 子进程

WinUI 3 应用可以启动、等待其他程序——桌面工具类应用的常见需求：

```cpp
#include <windows.h>

// exitCode 只在返回 true 时才有意义
bool RunTool(std::wstring cmdLine, DWORD& exitCode)
{
    STARTUPINFOW si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi{};

    // CreateProcessW 会就地改写命令行缓冲，所以必须传可写的缓冲区，
    // 传字符串字面量或 c_str() 是未定义行为
    if (!CreateProcessW(nullptr, cmdLine.data(), nullptr, nullptr,
                        FALSE, 0, nullptr, nullptr, &si, &pi))
    {
        exitCode = static_cast<DWORD>(GetLastError());
        return false;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);   // 阻塞等待：必须在后台线程，见 34.1

    DWORD code{};
    BOOL gotCode = GetExitCodeProcess(pi.hProcess, &code);

    // 句柄即资源：等完、取完码再关
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    if (!gotCode) { return false; }
    exitCode = code;
    return exitCode == 0;
}
```

三个容易忽略的点：

- **先等再关句柄**。最常见的写法是 `CreateProcessW` 成功就立刻 `CloseHandle` 两个句柄然后返回 true——那等于宣布"我不关心结果"，而工具类应用恰恰需要子进程的退出码来判断成功与否
- **`GetExitCodeProcess` 的 `STILL_ACTIVE`（259）歧义**：进程还在跑时它返回 259，于是真正以 259 退出的进程无法区分。要可靠判定"已结束"，只认 `WaitForSingleObject` 的返回，不要把退出码 259 当作"仍在运行"的证据
- **等待属于后台工作**。UI 线程上 `WaitForSingleObject(..., INFINITE)` 会让界面假死，正确姿势是 `co_await winrt::resume_background()` 之后再等，结果按 34.1 的纪律回流 UI 线程

或者走 WinRT 的 `Launcher`（更语义化）：

```cpp
#include <winrt/Windows.System.h>

winrt::Windows::System::Launcher::LaunchUriAsync(
    winrt::Windows::Foundation::Uri(L"https://learn.microsoft.com"));
```

耗时地等待/轮询子进程属于后台工作，遵守 34.1 的线程边界。

## 34.5 对象生命周期：引用计数 + RAII

WinUI 3 / C++/WinRT 的内存模型是两条规则的组合：

1. **WinRT 对象**：引用计数（[02 篇](./02-winrt.md) 2.3）。投影类型本身是智能指针——拷贝即 AddRef，析构即 Release。你基本不需要手动管理，但要理解计数的存在
2. **普通 C++ 资源**：RAII。`std::unique_ptr` 独占、`std::shared_ptr` 共享、容器/字符串自管理

工程上真正要花心思的是**所有权设计**：

- Page 短命（跟随导航），ViewModel 跟随页面，Service 应用级单例——生命周期从长到短单向依赖，禁止反向持有
- **循环引用**是引用计数模型的经典死锁：A 持 B、B 持 A，谁也释放不了。断环工具是弱引用：

```cpp
winrt::weak_ref<winrt::MyApp::TasksViewModel> weak{ m_viewModel };

// 异步回调里先升级为强引用，升级失败说明对象已销毁，直接退出
if (auto vm = weak.get())
{
    vm->LoadFrom(result);
}
```

- 后台线程/长命任务**不要**持有 UI 对象强引用（既是线程边界问题也是生命周期问题），需要回调 UI 时持 `DispatcherQueue` + 弱引用（见 34.1）

### 34.5.x 四工程的系统层清单

教程至今用过的一切"出 UI 界"的操作：%LOCALAPPDATA% 数据目录（SettingsStore/DocStore——两套同款纪律：目录自建、坏文件当空、UTF-8 无 BOM 落盘）；JSON 持久化（Windows.Data.Json——教学工程的轻量选择，产品可换 cJSON/rapidjson 但**读写纪律不变**）；窗口定位（AppWindow.MoveAndResize——31.5 的逻辑单位实测）；触摸注入与像素扫描（冒烟工具链——`tools/ui-smoke/` 是教程自产的"系统集成"活样本）。**34 章的每一个主题都能在四工程或工具链里找到非玩具用法**——这是"系统层"教学不打空炮的底气。

## 34.6 系统层与 UI 层的全景

把本篇与前面各篇合起来，一个真实 WinUI 3 应用的全景是：

```text
UI 层     XAML / Page / 绑定（03、06、07 篇）
状态层    ViewModel / INotifyPropertyChanged / IObservableVector（08 篇）
能力层    WinRT API / Service：文件、注册表、网络、子进程（本篇）
运行时层  WinRT 对象模型、引用计数、DispatcherQueue（02 篇）
系统层    Win32 进程、线程、句柄、内存（本篇）
交付层    Assets / Manifest / MSIX（09 篇）
```

每一层都知道自己的边界，修改就不会牵一发动全身——这就是"现代 UI 框架"之下，系统编程能力的正确位置。

---

上一篇：[33 主题资源与交付](./33-theming-packaging.md) ｜ 下一篇：[35 TaskFlow 实战](./35-taskflow.md) ｜ 返回 [目录](../README.md)
