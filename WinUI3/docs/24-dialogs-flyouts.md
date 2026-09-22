# 24. ContentDialog 与 Flyout

上一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 下一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md)

打断用户的两级手段：**模态**（ContentDialog——必须处理才能继续）与**轻浮层**（Flyout——点外面就走）。本章把两级的机制、时序和那个著名的 XamlRoot 坑讲全。示例来自画廊工程的 `DialogsPage`（导航 **Dialogs** 项）。

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

## 24.6 小结

| 需求 | API |
|------|-----|
| 模态确认 | ContentDialog + ShowAsync（协程）+ 三键 + DefaultButton |
| 表单对话框 | Content 放自定义 UI 树 |
| 快速浮层 | Button.Flyout 或 AttachedFlyout + ShowAt |
| 关闭前拦截 | Closing 事件 + args.Cancel |

画廊 `DialogsPage` 运行时证据：`.smoke/21-controls-shell/dialogs/click-3.png`——Show dialog → 模态弹出 → 点击 Remove → 对话框关闭、状态行 **"primary: removed"**（模态全链路，合成点击三点接力）。

---

上一篇：[23 CommandBar 与菜单](./23-commandbar-menus.md) ｜ 下一篇：[25 TeachingTip、InfoBar 与 ToolTip](./25-overlays.md) ｜ 返回 [目录](../README.md)
