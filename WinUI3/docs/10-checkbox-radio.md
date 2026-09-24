# 10. CheckBox 与 RadioButton：选择的状态

上一篇：[09 TextBox](./09-textbox.md) ｜ 下一篇：[11 ToggleSwitch](./11-toggleswitch.md)

"选/不选"这件事在 WinUI 3 里有三个控件：CheckBox（多项选择）、RadioButton（单项互斥）、ToggleSwitch（设置开关，11 章）。本章讲前两个——它们同根同源（RadioButton 直接继承 ToggleButton，CheckBox 也继承 ToggleButton），核心机制是同一个：**`IsChecked` 是三态可空布尔**。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 10.1 家谱与共同机制

```text
ToggleButton
├── CheckBox          多选；默认两态，IsThreeState 开三态
└── RadioButton       组内互斥；两态（选中/未选中）
```

两者读写状态的属性都叫 `IsChecked`，类型都是 **`IReference<bool>`**——可空布尔，这是本章最重要的机制：

```cpp
auto const& checked = NotifyBox().IsChecked();   // IReference<bool>
if (!checked)            { /* nullptr：尚未设置（三态模式下的中间态显示前） */ }
else if (checked.Value()) { /* true：选中 */ }
else                     { /* false：未选中 */ }
```

为什么不是 `bool`？因为"选择"真实存在第三态：**不确定（indeterminate）**——"子项部分选中"的父项、"未作答"的问题。`IReference<bool>` 用 `nullptr` 承载这个状态，同时强迫你读的时候处理它（解引用 nullptr 的 `IReference` 会抛，所以判空是肌肉记忆）。

> 这是教程 README 错误速查表里的常客：`if (NotifyBox().IsChecked())` 直接编译不过——`IReference<bool>` 不能隐式转 bool，必须 `.Value()`。

## 10.2 CheckBox：三态的开关与循环

```xml
<CheckBox x:Name="NotifyBox" Content="Enable notifications" IsChecked="True"
          IsThreeState="True"
          Checked="OnNotifyChanged" Unchecked="OnNotifyChanged" Indeterminate="OnNotifyChanged"/>
```

- **`IsThreeState="False"`（默认）**：点击在 选/不选 间切换，`IsChecked` 永远是 true/false（但类型仍是 `IReference<bool>`，判空习惯不变）。
- **`IsThreeState="True"`**：多出 indeterminate 态。**实测点击循环顺序是 checked → unchecked → indeterminate → checked**——注意不是直觉上的"选中→半选→不选"。要程序化设半选：`NotifyBox().IsChecked(nullptr);`（设 nullptr 就是 indeterminate）。

三个事件按状态各走各的：

| 事件 | 触发时机 |
|------|---------|
| `Checked` | 变为 true |
| `Unchecked` | 变为 false |
| `Indeterminate` | 变为 nullptr（三态模式） |

**只挂 Checked/Unchecked 的坑**：三态模式下进/出半选态你的代码毫无感知，状态栏与真实状态脱节。要么三个都挂（本页做法，共用一个 handler 读 `IsChecked` 最省），要么明确业务用不到半选就关 `IsThreeState`。

## 10.3 RadioButton：GroupName 的互斥圈

```xml
<StackPanel Orientation="Horizontal" Spacing="12">
    <RadioButton Content="Light" GroupName="Theme" IsChecked="True" Checked="OnThemeChecked"/>
    <RadioButton Content="Dark" GroupName="Theme" Checked="OnThemeChecked"/>
    <RadioButton Content="System" GroupName="Theme" Checked="OnThemeChecked"/>
</StackPanel>
```

```cpp
void CheckBoxPage::OnThemeChecked(IInspectable const& sender, RoutedEventArgs const&)
{
    auto button = sender.as<RadioButton>();
    StatusText().Text(L"theme = " + button.Content().as<hstring>());
}
```

`GroupName` 划定互斥圈，三条规则：

1. **同名互斥，与容器无关**。同一个 GroupName 的 RadioButton 即使散在不同 StackPanel 里也互斥——互斥按名字圈，不按视觉位置圈。
2. **不写 GroupName 的危险**：默认组名是空串，**同页面所有无组名的 RadioButton 全部互斥**——两组"无名单选"会互相打架。永远显式写 GroupName。
3. **初始无选中**：一组都没设 `IsChecked="True"` 时全空。表单上"必选一"的组要自己给默认或校验。

