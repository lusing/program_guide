# 第 22 章 COM 入门：对象模型与 IUnknown

> **本章回答的问题**：COM 到底是什么、为什么 Windows 到处是它？接口、对象、类厂怎么分工？`IUnknown` 三个方法为什么是整个模型的基石？`ComPtr` 替你管了什么？"套间"是什么概念？
>
> **前置章节**：第 20 章（插件契约三原则——你已经"发明过"COM 的雏形）；第 3 章（HRESULT）；第 21 章（CLSID 将住进注册表）。
>
> **你将做出什么**：本章是概念章（代码为最小片段）；成果是"看得懂任何 COM 代码"的眼睛——随后两章立刻变现。

## 22.1 为什么会有 COM：二进制复用的难题

第 20 章的插件系统有一个隐痛：宿主与插件必须**同时编译、同一编译器**才能保证结构体布局一致。想让"不同语言、不同编译器、不同时间编译的代码"互相调用对象，C++ 本身给不出答案：

- **名字修饰**：`?Add@Calc@@UEAAHHH@Z`，编译器一个版本一个样；
- **内存布局**：C++ 类的成员布局、虚表结构是编译器实现细节，无标准；
- **生命周期**：A 模块 `new` 的对象怎么让 B 模块安全地"用完放掉"？
- **版本**：接口一改，老用户全崩。

COM（Component Object Model，1993）的回答：**在二进制层面定死一套对象协议**——只要你的编译器能凑出同样的内存布局与调用约定，任何语言都能实现和消费 COM 组件。所以 C、C++、VB、C#、Python、甚至 Windows Script Host 都能调同一个对象。

## 22.2 对象模型：接口 = vtable 契约

COM 的核心抽象只有一个：**接口（interface）= 一组纯虚函数的指针表（vtable）**。

```text
对象（堆上的一块内存）
┌────────────┐
│ vptr ──────┼──→ vtable（编译器生成，布局由 COM 规定）
└────────────┘     ┌──────────────────────┐
                   │ [0] QueryInterface    │ ← IUnknown 三件套
                   │ [1] AddRef            │    永远排最前
                   │ [2] Release           │
                   ├──────────────────────┤
                   │ [3] Add               │ ← 接口自己的方法
                   │ [4] Sub               │
                   └──────────────────────┘
```

用 C++ 表达接口就是"继承 IUnknown 的纯虚类"：

```cpp
interface ICalc : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Add(int a, int b, int* result) = 0;
    virtual HRESULT STDMETHODCALLTYPE Sub(int a, int b, int* result) = 0;
};
```

三条铁律让"二进制契约"成立：

1. **`IUnknown` 三个方法永远占 vtable 前三格**——任何人都能从任何接口指针安全地调它们；
2. **调用约定固定** `STDMETHODCALLTYPE`（`__stdcall`）；
3. **接口一旦发布，永不修改**——要扩展就发布新接口（`ICalc2`），这是 COM 的版本哲学（对照第 20 章"版本握手"）。

分清三个角色：**类（class/CLSID）** 是实现，藏在 DLL/EXE 里；**接口（interface/IID）** 是契约，头文件里定义；**对象（object）** 是运行时实例，你永远只通过接口指针摸它。

## 22.3 `IUnknown`：三方法精讲

```cpp
HRESULT QueryInterface(REFIID riid, void** ppv);   // "你还会什么？"
ULONG   AddRef();                                   // 引用 +1
ULONG   Release();                                 // 引用 -1，归零自毁
```

**`QueryInterface`（QI）——接口导航器。** 一个对象可以实现多个接口；QI 是在接口之间跳转的唯一正规通道：

```cpp
ICalc* calc = ...;
IPersist* persist = nullptr;
HRESULT hr = calc->QueryInterface(IID_IPersist, (void**)&persist);
if (SUCCEEDED(hr)) { /* 同一个对象的另一个视角 */ persist->Release(); }
```

两条隐含规则：QI 到的**永远不带额外 AddRef 漏洞**（拿到就拥有，用完 Release）；对**同一对象**，从任何接口 QI `IID_IUnknown` 必须返回**相同的指针值**——这是 COM 判断"两个接口指针是不是同一个对象"的身份法则。

**`AddRef`/`Release`——引用计数生命周期。** 规则一句话：**谁拿到接口指针谁负责 Release；谁把指针交给别人（出参、存成员）谁先 AddRef**。计数归零时对象 `delete this` 自毁（第 24 章你会亲手写）。它的毛病也要知道：**循环引用**（A 持 B、B 持 A，谁也不归零）——大对象图要靠弱引用/显式断链破解，这也是后来 GC 语言嘲笑 COM 的点。

## 22.4 HRESULT 与错误

第 3 章的 HRESULT 在这里是唯一错误通道，补 COM 特有的一块：

- 设施码 `FACILITY_ITF`（第 4 位段 = 4）表示"接口自定义错误"，具体含义查接口文档；
- `S_FALSE` 是"成功但没做什么"（如 QI 缓存命中失败？不——典型如"剪贴板里没有那种格式"）；
- **判断永远用 `FAILED()/SUCCEEDED()`**；需要人话时 `FormatMessageW` 不认识 ITF 码，用 `IClassFactory` 之外组件自带的 `ISupportErrorInfo`/富错误信息（一句话：进阶话题，知道存在）。

