# 11 · 窗口与页面导航

> 对应示例：`examples/09_navigation`

## 1. 多窗口还是单窗口导航

界面跳转有两套思路，选择决定整个应用的骨架：

| | 多窗口（多个 Window） | 单窗口 + 导航（Frame + Page） |
|---|---|---|
| 模型 | 每个功能一个顶级窗口 | 一个窗口壳，内容区换页 |
| 状态共享 | 各窗口独立，靠传参/服务 | 页面共享同一个 DataContext 上下文 |
| 任务栏 | 可能出现多个图标 | 只有一个 |
| 典型应用 | 工具箱类（计算器 + 记事本） | 向导、设置中心、文档型应用 |
| 心智 | 并列 | **前进/后退** |

规则：功能间是"另一件事"→ 多窗口；功能间是"同一件事的步骤/区域"→ 导航。设置页、向导、文档浏览天然属于后者。

## 2. Frame + Page：最小导航

`09_navigation` 示例只有三个零件：壳窗口顶部两个按钮、内容区一个 `Frame`、两个程序化构建的 `Page`：

```xml
<DockPanel Margin="12">
    <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,12">
        <Button Content="首页" Width="90" Margin="0,0,8,0" Click="Home_Click"/>
        <Button Content="设置" Width="90" Click="Settings_Click"/>
    </StackPanel>
    <Frame x:Name="MainFrame" NavigationUIVisibility="Visible"/>
</DockPanel>
```

```csharp
public MainWindow()
{
    InitializeComponent();
    MainFrame.Navigate(new HomePage());       // 首次进入
}

private void Home_Click(object sender, RoutedEventArgs e)
    => MainFrame.Navigate(new HomePage());

private void Settings_Click(object sender, RoutedEventArgs e)
    => MainFrame.Navigate(new SettingsPage());
```

`Navigate` 换掉 Frame 的内容，`NavigationUIVisibility="Visible"` 显示前进/后退条。Journal（导航日志）自动记录历史：后退就是回到上一个 Page。

## 3. 页面可以纯代码构建

示例的页面没有 XAML，就是普通类：

```csharp
public sealed class HomePage : Page
{
    public HomePage()
    {
        Content = new TextBlock
        {
            Text = "欢迎来到首页",
            FontSize = 22,
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(20)
        };
    }
}
```

这是第 03 章"XAML = 对象图"论断的反向验证：**XAML 能做的，C# 都能做**——`Content = new TextBlock{...}` 对应 `<Page><TextBlock .../></Page>`。实际项目里页面还是用 XAML 写（可读、可设计器编辑），但这个对照能帮你彻底理解 XAML 的本质，也说明 Page 就是普通 ContentControl——绑定、样式、资源一概照旧。

## 4. 传参与页面状态

`Navigate(object)` 的参数就是页面本身，传参就是构造函数：

```csharp
MainFrame.Navigate(new DocumentPage(filePath));      // 传参

public DocumentPage(string path)
{
    InitializeComponent();
    DataContext = new DocumentViewModel(path);        // 每页一个 VM（第 07 章）
}
```

页面生命周期默认**每次导航都 new 一个新页面实例**——旧实例被 Journal 持有（支持后退）或等 GC。两个推论：

1. 页面里订阅了全局事件/静态服务，离开页面后仍然存活（Journal 还引用着它）——退订要配合导航事件
2. 想保留页面状态（输入到一半的表单），要么 `NavigationService.RemoveBackEntry` 控制 Journal，要么把状态放 ViewModel 层由外部持有——页面实例本身不可靠

页面知道自己在导航栈中的位置用 `NavigationService`（页面内）：

```csharp
NavigationService.GoBack();
NavigationService.Navigate(new Uri("Pages/SettingsPage.xaml", UriKind.Relative));
```

## 5. 用事件与主人通信

页面不该知道"谁在窗口里装它"。页面发出事件，壳窗口订阅：

```csharp
// Page 内
public event Action<string>? SaveRequested;
private void Save_Click(object s, RoutedEventArgs e) => SaveRequested?.Invoke(_path);

// 壳窗口
var page = new DocumentPage(path);
page.SaveRequested += p => SaveDocument(p);
MainFrame.Navigate(page);
```

这与第 07 章 ViewModel 的 `FindRequested` 事件外抛是同一个模式：**下级表达意图，上级实现手段**。

## 6. 常见坑

**重复 new 页面导致状态丢失**：每次 `Navigate(new ...)` 都是全新页面，用户填了一半的表单回来是空的。对策：状态放 ViewModel（由壳持有），或缓存页面实例按需 Navigate。

**Journal 内存**：后退历史默认持有页面实例，长会话多页面会涨内存。发布场景可以 `Frame.JournalOwnership` / 清理后退栈。

**Frame 里嵌 Frame**：XAML 导航默认会把 hyperlink 导航冒泡到最近的父 Frame，嵌套时表现为"点了链接整个窗口换页"。内层 Frame 设 `JournalOwnership="OwnsJournal"`。

**Window.Show 后没引用了**：非模态窗口赋给局部变量就离开作用域，窗口可能被 GC 中途回收（表现为闪退消失）。字段持有，第 10 章的规则。

**Page 直接操作窗口**：`((MainWindow)Application.Current.MainWindow).XXX` ——破界写法，难测试难复用。用事件外抛或共享服务。

## 7. 实战建议

- 壳窗口的职责只有：导航编排 + 事件汇聚；每个 Page 配自己的 ViewModel，页间共享数据走服务类，不走页面引用
- 向导类流程用 `NavigationService` 的前进/后退 + 页面构造传参，禁止页面之间互相 new 对方
- 需要菜单驱动的"多文档"界面时，考虑 MainMenu + 一个内容 Frame 的骨架（第 12 章实战虽然是单页编辑器，但"菜单栏 + 内容区"骨架同构）
- 大型应用把"导航"做成服务：`INavigationService.NavigateTo<TViewModel>()` + DataTemplate 映射 VM 到 View（社区库标准做法），本章的 Frame 是它的手工版

---
上一章：[10 对话框与文件 IO](10-dialogs-files.md) ｜ 下一章：[12 实战项目：WPF 记事本+](12-notepad-plus.md)
