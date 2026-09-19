# 第 24 章 COM 实现：手写进程内服务器

> **本章回答的问题**：`CoCreateInstance` 内部到底发生了什么？怎么从零写一个 COM 组件 DLL？类厂怎么写？注册表里登记哪些键？HKCU 注册为什么不用管理员？
>
> **前置章节**：第 21 章（注册表——COM 的登记簿）、第 19 章（DllMain/DLL 导出）、第 22 章（IUnknown/引用计数）、第 23 章（使用侧骨架——现在站到对面）。
>
> **你将做出什么**：一个完整可用的进程内 COM 服务器（`examples/27_com_server`）：自己的接口、自己的组件 DLL、HKCU 注册、`CoCreateInstance` 真实创建、用完注销——全链路 60 秒跑完。

本章示例：`examples/27_com_server`（calc.h / server.cpp / main.cpp / build.ps1）。

## 24.1 反向理解 `CoCreateInstance`：全链路泳道

第 23 章你是调用方；现在把自己想成"被调用方"。`CoCreateInstance(CLSID_Calc, ...)` 那一瞬间，系统替你跑了这条链：

```text
你的进程                                    注册表 / 磁盘
─────────────────────────────────────────────────────────
CoCreateInstance(CLSID_Calc, IID_ICalc)
   │
   ▼ ① 查户口：CLSID_Calc 登记在哪？
HKCU\Software\Classes\CLSID\{6B92FBEE-...}\InprocServer32
   │        默认值 = C:\...\build\calcdll.dll   ThreadingModel = Apartment
   │
   ▼ ② 还没加载？LoadLibraryW("C:\...\calcdll.dll")
   │     （第 19 章的加载机制，COM 亲自下场）
   ▼ ③ GetProcAddress("DllGetClassObject") → 调它
   │        "给我 CLSID_Calc 的类厂，要 IClassFactory 接口"
   ▼ ④ 类厂->CreateInstance(nullptr, IID_ICalc, &p)
   │        组件对象诞生，构造时引用=1
   ▼ ⑤ 对象->QueryInterface(IID_ICalc, &p)（CreateInstance 内部）
   │        QI 里 AddRef → 指针交给你
   ▼
你拿到 ICalc*，开始用；Release 归零后对象自毁
```

本章的全部内容就是把这条泳道上的四个"你"写出来：**接口定义 → 组件 → 类厂 → 四个标准导出**。

## 24.2 接口定义：教学版与工业版

`calc.h` 用教学版路线——C++ 纯虚类直接写，IID 手工固定：

```cpp
// 固定的 GUID（生成一次写死，两个编译单元共享同一个头）
static const IID IID_ICalc  = { 0x1DBE71E1, ... };
static const CLSID CLSID_Calc = { 0x6B92FBEE, ... };

interface ICalc : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE Add(int a, int b, int* result) = 0;
    virtual HRESULT STDMETHODCALLTYPE Sub(int a, int b, int* result) = 0;
};
```

**工业版**用 IDL（接口定义语言）+ `midl` 编译器生成头文件与代理/存根——换来的是跨进程调用（本地服务器）与自动化支持。教学版足够看清机制；两条路线的接口内存布局完全一致。

**GUID 两条铁律**：生成一次永不变；**定义放共享头文件**而不是各写各的 `static`（两个 `static` 同名不同值 = 每个翻译单元一个副本，跨模块对比 IID 居然能撞车失败——23 章的 `IID_PPV_ARGS` 之所以要求统一来源，原因之一）。

## 24.3 组件实现：Calc 类三件事

```cpp
class Calc : public ICalc {
    LONG m_ref = 1;                       // ① 诞生即 1：构造即被"创建流程"持有
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_ICalc) {
            *ppv = static_cast<ICalc*>(this);
            AddRef();                     // ② 给出指针必 AddRef（22 章铁律的实现侧）
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;             // 不认识就明说，别硬撑
    }
    STDMETHODIMP_(ULONG) AddRef() override {
        return InterlockedIncrement(&m_ref);   // ③ 原子操作：多线程下计数不能烂
    }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;          // ★ 归零自毁：COM 生命周期的终点
        return n;
    }
    STDMETHODIMP Add(int a, int b, int* result) override {
        if (!result) return E_POINTER;    // 出参防御：COM 方法的标准礼仪
        *result = a + b;
        return S_OK;
    }
    // Sub 同理……
};
```

