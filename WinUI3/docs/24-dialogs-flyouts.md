# 24. ContentDialog 与 Flyout

上一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 下一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md)

打断用户的两级手段：**模态**（ContentDialog——必须处理才能继续）与**轻浮层**（Flyout——点外面就走）。本章把两级的机制、时序和那个著名的 XamlRoot 坑讲全。示例代码来自功能工程 `examples/09-scratchpad/`（编辑器：多文档、加粗、查找、未保存确认、落盘回读）。

## 24.1 ContentDialog：模态确认

```cpp
winrt::Windows::Foundation::IAsyncAction DialogsPage::ShowDialogAsync()
{
    ContentDialog dialog;
    dialog.Title(box_value(L"Confirm removal"));
    dialog.Content(box_value(L"ContentDialog from a Page: XamlRoot still comes from the content tree root."));
    dialog.PrimaryButtonText(L"Remove");
    dialog.SecondaryButtonText(L"Keep");
    dialog.CloseButtonText(L"Cancel");
    dialog.DefaultButton(ContentDialogButton::Primary);

    // 24.2 核心坑：XamlRoot 从内容树根取（Window 自己没有这个成员）
    dialog.XamlRoot(rootPanel().XamlRoot());

    auto result = co_await dialog.ShowAsync();
    hstring verdict = result == ContentDialogResult::Primary ? L"primary: removed"
                   : result == ContentDialogResult::Secondary ? L"secondary: kept"
                                                                   : L"dismissed";
    if (!StatusText()) co_return;
    StatusText().Text(verdict);
}
```

机制逐条：

- **`ShowAsync` 是协程**：`co_await` 直到用户选择，返回 `ContentDialogResult`（Primary/Secondary/None）。None = 点了 Close 按钮、Esc 或标题栏关闭——**Close 按钮没有专属枚举值**，它就是"取消"语义。
- **三键封顶**：Primary/Secondary/Close。要更多入口就在 `Content` 里放自定义 UI（35 章 TaskFlow 的添加任务表单就这么做）。
- **`DefaultButton`** 绑回车键：对话框显示期间键盘焦点自动管理。
- **`Title`/`Content` 都是 `IInspectable`**：`box_value` 装（字符串/任意 UIElement 树）。

## 24.2 XamlRoot：全教程 Top 级坑的完整解释

```cpp
dialog.XamlRoot(rootPanel().XamlRoot());   // rootPanel 是页面根 Grid（x:Name）
```

**为什么必须设**：ContentDialog 要挂进 XAML 树渲染，而 WinUI 3 的弹层挂在独立的弹层根上（03 篇 3.4），运行时需要你显式告诉它"属于哪棵树"——不设就抛 **"XamlRoot has not been set"**（错误速查表常客）。

**为什么从内容树根取**：`XamlRoot` 是树级对象，`Microsoft.UI.Xaml.Window` **没有** `XamlRoot` 成员（元数据实证，README 早期实测）。取法：给页面根元素起 `x:Name`，`rootPanel().XamlRoot()`。在 Window 的 code-behind 里也一样——从 `this->Content().as<FrameworkElement>()` 取。

## 24.3 同时只允许一个

ContentDialog 是**应用级单例语义**：已有一个在显示时再 `ShowAsync` 第二个，直接抛异常。排队模式要自己写（一个 `std::queue` + 完成后弹下一个的协程链）。`Closing` 事件可以在关闭前拦截（`args.Cancel(true)` + 异步验证——"确认放弃未保存修改？"的二次确认用它）。

## 24.4 Flyout：轻浮层

```xml
<Button Content="Quick actions">
    <Button.Flyout>
        <Flyout Placement="Bottom">
            <StackPanel Spacing="8">
                <Button Content="Retry" Click="OnRetryClicked"/>
                <Button Content="Skip" Click="OnSkipClicked"/>
            </StackPanel>
        </Flyout>
    </Button.Flyout>
</Button>
```

- **`Button.Flyout` 语法糖**：点击自动开合，零代码。任何元素也能用 23 章的 `AttachedFlyout + ShowAt` 手动控制。
- **light-dismiss**：点击浮层外任意处自动关闭——与模态的本质差。
- `Placement` 控制锚定方位（Top/Bottom/Left/Right/Full...）。
- 浮层里放交互控件（本页 Retry/Skip）是合法且常用的（快速操作菜单）。

**选择矩阵**（含 25 章）：

| 手段 | 模态 | 生存期 | 典型 |
|------|------|--------|------|
| ContentDialog | 是 | 用户选择为止 | 破坏性确认、必须填的表单 |
| Flyout | 否（light-dismiss） | 失焦即走 | 快速操作、弹出说明 |
| TeachingTip（25 章） | 否 | 显式关闭/超时 | 新手引导 |

## 24.5 实测坑位

1. **XamlRoot 未设**（24.2，症状即抛错信息本身；从内容树根取）。
2. **两个 ContentDialog 并发**：第二个 ShowAsync 抛异常（24.3）。
3. **co_await 后判空**：协程恢复时页面可能已被导航销毁——`if (!StatusText()) co_return;`（12.5 的异步版，get_strong 模式见 32.7）。
4. **Esc = None**：把"取消"逻辑挂在 None 分支，别只处理 Primary。
5. **Flyout 里再弹 Flyout/Dialog**：层级管理混乱，避免嵌套弹层。

## 24.5 实战：未保存确认的完整时序（ScratchPad）

关闭一个脏页签，走到 ContentDialog 的全链路：

