# 10. OS 集成：进程、线程、文件与配置

WinUI 3 不是"逃离系统编程"。一个 WinUI 3 应用就是一个 Windows 进程：有线程、有句柄、能用全部 Win32/WinRT 能力。这一篇讲清 UI 工程里最常遇到的系统集成点：线程边界、文件访问、配置存储、子进程，以及对象生命周期。

> 原教程此章包含大量通用 OS 编程内容（纤程、自写线程池、Fork-Join、Future），已移除——那些属于系统编程教程的主题。这里只保留与 WinUI 3 工程直接相关、且容易踩坑的部分。

## 10.1 线程边界：UI 线程与 DispatcherQueue

WinUI 3 应用的线程模型：

- **UI 线程**：单线程 apartment（STA），拥有全部 UI 对象，跑消息循环
- **后台线程**：线程池或自建，做耗时工作，**不能触碰任何 UI 对象**

跨线程调度的枢纽是 `DispatcherQueue`——UI 线程的任务队列：

```cpp
#include <winrt/Microsoft.UI.Dispatching.h>

using namespace winrt::Microsoft::UI::Dispatching;

// 在 UI 线程上抓取（通常存在成员里）
m_dispatcherQueue = DispatcherQueue::GetForCurrentThread();

// 两个方向的切换
co_await winrt::resume_background();              // UI → 后台（线程池）
co_await winrt::resume_foreground(m_dispatcherQueue); // 后台 → UI
```

自建线程（`std::thread`）往 UI 线程投递工作，用 `TryEnqueue`：

```cpp
std::thread worker([q = m_dispatcherQueue]()
{
    auto result = HeavyComputation();          // 后台：纯数据

    q.TryEnqueue([result]()
    {
        // UI 线程：安全地更新状态/控件
        m_viewModel.LoadFrom(result);
    });
});
worker.detach();
```

工程纪律（完整异步模式见 [08 篇](./08-binding-mvvm.md) 8.7）：

```text
后台线程：只产生数据、只持有纯数据对象
      ↓ 结果通过 DispatcherQueue 回流
UI 线程：更新 ViewModel 状态 → 绑定刷界面
```

## 10.2 文件访问

### 10.2.1 WinRT 文件 API

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

### 10.2.2 FileOpenPicker：桌面应用必须传窗口句柄

文件选择器在桌面（非 UWP）应用里有一个必做步骤——**把它和你的窗口句柄绑定**，否则抛异常：

```cpp
#include <shobjidl_core.h>
#include <microsoft.ui.xaml.window.h>

using namespace winrt::Windows::Storage::Pickers;

winrt::Windows::Foundation::IAsyncAction PickFileAsync()
{
    FileOpenPicker picker;
    picker.SuggestedStartLocation(PickerLocationId::Documents);
    picker.FileTypeFilter().Append(L".json");

    // 桌面应用必须：把 picker 初始化到本窗口的 HWND
    auto windowNative{ this->try_as<::IWindowNative>() };
    HWND hWnd{ nullptr };
    windowNative->get_WindowHandle(&hWnd);
    picker.as<::IInitializeWithWindow>()->Initialize(hWnd);

    auto file = co_await picker.PickSingleFileAsync();
    if (file)
    {
        auto content = co_await Windows::Storage::FileIO::ReadTextAsync(file);
        m_viewModel.LoadFrom(content);
    }
}
```

这是 WinUI 3 桌面化后的真实适配点：UWP 的 picker 挂在应用窗口模型下，桌面进程里需要传统 HWND 互操作。

### 10.2.3 文件操作放 Service 层

无论用哪套 API，读写的职责在 Service，页面只发起和展示（分层依据见 [05 篇](./05-project-structure.md) 5.7）：

```text
Page：用户点"打开" → 调 ViewModel.OpenAsync()
ViewModel：更新 IsLoading 状态 → 调 Service → 结果写入可观察状态
Service：真实 IO（StorageFile / std::filesystem / 第三方库）
```

## 10.3 配置存储：注册表、JSON、XML 怎么选

| 存储 | 适合 | 注意 |
|------|------|------|
| 注册表（Win32 API） | 少量应用偏好、开关型配置 | 不是数据库；键值少而平 |
| JSON（文件） | 用户数据、任务列表、应用设置 | 首选的通用格式 |
| XML（文件） | 结构化文档、导入导出、旧格式兼容 | 需要解析库（pugixml、tinyxml2） |

注册表走 Win32 API（`RegCreateKeyExW` / `RegSetValueExW` / `RegQueryValueExW`），在 Service 层包成业务语义的方法，页面和 ViewModel 不感知实现。JSON 用 nlohmann/json 等库解析，解析完转成 Model 对象再进 ViewModel。

原则一句话：**格式是 Service 的实现细节，上层只看"保存设置 / 加载任务"**。

## 10.4 子进程

WinUI 3 应用可以启动、等待其他程序——桌面工具类应用的常见需求：

```cpp
#include <windows.h>

bool LaunchNotepad()
{
    STARTUPINFOW si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi{};

    std::wstring cmd = L"notepad.exe";
    BOOL ok = CreateProcessW(nullptr, cmd.data(), nullptr, nullptr,
                             FALSE, 0, nullptr, nullptr, &si, &pi);
    if (ok)
    {
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);   // 句柄即资源，用完即关
    }
    return ok != FALSE;
}
```

或者走 WinRT 的 `Launcher`（更语义化）：

```cpp
#include <winrt/Windows.System.h>

winrt::Windows::System::Launcher::LaunchUriAsync(
    winrt::Windows::Foundation::Uri(L"https://learn.microsoft.com"));
```

耗时地等待/轮询子进程属于后台工作，遵守 10.1 的线程边界。

## 10.5 对象生命周期：引用计数 + RAII

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

- 后台线程/长命任务**不要**持有 UI 对象强引用（既是线程边界问题也是生命周期问题），需要回调 UI 时持 `DispatcherQueue` + 弱引用（见 10.1）

## 10.6 系统层与 UI 层的全景

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

上一篇：[09-theming-packaging.md](./09-theming-packaging.md) ｜ 返回 [目录](../README.md)
