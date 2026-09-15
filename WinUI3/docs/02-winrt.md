# 2. WinRT 机制：对象模型、元数据、投影与 C++/WinRT

上一篇给出了分层图，这一篇回答"WinRT 到底怎么工作"。目标是你以后看到 `winrt::hstring`、`co_await GetFileFromPathAsync()`、`sender.as<Button>()` 这类代码时，知道底下发生了什么，而不是背语法。

## 2.1 从 Win32 到 WinRT：为什么需要新的对象模型

Win32 API 是 C 函数 + 句柄 + 消息：

```cpp
HWND hwnd = CreateWindowW(...);
SendMessageW(hwnd, WM_SETTEXT, 0, (LPARAM)L"hello");
```

这套模型的问题在于扩展性：能力越多，函数越多；没有对象身份，没有统一的错误模型，没有跨语言约定，没有标准化的异步。Windows 8 引入 WinRT，就是为了解决这些：

- 把系统能力组织成**对象**，对象实现**接口**
- 定义统一的二进制调用协议（ABI），任何编译型语言都能直接调用
- 定义统一的元数据格式（`.winmd`），让语言和工具能"看懂"API
- 把异步、事件、集合、字符串做成标准化的基础类型

WinRT 建立在 COM 之上——它的对象模型就是现代版的 COM。

## 2.2 ABI 层：IUnknown 与 IInspectable

### 2.2.1 IUnknown：COM 的根

每个 WinRT 对象在二进制层面都是一个 COM 对象，实现三个最基础的方法：

```cpp
struct IUnknown
{
    HRESULT QueryInterface(GUID const& riid, void** ppv);  // 按接口 ID 查询能力
    ULONG   AddRef();                                       // 引用计数 +1
    ULONG   Release();                                      // 引用计数 -1，归零则销毁
};
```

这三个方法定义了 COM/WinRT 对象的全部生存规则：

- **接口查询**：你拿到一个对象，问它"你支持 `IButton` 吗"，支持就返回该接口指针
- **引用计数**：对象的生命周期由计数管理，最后一个引用释放时对象销毁
- 没有继承树的要求——只有"实现了哪些接口"

### 2.2.2 IInspectable：WinRT 的根接口

WinRT 在 `IUnknown` 上加了一层：

```cpp
struct IInspectable : IUnknown
{
    HRESULT GetIids(ULONG* count, GUID** iids);              // 列出全部接口
    HRESULT GetRuntimeClassName(HSTRING* className);         // 报出真实类型名
    HRESULT GetTrustLevel(TrustLevel* level);
};
```

`IInspectable` 的意义：**任何 WinRT 对象都可以被当作 `IInspectable` 使用**，运行时能统一地查询它的类型和接口。你在事件回调里看到的第一个参数就是这个类型：

```cpp
void MainWindow::OnClick(IInspectable const& sender, RoutedEventArgs const& args)
{
    // sender 是"某个 WinRT 对象"，真实身份通常是 Button
    auto button = sender.as<winrt::Microsoft::UI::Xaml::Controls::Button>();
    // as<> 内部就是 QueryInterface
}
```

记住对应关系：

| Win32 世界 | WinRT 世界 |
|-----------|-----------|
| `HWND` 句柄 | 对象接口指针（引用计数） |
| `WM_COMMAND` 消息 + wParam | 对象事件 + sender/args |
| `GetWindowText` 函数 | 对象属性 `Text()` |
| `HRESULT` 错误码 | `hresult` 异常（C++/WinRT 投影层转换） |

## 2.3 元数据：.winmd 文件

WinRT API 不是只有编译好的二进制——每个组件都附带一个 **Windows Metadata（`.winmd`）** 文件，用 ECMA-335 格式（和 .NET 元数据同源）描述：

- 有哪些 runtimeclass（例如 `Button`）
- 每个 runtimeclass 实现哪些接口
- 每个接口有哪些方法、属性、事件，签名是什么（参数类型、是否异步、默认重载）

Windows SDK 和 Windows App SDK 都带着自己那部分的 `.winmd`。元数据是整个生态的枢纽：

