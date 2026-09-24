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

## 31.5 尺寸、位置与逻辑单位（本套教程实测最贵的一课）

### 31.5.1 AppWindow 系按逻辑单位解释

实测（175% DPI 显示器）：`appWindow.Resize({ 1080, 700 })` 得到 **1890×1225 物理**窗口；`MoveAndResize({ 30, 30, ... })` 的落点在 **(53, 53)**——30 × 1.75 的取整。文档口径与实测口径不一致时以实测为准，本教程四个功能工程全部按逻辑单位传参。

四个工程的自定位写法（构造期一次到位）：

```cpp
if (auto appWindow = AppWindow())
{
    // 1000x620 逻辑 = 1750x1085 物理 @175%，装得进 2194x1234 的屏
    appWindow.MoveAndResize(Windows::Graphics::RectInt32{ 30, 30, 1000, 620 });
}
```

两个细节：**`{...}` 花括号字面量有歧义**——它可能解析到 float 的 Rect 重载（又乘一次 1.75），显式写 `Windows::Graphics::RectInt32{...}` 钉死整数版；**构造期自移是安全的，外部再动窗口会打烂 XAML 岛的输入变换**（下一节的战争实录）。

### 31.5.2 级联出屏与注入输入

系统级联位置可能把大窗口顶出屏幕（底部出屏）——视觉上只是"截了一块"，**但对自动化是灾难**：注入点击的 release 命中在出屏区域失效，表现为"点了没反应"。自定位到完全在屏内后消失。这条坑与下一条合起来是"为什么教程应用全部自定位 (30,30)"的完整答案。

### 31.5.3 SetWindowPos 与岛输入变换（战争实录摘要）

外部 `SetWindowPos`（测试工具停靠窗口的常规操作）在 XAML 岛安定后执行：**渲染照旧、指针命中错位**——press 落在 A 处、界面认为点在 B 处。大目标（导航行、滑杆）仍在错位后的可命中区里"碰巧能点"，小目标（按钮、单选环）全军覆没。结论：**外部工具永远不要移动/缩放 WinUI 3 窗口**——要固定布局，让应用构造期自己来。完整排查过程见 README 验证段的"输入注入战争实录"。

## 31.6 单实例与激活重定向（方向）

`Microsoft.Windows.AppLifecycle.AppInstance` 是方向性内容：`FindMainInstance`/重定向激活（第二实例启动时把参数转给先例并退出）。多窗口编辑器（每文档一窗）与单窗口工具（如设置中心）是两个典型用例。本教程工程未覆盖（教学边界如实声明）；官方 WindowsAppSDK 礷例 `AppLifecycle` 有完整可抄实现。

## 31.7 实测坑位（窗口篇）

1. **`AppWindow().Resize` 的参数是 `SizeInt32`**（物理像素！150% DPI 下 Resize({900,640}) 得到的是 600×427 逻辑）——三个画廊统一 Resize({1280,860}) 的换算即为此。
2. **自绘标题栏要留系统按钮区**：右上角约 138×44 逻辑像素内别放可点内容。
3. **`SetTitleBar` 的元素必须在内容树里**（x:Name 挂根布局首行）。
4. **多窗口同线程共享 DispatcherQueue**：跨线程改 UI 仍必须 `TryEnqueue`（34 章）。
5. **材质要求 Win11**：Win10 上 Mica 退化为纯色——按系统版本降级预期。

### 31.5.4 DPI 感知与坐标一致性

窗口内容在高 DPI 屏上"清晰但坐标乱"的根源是**进程 DPI 感知级别**：WinUI 3 应用默认 Per-Monitor V2（清晰）；测试工具若不声明（ui-smoke.ps1 里那行 `SetProcessDpiAwarenessContext(PER_MONITOR_AWARE_V2)` 就是为此），GetWindowRect 拿到虚拟化坐标——点击换算差一个 1.75 倍，全盘错位。**工具与应用必须同感知级别**，这是自动化坐标系的隐含契约。自家代码里 `GetSystemMetrics`/`GetCursorPos` 系列同理——混用感知级别的进程互相看对方的窗口，尺寸永远是错的。

### 31.5.5 多显示器的 MoveAndResize

窗口跨屏（从 175% 屏拖到 100% 屏）：XAML 自动重排（逻辑单位不变、物理尺寸变），AppWindow 的 MoveAndResize 传的是**当前屏的坐标系**——跨屏定位要按目标屏 DPI 换算（`DisplayArea.GetFromPoint` 拿屏信息，31 章工程未覆盖，方向性提示）。单屏教学工程无此坑；产品化的多屏支持是窗口篇最深的坑矿。

### 31.4.x 多窗口的进阶形态

每窗口独立线程的完整姿势（防一窗卡全卡）：`std::thread` 里 `init_apartment(MTA)` + 各自 `DispatcherQueueController` + `make<Window>()`——31 章工程没走这条（同线程双窗够教学），产品级的"多文档独立响应"是它。**窗口间通信**：同线程直接调（本工程的 StatusText 跨窗写）；跨线程 `DispatcherQueue.TryEnqueue` 把 lambda 投递过去（34 章线程边界）。

## 31.9 练习与思考

1. 给 ThemeLab 加第二窗口（预设对照：左窗 Sunset 右窗 Forest）——两窗的 accent 独立吗？（提示：Application.Resources 是进程级的——这个练习逼你理解"应用级资源"与"窗口级主题"的分界）
2. 把设置中心的自定位改成"记住上次位置"（退出存盘、启动读回）——MoveAndResize 时机与出屏校验（拖到副屏后副屏被拔）各怎么处理？
3. OverlappedPresenter 全家：把窗口改成不可调（Resizable=false）与置顶（IsAlwaysOnTop）各跑一遍，观察标题栏按钮变化。

## 31.8 小结

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