三个细节：`delete this` 是 COM 的合法姿势（对象自己决定生命周期，调用方只管 Release）；`InterlockedIncrement` 保证线程安全（引用计数是多线程环境下最热的字段）；`STDMETHODIMP` 宏 = `virtual HRESULT STDMETHODCALLTYPE`，照宏写防笔误。

## 24.4 类厂：对象的中介

COM 不让你直接 `new` 别人的类——统一走**类厂（class factory）**，它也是一个小 COM 对象（实现 `IClassFactory`）：

```cpp
class CalcFactory : public IClassFactory {
    LONG m_ref = 1;
    // QI/AddRef/Release 与 Calc 同构，略……
    STDMETHODIMP CreateInstance(IUnknown* outer, REFIID riid, void** ppv) override {
        if (outer) return CLASS_E_NOAGGREGATION;   // 聚合：高级特性，教学版明确拒绝
        Calc* obj = new (std::nothrow) Calc();
        if (!obj) return E_OUTOFMEMORY;
        HRESULT hr = obj->QueryInterface(riid, ppv);   // QI 内部 AddRef → 指针归调用方
        obj->Release();        // ★ 抵消构造时的 1：算术必须配平
        return hr;             // 失败时对象已被 Release 归零自毁，无泄漏
    }
    STDMETHODIMP LockServer(BOOL) override { return S_OK; }   // 服务器级锁计数，教学版省略
};
```

`CreateInstance` 里"new 出来是 1，QI 加成 2，Release 掉 1，交出去 1"——这道引用算术题是本章最值得在脑中走一遍的流程。`LockServer(TRUE)` 的真实用途是"进程里还有用户时别让 DLL 卸载"，需要配一个计数器与 `DllCanUnloadNow` 联动，教学版从简。

## 24.5 四个标准导出：DLL 的门面

进程内 COM 服务器必须导出四个函数（`STDAPI` 定义 + 链接器 `/EXPORT` 导出，见 build.ps1）：

| 导出 | 何时被调 | 我们的实现 |
|------|---------|-----------|
| `DllGetClassObject` | CoCreateInstance 第 ③ 步 | 认 CLSID → new 类厂 → QI 给出 |
| `DllCanUnloadNow` | 系统想卸载 DLL 时 | `S_FALSE`（教学版常驻；真实版查对象计数+锁计数） |
| `DllRegisterServer` | `regsvr32 xxx.dll` | 写注册表登记条目 |
| `DllUnregisterServer` | `regsvr32 /u` | 删掉登记条目 |

`DllGetClassObject` 的骨架（认错 CLSID 要拒绝）：

```cpp
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, void** ppv) {
    if (rclsid != CLSID_Calc) return CLASS_E_CLASSNOTAVAILABLE;
    CalcFactory* f = new (std::nothrow) CalcFactory();
    if (!f) return E_OUTOFMEMORY;
    HRESULT hr = f->QueryInterface(riid, ppv);   // 老规矩：QI 配平
    f->Release();
    return hr;
}
```

## 24.6 注册：登记簿里写什么

`DllRegisterServer` 写的键树（第 21 章知识的现场应用）：

```text
HKCU\Software\Classes\CLSID\{6B92FBEE-1E6D-4010-9AC0-5783E288F9C1}
└── InprocServer32
    ├── (默认) = C:\...\calcdll.dll 的完整路径    ← GetModuleFileNameW(g_module) 取
    └── ThreadingModel = Apartment                ← 声明组件的套间要求（22.7）
```

三条注册路线对比：

| 路线 | 位置 | 权限 | 场景 |
|------|------|------|------|
| `regsvr32 xxx.dll` | HKLM\Software\Classes | **要管理员** | 传统安装器 |
| **自己调 DllRegisterServer 写 HKCU** | HKCU\Software\Classes | 免管理员 | per-user 安装（现代推荐）、教学环境 |
| 免注册 COM（manifest） | 应用清单声明 | 零注册 | 绿色软件（知道存在） |

本教程选 HKCU 路线：**不需要管理员、随注销即清、机器零残留**——HKCR 合成视图（21 章）保证系统照常找到它。注意 `GetModuleFileNameW(g_module)` 里 `g_module` 来自 `DllMain` 记下的自身句柄（19 章的"DllMain 只做零风险事"清单里的标准项）。

