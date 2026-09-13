# WPF Windows 编程指南 - .NET 10 版本

## 目录

1. [概述](#概述)
2. [环境准备](#环境准备)
3. [WPF 基础](#wpf-基础)
4. [XAML 语言](#xaml-语言)
5. [核心控件](#核心控件)
6. [布局系统](#布局系统)
7. [数据绑定](#数据绑定)
8. [MVVM 模式](#mvvm-模式)
9. [命令系统](#命令系统)
10. [资源与样式](#资源与样式)
11. [进度报告与异步操作](#进度报告与异步操作)
12. [文件对话框](#文件对话框)
13. [窗口与导航](#窗口与导航)
14. [最佳实践](#最佳实践)
15. [常见问题](#常见问题)

---

## 概述

Windows Presentation Foundation (WPF) 是微软提供的现代化 UI 框架，用于构建 Windows 桌面应用程序。WPF 基于 DirectX 技术，提供硬件加速的图形渲染能力。

### .NET 10 中的新特性

.NET 10 为 WPF 带来了以下改进：

- **性能优化**：UI 渲染性能提升，内存占用优化
- **Nullable 支持**：完整的空值可选性注解
- **AOT 编译支持**：支持 Native AOT 以实现更快的启动时间
- **现代控件更新**：WinUI 3 控件集成的进一步改进

---

## 环境准备

### 系统要求

- Windows 10 版本 1809 或更高版本
- Windows 11

### 安装开发工具

1. **安装 .NET 10 SDK**

   访问 [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download) 下载并安装 .NET 10 SDK。

2. **安装 Visual Studio 2022**

   推荐使用 Visual Studio 2022 version 17.8 或更高版本。

   或使用 VS Code + C# Dev Kit 扩展。

### 创建第一个 WPF 项目

**使用 .NET CLI：**

```bash
# 创建 WPF 项目
dotnet new wpf -n MyFirstWpfApp

# 进入项目目录
cd MyFirstWpfApp

# 运行项目
dotnet run
```

**项目结构：**

```
MyFirstWpfApp/
├── App.xaml          # 应用程序入口点
├── App.xaml.cs       # 应用程序代码
├── MainWindow.xaml   # 主窗口
├── MainWindow.xaml.cs # 主窗口代码
└── MyFirstWpfApp.csproj
```

**项目文件示例 (MyFirstWpfApp.csproj)：**

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

</Project>
```

---

## WPF 基础

### 应用程序结构

**App.xaml：**

```xml
<Application x:Class="MyApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>

    </Application.Resources>
</Application>
```

**App.xaml.cs：**

```csharp
namespace MyApp;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        // 应用程序启动逻辑
    }
}
```

### MainWindow 结构

**MainWindow.xaml：**

```xml
<Window x:Class="MyApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MainWindow" Height="450" Width="800">
    <Grid>

    </Grid>
</Window>
```

**MainWindow.xaml.cs：**

```csharp
namespace MyApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }
}
```

---

## XAML 语言

### XAML 基础

XAML (Extensible Application Markup Language) 是声明式 XML 语言，用于定义 UI。

**属性设置：**

```xml
<!-- 对象元素语法 -->
<Button Content="Click Me" Width="100" Height="50" />

<!-- 属性元素语法 -->
<Button>
    <Button.Content>Click Me</Button.Content>
    <Button.Width>100</Button.Width>
    <Button.Height>50</Button.Height>
</Button>
```

**事件处理：**

```xml
<Button.Content>Click Me</Button.Content>
<Button.Width>100</Button.Width>
<Button.Height>50</Button.Height>
</Button>
```

**C# 代码：**

```csharp
private void Button_Click(object sender, RoutedEventArgs e)
{
    MessageBox.Show("Button clicked!");
}
```

### 命名空间映射

```xml
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:local="clr-namespace:MyApp.ViewModels">

</Window>
```

---

## 核心控件

### 基础控件

**按钮 (Button)：**

```xml
<Button Content="Click Me"
        Click="Button_Click"
        Width="120" Height="40" />

<!-- Command 绑定 -->
<Button Content="Click Me" Command="{Binding MyCommand}" />
```

**文本显示：**

```xml
<!-- Label - 用于带访问键的文本 -->
<Label Content="_Name:" Target="{Binding ElementName=nameBox}" />

<!-- TextBlock - 用于文本显示 -->
<TextBlock Text="Hello WPF"
           FontSize="16"
           Foreground="Blue" />

<!-- TextBox - 单行文本输入 -->
<TextBox Text="{Binding UserName, UpdateSourceTrigger=PropertyChanged}"
         Width="200" />

<!-- PasswordBox - 密码输入 -->
<PasswordBox Width="200" PasswordChanged="PasswordBox_PasswordChanged" />

<!-- RichTextBox - 富文本编辑 -->
<RichTextBox Width="300" Height="150" />
```

**复选框与单选框：**

```xml
<!-- CheckBox -->
<CheckBox Content="Enable Feature"
          IsChecked="{Binding IsEnabled}" />

<!-- RadioButton -->
<StackPanel Orientation="Horizontal">
    <RadioButton Content="Option 1" GroupName="Group1" IsChecked="True" />
    <RadioButton Content="Option 2" GroupName="Group1" />
</StackPanel>
```

### 列表控件

**ComboBox：**

```xml
<ComboBox Width="200"
          ItemsSource="{Binding Items}"
          SelectedItem="{Binding SelectedItem}"
          DisplayMemberPath="Name" />
```

**ListBox：**

```xml
<ListBox Width="200" Height="200"
         ItemsSource="{Binding Items}"
         SelectedItem="{Binding SelectedItem}">
    <ListBox.ItemTemplate>
        <DataTemplate>
            <TextBlock Text="{Binding Name}" />
        </DataTemplate>
    </ListBox.ItemTemplate>
</ListBox>
```

**ListView：**

```xml
<ListView ItemsSource="{Binding People}">
    <ListView.View>
        <GridView>
            <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" />
            <GridViewColumn Header="Age" DisplayMemberBinding="{Binding Age}" />
        </GridView>
    </ListView.View>
</ListView>
```

**DataGrid：**

```xml
<DataGrid ItemsSource="{Binding Products}"
          AutoGenerateColumns="False"
          CanUserAddRows="True"
          IsReadOnly="False"
          SelectionMode="Single"
          SelectionUnit="FullRow">
    <DataGrid.Columns>
        <DataGridTextColumn Header="ID" Binding="{Binding Id}" IsReadOnly="True" />
        <DataGridTextColumn Header="Name" Binding="{Binding Name}" />
        <DataGridTextColumn Header="Price" Binding="{Binding Price, StringFormat=C2}" />
        <DataGridCheckBoxColumn Header="In Stock" Binding="{Binding InStock}" />
    </DataGrid.Columns>
</DataGrid>
```

### 导航控件

**TabControl：**

```xml
<TabControl>
    <TabItem Header="Overview">
        <TextBlock Text="Overview content" />
    </TabItem>
    <TabItem Header="Settings">
        <TextBlock Text="Settings content" />
    </TabItem>
</TabControl>
```

**Frame 和 NavigationWindow：**

```xml
<Frame Source="Page1.xaml" NavigationUIVisibility="Visible" />
```

### 容器控件

**Border：**

```xml
<Border BorderBrush="Black"
        BorderThickness="2"
        CornerRadius="5"
        Padding="10">
    <TextBlock Text="Content inside border" />
</Border>
```

**GroupBox：**

```xml
<GroupBox Header="User Information" Padding="10">
    <StackPanel>
        <TextBox Text="" Width="200" Margin="0,0,0,5" />
        <TextBox Text="" Width="200" />
    </StackPanel>
</GroupBox>
```

**ScrollViewer：**

```xml
<ScrollViewer Height="300" VerticalScrollBarVisibility="Auto">
    <StackPanel>
        <!-- Long content here -->
    </StackPanel>
</ScrollViewer>
```

### 区域选择控件

**ProgressBar：**

```xml
<!-- Indeterminate progress -->
<ProgressBar IsIndeterminate="True" Height="20" />

<!-- Determinate progress -->
<ProgressBar Value="{Binding ProgressValue}"
             Maximum="100"
             Height="20" />

<!-- 带样式的 ProgressBar -->
<ProgressBar Value="{Binding Progress}"
             Maximum="100"
             Height="20"
             Foreground="Green"
             Background="LightGray" />
```

**Separator：**

```xml
<StackPanel>
    <TextBlock Text="First Section" />
    <Separator Margin="0,5" />
    <TextBlock Text="Second Section" />
</StackPanel>
```

---

## 布局系统

### 主要布局容器

**Grid（网格布局）：**

```xml
<Grid>
    <!-- 定义列 -->
    <Grid.ColumnDefinitions>
        <ColumnDefinition Width="100" />
        <ColumnDefinition Width="*" />
        <ColumnDefinition Width="Auto" />
    </Grid.ColumnDefinitions>

    <!-- 定义行 -->
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto" />
        <RowDefinition Height="*" />
        <RowDefinition Height="50" />
    </Grid.RowDefinitions>

    <!-- 跨行跨列 -->
    <TextBlock Text="Title" Grid.Column="0" Grid.ColumnSpan="3" />
    <Button Content="OK" Grid.Row="2" Grid.Column="1" />
</Grid>
```

**StackPanel（堆叠布局）：**

```xml
<StackPanel Orientation="Vertical">
    <TextBlock Text="First" />
    <TextBlock Text="Second" />
    <TextBlock Text="Third" />
</StackPanel>

<StackPanel Orientation="Horizontal">
    <Button Content="Button 1" />
    <Button Content="Button 2" />
    <Button Content="Button 3" />
</StackPanel>
```

**DockPanel（停靠布局）：**

```xml
<DockPanel LastChildFill="True">
    <Menu DockPanel.Dock="Top">
        <MenuItem Header="_File" />
    </Menu>
    <StatusBar DockPanel.Dock="Bottom">
        <TextBlock Text="Ready" />
    </StatusBar>
    <Border DockPanel.Dock="Left" Width="200">
        <TextBlock Text="Sidebar" />
    </Border>
    <TextBox Text="Main content" />
</DockPanel>
```

**Canvas（画布布局）：**

```xml
<Canvas>
    <Rectangle Fill="Red" Width="50" Height="50"
               Canvas.Left="100" Canvas.Top="50" />
    <Ellipse Fill="Blue" Width="80" Height="80"
             Canvas.Left="150" Canvas.Top="100" />
</Canvas>
```

**WrapPanel（换行布局）：**

```xml
<WrapPanel Orientation="Horizontal">
    <Button Content="Item 1" Width="100" />
    <Button Content="Item 2" Width="100" />
    <Button Content="Item 3" Width="100" />
    <!-- Item 4 会自动换行 -->
    <Button Content="Item 4" Width="100" />
</WrapPanel>
```

### 对齐与边距

```xml
<!-- Margins: Left, Top, Right, Bottom -->
<Button Content="Button" Margin="10,5,10,5" />

<!-- Horizontal/Vertical Alignment -->
<TextBlock Text="Centered"
           HorizontalAlignment="Center"
           VerticalAlignment="Center" />

<!-- Padding: Left, Top, Right, Bottom -->
<Border BorderBrush="Black" BorderThickness="1" Padding="15,10,15,10">
    <TextBlock Text="Padded content" />
</Border>
```

---

## 数据绑定

### 绑定基础

```xml
<TextBox Text="{Binding UserName}" />
<TextBlock Text="{Binding UserName}" />
```

**绑定模式：**

- `OneTime`：一次绑定
- `OneWay`：单向绑定（源→目标）
- `TwoWay`：双向绑定（源↔目标）
- `OneWayToSource`：反向单向绑定（目标→源）

```xml
<TextBox Text="{Binding Name, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" />
```

**UpdateSourceTrigger 选项：**

- `Default`：默认值（TextBox 使用 LostFocus）
- `PropertyChanged`：属性变更时更新
- `LostFocus`：失去焦点时更新
- `Explicit`：手动更新

### 绑定源

**对象绑定：**

```xml
<StackPanel DataContext="{Binding User}">
    <TextBox Text="{Binding Name}" />
    <TextBox Text="{Binding Email}" />
</StackPanel>
```

**元素绑定：**

```xml
<Slider x:Name="fontSizeSlider" Minimum="10" Maximum="30" Value="14" />
<TextBlock Text="Hello"
           FontSize="{Binding Value, ElementName=fontSizeSlider}" />
```

**数据模板绑定：**

```xml
<ListBox ItemsSource="{Binding Items}">
    <ListBox.ItemTemplate>
        <DataTemplate>
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="{Binding Name}" FontWeight="Bold" />
                <TextBlock Text=" - " />
                <TextBlock Text="{Binding Description}" Foreground="Gray" />
            </StackPanel>
        </DataTemplate>
    </ListBox.ItemTemplate>
</ListBox>
```

### 绑定转换器

**创建转换器：**

```csharp
using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace MyApp.Converters;

public class BooleanToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool boolean)
        {
            bool invert = parameter != null;
            bool result = invert ? !boolean : boolean;
            return result ? Visibility.Visible : Visibility.Collapsed;
        }
        return Visibility.Collapsed;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is Visibility visibility)
        {
            bool invert = parameter != null;
            bool result = visibility == Visibility.Visible;
            return invert ? !result : result;
        }
        return false;
    }
}
```

**注册并使用转换器：**

```xml
<Window.Resources>
    <local:BooleanToVisibilityConverter x:Key="BoolToVis" />
</Window.Resources>

<TextBlock Text="Secret Content"
           Visibility="{Binding IsAdmin, Converter={StaticResource BoolToVis}}" />
```

### 多绑定

**MultiBinding：**

```xml
<TextBlock>
    <TextBlock.Text>
        <MultiBinding StringFormat="{}{0}, {1}">
            <Binding Path="LastName" />
            <Binding Path="FirstName" />
        </MultiBinding>
    </TextBlock.Text>
</TextBlock>
```

**优先级绑定：**

```xml
<TextBlock>
    <TextBlock.Text>
        <PriorityBinding>
            <Binding Path="DisplayName" />
            <Binding Path="UserName" />
            <Binding Path="Id" StringFormat="User {0}" />
        </PriorityBinding>
    </TextBlock.Text>
</TextBlock>
```

---

## MVVM 模式

### MVVM 架构

MVVM (Model-View-ViewModel) 是 WPF 推荐的设计模式：

- **Model**：数据模型和业务逻辑
- **View**：UI 界面（XAML）
- **ViewModel**：视图模型，连接 UI 和 Model

### 实现基类

**ViewModelBase：**

```csharp
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace MyApp.ViewModels;

public class ViewModelBase : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null!)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    protected bool SetField<T>(ref T field, T value, [CallerMemberName] string propertyName = null!)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }
}
```

### ViewModel 示例

```csharp
using System.Collections.ObjectModel;
using System.Windows.Input;

namespace MyApp.ViewModels;

public class MainWindowViewModel : ViewModelBase
{
    private string _name = string.Empty;
    private bool _isSaved = false;
    private ObservableCollection<string> _items = new();

    public string Name
    {
        get => _name;
        set => SetField(ref _name, value);
    }

    public bool IsSaved
    {
        get => _isSaved;
        set => SetField(ref _isSaved, value);
    }

    public ObservableCollection<string> Items => _items;

    public ICommand SaveCommand { get; }
    public ICommand AddItemCommand { get; }

    public MainWindowViewModel()
    {
        SaveCommand = new RelayCommand(OnSave, CanSave);
        AddItemCommand = new RelayCommand(OnAddItem);

        // 初始化数据
        Items.Add("Item 1");
        Items.Add("Item 2");
    }

    private bool CanSave() => !string.IsNullOrEmpty(Name);

    private void OnSave()
    {
        IsSaved = true;
        // 保存逻辑
    }

    private void OnAddItem()
    {
        Items.Add($"Item {Items.Count + 1}");
        Name = string.Empty;
        IsSaved = false;
    }
}
```

### RelayCommand 实现

```csharp
using System;
using System.Windows.Input;

namespace MyApp.Commands;

public class RelayCommand : ICommand
{
    private readonly Action _execute;
    private readonly Func<bool>? _canExecute;

    public event EventHandler? CanExecuteChanged;

    public RelayCommand(Action execute, Func<bool>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object parameter)
    {
        return _canExecute == null || _canExecute();
    }

    public void Execute(object parameter)
    {
        _execute();
    }

    public void RaiseCanExecuteChanged()
    {
        CanExecuteChanged?.Invoke(this, EventArgs.Empty);
    }
}
```

### View 与 ViewModel 绑定

**App.xaml：**

```xml
<Application x:Class="MyApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:viewModel="clr-namespace:MyApp.ViewModels"
             StartupUri="MainWindow.xaml">
    <Application.Resources>

    </Application.Resources>
</Application>
```

**MainWindow.xaml.cs：**

```csharp
using MyApp.ViewModels;

namespace MyApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainWindowViewModel();
    }
}
```

---

## 命令系统

### ICommand 接口

```csharp
public interface ICommand
{
    event EventHandler CanExecuteChanged;
    bool CanExecute(object parameter);
    void Execute(object parameter);
}
```

### RelayCommand<T> 通用实现

```csharp
using System;
using System.Windows.Input;

namespace MyApp.Commands;

public class RelayCommand<T> : ICommand
{
    private readonly Action<T> _execute;
    private readonly Func<T, bool>? _canExecute;

    public event EventHandler? CanExecuteChanged;

    public RelayCommand(Action<T> execute, Func<T, bool>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object parameter)
    {
        return _canExecute == null || _canExecute((T)parameter);
    }

    public void Execute(object parameter)
    {
        _execute((T)parameter);
    }

    public void RaiseCanExecuteChanged()
    {
        CanExecuteChanged?.Invoke(this, EventArgs.Empty);
    }
}
```

### 使用示例

```xml
<StackPanel>
    <TextBox Text="{Binding InputText, UpdateSourceTrigger=PropertyChanged}"
             Width="200" Margin="0,0,10,0" />
    <Button Content="Execute"
            Command="{Binding MyCommand}"
            CommandParameter="{Binding InputText}" />
    <Button Content="Execute (No Param)"
            Command="{Binding MyCommandWithoutParam}" />
</StackPanel>
```

```csharp
public class MainViewModel : ViewModelBase
{
    private string _inputText = string.Empty;

    public string InputText
    {
        get => _inputText;
        set => SetField(ref _inputText, value);
    }

    public ICommand MyCommand { get; }
    public ICommand MyCommandWithoutParam { get; }

    public MainViewModel()
    {
        MyCommand = new RelayCommand<string>(OnMyCommandExecute, OnMyCommandCanExecute);
        MyCommandWithoutParam = new RelayCommand(OnMyCommandWithoutParamExecute);
    }

    private bool OnMyCommandCanExecute(string? parameter)
    {
        return !string.IsNullOrWhiteSpace(parameter);
    }

    private void OnMyCommandExecute(string parameter)
    {
        // 处理命令
    }

    private void OnMyCommandWithoutParamExecute()
    {
        // 处理无参数命令
    }
}
```

### CommandManager

```csharp
public class MainViewModel : ViewModelBase
{
    public ICommand UpdateCommand { get; }

    public MainViewModel()
    {
        UpdateCommand = new RelayCommand(OnUpdate, CanUpdate);
    }

    private void OnUpdate()
    {
        // 更新逻辑
        // 通知命令状态变化
        (UpdateCommand as RelayCommand)?.RaiseCanExecuteChanged();
    }
}
```

---

## 资源与样式

### 资源字典

**定义资源：**

```xml
<!-- Colors.xaml -->
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

    <Color x:Key="PrimaryColor">#FF5C3D</Color>
    <SolidColorBrush x:Key="PrimaryBrush" Color="{StaticResource PrimaryColor}" />

    <Color x:Key="SecondaryColor">#3772FF</Color>
    <SolidColorBrush x:Key="SecondaryBrush" Color="{StaticResource SecondaryColor}" />
</ResourceDictionary>
```

**使用资源：**

```xml
<Window.Resources>
    <ResourceDictionary>
        <ResourceDictionary.MergedDictionaries>
            <ResourceDictionary Source="/Resources/Colors.xaml" />
        </ResourceDictionary.MergedDictionaries>

        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource PrimaryBrush}" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="Padding" Value="15,8" />
            <Setter Property="BorderRadius" Value="4" />
        </Style>
    </ResourceDictionary>
</Window.Resources>

<Grid Background="{StaticResource SecondaryBrush}">
    <Button Content="Click Me" Style="{StaticResource PrimaryButtonStyle}" />
</Grid>
```

### 样式

**定义样式：**

```xml
<Window.Resources>
    <!-- 具有键的样式 -->
    <Style x:Key="PrimaryButtonStyle" TargetType="Button">
        <Setter Property="FontSize" Value="14" />
        <Setter Property="FontWeight" Value="Bold" />
        <Setter Property="Padding" Value="12,6" />
        <Setter Property="Background" Value="#FF5C3D" />
        <Setter Property="Foreground" Value="White" />
        <Setter Property="BorderThickness" Value="0" />
        <Setter Property="Cursor" Value="Hand" />
        <Style.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Opacity" Value="0.8" />
            </Trigger>
            <Trigger Property="IsPressed" Value="True">
                <Setter Property="RenderTransform">
                    <Setter.Value>
                        <ScaleTransform ScaleX="0.98" ScaleY="0.98" />
                    </Setter.Value>
                </Setter>
            </Trigger>
        </Style.Triggers>
    </Style>

    <!-- 隐式样式（无 x:Key） -->
    <Style TargetType="TextBlock">
        <Setter Property="FontSize" Value="13" />
        <Setter Property="Margin" Value="5" />
    </Style>
</Window.Resources>
```

**设置控制模板：**

```xml
<Style x:Key="ModernButtonStyle" TargetType="Button">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="Button">
                <Border x:Name="border"
                        Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="{TemplateBinding BorderThickness}"
                        CornerRadius="4">
                    <ContentPresenter HorizontalAlignment="Center"
                                      VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="border" Property="Background" Value="LightBlue" />
                    </Trigger>
                    <Trigger Property="IsPressed" Value="True">
                        <Setter TargetName="border" Property="Background" Value="DarkBlue" />
                    </Trigger>
                    <Trigger Property="IsEnabled" Value="False">
                        <Setter TargetName="border" Property="Opacity" Value="0.5" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

### 动画

```xml
<Window.Resources>
    <Style x:Key="AnimatedButton" TargetType="Button">
        <Setter Property="FontSize" Value="16" />
        <Setter Property="Padding" Value="20,10" />
        <Style.Triggers>
            <EventTrigger RoutedEvent="MouseEnter">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetProperty="FontSize"
                                         To="18" Duration="0:0:0.2" />
                        <ColorAnimation Storyboard.TargetProperty="(Button.Background).(SolidColorBrush.Color)"
                                        To="LightBlue" Duration="0:0:0.2" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
            <EventTrigger RoutedEvent="MouseLeave">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetProperty="FontSize"
                                         Duration="0:0:0.2" />
                        <ColorAnimation Storyboard.TargetProperty="(Button.Background).(SolidColorBrush.Color)"
                                        Duration="0:0:0.2" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Style.Triggers>
    </Style>
</Window.Resources>

<Button Content="Hover Me" Style="{StaticResource AnimatedButton}" />
```

---

## 进度报告与异步操作

### IProgress<T> 接口

```csharp
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;

namespace MyApp.ViewModels;

public class ProgressViewModel : ViewModelBase
{
    private int _progress;
    private string _status = "Ready";
    private bool _isRunning;

    public int Progress
    {
        get => _progress;
        set => SetField(ref _progress, value);
    }

    public string Status
    {
        get => _status;
        set => SetField(ref _status, value);
    }

    public bool IsRunning
    {
        get => _isRunning;
        set => SetField(ref _isRunning, value);
    }

    public ICommand StartCommand { get; }
    public CancellationTokenSource CancellationTokenSource { get; } = new();

    public ProgressViewModel()
    {
        StartCommand = new RelayCommand(OnStart, () => !IsRunning);
    }

    private async void OnStart()
    {
        IsRunning = true;
        Status = "Starting...";

        var progress = new Progress<int>(value =>
        {
            Progress = value;
        });

        try
        {
            await LongRunningTaskAsync(progress, CancellationTokenSource.Token);
            Status = "Completed!";
        }
        catch (OperationCanceledException)
        {
            Status = "Cancelled";
        }
        finally
        {
            IsRunning = false;
        }
    }

    private async Task LongRunningTaskAsync(IProgress<int> progress, CancellationToken cancellationToken)
    {
        for (int i = 0; i <= 100; i++)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                throw new OperationCanceledException(cancellationToken);
            }

            Status = $"Processing... {i}%";
            progress.Report(i);
            await Task.Delay(50, cancellationToken);
        }
    }

    public void Cancel()
    {
        CancellationTokenSource.Cancel();
    }
}
```

**ProgressView.xaml：**

```xml
<Window x:Class="MyApp.Views.ProgressView"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Progress Demo" Height="250" Width="400">
    <Grid Margin="20">
        <StackPanel>
            <TextBlock Text="{Binding Status}" Margin="0,0,0,15" />

            <ProgressBar Value="{Binding Progress}"
                         Maximum="100"
                         Height="20"
                         Margin="0,0,0,15" />

            <Button Content="Start Task"
                    Command="{Binding StartCommand}"
                    Width="120" Height="30" />

            <Button Content="Cancel"
                    Command="{Binding CancelCommand}"
                    IsEnabled="{Binding IsRunning}"
                    Width="120" Height="30" Margin="0,10,0,0" />
        </StackPanel>
    </Grid>
</Window>
```

### IAsyncCommand 实现

```csharp
using System;
using System.Threading.Tasks;
using System.Windows.Input;

namespace MyApp.Commands;

public class AsyncCommand : IAsyncCommand
{
    private readonly Func<Task> _execute;
    private readonly Func<bool>? _canExecute;
    private bool _isExecuting;

    public event EventHandler? CanExecuteChanged;

    public AsyncCommand(Func<Task> execute, Func<bool>? canExecute = null)
    {
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
        _canExecute = canExecute;
    }

    public bool CanExecute(object? parameter)
    {
        return !_isExecuting && (_canExecute?.Invoke() ?? true);
    }

    public void Execute(object? parameter)
    {
        _ = ExecuteAsync(parameter);
    }

    public async Task ExecuteAsync(object? parameter = null)
    {
        _isExecuting = true;
        RaiseCanExecuteChanged();

        try
        {
            await _execute();
        }
        finally
        {
            _isExecuting = false;
            RaiseCanExecuteChanged();
        }
    }

    public void RaiseCanExecuteChanged()
    {
        CanExecuteChanged?.Invoke(this, EventArgs.Empty);
    }
}

public interface IAsyncCommand : ICommand
{
    Task ExecuteAsync(object? parameter = null);
}
```

---

## 文件对话框

### OpenFileDialog

```csharp
using Microsoft.Win32;
using System;
using System.Windows;

namespace MyApp.Views;

public partial class FileDialogView : Window
{
    public FileDialogView()
    {
        InitializeComponent();
    }

    private void OpenFileButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Title = "Open File",
            Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*",
            InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
            Multiselect = false
        };

        bool? result = dialog.ShowDialog();

        if (result == true)
        {
            string filename = dialog.FileName;
            // 处理文件
            MessageBox.Show($"Selected file: {filename}");
        }
    }
}
```

### SaveFileDialog

```csharp
private void SaveFileButton_Click(object sender, RoutedEventArgs e)
{
    var dialog = new SaveFileDialog
    {
        Title = "Save File",
        Filter = "Text Files (*.txt)|*.txt|JSON Files (*.json)|*.json",
        FileName = "document.txt",
        InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Desktop)
    };

    bool? result = dialog.ShowDialog();

    if (result == true)
    {
        string filename = dialog.FileName;
        // 保存文件
        System.IO.File.WriteAllText(filename, "Content to save");
        MessageBox.Show($"File saved: {filename}");
    }
}
```

### FolderBrowserDialog

```csharp
using System.Windows.Forms;

private void SelectFolderButton_Click(object sender, RoutedEventArgs e)
{
    using var dialog = new FolderBrowserDialog
    {
        Description = "Select a folder",
        ShowNewFolderButton = true
    };

    if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
    {
        string folderPath = dialog.SelectedPath;
        MessageBox.Show($"Selected folder: {folderPath}");
    }
}
```

---

## 窗口与导航

### 窗口属性

```xml
<Window x:Class="MyApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MainWindow"
        Height="600"
        Width="900"
        WindowStartupLocation="CenterScreen"
        WindowStyle="ThreeDBorderWindow"
        ResizeMode="CanResize"
        ShowInTaskbar="True"
        Topmost="False"
        Icon="app.ico">

</Window>
```

### 自定义窗口

**隐藏默认标题栏：**

```xml
<Window x:Class="MyApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title=""
        Height="600"
        Width="900"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent">

    <Border Background="White"
            CornerRadius="8"
            BorderBrush="#CCC"
            BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect ShadowDepth="2" BlurRadius="5" Opacity="0.3" />
        </Border.Effect>
        <Grid>
            <!-- 自定义标题栏 -->
            <Border x:Name="CustomTitleBar"
                    Height="40"
                    Background="#333"
                    MouseLeftButtonDown="CustomTitleBar_MouseLeftButtonDown">
                <TextBlock Text="My App"
                           Foreground="White"
                           VerticalAlignment="Center"
                           Margin="10,0,0,0" />
            </Border>

            <!-- 关闭按钮 -->
            <Button Content="×"
                    Width="40"
                    Height="40"
                    Background="Transparent"
                    Foreground="White"
                    VerticalAlignment="Top"
                    HorizontalAlignment="Right"
                    Click="CloseButton_Click" />

            <!-- 主内容 -->
            <Grid Margin="0,40,0,0">

            </Grid>
        </Grid>
    </Border>
</Window>
```

**后端代码：**

```csharp
using System.Windows;
using System.Windows.Input;

namespace MyApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void CustomTitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        DragMove();
    }

    private void CloseButton_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private void MinimizeButton_Click(object sender, RoutedEventArgs e)
    {
        WindowState = WindowState.Minimized;
    }

    private void MaximizeButton_Click(object sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized
            ? WindowState.Normal
            : WindowState.Maximized;
    }
}
```

### 窗口间导航

**使用 Frame 进行导航：**

```xml
<Window x:Class="MyApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Navigation Demo" Height="450" Width="800">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="50" />
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>

        <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="10">
            <Button Content="Home" Margin="0,0,10,0" Click="HomeButton_Click" />
            <Button Content="Settings" Margin="0,0,10,0" Click="SettingsButton_Click" />
            <Button Content="About" Click="AboutButton_Click" />
        </StackPanel>

        <Frame x:Name="ContentFrame" Grid.Row="1" NavigationUIVisibility="Hidden" />
    </Grid>
</Window>
```

**页面实现：**

```xml
<!-- HomeView.xaml -->
<Page x:Class="MyApp.Views.HomeView"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid>
        <TextBlock Text="Home View"
                   FontSize="24"
                   HorizontalAlignment="Center"
                   VerticalAlignment="Center" />
    </Grid>
</Page>
```

```csharp
using System.Windows.Navigation;

namespace MyApp.Views;

public partial class HomeView : Page
{
    public HomeView()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        // 页面激活逻辑
    }

    protected override void OnNavigatingFrom(NavigatingCancelEventArgs e)
    {
        base.OnNavigatingFrom(e);
        // 页面退出逻辑
    }
}
```

**导航逻辑：**

```csharp
using MyApp.Views;
using System.Windows.Navigation;

namespace MyApp;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        ContentFrame.Navigate(new HomeView());
    }

    private void HomeButton_Click(object sender, RoutedEventArgs e)
    {
        ContentFrame.Navigate(new HomeView());
    }

    private void SettingsButton_Click(object sender, RoutedEventArgs e)
    {
        ContentFrame.Navigate(new SettingsView());
    }

    private void AboutButton_Click(object sender, RoutedEventArgs e)
    {
        ContentFrame.Navigate(new AboutView());
    }
}
```

### showDialog 窗口

```csharp
using System.Windows;

namespace MyApp.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void OpenDialogButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new DialogWindow
        {
            Owner = this
        };

        bool? result = dialog.ShowDialog();

        if (result == true)
        {
            // 用户点击了 OK
            string data = dialog.ResultData;
        }
        // 用户点击了 Cancel 或关闭窗口
    }
}
```

```csharp
using System.Windows;

namespace MyApp.Views;

public partial class DialogWindow : Window
{
    public string ResultData { get; private set; } = string.Empty;

    public DialogWindow()
    {
        InitializeComponent();
    }

    private void OkButton_Click(object sender, RoutedEventArgs e)
    {
        ResultData = InputTextBox.Text;
        DialogResult = true;
        Close();
    }

    private void CancelButton_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
```

---

## 实战示例索引

为了让教程更贴近真实开发场景，本指南已补充一组可编译的 WPF 示例，统一放在 `examples/` 目录下。对应关系如下：

| 示例目录 | 主题 | 适用章节 | 说明 |
|---|---|---|---|
| `01_hello_wpf` | Hello World / 事件处理 | WPF 基础、XAML 语言 | 最小窗口与按钮交互 |
| `02_binding` | 数据绑定 | 数据绑定 | `TextBox`、`Slider` 与 `Binding` |
| `03_mvvm` | MVVM | MVVM 模式 | `INotifyPropertyChanged` + 命令 |
| `04_layout` | 布局容器 | 布局系统 | `Grid`、`StackPanel`、`DockPanel` |
| `05_styles` | 样式与资源 | 资源与样式 | `Style`、`Trigger` 和主题统一 |
| `06_commands` | 命令系统 | 命令系统 | `ICommand` 与 RelayCommand |
| `07_async_progress` | 异步任务 | 进度报告与异步操作 | `async/await` + `ProgressBar` |
| `08_file_dialogs` | 文件对话框 | 文件对话框 | `OpenFileDialog` / `SaveFileDialog` |
| `09_navigation` | 页面导航 | 窗口与导航 | `Frame` + `Page` 导航 |

这些示例均可直接在当前环境中使用：

```powershell
cd G:\code\guide\wpf
.\build.ps1
```

此外，每个示例都对应一个可独立编译的 `.csproj` 文件，适合拿来做“看教程 + 实现 demo”的学习闭环。

---

## 最佳实践

### 命名约定

| 元素类型 | 命名约定 | 示例 |
|---------|---------|------|
| 类 | PascalCase | MainWindow, CustomerViewModel |
| 私有字段 | _camelCase | _customerName |
| 公共属性 | PascalCase | CustomerName |
| 事件 | EventHandlerPostfix | CustomerSelected |
| Command 属性 | 命令名 + Command | SaveCommand, CancelCommand |

### 性能优化

1. **虚拟化列表：**

```xml
<ListBox ItemsSource="{Binding Items}"
         VirtualizingPanel.IsVirtualizing="True"
         VirtualizingPanel.VirtualizationMode="Recycling">
</ListBox>
```

2. **延迟加载：**

```xml
<DetailsView>
    <DetailsView.Header>
        <Image Source="{Binding ImageUrl}"
               DecodePixelWidth="200"
               CacheOption="OnLoad" />
    </DetailsView.Header>
</DetailsView>
```

3. **使用 SpriteBitmap：**

```csharp
using System.Windows.Media.Imaging;

public static BitmapImage LoadImage(string path)
{
    var bitmap = new BitmapImage();
    bitmap.BeginInit();
    bitmap.CacheOption = BitmapCacheOption.OnLoad;
    bitmap.UriSource = new Uri(path);
    bitmap.EndInit();
    bitmap.Freeze(); // 提升性能
    return bitmap;
}
```

### 可访问性

```xml
<StackPanel>
    <Label Target="{Binding ElementName=nameBox}"
           Content="_Name:" />
    <TextBox x:Name="nameBox"
             AutomationProperties.Name="Name Input" />

    <Button Content="Submit"
            AutomationProperties.HelpText="Click to submit the form" />

    <ListBox AutomationProperties.Name="Product List" />
</StackPanel>
```

---

## 常见问题

### 如何设置应用程序图标？

```xml
<Application x:Class="MyApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:local="clr-namespace:MyApp"
             ShutdownMode="OnMainWindowClose"
             StartupUri="MainWindow.xaml">
    <Application.Resources>

    </Application.Resources>
</Application>
```

在项目文件中：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ApplicationIcon>app.ico</ApplicationIcon>
  </PropertyGroup>

  <ItemGroup>
    <None Remove="app.ico" />
  </ItemGroup>

  <ItemGroup>
    <Resource Include="app.ico" />
  </ItemGroup>
</Project>
```

### 如何响应系统主题Changes?

```csharp
using Microsoft.Win32;
using System.Windows;

namespace MyApp;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        SystemParameters.StaticPropertyChanged += SystemParameters_StaticPropertyChanged;
    }

    private void SystemParameters_StaticPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(SystemParameters.HighContrast))
        {
            // 应用程序主题变更逻辑
        }
    }
}
```

### 如何处理未捕获异常？

```csharp
using System;
using System.Windows;