- **语言投影**从它生成（下一节）
- IDE 的智能感知从它来
- XAML 编译器靠它解析 `<Button>` 标签对应什么类型
- 你自己写的 runtimeclass 也会生成 `.winmd`，供别的语言/组件使用

## 2.4 语言投影：从元数据到 C++

`.winmd` 是抽象契约，具体语言需要一层"投影"把它翻译成该语言自然的 API。

**C++/WinRT 就是这个投影**：一个 header-only 的 C++17 库，配合 `cppwinrt.exe` 工具。构建时，工具读取 `.winmd` 文件，生成 `winrt/*.h` 头文件，把每个 WinRT 类型映射成 C++ 类型：

```text
.winmd 里的类型                    cppwinrt 生成的 C++ 类型
─────────────────────────────    ─────────────────────────────────────
Windows.Foundation.String    →   winrt::hstring
IInspectable                 →   winrt::Windows::Foundation::IInspectable
Button (Microsoft.UI.Xaml)   →   winrt::Microsoft::UI::Xaml::Controls::Button
IAsyncOperation<StorageFile> →   winrt::Windows::Foundation::IAsyncOperation<...>
事件订阅                     →   返回 winrt::event_token 的成员函数
```

所以：

> `winrt::` 命名空间里的东西，**不是另一个类库**，而是 WinRT 元数据经过投影后的 C++ 视图。你调用 `button.Content(...)` 时，底层是通过 vtable 调用 WinRT 接口方法，并自动管理引用计数。

你自己的工程里，构建也会：IDL（MIDL 3.0）→ `.winmd` → cppwinrt → 生成 `Module.g.h` 和每个类的模板基类（`AppT<>`、`MainWindowT<>` 等）。

### 2.4.1 C++/WinRT 命名空间结构

一个典型 XAML 类分布在两个命名空间里，这是初学者最困惑的点之一：

```cpp
namespace winrt::MyApp::implementation
{
    // 你写实现的地方：真正的成员变量、函数体
    struct MainWindow : MainWindowT<MainWindow> { ... };
}

namespace winrt::MyApp::factory_implementation
{
    // 生成的工厂壳：负责对象激活，内部转发到 implementation
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow> { };
}
```

- `implementation`：**你写的部分**
- `factory_implementation`：激活工厂，由模板生成，一般不动
- `MainWindowT<>`：cppwinrt 从 IDL/元数据生成的模板基类，实现了该类型的全部 WinRT 接口转发

## 2.5 常用基础类型

### 2.5.1 `winrt::hstring`：WinRT 字符串

WinRT ABI 层的字符串是 `HSTRING`（不可变的 UTF-16 引用计数字符串）。投影成 C++ 就是 `winrt::hstring`：

```cpp
winrt::hstring title = L"Hello";     // 从宽字面量构造
auto len = title.size();             // 和 std::wstring 类似的接口
std::wstring_view sv = title;        // 可零拷贝转成 wstring_view
```

和 `std::wstring` 的区别：`hstring` 直接对应 ABI 的 `HSTRING`，跨组件传递零转换。WinUI 3 的所有文本属性（`Text`、`Content` 的字符串形式）都用它。

### 2.5.2 `winrt::com_ptr`：智能指针

```cpp
winrt::com_ptr<ID2D1Factory> factory;
D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, factory.put());
// 出作用域自动 Release
```

WinRT 对象投影类型本身已经是引用计数的智能指针（构造即 AddRef，析构即 Release）。`com_ptr` 用于操作不在 WinRT 元数据里的裸 COM 接口（如 DirectX）。

### 2.5.3 `winrt::event` 与 `winrt::event_token`

WinRT 事件在 ABI 上是"添加/移除处理器"两个方法，返回 token 作为退订凭据。C++/WinRT 里：

```cpp
// 订阅（lambda 或成员函数）
winrt::event_token token = button.Click([](auto const& sender, auto const& args) {
    // 处理
});

// 退订
button.Click(token);
```

自己实现带事件的类时，用 `winrt::event<D>` 存储：