```cpp
Windows::Foundation::IAsyncAction MainWindow::OnTabCloseRequested(
    TabView const&, TabViewTabCloseRequestedEventArgs const& args)
{
    auto tab = args.Tab();
    auto entry = FindEntry(tab);
    if (entry && entry->Dirty)
    {
        // 24 章核心：WinUI 3 必须显式给 XamlRoot
        ContentDialog dlg;
        dlg.Title(box_value(L"Unsaved changes"));
        dlg.Content(box_value(L"Save '" + entry->Name + L"' before closing the tab?"));
        dlg.PrimaryButtonText(L"Save");
        dlg.SecondaryButtonText(L"Discard");
        dlg.CloseButtonText(L"Cancel");
        dlg.DefaultButton(ContentDialogButton::Primary);
        dlg.XamlRoot(Docs().XamlRoot());

        auto choice = co_await dlg.ShowAsync();
        if (choice == ContentDialogResult::Primary)
        {
            SaveTab(tab);                    // Save：存了再关
        }
        else if (choice == ContentDialogResult::None)
        {
            co_return;                       // Cancel：什么都不关
        }
        // Secondary（Discard）：不存，直接落到下面关页签
    }
    CloseTab(tab);
    if (m_docs.empty()) { AddTab(); }
}
```

### 24.5.1 三钮语义学

| 按钮 | ContentDialogResult | 行为 | 设计理由 |
|---|---|---|---|
| Primary (Save) | Primary | 存盘 → 关 | 安全默认 |
| Secondary (Discard) | Secondary | 弃改 → 关 | 明知故犯的出口 |
| Close (Cancel) | None | 什么都不做 | 反悔的门 |

**Cancel 必须显式 co_return**——落到函数尾就会关掉页签，"取消"变成"取消保存但照样关闭"（数据丢失 bug，语义完全反转）。三钮命名链：`PrimaryButtonText`/`SecondaryButtonText`/`CloseButtonText`——Close 按钮没有 Text 后缀的赋值时**根本不渲染**（两钮对话框就是这么来的）。

`DefaultButton(ContentDialogButton::Primary)` 让回车落在 Save——与视觉强调（主按钮填充色）指向同一动作：**键盘与鼠标的默认路径一致**是 DefaultButton 存在的全部意义。

### 24.5.2 XamlRoot 坑的真身

`dlg.XamlRoot(Docs().XamlRoot())` 这行不写，ShowAsync 抛 `COMException`——UWP 时代对话框挂在 ApplicationView 上，桌面 WinUI 3 没有它，每个窗口有自己的 XamlRoot 树根。**取哪个控件的都行**（同窗内共享）：`Docs()` 是 TabView，页里写就是 `this->XamlRoot()`。窗口嵌套/多窗口场景（31 章）里这行从"模板代码"升级为"正确性代码"——挂错窗口的对话框照常显示，关不掉也够你查一下午。

### 24.5.3 协程是唯一的异步形态

`co_await dlg.ShowAsync()` 要求处理器是协程（返回 IAsyncAction）。事件处理器变协程的三条纪律（32.7 全讲，这里先用起来）：**捕获按值**（`auto tab = args.Tab()`——挂起期间引用参数必悬空）；**不 lock**（UI 线程协程没有真并发，锁反而死锁自己）；**返回后世界已变**（await 回来时用户可能已点了别的——对 tab 状态的重校验放 await 之后）。

`.smoke/09-scratchpad/close/tap-3.png`：输入 unsaved work → 点页签 X → 对话框弹出（Unsaved changes + Save/Discard/Cancel 三钮 + 轻遮罩）——模态的全部视觉要素一帧齐活。

### 24.5.4 ContentDialog 的排他律

**同一 XamlRoot 同时只能开一个 ContentDialog**——第二个 ShowAsync 抛 `COMException`（"已经有一个打开"）。页签连续快速关闭（两个脏页签两记 Ctrl+W）就会踩：第一个对话框还没关、第二个 TabCloseRequested 已到。防御：窗口级 `std::atomic<bool> m_dialogUp` 进出置位，或在 ShowAsync 前 try/catch 退化为"直接保存"。ScratchPad 单用户操作序列教学没做这层——**产品化第一件事就是补它**，这也是"教学示例→产品"的距离样本。

### 24.5.5 Flyout：轻量到什么程度

Flyout（点外即走）适合**确认性小操作**：删除确认、颜色快选。与 ContentDialog 的分界在**丢失成本**：Flyout 关闭=用户意图取消，操作没发生（数据无损）；对话框三选一每条路都有后果。ScratchPad 没用 Flyout（保存确认值得模态）；DataExplorer 若加"删除文件"操作，确认就该是 Flyout（点外=不删，零损失）——**后果可逆用 Flyout，不可逆用 Dialog**。

## 24.6 小结

| 需求 | API |
|------|-----|
| 模态确认 | ContentDialog + ShowAsync（协程）+ 三键 + DefaultButton |
| 表单对话框 | Content 放自定义 UI 树 |
| 快速浮层 | Button.Flyout 或 AttachedFlyout + ShowAt |
| 关闭前拦截 | Closing 事件 + args.Cancel |

运行时证据：`.smoke/09-scratchpad/close/tap-3.png`——关闭带未保存修改的页签，模态 ContentDialog 弹出（标题 Unsaved changes，Save/Discard/Cancel 三钮，DefaultButton=Primary），XamlRoot 显式取自 `Docs().XamlRoot()`（24 章的核心坑在这里是真代码）。

---

上一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 下一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 返回 [目录](../README.md)