## 24.7 消费者：全链路验证程序

`main.cpp` 不是普通 demo，是**全链路验收器**——它把 24.1 泳道上的每一步亲手走一遍：

```text
[1] LoadLibraryW("calcdll.dll") + GetProcAddress("DllRegisterServer") + 调用
     —— 手动注册（regsvr32 干的就是这件事；第 20 章显式链接的又一课）
[2] CoInitializeEx + CoCreateInstance(CLSID_Calc, IID_ICalc)
     —— 成功 = 注册表 → 加载 → 类厂 → CreateInstance 全链贯通
[3] calc->Add(20,22) / Sub(50,8)     —— 接口真实可用
[4] calc->AddRef() 打印返回值        —— 引用计数现场可见（构造+QI 后是 2）
[5] Release 归零自毁 → DllUnregisterServer → FreeLibrary
     —— 环境完全还原
```

运行输出（已实测）：

```text
[1] DllRegisterServer → 已注册到 HKCU\Software\Classes
[2] CoCreateInstance 成功（COM 替你 LoadLibrary 了我们刚注册的 DLL）
[3] Add(20,22) = 42，Sub(50,8) = 42
[4] AddRef 后引用计数 = 2（Release 归位）
[5] DllUnregisterServer → 注册表已清理
全链路完成
```

## 24.8 `ThreadingModel=Apartment` 承诺了什么

回看 22.7：这个值的含义是**组件对线程安全的承诺**——`Apartment` 表示"我的对象需要在 STA 线程被调用，跨线程请 COM 用代理排队"；`Free` 表示"我自己线程安全，随便哪个线程直接调"；`Both` 两种都行。**写错这个值 = 随机崩溃**（对象在没保护的情况下被多线程摸）。教学版 Calc 用 `Apartment`：与消费者的 STA 匹配，调用全部同步直达、无代理。

## 24.9 易错清单

| 症状 | 原因 | 解法 |
|------|------|------|
| `REGDB_E_CLASSNOTREG` | 没注册 / 注册到 HKLM 但程序看 HKCU / 位数不符（21.8） | 检查 `reg query`；确认 64 位一致 |
| QI 成功但调方法崩 | 接口布局两边不一致（各改各的头） | 共享一个 calc.h |
| `CLASS_E_NOAGGREGATION` | 传了 outer——你没实现聚合 | 正常拒绝 |
| 对象泄漏 | CreateInstance 的引用算术没配平 | 24.4 的加一减一 |
| `delete this` 后再访问 | Release 后还用指针 | 用完即弃指针置空 |
| GUID 每次编译变 | 用了"每次生成"的宏/工具 | 生成一次写死进共享头 |
| 注销后残留 | `RegDeleteKeyW` 只删空键 | `RegDeleteTreeW`（21 章） |
| DllMain 里注册自己 | loader lock（19 章） | 注册推给 DllRegisterServer |

## 24.10 小结

1. CoCreateInstance 全链路：查注册表 → LoadLibrary → DllGetClassObject → 类厂 CreateInstance → QI。
2. 组件三件事：QI 给指针必 AddRef、计数用 Interlocked、归零 `delete this`。
3. 类厂是对象中介；CreateInstance 的"加一减一"算术必须配平。
4. 四个标准导出是 COM DLL 的门面；`STDAPI` + `/EXPORT` 或 .def 导出。
5. HKCU 注册 = 免管理员 per-user COM（HKCR 合成视图兜底）；ThreadingModel 是线程安全承诺。

## 24.11 动手练习

1. 给 `ICalc` 加 `Mul`（改共享头 → 重编 DLL 与消费者 → 验证），体会"接口演进 = 重新发布两端"。
2. 写第二个组件 `CLSID_Calc2`（同 DLL 双类）：`DllGetClassObject` 按 CLSID 分发到不同类厂——一个 DLL 装多个组件的标准形态。
3. 实验：把注册表里 `ThreadingModel` 删掉再创建——观察默认行为（"Single"：创建线程独占）；再把消费者改成 MTA 线程创建 STA 组件，感受代理介入后的调用开销（循环调一万次对比耗时）。

---

**下一章**：[第 25 章 Direct2D 与 DirectWrite](25-Direct2D与DirectWrite.md)——COM 接口风格的现代渲染。
