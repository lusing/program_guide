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

WinRT 建立在 COM 之上——它的对象模型就是现代版的 COM。如果你没接触过 COM，不要跳过这句话：下一节先补这一课。

## 2.2 先补课：COM 是什么，为什么 WinRT 离不开它

很多讲 WinRT 的资料会随口说一句"WinRT 建立在 COM 上"就带过去了，但如果不知道 COM 是什么，后面一半的机制都悬空。这一节假设你完全没听过 COM。

### 2.2.1 问题：C++ 没有稳定的二进制标准

你写了一个 C++ 类库，编译成 DLL 发给别人用——听起来天经地义，实际上行不通：

- 不同编译器（不同版本的 MSVC、MinGW、Borland/Delphi）对同一个 C++ 类生成**不同的内存布局、不同的虚函数表安排、不同的名字修饰**（name mangling）
- 你的 DLL 用 MSVC 编译，对方用 Delphi 或 Visual Basic，根本无法构造或调用你的对象——他们甚至不知道你的对象在内存里长什么样
- C 函数没有这个问题（调用约定和符号布局是稳定标准），但 C 函数表达不了对象、方法、继承

一句话：**源码级的类库可以跨编译器，二进制级的对象不行**。想要"编译好的组件能被任何语言直接使用"，就必须发明一套所有语言都能遵守的二进制约定。

### 2.2.2 COM 的答案：对象 = 固定布局的函数指针表

COM（Component Object Model，微软 1993 年发布）就是这套约定。它对"对象"的定义严格得近乎原始：

> 一个 COM 对象，在内存里就是一块自己的数据 + 一个指向**函数指针表**的指针。表里每个槽位是哪个函数、参数怎么传，由标准固定死。任何语言只要能声明出这种结构，就能调用这个对象。

用 C 语言的视角看，COM 接口长这样（这是从 COM 头文件里简化来的真实模样）：

```c
// "接口"在内存里的本体：一张函数指针表
struct ICalculatorVtbl
{
    HRESULT (__stdcall* QueryInterface)(ICalculator* self, REFIID riid, void** out);
    ULONG   (__stdcall* AddRef)(ICalculator* self);
    ULONG   (__stdcall* Release)(ICalculator* self);
    HRESULT (__stdcall* Add)(ICalculator* self, int a, int b, int* result);
};

// "对象指针"指向的东西：只有一张表的地址
struct ICalculator
{
    const ICalculatorVtbl* lpVtbl;
};
```

调用 `calc->lpVtbl->Add(calc, 1, 2, &result)` 的过程就是：查表 → 取函数指针 → 调用。实现方（C、C++、Delphi、Visual Basic，任何能构造这个布局的语言）和调用方（同样任何语言）只需要约定**这张表的布局**，不需要共享编译器、运行时或源码。

### 2.2.3 三条铁律

COM 的全部规则可以压缩成三条，后面章节会反复遇到：

1. **引用计数管生命周期**。每个对象带一个计数器：使用方拿到接口指针时调 `AddRef()`，用完调 `Release()`；计数归零，对象自我销毁。没有 `delete`、没有 GC，责任由计数规则分摊。
2. **QueryInterface 管能力发现**。你拿到一个对象时只知道"它是个 COM 对象"，问它 `QueryInterface(IFoo的ID)`——支持就返回 `IFoo` 接口指针，不支持就返回错误码。每个接口用 **GUID**（128 位随机数，全球唯一）标识身份，不靠名字靠数字——所以接口永远不会重名冲突。
3. **接口发布后永不变更**。要加功能就定义新接口（`IFoo2`），老接口原样保留。这是 COM 维持三十年二进制兼容的代价与保障。

### 2.2.4 WinRT = 照搬 COM 的二进制协议，现代化它的配套体验

WinRT 完整继承了上面这套机制——vtable、GUID、引用计数、QueryInterface 一条没少——然后把经典 COM 最痛苦的部分逐个补上：

| | 经典 COM（1993） | WinRT（2012） |
|---|---|---|
| 类型信息 | 手写 `.h`/`.idl` 分发，运行时类型信息可选 | `.winmd` 元数据全量自带（见 2.4 节） |
| 语言支持 | 各语言手工适配接口 | 投影自动生成：C++/WinRT、C#、Rust… |
| 字符串 | `BSTR`（分配/释放规则琐碎易错） | `HSTRING`（不可变、引用计数） |
| 根接口 | `IUnknown` | `IInspectable`（增加类型身份与反射） |
| 异步 | 无标准，各组件自定义回调 | `IAsyncAction` / `IAsyncOperation<T>` 标准接口 |
| 错误处理 | 裸 `HRESULT` 逐个手查 | 统一 `HRESULT` + 投影层自动转异常 |

所以"WinRT 是现代版的 COM"的准确含义是：**二进制协议照搬（它经过了三十年验证），开发体验全部现代化**。你在 C++/WinRT 里写 `button.Content(...)` 时，底下走的就是 2.2.2 那张函数指针表。

### 2.2.5 词汇表：后面章节会用到的词

| 词 | 意思 |
|----|------|
| vtable / 函数指针表 | 接口在内存中的本体 |
| GUID / IID | 接口的 128 位身份标识 |
| QueryInterface（QI） | 按接口 ID 查询对象支持的能力 |
| AddRef / Release | 引用计数的加一/减一 |
| IInspectable | WinRT 在 IUnknown 之上扩展的根接口（下一节） |