namespace MyApp;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        AppDomain.CurrentDomain.UnhandledException += CurrentDomain_UnhandledException;
        DispatcherUnhandledException += App_DispatcherUnhandledException;
    }

    private void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
    {
        LogError((Exception)e.ExceptionObject);
    }

    private void App_DispatcherUnhandledException(object sender, System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e)
    {
        LogError(e.Exception);
        e.Handled = true; // 防止应用程序崩溃
    }

    private void LogError(Exception ex)
    {
        // 记录错误日志
        MessageBox.Show($"An error occurred: {ex.Message}");
    }
}
```

---

## 附录

### 常用快捷键

| 快捷键 | 功能 |
|-------|------|
| Ctrl + S | 保存 |
| Ctrl + O | 打开 |
| Ctrl + N | 新建 |
| Ctrl + W | 关闭 |
| Ctrl + Q | 退出 |
| F5 | 调试 |
| Ctrl + F5 | 运行 |
| Alt + F4 | 关闭窗口 |
| Ctrl + Tab | 切换标签页 |

### 参考资源

- [Microsoft WPF Documentation](https://docs.microsoft.com/en-us/dotnet/desktop/wpf/)
- [.NET API Browser](https://learn.microsoft.com/en-us/dotnet/api/)
- [WPF Samples](https://github.com/microsoft/WPF-Samples)

---

*本文档基于 .NET 10 版本编写*
