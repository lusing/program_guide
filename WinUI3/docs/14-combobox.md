# 14. ComboBox：下拉选择

上一篇：[13 NumberBox](./13-numberbox.md) ｜ 下一篇：[15 AutoSuggestBox](./15-autosuggestbox.md)

选项多到 RadioButton 铺不下（10 章），就要收进下拉框。`ComboBox` 是"点开才见选项"的单选控件；WinUI 3 还给了它 `IsEditable`——能打字的下拉框，介于选择与输入之间。示例代码来自功能工程 `examples/07-settings-hub/`（设置中心：主题/密度/透明度即点即生效并持久化）。

## 14.1 喂选项的三种方式

```xml
<!-- 方式一：XAML 子元素直接装箱字符串（少量静态项的最短路径） -->
<ComboBox x:Name="ThemeBox" Header="Theme" PlaceholderText="pick one..."
          SelectionChanged="OnThemeChanged">
    <x:String>Light</x:String>
    <x:String>Dark</x:String>
    <x:String>System</x:String>
</ComboBox>
```

| 方式 | 适用 |
|------|------|
| XAML 子元素 | 3–8 个静态项，写死无妨 |
| `ItemsSource` + 集合 | 动态项；`ItemsSource(single_threaded_vector<hstring>(...))` |
| `ItemsSource` + `ItemTemplate` | 项是对象，要自定义每行长什么样（17 章 ListView 同机制） |

前两种的项都是"装箱的 hstring"——引出本章的核心机制。

## 14.2 SelectedItem 是装箱对象

```cpp
void ComboBoxPage::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
{
    if (!ThemeBox() || !StatusText()) return;   // 12.5 的解析期/析构期防御
    if (auto item = ThemeBox().SelectedItem())
    {
        StatusText().Text(L"theme = " + winrt::unbox_value<hstring>(item));
    }
}
```

`SelectedItem()` 返回 **`IInspectable`**——因为 ComboBox 的项可以是任何类型（字符串、自定义 runtimeclass、UIElement）。你装进去的是 hstring，取出来就要 `unbox_value<hstring>` 解包。两个常错：

- **当 hstring 用**：`item + L"x"` 编不过——它是 IInspectable，不是字符串。
- **忘了可能为空**：没有选中时返回 nullptr，`unbox_value(nullptr)` 抛异常。先 `if (auto item = ...)` 再解。

`SelectedIndex()` 是绕开装箱的整数路线（-1 = 未选），简单场景更省心。

## 14.3 初始化时序与程序化选择

```cpp
void ComboBoxPage::OnSelectDarkClicked(IInspectable const&, RoutedEventArgs const&)
{
    ThemeBox().SelectedIndex(1);   // 触发同一个 SelectionChanged
}
```

程序化设 `SelectedIndex` 与用户点选走同一事件——所以"恢复上次选择"的代码天然复用 handler。但要记住 12.5 的教训在 ComboBox 上的形态：**XAML 里写死选中项**（如给某项 `IsSelected="True"`）会在 InitializeComponent 期间触发 SelectionChanged，此刻页面其他控件未必就绪——**判空防护是每个 SelectionChanged handler 的第一行**（本页示例即如此）。

## 14.4 IsEditable：能打字的下拉框

```xml
<ComboBox x:Name="CountryBox" Header="Country (editable)" IsEditable="True"
          PlaceholderText="type to filter...">
```

WinUI 3 的 ComboBox 支持 `IsEditable`（元数据核对：1.8 有此属性）：用户可以在框里打字，列表按前缀过滤跳转。它与 15 章 `AutoSuggestBox` 的分界：

| | ComboBox + IsEditable | AutoSuggestBox |
|---|---|---|
| 语义 | 从固定清单里选（可打字辅助定位） | 搜索/自由输入（建议列表） |
| 列表来源 | ItemsSource 固定 | 每次输入动态给 |
| 值域 | 清单内 | 任意文本 |
| 典型场景 | 国家、时区 | 搜索框、@提及 |

**判断线：答案是否必须来自清单**。是 → ComboBox（IsEditable 只是输入辅助）；否 → AutoSuggestBox。

## 14.5 与相邻控件的取舍表