事件只挂 `Checked`：选中引发的旧项 `Unchecked` 不用管（互斥是框架做的），从 `sender` 读"选了谁"。`Content` 是 `IInspectable`，`as<hstring>()` 解包（07 章同一机制）。

### RadioButton 只在"少量且全可见"时用

选项多、动态、或要占位小时，ComboBox（14 章）更合适——Radio 占的是永久空间，换来的好处是全部选项一眼可见、单击直达。

## 10.4 三兄弟怎么选

| 场景 | 控件 |
|------|------|
| 多个独立的是/否选项 | CheckBox |
| 少量（≤5）互斥选项、全部可见 | RadioButton |
| 互斥选项多或要省空间 | ComboBox（14 章） |
| 设置项的即时开关（不提交表单） | ToggleSwitch（11 章） |
| 工具栏上的模式开关（加粗等） | ToggleButton（11 章） |

判断的根：**"选择"是数据（表单语义）还是"状态"（立即生效的设置语义）**。数据用 CheckBox/Radio/ComboBox，状态用 Toggle 系。

## 10.5 实测坑位

1. **`IsChecked()` 当 bool 用**：`IReference<bool>` 不能隐式转换，`.Value()` 前先判空（10.1）。
2. **半选设值**：`IsChecked(nullptr)` 是进半选的写法；`IsThreeState=False` 时设 nullptr 抛异常。
3. **三态点击顺序**：实测 checked→unchecked→indeterminate（10.2），文档站未明说，UI 自动化/教学演示按此排预期。
4. **GroupName 省略**：全页无名单选互串（10.3 规则 2）。
5. **程序化设 IsChecked 触发事件**：ctor 里设初值会走一遍 Checked——handler 若引用尚未初始化的成员会崩。习惯：**InitializeComponent 之后、接线之前不动状态；或 handler 判空**。
6. **Checked 里读"别的单选"**：互斥切换时旧项的状态已在变，别依赖"此刻另一项还是选中"的中间态。

## 10.6 实战：一组单选真的换肤，一组复选真的连坐（设置中心）

### 10.6.1 单选组：主题三选

```xml
<StackPanel Orientation="Horizontal" Spacing="16">
    <RadioButton x:Name="LightRadio"  Content="Light" GroupName="Theme" Checked="OnThemeChecked"/>
    <RadioButton x:Name="DarkRadio"   Content="Dark"  GroupName="Theme" Checked="OnThemeChecked"/>
    <RadioButton x:Name="SystemRadio" Content="Follow system" GroupName="Theme" Checked="OnThemeChecked"/>
</StackPanel>
```

三个成员共享 `GroupName="Theme"`（同组互斥）和同一个 `Checked` 处理器——**用 `sender` 区分是谁**：

```cpp
void AppearancePage::OnThemeChecked(IInspectable const& sender, RoutedEventArgs const&)
{
    if (!IsLoaded() || !StatusText()) { return; }   // 解析期触发的 Checked 一律跳过
    hstring name = sender.as<RadioButton>().Content().as<hstring>();
    hstring key = name == L"Light" ? L"light" : name == L"Dark" ? L"dark" : L"default";
    Application::Current().as<SettingsHub::App>().ApplyTheme(key);
    SettingsStore::Put(L"theme", key);
    StatusText().Text(L"theme = " + name);
}
```

第一行的守卫不是装饰：**XAML 里给任何 RadioButton 写 `IsChecked="True"` 都会在解析期触发 Checked**，此刻 App 可能还没拿到窗口引用——直接调 ApplyTheme 就是启动崩溃（12.5 坑的致命变体，实测复现）。所以恢复已存主题时，选中态在 ctor 里代码设置，且主题应用由 MainWindow 自理。

**`.smoke/07-settings-hub/theme/tap-1.png`**：点 Dark 后圆点入位、状态行 "theme = Dark"、整窗换暗——一次点击三层反馈，这是"单选=即时生效"的完整形态（对照表单型单选：提交时才读值）。

