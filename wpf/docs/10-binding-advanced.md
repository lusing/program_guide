# 10 · 绑定进阶：通知、集合与转换器

> 对应示例：`examples/10_binding_advanced`（MultiBinding + 集合 + 转换器的综合实验）

> **本章你将学会**：INotifyPropertyChanged 的标准写法、ObservableCollection、值转换器、MultiBinding、绑定调试方法。
> **前置章节**：[09 绑定基础](09-binding.md)。

## 1. 让"源"会说话：INotifyPropertyChanged

第 09 章绑定的源都是控件（控件属性是依赖属性，自带通知）。绑定到**自己的数据类**时，源只是普通 C# 属性——它变了，绑定管道不知道，界面不刷新。解法是让源实现 **INotifyPropertyChanged（INPC）**：

```csharp
public sealed class MainViewModel : INotifyPropertyChanged
{
    private string _firstName = "三";

    public string FirstName
    {
        get => _firstName;
        set
        {
            if (_firstName == value) return;      // ① 没变就别通知
            _firstName = value;
            OnPropertyChanged();                   // ② 通知"FirstName 变了"
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
```

setter 三步曲：**判等 → 赋值 → 通知**，一步不能少。`[CallerMemberName]` 让编译器自动填属性名字符串——杜绝 `OnPropertyChanged("FirstNam")` 手滑拼错（静默失效，极难查）。

绑定双方的完整要求（第 04 章伏笔兑现）：

| 角色 | 要求 | 例子 |
|---|---|---|
| 绑定**目标** | 必须是依赖属性（控件属性天然满足） | `TextBlock.Text` |
| 绑定**源** | 任意属性 + 变化时触发 INPC | ViewModel.FirstName |
| 源是**集合** | `ObservableCollection<T>` | Tasks |

`10_binding_advanced` 示例的 MainViewModel 完整实现了这套：任务列表增删时 `TaskCount`（派生属性）同步更新——setter 里额外 `OnPropertyChanged(nameof(TaskCount))`，这是派生属性联动的标准写法（第 17 章还会用到）。

## 2. ObservableCollection：会通知的集合

普通 `List<T>` 增删元素，绑定一无所知。`ObservableCollection<T>` 在增/删/替换/清空时触发 `CollectionChanged`，界面自动刷新：

```csharp
public ObservableCollection<TaskItem> Tasks { get; } = new();
Tasks.Add(new TaskItem { Name = "学绑定" });   // 列表条目立刻出现
Tasks.Remove(selected);                        // 条目立刻消失
```

两层通知缺一不可，职责不同：

```text
ObservableCollection → 管"列表的增删"（第几行没了/多了）
TaskItem 的 INPC     → 管"条目内部的变化"（某行的名字改了、勾选状态变了）
```

用 List + 重新赋值属性也能刷（属性通知了），但整表重建、选中/滚动状态全丢——ObservableCollection 是正确工具。**注意它不管排序**：要排序用 `CollectionViewSource`（第 17 章实战）。

## 3. 值转换器：类型对不上时的桥

目标是 `Visibility`（枚举），源给 `bool`——中间需要一座桥。实现 `IValueConverter`：

```csharp
public sealed class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is true ? Visibility.Visible : Visibility.Collapsed;

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is Visibility.Visible;
}
```

使用要先在资源字典登记（第 13 章伏笔），再以静态资源引用：

```xml
<Window.Resources>
    <local:BoolToVisibilityConverter x:Key="BoolToVis"/>
</Window.Resources>

<CheckBox Content="显示统计" IsChecked="{Binding ShowStats}"/>
<Border Visibility="{Binding ShowStats, Converter={StaticResource BoolToVis}}">
    ...统计面板...
</Border>
```

三条纪律：

1. **OneWay 绑定的 ConvertBack 直接抛 NotSupportedException**——写了也没人调，留 throw 反而能防误用（示例 FullNameConverter 就这么做的）
2. 转换器要写成**无状态**类（两个方向的方法可能被任意线程/任意绑定调用）
3. 最常见的 bool→Visibility 其实有内置的 `BooleanToVisibilityConverter`，先找内置再写自定义

顺带记住 `Visibility` 的两个"隐藏"：`Visible` / `Hidden`（占位隐藏）/ `Collapsed`（塌陷不占位）——转换器选哪个直接影响布局。