```cpp
winrt::event<winrt::Windows::Foundation::TypedEventHandler<
    winrt::MyApp::TaskItem,
    winrt::Windows::Foundation::IInspectable>> m_changed;

winrt::event_token Changed(Handler const& handler) { return m_changed.add(handler); }
void Changed(winrt::event_token const& token) { m_changed.remove(token); }
```

## 2.6 对象激活：静态方法其实是工厂调用

WinRT 里写 `Button()` 创建控件，或者调静态方法 `StorageFile::GetFileFromPathAsync(path)` 时，底层发生的是：

1. 通过 `RoGetActivationFactory` 拿到该类型的**激活工厂**（一个实现了 `IActivationFactory` 的单例对象）
2. 工厂 `ActivateInstance()` 创建对象，或工厂本身实现静态方法

这就是 `implementation` / `factory_implementation` 两个命名空间存在的原因：`factory_implementation` 里的类就是你自己类型对应的工厂。你通常不用关心它，但报错栈里看到 "activation factory" 时应该知道它在说什么。

创建自己 `implementation` 类的实例：

```cpp
auto vm = winrt::make<winrt::MyApp::implementation::MainViewModel>();
// make<> 创建一个实现指定接口的 WinRT 对象，返回引用计数的投影指针
```

## 2.7 异步：WinRT 的一等公民

WinRT 把所有可能超过几毫秒的操作都设计成异步 API。四个标准接口：

| 接口 | 用途 |
|------|------|
| `IAsyncAction` | 无返回值的异步操作 |
| `IAsyncActionWithProgress<T>` | 带进度 |
| `IAsyncOperation<T>` | 返回一个值 |
| `IAsyncOperationWithProgress<T, P>` | 返回值 + 进度 |

C++/WinRT 里用协程消费和生产它们：

```cpp
// 消费：co_await 一个异步操作
using namespace winrt::Windows::Storage;
StorageFile file = co_await StorageFile::GetFileFromPathAsync(path);

// 生产：函数返回异步接口类型
winrt::Windows::Foundation::IAsyncAction LoadAsync()
{
    co_await winrt::resume_background();          // 切到线程池
    // ... 耗时工作（这里不能碰 UI 对象）

    co_await winrt::resume_foreground(m_dispatcherQueue); // 切回 UI 线程
    StatusText().Text(L"done");                   // 现在可以更新界面
}
```

两个必须内化的规则：

1. **UI 对象只能在 UI 线程（单线程 apartment）访问**。后台线程直接改控件属性会抛异常。
2. `co_await` 之后默认回到原来的 apartment（C++/WinRT 协程自动处理上下文恢复），显式用 `resume_background()` / `resume_foreground()` 精确控制切换点。

异步的完整工程模式（加载状态、错误处理、重入）见 [08-binding-mvvm.md](./08-binding-mvvm.md) 第 8.7 节。

## 2.8 错误模型

ABI 层一切错误都是 `HRESULT`。C++/WinRT 投影层把它转成异常：

```cpp
try
{
    co_await StorageFile::GetFileFromPathAsync(L"C:\\不存在.txt");
}
catch (winrt::hresult_error const& e)
{
    auto code = e.code();      // HRESULT
    auto msg  = e.message();   // winrt::hstring
}
```

反过来，你自己的代码抛 `winrt::hresult_error`（或派生类型），跨过 ABI 后就变成对应 `HRESULT`。不要让裸 C++ 异常穿过 WinRT 边界。

## 2.9 一图总结：一次属性赋值的完整旅程

```text
你写：button.Content(box_value(L"Click me"));
  ↓
C++/WinRT 投影层：参数转成 HSTRING/IInspectable，引用计数 +1
  ↓
vtable 调用：通过接口指针调用 ABI 方法（跨模块边界）
  ↓
WinUI 3 框架内部：更新依赖属性、标记布局失效、安排重绘
  ↓
返回 HRESULT → 投影层检查，失败则抛 hresult_error
  ↓
离开作用域：临时对象 Release，引用计数 -1
```

每一次 `winrt::` 调用都在走这条路径——这就是"投影 + ABI + 引用计数"三件事在真实代码里的样子。

---

上一篇：[01-tech-stack.md](./01-tech-stack.md) ｜ 下一篇：[03-xaml.md](./03-xaml.md)