## 22.5 GUID/IID/CLSID：128 位的名字

每个接口、每个类都有一个 **GUID**（Globally Unique Identifier，128 位）：

```text
IID_ICalc  = {1DBE71E1-2CA9-417E-AF41-2A2101510601}   接口 ID（你叫什么方法）
CLSID_Calc = {6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}   类 ID（谁来实现）
```

生成一次、写死、永不复用（VS 的"创建 GUID"工具或 `CoCreateGuid`）。COM 的注册表就是"CLSID → 哪个 DLL"的登记簿（第 21 章的 `Software\Classes\CLSID` 路径）——第 24 章你会亲手写登记条目。

## 22.6 `ComPtr`：把引用计数装进 RAII

手工 `AddRef/Release` 的样板又长又容易漏。**ComPtr**（`<wrl/client.h>`，Windows SDK 自带）是标准解药：

```cpp
#include <wrl/client.h>
using Microsoft::WRL::ComPtr;

ComPtr<IFileOpenDialog> dlg;
HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dlg));
// dlg 离开作用域自动 Release；->
dlg->Show(hwnd);
```

要点速查：

| 操作 | 写法 |
|------|------|
| 检查是否为空 | `if (dlg)` |
| 取裸指针用 | `dlg.Get()` |
| 接收出参（先置空再取地址） | `dlg->GetResult(&item)`（ComPtr 重载了 `&`） |
| 交出所有权 | `dlg.Detach()` |
| 强制释放 | `dlg.Reset()` |

与 `std::unique_ptr` 的本质差异：它删除的方式是**调 `Release()` 方法**，不是 `delete`——COM 对象的自毁藏在 Release 里。C++/WinRT（第 26 章）还有自己的 `winrt::com_ptr`，一回事。

## 22.7 套间：线程与对象的契约（概念级）

COM 对象的线程安全千差万别（有的是自由线程，有的只能在创建它的线程跑）。**套间（apartment）** 是 COM 的解法：每个 COM 线程先声明自己住哪种套间，每个对象声明自己需要哪种——不匹配时 COM 在中间插一个**代理（proxy）**，替你把调用排队/转发到正确的线程：

| 套间 | 声明方式 | 特点 |
|------|---------|------|
| 单线程套间 STA | `CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)` | UI 线程的标准选择；带隐藏窗口收消息，跨线程调用被排队成窗口消息 |
| 多线程套间 MTA | `COINIT_MULTITHREADED` | 对象要求调用方自己保证线程安全 |

初学阶段记住三条就够：**用 COM 前必须 `CoInitializeEx`**（每线程一次，`CoUninitialize` 配对）；GUI 程序用 STA；`ThreadingModel=Apartment` 注册值（第 24 章）表示"我这个组件想住 STA"。跨套间调用的代理细节（marshaller）知道存在即可。

## 22.8 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| 对象泄漏（内存只涨不跌） | 每个 `AddRef`/`QueryInterface`/`CoCreateInstance` 没配 Release | 用 ComPtr（22.6） |
| 崩在 `Release` | 双重释放 | 所有权规则：拿到就放、出参与存成员要 AddRef |
| QI 返回 `E_NOINTERFACE` | 对象确实不实现该接口；或 IID 抄错 | 查接口文档；SUCCEEDED 判断 |
| 忘 `CoInitializeEx` 就创建 | `CoCreateInstance` 返回 `CO_E_NOTINITIALIZED` | 每线程开场白 |
| 用 `hr < 0` 判断失败 | S_FALSE 等值误判 | 永远 `FAILED/SUCCEEDED`（3 章） |
| 接口指针判空代替判 HRESULT | `SUCCEEDED(hr)` 但指针半空场景混乱 | 判 HRESULT 为主，指针兜底 |
| 循环引用不释放 | A↔B 互相持有 | 弱引用/父用普通引用子用 AddRef 的单向约定 |

## 22.9 小结

1. COM = 二进制对象协议：接口（vtable）+ IUnknown 头三格 + 固定调用约定 + 接口永不改。
2. QI 是接口导航器（同对象 IUnknown 指针相同）；AddRef/Release 是生命周期（拿到就 Release）。
3. GUID 命名接口与类；CLSID 的登记簿在注册表 `Software\Classes\CLSID`。
4. ComPtr 用 RAII 管引用计数；删除语义是 Release 不是 delete。
5. 套间是线程契约：先 `CoInitializeEx`，GUI 用 STA。

## 22.10 动手练习

1. 手写一个最小 IUnknown 实现（成员就一个计数器），`main` 里 AddRef/Release 各调几次并打印返回值，直到归零——预习第 24 章的自毁逻辑。
2. 把第 20 章插件宿主的"函数表结构体"与本章 vtable 图并排画出来，标出对应关系（query_plugin↔类厂、函数指针表↔vtable、apiVersion↔QI）。
3. 概念题：为什么 COM 接口"永不修改"？如果非要给 ICalc 加方法，标准做法是什么？（提示：IID_ICalc2 与 QI 链。）

---

**下一章**：[第 23 章 COM 实战](23-COM实战.md)——亲手调用系统里的 COM 组件。
