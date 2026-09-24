# 11. ToggleSwitch 与 ToggleButton：状态开关

上一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md) ｜ 下一篇：[12 Slider、ProgressBar、ProgressRing 与 RatingControl](./12-slider-progress.md)

10 章的 CheckBox/RadioButton 表达的是"表单数据"；本章的两个控件表达"即时生效的状态"——设置页的开关（ToggleSwitch）和工具栏的模式按钮（ToggleButton）。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

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

## 11.5 实战：总闸的完整生命周期（设置中心 + 数据浏览器）

### 11.5.1 开关的三件套：本体、文案、连坐

设置中心的通知总闸是 ToggleSwitch 的教科书场景——**状态立即生效，不需要确认**：

```xml
<ToggleSwitch x:Name="MasterSwitch" Header="Notifications"
              OnContent="On" OffContent="Off" IsOn="True"
              Toggled="OnMasterToggled"/>
```

`OnContent`/`OffContent` 让开关自带状态朗读：视觉是滑块位置，文字是当前语义——**两套反馈指同一状态，缺一个都算半残**（无文案的开关在暗色主题里尤其容易看错方向）。

处理器里做三件事（10.6.2 的全文）：

```cpp
bool on = MasterSwitch().IsOn();
for (auto&& child : ChannelBox().Children())
{
    if (auto control = child.try_as<Control>()) { control.IsEnabled(on); }
}
SettingsStore::Put(L"notify", on ? L"on" : L"off");
StatusText().Text(on ? L"notifications on: channels enabled"
                     : L"notifications off: channels disabled");
```

**连坐 → 持久化 → 状态行**，顺序即优先级：先让界面立刻对齐（用户的手还没离开开关），再写盘，最后补文字确认。`.smoke/07-settings-hub/master/tap-2.png`：开关 Off、三个渠道灰显、状态行三联动一帧完成。

### 11.5.2 构造期恢复：Toggled 会在你设值时触发

把上次的状态读回来：

```cpp
MasterSwitch().IsOn(SettingsStore::Get(L"notify", L"on") == L"on");
```

这行代码会**触发一次 Toggled**——ToggleSwitch 的 IsOn 是属性变更即事件（与 12 章 ValueChanged 同族）。构造期触发通常无害（处理器里的控件都已就绪），但若处理器引用了尚未构造的成员就是崩溃。防御性写法与 12.5 同款：处理器首行判空。**顺序也重要**：这行必须放在 InitializeComponent 之后、页面其余状态恢复之前——否则连坐禁用会把后续初始化的控件状态又改一遍。

### 11.5.3 ToggleButton：模式开关（数据浏览器）

视图切换用的是 ToggleButton（两态按钮，不是滑轨）：

```xml
<ToggleButton x:Name="CardsToggle" Content="Cards" Click="OnCardsToggled"/>
```

```cpp
void MainWindow::OnCardsToggled(IInspectable const&, RoutedEventArgs const&)
{
    m_cards = CardsToggle().IsChecked().Value();
    Table().Visibility(m_cards ? Visibility::Collapsed : Visibility::Visible);
    Cards().Visibility(m_cards ? Visibility::Visible : Visibility::Collapsed);
}
```

**坑位两枚**（都实测）：ToggleButton **没有 `Toggled` 事件**（XAML 编译器 WMC0011）——用 `Click`（每次点按必触发）或 `Checked`+`Unchecked` 成对挂；`IsChecked()` 返回 `IReference<bool>`（可空，支持三态），消费前 `.Value()` 取值。

**Switch 还是 ToggleButton？** 语义分界：Switch 表达"某功能开/关"（改变世界状态），ToggleButton 表达"某模式启用/停用"（改变交互视图）。总闸是前者，卡片视图是后者；颠倒使用不会崩，但用户的肌肉记忆会迷路——设置页里出现按钮样式的开关，没人敢直接点。

### 11.5.4 状态读写不对称

读开关：`IsOn()` / `IsChecked().Value()`——一个直接 bool，一个可空封装。这是 WinUI 遗产接口的写实：ToggleSwitch 从 UWP 时代就是强 bool；ToggleButton 的三态血统（继承 CheckBox 家族）注定它 nullable。写都一样直接赋值。跨控件搬代码时这个不对称最容易咬人。

### 11.5.5 Header 的排版位与标签虚线

ToggleSwitch 的 `Header` 渲染在开关上方（设置中心 "Notifications" 标签）——它不是行内标签。要"标签在左开关在右"的横排，自己摆 Grid 两列（TextBlock + ToggleSwitch），别扭曲 Header。**点击热区**：开关本体 + On/Off 文案可点，Header 标签不可点——小目标定律（Fitts）在触屏上是要紧事，行内标签紧贴开关时把标签也做进点击区（包一层 Button 样式化或处理 Tapped）是常见的补丁，设置中心没做（桌面鼠标场景热区足够）。

