# 31. 窗口与外壳：AppWindow、标题栏与背景材质

上一篇：[30 图形与媒体](./30-drawing-media.md) ｜ 下一篇：[32 绑定、MVVM 与异步](./32-binding-mvvm.md)

`Microsoft.UI.Xaml.Window` 只是故事的一半——窗口的**壳**（尺寸、标题栏、材质、多窗口、单实例）在另一层 API 里。本章把两层拼起来。示例来自工程 `examples/31-window-shell/`（`WindowShellApp`，非画廊结构）。

## 31.1 两层 API：Window 与 AppWindow

| 层 | 管什么 | 典型调用 |
|----|--------|---------|
| `Microsoft.UI.Xaml.Window` | XAML 宿主：内容树、激活、标题栏合作 | `Activate()` / `Content()` / `SetTitleBar()` |
| `Microsoft.UI.Windowing.AppWindow` | 壳 HWND 语义：尺寸/位置/图标/Presenter | `Window.AppWindow().Resize(...)` / `SetIcon(...)` |

**`Window.AppWindow()`**（1.4+，1.8 元数据核对）是从 XAML 层拿到壳层的桥。本教程三个画廊骨架里 `appWindow.Resize({1280,860})` 固定初始尺寸用的就是它（`Windows.Graphics.SizeInt32`）。Presenter（`OverlappedPresenter` 等）控制边框/可调性/最小化行为，进阶按元数据查 `AppWindow.Presenter()`。

## 31.2 标题栏三种做法

1. **系统默认**：什么也不做。
2. **扩展自绘**（本工程）：

```cpp
ExtendsContentIntoTitleBar(true);   // 内容区延伸进标题栏
SetTitleBar(AppTitleBar());         // 这块 Border 成为拖拽区 + 双击最大化区
```

   XAML 里首行放 `Height="44"` 的标题条（留出最小化/最大化/关闭按钮的空间——那三个系统按钮仍浮在右上）。**注意**：`Window` 自己没有 `XamlRoot`（24 章的老朋友），同理标题栏区域属于窗口层概念。
3. **AppWindow.TitleBar 全 API 定制**：按钮前景/悬停色等逐项设置（`TitleBar()` 返回 `AppWindowTitleBar`，元数据在 `Microsoft.UI.Windowing`）——深度品牌化用，自绘法覆盖 90% 场景。

## 31.3 SystemBackdrop：背景材质

```cpp
SystemBackdrop(MicaBackdrop());            // 加载即 Mica
...
SystemBackdrop(DesktopAcrylicBackdrop());  // 切亚克力
SystemBackdrop(nullptr);                   // 关掉
```

- 类型族：`MicaBackdrop`（云母——不透明矿石质感，桌面壁纸染色）与 `DesktopAcrylicBackdrop`（亚克力——半透明模糊，能透出后面的窗口）。基类 `Microsoft.UI.Xaml.Media.SystemBackdrop`。
- **运行时切换正常**（本工程按钮切换实测：截图可见材质差异 + 状态行回报）。
- 深浅色主题下材质自动适配（33 章）；配合 31.2 的标题栏扩展，材质贯通整窗。

## 31.4 多窗口

```cpp
void MainWindow::OnNewWindowClicked(IInspectable const&, RoutedEventArgs const&)
{
    auto second = make<MainWindow>();
    second.Activate();
    StatusText().Text(L"second window opened");
}
```

`make<Window>() + Activate()` 就是全部——每个 `Window` 自带内容树。**线程模型**：同一线程上创建的窗口共享一个 `DispatcherQueue`（UI 线程），从任一窗口的 UI 线程操作另一窗口的对象都合法（本工程两窗同线程，实测同开）。要"每窗口独立线程"（防一个卡全卡）则每个窗口一条线程 + 各自 `DispatcherQueue`，复杂度陡增，按需再上。

窗口生命周期：不持有强引用的窗口会被回收——`App` 里像 04 章那样存 `window` 成员，多窗口就 `std::vector<Window>`（34 章的引用计数纪律同样适用）。

## 31.5 单实例与激活重定向（方向）

`Microsoft.Windows.AppLifecycle.AppInstance` 提供 `FindOrRegisterForKey` / `GetActivatedEventArgs` / `RedirectActivationToAsync`——第二实例启动时把激活转给已存在实例并退出。这块依赖应用激活协议的完整链路（打包形态有额外要求），本教程定位为**方向指引**而非已验证路径：非打包形态下的重定向实测留作诚实边界，工程需要时从 `AppInstance` 的元数据起步。

## 31.6 实测坑位

1. **`AppWindow().Resize` 的参数是 `SizeInt32`**（物理像素！150% DPI 下 Resize({900,640}) 得到的是 600×427 逻辑）——三个画廊统一 Resize({1280,860}) 的换算即为此。
2. **自绘标题栏要留系统按钮区**：右上角约 138×44 逻辑像素内别放可点内容。
3. **`SetTitleBar` 的元素必须在内容树里**（x:Name 挂根布局首行）。
4. **多窗口同线程共享 DispatcherQueue**：跨线程改 UI 仍必须 `TryEnqueue`（34 章）。
5. **材质要求 Win11**：Win10 上 Mica 退化为纯色——按系统版本降级预期。

## 31.7 小结

| 需求 | API |
|------|-----|
| 固定初始尺寸 | `AppWindow().Resize({物理px})` |
| 自绘标题栏 | `ExtendsContentIntoTitleBar(true)` + `SetTitleBar(bar)` |
| 背景材质 | `SystemBackdrop(MicaBackdrop()/DesktopAcrylicBackdrop())` |
| 多窗口 | `make<Window>() + Activate()`（同线程共享 DQ） |
| 单实例 | `AppInstance`（方向，31.5 边界） |

工程 `WindowShellApp` 运行时证据：`.smoke/31-window-shell/home/click-2.png`——自绘标题栏（无系统标题文字）、点击 Acrylic 后背景呈半透明模糊、点击 New window 后状态行 **"second window opened"** 且第二窗口同屏可见。

---

上一篇：[30 图形与媒体](./30-drawing-media.md) ｜ 下一篇：[32 绑定、MVVM 与异步](./32-binding-mvvm.md) ｜ 返回 [目录](../README.md)
