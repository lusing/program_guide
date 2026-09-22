# 12. Slider、ProgressBar、ProgressRing 与 RatingControl

上一篇：[11 ToggleSwitch](./11-toggleswitch.md) ｜ 下一篇：[13 NumberBox](./13-numberbox.md)

"值在一段范围里"有四个控件：让用户**调**（Slider）、给用户**看进度**（ProgressBar/ProgressRing）、让用户**评**（RatingControl）。它们共享同一个基类机制 `RangeBase`。本章除了控件本身，还有全书目前最深的一个实测坑案例分析（12.5）。示例来自画廊工程的 `SliderPage`（左侧导航 **Slider** 项）。

## 12.1 RangeBase：范围值控件的地基

```text
RangeBase (Microsoft.UI.Xaml.Controls.Primitives)
├── Slider          用户拖动调值
├── ProgressBar     确定进度显示
└── ProgressRing    环形进度（1.8 起支持确定值）
```

公共属性：`Minimum` / `Maximum` / `Value`（都是 `double`），公共事件 `ValueChanged`，args 类型 `RangeBaseValueChangedEventArgs` 带 `NewValue()`/`OldValue()`——**比 TextBox.TextChanged 厚道**，新旧值都在（09 章 9.2 的对照）。

## 12.2 Slider：拖动调值

```xml
<Slider x:Name="VolumeSlider" Header="Volume"
        Minimum="0" Maximum="100" Value="25"
        StepFrequency="1" TickFrequency="25" TickPlacement="BottomRight"
        ValueChanged="OnVolumeChanged"/>
```

| 属性 | 作用 |
|------|------|
| `StepFrequency` | 值吸附步长（1 = 连续） |
| `SnapsTo` | `StepValues`（吸到步长）/ `Ticks`（吸到刻度）/ `Default`（不吸附） |
| `TickFrequency` / `TickPlacement` | 刻度密度与位置 |
| `Header` | 上方标签 |

键盘（方向键/翻页/PgUp）与点击轨道跳值都是内建行为——**点击轨道某处，值直接跳过去**，这是 ui-smoke 用合成点击驱动 Slider 的原理（不用模拟拖动）。

## 12.3 ProgressBar 与 ProgressRing：进度两面

```xml
<ProgressBar x:Name="SyncBar" Minimum="0" Maximum="100" Value="25"/>
<ProgressRing x:Name="BusyRing" IsActive="False" Width="32" Height="32"/>
```

- **ProgressBar**：确定模式 = `Value` 占 `Maximum` 的比例填充；不确定模式 = `IsIndeterminate="True"` 的往复动画（时长未知时用）。
- **ProgressRing**：环形的忙碌指示。元数据核对（1.8.260224000）：`IProgressRing` 有 `IsActive`、`IsIndeterminate` 和 **`Value`**——**WinUI 3 的 ProgressRing 支持确定值**（UWP 时代"只能转圈"的旧结论作废）；日常"忙碌中"用法仍是 `IsActive` 开关。
- 选型：**有百分比的确定性进度用确定模式；没有就用不确定模式**。永远别拿不确定 ProgressBar 充当装饰动画。

```cpp
void SliderPage::OnToggleBusyClicked(IInspectable const&, RoutedEventArgs const&)
{
    BusyRing().IsActive(!BusyRing().IsActive());
    StatusText().Text(BusyRing().IsActive() ? L"ring busy" : L"ring idle");
}
```

运行时切换 `IsActive`、`IsIndeterminate`、`Visibility` 都正常（实测，含连续多次切换的合成点击压力）——12.5 会讲为什么这项"正常"曾经被误判成崩溃。

## 12.4 RatingControl：打分

```xml
<RatingControl x:Name="Importance" Caption="importance" MaxRating="5"
               Value="3" ValueChanged="OnRatingChanged"/>
```

```cpp
void SliderPage::OnRatingChanged(IInspectable const&, IInspectable const&)
{
    // RatingControl.ValueChanged 的 args 是裸 IInspectable（元数据核对），值直接读控件
    if (!Importance() || !StatusText()) return;
    StatusText().Text(L"rating = " + winrt::to_hstring(Importance().Value()));
}
```

元数据实测要点：类名是 **`RatingControl`**（不是 `Rating`）；`Value` 是 `double`、`MaxRating` 是 `Int32`；`ValueChanged` 的委托第二参数是**裸 `IInspectable`**（不是什么 RatingEventArgs——网上教程常见的臆造类型，编译即报 C2039）。`PlaceholderValue` 用于"未评分但显示占位星"。

## 12.5 深坑实录：ValueChanged 在解析期与析构期都会触发

这是本章最有价值的内容——一个花了完整排查流程才定位的崩溃，完整记录如下。

