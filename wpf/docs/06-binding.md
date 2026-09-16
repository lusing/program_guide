# 06 · 数据绑定：从 DataContext 到转换器

> 对应示例：`examples/02_binding`

## 1. 绑定解决什么问题

事件写法的死穴是**同步**：数据改了要手动刷新控件，控件改了要手动读回数据，每一处都要写，漏一处就是 bug。MFC 的 DDX（第 06 章）用 `UpdateData(TRUE/FALSE)` 手动触发两个方向的快照；WPF 的绑定则是一条**持续的管道**：源变了目标自动变，目标变了源自动变，没有"触发"这个动作。

绑定四要素：

```text
{Binding Path=..., Source=..., Mode=..., Converter=...}
```

| 要素 | 含义 | 缺省时 |
|---|---|---|
| `Path` | 源对象上的属性路径 | 绑定整个对象 |
| `Source` | 源对象 | 沿可视化树向上找 `DataContext` |
| `Mode` | OneWay / TwoWay / OneTime / OneWayToSource | 依目标属性默认（TextBox.Text 是 TwoWay） |
| `Converter` | 两个方向各自如何转换 | 直接类型转换 |

**DataContext 继承**是绑定的隐形主角：元素自己没设 Source 时沿树向上找最近的 DataContext，所以"窗口设一次 DataContext，整棵树都能绑"。

## 2. ElementName：控件绑定控件

`02_binding` 示例没有任何 ViewModel，两个 TextBlock 直接绑定到别的控件——先建立直觉：

```xml
<TextBox x:Name="NameEntry" Text="Alice" />
<Slider x:Name="ValueSlider" Minimum="0" Maximum="100" Value="60" />

<TextBlock Text="{Binding ElementName=NameEntry, Path=Text, StringFormat='Hello, {0}!'}" FontSize="20" />
<TextBlock Text="{Binding ElementName=ValueSlider, Path=Value}" FontSize="18" />
```

拖动 Slider，数字实时变；改 TextBox，问候实时变——**一行处理函数都没写**。Slider 的 Value 变化沿绑定管道流进 TextBlock.Text（OneWay），这就是绑定在"管数据"而不是"被打调"。

注意第二个 TextBlock 显示的是 0~100 的数字原样；想要 `60%` 就用 `StringFormat='{}{0}%'`（`{}` 是转义前缀，见第 03 章）。

## 3. UpdateSourceTrigger：TextBox 的著名陷阱

TwoWay 绑定回写源的时机由 `UpdateSourceTrigger` 决定，默认值是 **LostFocus**：

```xml
<!-- 每敲一个字都更新源 -->
<TextBox Text="{Binding Content, UpdateSourceTrigger=PropertyChanged}" />
```

后果：用户在 TextBox 里打字，源属性要等**焦点离开**才更新。你的"保存"按钮绑定的命令在用户还没点别处时读到的是旧值。修正：触发时机改成 `PropertyChanged`。第 12 章实战项目的编辑框就是这么写的——这是 WPF 新手最常踩也最容易查明的坑。

## 4. INotifyPropertyChanged：让"源"会说话

绑定源不必是依赖属性，但必须是"会通知"的——实现 `INotifyPropertyChanged`：

```csharp
public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _taskName = "学习 WPF";

    public string TaskName
    {
        get => _taskName;
        set
        {
            if (_taskName == value) return;
            _taskName = value;
            OnPropertyChanged();      // [CallerMemberName] 自动带上 "TaskName"
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
```

方向对照表：

| 角色 | 要求 | 例子 |
|---|---|---|
| 绑定**目标** | 必须是依赖属性（控件属性天然都是） | `TextBlock.Text` |
| 绑定**源** | 普通 CLR 属性 + INPC 通知 | ViewModel.TaskName |
| 源是**集合** | `ObservableCollection<T>` | 第 12 章的 RecentFiles |

`ObservableCollection<T>` 是"会发通知的 List"：增删元素时自动刷界面，但对**元素内部属性变化**无效——元素自己要实现 INPC。

## 5. 转换器：类型对不上时的桥

目标要 `Visibility`，源给 `bool`——写一个 `IValueConverter`：

```csharp
public class BooleanToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, ...) => (bool)value ? Visibility.Visible : Visibility.Collapsed;
    public object ConvertBack(object? value, ...) => value is Visibility v && v == Visibility.Visible;
}
```

```xml
<Window.Resources>
    <local:BooleanToVisibilityConverter x:Key="BoolToVis" />
</Window.Resources>
<TextBlock Text="机密内容" Visibility="{Binding IsAdmin, Converter={StaticResource BoolToVis}}"/>
```

多数"界面要不要显示"的判断都适合放转换器或触发器（第 08 章 DataTrigger），**别为显示逻辑改数据模型**。此外内置的 `BooleanToVisibilityConverter` 覆盖了最常见场景，不必每处自己写。

多源聚合用 `MultiBinding` + `IMultiValueConverter`（如"姓 + 名 → 全名"）；纯拼串则 `StringFormat` 就够，不需要转换器。

## 6. 调试绑定

绑定失败不抛异常，只在输出窗口写一行：

```text
System.Windows.Data Error: 40 : BindingExpression path error: 'UserrName' property not found ...
```

排查清单按命中率排序：

1. **输出窗口**有没有 Binding Error——90% 的"界面空白"在这找到答案
2. DataContext 是不是 null / 设晚了（绑定时还没有值，之后没通知）
3. Path 拼写（绑定错误不编译报错，纯运行时）
4. 源属性改了但**没触发 INPC**（或触发的名字写错）
5. 集合用了 List 而不是 ObservableCollection

## 7. 常见坑

**忘记 INPC**：属性改了界面不动，90% 是没实现 INotifyPropertyChanged 或 setter 里忘了触发。

**字符串属性名**：`OnPropertyChanged("TaskNmae")` 拼错静默失效。用 `[CallerMemberName]` 从根上消灭。

**绑定方向误解**：Mode 缺省不是 TwoWay！`TextBlock.Text` 默认 OneWay、`TextBox.Text` 默认 TwoWay，由依赖属性的元数据决定。拿不准就显式写 Mode。

**绑定整个对象当字符串**：`Text="{Binding}"` 显示 Person 类的 ToString。要么给 Path，要么重写 ToString（仅调试期推荐）。

**在源属性 setter 里做重活**：setter 在绑定时被高频调用（尤其 PropertyChanged 触发器），别在里面弹窗/同步 IO。

## 8. 实战建议

- 每个窗口/页面一个 ViewModel，`DataContext` 在构造函数赋值——第 07 章的 MVVM 就建立在这条管道上
- 集合绑定的增删走 `ObservableCollection`，元素属性变化靠元素自己的 INPC，两层通知缺一不可
- 显示格式优先 `StringFormat`，其次转换器，最后才考虑在源上再造一个"显示用属性"
- 开发期保持"输出窗口"开着，绑定错误当场看到，不要攒到联调

---
上一章：[05 核心控件与路由事件](05-controls.md) ｜ 下一章：[07 MVVM 与命令](07-mvvm-commands.md)