### 10.6.2 复选连坐：总闸与渠道

```cpp
void NotificationsPage::OnMasterToggled(IInspectable const&, RoutedEventArgs const&)
{
    bool on = MasterSwitch().IsOn();
    // Panel 没有 IsEnabled（那是 Control 的属性）：逐个禁用渠道 CheckBox
    for (auto&& child : ChannelBox().Children())
    {
        if (auto control = child.try_as<Control>())
        {
            control.IsEnabled(on);
        }
    }
}
```

"总闸关掉、渠道灰显"就是 IsEnabled 的连坐语义——灰显不只是视觉：禁用的控件不再参与 Tab 序、屏幕阅读器跳过、点击无响应，三层一致。**坑**：容器 Panel 不是 Control，没有 IsEnabled 可设；要么逐子遍历（如上），要么把渠道组换成 UserControl/ContentControl 这种 Control 派生容器再整体禁用。

**三态复选在这套应用里的取舍**：渠道复选全部两态（IsChecked 不预置 null）；三态（`IsThreeState`）适合"父项汇总子项"的树形场景——全选/部分选/全不选，本章开头的三态表在那种语境下才有产品意义。

### 10.6.3 三态语义的工程化：null 不是"没选"

两态复选的 IsChecked 类型是 `IReference<bool>`（可空）——null 是第三个合法值："部分选中"（IsThreeState=true 时用户可见）或"尚未交互"。设置中心把渠道复选**恢复期**读成：

```cpp
ToastCheck().IsChecked(SettingsStore::Get(L"toast", L"true") == L"true");
```

字符串比较给 bool，null 态被刻意压掉——恢复语义里"没存过"等同"默认开"。**什么时候让 null 活着**：父节点汇总子节点（全选/部分/全不选）时，父复选的值就该是子集的投影（全真=真、全假=假、混合=null），用户点它再展开成显式真/假写回全部子节点。设置中心没这层树，所以 null 只在初始化瞬间存在且立即被赋值覆盖。

### 10.6.4 键盘可达：单选组的方向键

同 GroupName 的单选组自动获得方向键导航（上下左右在组内移动焦点并选中）——这是 RadioButton 内建的，一行代码不用写。但注意它与 15 章 AutoSuggestBox 的键盘流在同一个 Tab 序里排队：设置中心 Appearance 页的 Tab 序是 Light→Dark→System→密度下拉→滑杆，方向键在单选组内消化、Tab 跨组跳跃——**两种键各司其职，别在处理器里抢 Tab 的活**（拦截 KeyDown 改 Tab 行为是最快的可达性破坏）。

### 10.6.5 复选框的对齐细节

渠道组的三个 CheckBox 垂直间距 Spacing=8——比按钮组（16）紧：**复选清单是"一组相关小项"，视觉上要聚成一团**。框与文字的间距由控件内建（8px 逻辑），别用 Margin 手调（主题更新会变）。列表项复选（DataExplorer 若加"多选下载"）用 `ListView` + ItemTemplate 包 CheckBox 而非 StackPanel 硬摆——虚拟化与键盘导航都是白送的。

## 10.6 小结

| 需求 | 写法 |
|------|------|
| 三态复选 | `IsThreeState="True"` + 三事件共用 handler + 判空读值 |
| 半选 | `IsChecked(nullptr)` |
| 互斥组 | 同 `GroupName` + 每组一个初始 `IsChecked="True"` |
| 读选中的是谁 | `sender.as<RadioButton>().Content().as<hstring>()` |

运行时证据：`.smoke/07-settings-hub/theme/tap-1.png`——Light/Dark/Follow system 三个同组单选（GroupName="Theme"），点 Dark 后圆点选中、状态行 **"theme = Dark"**、整窗换暗；`.smoke/07-settings-hub/master/tap-2.png`——总闸关闭后 Toast/Sounds/Email 三个渠道 CheckBox 整体灰显（IsEnabled 连动）。

---

上一篇：[09 TextBox](./09-textbox.md) ｜ 下一篇：[11 ToggleSwitch](./11-toggleswitch.md) ｜ 返回 [目录](../README.md)