**现象**：SliderPage 任意交互（拖值、点按钮、点星星）后 ~1–3 秒，进程 AV 崩溃（事件日志 c0000005）；有时拖到窗口关闭时才崩。其他页面无此问题。

**排查路径**（方法论比结论值钱）：

1. **事件日志拿偏移**：`Get-WinEvent Id=1000` 的 `Properties[7]` = 模块内偏移。
2. **map 文件符号化**：vcxproj 开 `<GenerateMapFile>true</GenerateMapFile>`，链接产生 `.map`；用偏移在符号表里找最近地址——落点：`winrt::impl::consume_..._IRangeBase<ProgressBar>::Value` —— **ProgressBar 的 Value 访问器**。
3. **对照实验矩阵**（每轮 ×2 起）：Home 页连击稳 / Button 页 5 连击稳 / SliderPage 纯导航也崩 → 锁定本页；逐个注释 handler 里的控件操作 → 定罪 `OnVolumeChanged` 里的 `SyncBar().Value(v)`。

**根因**：`ValueChanged` 不只在用户拖动时触发——**XAML 解析期**（`Value="25"` 属性应用时，若事件已接线）和**窗口析构期**（控件树拆除时的最后一次值刷新）都会走 handler。此刻相邻控件要么尚未建立、要么已经释放，`SyncBar()` 返回的是空投影对象，对它调 `.Value()` = 空引用 AV。间歇性 purely 是时序。

**修复（双保险，已在页面代码里）**：

```cpp
// ① 声明序：把 SyncBar 放在 VolumeSlider 之前的 XAML 里——解析期触发时它已存在
// ② 判空防护：任何 x:Name 控件在 handler 里先验后用
void SliderPage::OnVolumeChanged(IInspectable const&, RangeBaseValueChangedEventArgs const& args)
{
    if (!SyncBar() || !StatusText()) return;   // 解析期/析构期防御
    auto v = args.NewValue();
    if (std::abs(SyncBar().Value() - v) < 0.5) return;  // 值未变早退
    StatusText().Text(L"volume = " + winrt::to_hstring(v));
    SyncBar().Value(v);
}
```

投影类型对 `if (control)` 的判空是 `winrt` 的内建能力（底层 com_ptr 判空），代价一行，收益是整个生命周期的健壮。

**连带教训（自动化视角）**：排查中途一度把崩溃归咎于"运行时切换 ProgressRing.IsActive"——因为带防护缺失的 handler 页面上，任何交互都可能踩中空引用，切换动画态的按钮只是最常见的触发者。**单变量对照实验**（纯导航、单交互、状态-only handler）才把真凶剥离出来。写"实测坑"时这条纪律同样适用：**没有对照的归因都是嫌疑**。

另一个自动化副产物：ui-smoke 对含常驻动画的进程用 `TerminateProcess` 收尾会在事件日志留下 AV——驱动器已改为 `CloseMainWindow()` 优先、3 秒超时回退强杀。

## 12.6 实测坑位

1. **`ValueChanged` 的解析期/析构期触发**（12.5 全文——本章头号坑，判空 + 声明序双保险）。
2. **`RatingControl` 的 args 是裸 `IInspectable`**（12.4，C2039）。
3. **ProgressRing 确定值**：1.8 元数据有 `Value`，教程写法按新 API；`IsActive` 运行时切换正常（带 12.5 防护的前提下实测）。
4. **`RatingControl` 类名**：XAML 元素名与类型名一致是 `RatingControl`。
5. **在 ValueChanged 里回写 Value**：即使判了空，回写前也要比对值——等值回放在部分内部路径上仍会重入（防御性写法，见 12.5 代码）。

## 12.7 小结

| 需求 | 控件 + 关键 API |
|------|----------------|
| 范围调值 | Slider：Minimum/Maximum/Value/StepFrequency + ValueChanged(NewValue/OldValue) |
| 确定进度 | ProgressBar：Value 驱动填充 |
| 不确定进度 | ProgressBar：IsIndeterminate / ProgressRing：IsActive |
| 环形确定进度 | ProgressRing：Value（1.8 起） |
| 打分 | RatingControl：Value/MaxRating/PlaceholderValue，args 是 IInspectable |
| 值联动 | handler 判空 + 比对后直写；x:Bind 函数绑定见 32 章 |

画廊 `SliderPage` 运行时证据：`.smoke/07-controls-basic/slider/click-4.png`——轨道点击后 thumb 与 ProgressBar 同步 ~42%，busy 按钮两次切换后状态行 **"ring idle"**，全交互序列零崩溃（修复后 3/3 复测）。

---

上一篇：[11 ToggleSwitch](./11-toggleswitch.md) ｜ 下一篇：[13 NumberBox](./13-numberbox.md) ｜ 返回 [目录](../README.md)
