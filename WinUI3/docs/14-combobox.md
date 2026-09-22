# 14. ComboBox：下拉选择

上一篇：[13 NumberBox](./13-numberbox.md) ｜ 下一篇：[15 AutoSuggestBox](./15-autosuggestbox.md)

选项多到 RadioButton 铺不下（10 章），就要收进下拉框。`ComboBox` 是"点开才见选项"的单选控件；WinUI 3 还给了它 `IsEditable`——能打字的下拉框，介于选择与输入之间。示例来自画廊工程的 `ComboBoxPage`（左侧导航 **ComboBox** 项）。

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

## 14.7 小结

| 需求 | 写法 |
|------|------|
| 静态项 | XAML 子元素 `x:String` |
| 动态项 | ItemsSource + WinRT 集合 |
| 读选择 | SelectedIndex（int）或 SelectedItem（判空 + unbox） |
| 程序化选择 | SelectedIndex(n)，事件自动触发 |
| 可输的定位 | IsEditable="True" |
| 自由输入 | 换 AutoSuggestBox |

画廊 `ComboBoxPage` 运行时证据：`.smoke/07-controls-basic/combobox/click-2.png`——点击 "Select Dark"，状态行 **"theme = Dark"**，下拉框同步显示 Dark。

---

上一篇：[13 NumberBox](./13-numberbox.md) ｜ 下一篇：[15 AutoSuggestBox](./15-autosuggestbox.md) ｜ 返回 [目录](../README.md)
