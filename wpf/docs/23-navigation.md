# 23 · 窗口与页面导航

> 对应示例：`examples/23_navigation`（Frame + Page 的最小导航壳）

> **本章你将学会**：多窗口与单窗口导航的选型、Frame/Page/Journal 的工作机制、页面传参与状态管理、页面与壳窗口的通信。
> **前置章节**：[22 对话框](22-dialogs-files.md)、[11 MVVM](11-mvvm.md)。

## 1. 多窗口还是单窗口导航

界面跳转有两套思路，选择决定整个应用的骨架：

| | 多窗口（多个 Window） | 单窗口 + 导航（Frame + Page） |
|---|---|---|
| 模型 | 每个功能一个顶级窗口 | 一个窗口壳，内容区换页 |
| 状态共享 | 各窗口独立，靠传参/服务 | 页面共享同一个宿主上下文 |
| 任务栏 | 可能出现多个图标 | 只有一个 |
| 典型应用 | 工具箱类（计算器 + 记事本） | 向导、设置中心、文档型应用 |
| 心智 | 并列 | **前进/后退** |

选型规则：功能间是"另一件事"→ 多窗口；功能间是"同一件事的步骤/区域"→ 导航。设置页、安装向导、文档浏览天然属于后者——用户期待"上一步/下一步"，多窗口给不了这个心智。

## 2. Frame + Page：最小导航

`23_navigation` 示例只有三个零件：壳窗口顶部两个按钮、内容区一个 `Frame`、两个 Page：

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

`Navigate` 换掉 Frame 的内容；`NavigationUIVisibility="Visible"` 显示内置前进/后退条。**Journal（导航日志）自动记录历史**——后退就是回到上一个 Page 实例，浏览器式的心智免费获得。

Page 是什么？就是 `ContentControl` 的一个子类（内容控件，第 07 章家族表里 Window 的近亲）——绑定、样式、资源、模板一概照旧，第 09-15 章的一切在页面里同样成立。

## 3. 页面可以纯代码构建

示例的页面没有 XAML，就是普通类——第 03 章"XAML = 对象图"论断的反向验证：

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

`Content = new TextBlock {...}` 对应 `<Page><TextBlock .../></Page>`——**XAML 能做的，C# 都能做**。实际项目页面还是用 XAML 写（可读、工具支持好），但这个对照能帮你彻底祛魅；也适合"页面内容由数据动态生成"的场景（报表、列表页）。

## 4. 传参与页面状态

`Navigate(object)` 的参数就是页面实例本身，传参就是构造函数：

```csharp
MainFrame.Navigate(new DocumentPage(filePath));

public DocumentPage(string path)
{
    InitializeComponent();
    DataContext = new DocumentViewModel(path);        // 每页一个 VM（第 11 章）
}
```

页面生命周期的关键设定：**每次 Navigate 都 new 一个新页面实例**——旧实例被 Journal 持有（支持后退）或等 GC。两个推论：

1. 页面里订阅了全局事件/静态服务，离开页面后它**仍被 Journal 引用而存活**——退订要配合导航事件做
2. 想保留页面状态（填到一半的表单），把状态放 ViewModel 层由壳持有——**页面实例本身不可靠**；或者干脆缓存页面实例按需 Navigate

页面内主动导航（后退、跳转）用页面自带的 `NavigationService`：

```csharp
NavigationService?.GoBack();
NavigationService?.Navigate(new Uri("Pages/SettingsPage.xaml", UriKind.Relative));
```

## 5. 页面与壳窗口的通信

页面不该知道"谁在窗口里装它"（第 11 章依赖方向在导航场景的应用）。页面发事件，壳订阅：

```csharp
// Page 内
public event Action<string>? SaveRequested;
private void Save_Click(object s, RoutedEventArgs e) => SaveRequested?.Invoke(_path);

// 壳窗口
var page = new DocumentPage(path);
page.SaveRequested += p => SaveDocument(p);
MainFrame.Navigate(page);
```

与 ViewModel 的 `FindRequested` 事件外抛（第 11 章）是同一个模式：**下级表达意图，上级实现手段**。破界写法 `((MainWindow)Application.Current.MainWindow).XXX` 能跑但难测试难复用，见常见坑。

## 6. 常见坑

**重复 new 页面状态丢失**：每次 `Navigate(new ...)` 全新页面，填一半的表单回来是空的。对策：状态放 VM（壳持有）或缓存页面实例。

**Journal 涨内存**：后退历史默认持有页面实例，长会话多页面持续累积。发布场景清理后退栈（`RemoveBackEntry`）或限制历史深度。

**Frame 嵌套**：嵌套 Frame 时点击内层链接把外层换了页——导航事件冒泡到最近的父 Frame。内层设 `JournalOwnership="OwnsJournal"`。

**页面间互相 new 对方**：A 页面里 `new BPage()` 导航过去，B 又知道 A——页面耦合地狱。导航编排集中在壳或导航服务，页面只表达意图（第 5 节）。

**Window.Show 的窗口被 GC**：第 22 章规则在导航场景同样适用——非模态窗口字段持有。

## 7. 实战建议

- 壳窗口职责只有两件事：**导航编排 + 事件汇聚**；每个 Page 配自己的 VM，页间共享数据走服务类
- 向导类流程 = 前进/后退 + 构造传参；禁止页面之间互相引用
- 大型应用的社区标准做法：`INavigationService.NavigateTo<TViewModel>()` + DataTemplate 把 VM 映射到 View（VM 优先导航，页面不实例化）——本章的 Frame 是它的手工版，理解了前者后者只是一层注册
- 与第 22 章的边界：向导/设置用导航；确认/输入用模态对话框——"流程"导航、"打断"对话框

## 自测

1. **什么场景选导航而不是多窗口？** —— 功能是"同一件事的步骤/区域"，用户有前进/后退心智（向导、设置中心）。
2. **每次 Navigate 后页面状态还在吗？为什么？** —— 不在；每次都是新实例，旧实例被 Journal 持有仅供后退。
3. **页面怎么和壳窗口通信？** —— 事件外抛，壳订阅实现——下级表达意图，上级实现手段。
4. **Page 与 Window 是什么关系？** —— 都是 ContentControl 家族；Page 装在 Frame 里、Window 独立存在，绑定/样式体系完全通用。

---
上一章：[22 对话框与文件 IO](22-dialogs-files.md) ｜ 下一章：[24 部署与发布](24-publishing.md)
