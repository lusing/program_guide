# 6. 常用控件：真实写法与使用模式

控件本身不难，难的是两个问题：**这个控件在工程里扮演什么角色**，以及**哪些 API 细节是坑**。本篇按角色分类过一遍主力控件，代码均为真实 C++/WinRT 写法。

> **哪些要进 IDL？** 本篇的 C++ 成员函数（`OnSaveClicked`、`OnThemeChanged`、`OnNotifyToggled` 等）都是**按名字挂接的事件处理器**（XAML 里写 `Click="OnSaveClicked"`、`SelectionChanged="OnThemeChanged"`）——这类处理器**不需要进 `.idl`**，只要它是 `x:Class` 实现类上的成员函数，XAML 就引用得到。真正**必须进 IDL** 的是 `x:Bind` 路径上的成员（如 6.4 的 `ViewModel.Themes`/`SelectedTheme`、6.5 的 `ViewModel.Tasks`、6.6 的 `ViewModel.AutoSave`）。规则详见 [04 篇](./04-first-app.md) 4.7；`examples/06-controls/` 编译验证过：下面所有事件处理器都没写进 IDL 照样编过、跑通。为省篇幅，示例只给 XAML + `.cpp`。

学习主线不是背控件表，而是记住这个角色表：

| 角色 | 控件 |
|------|------|
| 触发动作 | Button |
| 收集输入 | TextBox |
| 表达选择 | CheckBox / RadioButton |
| 单选枚举值 | ComboBox |
| 展示集合 | ListView / ItemsControl |
| 表达状态/数值 | ToggleSwitch / Slider |
| 临时确认交互 | ContentDialog |
| 页面切换入口 | NavigationView（见 [05 篇](./05-project-structure.md) 5.3） |

## 6.1 Button：用户动作入口

```xml
<StackPanel Spacing="12">
    <TextBlock x:Name="StatusText" Text="Ready" />
    <Button x:Name="SaveButton" Content="Save" Click="OnSaveClicked" />
</StackPanel>
```

```cpp
void MainWindow::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
{
    StatusText().Text(L"Saved");
}
```

进阶写法（工程推荐）：按钮不放业务逻辑，`Click` 处理器只做转交，逻辑在 ViewModel：

```cpp
void MainWindow::OnSaveClicked(IInspectable const&, RoutedEventArgs const&)
{
    m_viewModel.Save();   // 状态变化通过绑定反映到界面
}
```

常用属性/事件速查：

- `Content`：按钮内容（可以是任意 UI 元素，不只字符串）
- `IsEnabled`：禁用/启用——异步操作进行中置 `false` 防止重复提交
- `Click`：主事件；`Command` 属性绑定 `ICommand`（C++/WinRT 里更常用 `x:Bind` 函数绑定，见 [08 篇](./08-binding-mvvm.md) 8.6）

## 6.2 TextBox：输入与校验

```xml
<StackPanel Spacing="12">
    <TextBox x:Name="NameBox" Header="Name" PlaceholderText="Enter user name"
             TextChanged="OnNameChanged" />
    <Button x:Name="SubmitButton" Content="Submit" IsEnabled="False" />
</StackPanel>
```

```cpp
void MainWindow::OnNameChanged(IInspectable const&, TextChangedEventArgs const&)
{
    // Text() 返回 winrt::hstring
    auto value = NameBox().Text();
    SubmitButton().IsEnabled(value.size() > 2);
}
```

要点：

- `Text()` / `Text(value)` 读写字符串，类型是 `winrt::hstring`
- `TextChanged` 每敲一个字符触发一次；轻量校验可以直接做，重量逻辑应去抖或在提交时统一校验
- `Header` 是输入框上方的标签，`PlaceholderText` 是空态提示——别再另摆一个 `TextBlock` 当标签

## 6.3 CheckBox 与 RadioButton：状态表达

```xml
<CheckBox x:Name="NotifyBox" Content="Enable notifications" IsChecked="True" />
```

```cpp
void MainWindow::OnNotifyToggled(IInspectable const&, RoutedEventArgs const&)
{
    // IsChecked() 返回 IReference<bool>（可为 null 的三态），必须先解包
    if (NotifyBox().IsChecked().Value())
    {
        // 开启通知
    }
}
```

**注意 `IsChecked()` 的返回类型是 `IReference<bool>`**：CheckBox 是三态控件（选/未选/不确定）。直接当 `bool` 用编译不过，`.Value()` 取值（不确定态视为 false）或先判断 `has_value()`。

RadioButton 靠 `GroupName` 分组：

```xml
<StackPanel>
    <RadioButton Content="Light" GroupName="Theme" IsChecked="True" />
    <RadioButton Content="Dark" GroupName="Theme" />
    <RadioButton Content="System" GroupName="Theme" />
</StackPanel>
```

同一 `GroupName` 内自动互斥。读取选中项不要挨个问每个 RadioButton——给每个挂 `Checked` 事件，把结果写进 ViewModel 的枚举字段。

## 6.4 ComboBox：下拉选择

```xml
<ComboBox x:Name="ThemeBox" Header="Theme" SelectionChanged="OnThemeChanged">
    <x:String>Light</x:String>
    <x:String>Dark</x:String>
    <x:String>System</x:String>
</ComboBox>
```

```cpp
void MainWindow::OnThemeChanged(IInspectable const&, SelectionChangedEventArgs const&)
{
    // SelectedItem() 返回 IInspectable，XAML 里的字符串被装箱为 hstring
    auto item = ThemeBox().SelectedItem();
    auto theme = winrt::unbox_value<winrt::hstring>(item);
    // 按值切换主题……
}
```