## 4. MultiBinding：多个源聚合成一个目标

"姓 + 名 → 全名"这类聚合，用 `MultiBinding` + `IMultiValueConverter`（示例第 1 区）：

```xml
<TextBlock>
    <TextBlock.Text>
        <MultiBinding Converter="{StaticResource FullName}">
            <Binding Path="LastName"/>
            <Binding Path="FirstName"/>
        </MultiBinding>
    </TextBlock.Text>
</TextBlock>
```

```csharp
public object Convert(object?[] values, ...) => $"{values[0]}{values[1]}";
```

顺序 = `<Binding>` 声明顺序。纯拼串不需要它——StringFormat 配多绑定也能拼；MultiBinding 的价值在**逻辑聚合**（如"两个字段都非空 → 按钮可用"）。

## 5. 绑定调试：从静默失败到定位

绑定失败不抛异常，只往输出窗口写一行。排查清单按命中率排序：

1. **输出窗口**有没有 Binding Error——90% 的"界面空白"在这找到答案
2. **DataContext 是不是 null / 设晚了**：绑定时还没值，之后又没通知
3. **Path 拼写**（不编译报错，纯运行时）
4. **源改了没触发通知**：忘实现 INPC / setter 忘调 OnPropertyChanged / 属性名字符串拼错
5. **集合用了 List** 而不是 ObservableCollection
6. **值在但显示怪**：类型不匹配（给 Text 绑 List）、StringFormat 转不动、转换器返回了错类型

开发期把绑定跟踪开到最高，输出窗口会打出每条绑定的求值过程：

```csharp
PresentationTraceSources.Refresh();
PresentationTraceSources.DataBindingSource.Switch.Level = SourceLevels.Warning;
```

VS 里还有个免代码的：选中元素看"实时可视化树"，DataContext 是谁、绑定值多少直接显示（第 24 章调试一节展开）。

## 6. 常见坑

**忘了 INPC**：属性改了界面不动——本坑命中率常年第一。判据：界面显示"初始值"之后再不变，九成是通知缺失。

**属性名手写字符串拼错**：`OnPropertyChanged("TaskNmae")` 静默失效。`[CallerMemberName]` 从根上消灭。

**转换器抛异常**：运行时绑定直接断（输出窗口有记录）。Convert 里做防御：`value is true` 这类模式匹配天然安全。

**在源属性 setter 里做重活**：setter 被 UI 高频调用（每敲一个字一次），弹窗/同步 IO/大量计算放进去会卡输入。重活下沉到命令（第 12 章），setter 只管存值与通知。

**ObservableCollection 跨线程改**：后台线程 Add 直接异常（集合通知只允许 UI 线程）。异步场景回 UI 线程再改（第 21 章）。

**一次性装换器状态**：转换器实例被多处共享（StaticResource 只建一次），别在字段里存"当前值"。

## 7. 实战建议

- `MainViewModel + TaskItem` 这套两层通知（集合 INPC + 元素 INPC）是列表界面的最小完整范式，示例可直接当模板抄
- 派生属性（TaskCount、FullName）**在引起它变化的 setter 里联动通知**——等界面"自己发现"是不可能的
- 转换器放独立文件按项目归类（Converters/ 目录），命名写清转换方向
- 开发全程保持输出窗口可见，绑定错误当场看，不要攒到联调
- 第 11 章的 ViewModelBase 将把 INPC 样板抽成基类——本章先痛一次，下一章就知道基类替你省了什么

## 自测

1. **INPC setter 的三步曲？漏掉判等会怎样？** —— 判等、赋值、通知；漏判等会重复通知（轻则浪费，重则循环触发）。
2. **ObservableCollection 和元素 INPC 各管什么？** —— 集合管条目增删，元素 INPC 管条目内部属性变化，两层缺一不可。
3. **bool→Visibility 有内置方案吗？还有哪两种"隐藏"？** —— 内置 BooleanToVisibilityConverter；Hidden 占位、Collapsed 塌陷。
4. **绑定排查第一步看什么？** —— 输出窗口的 Binding Error 行。

---
上一章：[09 绑定基础](09-binding.md) ｜ 下一章：[11 MVVM 模式](11-mvvm.md)
