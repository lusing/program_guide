# 39. 应用通知：AppNotificationBuilder 从 C++ 发本地 Toast

> 对应《Learn WinUI 3》第 8 章。Windows App SDK 1.2+ 的通知 API（`Microsoft.Windows.AppNotifications`）是 WinRT 投影——**C++/WinRT 与 C# 消费的是同一套接口**。本章落地本地应用通知（toast）：发、收、激活回传；推送（WNS/Azure）只在 39.6 概述——它需要云端与商店身份，与语言无关。

示例：`examples/34-os-integration` 的"Send app notification"按钮（34 例在本章扩展出的通知段）。

## 39.1 通知的三种形态

| 形态 | 通道 | 需要什么 | 本章 |
|---|---|---|---|
| **本地应用通知** | 无——应用自己 Show | 打包或 unpackaged 注册 | ✅ 全流程 |
| 云端应用通知 | WNS | Store 注册 + Azure 通知中心 | 39.6 概述 |
| 原始推送（raw push） | WNS | 同上 + COM 激活登记 | 39.6 概述 |

书 8.1 的使用场景判断同样适用 C++：本地 toast 是"提醒用户事件/请求动作"的最廉价通道；推送是"应用不在运行也要被唤醒"的通道，代价是云端身份链。

## 39.2 构建通知：链式 Builder

`AppNotificationBuilder`（`Microsoft.Windows.AppNotifications.Builder`）把 toast XML 藏在流式接口后面。**C++ 投影的坑位先行**：这些方法返回接口类型 `IAppNotificationBuilder`，链式调用一整条 `a().b().c()` 在投影上偶发临时对象生命周期问题——**教程采用逐行调用**（同样编译期类型安全，可读性更好）：

```cpp
// examples/34-os-integration/MainWindow.xaml.cpp（39 章扩展段）
using winrt::Microsoft::Windows::AppNotifications::Builder::AppNotificationBuilder;
using winrt::Microsoft::Windows::AppNotifications::Builder::AppNotificationButton;

AppNotificationBuilder builder;
builder.AddArgument(L"action", L"send");    // 通知激活时回传的键值对
builder.AddText(L"Hello from C++/WinRT");   // 第一行文本（标题语义）
builder.AddText(L"Local app notification - no WNS, no cloud, no package identity.");

AppNotificationButton button{ L"Activate app" };
button.AddArgument(L"action", L"activate"); // 按钮自己的参数
builder.AddButton(button);

AppNotification notification = builder.BuildNotification();
AppNotificationManager::Default().Show(notification);
```

Builder 的能力清单（1.8 投影实测存在）：`AddText`（两行以内有语义区分）、`AddTextBox`（通知内输入框）、`AddComboBox`、`AddProgressBar`（进度条，配 `AppNotificationProgressData` 可后续更新同一条通知）、`SetAppLogoOverride`（圆形头像位）、`SetInlineImage`/`SetHeroImage`、`SetScenario`（提醒/闹钟/来电的强调级别）、`SetDuration`、`AddArgument`、`SetTag`/`SetGroup`（替换更新同条通知的寻址键）、`ExpiresOnReboot`。

### 参数与激活的契约

`AddArgument(L"action", L"activate")` 写进的是通知的**激活参数**：用户点通知本体或按钮时，应用收到 `"action=activate"` 形式的字符串。它不是 JSON——多参数拼成 `k1=v1;k2=v2`，你自己解析。**从通知输入框回传的文本走另一个集合**（`UserInput`，39.4）。

## 39.3 注册：打包与 unpackaged 的两条路

通知要能"回到"你的应用，Windows 得先认识它。**身份登记的形态取决于打包形态**（[01.7](01-tech-stack.md)）：

**打包应用（有 MSIX 清单）**——书 8.3 的路：清单里登 COM 激活器 + ToastActivatorCLSID（GUID），`AppNotificationManager.Default().Register()` 无参调用。清单片段（书 8.3 步骤 1-2 的直录）：

```xml
<desktop:Extension Category="windows.toastNotificationActivation">
  <desktop:ToastNotificationActivation ToastActivatorCLSID="你的GUID" />
</desktop:Extension>
<com:Extension Category="windows.comServer">
  <com:ComServer>
    <com:ExeServer Executable="App\App.exe" DisplayName="App"
                   Arguments="----AppNotificationActivated:">
      <com:Class Id="同一个GUID" />
    </com:ExeServer>
  </com:ComServer>
</com:Extension>
```

**unpackaged 应用（本教程四工程的形态）**——不用清单，用 1.3+ 的重载现场注册：

```cpp
// examples/34-os-integration/MainWindow.xaml.cpp
auto manager = AppNotificationManager::Default();
manager.Register(L"OsIntApp (C++/WinRT demo)",                // 显示名
    Windows::Foundation::Uri{ L"file:///" + exeDir + L"\\Assets\\appicon.png" });
```

`Register(displayName, iconUri)` 是 `IAppNotificationManager2` 的成员，**给没有包身份的进程现场发一个 AUMID**。三个实测细节：