要点：`SelectedItem()` / `SelectedValue()` 返回的是 `IInspectable`（装箱对象），必须 `unbox_value<T>` 解包。这是 XAML 字符串列表 → C++ 类型之间必经的一步。

数据驱动的写法（工程推荐）——选项来自 ViewModel，选中项双向绑定：

```xml
<ComboBox ItemsSource="{x:Bind ViewModel.Themes, Mode=OneWay}"
          SelectedItem="{x:Bind ViewModel.SelectedTheme, Mode=TwoWay}" />
```

## 6.5 ListView：集合展示

ListView 是最能体现"数据驱动 UI"的控件：

```xml
<ListView x:Name="TaskList" ItemsSource="{x:Bind ViewModel.Tasks, Mode=OneWay}">
    <ListView.ItemTemplate>
        <DataTemplate x:DataType="vm:TaskItem">
            <CheckBox Content="{x:Bind Title, Mode=OneWay}"
                      IsChecked="{x:Bind Done, Mode=TwoWay}" />
        </DataTemplate>
    </ListView.ItemTemplate>
</ListView>
```

```xml
<!-- xmlns 声明 -->
xmlns:vm="using:MyApp"
```

四个组成部分：

1. `ItemsSource`：数据源（`IObservableVector<T>`，见 [08 篇](./08-binding-mvvm.md) 8.4）
2. `ItemTemplate` + `x:DataType`：每项的渲染模板，`x:DataType` 让模板内 `x:Bind` 获得编译期检查
3. 模板内 `x:Bind` 路径相对于**项类型**（`TaskItem`），不是页面
4. `SelectionChanged` 事件 + `SelectedItem()` 获取用户选中的项

和 ComboBox 的分工：ComboBox 选择一个值；ListView 展示并浏览集合。

## 6.6 ToggleSwitch 与 Slider：状态和数值

```xml
<ToggleSwitch x:Name="AutoSaveSwitch" Header="Auto save" IsOn="True" />
<Slider x:Name="VolumeSlider" Header="Volume" Minimum="0" Maximum="100" Value="50" />
```

```cpp
bool autoSave = AutoSaveSwitch().IsOn();    // ToggleSwitch 就是普通 bool，无三态问题
double volume = VolumeSlider().Value();
```

这两个控件的正确用法是**双向绑定到 ViewModel 的设置项**，而不是事件里手动搬运值：

```xml
<ToggleSwitch IsOn="{x:Bind ViewModel.AutoSave, Mode=TwoWay}" />
<Slider Value="{x:Bind ViewModel.Volume, Mode=TwoWay}" />
```

## 6.7 ContentDialog：临时确认交互

确认删除、一次性提示等场景：

```cpp
winrt::Windows::Foundation::IAsyncAction MainWindow::ConfirmDeleteAsync()
{
    ContentDialog dialog;
    dialog.Title(winrt::box_value(L"Delete item"));
    dialog.Content(winrt::box_value(L"Do you want to delete this task?"));
    dialog.PrimaryButtonText(L"Delete");
    dialog.CloseButtonText(L"Cancel");
    dialog.DefaultButton(ContentDialogButton::Primary);

    // WinUI 3 必须设置 XamlRoot，否则 ShowAsync 运行时抛异常！
    // Window 本身没有 XamlRoot 成员，只能从内容树的根元素取。
    dialog.XamlRoot(rootPanel().XamlRoot());

    auto result = co_await dialog.ShowAsync();
    if (result == ContentDialogResult::Primary)
    {
        m_viewModel.DeleteSelected();
    }
}
```

根元素要有名字才取得到（`MainWindow.xaml`）：

```xml
<Window x:Class="MyApp.MainWindow" ...>
    <Grid x:Name="rootPanel">
        <!-- 页面内容 -->
    </Grid>
</Window>
```

**WinUI 3 特有的坑**：UWP 时代直接 `ShowAsync()` 就行；WinUI 3 里弹层挂在弹层根（不隶属声明位置的树，见 [03 篇](./03-xaml.md) 3.8），必须显式指定 `XamlRoot`，否则运行时抛 "XamlRoot has not been set"。取法分两种：

- **在 Page 里**：`dialog.XamlRoot(this->XamlRoot())`——`Page` 是 `FrameworkElement`，本身就有 `XamlRoot`
- **在 Window 里**：只能取内容树根元素的 `XamlRoot`（`Window` 上没有这个成员，写成 `this->XamlRoot()` 直接编译不过）

其他要点：

- `ShowAsync` 是异步的，同一时刻**只能显示一个** ContentDialog
- 返回值 `ContentDialogResult` 告诉你用户按了哪个按钮
- 复杂输入场景不要往 ContentDialog 里硬塞——考虑独立 Page 或 `TeachingTip`

## 6.8 控件协作的总原则

回看这些控件，它们在工程里遵守同一条纪律：

```text
控件 = 状态的展示 + 动作的入口
        ↑                    ↓
   绑定自动刷新         事件/绑定转交 ViewModel
```

- 展示侧：控件属性绑定 ViewModel 状态，**不手动搬运**
- 输入侧：事件处理器只做转交（或直接 `x:Bind` 到 ViewModel 方法），**不写业务逻辑**
- 跨页共享的状态一律进 ViewModel/Service，不借控件互访

做到这三条，控件篇就算学完了；做不到，背再多控件名也会把页面写成事件泥团。

---

上一篇：[05-project-structure.md](./05-project-structure.md) ｜ 下一篇：[07-layout.md](./07-layout.md)