| 场景 | 控件 |
|------|------|
| ≤5 个互斥选项、全可见 | RadioButton（10 章） |
| 5–30 个固定选项 | **ComboBox** |
| 选项需搜索/自由输入 | AutoSuggestBox（15 章） |
| 上下文菜单动作 | MenuFlyout（23 章） |

## 14.6 实测坑位

1. **SelectedItem 装箱**（14.2）：unbox_value 解包 + 判空。
2. **替换 ItemsSource 清空选中**：整个换掉集合对象后 SelectedIndex 回到 -1、SelectedItem 变 nullptr——handler 里别假设选中仍在。
3. **初始化期 SelectionChanged**（14.3）：XAML 写死选中或 ctor 里设 SelectedIndex 都会提前触发；判空防御。
4. **`MaxDropDownHeight`**：列表太长时下拉自己滚动，别在外面包 ScrollViewer。
5. **PlaceholderText 不参与选择**：它不是一项。要"默认选 System"就程序化设 SelectedIndex。

## 14.5 实战：下拉框改的是真实布局（设置中心）

密度选择不是"选了报状态"——选中项直接改预览列表的行高：

```xml
<ComboBox x:Name="DensityBox" Header="List spacing" Width="220"
          SelectionChanged="OnDensityChanged">
    <x:String>Comfortable</x:String>
    <x:String>Compact</x:String>
</ComboBox>
```

处理器在**代码里构造 Style** 套到列表的项容器上：

```cpp
void AppearancePage::OnDensityChanged(IInspectable const&, SelectionChangedEventArgs const&)
{
    if (!PreviewList() || !StatusText()) { return; }
    if (auto item = DensityBox().SelectedItem())
    {
        hstring density = unbox_value<hstring>(item);
        double minHeight = density == L"Compact" ? 28.0 : 44.0;

        // 元数据实测：ListViewItem 没有静态 PaddingProperty——密度用
        // FrameworkElement::MinHeight 的容器样式实现
        Microsoft::UI::Xaml::Style spacing;
        spacing.TargetType(xaml_typename<ListViewItem>());
        Microsoft::UI::Xaml::Setter height(FrameworkElement::MinHeightProperty(),
            box_value(minHeight));
        spacing.Setters().Append(height);
        PreviewList().ItemContainerStyle(spacing);
        ...
    }
}
```

三处都是实战级细节：**`Style`/`Setter` 裸名会被 FrameworkElement::Style 属性遮蔽**（成员上下文里 C2146/C2665），必须全限定 `Microsoft::UI::Xaml::Style`；**密度用 MinHeight 而不是 Padding**——ListViewItem 的元数据里没有静态 PaddingProperty，MinHeight 同样达成"行高"且兼容虚拟化；**SelectionChanged 出参是 SelectedItem（IInspectable）**，`x:String` 项用 `unbox_value<hstring>` 取回。

### 14.5.1 预选必须在 ctor 里

```cpp
hstring density = SettingsStore::Get(L"density", L"Comfortable");
DensityBox().SelectedIndex(density == L"Compact" ? 1 : 0);
```

**XAML 里写 `SelectedIndex="0"` 会在 Items 子元素建立之前应用**——启动即崩（stowed exception，实测复现）。这是 12.5 家族的第三名成员：RadioButton 的 IsChecked、Slider 的 Value、ComboBox 的 SelectedIndex，凡是"属性即事件"的控件，XAML 预置值都在赌解析时序。规则统一为：**XAML 放结构，代码放状态**。

### 14.5.2 IsEditable 的适用边界

`IsEditable="True"` 让下拉框变"可输入的单行框 + 建议列表"——但输入值不在选项里时它**不是**自动新增选项，而是把自由文本原样交给你（`Text` 与 `SelectedItem` 可能对不上）。设置中心没用它：密度只有两个合法值，自由输入是制造脏数据的入口。它适合的形态是"历史记录 + 允许临时新值"（如浏览器地址栏）——那其实已经是 AutoSuggestBox（15 章）的领域，两者的分界就在"选项封闭与否"。

### 14.5.3 ItemsSource 化：三个以上选项就该换队形