1. **图标必须是存在的 `file://` URI**——图不存在 Register 不抛但通知降级（无图标）。34 例把 `Assets/appicon.png` 以 `Content/CopyToOutputDirectory` 随构建拷贝。
2. **Register 先于 Show**，且每次启动注册一次（重复注册幂等）。应用退出前不强制 Unregister——下次注册覆盖。
3. 书 8.1.3 的限制照抄：**以管理员身份运行的进程不符合通知条件**；"专注助手/勿扰"会把通知直接压进通知中心且**丢失交互能力**（输入框不可用）。

## 39.4 接收激活：NotificationInvoked

应用在运行时，用户点通知/按钮触发 `NotificationInvoked`。**这个事件在后台线程上来**（书 8.3 步骤 24 的 DispatcherQueue 检查在 C++ 里同样必要）：

```cpp
// examples/34-os-integration/MainWindow.xaml.cpp
m_notificationRevoker = manager.NotificationInvoked(auto_revoke_t{},
    [this](AppNotificationManager const&,
        AppNotificationActivatedEventArgs const& args)
{
    auto strong = get_strong();
    // args.Argument(): "action=activate" 形式的激活参数（hstring）
    // args.UserInput(): 通知输入框的内容（ValueSet，键=TextBox 的 InputId）
    m_dispatcherQueue.TryEnqueue([strong, argument = args.Argument()]
    {
        strong->StatusText().Text(std::wstring{ L"notification activated: " } +
            std::wstring_view{ argument });
    });
});
```

两件事别漏：

- **`auto_revoke_t` 退订票据存成员**（`m_notificationRevoker`）——窗口析构自动退订，断开事件环（[34.5](34-os-integration.md) 的纪律在通知上的应用）。
- 回 UI 用 `DispatcherQueue::TryEnqueue`（[32.7](32-binding-mvvm.md)），事件线程不是 UI 线程。

### 应用没在运行时点通知（激活启动）

书 8.3 步骤 16 用 `AppInstance.GetCurrent().GetActivatedEventArgs()` 检查 `ExtendedActivationKind::AppNotification`——C++ 投影里是 `winrt::Microsoft::Windows::AppLifecycle` 命名空间，同一套接口。但 **unpackaged 形态下"冷启动激活"依赖 COM 的 ExeServer 登记，而那份登记在 MSIX 清单里**——没有清单的 unpackaged 应用，冷启动激活会以普通启动进行（参数丢失）。这是 unpackaged 路线的诚实边界：**运行中点通知 → 完整闭环；冷启动点通知 → 要打包（42 章）才有**。

## 39.5 展示行为的真相（实测 + 书 8.3 尾注）

- 通知**不堆叠**：同应用连续 Show，后续直接进通知中心（Action Center），不弹横幅。
- 进了通知中心的通知**失去交互字段**（按钮还在，输入框不可用）。
- `notification.Id()` 非 0 是投递成功的信号（34 例状态行用它做无 UI 断言）。
- 要"更新已在通知中心的那条"：`SetTag`/`SetGroup` 定址 + 再次 Show 同 tag。

## 39.6 推送（WNS）：C++ 视角

书 8.2 的五步（清单 COM 登记 → PushNotificationManager 注册 → 通道创建 → WNS 注册 → HTTP POST 推送）里，**第 1、4、5 步与语言无关**（清单 XML、REST 调用），第 2、3 步的 API 全部有 C++ 投影（`Microsoft.Windows.PushNotifications` 在 Generated Files 里同样存在）。C++ 工程做推送的真正门槛是运维不是代码：Store 账号、Azure 通知中心、证书链。教程**不铺这条流水线**，需要时按书 8.2 的链接从 `PushNotificationChannel` 快速入门（learn.microsoft.com/windows/apps/windows-app-sdk/notifications/push-notifications/push-quickstart）走——那份文档的示例恰好 C++ 版齐全。

## 39.7 实测坑位（本章新增）

1. **链式 Builder 调用逐行写**——投影返回接口类型，长链在 MSVC 下有临时对象求值序的坑（教学代码可读性也更好）。
2. **`NotificationInvoked` 在后台线程**——直接碰控件 = 抛错或 stowed exception，`TryEnqueue` 是唯一正路。
3. **unpackaged Register 的图标 URI 必须真实存在**，且 `Content` 项要 vcxproj 登记（不然 VS 手搬 exe 调试时丢图标）。
4. **通知横幅一闪即进中心**：不是 bug。要停留/强调用 `SetScenario`，要覆盖用 Tag。
5. `Argument()` 是**字符串自拼格式**（`k=v;k=v`），别当 JSON 解析；`UserInput()` 才是结构化的 `ValueSet`。
6. **管理员权限运行的调试会话收不到通知**——以普通权限跑（VS 默认如此，除非开了管理员 VS）。

## 39.8 练习与思考

1. 给 34 例的通知加 `AddTextBox`，把用户输入回显到状态行（`UserInput` 集合）。
2. 用 `SetTag(L"progress")` + `AddProgressBar` 做一条假进度：每秒 Show 一次同 tag，观察通知中心里的原地更新。
3. 把 37 章 MediaLibrary 打包成 MSIX（42 章流程），给它加"删除收藏"成功后的本地通知——打包后 Register 换成清单路线，对比两份代码差在哪。
4. 思考：为什么本地通知也要"注册"？（提示：Windows 需要知道横幅点下去该激活谁——身份问题与 [42 章](42-packaging-deploy.md)的包身份是同一个问题的两面。）