### 11.5.6 持久化的原子性

开关类设置的写入是**每拨一次写一次**（SettingsStore::Put 立即跟 Save 或攒批）——用户拨开关后杀进程（断电、崩溃）不能丢。设置中心走内存 Put + 显式 Save（保存按钮）——**开关即时生效但持久化等确认**，这个组合的产品语义是"先试后存"：拨了马上看到效果（主题/密度），保存才写盘；不保存就退出=回到旧值。另一种产品选择是"拨即存"（Windows 系统设置页），实现上把 Save 塞进 OnMasterToggled 即可——两种都对，**错的是没想清楚就混着**（有的开关即存、有的等保存，用户建模会分裂）。

### 11.5.7 触屏与滑轨

ToggleSwitch 在触屏上是**点击翻转**（不是拖拽）——WinUI 的触控适配已把它做成大目标按钮。别在 Tapped 里自己实现"拖到左半关右半开"，原生语义就够。真正的"拖拽调量"需求（连续值）用 Slider——这也反过来解释了 11/12 章的分界：**离散二值给开关，连续量程给滑杆**，中间态（三档）用 ComboBox 或分段控件。

### 11.5.8 开关与确认：即时生效的例外

"开关即时生效"有例外清单：**破坏性或高代价操作**（删数据、断连接、付费开关）不该拨了就执行——拨向危险侧要 ContentDialog 二次确认，取消则**把开关拨回去**（`MasterSwitch().IsOn(false)` 在代码里反转，视觉与意图重新对齐）。反转时又触发一次 Toggled——处理器要能区分"用户拨的"与"程序回拨的"（一个 bool 标志或检查 m_syncing）。这是开关家族最容易写错的时序，没有之一。

### 11.5.9 ToggleSwitch 的自动化面孔

朗读顺序：Header（"Notifications"）→ 状态（"on/off，开关"）。**OnContent/OffContent 参与朗读**——`OnContent="On"` 时念 "On, 开关"；自定义成 "已启用" 更友好。AutomationProperties.Name 可整体覆盖。触屏目标尺寸：开关本体约 44×20 逻辑 px——**点击区含 Header 与文案区**（整个控件行），比看起来大，别在窄行里挤两个开关（误触率翻倍）。

### 11.5.10 ToggleSwitch 与设置搜索的联动

设置中心有搜索（15 章）——开关们是搜索的**目标域**：搜 "notification" 该命中总闸所在的页。实现层：页面的可搜索文本集合（kPages 表）扩到控件级（"Notifications, master switch, channels"）——**每个交互控件的语义描述是搜索资产**，不是文案包袱。Windows 11 设置的搜索就是这么工作的（搜"深色"能到主题页）。教学工程的 kPages 停在页级；控件级搜索是自然的下一步扩展，架构上只改 OnSearchChanged 的扫描范围。

## 11.6 练习与思考

1. 11.5.8 的"危险开关确认"：把设置中心总闸改成关掉时弹 ContentDialog（关=停用所有通知，高风险），Cancel 时开关回弹。处理 Toggled 重入。
2. 把 DataExplorer 的 Cards 视图开关从 ToggleButton 换成 ToggleSwitch——用户会困惑吗？用 11.5.3 的语义分界论证。
3. 数一数 Windows 11 设置页里 ToggleSwitch 与 ToggleButton 的出现比例，推断微软的判断标准。

## 11.7 上生产前的审查清单

- [ ] 开关状态即时生效（无保存按钮语义混用），或明确走"先试后存"且全应用统一
- [ ] OnContent/OffContent 已设置且语义对仗（不是 On/空）
- [ ] 危险方向的开关有确认与回弹（11.5.8）
- [ ] 构造期恢复状态时 Toggled 重入已评估（11.5.2）
- [ ] 开关与滑杆的语义分工正确（离散二值 vs 连续量程）

## 11.6 小结

| 需求 | 控件 + 关键 API |
|------|----------------|
| 设置项开关 | ToggleSwitch：IsOn(bool) / Toggled / OnContent / OffContent / Header |
| 工具栏模式开关 | ToggleButton（Primitives）：IsChecked / Checked+Unchecked / IsThreeState |
| 命令栏模式开关 | AppBarToggleButton（23 章） |
| 表单多选 | 回 10 章 CheckBox |

运行时证据：`.smoke/07-settings-hub/master/tap-2.png`——Notifications 总闸翻 Off：开关本体移到左侧、On/Off 文案切换、下方三个渠道复选框整体灰显、状态行 **"notifications off: channels disabled"**。

---

上一篇：[10 CheckBox 与 RadioButton](./10-checkbox-radio.md) ｜ 下一篇：[12 Slider、ProgressBar、ProgressRing 与 RatingControl](./12-slider-progress.md) ｜ 返回 [目录](../README.md)