两选项的 ComboBox 是浪费（点开下拉才见第二个——RadioButton 摆开更直接）。设置中心两选项走 ComboBox 是**教学覆盖**优先；产品判断线：**2 项用 RadioButton/ToggleSwitch，3–7 项 ComboBox，更多项 AutoSuggestBox**（输字过滤胜过滚动找）。选项集合会变（如 DataExplorer 的类别）就 ItemsSource 接向量，XAML 里静态 `x:String` 只喂真正的常量。

### 14.5.4 SelectionChanged 的负载取舍

取选中项有三条路：`SelectedItem()`（IInspectable，要 unbox）、`SelectedIndex()`（int，但要自己映射语义）、`Text()`（IsEditable 才有意义）。**设置中心用 SelectedItem+unbox**——选项即语义（"Compact" 字符串直接进存储与判断）。索引版在选项重排时是定时炸弹（"1 是紧凑"硬编码进逻辑）；对象版（FileItem 那类）最稳但两选项犯不着。选哪条都行，**别混用**——一处用索引一处用字符串，重构时必漏。

### 14.5.5 下拉的虚拟化与大量选项

ComboBox 的下拉列表**默认虚拟化**（百项无压力）；但 `IsEditable=true` 时自动关闭——可编辑下拉建议走 AutoSuggestBox（15 章）。选项超三四十个就该给用户过滤入口：要么 ASB，要么分组（`ComboBoxItem` 前插不可选的分组头——IsEnabled=false 的伪标题项，土但有效）。**MaxDropDownHeight** 控制下拉高度（默认约 7 项高），别调太大——比窗口还高的下拉是事故。

### 14.5.6 SelectedValue 与绑定（32 章预告）

ComboBox 有 `SelectedItem`（对象）与 `SelectedValue`+`SelectedValuePath`（取对象的某属性做值）——WPF 迁移者熟悉这对。WinUI 3 里 **SelectedValuePath 存在但 x:Bind 场景基本用不上**：直接 SelectedItem 双向绑到视图模型的对象属性更 C++/WinRT 风格（值转换在属性 getter 里做）。设置中心走事件直读 SelectedItem——三种风格（事件/绑定/ValuePath）在同一控件上的取舍，32 章统一讲。

### 14.5.7 下拉动画与开合感知

ComboBox 下拉展开有系统动画（滑出）——`IsDropDownOpen` 可查/可设（程序化开合）。教学常见误区：自己写开合动画（Storyboard 折叠面板）复刻 ComboBox——内建的这个就是了（还带遮罩关闭、Esc 关闭、焦点管理三件免费）。**ComboBox 开着时点外面=选中关闭**；要"点外面=取消关闭"（不改变选择）用 `IsEditable=false` + SelectionChanged 里校验，或干脆用 ListPickerFlyout（更冷门但语义正）。

## 14.6 练习与思考

1. 把 DensityBox 换成两个 RadioButton——哪个更省一次点击？哪个更省屏幕？什么时候空间比点击贵？
2. 给 ComboBox 选项换成 FileItem 对象（17 章模型）：SelectedItem 取回对象后 as 成什么？对照 14.5.4 的三条取值路。
3. 14.5.1 的坑：把 SelectedIndex=0 写回 XAML，用 UnhandledException 落盘法（27.2.1 坑③）抓启动崩溃的消息，把它变成你的教学素材。

## 14.7 小结

| 需求 | 写法 |
|------|------|
| 静态项 | XAML 子元素 `x:String` |
| 动态项 | ItemsSource + WinRT 集合 |
| 读选择 | SelectedIndex（int）或 SelectedItem（判空 + unbox） |
| 程序化选择 | SelectedIndex(n)，事件自动触发 |
| 可输的定位 | IsEditable="True" |
| 自由输入 | 换 AutoSuggestBox |

AppearancePage 的 DensityBox（Comfortable/Compact 两项）真改 ListView 密度：OnDensityChanged 在代码里构造 ItemContainerStyle（ListViewItem 的 MinHeight 44/28）套到预览列表上，状态行同步 **"density = Compact"**。注意预选必须在 ctor 里 `SelectedIndex(...)`——XAML 里设置会在 Items 建立前应用而崩（实测）。

---

上一篇：[13 NumberBox](./13-numberbox.md) ｜ 下一篇：[15 AutoSuggestBox](./15-autosuggestbox.md) ｜ 返回 [目录](../README.md)