## 2.3 ABI 层：IUnknown 与 IInspectable

### 2.3.1 IUnknown：COM 的根

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

### 2.3.2 IInspectable：WinRT 的根接口

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

## 2.4 元数据：.winmd 文件

WinRT API 不是只有编译好的二进制——每个组件都附带一个 **Windows Metadata（`.winmd`）** 文件，用 ECMA-335 格式（和 .NET 元数据同源）描述：

- 有哪些 runtimeclass（例如 `Button`）
- 每个 runtimeclass 实现哪些接口
- 每个接口有哪些方法、属性、事件，签名是什么（参数类型、是否异步、默认重载）

Windows SDK 和 Windows App SDK 都带着自己那部分的 `.winmd`。元数据是整个生态的枢纽：

- **语言投影**从它生成（下一节）
- IDE 的智能感知从它来
- XAML 编译器靠它解析 `<Button>` 标签对应什么类型
- 你自己写的 runtimeclass 也会生成 `.winmd`，供别的语言/组件使用

## 2.5 语言投影：从元数据到 C++

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

### 2.5.1 C++/WinRT 命名空间结构

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

## 2.6 常用基础类型

### 2.6.1 `winrt::hstring`：WinRT 字符串

WinRT ABI 层的字符串是 `HSTRING`（不可变的 UTF-16 引用计数字符串）。投影成 C++ 就是 `winrt::hstring`：

```cpp
winrt::hstring title = L"Hello";     // 从宽字面量构造
auto len = title.size();             // 和 std::wstring 类似的接口
std::wstring_view sv = title;        // 可零拷贝转成 wstring_view
```

和 `std::wstring` 的区别：`hstring` 直接对应 ABI 的 `HSTRING`，跨组件传递零转换。WinUI 3 的所有文本属性（`Text`、`Content` 的字符串形式）都用它。

### 2.6.2 `winrt::com_ptr`：智能指针

```cpp
winrt::com_ptr<ID2D1Factory> factory;
D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, factory.put());
// 出作用域自动 Release
```

WinRT 对象投影类型本身已经是引用计数的智能指针（构造即 AddRef，析构即 Release）。`com_ptr` 用于操作不在 WinRT 元数据里的裸 COM 接口（如 DirectX）。

### 2.6.3 `winrt::event` 与 `winrt::event_token`

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

## 2.7 对象激活：静态方法其实是工厂调用

WinRT 里写 `Button()` 创建控件，或者调静态方法 `StorageFile::GetFileFromPathAsync(path)` 时，底层发生的是：

1. 通过 `RoGetActivationFactory` 拿到该类型的**激活工厂**（一个实现了 `IActivationFactory` 的单例对象）
2. 工厂 `ActivateInstance()` 创建对象，或工厂本身实现静态方法

这就是 `implementation` / `factory_implementation` 两个命名空间存在的原因：`factory_implementation` 里的类就是你自己类型对应的工厂。你通常不用关心它，但报错栈里看到 "activation factory" 时应该知道它在说什么。

创建自己 `implementation` 类的实例：

```cpp
auto vm = winrt::make<winrt::MyApp::implementation::MainViewModel>();
// make<> 创建一个实现指定接口的 WinRT 对象，返回引用计数的投影指针
```

## 2.8 异步：WinRT 的一等公民

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

    // 切回 UI 线程：用 DispatcherQueue::TryEnqueue，不要 co_await resume_foreground
    // （WinUI 3 的 Microsoft.UI.Dispatching.DispatcherQueue 没有 resume_foreground 重载，
    //   换 Windows.System 的同名类型能编过但运行时永不恢复——见 32.7.1）
    m_dispatcherQueue.TryEnqueue([strong = get_strong()]
    {
        strong->StatusText().Text(L"done");       // 现在在 UI 线程，可以更新界面
    });
}
```

两个必须内化的规则：

1. **UI 对象只能在 UI 线程（单线程 apartment）访问**。后台线程直接改控件属性会抛异常。
2. `co_await` 之后默认回到原来的 apartment（C++/WinRT 协程自动处理上下文恢复）；要显式控制切换点，UI→后台用 `resume_background()`，后台→UI 用 `Microsoft.UI.Dispatching.DispatcherQueue::TryEnqueue`（WinUI 3 桌面线程上**不要**用 `resume_foreground`，见 [32-binding-mvvm.md](./32-binding-mvvm.md) 32.7.1）。

异步的完整工程模式（加载状态、错误处理、重入）见 [32-binding-mvvm.md](./32-binding-mvvm.md) 第 32.7 节。

## 2.9 错误模型

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

### 2.9.x 四工程里的投影实战位

hstring/std::wstring_view 过桥（设置中心搜索的 find/substr）、box_value/unbox_value（Tag 路由、ComboBox 选项）、make<T> 与 factory_implementation（每个 runtimeclass 的另一半）、协程 + get_strong（保存动画）——2 章的每个机制在四个工程里都有高频出场。**回望法**：卡在某个投影概念时，grep 四工程的对应用法（`grep -r "wstring_view" examples/`）看真实上下文，比读三遍文档快。

## 2.10 一图总结：一次属性赋值的完整旅程

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
