# 11. ToggleSwitch 与 ToggleButton：状态开关

上一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md) ｜ 下一篇：[12 Slider、ProgressBar、ProgressRing 与 RatingControl](./12-slider-progress.md)

10 章的 CheckBox/RadioButton 表达的是"表单数据"；本章的两个控件表达"即时生效的状态"——设置页的开关（ToggleSwitch）和工具栏的模式按钮（ToggleButton）。示例来自画廊工程的 `TogglePage`（左侧导航 **Toggle** 项）。

## 11.1 定位：数据 vs 状态的分界线

同一个"开/关"，放在表单里是**待提交的数据**，放在工具栏/设置页里是**立即生效的状态**。这条线决定控件选择：

| 语境 | 控件 | 交互预期 |
|------|------|---------|
| 表单（点了先不生效，提交才生效） | CheckBox（10 章） | 打勾 |
| 设置项（点了立即生效） | **ToggleSwitch** | 拨开关 |
| 工具栏模式（加粗、覆盖模式等，可叠加） | **ToggleButton** | 按下去亮 |

选错控件用户不会有"报错"体验，但会有"迟钝/错乱"体验：设置项用 CheckBox，用户点了却没生效，会怀疑自己要点"保存"。

## 11.2 ToggleSwitch：普通 bool 的清爽世界

```xml
<ToggleSwitch x:Name="AutoSaveSwitch" Header="Auto save"
              OnContent="Saving after every edit" OffContent="Manual save only"
              IsOn="True" Toggled="OnAutoSaveToggled"/>
```

```cpp
void TogglePage::OnAutoSaveToggled(IInspectable const&, RoutedEventArgs const&)
{
    // IsOn 是普通 bool——与 CheckBox 的 IReference<bool> 三态对照
    StatusText().Text(AutoSaveSwitch().IsOn() ? L"autosave on" : L"autosave off");
}
```

和 10 章的 `IsChecked` 对比一下就懂设计意图：

| | ToggleSwitch.IsChecked（无） | ToggleSwitch.IsOn |
|---|---|---|
| 类型 | — | `bool`，非空 |
| 三态 | 不支持 | **没有三态** |
| 事件 | — | `Toggled`（一个，不带参数区分方向） |

开关语义天然两态，所以 `IsOn` 直接是 `bool`，**没有 `IReference<bool>`、没有判空、没有 Indeterminate 事件**——这是 API 设计在替你减负。`Toggled` 只此一个事件，方向自己读 `IsOn()`。

`OnContent`/`OffContent` 是开关旁的状态文案（本页 "Saving after every edit" ↔ "Manual save only"）；不写则显示系统的 On/Off。**文案要写"现状描述"而不是"动作指令"**——用户看文案确认当前状态，不是被告知点击会发生什么。

## 11.3 ToggleButton：住在 Primitives 里的工具栏开关

```xml
<StackPanel Orientation="Horizontal" Spacing="12">
    <ToggleButton x:Name="BoldBtn" Content="Bold" IsThreeState="False"
                  Checked="OnModeToggled" Unchecked="OnModeToggled"/>
    <ToggleButton x:Name="ItalicBtn" Content="Italic"
                  Checked="OnModeToggled" Unchecked="OnModeToggled"/>
    <ToggleButton x:Name="WrapBtn" Content="Wrap" IsChecked="True"
                  Checked="OnModeToggled" Unchecked="OnModeToggled"/>
</StackPanel>
```

```cpp
void TogglePage::OnModeToggled(IInspectable const& sender, RoutedEventArgs const&)
{
    auto button = sender.as<ToggleButton>();
    auto name = button.Content().as<hstring>();
    // IsChecked 是 IReference<bool>（继承自 CheckBox 家族的语义）
    bool on = button.IsChecked().Value();
    StatusText().Text(name + (on ? L" = on" : L" = off"));
}
```

两个实测要点：

1. **命名空间坑**：`ToggleButton` 不在 `Microsoft.UI.Xaml.Controls` 而在 **`Microsoft.UI.Xaml.Controls.Primitives`**（和 `RepeatButton` 同区，7 章家谱里它们都挂在 ButtonBase 下）。`using namespace` 少写一行就是 C2065 未声明标识符。
2. **它继承的是 CheckBox 的状态语义**：`IsChecked` 同为 `IReference<bool>`，同样有 `IsThreeState`、同样 Checked/Unchecked/Indeterminate 三事件。工具栏模式一般 `IsThreeState="False"`（默认就是 False），但"段落混合格式"场景（选区既有粗有细）三态正好表达。

页面初始状态 `Wrap IsChecked="True"` 会在 **InitializeComponent 期间触发一次 Checked**——本页状态行在加载时就显示 "Wrap = on"（运行时实测，smoke 截图可见）。这是 10 章 10.5 坑位 5 的直接后果：**构造期赋初值会走事件**，handler 必须能承受"控件树只建了一半"的时刻（12 章会把这条坑的完整形态展开——它不只是烦，还能崩进程）。

## 11.4 AppBarToggleButton 预告

CommandBar 里有专门的 `AppBarToggleButton`（23 章）——语义同 ToggleButton，外形是带图标和标签的命令栏按钮。工具栏开关放 CommandBar 里时不用裸 ToggleButton。

## 11.5 实测坑位

1. **`ToggleButton` 的命名空间**：`Controls.Primitives`，不是 `Controls`（11.3，编译级 C2065）。
2. **构造期初值触发事件**：`IsChecked="True"` 在 InitializeComponent 内就走 Checked；同理 `IsOn="True"` 会走 Toggled。handler 里引用后建立的控件 = 隐患（12 章 12.5 的崩溃案例分析）。
3. **`IsChecked` 判空**：ToggleButton 上它仍是 `IReference<bool>`，`.Value()` 前的老规矩。
4. **OnContent/OffContent 文案方向**：写现状（"自动保存已开启"），不写动作（"点击开启"）。

## 11.6 小结

| 需求 | 控件 + 关键 API |
|------|----------------|
| 设置项开关 | ToggleSwitch：IsOn(bool) / Toggled / OnContent / OffContent / Header |
| 工具栏模式开关 | ToggleButton（Primitives）：IsChecked / Checked+Unchecked / IsThreeState |
| 命令栏模式开关 | AppBarToggleButton（23 章） |
| 表单多选 | 回 10 章 CheckBox |

画廊 `TogglePage` 运行时证据：`.smoke/07-controls-basic/toggle/click-2.png`——点击 Auto save 开关本体，状态行变 **"autosave off"**，开关翻 Off、文案切到 "Manual save only"。

---

上一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md) ｜ 下一篇：[12 Slider、ProgressBar、ProgressRing 与 RatingControl](./12-slider-progress.md) ｜ 返回 [目录](../README.md)
